import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/dashboard_api_service.dart';
import '../../services/notification_api_service.dart' as notification_api;
import '../patients/patient_list_screen.dart';
import '../patients/patient_registration_screen.dart';
import '../auth/login_screen.dart';
import '../../followups/followup_dashboard_screen.dart';
import '../library/library_home_screen.dart';
import '../referrals/referrals_dashboard_screen.dart';
import '../triage/smart_triage_screen.dart';
import '../training/training_home_screen.dart';
import '../dashboard/supervisor_dashboard_screen.dart';
import '../health_card/health_card_screen.dart';
import '../outbreak/outbreak_map_screen.dart';
import '../visual_diagnosis/visual_diagnosis_screen.dart';
import '../settings/settings_screen.dart';
import '../feedback/feedback_screen.dart';
import '../analytics/analytics_dashboard_screen.dart';
import '../notifications/notifications_screen.dart';
import '../supplies/supply_management_screen.dart';
import '../safety/safety_sos_screen.dart';
import '../community/community_engagement_screen.dart';
import '../wellbeing/wellbeing_support_screen.dart';
import '../messages/messages_screen.dart';
import '../weather/weather_alerts_screen.dart';
import '../knowledge/knowledge_pocket_screen.dart';
import '../health_graph/health_graph_screen.dart';
import '../registration/family_registration_screen.dart';
import '../travel/travel_log_screen.dart';
import '../settings/profile_screen.dart';
import '../ai/ai_service_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final DashboardApiService _dashboardApi = DashboardApiService.instance;
  final notification_api.NotificationApiService _notificationApi = notification_api.NotificationApiService.instance;
  int _selectedIndex = 0;
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;
  
  DashboardSummary? _dashboardSummary;
  bool _isDashboardLoading = false;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    
    // Header animation
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    // Content animation
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentAnimationController.forward();
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final patientProvider = context.read<PatientProvider>();

    if (authProvider.currentCHW != null) {
      // Load patient data (offline-first)
      await patientProvider.loadPatients(authProvider.currentCHW!.id);
      
      // Load dashboard summary (backend)
      _loadDashboardSummary();
      
      // Load notification count
      _loadNotificationCount();
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final response = await _notificationApi.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = response.unreadCount;
        });
      }
    } catch (e) {
      // Silently fail - don't show badge if API fails
      debugPrint('Failed to load notification count: $e');
    }
  }

  Future<void> _loadDashboardSummary() async {
    if (!mounted) return;
    
    setState(() => _isDashboardLoading = true);

    try {
      final summary = await _dashboardApi.getSummary();
      
      if (!mounted) return;
      
      setState(() {
        _dashboardSummary = summary;
        _isDashboardLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDashboardLoading = false);
      // Silently fail - local statistics still available
    }
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.logout, style: AppTheme.headingMedium),
        content: Text(l10n.translate('logoutConfirmation') ?? 'Are you sure you want to logout?', style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel, style: AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.logout, style: AppTheme.bodyMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final patientProvider = context.watch<PatientProvider>();

    final chw = authProvider.currentCHW;
    if (chw == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final stats = patientProvider.statistics;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Animated Header
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.3),
                      end: Offset.zero,
                    ).animate(_headerAnimation),
                    child: _buildHeader(chw.fullName, chw.village),
                  ),
                ),
              ),
              
              // Animated Stats Cards
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _contentAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(_contentAnimation),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      child: _buildStatsSection(stats),
                    ),
                  ),
                ),
              ),
              
              // Performance Summary from Backend
              if (_isDashboardLoading)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _contentAnimation,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppTheme.spacingMd, 
                        AppTheme.spacingSm, 
                        AppTheme.spacingMd, 
                        AppTheme.spacingMd
                      ),
                      child: Container(
                        padding: EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                )
              else if (_dashboardSummary != null)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _contentAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(_contentAnimation),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppTheme.spacingMd, 
                          AppTheme.spacingSm, 
                          AppTheme.spacingMd, 
                          AppTheme.spacingMd
                        ),
                        child: _buildPerformanceSummary(_dashboardSummary!),
                      ),
                    ),
                  ),
                ),
              
              // Animated Quick Actions Grid
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _contentAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(_contentAnimation),
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      child: _buildQuickActionsGrid(),
                    ),
                  ),
                ),
              ),
              
              // Animated Feature Cards
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _contentAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(_contentAnimation),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      child: _buildFeaturesList(),
                    ),
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _contentAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PatientRegistrationScreen()),
            ).then((_) => _loadData());
          },
          backgroundColor: AppColors.primary,
          elevation: 4,
          icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 18),
          label: Text(AppLocalizations.of(context).newPatient, style: AppTheme.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(String name, String? village) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.heartPulse,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: AppTheme.spacingSm),
                          Text(
                            'UbuntuHealth',
                            style: AppTheme.headingLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingSm),
                      Text(
                        AppLocalizations.of(context).welcomeUser(name.split(' ').first),
                        style: AppTheme.bodyLarge.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildHeaderIconButton(FontAwesomeIcons.gear, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    }),
                    SizedBox(width: AppTheme.spacingSm),
                    _buildHeaderIconButton(FontAwesomeIcons.bell, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ).then((_) => _loadNotificationCount()); // Refresh count when returning
                    }, badge: _unreadNotificationCount > 0 ? (_unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount') : null),
                    SizedBox(width: AppTheme.spacingSm),
                    _buildHeaderIconButton(FontAwesomeIcons.rightFromBracket, _handleLogout),
                  ],
                ),
              ],
            ),
            if (village != null) ...[
              SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(FontAwesomeIcons.locationDot, color: Colors.white, size: 14),
                    SizedBox(width: AppTheme.spacingSm),
                    Text(
                      village,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppTheme.spacingLg),
            // Enhanced Search Bar
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientListScreen()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingMd,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        '${AppLocalizations.of(context).search} patients by name or ID...',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        AppLocalizations.of(context).search,
                        style: AppTheme.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, VoidCallback onTap, {String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            FaIcon(icon, color: Colors.white, size: 18),
            if (badge != null)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, int> stats) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.chartPie, color: AppColors.primary, size: 16),
              SizedBox(width: AppTheme.spacingSm),
              Text(
                l10n.todayOverview,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: l10n.patients,
                  value: '${stats['totalPatients'] ?? 0}',
                  icon: FontAwesomeIcons.users,
                  color: AppColors.info,
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildStatCard(
                  title: l10n.visits,
                  value: '${stats['totalVisits'] ?? 0}',
                  icon: FontAwesomeIcons.stethoscope,
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildStatCard(
                  title: l10n.highRisk,
                  value: '${stats['highRiskPatients'] ?? 0}',
                  icon: FontAwesomeIcons.triangleExclamation,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildStatCard(
                  title: l10n.followups,
                  value: '${stats['pendingFollowUps'] ?? 0}',
                  icon: FontAwesomeIcons.clock,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 18),
          SizedBox(height: AppTheme.spacingXs),
          Text(
            value,
            style: AppTheme.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(FontAwesomeIcons.bolt, color: AppColors.primary, size: 16),
            SizedBox(width: AppTheme.spacingSm),
            Text(l10n.quickActions, style: AppTheme.headingSmall.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionTile(
                icon: FontAwesomeIcons.userPlus,
                label: l10n.registerPatient.replaceAll(' ', '\n'),
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientRegistrationScreen()),
                  ).then((_) => _loadData());
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildQuickActionTile(
                icon: FontAwesomeIcons.heartPulse,
                label: l10n.smartTriage.replaceAll(' ', '\n'),
                color: AppColors.error,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SmartTriageScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildQuickActionTile(
                icon: FontAwesomeIcons.idCard,
                label: l10n.healthCard.replaceAll(' ', '\n'),
                color: AppColors.info,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthCardScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildQuickActionTile(
                icon: FontAwesomeIcons.graduationCap,
                label: l10n.trainingCenter.replaceAll(' ', '\n'),
                color: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrainingHomeScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.spacingMd,
          horizontal: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, color: color, size: 20),
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              label,
              style: AppTheme.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(FontAwesomeIcons.grip, color: AppColors.primary, size: 16),
            SizedBox(width: AppTheme.spacingSm),
            Text(l10n.features, style: AppTheme.headingSmall.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: AppTheme.spacingMd),
        
        // Two-column grid for features
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.allPatients,
                icon: FontAwesomeIcons.users,
                iconColor: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientListScreen()),
                  ).then((_) => _loadData());
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.highRisk,
                icon: FontAwesomeIcons.triangleExclamation,
                iconColor: AppColors.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientListScreen(showHighRiskOnly: true),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.followups,
                icon: FontAwesomeIcons.calendarCheck,
                iconColor: AppColors.error,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FollowupDashboardScreen()),
                  ).then((_) => _loadData());
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.outbreaks,
                icon: FontAwesomeIcons.mapLocationDot,
                iconColor: AppColors.error,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OutbreakMapScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.medicalLibrary,
                icon: FontAwesomeIcons.bookMedical,
                iconColor: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LibraryHomeScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.referrals,
                icon: FontAwesomeIcons.hospitalUser,
                iconColor: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReferralsDashboardScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.visualDiagnosis,
                icon: FontAwesomeIcons.camera,
                iconColor: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VisualDiagnosisScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.dashboard,
                icon: FontAwesomeIcons.chartLine,
                iconColor: AppColors.info,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupervisorDashboardScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.analytics,
                icon: FontAwesomeIcons.chartPie,
                iconColor: AppColors.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.feedback,
                icon: FontAwesomeIcons.commentDots,
                iconColor: AppColors.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        
        // Messages & Supplies Row
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.messages,
                icon: FontAwesomeIcons.comments,
                iconColor: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MessagesScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.supplies,
                icon: FontAwesomeIcons.boxesStacked,
                iconColor: AppColors.info,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupplyManagementScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        
        // Emergency SOS & Community Row
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.emergencySOS,
                icon: FontAwesomeIcons.shieldHeart,
                iconColor: AppColors.error,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SafetySOSScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.community,
                icon: FontAwesomeIcons.peopleGroup,
                iconColor: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CommunityEngagementScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        
        // Wellbeing & Weather Row
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.wellbeing,
                icon: FontAwesomeIcons.handHoldingHeart,
                iconColor: AppColors.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WellbeingSupportScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.weatherAlerts,
                icon: FontAwesomeIcons.cloudBolt,
                iconColor: AppColors.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeatherAlertsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        
        // Knowledge & Health Graph Row
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.knowledgePocket,
                icon: FontAwesomeIcons.bookMedical,
                iconColor: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KnowledgePocketScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.healthGraph,
                icon: FontAwesomeIcons.diagramProject,
                iconColor: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthGraphScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        
        // Family Registration & Travel Log Row
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.translate('registerFamily') ?? 'Register Family',
                icon: FontAwesomeIcons.peopleRoof,
                iconColor: AppColors.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FamilyRegistrationScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.translate('travelLog') ?? 'Travel Log',
                icon: FontAwesomeIcons.mapMarkedAlt,
                iconColor: AppColors.info,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TravelLogScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),
        
        // Profile & AI Assistant Row
        Row(
          children: [
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.translate('profile') ?? 'My Profile',
                icon: FontAwesomeIcons.userCircle,
                iconColor: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildFeatureCardCompact(
                title: l10n.translate('aiAssistant') ?? 'AI Assistant',
                icon: FontAwesomeIcons.robot,
                iconColor: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AIServiceScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFeatureCardCompact({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(icon, color: iconColor, size: 18),
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                title,
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            FaIcon(FontAwesomeIcons.chevronRight, color: AppColors.textSecondary, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(FontAwesomeIcons.house, l10n.home, 0),
              _buildNavItem(FontAwesomeIcons.users, l10n.patients, 1),
              _buildNavItem(FontAwesomeIcons.stethoscope, l10n.triage, 2),
              _buildNavItem(FontAwesomeIcons.graduationCap, l10n.learn, 3),
              _buildNavItem(FontAwesomeIcons.chartLine, l10n.stats, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        switch (index) {
          case 1:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientListScreen()));
            break;
          case 2:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartTriageScreen()));
            break;
          case 3:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingHomeScreen()));
            break;
          case 4:
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorDashboardScreen()));
            break;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? AppTheme.spacingMd : AppTheme.spacingSm,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: isActive ? 22 : 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary(DashboardSummary summary) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                  FontAwesomeIcons.chartLine,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('performanceSummary') ?? 'Performance Summary',
                      style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      l10n.translate('last30Days') ?? 'Last 30 days',
                      style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  label: l10n.translate('totalVisits') ?? 'Visits',
                  value: '${summary.monthVisits}',
                  icon: FontAwesomeIcons.stethoscope,
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildPerformanceMetric(
                  label: l10n.translate('referrals') ?? 'Referrals',
                  value: '${summary.activeReferrals}',
                  icon: FontAwesomeIcons.hospital,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _buildPerformanceMetric(
                  label: l10n.translate('alerts') ?? 'Alerts',
                  value: '${summary.criticalAlerts}',
                  icon: FontAwesomeIcons.triangleExclamation,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 16),
          SizedBox(height: AppTheme.spacingXs),
          Text(
            value,
            style: AppTheme.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
