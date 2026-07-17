/// Visit API Models
/// Models for visit CRUD operations with backend API
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

/// Vitals schema for patient visits
class VitalsSchema {
  final double? temperature;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? pulseRate;
  final int? respiratoryRate;
  final double? oxygenSaturation;
  final double? weight;
  final double? height;
  final double? bmi;
  final double? bloodGlucose;
  final double? muac;
  final String? muacColor;

  VitalsSchema({
    this.temperature,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.pulseRate,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.weight,
    this.height,
    this.bmi,
    this.bloodGlucose,
    this.muac,
    this.muacColor,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (temperature != null) data['temperature'] = temperature;
    if (bloodPressureSystolic != null)
      data['blood_pressure_systolic'] = bloodPressureSystolic;
    if (bloodPressureDiastolic != null)
      data['blood_pressure_diastolic'] = bloodPressureDiastolic;
    if (pulseRate != null) data['pulse_rate'] = pulseRate;
    if (respiratoryRate != null) data['respiratory_rate'] = respiratoryRate;
    if (oxygenSaturation != null) data['oxygen_saturation'] = oxygenSaturation;
    if (weight != null) data['weight'] = weight;
    if (height != null) data['height'] = height;
    if (bmi != null) data['bmi'] = bmi;
    if (bloodGlucose != null) data['blood_glucose'] = bloodGlucose;
    if (muac != null) data['muac'] = muac;
    if (muacColor != null) data['muac_color'] = muacColor;
    return data;
  }

  factory VitalsSchema.fromJson(Map<String, dynamic> json) {
    return VitalsSchema(
      temperature: json['temperature']?.toDouble(),
      bloodPressureSystolic: json['blood_pressure_systolic'],
      bloodPressureDiastolic: json['blood_pressure_diastolic'],
      pulseRate: json['pulse_rate'],
      respiratoryRate: json['respiratory_rate'],
      oxygenSaturation: json['oxygen_saturation']?.toDouble(),
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      bmi: json['bmi']?.toDouble(),
      bloodGlucose: json['blood_glucose']?.toDouble(),
      muac: json['muac']?.toDouble(),
      muacColor: json['muac_color'],
    );
  }
}

/// Medication object for visits
class MedicationGiven {
  final String name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? route;
  final String? notes;

  MedicationGiven({
    required this.name,
    this.dosage,
    this.frequency,
    this.duration,
    this.route,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'name': name};
    if (dosage != null) data['dosage'] = dosage;
    if (frequency != null) data['frequency'] = frequency;
    if (duration != null) data['duration'] = duration;
    if (route != null) data['route'] = route;
    if (notes != null) data['notes'] = notes;
    return data;
  }

  factory MedicationGiven.fromJson(Map<String, dynamic> json) {
    return MedicationGiven(
      name: json['name'] ?? '',
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      route: json['route'],
      notes: json['notes'],
    );
  }
}

/// Request model for creating a new visit
/// Required: patient_id, visit_date
class VisitCreateRequest {
  final String patientId;
  final String visitDate; // ISO 8601 format
  final String? visitType;
  final String? visitLocation;
  final String? chiefComplaint;
  final String? symptoms;
  final List<String>? symptomsList;
  final String? symptomDuration;
  final String? symptomSeverity;
  final String? diagnosis;
  final List<String>? diagnosisCodes;
  final List<String>? differentialDiagnosis;
  final Map<String, dynamic>? aiAssessment;
  final String? treatment;
  final List<MedicationGiven>? medicationsGiven;
  final List<String>? proceduresPerformed;
  final String? healthEducation;
  final String? urgencyLevel;
  final bool? wasReferred;
  final String? referralLocation;
  final String? referralReason;
  final String? outcome;
  final String? patientStatusAfter;
  final String? followUpDate;
  final bool? followUpCompleted;
  final VitalsSchema? vitals;
  final String? notes;
  final List<String>? attachments;
  final int? visitDurationMinutes;
  final String? deviceId;

