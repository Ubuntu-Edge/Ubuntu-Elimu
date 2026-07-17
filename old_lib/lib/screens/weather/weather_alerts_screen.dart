import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/alerts_api_service.dart';
import '../../services/auth_service.dart';
import 'alert_detail_screen.dart';

/// Weather and Environmental Alerts Screen
/// Displays severe weather warnings, disease outbreaks, and local hazards
class WeatherAlertsScreen extends StatefulWidget {
  const WeatherAlertsScreen({super.key});

  @override
  State<WeatherAlertsScreen> createState() => _WeatherAlertsScreenState();
}

class _WeatherAlertsScreenState extends State<WeatherAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AlertsApiService _alertsApi = AlertsApiService.instance;

  // API data for alerts
  List<Alert> _weatherAlerts = [];
  List<Alert> _diseaseAlerts = [];
  List<Alert> _hazardAlerts = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all alert types in parallel
      final results = await Future.wait([
        _alertsApi.getWeatherAlerts(perPage: 50),
        _alertsApi.getDiseaseAlerts(perPage: 50),
        _alertsApi.getHazardAlerts(perPage: 50),
      ]);

      setState(() {
        _weatherAlerts = results[0].data;
        _diseaseAlerts = results[1].data;
        _hazardAlerts = results[2].data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load alerts: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('Error loading alerts: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.triangleExclamation,
                            color: AppColors.error, size: 48),
                        SizedBox(height: AppTheme.spacingMd),
                        Text(_error!,
                            style: AppTheme.bodyMedium,
                            textAlign: TextAlign.center),
                        SizedBox(height: AppTheme.spacingMd),
                        ElevatedButton.icon(
                          onPressed: _loadAlerts,
                          icon: FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
                          label: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _buildHeader(l10n),
                      _buildTabBar(l10n),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAlertsList(_weatherAlerts, l10n),
                            _buildAlertsList(_diseaseAlerts, l10n),
                            _buildAlertsList(_hazardAlerts, l10n),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _canManageAlerts(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return FloatingActionButton.extended(
              onPressed: () => _showCreateAlertDialog(l10n),
              icon: FaIcon(FontAwesomeIcons.plus, size: 16),
              label: Text('Create Alert'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

  /// Check if current user can manage alerts (admin/supervisor only)
  Future<bool> _canManageAlerts() async {
    final chw = await AuthService.instance.getCurrentCHW();
    return chw != null && (chw.role == 'admin' || chw.role == 'supervisor');
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final activeAlerts =
        _weatherAlerts.length + _diseaseAlerts.length + _hazardAlerts.length;
    final criticalCount = [
      ..._weatherAlerts,
      ..._diseaseAlerts,
      ..._hazardAlerts
    ].where((a) => a.severityEnum == AlertSeverity.critical).length;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)],
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
                        l10n.weatherAlerts,
                        style: AppTheme.headingMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.environmentalAlerts,
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
                  child: const FaIcon(FontAwesomeIcons.bell,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingLg),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    icon: FontAwesomeIcons.triangleExclamation,
                    value: '$activeAlerts',
                    label: l10n.translate('activeAlerts') ?? 'Active Alerts',
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: _buildSummaryCard(
                    icon: FontAwesomeIcons.circleExclamation,
                    value: '$criticalCount',
                    label: l10n.translate('criticalAlerts') ?? 'Critical',
                    color: Colors.red.shade100,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: color, size: 24),
          SizedBox(width: AppTheme.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTheme.headingMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
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
                FaIcon(FontAwesomeIcons.cloudBolt, size: 14),
                SizedBox(width: AppTheme.spacingXs),
                Flexible(
                    child: Text(l10n.severeWeather,
                        style: AppTheme.labelSmall,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.virus, size: 14),
                SizedBox(width: AppTheme.spacingXs),
                Flexible(
                    child: Text(l10n.diseaseOutbreak,
                        style: AppTheme.labelSmall,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.roadBarrier, size: 14),
                SizedBox(width: AppTheme.spacingXs),
                Flexible(
                    child: Text(l10n.localHazards,
                        style: AppTheme.labelSmall,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(List<Alert> alerts, AppLocalizations l10n) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.circleCheck,
                color: AppColors.success, size: 48),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              l10n.translate('noActiveAlerts') ?? 'No active alerts',
              style:
                  AppTheme.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        itemCount: alerts.length,
        itemBuilder: (context, index) => _buildAlertCard(alerts[index], l10n),
      ),
    );
  }

  Widget _buildAlertCard(Alert alert, AppLocalizations l10n) {
    final severityColor = _getSeverityColor(alert.severityEnum);
    final typeIcon = _getTypeIcon(alert.type);

    return InkWell(
      onTap: () async {
        // Navigate to alert detail screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlertDetailScreen(alertId: alert.id),
          ),
        );

        // Reload alerts if the detail screen returned true (indicating changes)
        if (result == true) {
          _loadAlerts();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: severityColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: severityColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with severity indicator
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FaIcon(typeIcon, color: severityColor, size: 18),
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: AppTheme.bodyMedium
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getSeverityLabel(alert.severityEnum),
                          style: AppTheme.labelSmall
                              .copyWith(color: severityColor),
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
                      color: severityColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getSeverityLabel(alert.severityEnum).toUpperCase(),
                      style: AppTheme.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.description,
                    style: AppTheme.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: AppTheme.spacingMd),

                  // Case counts for disease alerts
                  if (alert.type == AlertType.disease &&
                      alert.caseCount != null) ...[
                    Row(
                      children: [
                        _buildCountChip(
                          icon: FontAwesomeIcons.userInjured,
                          count: alert.caseCount!,
                          label: l10n.translate('cases') ?? 'Cases',
                          color: AppColors.warning,
                        ),
                        SizedBox(width: AppTheme.spacingSm),
                        if (alert.deathCount != null)
                          _buildCountChip(
                            icon: FontAwesomeIcons.skullCrossbones,
                            count: alert.deathCount!,
                            label: l10n.translate('deaths') ?? 'Deaths',
                            color: AppColors.error,
                          ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                  ],

                  // Affected areas
                  Text(
                    l10n.translate('affectedAreas') ?? 'Affected Areas',
                    style: AppTheme.labelMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppTheme.spacingXs),
                  Wrap(
                    spacing: AppTheme.spacingXs,
                    runSpacing: AppTheme.spacingXs,
                    children: alert.affectedAreas
                        .map((area) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingSm,
                                vertical: AppTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                area,
                                style: AppTheme.labelSmall
                                    .copyWith(color: AppColors.info),
                              ),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: AppTheme.spacingMd),

                  // Recommendations
                  Text(
                    l10n.translate('recommendations') ?? 'Recommendations',
                    style: AppTheme.labelMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppTheme.spacingXs),
                  ...alert.recommendations.map((rec) => Padding(
                        padding: EdgeInsets.only(bottom: AppTheme.spacingXs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FaIcon(FontAwesomeIcons.circleCheck,
                                color: AppColors.success, size: 12),
                            SizedBox(width: AppTheme.spacingSm),
                            Expanded(
                              child: Text(
                                rec,
                                style: AppTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      )),

                  SizedBox(height: AppTheme.spacingMd),

                  // Time info
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.clock,
                          color: AppColors.textSecondary, size: 12),
                      SizedBox(width: AppTheme.spacingXs),
                      Text(
                        '${l10n.translate('started') ?? 'Started'}: ${_formatDate(alert.startTime)}',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      if (alert.endTime != null) ...[
                        Text(
                          ' • ${l10n.translate('expires') ?? 'Expires'}: ${_formatDate(alert.endTime!)}',
                          style: AppTheme.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareAlert(alert),
                      icon: FaIcon(FontAwesomeIcons.share, size: 14),
                      label: Text(l10n.translate('share') ?? 'Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acknowledgeAlert(alert),
                      icon: FaIcon(FontAwesomeIcons.check,
                          size: 14, color: Colors.white),
                      label:
                          Text(l10n.translate('acknowledge') ?? 'Acknowledge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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

  Widget _buildCountChip({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: color, size: 12),
          SizedBox(width: AppTheme.spacingXs),
          Text(
            '$count $label',
            style: AppTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
      case AlertSeverity.info:
        return AppColors.info;
      case AlertSeverity.medium:
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.high:
      case AlertSeverity.severe:
        return Colors.orange;
      case AlertSeverity.critical:
        return AppColors.error;
    }
  }

  String _getSeverityLabel(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.medium:
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.high:
      case AlertSeverity.severe:
        return 'Severe';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  IconData _getTypeIcon(AlertType type) {
    switch (type) {
      case AlertType.weather:
        return FontAwesomeIcons.cloudBolt;
      case AlertType.disease:
        return FontAwesomeIcons.virus;
      case AlertType.hazard:
        return FontAwesomeIcons.roadBarrier;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _shareAlert(Alert alert) {
    // Create formatted alert message
    final message = '''
🚨 ${alert.title}

${alert.description}

📍 Area: ${alert.area}, ${alert.region}
⚠️ Severity: ${alert.severity.toUpperCase()}
🕐 Start: ${_formatDate(alert.startTime)}
${alert.endTime != null ? '⏰ End: ${_formatDate(alert.endTime!)}' : ''}

${alert.actionRequired != null ? '✅ Action Required:\n${alert.actionRequired}' : ''}

${alert.source != null ? '📢 Source: ${alert.source}' : ''}
''';

    Share.share(
      message,
      subject: '🚨 Alert: ${alert.title}',
    );
  }

  Future<void> _acknowledgeAlert(Alert alert) async {
    try {
      await _alertsApi.acknowledgeAlert(alert.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert acknowledged'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
      // Reload alerts to reflect acknowledgement
      _loadAlerts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to acknowledge alert'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Show create alert dialog (admin/supervisor only)
  void _showCreateAlertDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => _CreateAlertDialog(
        onCreated: () {
          _loadAlerts(); // Reload alerts after creation
        },
      ),
    );
  }
}

/// Create Alert Dialog Widget
class _CreateAlertDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const _CreateAlertDialog({required this.onCreated});

  @override
  State<_CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<_CreateAlertDialog> {
  final _formKey = GlobalKey<FormState>();
  final AlertsApiService _alertsApi = AlertsApiService.instance;

  // Form fields
  String _alertType = 'weather';
  String _severity = 'info';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _areaController = TextEditingController();
  final _regionController = TextEditingController();
  final _actionController = TextEditingController();
  final _sourceController = TextEditingController();
  final DateTime _startTime = DateTime.now();
  DateTime? _endTime;
  bool _isActive = true;
  bool _isBroadcast = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _regionController.dispose();
    _actionController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        constraints: BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.triangleExclamation,
                      color: AppColors.warning),
                  SizedBox(width: AppTheme.spacingSm),
                  Text('Create New Alert', style: AppTheme.headingMedium),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: FaIcon(FontAwesomeIcons.xmark, size: 16),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingMd),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Alert Type
                      DropdownButtonFormField<String>(
                        initialValue: _alertType,
                        decoration: InputDecoration(labelText: 'Alert Type'),
                        items: [
                          DropdownMenuItem(
                              value: 'weather', child: Text('Weather')),
                          DropdownMenuItem(
                              value: 'disease', child: Text('Disease')),
                          DropdownMenuItem(
                              value: 'hazard', child: Text('Hazard')),
                        ],
                        onChanged: (value) =>
                            setState(() => _alertType = value!),
                      ),
                      SizedBox(height: AppTheme.spacingMd),

                      // Severity
                      DropdownButtonFormField<String>(
                        initialValue: _severity,
                        decoration: InputDecoration(labelText: 'Severity'),
                        items: [
                          DropdownMenuItem(value: 'info', child: Text('Info')),
                          DropdownMenuItem(
                              value: 'warning', child: Text('Warning')),
                          DropdownMenuItem(
                              value: 'severe', child: Text('Severe')),
                          DropdownMenuItem(
                              value: 'critical', child: Text('Critical')),
                        ],
                        onChanged: (value) =>
                            setState(() => _severity = value!),
                      ),
                      SizedBox(height: AppTheme.spacingMd),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(labelText: 'Title *'),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      SizedBox(height: AppTheme.spacingMd),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(labelText: 'Description *'),
                        maxLines: 3,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      SizedBox(height: AppTheme.spacingMd),

                      // Area & Region
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _areaController,
                              decoration: InputDecoration(labelText: 'Area'),
                            ),
                          ),
                          SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: TextFormField(
                              controller: _regionController,
                              decoration: InputDecoration(labelText: 'Region'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingMd),

                      // Action Required
                      TextFormField(
                        controller: _actionController,
                        decoration:
                            InputDecoration(labelText: 'Action Required'),
                        maxLines: 2,
                      ),
                      SizedBox(height: AppTheme.spacingMd),

                      // Source
                      TextFormField(
                        controller: _sourceController,
                        decoration: InputDecoration(labelText: 'Source'),
                      ),
                      SizedBox(height: AppTheme.spacingMd),

                      // Switches
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: Text('Active', style: AppTheme.bodySmall),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title:
                                  Text('Broadcast', style: AppTheme.bodySmall),
                              value: _isBroadcast,
                              onChanged: (v) =>
                                  setState(() => _isBroadcast = v),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spacingMd),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.all(AppTheme.spacingMd),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Create Alert'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _alertsApi.createAlert(
        alertType: _alertType,
        severity: _severity,
        title: _titleController.text,
        description: _descriptionController.text,
        area: _areaController.text.isEmpty ? 'General' : _areaController.text,
        region:
            _regionController.text.isEmpty ? 'General' : _regionController.text,
        startTime: _startTime,
        endTime: _endTime,
        isActive: _isActive,
        isBroadcast: _isBroadcast,
        actionRequired:
            _actionController.text.isEmpty ? null : _actionController.text,
        source: _sourceController.text.isEmpty ? null : _sourceController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create alert: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
