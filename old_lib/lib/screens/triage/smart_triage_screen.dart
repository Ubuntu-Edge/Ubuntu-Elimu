import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../models/smart_triage.dart';
import '../../services/smart_triage_service.dart';
import '../../services/triage_api_service.dart' as api;
import '../../l10n/app_localizations.dart';

class SmartTriageScreen extends StatefulWidget {
  const SmartTriageScreen({super.key});

  @override
  State<SmartTriageScreen> createState() => _SmartTriageScreenState();
}

class _SmartTriageScreenState extends State<SmartTriageScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final SmartTriageService _localTriageService = SmartTriageService();
  final api.TriageApiService _apiService = api.TriageApiService.instance;

  final List<SymptomEntry> _selectedSymptoms = [];
  final List<VitalSign> _vitalSigns = [];
  TriageAssessment? _currentAssessment;

  // Backend data
  // ignore: unused_field
  List<api.TriageAssessment> _apiAssessments = [];
  // ignore: unused_field
  List<api.TriageGuideline> _apiGuidelines = [];
  // ignore: unused_field
  api.TriageStats? _triageStats;
  // ignore: unused_field
  bool _isLoadingAssessments = false;
  // ignore: unused_field
  bool _isPerformingAssessment = false;
  final bool _useBackend = true;

  // Vital sign controllers
  final _temperatureController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _respiratoryController = TextEditingController();
  final _oxygenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    _tabController.addListener(() {
      setState(() {});
    });

    // Load backend data
    _loadBackendData();
  }

  Future<void> _loadBackendData() async {
    if (!_useBackend) return;

    await Future.wait([
      _loadAssessments(),
      _loadGuidelines(),
      _loadStats(),
    ]);
  }

  Future<void> _loadAssessments() async {
    setState(() => _isLoadingAssessments = true);
    try {
      final result = await _apiService.listAssessments();
      setState(() {
        _apiAssessments = result.items;
        _isLoadingAssessments = false;
      });
    } catch (e) {
      setState(() => _isLoadingAssessments = false);
      debugPrint('Backend unavailable for assessments: $e');
    }
  }

  Future<void> _loadGuidelines() async {
    try {
      final guidelines = await _apiService.getGuidelines();
      setState(() => _apiGuidelines = guidelines);
    } catch (e) {
      debugPrint('Backend unavailable for guidelines: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _apiService.getStats();
      setState(() => _triageStats = stats);
    } catch (e) {
      debugPrint('Backend unavailable for stats: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _temperatureController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _respiratoryController.dispose();
    _oxygenController.dispose();
    super.dispose();
  }

  void _collectVitals() {
    _vitalSigns.clear();

    if (_temperatureController.text.isNotEmpty) {
      _vitalSigns.add(_localTriageService.createVitalSign(
        type: VitalType.temperature,
        value: double.tryParse(_temperatureController.text) ?? 37.0,
      ));
    }

    if (_systolicController.text.isNotEmpty) {
      _vitalSigns.add(_localTriageService.createVitalSign(
        type: VitalType.bloodPressureSystolic,
        value: double.tryParse(_systolicController.text) ?? 120,
      ));
    }

    if (_diastolicController.text.isNotEmpty) {
      _vitalSigns.add(_localTriageService.createVitalSign(
        type: VitalType.bloodPressureDiastolic,
        value: double.tryParse(_diastolicController.text) ?? 80,
      ));
    }

    if (_heartRateController.text.isNotEmpty) {
      _vitalSigns.add(_localTriageService.createVitalSign(
        type: VitalType.heartRate,
        value: double.tryParse(_heartRateController.text) ?? 80,
      ));
    }

    if (_respiratoryController.text.isNotEmpty) {
      _vitalSigns.add(_localTriageService.createVitalSign(
        type: VitalType.respiratoryRate,
        value: double.tryParse(_respiratoryController.text) ?? 16,
      ));
    }

    if (_oxygenController.text.isNotEmpty) {
      _vitalSigns.add(_localTriageService.createVitalSign(
        type: VitalType.oxygenSaturation,
        value: double.tryParse(_oxygenController.text) ?? 98,
      ));
    }
  }

  Future<void> _performTriage() async {
    _collectVitals();
    final l10n = AppLocalizations.of(context);

    if (_selectedSymptoms.isEmpty && _vitalSigns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              l10n.translate('addSymptomOrVital') ??
                  'Please add at least one symptom or vital sign',
              style: AppTheme.bodyMedium),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isPerformingAssessment = true);

    if (_useBackend) {
      try {
        // Convert local symptoms to API format
        final symptomsList = _selectedSymptoms.map((s) => s.symptom).toList();

        // Build vitals map
        final vitals = api.VitalSigns(
          temperatureC: _temperatureController.text.isNotEmpty
              ? double.tryParse(_temperatureController.text)
              : null,
          bloodPressureSystolic: _systolicController.text.isNotEmpty
              ? int.tryParse(_systolicController.text)
              : null,
          bloodPressureDiastolic: _diastolicController.text.isNotEmpty
              ? int.tryParse(_diastolicController.text)
              : null,
          pulseRate: _heartRateController.text.isNotEmpty
              ? int.tryParse(_heartRateController.text)
              : null,
          respiratoryRate: _respiratoryController.text.isNotEmpty
              ? int.tryParse(_respiratoryController.text)
              : null,
          oxygenSaturation: _oxygenController.text.isNotEmpty
              ? int.tryParse(_oxygenController.text)
              : null,
        );

        final apiResult = await _apiService.performAssessment(
          patientId: 'temp_patient',
          symptoms: symptomsList,
          vitalSigns: vitals,
        );

        // Convert API result to local model for display
        final assessment = TriageAssessment(
          id: apiResult.assessmentId,
          patientId: 'temp_patient',
          assessmentDate: apiResult.createdAt,
          symptoms: _selectedSymptoms,
          vitalSigns: _vitalSigns,
          urgencyLevel: _mapApiUrgencyToLocal(apiResult.urgencyLevel),
          priorityScore: apiResult.priorityScore.toInt(),
          redFlags: apiResult.redFlags,
          recommendedAction: apiResult.nextSteps.isNotEmpty
              ? apiResult.nextSteps.first
              : 'Follow standard care protocols',
          recommendations: apiResult.nextSteps,
          requiresReferral: apiResult.requiresReferral,
          referralFacility: apiResult.referralUrgency?.name,
          referralReason:
              apiResult.redFlags.isNotEmpty ? apiResult.redFlags.first : null,
          assessedBy: 'CHW',
        );

        setState(() {
          _currentAssessment = assessment;
          _isPerformingAssessment = false;
        });

        // Reload assessments list
        await _loadAssessments();

        _tabController.animateTo(2);
        return;
      } catch (e) {
        debugPrint('Backend triage failed, falling back to local: $e');
        // Continue to local fallback
      }
    }

    // Local fallback
    final assessment = _localTriageService.performTriage(
      patientId: 'temp_patient',
      symptoms: _selectedSymptoms,
      vitalSigns: _vitalSigns,
      assessedBy: 'CHW',
    );

    setState(() {
      _currentAssessment = assessment;
      _isPerformingAssessment = false;
    });

    if (_useBackend) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using offline assessment (backend unavailable)',
              style: AppTheme.bodyMedium),
          backgroundColor: AppColors.warning,
        ),
      );
    }

    _tabController.animateTo(2);
  }

  UrgencyLevel _mapApiUrgencyToLocal(api.UrgencyLevel apiLevel) {
    switch (apiLevel) {
      case api.UrgencyLevel.emergency:
        return UrgencyLevel.emergency;
      case api.UrgencyLevel.urgent:
        return UrgencyLevel.urgent;
      case api.UrgencyLevel.semiUrgent:
        return UrgencyLevel.semiUrgent;
      case api.UrgencyLevel.nonUrgent:
        return UrgencyLevel.routine;
    }
  }

  void _addSymptom(
      String symptomName, SymptomSeverity severity, int days, bool worsening) {
    setState(() {
      _selectedSymptoms.add(SymptomEntry(
        symptom: symptomName,
        severity: severity,
        durationDays: days,
        isWorsening: worsening,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Tabs
            _buildHeader(),

            // Tab Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSymptomsTab(),
                    _buildVitalsTab(),
                    _buildResultsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index < 2
          ? Builder(builder: (context) {
              final l10n = AppLocalizations.of(context);
              return FloatingActionButton.extended(
                onPressed: _performTriage,
                backgroundColor: AppColors.primary,
                elevation: 4,
                icon: const FaIcon(FontAwesomeIcons.stethoscope,
                    color: Colors.white, size: 18),
                label: Text(l10n.translate('runAssessment') ?? 'Run Assessment',
                    style: AppTheme.labelMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              );
            })
          : null,
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
                        l10n.translate('smartTriageTitle') ?? 'Smart Triage',
                        style: AppTheme.headingMedium.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        l10n.translate('aiAssistedAssessment') ??
                            'AI-assisted patient assessment',
                        style: AppTheme.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(FontAwesomeIcons.circleCheck,
                          color: Colors.white, size: 12),
                      SizedBox(width: 6),
                      Text(
                          '${_selectedSymptoms.length} ${l10n.translate('symptoms') ?? 'symptoms'}',
                          style: AppTheme.labelSmall
                              .copyWith(color: Colors.white)),
                    ],
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
              labelStyle:
                  AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTheme.labelMedium,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.clipboardList, size: 14),
                      SizedBox(width: 8),
                      Text(l10n
                              .translate('symptoms')
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          'S'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.heartPulse, size: 14),
                      SizedBox(width: 8),
                      Text(l10n.translate('vitalSigns')?.split(' ')[0] ??
                          'Vitals'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.chartLine, size: 14),
                      SizedBox(width: 8),
                      Text(l10n.translate('getResults')?.split(' ')[0] ??
                          'Results'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsTab() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Selected symptoms
        if (_selectedSymptoms.isNotEmpty) ...[
          Row(
            children: [
              FaIcon(FontAwesomeIcons.circleCheck,
                  color: AppColors.primary, size: 16),
              SizedBox(width: AppTheme.spacingSm),
              Text(l10n.translate('selectedSymptoms') ?? 'Selected Symptoms',
                  style: AppTheme.headingSmall
                      .copyWith(fontWeight: FontWeight.w600)),
              Spacer(),
              Text(
                  '${_selectedSymptoms.length} ${l10n.translate('selected') ?? 'selected'}',
                  style: AppTheme.labelSmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: _selectedSymptoms
                .map((s) => _buildSelectedSymptomChip(s))
                .toList(),
          ),
          SizedBox(height: AppTheme.spacingLg),
        ],

        // Instructions card
        Container(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(FontAwesomeIcons.circleInfo,
                    color: AppColors.info, size: 18),
              ),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.translate('howToUse') ?? 'How to use',
                        style: AppTheme.labelMedium.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text(
                        l10n.translate('tapCategoryToExpand') ??
                            'Tap on a category to expand and add symptoms',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppTheme.spacingMd),

        // Symptom categories
        Row(
          children: [
            FaIcon(FontAwesomeIcons.list, color: AppColors.primary, size: 16),
            SizedBox(width: AppTheme.spacingSm),
            Text(l10n.translate('symptomCategories') ?? 'Symptom Categories',
                style: AppTheme.headingSmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: AppTheme.spacingSm),

        for (var category in TriageSymptomCategories.all)
          _buildSymptomCategoryCard(category),
      ],
    );
  }

  Widget _buildSelectedSymptomChip(SymptomEntry symptom) {
    Color color;
    IconData icon;
    switch (symptom.severity) {
      case SymptomSeverity.mild:
        color = AppColors.success;
        icon = FontAwesomeIcons.circleCheck;
        break;
      case SymptomSeverity.moderate:
        color = AppColors.warning;
        icon = FontAwesomeIcons.circleExclamation;
        break;
      case SymptomSeverity.severe:
        color = AppColors.error;
        icon = FontAwesomeIcons.triangleExclamation;
        break;
      case SymptomSeverity.critical:
        color = const Color(0xFF7B1FA2);
        icon = FontAwesomeIcons.skull;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: color, size: 12),
          SizedBox(width: 8),
          Text(
            symptom.symptom,
            style: AppTheme.labelSmall
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedSymptoms.remove(symptom);
              });
            },
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: FaIcon(FontAwesomeIcons.xmark, size: 10, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomCategoryCard(SymptomCategory category) {
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          childrenPadding: EdgeInsets.only(bottom: AppTheme.spacingSm),
          leading: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(FontAwesomeIcons.clipboardList,
                color: AppColors.primary, size: 16),
          ),
          title: Text(category.name,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${category.symptoms.length} symptoms',
            style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          children: [
            // Red flags warning
            if (category.redFlags.isNotEmpty)
              Builder(builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                  padding: EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          FaIcon(FontAwesomeIcons.triangleExclamation,
                              color: AppColors.error, size: 14),
                          SizedBox(width: AppTheme.spacingSm),
                          Text(
                              l10n.translate('redFlagsReferImmediately') ??
                                  'Red Flags - Refer Immediately',
                              style: AppTheme.labelMedium.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingXs),
                      ...category.redFlags.map((flag) => Padding(
                            padding: EdgeInsets.only(
                                left: AppTheme.spacingMd, top: 2),
                            child: Text('• $flag',
                                style: AppTheme.bodySmall
                                    .copyWith(color: AppColors.error)),
                          )),
                    ],
                  ),
                );
              }),
            SizedBox(height: AppTheme.spacingSm),

            // Symptoms list
            ...category.symptoms.map((symptom) => _buildSymptomTile(symptom)),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomTile(SymptomDefinition symptom) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        title: Text(symptom.name, style: AppTheme.bodyMedium),
        subtitle: Text(symptom.description,
            style:
                AppTheme.labelSmall.copyWith(color: AppColors.textSecondary)),
        trailing: GestureDetector(
          onTap: () => _showAddSymptomDialog(symptom),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(FontAwesomeIcons.plus,
                color: AppColors.primary, size: 14),
          ),
        ),
      ),
    );
  }

  void _showAddSymptomDialog(SymptomDefinition symptom) {
    SymptomSeverity selectedSeverity = SymptomSeverity.mild;
    int days = 1;
    bool isWorsening = false;
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          title: Text(symptom.name, style: AppTheme.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.translate('severity') ?? 'Severity',
                  style: AppTheme.labelMedium),
              const SizedBox(height: AppTheme.spacingSm),
              Wrap(
                spacing: AppTheme.spacingSm,
                children: SymptomSeverity.values.map((severity) {
                  final isSelected = selectedSeverity == severity;
                  Color color;
                  switch (severity) {
                    case SymptomSeverity.mild:
                      color = AppColors.success;
                      break;
                    case SymptomSeverity.moderate:
                      color = AppColors.warning;
                      break;
                    case SymptomSeverity.severe:
                      color = AppColors.error;
                      break;
                    case SymptomSeverity.critical:
                      color = const Color(0xFF7B1FA2);
                      break;
                  }
                  return ChoiceChip(
                    label: Text(severity.name, style: AppTheme.labelSmall),
                    selected: isSelected,
                    selectedColor: color.withValues(alpha: 0.2),
                    onSelected: (selected) {
                      setDialogState(() => selectedSeverity = severity);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                  '${l10n.translate('duration') ?? 'Duration'} (${l10n.translate('days') ?? 'days'})',
                  style: AppTheme.labelMedium),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (days > 1) setDialogState(() => days--);
                    },
                  ),
                  Text('$days', style: AppTheme.headingMedium),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setDialogState(() => days++);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              CheckboxListTile(
                title: Text(l10n.translate('gettingWorse') ?? 'Getting worse',
                    style: AppTheme.bodyMedium),
                value: isWorsening,
                onChanged: (value) {
                  setDialogState(() => isWorsening = value ?? false);
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel,
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                _addSymptom(symptom.name, selectedSeverity, days, isWorsening);
                Navigator.pop(context);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(l10n.add,
                  style: AppTheme.labelMedium.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsTab() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      children: [
        Row(
          children: [
            FaIcon(FontAwesomeIcons.heartPulse,
                color: AppColors.primary, size: 16),
            SizedBox(width: AppTheme.spacingSm),
            Text(l10n.translate('vitalSigns') ?? 'Vital Signs',
                style: AppTheme.headingSmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: AppTheme.spacingXs),
        Text(
            l10n.translate('enterVitalsForAccuracy') ??
                'Enter patient vital signs for accurate assessment',
            style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary)),
        SizedBox(height: AppTheme.spacingMd),
        _buildVitalInput(
          label: l10n.translate('temperature') ?? 'Temperature',
          hint: '37.0',
          unit: '°C',
          controller: _temperatureController,
          icon: FontAwesomeIcons.temperatureHigh,
          color: AppColors.error,
        ),
        _buildVitalInput(
          label: l10n.translate('bloodPressureSystolic') ??
              'Blood Pressure (Systolic)',
          hint: '120',
          unit: 'mmHg',
          controller: _systolicController,
          icon: FontAwesomeIcons.heart,
          color: Colors.red,
        ),
        _buildVitalInput(
          label: l10n.translate('bloodPressureDiastolic') ??
              'Blood Pressure (Diastolic)',
          hint: '80',
          unit: 'mmHg',
          controller: _diastolicController,
          icon: FontAwesomeIcons.heart,
          color: Colors.pink,
        ),
        _buildVitalInput(
          label: l10n.translate('heartRate') ?? 'Heart Rate',
          hint: '80',
          unit: 'bpm',
          controller: _heartRateController,
          icon: FontAwesomeIcons.heartPulse,
          color: AppColors.secondary,
        ),
        _buildVitalInput(
          label: l10n.translate('respiratoryRate') ?? 'Respiratory Rate',
          hint: '16',
          unit: '/min',
          controller: _respiratoryController,
          icon: FontAwesomeIcons.lungs,
          color: AppColors.info,
        ),
        _buildVitalInput(
          label: l10n.translate('oxygenSaturation') ?? 'Oxygen Saturation',
          hint: '98',
          unit: '%',
          controller: _oxygenController,
          icon: FontAwesomeIcons.droplet,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildVitalInput({
    required String label,
    required String hint,
    required String unit,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(icon, color: color, size: 18),
          ),
          SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTheme.labelMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                SizedBox(height: AppTheme.spacingXs),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style:
                      AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: AppTheme.bodyLarge.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    suffixText: unit,
                    suffixStyle: AppTheme.bodyMedium
                        .copyWith(color: color, fontWeight: FontWeight.w600),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    final l10n = AppLocalizations.of(context);
    if (_currentAssessment == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(FontAwesomeIcons.clipboardCheck,
                    size: 48, color: AppColors.primary),
              ),
              SizedBox(height: AppTheme.spacingLg),
              Text(l10n.translate('noAssessmentYet') ?? 'No assessment yet',
                  style: AppTheme.headingSmall
                      .copyWith(color: AppColors.textPrimary)),
              SizedBox(height: AppTheme.spacingSm),
              Text(
                l10n.translate('addSymptomsAndVitals') ??
                    'Add symptoms and vitals in the other tabs, then tap "Run Assessment"',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spacingLg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(
                      1,
                      l10n.translate('addSymptoms') ?? 'Add Symptoms',
                      _selectedSymptoms.isNotEmpty),
                  Container(width: 40, height: 2, color: AppColors.divider),
                  _buildStepIndicator(
                      2,
                      l10n.translate('enterVitals') ?? 'Enter Vitals',
                      _vitalSigns.isNotEmpty),
                  Container(width: 40, height: 2, color: AppColors.divider),
                  _buildStepIndicator(
                      3,
                      l10n.translate('getResults') ?? 'Get Results',
                      _currentAssessment != null),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final assessment = _currentAssessment!;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Urgency Banner
        Container(
          padding: EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                assessment.urgencyLevel.color,
                assessment.urgencyLevel.color.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: assessment.urgencyLevel.color.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  assessment.urgencyLevel == UrgencyLevel.emergency
                      ? FontAwesomeIcons.triangleExclamation
                      : FontAwesomeIcons.clipboardCheck,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              SizedBox(height: AppTheme.spacingMd),
              Text(
                assessment.urgencyLevel.displayName,
                style: AppTheme.headingLarge
                    .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppTheme.spacingXs),
              Text(
                '${l10n.translate('priorityScore') ?? 'Priority Score'}: ${assessment.priorityScore}',
                style: AppTheme.bodyMedium
                    .copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
              SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.clock,
                        color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text(
                      assessment.urgencyLevel.responseTimeframe,
                      style: AppTheme.labelMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppTheme.spacingMd),

        // Recommended Action
        _buildResultCard(
          icon: FontAwesomeIcons.userDoctor,
          iconColor: AppColors.primary,
          title: l10n.translate('recommendedAction') ?? 'Recommended Action',
          child: Text(assessment.recommendedAction, style: AppTheme.bodyMedium),
        ),
        SizedBox(height: AppTheme.spacingSm),

        // Red Flags
        if (assessment.redFlags.isNotEmpty) ...[
          _buildResultCard(
            icon: FontAwesomeIcons.triangleExclamation,
            iconColor: AppColors.error,
            title: l10n.translate('redFlagsDetected') ?? 'Red Flags Detected',
            backgroundColor: AppColors.error.withValues(alpha: 0.05),
            borderColor: AppColors.error.withValues(alpha: 0.2),
            child: Column(
              children: assessment.redFlags
                  .map((flag) => Padding(
                        padding: EdgeInsets.only(bottom: AppTheme.spacingXs),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle),
                            ),
                            SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                                child: Text(flag, style: AppTheme.bodyMedium)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          SizedBox(height: AppTheme.spacingSm),
        ],

        // Referral Info
        if (assessment.requiresReferral) ...[
          _buildResultCard(
            icon: FontAwesomeIcons.hospital,
            iconColor: AppColors.warning,
            title:
                l10n.translate('referralRecommended') ?? 'Referral Recommended',
            backgroundColor: AppColors.warning.withValues(alpha: 0.05),
            borderColor: AppColors.warning.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (assessment.referralFacility != null)
                  Text(
                      '${l10n.translate('facility') ?? 'Facility'}: ${assessment.referralFacility}',
                      style: AppTheme.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                if (assessment.referralReason != null)
                  Text(
                      '${l10n.translate('reason') ?? 'Reason'}: ${assessment.referralReason}',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingSm),
        ],

        // Recommendations
        _buildResultCard(
          icon: FontAwesomeIcons.listCheck,
          iconColor: AppColors.success,
          title: l10n.translate('recommendations') ?? 'Recommendations',
          child: Column(
            children: assessment.recommendations
                .map((rec) => Padding(
                      padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FaIcon(FontAwesomeIcons.circleCheck,
                              color: AppColors.success, size: 14),
                          SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                              child: Text(rec, style: AppTheme.bodyMedium)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        SizedBox(height: AppTheme.spacingMd),

        // Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedSymptoms.clear();
                    _vitalSigns.clear();
                    _currentAssessment = null;
                    _temperatureController.clear();
                    _systolicController.clear();
                    _diastolicController.clear();
                    _heartRateController.clear();
                    _respiratoryController.clear();
                    _oxygenController.clear();
                  });
                  _tabController.animateTo(0);
                },
                icon: FaIcon(FontAwesomeIcons.arrowRotateLeft, size: 16),
                label:
                    Text(l10n.translate('newAssessment') ?? 'New Assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.circleCheck,
                              color: Colors.white, size: 16),
                          SizedBox(width: 10),
                          Text(
                              l10n.translate('assessmentSaved') ??
                                  'Assessment saved',
                              style: AppTheme.bodyMedium
                                  .copyWith(color: Colors.white)),
                        ],
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: FaIcon(FontAwesomeIcons.floppyDisk, size: 16),
                label: Text(l10n.save),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: completed ? AppColors.success : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completed
                ? FaIcon(FontAwesomeIcons.check, color: Colors.white, size: 14)
                : Text('$step',
                    style: AppTheme.labelMedium.copyWith(color: Colors.white)),
          ),
        ),
        SizedBox(height: 4),
        Text(label,
            style:
                AppTheme.labelSmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: backgroundColor == null
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(icon, color: iconColor, size: 16),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Text(title,
                  style: AppTheme.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          child,
        ],
      ),
    );
  }
}
