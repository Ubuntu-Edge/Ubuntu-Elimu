import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/supervisor_dashboard.dart';
import '../../services/dashboard_service.dart';
import '../../services/dashboard_api_service.dart' as dashboard_api;
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  SupervisorDashboard? _dashboard;
  dashboard_api.DashboardOverview? _apiOverview;
  dashboard_api.DashboardSummary? _apiSummary;
  bool _isLoading = true;
  bool _isUsingApiData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadDashboard();

    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final chwId = authProvider.currentCHW?.id ?? 'supervisor_1';

    // Try API first for real data
    try {
      final apiService = dashboard_api.DashboardApiService.instance;

      // Load API data in parallel
      final results = await Future.wait([
        apiService.getSummary().catchError((_) => null as dynamic),
        apiService.getOverview().catchError((_) => null as dynamic),
        apiService.getDiseaseStats().catchError((_) => null as dynamic),
      ]);

      if (results[0] is dashboard_api.DashboardSummary ||
          results[1] is dashboard_api.DashboardOverview) {
        setState(() {
          _apiSummary = results[0] as dashboard_api.DashboardSummary?;
          _apiOverview = results[1] as dashboard_api.DashboardOverview?;
          _isUsingApiData = true;
        });
        debugPrint('Dashboard: Using API data');
      }
    } catch (e) {
      debugPrint('Dashboard API error: $e');
    }

    // Also load local dashboard data (for CHW list, alerts, etc.)
    try {
      final dashboard = await DashboardService.instance.getDashboard(chwId);
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      debugPrint('Dashboard local error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _getUnreadAlertCount() {
    return _dashboard?.activeAlerts.where((a) => !a.isRead).length ?? 0;
  }

  // Get overview stats preferring API data
  int get _totalPatients =>
      _apiOverview?.totalPatients ??
      _apiSummary?.totalPatients ??
      _dashboard?.overview.totalPatients ??
      0;
  int get _totalCHWs =>
      _apiOverview?.totalChws ?? _dashboard?.overview.totalCHWs ?? 0;
  int get _totalVisits =>
      _apiOverview?.monthVisitsTotal ??
      _apiSummary?.monthVisits ??
      _dashboard?.overview.totalVisitsThisMonth ??
      0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Tabs
            _buildHeader(l10n),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: AppTheme.spacingMd),
                          Text(
                              l10n.translate('loadingDashboard') ??
                                  'Loading dashboard...',
                              style: AppTheme.bodyMedium
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: _loadDashboard,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildCHWsTab(),
                            _buildHealthTab(),
                            _buildResourcesTab(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
                        l10n.translate('dashboard') ?? 'Dashboard',
                        style: AppTheme.headingMedium.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            l10n.translate('monitorTeam') ??
                                'Monitor and manage your team',
                            style: AppTheme.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          if (_isUsingApiData) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(FontAwesomeIcons.circleCheck,
                                      color: Colors.white, size: 8),
                                  SizedBox(width: 4),
                                  Text('Live',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAlerts(),
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FaIcon(FontAwesomeIcons.bell,
                            color: Colors.white, size: 18),
                      ),
                      if (_getUnreadAlertCount() > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              '${_getUnreadAlertCount()}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: AppTheme.spacingSm),
                GestureDetector(
                  onTap: () => _generateReport(),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.download,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          // Custom Tab Bar
          Container(
            margin: EdgeInsets.fromLTRB(
                AppTheme.spacingMd, 0, AppTheme.spacingMd, AppTheme.spacingMd),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white,
              labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 11),
              tabs: [
                Tab(icon: FaIcon(FontAwesomeIcons.gauge, size: 16)),
                Tab(icon: FaIcon(FontAwesomeIcons.users, size: 16)),
                Tab(icon: FaIcon(FontAwesomeIcons.heartPulse, size: 16)),
                Tab(icon: FaIcon(FontAwesomeIcons.boxesStacked, size: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final l10n = AppLocalizations.of(context);
    if (_dashboard == null && !_isUsingApiData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.chartLine,
                color: AppColors.textLight, size: 48),
            SizedBox(height: AppTheme.spacingMd),
            Text(l10n.translate('noDataYet') ?? 'No data available',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            SizedBox(height: AppTheme.spacingSm),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: Text(l10n.translate('retry') ?? 'Retry'),
            ),
          ],
        ),
      );
    }
    final overview = _dashboard?.overview;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Stats Grid - Using API data with fallback to local
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                l10n.translate('totalPatients') ?? 'Total Patients',
                '$_totalPatients',
                FontAwesomeIcons.users,
                AppColors.primary,
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildStatCard(
                l10n.translate('activeChws') ?? 'Active CHWs',
                '$_totalCHWs',
                FontAwesomeIcons.userNurse,
                AppColors.info,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                l10n.translate('monthlyVisits') ?? 'Visits (Month)',
                '$_totalVisits',
                FontAwesomeIcons.stethoscope,
                AppColors.success,
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildStatCard(
                l10n.translate('referrals') ?? 'Referrals',
                '${_apiOverview?.activeReferralsTotal ?? _apiSummary?.activeReferrals ?? overview?.totalReferrals ?? 0}',
                FontAwesomeIcons.hospital,
                AppColors.warning,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                l10n.translate('highRisk') ?? 'High Risk',
                '${overview?.highRiskPatients ?? 0}',
                FontAwesomeIcons.triangleExclamation,
                AppColors.error,
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildStatCard(
                'Follow-ups',
                '${overview?.pendingFollowUps ?? 0}',
                FontAwesomeIcons.clock,
                AppColors.secondary,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingMd),

        // Active Alerts
        if (_dashboard != null && _dashboard!.activeAlerts.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.bell,
                      color: AppColors.warning, size: 16),
                  SizedBox(width: AppTheme.spacingSm),
                  Text('Active Alerts',
                      style: AppTheme.headingSmall
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              TextButton(
                onPressed: _showAlerts,
                child: Text('View All',
                    style: AppTheme.labelMedium
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          ..._dashboard!.activeAlerts
              .take(3)
              .map((alert) => _buildAlertCard(alert)),
        ],
        SizedBox(height: AppTheme.spacingMd),

        // Community Summary
        if (_dashboard != null) ...[
          Row(
            children: [
              FaIcon(FontAwesomeIcons.mapLocationDot,
                  color: AppColors.primary, size: 16),
              SizedBox(width: AppTheme.spacingSm),
              Text('Community Health',
                  style: AppTheme.headingSmall
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          ..._dashboard!.communitySummaries.map((c) => _buildCommunityCard(c)),
        ],
        SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(icon, color: color, size: 18),
              ),
              Text(
                value,
                style: AppTheme.headingMedium
                    .copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          Text(title,
              style:
                  AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    Color color;
    IconData icon;
    switch (alert.severity) {
      case AlertSeverity.critical:
        color = AppColors.error;
        icon = FontAwesomeIcons.circleExclamation;
        break;
      case AlertSeverity.warning:
        color = AppColors.warning;
        icon = FontAwesomeIcons.triangleExclamation;
        break;
      case AlertSeverity.info:
        color = AppColors.info;
        icon = FontAwesomeIcons.circleInfo;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(icon, color: color, size: 18),
          ),
          SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(
                  alert.description,
                  style: AppTheme.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!alert.isRead)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(CommunityHealthSummary community) {
    Color healthColor;
    if (community.healthScore >= 80) {
      healthColor = AppColors.success;
    } else if (community.healthScore >= 60) {
      healthColor = AppColors.warning;
    } else {
      healthColor = AppColors.error;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.locationDot,
                      color: AppColors.textSecondary, size: 14),
                  SizedBox(width: 8),
                  Text(community.village,
                      style: AppTheme.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: healthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.heartPulse,
                        color: healthColor, size: 10),
                    SizedBox(width: 4),
                    Text(
                      '${community.healthScore.toStringAsFixed(0)}%',
                      style: AppTheme.labelSmall.copyWith(
                          color: healthColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              _buildCommunityInfo(
                  FontAwesomeIcons.users, '${community.registeredPatients}'),
              SizedBox(width: AppTheme.spacingMd),
              _buildCommunityInfo(
                  FontAwesomeIcons.userNurse, community.assignedCHW),
              if (community.activeOutbreaks > 0) ...[
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.virus,
                          color: Colors.white, size: 10),
                      SizedBox(width: 4),
                      Text(
                        '${community.activeOutbreaks} outbreak',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityInfo(IconData icon, String text) {
    return Row(
      children: [
        FaIcon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text,
            style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildCHWsTab() {
    if (_dashboard == null) return const Center(child: Text('No data'));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Performance summary
        Container(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.usersGear,
                        color: Colors.white, size: 18),
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  Text('Team Performance',
                      style:
                          AppTheme.headingSmall.copyWith(color: Colors.white)),
                ],
              ),
              SizedBox(height: AppTheme.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTeamStat(
                      'Excellent',
                      _dashboard!.chwPerformance
                          .where((c) =>
                              c.overallRating == PerformanceRating.excellent)
                          .length,
                      FontAwesomeIcons.medal),
                  _buildTeamStat(
                      'Good',
                      _dashboard!.chwPerformance
                          .where(
                              (c) => c.overallRating == PerformanceRating.good)
                          .length,
                      FontAwesomeIcons.circleCheck),
                  _buildTeamStat(
                      'Needs Help',
                      _dashboard!.chwPerformance
                          .where((c) =>
                              c.overallRating ==
                              PerformanceRating.needsImprovement)
                          .length,
                      FontAwesomeIcons.handHoldingHeart),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppTheme.spacingMd),

        Row(
          children: [
            FaIcon(FontAwesomeIcons.chartLine,
                color: AppColors.primary, size: 16),
            SizedBox(width: AppTheme.spacingSm),
            Text('CHW Performance',
                style: AppTheme.headingSmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        ..._dashboard!.chwPerformance.map((chw) => _buildCHWCard(chw)),
        SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTeamStat(String label, int count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(icon, color: Colors.white, size: 16),
        ),
        SizedBox(height: 6),
        Text('$count',
            style: AppTheme.headingMedium
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label,
            style: AppTheme.labelSmall
                .copyWith(color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildCHWCard(CHWPerformanceMetrics chw) {
    Color ratingColor;
    IconData ratingIcon;
    switch (chw.overallRating) {
      case PerformanceRating.excellent:
        ratingColor = AppColors.success;
        ratingIcon = FontAwesomeIcons.medal;
        break;
      case PerformanceRating.good:
        ratingColor = AppColors.primary;
        ratingIcon = FontAwesomeIcons.circleCheck;
        break;
      case PerformanceRating.average:
        ratingColor = AppColors.warning;
        ratingIcon = FontAwesomeIcons.chartLine;
        break;
      case PerformanceRating.needsImprovement:
      case PerformanceRating.critical:
        ratingColor = AppColors.error;
        ratingIcon = FontAwesomeIcons.triangleExclamation;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(AppTheme.spacingMd),
        childrenPadding: EdgeInsets.fromLTRB(
            AppTheme.spacingMd, 0, AppTheme.spacingMd, AppTheme.spacingMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: ratingColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              chw.chwName.substring(0, 1),
              style: AppTheme.headingSmall
                  .copyWith(color: ratingColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(chw.chwName,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            FaIcon(FontAwesomeIcons.locationDot,
                size: 10, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(chw.village,
                style: AppTheme.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ratingColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(ratingIcon, color: ratingColor, size: 10),
              SizedBox(width: 4),
              Text(
                chw.overallRating.name.toUpperCase(),
                style: AppTheme.labelSmall.copyWith(
                    color: ratingColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        children: [
          // Stats row
          Container(
            padding: EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCHWStat('Patients', '${chw.patientsAssigned}',
                    FontAwesomeIcons.users),
                _buildCHWStat('Visits', '${chw.visitsThisMonth}',
                    FontAwesomeIcons.stethoscope),
                _buildCHWStat(
                    'Follow-up',
                    '${chw.followUpCompletionRate.toStringAsFixed(0)}%',
                    FontAwesomeIcons.clock),
                _buildCHWStat(
                    'Rating',
                    chw.patientSatisfactionScore.toStringAsFixed(1),
                    FontAwesomeIcons.star),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingMd),

          // Strengths
          if (chw.strengths.isNotEmpty) ...[
            Row(
              children: [
                FaIcon(FontAwesomeIcons.thumbsUp,
                    color: AppColors.success, size: 14),
                SizedBox(width: AppTheme.spacingSm),
                Text('Strengths',
                    style: AppTheme.labelSmall.copyWith(
                        color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: AppTheme.spacingXs),
            Wrap(
              spacing: AppTheme.spacingXs,
              runSpacing: 4,
              children: chw.strengths
                  .map((s) => Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(s,
                            style: AppTheme.labelSmall
                                .copyWith(color: AppColors.success)),
                      ))
                  .toList(),
            ),
          ],

          // Areas for improvement
          if (chw.areasForImprovement.isNotEmpty) ...[
            SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.arrowTrendUp,
                    color: AppColors.warning, size: 14),
                SizedBox(width: AppTheme.spacingSm),
                Text('Areas to Improve',
                    style: AppTheme.labelSmall.copyWith(
                        color: AppColors.warning, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: AppTheme.spacingXs),
            Wrap(
              spacing: AppTheme.spacingXs,
              runSpacing: 4,
              children: chw.areasForImprovement
                  .map((s) => Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(s,
                            style: AppTheme.labelSmall
                                .copyWith(color: AppColors.warning)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCHWStat(String label, String value, IconData icon) {
    return Column(
      children: [
        FaIcon(icon, size: 12, color: AppColors.textSecondary),
        SizedBox(height: 4),
        Text(value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        Text(label,
            style: AppTheme.bodySmall
                .copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildHealthTab() {
    if (_dashboard == null) return const Center(child: Text('No data'));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Outbreak Alert if any
        ..._dashboard!.diseaseStats.where((d) => d.isOutbreak).map((d) =>
            Container(
              margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
              padding: EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.virus,
                        color: AppColors.error, size: 24),
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('OUTBREAK ALERT',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                        SizedBox(height: 6),
                        Text(
                            '${d.disease} - ${d.newCasesThisWeek} new cases this week',
                            style: AppTheme.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            FaIcon(FontAwesomeIcons.locationDot,
                                size: 10, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                  'Affected: ${d.affectedVillages.join(", ")}',
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),

        Row(
          children: [
            FaIcon(FontAwesomeIcons.chartPie,
                color: AppColors.primary, size: 16),
            SizedBox(width: AppTheme.spacingSm),
            Text('Disease Statistics',
                style: AppTheme.headingSmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        ..._dashboard!.diseaseStats.map((d) => _buildDiseaseCard(d)),
        SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDiseaseCard(DiseaseStats disease) {
    Color trendColor;
    IconData trendIcon;

    switch (disease.trend) {
      case 'increasing':
        trendColor = AppColors.error;
        trendIcon = FontAwesomeIcons.arrowTrendUp;
        break;
      case 'decreasing':
        trendColor = AppColors.success;
        trendIcon = FontAwesomeIcons.arrowTrendDown;
        break;
      default:
        trendColor = AppColors.warning;
        trendIcon = FontAwesomeIcons.minus;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: disease.isOutbreak
            ? Border.all(color: AppColors.error, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (disease.isOutbreak
                              ? AppColors.error
                              : AppColors.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FaIcon(
                      disease.isOutbreak
                          ? FontAwesomeIcons.virus
                          : FontAwesomeIcons.disease,
                      color: disease.isOutbreak
                          ? AppColors.error
                          : AppColors.primary,
                      size: 14,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  Text(disease.disease,
                      style: AppTheme.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  if (disease.isOutbreak) ...[
                    SizedBox(width: AppTheme.spacingSm),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('OUTBREAK',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(trendIcon, color: trendColor, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      '${disease.growthRate > 0 ? "+" : ""}${disease.growthRate.toStringAsFixed(1)}%',
                      style: AppTheme.labelSmall.copyWith(
                          color: trendColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          Container(
            padding: EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDiseaseStat('Total', '${disease.totalCases}',
                    FontAwesomeIcons.chartColumn),
                _buildDiseaseStat('This Week', '${disease.newCasesThisWeek}',
                    FontAwesomeIcons.calendarWeek),
                _buildDiseaseStat('This Month', '${disease.newCasesThisMonth}',
                    FontAwesomeIcons.calendarDays),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseStat(String label, String value, IconData icon) {
    return Column(
      children: [
        FaIcon(icon, size: 12, color: AppColors.textSecondary),
        SizedBox(height: 4),
        Text(value,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        Text(label,
            style: AppTheme.bodySmall
                .copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildResourcesTab() {
    if (_dashboard == null) return const Center(child: Text('No data'));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      children: [
        Row(
          children: [
            FaIcon(FontAwesomeIcons.boxesStacked,
                color: AppColors.primary, size: 16),
            SizedBox(width: AppTheme.spacingSm),
            Text('Resource Needs',
                style: AppTheme.headingSmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        ..._dashboard!.resourceNeeds.map((r) => _buildResourceCard(r)),
        SizedBox(height: 80),
      ],
    );
  }

  Widget _buildResourceCard(ResourceNeed resource) {
    Color priorityColor;
    IconData priorityIcon;
    switch (resource.priority) {
      case ResourcePriority.critical:
        priorityColor = AppColors.error;
        priorityIcon = FontAwesomeIcons.circleExclamation;
        break;
      case ResourcePriority.high:
        priorityColor = AppColors.warning;
        priorityIcon = FontAwesomeIcons.triangleExclamation;
        break;
      case ResourcePriority.medium:
        priorityColor = AppColors.info;
        priorityIcon = FontAwesomeIcons.circleInfo;
        break;
      case ResourcePriority.low:
        priorityColor = AppColors.success;
        priorityIcon = FontAwesomeIcons.circleCheck;
        break;
    }

    double stockPercentage = resource.currentStock / resource.quantityNeeded;
    Color stockColor = stockPercentage > 0.5
        ? AppColors.success
        : stockPercentage > 0.25
            ? AppColors.warning
            : AppColors.error;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(priorityIcon, color: priorityColor, size: 16),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.resourceType,
                        style: AppTheme.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.locationDot,
                            size: 10, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text(resource.location,
                            style: AppTheme.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resource.priority.name.toUpperCase(),
                  style: AppTheme.labelSmall.copyWith(
                      color: priorityColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),

          // Stock bar
          Container(
            padding: EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.boxOpen,
                            size: 10, color: AppColors.textSecondary),
                        SizedBox(width: 6),
                        Text(
                            'Stock: ${resource.currentStock}/${resource.quantityNeeded}',
                            style: AppTheme.bodySmall),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.arrowDown,
                              size: 8, color: AppColors.error),
                          SizedBox(width: 4),
                          Text('Deficit: ${resource.deficit}',
                              style: AppTheme.labelSmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: stockPercentage.clamp(0, 1),
                    backgroundColor: stockColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FaIcon(FontAwesomeIcons.noteSticky,
                  size: 10, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Expanded(
                child: Text(resource.reason,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAlerts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FaIcon(FontAwesomeIcons.bell,
                              color: AppColors.warning, size: 18),
                        ),
                        SizedBox(width: AppTheme.spacingSm),
                        Text('All Alerts', style: AppTheme.headingMedium),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(FontAwesomeIcons.xmark,
                            size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                  children: _dashboard?.activeAlerts
                          .map((a) => _buildAlertCard(a))
                          .toList() ??
                      [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            FaIcon(FontAwesomeIcons.fileArrowDown,
                color: Colors.white, size: 16),
            SizedBox(width: AppTheme.spacingSm),
            Text('Generating report...', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(AppTheme.spacingMd),
      ),
    );
  }
}
