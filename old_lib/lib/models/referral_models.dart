/// Referral API Models
/// Models for referral CRUD operations with backend API
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

/// Request model for creating a new referral
/// Required: patient_id, referral_reason, referred_to
class ReferralCreateRequest {
  final String patientId;
  final String referralReason;
  final String referredTo;
  final String? visitId;
  final String? clinicalNotes;
  final String? facilityType;
  final String? facilityContact;
  final String? department;
  final String? urgency; // emergency, urgent, routine
  final bool? transportArranged;
  final String? transportType;
  final String? transportNotes;
  final String? accompaniedBy;
  final String? escortPhone;
  final String? appointmentDate; // ISO 8601 format
  final String? notes;
  final List<String>? attachments;
  final String? deviceId;

  ReferralCreateRequest({
    required this.patientId,
    required this.referralReason,
    required this.referredTo,
    this.visitId,
    this.clinicalNotes,
    this.facilityType,
    this.facilityContact,
    this.department,
    this.urgency,
    this.transportArranged,
    this.transportType,
    this.transportNotes,
    this.accompaniedBy,
    this.escortPhone,
    this.appointmentDate,
    this.notes,
    this.attachments,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'patient_id': patientId,
      'referral_reason': referralReason,
      'referred_to': referredTo,
    };

    if (visitId != null) data['visit_id'] = visitId;
    if (clinicalNotes != null) data['clinical_notes'] = clinicalNotes;
    if (facilityType != null) data['facility_type'] = facilityType;
    if (facilityContact != null) data['facility_contact'] = facilityContact;
    if (department != null) data['department'] = department;
    if (urgency != null) data['urgency'] = urgency;
    if (transportArranged != null)
      data['transport_arranged'] = transportArranged;
    if (transportType != null) data['transport_type'] = transportType;
    if (transportNotes != null) data['transport_notes'] = transportNotes;
    if (accompaniedBy != null) data['accompanied_by'] = accompaniedBy;
    if (escortPhone != null) data['escort_phone'] = escortPhone;
    if (appointmentDate != null) data['appointment_date'] = appointmentDate;
    if (notes != null) data['notes'] = notes;
    if (attachments != null) data['attachments'] = attachments;
    if (deviceId != null) data['device_id'] = deviceId;

    return data;
  }
}

/// Request model for updating a referral (all fields optional)
class ReferralUpdateRequest {
  final String? referralReason;
  final String? referredTo;
  final String? clinicalNotes;
  final String? facilityType;
  final String? facilityContact;
  final String? department;
  final String? urgency;
  final bool? transportArranged;
  final String? transportType;
  final String? transportNotes;
  final String? accompaniedBy;
  final String? escortPhone;
  final String? appointmentDate;
  final String? notes;
  final List<String>? attachments;

  ReferralUpdateRequest({
    this.referralReason,
    this.referredTo,
    this.clinicalNotes,
    this.facilityType,
    this.facilityContact,
    this.department,
    this.urgency,
    this.transportArranged,
    this.transportType,
    this.transportNotes,
    this.accompaniedBy,
    this.escortPhone,
    this.appointmentDate,
    this.notes,
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (referralReason != null) data['referral_reason'] = referralReason;
    if (referredTo != null) data['referred_to'] = referredTo;
    if (clinicalNotes != null) data['clinical_notes'] = clinicalNotes;
    if (facilityType != null) data['facility_type'] = facilityType;
    if (facilityContact != null) data['facility_contact'] = facilityContact;
    if (department != null) data['department'] = department;
    if (urgency != null) data['urgency'] = urgency;
    if (transportArranged != null)
      data['transport_arranged'] = transportArranged;
    if (transportType != null) data['transport_type'] = transportType;
    if (transportNotes != null) data['transport_notes'] = transportNotes;
    if (accompaniedBy != null) data['accompanied_by'] = accompaniedBy;
    if (escortPhone != null) data['escort_phone'] = escortPhone;
    if (appointmentDate != null) data['appointment_date'] = appointmentDate;
    if (notes != null) data['notes'] = notes;
    if (attachments != null) data['attachments'] = attachments;

    return data;
  }
}

/// Request model for updating referral status
class ReferralStatusUpdateRequest {
  final String
      status; // pending, accepted, in_progress, completed, cancelled, rejected, no_show
  final String? outcome;
  final String? outcomeDate;
  final String? facilityFeedback;
  final String? facilityDiagnosis;
  final String? facilityTreatment;
  final String? followUpInstructions;

  ReferralStatusUpdateRequest({
    required this.status,
    this.outcome,
    this.outcomeDate,
    this.facilityFeedback,
    this.facilityDiagnosis,
    this.facilityTreatment,
    this.followUpInstructions,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'status': status,
    };

    if (outcome != null) data['outcome'] = outcome;
    if (outcomeDate != null) data['outcome_date'] = outcomeDate;
    if (facilityFeedback != null) data['facility_feedback'] = facilityFeedback;
    if (facilityDiagnosis != null)
      data['facility_diagnosis'] = facilityDiagnosis;
    if (facilityTreatment != null)
      data['facility_treatment'] = facilityTreatment;
    if (followUpInstructions != null)
      data['follow_up_instructions'] = followUpInstructions;

    return data;
  }
}

/// Response model for referral data from API
class ReferralResponse {
  final String id;
  final String patientId;
  final String? chwId;
  final String? visitId;
  final String referralReason;
  final String referredTo;
  final String? clinicalNotes;
  final String? facilityType;
  final String? facilityContact;
  final String? department;
  final String? urgency;
  final String? status;
  final bool? transportArranged;
  final String? transportType;
  final String? transportNotes;
  final String? accompaniedBy;
  final String? escortPhone;
  final String? appointmentDate;
  final bool? appointmentConfirmed;
  final String? notes;
  final List<String>? attachments;
  final String? referralDate;
  final bool? reminderSent;
  final String? reminderSentAt;
  final String? outcome;
  final String? outcomeDate;
  final String? outcomeStatus;
  final String? facilityFeedback;
  final String? facilityDiagnosis;
  final String? facilityTreatment;
  final String? followUpInstructions;
  final String? createdAt;
  final String? updatedAt;
  final int? syncVersion;
  final String? lastSyncedAt;

