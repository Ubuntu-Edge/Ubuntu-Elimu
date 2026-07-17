/// Sync Models for API Integration
/// Supports: Push, Pull, Status, User Profile GET & POST
library;

/// Sync status
class SyncStatus {
  static const String pending = 'pending';
  static const String syncing = 'syncing';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String conflict = 'conflict';

  static const List<String> all = [
    pending,
    syncing,
    completed,
    failed,
    conflict
  ];
}

/// Entity types for syncing
class SyncEntityType {
  static const String patient = 'patient';
  static const String family = 'family';
  static const String visit = 'visit';
  static const String referral = 'referral';
  static const String reminder = 'reminder';
  static const String feedback = 'feedback';
  static const String message = 'message';
  static const String training = 'training';

  static const List<String> all = [
    patient,
    family,
    visit,
    referral,
    reminder,
    feedback,
    message,
    training,
  ];
}

/// Request model for push sync
class SyncPushRequest {
  final List<SyncPushItem> items;
  final String? deviceId;
  final DateTime lastSyncAt;

  SyncPushRequest({
    required this.items,
    this.deviceId,
    required this.lastSyncAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      if (deviceId != null) 'device_id': deviceId,
      'last_sync_at': lastSyncAt.toIso8601String(),
    };
  }
}

/// Individual item for push sync
class SyncPushItem {
  final String entityType; // SyncEntityType
  final String entityId;
  final String operation; // create, update, delete
  final Map<String, dynamic> data;
  final DateTime modifiedAt;
  final String? localId;

  SyncPushItem({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.modifiedAt,
    this.localId,
  });

  Map<String, dynamic> toJson() {
    return {
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'data': data,
      'modified_at': modifiedAt.toIso8601String(),
      if (localId != null) 'local_id': localId,
    };
  }
}

/// Response model for push sync
class SyncPushResponse {
  final int totalProcessed;
  final int successCount;
  final int failedCount;
  final int conflictCount;
  final List<SyncPushResult> results;
  final DateTime syncedAt;

  SyncPushResponse({
    required this.totalProcessed,
    required this.successCount,
    required this.failedCount,
    required this.conflictCount,
    required this.results,
    required this.syncedAt,
  });

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) {
    return SyncPushResponse(
      totalProcessed: json['total_processed'] ?? 0,
      successCount: json['success_count'] ?? 0,
      failedCount: json['failed_count'] ?? 0,
      conflictCount: json['conflict_count'] ?? 0,
      results: (json['results'] as List? ?? [])
          .map((item) => SyncPushResult.fromJson(item))
          .toList(),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'])
          : DateTime.now(),
    );
  }
}

/// Result for individual push item
class SyncPushResult {
  final String entityType;
  final String entityId;
  final String? localId;
  final String status; // success, failed, conflict
  final String? serverId;
  final String? errorMessage;
  final Map<String, dynamic>? conflictData;

  SyncPushResult({
    required this.entityType,
    required this.entityId,
    this.localId,
    required this.status,
    this.serverId,
    this.errorMessage,
    this.conflictData,
  });

  factory SyncPushResult.fromJson(Map<String, dynamic> json) {
    return SyncPushResult(
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'] ?? '',
      localId: json['local_id'],
      status: json['status'] ?? 'failed',
      serverId: json['server_id'],
      errorMessage: json['error_message'],
      conflictData: json['conflict_data'],
    );
  }
}

/// Request model for pull sync
class SyncPullRequest {
  final DateTime lastSyncAt;
  final List<String>? entityTypes; // Filter specific entity types
  final String? deviceId;
  final int? limit;

  SyncPullRequest({
    required this.lastSyncAt,
    this.entityTypes,
    this.deviceId,
    this.limit,
  });

  Map<String, dynamic> toJson() {
    return {
      'last_sync_at': lastSyncAt.toIso8601String(),
      if (entityTypes != null) 'entity_types': entityTypes,
      if (deviceId != null) 'device_id': deviceId,
      if (limit != null) 'limit': limit,
    };
  }
}

/// Response model for pull sync
class SyncPullResponse {
  final List<SyncPullItem> items;
  final int totalItems;
  final bool hasMore;
  final DateTime serverTime;
  final DateTime syncedAt;

  SyncPullResponse({
    required this.items,
    required this.totalItems,
    required this.hasMore,
    required this.serverTime,
    required this.syncedAt,
  });

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) {
    return SyncPullResponse(
      items: (json['items'] as List? ?? json['data'] as List? ?? [])
          .map((item) => SyncPullItem.fromJson(item))
          .toList(),
      totalItems: json['total_items'] ?? json['total'] ?? 0,
      hasMore: json['has_more'] ?? false,
      serverTime: json['server_time'] != null
          ? DateTime.parse(json['server_time'])
          : DateTime.now(),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'])
          : DateTime.now(),
    );
  }
}

