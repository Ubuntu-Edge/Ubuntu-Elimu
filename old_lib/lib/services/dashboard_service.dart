/// Dashboard Service
/// Implements Health Dashboards for Supervisors & Government
///
/// Features:
/// - Aggregated health statistics
/// - CHW performance tracking
/// - Outbreak monitoring
/// - Report generation
library;

import '../models/supervisor_dashboard.dart';
import '../models/patient.dart';
import '../models/health_risk_score.dart';
import 'database_service.dart';
import 'outbreak_detection_service.dart';
import 'risk_scoring_service.dart';

class DashboardService {
  static final DashboardService instance = DashboardService._internal();
  DashboardService._internal();

  // In-memory data for demo
  final List<CHWPerformanceMetrics> _chwMetrics = [];
  final List<Alert> _alerts = [];
  final Map<String, CommunityHealthSummary> _communitySummaries = {};

  /// Get dashboard overview for supervisor
  Future<SupervisorDashboard> getDashboard(String supervisorId) async {
    // Get all patients from database
    List<Patient> allPatients = await _getAllPatients(supervisorId);

    // Calculate overview stats
    OverviewStats overview =
        await _calculateOverviewStats(allPatients, supervisorId);

    // Get CHW performance
    List<CHWPerformanceMetrics> chwPerformance = await _getCHWPerformance();

    // Get disease statistics
    List<DiseaseStats> diseaseStats = await _getDiseaseStats();

    // Get community summaries
    List<CommunityHealthSummary> communities =
        await _getCommunitySummaries(allPatients);

    // Get resource needs
    List<ResourceNeed> resourceNeeds = _getResourceNeeds();

    // Get active alerts
    List<Alert> activeAlerts = _getActiveAlerts();

    return SupervisorDashboard(
      supervisorId: supervisorId,
      reportDate: DateTime.now(),
      overview: overview,
      chwPerformance: chwPerformance,
      diseaseStats: diseaseStats,
      communitySummaries: communities,
      resourceNeeds: resourceNeeds,
      activeAlerts: activeAlerts,
    );
  }

  /// Get all patients (for supervisor view)
  Future<List<Patient>> _getAllPatients(String chwId) async {
    return await DatabaseService.instance.getPatientsByCHW(chwId);
  }

  /// Calculate overview statistics
  Future<OverviewStats> _calculateOverviewStats(
      List<Patient> patients, String chwId) async {
    int totalPatients = patients.length;

    // Count high-risk patients
    int highRiskPatients = 0;
    for (var patient in patients) {
      var riskScore =
          await RiskScoringService.instance.calculateRiskScore(patient);
      if (riskScore.riskLevel == RiskLevel.high ||
          riskScore.riskLevel == RiskLevel.critical) {
        highRiskPatients++;
      }
    }

    // Get outbreak count
    var outbreaks =
        await OutbreakDetectionService.instance.detectOutbreaks(chwId);
    int outbreakAlerts = outbreaks.where((o) => !o.isResolved).length;

    return OverviewStats(
      totalPatients: totalPatients,
      totalCHWs: 5, // Demo value
      totalVisitsThisMonth: patients.length * 2, // Demo calculation
      totalReferrals: (patients.length * 0.1).round(), // Demo
      pendingFollowUps: (patients.length * 0.3).round(), // Demo
      highRiskPatients: highRiskPatients,
      outbreakAlerts: outbreakAlerts,
      averagePatientsPerCHW: totalPatients / 5,
      visitGrowthRate: 12.5, // Demo percentage
    );
  }

  /// Get CHW performance metrics
  Future<List<CHWPerformanceMetrics>> _getCHWPerformance() async {
    // Generate sample CHW data if empty
    if (_chwMetrics.isEmpty) {
      _chwMetrics.addAll(_generateSampleCHWData());
    }
    return _chwMetrics;
  }

