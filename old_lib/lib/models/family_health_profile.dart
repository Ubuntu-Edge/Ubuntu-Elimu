// Family Health Risk Model
// Implements Family Health Genetics & Risk Inheritance Tracker
// 
// Tracks how health risks move through families:
// - Genetic risks (diabetes, hypertension, etc.)
// - Environmental risks (TB exposure, contaminated water, etc.)
// - Household-level health alerts

class FamilyHealthProfile {
  final String familyId;
  final String familyName;
  final String headOfHouseholdId;
  final List<FamilyMemberHealth> members;
  final List<FamilyHealthAlert> alerts;
  final List<InheritedRisk> inheritedRisks;
  final List<EnvironmentalRisk> environmentalRisks;
  final double overallFamilyRiskScore;
  final DateTime lastUpdated;

  FamilyHealthProfile({
    required this.familyId,
    required this.familyName,
    required this.headOfHouseholdId,
    required this.members,
    required this.alerts,
    required this.inheritedRisks,
    required this.environmentalRisks,
    required this.overallFamilyRiskScore,
    required this.lastUpdated,
  });

  /// Get high-priority alerts
  List<FamilyHealthAlert> get criticalAlerts => 
    alerts.where((a) => a.priority == AlertPriority.critical).toList();

  /// Get pending screenings for family members
  List<FamilyMemberHealth> get membersNeedingScreening =>
    members.where((m) => m.pendingScreenings.isNotEmpty).toList();

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'headOfHouseholdId': headOfHouseholdId,
      'members': members.map((m) => m.toMap()).toList(),
      'alerts': alerts.map((a) => a.toMap()).toList(),
      'inheritedRisks': inheritedRisks.map((r) => r.toMap()).toList(),
      'environmentalRisks': environmentalRisks.map((r) => r.toMap()).toList(),
      'overallFamilyRiskScore': overallFamilyRiskScore,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory FamilyHealthProfile.fromMap(Map<String, dynamic> map) {
    return FamilyHealthProfile(
      familyId: map['familyId'],
      familyName: map['familyName'],
      headOfHouseholdId: map['headOfHouseholdId'],
      members: (map['members'] as List)
          .map((m) => FamilyMemberHealth.fromMap(m))
          .toList(),
      alerts: (map['alerts'] as List)
          .map((a) => FamilyHealthAlert.fromMap(a))
          .toList(),
      inheritedRisks: (map['inheritedRisks'] as List)
          .map((r) => InheritedRisk.fromMap(r))
          .toList(),
      environmentalRisks: (map['environmentalRisks'] as List)
          .map((r) => EnvironmentalRisk.fromMap(r))
          .toList(),
      overallFamilyRiskScore: (map['overallFamilyRiskScore'] as num).toDouble(),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}

class FamilyMemberHealth {
  final String patientId;
  final String name;
  final String relationship;
  final int age;
  final List<String> conditions;
  final List<String> pendingScreenings;
  final double riskScore;
  final bool needsAttention;

  FamilyMemberHealth({
    required this.patientId,
    required this.name,
    required this.relationship,
    required this.age,
    required this.conditions,
    required this.pendingScreenings,
    required this.riskScore,
    required this.needsAttention,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'name': name,
      'relationship': relationship,
      'age': age,
      'conditions': conditions,
      'pendingScreenings': pendingScreenings,
      'riskScore': riskScore,
      'needsAttention': needsAttention,
    };
  }

  factory FamilyMemberHealth.fromMap(Map<String, dynamic> map) {
    return FamilyMemberHealth(
      patientId: map['patientId'],
      name: map['name'],
      relationship: map['relationship'],
      age: map['age'],
      conditions: List<String>.from(map['conditions']),
      pendingScreenings: List<String>.from(map['pendingScreenings']),
      riskScore: (map['riskScore'] as num).toDouble(),
      needsAttention: map['needsAttention'],
    );
  }
}

class FamilyHealthAlert {
  final String id;
  final String familyId;
  final String title;
  final String description;
  final AlertPriority priority;
  final AlertType type;
  final String? sourcePatientId;
  final List<String> affectedMemberIds;
  final String recommendedAction;
  final DateTime createdAt;
  final bool isAcknowledged;
  final DateTime? acknowledgedAt;

  FamilyHealthAlert({
    required this.id,
    required this.familyId,
    required this.title,
    required this.description,
    required this.priority,
    required this.type,
    this.sourcePatientId,
    required this.affectedMemberIds,
    required this.recommendedAction,
    required this.createdAt,
    this.isAcknowledged = false,
    this.acknowledgedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'title': title,
      'description': description,
      'priority': priority.name,
      'type': type.name,
      'sourcePatientId': sourcePatientId,
      'affectedMemberIds': affectedMemberIds,
      'recommendedAction': recommendedAction,
      'createdAt': createdAt.toIso8601String(),
      'isAcknowledged': isAcknowledged,
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    };
  }

  factory FamilyHealthAlert.fromMap(Map<String, dynamic> map) {
    return FamilyHealthAlert(
      id: map['id'],
      familyId: map['familyId'],
      title: map['title'],
      description: map['description'],
      priority: AlertPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => AlertPriority.low,
      ),
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.screening,
      ),
      sourcePatientId: map['sourcePatientId'],
      affectedMemberIds: List<String>.from(map['affectedMemberIds']),
      recommendedAction: map['recommendedAction'],
      createdAt: DateTime.parse(map['createdAt']),
      isAcknowledged: map['isAcknowledged'] ?? false,
      acknowledgedAt: map['acknowledgedAt'] != null
          ? DateTime.parse(map['acknowledgedAt'])
          : null,
    );
  }
}

