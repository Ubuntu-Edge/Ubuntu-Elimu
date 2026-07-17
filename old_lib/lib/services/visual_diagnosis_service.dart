/// Visual Diagnosis Service
/// Implements photo-based diagnosis support
///
/// Features:
/// - Photo capture and storage
/// - Condition matching
/// - Progress tracking over time
/// - Reference image library
library;

import '../models/visual_diagnosis.dart';

class VisualDiagnosisService {
  static final VisualDiagnosisService _instance =
      VisualDiagnosisService._internal();
  factory VisualDiagnosisService() => _instance;
  VisualDiagnosisService._internal();

  // In-memory storage for diagnoses
  final Map<String, List<VisualDiagnosis>> _patientDiagnoses = {};
  final List<VisualProgressRecord> _progressRecords = [];

  /// Analyze an image for potential conditions
  /// Note: This is a simplified matching algorithm - in production,
  /// this would integrate with an ML model
  Future<VisualDiagnosis> analyzeImage({
    required String patientId,
    required String visitId,
    required String imagePath,
    required VisualDiagnosisType type,
    required String bodyLocation,
    String? chiefComplaint,
    required String capturedBy,
  }) async {
    // Get reference conditions for this type
    List<VisualConditionReference> references = getConditionsForType(type);

    // Simple keyword matching for condition suggestions
    List<String> matchedConditions = [];
    double? confidence;

    if (chiefComplaint != null) {
      String complaint = chiefComplaint.toLowerCase();

      for (var ref in references) {
        double matchScore = 0;

        // Check symptoms match
        for (var symptom in ref.symptoms) {
          if (complaint.contains(symptom.toLowerCase())) {
            matchScore += 20;
          }
        }

        if (matchScore > 0) {
          matchedConditions.add(ref.name);
          confidence = (matchScore / 100).clamp(0.0, 0.95);
        }
      }
    }

    // If no matches, add a generic entry
    if (matchedConditions.isEmpty) {
      matchedConditions.add('Unidentified Condition');
    }

    // Create diagnosis record
    VisualDiagnosis diagnosis = VisualDiagnosis(
      id: 'vd_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      visitId: visitId,
      type: type,
      photoPath: imagePath,
      bodyLocation: bodyLocation,
      description: chiefComplaint ?? '',
      matchedConditions: matchedConditions,
      confidenceScore: confidence,
      chwNotes: '',
      capturedAt: DateTime.now(),
    );

    // Store diagnosis
    _patientDiagnoses.putIfAbsent(patientId, () => []);
    _patientDiagnoses[patientId]!.add(diagnosis);

    return diagnosis;
  }

  /// Get conditions for a diagnosis type
  List<VisualConditionReference> getConditionsForType(
      VisualDiagnosisType type) {
    // Filter from CommonVisualConditions based on type
    List<VisualConditionReference> conditions = [];

    for (var conditionData in CommonVisualConditions.conditions) {
      final condType = conditionData['type'] as String;
      if (condType == type.name) {
        conditions.add(VisualConditionReference(
          id: conditionData['name']
              .toString()
              .toLowerCase()
              .replaceAll(' ', '_'),
          name: conditionData['name'] as String,
          description: conditionData['description'] as String,
          type: type,
          referenceImagePaths: [],
          symptoms: List<String>.from(conditionData['symptoms'] as List),
          severity: conditionData['severity'] as String,
          treatmentGuideline: 'Consult healthcare provider',
          requiresReferral: conditionData['requiresReferral'] as bool,
        ));
      }
    }

    return conditions;
  }

  /// Get all reference conditions
  List<VisualConditionReference> getAllConditions() {
    List<VisualConditionReference> allConditions = [];

    for (var conditionData in CommonVisualConditions.conditions) {
      final condType = VisualDiagnosisType.values.firstWhere(
        (t) => t.name == conditionData['type'],
        orElse: () => VisualDiagnosisType.other,
      );

      allConditions.add(VisualConditionReference(
        id: conditionData['name'].toString().toLowerCase().replaceAll(' ', '_'),
        name: conditionData['name'] as String,
        description: conditionData['description'] as String,
        type: condType,
        referenceImagePaths: [],
        symptoms: List<String>.from(conditionData['symptoms'] as List),
        severity: conditionData['severity'] as String,
        treatmentGuideline: 'Consult healthcare provider',
        requiresReferral: conditionData['requiresReferral'] as bool,
      ));
    }

    return allConditions;
  }

