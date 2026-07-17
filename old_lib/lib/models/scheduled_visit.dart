class ScheduledVisit {
  final String id;
  final String patientId;
  final String chwId;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final String purpose;
  final String? notes;
  final int? estimatedDuration;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? actualDuration;
  final String? visitId;
  final int? sortOrder;

  ScheduledVisit({
    required this.id,
    required this.patientId,
    required this.chwId,
    required this.scheduledDate,
    this.scheduledTime,
    required this.purpose,
    this.notes,
    this.estimatedDuration,
    this.isCompleted = false, // Default value
    this.completedAt,
    this.actualDuration,
    this.visitId,
    this.sortOrder,
  });

  // Getter: Check if visit is scheduled for today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visitDay = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );
    return today == visitDay;
  }

  // Getter: Check if visit is overdue
  bool get isOverdue {
    return !isCompleted && scheduledDate.isBefore(DateTime.now());
  }

  // Getter: Check if visit is upcoming (within next 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return !isCompleted &&
        scheduledDate.isAfter(now) &&
        scheduledDate.isBefore(weekFromNow);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'chw_id': chwId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'scheduled_time': scheduledTime,
      'purpose': purpose,
      'notes': notes,
      'estimated_duration': estimatedDuration,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'actual_duration': actualDuration,
      'visit_id': visitId,
      'sort_order': sortOrder,
    };
  }

  factory ScheduledVisit.fromMap(Map<String, dynamic> map) {
    return ScheduledVisit(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      chwId: map['chw_id'] as String,
      scheduledDate: DateTime.parse(map['scheduled_date'] as String),
      scheduledTime: map['scheduled_time'] as String?,
      purpose: map['purpose'] as String,
      notes: map['notes'] as String?,
      estimatedDuration: map['estimated_duration'] as int?,
      isCompleted: (map['is_completed'] as int) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      actualDuration: map['actual_duration'] as String?,
      visitId: map['visit_id'] as String?,
      sortOrder: map['sort_order'] as int?,
    );
  }

  // CopyWith method for easy updates
  ScheduledVisit copyWith({
    String? id,
    String? patientId,
    String? chwId,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? purpose,
    String? notes,
    int? estimatedDuration,
    bool? isCompleted,
    DateTime? completedAt,
    String? actualDuration,
    String? visitId,
    int? sortOrder,
  }) {
    return ScheduledVisit(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      chwId: chwId ?? this.chwId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      actualDuration: actualDuration ?? this.actualDuration,
      visitId: visitId ?? this.visitId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}