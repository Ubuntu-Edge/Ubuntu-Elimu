import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../models/visit.dart';
// Providers
import 'package:chw_augment/providers/auth_provider.dart';
import 'package:chw_augment/providers/followup_provider.dart';
import 'package:chw_augment/providers/patient_provider.dart'; // Import PatientProvider
// Widgets
import 'package:chw_augment/widgets/followup_card.dart';
// Screens
import 'package:chw_augment/screens/patients/patient_detail_screen.dart';
import 'package:chw_augment/followups/complete_followup_screen.dart';
import 'package:chw_augment/models/patient.dart'; // Import Patient model

class FollowupDashboardScreen extends StatefulWidget {
  const FollowupDashboardScreen({super.key});

  @override
  State<FollowupDashboardScreen> createState() => _FollowupDashboardScreenState();
}

class _FollowupDashboardScreenState extends State<FollowupDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color primaryColor = const Color(0xFF00897B); // Teal
  final Color secondaryColor = const Color(0xFF26A69A); // Lighter Teal

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final followupProvider = Provider.of<FollowupProvider>(context, listen: false);

    final chw = authProvider.currentCHW;
    if (chw == null) return;

    await Future.wait([
      followupProvider.loadReminders(chw.id),
      followupProvider.loadScheduledVisits(chw.id),
      followupProvider.loadVisitsFromApi(), // Load visits from API
    ]);

    if (mounted) setState(() {});
  }

  Future<void> _showRescheduleDialog(String reminderId) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026, 12, 31),
    );

    if (!mounted || selectedDate == null) return;

    final followupProvider = Provider.of<FollowupProvider>(context, listen: false);
    final success = await followupProvider.rescheduleReminder(reminderId, selectedDate);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Follow-up rescheduled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData();
    }
  }

  Future<void> _showSnoozeDialog(String reminderId) async {
    final snoozeDuration = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How long would you like to snooze this reminder?'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: const Text('15 minutes'),
              onTap: () => Navigator.pop(context, 15),
            ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: const Text('30 minutes'),
              onTap: () => Navigator.pop(context, 30),
            ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: const Text('1 hour'),
              onTap: () => Navigator.pop(context, 60),
            ),
            ListTile(
              leading: const Icon(Icons.snooze),
              title: const Text('2 hours'),
              onTap: () => Navigator.pop(context, 120),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Tomorrow 9 AM'),
              onTap: () => Navigator.pop(context, -1), // Special value for tomorrow
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (!mounted || snoozeDuration == null) return;

    final followupProvider = Provider.of<FollowupProvider>(context, listen: false);
    
    // Calculate snooze until time
    DateTime snoozeUntil;
    if (snoozeDuration == -1) {
      // Tomorrow at 9 AM
      snoozeUntil = DateTime.now().add(const Duration(days: 1));
      snoozeUntil = DateTime(snoozeUntil.year, snoozeUntil.month, snoozeUntil.day, 9, 0);
    } else {
      snoozeUntil = DateTime.now().add(Duration(minutes: snoozeDuration));
    }
    
    final success = await followupProvider.snoozeReminder(reminderId, snoozeUntil);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder snoozed until ${DateFormat('MMM dd, h:mm a').format(snoozeUntil)}'),
          backgroundColor: Colors.orange,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to snooze reminder: ${followupProvider.errorMessage ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeReminder(String reminderId, String patientId) async {
    final outcome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was this reminder completed?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Outcome Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter any notes about completion',
              ),
              maxLines: 3,
              onChanged: (value) {
                // Store value for later
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'completed'),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );

    if (!mounted || outcome == null) return;

    final followupProvider = Provider.of<FollowupProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chwId = authProvider.currentCHW?.id ?? '';
    
    final success = await followupProvider.completeReminder(
      reminderId, 
      'completed',
      chwId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder marked as complete!'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete reminder: ${followupProvider.errorMessage ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // TODO: May be needed later
  // New method to uncomplete a scheduled visit
  /* Future<void> _uncompleteVisit(ScheduledVisit visit) async {
    if (!mounted) return;

    final followupProvider = Provider.of<FollowupProvider>(context, listen: false);

    try {
      final success = await followupProvider.uncompleteScheduledVisit(visit.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit marked as incomplete!'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadData(); // Refresh data to update UI
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark visit as incomplete: ${followupProvider.errorMessage ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking visit as incomplete: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final followupProvider = Provider.of<FollowupProvider>(context);
    final patientProvider = Provider.of<PatientProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chwId = authProvider.currentCHW?.id ?? 'default_chw_id';
    final chwName = authProvider.currentCHW?.fullName ?? 'User';
    final stats = followupProvider.statistics;
    final currentTime = DateTime.now();
    final welcomeMessage = currentTime.hour < 12
        ? 'Good morning'
        : currentTime.hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text('Follow-up Dashboard'),
          actions: [
            if (followupProvider.isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Today'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Overdue'),
              Tab(text: 'Reminders'),
            ],
          ),
        ),
        body: followupProvider.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading follow-ups...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
          onRefresh: _loadData,
          color: primaryColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$welcomeMessage, ${chwName.split(' ').first}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatisticsRow(stats, followupProvider),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      100,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Today's visits from API
                      _buildApiVisitList(
                        followupProvider.todayVisitsFromApi, 
                        patientProvider, 
                        'today',
                      ),
                      // Upcoming visits from API
                      _buildApiVisitList(
                        followupProvider.upcomingVisitsFromApi, 
                        patientProvider, 
                        'upcoming',
                      ),
                      // Overdue follow-ups from API
                      _buildApiVisitList(
                        followupProvider.overdueVisitsFromApi, 
                        patientProvider, 
                        'overdue',
                      ),
                      // Reminders (local)
                      _buildReminderList(followupProvider.reminders, patientProvider, chwId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: secondaryColor,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add new follow-up action')),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatisticsRow(
      Map<String, int> stats, FollowupProvider followupProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          'Pending', 
          '${stats['pendingFollowUps'] ?? followupProvider.pendingFollowUpsFromApi.length}', 
          Colors.orange
        ),
        _buildStatItem(
          'Overdue', 
          '${stats['overdueFollowUps'] ?? followupProvider.overdueVisitsFromApi.length}', 
          Colors.redAccent
        ),
        _buildStatItem(
          'Today', 
          '${stats['todayVisits'] ?? followupProvider.todayVisitsFromApi.length}', 
          primaryColor
        ),
        _buildStatItem(
          'Soon', 
          '${stats['upcomingVisits'] ?? followupProvider.upcomingVisitsFromApi.length}', 
          secondaryColor
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(200), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList(
      List<Reminder> reminders, PatientProvider patientProvider, String chwId,
      [bool isOverdue = false]) {
    if (reminders.isEmpty) return _buildEmptyState(isOverdue ? 'overdue' : 'reminders');

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        // Ensure patient is found, or handle the case where it's not (e.g., return a placeholder Patient)
        final patient = patientProvider.patients.firstWhere(
              (p) => p.id == reminder.patientId,
          orElse: () => Patient(
            id: 'unknown',
            chwId: chwId,
            familyId: 'unknown',
            firstName: 'Unknown',
            lastName: 'Patient',
            dateOfBirth: DateTime.now(),
            gender: 'unknown',
            relationshipToHead: 'Unknown',
            healthStatus: 'Unknown',
            registeredDate: DateTime.now(),
          ),
        );

        return FollowupCard(
          reminder: reminder,
          patientDisplayId: patient.displayId,
          onTap: () {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientDetailScreen(patientId: reminder.patientId ?? ''),
              ),
            );
          },
          onComplete: () => _completeReminder(reminder.id, reminder.patientId ?? ''),
          onReschedule: () => _showRescheduleDialog(reminder.id),
          onSnooze: () => _showSnoozeDialog(reminder.id),
        );
      },
    );
  }

  /// Build visit list from API data
  Widget _buildApiVisitList(
    List<Visit> visits, 
    PatientProvider patientProvider, 
    String listType,
  ) {
    if (visits.isEmpty) return _buildEmptyState(listType);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        return _buildVisitCard(visit, patientProvider, listType);
      },
    );
  }
  
  /// Build individual visit card from API visit data
  Widget _buildVisitCard(Visit visit, PatientProvider patientProvider, String listType) {
    final isOverdue = listType == 'overdue';
    final urgencyColor = _getUrgencyColor(visit.urgencyLevel);
    
    // Determine the relevant date to display
    final displayDate = listType == 'overdue' && visit.followUpDate != null
        ? visit.followUpDate!
        : visit.visitDate;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isOverdue 
            ? const BorderSide(color: Colors.red, width: 2) 
            : BorderSide.none,
      ),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final patient = await patientProvider.getPatient(visit.patientId);
          if (!mounted || patient == null) return;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDetailScreen(patientId: visit.patientId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with urgency and visit type
              Row(
                children: [
                  // Urgency indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getUrgencyIcon(visit.urgencyLevel), size: 14, color: urgencyColor),
                        const SizedBox(width: 4),
                        Text(
                          visit.urgencyLevelDisplay.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: urgencyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Visit type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      visit.visitTypeDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Patient ID
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Patient ID: ${visit.patientId.substring(0, 8)}...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Chief complaint
              if (visit.chiefComplaint != null && visit.chiefComplaint!.isNotEmpty) ...[
                Text(
                  visit.chiefComplaint!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              
              // Date and time info
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy').format(displayDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${DateTime.now().difference(displayDate).inDays} days overdue',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              // Follow-up date if present
              if (visit.followUpDate != null && listType != 'overdue') ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.event_repeat, 
                      size: 14, 
                      color: visit.followUpCompleted ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Follow-up: ${DateFormat('MMM dd').format(visit.followUpDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: visit.followUpCompleted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (visit.followUpCompleted)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.check_circle, size: 14, color: Colors.green),
                      ),
                  ],
                ),
              ],
              
              const Divider(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final patient = await patientProvider.getPatient(visit.patientId);
                        if (!mounted || patient == null) return;
                        
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CompleteFollowupScreen(patient: patient),
                          ),
                        );
                        if (mounted) await _loadData();
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Complete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showVisitRescheduleDialog(visit.id!),
                      icon: const Icon(Icons.event, size: 18),
                      label: const Text('Reschedule'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Show dialog to reschedule a visit's follow-up date
  Future<void> _showVisitRescheduleDialog(String visitId) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026, 12, 31),
    );

    if (!mounted || selectedDate == null) return;

    final followupProvider = Provider.of<FollowupProvider>(context, listen: false);
    final success = await followupProvider.rescheduleFollowUp(visitId, selectedDate);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Follow-up rescheduled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reschedule: ${followupProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Get color based on urgency level
  Color _getUrgencyColor(String urgencyLevel) {
    switch (urgencyLevel.toLowerCase()) {
      case 'emergency': return Colors.red;
      case 'urgent': return Colors.orange;
      case 'standard': return Colors.blue;
      case 'low': return Colors.green;
      case 'routine': return Colors.teal;
      default: return Colors.grey;
    }
  }
  
  /// Get icon based on urgency level
  IconData _getUrgencyIcon(String urgencyLevel) {
    switch (urgencyLevel.toLowerCase()) {
      case 'emergency': return Icons.emergency;
      case 'urgent': return Icons.warning;
      case 'standard': return Icons.info;
      case 'low': return Icons.check_circle;
      case 'routine': return Icons.schedule;
      default: return Icons.help;
    }
  }

  // TODO: Unused method - kept for potential future use
  // Widget _buildVisitList(List<ScheduledVisit> visits, PatientProvider patientProvider) {
  //   if (visits.isEmpty) return _buildEmptyState('visits');
  //
  //   return ListView.builder(
  //     padding: EdgeInsets.zero,
  //     itemCount: visits.length,
  //     itemBuilder: (context, index) {
  //       final visit = visits[index];
  //       final circleColor = primaryColor.withAlpha(200);
  //
  //       return Card(
  //         margin: const EdgeInsets.symmetric(vertical: 8),
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //         elevation: 4,
  //         child: ListTile(
  //           leading: CircleAvatar(
  //             backgroundColor: circleColor,
  //             child: Icon(Icons.location_on, color: primaryColor),
  //           ),
  //           title: Text(
  //             'Patient ID: ${visit.patientId}',
  //             style: const TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //           subtitle: Text(
  //             'Purpose: ${visit.purpose}\nDate: ${visit.scheduledDate}',
  //           ),
  //           trailing: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               if (!visit.isCompleted)
  //                 IconButton(
  //                   icon: const Icon(Icons.check_circle_outline, color: Colors.green),
  //                   onPressed: () async { // Made async
  //                     // Fetch patient before navigating to CompleteFollowupScreen
  //                     final patient = await patientProvider.getPatient(visit.patientId);
  //                     if (!mounted || patient == null) return;
  //
  //                     await Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (_) => CompleteFollowupScreen(
  //                           patient: patient,
  //                           pendingVisit: visit,
  //                         ),
  //                       ),
  //                     );
  //                     if (mounted) await _loadData(); // Refresh data when returning
  //                   },
  //                   tooltip: 'Mark as complete',
  //                 )
  //               else
  //                 IconButton(
  //                   icon: const Icon(Icons.undo, color: Colors.orange),
  //                   onPressed: () => _uncompleteVisit(visit),
  //                   tooltip: 'Mark as incomplete',
  //                 ),
  //               Icon(
  //                 visit.isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
  //                 color: visit.isCompleted ? Colors.green : Colors.grey,
  //               ),
  //             ],
  //           ),
  //           onTap: () async { // Made async
  //             // Fetch patient before navigating to CompleteFollowupScreen
  //             final patient = await patientProvider.getPatient(visit.patientId);
  //             if (!mounted || patient == null) return;
  //
  //             await Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (_) => CompleteFollowupScreen(
  //                   patient: patient,
  //                   pendingVisit: visit,
  //                 ), // Navigate to CompleteFollowupScreen with pending visit
  //               ),
  //             );
  //             if (mounted) await _loadData(); // Refresh data when returning
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildEmptyState(String listType) {
    IconData icon;
    String title;
    String subtitle;
    
    switch (listType) {
      case 'today':
        icon = Icons.event_available;
        title = 'No visits scheduled for today!';
        subtitle = 'Enjoy your day or check upcoming visits.';
        break;
      case 'upcoming':
        icon = Icons.calendar_month;
        title = 'No upcoming visits!';
        subtitle = 'Future scheduled visits will appear here.';
        break;
      case 'overdue':
        icon = Icons.check_circle_outline;
        title = 'No overdue follow-ups! 🎉';
        subtitle = "You're all caught up!";
        break;
      case 'reminders':
        icon = Icons.notifications_none;
        title = 'No reminders';
        subtitle = 'Your reminders will appear here.';
        break;
      default:
        icon = Icons.list_alt;
        title = 'No items';
        subtitle = 'Items will appear here when added.';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 90, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