enum AlertPriority {
  critical,  // Act immediately
  high,      // Act within 24-48 hours
  medium,    // Act this week
  low,       // Routine follow-up
}

enum AlertType {
  infectiousExposure,  // TB, COVID, etc. in household
  geneticRisk,         // Diabetes, hypertension screening
  screening,           // Routine health screening
  immunization,        // Vaccine due
  prenatal,            // Pregnancy-related
  childHealth,         // Under-5 monitoring
  medication,          // Medication adherence
}

/// Inherited/Genetic Risk passed from parent to child
class InheritedRisk {
  final String riskName;
  final String sourcePatientId;
  final String sourceName;
  final String sourceRelationship;
  final List<String> atRiskMemberIds;
  final double inheritanceProbability;
  final String screeningRecommendation;
  final bool screeningCompleted;

  InheritedRisk({
    required this.riskName,
    required this.sourcePatientId,
    required this.sourceName,
    required this.sourceRelationship,
    required this.atRiskMemberIds,
    required this.inheritanceProbability,
    required this.screeningRecommendation,
    this.screeningCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'riskName': riskName,
      'sourcePatientId': sourcePatientId,
      'sourceName': sourceName,
      'sourceRelationship': sourceRelationship,
      'atRiskMemberIds': atRiskMemberIds,
      'inheritanceProbability': inheritanceProbability,
      'screeningRecommendation': screeningRecommendation,
      'screeningCompleted': screeningCompleted,
    };
  }

  factory InheritedRisk.fromMap(Map<String, dynamic> map) {
    return InheritedRisk(
      riskName: map['riskName'],
      sourcePatientId: map['sourcePatientId'],
      sourceName: map['sourceName'],
      sourceRelationship: map['sourceRelationship'],
      atRiskMemberIds: List<String>.from(map['atRiskMemberIds']),
      inheritanceProbability: (map['inheritanceProbability'] as num).toDouble(),
      screeningRecommendation: map['screeningRecommendation'],
      screeningCompleted: map['screeningCompleted'] ?? false,
    );
  }
}

/// Environmental/Household Risk affecting all family members
class EnvironmentalRisk {
  final String riskName;
  final String description;
  final EnvironmentalRiskType type;
  final String sourcePatientId;
  final List<String> affectedMemberIds;
  final String immediateAction;
  final bool actionTaken;
  final DateTime detectedAt;

