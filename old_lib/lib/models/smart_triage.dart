// Smart Triage Model
// Implements Smart Triage & Visit Prioritization
// 
// Features:
// - Symptom-based urgency assessment
// - Visit prioritization queue
// - Emergency detection
// - Referral recommendations

import 'package:flutter/material.dart';

/// Main triage assessment result
class TriageAssessment {
  final String id;
  final String patientId;
  final DateTime assessmentDate;
  final List<SymptomEntry> symptoms;
  final List<VitalSign> vitalSigns;
  final UrgencyLevel urgencyLevel;
  final String recommendedAction;
  final bool requiresReferral;
  final String? referralReason;
  final String? referralFacility;
  final int priorityScore; // 1-100, higher = more urgent
  final List<String> redFlags;
  final List<String> recommendations;
  final String assessedBy;

  TriageAssessment({
    required this.id,
    required this.patientId,
    required this.assessmentDate,
    required this.symptoms,
    required this.vitalSigns,
    required this.urgencyLevel,
    required this.recommendedAction,
    required this.requiresReferral,
    this.referralReason,
    this.referralFacility,
    required this.priorityScore,
    required this.redFlags,
    required this.recommendations,
    required this.assessedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'assessmentDate': assessmentDate.toIso8601String(),
      'symptoms': symptoms.map((s) => s.toMap()).toList(),
      'vitalSigns': vitalSigns.map((v) => v.toMap()).toList(),
      'urgencyLevel': urgencyLevel.name,
      'recommendedAction': recommendedAction,
      'requiresReferral': requiresReferral,
      'referralReason': referralReason,
      'referralFacility': referralFacility,
      'priorityScore': priorityScore,
      'redFlags': redFlags,
      'recommendations': recommendations,
      'assessedBy': assessedBy,
    };
  }

  factory TriageAssessment.fromMap(Map<String, dynamic> map) {
    return TriageAssessment(
      id: map['id'],
      patientId: map['patientId'],
      assessmentDate: DateTime.parse(map['assessmentDate']),
      symptoms: (map['symptoms'] as List)
          .map((s) => SymptomEntry.fromMap(s))
          .toList(),
      vitalSigns: (map['vitalSigns'] as List)
          .map((v) => VitalSign.fromMap(v))
          .toList(),
      urgencyLevel: UrgencyLevel.values.firstWhere(
        (e) => e.name == map['urgencyLevel'],
        orElse: () => UrgencyLevel.routine,
      ),
      recommendedAction: map['recommendedAction'],
      requiresReferral: map['requiresReferral'],
      referralReason: map['referralReason'],
      referralFacility: map['referralFacility'],
      priorityScore: map['priorityScore'],
      redFlags: List<String>.from(map['redFlags']),
      recommendations: List<String>.from(map['recommendations']),
      assessedBy: map['assessedBy'],
    );
  }
}

/// Urgency levels for triage
enum UrgencyLevel {
  emergency,    // Immediate care needed
  urgent,       // Within 1-2 hours
  semiUrgent,   // Within 24 hours
  routine,      // Can wait for scheduled visit
  preventive,   // No acute issue, wellness check
}

extension UrgencyLevelExtension on UrgencyLevel {
  String get displayName {
    switch (this) {
      case UrgencyLevel.emergency:
        return 'EMERGENCY';
      case UrgencyLevel.urgent:
        return 'Urgent';
      case UrgencyLevel.semiUrgent:
        return 'Semi-Urgent';
      case UrgencyLevel.routine:
        return 'Routine';
      case UrgencyLevel.preventive:
        return 'Preventive';
    }
  }

  Color get color {
    switch (this) {
      case UrgencyLevel.emergency:
        return const Color(0xFFD32F2F); // Red
      case UrgencyLevel.urgent:
        return const Color(0xFFF57C00); // Orange
      case UrgencyLevel.semiUrgent:
        return const Color(0xFFFBC02D); // Yellow
      case UrgencyLevel.routine:
        return const Color(0xFF388E3C); // Green
      case UrgencyLevel.preventive:
        return const Color(0xFF1976D2); // Blue
    }
  }

