import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/travel_api_service.dart';

/// Travel Log Screen
/// Tracks CHW movement, visit locations, and creates GPS breadcrumbs for safety
class TravelLogScreen extends StatefulWidget {
  const TravelLogScreen({super.key});

  @override
  State<TravelLogScreen> createState() => _TravelLogScreenState();
}

class _TravelLogScreenState extends State<TravelLogScreen> with SingleTickerProviderStateMixin {
  final TravelApiService _travelApi = TravelApiService.instance;
  late TabController _tabController;
  bool _isTracking = true;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _error;
  
  List<TravelEntry> _todayEntries = [];
  TravelSummary? _todaySummary;
  List<TravelEntry> _historicalEntries = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      // Load today's entries and summary
      final entriesResponse = await _travelApi.getEntries(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      final summary = await _travelApi.getSummary(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (!mounted) return;

      setState(() {
        _todayEntries = entriesResponse.data;
        _todaySummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: Column(
            children: [
              _buildHeader(l10n),
              _buildTrackingStatus(l10n),
              _buildTabBar(l10n),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorView(l10n)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildTodayTab(l10n),
                              _buildHistoryTab(l10n),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _manualCheckIn,
        backgroundColor: AppColors.primary,
        icon: const FaIcon(FontAwesomeIcons.locationDot, color: Colors.white, size: 18),
        label: Text(
          l10n.checkIn,
          style: AppTheme.labelMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorView(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.triangleExclamation, 
                color: AppColors.error, size: 48),
            SizedBox(height: AppTheme.spacingMd),
            Text(
              l10n.translate('errorLoadingData') ?? 'Error loading data',
              style: AppTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              _error ?? '',
              style: AppTheme.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const FaIcon(FontAwesomeIcons.arrowRotateRight, size: 16),
              label: Text(l10n.translate('retry') ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final summary = _todaySummary;
    
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
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
                    child: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
                  ),
                ),
                SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.travelLog,
                        style: AppTheme.headingMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.locationHistory,
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showSettings,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const FaIcon(FontAwesomeIcons.gear, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingLg),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: FontAwesomeIcons.route,
                    value: summary != null ? '${summary.totalDistance.toStringAsFixed(1)} km' : '--',
                    label: l10n.translate('distanceToday') ?? 'Today',
                  ),
                ),
                SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _buildStatCard(
                    icon: FontAwesomeIcons.house,
                    value: summary != null ? '${summary.totalTrips}' : '--',
                    label: l10n.translate('totalTrips') ?? 'Trips',
                  ),
                ),
                SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _buildStatCard(
                    icon: FontAwesomeIcons.clock,
                    value: summary != null ? '${summary.totalDuration}h' : '--',
                    label: l10n.translate('duration') ?? 'Duration',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: Colors.white, size: 18),
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
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStatus(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.all(AppTheme.spacingMd),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: _isTracking ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isTracking ? AppColors.success.withValues(alpha: 0.3) : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isTracking ? AppColors.success.withValues(alpha: 0.2) : AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
              _isTracking ? FontAwesomeIcons.locationArrow : FontAwesomeIcons.locationCrosshairs,
              color: _isTracking ? AppColors.success : AppColors.warning,
              size: 18,
            ),
          ),
          SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isTracking 
                      ? (l10n.translate('trackingActive') ?? 'Location Tracking Active')
                      : (l10n.translate('trackingPaused') ?? 'Tracking Paused'),
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  _isTracking
                      ? (l10n.translate('yourLocationBeingRecorded') ?? 'Your location is being recorded for safety')
                      : (l10n.translate('enableForSafety') ?? 'Enable for safety monitoring'),
                  style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isTracking,
            onChanged: (value) => setState(() => _isTracking = value),
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: EdgeInsets.all(AppTheme.spacingXs),
        tabs: [
          Tab(text: l10n.translate('todayRoute') ?? 'Today\'s Route'),
          Tab(text: l10n.translate('history') ?? 'History'),
        ],
      ),
    );
  }

  Widget _buildTodayTab(AppLocalizations l10n) {
    if (_todayEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.route, 
                  color: AppColors.textSecondary, size: 48),
              SizedBox(height: AppTheme.spacingMd),
              Text(
                l10n.translate('noTripsToday') ?? 'No trips recorded today',
                style: AppTheme.bodyLarge,
              ),
              SizedBox(height: AppTheme.spacingSm),
              Text(
                l10n.translate('startLoggingTrips') ?? 'Start logging your trips',
                style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      itemCount: _todayEntries.length,
      itemBuilder: (context, index) {
        final entry = _todayEntries[index];
        final isLast = index == _todayEntries.length - 1;
        final isFirst = index == 0;
        
        return _buildTimelineEntry(entry, isFirst, isLast, l10n);
      },
    );
  }