  EnvironmentalRisk({
    required this.riskName,
    required this.description,
    required this.type,
    required this.sourcePatientId,
    required this.affectedMemberIds,
    required this.immediateAction,
    this.actionTaken = false,
    required this.detectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'riskName': riskName,
      'description': description,
      'type': type.name,
      'sourcePatientId': sourcePatientId,
      'affectedMemberIds': affectedMemberIds,
      'immediateAction': immediateAction,
      'actionTaken': actionTaken,
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  factory EnvironmentalRisk.fromMap(Map<String, dynamic> map) {
    return EnvironmentalRisk(
      riskName: map['riskName'],
      description: map['description'],
      type: EnvironmentalRiskType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EnvironmentalRiskType.other,
      ),
      sourcePatientId: map['sourcePatientId'],
      affectedMemberIds: List<String>.from(map['affectedMemberIds']),
      immediateAction: map['immediateAction'],
      actionTaken: map['actionTaken'] ?? false,
      detectedAt: DateTime.parse(map['detectedAt']),
    );
  }
}

enum EnvironmentalRiskType {
  infectious,      // TB, COVID, etc.
  waterBorne,      // Cholera, typhoid
  vectorBorne,     // Malaria, dengue
  nutritional,     // Malnutrition in household
  sanitation,      // Poor hygiene conditions
  other,
}

/// List of conditions that can be inherited genetically
class GeneticConditions {
  static const List<String> heritableConditions = [
    'diabetes',
    'type 1 diabetes',
    'type 2 diabetes',
    'hypertension',
    'high blood pressure',
    'heart disease',
    'cardiovascular disease',
    'sickle cell',
    'sickle cell anemia',
    'asthma',
    'cancer',
    'breast cancer',
    'colorectal cancer',
    'epilepsy',
    'mental illness',
    'depression',
    'bipolar disorder',
    'schizophrenia',
    'obesity',
    'thyroid disorder',
    'hemophilia',
    'cystic fibrosis',
  ];

  static bool isHeritable(String condition) {
    final lowerCondition = condition.toLowerCase();
    return heritableConditions.any((c) => lowerCondition.contains(c));
  }

  static String getScreeningRecommendation(String condition) {
    final lowerCondition = condition.toLowerCase();
    
    if (lowerCondition.contains('diabetes')) {
      return 'Screen for early signs of diabetes: fasting blood glucose, HbA1c';
    }
    if (lowerCondition.contains('hypertension') || lowerCondition.contains('blood pressure')) {
      return 'Regular blood pressure monitoring recommended';
    }
    if (lowerCondition.contains('heart') || lowerCondition.contains('cardiovascular')) {
      return 'Cardiovascular risk assessment and lifestyle counseling';
    }
    if (lowerCondition.contains('sickle cell')) {
      return 'Sickle cell screening for children';
    }
    if (lowerCondition.contains('asthma')) {
      return 'Monitor for respiratory symptoms and allergies';
    }
    if (lowerCondition.contains('cancer')) {
      return 'Age-appropriate cancer screening and awareness';
    }
    
    return 'General health screening recommended';
  }
}

/// List of infectious diseases that spread in households
class InfectiousDiseases {
  static const List<String> householdSpreadDiseases = [
    'tuberculosis',
    'tb',
    'covid',
    'covid-19',
    'coronavirus',
    'influenza',
    'flu',
    'measles',
    'chicken pox',
    'chickenpox',
    'mumps',
    'rubella',
    'hepatitis a',
    'hepatitis b',
    'meningitis',
    'whooping cough',
    'pertussis',
    'typhoid',
    'cholera',
    'diarrhea',
    'gastroenteritis',
  ];

  static bool isHouseholdRisk(String diagnosis) {
    final lowerDiagnosis = diagnosis.toLowerCase();
    return householdSpreadDiseases.any((d) => lowerDiagnosis.contains(d));
  }

  static String getHouseholdAction(String diagnosis) {
    final lowerDiagnosis = diagnosis.toLowerCase();
    
    if (lowerDiagnosis.contains('tb') || lowerDiagnosis.contains('tuberculosis')) {
      return 'Screen all household members for TB immediately. Implement infection control measures.';
    }
    if (lowerDiagnosis.contains('covid') || lowerDiagnosis.contains('coronavirus')) {
      return 'Isolate patient. Monitor all household members for symptoms. Consider testing.';
    }
    if (lowerDiagnosis.contains('cholera') || lowerDiagnosis.contains('typhoid')) {
      return 'Check water source. Provide ORS. Screen household for diarrheal illness.';
    }
    if (lowerDiagnosis.contains('measles') || lowerDiagnosis.contains('chicken')) {
      return 'Check vaccination status of all household members. Isolate until no longer infectious.';
    }
    if (lowerDiagnosis.contains('diarrhea') || lowerDiagnosis.contains('gastro')) {
      return 'Emphasize hand hygiene. Provide ORS. Check water and food sources.';
    }
    
    return 'Monitor household members for similar symptoms. Implement hygiene measures.';
  }
}
