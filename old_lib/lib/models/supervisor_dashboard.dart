// Supervisor Dashboard Model
// Implements Health Dashboards for Supervisors & Government
// 
// Features:
// - Aggregated health data across CHWs
// - Disease trend analysis
// - CHW performance metrics
// - Resource allocation insights

class SupervisorDashboard {
  final String supervisorId;
  final DateTime reportDate;
  final OverviewStats overview;
  final List<CHWPerformanceMetrics> chwPerformance;
  final List<DiseaseStats> diseaseStats;
  final List<CommunityHealthSummary> communitySummaries;
  final List<ResourceNeed> resourceNeeds;
  final List<Alert> activeAlerts;

  SupervisorDashboard({
    required this.supervisorId,
    required this.reportDate,
    required this.overview,
    required this.chwPerformance,
    required this.diseaseStats,
    required this.communitySummaries,
    required this.resourceNeeds,
    required this.activeAlerts,
  });

  Map<String, dynamic> toMap() {
    return {
      'supervisorId': supervisorId,
      'reportDate': reportDate.toIso8601String(),
      'overview': overview.toMap(),
      'chwPerformance': chwPerformance.map((c) => c.toMap()).toList(),
      'diseaseStats': diseaseStats.map((d) => d.toMap()).toList(),
      'communitySummaries': communitySummaries.map((c) => c.toMap()).toList(),
      'resourceNeeds': resourceNeeds.map((r) => r.toMap()).toList(),
      'activeAlerts': activeAlerts.map((a) => a.toMap()).toList(),
    };
  }
}

/// High-level overview statistics
class OverviewStats {
  final int totalPatients;
  final int totalCHWs;
  final int totalVisitsThisMonth;
  final int totalReferrals;
  final int pendingFollowUps;
  final int highRiskPatients;
  final int outbreakAlerts;
  final double averagePatientsPerCHW;
  final double visitGrowthRate; // % change from last month

  OverviewStats({
    required this.totalPatients,
    required this.totalCHWs,
    required this.totalVisitsThisMonth,
    required this.totalReferrals,
    required this.pendingFollowUps,
    required this.highRiskPatients,
    required this.outbreakAlerts,
    required this.averagePatientsPerCHW,
    required this.visitGrowthRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalPatients': totalPatients,
      'totalCHWs': totalCHWs,
      'totalVisitsThisMonth': totalVisitsThisMonth,
      'totalReferrals': totalReferrals,
      'pendingFollowUps': pendingFollowUps,
      'highRiskPatients': highRiskPatients,
      'outbreakAlerts': outbreakAlerts,
      'averagePatientsPerCHW': averagePatientsPerCHW,
      'visitGrowthRate': visitGrowthRate,
    };
  }

  factory OverviewStats.fromMap(Map<String, dynamic> map) {
    return OverviewStats(
      totalPatients: map['totalPatients'],
      totalCHWs: map['totalCHWs'],
      totalVisitsThisMonth: map['totalVisitsThisMonth'],
      totalReferrals: map['totalReferrals'],
      pendingFollowUps: map['pendingFollowUps'],
      highRiskPatients: map['highRiskPatients'],
      outbreakAlerts: map['outbreakAlerts'],
      averagePatientsPerCHW: (map['averagePatientsPerCHW'] as num).toDouble(),
      visitGrowthRate: (map['visitGrowthRate'] as num).toDouble(),
    );
  }
}

/// Individual CHW performance metrics
class CHWPerformanceMetrics {
  final String chwId;
  final String chwName;
  final String village;
  final int patientsAssigned;
  final int visitsThisMonth;
  final int highRiskPatientsManaged;
  final int referralsMade;
  final double followUpCompletionRate;
  final double patientSatisfactionScore;
  final int trainingModulesCompleted;
  final PerformanceRating overallRating;
  final List<String> strengths;
  final List<String> areasForImprovement;

  CHWPerformanceMetrics({
    required this.chwId,
    required this.chwName,
    required this.village,
    required this.patientsAssigned,
    required this.visitsThisMonth,
    required this.highRiskPatientsManaged,
    required this.referralsMade,
    required this.followUpCompletionRate,
    required this.patientSatisfactionScore,
    required this.trainingModulesCompleted,
    required this.overallRating,
    required this.strengths,
    required this.areasForImprovement,
  });

