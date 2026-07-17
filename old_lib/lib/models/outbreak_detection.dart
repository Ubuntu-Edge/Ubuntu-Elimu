// Outbreak Detection Model
// Implements Community Health Mapping & Outbreak Detection
// 
// Detects patterns of disease spread in communities:
// - Cluster detection (multiple cases in same area)
// - Temporal patterns (cases increasing over time)
// - Geographic hotspots

class OutbreakAlert {
  final String id;
  final String disease;
  final String village;
  final int caseCount;
  final int newCasesLast7Days;
  final double growthRate; // Percentage increase
  final OutbreakSeverity severity;
  final String description;
  final String recommendedAction;
  final List<String> affectedPatientIds;
  final DateTime firstCaseDate;
  final DateTime lastCaseDate;
  final DateTime detectedAt;
  final bool isAcknowledged;
  final bool isResolved;

  OutbreakAlert({
    required this.id,
    required this.disease,
    required this.village,
    required this.caseCount,
    required this.newCasesLast7Days,
    required this.growthRate,
    required this.severity,
    required this.description,
    required this.recommendedAction,
    required this.affectedPatientIds,
    required this.firstCaseDate,
    required this.lastCaseDate,
    required this.detectedAt,
    this.isAcknowledged = false,
    this.isResolved = false,
  });

  String get severityIcon {
    switch (severity) {
      case OutbreakSeverity.critical:
        return '🚨';
      case OutbreakSeverity.high:
        return '⚠️';
      case OutbreakSeverity.moderate:
        return '🔶';
      case OutbreakSeverity.low:
        return '📊';
    }
  }

  String get severityLabel {
    switch (severity) {
      case OutbreakSeverity.critical:
        return 'CRITICAL';
      case OutbreakSeverity.high:
        return 'HIGH';
      case OutbreakSeverity.moderate:
        return 'MODERATE';
      case OutbreakSeverity.low:
        return 'LOW';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'disease': disease,
      'village': village,
      'caseCount': caseCount,
      'newCasesLast7Days': newCasesLast7Days,
      'growthRate': growthRate,
      'severity': severity.name,
      'description': description,
      'recommendedAction': recommendedAction,
      'affectedPatientIds': affectedPatientIds,
      'firstCaseDate': firstCaseDate.toIso8601String(),
      'lastCaseDate': lastCaseDate.toIso8601String(),
      'detectedAt': detectedAt.toIso8601String(),
      'isAcknowledged': isAcknowledged,
      'isResolved': isResolved,
    };
  }

  factory OutbreakAlert.fromMap(Map<String, dynamic> map) {
    return OutbreakAlert(
      id: map['id'],
      disease: map['disease'],
      village: map['village'],
      caseCount: map['caseCount'],
      newCasesLast7Days: map['newCasesLast7Days'],
      growthRate: (map['growthRate'] as num).toDouble(),
      severity: OutbreakSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => OutbreakSeverity.low,
      ),
      description: map['description'],
      recommendedAction: map['recommendedAction'],
      affectedPatientIds: List<String>.from(map['affectedPatientIds']),
      firstCaseDate: DateTime.parse(map['firstCaseDate']),
      lastCaseDate: DateTime.parse(map['lastCaseDate']),
      detectedAt: DateTime.parse(map['detectedAt']),
      isAcknowledged: map['isAcknowledged'] ?? false,
      isResolved: map['isResolved'] ?? false,
    );
  }
}

enum OutbreakSeverity {
  low,      // 3-4 cases, stable
  moderate, // 5-9 cases or growing
  high,     // 10+ cases or rapid growth
  critical, // Emergency, widespread
}

/// Disease cluster - group of cases in same location
class DiseaseCluster {
  final String disease;
  final String location;
  final List<CaseRecord> cases;
  final DateTime periodStart;
  final DateTime periodEnd;

  DiseaseCluster({
    required this.disease,
    required this.location,
    required this.cases,
    required this.periodStart,
    required this.periodEnd,
  });

  int get totalCases => cases.length;
  
  int get recentCases => cases.where((c) => 
    DateTime.now().difference(c.diagnosisDate).inDays <= 7
  ).length;

  double get growthRate {
    final olderCases = cases.where((c) => 
      DateTime.now().difference(c.diagnosisDate).inDays > 7
    ).length;
    
    if (olderCases == 0) return recentCases > 0 ? 100.0 : 0.0;
    
    return ((recentCases - olderCases) / olderCases) * 100;
  }
}

/// Individual case record for tracking
class CaseRecord {
  final String patientId;
  final String patientName;
  final String disease;
  final String village;
  final DateTime diagnosisDate;
  final String? symptoms;
  final String? outcome;

  CaseRecord({
    required this.patientId,
    required this.patientName,
    required this.disease,
    required this.village,
    required this.diagnosisDate,
    this.symptoms,
    this.outcome,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'disease': disease,
      'village': village,
      'diagnosisDate': diagnosisDate.toIso8601String(),
      'symptoms': symptoms,
      'outcome': outcome,
    };
  }

