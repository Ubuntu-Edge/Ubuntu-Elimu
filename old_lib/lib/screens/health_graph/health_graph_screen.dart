import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/community_api_service.dart';
import '../../models/community_models.dart' as api;

/// Health Graph Screen - Community Social Determinant Mapping
/// Features:
/// - Shared Resource Linker (households linked to water sources, latrines)
/// - Sickness Time-Lapse (visual outbreak tracking over time)
/// - Proximity Risk Scoring (predictive health weather)
class HealthGraphScreen extends StatefulWidget {
  const HealthGraphScreen({super.key});

  @override
  State<HealthGraphScreen> createState() => _HealthGraphScreenState();
}

class _HealthGraphScreenState extends State<HealthGraphScreen>
    with SingleTickerProviderStateMixin {
  final CommunityApiService _communityApi = CommunityApiService.instance;

  late TabController _tabController;
  int _selectedTimeRange = 7; // Days for time-lapse
  double _timeSliderValue = 1.0; // For outbreak animation
  String? _selectedResourceType;

  // API data
  List<api.Household> _apiHouseholds = [];
  List<api.SharedResource> _apiResources = [];
  List<api.DiseaseCase> _apiDiseaseCases = [];
  // TODO: May be needed later for risk summary display
  // api.RiskScoreSummary? _riskSummary;
  bool _isLoading = true;
  String? _error;

  // Local display models (for UI compatibility)
  List<Household> _households = [];
  List<SharedResource> _resources = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load from API
      final results = await Future.wait([
        _communityApi.listHouseholds(perPage: 100),
        _communityApi.listResources(perPage: 100),
        _communityApi.listDiseaseCases(periodDays: 30, perPage: 100),
        _communityApi.getRiskScores(),
      ]);

      final householdsResponse = results[0] as api.HouseholdListResponse;
      final resourcesResponse = results[1] as api.SharedResourceListResponse;
      final diseaseCasesResponse = results[2] as api.DiseaseCaseListResponse;
      // TODO: Use riskSummary when UI is implemented
      // final riskSummary = results[3] as api.RiskScoreSummary;

      setState(() {
        _apiHouseholds = householdsResponse.data;
        _apiResources = resourcesResponse.data;
        _apiDiseaseCases = diseaseCasesResponse.data;
        // TODO: Use riskSummary when UI is implemented
        // _riskSummary = riskSummary;

        // Convert API data to local display models
        _convertApiDataToDisplayModels();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading community data from API: $e');
      // Fall back to demo data
      _loadDemoData();
    }
  }

  void _convertApiDataToDisplayModels() {
    // Convert API households to local Household model for display
    _households = _apiHouseholds.map((h) {
      // Find disease cases for this household
      final householdCases = _apiDiseaseCases
          .where((c) => c.householdId == h.id)
          .map((c) =>
              DiseaseCase(c.disease, c.caseDate, c.patientId ?? 'Unknown'))
          .toList();

      return Household(
        id: h.id,
        name: h.familyId ?? 'Household ${h.id.substring(0, 4)}',
        members: h.householdSize,
        children: h.vulnerableMembers,
        coordinates: (
          h.longitude * 0.01,
          h.latitude * 0.01
        ), // Normalize for display
        waterSourceId: h.waterAccess ? 'W001' : '',
        latrineId: h.sanitationAccess ? 'L001' : '',
        riskScore: h.riskScore.round(),
        riskFactors: _getRiskFactors(h),
        recentCases: householdCases,
      );
    }).toList();

    // Convert API resources to local SharedResource model
    _resources = _apiResources
        .map((r) => SharedResource(
              id: r.id,
              type: _mapResourceType(r.resourceType),
              name: r.name,
              coordinates: (r.longitude * 0.01, r.latitude * 0.01),
              status: r.functional
                  ? (r.usersCount > r.capacity
                      ? ResourceStatus.overcrowded
                      : ResourceStatus.safe)
                  : ResourceStatus.contaminated,
              linkedHouseholds: [], // Would need to be computed from household data
              notes: r.notes,
            ))
        .toList();

    // If no API data, use demo data
    if (_households.isEmpty) {
      _loadDemoData();
    }
  }

  List<String> _getRiskFactors(api.Household h) {
    final factors = <String>[];
    if (!h.waterAccess) factors.add('No safe water access');
    if (!h.sanitationAccess) factors.add('No sanitation access');
    if (h.vulnerableMembers > 2)
      factors.add('${h.vulnerableMembers} vulnerable members');
    if (h.riskLevel == api.RiskLevel.high ||
        h.riskLevel == api.RiskLevel.critical) {
      factors.add('High risk level');
    }
    return factors;
  }

  ResourceType _mapResourceType(String apiType) {
    switch (apiType) {
      case 'water_source':
        return ResourceType.waterSource;
      case 'latrine':
        return ResourceType.latrine;
      case 'clinic':
      case 'school':
        // Map clinic and school to waterSource as fallback (local enum only has 2 types)
        return ResourceType.waterSource;
      default:
        return ResourceType.waterSource;
    }
  }

  void _loadDemoData() {
    // Fall back demo data for when API is not available
    _households = [
      Household(
        id: 'H001',
        name: 'Mwangi Family',
        members: 6,
        children: 3,
        coordinates: (0.15, 0.25),
        waterSourceId: 'W001',
        latrineId: 'L001',
        riskScore: 75,
        riskFactors: [
          'Contaminated water source',
          '3 children under 5',
          'No bed nets'
        ],
        recentCases: [
          DiseaseCase('Diarrhea',
              DateTime.now().subtract(const Duration(days: 3)), 'Child, 3yrs'),
          DiseaseCase('Malaria',
              DateTime.now().subtract(const Duration(days: 10)), 'Child, 5yrs'),
        ],
      ),
      Household(
        id: 'H002',
        name: 'Ochieng Family',
        members: 4,
        children: 2,
        coordinates: (0.35, 0.30),
        waterSourceId: 'W001',
        latrineId: 'L002',
        riskScore: 45,
        riskFactors: ['Contaminated water source'],
        recentCases: [],
      ),
      Household(
        id: 'H003',
        name: 'Kamau Family',
        members: 5,
        children: 2,
        coordinates: (0.55, 0.40),
        waterSourceId: 'W002',
        latrineId: 'L003',
        riskScore: 25,
        riskFactors: [],
        recentCases: [],
      ),
      Household(
        id: 'H004',
        name: 'Wanjiku Family',
        members: 7,
        children: 4,
        coordinates: (0.25, 0.60),
        waterSourceId: 'W001',
        latrineId: 'L001',
        riskScore: 85,
        riskFactors: [
          'Contaminated water source',
          'Shared latrine overcrowded',
          '4 children under 5',
          'Pregnant woman'
        ],
        recentCases: [
          DiseaseCase('Cholera suspected',
              DateTime.now().subtract(const Duration(days: 1)), 'Adult female'),
          DiseaseCase('Diarrhea',
              DateTime.now().subtract(const Duration(days: 2)), 'Child, 2yrs'),
        ],
      ),
      Household(
        id: 'H005',
        name: 'Njoroge Family',
        members: 3,
        children: 1,
        coordinates: (0.70, 0.55),
        waterSourceId: 'W002',
        latrineId: 'L004',
        riskScore: 20,
        riskFactors: [],
        recentCases: [],
      ),
      Household(
        id: 'H006',
        name: 'Akinyi Family',
        members: 8,
        children: 5,
        coordinates: (0.45, 0.75),
        waterSourceId: 'W003',
        latrineId: 'L002',
        riskScore: 60,
        riskFactors: [
          'Large family',
          '5 children under 5',
          'No hand washing station'
        ],
        recentCases: [
          DiseaseCase('Malaria',
              DateTime.now().subtract(const Duration(days: 5)), 'Child, 4yrs'),
        ],
      ),
    ];

    _resources = [
      SharedResource(
        id: 'W001',
        type: ResourceType.waterSource,
        name: 'Village Borehole A',
        coordinates: (0.25, 0.35),
        status: ResourceStatus.contaminated,
        linkedHouseholds: ['H001', 'H002', 'H004'],
        notes: 'E. coli detected - 12/01/2024',
      ),
      SharedResource(
        id: 'W002',
        type: ResourceType.waterSource,
        name: 'Protected Spring',
        coordinates: (0.60, 0.45),
        status: ResourceStatus.safe,
        linkedHouseholds: ['H003', 'H005'],
        notes: 'Last tested: 10/01/2024 - Clear',
      ),
      SharedResource(
        id: 'W003',
        type: ResourceType.waterSource,
        name: 'River Collection Point',
        coordinates: (0.40, 0.80),
        status: ResourceStatus.unknown,
        linkedHouseholds: ['H006'],
        notes: 'Needs testing',
      ),
      SharedResource(
        id: 'L001',
        type: ResourceType.latrine,
        name: 'Community Latrine Block A',
        coordinates: (0.20, 0.45),
        status: ResourceStatus.overcrowded,
        linkedHouseholds: ['H001', 'H004'],
        notes: '13 users - capacity 8',
      ),
      SharedResource(
        id: 'L002',
        type: ResourceType.latrine,
        name: 'Community Latrine Block B',
        coordinates: (0.38, 0.50),
        status: ResourceStatus.safe,
        linkedHouseholds: ['H002', 'H006'],
        notes: '6 users - good condition',
      ),
      SharedResource(
        id: 'L003',
        type: ResourceType.latrine,
        name: 'Kamau Private Latrine',
        coordinates: (0.58, 0.42),
        status: ResourceStatus.safe,
        linkedHouseholds: ['H003'],
        notes: 'Private - good condition',
      ),
      SharedResource(
        id: 'L004',
        type: ResourceType.latrine,
        name: 'Njoroge Private Latrine',
        coordinates: (0.72, 0.53),
        status: ResourceStatus.safe,
        linkedHouseholds: ['H005'],
        notes: 'Private - good condition',
      ),
    ];
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
            _buildTabBar(l10n),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState(l10n)
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildResourceLinkerTab(l10n),
                              _buildTimeLapseTab(l10n),
                              _buildRiskScoringTab(l10n),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.circleExclamation,
                size: 48, color: AppColors.error),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            SizedBox(height: AppTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
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
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
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
                        l10n.healthGraph,
                        style: AppTheme.headingMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.communityMap,
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const FaIcon(FontAwesomeIcons.mapLocationDot,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                _buildHeaderStat(
                  icon: FontAwesomeIcons.house,
                  value: '${_households.length}',
                  label: l10n.translate('households') ?? 'Households',
                ),
                SizedBox(width: AppTheme.spacingSm),
                _buildHeaderStat(
                  icon: FontAwesomeIcons.droplet,
                  value:
                      '${_resources.where((r) => r.type == ResourceType.waterSource).length}',
                  label: l10n.waterSources,
                ),
                SizedBox(width: AppTheme.spacingSm),
                _buildHeaderStat(
                  icon: FontAwesomeIcons.triangleExclamation,
                  value:
                      '${_households.where((h) => h.riskScore >= 60).length}',
                  label: l10n.highRisk,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: Colors.white, size: 16),
            SizedBox(height: AppTheme.spacingXs),
            Text(
              value,
              style: AppTheme.headingSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTheme.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.all(AppTheme.spacingMd),
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
          color: AppColors.primary,
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
                FaIcon(FontAwesomeIcons.link, size: 12),
                SizedBox(width: AppTheme.spacingXs),
                Flexible(
                    child: Text(l10n.sharedResources.split(' ').first,
                        style: AppTheme.labelSmall)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.clock, size: 12),
                SizedBox(width: AppTheme.spacingXs),
                Flexible(
                    child: Text(l10n.translate('timeLapse') ?? 'Time-Lapse',
                        style: AppTheme.labelSmall)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.gauge, size: 12),
                SizedBox(width: AppTheme.spacingXs),
                Flexible(
                    child: Text(l10n.riskScoring.split(' ').first,
                        style: AppTheme.labelSmall)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceLinkerTab(AppLocalizations l10n) {
    return Column(
      children: [
        // Resource filter chips
        Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip(null, l10n.translate('all') ?? 'All', l10n),
              SizedBox(width: AppTheme.spacingSm),
              _buildFilterChip('water', l10n.waterSources, l10n),
              SizedBox(width: AppTheme.spacingSm),
              _buildFilterChip(
                  'latrine', l10n.translate('latrines') ?? 'Latrines', l10n),
            ],
          ),
        ),

        // Map visualization (simplified)
        Expanded(
          child: Container(
            margin: EdgeInsets.all(AppTheme.spacingMd),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Background grid
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade100,
                        ],
                      ),
                    ),
                  ),

                  // Connection lines between households and resources
                  CustomPaint(
                    size: Size.infinite,
                    painter: ConnectionPainter(
                      households: _households,
                      resources: _resources,
                      selectedType: _selectedResourceType,
                    ),
                  ),

                  // Resources
                  ..._resources
                      .where((r) =>
                          _selectedResourceType == null ||
                          (_selectedResourceType == 'water' &&
                              r.type == ResourceType.waterSource) ||
                          (_selectedResourceType == 'latrine' &&
                              r.type == ResourceType.latrine))
                      .map((resource) => _buildResourceMarker(resource, l10n)),

                  // Households
                  ..._households.map(
                      (household) => _buildHouseholdMarker(household, l10n)),

                  // Legend
                  Positioned(
                    left: AppTheme.spacingSm,
                    bottom: AppTheme.spacingSm,
                    child: _buildMapLegend(l10n),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Resource summary cards
        Container(
          height: 120,
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _resources
                .where((r) => r.status != ResourceStatus.safe)
                .map((r) => _buildResourceSummaryCard(r, l10n))
                .toList(),
          ),
        ),
        SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }

  Widget _buildFilterChip(String? type, String label, AppLocalizations l10n) {
    final isSelected = _selectedResourceType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedResourceType = type),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildResourceMarker(SharedResource resource, AppLocalizations l10n) {
    final color = _getResourceStatusColor(resource.status);
    final icon = resource.type == ResourceType.waterSource
        ? FontAwesomeIcons.droplet
        : FontAwesomeIcons.toilet;

    return Positioned(
      left: resource.coordinates.$1 * MediaQuery.of(context).size.width * 0.85,
      top: resource.coordinates.$2 * 300,
      child: GestureDetector(
        onTap: () => _showResourceDetails(resource, l10n),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: FaIcon(icon, color: Colors.white, size: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildHouseholdMarker(Household household, AppLocalizations l10n) {
    final riskColor = _getRiskColor(household.riskScore);

    return Positioned(
      left: household.coordinates.$1 * MediaQuery.of(context).size.width * 0.85,
      top: household.coordinates.$2 * 300,
      child: GestureDetector(
        onTap: () => _showHouseholdDetails(household, l10n),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: riskColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child:
                FaIcon(FontAwesomeIcons.house, color: Colors.white, size: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildMapLegend(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(Colors.green, l10n.translate('safe') ?? 'Safe'),
          _buildLegendItem(
              Colors.orange, l10n.translate('warning') ?? 'Warning'),
          _buildLegendItem(
              Colors.red, l10n.translate('contaminated') ?? 'Contaminated'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppTheme.spacingXs),
          Text(label, style: AppTheme.labelSmall.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildResourceSummaryCard(
      SharedResource resource, AppLocalizations l10n) {
    final color = _getResourceStatusColor(resource.status);

    return Container(
      width: 200,
      margin: EdgeInsets.only(right: AppTheme.spacingSm),
      padding: EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: FaIcon(
                    resource.type == ResourceType.waterSource
                        ? FontAwesomeIcons.droplet
                        : FontAwesomeIcons.toilet,
                    color: color,
                    size: 14,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  resource.name,
                  style:
                      AppTheme.labelSmall.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingXs),
          Text(
            '${resource.linkedHouseholds.length} ${l10n.translate('householdsConnected') ?? 'households connected'}',
            style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getStatusLabel(resource.status),
              style: AppTheme.labelSmall.copyWith(color: color, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLapseTab(AppLocalizations l10n) {
    // Get cases within the time range
    final casesInRange = <DiseaseCase>[];
    for (final household in _households) {
      for (final c in household.recentCases) {
        if (c.date.isAfter(
            DateTime.now().subtract(Duration(days: _selectedTimeRange)))) {
          casesInRange.add(c);
        }
      }
    }

    return Column(
      children: [
        // Time range selector
        Container(
          margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          padding: EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('timeRange') ?? 'Time Range',
                style:
                    AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  _buildTimeRangeChip(
                      7, '7 ${l10n.translate('days') ?? 'days'}'),
                  SizedBox(width: AppTheme.spacingSm),
                  _buildTimeRangeChip(
                      14, '14 ${l10n.translate('days') ?? 'days'}'),
                  SizedBox(width: AppTheme.spacingSm),
                  _buildTimeRangeChip(
                      30, '30 ${l10n.translate('days') ?? 'days'}'),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: AppTheme.spacingMd),

        // Time slider for animation
        Container(
          margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          padding: EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_selectedTimeRange ${l10n.translate('daysAgoLabel') ?? 'days ago'}',
                    style: AppTheme.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    l10n.translate('today') ?? 'Today',
                    style: AppTheme.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Slider(
                value: _timeSliderValue,
                min: 0,
                max: 1,
                divisions: _selectedTimeRange,
                activeColor: AppColors.primary,
                onChanged: (value) => setState(() => _timeSliderValue = value),
              ),
              Center(
                child: Text(
                  _formatSliderDate(_timeSliderValue),
                  style: AppTheme.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: AppTheme.spacingMd),

        // Cases timeline
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            padding: EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.virus,
                        color: AppColors.error, size: 16),
                    SizedBox(width: AppTheme.spacingSm),
                    Text(
                      '${l10n.translate('casesReported') ?? 'Cases Reported'}: ${casesInRange.length}',
                      style: AppTheme.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingMd),
                Expanded(
                  child: casesInRange.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(FontAwesomeIcons.circleCheck,
                                  color: AppColors.success, size: 48),
                              SizedBox(height: AppTheme.spacingMd),
                              Text(
                                l10n.translate('noCasesReported') ??
                                    'No cases reported in this period',
                                style: AppTheme.bodyMedium
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _households
                              .where((h) => h.recentCases.isNotEmpty)
                              .length,
                          itemBuilder: (context, index) {
                            final household = _households
                                .where((h) => h.recentCases.isNotEmpty)
                                .toList()[index];
                            return _buildCaseTimelineItem(household, l10n);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }

  Widget _buildTimeRangeChip(int days, String label) {
    final isSelected = _selectedTimeRange == days;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeRange = days),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCaseTimelineItem(Household household, AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.house, color: AppColors.error, size: 12),
              SizedBox(width: AppTheme.spacingXs),
              Text(
                household.name,
                style:
                    AppTheme.labelMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingXs),
          ...household.recentCases.map((c) => Padding(
                padding: EdgeInsets.only(left: AppTheme.spacingMd, top: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        '${c.disease} - ${c.patientInfo} (${_formatDate(c.date)})',
                        style: AppTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRiskScoringTab(AppLocalizations l10n) {
    // Sort households by risk score
    final sortedHouseholds = List<Household>.from(_households)
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return ListView(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Risk summary
        Container(
          padding: EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.cloudSunRain,
                      color: AppColors.primary, size: 18),
                  SizedBox(width: AppTheme.spacingSm),
                  Text(
                    l10n.translate('healthWeather') ?? 'Health Weather',
                    style: AppTheme.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _buildWeatherCard(
                      icon: FontAwesomeIcons.sun,
                      color: AppColors.success,
                      label: l10n.translate('lowRisk') ?? 'Low Risk',
                      count: _households.where((h) => h.riskScore < 40).length,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: _buildWeatherCard(
                      icon: FontAwesomeIcons.cloudSun,
                      color: AppColors.warning,
                      label: l10n.translate('mediumRisk') ?? 'Medium',
                      count: _households
                          .where((h) => h.riskScore >= 40 && h.riskScore < 60)
                          .length,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: _buildWeatherCard(
                      icon: FontAwesomeIcons.cloudBolt,
                      color: AppColors.error,
                      label: l10n.highRisk,
                      count: _households.where((h) => h.riskScore >= 60).length,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: AppTheme.spacingMd),

        Text(
          l10n.translate('householdRiskRanking') ?? 'Household Risk Ranking',
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: AppTheme.spacingSm),

        // Household risk cards
        ...sortedHouseholds
            .map((household) => _buildHouseholdRiskCard(household, l10n)),
      ],
    );
  }

  Widget _buildWeatherCard({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 24),
          SizedBox(height: AppTheme.spacingXs),
          Text(
            '$count',
            style: AppTheme.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdRiskCard(Household household, AppLocalizations l10n) {
    final riskColor = _getRiskColor(household.riskScore);

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: riskColor, width: 4),
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: riskColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${household.riskScore}',
              style: AppTheme.bodyMedium.copyWith(
                color: riskColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(household.name,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${household.members} ${l10n.translate('members') ?? 'members'} • ${household.children} ${l10n.translate('children') ?? 'children'}',
          style: AppTheme.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        children: [
          if (household.riskFactors.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('riskFactors') ?? 'Risk Factors',
                    style: AppTheme.labelMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppTheme.spacingXs),
                  ...household.riskFactors.map((factor) => Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.triangleExclamation,
                                color: riskColor, size: 12),
                            SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                                child: Text(factor, style: AppTheme.bodySmall)),
                          ],
                        ),
                      )),
                  SizedBox(height: AppTheme.spacingMd),
                ],
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppTheme.spacingMd, 0, AppTheme.spacingMd, AppTheme.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: FaIcon(FontAwesomeIcons.eye, size: 14),
                    label: Text(l10n.translate('viewDetails') ?? 'Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: FaIcon(FontAwesomeIcons.calendarPlus,
                        size: 14, color: Colors.white),
                    label: Text(l10n.translate('scheduleVisit') ?? 'Visit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResourceDetails(SharedResource resource, AppLocalizations l10n) {
    final linkedHouseholds = _households
        .where((h) => resource.linkedHouseholds.contains(h.id))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getResourceStatusColor(resource.status)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: FaIcon(
                      resource.type == ResourceType.waterSource
                          ? FontAwesomeIcons.droplet
                          : FontAwesomeIcons.toilet,
                      color: _getResourceStatusColor(resource.status),
                      size: 22,
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resource.name,
                          style: AppTheme.headingSmall
                              .copyWith(fontWeight: FontWeight.bold)),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getResourceStatusColor(resource.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusLabel(resource.status),
                          style: AppTheme.labelSmall.copyWith(
                            color: _getResourceStatusColor(resource.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingMd),
            Text(resource.notes ?? '',
                style: AppTheme.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              '${l10n.translate('connectedHouseholds') ?? 'Connected Households'} (${linkedHouseholds.length})',
              style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: AppTheme.spacingSm),
            ...linkedHouseholds.map((h) => ListTile(
                  dense: true,
                  leading: FaIcon(FontAwesomeIcons.house,
                      size: 16, color: _getRiskColor(h.riskScore)),
                  title: Text(h.name, style: AppTheme.bodySmall),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRiskColor(h.riskScore).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${l10n.translate('risk') ?? 'Risk'}: ${h.riskScore}',
                      style: AppTheme.labelSmall
                          .copyWith(color: _getRiskColor(h.riskScore)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showHouseholdDetails(Household household, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getRiskColor(household.riskScore)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${household.riskScore}',
                      style: AppTheme.headingSmall.copyWith(
                        color: _getRiskColor(household.riskScore),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(household.name,
                          style: AppTheme.headingSmall
                              .copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${household.members} ${l10n.translate('members') ?? 'members'}, ${household.children} ${l10n.translate('childrenUnder5') ?? 'children under 5'}',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingMd),
            if (household.riskFactors.isNotEmpty) ...[
              Text(
                l10n.translate('riskFactors') ?? 'Risk Factors',
                style:
                    AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppTheme.spacingXs),
              ...household.riskFactors.map((f) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.exclamation,
                            color: AppColors.warning, size: 12),
                        SizedBox(width: AppTheme.spacingSm),
                        Expanded(child: Text(f, style: AppTheme.bodySmall)),
                      ],
                    ),
                  )),
            ],
            SizedBox(height: AppTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to patient list for this household
              },
              icon:
                  FaIcon(FontAwesomeIcons.users, size: 14, color: Colors.white),
              label: Text(l10n.translate('viewHouseholdMembers') ??
                  'View Household Members'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getResourceStatusColor(ResourceStatus status) {
    switch (status) {
      case ResourceStatus.safe:
        return AppColors.success;
      case ResourceStatus.contaminated:
        return AppColors.error;
      case ResourceStatus.overcrowded:
        return AppColors.warning;
      case ResourceStatus.unknown:
        return Colors.grey;
    }
  }

  String _getStatusLabel(ResourceStatus status) {
    switch (status) {
      case ResourceStatus.safe:
        return 'Safe';
      case ResourceStatus.contaminated:
        return 'Contaminated';
      case ResourceStatus.overcrowded:
        return 'Overcrowded';
      case ResourceStatus.unknown:
        return 'Unknown';
    }
  }

  Color _getRiskColor(int riskScore) {
    if (riskScore >= 70) return AppColors.error;
    if (riskScore >= 50) return Colors.orange;
    if (riskScore >= 30) return AppColors.warning;
    return AppColors.success;
  }

  String _formatSliderDate(double value) {
    final daysAgo = ((_selectedTimeRange) * (1 - value)).round();
    if (daysAgo == 0) return 'Today';
    return _formatDate(DateTime.now().subtract(Duration(days: daysAgo)));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

// Custom painter for connection lines
class ConnectionPainter extends CustomPainter {
  final List<Household> households;
  final List<SharedResource> resources;
  final String? selectedType;

  ConnectionPainter({
    required this.households,
    required this.resources,
    this.selectedType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final household in households) {
      // Draw water connection
      if (selectedType == null || selectedType == 'water') {
        final waterSource = resources.firstWhere(
          (r) => r.id == household.waterSourceId,
          orElse: () => resources.first,
        );

        paint.color =
            _getStatusColor(waterSource.status).withValues(alpha: 0.4);

        final start = Offset(
          household.coordinates.$1 * size.width * 0.85 + 14,
          household.coordinates.$2 * 300 + 14,
        );
        final end = Offset(
          waterSource.coordinates.$1 * size.width * 0.85 + 18,
          waterSource.coordinates.$2 * 300 + 18,
        );

        canvas.drawLine(start, end, paint);
      }

      // Draw latrine connection
      if (selectedType == null || selectedType == 'latrine') {
        final latrine = resources.firstWhere(
          (r) => r.id == household.latrineId,
          orElse: () => resources.first,
        );

        paint.color = _getStatusColor(latrine.status).withValues(alpha: 0.3);

        final start = Offset(
          household.coordinates.$1 * size.width * 0.85 + 14,
          household.coordinates.$2 * 300 + 14,
        );
        final end = Offset(
          latrine.coordinates.$1 * size.width * 0.85 + 18,
          latrine.coordinates.$2 * 300 + 18,
        );

        canvas.drawLine(start, end, paint);
      }
    }
  }

  Color _getStatusColor(ResourceStatus status) {
    switch (status) {
      case ResourceStatus.safe:
        return Colors.green;
      case ResourceStatus.contaminated:
        return Colors.red;
      case ResourceStatus.overcrowded:
        return Colors.orange;
      case ResourceStatus.unknown:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data models
class Household {
  final String id;
  final String name;
  final int members;
  final int children;
  final (double, double) coordinates;
  final String waterSourceId;
  final String latrineId;
  final int riskScore;
  final List<String> riskFactors;
  final List<DiseaseCase> recentCases;

  Household({
    required this.id,
    required this.name,
    required this.members,
    required this.children,
    required this.coordinates,
    required this.waterSourceId,
    required this.latrineId,
    required this.riskScore,
    required this.riskFactors,
    required this.recentCases,
  });
}

class SharedResource {
  final String id;
  final ResourceType type;
  final String name;
  final (double, double) coordinates;
  final ResourceStatus status;
  final List<String> linkedHouseholds;
  final String? notes;

  SharedResource({
    required this.id,
    required this.type,
    required this.name,
    required this.coordinates,
    required this.status,
    required this.linkedHouseholds,
    this.notes,
  });
}

class DiseaseCase {
  final String disease;
  final DateTime date;
  final String patientInfo;

  DiseaseCase(this.disease, this.date, this.patientInfo);
}

enum ResourceType { waterSource, latrine }

enum ResourceStatus { safe, contaminated, overcrowded, unknown }