  String get responseTimeframe {
    switch (this) {
      case UrgencyLevel.emergency:
        return 'Immediately';
      case UrgencyLevel.urgent:
        return 'Within 1-2 hours';
      case UrgencyLevel.semiUrgent:
        return 'Within 24 hours';
      case UrgencyLevel.routine:
        return 'Within 1 week';
      case UrgencyLevel.preventive:
        return 'Scheduled visit';
    }
  }

  int get basePriorityScore {
    switch (this) {
      case UrgencyLevel.emergency:
        return 90;
      case UrgencyLevel.urgent:
        return 70;
      case UrgencyLevel.semiUrgent:
        return 50;
      case UrgencyLevel.routine:
        return 30;
      case UrgencyLevel.preventive:
        return 10;
    }
  }
}

/// Individual symptom entry
class SymptomEntry {
  final String symptom;
  final SymptomSeverity severity;
  final int durationDays;
  final bool isWorsening;
  final String? additionalNotes;

  SymptomEntry({
    required this.symptom,
    required this.severity,
    required this.durationDays,
    required this.isWorsening,
    this.additionalNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'symptom': symptom,
      'severity': severity.name,
      'durationDays': durationDays,
      'isWorsening': isWorsening,
      'additionalNotes': additionalNotes,
    };
  }

  factory SymptomEntry.fromMap(Map<String, dynamic> map) {
    return SymptomEntry(
      symptom: map['symptom'],
      severity: SymptomSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => SymptomSeverity.mild,
      ),
      durationDays: map['durationDays'],
      isWorsening: map['isWorsening'],
      additionalNotes: map['additionalNotes'],
    );
  }
}

enum SymptomSeverity {
  mild,
  moderate,
  severe,
  critical,
}

/// Vital sign measurement
class VitalSign {
  final VitalType type;
  final double value;
  final String unit;
  final DateTime measuredAt;
  final VitalStatus status;

  VitalSign({
    required this.type,
    required this.value,
    required this.unit,
    required this.measuredAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'value': value,
      'unit': unit,
      'measuredAt': measuredAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory VitalSign.fromMap(Map<String, dynamic> map) {
    return VitalSign(
      type: VitalType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VitalType.temperature,
      ),
      value: (map['value'] as num).toDouble(),
      unit: map['unit'],
      measuredAt: DateTime.parse(map['measuredAt']),
      status: VitalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VitalStatus.normal,
      ),
    );
  }
}

enum VitalType {
  temperature,
  bloodPressureSystolic,
  bloodPressureDiastolic,
  heartRate,
  respiratoryRate,
  oxygenSaturation,
  bloodGlucose,
  weight,
}

extension VitalTypeExtension on VitalType {
  String get displayName {
    switch (this) {
      case VitalType.temperature:
        return 'Temperature';
      case VitalType.bloodPressureSystolic:
        return 'Blood Pressure (Systolic)';
      case VitalType.bloodPressureDiastolic:
        return 'Blood Pressure (Diastolic)';
      case VitalType.heartRate:
        return 'Heart Rate';
      case VitalType.respiratoryRate:
        return 'Respiratory Rate';
      case VitalType.oxygenSaturation:
        return 'Oxygen Saturation';
      case VitalType.bloodGlucose:
        return 'Blood Glucose';
      case VitalType.weight:
        return 'Weight';
    }
  }

  String get defaultUnit {
    switch (this) {
      case VitalType.temperature:
        return '°C';
      case VitalType.bloodPressureSystolic:
      case VitalType.bloodPressureDiastolic:
        return 'mmHg';
      case VitalType.heartRate:
        return 'bpm';
      case VitalType.respiratoryRate:
        return 'breaths/min';
      case VitalType.oxygenSaturation:
        return '%';
      case VitalType.bloodGlucose:
        return 'mg/dL';
      case VitalType.weight:
        return 'kg';
    }
  }

  (double, double) get normalRange {
    switch (this) {
      case VitalType.temperature:
        return (36.1, 37.2);
      case VitalType.bloodPressureSystolic:
        return (90, 120);
      case VitalType.bloodPressureDiastolic:
        return (60, 80);
      case VitalType.heartRate:
        return (60, 100);
      case VitalType.respiratoryRate:
        return (12, 20);
      case VitalType.oxygenSaturation:
        return (95, 100);
      case VitalType.bloodGlucose:
        return (70, 140);
      case VitalType.weight:
        return (0, 300); // No "normal" range for weight
    }
  }
}

