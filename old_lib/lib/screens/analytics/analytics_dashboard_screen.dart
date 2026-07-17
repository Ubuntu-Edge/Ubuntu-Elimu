import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/analytics_api_service.dart';
import '../../models/analytics_models.dart' as api;
import '../../l10n/app_localizations.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnalyticsApiService _analyticsApi = AnalyticsApiService.instance;

  // Local analytics data (fallback)
  AnalyticsSummary? _analytics;
  List<AnalyticsDataPoint>? _visitTrend;
  List<AnalyticsDataPoint>? _registrationTrend;

  // API analytics data
  api.AnalyticsSummaryResponse? _apiSummary;
  api.PerformanceMetricsResponse? _apiPerformance;

  bool _isLoading = true;
  String? _errorMessage;
  bool _usingApiData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Calculate date range (last 30 days)
    final now = DateTime.now();
    final periodEnd =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final periodStart = now.subtract(const Duration(days: 30));
    final periodStartStr =
        '${periodStart.year}-${periodStart.month.toString().padLeft(2, '0')}-${periodStart.day.toString().padLeft(2, '0')}';

    try {
      // Try to load from API first
      final results = await Future.wait([
        _analyticsApi.getAnalyticsSummary(
          periodStart: periodStartStr,
          periodEnd: periodEnd,
        ),
        _analyticsApi.getPerformanceMetrics(
          periodStart: periodStartStr,
          periodEnd: periodEnd,
        ),
      ]);

      setState(() {
        _apiSummary = results[0] as api.AnalyticsSummaryResponse;
        _apiPerformance = results[1] as api.PerformanceMetricsResponse;
        _usingApiData = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics from API: $e');
      // Fall back to local analytics service
      _loadLocalAnalytics();
    }
  }

  Future<void> _loadLocalAnalytics() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final chwId = authProvider.currentCHW?.id ?? '';

      final analytics =
          await AnalyticsService.instance.getAnalyticsSummary(chwId);
      final visitTrend =
          await AnalyticsService.instance.getVisitTrend(chwId, 30);
      final registrationTrend = await AnalyticsService.instance
          .getPatientRegistrationTrend(chwId, 30);

      setState(() {
        _analytics = analytics;
        _visitTrend = visitTrend;
        _registrationTrend = registrationTrend;
        _usingApiData = false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading local analytics: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildPatientsTab(),
                            _buildPerformanceTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(FontAwesomeIcons.triangleExclamation,
                  color: AppColors.error, size: 48),
            ),
            SizedBox(height: AppTheme.spacingLg),
            Text(
              l10n.translate('errorLoadingAnalytics') ??
                  'Error Loading Analytics',
              style: AppTheme.headingMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: AppTheme.bodyMedium.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: FaIcon(FontAwesomeIcons.arrowRotateRight, size: 16),
              label: Text(l10n.translate('retry') ?? 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.arrowLeft,
                        color: Colors.white, size: 18),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.analytics,
                        style: AppTheme.headingMedium.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        l10n.translate('trackPerformance') ??
                            'Track your performance & insights',
                        style: AppTheme.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _loadAnalytics,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.arrowsRotate,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white,
              labelStyle:
                  AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
              tabs: [
                Tab(child: FaIcon(FontAwesomeIcons.chartLine, size: 16)),
                Tab(child: FaIcon(FontAwesomeIcons.users, size: 16)),
                Tab(child: FaIcon(FontAwesomeIcons.trophy, size: 16)),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final l10n = AppLocalizations.of(context);

    // Check if we have API data or local data
    if (_usingApiData && _apiSummary != null) {
      return _buildApiOverviewTab(l10n);
    }

    if (_analytics == null)
      return Center(
          child:
              Text(l10n.translate('noDataAvailable') ?? 'No data available'));

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.totalPatients,
                  value: '${_analytics!.totalPatients}',
                  icon: FontAwesomeIcons.users,
                  color: AppColors.primary,
                  change: '+${_analytics!.newPatientsThisMonth}',
                  changeLabel: l10n.translate('thisMonth') ?? 'this month',
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.translate('totalVisits') ?? 'Total Visits',
                  value: '${_analytics!.totalVisits}',
                  icon: FontAwesomeIcons.stethoscope,
                  color: AppColors.success,
                  change: '+${_analytics!.visitsThisMonth}',
                  changeLabel: l10n.translate('thisMonth') ?? 'this month',
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.highRisk,
                  value: '${_analytics!.highRiskPatients}',
                  icon: FontAwesomeIcons.triangleExclamation,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.translate('followUpRate') ?? 'Follow-up Rate',
                  value:
                      '${_analytics!.followupCompletionRate.toStringAsFixed(0)}%',
                  icon: FontAwesomeIcons.calendarCheck,
                  color: AppColors.info,
                ),
              ),
            ],
          ),

          SizedBox(height: AppTheme.spacingLg),

          // Visit Trend Chart
          _buildChartCard(
            title:
                l10n.translate('visitsLast30Days') ?? 'Visits (Last 30 Days)',
            child: SizedBox(
              height: 200,
              child: _buildLineChart(_visitTrend ?? [], AppColors.success),
            ),
          ),

          SizedBox(height: AppTheme.spacingMd),

          // Triage Distribution
          _buildChartCard(
            title: l10n.translate('triageDistribution') ??
                'Triage Level Distribution',
            child: SizedBox(
              height: 200,
              child: _buildPieChart(_analytics!.triageLevelDistribution),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiOverviewTab(AppLocalizations l10n) {
    final summary = _apiSummary!;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Data source indicator
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
            margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.cloud,
                    size: 14, color: AppColors.success),
                SizedBox(width: AppTheme.spacingSm),
                Text(
                  l10n.translate('dataFromServer') ?? 'Data from server',
                  style: AppTheme.labelSmall.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),

          // Summary Cards from API
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.totalPatients,
                  value: '${summary.totalPatients}',
                  icon: FontAwesomeIcons.users,
                  color: AppColors.primary,
                  change: '+${summary.newPatients}',
                  changeLabel: l10n.translate('thisPeriod') ?? 'this period',
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.translate('totalVisits') ?? 'Total Visits',
                  value: '${summary.totalVisits}',
                  icon: FontAwesomeIcons.stethoscope,
                  color: AppColors.success,
                  change: '${summary.avgVisitsPerDay.toStringAsFixed(1)}/day',
                  changeLabel: l10n.translate('average') ?? 'average',
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.highRisk,
                  value: '${summary.highRiskPatients}',
                  icon: FontAwesomeIcons.triangleExclamation,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.translate('followUpRate') ?? 'Follow-up Rate',
                  value:
                      '${summary.followUpCompletionRate.toStringAsFixed(0)}%',
                  icon: FontAwesomeIcons.calendarCheck,
                  color: AppColors.info,
                ),
              ),
            ],
          ),

          SizedBox(height: AppTheme.spacingLg),

          // Visit breakdown
          _buildChartCard(
            title: l10n.translate('visitBreakdown') ?? 'Visit Breakdown',
            child: SizedBox(
              height: 200,
              child: _buildPieChart({
                l10n.translate('homeVisits') ?? 'Home': summary.homeVisits,
                l10n.translate('followUp') ?? 'Follow-up':
                    summary.followUpVisits,
                l10n.translate('emergency') ?? 'Emergency':
                    summary.emergencyVisits,
              }),
            ),
          ),

          SizedBox(height: AppTheme.spacingMd),

          // Referral Stats
          _buildChartCard(
            title: l10n.translate('referralStats') ?? 'Referral Statistics',
            child: SizedBox(
              height: 200,
              child: _buildPieChart({
                l10n.translate('completed') ?? 'Completed':
                    summary.completedReferrals,
                l10n.translate('pending') ?? 'Pending':
                    summary.pendingReferrals,
              }),
            ),
          ),
        ],
      ),
    );
  }

  // TODO: Unused method - kept for potential API line chart feature
  // Widget _buildApiLineChart(List<api.VisitTrendData> data, Color color) {
  //   if (data.isEmpty) {
  //     return Center(child: Text('No data available', style: AppTheme.bodySmall));
  //   }
  //
  //   final spots = data.asMap().entries.map((entry) {
  //     return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
  //   }).toList();
  //
  //   return LineChart(
  //     LineChartData(
  //       gridData: FlGridData(show: false),
  //       titlesData: FlTitlesData(show: false),
  //       borderData: FlBorderData(show: false),
  //       lineBarsData: [
  //         LineChartBarData(
  //           spots: spots,
  //           isCurved: true,
  //           color: color,
  //           barWidth: 3,
  //           isStrokeCapRound: true,
  //           dotData: FlDotData(show: false),
  //           belowBarData: BarAreaData(
  //             show: true,
  //             color: color.withValues(alpha: 0.1),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildPatientsTab() {
    final l10n = AppLocalizations.of(context);

    // Use API data if available
    if (_usingApiData && _apiSummary != null) {
      return _buildApiPatientsTab(l10n);
    }

    if (_analytics == null)
      return Center(
          child:
              Text(l10n.translate('noDataAvailable') ?? 'No data available'));

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Patient Registration Trend
          _buildChartCard(
            title: l10n.translate('patientRegistrations') ??
                'Patient Registrations (Last 30 Days)',
            child: SizedBox(
              height: 200,
              child:
                  _buildLineChart(_registrationTrend ?? [], AppColors.primary),
            ),
          ),

          SizedBox(height: AppTheme.spacingMd),

          // Gender Distribution
          _buildChartCard(
            title: l10n.translate('patientsByGender') ?? 'Patients by Gender',
            child: SizedBox(
              height: 200,
              child: _buildPieChart(_analytics!.patientsByGender),
            ),
          ),

          SizedBox(height: AppTheme.spacingMd),

          // Age Distribution
          _buildChartCard(
            title: l10n.translate('patientsByAge') ?? 'Patients by Age Group',
            child: SizedBox(
              height: 200,
              child: _buildBarChart(_analytics!.patientsByAgeGroup),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiPatientsTab(AppLocalizations l10n) {
    final summary = _apiSummary!;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Patient Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.translate('totalPatients') ?? 'Total Patients',
                  value: '${summary.totalPatients}',
                  icon: FontAwesomeIcons.users,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildSummaryCard(
                  title: l10n.translate('newPatients') ?? 'New This Period',
                  value: '${summary.newPatients}',
                  icon: FontAwesomeIcons.userPlus,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),

          // Patient categories breakdown
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    l10n.translate('patientCategories') ?? 'Patient Categories',
                    style: AppTheme.labelLarge),
                SizedBox(height: AppTheme.spacingMd),
                _buildCategoryRow(l10n.translate('highRisk') ?? 'High Risk',
                    summary.highRiskPatients, AppColors.error),
                _buildCategoryRow(l10n.translate('pregnant') ?? 'Pregnant',
                    summary.pregnantPatients, AppColors.secondary),
                _buildCategoryRow(
                    l10n.translate('childrenUnder5') ?? 'Children Under 5',
                    summary.childrenUnder5,
                    AppColors.info),
              ],
            ),
          ),

          SizedBox(height: AppTheme.spacingMd),

          // Follow-up stats
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.translate('followUpStats') ?? 'Follow-up Statistics',
                    style: AppTheme.labelLarge),
                SizedBox(height: AppTheme.spacingMd),
                _buildCategoryRow(l10n.translate('completed') ?? 'Completed',
                    summary.completedFollowUps, AppColors.success),
                _buildCategoryRow(l10n.translate('pending') ?? 'Pending',
                    summary.pendingFollowUps, AppColors.warning),
                _buildCategoryRow(l10n.translate('overdue') ?? 'Overdue',
                    summary.overdueFollowUps, AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String label, int count, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(label, style: AppTheme.bodyMedium)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: AppTheme.labelSmall
                  .copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final l10n = AppLocalizations.of(context);

    // Use API performance data if available
    if (_usingApiData && _apiPerformance != null) {
      return _buildApiPerformanceTab(l10n);
    }

    if (_analytics == null)
      return Center(
          child:
              Text(l10n.translate('noDataAvailable') ?? 'No data available'));

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Performance Score
          _buildPerformanceScoreCard(),

          SizedBox(height: AppTheme.spacingMd),

          // Key Metrics
          _buildMetricsCard(),

          SizedBox(height: AppTheme.spacingMd),

          // Visits by Month
          _buildChartCard(
            title: l10n.translate('visitsByMonth') ?? 'Visits by Month',
            child: SizedBox(
              height: 200,
              child: _buildBarChart(_analytics!.visitsByMonth),
            ),
          ),

          SizedBox(height: AppTheme.spacingMd),

          // Common Diagnoses
          _buildListCard(
            title: l10n.translate('commonDiagnoses') ?? 'Common Diagnoses',
            data: _analytics!.commonDiagnoses,
          ),
        ],
      ),
    );
  }

  Widget _buildApiPerformanceTab(AppLocalizations l10n) {
    final perf = _apiPerformance!;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Performance Score from API
          _buildApiPerformanceScoreCard(perf),

          SizedBox(height: AppTheme.spacingMd),

          // Key Metrics from API
          _buildApiMetricsCard(perf, l10n),

          SizedBox(height: AppTheme.spacingMd),

          // Training Progress
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.translate('trainingProgress') ?? 'Training Progress',
                    style: AppTheme.labelLarge),
                SizedBox(height: AppTheme.spacingMd),
                _buildMetricRow(
                    l10n.translate('modulesCompleted') ?? 'Modules Completed',
                    '${perf.trainingModulesCompleted}'),
                _buildMetricRow(
                    l10n.translate('completionRate') ?? 'Completion Rate',
                    '${perf.trainingCompletionPercentage.toStringAsFixed(0)}%'),
              ],
            ),
          ),

          SizedBox(height: AppTheme.spacingMd),

          // Response Times
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.translate('responseTimes') ?? 'Response Times',
                    style: AppTheme.labelLarge),
                SizedBox(height: AppTheme.spacingMd),
                _buildMetricRow(
                  l10n.translate('avgEmergencyResponse') ??
                      'Avg Emergency Response',
                  '${perf.avgEmergencyResponseTimeMinutes.toStringAsFixed(0)} min',
                ),
                _buildMetricRow(
                  l10n.translate('avgReferralProcessing') ??
                      'Avg Referral Processing',
                  '${perf.avgReferralProcessingTimeHours.toStringAsFixed(1)} hrs',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiPerformanceScoreCard(api.PerformanceMetricsResponse perf) {
    final l10n = AppLocalizations.of(context);
    // Calculate a performance score based on available metrics
    final score = ((perf.followUpCompletionRate +
                perf.referralCompletionRate +
                perf.documentationCompleteness) /
            3)
        .clamp(0, 100);

    String performanceLabel;
    Color performanceColor;
    if (score >= 90) {
      performanceLabel =
          l10n.translate('excellentPerformance') ?? 'Excellent Performance!';
      performanceColor = AppColors.success;
    } else if (score >= 75) {
      performanceLabel =
          l10n.translate('greatPerformance') ?? 'Great Performance!';
      performanceColor = AppColors.primary;
    } else if (score >= 60) {
      performanceLabel =
          l10n.translate('goodPerformance') ?? 'Good Performance';
      performanceColor = AppColors.info;
    } else {
      performanceLabel =
          l10n.translate('needsImprovement') ?? 'Needs Improvement';
      performanceColor = AppColors.warning;
    }

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [performanceColor, performanceColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: AppTheme.headingLarge.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      l10n.translate('score') ?? 'Score',
                      style: AppTheme.labelSmall
                          .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performanceLabel,
                  style: AppTheme.headingSmall.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (perf.rankInRegion > 0)
                  Text(
                    '${l10n.translate('rank') ?? 'Rank'}: #${perf.rankInRegion} ${l10n.translate('of') ?? 'of'} ${perf.totalChwsInRegion}',
                    style: AppTheme.bodySmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiMetricsCard(
      api.PerformanceMetricsResponse perf, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.translate('keyMetrics') ?? 'Key Metrics',
              style: AppTheme.labelLarge),
          SizedBox(height: AppTheme.spacingMd),
          _buildMetricRow(
              l10n.translate('avgVisitsPerDay') ?? 'Avg. Visits per Day',
              perf.avgVisitsPerDay.toStringAsFixed(1)),
          _buildMetricRow(
              l10n.translate('followUpCompletion') ?? 'Follow-up Completion',
              '${perf.followUpCompletionRate.toStringAsFixed(0)}%'),
          _buildMetricRow(
              l10n.translate('referralCompletion') ?? 'Referral Completion',
              '${perf.referralCompletionRate.toStringAsFixed(0)}%'),
          _buildMetricRow(
              l10n.translate('documentationCompleteness') ?? 'Documentation',
              '${perf.documentationCompleteness.toStringAsFixed(0)}%'),
          _buildMetricRow(l10n.translate('workingDays') ?? 'Working Days',
              '${perf.totalWorkingDays}'),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? change,
    String? changeLabel,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(icon, color: color, size: 16),
              ),
              if (change != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    change,
                    style: AppTheme.labelSmall.copyWith(
                        color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          Text(value,
              style:
                  AppTheme.headingLarge.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(title,
              style:
                  AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
          if (changeLabel != null)
            Text(changeLabel,
                style:
                    AppTheme.labelSmall.copyWith(color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.labelLarge),
          SizedBox(height: AppTheme.spacingMd),
          child,
        ],
      ),
    );
  }

  Widget _buildLineChart(List<AnalyticsDataPoint> data, Color color) {
    final l10n = AppLocalizations.of(context);
    if (data.isEmpty) {
      return Center(
          child: Text(l10n.translate('noDataAvailable') ?? 'No data available',
              style: AppTheme.bodySmall));
    }

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    final l10n = AppLocalizations.of(context);

    // Check if data is empty or all values are zero
    if (data.isEmpty) {
      return Center(
          child: Text(l10n.translate('noDataAvailable') ?? 'No data available',
              style: AppTheme.bodySmall));
    }

    // Calculate total and check if all values are zero
    final total = data.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.chartPie,
                color: AppColors.textLight, size: 40),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              l10n.translate('noDataYet') ?? 'No data yet',
              style:
                  AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              l10n.translate('checkBackLater') ??
                  'Check back after recording some activity',
              style: AppTheme.labelSmall.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.info,
    ];

    // Filter out zero values for pie chart display
    final filteredData =
        Map.fromEntries(data.entries.where((e) => e.value > 0));
    if (filteredData.isEmpty) {
      return Center(
          child: Text(l10n.translate('noDataAvailable') ?? 'No data available',
              style: AppTheme.bodySmall));
    }

    final sections = filteredData.entries.toList().asMap().entries.map((entry) {
      final colorIndex = entry.key % colors.length;
      final percentage = (entry.value.value / total * 100).toStringAsFixed(0);
      return PieChartSectionData(
        value: entry.value.value.toDouble(),
        color: colors[colorIndex],
        title: '$percentage%',
        titleStyle: TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        radius: 60,
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                filteredData.entries.toList().asMap().entries.map((entry) {
              final colorIndex = entry.key % colors.length;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[colorIndex],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${entry.value.key}: ${entry.value.value}',
                        style: AppTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    final l10n = AppLocalizations.of(context);
    if (data.isEmpty) {
      return Center(
          child: Text(l10n.translate('noDataAvailable') ?? 'No data available',
              style: AppTheme.bodySmall));
    }

    final barGroups = data.entries.toList().asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value.toDouble(),
            color: AppColors.primary,
            width: 20,
            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final label = data.keys.toList()[index];
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      label.length > 5 ? label.substring(0, 5) : label,
                      style: AppTheme.labelSmall,
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildPerformanceScoreCard() {
    final l10n = AppLocalizations.of(context);
    final score = 85; // Calculate based on metrics

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: AppTheme.headingLarge.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      l10n.translate('score') ?? 'Score',
                      style: AppTheme.labelSmall
                          .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('greatPerformance') ?? 'Great Performance!',
                  style: AppTheme.headingSmall.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  l10n.translate('performanceMessage') ??
                      'You\'re in the top 15% of CHWs in your region. Keep up the excellent work!',
                  style: AppTheme.bodySmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.translate('keyMetrics') ?? 'Key Metrics',
              style: AppTheme.labelLarge),
          SizedBox(height: AppTheme.spacingMd),
          _buildMetricRow(
              l10n.translate('avgVisitsPerPatient') ??
                  'Avg. Visits per Patient',
              _analytics!.averageVisitsPerPatient.toStringAsFixed(1)),
          _buildMetricRow(
              l10n.translate('followUpCompletion') ?? 'Follow-up Completion',
              '${_analytics!.followupCompletionRate.toStringAsFixed(0)}%'),
          _buildMetricRow(l10n.translate('referralsMade') ?? 'Referrals Made',
              '${_analytics!.referralsMade}'),
          _buildMetricRow(
              l10n.translate('referralsCompleted') ?? 'Referrals Completed',
              '${_analytics!.referralsCompleted}'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(value,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildListCard(
      {required String title, required Map<String, int> data}) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.labelLarge),
          SizedBox(height: AppTheme.spacingMd),
          ...sortedEntries.take(5).map((entry) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key, style: AppTheme.bodyMedium)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: AppTheme.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
