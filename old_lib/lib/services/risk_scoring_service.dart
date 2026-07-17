import '../models/patient.dart';
import '../models/visit.dart';
import '../models/health_risk_score.dart';
import 'database_service.dart';

/// Risk Scoring Service - "The Health Weather Forecast"
///
/// Calculates predictive health risk scores for patients based on:
/// - Visit history and missed appointments
/// - Chronic conditions
/// - Pregnancy status
/// - Age vulnerability
/// - Symptom patterns
/// - Family health history
class RiskScoringService {
  static final RiskScoringService instance = RiskScoringService._init();
  RiskScoringService._init();

  /// Calculate risk score for a single patient
  Future<HealthRiskScore> calculateRiskScore(Patient patient) async {
    final visits =
        await DatabaseService.instance.getVisitsByPatient(patient.id);

    List<RiskFactor> factors = [];

    // Factor 1: Visit History (missed visits, overdue follow-ups)
    factors.add(_calculateVisitHistoryRisk(patient, visits));

    // Factor 2: Chronic Conditions
    factors.add(_calculateChronicConditionRisk(patient));

    // Factor 3: Pregnancy Risk
    factors.add(_calculatePregnancyRisk(patient, visits));

    // Factor 4: Age Vulnerability
    factors.add(_calculateAgeRisk(patient));

    // Factor 5: Symptom Severity (from recent visits)
    factors.add(_calculateSymptomRisk(visits));

    // Factor 6: Follow-up Compliance
    factors.add(_calculateComplianceRisk(visits));

    // Calculate overall score (weighted average)
    double totalWeight = factors.fold(0.0, (sum, f) => sum + f.weight);
    double weightedScore = factors.fold(0.0, (sum, f) => sum + f.contribution);
    double overallScore = totalWeight > 0 ? weightedScore / totalWeight : 0;

    // Determine risk level
    RiskLevel riskLevel = _determineRiskLevel(overallScore);

    // Generate recommendation
    String recommendation =
        _generateRecommendation(riskLevel, factors, patient);

    // Calculate days until next recommended visit
    int daysUntilVisit = _calculateDaysUntilVisit(riskLevel);

    return HealthRiskScore(
      patientId: patient.id,
      overallScore: overallScore,
      riskLevel: riskLevel,
      riskFactors: factors.where((f) => f.score > 0).toList(),
      recommendation: recommendation,
      calculatedAt: DateTime.now(),
      daysUntilNextRecommendedVisit: daysUntilVisit,
    );
  }

  /// Calculate risk scores for all patients and return prioritized list
  Future<List<VisitPriority>> getPrioritizedVisitList(String chwId) async {
    final patients = await DatabaseService.instance.getPatientsByCHW(chwId);
    List<VisitPriority> priorities = [];

    for (var patient in patients) {
      final riskScore = await calculateRiskScore(patient);
      final visits =
          await DatabaseService.instance.getVisitsByPatient(patient.id);

      DateTime? lastVisit = visits.isNotEmpty ? visits.first.visitDate : null;
      DateTime? nextDue = _calculateNextDueDate(riskScore, lastVisit);

      priorities.add(VisitPriority(
        patientId: patient.id,
        patientName: '${patient.firstName} ${patient.lastName}',
        priority: 0, // Will be assigned after sorting
        riskScore: riskScore,
        urgencyLabel: _getUrgencyLabel(riskScore.riskLevel),
        lastVisitDate: lastVisit,
        nextDueDate: nextDue,
        reasons: riskScore.riskFactors
            .where((f) => f.score > 30)
            .map((f) => f.description)
            .toList(),
      ));
    }

    // Sort by risk score (highest first)
    priorities.sort(
        (a, b) => b.riskScore.overallScore.compareTo(a.riskScore.overallScore));

    // Assign priority numbers
    for (int i = 0; i < priorities.length; i++) {
      priorities[i] = VisitPriority(
        patientId: priorities[i].patientId,
        patientName: priorities[i].patientName,
        priority: i + 1,
        riskScore: priorities[i].riskScore,
        urgencyLabel: priorities[i].urgencyLabel,
        lastVisitDate: priorities[i].lastVisitDate,
        nextDueDate: priorities[i].nextDueDate,
        reasons: priorities[i].reasons,
      );
    }

    return priorities;
  }

  /// Get today's priority visits (critical and high risk)
  Future<List<VisitPriority>> getTodaysPriorityVisits(String chwId) async {
    final allPriorities = await getPrioritizedVisitList(chwId);
    return allPriorities
        .where((p) =>
            p.riskScore.riskLevel == RiskLevel.critical ||
            p.riskScore.riskLevel == RiskLevel.high)
        .toList();
  }

