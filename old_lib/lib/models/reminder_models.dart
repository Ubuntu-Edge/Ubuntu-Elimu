/// Reminder API Models
/// Models for reminder CRUD operations with backend API
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

/// Valid reminder types
class ReminderTypes {
  static const String followup = 'followup';
  static const String medication = 'medication';
  static const String vaccination = 'vaccination';
  static const String appointment = 'appointment';
  static const String antenatal = 'antenatal';
  static const String postnatal = 'postnatal';
  static const String chronicCare = 'chronic_care';
  static const String growthMonitoring = 'growth_monitoring';
  static const String homeVisit = 'home_visit';
  static const String general = 'general';

  static List<String> get all => [
        followup,
        medication,
        vaccination,
        appointment,
        antenatal,
        postnatal,
        chronicCare,
        growthMonitoring,
        homeVisit,
        general,
      ];
}

/// Valid priority levels
class ReminderPriority {
  static const String high = 'high';
  static const String medium = 'medium';
  static const String low = 'low';

  static List<String> get all => [high, medium, low];
}

/// Valid recurrence patterns
class ReminderRecurrence {
  static const String none = 'none';
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String biweekly = 'biweekly';
  static const String monthly = 'monthly';
  static const String quarterly = 'quarterly';

  static List<String> get all =>
      [none, daily, weekly, biweekly, monthly, quarterly];
}

/// Request model for creating a new reminder
/// Required: type, title, reminder_date
class ReminderCreateRequest {
  final String type;
  final String title;
  final String reminderDate; // ISO 8601 format
  final String? patientId;
  final String? visitId;
  final String? referralId;
  final String? description;
  final String? notificationTime;
  final String? priority;
  final String? recurrence;
  final String? recurrenceEndDate;
  final String? notes;
  final String? deviceId;

  ReminderCreateRequest({
    required this.type,
    required this.title,
    required this.reminderDate,
    this.patientId,
    this.visitId,
    this.referralId,
    this.description,
    this.notificationTime,
    this.priority,
    this.recurrence,
    this.recurrenceEndDate,
    this.notes,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': type,
      'title': title,
      'reminder_date': reminderDate,
    };

    if (patientId != null) data['patient_id'] = patientId;
    if (visitId != null) data['visit_id'] = visitId;
    if (referralId != null) data['referral_id'] = referralId;
    if (description != null) data['description'] = description;
    if (notificationTime != null) data['notification_time'] = notificationTime;
    if (priority != null) data['priority'] = priority;
    if (recurrence != null) data['recurrence'] = recurrence;
    if (recurrenceEndDate != null)
      data['recurrence_end_date'] = recurrenceEndDate;
    if (notes != null) data['notes'] = notes;
    if (deviceId != null) data['device_id'] = deviceId;

    return data;
  }
}

/// Request model for updating a reminder (all fields optional)
class ReminderUpdateRequest {
  final String? type;
  final String? title;
  final String? reminderDate;
  final String? patientId;
  final String? visitId;
  final String? referralId;
  final String? description;
  final String? notificationTime;
  final String? priority;
  final String? recurrence;
  final String? recurrenceEndDate;
  final String? notes;

  ReminderUpdateRequest({
    this.type,
    this.title,
    this.reminderDate,
    this.patientId,
    this.visitId,
    this.referralId,
    this.description,
    this.notificationTime,
    this.priority,
    this.recurrence,
    this.recurrenceEndDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (type != null) data['type'] = type;
    if (title != null) data['title'] = title;
    if (reminderDate != null) data['reminder_date'] = reminderDate;
    if (patientId != null) data['patient_id'] = patientId;
    if (visitId != null) data['visit_id'] = visitId;
    if (referralId != null) data['referral_id'] = referralId;
    if (description != null) data['description'] = description;
    if (notificationTime != null) data['notification_time'] = notificationTime;
    if (priority != null) data['priority'] = priority;
    if (recurrence != null) data['recurrence'] = recurrence;
    if (recurrenceEndDate != null)
      data['recurrence_end_date'] = recurrenceEndDate;
    if (notes != null) data['notes'] = notes;

    return data;
  }
}

/// Request model for completing a reminder
class ReminderCompleteRequest {
  final String? outcome;
  final String? outcomeNotes;

  ReminderCompleteRequest({
    this.outcome,
    this.outcomeNotes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (outcome != null) data['outcome'] = outcome;
    if (outcomeNotes != null) data['outcome_notes'] = outcomeNotes;
    return data;
  }
}

/// Response model for reminder data from API
class ReminderResponse {
  final String id;
  final String? chwId;
  final String type;
  final String title;
  final String reminderDate;
  final String? patientId;
  final String? visitId;
  final String? referralId;
  final String? description;
  final String? notificationTime;
  final String? priority;
  final String? recurrence;
  final String? recurrenceEndDate;
  final String? notes;
  final bool? isCompleted;
  final String? completedDate;
  final String? completedById;
  final String? outcome;
  final String? outcomeNotes;
  final String? notificationId;
  final bool? notificationSent;
  final String? notificationSentAt;
  final String? snoozedUntil;
  final int? snoozeCount;
  final bool? isOverdue;
  final bool? isDueToday;
  final bool? isSnoozed;
  final int? daysUntilDue;
  final String? createdAt;
  final String? updatedAt;
  final int? syncVersion;
  final String? lastSyncedAt;

