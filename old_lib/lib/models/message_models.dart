/// Message Models for API Integration
/// Based on actual API specification: /api/v1/messages
/// API Response Fields: id, sender_id, recipient_id, group_id, content, message_type,
/// attachment_url/name/size/mime_type, latitude/longitude/location_name,
/// is_read/read_at/delivered_at/edited_at/original_content,
/// forwarded_from_id, replied_to_id, created_at, updated_at
library;

/// Message types (from API specification)
class MessageType {
  static const String text = 'text';
  static const String image = 'image';
  static const String audio = 'audio';
  static const String video = 'video';
  static const String file = 'file';
  static const String location = 'location';
  static const String system = 'system';

  static const List<String> all = [
    text,
    image,
    audio,
    video,
    file,
    location,
    system
  ];
}

/// Group types (from API specification)
class MessageGroupType {
  static const String chwTeam = 'chw_team';
  static const String supervisorGroup = 'supervisor_group';
  static const String projectGroup = 'project_group';
  static const String facilityGroup = 'facility_group';
  static const String regionGroup = 'region_group';
  static const String announcement = 'announcement';

  static const List<String> all = [
    chwTeam,
    supervisorGroup,
    projectGroup,
    facilityGroup,
    regionGroup,
    announcement,
  ];
}

/// Request model for creating a message (POST /api/v1/messages)
class MessageCreateRequest {
  final String content; // Required
  final String? recipientId; // Required if no groupId
  final String? groupId; // Required if no recipientId
  final String?
      messageType; // Optional: text, image, audio, video, file, location, system
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final String? attachmentMimeType;
  final double? latitude; // For location messages
  final double? longitude; // For location messages
  final String? locationName; // For location messages
  final String? forwardedFromId;
  final String? repliedToId;

  MessageCreateRequest({
    required this.content,
    this.recipientId,
    this.groupId,
    this.messageType,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.attachmentMimeType,
    this.latitude,
    this.longitude,
    this.locationName,
    this.forwardedFromId,
    this.repliedToId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'content': content,
    };

    if (recipientId != null) map['recipient_id'] = recipientId;
    if (groupId != null) map['group_id'] = groupId;
    if (messageType != null) map['message_type'] = messageType;
    if (attachmentUrl != null) map['attachment_url'] = attachmentUrl;
    if (attachmentName != null) map['attachment_name'] = attachmentName;
    if (attachmentSize != null) map['attachment_size'] = attachmentSize;
    if (attachmentMimeType != null)
      map['attachment_mime_type'] = attachmentMimeType;
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (locationName != null) map['location_name'] = locationName;
    if (forwardedFromId != null) map['forwarded_from_id'] = forwardedFromId;
    if (repliedToId != null) map['replied_to_id'] = repliedToId;

    return map;
  }
}

/// Request model for editing a message (PATCH /api/v1/messages/{id})
class MessageUpdateRequest {
  final String content;