  Widget _buildTimelineEntry(TravelEntry entry, bool isFirst, bool isLast, AppLocalizations l10n) {
    final typeColor = _getTypeColor(entry.type);
    final typeIcon = _getTypeIcon(entry.type);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 20,
                    color: AppColors.divider,
                  ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: typeColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: FaIcon(
                      typeIcon,
                      color: typeColor,
                      size: 12,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacingSm),
          
          // Content card
          Expanded(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.destination ?? 'Unknown destination',
                          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: AppTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTypeLabel(entry.type),
                          style: AppTheme.labelSmall.copyWith(color: typeColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingSm),
                  
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.clock, color: AppColors.textSecondary, size: 12),
                      SizedBox(width: AppTheme.spacingXs),
                      Text(
                        _formatTime(entry.startTime),
                        style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      if (entry.endTime != null) ...[
                        Text(
                          ' - ${_formatTime(entry.endTime!)}',
                          style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    SizedBox(height: AppTheme.spacingSm),
                    Text(
                      entry.notes!,
                      style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  if (entry.distance != null) ...[
                    SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.route, color: AppColors.textSecondary, size: 10),
                        SizedBox(width: AppTheme.spacingXs),
                        Text(
                          '${entry.distance!.toStringAsFixed(1)} km',
                          style: AppTheme.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(AppLocalizations l10n) {
    return Column(
      children: [
        // Date selector
        Container(
          padding: EdgeInsets.all(AppTheme.spacingMd),
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
          child: Row(
            children: [
              FaIcon(FontAwesomeIcons.calendar, color: AppColors.primary, size: 18),
              SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    _loadHistoricalData();
                  }
                },
                icon: FaIcon(FontAwesomeIcons.chevronDown, size: 14),
                label: Text(l10n.translate('changeDate') ?? 'Change'),
              ),
            ],
          ),
        ),
        // Historical entries list
        Expanded(
          child: _historicalEntries.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.clockRotateLeft, 
                            color: AppColors.textSecondary, size: 48),
                        SizedBox(height: AppTheme.spacingMd),
                        Text(
                          l10n.translate('noTripsOnDate') ?? 'No trips on this date',
                          style: AppTheme.bodyLarge,
                        ),
                        SizedBox(height: AppTheme.spacingSm),
                        Text(
                          l10n.translate('selectDifferentDate') ?? 'Try selecting a different date',
                          style: AppTheme.bodySmall.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: _historicalEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _historicalEntries[index];
                    final isLast = index == _historicalEntries.length - 1;
                    final isFirst = index == 0;
                    return _buildTimelineEntry(entry, isFirst, isLast, l10n);
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _loadHistoricalData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
      
      final entriesResponse = await _travelApi.getEntries(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (!mounted) return;

      setState(() {
        _historicalEntries = entriesResponse.data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getTypeColor(TravelType type) {
    switch (type) {
      case TravelType.homeVisit:
        return AppColors.primary;
      case TravelType.outreach:
        return AppColors.secondary;
      case TravelType.training:
        return AppColors.info;
      case TravelType.referral:
        return AppColors.warning;
      case TravelType.supply:
        return AppColors.success;
      case TravelType.meeting:
        return AppColors.primaryLight;
      case TravelType.other:
        return AppColors.textSecondary;
    }
  }

  IconData _getTypeIcon(TravelType type) {
    switch (type) {
      case TravelType.homeVisit:
        return FontAwesomeIcons.houseMedical;
      case TravelType.outreach:
        return FontAwesomeIcons.peopleGroup;
      case TravelType.training:
        return FontAwesomeIcons.graduationCap;
      case TravelType.referral:
        return FontAwesomeIcons.hospital;
      case TravelType.supply:
        return FontAwesomeIcons.boxesPacking;
      case TravelType.meeting:
        return FontAwesomeIcons.users;
      case TravelType.other:
        return FontAwesomeIcons.ellipsis;
    }
  }

  String _getTypeLabel(TravelType type) {
    switch (type) {
      case TravelType.homeVisit:
        return 'Home Visit';
      case TravelType.outreach:
        return 'Outreach';
      case TravelType.training:
        return 'Training';
      case TravelType.referral:
        return 'Referral';
      case TravelType.supply:
        return 'Supply';
      case TravelType.meeting:
        return 'Meeting';
      case TravelType.other:
        return 'Other';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _manualCheckIn() async {
    final l10n = AppLocalizations.of(context);
    final TextEditingController destinationController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    TravelType selectedType = TravelType.homeVisit;

    final result = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: AppTheme.spacingLg,
          right: AppTheme.spacingLg,
          top: AppTheme.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppTheme.spacingLg),
            Text(
              l10n.translate('logNewTrip') ?? 'Log New Trip',
              style: AppTheme.headingMedium,
            ),
            SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: destinationController,
              decoration: InputDecoration(
                labelText: l10n.translate('destination') ?? 'Destination',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingMd),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: l10n.translate('notes') ?? 'Notes (optional)',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
            SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const FaIcon(FontAwesomeIcons.locationDot, size: 16, color: Colors.white),
                label: Text(l10n.translate('logTrip') ?? 'Log Trip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );

    if (result == true && destinationController.text.isNotEmpty) {
      try {
        await _travelApi.startEntry(
          destination: destinationController.text,
          type: selectedType,
          notes: notesController.text.isEmpty ? null : notesController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('tripLogged') ?? 'Trip logged successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tracking settings'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