  ReminderResponse({
    required this.id,
    this.chwId,
    required this.type,
    required this.title,
    required this.reminderDate,
    this.patientId,
    this.visitId,
    this.referralId,
    this.description,
    this.notificationTime,
    this.priority,
    this.recurrence,
    this.recurrenceEndDate,
    this.notes,
    this.isCompleted,
    this.completedDate,
    this.completedById,
    this.outcome,
    this.outcomeNotes,
    this.notificationId,
    this.notificationSent,
    this.notificationSentAt,
    this.snoozedUntil,
    this.snoozeCount,
    this.isOverdue,
    this.isDueToday,
    this.isSnoozed,
    this.daysUntilDue,
    this.createdAt,
    this.updatedAt,
    this.syncVersion,
    this.lastSyncedAt,
  });

  factory ReminderResponse.fromJson(Map<String, dynamic> json) {
    return ReminderResponse(
      id: json['id'] ?? '',
      chwId: json['chw_id'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      reminderDate: json['reminder_date'] ?? '',
      patientId: json['patient_id'],
      visitId: json['visit_id'],
      referralId: json['referral_id'],
      description: json['description'],
      notificationTime: json['notification_time'],
      priority: json['priority'],
      recurrence: json['recurrence'],
      recurrenceEndDate: json['recurrence_end_date'],
      notes: json['notes'],
      isCompleted: json['is_completed'],
      completedDate: json['completed_date'],
      completedById: json['completed_by_id'],
      outcome: json['outcome'],
      outcomeNotes: json['outcome_notes'],
      notificationId: json['notification_id'],
      notificationSent: json['notification_sent'],
      notificationSentAt: json['notification_sent_at'],
      snoozedUntil: json['snoozed_until'],
      snoozeCount: json['snooze_count'],
      isOverdue: json['is_overdue'],
      isDueToday: json['is_due_today'],
      isSnoozed: json['is_snoozed'],
      daysUntilDue: json['days_until_due'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      syncVersion: json['sync_version'],
      lastSyncedAt: json['last_synced_at'],
    );
  }

  /// Convert to database map for local storage
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'chw_id': chwId,
      'type': type,
      'title': title,
      'reminder_date': reminderDate,
      'patient_id': patientId,
      'visit_id': visitId,
      'referral_id': referralId,
      'description': description,
      'notification_time': notificationTime,
      'priority': priority,
      'recurrence': recurrence,
      'recurrence_end_date': recurrenceEndDate,
      'notes': notes,
      'is_completed': isCompleted == true ? 1 : 0,
      'completed_date': completedDate,
      'outcome': outcome,
      'outcome_notes': outcomeNotes,
      'snoozed_until': snoozedUntil,
      'snooze_count': snoozeCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_synced': 1,
      'pending_sync': 0,
    };
  }
}

/// Response model for paginated reminder list
class ReminderListResponse {
  final bool success;
  final List<ReminderResponse> data;
  final ReminderPaginationMeta pagination;

  ReminderListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory ReminderListResponse.fromJson(Map<String, dynamic> json) {
    return ReminderListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => ReminderResponse.fromJson(item))
              .toList() ??
          [],
      pagination: ReminderPaginationMeta.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// Pagination metadata for reminders
class ReminderPaginationMeta {
  final int page;
  final int perPage;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  ReminderPaginationMeta({
    required this.page,
    required this.perPage,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory ReminderPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ReminderPaginationMeta(
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalCount: json['total_count'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }
}

/// Exception for reminder API errors
class ReminderApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<ReminderValidationError>? validationErrors;

  ReminderApiException(this.message, {this.statusCode, this.validationErrors});

  @override
  String toString() => 'ReminderApiException: $message';
}

/// Validation error from API
class ReminderValidationError {
  final String type;
  final List<String> loc;
  final String msg;
  final dynamic input;

  ReminderValidationError({
    required this.type,
    required this.loc,
    required this.msg,
    this.input,
  });

  factory ReminderValidationError.fromJson(Map<String, dynamic> json) {
    return ReminderValidationError(
      type: json['type'] ?? '',
      loc: List<String>.from(json['loc']?.map((e) => e.toString()) ?? []),
      msg: json['msg'] ?? '',
      input: json['input'],
    );
  }
}
