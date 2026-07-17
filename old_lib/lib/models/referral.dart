/// Local Referral Model
/// Extends API model with additional fields for local storage and UI
class Referral {
  final String id;
  final String patientId;
  final String chwId;
  final DateTime referralDate;
  final String referralReason;
  final String referredTo;
  
  // Optional fields
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final String? contactNumber;
  final String? urgency;
  final String? status;
  final String? facilityType;
  final String? department;
  final String? referringProvider;
  final String? referralType;
  final String? transportMethod;
  final String? estimatedArrivalTime;
  final String? accompaniedBy;
  final bool? consentObtained;
  final String? consentBy;
  final String? vitalsAtReferral;
  final bool? reminderSent;
  final DateTime? reminderSentAt;
  
  // Outcome fields
  String? outcome;
  DateTime? outcomeDate;
  final String? outcomeNotes;
  final String? feedbackReceived;
  final DateTime? feedbackReceivedAt;
  final String? patientArrived;
  final DateTime? actualArrivalTime;
  final String? treatmentReceived;
  
  // Metadata
  String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? syncVersion;
  final DateTime? lastSyncedAt;
  
  // Local-only fields
  final bool isSynced;
  final bool pendingSync;

  Referral({
    required this.id,
    required this.patientId,
    required this.chwId,
    required this.referralDate,
    required this.referralReason,
    required this.referredTo,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.contactNumber,
    this.urgency,
    this.status,
    this.facilityType,
    this.department,
    this.referringProvider,
    this.referralType,
    this.transportMethod,
    this.estimatedArrivalTime,
    this.accompaniedBy,
    this.consentObtained,
    this.consentBy,
    this.vitalsAtReferral,
    this.reminderSent,
    this.reminderSentAt,
    this.outcome,
    this.outcomeDate,
    this.outcomeNotes,
    this.feedbackReceived,
    this.feedbackReceivedAt,
    this.patientArrived,
    this.actualArrivalTime,
    this.treatmentReceived,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.syncVersion,
    this.lastSyncedAt,
    this.isSynced = false,
    this.pendingSync = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'chw_id': chwId,
      'referral_date': referralDate.toIso8601String(),
      'referral_reason': referralReason,
      'referred_to': referredTo,
      'patient_name': patientName,
      'patient_age': patientAge,
      'patient_gender': patientGender,
      'contact_number': contactNumber,
      'urgency': urgency,
      'status': status,
      'facility_type': facilityType,
      'department': department,
      'referring_provider': referringProvider,
      'referral_type': referralType,
      'transport_method': transportMethod,
      'estimated_arrival_time': estimatedArrivalTime,
      'accompanied_by': accompaniedBy,
      'consent_obtained': consentObtained == true ? 1 : 0,
      'consent_by': consentBy,
      'vitals_at_referral': vitalsAtReferral,
      'reminder_sent': reminderSent == true ? 1 : 0,
      'reminder_sent_at': reminderSentAt?.toIso8601String(),
      'outcome': outcome,
      'outcome_date': outcomeDate?.toIso8601String(),
      'outcome_notes': outcomeNotes,
      'feedback_received': feedbackReceived,
      'feedback_received_at': feedbackReceivedAt?.toIso8601String(),
      'patient_arrived': patientArrived,
      'actual_arrival_time': actualArrivalTime?.toIso8601String(),
      'treatment_received': treatmentReceived,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_version': syncVersion,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'pending_sync': pendingSync ? 1 : 0,
    };
  }

