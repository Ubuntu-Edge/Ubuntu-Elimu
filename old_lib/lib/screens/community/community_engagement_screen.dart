import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/engagement_api_service.dart';
import '../../models/engagement_models.dart';

class CommunityEngagementScreen extends StatefulWidget {
  const CommunityEngagementScreen({super.key});

  @override
  State<CommunityEngagementScreen> createState() =>
      _CommunityEngagementScreenState();
}

class _CommunityEngagementScreenState extends State<CommunityEngagementScreen>
    with SingleTickerProviderStateMixin {
  final EngagementApiService _engagementApi = EngagementApiService.instance;
  late TabController _tabController;
  List<CommunityEvent> _events = [];
  List<Campaign> _campaigns = [];
  bool _isLoading = true;
  String? _error;

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
      // Load events and campaigns in parallel
      final results = await Future.wait([
        _engagementApi.getEvents(perPage: 100),
        _engagementApi.getCampaigns(perPage: 100),
      ]);

      final eventsResponse = results[0] as EventListResponse;
      final campaignsResponse = results[1] as CampaignListResponse;

      setState(() {
        _events = eventsResponse.data;
        _campaigns = campaignsResponse.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCreateEventDialog() {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    String selectedType = EventType.healthTalk;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
              l10n.translate('createCommunityEvent') ??
                  'Create Community Event',
              style: AppTheme.headingMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('eventTitle') ?? 'Event Title',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: l10n.translate('eventType') ?? 'Event Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: EventType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(EventType.displayName(t)),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedType = value!),
                ),
                SizedBox(height: AppTheme.spacingMd),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.translate('description') ?? 'Description',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('location') ?? 'Location',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: AppTheme.spacingMd),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.translate('dateTime') ?? 'Date & Time'),
                  subtitle: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
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
                if (titleController.text.isNotEmpty &&
                    locationController.text.isNotEmpty) {
                  try {
                    final request = EventRequest(
                      title: titleController.text,
                      eventType: selectedType,
                      eventDate: selectedDate,
                      description: descriptionController.text.isNotEmpty
                          ? descriptionController.text
                          : null,
                      location: locationController.text,
                      expectedParticipants: 50,
                      status: EventStatus.planned,
                    );
                    await _engagementApi.createEvent(request);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              l10n.translate('eventCreatedSuccessfully') ??
                                  'Event created successfully'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      _loadData(); // Refresh data
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create event: $e'),
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
              child: Text(l10n.translate('create') ?? 'Create',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(CommunityEvent event) {
    final l10n = AppLocalizations.of(context);
    final isUpcoming = event.isPlanned;
    final isCompleted = event.isCompleted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                  // Event Type Badge
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.eventTypeDisplay,
                          style: AppTheme.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.statusDisplay.toUpperCase(),
                          style: AppTheme.labelSmall.copyWith(
                            color: isCompleted
                                ? AppColors.success
                                : AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingMd),

                  // Title
                  Text(event.title, style: AppTheme.headingLarge),
                  SizedBox(height: AppTheme.spacingSm),
                  Text(event.description ?? '',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),

                  SizedBox(height: AppTheme.spacingLg),

                  // Details
                  _buildDetailRow(
                      FontAwesomeIcons.calendar,
                      l10n.translate('date') ?? 'Date',
                      '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}'),
                  if (event.location != null)
                    _buildDetailRow(
                        FontAwesomeIcons.locationDot,
                        l10n.translate('location') ?? 'Location',
                        event.location!),
                  _buildDetailRow(
                      FontAwesomeIcons.user,
                      l10n.translate('organizer') ?? 'Organizer',
                      event.organizedBy),

                  SizedBox(height: AppTheme.spacingLg),

                  // Attendance Stats
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.translate('attendance') ?? 'Attendance',
                            style: AppTheme.labelLarge),
                        SizedBox(height: AppTheme.spacingMd),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text('${event.actualAttendees ?? 0}',
                                      style: AppTheme.headingLarge
                                          .copyWith(color: AppColors.primary)),
                                  Text(
                                      l10n.translate('confirmed') ??
                                          'Confirmed',
                                      style: AppTheme.labelSmall.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                                width: 1, height: 40, color: Colors.grey[300]),
                            Expanded(
                              child: Column(
                                children: [
                                  Text('${event.targetAttendees ?? 0}',
                                      style: AppTheme.headingLarge.copyWith(
                                          color: AppColors.textSecondary)),
                                  Text(l10n.translate('expected') ?? 'Expected',
                                      style: AppTheme.labelSmall.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMd),
                        LinearProgressIndicator(
                          value: event.attendanceRate,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppTheme.spacingLg),

                  if (isUpcoming)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        l10n.translate('sharingEvent') ??
                                            'Sharing event...'),
                                    behavior: SnackBarBehavior.floating),
                              );
                            },
                            icon: FaIcon(FontAwesomeIcons.share, size: 16),
                            label: Text(l10n.translate('share') ?? 'Share'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              // Update event to ongoing
                              try {
                                final request = EventRequest(
                                  title: event.title,
                                  eventType: event.eventType,
                                  eventDate: event.eventDate,
                                  status: EventStatus.ongoing,
                                );
                                await _engagementApi.updateEvent(
                                    event.id, request);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          l10n.translate('eventStarted') ??
                                              'Event started!'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  _loadData(); // Refresh data
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const FaIcon(FontAwesomeIcons.userCheck,
                                size: 16, color: Colors.white),
                            label: Text(
                                l10n.translate('recordAttendance') ??
                                    'Record Attendance',
                                style: const TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, color: AppColors.primary, size: 14),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTheme.labelSmall
                      .copyWith(color: AppColors.textSecondary)),
              Text(value,
                  style: AppTheme.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventDialog,
        backgroundColor: AppColors.primary,
        icon: FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 18),
        label: Text(l10n.translate('newEvent') ?? 'New Event',
            style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildTabBar(l10n),
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
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildEventsTab(l10n),
                            _buildCampaignsTab(l10n),
                            _buildResourcesTab(l10n),
                          ],
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
          colors: [AppColors.secondary, AppColors.secondary.withGreen(180)],
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
                    l10n.community,
                    style: AppTheme.headingMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l10n.translate('eventsOutreach') ?? 'Events & Outreach',
                    style: AppTheme.bodySmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(FontAwesomeIcons.magnifyingGlass,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: l10n.translate('events') ?? 'Events'),
          Tab(text: l10n.translate('campaigns') ?? 'Campaigns'),
          Tab(text: l10n.translate('resources') ?? 'Resources'),
        ],
      ),
    );
  }

  Widget _buildEventsTab(AppLocalizations l10n) {
    final upcomingEvents =
        _events.where((e) => e.isPlanned || e.isOngoing).toList();
    final pastEvents =
        _events.where((e) => e.isCompleted || e.isCancelled).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          if (upcomingEvents.isNotEmpty) ...[
            Text(l10n.translate('upcomingEvents') ?? 'Upcoming Events',
                style: AppTheme.labelLarge),
            SizedBox(height: AppTheme.spacingSm),
            ...upcomingEvents.map((event) => _buildEventCard(event, l10n)),
          ],
          SizedBox(height: AppTheme.spacingLg),
          if (pastEvents.isNotEmpty) ...[
            Text(l10n.translate('pastEvents') ?? 'Past Events',
                style: AppTheme.labelLarge),
            SizedBox(height: AppTheme.spacingSm),
            ...pastEvents.map((event) => _buildEventCard(event, l10n)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEventCard(CommunityEvent event, AppLocalizations l10n) {
    final isUpcoming = event.isPlanned || event.isOngoing;

    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
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
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _getEventColor(event.eventType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(_getEventIcon(event.eventType),
                  color: _getEventColor(event.eventType), size: 20),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: AppTheme.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isUpcoming
                              ? AppColors.info.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.statusDisplay.toUpperCase(),
                          style: AppTheme.labelSmall.copyWith(
                            color:
                                isUpcoming ? AppColors.info : AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.calendar,
                          color: AppColors.textSecondary, size: 11),
                      SizedBox(width: 4),
                      Text(
                        '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                        style: AppTheme.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      if (event.location != null) ...[
                        SizedBox(width: 12),
                        FaIcon(FontAwesomeIcons.locationDot,
                            color: AppColors.textSecondary, size: 11),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: AppTheme.labelSmall
                                .copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.users,
                          color: AppColors.primary, size: 12),
                      SizedBox(width: 6),
                      Text(
                        '${event.actualAttendees ?? 0}/${event.targetAttendees ?? 0} ${l10n.translate('confirmed') ?? 'confirmed'}',
                        style: AppTheme.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignsTab(AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        children: [
          ..._campaigns.map((campaign) => _buildCampaignCard(campaign, l10n)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign, AppLocalizations l10n) {
    final progress = campaign.progressRate;
    final isActive = campaign.isActive;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3), width: 2)
            : null,
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
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(FontAwesomeIcons.bullhorn,
                    color: AppColors.primary, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign.name,
                        style: AppTheme.labelLarge
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      '${campaign.startDate.day}/${campaign.startDate.month} - ${campaign.endDate?.day ?? '--'}/${campaign.endDate?.month ?? '--'}',
                      style: AppTheme.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  campaign.statusDisplay.toUpperCase(),
                  style: AppTheme.labelSmall.copyWith(
                    color: isActive ? AppColors.success : AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  campaign.campaignTypeDisplay,
                  style: AppTheme.labelSmall.copyWith(
                      color: AppColors.secondary, fontWeight: FontWeight.w500),
                ),
              ),
              if (campaign.targetArea != null) ...[
                SizedBox(width: 8),
                FaIcon(FontAwesomeIcons.locationDot,
                    color: AppColors.textSecondary, size: 12),
                SizedBox(width: 4),
                Text(
                  campaign.targetArea!,
                  style: AppTheme.labelSmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          if (campaign.description != null) ...[
            SizedBox(height: AppTheme.spacingSm),
            Text(campaign.description!,
                style: AppTheme.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
          SizedBox(height: AppTheme.spacingMd),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.translate('progress') ?? 'Progress',
                  style: AppTheme.labelSmall
                      .copyWith(color: AppColors.textSecondary)),
              Text(
                '${campaign.reachedCount}/${campaign.targetCount} ${l10n.translate('reached') ?? 'reached'}',
                style: AppTheme.labelSmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
            borderRadius: BorderRadius.circular(10),
          ),

          if (isActive) ...[
            SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: FaIcon(FontAwesomeIcons.fileLines, size: 14),
                    label:
                        Text(l10n.translate('viewDetails') ?? 'View Details'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Show dialog to enter number of people reached
                      final controller = TextEditingController();
                      final result = await showDialog<int>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(l10n.translate('logCampaignActivity') ??
                              'Log Campaign Activity'),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.translate('peopleReached') ??
                                  'People Reached',
                              hintText: '0',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () {
                                final count =
                                    int.tryParse(controller.text) ?? 0;
                                Navigator.pop(dialogContext, count);
                              },
                              child: Text(l10n.translate('save') ?? 'Save'),
                            ),
                          ],
                        ),
                      );

                      if (result != null && result > 0) {
                        try {
                          final newCount = campaign.reachedCount + result;
                          final request = CampaignRequest(
                            name: campaign.name,
                            campaignType: campaign.campaignType,
                            startDate: campaign.startDate,
                            reachedCount: newCount,
                          );
                          await _engagementApi.updateCampaign(
                              campaign.id, request);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    l10n.translate('progressUpdated') ??
                                        'Progress updated successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            _loadData(); // Refresh data
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update progress: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const FaIcon(FontAwesomeIcons.plus,
                        size: 14, color: Colors.white),
                    label: Text(l10n.translate('logActivity') ?? 'Log Activity',
                        style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourcesTab(AppLocalizations l10n) {
    return ListView(
      padding: EdgeInsets.all(AppTheme.spacingMd),
      children: [
        _buildResourceItem(
          icon: FontAwesomeIcons.fileLines,
          title:
              l10n.translate('healthTalkTemplates') ?? 'Health Talk Templates',
          subtitle:
              '12 ${l10n.translate('templatesAvailable') ?? 'templates available'}',
          color: AppColors.primary,
        ),
        _buildResourceItem(
          icon: FontAwesomeIcons.images,
          title: l10n.translate('iecMaterials') ?? 'IEC Materials',
          subtitle: l10n.translate('iecDescription') ??
              'Posters, brochures, infographics',
          color: AppColors.secondary,
        ),
        _buildResourceItem(
          icon: FontAwesomeIcons.video,
          title: l10n.translate('trainingVideos') ?? 'Training Videos',
          subtitle:
              '8 ${l10n.translate('videosAvailable') ?? 'community health videos'}',
          color: AppColors.info,
        ),
        _buildResourceItem(
          icon: FontAwesomeIcons.clipboardCheck,
          title: l10n.translate('attendanceForms') ?? 'Attendance Forms',
          subtitle: l10n.translate('digitalAttendanceTracking') ??
              'Digital attendance tracking',
          color: AppColors.success,
        ),
        _buildResourceItem(
          icon: FontAwesomeIcons.chartBar,
          title: l10n.translate('impactReports') ?? 'Impact Reports',
          subtitle: l10n.translate('generateEventReports') ??
              'Generate event reports',
          color: AppColors.warning,
        ),
        SizedBox(height: 80),
      ],
    );
  }

  Widget _buildResourceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
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
      child: ListTile(
        contentPadding: EdgeInsets.all(AppTheme.spacingMd),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style:
                AppTheme.labelSmall.copyWith(color: AppColors.textSecondary)),
        trailing: FaIcon(FontAwesomeIcons.chevronRight,
            color: AppColors.textSecondary, size: 14),
      ),
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case EventType.healthTalk:
        return AppColors.primary;
      case EventType.vaccination:
        return AppColors.success;
      case EventType.training:
        return AppColors.info;
      case EventType.screening:
        return AppColors.warning;
      case EventType.awareness:
        return AppColors.secondary;
      case EventType.outreach:
        return AppColors.primary;
      case EventType.meeting:
        return AppColors.info;
      default:
        return AppColors.secondary;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case EventType.healthTalk:
        return FontAwesomeIcons.personChalkboard;
      case EventType.vaccination:
        return FontAwesomeIcons.syringe;
      case EventType.training:
        return FontAwesomeIcons.users;
      case EventType.screening:
        return FontAwesomeIcons.stethoscope;
      case EventType.awareness:
        return FontAwesomeIcons.bullhorn;
      case EventType.outreach:
        return FontAwesomeIcons.handsHoldingCircle;
      case EventType.meeting:
        return FontAwesomeIcons.peopleGroup;
      default:
        return FontAwesomeIcons.calendarDay;
    }
  }
}