  Map<String, dynamic> toMap() {
    return {
      'chwId': chwId,
      'chwName': chwName,
      'village': village,
      'patientsAssigned': patientsAssigned,
      'visitsThisMonth': visitsThisMonth,
      'highRiskPatientsManaged': highRiskPatientsManaged,
      'referralsMade': referralsMade,
      'followUpCompletionRate': followUpCompletionRate,
      'patientSatisfactionScore': patientSatisfactionScore,
      'trainingModulesCompleted': trainingModulesCompleted,
      'overallRating': overallRating.name,
      'strengths': strengths,
      'areasForImprovement': areasForImprovement,
    };
  }

  factory CHWPerformanceMetrics.fromMap(Map<String, dynamic> map) {
    return CHWPerformanceMetrics(
      chwId: map['chwId'],
      chwName: map['chwName'],
      village: map['village'],
      patientsAssigned: map['patientsAssigned'],
      visitsThisMonth: map['visitsThisMonth'],
      highRiskPatientsManaged: map['highRiskPatientsManaged'],
      referralsMade: map['referralsMade'],
      followUpCompletionRate: (map['followUpCompletionRate'] as num).toDouble(),
      patientSatisfactionScore: (map['patientSatisfactionScore'] as num).toDouble(),
      trainingModulesCompleted: map['trainingModulesCompleted'],
      overallRating: PerformanceRating.values.firstWhere(
        (e) => e.name == map['overallRating'],
        orElse: () => PerformanceRating.average,
      ),
      strengths: List<String>.from(map['strengths']),
      areasForImprovement: List<String>.from(map['areasForImprovement']),
    );
  }
}

enum PerformanceRating {
  excellent,
  good,
  average,
  needsImprovement,
  critical,
}

/// Disease statistics for a region
class DiseaseStats {
  final String disease;
  final int totalCases;
  final int newCasesThisWeek;
  final int newCasesThisMonth;
  final double growthRate;
  final List<String> affectedVillages;
  final String trend; // increasing, stable, decreasing
  final bool isOutbreak;

  DiseaseStats({
    required this.disease,
    required this.totalCases,
    required this.newCasesThisWeek,
    required this.newCasesThisMonth,
    required this.growthRate,
    required this.affectedVillages,
    required this.trend,
    required this.isOutbreak,
  });

  Map<String, dynamic> toMap() {
    return {
      'disease': disease,
      'totalCases': totalCases,
      'newCasesThisWeek': newCasesThisWeek,
      'newCasesThisMonth': newCasesThisMonth,
      'growthRate': growthRate,
      'affectedVillages': affectedVillages,
      'trend': trend,
      'isOutbreak': isOutbreak,
    };
  }

  factory DiseaseStats.fromMap(Map<String, dynamic> map) {
    return DiseaseStats(
      disease: map['disease'],
      totalCases: map['totalCases'],
      newCasesThisWeek: map['newCasesThisWeek'],
      newCasesThisMonth: map['newCasesThisMonth'],
      growthRate: (map['growthRate'] as num).toDouble(),
      affectedVillages: List<String>.from(map['affectedVillages']),
      trend: map['trend'],
      isOutbreak: map['isOutbreak'],
    );
  }
}

/// Community-level health summary
class CommunityHealthSummary {
  final String village;
  final int population;
  final int registeredPatients;
  final double healthScore;
  final List<String> topHealthConcerns;
  final int activeOutbreaks;
  final String assignedCHW;
  final DateTime lastVisitDate;

  CommunityHealthSummary({
    required this.village,
    required this.population,
    required this.registeredPatients,
    required this.healthScore,
    required this.topHealthConcerns,
    required this.activeOutbreaks,
    required this.assignedCHW,
    required this.lastVisitDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'village': village,
      'population': population,
      'registeredPatients': registeredPatients,
      'healthScore': healthScore,
      'topHealthConcerns': topHealthConcerns,
      'activeOutbreaks': activeOutbreaks,
      'assignedCHW': assignedCHW,
      'lastVisitDate': lastVisitDate.toIso8601String(),
    };
  }

