// Health Risk Score Model
// Implements predictive health risk scoring - "The Health Weather Forecast"
// 
// This model calculates a risk score based on multiple factors:
// - Missed visits
// - Worsening symptoms
// - Chronic illnesses
// - Pregnancy risks
// - Distance from health facilities
// - Age and demographics

class HealthRiskScore {
  final String patientId;
  final double overallScore; // 0-100
  final RiskLevel riskLevel;
  final List<RiskFactor> riskFactors;
  final String recommendation;
  final DateTime calculatedAt;
  final int daysUntilNextRecommendedVisit;

  HealthRiskScore({
    required this.patientId,
    required this.overallScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.recommendation,
    required this.calculatedAt,
    required this.daysUntilNextRecommendedVisit,
  });

  /// Get display color for the risk level
  String get riskColor {
    switch (riskLevel) {
      case RiskLevel.critical:
        return '#7F1D1D';
      case RiskLevel.high:
        return '#DC2626';
      case RiskLevel.medium:
        return '#F97316';
      case RiskLevel.low:
        return '#22C55E';
    }
  }

  /// Get display icon for the risk level
  String get riskIcon {
    switch (riskLevel) {
      case RiskLevel.critical:
        return '🚨';
      case RiskLevel.high:
        return '⚠️';
      case RiskLevel.medium:
        return '🔶';
      case RiskLevel.low:
        return '✅';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'overallScore': overallScore,
      'riskLevel': riskLevel.name,
      'riskFactors': riskFactors.map((f) => f.toMap()).toList(),
      'recommendation': recommendation,
      'calculatedAt': calculatedAt.toIso8601String(),
      'daysUntilNextRecommendedVisit': daysUntilNextRecommendedVisit,
    };
  }

  factory HealthRiskScore.fromMap(Map<String, dynamic> map) {
    return HealthRiskScore(
      patientId: map['patientId'],
      overallScore: (map['overallScore'] as num).toDouble(),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == map['riskLevel'],
        orElse: () => RiskLevel.low,
      ),
      riskFactors: (map['riskFactors'] as List)
          .map((f) => RiskFactor.fromMap(f))
          .toList(),
      recommendation: map['recommendation'],
      calculatedAt: DateTime.parse(map['calculatedAt']),
      daysUntilNextRecommendedVisit: map['daysUntilNextRecommendedVisit'],
    );
  }
}

enum RiskLevel {
  low,      // 0-25: Stable, routine follow-up
  medium,   // 26-50: Needs attention soon
  high,     // 51-75: Visit within 24-48 hours
  critical, // 76-100: Visit today / Emergency
}

class RiskFactor {
  final String name;
  final String description;
  final double weight; // 0-1, how much this contributes to overall risk
  final double score;  // 0-100, individual factor score
  final RiskFactorCategory category;

  RiskFactor({
    required this.name,
    required this.description,
    required this.weight,
    required this.score,
    required this.category,
  });

  double get contribution => weight * score;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'weight': weight,
      'score': score,
      'category': category.name,
    };
  }

  factory RiskFactor.fromMap(Map<String, dynamic> map) {
    return RiskFactor(
      name: map['name'],
      description: map['description'],
      weight: (map['weight'] as num).toDouble(),
      score: (map['score'] as num).toDouble(),
      category: RiskFactorCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => RiskFactorCategory.other,
      ),
    );
  }
}

enum RiskFactorCategory {
  visitHistory,     // Missed visits, overdue follow-ups
  symptoms,         // Worsening symptoms, new symptoms
  chronicCondition, // Diabetes, hypertension, etc.
  pregnancy,        // Pregnancy-related risks
  age,              // Age-based vulnerability
  location,         // Distance from facility
  familyHistory,    // Inherited risks from family
  environmental,    // Household risks (TB exposure, etc.)
  other,
}

/// Prioritized visit recommendation
class VisitPriority {
  final String patientId;
  final String patientName;
  final int priority; // 1 = highest priority
  final HealthRiskScore riskScore;
  final String urgencyLabel;
  final DateTime? lastVisitDate;
  final DateTime? nextDueDate;
  final List<String> reasons;

  VisitPriority({
    required this.patientId,
    required this.patientName,
    required this.priority,
    required this.riskScore,
    required this.urgencyLabel,
    this.lastVisitDate,
    this.nextDueDate,
    required this.reasons,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'priority': priority,
      'riskScore': riskScore.toMap(),
      'urgencyLabel': urgencyLabel,
      'lastVisitDate': lastVisitDate?.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'reasons': reasons,
    };
  }

  factory VisitPriority.fromMap(Map<String, dynamic> map) {
    return VisitPriority(
      patientId: map['patientId'],
      patientName: map['patientName'],
      priority: map['priority'],
      riskScore: HealthRiskScore.fromMap(map['riskScore']),
      urgencyLabel: map['urgencyLabel'],
      lastVisitDate: map['lastVisitDate'] != null
          ? DateTime.parse(map['lastVisitDate'])
          : null,
      nextDueDate: map['nextDueDate'] != null
          ? DateTime.parse(map['nextDueDate'])
          : null,
      reasons: List<String>.from(map['reasons']),
    );
  }
}
