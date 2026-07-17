import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/wellbeing_api_service.dart';

class WellbeingSupportScreen extends StatefulWidget {
  const WellbeingSupportScreen({super.key});

  @override
  State<WellbeingSupportScreen> createState() => _WellbeingSupportScreenState();
}

class _WellbeingSupportScreenState extends State<WellbeingSupportScreen> {
  final WellbeingApiService _wellbeingApi = WellbeingApiService.instance;
  int? _todayMood;
  List<MoodLog> _moodHistory = [];
  List<WellbeingResource> _resources = [];
  List<Helpline> _helplines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load mood logs, resources, and helplines in parallel
      final results = await Future.wait([
        _wellbeingApi.getMoodLogs(perPage: 30),
        _wellbeingApi.getResources(perPage: 100),
        _wellbeingApi.getHelplines(),
      ]);

      final moodLogsResponse = results[0] as MoodLogListResponse;
      final resourcesResponse = results[1] as ResourceListResponse;
      final helplines = results[2] as List<Helpline>;

      setState(() {
        _moodHistory = moodLogsResponse.data;
        _resources = resourcesResponse.data;
        _helplines = helplines;
        _isLoading = false;

        // Set today's mood if exists
        final today = DateTime.now();
        final todayLog = _moodHistory.cast<MoodLog?>().firstWhere(
              (log) =>
                  log != null &&
                  log.loggedAt.year == today.year &&
                  log.loggedAt.month == today.month &&
                  log.loggedAt.day == today.day,
              orElse: () => null,
            );
        if (todayLog != null) {
          _todayMood = todayLog.moodRating;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logMood(int level, String? notes) async {
    try {
      // Convert 1-5 scale to 1-10 scale for API
      final moodScore = (level * 2).clamp(1, 10);
      final newLog = await _wellbeingApi.logMood(
        moodScore: moodScore,
        notes: notes,
      );

      setState(() {
        _todayMood = level;
        _moodHistory.insert(0, newLog);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood logged successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to log mood: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showMoodNoteDialog(int level) {
    final noteController = TextEditingController();
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(_getMoodEmoji(level), style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(l10n.translate('addNote') ?? 'Add a Note',
                style: AppTheme.headingMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.translate('wouldYouLikeToAddNotes') ??
                  'Would you like to add any notes about how you\'re feeling?',
              style:
                  AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.translate('optionalShareThoughts') ??
                    'Optional: Share your thoughts...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.translate('skip') ?? 'Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final notes = noteController.text.trim();
              _logMood(level, notes.isEmpty ? null : notes);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('save') ?? 'Save'),
          ),
        ],
      ),
    );
  }

  void _showAnonymousFeedbackDialog() {
    final feedbackController = TextEditingController();
    final l10n = AppLocalizations.of(context);
    SupportRequestType selectedRequestType = SupportRequestType.peerSupport;

    // Map UI categories to SupportRequestType enum
    final categories = [
      {
        'key': 'workEnvironment',
        'fallback': 'Work Environment',
        'type': SupportRequestType.peerSupport
      },
      {
        'key': 'supervision',
        'fallback': 'Supervision',
        'type': SupportRequestType.professionalReferral
      },
      {
        'key': 'resourcesLabel',
        'fallback': 'Resources',
        'type': SupportRequestType.peerSupport
      },
      {
        'key': 'safetyConcerns',
        'fallback': 'Safety Concerns',
        'type': SupportRequestType.crisisIntervention
      },
      {
        'key': 'suggestions',
        'fallback': 'Suggestions',
        'type': SupportRequestType.peerSupport
      },
      {
        'key': 'counseling',
        'fallback': 'Counseling',
        'type': SupportRequestType.counseling
      },
    ];
    // Track selected category label for submission (used in onChanged)
    // ignore: unused_local_variable
    String selectedCategoryLabel = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              FaIcon(FontAwesomeIcons.userSecret,
                  color: AppColors.primary, size: 20),
              SizedBox(width: 12),
              Text(l10n.translate('anonymousFeedback') ?? 'Anonymous Feedback',
                  style: AppTheme.headingMedium),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.shieldHalved,
                          color: AppColors.info, size: 14),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.translate('feedbackAnonymousConfidential') ??
                              'Your feedback is completely anonymous and confidential',
                          style: AppTheme.labelSmall
                              .copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                Text(l10n.translate('category') ?? 'Category',
                    style: AppTheme.labelMedium),
                SizedBox(height: 8),
                DropdownButtonFormField<SupportRequestType>(
                  initialValue: selectedRequestType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem<SupportRequestType>(
                            value: c['type'] as SupportRequestType,
                            child: Text(l10n.translate(c['key'] as String) ??
                                c['fallback'] as String),
                          ))
                      .toList(),
                  onChanged: (value) => setDialogState(() {
                    selectedRequestType = value!;
                    final cat =
                        categories.firstWhere((c) => c['type'] == value);
                    selectedCategoryLabel =
                        l10n.translate(cat['key'] as String) ??
                            cat['fallback'] as String;
                  }),
                ),
                SizedBox(height: AppTheme.spacingMd),
                Text(l10n.translate('yourFeedback') ?? 'Your Feedback',
                    style: AppTheme.labelMedium),
                SizedBox(height: 8),
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: l10n.translate('shareFeedbackPlaceholder') ??
                        'Share your thoughts, concerns, or suggestions...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (feedbackController.text.isNotEmpty) {
                  Navigator.pop(context);

                  try {
                    await _wellbeingApi.requestSupport(
                      requestType: selectedRequestType,
                      description: feedbackController.text.trim(),
                      isAnonymous: true,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.circleCheck,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 12),
                              Text(l10n.translate(
                                      'feedbackSubmittedAnonymously') ??
                                  'Feedback submitted anonymously. Thank you!'),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to submit feedback: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                  l10n.translate('submitAnonymously') ?? 'Submit Anonymously',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showResourceDetails(WellbeingResource resource) {
    final l10n = AppLocalizations.of(context);
    final resourceColor = _getResourceColor(resource.type);
    final resourceIcon = _getResourceIcon(resource.type);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: resourceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        FaIcon(resourceIcon, color: resourceColor, size: 40),
                        SizedBox(height: AppTheme.spacingMd),
                        Text(resource.title,
                            style: AppTheme.headingMedium,
                            textAlign: TextAlign.center),
                        SizedBox(height: AppTheme.spacingSm),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: resourceColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            resource.type.toUpperCase(),
                            style: AppTheme.labelSmall.copyWith(
                                color: resourceColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMd),
                  Text(resource.description, style: AppTheme.bodyMedium),
                  SizedBox(height: AppTheme.spacingLg),

                  // Sample content based on resource type
                  if (resource.type == 'exercises') ...[
                    Text(l10n.translate('quickExercises') ?? 'Quick Exercises',
                        style: AppTheme.labelLarge),
                    SizedBox(height: AppTheme.spacingSm),
                    _buildExerciseItem(
                        '1',
                        l10n.translate('deepBreathing') ?? 'Deep Breathing',
                        '2 minutes'),
                    _buildExerciseItem('2',
                        l10n.translate('bodyScan') ?? 'Body Scan', '3 minutes'),
                    _buildExerciseItem(
                        '3',
                        l10n.translate('gratitudeMoment') ?? 'Gratitude Moment',
                        '1 minute'),
                  ],

                  SizedBox(height: AppTheme.spacingLg),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(l10n.translate('openingResource') ??
                                'Opening resource...'),
                            behavior: SnackBarBehavior.floating),
                      );
                    },
                    icon: FaIcon(FontAwesomeIcons.bookOpen,
                        size: 16, color: Colors.white),
                    label: Text(
                        l10n.translate('readFullArticle') ??
                            'Read Full Article',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: resourceColor,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      minimumSize: Size(double.infinity, 0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(String number, String title, String duration) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: AppTheme.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600))),
          Text(duration,
              style:
                  AppTheme.labelSmall.copyWith(color: AppColors.textSecondary)),
          SizedBox(width: 8),
          FaIcon(FontAwesomeIcons.play, color: AppColors.primary, size: 14),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(FontAwesomeIcons.triangleExclamation,
                                  size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text('Error: $_error',
                                  style: AppTheme.bodyMedium),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: const FaIcon(
                                    FontAwesomeIcons.arrowsRotate,
                                    size: 14),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView(
                            padding: EdgeInsets.all(AppTheme.spacingMd),
                            children: [
                              // Daily Check-in
                              _buildMoodCheckIn(),
                              SizedBox(height: AppTheme.spacingMd),

                              // Quick Actions
                              _buildQuickActions(),
                              SizedBox(height: AppTheme.spacingMd),

                              // Helplines
                              _buildHelplines(),
                              SizedBox(height: AppTheme.spacingMd),

                              // Resources
                              _buildResources(),
                              SizedBox(height: AppTheme.spacingMd),

                              // Mood History
                              _buildMoodHistory(),
                              const SizedBox(height: 24),
                            ],
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
          colors: [AppColors.primary, AppColors.primary.withBlue(200)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
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
                    l10n.wellbeing,
                    style: AppTheme.headingMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l10n.translate('yourMentalHealthMatters') ??
                        'Your mental health matters',
                    style: AppTheme.bodySmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCheckIn() {
    final l10n = AppLocalizations.of(context);
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
          Text(
              l10n.translate('howAreYouFeelingToday') ??
                  'How are you feeling today?',
              style: AppTheme.labelLarge),
          SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final level = index + 1;
              final isSelected = _todayMood == level;
              return GestureDetector(
                onTap: () => _showMoodNoteDialog(level),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getMoodColor(level).withValues(alpha: 0.2)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: _getMoodColor(level), width: 2)
                            : null,
                      ),
                      child: Text(_getMoodEmoji(level),
                          style: TextStyle(fontSize: 28)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getMoodLabel(level, l10n),
                      style: AppTheme.labelSmall.copyWith(
                        color: isSelected
                            ? _getMoodColor(level)
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: FontAwesomeIcons.userSecret,
            title: l10n.translate('anonymousFeedback') ?? 'Anonymous Feedback',
            color: AppColors.info,
            onTap: _showAnonymousFeedbackDialog,
          ),
        ),
        SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: _buildActionCard(
            icon: FontAwesomeIcons.comments,
            title: l10n.translate('talkToCounselor') ?? 'Talk to Counselor',
            color: AppColors.secondary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(l10n.translate('connectingToCounselor') ??
                        'Connecting to counselor...'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 24),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              title,
              style: AppTheme.labelMedium
                  .copyWith(color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelplines() {
    final l10n = AppLocalizations.of(context);
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
            children: [
              FaIcon(FontAwesomeIcons.phone,
                  color: AppColors.primary, size: 16),
              SizedBox(width: AppTheme.spacingSm),
              Text(l10n.translate('supportHelplines') ?? 'Support Helplines',
                  style: AppTheme.labelLarge),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          ..._helplines.map((helpline) => _buildHelplineItem(helpline)),
        ],
      ),
    );
  }

  Widget _buildHelplineItem(Helpline helpline) {
    // Determine icon based on services or name
    final IconData helplineIcon =
        helpline.name.toLowerCase().contains('emergency') ||
                helpline.services.contains('emergency')
            ? FontAwesomeIcons.circleExclamation
            : helpline.hoursOfOperation?.contains('24') == true
                ? FontAwesomeIcons.phone
                : FontAwesomeIcons.headset;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(helplineIcon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(helpline.name,
                    style: AppTheme.labelMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text(helpline.phone,
                        style: AppTheme.bodySmall
                            .copyWith(color: AppColors.primary)),
                    if (helpline.hoursOfOperation != null) ...[
                      const SizedBox(width: 8),
                      Text('• ${helpline.hoursOfOperation}',
                          style: AppTheme.labelSmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Calling ${helpline.name}...'),
                    behavior: SnackBarBehavior.floating),
              );
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  FaIcon(FontAwesomeIcons.phone, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResources() {
    final l10n = AppLocalizations.of(context);
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
              Text(
                  l10n.translate('wellbeingResources') ?? 'Wellbeing Resources',
                  style: AppTheme.labelLarge),
              Text(l10n.translate('seeAll') ?? 'See All',
                  style:
                      AppTheme.labelSmall.copyWith(color: AppColors.primary)),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _resources.length,
              itemBuilder: (context, index) =>
                  _buildResourceCard(_resources[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(WellbeingResource resource) {
    final resourceColor = _getResourceColor(resource.type);
    final resourceIcon = _getResourceIcon(resource.type);
    return GestureDetector(
      onTap: () => _showResourceDetails(resource),
      child: Container(
        width: 160,
        margin: EdgeInsets.only(right: AppTheme.spacingSm),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: resourceColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: resourceColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaIcon(resourceIcon, color: resourceColor, size: 24),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              resource.title,
              style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Spacer(),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: resourceColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    resource.type.toUpperCase(),
                    style: AppTheme.labelSmall.copyWith(
                      color: resourceColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodHistory() {
    final l10n = AppLocalizations.of(context);
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
          Text(l10n.translate('yourMoodThisWeek') ?? 'Your Mood This Week',
              style: AppTheme.labelLarge),
          SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moodHistory.take(7).toList().reversed.map((log) {
              final dayName = _getDayName(log.loggedAt);
              return Column(
                children: [
                  Text(dayName,
                      style: AppTheme.labelSmall
                          .copyWith(color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          _getMoodColor(log.moodRating).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                        child: Text(_getMoodEmoji(log.moodRating),
                            style: TextStyle(fontSize: 18))),
                  ),
                ],
              );
            }).toList(),
          ),
          SizedBox(height: AppTheme.spacingMd),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.chartLine,
                    color: AppColors.info, size: 16),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.translate('trackingMoodHelps') ??
                        'Tracking your mood helps identify patterns and take better care of yourself.',
                    style: AppTheme.labelSmall.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(int level) {
    switch (level) {
      case 1:
        return '😢';
      case 2:
        return '😔';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😊';
      default:
        return '😐';
    }
  }

  String _getMoodLabel(int level, AppLocalizations l10n) {
    switch (level) {
      case 1:
        return l10n.translate('moodLow') ?? 'Low';
      case 2:
        return l10n.translate('moodDown') ?? 'Down';
      case 3:
        return l10n.translate('moodOkay') ?? 'Okay';
      case 4:
        return l10n.translate('moodGood') ?? 'Good';
      case 5:
        return l10n.translate('moodGreat') ?? 'Great';
      default:
        return '';
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      case 4:
        return AppColors.secondary;
      case 5:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getDayName(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  Color _getResourceColor(String type) {
    switch (type.toLowerCase()) {
      case 'article':
        return AppColors.primary;
      case 'video':
        return AppColors.error;
      case 'audio':
        return AppColors.secondary;
      case 'exercise':
      case 'exercises':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  IconData _getResourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'article':
        return FontAwesomeIcons.bookOpen;
      case 'video':
        return FontAwesomeIcons.video;
      case 'audio':
        return FontAwesomeIcons.headphones;
      case 'exercise':
      case 'exercises':
        return FontAwesomeIcons.personWalking;
      default:
        return FontAwesomeIcons.fileLines;
    }
  }
}