enum VitalStatus {
  criticallyLow,
  low,
  normal,
  high,
  criticallyHigh,
}

extension VitalStatusExtension on VitalStatus {
  Color get color {
    switch (this) {
      case VitalStatus.criticallyLow:
      case VitalStatus.criticallyHigh:
        return const Color(0xFFD32F2F);
      case VitalStatus.low:
      case VitalStatus.high:
        return const Color(0xFFF57C00);
      case VitalStatus.normal:
        return const Color(0xFF388E3C);
    }
  }
}

/// Predefined symptom categories with red flags
class SymptomCategory {
  final String name;
  final List<SymptomDefinition> symptoms;
  final List<String> redFlags;

  const SymptomCategory({
    required this.name,
    required this.symptoms,
    required this.redFlags,
  });
}

class SymptomDefinition {
  final String name;
  final String description;
  final List<String> associatedRedFlags;
  final int baseUrgencyScore;

  const SymptomDefinition({
    required this.name,
    required this.description,
    required this.associatedRedFlags,
    required this.baseUrgencyScore,
  });
}

/// Common symptom categories for CHW use
class TriageSymptomCategories {
  static const respiratory = SymptomCategory(
    name: 'Respiratory',
    symptoms: [
      SymptomDefinition(
        name: 'Cough',
        description: 'Dry or productive cough',
        associatedRedFlags: ['Coughing blood', 'Difficulty breathing'],
        baseUrgencyScore: 20,
      ),
      SymptomDefinition(
        name: 'Difficulty breathing',
        description: 'Shortness of breath or labored breathing',
        associatedRedFlags: ['Blue lips', 'Cannot speak in full sentences'],
        baseUrgencyScore: 60,
      ),
      SymptomDefinition(
        name: 'Chest pain',
        description: 'Pain or tightness in chest',
        associatedRedFlags: ['Radiating to arm', 'Crushing pain'],
        baseUrgencyScore: 70,
      ),
    ],
    redFlags: [
      'Blue lips or fingernails',
      'Severe difficulty breathing',
      'Coughing blood',
      'Cannot lie flat',
    ],
  );

  static const gastrointestinal = SymptomCategory(
    name: 'Gastrointestinal',
    symptoms: [
      SymptomDefinition(
        name: 'Diarrhea',
        description: 'Loose or watery stools',
        associatedRedFlags: ['Blood in stool', 'Severe dehydration'],
        baseUrgencyScore: 30,
      ),
      SymptomDefinition(
        name: 'Vomiting',
        description: 'Persistent nausea and vomiting',
        associatedRedFlags: ['Blood in vomit', 'Cannot keep fluids down'],
        baseUrgencyScore: 35,
      ),
      SymptomDefinition(
        name: 'Abdominal pain',
        description: 'Stomach or abdominal discomfort',
        associatedRedFlags: ['Rigid abdomen', 'Severe localized pain'],
        baseUrgencyScore: 40,
      ),
    ],
    redFlags: [
      'Blood in stool or vomit',
      'Severe dehydration',
      'Rigid or tender abdomen',
      'Unable to keep any fluids down for 12+ hours',
    ],
  );

  static const neurological = SymptomCategory(
    name: 'Neurological',
    symptoms: [
      SymptomDefinition(
        name: 'Severe headache',
        description: 'Intense or unusual headache',
        associatedRedFlags: ['Worst headache ever', 'Stiff neck'],
        baseUrgencyScore: 50,
      ),
      SymptomDefinition(
        name: 'Confusion',
        description: 'Altered mental status or disorientation',
        associatedRedFlags: ['Sudden onset', 'Cannot recognize family'],
        baseUrgencyScore: 70,
      ),
      SymptomDefinition(
        name: 'Seizures',
        description: 'Convulsions or fits',
        associatedRedFlags: ['First seizure', 'Prolonged seizure'],
        baseUrgencyScore: 80,
      ),
    ],
    redFlags: [
      'Sudden severe headache',
      'Loss of consciousness',
      'One-sided weakness',
      'Difficulty speaking suddenly',
      'Seizures',
    ],
  );

