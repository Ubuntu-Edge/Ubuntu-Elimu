import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../models/reminder_models.dart';
import '../models/scheduled_visit.dart';
import '../models/visit.dart';
import '../models/visit_models.dart';
import '../models/patient.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/visit_api_service.dart';
import '../services/reminder_api_service.dart';
import '../services/connectivity_service.dart';

class FollowupProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final VisitApiService _visitApi = VisitApiService.instance;
  final ReminderApiService _reminderApi = ReminderApiService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;

  List<Reminder> _reminders = [];
  List<Reminder> _overdueReminders = [];
  List<Reminder> _todayReminders = [];
  List<Reminder> _weekReminders = [];
  List<ScheduledVisit> _scheduledVisits = [];
  Map<String, int> _statistics = {};
  
  // Visit-based follow-ups from API
  List<Visit> _allVisits = [];
  List<Visit> _todayVisitsFromApi = [];
  List<Visit> _upcomingVisitsFromApi = [];
  List<Visit> _overdueVisitsFromApi = [];
  List<Visit> _pendingFollowUpsFromApi = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Reminder> get reminders => _reminders;
  List<Reminder> get overdueReminders => _overdueReminders;
  List<Reminder> get todayReminders => _todayReminders;
  List<Reminder> get weekReminders => _weekReminders;
  List<ScheduledVisit> get scheduledVisits => _scheduledVisits;
  Map<String, int> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _connectivity.isOnline;
  
  // Visit-based getters (from API)
  List<Visit> get allVisits => _allVisits;
  List<Visit> get todayVisitsFromApi => _todayVisitsFromApi;
  List<Visit> get upcomingVisitsFromApi => _upcomingVisitsFromApi;
  List<Visit> get overdueVisitsFromApi => _overdueVisitsFromApi;
  List<Visit> get pendingFollowUpsFromApi => _pendingFollowUpsFromApi;

  // Legacy getter for today's visits, derived from _scheduledVisits
  List<ScheduledVisit> get todayVisits => _scheduledVisits.where((visit) => visit.isToday && !visit.isCompleted).toList();

  // Legacy getter for upcoming visits, derived from _scheduledVisits
  List<ScheduledVisit> get upcomingVisits => _scheduledVisits
      .where((visit) => visit.isUpcoming && !visit.isCompleted)
      .toList();

  /// Load all reminders for a CHW with offline-first approach
  /// - If online: fetches from API and syncs to local DB
  /// - If offline: loads from local DB only
  Future<void> loadReminders(String chwId) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Loading reminders for CHW: $chwId');
      
      if (isOnline) {
        // Online: Fetch from API
        try {
          final response = await _reminderApi.listReminders(perPage: 100);
          
          // Convert API responses to local Reminder models
          _reminders = response.data.map((apiReminder) => _convertApiToLocalReminder(apiReminder)).toList();
          
          // Sync to local database
          for (final reminder in _reminders) {
            await _db.createOrUpdateReminder(reminder.copyWith(
              isSynced: true,
              pendingSync: false,
              lastSyncedAt: DateTime.now(),
            ));
          }
          
          debugPrint('✅ Loaded ${_reminders.length} reminders from API');
        } catch (e) {
          debugPrint('❌ API fetch failed: $e, falling back to local DB');
          _reminders = await _db.getRemindersByCHW(chwId);
        }
      } else {
        // Offline: Load from local database
        _reminders = await _db.getRemindersByCHW(chwId);
        debugPrint('📱 Loaded ${_reminders.length} reminders from local DB (offline)');
      }
      
      _updateReminderLists();
      _statistics = await _db.getReminderStatistics(chwId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load reminders: $e';
      debugPrint('Error loading reminders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load scheduled visits from local DB
  Future<void> loadScheduledVisits(String chwId) async {
    try {
      // Fetch all scheduled visits (completed or not)
      _scheduledVisits = await _db.getScheduledVisitsByCHW(chwId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load scheduled visits: $e';
      notifyListeners();
    }
  }

  /// Load all visits from the API and categorize them by date
  /// This fetches visits from the backend and organizes them into:
  /// - Today's visits (visit_date is today)
  /// - Upcoming visits (visit_date is in the future)
  /// - Overdue follow-ups (follow_up_date is past and not completed)
  /// - Pending follow-ups (has follow_up_date and not completed)
  Future<void> loadVisitsFromApi() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isOnline) {
        final response = await _visitApi.listVisits(perPage: 100);
        
        // Convert API responses to Visit models
        _allVisits = response.data.map((apiVisit) => _convertApiVisitToVisit(apiVisit)).toList();
        
        // Categorize visits by date
        _categorizeVisits();
        
        // Update statistics
        _updateVisitStatistics();
        
        _errorMessage = null;
        debugPrint('✅ Loaded ${_allVisits.length} visits from API');
      } else {
        // Offline - load from local database
        _allVisits = await _db.getAllVisits();
        _categorizeVisits();
        _updateVisitStatistics();
        debugPrint('📱 Loaded ${_allVisits.length} visits from local DB (offline)');
      }
    } catch (e) {
      _errorMessage = 'Failed to load visits: $e';
      debugPrint('❌ Failed to load visits from API: $e');
      
      // Fallback to local database on error
      try {
        _allVisits = await _db.getAllVisits();
        _categorizeVisits();
        _updateVisitStatistics();
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Convert API VisitResponse to local Visit model
  Visit _convertApiVisitToVisit(VisitResponse apiVisit) {
    return Visit(
      id: apiVisit.id,
      patientId: apiVisit.patientId,
      visitDate: DateTime.tryParse(apiVisit.visitDate) ?? DateTime.now(),
      chwId: apiVisit.chwId ?? '',
      visitType: apiVisit.visitType,
      visitLocation: apiVisit.visitLocation,
      chiefComplaint: apiVisit.chiefComplaint,
      symptoms: apiVisit.symptoms,
      symptomsList: apiVisit.symptomsList,
      symptomDuration: apiVisit.symptomDuration,
      symptomSeverity: apiVisit.symptomSeverity,
      diagnosis: apiVisit.diagnosis,
      diagnosisCodes: apiVisit.diagnosisCodes,
      differentialDiagnosis: apiVisit.differentialDiagnosis,
      aiAssessment: apiVisit.aiAssessment,
      treatment: apiVisit.treatment,
      medicationsGiven: apiVisit.medicationsGiven?.map((m) => MedicationGivenModel(
        name: m.name,
        dosage: m.dosage,
        frequency: m.frequency,
        duration: m.duration,
        route: m.route,
        notes: m.notes,
      )).toList(),
      proceduresPerformed: apiVisit.proceduresPerformed,
      healthEducation: apiVisit.healthEducation,
      urgencyLevel: apiVisit.urgencyLevel ?? 'routine',
      wasReferred: apiVisit.wasReferred ?? false,
      referralLocation: apiVisit.referralLocation,
      referralReason: apiVisit.referralReason,
      outcome: apiVisit.outcome,
      patientStatusAfter: apiVisit.patientStatusAfter,
      followUpDate: apiVisit.followUpDate != null ? DateTime.tryParse(apiVisit.followUpDate!) : null,
      followUpCompleted: apiVisit.followUpCompleted ?? false,
      followUpNotes: null,
      vitals: apiVisit.vitals != null ? Vitals(
        temperature: apiVisit.vitals!.temperature,
        bloodPressureSystolic: apiVisit.vitals!.bloodPressureSystolic,
        bloodPressureDiastolic: apiVisit.vitals!.bloodPressureDiastolic,
        pulseRate: apiVisit.vitals!.pulseRate,
        respiratoryRate: apiVisit.vitals!.respiratoryRate,
        oxygenSaturation: apiVisit.vitals!.oxygenSaturation,
        weight: apiVisit.vitals!.weight,
        height: apiVisit.vitals!.height,
        bmi: apiVisit.vitals!.bmi,
        bloodGlucose: apiVisit.vitals!.bloodGlucose,
        muac: apiVisit.vitals!.muac,
        muacColor: apiVisit.vitals!.muacColor,
      ) : null,
      notes: apiVisit.notes,
      attachments: apiVisit.attachments,
      visitDurationMinutes: apiVisit.visitDurationMinutes,
      createdAt: apiVisit.createdAt != null ? DateTime.tryParse(apiVisit.createdAt!) : null,
      updatedAt: apiVisit.updatedAt != null ? DateTime.tryParse(apiVisit.updatedAt!) : null,
    );
  }
  
  /// Categorize visits into today, upcoming, overdue based on dates
  void _categorizeVisits() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    _todayVisitsFromApi = [];
    _upcomingVisitsFromApi = [];
    _overdueVisitsFromApi = [];
    _pendingFollowUpsFromApi = [];
    
    for (final visit in _allVisits) {
      final visitDate = DateTime(visit.visitDate.year, visit.visitDate.month, visit.visitDate.day);
      
      // Check if visit is scheduled for today
      if (visitDate.isAtSameMomentAs(today)) {
        _todayVisitsFromApi.add(visit);
      }
      // Check if visit is scheduled for future (upcoming)
      else if (visitDate.isAfter(today)) {
        _upcomingVisitsFromApi.add(visit);
      }
      
      // Check for pending follow-ups based on follow_up_date
      if (visit.followUpDate != null && !visit.followUpCompleted) {
        final followUpDate = DateTime(
          visit.followUpDate!.year, 
          visit.followUpDate!.month, 
          visit.followUpDate!.day
        );
        
        _pendingFollowUpsFromApi.add(visit);
        
        // If follow-up date is past and not completed, it's overdue
        if (followUpDate.isBefore(today)) {
          _overdueVisitsFromApi.add(visit);
        }
      }
    }
    
    // Sort visits
    _todayVisitsFromApi.sort((a, b) => a.visitDate.compareTo(b.visitDate));
    _upcomingVisitsFromApi.sort((a, b) => a.visitDate.compareTo(b.visitDate));
    _overdueVisitsFromApi.sort((a, b) {
      final dateA = a.followUpDate ?? a.visitDate;
      final dateB = b.followUpDate ?? b.visitDate;
      return dateA.compareTo(dateB);
    });
    _pendingFollowUpsFromApi.sort((a, b) {
      final dateA = a.followUpDate ?? a.visitDate;
      final dateB = b.followUpDate ?? b.visitDate;
      return dateA.compareTo(dateB);
    });
  }
  
  /// Update statistics based on visits
  void _updateVisitStatistics() {
    _statistics['todayVisits'] = _todayVisitsFromApi.length;
    _statistics['upcomingVisits'] = _upcomingVisitsFromApi.length;
    _statistics['overdueFollowUps'] = _overdueVisitsFromApi.length;
    _statistics['pendingFollowUps'] = _pendingFollowUpsFromApi.length;
    _statistics['totalVisits'] = _allVisits.length;
    
    // Count visits this week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekVisits = _allVisits.where((v) => v.visitDate.isAfter(weekStart)).length;
    _statistics['visitsThisWeek'] = thisWeekVisits;
  }
  
  /// Get visits for a specific patient from API
  Future<List<Visit>> getPatientVisitsFromApi(String patientId) async {
    try {
      if (isOnline) {
        final response = await _visitApi.listVisits(patientId: patientId, perPage: 100);
        return response.data.map((apiVisit) => _convertApiVisitToVisit(apiVisit)).toList();
      }
      return await _db.getVisitsByPatient(patientId);
    } catch (e) {
      _errorMessage = 'Failed to get patient visits: $e';
      notifyListeners();
      return [];
    }
  }
  
  /// Mark a follow-up as completed via API
  Future<bool> completeFollowUp(String visitId) async {
    try {
      if (isOnline) {
        final request = VisitUpdateRequest(followUpCompleted: true);
        await _visitApi.updateVisit(visitId, request);
        
        // Update local state
        final index = _allVisits.indexWhere((v) => v.id == visitId);
        if (index != -1) {
          _allVisits[index] = _allVisits[index].copyWith(followUpCompleted: true);
        }
        
        _categorizeVisits();
        _updateVisitStatistics();
        notifyListeners();
        
        debugPrint('✅ Follow-up completed: $visitId');
        return true;
      } else {
        _errorMessage = 'Cannot update while offline';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to complete follow-up: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Update follow-up date for a visit
  Future<bool> rescheduleFollowUp(String visitId, DateTime newFollowUpDate) async {
    try {
      if (isOnline) {
        final request = VisitUpdateRequest(
          followUpDate: newFollowUpDate.toIso8601String().split('T')[0],
          followUpCompleted: false,
        );
        await _visitApi.updateVisit(visitId, request);
        
        // Update local state
        final index = _allVisits.indexWhere((v) => v.id == visitId);
        if (index != -1) {
          _allVisits[index] = _allVisits[index].copyWith(
            followUpDate: newFollowUpDate,
            followUpCompleted: false,
          );
        }
        
        _categorizeVisits();
        _updateVisitStatistics();
        notifyListeners();
        
        debugPrint('✅ Follow-up rescheduled: $visitId to $newFollowUpDate');
        return true;
      } else {
        _errorMessage = 'Cannot update while offline';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to reschedule follow-up: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Convert API ReminderResponse to local Reminder model
  Reminder _convertApiToLocalReminder(ReminderResponse apiReminder) {
    return Reminder(
      id: apiReminder.id,
      chwId: apiReminder.chwId ?? '',
      patientId: apiReminder.patientId,
      visitId: apiReminder.visitId,
      referralId: apiReminder.referralId,
      type: apiReminder.type,
      title: apiReminder.title,
      description: apiReminder.description,
      reminderDate: DateTime.tryParse(apiReminder.reminderDate) ?? DateTime.now(),
      notificationTime: apiReminder.notificationTime != null ? DateTime.tryParse(apiReminder.notificationTime!) : null,
      priority: apiReminder.priority,
      recurrence: apiReminder.recurrence,
      recurrenceEndDate: apiReminder.recurrenceEndDate != null ? DateTime.tryParse(apiReminder.recurrenceEndDate!) : null,
      isCompleted: apiReminder.isCompleted ?? false,
      completedDate: apiReminder.completedDate != null ? DateTime.tryParse(apiReminder.completedDate!) : null,
      completedById: apiReminder.completedById,
      outcome: apiReminder.outcome,
      outcomeNotes: apiReminder.outcomeNotes,
      notes: apiReminder.notes,
      notificationId: apiReminder.notificationId != null ? int.tryParse(apiReminder.notificationId!) : null,
      notificationSent: apiReminder.notificationSent,
      notificationSentAt: apiReminder.notificationSentAt != null ? DateTime.tryParse(apiReminder.notificationSentAt!) : null,
      snoozedUntil: apiReminder.snoozedUntil != null ? DateTime.tryParse(apiReminder.snoozedUntil!) : null,
      snoozeCount: apiReminder.snoozeCount,
      createdAt: apiReminder.createdAt != null ? DateTime.tryParse(apiReminder.createdAt!) : null,
      updatedAt: apiReminder.updatedAt != null ? DateTime.tryParse(apiReminder.updatedAt!) : null,
      syncVersion: apiReminder.syncVersion,
      lastSyncedAt: apiReminder.lastSyncedAt != null ? DateTime.tryParse(apiReminder.lastSyncedAt!) : null,
      isSynced: true,
      pendingSync: false,
      isOverdueComputed: apiReminder.isOverdue,
      isDueTodayComputed: apiReminder.isDueToday,
      isSnoozedComputed: apiReminder.isSnoozed,
      daysUntilDueComputed: apiReminder.daysUntilDue,
    );
  }

  /// Create a new reminder with offline-first approach
  Future<bool> createReminder(Reminder reminder, Patient patient) async {
    try {
      debugPrint('Creating reminder: ${reminder.title}');
      
      if (isOnline) {
        // Online: Create via API
        final request = ReminderCreateRequest(
          type: reminder.type,
          title: reminder.title,
          reminderDate: reminder.reminderDate.toIso8601String(),
          patientId: reminder.patientId,
          visitId: reminder.visitId,
          referralId: reminder.referralId,
          description: reminder.description,
          notificationTime: reminder.notificationTime?.toIso8601String(),
          priority: reminder.priority,
          recurrence: reminder.recurrence,
          recurrenceEndDate: reminder.recurrenceEndDate?.toIso8601String(),
          notes: reminder.notes,
        );
        
        final apiResponse = await _reminderApi.createReminder(request);
        
        // Convert to local model
        final syncedReminder = _convertApiToLocalReminder(apiResponse).copyWith(
          isSynced: true,
          pendingSync: false,
          lastSyncedAt: DateTime.now(),
        );
        
        await _db.createOrUpdateReminder(syncedReminder);
        
        // Schedule notification
        if (syncedReminder.notificationTime != null) {
          await _notificationService.scheduleReminderNotification(syncedReminder, patient);
        }
        
        _reminders.insert(0, syncedReminder);
        debugPrint('✅ Reminder created via API: ${apiResponse.id}');
      } else {
        // Offline: Save to local DB with pending sync
        final offlineReminder = reminder.copyWith(
          isSynced: false,
          pendingSync: true,
        );
        await _db.createReminder(offlineReminder);
        
        // Schedule notification
        if (offlineReminder.notificationTime != null) {
          await _notificationService.scheduleReminderNotification(offlineReminder, patient);
        }
        
        _reminders.insert(0, offlineReminder);
        debugPrint('📱 Reminder saved locally (pending sync)');
      }

      _updateReminderLists();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create reminder: $e';
      debugPrint('Error creating reminder: $e');
      notifyListeners();
      return false;
    }
  }

  /// Create a reminder from ReminderCreateRequest (used by dialogs)
  Future<bool> createReminderFromRequest(ReminderCreateRequest request, String chwId) async {
    try {
      debugPrint('Creating reminder from request: ${request.title}');
      
      if (isOnline) {
        // Online: Create via API
        final apiResponse = await _reminderApi.createReminder(request);
        
        // Convert to local model
        final syncedReminder = _convertApiToLocalReminder(apiResponse).copyWith(
          isSynced: true,
          pendingSync: false,
          lastSyncedAt: DateTime.now(),
        );
        
        await _db.createOrUpdateReminder(syncedReminder);
        _reminders.insert(0, syncedReminder);
        debugPrint('✅ Reminder created via API: ${apiResponse.id}');
      } else {
        // Offline: Save to local DB with pending sync
        final offlineReminder = Reminder(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          chwId: chwId,
          patientId: request.patientId,
          visitId: request.visitId,
          referralId: request.referralId,
          type: request.type,
          title: request.title,
          description: request.description,
          reminderDate: DateTime.parse(request.reminderDate),
          notificationTime: request.notificationTime != null ? DateTime.tryParse(request.notificationTime!) : null,
          priority: request.priority,
          recurrence: request.recurrence,
          recurrenceEndDate: request.recurrenceEndDate != null ? DateTime.tryParse(request.recurrenceEndDate!) : null,
          notes: request.notes,
          isSynced: false,
          pendingSync: true,
        );
        
        await _db.createReminder(offlineReminder);
        _reminders.insert(0, offlineReminder);
        debugPrint('📱 Reminder saved locally (pending sync)');
      }

      _updateReminderLists();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create reminder: $e';
      debugPrint('Error creating reminder: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update a reminder with offline-first approach
  Future<bool> updateReminder(Reminder reminder) async {
    try {
      if (isOnline && reminder.isSynced) {
        // Online: Update via API
        final request = ReminderUpdateRequest(
          type: reminder.type,
          title: reminder.title,
          description: reminder.description,
          reminderDate: reminder.reminderDate.toIso8601String(),
          notificationTime: reminder.notificationTime?.toIso8601String(),
          priority: reminder.priority,
          recurrence: reminder.recurrence,
          recurrenceEndDate: reminder.recurrenceEndDate?.toIso8601String(),
          notes: reminder.notes,
        );
        
        await _reminderApi.updateReminder(reminder.id, request);
        debugPrint('✅ Reminder updated via API');
      }
      
      // Always update local DB
      await _db.updateReminder(reminder.copyWith(
        pendingSync: !isOnline || !reminder.isSynced,
        lastSyncedAt: isOnline ? DateTime.now() : reminder.lastSyncedAt,
      ));

      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder;
      }

      _updateReminderLists();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update reminder: $e';
      debugPrint('Error updating reminder: $e');
      notifyListeners();
      return false;
    }
  }

  /// Complete a reminder via API or locally
  Future<bool> completeReminder(String reminderId, String outcome, String? notes) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == reminderId);
      
      if (isOnline && reminder.isSynced) {
        // Online: Complete via API
        final request = ReminderCompleteRequest(
          outcome: outcome,
          outcomeNotes: notes,
        );
        
        await _reminderApi.completeReminder(reminderId, request: request);
        debugPrint('✅ Reminder completed via API');
      }
      
      final updatedReminder = reminder.copyWith(
        isCompleted: true,
        completedDate: DateTime.now(),
        outcome: outcome,
        outcomeNotes: notes,
        pendingSync: !isOnline || !reminder.isSynced,
        lastSyncedAt: isOnline ? DateTime.now() : reminder.lastSyncedAt,
      );

      await _db.updateReminder(updatedReminder);

      // Cancel notification if exists
      if (reminder.notificationId != null) {
        await _notificationService.cancelNotification(reminder.notificationId!);
      }

      _reminders.removeWhere((r) => r.id == reminderId);
      _updateReminderLists();

      // Update statistics
      _statistics['totalPending'] = (_statistics['totalPending'] ?? 1) - 1;
      _statistics['completedThisWeek'] = (_statistics['completedThisWeek'] ?? 0) + 1;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete reminder: $e';
      debugPrint('Error completing reminder: $e');
      notifyListeners();
      return false;
    }
  }

  /// Reschedule a reminder (uses update under the hood)
  Future<bool> rescheduleReminder(String reminderId, DateTime newDate) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == reminderId);
      final updatedReminder = reminder.copyWith(
        reminderDate: newDate,
        notificationTime: newDate.subtract(const Duration(hours: 1)),
      );

      // Use updateReminder which handles API/offline logic
      final success = await updateReminder(updatedReminder);
      
      if (success) {
        // Reschedule notification
        if (reminder.notificationId != null) {
          await _notificationService.cancelNotification(reminder.notificationId!);
        }
        debugPrint('✅ Reminder rescheduled to $newDate');
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to reschedule reminder: $e';
      debugPrint('Error rescheduling reminder: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Snooze a reminder until a specific time via API
  Future<bool> snoozeReminder(String reminderId, DateTime snoozeUntil) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == reminderId);
      
      if (isOnline && reminder.isSynced) {
        // Online: Snooze via API
        await _reminderApi.snoozeReminder(reminderId, snoozeUntil.toIso8601String());
        debugPrint('✅ Reminder snoozed via API until $snoozeUntil');
      }
      
      final updatedReminder = reminder.copyWith(
        snoozedUntil: snoozeUntil,
        snoozeCount: (reminder.snoozeCount ?? 0) + 1,
        pendingSync: !isOnline || !reminder.isSynced,
        lastSyncedAt: isOnline ? DateTime.now() : reminder.lastSyncedAt,
      );

      await _db.updateReminder(updatedReminder);

      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index != -1) {
        _reminders[index] = updatedReminder;
      }

      _updateReminderLists();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to snooze reminder: $e';
      debugPrint('Error snoozing reminder: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete a reminder via API or locally
  Future<bool> deleteReminder(String reminderId) async {
    try {
      final reminder = _reminders.firstWhere((r) => r.id == reminderId);

      if (isOnline && reminder.isSynced) {
        // Online: Delete via API
        await _reminderApi.deleteReminder(reminderId);
        debugPrint('✅ Reminder deleted via API');
      }
      
      await _db.deleteReminder(reminderId);

      // Cancel notification if exists
      if (reminder.notificationId != null) {
        await _notificationService.cancelNotification(reminder.notificationId!);
      }

      _reminders.removeWhere((r) => r.id == reminderId);
      _updateReminderLists();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete reminder: $e';
      debugPrint('Error deleting reminder: $e');
      notifyListeners();
      return false;
    }
  }

  // Get reminders for a specific patient
  Future<List<Reminder>> getPatientReminders(String patientId) async {
    try {
      return await _db.getRemindersByPatient(patientId);
    } catch (e) {
      _errorMessage = 'Failed to get patient reminders: $e';
      notifyListeners();
      return [];
    }
  }

  // Create scheduled visit
  Future<bool> createScheduledVisit(ScheduledVisit visit) async {
    try {
      await _db.createScheduledVisit(visit);
      _scheduledVisits.insert(0, visit);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create scheduled visit: $e';
      notifyListeners();
      return false;
    }
  }

  // Update scheduled visit
  Future<bool> updateScheduledVisit(ScheduledVisit visit) async {
    try {
      await _db.updateScheduledVisit(visit);

      final index = _scheduledVisits.indexWhere((v) => v.id == visit.id);
      if (index != -1) {
        _scheduledVisits[index] = visit;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update scheduled visit: $e';
      notifyListeners();
      return false;
    }
  }

  // Complete scheduled visit
  Future<bool> completeScheduledVisit(String visitId, String? actualDuration, String? linkedVisitId) async {
    try {
      final visit = _scheduledVisits.firstWhere((v) => v.id == visitId);
      final updatedVisit = visit.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        actualDuration: actualDuration,
        visitId: linkedVisitId,
      );

      await _db.updateScheduledVisit(updatedVisit);

      final index = _scheduledVisits.indexWhere((v) => v.id == visitId);
      if (index != -1) {
        _scheduledVisits[index] = updatedVisit;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete scheduled visit: $e';
      notifyListeners();
      return false;
    }
  }

  // New method to uncomplete a scheduled visit
  Future<bool> uncompleteScheduledVisit(String visitId) async {
    try {
      final visit = _scheduledVisits.firstWhere((v) => v.id == visitId);
      final updatedVisit = visit.copyWith(
        isCompleted: false,
        completedAt: null,
        actualDuration: null,
        visitId: null,
      );

      await _db.updateScheduledVisit(updatedVisit);

      final index = _scheduledVisits.indexWhere((v) => v.id == visitId);
      if (index != -1) {
        _scheduledVisits[index] = updatedVisit;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to uncomplete scheduled visit: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete scheduled visit
  Future<bool> deleteScheduledVisit(String visitId) async {
    try {
      await _db.deleteScheduledVisit(visitId);
      _scheduledVisits.removeWhere((v) => v.id == visitId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete scheduled visit: $e';
      notifyListeners();
      return false;
    }
  }

  // Get scheduled visits for a specific date
  Future<List<ScheduledVisit>> getVisitsByDate(String chwId, DateTime date) async {
    try {
      return await _db.getScheduledVisitsByDate(chwId, date);
    } catch (e) {
      _errorMessage = 'Failed to get visits by date: $e';
      notifyListeners();
      return [];
    }
  }

  // Helper: Update filtered lists after changes
  void _updateReminderLists() {
    // NOTE: isOverdue, isDueToday, and isDueThisWeek rely on logic implemented in the Reminder model.
    _overdueReminders = _reminders.where((r) => r.isOverdue).toList();
    _todayReminders = _reminders.where((r) => r.isDueToday).toList();
    _weekReminders = _reminders.where((r) => r.isDueThisWeek).toList();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      return await _notificationService.requestPermissions();
    } catch (e) {
      _errorMessage = 'Failed to request permissions: $e';
      notifyListeners();
      return false;
    }
  }

  // Schedule daily summary
  Future<void> scheduleDailySummary(String chwId) async {
    final pendingCount = _statistics['totalPending'] ?? 0;
    final overdueCount = _statistics['overdue'] ?? 0;

    await _notificationService.scheduleDailySummary(chwId, pendingCount, overdueCount);
  }
}