  VisitCreateRequest({
    required this.patientId,
    required this.visitDate,
    this.visitType,
    this.visitLocation,
    this.chiefComplaint,
    this.symptoms,
    this.symptomsList,
    this.symptomDuration,
    this.symptomSeverity,
    this.diagnosis,
    this.diagnosisCodes,
    this.differentialDiagnosis,
    this.aiAssessment,
    this.treatment,
    this.medicationsGiven,
    this.proceduresPerformed,
    this.healthEducation,
    this.urgencyLevel,
    this.wasReferred,
    this.referralLocation,
    this.referralReason,
    this.outcome,
    this.patientStatusAfter,
    this.followUpDate,
    this.followUpCompleted,
    this.vitals,
    this.notes,
    this.attachments,
    this.visitDurationMinutes,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'patient_id': patientId,
      'visit_date': visitDate,
    };

    if (visitType != null) data['visit_type'] = visitType;
    if (visitLocation != null) data['visit_location'] = visitLocation;
    if (chiefComplaint != null) data['chief_complaint'] = chiefComplaint;
    if (symptoms != null) data['symptoms'] = symptoms;
    if (symptomsList != null) data['symptoms_list'] = symptomsList;
    if (symptomDuration != null) data['symptom_duration'] = symptomDuration;
    if (symptomSeverity != null) data['symptom_severity'] = symptomSeverity;
    if (diagnosis != null) data['diagnosis'] = diagnosis;
    if (diagnosisCodes != null) data['diagnosis_codes'] = diagnosisCodes;
    if (differentialDiagnosis != null)
      data['differential_diagnosis'] = differentialDiagnosis;
    if (aiAssessment != null) data['ai_assessment'] = aiAssessment;
    if (treatment != null) data['treatment'] = treatment;
    if (medicationsGiven != null) {
      data['medications_given'] =
          medicationsGiven!.map((m) => m.toJson()).toList();
    }
    if (proceduresPerformed != null)
      data['procedures_performed'] = proceduresPerformed;
    if (healthEducation != null) data['health_education'] = healthEducation;
    if (urgencyLevel != null) data['urgency_level'] = urgencyLevel;
    if (wasReferred != null) data['was_referred'] = wasReferred;
    if (referralLocation != null) data['referral_location'] = referralLocation;
    if (referralReason != null) data['referral_reason'] = referralReason;
    if (outcome != null) data['outcome'] = outcome;
    if (patientStatusAfter != null)
      data['patient_status_after'] = patientStatusAfter;
    if (followUpDate != null) data['follow_up_date'] = followUpDate;
    if (followUpCompleted != null)
      data['follow_up_completed'] = followUpCompleted;
    if (vitals != null) data['vitals'] = vitals!.toJson();
    if (notes != null) data['notes'] = notes;
    if (attachments != null) data['attachments'] = attachments;
    if (visitDurationMinutes != null)
      data['visit_duration_minutes'] = visitDurationMinutes;
    if (deviceId != null) data['device_id'] = deviceId;

    return data;
  }
}

/// Request model for updating a visit (all fields optional)
class VisitUpdateRequest {
  final String? visitType;
  final String? visitLocation;
  final String? chiefComplaint;
  final String? symptoms;
  final List<String>? symptomsList;
  final String? symptomDuration;
  final String? symptomSeverity;
  final String? diagnosis;
  final List<String>? diagnosisCodes;
  final List<String>? differentialDiagnosis;
  final Map<String, dynamic>? aiAssessment;
  final String? treatment;
  final List<MedicationGiven>? medicationsGiven;
  final List<String>? proceduresPerformed;
  final String? healthEducation;
  final String? urgencyLevel;
  final bool? wasReferred;
  final String? referralLocation;
  final String? referralReason;
  final String? outcome;
  final String? patientStatusAfter;
  final String? followUpDate;
  final bool? followUpCompleted;
  final VitalsSchema? vitals;
  final String? notes;
  final List<String>? attachments;
  final int? visitDurationMinutes;

