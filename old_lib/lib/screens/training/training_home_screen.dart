import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/training_module.dart';
import '../../services/training_service.dart';
import '../../services/training_api_service.dart';
import '../../models/training_models.dart' as api;
import '../../l10n/app_localizations.dart';
import 'module_content_screen.dart';

class TrainingHomeScreen extends StatefulWidget {
  const TrainingHomeScreen({super.key});

  @override
  State<TrainingHomeScreen> createState() => _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends State<TrainingHomeScreen>
    with SingleTickerProviderStateMixin {
  final TrainingService _trainingService = TrainingService();
  final TrainingApiService _trainingApi = TrainingApiService.instance;

  CHWTrainingProgress? _progress;
  api.TrainingProgressResponse? _apiProgress;
  // TODO: May be needed later
  // api.LeaderboardResponse? _leaderboard;
  DailyQuiz? _dailyQuiz;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  // TODO: May be needed later
  // String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      // _error = null;
    });

    try {
      // Try to load from API first
      final results = await Future.wait([
        _trainingApi.getTrainingProgress(),
        _trainingApi.getLeaderboard(period: 'weekly', limit: 10),
      ]);

      setState(() {
        _apiProgress = results[0] as api.TrainingProgressResponse;
        // Leaderboard loaded but not currently used
        // _leaderboard = results[1] as api.LeaderboardResponse;
        _isLoading = false;
      });
    } catch (e) {
      // Fall back to local data if API fails
      debugPrint('Training API error: $e');
      setState(() {
        _isLoading = false;
      });
      _loadLocalData();
    }

    // Always load daily quiz from local service for now
    _loadLocalData();
  }

  void _loadLocalData() {
    setState(() {
      _progress = _trainingService.getProgress('current_chw');
      _dailyQuiz = _trainingService.generateDailyQuiz('current_chw');
    });
  }

  @override
  Widget build(BuildContext context) {
    final modules = _trainingService.getAllModules();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ListView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.all(AppTheme.spacingMd),
                          children: [
                            // Progress Card
                            _buildProgressCard(),
                            SizedBox(height: AppTheme.spacingMd),

                            // Daily Quiz Card
                            if (_dailyQuiz != null && !_dailyQuiz!.isCompleted)
                              _buildDailyQuizCard(),

                            // Categories Section
                            Row(
                              children: [
                                FaIcon(FontAwesomeIcons.bookOpen,
                                    color: AppColors.primary, size: 16),
                                SizedBox(width: AppTheme.spacingSm),
                                Text(
                                    AppLocalizations.of(context)
                                            .translate('trainingModules') ??
                                        'Training Modules',
                                    style: AppTheme.headingSmall
                                        .copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            SizedBox(height: AppTheme.spacingSm),

                            // Module Categories
                            for (var category in TrainingCategory.values)
                              _buildCategorySection(category, modules),

                            SizedBox(height: 80),
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

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
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
                  l10n.translate('trainingCenterTitle') ?? 'Training Center',
                  style: AppTheme.headingMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  l10n.translate('learnAndGrow') ??
                      'Learn and grow your skills',
                  style: AppTheme.bodySmall
                      .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showBadges(),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(FontAwesomeIcons.trophy,
                  color: AppColors.warning, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _progress;
    final apiProg = _apiProgress;
    final l10n = AppLocalizations.of(context);

    // Use API data if available, otherwise fall back to local
    final modulesCompleted =
        apiProg?.completedModules ?? progress?.totalModulesCompleted ?? 0;
    // Quizzes passed available via: apiProg?.totalQuizzesPassed ?? progress?.totalQuizzesPassed ?? 0
    final badgeCount =
        apiProg?.certifications.length ?? progress?.badges.length ?? 0;
    final currentStreak = progress?.currentStreak ?? 0;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.chartLine,
                          color: AppColors.primary, size: 16),
                      SizedBox(width: AppTheme.spacingSm),
                      Text(
                        l10n.translate('yourProgress') ?? 'Your Progress',
                        style: AppTheme.headingSmall
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$modulesCompleted ${l10n.translate('completed') ?? 'Completed'}',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(14),
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
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FaIcon(FontAwesomeIcons.graduationCap,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),

          // Progress bar to next level
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      l10n.translate('progressToNextLevel') ??
                          'Progress to next level',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppColors.textSecondary)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_getProgressPercent()}%',
                        style: AppTheme.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingXs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: LinearProgressIndicator(
                  value: _getProgressPercent() / 100,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),

          // Stats row
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressStat(
                    FontAwesomeIcons.circleCheck,
                    '$modulesCompleted',
                    l10n.translate('completed') ?? 'Completed',
                    AppColors.success),
                Container(width: 1, height: 40, color: AppColors.divider),
                _buildProgressStat(
                    FontAwesomeIcons.fire,
                    '$currentStreak',
                    l10n.translate('dayStreak') ?? 'Day Streak',
                    AppColors.warning),
                Container(width: 1, height: 40, color: AppColors.divider),
                _buildProgressStat(FontAwesomeIcons.medal, '$badgeCount',
                    l10n.translate('badges') ?? 'Badges', AppColors.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: FaIcon(icon, color: color, size: 16),
        ),
        SizedBox(height: AppTheme.spacingXs),
        Text(value,
            style: AppTheme.headingSmall.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  int _getProgressPercent() {
    final modules = _progress?.totalModulesCompleted ?? 0;
    // Show progress based on modules completed (target: 10 modules = 100%)
    return ((modules / 10) * 100).clamp(0, 100).round();
  }

  Widget _buildDailyQuizCard() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            AppColors.secondary.withValues(alpha: 0.8)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: FaIcon(FontAwesomeIcons.lightbulb,
                color: Colors.white, size: 24),
          ),
          SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.translate('dailyQuiz') ?? 'Daily Quiz',
                    style: AppTheme.headingSmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text(
                    l10n.translate('quizDescription') ??
                        '5 questions • Earn bonus points!',
                    style: AppTheme.bodySmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _startDailyQuiz(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.secondary,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              children: [
                Text(l10n.translate('start') ?? 'Start',
                    style: AppTheme.labelMedium.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600)),
                SizedBox(width: 6),
                FaIcon(FontAwesomeIcons.arrowRight,
                    color: AppColors.secondary, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      TrainingCategory category, List<TrainingModule> allModules) {
    final categoryModules =
        allModules.where((m) => m.category == category).toList();
    if (categoryModules.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppTheme.spacingMd),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(_getCategoryIcon(category),
                  color: AppColors.primary, size: 14),
              SizedBox(width: AppTheme.spacingSm),
              Text(_getCategoryName(category),
                  style: AppTheme.labelMedium.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        SizedBox(height: AppTheme.spacingSm),
        ...categoryModules.map((module) => _buildModuleCard(module)),
      ],
    );
  }

  Widget _buildModuleCard(TrainingModule module) {
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
      child: InkWell(
        onTap: () => _openModule(module),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Icon or completion indicator
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: module.isCompleted
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: FaIcon(
                    module.isCompleted
                        ? FontAwesomeIcons.circleCheck
                        : FontAwesomeIcons.play,
                    color: module.isCompleted
                        ? AppColors.success
                        : AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacingMd),

              // Module info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title,
                        style: AppTheme.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: AppTheme.spacingXs),
                    Text(
                      module.description,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        _buildModuleInfoTag(
                            FontAwesomeIcons.clock, _formatModuleInfo(module)),
                        SizedBox(width: AppTheme.spacingSm),
                        _buildModuleInfoTag(
                            FontAwesomeIcons.file, _formatLessonsInfo(module)),
                      ],
                    ),
                    // Progress indicator
                    if (module.completionPercentage > 0 &&
                        !module.isCompleted) ...[
                      SizedBox(height: AppTheme.spacingSm),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusFull),
                              child: LinearProgressIndicator(
                                value: module.completionPercentage / 100,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('${module.completionPercentage}%',
                              style: AppTheme.labelSmall
                                  .copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              FaIcon(FontAwesomeIcons.chevronRight,
                  color: AppColors.textSecondary, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleInfoTag(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 10, color: AppColors.textSecondary),
          SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _formatModuleInfo(TrainingModule module) {
    final l10n = AppLocalizations.of(context);
    final minLabel = l10n.translate('min') ?? 'min';
    return '${module.estimatedMinutes} $minLabel';
  }

  String _formatLessonsInfo(TrainingModule module) {
    final l10n = AppLocalizations.of(context);
    final lessonsLabel = l10n.translate('lessons') ?? 'lessons';
    return '${module.sections.length} $lessonsLabel';
  }

  IconData _getCategoryIcon(TrainingCategory category) {
    switch (category) {
      case TrainingCategory.maternal:
        return FontAwesomeIcons.personPregnant;
      case TrainingCategory.childHealth:
        return FontAwesomeIcons.baby;
      case TrainingCategory.infectious:
        return FontAwesomeIcons.virus;
      case TrainingCategory.chronic:
        return FontAwesomeIcons.heartCirclePlus;
      case TrainingCategory.emergency:
        return FontAwesomeIcons.truckMedical;
      case TrainingCategory.nutrition:
        return FontAwesomeIcons.appleWhole;
      case TrainingCategory.mentalHealth:
        return FontAwesomeIcons.brain;
      case TrainingCategory.community:
        return FontAwesomeIcons.users;
      case TrainingCategory.general:
        return FontAwesomeIcons.bookMedical;
    }
  }

  String _getCategoryName(TrainingCategory category) {
    final l10n = AppLocalizations.of(context);
    switch (category) {
      case TrainingCategory.maternal:
        return l10n.translate('maternalHealth') ?? 'Maternal Health';
      case TrainingCategory.childHealth:
        return l10n.translate('childHealth') ?? 'Child Health';
      case TrainingCategory.infectious:
        return l10n.translate('infectiousDiseases') ?? 'Infectious Diseases';
      case TrainingCategory.chronic:
        return l10n.translate('chronicDiseases') ?? 'Chronic Diseases';
      case TrainingCategory.emergency:
        return l10n.translate('emergencyResponse') ?? 'Emergency Response';
      case TrainingCategory.nutrition:
        return l10n.translate('nutrition') ?? 'Nutrition';
      case TrainingCategory.mentalHealth:
        return l10n.translate('mentalHealth') ?? 'Mental Health';
      case TrainingCategory.community:
        return l10n.translate('communityHealth') ?? 'Community Health';
      case TrainingCategory.general:
        return l10n.translate('generalSkills') ?? 'General Skills';
    }
  }

  void _openModule(TrainingModule module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModuleDetailScreen(module: module),
      ),
    );
  }

  void _startDailyQuiz() {
    if (_dailyQuiz == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          quiz: Quiz(
            id: _dailyQuiz!.id,
            title: 'Daily Quiz',
            questions: _dailyQuiz!.questions,
            passingScore: 60,
          ),
        ),
      ),
    );
  }

  void _showBadges() {
    final badges = _progress?.badges ?? [];
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMd)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.translate('yourBadges') ?? 'Your Badges',
                style: AppTheme.headingMedium),
            const SizedBox(height: AppTheme.spacingMd),
            if (badges.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(l10n.translate('noBadgesYet') ?? 'No badges yet',
                          style: AppTheme.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      Text(
                          l10n.translate('completeQuizzesToEarnBadges') ??
                              'Complete quizzes to earn badges!',
                          style: AppTheme.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: AppTheme.spacingMd,
                runSpacing: AppTheme.spacingMd,
                children:
                    badges.map((badge) => _buildBadgeItem(badge)).toList(),
              ),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeItem(TrainingBadge badge) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(Icons.emoji_events, color: AppColors.warning, size: 32),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            badge.name,
            style: AppTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Module Detail Screen
class ModuleDetailScreen extends StatelessWidget {
  final TrainingModule module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(module.title,
            style: AppTheme.headingSmall.copyWith(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Module Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(module.description, style: AppTheme.bodyMedium),
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  children: [
                    _buildInfoChip(
                        Icons.timer, '${module.estimatedMinutes} min'),
                    const SizedBox(width: AppTheme.spacingSm),
                    _buildInfoChip(
                        Icons.article, '${module.sections.length} lessons'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Objectives (extracted from sections' key points)
          Text('Learning Objectives', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              children: module.sections
                  .expand((section) => section.keyPoints)
                  .take(5)
                  .map((obj) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: AppColors.success, size: 18),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                                child: Text(obj, style: AppTheme.bodyMedium)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Lessons
          Text('Lessons', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingSm),
          ...module.sections
              .asMap()
              .entries
              .map((entry) => _buildLessonCard(entry.key + 1, entry.value)),
          const SizedBox(height: AppTheme.spacingMd),

          // Start Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModuleContentScreen(module: module),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
            ),
            child: Text(module.isCompleted ? 'Review Module' : 'Start Module',
                style: AppTheme.labelMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text,
              style: AppTheme.labelSmall.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildLessonCard(int number, LearningSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Center(
              child: Text('$number',
                  style:
                      AppTheme.labelMedium.copyWith(color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(child: Text(section.title, style: AppTheme.bodyMedium)),
          Icon(
              section.isCompleted
                  ? Icons.check_circle
                  : Icons.play_circle_outline,
              color:
                  section.isCompleted ? AppColors.success : AppColors.primary),
        ],
      ),
    );
  }
}

// Quiz Screen
class QuizScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  final Map<String, int> _answers = {};
  bool _showResults = false;

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return _buildResultsScreen();
    }

    final question = widget.quiz.questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.quiz.title,
            style: AppTheme.headingSmall.copyWith(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Progress
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.quiz.questions.length,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_currentIndex + 1} of ${widget.quiz.questions.length}',
                    style: AppTheme.labelMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(question.question, style: AppTheme.headingSmall),
                  const SizedBox(height: AppTheme.spacingLg),

                  // Options
                  ...question.options.asMap().entries.map((entry) {
                    final isSelected = _answers[question.id] == entry.key;
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _answers[question.id] = entry.key;
                          });
                        },
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                  child: Text(entry.value,
                                      style: AppTheme.bodyMedium)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Navigation
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppTheme.shadowMd,
            ),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentIndex--),
                    child: const Text('Previous'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _answers[question.id] != null
                      ? () {
                          if (_currentIndex <
                              widget.quiz.questions.length - 1) {
                            setState(() => _currentIndex++);
                          } else {
                            setState(() => _showResults = true);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentIndex < widget.quiz.questions.length - 1
                        ? 'Next'
                        : 'Finish',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    int correct = 0;
    for (var question in widget.quiz.questions) {
      if (_answers[question.id] == question.correctAnswer) {
        correct++;
      }
    }
    double score = (correct / widget.quiz.questions.length) * 100;
    bool passed = score >= widget.quiz.passingScore;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Quiz Results',
            style: AppTheme.headingSmall.copyWith(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          // Score Card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: passed ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              children: [
                Icon(
                  passed ? Icons.celebration : Icons.refresh,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  passed ? 'Congratulations!' : 'Keep Learning!',
                  style: AppTheme.headingMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  '${score.toStringAsFixed(0)}%',
                  style: AppTheme.headingLarge
                      .copyWith(color: Colors.white, fontSize: 48),
                ),
                Text(
                  '$correct out of ${widget.quiz.questions.length} correct',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Answers Review
          Text('Review Answers', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingSm),
          ...widget.quiz.questions.map((q) => _buildAnswerReview(q)),
          const SizedBox(height: AppTheme.spacingMd),

          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
            ),
            child: Text('Done',
                style: AppTheme.labelMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerReview(QuizQuestion question) {
    final selected = _answers[question.id];
    final isCorrect = selected == question.correctAnswer;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isCorrect ? AppColors.success : AppColors.error,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                  child: Text(question.question, style: AppTheme.labelMedium)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Your answer: ${selected != null ? question.options[selected] : "Not answered"}',
            style: AppTheme.bodySmall.copyWith(
              color: isCorrect ? AppColors.success : AppColors.error,
            ),
          ),
          if (!isCorrect) ...[
            Text(
              'Correct answer: ${question.options[question.correctAnswer]}',
              style: AppTheme.bodySmall.copyWith(color: AppColors.success),
            ),
          ],
          if (question.explanation != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              question.explanation!,
              style:
                  AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
