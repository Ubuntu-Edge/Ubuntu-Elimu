/// Smart Triage Service
/// Implements visit prioritization and urgency assessment logic
///
/// Features:
/// - Symptom-based triage scoring
/// - Red flag detection
/// - Visit queue management
/// - Referral recommendations
library;

import '../models/smart_triage.dart';
import '../models/patient.dart';

class SmartTriageService {
  static final SmartTriageService _instance = SmartTriageService._internal();
  factory SmartTriageService() => _instance;
  SmartTriageService._internal();

  // In-memory visit queue
  final List<VisitQueueEntry> _visitQueue = [];

  /// Perform triage assessment based on symptoms and vitals
  TriageAssessment performTriage({
    required String patientId,
    required List<SymptomEntry> symptoms,
    required List<VitalSign> vitalSigns,
    required String assessedBy,
  }) {
    // Calculate priority score and detect red flags
    List<String> redFlags = [];
    int priorityScore = 0;

    // Analyze symptoms
    for (var symptom in symptoms) {
      priorityScore += _getSymptomScore(symptom);
      redFlags.addAll(_detectSymptomRedFlags(symptom));
    }

    // Analyze vital signs
    for (var vital in vitalSigns) {
      priorityScore += _getVitalScore(vital);
      if (vital.status == VitalStatus.criticallyHigh ||
          vital.status == VitalStatus.criticallyLow) {
        redFlags.add(
            'Critical ${vital.type.displayName}: ${vital.value} ${vital.unit}');
      }
    }

    // Determine urgency level
    UrgencyLevel urgencyLevel = _determineUrgencyLevel(priorityScore, redFlags);

    // Check if referral is needed
    bool requiresReferral = _requiresReferral(urgencyLevel, redFlags);
    String? referralReason;
    String? referralFacility;

    if (requiresReferral) {
      referralReason = _getReferralReason(redFlags, symptoms);
      referralFacility = _recommendFacility(urgencyLevel);
    }

    // Generate recommendations
    List<String> recommendations = _generateRecommendations(
      urgencyLevel,
      symptoms,
      vitalSigns,
      requiresReferral,
    );

    // Get recommended action
    String recommendedAction =
        _getRecommendedAction(urgencyLevel, requiresReferral);

    return TriageAssessment(
      id: 'triage_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      assessmentDate: DateTime.now(),
      symptoms: symptoms,
      vitalSigns: vitalSigns,
      urgencyLevel: urgencyLevel,
      recommendedAction: recommendedAction,
      requiresReferral: requiresReferral,
      referralReason: referralReason,
      referralFacility: referralFacility,
      priorityScore: priorityScore.clamp(0, 100),
      redFlags: redFlags.toSet().toList(), // Remove duplicates
      recommendations: recommendations,
      assessedBy: assessedBy,
    );
  }

  /// Calculate score for a symptom
  int _getSymptomScore(SymptomEntry symptom) {
    int baseScore = 10;

    // Adjust for severity
    switch (symptom.severity) {
      case SymptomSeverity.mild:
        baseScore += 5;
        break;
      case SymptomSeverity.moderate:
        baseScore += 15;
        break;
      case SymptomSeverity.severe:
        baseScore += 30;
        break;
      case SymptomSeverity.critical:
        baseScore += 50;
        break;
    }

    // Adjust for duration
    if (symptom.durationDays > 7) {
      baseScore += 10;
    } else if (symptom.durationDays > 3) {
      baseScore += 5;
    }

    // Adjust if worsening
    if (symptom.isWorsening) {
      baseScore += 15;
    }

    return baseScore;
  }

  /// Detect red flags from symptoms
  List<String> _detectSymptomRedFlags(SymptomEntry symptom) {
    List<String> flags = [];
    String lowerSymptom = symptom.symptom.toLowerCase();

    // Check against known red flags
    final redFlagPatterns = {
      'difficulty breathing': ['severe difficulty breathing', 'cannot breathe'],
      'chest pain': ['crushing chest pain', 'radiating pain'],
      'blood': ['coughing blood', 'blood in stool', 'blood in vomit'],
      'unconscious': ['loss of consciousness', 'unresponsive'],
      'seizure': ['seizure', 'convulsion', 'fit'],
      'severe headache': ['worst headache', 'sudden severe headache'],
      'pregnancy bleeding': ['vaginal bleeding', 'hemorrhage'],
    };

    for (var entry in redFlagPatterns.entries) {
      if (lowerSymptom.contains(entry.key)) {
        if (symptom.severity == SymptomSeverity.severe ||
            symptom.severity == SymptomSeverity.critical) {
          flags.addAll(entry.value);
        }
      }
    }

    // Critical severity is always a red flag
    if (symptom.severity == SymptomSeverity.critical) {
      flags.add('Critical: ${symptom.symptom}');
    }

    return flags;
  }