  VisitUpdateRequest({
    this.visitType,
    this.visitLocation,
    this.chiefComplaint,
    this.symptoms,
    this.symptomsList,
    this.symptomDuration,
    this.symptomSeverity,
    this.diagnosis,
    this.diagnosisCodes,
    this.differentialDiagnosis,
    this.aiAssessment,
    this.treatment,
    this.medicationsGiven,
    this.proceduresPerformed,
    this.healthEducation,
    this.urgencyLevel,
    this.wasReferred,
    this.referralLocation,
    this.referralReason,
    this.outcome,
    this.patientStatusAfter,
    this.followUpDate,
    this.followUpCompleted,
    this.vitals,
    this.notes,
    this.attachments,
    this.visitDurationMinutes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (visitType != null) data['visit_type'] = visitType;
    if (visitLocation != null) data['visit_location'] = visitLocation;
    if (chiefComplaint != null) data['chief_complaint'] = chiefComplaint;
    if (symptoms != null) data['symptoms'] = symptoms;
    if (symptomsList != null) data['symptoms_list'] = symptomsList;
    if (symptomDuration != null) data['symptom_duration'] = symptomDuration;
    if (symptomSeverity != null) data['symptom_severity'] = symptomSeverity;
    if (diagnosis != null) data['diagnosis'] = diagnosis;
    if (diagnosisCodes != null) data['diagnosis_codes'] = diagnosisCodes;
    if (differentialDiagnosis != null)
      data['differential_diagnosis'] = differentialDiagnosis;
    if (aiAssessment != null) data['ai_assessment'] = aiAssessment;
    if (treatment != null) data['treatment'] = treatment;
    if (medicationsGiven != null) {
      data['medications_given'] =
          medicationsGiven!.map((m) => m.toJson()).toList();
    }
    if (proceduresPerformed != null)
      data['procedures_performed'] = proceduresPerformed;
    if (healthEducation != null) data['health_education'] = healthEducation;
    if (urgencyLevel != null) data['urgency_level'] = urgencyLevel;
    if (wasReferred != null) data['was_referred'] = wasReferred;
    if (referralLocation != null) data['referral_location'] = referralLocation;
    if (referralReason != null) data['referral_reason'] = referralReason;
    if (outcome != null) data['outcome'] = outcome;
    if (patientStatusAfter != null)
      data['patient_status_after'] = patientStatusAfter;
    if (followUpDate != null) data['follow_up_date'] = followUpDate;
    if (followUpCompleted != null)
      data['follow_up_completed'] = followUpCompleted;
    if (vitals != null) data['vitals'] = vitals!.toJson();
    if (notes != null) data['notes'] = notes;
    if (attachments != null) data['attachments'] = attachments;
    if (visitDurationMinutes != null)
      data['visit_duration_minutes'] = visitDurationMinutes;

    return data;
  }
}

/// Response model for visit data from API
class VisitResponse {
  final String id;
  final String patientId;
  final String? chwId;
  final String visitDate;
  final String? visitType;
  final String? visitLocation;
  final String? chiefComplaint;
  final String? symptoms;
  final List<String>? symptomsList;
  final String? symptomDuration;
  final String? symptomSeverity;
  final String? diagnosis;
  final List<String>? diagnosisCodes;
  final List<String>? differentialDiagnosis;
  final Map<String, dynamic>? aiAssessment;
  final String? treatment;
  final List<MedicationGiven>? medicationsGiven;
  final List<String>? proceduresPerformed;
  final String? healthEducation;
  final String? urgencyLevel;
  final bool? wasReferred;
  final String? referralLocation;
  final String? referralReason;
  final String? outcome;
  final String? patientStatusAfter;
  final String? followUpDate;
  final bool? followUpCompleted;
  final VitalsSchema? vitals;
  final String? notes;
  final List<String>? attachments;
  final int? visitDurationMinutes;
  final String? createdAt;
  final String? updatedAt;
  final int? syncVersion;
  final String? lastSyncedAt;

  VisitResponse({
    required this.id,
    required this.patientId,
    this.chwId,
    required this.visitDate,
    this.visitType,
    this.visitLocation,
    this.chiefComplaint,
    this.symptoms,
    this.symptomsList,
    this.symptomDuration,
    this.symptomSeverity,
    this.diagnosis,
    this.diagnosisCodes,
    this.differentialDiagnosis,
    this.aiAssessment,
    this.treatment,
    this.medicationsGiven,
    this.proceduresPerformed,
    this.healthEducation,
    this.urgencyLevel,
    this.wasReferred,
    this.referralLocation,
    this.referralReason,
    this.outcome,
    this.patientStatusAfter,
    this.followUpDate,
    this.followUpCompleted,
    this.vitals,
    this.notes,
    this.attachments,
    this.visitDurationMinutes,
    this.createdAt,
    this.updatedAt,
    this.syncVersion,
    this.lastSyncedAt,
  });