  factory CaseRecord.fromMap(Map<String, dynamic> map) {
    return CaseRecord(
      patientId: map['patientId'],
      patientName: map['patientName'],
      disease: map['disease'],
      village: map['village'],
      diagnosisDate: DateTime.parse(map['diagnosisDate']),
      symptoms: map['symptoms'],
      outcome: map['outcome'],
    );
  }
}

/// Community health statistics for dashboard
class CommunityHealthStats {
  final String village;
  final int totalPatients;
  final int totalVisitsLast30Days;
  final Map<String, int> diseaseBreakdown;
  final List<OutbreakAlert> activeAlerts;
  final double healthScore; // 0-100
  final List<String> topConcerns;

  CommunityHealthStats({
    required this.village,
    required this.totalPatients,
    required this.totalVisitsLast30Days,
    required this.diseaseBreakdown,
    required this.activeAlerts,
    required this.healthScore,
    required this.topConcerns,
  });

  Map<String, dynamic> toMap() {
    return {
      'village': village,
      'totalPatients': totalPatients,
      'totalVisitsLast30Days': totalVisitsLast30Days,
      'diseaseBreakdown': diseaseBreakdown,
      'activeAlerts': activeAlerts.map((a) => a.toMap()).toList(),
      'healthScore': healthScore,
      'topConcerns': topConcerns,
    };
  }
}

/// Disease categories for outbreak tracking
class TrackableDiseases {
  static const Map<String, List<String>> diseaseCategories = {
    'Diarrheal': ['diarrhea', 'cholera', 'typhoid', 'dysentery', 'gastroenteritis'],
    'Respiratory': ['pneumonia', 'tuberculosis', 'tb', 'covid', 'influenza', 'flu', 'bronchitis'],
    'Vector-borne': ['malaria', 'dengue', 'chikungunya', 'yellow fever'],
    'Skin/Infectious': ['measles', 'chicken pox', 'scabies', 'ringworm', 'impetigo'],
    'Water-borne': ['cholera', 'typhoid', 'hepatitis a', 'giardia'],
    'Preventable': ['polio', 'tetanus', 'diphtheria', 'pertussis', 'measles', 'rubella'],
  };

  static const List<String> highPriorityDiseases = [
    'cholera',
    'typhoid',
    'malaria',
    'measles',
    'tuberculosis',
    'tb',
    'covid',
    'pneumonia',
    'meningitis',
    'polio',
    'dengue',
  ];

  static String? categorizeDisease(String diagnosis) {
    final lowerDiag = diagnosis.toLowerCase();
    
    for (var entry in diseaseCategories.entries) {
      if (entry.value.any((d) => lowerDiag.contains(d))) {
        return entry.key;
      }
    }
    return null;
  }

  static bool isHighPriority(String diagnosis) {
    final lowerDiag = diagnosis.toLowerCase();
    return highPriorityDiseases.any((d) => lowerDiag.contains(d));
  }

  static String getOutbreakResponse(String disease) {
    final lowerDisease = disease.toLowerCase();
    
    if (lowerDisease.contains('cholera') || lowerDisease.contains('diarrhea')) {
      return 'IMMEDIATE: Check water sources. Distribute ORS. Set up rehydration points. Report to health facility.';
    }
    if (lowerDisease.contains('malaria')) {
      return 'Distribute bed nets. Conduct indoor residual spraying. Stock up on antimalarials. Report to malaria control program.';
    }
    if (lowerDisease.contains('measles')) {
      return 'Verify vaccination status. Vaccinate unprotected children. Isolate cases. Supplement with Vitamin A.';
    }
    if (lowerDisease.contains('tb') || lowerDisease.contains('tuberculosis')) {
      return 'Contact tracing required. Screen household members. Ensure treatment adherence. Report to TB program.';
    }
    if (lowerDisease.contains('pneumonia')) {
      return 'Ensure antibiotic availability. Monitor oxygen saturation. Refer severe cases. Check for co-infections.';
    }
    if (lowerDisease.contains('typhoid')) {
      return 'Check water and food sources. Emphasize hand hygiene. Provide antibiotics. Report to surveillance.';
    }
    
    return 'Monitor situation. Increase surveillance. Report to health facility. Coordinate with public health.';
  }

  static int getOutbreakThreshold(String disease) {
    final lowerDisease = disease.toLowerCase();
    
    // Some diseases have lower thresholds for outbreak declaration
    if (lowerDisease.contains('cholera')) return 1; // Even 1 case is an outbreak
    if (lowerDisease.contains('polio')) return 1;
    if (lowerDisease.contains('measles')) return 3;
    if (lowerDisease.contains('meningitis')) return 2;
    if (lowerDisease.contains('typhoid')) return 3;
    
    return 5; // Default threshold
  }
}
