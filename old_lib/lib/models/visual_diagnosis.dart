// Visual Diagnosis Model
// Implements Visual Diagnosis Support (Photo-Based)
// 
// Features:
// - Photo capture for skin rashes, wounds, etc.
// - Reference image comparison
// - Progress tracking over time

class VisualDiagnosis {
  final String id;
  final String patientId;
  final String visitId;
  final VisualDiagnosisType type;
  final String photoPath;
  final String? thumbnailPath;
  final String bodyLocation;
  final String description;
  final List<String> matchedConditions;
  final double? confidenceScore;
  final String? chwNotes;
  final DateTime capturedAt;
  final bool isFlagged;
  final String? flagReason;

  VisualDiagnosis({
    required this.id,
    required this.patientId,
    required this.visitId,
    required this.type,
    required this.photoPath,
    this.thumbnailPath,
    required this.bodyLocation,
    required this.description,
    required this.matchedConditions,
    this.confidenceScore,
    this.chwNotes,
    required this.capturedAt,
    this.isFlagged = false,
    this.flagReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'visitId': visitId,
      'type': type.name,
      'photoPath': photoPath,
      'thumbnailPath': thumbnailPath,
      'bodyLocation': bodyLocation,
      'description': description,
      'matchedConditions': matchedConditions,
      'confidenceScore': confidenceScore,
      'chwNotes': chwNotes,
      'capturedAt': capturedAt.toIso8601String(),
      'isFlagged': isFlagged,
      'flagReason': flagReason,
    };
  }

  factory VisualDiagnosis.fromMap(Map<String, dynamic> map) {
    return VisualDiagnosis(
      id: map['id'],
      patientId: map['patientId'],
      visitId: map['visitId'],
      type: VisualDiagnosisType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VisualDiagnosisType.other,
      ),
      photoPath: map['photoPath'],
      thumbnailPath: map['thumbnailPath'],
      bodyLocation: map['bodyLocation'],
      description: map['description'],
      matchedConditions: List<String>.from(map['matchedConditions']),
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble(),
      chwNotes: map['chwNotes'],
      capturedAt: DateTime.parse(map['capturedAt']),
      isFlagged: map['isFlagged'] ?? false,
      flagReason: map['flagReason'],
    );
  }
}

enum VisualDiagnosisType {
  skinRash,
  wound,
  eyeCondition,
  oralCondition,
  malnutrition,
  swelling,
  skinInfection,
  burn,
  other,
}

/// Reference condition for comparison
class VisualConditionReference {
  final String id;
  final String name;
  final String description;
  final VisualDiagnosisType type;
  final List<String> referenceImagePaths;
  final List<String> symptoms;
  final String severity;
  final String treatmentGuideline;
  final bool requiresReferral;

  VisualConditionReference({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.referenceImagePaths,
    required this.symptoms,
    required this.severity,
    required this.treatmentGuideline,
    this.requiresReferral = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'referenceImagePaths': referenceImagePaths,
      'symptoms': symptoms,
      'severity': severity,
      'treatmentGuideline': treatmentGuideline,
      'requiresReferral': requiresReferral,
    };
  }

  factory VisualConditionReference.fromMap(Map<String, dynamic> map) {
    return VisualConditionReference(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: VisualDiagnosisType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VisualDiagnosisType.other,
      ),
      referenceImagePaths: List<String>.from(map['referenceImagePaths']),
      symptoms: List<String>.from(map['symptoms']),
      severity: map['severity'],
      treatmentGuideline: map['treatmentGuideline'],
      requiresReferral: map['requiresReferral'] ?? false,
    );
  }
}

/// Progress tracking - compare images over time
class VisualProgressRecord {
  final String patientId;
  final String conditionName;
  final List<VisualProgressEntry> entries;
  final String status; // improving, stable, worsening
  final DateTime startDate;
  final DateTime lastUpdated;

