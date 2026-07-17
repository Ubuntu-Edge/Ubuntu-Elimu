/// Dashboard API Service
/// Handles dashboard data aggregation and statistics
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
///
/// Endpoints:
/// GET /dashboard/summary - Dashboard summary for CHW
/// GET /dashboard/overview - Overview (supervisor/admin only)
/// GET /dashboard/chw-performance - CHW performance metrics
/// GET /dashboard/disease-stats - Disease statistics
/// GET /dashboard/alerts - Active alerts
/// GET /dashboard/community-summaries - Community health summaries
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Period Enum for performance filtering
enum DashboardPeriod { week, month, quarter, year }

/// Alert Severity Enum
enum AlertSeverity { info, low, medium, high, critical }

/// Dashboard Summary Model
class DashboardSummary {
  final int totalPatients;
  final int todayVisits;
  final int weekVisits;
  final int monthVisits;
  final int pendingFollowups;
  final int activeReferrals;
  final int newRegistrations;
  final int criticalAlerts;
  final Map<String, int> visitsByType;
  final Map<String, int> patientsByStatus;
  final DateTime generatedAt;

  DashboardSummary({
    required this.totalPatients,
    required this.todayVisits,
    required this.weekVisits,
    required this.monthVisits,
    required this.pendingFollowups,
    required this.activeReferrals,
    required this.newRegistrations,
    required this.criticalAlerts,
    required this.visitsByType,
    required this.patientsByStatus,
    required this.generatedAt,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalPatients: json['total_patients'] ?? 0,
      todayVisits: json['today_visits'] ?? 0,
      weekVisits: json['week_visits'] ?? 0,
      monthVisits: json['month_visits'] ?? 0,
      pendingFollowups: json['pending_followups'] ?? 0,
      activeReferrals: json['active_referrals'] ?? 0,
      newRegistrations: json['new_registrations'] ?? 0,
      criticalAlerts: json['critical_alerts'] ?? 0,
      visitsByType: Map<String, int>.from(json['visits_by_type'] ?? {}),
      patientsByStatus: Map<String, int>.from(json['patients_by_status'] ?? {}),
      generatedAt:
          DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Performance Metrics Model
class PerformanceMetrics {
  final double visitCompletionRate;
  final double followupCompletionRate;
  final double patientSatisfaction;
  final int totalWorkingDays;
  final int activeDays;
  final double averageVisitsPerDay;
  final Map<String, dynamic> monthlyTrends;
  final DateTime periodStart;
  final DateTime periodEnd;

  PerformanceMetrics({
    required this.visitCompletionRate,
    required this.followupCompletionRate,
    required this.patientSatisfaction,
    required this.totalWorkingDays,
    required this.activeDays,
    required this.averageVisitsPerDay,
    required this.monthlyTrends,
    required this.periodStart,
    required this.periodEnd,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      visitCompletionRate: (json['visit_completion_rate'] ?? 0).toDouble(),
      followupCompletionRate:
          (json['followup_completion_rate'] ?? 0).toDouble(),
      patientSatisfaction: (json['patient_satisfaction'] ?? 0).toDouble(),
      totalWorkingDays: json['total_working_days'] ?? 0,
      activeDays: json['active_days'] ?? 0,
      averageVisitsPerDay: (json['average_visits_per_day'] ?? 0).toDouble(),
      monthlyTrends: Map<String, dynamic>.from(json['monthly_trends'] ?? {}),
      periodStart:
          DateTime.tryParse(json['period_start'] ?? '') ?? DateTime.now(),
      periodEnd: DateTime.tryParse(json['period_end'] ?? '') ?? DateTime.now(),
    );
  }

  String get visitCompletionPercentage =>
      '${(visitCompletionRate * 100).toInt()}%';
  String get followupCompletionPercentage =>
      '${(followupCompletionRate * 100).toInt()}%';
  String get patientSatisfactionPercentage =>
      '${(patientSatisfaction * 100).toInt()}%';
}

/// Activity Timeline Item
class ActivityTimelineItem {
  final String id;
  final String type; // visit, referral, followup, alert, registration
  final String title;
  final String? description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ActivityTimelineItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityTimelineItem.fromJson(Map<String, dynamic> json) {
    return ActivityTimelineItem(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'visit':
        return 'Visit';
      case 'referral':
        return 'Referral';
      case 'followup':
        return 'Follow-up';
      case 'alert':
        return 'Alert';
      case 'registration':
        return 'Registration';
      default:
        return type;
    }
  }
}

/// Quick Stats Model
class QuickStats {
  final String label;
  final int value;
  final String? trend; // up, down, stable
  final double? changePercentage;

  QuickStats({
    required this.label,
    required this.value,
    this.trend,
    this.changePercentage,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      label: json['label'] ?? '',
      value: json['value'] ?? 0,
      trend: json['trend'],
      changePercentage: json['change_percentage']?.toDouble(),
    );
  }

  bool get isTrendingUp => trend?.toLowerCase() == 'up';
  bool get isTrendingDown => trend?.toLowerCase() == 'down';
  String get formattedChange => changePercentage != null
      ? '${changePercentage!.abs().toStringAsFixed(1)}%'
      : '';
}

/// Dashboard Overview Model - For supervisors/admins
class DashboardOverview {
  final int totalChws;
  final int activeChws;
  final int totalPatients;
  final int todayVisitsTotal;
  final int weekVisitsTotal;
  final int monthVisitsTotal;
  final int pendingFollowupsTotal;
  final int activeReferralsTotal;
  final int criticalAlertsTotal;
  final Map<String, int> chwsByRegion;
  final Map<String, int> patientsByRegion;
  final DateTime generatedAt;

  DashboardOverview({
    required this.totalChws,
    required this.activeChws,
    required this.totalPatients,
    required this.todayVisitsTotal,
    required this.weekVisitsTotal,
    required this.monthVisitsTotal,
    required this.pendingFollowupsTotal,
    required this.activeReferralsTotal,
    required this.criticalAlertsTotal,
    required this.chwsByRegion,
    required this.patientsByRegion,
    required this.generatedAt,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      totalChws: json['total_chws'] ?? 0,
      activeChws: json['active_chws'] ?? 0,
      totalPatients: json['total_patients'] ?? 0,
      todayVisitsTotal: json['today_visits_total'] ?? 0,
      weekVisitsTotal: json['week_visits_total'] ?? 0,
      monthVisitsTotal: json['month_visits_total'] ?? 0,
      pendingFollowupsTotal: json['pending_followups_total'] ?? 0,
      activeReferralsTotal: json['active_referrals_total'] ?? 0,
      criticalAlertsTotal: json['critical_alerts_total'] ?? 0,
      chwsByRegion: Map<String, int>.from(json['chws_by_region'] ?? {}),
      patientsByRegion: Map<String, int>.from(json['patients_by_region'] ?? {}),
      generatedAt:
          DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// CHW Performance Model
class ChwPerformance {
  final String chwId;
  final String chwName;
  final DashboardPeriod period;
  final int totalVisits;
  final int completedFollowups;
  final int missedFollowups;
  final double followupCompletionRate;
  final int referralsMade;
  final int patientsServed;
  final double averageVisitsPerDay;
  final int rank;
  final DateTime periodStart;
  final DateTime periodEnd;

  ChwPerformance({
    required this.chwId,
    required this.chwName,
    required this.period,
    required this.totalVisits,
    required this.completedFollowups,
    required this.missedFollowups,
    required this.followupCompletionRate,
    required this.referralsMade,
    required this.patientsServed,
    required this.averageVisitsPerDay,
    required this.rank,
    required this.periodStart,
    required this.periodEnd,
  });

  factory ChwPerformance.fromJson(Map<String, dynamic> json) {
    return ChwPerformance(
      chwId: json['chw_id'] ?? '',
      chwName: json['chw_name'] ?? '',
      period: _parsePeriod(json['period']),
      totalVisits: json['total_visits'] ?? 0,
      completedFollowups: json['completed_followups'] ?? 0,
      missedFollowups: json['missed_followups'] ?? 0,
      followupCompletionRate:
          (json['followup_completion_rate'] ?? 0).toDouble(),
      referralsMade: json['referrals_made'] ?? 0,
      patientsServed: json['patients_served'] ?? 0,
      averageVisitsPerDay: (json['average_visits_per_day'] ?? 0).toDouble(),
      rank: json['rank'] ?? 0,
      periodStart:
          DateTime.tryParse(json['period_start'] ?? '') ?? DateTime.now(),
      periodEnd: DateTime.tryParse(json['period_end'] ?? '') ?? DateTime.now(),
    );
  }

  static DashboardPeriod _parsePeriod(String? period) {
    switch (period?.toLowerCase()) {
      case 'week':
        return DashboardPeriod.week;
      case 'month':
        return DashboardPeriod.month;
      case 'quarter':
        return DashboardPeriod.quarter;
      case 'year':
        return DashboardPeriod.year;
      default:
        return DashboardPeriod.month;
    }
  }

  String get followupCompletionPercentage =>
      '${(followupCompletionRate * 100).toInt()}%';
}

/// Disease Statistics Model
class DiseaseStats {
  final String diseaseCode;
  final String diseaseName;
  final int totalCases;
  final int newCases;
  final int activeCases;
  final int recoveredCases;
  final int deaths;
  final String? area;
  final DashboardPeriod period;
  final Map<String, int> casesByAge;
  final Map<String, int> casesByGender;
  final DateTime generatedAt;

  DiseaseStats({
    required this.diseaseCode,
    required this.diseaseName,
    required this.totalCases,
    required this.newCases,
    required this.activeCases,
    required this.recoveredCases,
    required this.deaths,
    this.area,
    required this.period,
    required this.casesByAge,
    required this.casesByGender,
    required this.generatedAt,
  });

  factory DiseaseStats.fromJson(Map<String, dynamic> json) {
    return DiseaseStats(
      diseaseCode: json['disease_code'] ?? '',
      diseaseName: json['disease_name'] ?? '',
      totalCases: json['total_cases'] ?? 0,
      newCases: json['new_cases'] ?? 0,
      activeCases: json['active_cases'] ?? 0,
      recoveredCases: json['recovered_cases'] ?? 0,
      deaths: json['deaths'] ?? 0,
      area: json['area'],
      period: ChwPerformance._parsePeriod(json['period']),
      casesByAge: Map<String, int>.from(json['cases_by_age'] ?? {}),
      casesByGender: Map<String, int>.from(json['cases_by_gender'] ?? {}),
      generatedAt:
          DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Dashboard Alert Model
class DashboardAlert {
  final String id;
  final String alertType;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? area;
  final String? chwId;
  final bool isRead;
  final bool isResolved;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  DashboardAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    this.area,
    this.chwId,
    required this.isRead,
    required this.isResolved,
    required this.createdAt,
    this.resolvedAt,
  });

  factory DashboardAlert.fromJson(Map<String, dynamic> json) {
    return DashboardAlert(
      id: json['id'] ?? '',
      alertType: json['alert_type'] ?? '',
      severity: _parseSeverity(json['severity']),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      area: json['area'],
      chwId: json['chw_id'],
      isRead: json['is_read'] ?? false,
      isResolved: json['is_resolved'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'])
          : null,
    );
  }

  static AlertSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'info':
        return AlertSeverity.info;
      case 'low':
        return AlertSeverity.low;
      case 'medium':
        return AlertSeverity.medium;
      case 'high':
        return AlertSeverity.high;
      case 'critical':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.medium;
    }
  }

  String get severityLabel {
    switch (severity) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }
}

/// Community Summary Model
class CommunitySummary {
  final String villageName;
  final String? villageId;
  final int totalHouseholds;
  final int totalPopulation;
  final int registeredPatients;
  final int activePatients;
  final int highRiskPatients;
  final int pendingFollowups;
  final int todayVisits;
  final double vaccinationCoverage;
  final double healthScore;
  final DateTime generatedAt;

  CommunitySummary({
    required this.villageName,
    this.villageId,
    required this.totalHouseholds,
    required this.totalPopulation,
    required this.registeredPatients,
    required this.activePatients,
    required this.highRiskPatients,
    required this.pendingFollowups,
    required this.todayVisits,
    required this.vaccinationCoverage,
    required this.healthScore,
    required this.generatedAt,
  });

  factory CommunitySummary.fromJson(Map<String, dynamic> json) {
    return CommunitySummary(
      villageName: json['village_name'] ?? '',
      villageId: json['village_id'],
      totalHouseholds: json['total_households'] ?? 0,
      totalPopulation: json['total_population'] ?? 0,
      registeredPatients: json['registered_patients'] ?? 0,
      activePatients: json['active_patients'] ?? 0,
      highRiskPatients: json['high_risk_patients'] ?? 0,
      pendingFollowups: json['pending_followups'] ?? 0,
      todayVisits: json['today_visits'] ?? 0,
      vaccinationCoverage: (json['vaccination_coverage'] ?? 0).toDouble(),
      healthScore: (json['health_score'] ?? 0).toDouble(),
      generatedAt:
          DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get vaccinationCoveragePercentage =>
      '${(vaccinationCoverage * 100).toInt()}%';
  String get healthScoreLabel => healthScore >= 80
      ? 'Good'
      : healthScore >= 60
          ? 'Fair'
          : 'Needs Attention';
}

/// Dashboard Alert List Response
class DashboardAlertListResponse {
  final bool success;
  final List<DashboardAlert> data;
  final int totalCount;
  final int page;
  final int perPage;

  DashboardAlertListResponse({
    required this.success,
    required this.data,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory DashboardAlertListResponse.fromJson(Map<String, dynamic> json) {
    return DashboardAlertListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => DashboardAlert.fromJson(item))
              .toList() ??
          [],
      totalCount:
          json['pagination']?['total_count'] ?? json['total_count'] ?? 0,
      page: json['pagination']?['page'] ?? json['page'] ?? 1,
      perPage: json['pagination']?['per_page'] ?? json['per_page'] ?? 20,
    );
  }
}

/// Dashboard API Exception
class DashboardApiException implements Exception {
  final String message;
  final int? statusCode;

  DashboardApiException(this.message, {this.statusCode});

  @override
  String toString() => 'DashboardApiException: $message';
}

/// Dashboard API Service
class DashboardApiService {
  static final DashboardApiService instance = DashboardApiService._internal();
  DashboardApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Get dashboard summary
  /// GET /dashboard/summary
  Future<DashboardSummary> getSummary() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/summary'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardSummary.fromJson(data);
      } else if (response.statusCode == 401) {
        throw DashboardApiException('Unauthorized', statusCode: 401);
      } else {
        throw DashboardApiException(
          'Failed to get dashboard summary: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DashboardApiException) rethrow;
      debugPrint('Error getting dashboard summary: $e');
      throw DashboardApiException('Network error: $e');
    }
  }

  /// Get performance metrics
  /// GET /dashboard/performance
  Future<PerformanceMetrics> getPerformance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final uri = Uri.parse('$_baseUrl/dashboard/performance')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PerformanceMetrics.fromJson(data);
      } else if (response.statusCode == 401) {
        throw DashboardApiException('Unauthorized', statusCode: 401);
      } else {
        throw DashboardApiException(
          'Failed to get performance metrics: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DashboardApiException) rethrow;
      debugPrint('Error getting performance metrics: $e');
      throw DashboardApiException('Network error: $e');
    }
  }

  /// Get activity timeline
  /// GET /dashboard/activity
  Future<List<ActivityTimelineItem>> getActivity({
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$_baseUrl/dashboard/activity')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List<dynamic>?)
                ?.map((item) => ActivityTimelineItem.fromJson(item))
                .toList() ??
            [];
      } else if (response.statusCode == 401) {
        throw DashboardApiException('Unauthorized', statusCode: 401);
      } else {
        throw DashboardApiException(
          'Failed to get activity timeline: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DashboardApiException) rethrow;
      debugPrint('Error getting activity timeline: $e');
      throw DashboardApiException('Network error: $e');
    }
  }

  /// Get quick stats
  /// GET /dashboard/quick-stats
  Future<List<QuickStats>> getQuickStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/quick-stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List<dynamic>?)
                ?.map((item) => QuickStats.fromJson(item))
                .toList() ??
            [];
      } else if (response.statusCode == 401) {
        throw DashboardApiException('Unauthorized', statusCode: 401);
      } else {
        throw DashboardApiException(
          'Failed to get quick stats: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DashboardApiException) rethrow;
      debugPrint('Error getting quick stats: $e');
      throw DashboardApiException('Network error: $e');
    }
  }

  /// Get comprehensive dashboard data
  Future<Map<String, dynamic>> getFullDashboard() async {
    try {
      final summary = await getSummary();
      final performance = await getPerformance();
      final activity = await getActivity();
      final quickStats = await getQuickStats();

      return {
        'summary': summary,
        'performance': performance,
        'activity': activity,
        'quickStats': quickStats,
        'loadedAt': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error getting full dashboard: $e');
      rethrow;
    }
  }

  /// Get weekly summary
  Future<DashboardSummary> getWeeklySummary() async {
    // Same as getSummary for now, backend returns current week data
    return getSummary();
  }

  /// Get monthly performance
  Future<PerformanceMetrics> getMonthlyPerformance() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getPerformance(startDate: startOfMonth, endDate: endOfMonth);
  }

  /// Refresh dashboard cache
  /// POST /dashboard/refresh
  Future<bool> refreshDashboard() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/dashboard/refresh'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw DashboardApiException('Unauthorized', statusCode: 401);
      } else {
        throw DashboardApiException(
          'Failed to refresh dashboard: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DashboardApiException) rethrow;
      debugPrint('Error refreshing dashboard: $e');
      throw DashboardApiException('Network error: $e');
    }
  }

  // ============ NEW ENDPOINTS ============

  /// Get dashboard overview (supervisor/admin only)
  /// GET /dashboard/overview
  Future<DashboardOverview> getOverview() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/overview'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardOverview.fromJson(data);
      } else if (response.statusCode == 401) {
        throw DashboardApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 403) {
        throw DashboardApiException(
            'Forbidden - Supervisor/Admin access required',
            statusCode: 403);
      } else {
        throw DashboardApiException(
          'Failed to get dashboard overview: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DashboardApiException) rethrow;
      debugPrint('Error getting dashboard overview: $e');
      throw DashboardApiException('Network error: $e');
    }
  }

  /// Get CHW performance
  /// GET /dashboard/chw-performance
  /// Query params: period (week/month/quarter/year)
  Future<ChwPerformance> getChwPerformance({
    DashboardPeriod period = DashboardPeriod.month,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'period': _getPeriodString(period),
      };

      final uri = Uri.parse('$_baseUrl/dashboard/chw-performance')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChwPerformance.fromJson(data);
      } else if (response.statusCode == 401) {
        throw DashboardApiException('Unauthorized', statusCode: 401);
      } else {
        throw DashboardApiException(
          'Failed to get CHW performance: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DashboardApiException) rethrow;
      debugPrint('Error getting CHW performance: $e');
      throw DashboardApiException('Network error: $e');
    }
  }

  /// Get disease statistics
  /// GET /dashboard/disease-stats
  /// Query params: area (optional), period (optional)
  Future<List<DiseaseStats>> getDiseaseStats({
    String? area,
    DashboardPeriod period = DashboardPeriod.month,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'period': _getPeriodString(period),
      };
      if (area != null) queryParams['area'] = area;

      final uri = Uri.parse('$_baseUrl/dashboard/disease-stats')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List<dynamic>?)
                ?.map((item) => DiseaseStats.fromJson(item))
                .toList() ??
            [];
      } else if (response.statusCode == 401) {
        throw DashboardApiException('Unauthorized', statusCode: 401);
      } else {
        throw DashboardApiException(
          'Failed to get disease stats: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DashboardApiException) rethrow;
      debugPrint('Error getting disease stats: $e');
      throw DashboardApiException('Network error: $e');
    }
  }

  /// Get active alerts
  /// GET /dashboard/alerts
  /// Query params: severity (optional), alert_type (optional), page, per_page
  Future<DashboardAlertListResponse> getAlerts({
    AlertSeverity? severity,
    String? alertType,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (severity != null)
        queryParams['severity'] = _getSeverityString(severity);
      if (alertType != null) queryParams['alert_type'] = alertType;

      final uri = Uri.parse('$_baseUrl/dashboard/alerts')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardAlertListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw DashboardApiException('Unauthorized', statusCode: 401);
      } else {
        throw DashboardApiException(
          'Failed to get alerts: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DashboardApiException) rethrow;
      debugPrint('Error getting alerts: $e');
      throw DashboardApiException('Network error: $e');
    }
  }

  /// Get community health summaries
  /// GET /dashboard/community-summaries
  Future<List<CommunitySummary>> getCommunitySummaries() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/community-summaries'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List<dynamic>?)
                ?.map((item) => CommunitySummary.fromJson(item))
                .toList() ??
            [];
      } else if (response.statusCode == 401) {
        throw DashboardApiException('Unauthorized', statusCode: 401);
      } else {
        throw DashboardApiException(
          'Failed to get community summaries: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DashboardApiException) rethrow;
      debugPrint('Error getting community summaries: $e');
      throw DashboardApiException('Network error: $e');
    }
  }

  // ============ HELPER METHODS ============

  String _getPeriodString(DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.week:
        return 'week';
      case DashboardPeriod.month:
        return 'month';
      case DashboardPeriod.quarter:
        return 'quarter';
      case DashboardPeriod.year:
        return 'year';
    }
  }

  String _getSeverityString(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return 'info';
      case AlertSeverity.low:
        return 'low';
      case AlertSeverity.medium:
        return 'medium';
      case AlertSeverity.high:
        return 'high';
      case AlertSeverity.critical:
        return 'critical';
    }
  }
}
