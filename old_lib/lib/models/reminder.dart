/// Local Reminder Model
/// Extends API model with additional helper methods for UI
class Reminder {
  final String id;
  final String chwId;
  final String? patientId;
  final String? visitId;
  final String? referralId;
  final String type; // followup, medication, vaccination, appointment, antenatal, postnatal, chronic_care, growth_monitoring, home_visit, general
  final String title;
  final String? description;
  final DateTime reminderDate;
  final DateTime? notificationTime;
  final String? priority; // high, medium, low
  final String? recurrence; // none, daily, weekly, biweekly, monthly, quarterly
  final DateTime? recurrenceEndDate;
  final bool isCompleted;
  final DateTime? completedDate;
  final String? completedById;
  final String? outcome;
  final String? outcomeNotes;
  final String? notes;
  final int? notificationId;
  final bool? notificationSent;
  final DateTime? notificationSentAt;
  final DateTime? snoozedUntil;
  final int? snoozeCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? syncVersion;
  final DateTime? lastSyncedAt;
  
  // Local-only fields
  final bool isSynced;
  final bool pendingSync;
  
  // Computed fields (not stored, calculated)
  final bool? isOverdueComputed;
  final bool? isDueTodayComputed;
  final bool? isSnoozedComputed;
  final int? daysUntilDueComputed;

  Reminder({
    required this.id,
    required this.chwId,
    this.patientId,
    this.visitId,
    this.referralId,
    required this.type,
    required this.title,
    this.description,
    required this.reminderDate,
    this.notificationTime,
    this.priority,
    this.recurrence,
    this.recurrenceEndDate,
    this.isCompleted = false,
    this.completedDate,
    this.completedById,
    this.outcome,
    this.outcomeNotes,
    this.notes,
    this.notificationId,
    this.notificationSent,
    this.notificationSentAt,
    this.snoozedUntil,
    this.snoozeCount,
    this.createdAt,
    this.updatedAt,
    this.syncVersion,
    this.lastSyncedAt,
    this.isSynced = false,
    this.pendingSync = false,
    this.isOverdueComputed,
    this.isDueTodayComputed,
    this.isSnoozedComputed,
    this.daysUntilDueComputed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chw_id': chwId,
      'patient_id': patientId,
      'visit_id': visitId,
      'referral_id': referralId,
      'type': type,
      'title': title,
      'description': description,
      'reminder_date': reminderDate.toIso8601String(),
      'notification_time': notificationTime?.toIso8601String(),
      'priority': priority,
      'recurrence': recurrence,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'completed_date': completedDate?.toIso8601String(),
      'completed_by_id': completedById,
      'outcome': outcome,
      'outcome_notes': outcomeNotes,
      'notes': notes,
      'notification_id': notificationId,
      'notification_sent': notificationSent == true ? 1 : 0,
      'notification_sent_at': notificationSentAt?.toIso8601String(),
      'snoozed_until': snoozedUntil?.toIso8601String(),
      'snooze_count': snoozeCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_version': syncVersion,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'pending_sync': pendingSync ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      chwId: map['chw_id'],
      patientId: map['patient_id'],
      visitId: map['visit_id'],
      referralId: map['referral_id'],
      type: map['type'],
      title: map['title'],
      description: map['description'],
      reminderDate: DateTime.parse(map['reminder_date']),
      notificationTime: map['notification_time'] != null ? DateTime.parse(map['notification_time']) : null,
      priority: map['priority'],
      recurrence: map['recurrence'],
      recurrenceEndDate: map['recurrence_end_date'] != null ? DateTime.parse(map['recurrence_end_date']) : null,
      isCompleted: map['is_completed'] == 1,
      completedDate: map['completed_date'] != null ? DateTime.parse(map['completed_date']) : null,
      completedById: map['completed_by_id'],
      outcome: map['outcome'],
      outcomeNotes: map['outcome_notes'],
      notes: map['notes'],
      notificationId: map['notification_id'],
      notificationSent: map['notification_sent'] == 1,
      notificationSentAt: map['notification_sent_at'] != null ? DateTime.parse(map['notification_sent_at']) : null,
      snoozedUntil: map['snoozed_until'] != null ? DateTime.parse(map['snoozed_until']) : null,
      snoozeCount: map['snooze_count'] ?? 0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      syncVersion: map['sync_version'],
      lastSyncedAt: map['last_synced_at'] != null ? DateTime.parse(map['last_synced_at']) : null,
      isSynced: map['is_synced'] == 1,
      pendingSync: map['pending_sync'] == 1,
    );
  }

