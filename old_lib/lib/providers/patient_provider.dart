import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/patient_models.dart';
import '../models/visit.dart';
import '../models/visit_models.dart';
import '../services/database_service.dart';
import '../services/patient_api_service.dart';
import '../services/visit_api_service.dart';
import '../services/connectivity_service.dart';
import '../services/audit_log_service.dart';

class PatientProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final PatientApiService _api = PatientApiService.instance;
  final VisitApiService _visitApi = VisitApiService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final AuditLogService _auditLog = AuditLogService.instance;

  String? _chwId;
  List<Patient> _patients = [];
  List<Patient> _highRiskPatients = [];
  List<Visit> _pendingFollowUps = [];
  Map<String, int> _statistics = {};

  bool _isLoading = false;
  String? _errorMessage;

  List<Patient> get patients => _patients;
  List<Patient> get highRiskPatients => _highRiskPatients;
  List<Visit> get pendingFollowUps => _pendingFollowUps;
  Map<String, int> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _connectivity.isOnline;

  // Load all patients for a CHW - sync from server when online
  Future<void> loadPatients(String chwId) async {
    _chwId = chwId;
    _isLoading = true;
    notifyListeners();

    try {
      // Try to sync from server first when online
      if (isOnline) {
        try {
          final response = await _api.listPatients(perPage: 100);
          // Update local database with server data
          for (final serverPatient in response.data) {
            final dbMap = serverPatient.toDbMap();
            // Override chw_id if server didn't provide it
            if (dbMap['chw_id'] == null || dbMap['chw_id'].isEmpty) {
              dbMap['chw_id'] = chwId;
            }
            await _db.upsertPatient(dbMap);
          }
          debugPrint('✅ Synced ${response.data.length} patients from server');
        } on PatientApiException catch (e) {
          debugPrint('⚠️ Failed to sync patients from server: ${e.message}');
        }
      }

      // Load from local database
      _patients = await _db.getPatientsByCHW(chwId);
      _highRiskPatients = await _db.getHighRiskPatients(chwId);
      _pendingFollowUps = await _db.getPendingFollowUps(chwId);
      _statistics = await _db.getCHWStatistics(chwId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load patients: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new patient - offline-first, sync in background
  Future<bool> addPatient(Patient patient) async {
    try {
      // OFFLINE-FIRST: Save locally immediately
      final patientMap = patient.toMap();
      patientMap['is_synced'] = 0;
      patientMap['pending_sync'] = 1;
      await _db.createPatientFromMap(patientMap);

      debugPrint('✅ Patient saved locally: ${patient.id}');

      // Log the operation for audit
      await _auditLog.logPatient(
        operation: AuditOperation.create,
        patientId: patient.id,
        description: 'Created patient ${patient.firstName} ${patient.lastName}',
        newValue: patientMap,
      );

      _patients.insert(0, patient);

      // Update high risk list if needed
      if (patient.isHighRisk ||
          (patient.isPregnant ?? false) ||
          (patient.hasChronicCondition ?? false)) {
        _highRiskPatients.insert(0, patient);
      }

      // Update statistics
      _statistics['totalPatients'] = (_statistics['totalPatients'] ?? 0) + 1;
      if (patient.isHighRisk || (patient.isPregnant ?? false)) {
        _statistics['highRiskPatients'] =
            (_statistics['highRiskPatients'] ?? 0) + 1;
      }

      notifyListeners();

      // Try to sync to server in background (non-blocking)
      if (isOnline) {
        _syncPatientToBackgroundCreate(patient);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to add patient: $e';
      notifyListeners();
      return false;
    }
  }

  // Update patient - sync to server when online
  Future<bool> updatePatient(Patient patient) async {
    try {
      // Try to sync to server first when online
      if (isOnline) {
        try {
          final request = PatientUpdateRequest(
            firstName: patient.firstName,
            lastName: patient.lastName,
            otherNames: patient.otherNames,
            dateOfBirth: patient.dateOfBirth?.toIso8601String().split('T')[0],
            gender: patient.gender,
            phoneNumber: patient.phoneNumber,
            alternativePhone: patient.alternativePhone,
            village: patient.village,
            location: patient.location,
            address: patient.address,
            latitude: patient.latitude,
            longitude: patient.longitude,
            familyId: patient.familyId,
            relationshipToHead: patient.relationshipToHead,
            nationalId: patient.nationalId,
            healthStatus: patient.healthStatus,
            isPregnant: patient.isPregnant,
            pregnancyWeek: patient.pregnancyWeek,
            expectedDeliveryDate:
                patient.expectedDeliveryDate?.toIso8601String().split('T')[0],
            hasChronicCondition: patient.hasChronicCondition,
            chronicConditions: patient.chronicConditions
                ?.split(',')
                .map((e) => e.trim())
                .toList(),
            isHighRisk: patient.isHighRisk,
            riskFactors:
                patient.riskFactors?.split(',').map((e) => e.trim()).toList(),
            riskScore: patient.riskScore,
            bloodType: patient.bloodType,
            allergies:
                patient.allergies?.split(',').map((e) => e.trim()).toList(),
            currentMedications: patient.currentMedications
                ?.split(',')
                .map((e) => e.trim())
                .toList(),
            nextOfKinName: patient.nextOfKinName,
            nextOfKinPhone: patient.nextOfKinPhone,
            nextOfKinRelationship: patient.nextOfKinRelationship,
            photoUrl: patient.photoPath,
            notes: patient.notes,
          );

          await _api.updatePatient(patient.id, request);
          debugPrint('✅ Patient updated on server: ${patient.id}');
        } on PatientApiException catch (e) {
          debugPrint(
              '⚠️ Failed to sync patient update to server: ${e.message}');
        }
      }

      // Update in local database with sync status
      final patientMap = patient.toMap();
      // If we failed to sync to server (or offline), mark as pending
      if (!isOnline) {
        patientMap['pending_sync'] = 1;
      }
      await _db.updatePatientFromMap(patient.id, patientMap);

      // Log the operation for audit
      await _auditLog.logPatient(
        operation: AuditOperation.update,
        patientId: patient.id,
        description: 'Updated patient ${patient.firstName} ${patient.lastName}',
        newValue: patientMap,
      );

      final index = _patients.indexWhere((p) => p.id == patient.id);
      if (index != -1) {
        _patients[index] = patient;
      }

      // Update high risk list
      final highRiskIndex =
          _highRiskPatients.indexWhere((p) => p.id == patient.id);
      if (patient.isHighRisk ||
          (patient.isPregnant ?? false) ||
          (patient.hasChronicCondition ?? false)) {
        if (highRiskIndex == -1) {
          _highRiskPatients.insert(0, patient);
        } else {
          _highRiskPatients[highRiskIndex] = patient;
        }
      } else if (highRiskIndex != -1) {
        _highRiskPatients.removeAt(highRiskIndex);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update patient: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete patient - sync to server when online
  Future<bool> deletePatient(String patientId) async {
    try {
      // Try to delete from server first when online
      if (isOnline) {
        try {
          await _api.deletePatient(patientId);
          debugPrint('✅ Patient deleted from server: $patientId');
        } on PatientApiException catch (e) {
          debugPrint('⚠️ Failed to delete patient from server: ${e.message}');
          // Continue with local delete
        }
      }

      await _db.deletePatient(patientId);

      // Log the operation for audit
      await _auditLog.logPatient(
        operation: AuditOperation.delete,
        patientId: patientId,
        description: 'Deleted patient',
      );

      _patients.removeWhere((p) => p.id == patientId);
      _highRiskPatients.removeWhere((p) => p.id == patientId);

      _statistics['totalPatients'] = (_statistics['totalPatients'] ?? 1) - 1;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete patient: $e';
      notifyListeners();
      return false;
    }
  }

  // Sync pending patients to server
  Future<void> syncPendingPatients() async {
    if (!isOnline) return;

    try {
      final pendingPatients = await _db.getPendingSyncPatients();

      for (final patientMap in pendingPatients) {
        try {
          final chronicConditionsStr =
              patientMap['chronic_conditions'] as String?;
          final chronicConditionsList =
              chronicConditionsStr != null && chronicConditionsStr.isNotEmpty
                  ? [chronicConditionsStr]
                  : null;

          final request = PatientCreateRequest(
            firstName: patientMap['first_name'],
            lastName: patientMap['last_name'],
            dateOfBirth: patientMap['date_of_birth'],
            gender: patientMap['gender'],
            phoneNumber: patientMap['phone_number'],
            village: patientMap['village'],
            address: patientMap['address'],
            familyId: patientMap['family_id'],
            relationshipToHead: patientMap['relationship_to_head'],
            healthStatus: patientMap['health_status'],
            isPregnant: patientMap['is_pregnant'] == 1,
            hasChronicCondition: patientMap['has_chronic_condition'] == 1,
            chronicConditions: chronicConditionsList,
            isHighRisk: patientMap['is_high_risk'] == 1,
            photoUrl: patientMap['photo_path'],
            notes: patientMap['notes'],
          );

          final response = await _api.createPatient(request);

          // Update local record with server ID and sync status
          await _db.updatePatientSyncStatus(
            patientMap['id'],
            response.id,
            isSynced: true,
          );

          debugPrint(
              '✅ Synced pending patient: ${patientMap['id']} -> ${response.id}');
        } on PatientApiException catch (e) {
          debugPrint(
              '⚠️ Failed to sync patient ${patientMap['id']}: ${e.message}');
        }
      }
    } catch (e) {
      debugPrint('Error syncing pending patients: $e');
    }
  }

  // Search patients
  Future<List<Patient>> searchPatients(String chwId, String query) async {
    try {
      return await _db.searchPatients(chwId, query);
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      notifyListeners();
      return [];
    }
  }

  // Add visit - sync to server when online
  Future<bool> addVisit(Visit visit) async {
    try {
      Visit savedVisit = visit;

      // Try to sync to server first when online
      if (isOnline) {
        try {
          // Create API request from visit
          final request = VisitCreateRequest(
            patientId: visit.patientId,
            visitDate: visit.visitDate.toIso8601String(),
            visitType: visit.visitType,
            visitLocation: visit.visitLocation,
            chiefComplaint: visit.chiefComplaint,
            symptoms: visit.symptoms,
            symptomsList: visit.symptomsList,
            symptomDuration: visit.symptomDuration,
            symptomSeverity: visit.symptomSeverity,
            diagnosis: visit.diagnosis,
            diagnosisCodes: visit.diagnosisCodes,
            differentialDiagnosis: visit.differentialDiagnosis,
            aiAssessment: visit.aiAssessment,
            treatment: visit.treatment,
            medicationsGiven: visit.medicationsGiven
                ?.map((m) => MedicationGiven(
                      name: m.name,
                      dosage: m.dosage,
                      frequency: m.frequency,
                      duration: m.duration,
                      route: m.route,
                      notes: m.notes,
                    ))
                .toList(),
            proceduresPerformed: visit.proceduresPerformed,
            healthEducation: visit.healthEducation,
            urgencyLevel: visit.urgencyLevel,
            wasReferred: visit.wasReferred,
            referralLocation: visit.referralLocation,
            referralReason: visit.referralReason,
            outcome: visit.outcome,
            patientStatusAfter: visit.patientStatusAfter,
            followUpDate: visit.followUpDate?.toIso8601String().split('T')[0],
            followUpCompleted: visit.followUpCompleted,
            vitals: visit.vitals != null
                ? VitalsSchema(
                    temperature: visit.vitals!.temperature,
                    bloodPressureSystolic: visit.vitals!.bloodPressureSystolic,
                    bloodPressureDiastolic:
                        visit.vitals!.bloodPressureDiastolic,
                    pulseRate: visit.vitals!.pulseRate,
                    respiratoryRate: visit.vitals!.respiratoryRate,
                    oxygenSaturation: visit.vitals!.oxygenSaturation,
                    weight: visit.vitals!.weight,
                    height: visit.vitals!.height,
                    bmi: visit.vitals!.bmi,
                    bloodGlucose: visit.vitals!.bloodGlucose,
                    muac: visit.vitals!.muac,
                    muacColor: visit.vitals!.muacColor,
                  )
                : null,
            notes: visit.notes,
            attachments: visit.attachments,
            visitDurationMinutes: visit.visitDurationMinutes,
          );

          final response = await _visitApi.createVisit(request);

          // Update visit with server-generated ID and timestamps
          savedVisit = visit.copyWith(
            id: response.id,
            createdAt: response.createdAt != null
                ? DateTime.tryParse(response.createdAt!)
                : null,
            updatedAt: response.updatedAt != null
                ? DateTime.tryParse(response.updatedAt!)
                : null,
          );

          debugPrint('✅ Visit synced to server: ${response.id}');
        } on VisitApiException catch (e) {
          debugPrint('⚠️ Failed to sync visit to server: ${e.message}');
          // Continue to save locally even if server sync fails
        }
      }

      // Save to local database
      await _db.createVisit(savedVisit);

      // Log the operation for audit
      await _auditLog.logVisit(
        operation: AuditOperation.create,
        visitId: savedVisit.id!,
        description: 'Created visit for patient ${visit.patientId}',
        newValue: savedVisit.toMap(),
      );

      _statistics['totalVisits'] = (_statistics['totalVisits'] ?? 0) + 1;

      if (visit.followUpDate != null) {
        _pendingFollowUps.insert(0, savedVisit);
        _statistics['pendingFollowUps'] =
            (_statistics['pendingFollowUps'] ?? 0) + 1;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add visit: $e';
      notifyListeners();
      return false;
    }
  }

  // Get visits for a patient - fetch from server when online
  Future<List<Visit>> getPatientVisitsFromServer(String patientId) async {
    try {
      if (isOnline) {
        try {
          final response =
              await _visitApi.listVisits(patientId: patientId, perPage: 100);

          // Convert API responses to Visit models
          final visits = response.data
              .map((apiVisit) => Visit(
                    id: apiVisit.id,
                    patientId: apiVisit.patientId,
                    visitDate:
                        DateTime.tryParse(apiVisit.visitDate) ?? DateTime.now(),
                    chwId: apiVisit.chwId ?? '',
                    visitType: apiVisit.visitType,
                    visitLocation: apiVisit.visitLocation,
                    chiefComplaint: apiVisit.chiefComplaint,
                    symptoms: apiVisit.symptoms,
                    symptomsList: apiVisit.symptomsList,
                    symptomDuration: apiVisit.symptomDuration,
                    symptomSeverity: apiVisit.symptomSeverity,
                    diagnosis: apiVisit.diagnosis,
                    diagnosisCodes: apiVisit.diagnosisCodes,
                    differentialDiagnosis: apiVisit.differentialDiagnosis,
                    aiAssessment: apiVisit.aiAssessment,
                    treatment: apiVisit.treatment,
                    medicationsGiven: apiVisit.medicationsGiven
                        ?.map((m) => MedicationGivenModel(
                              name: m.name,
                              dosage: m.dosage,
                              frequency: m.frequency,
                              duration: m.duration,
                              route: m.route,
                              notes: m.notes,
                            ))
                        .toList(),
                    proceduresPerformed: apiVisit.proceduresPerformed,
                    healthEducation: apiVisit.healthEducation,
                    urgencyLevel: apiVisit.urgencyLevel ?? 'routine',
                    wasReferred: apiVisit.wasReferred ?? false,
                    referralLocation: apiVisit.referralLocation,
                    referralReason: apiVisit.referralReason,
                    outcome: apiVisit.outcome,
                    patientStatusAfter: apiVisit.patientStatusAfter,
                    followUpDate: apiVisit.followUpDate != null
                        ? DateTime.tryParse(apiVisit.followUpDate!)
                        : null,
                    followUpCompleted: apiVisit.followUpCompleted ?? false,
                    followUpNotes: null, // Not in API response
                    vitals: apiVisit.vitals != null
                        ? Vitals(
                            temperature: apiVisit.vitals!.temperature,
                            bloodPressureSystolic:
                                apiVisit.vitals!.bloodPressureSystolic,
                            bloodPressureDiastolic:
                                apiVisit.vitals!.bloodPressureDiastolic,
                            pulseRate: apiVisit.vitals!.pulseRate,
                            respiratoryRate: apiVisit.vitals!.respiratoryRate,
                            oxygenSaturation: apiVisit.vitals!.oxygenSaturation,
                            weight: apiVisit.vitals!.weight,
                            height: apiVisit.vitals!.height,
                            bmi: apiVisit.vitals!.bmi,
                            bloodGlucose: apiVisit.vitals!.bloodGlucose,
                            muac: apiVisit.vitals!.muac,
                            muacColor: apiVisit.vitals!.muacColor,
                          )
                        : null,
                    notes: apiVisit.notes,
                    attachments: apiVisit.attachments,
                    visitDurationMinutes: apiVisit.visitDurationMinutes,
                    createdAt: apiVisit.createdAt != null
                        ? DateTime.tryParse(apiVisit.createdAt!)
                        : null,
                    updatedAt: apiVisit.updatedAt != null
                        ? DateTime.tryParse(apiVisit.updatedAt!)
                        : null,
                  ))
              .toList();

          debugPrint(
              '✅ Fetched ${visits.length} visits from server for patient $patientId');
          return visits;
        } on VisitApiException catch (e) {
          debugPrint('⚠️ Failed to fetch visits from server: ${e.message}');
        }
      }

      // Fallback to local database
      return await _db.getVisitsByPatient(patientId);
    } catch (e) {
      _errorMessage = 'Failed to get visits: $e';
      notifyListeners();
      return [];
    }
  }

  // Get patient by ID - fetch from server when online, fallback to local
  Future<Patient?> getPatient(String patientId) async {
    try {
      // Try to fetch from server first when online
      if (isOnline) {
        try {
          final response = await _api.getPatient(patientId);

          // Convert API response to local Patient model
          final patient = Patient(
            id: response.id,
            chwId: response.chwId ?? '',
            familyId: response.familyId,
            firstName: response.firstName,
            lastName: response.lastName,
            otherNames: response.otherNames,
            dateOfBirth: response.dateOfBirth != null
                ? DateTime.tryParse(response.dateOfBirth!)
                : null,
            gender: response.gender,
            phoneNumber: response.phoneNumber,
            alternativePhone: response.alternativePhone,
            relationshipToHead: response.relationshipToHead,
            healthStatus: response.healthStatus,
            village: response.village,
            location: response.location,
            address: response.address,
            latitude: response.latitude,
            longitude: response.longitude,
            photoPath: response.photoUrl,
            notes: response.notes,
            isPregnant: response.isPregnant,
            pregnancyWeek: response.pregnancyWeek,
            expectedDeliveryDate: response.expectedDeliveryDate != null
                ? DateTime.tryParse(response.expectedDeliveryDate!)
                : null,
            hasChronicCondition: response.hasChronicCondition,
            chronicConditions: response.chronicConditions?.join(', '),
            isHighRisk: response.isHighRisk ?? false,
            riskFactors: response.riskFactors?.join(', '),
            riskScore: response.riskScore,
            bloodType: response.bloodType,
            allergies: response.allergies?.join(', '),
            currentMedications: response.currentMedications?.join(', '),
            maritalStatus: response.maritalStatus,
            nationalId: response.nationalId,
            nextOfKinName: response.nextOfKinName,
            nextOfKinPhone: response.nextOfKinPhone,
            nextOfKinRelationship: response.nextOfKinRelationship,
            registeredDate: response.registeredDate != null
                ? DateTime.tryParse(response.registeredDate!) ?? DateTime.now()
                : DateTime.now(),
          );

          debugPrint('✅ Fetched patient from server: ${response.id}');
          return patient;
        } on PatientApiException catch (e) {
          debugPrint('⚠️ Failed to fetch patient from server: ${e.message}');
          // Fallback to local database
        }
      }

      // Fallback to local database
      return await _db.getPatientById(patientId);
    } catch (e) {
      _errorMessage = 'Failed to get patient: $e';
      notifyListeners();
      return null;
    }
  }

  // Get visits for a patient
  Future<List<Visit>> getPatientVisits(String patientId) async {
    try {
      return await _db.getVisitsByPatient(patientId);
    } catch (e) {
      _errorMessage = 'Failed to load visits: $e';
      notifyListeners();
      return [];
    }
  }

  // Update visit (mark follow-up as completed)
  Future<bool> updateVisit(Visit visit) async {
    try {
      await _db.updateVisit(visit);

      if (visit.followUpCompleted) {
        _pendingFollowUps.removeWhere((v) => v.id == visit.id);
        _statistics['pendingFollowUps'] =
            (_statistics['pendingFollowUps'] ?? 1) - 1;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update visit: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Background patient creation sync - runs asynchronously
  void _syncPatientToBackgroundCreate(Patient patient) {
    Future.microtask(() async {
      try {
        debugPrint('🔄 Background sync: Creating patient on server...');
        final request = PatientCreateRequest(
          firstName: patient.firstName,
          lastName: patient.lastName,
          otherNames: patient.otherNames,
          dateOfBirth: patient.dateOfBirth?.toIso8601String().split('T')[0],
          gender: patient.gender,
          phoneNumber: patient.phoneNumber,
          alternativePhone: patient.alternativePhone,
          village: patient.village,
          location: patient.location,
          address: patient.address,
          latitude: patient.latitude,
          longitude: patient.longitude,
          familyId: patient.familyId,
          relationshipToHead: patient.relationshipToHead,
          nationalId: patient.nationalId,
          healthStatus: patient.healthStatus,
          isPregnant: patient.isPregnant,
          pregnancyWeek: patient.pregnancyWeek,
          expectedDeliveryDate:
              patient.expectedDeliveryDate?.toIso8601String().split('T')[0],
          hasChronicCondition: patient.hasChronicCondition,
          chronicConditions: patient.chronicConditions
              ?.split(',')
              .map((e) => e.trim())
              .toList(),
          isHighRisk: patient.isHighRisk,
          riskFactors:
              patient.riskFactors?.split(',').map((e) => e.trim()).toList(),
          riskScore: patient.riskScore,
          bloodType: patient.bloodType,
          allergies:
              patient.allergies?.split(',').map((e) => e.trim()).toList(),
          currentMedications: patient.currentMedications
              ?.split(',')
              .map((e) => e.trim())
              .toList(),
          nextOfKinName: patient.nextOfKinName,
          nextOfKinPhone: patient.nextOfKinPhone,
          nextOfKinRelationship: patient.nextOfKinRelationship,
          photoUrl: patient.photoPath,
          notes: patient.notes,
        );
        final response = await _api.createPatient(request);
        final db = await _db.database;
        await db.update(
          'patients',
          {
            'id': response.id,
            'is_synced': 1,
            'pending_sync': 0,
            'last_sync_date': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [patient.id],
        );
        debugPrint(
            '✅ Background sync: Patient created on server: ${response.id}');
      } catch (e) {
        debugPrint('⚠️ Background sync: Failed, will retry later: $e');
      }
    });
  }
}