  factory Referral.fromMap(Map<String, dynamic> map) {
    return Referral(
      id: map['id'],
      patientId: map['patient_id'],
      chwId: map['chw_id'],
      referralDate: DateTime.parse(map['referral_date']),
      referralReason: map['referral_reason'],
      referredTo: map['referred_to'],
      patientName: map['patient_name'],
      patientAge: map['patient_age'],
      patientGender: map['patient_gender'],
      contactNumber: map['contact_number'],
      urgency: map['urgency'],
      status: map['status'],
      facilityType: map['facility_type'],
      department: map['department'],
      referringProvider: map['referring_provider'],
      referralType: map['referral_type'],
      transportMethod: map['transport_method'],
      estimatedArrivalTime: map['estimated_arrival_time'],
      accompaniedBy: map['accompanied_by'],
      consentObtained: map['consent_obtained'] == 1,
      consentBy: map['consent_by'],
      vitalsAtReferral: map['vitals_at_referral'],
      reminderSent: map['reminder_sent'] == 1,
      reminderSentAt: map['reminder_sent_at'] != null ? DateTime.parse(map['reminder_sent_at']) : null,
      outcome: map['outcome'],
      outcomeDate: map['outcome_date'] != null ? DateTime.parse(map['outcome_date']) : null,
      outcomeNotes: map['outcome_notes'],
      feedbackReceived: map['feedback_received'],
      feedbackReceivedAt: map['feedback_received_at'] != null ? DateTime.parse(map['feedback_received_at']) : null,
      patientArrived: map['patient_arrived'],
      actualArrivalTime: map['actual_arrival_time'] != null ? DateTime.parse(map['actual_arrival_time']) : null,
      treatmentReceived: map['treatment_received'],
      notes: map['notes'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      syncVersion: map['sync_version'],
      lastSyncedAt: map['last_synced_at'] != null ? DateTime.parse(map['last_synced_at']) : null,
      isSynced: map['is_synced'] == 1,
      pendingSync: map['pending_sync'] == 1,
    );
  }
  
  Referral copyWith({
    String? id,
    String? patientId,
    String? chwId,
    DateTime? referralDate,
    String? referralReason,
    String? referredTo,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? contactNumber,
    String? urgency,
    String? status,
    String? facilityType,
    String? department,
    String? referringProvider,
    String? referralType,
    String? transportMethod,
    String? estimatedArrivalTime,
    String? accompaniedBy,
    bool? consentObtained,
    String? consentBy,
    String? vitalsAtReferral,
    bool? reminderSent,
    DateTime? reminderSentAt,
    String? outcome,
    DateTime? outcomeDate,
    String? outcomeNotes,
    String? feedbackReceived,
    DateTime? feedbackReceivedAt,
    String? patientArrived,
    DateTime? actualArrivalTime,
    String? treatmentReceived,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncVersion,
    DateTime? lastSyncedAt,
    bool? isSynced,
    bool? pendingSync,
  }) {
    return Referral(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      chwId: chwId ?? this.chwId,
      referralDate: referralDate ?? this.referralDate,
      referralReason: referralReason ?? this.referralReason,
      referredTo: referredTo ?? this.referredTo,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      contactNumber: contactNumber ?? this.contactNumber,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      facilityType: facilityType ?? this.facilityType,
      department: department ?? this.department,
      referringProvider: referringProvider ?? this.referringProvider,
      referralType: referralType ?? this.referralType,
      transportMethod: transportMethod ?? this.transportMethod,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      accompaniedBy: accompaniedBy ?? this.accompaniedBy,
      consentObtained: consentObtained ?? this.consentObtained,
      consentBy: consentBy ?? this.consentBy,
      vitalsAtReferral: vitalsAtReferral ?? this.vitalsAtReferral,
      reminderSent: reminderSent ?? this.reminderSent,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      outcome: outcome ?? this.outcome,
      outcomeDate: outcomeDate ?? this.outcomeDate,
      outcomeNotes: outcomeNotes ?? this.outcomeNotes,
      feedbackReceived: feedbackReceived ?? this.feedbackReceived,
      feedbackReceivedAt: feedbackReceivedAt ?? this.feedbackReceivedAt,
      patientArrived: patientArrived ?? this.patientArrived,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      treatmentReceived: treatmentReceived ?? this.treatmentReceived,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
