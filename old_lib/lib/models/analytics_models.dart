/// Analytics API Models
/// Models for analytics operations with backend API
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

/// Response model for analytics summary (GET /analytics/summary)
class AnalyticsSummaryResponse {
  final String userId;
  final String periodStart;
  final String periodEnd;
  final int totalPatients;
  final int newPatients;
  final int highRiskPatients;
  final int pregnantPatients;
  final int childrenUnder5;
  final int totalVisits;
  final int homeVisits;
  final int followUpVisits;
  final int emergencyVisits;
  final double avgVisitsPerDay;
  final int totalReferrals;
  final int pendingReferrals;
  final int completedReferrals;
  final double referralCompletionRate;
  final int pendingFollowUps;
  final int completedFollowUps;
  final int overdueFollowUps;
  final double followUpCompletionRate;
  final int pendingReminders;
  final int completedReminders;
  final int overdueReminders;

  AnalyticsSummaryResponse({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalPatients,
    required this.newPatients,
    required this.highRiskPatients,
    required this.pregnantPatients,
    required this.childrenUnder5,
    required this.totalVisits,
    required this.homeVisits,
    required this.followUpVisits,
    required this.emergencyVisits,
    required this.avgVisitsPerDay,
    required this.totalReferrals,
    required this.pendingReferrals,
    required this.completedReferrals,
    required this.referralCompletionRate,
    required this.pendingFollowUps,
    required this.completedFollowUps,
    required this.overdueFollowUps,
    required this.followUpCompletionRate,
    required this.pendingReminders,
    required this.completedReminders,
    required this.overdueReminders,
  });

  factory AnalyticsSummaryResponse.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummaryResponse(
      userId: json['user_id'] ?? '',
      periodStart: json['period_start'] ?? '',
      periodEnd: json['period_end'] ?? '',
      totalPatients: json['total_patients'] ?? 0,
      newPatients: json['new_patients'] ?? 0,
      highRiskPatients: json['high_risk_patients'] ?? 0,
      pregnantPatients: json['pregnant_patients'] ?? 0,
      childrenUnder5: json['children_under_5'] ?? 0,
      totalVisits: json['total_visits'] ?? 0,
      homeVisits: json['home_visits'] ?? 0,
      followUpVisits: json['follow_up_visits'] ?? 0,
      emergencyVisits: json['emergency_visits'] ?? 0,
      avgVisitsPerDay: (json['avg_visits_per_day'] ?? 0).toDouble(),
      totalReferrals: json['total_referrals'] ?? 0,
      pendingReferrals: json['pending_referrals'] ?? 0,
      completedReferrals: json['completed_referrals'] ?? 0,
      referralCompletionRate:
          (json['referral_completion_rate'] ?? 0).toDouble(),
      pendingFollowUps: json['pending_follow_ups'] ?? 0,
      completedFollowUps: json['completed_follow_ups'] ?? 0,
      overdueFollowUps: json['overdue_follow_ups'] ?? 0,
      followUpCompletionRate:
          (json['follow_up_completion_rate'] ?? 0).toDouble(),
      pendingReminders: json['pending_reminders'] ?? 0,
      completedReminders: json['completed_reminders'] ?? 0,
      overdueReminders: json['overdue_reminders'] ?? 0,
    );
  }
}

/// Response model for performance metrics (GET /analytics/performance)
class PerformanceMetricsResponse {
  final String userId;
  final String periodStart;
  final String periodEnd;
  final int totalWorkingDays;
  final double avgVisitsPerDay;
  final double avgPatientsRegisteredPerWeek;
  final double followUpCompletionRate;
  final double referralCompletionRate;
  final double documentationCompleteness;
  final double avgEmergencyResponseTimeMinutes;
  final double avgReferralProcessingTimeHours;
  final int trainingModulesCompleted;
  final double trainingCompletionPercentage;
  final int rankInRegion;
  final int totalChwsInRegion;