/// Individual item from pull sync
class SyncPullItem {
  final String entityType;
  final String entityId;
  final String operation; // create, update, delete
  final Map<String, dynamic> data;
  final DateTime modifiedAt;

  SyncPullItem({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.modifiedAt,
  });

  factory SyncPullItem.fromJson(Map<String, dynamic> json) {
    return SyncPullItem(
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'] ?? '',
      operation: json['operation'] ?? 'update',
      data: json['data'] ?? {},
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'])
          : DateTime.now(),
    );
  }
}

/// Response model for sync status
class SyncStatusResponse {
  final DateTime? lastSyncAt;
  final int pendingPushCount;
  final int pendingPullCount;
  final String status; // SyncStatus
  final bool isOnline;
  final Map<String, EntitySyncStatus> entityStatuses;
  final DateTime checkedAt;

  SyncStatusResponse({
    this.lastSyncAt,
    required this.pendingPushCount,
    required this.pendingPullCount,
    required this.status,
    required this.isOnline,
    required this.entityStatuses,
    required this.checkedAt,
  });

  factory SyncStatusResponse.fromJson(Map<String, dynamic> json) {
    final entityStatusesMap = <String, EntitySyncStatus>{};
    if (json['entity_statuses'] != null) {
      (json['entity_statuses'] as Map<String, dynamic>).forEach((key, value) {
        entityStatusesMap[key] = EntitySyncStatus.fromJson(value);
      });
    }

    return SyncStatusResponse(
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'])
          : null,
      pendingPushCount: json['pending_push_count'] ?? 0,
      pendingPullCount: json['pending_pull_count'] ?? 0,
      status: json['status'] ?? 'pending',
      isOnline: json['is_online'] ?? false,
      entityStatuses: entityStatusesMap,
      checkedAt: json['checked_at'] != null
          ? DateTime.parse(json['checked_at'])
          : DateTime.now(),
    );
  }
}

/// Sync status for individual entity type
class EntitySyncStatus {
  final String entityType;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String status;

  EntitySyncStatus({
    required this.entityType,
    required this.pendingCount,
    this.lastSyncAt,
    required this.status,
  });

  factory EntitySyncStatus.fromJson(Map<String, dynamic> json) {
    return EntitySyncStatus(
      entityType: json['entity_type'] ?? '',
      pendingCount: json['pending_count'] ?? 0,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'])
          : null,
      status: json['status'] ?? 'pending',
    );
  }
}

/// User profile model
class UserProfile {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String role;
  final String? facilityId;
  final String? facilityName;
  final String? supervisorId;
  final String? supervisorName;
  final String? avatarUrl;
  final String? languagePreference;
  final bool isActive;
  final bool isVerified;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.role,
    this.facilityId,
    this.facilityName,
    this.supervisorId,
    this.supervisorName,
    this.avatarUrl,
    this.languagePreference,
    required this.isActive,
    required this.isVerified,
    this.settings,
    this.metadata,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? json['user_id'] ?? json['chw_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'] ?? json['phone'],
      role: json['role'] ?? 'chw',
      facilityId: json['facility_id'],
      facilityName: json['facility_name'],
      supervisorId: json['supervisor_id'],
      supervisorName: json['supervisor_name'],
      avatarUrl: json['avatar_url'],
      languagePreference: json['language_preference'] ?? json['language'],
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      settings: json['settings'],
      metadata: json['metadata'],
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'role': role,
      'facility_id': facilityId,
      'facility_name': facilityName,
      'supervisor_id': supervisorId,
      'supervisor_name': supervisorName,
      'avatar_url': avatarUrl,
      'language_preference': languagePreference,
      'is_active': isActive ? 1 : 0,
      'is_verified': isVerified ? 1 : 0,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Request model for updating user profile
class UserProfileUpdateRequest {
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? languagePreference;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;

  UserProfileUpdateRequest({
    this.fullName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.languagePreference,
    this.settings,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (fullName != null) map['full_name'] = fullName;
    if (firstName != null) map['first_name'] = firstName;
    if (lastName != null) map['last_name'] = lastName;
    if (phoneNumber != null) map['phone_number'] = phoneNumber;
    if (avatarUrl != null) map['avatar_url'] = avatarUrl;
    if (languagePreference != null) {
      map['language_preference'] = languagePreference;
    }
    if (settings != null) map['settings'] = settings;
    if (metadata != null) map['metadata'] = metadata;

    return map;
  }
}

/// Exception for sync API errors
class SyncApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  SyncApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'SyncApiException: $message (status: $statusCode)';
}