  /// Get diagnosis history for a patient
  List<VisualDiagnosis> getPatientDiagnoses(String patientId) {
    return _patientDiagnoses[patientId] ?? [];
  }

  /// Add progress record
  void addProgressRecord({
    required String patientId,
    required String conditionName,
    required String imagePath,
    required String status, // 'improving', 'stable', 'worsening', 'resolved'
    String? notes,
  }) {
    // Create new entry
    var entry = VisualProgressEntry(
      photoPath: imagePath,
      date: DateTime.now(),
      notes: notes ?? '',
      assessment: status,
    );

    // Check if record exists for this condition
    var existingRecord = _progressRecords.firstWhere(
      (r) => r.patientId == patientId && r.conditionName == conditionName,
      orElse: () => VisualProgressRecord(
        patientId: patientId,
        conditionName: conditionName,
        entries: [],
        status: status,
        startDate: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
    );

    // Add entry to record
    var updatedRecord = VisualProgressRecord(
      patientId: patientId,
      conditionName: conditionName,
      entries: [...existingRecord.entries, entry],
      status: status,
      startDate: existingRecord.startDate,
      lastUpdated: DateTime.now(),
    );

    // Update or add record
    _progressRecords.removeWhere(
        (r) => r.patientId == patientId && r.conditionName == conditionName);
    _progressRecords.add(updatedRecord);
  }

  /// Get progress history for a condition
  List<VisualProgressRecord> getProgressHistory({
    required String patientId,
    required String conditionName,
  }) {
    return _progressRecords
        .where(
            (r) => r.patientId == patientId && r.conditionName == conditionName)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Compare two images for progress
  String assessProgress(String status) {
    switch (status) {
      case 'improved':
        return 'Condition is improving. Continue current treatment.';
      case 'stable':
        return 'Condition is stable. Monitor and continue treatment.';
      case 'worsened':
        return 'Condition has worsened. Consider referral or treatment adjustment.';
      case 'resolved':
        return 'Condition has resolved. Continue preventive measures.';
      default:
        return 'New condition identified. Assess and determine treatment plan.';
    }
  }

  /// Update diagnosis with confirmed condition
  void updateDiagnosis({
    required String diagnosisId,
    required String patientId,
    String? selectedCondition,
    String? notes,
    bool? isReferred,
  }) {
    var diagnoses = _patientDiagnoses[patientId];
    if (diagnoses == null) return;

    int index = diagnoses.indexWhere((d) => d.id == diagnosisId);
    if (index == -1) return;

    var existing = diagnoses[index];
    diagnoses[index] = VisualDiagnosis(
      id: existing.id,
      patientId: existing.patientId,
      visitId: existing.visitId,
      type: existing.type,
      photoPath: existing.photoPath,
      bodyLocation: existing.bodyLocation,
      description: existing.description,
      matchedConditions: selectedCondition != null
          ? [
              selectedCondition,
              ...existing.matchedConditions.where((c) => c != selectedCondition)
            ]
          : existing.matchedConditions,
      confidenceScore: existing.confidenceScore,
      chwNotes: notes ?? existing.chwNotes,
      capturedAt: existing.capturedAt,
      isFlagged: isReferred ?? existing.isFlagged,
      flagReason: isReferred == true
          ? 'Referred for further examination'
          : existing.flagReason,
    );
  }

  /// Get body location display name
  String getBodyLocationName(String location) {
    return BodyLocations.locations.firstWhere(
      (l) => l.toLowerCase() == location.toLowerCase(),
      orElse: () => location,
    );
  }

  /// Get all available body locations
  List<String> getBodyLocations() {
    return BodyLocations.locations;
  }

  /// Get all diagnosis history (all patients)
  List<VisualDiagnosis> getDiagnosisHistory() {
    List<VisualDiagnosis> allDiagnoses = [];
    for (var diagnoses in _patientDiagnoses.values) {
      allDiagnoses.addAll(diagnoses);
    }
    allDiagnoses.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return allDiagnoses;
  }
}