  MessageUpdateRequest({
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}

/// Local Message model for offline storage with all API response fields
class Message {
  final String id;
  final String senderId;
  final String? recipientId;
  final String? groupId;
  final String content;
  final String messageType;
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final String? attachmentMimeType;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final DateTime? editedAt;
  final String? originalContent;
  final String? forwardedFromId;
  final String? repliedToId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Offline-first fields
  final bool pendingSync;
  final String? syncError;

  Message({
    required this.id,
    required this.senderId,
    this.recipientId,
    this.groupId,
    required this.content,
    required this.messageType,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.attachmentMimeType,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.isRead,
    this.readAt,
    this.deliveredAt,
    this.editedAt,
    this.originalContent,
    this.forwardedFromId,
    this.repliedToId,
    required this.createdAt,
    required this.updatedAt,
    this.pendingSync = false,
    this.syncError,
  });

  /// Create from API response
  factory Message.fromApi(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      recipientId: json['recipient_id'] as String?,
      groupId: json['group_id'] as String?,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentSize: json['attachment_size'] as int?,
      attachmentMimeType: json['attachment_mime_type'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['location_name'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      editedAt:
          json['edited_at'] != null ? DateTime.parse(json['edited_at']) : null,
      originalContent: json['original_content'] as String?,
      forwardedFromId: json['forwarded_from_id'] as String?,
      repliedToId: json['replied_to_id'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      pendingSync: false,
    );
  }

  /// Create from database map
  factory Message.fromDb(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      senderId: map['sender_id'] as String,
      recipientId: map['recipient_id'] as String?,
      groupId: map['group_id'] as String?,
      content: map['content'] as String,
      messageType: map['message_type'] as String? ?? 'text',
      attachmentUrl: map['attachment_url'] as String?,
      attachmentName: map['attachment_name'] as String?,
      attachmentSize: map['attachment_size'] as int?,
      attachmentMimeType: map['attachment_mime_type'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationName: map['location_name'] as String?,
      isRead: (map['is_read'] as int?) == 1,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.parse(map['delivered_at'])
          : null,
      editedAt:
          map['edited_at'] != null ? DateTime.parse(map['edited_at']) : null,
      originalContent: map['original_content'] as String?,
      forwardedFromId: map['forwarded_from_id'] as String?,
      repliedToId: map['replied_to_id'] as String?,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      pendingSync: (map['pending_sync'] as int?) == 1,
      syncError: map['sync_error'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'group_id': groupId,
      'content': content,
      'message_type': messageType,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
      'attachment_mime_type': attachmentMimeType,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'is_read': isRead ? 1 : 0,
      'read_at': readAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'original_content': originalContent,
      'forwarded_from_id': forwardedFromId,
      'replied_to_id': repliedToId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'pending_sync': pendingSync ? 1 : 0,
      'sync_error': syncError,
    };
  }

  /// Create a copy with updated fields
  Message copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? groupId,
    String? content,
    String? messageType,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? attachmentMimeType,
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isRead,
    DateTime? readAt,
    DateTime? deliveredAt,
    DateTime? editedAt,
    String? originalContent,
    String? forwardedFromId,
    String? repliedToId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pendingSync,
    String? syncError,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      attachmentMimeType: attachmentMimeType ?? this.attachmentMimeType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      editedAt: editedAt ?? this.editedAt,
      originalContent: originalContent ?? this.originalContent,
      forwardedFromId: forwardedFromId ?? this.forwardedFromId,
      repliedToId: repliedToId ?? this.repliedToId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      syncError: syncError ?? this.syncError,
    );
  }
}

/// Pagination metadata for API responses
class PaginationMeta {
  final int page;
  final int perPage;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationMeta({
    required this.page,
    required this.perPage,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      totalCount: json['total_count'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 1,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrev: json['has_prev'] as bool? ?? false,
    );
  }
}

/// Response model for a single message from API
class MessageResponse {
  final String id;
  final String senderId;
  final String? recipientId;
  final String? groupId;
  final String content;
  final String messageType;
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final String? attachmentMimeType;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool isRead;
  final String? readAt;
  final String? deliveredAt;
  final String? editedAt;
  final String? originalContent;
  final String? forwardedFromId;
  final String? repliedToId;
  final String createdAt;
  final String updatedAt;

  MessageResponse({
    required this.id,
    required this.senderId,
    this.recipientId,
    this.groupId,
    required this.content,
    required this.messageType,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.attachmentMimeType,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.isRead,
    this.readAt,
    this.deliveredAt,
    this.editedAt,
    this.originalContent,
    this.forwardedFromId,
    this.repliedToId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      recipientId: json['recipient_id'] as String?,
      groupId: json['group_id'] as String?,
      content: json['content'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'text',
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentSize: json['attachment_size'] as int?,
      attachmentMimeType: json['attachment_mime_type'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['location_name'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      editedAt: json['edited_at'] as String?,
      originalContent: json['original_content'] as String?,
      forwardedFromId: json['forwarded_from_id'] as String?,
      repliedToId: json['replied_to_id'] as String?,
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Convert to local Message model for database storage
  Message toLocal({bool pendingSync = false, String? syncError}) {
    return Message(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      groupId: groupId,
      content: content,
      messageType: messageType,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
      attachmentMimeType: attachmentMimeType,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      isRead: isRead,
      readAt: readAt != null ? DateTime.tryParse(readAt!) : null,
      deliveredAt: deliveredAt != null ? DateTime.tryParse(deliveredAt!) : null,
      editedAt: editedAt != null ? DateTime.tryParse(editedAt!) : null,
      originalContent: originalContent,
      forwardedFromId: forwardedFromId,
      repliedToId: repliedToId,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
      pendingSync: pendingSync,
      syncError: syncError,
    );
  }
}

/// Response model for paginated message list from API
class MessageListResponse {
  final bool success;
  final List<MessageResponse> data;
  final PaginationMeta pagination;

  MessageListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory MessageListResponse.fromJson(Map<String, dynamic> json) {
    return MessageListResponse(
      success: json['success'] as bool? ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) =>
                  MessageResponse.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: PaginationMeta.fromJson(
          json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Response model for message group from API
class MessageGroupResponse {
  final String id;
  final String name;
  final String? description;
  final String? groupType;
  final String? avatarUrl;
  final bool isActive;
  final bool allowMemberMessages;
  final String createdById;
  final String createdAt;
  final String updatedAt;
  final int memberCount;

  MessageGroupResponse({
    required this.id,
    required this.name,
    this.description,
    this.groupType,
    this.avatarUrl,
    required this.isActive,
    required this.allowMemberMessages,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    required this.memberCount,
  });

  factory MessageGroupResponse.fromJson(Map<String, dynamic> json) {
    return MessageGroupResponse(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      groupType: json['group_type'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      allowMemberMessages: json['allow_member_messages'] as bool? ?? true,
      createdById: json['created_by_id'] as String? ?? '',
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  /// Convert to local MessageGroup model for database storage
  MessageGroup toLocal({bool pendingSync = false, String? syncError}) {
    return MessageGroup(
      id: id,
      name: name,
      description: description,
      groupType: groupType,
      avatarUrl: avatarUrl,
      isActive: isActive,
      allowMemberMessages: allowMemberMessages,
      createdById: createdById,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
      memberCount: memberCount,
      pendingSync: pendingSync,
      syncError: syncError,
    );
  }
}

/// Response for simple success/failure operations
class MessageOperationResponse {
  final String message;
  final bool success;

  MessageOperationResponse({
    required this.message,
    required this.success,
  });

  factory MessageOperationResponse.fromJson(Map<String, dynamic> json) {
    return MessageOperationResponse(
      message: json['message'] as String? ?? 'Operation completed',
      success: json['success'] as bool? ?? true,
    );
  }
}

/// Response for unread count
class UnreadCountResponse {
  final int count;
  final Map<String, int>? byConversation;
  final Map<String, int>? byGroup;

  UnreadCountResponse({
    required this.count,
    this.byConversation,
    this.byGroup,
  });

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    // The API returns an object with counts - we'll parse what we can
    int totalCount = 0;
    Map<String, int>? byConv;
    Map<String, int>? byGrp;

    // Try to extract total count or sum up individual counts
    if (json.containsKey('count')) {
      totalCount = json['count'] as int? ?? 0;
    } else if (json.containsKey('total')) {
      totalCount = json['total'] as int? ?? 0;
    } else {
      // Sum up all values if it's just a flat object of counts
      for (final value in json.values) {
        if (value is int) {
          totalCount += value;
        } else if (value is Map) {
          // Nested structure
        }
      }
    }

    return UnreadCountResponse(
      count: totalCount,
      byConversation: byConv,
      byGroup: byGrp,
    );
  }
}

/// Validation error from API
class MessageValidationError {
  final String type;
  final List<String> loc;
  final String msg;
  final dynamic input;

  MessageValidationError({
    required this.type,
    required this.loc,
    required this.msg,
    this.input,
  });

  factory MessageValidationError.fromJson(Map<String, dynamic> json) {
    return MessageValidationError(
      type: json['type'] as String? ?? '',
      loc: (json['loc'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      msg: json['msg'] as String? ?? '',
      input: json['input'],
    );
  }
}

/// Exception for message API errors
class MessageApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
  final List<MessageValidationError>? validationErrors;

  MessageApiException(this.message,
      {this.statusCode, this.errors, this.validationErrors});

  @override
  String toString() => 'MessageApiException: $message (status: $statusCode)';
}

// ==================== MESSAGE GROUPS ====================

/// Request model for creating a message group (POST /api/v1/messages/groups)
class MessageGroupCreateRequest {
  final String name; // Required
  final String? description; // Optional
  final String? groupType; // Optional: chw_team, supervisor_group, etc.
  final List<String> memberIds; // Required: at least 1 member

  MessageGroupCreateRequest({
    required this.name,
    this.description,
    this.groupType,
    required this.memberIds,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'member_ids': memberIds,
    };

    if (description != null) map['description'] = description;
    if (groupType != null) map['group_type'] = groupType;

    return map;
  }
}

/// Local MessageGroup model for offline storage with all API response fields
class MessageGroup {
  final String id;
  final String name;
  final String? description;
  final String? groupType;
  final String? avatarUrl;
  final bool isActive;
  final bool allowMemberMessages;
  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;

  // Offline-first fields
  final bool pendingSync;
  final String? syncError;

  MessageGroup({
    required this.id,
    required this.name,
    this.description,
    this.groupType,
    this.avatarUrl,
    required this.isActive,
    required this.allowMemberMessages,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    required this.memberCount,
    this.pendingSync = false,
    this.syncError,
  });

  /// Create from API response
  factory MessageGroup.fromApi(Map<String, dynamic> json) {
    return MessageGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      groupType: json['group_type'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      allowMemberMessages: json['allow_member_messages'] as bool? ?? true,
      createdById: json['created_by_id'] as String,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      memberCount: json['member_count'] as int? ?? 0,
      pendingSync: false,
    );
  }

  /// Create from database map
  factory MessageGroup.fromDb(Map<String, dynamic> map) {
    return MessageGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      groupType: map['group_type'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      allowMemberMessages: (map['allow_member_messages'] as int?) == 1,
      createdById: map['created_by_id'] as String,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      memberCount: map['member_count'] as int? ?? 0,
      pendingSync: (map['pending_sync'] as int?) == 1,
      syncError: map['sync_error'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'group_type': groupType,
      'avatar_url': avatarUrl,
      'is_active': isActive ? 1 : 0,
      'allow_member_messages': allowMemberMessages ? 1 : 0,
      'created_by_id': createdById,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'member_count': memberCount,
      'pending_sync': pendingSync ? 1 : 0,
      'sync_error': syncError,
    };
  }

  /// Create a copy with updated fields
  MessageGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? groupType,
    String? avatarUrl,
    bool? isActive,
    bool? allowMemberMessages,
    String? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
    bool? pendingSync,
    String? syncError,
  }) {
    return MessageGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      groupType: groupType ?? this.groupType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      allowMemberMessages: allowMemberMessages ?? this.allowMemberMessages,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
      pendingSync: pendingSync ?? this.pendingSync,
      syncError: syncError ?? this.syncError,
    );
  }
}