  Reminder copyWith({
    String? id,
    String? chwId,
    String? patientId,
    String? visitId,
    String? referralId,
    String? type,
    String? title,
    String? description,
    DateTime? reminderDate,
    DateTime? notificationTime,
    String? priority,
    String? recurrence,
    DateTime? recurrenceEndDate,
    bool? isCompleted,
    DateTime? completedDate,
    String? completedById,
    String? outcome,
    String? outcomeNotes,
    String? notes,
    int? notificationId,
    bool? notificationSent,
    DateTime? notificationSentAt,
    DateTime? snoozedUntil,
    int? snoozeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncVersion,
    DateTime? lastSyncedAt,
    bool? isSynced,
    bool? pendingSync,
  }) {
    return Reminder(
      id: id ?? this.id,
      chwId: chwId ?? this.chwId,
      patientId: patientId ?? this.patientId,
      visitId: visitId ?? this.visitId,
      referralId: referralId ?? this.referralId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderDate: reminderDate ?? this.reminderDate,
      notificationTime: notificationTime ?? this.notificationTime,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      completedById: completedById ?? this.completedById,
      outcome: outcome ?? this.outcome,
      outcomeNotes: outcomeNotes ?? this.outcomeNotes,
      notes: notes ?? this.notes,
      notificationId: notificationId ?? this.notificationId,
      notificationSent: notificationSent ?? this.notificationSent,
      notificationSentAt: notificationSentAt ?? this.notificationSentAt,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  // Helper methods - use computed fields from API if available, otherwise calculate locally
  bool get isOverdue {
    if (isOverdueComputed != null) return isOverdueComputed!;
    if (isCompleted || isSnoozed) return false;
    return reminderDate.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (isDueTodayComputed != null) return isDueTodayComputed!;
    if (isCompleted || isSnoozed) return false;
    final now = DateTime.now();
    return reminderDate.year == now.year &&
        reminderDate.month == now.month &&
        reminderDate.day == now.day;
  }

  bool get isDueTomorrow {
    if (isCompleted || isSnoozed) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return reminderDate.year == tomorrow.year &&
        reminderDate.month == tomorrow.month &&
        reminderDate.day == tomorrow.day;
  }

  bool get isDueThisWeek {
    if (isCompleted || isSnoozed) return false;
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return reminderDate.isAfter(now) && reminderDate.isBefore(weekFromNow);
  }
  
  bool get isSnoozed {
    if (isSnoozedComputed != null) return isSnoozedComputed!;
    if (snoozedUntil == null) return false;
    return snoozedUntil!.isAfter(DateTime.now());
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(reminderDate).inDays;
  }

  int get daysUntilDue {
    if (daysUntilDueComputed != null) return daysUntilDueComputed!;
    if (isOverdue) return 0;
    return reminderDate.difference(DateTime.now()).inDays;
  }

  String get urgencyLevel {
    if (isOverdue) return 'overdue';
    if (isDueToday) return 'today';
    if (isDueTomorrow) return 'tomorrow';
    if (isDueThisWeek) return 'this_week';
    return 'future';
  }
  
  String get priorityDisplay {
    switch (priority?.toLowerCase()) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
        return 'Low Priority';
      default:
        return 'Normal';
    }
  }
  
  String get typeDisplay {
    switch (type.toLowerCase()) {
      case 'followup':
        return 'Follow-up';
      case 'medication':
        return 'Medication';
      case 'vaccination':
        return 'Vaccination';
      case 'appointment':
        return 'Appointment';
      case 'antenatal':
        return 'Antenatal Care';
      case 'postnatal':
        return 'Postnatal Care';
      case 'chronic_care':
        return 'Chronic Care';
      case 'growth_monitoring':
        return 'Growth Monitoring';
      case 'home_visit':
        return 'Home Visit';
      case 'general':
        return 'General';
      default:
        return type;
    }
  }
}