  PerformanceMetricsResponse({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalWorkingDays,
    required this.avgVisitsPerDay,
    required this.avgPatientsRegisteredPerWeek,
    required this.followUpCompletionRate,
    required this.referralCompletionRate,
    required this.documentationCompleteness,
    required this.avgEmergencyResponseTimeMinutes,
    required this.avgReferralProcessingTimeHours,
    required this.trainingModulesCompleted,
    required this.trainingCompletionPercentage,
    required this.rankInRegion,
    required this.totalChwsInRegion,
  });

  factory PerformanceMetricsResponse.fromJson(Map<String, dynamic> json) {
    return PerformanceMetricsResponse(
      userId: json['user_id'] ?? '',
      periodStart: json['period_start'] ?? '',
      periodEnd: json['period_end'] ?? '',
      totalWorkingDays: json['total_working_days'] ?? 0,
      avgVisitsPerDay: (json['avg_visits_per_day'] ?? 0).toDouble(),
      avgPatientsRegisteredPerWeek:
          (json['avg_patients_registered_per_week'] ?? 0).toDouble(),
      followUpCompletionRate:
          (json['follow_up_completion_rate'] ?? 0).toDouble(),
      referralCompletionRate:
          (json['referral_completion_rate'] ?? 0).toDouble(),
      documentationCompleteness:
          (json['documentation_completeness'] ?? 0).toDouble(),
      avgEmergencyResponseTimeMinutes:
          (json['avg_emergency_response_time_minutes'] ?? 0).toDouble(),
      avgReferralProcessingTimeHours:
          (json['avg_referral_processing_time_hours'] ?? 0).toDouble(),
      trainingModulesCompleted: json['training_modules_completed'] ?? 0,
      trainingCompletionPercentage:
          (json['training_completion_percentage'] ?? 0).toDouble(),
      rankInRegion: json['rank_in_region'] ?? 0,
      totalChwsInRegion: json['total_chws_in_region'] ?? 0,
    );
  }
}

/// Response model for dashboard overview (supervisors/admins)
/// GET /analytics/dashboard
class DashboardOverviewResponse {
  final String? region;
  final String? healthFacility;
  final String periodStart;
  final String periodEnd;
  final int totalChws;
  final int activeChws;
  final int chwsWithPendingTasks;
  final int totalPatients;
  final int newPatientsThisPeriod;
  final int highRiskPatients;
  final int pregnantPatients;
  final int totalVisits;
  final int emergencyVisits;
  final List<VisitTrendData>? visitsTrend;
  final int totalReferrals;
  final int pendingReferrals;
  final int urgentReferrals;
  final int criticalAlerts;
  final List<OutbreakAlert>? outbreakAlerts;
  final Map<String, dynamic>? diseaseStats;
  final double avgVisitsPerChw;
  final double avgReferralCompletionRate;
  final List<ChwPerformance>? topPerformers;
  final List<ChwPerformance>? needsAttention;
  final Map<String, dynamic>? visitsByType;
  final Map<String, dynamic>? referralsByStatus;

  DashboardOverviewResponse({
    this.region,
    this.healthFacility,
    required this.periodStart,
    required this.periodEnd,
    required this.totalChws,
    required this.activeChws,
    required this.chwsWithPendingTasks,
    required this.totalPatients,
    required this.newPatientsThisPeriod,
    required this.highRiskPatients,
    required this.pregnantPatients,
    required this.totalVisits,
    required this.emergencyVisits,
    this.visitsTrend,
    required this.totalReferrals,
    required this.pendingReferrals,
    required this.urgentReferrals,
    required this.criticalAlerts,
    this.outbreakAlerts,
    this.diseaseStats,
    required this.avgVisitsPerChw,
    required this.avgReferralCompletionRate,
    this.topPerformers,
    this.needsAttention,
    this.visitsByType,
    this.referralsByStatus,
  });