  factory CommunityHealthSummary.fromMap(Map<String, dynamic> map) {
    return CommunityHealthSummary(
      village: map['village'],
      population: map['population'],
      registeredPatients: map['registeredPatients'],
      healthScore: (map['healthScore'] as num).toDouble(),
      topHealthConcerns: List<String>.from(map['topHealthConcerns']),
      activeOutbreaks: map['activeOutbreaks'],
      assignedCHW: map['assignedCHW'],
      lastVisitDate: DateTime.parse(map['lastVisitDate']),
    );
  }
}

/// Resource allocation needs
class ResourceNeed {
  final String resourceType;
  final String location;
  final int quantityNeeded;
  final int currentStock;
  final ResourcePriority priority;
  final String reason;
  final DateTime estimatedNeedDate;

  ResourceNeed({
    required this.resourceType,
    required this.location,
    required this.quantityNeeded,
    required this.currentStock,
    required this.priority,
    required this.reason,
    required this.estimatedNeedDate,
  });

  int get deficit => quantityNeeded - currentStock;

  Map<String, dynamic> toMap() {
    return {
      'resourceType': resourceType,
      'location': location,
      'quantityNeeded': quantityNeeded,
      'currentStock': currentStock,
      'priority': priority.name,
      'reason': reason,
      'estimatedNeedDate': estimatedNeedDate.toIso8601String(),
    };
  }

  factory ResourceNeed.fromMap(Map<String, dynamic> map) {
    return ResourceNeed(
      resourceType: map['resourceType'],
      location: map['location'],
      quantityNeeded: map['quantityNeeded'],
      currentStock: map['currentStock'],
      priority: ResourcePriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => ResourcePriority.medium,
      ),
      reason: map['reason'],
      estimatedNeedDate: DateTime.parse(map['estimatedNeedDate']),
    );
  }
}

enum ResourcePriority {
  critical,
  high,
  medium,
  low,
}

/// Alert for supervisors
class Alert {
  final String id;
  final String title;
  final String description;
  final AlertCategory category;
  final AlertSeverity severity;
  final String? location;
  final String? chwId;
  final DateTime createdAt;
  final bool isRead;
  final bool isResolved;

  Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    this.location,
    this.chwId,
    required this.createdAt,
    this.isRead = false,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'severity': severity.name,
      'location': location,
      'chwId': chwId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isResolved': isResolved,
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: AlertCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => AlertCategory.general,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => AlertSeverity.info,
      ),
      location: map['location'],
      chwId: map['chwId'],
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
      isResolved: map['isResolved'] ?? false,
    );
  }
}

enum AlertCategory {
  outbreak,
  resourceShortage,
  chwPerformance,
  patientEmergency,
  systemIssue,
  general,
}

enum AlertSeverity {
  critical,
  warning,
  info,
}

/// Time-series data for charts
class TimeSeriesData {
  final DateTime date;
  final double value;
  final String? label;

  TimeSeriesData({
    required this.date,
    required this.value,
    this.label,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'label': label,
    };
  }

  factory TimeSeriesData.fromMap(Map<String, dynamic> map) {
    return TimeSeriesData(
      date: DateTime.parse(map['date']),
      value: (map['value'] as num).toDouble(),
      label: map['label'],
    );
  }
}

/// Report generation settings
class ReportSettings {
  final ReportPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> includedVillages;
  final List<String> includedCHWs;
  final bool includePatientDetails;
  final bool includeDiseaseBreakdown;
  final bool includeCHWPerformance;
  final ReportFormat format;

  ReportSettings({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.includedVillages,
    required this.includedCHWs,
    this.includePatientDetails = true,
    this.includeDiseaseBreakdown = true,
    this.includeCHWPerformance = true,
    this.format = ReportFormat.pdf,
  });

  Map<String, dynamic> toMap() {
    return {
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'includedVillages': includedVillages,
      'includedCHWs': includedCHWs,
      'includePatientDetails': includePatientDetails,
      'includeDiseaseBreakdown': includeDiseaseBreakdown,
      'includeCHWPerformance': includeCHWPerformance,
      'format': format.name,
    };
  }
}

enum ReportPeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

enum ReportFormat {
  pdf,
  excel,
  csv,
}