  /// Calculate score for vital sign
  int _getVitalScore(VitalSign vital) {
    switch (vital.status) {
      case VitalStatus.criticallyLow:
      case VitalStatus.criticallyHigh:
        return 40;
      case VitalStatus.low:
      case VitalStatus.high:
        return 15;
      case VitalStatus.normal:
        return 0;
    }
  }

  /// Determine urgency level from score and red flags
  UrgencyLevel _determineUrgencyLevel(int score, List<String> redFlags) {
    if (redFlags.isNotEmpty || score >= 80) {
      return UrgencyLevel.emergency;
    } else if (score >= 60) {
      return UrgencyLevel.urgent;
    } else if (score >= 40) {
      return UrgencyLevel.semiUrgent;
    } else if (score >= 20) {
      return UrgencyLevel.routine;
    } else {
      return UrgencyLevel.preventive;
    }
  }

  /// Check if patient needs referral
  bool _requiresReferral(UrgencyLevel urgency, List<String> redFlags) {
    return urgency == UrgencyLevel.emergency ||
        urgency == UrgencyLevel.urgent ||
        redFlags.length >= 2;
  }

  /// Get reason for referral
  String _getReferralReason(
      List<String> redFlags, List<SymptomEntry> symptoms) {
    if (redFlags.isNotEmpty) {
      return 'Red flags detected: ${redFlags.take(3).join(', ')}';
    }

    var severeSymptoms = symptoms
        .where((s) =>
            s.severity == SymptomSeverity.severe ||
            s.severity == SymptomSeverity.critical)
        .map((s) => s.symptom)
        .toList();

    if (severeSymptoms.isNotEmpty) {
      return 'Severe symptoms: ${severeSymptoms.take(3).join(', ')}';
    }

    return 'Clinical assessment indicates need for higher level of care';
  }