  static const pediatric = SymptomCategory(
    name: 'Pediatric',
    symptoms: [
      SymptomDefinition(
        name: 'High fever in infant',
        description: 'Fever over 38°C in child under 3 months',
        associatedRedFlags: ['Lethargy', 'Poor feeding'],
        baseUrgencyScore: 75,
      ),
      SymptomDefinition(
        name: 'Severe malnutrition',
        description: 'Signs of severe acute malnutrition',
        associatedRedFlags: ['Edema', 'Very thin'],
        baseUrgencyScore: 70,
      ),
      SymptomDefinition(
        name: 'Dehydration in child',
        description: 'Signs of dehydration in pediatric patient',
        associatedRedFlags: ['Sunken eyes', 'No tears', 'No urine 6+ hours'],
        baseUrgencyScore: 60,
      ),
    ],
    redFlags: [
      'Fever in infant under 3 months',
      'Lethargy or unresponsive',
      'Severe dehydration',
      'Difficulty breathing',
      'Bulging fontanelle',
    ],
  );

  static const maternal = SymptomCategory(
    name: 'Maternal',
    symptoms: [
      SymptomDefinition(
        name: 'Vaginal bleeding in pregnancy',
        description: 'Bleeding during pregnancy',
        associatedRedFlags: ['Heavy bleeding', 'Severe pain'],
        baseUrgencyScore: 80,
      ),
      SymptomDefinition(
        name: 'Severe headache in pregnancy',
        description: 'Headache with visual changes',
        associatedRedFlags: ['Blurred vision', 'Swelling'],
        baseUrgencyScore: 75,
      ),
      SymptomDefinition(
        name: 'Reduced fetal movement',
        description: 'Baby moving less than usual',
        associatedRedFlags: ['No movement for 12+ hours'],
        baseUrgencyScore: 65,
      ),
    ],
    redFlags: [
      'Heavy vaginal bleeding',
      'Severe abdominal pain',
      'Headache with visual changes',
      'Sudden swelling of face or hands',
      'No fetal movement',
      'Leaking fluid',
    ],
  );

  static List<SymptomCategory> get all => [
    respiratory,
    gastrointestinal,
    neurological,
    pediatric,
    maternal,
  ];
}

/// Visit queue entry for prioritization
class VisitQueueEntry {
  final String patientId;
  final String patientName;
  final int age;
  final String village;
  final UrgencyLevel urgencyLevel;
  final int priorityScore;
  final String chiefComplaint;
  final DateTime requestedAt;
  final bool hasRedFlags;
  final List<String> redFlags;
  final TriageAssessment? triageAssessment;

  VisitQueueEntry({
    required this.patientId,
    required this.patientName,
    required this.age,
    required this.village,
    required this.urgencyLevel,
    required this.priorityScore,
    required this.chiefComplaint,
    required this.requestedAt,
    required this.hasRedFlags,
    required this.redFlags,
    this.triageAssessment,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'age': age,
      'village': village,
      'urgencyLevel': urgencyLevel.name,
      'priorityScore': priorityScore,
      'chiefComplaint': chiefComplaint,
      'requestedAt': requestedAt.toIso8601String(),
      'hasRedFlags': hasRedFlags,
      'redFlags': redFlags,
      'triageAssessment': triageAssessment?.toMap(),
    };
  }

  factory VisitQueueEntry.fromMap(Map<String, dynamic> map) {
    return VisitQueueEntry(
      patientId: map['patientId'],
      patientName: map['patientName'],
      age: map['age'],
      village: map['village'],
      urgencyLevel: UrgencyLevel.values.firstWhere(
        (e) => e.name == map['urgencyLevel'],
        orElse: () => UrgencyLevel.routine,
      ),
      priorityScore: map['priorityScore'],
      chiefComplaint: map['chiefComplaint'],
      requestedAt: DateTime.parse(map['requestedAt']),
      hasRedFlags: map['hasRedFlags'],
      redFlags: List<String>.from(map['redFlags']),
      triageAssessment: map['triageAssessment'] != null
          ? TriageAssessment.fromMap(map['triageAssessment'])
          : null,
    );
  }
}