  // ========== Risk Factor Calculations ==========

  RiskFactor _calculateVisitHistoryRisk(Patient patient, List<Visit> visits) {
    double score = 0;
    String description = 'Visit history normal';

    if (visits.isEmpty) {
      score = 60;
      description = 'No previous visits recorded';
    } else {
      final lastVisit = visits.first;
      final daysSinceVisit =
          DateTime.now().difference(lastVisit.visitDate).inDays;

      if (daysSinceVisit > 90) {
        score = 70;
        description = 'No visit in over 3 months';
      } else if (daysSinceVisit > 60) {
        score = 50;
        description = 'No visit in over 2 months';
      } else if (daysSinceVisit > 30) {
        score = 30;
        description = 'Last visit over 1 month ago';
      }

      // Check for missed follow-ups
      final missedFollowups = visits
          .where((v) =>
              v.followUpDate != null &&
              !v.followUpCompleted &&
              v.followUpDate!.isBefore(DateTime.now()))
          .length;

      if (missedFollowups > 0) {
        score += missedFollowups * 15;
        description = 'Missed $missedFollowups follow-up visits';
      }
    }

    return RiskFactor(
      name: 'Visit History',
      description: description,
      weight: 0.2,
      score: score.clamp(0, 100),
      category: RiskFactorCategory.visitHistory,
    );
  }

  RiskFactor _calculateChronicConditionRisk(Patient patient) {
    double score = 0;
    String description = 'No chronic conditions';

    if (patient.hasChronicCondition == true) {
      score = 50;
      description = 'Has chronic condition';

      final conditions = patient.chronicConditions?.toLowerCase() ?? '';

      // Higher risk for certain conditions
      if (conditions.contains('diabetes')) {
        score += 15;
        description = 'Diabetes requires monitoring';
      }
      if (conditions.contains('hypertension') ||
          conditions.contains('blood pressure')) {
        score += 15;
        description = 'Hypertension requires monitoring';
      }
      if (conditions.contains('hiv') || conditions.contains('aids')) {
        score += 20;
        description = 'HIV/AIDS requires close monitoring';
      }
      if (conditions.contains('tb') || conditions.contains('tuberculosis')) {
        score += 25;
        description = 'TB requires treatment adherence monitoring';
      }
    }

    return RiskFactor(
      name: 'Chronic Conditions',
      description: description,
      weight: 0.25,
      score: score.clamp(0, 100),
      category: RiskFactorCategory.chronicCondition,
    );
  }

  RiskFactor _calculatePregnancyRisk(Patient patient, List<Visit> visits) {
    double score = 0;
    String description = 'Not pregnant or not applicable';

    if (patient.isPregnant == true) {
      score = 40;
      description = 'Pregnancy requires regular monitoring';

      // Check for high-risk pregnancy indicators
      if (patient.isHighRisk) {
        score = 80;
        description = 'High-risk pregnancy - close monitoring needed';
      }

      // Check age risk in pregnancy
      final age = patient.age;
      if (age < 18) {
        score += 20;
        description = 'Adolescent pregnancy - high risk';
      } else if (age > 35) {
        score += 15;
        description = 'Advanced maternal age - increased monitoring';
      }

      // Check recent visit history during pregnancy
      final recentVisits = visits
          .where((v) => DateTime.now().difference(v.visitDate).inDays <= 30)
          .length;

      if (recentVisits == 0) {
        score += 20;
        description += ' - no recent prenatal visit';
      }
    }

    return RiskFactor(
      name: 'Pregnancy Status',
      description: description,
      weight: 0.2,
      score: score.clamp(0, 100),
      category: RiskFactorCategory.pregnancy,
    );
  }

  RiskFactor _calculateAgeRisk(Patient patient) {
    double score = 0;
    String description = 'Age-appropriate care';

    final age = patient.age;

    if (age < 1) {
      score = 60;
      description = 'Infant - requires frequent monitoring';
    } else if (age < 5) {
      score = 45;
      description = 'Under-5 child - growth monitoring needed';
    } else if (age < 18) {
      score = 20;
      description = 'Child/Adolescent';
    } else if (age > 65) {
      score = 50;
      description = 'Elderly - increased health vulnerability';
    } else if (age > 50) {
      score = 30;
      description = 'Middle-aged - preventive screening recommended';
    }

    return RiskFactor(
      name: 'Age Factor',
      description: description,
      weight: 0.1,
      score: score,
      category: RiskFactorCategory.age,
    );
  }