  /// Generate sample CHW data for demonstration
  List<CHWPerformanceMetrics> _generateSampleCHWData() {
    return [
      CHWPerformanceMetrics(
        chwId: 'chw_001',
        chwName: 'Mary Wanjiku',
        village: 'Kiambu East',
        patientsAssigned: 85,
        visitsThisMonth: 42,
        highRiskPatientsManaged: 8,
        referralsMade: 5,
        followUpCompletionRate: 92.5,
        patientSatisfactionScore: 4.7,
        trainingModulesCompleted: 12,
        overallRating: PerformanceRating.excellent,
        strengths: [
          'Patient communication',
          'Timely follow-ups',
          'Accurate documentation'
        ],
        areasForImprovement: [],
      ),
      CHWPerformanceMetrics(
        chwId: 'chw_002',
        chwName: 'John Kamau',
        village: 'Kiambu West',
        patientsAssigned: 72,
        visitsThisMonth: 38,
        highRiskPatientsManaged: 6,
        referralsMade: 4,
        followUpCompletionRate: 85.0,
        patientSatisfactionScore: 4.3,
        trainingModulesCompleted: 8,
        overallRating: PerformanceRating.good,
        strengths: ['Emergency response', 'Community engagement'],
        areasForImprovement: ['Documentation timeliness'],
      ),
      CHWPerformanceMetrics(
        chwId: 'chw_003',
        chwName: 'Grace Muthoni',
        village: 'Ruiru North',
        patientsAssigned: 68,
        visitsThisMonth: 45,
        highRiskPatientsManaged: 10,
        referralsMade: 7,
        followUpCompletionRate: 95.0,
        patientSatisfactionScore: 4.8,
        trainingModulesCompleted: 15,
        overallRating: PerformanceRating.excellent,
        strengths: [
          'Maternal health expertise',
          'Training completion',
          'High visit rate'
        ],
        areasForImprovement: [],
      ),
      CHWPerformanceMetrics(
        chwId: 'chw_004',
        chwName: 'Peter Otieno',
        village: 'Ruiru South',
        patientsAssigned: 90,
        visitsThisMonth: 28,
        highRiskPatientsManaged: 5,
        referralsMade: 3,
        followUpCompletionRate: 72.0,
        patientSatisfactionScore: 3.9,
        trainingModulesCompleted: 5,
        overallRating: PerformanceRating.needsImprovement,
        strengths: ['Community knowledge'],
        areasForImprovement: [
          'Visit frequency',
          'Follow-up completion',
          'Training participation'
        ],
      ),
      CHWPerformanceMetrics(
        chwId: 'chw_005',
        chwName: 'Faith Nyambura',
        village: 'Juja',
        patientsAssigned: 75,
        visitsThisMonth: 40,
        highRiskPatientsManaged: 7,
        referralsMade: 6,
        followUpCompletionRate: 88.0,
        patientSatisfactionScore: 4.5,
        trainingModulesCompleted: 10,
        overallRating: PerformanceRating.good,
        strengths: ['Child health', 'Vaccination tracking'],
        areasForImprovement: ['Emergency protocols'],
      ),
    ];
  }

  /// Get disease statistics
  Future<List<DiseaseStats>> _getDiseaseStats() async {
    return [
      DiseaseStats(
        disease: 'Malaria',
        totalCases: 45,
        newCasesThisWeek: 8,
        newCasesThisMonth: 23,
        growthRate: 15.2,
        affectedVillages: ['Kiambu East', 'Ruiru North'],
        trend: 'increasing',
        isOutbreak: false,
      ),
      DiseaseStats(
        disease: 'Diarrheal Disease',
        totalCases: 32,
        newCasesThisWeek: 12,
        newCasesThisMonth: 28,
        growthRate: 45.0,
        affectedVillages: ['Ruiru South', 'Juja'],
        trend: 'increasing',
        isOutbreak: true,
      ),
      DiseaseStats(
        disease: 'Respiratory Infections',
        totalCases: 67,
        newCasesThisWeek: 5,
        newCasesThisMonth: 18,
        growthRate: -8.5,
        affectedVillages: ['Kiambu West', 'Kiambu East'],
        trend: 'decreasing',
        isOutbreak: false,
      ),
      DiseaseStats(
        disease: 'Hypertension',
        totalCases: 89,
        newCasesThisWeek: 2,
        newCasesThisMonth: 7,
        growthRate: 5.0,
        affectedVillages: ['All areas'],
        trend: 'stable',
        isOutbreak: false,
      ),
      DiseaseStats(
        disease: 'Diabetes',
        totalCases: 54,
        newCasesThisWeek: 1,
        newCasesThisMonth: 4,
        growthRate: 3.5,
        affectedVillages: ['Juja', 'Ruiru North'],
        trend: 'stable',
        isOutbreak: false,
      ),
    ];
  }