  ReferralResponse({
    required this.id,
    required this.patientId,
    this.chwId,
    this.visitId,
    required this.referralReason,
    required this.referredTo,
    this.clinicalNotes,
    this.facilityType,
    this.facilityContact,
    this.department,
    this.urgency,
    this.status,
    this.transportArranged,
    this.transportType,
    this.transportNotes,
    this.accompaniedBy,
    this.escortPhone,
    this.appointmentDate,
    this.appointmentConfirmed,
    this.notes,
    this.attachments,
    this.referralDate,
    this.reminderSent,
    this.reminderSentAt,
    this.outcome,
    this.outcomeDate,
    this.outcomeStatus,
    this.facilityFeedback,
    this.facilityDiagnosis,
    this.facilityTreatment,
    this.followUpInstructions,
    this.createdAt,
    this.updatedAt,
    this.syncVersion,
    this.lastSyncedAt,
  });

  factory ReferralResponse.fromJson(Map<String, dynamic> json) {
    return ReferralResponse(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      chwId: json['chw_id'],
      visitId: json['visit_id'],
      referralReason: json['referral_reason'] ?? '',
      referredTo: json['referred_to'] ?? '',
      clinicalNotes: json['clinical_notes'],
      facilityType: json['facility_type'],
      facilityContact: json['facility_contact'],
      department: json['department'],
      urgency: json['urgency'],
      status: json['status'],
      transportArranged: json['transport_arranged'],
      transportType: json['transport_type'],
      transportNotes: json['transport_notes'],
      accompaniedBy: json['accompanied_by'],
      escortPhone: json['escort_phone'],
      appointmentDate: json['appointment_date'],
      appointmentConfirmed: json['appointment_confirmed'],
      notes: json['notes'],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      referralDate: json['referral_date'],
      reminderSent: json['reminder_sent'],
      reminderSentAt: json['reminder_sent_at'],
      outcome: json['outcome'],
      outcomeDate: json['outcome_date'],
      outcomeStatus: json['outcome_status'],
      facilityFeedback: json['facility_feedback'],
      facilityDiagnosis: json['facility_diagnosis'],
      facilityTreatment: json['facility_treatment'],
      followUpInstructions: json['follow_up_instructions'],
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
      'patient_id': patientId,
      'chw_id': chwId,
      'visit_id': visitId,
      'referral_reason': referralReason,
      'referred_to': referredTo,
      'clinical_notes': clinicalNotes,
      'facility_type': facilityType,
      'facility_contact': facilityContact,
      'department': department,
      'urgency': urgency,
      'status': status,
      'transport_arranged': transportArranged == true ? 1 : 0,
      'transport_type': transportType,
      'accompanied_by': accompaniedBy,
      'escort_phone': escortPhone,
      'appointment_date': appointmentDate,
      'notes': notes,
      'referral_date': referralDate,
      'outcome': outcome,
      'outcome_date': outcomeDate,
      'facility_feedback': facilityFeedback,
      'facility_diagnosis': facilityDiagnosis,
      'facility_treatment': facilityTreatment,
      'follow_up_instructions': followUpInstructions,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_synced': 1,
      'pending_sync': 0,
    };
  }
}

/// Response model for paginated referral list
class ReferralListResponse {
  final bool success;
  final List<ReferralResponse> data;
  final ReferralPaginationMeta pagination;

  ReferralListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory ReferralListResponse.fromJson(Map<String, dynamic> json) {
    return ReferralListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => ReferralResponse.fromJson(item))
              .toList() ??
          [],
      pagination: ReferralPaginationMeta.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// Pagination metadata for referrals
class ReferralPaginationMeta {
  final int page;
  final int perPage;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  ReferralPaginationMeta({
    required this.page,
    required this.perPage,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory ReferralPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ReferralPaginationMeta(
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalCount: json['total_count'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }
}

/// Exception for referral API errors
class ReferralApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<ReferralValidationError>? validationErrors;

  ReferralApiException(this.message, {this.statusCode, this.validationErrors});

  @override
  String toString() => 'ReferralApiException: $message';
}

/// Validation error from API
class ReferralValidationError {
  final String type;
  final List<String> loc;
  final String msg;
  final dynamic input;

  ReferralValidationError({
    required this.type,
    required this.loc,
    required this.msg,
    this.input,
  });

  factory ReferralValidationError.fromJson(Map<String, dynamic> json) {
    return ReferralValidationError(
      type: json['type'] ?? '',
      loc: List<String>.from(json['loc']?.map((e) => e.toString()) ?? []),
      msg: json['msg'] ?? '',
      input: json['input'],
    );
  }
}