  /// Recommend appropriate facility
  String _recommendFacility(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.emergency:
        return 'Nearest Hospital Emergency Department';
      case UrgencyLevel.urgent:
        return 'Health Center or Hospital';
      case UrgencyLevel.semiUrgent:
        return 'Health Center';
      case UrgencyLevel.routine:
        return 'Local Clinic';
      case UrgencyLevel.preventive:
        return 'Community Health Post';
    }
  }

  /// Generate recommendations based on assessment
  List<String> _generateRecommendations(
    UrgencyLevel urgency,
    List<SymptomEntry> symptoms,
    List<VitalSign> vitalSigns,
    bool requiresReferral,
  ) {
    List<String> recommendations = [];

    if (urgency == UrgencyLevel.emergency) {
      recommendations
          .add('URGENT: Arrange immediate transport to health facility');
      recommendations.add('Keep patient calm and comfortable during transport');
      recommendations.add('Do not give food or water if surgery may be needed');
    }

    // Check for dehydration signs
    bool hasDiarrhea =
        symptoms.any((s) => s.symptom.toLowerCase().contains('diarrhea'));
    bool hasVomiting =
        symptoms.any((s) => s.symptom.toLowerCase().contains('vomiting'));

    if (hasDiarrhea || hasVomiting) {
      recommendations.add('Start oral rehydration therapy (ORS)');
      recommendations.add('Monitor for signs of dehydration');
    }

    // Check for fever
    var tempVital =
        vitalSigns.where((v) => v.type == VitalType.temperature).firstOrNull;
    if (tempVital != null && tempVital.value > 38.0) {
      recommendations.add('Give paracetamol for fever if appropriate');
      recommendations.add('Keep patient cool and hydrated');
      if (tempVital.value > 39.5) {
        recommendations.add('Monitor temperature closely - very high fever');
      }
    }

    // Respiratory issues
    bool hasRespiratoryIssue = symptoms.any((s) {
      var lower = s.symptom.toLowerCase();
      return lower.contains('cough') ||
          lower.contains('breathing') ||
          lower.contains('respiratory');
    });
    if (hasRespiratoryIssue) {
      recommendations.add(
          'Keep patient in upright position if having breathing difficulty');
      recommendations.add('Ensure adequate ventilation');
    }

    // General recommendations
    if (!requiresReferral) {
      recommendations
          .add('Schedule follow-up visit in ${_getFollowUpDays(urgency)} days');
    }

    recommendations.add('Document all observations and actions taken');

    return recommendations;
  }

  /// Get follow-up days based on urgency
  int _getFollowUpDays(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.emergency:
      case UrgencyLevel.urgent:
        return 1;
      case UrgencyLevel.semiUrgent:
        return 2;
      case UrgencyLevel.routine:
        return 7;
      case UrgencyLevel.preventive:
        return 30;
    }
  }

  /// Get recommended action text
  String _getRecommendedAction(UrgencyLevel urgency, bool requiresReferral) {
    if (requiresReferral) {
      switch (urgency) {
        case UrgencyLevel.emergency:
          return 'IMMEDIATE REFERRAL - Call emergency services or transport immediately';
        case UrgencyLevel.urgent:
          return 'URGENT REFERRAL - Transport to health facility within 2 hours';
        default:
          return 'REFERRAL RECOMMENDED - Schedule appointment at health center';
      }
    }

    switch (urgency) {
      case UrgencyLevel.emergency:
        return 'EMERGENCY - Stabilize and transport immediately';
      case UrgencyLevel.urgent:
        return 'Provide immediate care and monitor closely';
      case UrgencyLevel.semiUrgent:
        return 'Treat and schedule follow-up within 24 hours';
      case UrgencyLevel.routine:
        return 'Provide standard care and schedule routine follow-up';
      case UrgencyLevel.preventive:
        return 'Wellness check - provide health education';
    }
  }

  /// Add patient to visit queue
  void addToVisitQueue({
    required Patient patient,
    required String chiefComplaint,
    TriageAssessment? triageAssessment,
  }) {
    UrgencyLevel urgency =
        triageAssessment?.urgencyLevel ?? UrgencyLevel.routine;
    int priority = triageAssessment?.priorityScore ?? 30;
    List<String> redFlags = triageAssessment?.redFlags ?? [];

    final entry = VisitQueueEntry(
      patientId: patient.id,
      patientName: patient.displayId,
      age: patient.age,
      village: patient.village ?? 'Unknown',
      urgencyLevel: urgency,
      priorityScore: priority,
      chiefComplaint: chiefComplaint,
      requestedAt: DateTime.now(),
      hasRedFlags: redFlags.isNotEmpty,
      redFlags: redFlags,
      triageAssessment: triageAssessment,
    );

    _visitQueue.add(entry);
    _sortVisitQueue();
  }

  /// Sort visit queue by priority
  void _sortVisitQueue() {
    _visitQueue.sort((a, b) {
      // First by urgency level
      int urgencyCompare = a.urgencyLevel.index.compareTo(b.urgencyLevel.index);
      if (urgencyCompare != 0) return urgencyCompare;

      // Then by priority score (descending)
      int scoreCompare = b.priorityScore.compareTo(a.priorityScore);
      if (scoreCompare != 0) return scoreCompare;

      // Then by request time (earlier first)
      return a.requestedAt.compareTo(b.requestedAt);
    });
  }

  /// Get current visit queue
  List<VisitQueueEntry> getVisitQueue() {
    _sortVisitQueue();
    return List.unmodifiable(_visitQueue);
  }

  /// Get patients by urgency level
  List<VisitQueueEntry> getPatientsByUrgency(UrgencyLevel urgency) {
    return _visitQueue.where((e) => e.urgencyLevel == urgency).toList();
  }

  /// Remove patient from queue after visit
  void removeFromQueue(String patientId) {
    _visitQueue.removeWhere((e) => e.patientId == patientId);
  }

  /// Get queue statistics
  Map<UrgencyLevel, int> getQueueStats() {
    Map<UrgencyLevel, int> stats = {};
    for (var level in UrgencyLevel.values) {
      stats[level] = _visitQueue.where((e) => e.urgencyLevel == level).length;
    }
    return stats;
  }

  /// Check vital sign status
  VitalStatus checkVitalStatus(VitalType type, double value) {
    final range = type.normalRange;
    final low = range.$1;
    final high = range.$2;

    // Define critical thresholds
    double criticalLow = low * 0.8;
    double criticalHigh = high * 1.25;

    if (value < criticalLow) {
      return VitalStatus.criticallyLow;
    } else if (value < low) {
      return VitalStatus.low;
    } else if (value > criticalHigh) {
      return VitalStatus.criticallyHigh;
    } else if (value > high) {
      return VitalStatus.high;
    } else {
      return VitalStatus.normal;
    }
  }

  /// Create vital sign with automatic status check
  VitalSign createVitalSign({
    required VitalType type,
    required double value,
    String? unit,
  }) {
    return VitalSign(
      type: type,
      value: value,
      unit: unit ?? type.defaultUnit,
      measuredAt: DateTime.now(),
      status: checkVitalStatus(type, value),
    );
  }

  /// Get next patient to visit
  VisitQueueEntry? getNextPatient() {
    if (_visitQueue.isEmpty) return null;
    return _visitQueue.first;
  }

  /// Clear the queue
  void clearQueue() {
    _visitQueue.clear();
  }
}