  RiskFactor _calculateSymptomRisk(List<Visit> visits) {
    double score = 0;
    String description = 'No concerning symptoms';

    if (visits.isEmpty) {
      return RiskFactor(
        name: 'Symptom History',
        description: description,
        weight: 0.15,
        score: score,
        category: RiskFactorCategory.symptoms,
      );
    }

    // Check recent visits for concerning symptoms
    final recentVisits = visits
        .where((v) => DateTime.now().difference(v.visitDate).inDays <= 14)
        .toList();

    for (var visit in recentVisits) {
      final symptoms = visit.symptoms?.toLowerCase() ?? '';
      final urgency = visit.urgencyLevel.toLowerCase();

      // High urgency recent visits
      if (urgency == 'emergency') {
        score += 50;
        description = 'Recent emergency visit';
      } else if (urgency == 'high') {
        score += 30;
        description = 'Recent high-urgency visit';
      }

      // Concerning symptom keywords
      if (symptoms.contains('fever') || symptoms.contains('temperature')) {
        score += 15;
      }
      if (symptoms.contains('breathing') || symptoms.contains('respiratory')) {
        score += 20;
      }
      if (symptoms.contains('blood') || symptoms.contains('bleeding')) {
        score += 25;
      }
      if (symptoms.contains('pain') && symptoms.contains('severe')) {
        score += 20;
      }
      if (symptoms.contains('unconscious') || symptoms.contains('seizure')) {
        score += 40;
      }
    }

    if (score > 0 && description == 'No concerning symptoms') {
      description = 'Recent symptoms require follow-up';
    }

    return RiskFactor(
      name: 'Symptom Severity',
      description: description,
      weight: 0.15,
      score: score.clamp(0, 100),
      category: RiskFactorCategory.symptoms,
    );
  }

  RiskFactor _calculateComplianceRisk(List<Visit> visits) {
    double score = 0;
    String description = 'Good compliance';

    if (visits.isEmpty) {
      return RiskFactor(
        name: 'Treatment Compliance',
        description: 'No visit history to assess',
        weight: 0.1,
        score: 30,
        category: RiskFactorCategory.other,
      );
    }

    // Count completed vs missed follow-ups
    final withFollowup = visits.where((v) => v.followUpDate != null).toList();
    final completed = withFollowup.where((v) => v.followUpCompleted).length;
    final missed = withFollowup
        .where((v) =>
            !v.followUpCompleted && v.followUpDate!.isBefore(DateTime.now()))
        .length;

    if (withFollowup.isNotEmpty) {
      final complianceRate = completed / withFollowup.length;

      if (complianceRate < 0.5) {
        score = 70;
        description = 'Poor follow-up compliance';
      } else if (complianceRate < 0.75) {
        score = 40;
        description = 'Moderate compliance - needs encouragement';
      } else {
        score = 10;
        description = 'Good compliance with follow-ups';
      }
    }

    // Recent missed appointments add to risk
    score += missed * 10;

    return RiskFactor(
      name: 'Treatment Compliance',
      description: description,
      weight: 0.1,
      score: score.clamp(0, 100),
      category: RiskFactorCategory.other,
    );
  }

  // ========== Helper Methods ==========

  RiskLevel _determineRiskLevel(double score) {
    if (score >= 75) return RiskLevel.critical;
    if (score >= 50) return RiskLevel.high;
    if (score >= 25) return RiskLevel.medium;
    return RiskLevel.low;
  }

  String _generateRecommendation(
      RiskLevel level, List<RiskFactor> factors, Patient patient) {
    switch (level) {
      case RiskLevel.critical:
        return 'URGENT: Visit ${patient.firstName} ${patient.lastName} TODAY. Multiple high-risk factors detected.';
      case RiskLevel.high:
        return 'Visit ${patient.firstName} within 24-48 hours. Requires immediate attention.';
      case RiskLevel.medium:
        return 'Schedule a visit to ${patient.firstName} this week. Some concerns need addressing.';
      case RiskLevel.low:
        return '${patient.firstName} is stable. Continue routine follow-up schedule.';
    }
  }

  int _calculateDaysUntilVisit(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return 0; // Today
      case RiskLevel.high:
        return 2; // Within 2 days
      case RiskLevel.medium:
        return 7; // Within a week
      case RiskLevel.low:
        return 30; // Routine monthly
    }
  }

  String _getUrgencyLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.critical:
        return 'Visit Today';
      case RiskLevel.high:
        return 'Visit Soon';
      case RiskLevel.medium:
        return 'This Week';
      case RiskLevel.low:
        return 'Routine';
    }
  }

  DateTime? _calculateNextDueDate(
      HealthRiskScore riskScore, DateTime? lastVisit) {
    if (lastVisit == null) {
      return DateTime.now();
    }

    return DateTime.now()
        .add(Duration(days: riskScore.daysUntilNextRecommendedVisit));
  }
}