  VisualProgressRecord({
    required this.patientId,
    required this.conditionName,
    required this.entries,
    required this.status,
    required this.startDate,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'conditionName': conditionName,
      'entries': entries.map((e) => e.toMap()).toList(),
      'status': status,
      'startDate': startDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory VisualProgressRecord.fromMap(Map<String, dynamic> map) {
    return VisualProgressRecord(
      patientId: map['patientId'],
      conditionName: map['conditionName'],
      entries: (map['entries'] as List)
          .map((e) => VisualProgressEntry.fromMap(e))
          .toList(),
      status: map['status'],
      startDate: DateTime.parse(map['startDate']),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}

class VisualProgressEntry {
  final String photoPath;
  final DateTime date;
  final String notes;
  final String assessment; // improved, same, worsened

  VisualProgressEntry({
    required this.photoPath,
    required this.date,
    required this.notes,
    required this.assessment,
  });

  Map<String, dynamic> toMap() {
    return {
      'photoPath': photoPath,
      'date': date.toIso8601String(),
      'notes': notes,
      'assessment': assessment,
    };
  }

  factory VisualProgressEntry.fromMap(Map<String, dynamic> map) {
    return VisualProgressEntry(
      photoPath: map['photoPath'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      assessment: map['assessment'],
    );
  }
}

/// Body locations for photo capture
class BodyLocations {
  static const List<String> locations = [
    'Head/Face',
    'Neck',
    'Chest',
    'Abdomen',
    'Back',
    'Left Arm',
    'Right Arm',
    'Left Hand',
    'Right Hand',
    'Left Leg',
    'Right Leg',
    'Left Foot',
    'Right Foot',
    'Eyes',
    'Mouth/Oral',
    'Ears',
    'Scalp',
    'Genitals',
    'Full Body',
    'Other',
  ];
}

/// Common visual conditions for CHW reference
class CommonVisualConditions {
  static const List<Map<String, dynamic>> conditions = [
    {
      'name': 'Measles Rash',
      'type': 'skinRash',
      'description': 'Red, blotchy rash that starts on face and spreads',
      'symptoms': ['Fever', 'Cough', 'Runny nose', 'Red eyes'],
      'severity': 'High',
      'requiresReferral': true,
    },
    {
      'name': 'Chickenpox',
      'type': 'skinRash',
      'description': 'Itchy blisters that start on chest and spread',
      'symptoms': ['Fever', 'Tiredness', 'Itchy blisters'],
      'severity': 'Moderate',
      'requiresReferral': false,
    },
    {
      'name': 'Scabies',
      'type': 'skinInfection',
      'description': 'Intense itching with small bumps, often between fingers',
      'symptoms': ['Intense itching', 'Small bumps', 'Burrow tracks'],
      'severity': 'Low',
      'requiresReferral': false,
    },
    {
      'name': 'Ringworm',
      'type': 'skinInfection',
      'description': 'Circular red patch with clearer center',
      'symptoms': ['Ring-shaped rash', 'Itching', 'Scaly patch'],
      'severity': 'Low',
      'requiresReferral': false,
    },
    {
      'name': 'Impetigo',
      'type': 'skinInfection',
      'description': 'Honey-colored crusted sores, often around mouth/nose',
      'symptoms': ['Red sores', 'Honey-colored crusts', 'Itching'],
      'severity': 'Moderate',
      'requiresReferral': false,
    },
    {
      'name': 'Malnutrition (Kwashiorkor)',
      'type': 'malnutrition',
      'description': 'Swollen belly, skin changes, hair changes',
      'symptoms': ['Swollen belly', 'Peeling skin', 'Reddish hair'],
      'severity': 'Critical',
      'requiresReferral': true,
    },
    {
      'name': 'Malnutrition (Marasmus)',
      'type': 'malnutrition',
      'description': 'Severe wasting, loose skin, visible ribs',
      'symptoms': ['Extreme thinness', 'Loose skin', 'Sunken eyes'],
      'severity': 'Critical',
      'requiresReferral': true,
    },
    {
      'name': 'Conjunctivitis (Pink Eye)',
      'type': 'eyeCondition',
      'description': 'Red, itchy eye with discharge',
      'symptoms': ['Red eye', 'Discharge', 'Itching', 'Crusting'],
      'severity': 'Low',
      'requiresReferral': false,
    },
    {
      'name': 'Oral Thrush',
      'type': 'oralCondition',
      'description': 'White patches in mouth that can be wiped off',
      'symptoms': ['White patches', 'Redness', 'Difficulty feeding'],
      'severity': 'Low',
      'requiresReferral': false,
    },
    {
      'name': 'Infected Wound',
      'type': 'wound',
      'description': 'Red, swollen wound with pus or increased pain',
      'symptoms': ['Redness', 'Swelling', 'Pus', 'Fever'],
      'severity': 'Moderate',
      'requiresReferral': true,
    },
  ];
}
