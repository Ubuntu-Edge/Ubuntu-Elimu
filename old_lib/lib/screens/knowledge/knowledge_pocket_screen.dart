import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/knowledge_api_service.dart' as api;

/// Knowledge Pocket Screen - Offline clinical guidelines, danger signs, referral criteria
/// All content available offline for quick reference during patient visits
class KnowledgePocketScreen extends StatefulWidget {
  const KnowledgePocketScreen({super.key});

  @override
  State<KnowledgePocketScreen> createState() => _KnowledgePocketScreenState();
}

class _KnowledgePocketScreenState extends State<KnowledgePocketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final api.KnowledgeApiService _apiService = api.KnowledgeApiService.instance;

  // Backend data
  List<api.KnowledgeGuideline> _apiGuidelines = [];
  List<api.DangerSign> _apiDangerSigns = [];
  List<api.ReferralCriteria> _apiReferralCriteria = [];
  // TODO: May be needed later for drug dosing display
  // List<api.DrugDosingGuideline> _apiDrugs = [];
  List<api.KnowledgeBookmark> _bookmarks = [];
  bool _isLoadingGuidelines = false;
  bool _isLoadingDangerSigns = false;
  bool _isLoadingReferralCriteria = false;
  final bool _useBackend = true;
  // TODO: May be needed later for showing last sync time
  // DateTime? _lastSyncedAt;

  // Clinical guidelines data
  final List<ClinicalGuideline> _guidelines = [
    ClinicalGuideline(
      id: '1',
      title: 'Malaria Case Management',
      category: 'Infectious Diseases',
      icon: FontAwesomeIcons.mosquito,
      color: Colors.orange,
      content: '''
**Assessment**
- Check for fever (≥37.5°C) or history of fever in last 48 hours
- Perform RDT if available
- Ask about travel to malaria-endemic areas

**Uncomplicated Malaria Treatment**
- ACT (Artemisinin-based Combination Therapy)
- Age-appropriate dosing based on weight
- Complete full course (3 days)

**Danger Signs - REFER IMMEDIATELY**
- Unable to drink or breastfeed
- Vomiting everything
- Recent convulsions
- Lethargy or unconsciousness
- Severe anemia (pale palms/conjunctiva)

**Follow-up**
- Check on day 3 for fever resolution
- Complete parasitological confirmation if possible
''',
      lastUpdated: DateTime(2024, 1, 15),
      isBookmarked: true,
    ),
    ClinicalGuideline(
      id: '2',
      title: 'Pneumonia in Children',
      category: 'Respiratory',
      icon: FontAwesomeIcons.lungs,
      color: Colors.blue,
      content: '''
**Assessment - Count respiratory rate**
- <2 months: Fast breathing ≥60/min
- 2-12 months: Fast breathing ≥50/min
- 1-5 years: Fast breathing ≥40/min

**Check for chest indrawing**
- Lower chest wall moves IN when child breathes IN
- Sign of severe pneumonia

**Classification & Treatment**
- **Pneumonia** (fast breathing only): Oral Amoxicillin at home
- **Severe Pneumonia** (chest indrawing): REFER urgently

**Danger Signs - REFER IMMEDIATELY**
- Stridor when calm
- Central cyanosis
- Unable to drink
- Convulsions
- Lethargy or unconsciousness

**Home Care Advice**
- Continue breastfeeding/feeding
- Clear nose before feeds
- Return if breathing worsens
''',
      lastUpdated: DateTime(2024, 2, 10),
      isBookmarked: true,
    ),
    ClinicalGuideline(
      id: '3',
      title: 'Diarrhea Management',
      category: 'Gastrointestinal',
      icon: FontAwesomeIcons.droplet,
      color: Colors.teal,
      content: '''
**Assessment**
- Duration of diarrhea
- Blood in stool (dysentery)
- Signs of dehydration

**Dehydration Assessment**
| Sign | None | Some | Severe |
|------|------|------|--------|
| Condition | Alert | Restless/Irritable | Lethargic |
| Eyes | Normal | Sunken | Very sunken |
| Thirst | Drinks normally | Thirsty | Cannot drink |
| Skin pinch | Goes back quickly | Goes back slowly | Goes back very slowly |

**Treatment**
- **No dehydration**: ORS at home + Zinc for 14 days
- **Some dehydration**: ORS under observation (Plan B)
- **Severe dehydration**: IV fluids URGENT + REFER

**Zinc Dosing**
- <6 months: 10mg daily for 14 days
- ≥6 months: 20mg daily for 14 days

**When to refer**
- Blood in stool
- Severe dehydration
- No improvement after 2 days
''',
      lastUpdated: DateTime(2024, 1, 20),
      isBookmarked: false,
    ),
    ClinicalGuideline(
      id: '4',
      title: 'Antenatal Care',
      category: 'Maternal Health',
      icon: FontAwesomeIcons.personPregnant,
      color: Colors.pink,
      content: '''
**First Visit (Before 12 weeks)**
- Confirm pregnancy
- Calculate expected date of delivery
- Check blood pressure, weight, hemoglobin
- Provide folic acid + iron
- Discuss birth plan

**Routine ANC Schedule**
- Monthly until 28 weeks
- Fortnightly 28-36 weeks
- Weekly after 36 weeks
- Minimum 8 contacts recommended

**Essential Interventions**
- Tetanus vaccination
- Iron/Folic acid supplementation
- IPTp (malaria prevention)
- Deworming in 2nd trimester
- HIV testing and counseling

**Danger Signs - REFER IMMEDIATELY**
- Vaginal bleeding
- Severe headache with blurred vision
- Fits/convulsions
- Fever
- Reduced or no fetal movement
- Water break before 37 weeks
- Severe abdominal pain
''',
      lastUpdated: DateTime(2024, 2, 1),
      isBookmarked: true,
    ),
    ClinicalGuideline(
      id: '5',
      title: 'Newborn Care',
      category: 'Neonatal',
      icon: FontAwesomeIcons.baby,
      color: Colors.purple,
      content: '''
**Immediate Care at Birth**
- Dry the baby thoroughly
- Assess breathing (cry)
- Clamp and cut cord
- Skin-to-skin contact with mother
- Initiate breastfeeding within 1 hour

**Essential Newborn Care**
- Keep baby warm
- Exclusive breastfeeding on demand
- Delayed bathing (after 24 hours)
- Eye care with antibiotic
- Vitamin K injection

**Danger Signs - REFER IMMEDIATELY**
- Not feeding well
- Convulsions
- Fast breathing (>60/min)
- Severe chest indrawing
- Fever (>37.5°C) or low temperature (<35.5°C)
- Yellow palms/soles (first 24 hours)
- Umbilicus red/draining pus

**Follow-up Visits**
- Day 1, 3, 7, 14, and 6 weeks
- Check feeding, weight, cord, danger signs
''',
      lastUpdated: DateTime(2024, 1, 25),
      isBookmarked: false,
    ),
  ];

  // Danger signs checklist
  final List<DangerSignCategory> _dangerSigns = [
    DangerSignCategory(
      title: 'Children Under 5',
      icon: FontAwesomeIcons.child,
      color: Colors.orange,
      signs: [
        DangerSign(
            'Unable to drink or breastfeed', 'CRITICAL - Refer immediately'),
        DangerSign('Vomiting everything', 'CRITICAL - Refer immediately'),
        DangerSign('Convulsions', 'CRITICAL - Refer immediately'),
        DangerSign('Lethargic or unconscious', 'CRITICAL - Refer immediately'),
        DangerSign('Fast breathing', 'Assess for pneumonia'),
        DangerSign('Chest indrawing', 'Severe pneumonia - Refer'),
        DangerSign('Blood in stool', 'Dysentery - Refer'),
        DangerSign('Very pale (severe anemia)', 'CRITICAL - Refer immediately'),
        DangerSign('Swelling of both feet', 'Severe malnutrition - Refer'),
      ],
    ),
    DangerSignCategory(
      title: 'Pregnant Women',
      icon: FontAwesomeIcons.personPregnant,
      color: Colors.pink,
      signs: [
        DangerSign('Vaginal bleeding', 'CRITICAL - Refer immediately'),
        DangerSign('Severe headache with blurred vision',
            'Pre-eclampsia - Refer urgently'),
        DangerSign('Fits/convulsions', 'Eclampsia - EMERGENCY'),
        DangerSign('Fever', 'Infection - Assess and treat/refer'),
        DangerSign(
            'Reduced or no fetal movement', 'Assess fetal status - Refer'),
        DangerSign('Water break before 37 weeks', 'Preterm labor - Refer'),
        DangerSign('Severe abdominal pain', 'Possible complications - Refer'),
        DangerSign('Swelling of face and hands', 'Pre-eclampsia sign - Refer'),
      ],
    ),
    DangerSignCategory(
      title: 'Newborns (0-28 days)',
      icon: FontAwesomeIcons.baby,
      color: Colors.purple,
      signs: [
        DangerSign('Not feeding well', 'Possible infection - Refer'),
        DangerSign('Convulsions', 'CRITICAL - Refer immediately'),
        DangerSign('Fast breathing (>60/min)', 'Respiratory distress - Refer'),
        DangerSign('Severe chest indrawing', 'CRITICAL - Refer immediately'),
        DangerSign('Fever (>37.5°C) or hypothermia (<35.5°C)',
            'Possible sepsis - Refer'),
        DangerSign(
            'Jaundice in first 24 hours', 'CRITICAL - Refer immediately'),
        DangerSign('Umbilicus red/draining pus', 'Infection - Treat/Refer'),
        DangerSign('Bulging fontanelle', 'Possible meningitis - Refer'),
      ],
    ),
    DangerSignCategory(
      title: 'Postpartum Women',
      icon: FontAwesomeIcons.personBreastfeeding,
      color: Colors.teal,
      signs: [
        DangerSign(
            'Heavy vaginal bleeding', 'CRITICAL - Postpartum hemorrhage'),
        DangerSign('Fever with chills', 'Possible puerperal sepsis - Refer'),
        DangerSign(
            'Severe headache/blurred vision', 'Postpartum eclampsia - Refer'),
        DangerSign('Fits/convulsions', 'EMERGENCY - Refer immediately'),
        DangerSign('Smelly vaginal discharge', 'Possible infection - Refer'),
        DangerSign('Red, tender breasts with fever', 'Mastitis - Treat/Refer'),
        DangerSign('Extreme sadness/thoughts of harm',
            'Postpartum depression - Refer'),
      ],
    ),
  ];

  // Referral criteria
  final List<ReferralCriteria> _referralCriteria = [
    ReferralCriteria(
      category: 'Emergency - Transport Immediately',
      color: Colors.red,
      icon: FontAwesomeIcons.truckMedical,
      criteria: [
        'Unconscious or convulsing',
        'Severe difficulty breathing',
        'Active heavy bleeding',
        'Signs of shock (cold, pale, weak pulse)',
        'Severe burns',
        'Suspected fracture with bone visible',
        'Snake or animal bite',
        'Poisoning or overdose',
      ],
    ),
    ReferralCriteria(
      category: 'Urgent - Within 24 hours',
      color: Colors.orange,
      icon: FontAwesomeIcons.clockRotateLeft,
      criteria: [
        'Severe dehydration',
        'Severe pneumonia (chest indrawing)',
        'Severe malnutrition with complications',
        'High fever not responding to treatment',
        'Blood in stool with dehydration',
        'Pregnancy with danger signs',
        'Newborn with danger signs',
        'Suspected TB (cough >2 weeks)',
      ],
    ),
    ReferralCriteria(
      category: 'Non-Urgent - Planned Referral',
      color: Colors.blue,
      icon: FontAwesomeIcons.calendarCheck,
      criteria: [
        'Chronic conditions needing specialist care',
        'Growth monitoring concerns',
        'Developmental delays',
        'Skin conditions not improving',
        'Follow-up lab tests needed',
        'Immunization catch-up',
        'Mental health concerns',
        'Family planning counseling',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBackendData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBackendData() async {
    if (!_useBackend) return;

    await Future.wait([
      _loadGuidelines(),
      _loadDangerSigns(),
      _loadReferralCriteria(),
      _loadBookmarks(),
    ]);
  }

  Future<void> _loadGuidelines() async {
    setState(() => _isLoadingGuidelines = true);
    try {
      final result = await _apiService.listGuidelines();
      setState(() {
        _apiGuidelines = result.items;
        _isLoadingGuidelines = false;
      });
    } catch (e) {
      setState(() => _isLoadingGuidelines = false);
      debugPrint('Backend unavailable for guidelines: $e');
    }
  }

  Future<void> _searchGuidelines() async {
    if (_searchQuery.isEmpty) {
      await _loadGuidelines();
      return;
    }

    setState(() => _isLoadingGuidelines = true);
    try {
      final result = await _apiService.searchGuidelines(query: _searchQuery);
      setState(() {
        _apiGuidelines = result.items;
        _isLoadingGuidelines = false;
      });
    } catch (e) {
      setState(() => _isLoadingGuidelines = false);
      debugPrint('Backend search failed: $e');
    }
  }

  Future<void> _loadDangerSigns() async {
    setState(() => _isLoadingDangerSigns = true);
    try {
      final result = await _apiService.listDangerSigns();
      setState(() {
        _apiDangerSigns = result.items;
        _isLoadingDangerSigns = false;
      });
    } catch (e) {
      setState(() => _isLoadingDangerSigns = false);
      debugPrint('Backend unavailable for danger signs: $e');
    }
  }

  Future<void> _loadReferralCriteria() async {
    setState(() => _isLoadingReferralCriteria = true);
    try {
      final criteria = await _apiService.listReferralCriteria();
      setState(() {
        _apiReferralCriteria = criteria;
        _isLoadingReferralCriteria = false;
      });
    } catch (e) {
      setState(() => _isLoadingReferralCriteria = false);
      debugPrint('Backend unavailable for referral criteria: $e');
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await _apiService.listBookmarks();
      setState(() => _bookmarks = bookmarks);
    } catch (e) {
      debugPrint('Backend unavailable for bookmarks: $e');
    }
  }

  Future<void> _toggleBookmark(String guidelineId, String title) async {
    final existingBookmark =
        _bookmarks.where((b) => b.guidelineId == guidelineId).firstOrNull;

    try {
      if (existingBookmark != null) {
        await _apiService.deleteBookmark(existingBookmark.id);
        setState(() {
          _bookmarks.removeWhere((b) => b.id == existingBookmark.id);
        });
      } else {
        final bookmark = await _apiService.createBookmark(
          guidelineId: guidelineId,
        );
        setState(() {
          _bookmarks.add(bookmark);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to update bookmark', style: AppTheme.bodyMedium),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _syncKnowledgeBase() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Syncing knowledge base...', style: AppTheme.bodyMedium),
            ],
          ),
          backgroundColor: AppColors.primary,
        ),
      );

      final result = await _apiService.syncKnowledgeBase();
      // TODO: Display last sync time in UI
      // setState(() => _lastSyncedAt = result.syncTimestamp);

      // Reload all data
      await _loadBackendData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synced: ${result.totalItems} items (${result.newItems} new, ${result.updatedItems} updated)',
            style: AppTheme.bodyMedium,
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e', style: AppTheme.bodyMedium),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  bool _isBookmarked(String guidelineId) {
    return _bookmarks.any((b) => b.guidelineId == guidelineId);
  }

  List<ClinicalGuideline> get _filteredGuidelines {
    if (_searchQuery.isEmpty) return _guidelines;
    return _guidelines
        .where((g) =>
            g.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            g.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            g.content.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildSearchBar(l10n),
            _buildTabBar(l10n),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGuidelinesTab(l10n),
                  _buildDangerSignsTab(l10n),
                  _buildReferralCriteriaTab(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _syncKnowledgeBase,
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.sync, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            AppColors.secondary.withValues(alpha: 0.8)
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(FontAwesomeIcons.arrowLeft,
                    color: Colors.white, size: 18),
              ),
            ),
            SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.knowledgePocket,
                    style: AppTheme.headingMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.translate('offlineReady') ?? 'Available Offline',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(FontAwesomeIcons.circleCheck,
                      color: Colors.white, size: 12),
                  SizedBox(width: AppTheme.spacingXs),
                  Text(
                    'OFFLINE',
                    style: AppTheme.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.all(AppTheme.spacingMd),
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
          if (_useBackend && value.isNotEmpty) {
            // Debounce search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchQuery == value) {
                _searchGuidelines();
              }
            });
          }
        },
        onSubmitted: (_) => _searchGuidelines(),
        decoration: InputDecoration(
          hintText: l10n.translate('searchGuidelines') ??
              'Search guidelines, symptoms...',
          hintStyle:
              AppTheme.bodyMedium.copyWith(color: AppColors.textSecondary),
          border: InputBorder.none,
          icon: FaIcon(FontAwesomeIcons.magnifyingGlass,
              color: AppColors.textSecondary, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: FaIcon(FontAwesomeIcons.xmark, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadGuidelines();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
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
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: EdgeInsets.all(AppTheme.spacingXs),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.bookMedical, size: 14),
                SizedBox(width: AppTheme.spacingXs),
                Flexible(
                    child: Text(l10n.clinicalGuidelines.split(' ').first,
                        style: AppTheme.labelSmall)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.triangleExclamation, size: 14),
                SizedBox(width: AppTheme.spacingXs),
                Flexible(
                    child: Text(l10n.dangerSigns.split(' ').first,
                        style: AppTheme.labelSmall)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.hospitalUser, size: 14),
                SizedBox(width: AppTheme.spacingXs),
                Flexible(
                    child: Text(l10n.referralCriteria.split(' ').first,
                        style: AppTheme.labelSmall)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelinesTab(AppLocalizations l10n) {
    // Use backend guidelines if available
    if (_useBackend && (_apiGuidelines.isNotEmpty || _isLoadingGuidelines)) {
      if (_isLoadingGuidelines) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_apiGuidelines.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.magnifyingGlass,
                  color: AppColors.textSecondary, size: 48),
              SizedBox(height: AppTheme.spacingMd),
              Text(
                l10n.translate('noResults') ?? 'No matching guidelines',
                style:
                    AppTheme.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextButton.icon(
                onPressed: _loadGuidelines,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadGuidelines,
        child: ListView.builder(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          itemCount: _apiGuidelines.length,
          itemBuilder: (context, index) =>
              _buildApiGuidelineCard(_apiGuidelines[index], l10n),
        ),
      );
    }

    // Fall back to local hardcoded guidelines
    final guidelines = _filteredGuidelines;

    if (guidelines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.magnifyingGlass,
                color: AppColors.textSecondary, size: 48),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              l10n.translate('noResults') ?? 'No matching guidelines',
              style:
                  AppTheme.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      itemCount: guidelines.length,
      itemBuilder: (context, index) =>
          _buildGuidelineCard(guidelines[index], l10n),
    );
  }

  Widget _buildApiGuidelineCard(
      api.KnowledgeGuideline guideline, AppLocalizations l10n) {
    final isBookmarked = _isBookmarked(guideline.id);
    final categoryColor = _getCategoryColor(guideline.category);

    return GestureDetector(
      onTap: () => _showApiGuidelineDetail(guideline, l10n),
      child: Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(_getCategoryIcon(guideline.category),
                    color: categoryColor, size: 22),
              ),
            ),
            SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          guideline.title,
                          style: AppTheme.bodyMedium
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _toggleBookmark(guideline.id, guideline.title),
                        child: FaIcon(
                          isBookmarked
                              ? FontAwesomeIcons.solidBookmark
                              : FontAwesomeIcons.bookmark,
                          color: AppColors.warning,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingXs),
                  Text(
                    guideline.category.name,
                    style: AppTheme.labelSmall.copyWith(color: categoryColor),
                  ),
                  SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Text(
                        '${l10n.translate('updated') ?? 'Updated'}: ${guideline.lastUpdated != null ? _formatDate(guideline.lastUpdated!) : 'N/A'}',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          'v${guideline.version}',
                          style: AppTheme.labelSmall
                              .copyWith(color: AppColors.primary, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FaIcon(FontAwesomeIcons.chevronRight,
                color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  void _showApiGuidelineDetail(
      api.KnowledgeGuideline guideline, AppLocalizations l10n) {
    final categoryColor = _getCategoryColor(guideline.category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: FaIcon(_getCategoryIcon(guideline.category),
                            color: categoryColor, size: 22),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guideline.title,
                            style: AppTheme.headingSmall
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            guideline.category.name,
                            style: AppTheme.labelMedium
                                .copyWith(color: categoryColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _toggleBookmark(guideline.id, guideline.title);
                        setSheetState(() {});
                      },
                      icon: FaIcon(
                        _isBookmarked(guideline.id)
                            ? FontAwesomeIcons.solidBookmark
                            : FontAwesomeIcons.bookmark,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: AppTheme.spacingLg),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary
                      if (guideline.summary != null &&
                          guideline.summary!.isNotEmpty) ...[
                        Text('Summary',
                            style: AppTheme.labelMedium
                                .copyWith(color: AppColors.primary)),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(guideline.summary!, style: AppTheme.bodyMedium),
                        const SizedBox(height: AppTheme.spacingMd),
                      ],

                      // Content
                      _buildMarkdownContent(guideline.content),

                      const SizedBox(height: AppTheme.spacingMd),

                      // Keywords (using keywords instead of keyPoints)
                      if (guideline.keywords.isNotEmpty) ...[
                        Text('Keywords',
                            style: AppTheme.labelMedium
                                .copyWith(color: AppColors.primary)),
                        const SizedBox(height: AppTheme.spacingSm),
                        Wrap(
                          spacing: AppTheme.spacingSm,
                          runSpacing: AppTheme.spacingSm,
                          children: guideline.keywords
                              .map((keyword) => Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(keyword,
                                        style: AppTheme.labelSmall.copyWith(
                                            color: AppColors.primary)),
                                  ))
                              .toList(),
                        ),
                      ],

                      // Source
                      const SizedBox(height: AppTheme.spacingMd),
                      Container(
                        padding: EdgeInsets.all(AppTheme.spacingSm),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.circleInfo,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Text(
                                'Source: ${guideline.source} | Version: ${guideline.version}',
                                style: AppTheme.labelSmall
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(api.KnowledgeCategory category) {
    switch (category) {
      case api.KnowledgeCategory.maternal:
        return Colors.pink;
      case api.KnowledgeCategory.child:
        return Colors.blue;
      case api.KnowledgeCategory.nutrition:
        return Colors.green;
      case api.KnowledgeCategory.communicableDiseases:
        return Colors.orange;
      case api.KnowledgeCategory.nonCommunicable:
        return Colors.purple;
      case api.KnowledgeCategory.emergency:
        return Colors.red;
      case api.KnowledgeCategory.mentalHealth:
        return Colors.teal;
      case api.KnowledgeCategory.reproductive:
        return Colors.indigo;
      case api.KnowledgeCategory.immunization:
        return Colors.cyan;
      case api.KnowledgeCategory.waterSanitation:
        return Colors.amber;
    }
  }

  IconData _getCategoryIcon(api.KnowledgeCategory category) {
    switch (category) {
      case api.KnowledgeCategory.maternal:
        return FontAwesomeIcons.personPregnant;
      case api.KnowledgeCategory.child:
        return FontAwesomeIcons.baby;
      case api.KnowledgeCategory.nutrition:
        return FontAwesomeIcons.apple;
      case api.KnowledgeCategory.communicableDiseases:
        return FontAwesomeIcons.virus;
      case api.KnowledgeCategory.nonCommunicable:
        return FontAwesomeIcons.heartPulse;
      case api.KnowledgeCategory.emergency:
        return FontAwesomeIcons.kitMedical;
      case api.KnowledgeCategory.mentalHealth:
        return FontAwesomeIcons.brain;
      case api.KnowledgeCategory.reproductive:
        return FontAwesomeIcons.venusMars;
      case api.KnowledgeCategory.immunization:
        return FontAwesomeIcons.syringe;
      case api.KnowledgeCategory.waterSanitation:
        return FontAwesomeIcons.droplet;
    }
  }

  Widget _buildGuidelineCard(
      ClinicalGuideline guideline, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => _showGuidelineDetail(guideline, l10n),
      child: Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: guideline.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(guideline.icon, color: guideline.color, size: 22),
              ),
            ),
            SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          guideline.title,
                          style: AppTheme.bodyMedium
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (guideline.isBookmarked)
                        FaIcon(FontAwesomeIcons.solidBookmark,
                            color: AppColors.warning, size: 16),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingXs),
                  Text(
                    guideline.category,
                    style: AppTheme.labelSmall.copyWith(color: guideline.color),
                  ),
                  SizedBox(height: AppTheme.spacingXs),
                  Text(
                    '${l10n.translate('updated') ?? 'Updated'}: ${_formatDate(guideline.lastUpdated)}',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            FaIcon(FontAwesomeIcons.chevronRight,
                color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  void _showGuidelineDetail(
      ClinicalGuideline guideline, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: guideline.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: FaIcon(guideline.icon,
                          color: guideline.color, size: 22),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guideline.title,
                          style: AppTheme.headingSmall
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          guideline.category,
                          style: AppTheme.labelMedium
                              .copyWith(color: guideline.color),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        // Toggle bookmark
                      });
                    },
                    icon: FaIcon(
                      guideline.isBookmarked
                          ? FontAwesomeIcons.solidBookmark
                          : FontAwesomeIcons.bookmark,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: AppTheme.spacingLg),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacingMd),
                child: _buildMarkdownContent(guideline.content),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdownContent(String content) {
    // Simple markdown-like rendering
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('**') && line.endsWith('**')) {
          return Padding(
            padding: EdgeInsets.only(
                top: AppTheme.spacingMd, bottom: AppTheme.spacingXs),
            child: Text(
              line.replaceAll('**', ''),
              style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          );
        } else if (line.startsWith('- ')) {
          return Padding(
            padding: EdgeInsets.only(
                left: AppTheme.spacingSm, bottom: AppTheme.spacingXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: EdgeInsets.only(top: 6, right: AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: AppTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        } else if (line.trim().isEmpty) {
          return SizedBox(height: AppTheme.spacingSm);
        } else {
          return Text(line, style: AppTheme.bodySmall);
        }
      }).toList(),
    );
  }

  Widget _buildDangerSignsTab(AppLocalizations l10n) {
    // Use backend danger signs if available
    if (_useBackend && (_apiDangerSigns.isNotEmpty || _isLoadingDangerSigns)) {
      if (_isLoadingDangerSigns) {
        return const Center(child: CircularProgressIndicator());
      }

      // Group by category
      final groupedSigns = <String, List<api.DangerSign>>{};
      for (final sign in _apiDangerSigns) {
        final group = sign.category.name;
        groupedSigns.putIfAbsent(group, () => []).add(sign);
      }

      return RefreshIndicator(
        onRefresh: _loadDangerSigns,
        child: ListView.builder(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          itemCount: groupedSigns.length,
          itemBuilder: (context, index) {
            final group = groupedSigns.keys.elementAt(index);
            final signs = groupedSigns[group]!;
            return _buildApiDangerSignCategoryCard(group, signs, l10n);
          },
        ),
      );
    }

    // Fall back to local data
    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _dangerSigns.length,
      itemBuilder: (context, index) =>
          _buildDangerSignCategoryCard(_dangerSigns[index], l10n),
    );
  }

  Widget _buildApiDangerSignCategoryCard(
      String categoryName, List<api.DangerSign> signs, AppLocalizations l10n) {
    final color = _getTargetGroupColor(categoryName);
    final icon = _getTargetGroupIcon(categoryName);

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(icon, color: color, size: 18),
            ),
          ),
          title: Text(categoryName,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${signs.length} ${l10n.dangerSigns.toLowerCase()}',
            style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          children: signs
              .map((sign) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getSeverityColor(sign.severity)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.exclamation,
                              color: _getSeverityColor(sign.severity),
                              size: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sign.signName,
                                  style: AppTheme.bodySmall
                                      .copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                sign.immediateActions.isNotEmpty
                                    ? sign.immediateActions.first
                                    : sign.description,
                                style: AppTheme.labelSmall.copyWith(
                                  color: _getSeverityColor(sign.severity),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Color _getTargetGroupColor(String group) {
    if (group.toLowerCase().contains('child')) return Colors.orange;
    if (group.toLowerCase().contains('pregnant')) return Colors.pink;
    if (group.toLowerCase().contains('newborn')) return Colors.purple;
    if (group.toLowerCase().contains('postpartum')) return Colors.teal;
    return AppColors.primary;
  }

  IconData _getTargetGroupIcon(String group) {
    if (group.toLowerCase().contains('child')) return FontAwesomeIcons.child;
    if (group.toLowerCase().contains('pregnant'))
      return FontAwesomeIcons.personPregnant;
    if (group.toLowerCase().contains('newborn')) return FontAwesomeIcons.baby;
    if (group.toLowerCase().contains('postpartum'))
      return FontAwesomeIcons.personBreastfeeding;
    return FontAwesomeIcons.person;
  }

  Color _getSeverityColor(api.DangerSignSeverity severity) {
    switch (severity) {
      case api.DangerSignSeverity.critical:
        return AppColors.error;
      case api.DangerSignSeverity.high:
        return AppColors.warning;
      case api.DangerSignSeverity.moderate:
        return Colors.orange;
      case api.DangerSignSeverity.low:
        return Colors.blue;
    }
  }

  Widget _buildDangerSignCategoryCard(
      DangerSignCategory category, AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(category.icon, color: category.color, size: 18),
            ),
          ),
          title: Text(category.title,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${category.signs.length} ${l10n.dangerSigns.toLowerCase()}',
            style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          children: category.signs
              .map((sign) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: sign.action.contains('CRITICAL') ||
                                    sign.action.contains('EMERGENCY')
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: FaIcon(
                              FontAwesomeIcons.exclamation,
                              color: sign.action.contains('CRITICAL') ||
                                      sign.action.contains('EMERGENCY')
                                  ? AppColors.error
                                  : AppColors.warning,
                              size: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sign.sign,
                                  style: AppTheme.bodySmall
                                      .copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                sign.action,
                                style: AppTheme.labelSmall.copyWith(
                                  color: sign.action.contains('CRITICAL') ||
                                          sign.action.contains('EMERGENCY')
                                      ? AppColors.error
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildReferralCriteriaTab(AppLocalizations l10n) {
    // Use backend referral criteria if available
    if (_useBackend &&
        (_apiReferralCriteria.isNotEmpty || _isLoadingReferralCriteria)) {
      if (_isLoadingReferralCriteria) {
        return const Center(child: CircularProgressIndicator());
      }

      // Group by condition category
      final groupedCriteria = <String, List<api.ReferralCriteria>>{};
      for (final criteria in _apiReferralCriteria) {
        final category = criteria.conditionCategory;
        groupedCriteria.putIfAbsent(category, () => []).add(criteria);
      }

      return RefreshIndicator(
        onRefresh: _loadReferralCriteria,
        child: ListView.builder(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          itemCount: groupedCriteria.length,
          itemBuilder: (context, index) {
            final category = groupedCriteria.keys.elementAt(index);
            final criteriaList = groupedCriteria[category]!;
            return _buildApiReferralCriteriaCard(category, criteriaList, l10n);
          },
        ),
      );
    }

    // Fall back to local data
    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _referralCriteria.length,
      itemBuilder: (context, index) =>
          _buildReferralCriteriaCard(_referralCriteria[index], l10n),
    );
  }

  Widget _buildApiReferralCriteriaCard(String category,
      List<api.ReferralCriteria> criteriaList, AppLocalizations l10n) {
    final color = _getUrgencyColor(category);
    final icon = _getUrgencyIcon(category);

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: FaIcon(icon, color: color, size: 18),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    category,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              children: criteriaList
                  .map((criteria) => Padding(
                        padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FaIcon(FontAwesomeIcons.circleCheck,
                                    color: color, size: 14),
                                SizedBox(width: AppTheme.spacingSm),
                                Expanded(
                                  child: Text(criteria.conditionName,
                                      style: AppTheme.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            if (criteria.immediateReferralSigns.isNotEmpty)
                              Padding(
                                padding:
                                    EdgeInsets.only(left: AppTheme.spacingLg),
                                child: Text(
                                  criteria.immediateReferralSigns.join(', '),
                                  style: AppTheme.bodySmall
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            Container(
                              margin: EdgeInsets.only(
                                  left: AppTheme.spacingLg, top: 4),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getFacilityLevelColor(
                                        criteria.facilityLevelRequired)
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                'Refer to: ${criteria.facilityLevelRequired.name}',
                                style: AppTheme.labelSmall.copyWith(
                                  color: _getFacilityLevelColor(
                                      criteria.facilityLevelRequired),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    if (urgency.toLowerCase().contains('emergency')) return Colors.red;
    if (urgency.toLowerCase().contains('urgent')) return Colors.orange;
    if (urgency.toLowerCase().contains('non-urgent') ||
        urgency.toLowerCase().contains('planned')) return Colors.blue;
    return AppColors.primary;
  }

  IconData _getUrgencyIcon(String urgency) {
    if (urgency.toLowerCase().contains('emergency'))
      return FontAwesomeIcons.truckMedical;
    if (urgency.toLowerCase().contains('urgent'))
      return FontAwesomeIcons.clockRotateLeft;
    return FontAwesomeIcons.calendarCheck;
  }

  Color _getFacilityLevelColor(api.FacilityLevel level) {
    switch (level) {
      case api.FacilityLevel.community:
        return AppColors.success;
      case api.FacilityLevel.healthCenter:
        return Colors.blue;
      case api.FacilityLevel.districtHospital:
        return Colors.orange;
      case api.FacilityLevel.regionalHospital:
        return Colors.deepOrange;
      case api.FacilityLevel.nationalHospital:
        return Colors.red;
    }
  }

  Widget _buildReferralCriteriaCard(
      ReferralCriteria criteria, AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: criteria.color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: criteria.color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: criteria.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: criteria.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child:
                        FaIcon(criteria.icon, color: criteria.color, size: 18),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    criteria.category,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: criteria.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              children: criteria.criteria
                  .map((c) => Padding(
                        padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FaIcon(FontAwesomeIcons.circleCheck,
                                color: criteria.color, size: 14),
                            SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Text(c, style: AppTheme.bodySmall),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Data models
class ClinicalGuideline {
  final String id;
  final String title;
  final String category;
  final IconData icon;
  final Color color;
  final String content;
  final DateTime lastUpdated;
  final bool isBookmarked;

  ClinicalGuideline({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.color,
    required this.content,
    required this.lastUpdated,
    this.isBookmarked = false,
  });
}

class DangerSignCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<DangerSign> signs;

  DangerSignCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.signs,
  });
}

class DangerSign {
  final String sign;
  final String action;

  DangerSign(this.sign, this.action);
}

class ReferralCriteria {
  final String category;
  final Color color;
  final IconData icon;
  final List<String> criteria;

  ReferralCriteria({
    required this.category,
    required this.color,
    required this.icon,
    required this.criteria,
  });
}