  /// Get community health summaries
  Future<List<CommunityHealthSummary>> _getCommunitySummaries(
      List<Patient> patients) async {
    // Group patients by village
    Map<String, List<Patient>> byVillage = {};
    for (var patient in patients) {
      final village = patient.village ?? 'Unknown';
      byVillage.putIfAbsent(village, () => []);
      byVillage[village]!.add(patient);
    }

    List<CommunityHealthSummary> summaries = [];

    for (var entry in byVillage.entries) {
      summaries.add(CommunityHealthSummary(
        village: entry.key,
        population: entry.value.length * 5, // Estimate
        registeredPatients: entry.value.length,
        healthScore: 72.5 + (entry.value.length % 20), // Demo calculation
        topHealthConcerns: [
          'Malaria',
          'Respiratory infections',
          'Malnutrition'
        ],
        activeOutbreaks: 0,
        assignedCHW: 'CHW ${entry.key.split(' ').first}',
        lastVisitDate:
            DateTime.now().subtract(Duration(days: entry.value.length % 7)),
      ));
    }

    // Add default communities if no patients
    if (summaries.isEmpty) {
      summaries.addAll([
        CommunityHealthSummary(
          village: 'Kiambu East',
          population: 1200,
          registeredPatients: 85,
          healthScore: 78.5,
          topHealthConcerns: ['Malaria', 'Respiratory infections'],
          activeOutbreaks: 0,
          assignedCHW: 'Mary Wanjiku',
          lastVisitDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
        CommunityHealthSummary(
          village: 'Ruiru North',
          population: 980,
          registeredPatients: 68,
          healthScore: 82.0,
          topHealthConcerns: ['Diarrheal disease', 'Malnutrition'],
          activeOutbreaks: 1,
          assignedCHW: 'Grace Muthoni',
          lastVisitDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
    }

    return summaries;
  }

  /// Get resource needs
  List<ResourceNeed> _getResourceNeeds() {
    return [
      ResourceNeed(
        resourceType: 'ORS Packets',
        location: 'Ruiru South',
        quantityNeeded: 500,
        currentStock: 120,
        priority: ResourcePriority.high,
        reason: 'Diarrhea outbreak - increased demand',
        estimatedNeedDate: DateTime.now().add(const Duration(days: 7)),
      ),
      ResourceNeed(
        resourceType: 'Malaria RDTs',
        location: 'Kiambu East',
        quantityNeeded: 200,
        currentStock: 45,
        priority: ResourcePriority.high,
        reason: 'Rainy season - increased malaria cases',
        estimatedNeedDate: DateTime.now().add(const Duration(days: 5)),
      ),
      ResourceNeed(
        resourceType: 'Blood Pressure Monitors',
        location: 'All areas',
        quantityNeeded: 10,
        currentStock: 3,
        priority: ResourcePriority.medium,
        reason: 'Equipment aging and increased NCD screening',
        estimatedNeedDate: DateTime.now().add(const Duration(days: 14)),
      ),
      ResourceNeed(
        resourceType: 'MUAC Tapes',
        location: 'Juja',
        quantityNeeded: 50,
        currentStock: 8,
        priority: ResourcePriority.medium,
        reason: 'Malnutrition screening campaign',
        estimatedNeedDate: DateTime.now().add(const Duration(days: 10)),
      ),
    ];
  }

  /// Get active alerts
  List<Alert> _getActiveAlerts() {
    if (_alerts.isEmpty) {
      _alerts.addAll([
        Alert(
          id: 'alert_001',
          title: 'Diarrhea Outbreak - Ruiru South',
          description: '12 new cases reported this week. Threshold exceeded.',
          category: AlertCategory.outbreak,
          severity: AlertSeverity.critical,
          location: 'Ruiru South',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          isRead: false,
          isResolved: false,
        ),
        Alert(
          id: 'alert_002',
          title: 'Low ORS Stock',
          description: 'ORS packets running low in Ruiru South. Order needed.',
          category: AlertCategory.resourceShortage,
          severity: AlertSeverity.warning,
          location: 'Ruiru South',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
          isRead: true,
          isResolved: false,
        ),
        Alert(
          id: 'alert_003',
          title: 'CHW Performance Review Needed',
          description: 'Peter Otieno has low follow-up completion rate.',
          category: AlertCategory.chwPerformance,
          severity: AlertSeverity.warning,
          chwId: 'chw_004',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          isRead: false,
          isResolved: false,
        ),
      ]);
    }

    return _alerts.where((a) => !a.isResolved).toList();
  }

  /// Add new alert
  void addAlert({
    required String title,
    required String description,
    required AlertCategory category,
    required AlertSeverity severity,
    String? location,
    String? chwId,
  }) {
    _alerts.add(Alert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      category: category,
      severity: severity,
      location: location,
      chwId: chwId,
      createdAt: DateTime.now(),
    ));
  }

  /// Mark alert as read
  void markAlertRead(String alertId) {
    int index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      var alert = _alerts[index];
      _alerts[index] = Alert(
        id: alert.id,
        title: alert.title,
        description: alert.description,
        category: alert.category,
        severity: alert.severity,
        location: alert.location,
        chwId: alert.chwId,
        createdAt: alert.createdAt,
        isRead: true,
        isResolved: alert.isResolved,
      );
    }
  }

  /// Resolve alert
  void resolveAlert(String alertId) {
    int index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      var alert = _alerts[index];
      _alerts[index] = Alert(
        id: alert.id,
        title: alert.title,
        description: alert.description,
        category: alert.category,
        severity: alert.severity,
        location: alert.location,
        chwId: alert.chwId,
        createdAt: alert.createdAt,
        isRead: true,
        isResolved: true,
      );
    }
  }

  /// Get time series data for charts
  List<TimeSeriesData> getVisitTrend({int days = 30}) {
    List<TimeSeriesData> data = [];
    DateTime now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      DateTime date = now.subtract(Duration(days: i));
      // Generate sample data
      double value = 15 + (i % 7) * 3 + (date.weekday < 6 ? 5 : 0);
      data.add(TimeSeriesData(
        date: date,
        value: value,
        label: '${date.day}/${date.month}',
      ));
    }

    return data;
  }