  factory DashboardOverviewResponse.fromJson(Map<String, dynamic> json) {
    return DashboardOverviewResponse(
      region: json['region'],
      healthFacility: json['health_facility'],
      periodStart: json['period_start'] ?? '',
      periodEnd: json['period_end'] ?? '',
      totalChws: json['total_chws'] ?? 0,
      activeChws: json['active_chws'] ?? 0,
      chwsWithPendingTasks: json['chws_with_pending_tasks'] ?? 0,
      totalPatients: json['total_patients'] ?? 0,
      newPatientsThisPeriod:
          json['new_patients_this_period'] ?? json['new_patients'] ?? 0,
      highRiskPatients: json['high_risk_patients'] ?? 0,
      pregnantPatients: json['pregnant_patients'] ?? 0,
      totalVisits: json['total_visits'] ?? 0,
      emergencyVisits: json['emergency_visits'] ?? 0,
      visitsTrend: json['visits_trend'] != null
          ? (json['visits_trend'] as List)
              .map((e) => VisitTrendData.fromJson(e))
              .toList()
          : null,
      totalReferrals: json['total_referrals'] ?? 0,
      pendingReferrals: json['pending_referrals'] ?? 0,
      urgentReferrals: json['urgent_referrals'] ?? 0,
      criticalAlerts: json['critical_alerts'] ?? 0,
      outbreakAlerts: json['outbreak_alerts'] != null
          ? (json['outbreak_alerts'] as List)
              .map((e) => OutbreakAlert.fromJson(e))
              .toList()
          : null,
      diseaseStats: json['disease_stats'],
      avgVisitsPerChw: (json['avg_visits_per_chw'] ?? 0).toDouble(),
      avgReferralCompletionRate:
          (json['avg_referral_completion_rate'] ?? 0).toDouble(),
      topPerformers: json['top_performers'] != null
          ? (json['top_performers'] as List)
              .map((e) => ChwPerformance.fromJson(e))
              .toList()
          : null,
      needsAttention: json['needs_attention'] != null
          ? (json['needs_attention'] as List)
              .map((e) => ChwPerformance.fromJson(e))
              .toList()
          : null,
      visitsByType: json['visits_by_type'],
      referralsByStatus: json['referrals_by_status'],
    );
  }

  // Backwards compatibility getters
  int get newPatients => newPatientsThisPeriod;
}

/// CHW Performance data for dashboard
class ChwPerformance {
  final String id;
  final String name;
  final int totalVisits;
  final int patientsRegistered;
  final double referralCompletionRate;
  final String? lastActive;

  ChwPerformance({
    required this.id,
    required this.name,
    required this.totalVisits,
    required this.patientsRegistered,
    required this.referralCompletionRate,
    this.lastActive,
  });

  factory ChwPerformance.fromJson(Map<String, dynamic> json) {
    return ChwPerformance(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      totalVisits: json['total_visits'] ?? 0,
      patientsRegistered: json['patients_registered'] ?? 0,
      referralCompletionRate:
          (json['referral_completion_rate'] ?? 0).toDouble(),
      lastActive: json['last_active'],
    );
  }
}

/// Visit trend data point for charts
class VisitTrendData {
  final String date;
  final int count;
  final String? type;

  VisitTrendData({
    required this.date,
    required this.count,
    this.type,
  });

  factory VisitTrendData.fromJson(Map<String, dynamic> json) {
    return VisitTrendData(
      date: json['date'] ?? '',
      count: json['count'] ?? 0,
      type: json['type'],
    );
  }
}

/// Outbreak alert data
class OutbreakAlert {
  final String id;
  final String diseaseName;
  final String location;
  final int caseCount;
  final String severity;
  final DateTime reportedAt;

  OutbreakAlert({
    required this.id,
    required this.diseaseName,
    required this.location,
    required this.caseCount,
    required this.severity,
    required this.reportedAt,
  });

  factory OutbreakAlert.fromJson(Map<String, dynamic> json) {
    return OutbreakAlert(
      id: json['id'] ?? '',
      diseaseName: json['disease_name'] ?? '',
      location: json['location'] ?? '',
      caseCount: json['case_count'] ?? 0,
      severity: json['severity'] ?? 'low',
      reportedAt: DateTime.tryParse(json['reported_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Exception for analytics API errors
class AnalyticsApiException implements Exception {
  final String message;
  final int? statusCode;

  AnalyticsApiException(this.message, {this.statusCode});

  @override
  String toString() => 'AnalyticsApiException: $message';
}
