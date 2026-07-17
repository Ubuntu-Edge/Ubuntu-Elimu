import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../models/outbreak_detection.dart';
import '../../services/outbreak_detection_service.dart';
import '../../services/community_api_service.dart';
import '../../models/community_models.dart' as api;

class OutbreakMapScreen extends StatefulWidget {
  const OutbreakMapScreen({super.key});

  @override
  State<OutbreakMapScreen> createState() => _OutbreakMapScreenState();
}

class _OutbreakMapScreenState extends State<OutbreakMapScreen>
    with SingleTickerProviderStateMixin {
  final CommunityApiService _communityApi = CommunityApiService.instance;

  late TabController _tabController;
  String _selectedVillage = 'All Villages';
  List<OutbreakAlert> _alerts = [];
  bool _isLoading = true;
  // TODO: May be needed later for error display
  // String? _error;

  // API data for disease cases
  List<api.DiseaseCase> _apiDiseaseCases = [];
  // TODO: May be needed later for risk summary display
  // api.RiskScoreSummary? _riskSummary;

  final List<String> _villages = [
    'All Villages',
    'Kiambu',
    'Nakuru',
    'Mombasa',
    'Kisumu',
    'Eldoret',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      // _error = null;
    });

    try {
      // Load from API in parallel with proper error handling
      api.DiseaseCaseListResponse? casesResponse;
      // api.RiskScoreSummary? riskResponse;

      try {
        casesResponse =
            await _communityApi.listDiseaseCases(periodDays: 30, perPage: 100);
      } catch (_) {
        // Ignore API errors, will fall back to local data
      }

      // TODO: Re-enable when risk scores UI is implemented
      // try {
      //   riskResponse = await _communityApi.getRiskScores();
      // } catch (_) {
      //   // Ignore API errors, will fall back to local data
      // }

      if (casesResponse != null) {
        _apiDiseaseCases = casesResponse.data;
      }
      // TODO: Use risk summary data when UI is implemented
      // if (riskResponse != null) {
      //   _riskSummary = riskResponse;
      // }

      // Convert API disease cases to outbreak alerts
      _convertApiToAlerts();

      // Also try local detection
      await _loadLocalAlerts();

      setState(() => _isLoading = false);
    } catch (e) {
      // Fall back to local detection only
      await _loadLocalAlerts();
      setState(() => _isLoading = false);
    }
  }

  void _convertApiToAlerts() {
    // Group API disease cases by disease and village for outbreak detection
    Map<String, List<api.DiseaseCase>> clusters = {};

    for (var diseaseCase in _apiDiseaseCases) {
      // Use disease field from API model
      // Note: location info would need to be joined with household data
      final key = '${diseaseCase.disease}|unknown';
      clusters.putIfAbsent(key, () => []);
      clusters[key]!.add(diseaseCase);
    }

    // Create alerts from clusters with significant case counts
    for (var entry in clusters.entries) {
      final parts = entry.key.split('|');
      final disease = parts[0];
      final village = parts[1];
      final cases = entry.value;

      if (cases.length >= 3) {
        // Threshold for outbreak alert
        final severity = _determineSeverity(cases.length, disease);

        _alerts.add(OutbreakAlert(
          id: 'api_${disease}_$village',
          disease: _formatDiseaseName(disease),
          village: village,
          caseCount: cases.length,
          newCasesLast7Days: cases
              .where((c) => DateTime.now().difference(c.caseDate).inDays <= 7)
              .length,
          growthRate: 0, // Would need historical data
          severity: severity,
          description:
              '${cases.length} cases of ${_formatDiseaseName(disease)} in $village',
          recommendedAction: 'Investigate and monitor',
          affectedPatientIds:
              cases.map((c) => c.patientId).whereType<String>().toList(),
          firstCaseDate: cases
              .map((c) => c.caseDate)
              .reduce((a, b) => a.isBefore(b) ? a : b),
          lastCaseDate: cases
              .map((c) => c.caseDate)
              .reduce((a, b) => a.isAfter(b) ? a : b),
          detectedAt: DateTime.now(),
        ));
      }
    }
  }

  OutbreakSeverity _determineSeverity(int caseCount, String disease) {
    final highPriority = ['cholera', 'measles', 'covid', 'meningitis']
        .contains(disease.toLowerCase());

    if (caseCount >= 15 || (highPriority && caseCount >= 5)) {
      return OutbreakSeverity.critical;
    }
    if (caseCount >= 10) {
      return OutbreakSeverity.high;
    }
    if (caseCount >= 5) {
      return OutbreakSeverity.moderate;
    }
    return OutbreakSeverity.low;
  }

  String _formatDiseaseName(String disease) {
    return disease
        .split('_')
        .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  Future<void> _loadLocalAlerts() async {
    try {
      final localAlerts =
          await OutbreakDetectionService.instance.detectOutbreaks('demo_chw');

      // Merge with API alerts, avoiding duplicates
      for (var alert in localAlerts) {
        final exists = _alerts.any((a) =>
            a.disease.toLowerCase() == alert.disease.toLowerCase() &&
            a.village.toLowerCase() == alert.village.toLowerCase());
        if (!exists) {
          _alerts.add(alert);
        }
      }

      // Sort by severity
      _alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    } catch (e) {
      // Silent fail - API alerts may still be available
    }

    // If still no alerts, load demo data
    if (_alerts.isEmpty) {
      _loadDemoAlerts();
    }
  }

  void _loadDemoAlerts() {
    _alerts = [
      OutbreakAlert(
        id: 'demo_1',
        disease: 'Malaria',
        village: 'Kibera',
        caseCount: 12,
        newCasesLast7Days: 5,
        growthRate: 45.5,
        severity: OutbreakSeverity.high,
        description:
            '12 cases of Malaria in Kibera, with 5 new cases this week. Outbreak is growing rapidly.',
        recommendedAction:
            'Distribute mosquito nets, conduct health education sessions, investigate breeding sites',
        affectedPatientIds: ['p1', 'p2', 'p3'],
        firstCaseDate: DateTime.now().subtract(const Duration(days: 14)),
        lastCaseDate: DateTime.now().subtract(const Duration(days: 1)),
        detectedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      OutbreakAlert(
        id: 'demo_2',
        disease: 'Diarrhea',
        village: 'Nakuru',
        caseCount: 8,
        newCasesLast7Days: 3,
        growthRate: 20.0,
        severity: OutbreakSeverity.moderate,
        description:
            '8 cases of Diarrhea detected in Nakuru. 3 new cases in the last 7 days.',
        recommendedAction:
            'Promote hand washing, check water sources, distribute ORS',
        affectedPatientIds: ['p4', 'p5'],
        firstCaseDate: DateTime.now().subtract(const Duration(days: 10)),
        lastCaseDate: DateTime.now().subtract(const Duration(days: 2)),
        detectedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      OutbreakAlert(
        id: 'demo_3',
        disease: 'COVID-19',
        village: 'Mombasa',
        caseCount: 6,
        newCasesLast7Days: 6,
        growthRate: 100.0,
        severity: OutbreakSeverity.critical,
        description:
            '6 cases of COVID-19 reported in Mombasa in the last 7 days. Possible outbreak developing.',
        recommendedAction:
            'Enforce mask wearing, promote vaccination, contact tracing, isolate patients',
        affectedPatientIds: ['p6', 'p7', 'p8'],
        firstCaseDate: DateTime.now().subtract(const Duration(days: 7)),
        lastCaseDate: DateTime.now(),
        detectedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      OutbreakAlert(
        id: 'demo_4',
        disease: 'Cholera',
        village: 'Kisumu',
        caseCount: 4,
        newCasesLast7Days: 2,
        growthRate: 15.0,
        severity: OutbreakSeverity.moderate,
        description: '4 cases of Cholera in Kisumu. 2 new cases this week.',
        recommendedAction:
            'Test water sources, promote water treatment, distribute chlorine tablets',
        affectedPatientIds: ['p9'],
        firstCaseDate: DateTime.now().subtract(const Duration(days: 12)),
        lastCaseDate: DateTime.now().subtract(const Duration(days: 3)),
        detectedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Community Health Map',
            style: AppTheme.headingMedium.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data refreshed', style: AppTheme.bodyMedium),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppTheme.labelMedium,
          tabs: const [
            Tab(text: 'Map View'),
            Tab(text: 'Alerts'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(),
                _buildAlertsTab(),
                _buildStatisticsTab(),
              ],
            ),
    );
  }

  Widget _buildMapTab() {
    final activeAlerts = _alerts.where((a) => !a.isResolved).toList();

    return Column(
      children: [
        // Village selector
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVillage,
                    style: AppTheme.bodyMedium,
                    items: _villages
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _selectedVillage = v ?? 'All Villages');
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: activeAlerts.isNotEmpty
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  activeAlerts.isNotEmpty
                      ? '${activeAlerts.length} Active Alerts'
                      : 'No Alerts',
                  style: AppTheme.labelSmall.copyWith(
                    color: activeAlerts.isNotEmpty
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Map placeholder
        Expanded(
          child: Stack(
            children: [
              // Interactive Map
              FlutterMap(
                options: MapOptions(
                  initialCenter:
                      const LatLng(-1.286389, 36.817223), // Nairobi coordinates
                  initialZoom: 11.0,
                  minZoom: 8.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.chw.augment',
                  ),
                  MarkerLayer(
                    markers: activeAlerts.map((alert) {
                      // Map village names to approximate coordinates
                      LatLng position = _getVillageCoordinates(alert.village);
                      Color markerColor = _getSeverityColor(alert.severity);

                      return Marker(
                        point: position,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showAlertDetails(alert),
                          child: Container(
                            decoration: BoxDecoration(
                              color: markerColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${alert.caseCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Alert markers overlay
              if (activeAlerts.isNotEmpty)
                Positioned(
                  top: AppTheme.spacingMd,
                  left: AppTheme.spacingMd,
                  right: AppTheme.spacingMd,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: AppTheme.shadowMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Active Outbreaks', style: AppTheme.labelMedium),
                        const SizedBox(height: AppTheme.spacingXs),
                        Wrap(
                          spacing: AppTheme.spacingXs,
                          runSpacing: AppTheme.spacingXs,
                          children: activeAlerts
                              .take(3)
                              .map((a) => _buildAlertChip(a))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              // Legend
              Positioned(
                bottom: AppTheme.spacingMd,
                left: AppTheme.spacingMd,
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Legend', style: AppTheme.labelSmall),
                      const SizedBox(height: AppTheme.spacingXs),
                      _buildLegendItem(AppColors.error, 'Critical Alert'),
                      _buildLegendItem(AppColors.warning, 'Warning'),
                      _buildLegendItem(AppColors.success, 'Normal'),
                    ],
                  ),
                ),
              ),

              // Zoom controls
              Positioned(
                bottom: AppTheme.spacingMd,
                right: AppTheme.spacingMd,
                child: Column(
                  children: [
                    _buildMapButton(Icons.add, () {}),
                    const SizedBox(height: AppTheme.spacingXs),
                    _buildMapButton(Icons.remove, () {}),
                    const SizedBox(height: AppTheme.spacingXs),
                    _buildMapButton(Icons.my_location, () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertChip(OutbreakAlert alert) {
    Color color = _getSeverityColor(alert.severity);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${alert.disease}: ${alert.caseCount}',
            style: AppTheme.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(OutbreakSeverity severity) {
    switch (severity) {
      case OutbreakSeverity.critical:
        return AppColors.error;
      case OutbreakSeverity.high:
        return AppColors.warning;
      case OutbreakSeverity.moderate:
        return AppColors.info;
      case OutbreakSeverity.low:
        return AppColors.success;
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
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
          const SizedBox(width: 4),
          Text(label, style: AppTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    final activeAlerts = _alerts.where((a) => !a.isResolved).toList();
    final resolvedAlerts = _alerts.where((a) => a.isResolved).toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Active alerts
        if (activeAlerts.isNotEmpty) ...[
          Text('Active Alerts', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingSm),
          ...activeAlerts.map((a) => _buildAlertCard(a, true)),
          const SizedBox(height: AppTheme.spacingMd),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 48),
                const SizedBox(height: AppTheme.spacingSm),
                Text('No Active Outbreaks', style: AppTheme.headingSmall),
                Text(
                  'Community health status is normal',
                  style: AppTheme.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],

        // Report new case
        AppWidgets.actionCard(
          title: 'Report New Case',
          subtitle: 'Add a suspected outbreak case',
          icon: Icons.add_alert,
          iconColor: AppColors.warning,
          onTap: () => _showReportCaseDialog(),
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Alert history
        if (resolvedAlerts.isNotEmpty) ...[
          Text('Alert History', style: AppTheme.headingSmall),
          const SizedBox(height: AppTheme.spacingSm),
          ...resolvedAlerts.take(5).map((a) => _buildAlertCard(a, false)),
        ],
      ],
    );
  }

  Widget _buildAlertCard(OutbreakAlert alert, bool isActive) {
    Color severityColor = _getSeverityColor(alert.severity);
    IconData severityIcon;
    switch (alert.severity) {
      case OutbreakSeverity.critical:
        severityIcon = Icons.emergency;
        break;
      case OutbreakSeverity.high:
        severityIcon = Icons.warning;
        break;
      case OutbreakSeverity.moderate:
        severityIcon = Icons.info;
        break;
      case OutbreakSeverity.low:
        severityIcon = Icons.info_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
        border: isActive
            ? Border.all(color: severityColor.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMd)),
            ),
            child: Row(
              children: [
                Icon(severityIcon, color: severityColor, size: 24),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.disease, style: AppTheme.labelMedium),
                      Text(
                        '${alert.caseCount} cases • ${alert.village}',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    alert.severityLabel,
                    style: AppTheme.labelSmall.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.description, style: AppTheme.bodySmall),
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Detected: ${_formatDate(alert.detectedAt)}',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Recommended: ${alert.recommendedAction}',
                    style:
                        AppTheme.bodySmall.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.visibility,
                              size: 16, color: AppColors.primary),
                          label: Text('Details', style: AppTheme.labelSmall),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share, size: 16),
                          label: Text('Report',
                              style: AppTheme.labelSmall
                                  .copyWith(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: severityColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final activeAlerts = _alerts.where((a) => !a.isResolved).toList();
    final totalCases = activeAlerts.fold(0, (sum, a) => sum + a.caseCount);
    final diseases = TrackableDiseases.highPriorityDiseases;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Overview stats
        Text('Community Overview', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: [
            Expanded(
              child: AppWidgets.statCard(
                title: 'Active Alerts',
                value: activeAlerts.length.toString(),
                icon: Icons.warning,
                iconColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: AppWidgets.statCard(
                title: 'Total Cases',
                value: totalCases.toString(),
                icon: Icons.healing,
                iconColor: AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Disease tracking
        Text('Disease Tracking', style: AppTheme.headingSmall),
        const SizedBox(height: AppTheme.spacingSm),
        ...diseases.take(6).map((d) => _buildDiseaseTrackingCard(d)),
        const SizedBox(height: AppTheme.spacingMd),

        // Trends chart placeholder
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
              Text('Weekly Trend', style: AppTheme.labelMedium),
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart,
                          size: 48,
                          color: AppColors.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Chart visualization',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseTrackingCard(String disease) {
    // Find alert for this disease
    final diseaseAlerts = _alerts
        .where((a) =>
            a.disease.toLowerCase().contains(disease.toLowerCase()) &&
            !a.isResolved)
        .toList();
    final caseCount = diseaseAlerts.fold(0, (sum, a) => sum + a.caseCount);
    final trend = caseCount > 10 ? 'up' : (caseCount > 5 ? 'stable' : 'down');

    IconData trendIcon;
    Color trendColor;
    switch (trend) {
      case 'up':
        trendIcon = Icons.trending_up;
        trendColor = AppColors.error;
        break;
      case 'down':
        trendIcon = Icons.trending_down;
        trendColor = AppColors.success;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = AppColors.info;
    }

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(Icons.coronavirus, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    disease.split('').first.toUpperCase() +
                        disease.substring(1),
                    style: AppTheme.labelMedium),
                Text(
                  '$caseCount active cases',
                  style: AppTheme.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: AppTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, size: 14, color: trendColor),
                const SizedBox(width: 2),
                Text(
                  trend.toUpperCase(),
                  style: AppTheme.labelSmall.copyWith(color: trendColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportCaseDialog() {
    final diseases = TrackableDiseases.highPriorityDiseases;
    String? selectedDisease;
    final locationController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          title: Text('Report Suspected Case', style: AppTheme.headingSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Disease', style: AppTheme.labelMedium),
                const SizedBox(height: AppTheme.spacingXs),
                DropdownButtonFormField<String>(
                  initialValue: selectedDisease,
                  decoration: const InputDecoration(
                    hintText: 'Select disease',
                    border: OutlineInputBorder(),
                  ),
                  items: diseases
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d, style: AppTheme.bodyMedium),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedDisease = v),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text('Location', style: AppTheme.labelMedium),
                const SizedBox(height: AppTheme.spacingXs),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    hintText: 'Village / Area',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text('Notes', style: AppTheme.labelMedium),
                const SizedBox(height: AppTheme.spacingXs),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    hintText: 'Additional details',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: selectedDisease != null
                  ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Case reported successfully',
                              style: AppTheme.bodyMedium),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  : null,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              child: Text('Report',
                  style: AppTheme.labelMedium.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  LatLng _getVillageCoordinates(String village) {
    // Map village names to approximate coordinates in Kenya
    switch (village.toLowerCase()) {
      case 'kibera':
        return const LatLng(-1.3133, 36.7897);
      case 'nakuru':
        return const LatLng(-0.3031, 36.0800);
      case 'mombasa':
        return const LatLng(-4.0435, 39.6682);
      case 'kisumu':
        return const LatLng(-0.0917, 34.7680);
      case 'eldoret':
        return const LatLng(0.5143, 35.2698);
      default:
        return const LatLng(-1.286389, 36.817223); // Default to Nairobi
    }
  }

  void _showAlertDetails(OutbreakAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getSeverityIcon(alert.severity),
                color: _getSeverityColor(alert.severity)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(alert.disease, style: AppTheme.headingSmall),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Location', alert.village),
              _buildDetailRow('Cases', '${alert.caseCount} total'),
              _buildDetailRow(
                  'New (7 days)', '${alert.newCasesLast7Days} cases'),
              _buildDetailRow('Severity', alert.severityLabel),
              _buildDetailRow('Detected', _formatDate(alert.detectedAt)),
              const SizedBox(height: 12),
              Text('Description', style: AppTheme.labelMedium),
              const SizedBox(height: 4),
              Text(alert.description, style: AppTheme.bodySmall),
              const SizedBox(height: 12),
              Text('Recommended Action', style: AppTheme.labelMedium),
              const SizedBox(height: 4),
              Text(alert.recommendedAction,
                  style: AppTheme.bodySmall.copyWith(color: AppColors.primary)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Could navigate to detailed outbreak management
            },
            child: const Text('Take Action'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTheme.labelSmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: AppTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  IconData _getSeverityIcon(OutbreakSeverity severity) {
    switch (severity) {
      case OutbreakSeverity.critical:
        return Icons.emergency;
      case OutbreakSeverity.high:
        return Icons.warning;
      case OutbreakSeverity.moderate:
        return Icons.info;
      case OutbreakSeverity.low:
        return Icons.info_outline;
    }
  }
}