  factory VisitResponse.fromJson(Map<String, dynamic> json) {
    return VisitResponse(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      chwId: json['chw_id'],
      visitDate: json['visit_date'] ?? '',
      visitType: json['visit_type'],
      visitLocation: json['visit_location'],
      chiefComplaint: json['chief_complaint'],
      symptoms: json['symptoms'],
      symptomsList: json['symptoms_list'] != null
          ? List<String>.from(json['symptoms_list'])
          : null,
      symptomDuration: json['symptom_duration'],
      symptomSeverity: json['symptom_severity'],
      diagnosis: json['diagnosis'],
      diagnosisCodes: json['diagnosis_codes'] != null
          ? List<String>.from(json['diagnosis_codes'])
          : null,
      differentialDiagnosis: json['differential_diagnosis'] != null
          ? List<String>.from(json['differential_diagnosis'])
          : null,
      aiAssessment: json['ai_assessment'],
      treatment: json['treatment'],
      medicationsGiven: json['medications_given'] != null
          ? (json['medications_given'] as List)
              .map((m) => MedicationGiven.fromJson(m))
              .toList()
          : null,
      proceduresPerformed: json['procedures_performed'] != null
          ? List<String>.from(json['procedures_performed'])
          : null,
      healthEducation: json['health_education'],
      urgencyLevel: json['urgency_level'],
      wasReferred: json['was_referred'],
      referralLocation: json['referral_location'],
      referralReason: json['referral_reason'],
      outcome: json['outcome'],
      patientStatusAfter: json['patient_status_after'],
      followUpDate: json['follow_up_date'],
      followUpCompleted: json['follow_up_completed'],
      vitals:
          json['vitals'] != null ? VitalsSchema.fromJson(json['vitals']) : null,
      notes: json['notes'],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      visitDurationMinutes: json['visit_duration_minutes'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      syncVersion: json['sync_version'],
      lastSyncedAt: json['last_synced_at'],
    );
  }

  /// Convert to database map for local storage
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'chw_id': chwId,
      'visit_date': visitDate,
      'visit_type': visitType,
      'visit_location': visitLocation,
      'chief_complaint': chiefComplaint,
      'symptoms': symptoms,
      'symptoms_list': symptomsList?.join(','),
      'symptom_duration': symptomDuration,
      'symptom_severity': symptomSeverity,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'urgency_level': urgencyLevel,
      'was_referred': wasReferred == true ? 1 : 0,
      'referral_location': referralLocation,
      'referral_reason': referralReason,
      'outcome': outcome,
      'follow_up_date': followUpDate,
      'follow_up_completed': followUpCompleted == true ? 1 : 0,
      'notes': notes,
      'visit_duration_minutes': visitDurationMinutes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_synced': 1,
      'pending_sync': 0,
    };
  }
}

/// Response model for paginated visit list
class VisitListResponse {
  final bool success;
  final List<VisitResponse> data;
  final VisitPaginationMeta pagination;

  VisitListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory VisitListResponse.fromJson(Map<String, dynamic> json) {
    return VisitListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => VisitResponse.fromJson(item))
              .toList() ??
          [],
      pagination: VisitPaginationMeta.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// Pagination metadata for visits
class VisitPaginationMeta {
  final int page;
  final int perPage;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  VisitPaginationMeta({
    required this.page,
    required this.perPage,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory VisitPaginationMeta.fromJson(Map<String, dynamic> json) {
    return VisitPaginationMeta(
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalCount: json['total_count'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }
}

/// Exception for visit API errors
class VisitApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<VisitValidationError>? validationErrors;

  VisitApiException(this.message, {this.statusCode, this.validationErrors});

  @override
  String toString() => 'VisitApiException: $message';
}

/// Validation error from API
class VisitValidationError {
  final String type;
  final List<String> loc;
  final String msg;
  final dynamic input;

  VisitValidationError({
    required this.type,
    required this.loc,
    required this.msg,
    this.input,
  });

  factory VisitValidationError.fromJson(Map<String, dynamic> json) {
    return VisitValidationError(
      type: json['type'] ?? '',
      loc: List<String>.from(json['loc']?.map((e) => e.toString()) ?? []),
      msg: json['msg'] ?? '',
      input: json['input'],
    );
  }
}