  /// Get disease trend for charts
  List<TimeSeriesData> getDiseaseTrend(String disease, {int weeks = 8}) {
    List<TimeSeriesData> data = [];
    DateTime now = DateTime.now();

    for (int i = weeks - 1; i >= 0; i--) {
      DateTime date = now.subtract(Duration(days: i * 7));
      // Generate sample data based on disease
      double value;
      switch (disease.toLowerCase()) {
        case 'malaria':
          value = 8 + (i % 4) * 2;
          break;
        case 'diarrhea':
          value = 4 + (weeks - i) * 1.5; // Increasing trend
          break;
        default:
          value = 5 + (i % 3) * 2;
      }
      data.add(TimeSeriesData(
        date: date,
        value: value,
        label: 'Week ${weeks - i}',
      ));
    }

    return data;
  }

  /// Generate report
  Future<Map<String, dynamic>> generateReport(ReportSettings settings) async {
    var dashboard = await getDashboard('supervisor');

    return {
      'generatedAt': DateTime.now().toIso8601String(),
      'period':
          '${settings.startDate.toIso8601String()} to ${settings.endDate.toIso8601String()}',
      'overview': dashboard.overview.toMap(),
      'chwPerformance': settings.includeCHWPerformance
          ? dashboard.chwPerformance.map((c) => c.toMap()).toList()
          : null,
      'diseaseBreakdown': settings.includeDiseaseBreakdown
          ? dashboard.diseaseStats.map((d) => d.toMap()).toList()
          : null,
      'communities':
          dashboard.communitySummaries.map((c) => c.toMap()).toList(),
      'alerts': dashboard.activeAlerts.map((a) => a.toMap()).toList(),
      'resourceNeeds': dashboard.resourceNeeds.map((r) => r.toMap()).toList(),
    };
  }

  /// Get unread alert count
  int getUnreadAlertCount() {
    return _alerts.where((a) => !a.isRead && !a.isResolved).length;
  }

  /// Get critical alert count
  int getCriticalAlertCount() {
    return _alerts
        .where((a) => a.severity == AlertSeverity.critical && !a.isResolved)
        .length;
  }

  /// Get community summary by village name
  CommunityHealthSummary? getCommunitySummary(String village) {
    return _communitySummaries[village];
  }

  /// Get all community summaries
  Map<String, CommunityHealthSummary> getAllCommunitySummaries() {
    return Map.unmodifiable(_communitySummaries);
  }

  /// Update community summary
  void updateCommunitySummary(String village, CommunityHealthSummary summary) {
    _communitySummaries[village] = summary;
  }
}
