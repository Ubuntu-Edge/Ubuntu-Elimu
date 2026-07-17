import 'dart:convert';

/// Enhanced message types for rich messaging
enum MessageType {
  text,
  image,
  audio,
  video,
  location,
  file,
  call, // Voice/video call notification
  systemMessage, // System notifications
}

/// Message status for delivery tracking
enum MessageStatus {
  sending, // Message is being sent
  sent, // Message sent to server
  delivered, // Message delivered to recipient
  read, // Message read by recipient
  failed, // Failed to send
  queued, // Queued for offline sending
}

/// Call types
enum CallType {
  voice,
  video,
  groupVoice,
  groupVideo,
}

/// Call status
enum CallStatus {
  ringing,
  answered,
  ended,
  missed,
  declined,
  busy,
}

/// Enhanced message model with support for multimedia, calls, and location
class EnhancedMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String? recipientId;
  final String? groupId;
  final MessageType type;
  final String? textContent;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final int? mediaDuration; // For audio/video in seconds
  final int? mediaSize; // File size in bytes
  final String? mimeType;
  final LocationData? location;
  final CallData? callData;
  final String? replyToMessageId;
  final String? forwardedFromId;
  final String? forwardedFromName;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? editedAt;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final bool isDeleted;
  final Map<String, dynamic>? metadata;

  EnhancedMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.recipientId,
    this.groupId,
    required this.type,
    this.textContent,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaDuration,
    this.mediaSize,
    this.mimeType,
    this.location,
    this.callData,
    this.replyToMessageId,
    this.forwardedFromId,
    this.forwardedFromName,
    this.status = MessageStatus.sending,
    required this.timestamp,
    this.editedAt,
    this.readAt,
    this.deliveredAt,
    this.isDeleted = false,
    this.metadata,
  });

  /// Check if message is a media message
  bool get isMediaMessage =>
      type == MessageType.image ||
      type == MessageType.audio ||
      type == MessageType.video ||
      type == MessageType.file;

  /// Check if message is pending sync (offline)
  bool get isPendingSync => status == MessageStatus.queued;

  /// Get display text for the message (for conversation list preview)
  String get previewText {
    switch (type) {
      case MessageType.text:
        return textContent ?? '';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.audio:
        return '🎵 Voice message';
      case MessageType.video:
        return '🎬 Video';
      case MessageType.location:
        return '📍 Location';
      case MessageType.file:
        return '📎 File';
      case MessageType.call:
        if (callData != null) {
          final callIcon = callData!.type == CallType.video ? '📹' : '📞';
          switch (callData!.status) {
            case CallStatus.missed:
              return '$callIcon Missed call';
            case CallStatus.ended:
              return '$callIcon Call ended (${_formatDuration(callData!.duration ?? 0)})';
            case CallStatus.declined:
              return '$callIcon Call declined';
            default:
              return '$callIcon Call';
          }
        }
        return '📞 Call';
      case MessageType.systemMessage:
        return textContent ?? 'System message';
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'recipient_id': recipientId,
      'group_id': groupId,
      'type': type.name,
      'text_content': textContent,
      'media_url': mediaUrl,
      'media_thumbnail_url': mediaThumbnailUrl,
      'media_duration': mediaDuration,
      'media_size': mediaSize,
      'mime_type': mimeType,
      'location': location?.toMap(),
      'call_data': callData?.toMap(),
      'reply_to_message_id': replyToMessageId,
      'forwarded_from_id': forwardedFromId,
      'forwarded_from_name': forwardedFromName,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  factory EnhancedMessage.fromMap(Map<String, dynamic> map) {
    return EnhancedMessage(
      id: map['id'],
      senderId: map['sender_id'],
      senderName: map['sender_name'],
      senderAvatar: map['sender_avatar'],
      recipientId: map['recipient_id'],
      groupId: map['group_id'],
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      textContent: map['text_content'],
      mediaUrl: map['media_url'],
      mediaThumbnailUrl: map['media_thumbnail_url'],
      mediaDuration: map['media_duration'],
      mediaSize: map['media_size'],
      mimeType: map['mime_type'],
      location: map['location'] != null
          ? LocationData.fromMap(map['location'] is String
              ? jsonDecode(map['location'])
              : map['location'])
          : null,
      callData: map['call_data'] != null
          ? CallData.fromMap(map['call_data'] is String
              ? jsonDecode(map['call_data'])
              : map['call_data'])
          : null,
      replyToMessageId: map['reply_to_message_id'],
      forwardedFromId: map['forwarded_from_id'],
      forwardedFromName: map['forwarded_from_name'],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      editedAt:
          map['edited_at'] != null ? DateTime.parse(map['edited_at']) : null,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.parse(map['delivered_at'])
          : null,
      isDeleted: map['is_deleted'] == 1,
      metadata: map['metadata'] != null
          ? (map['metadata'] is String
              ? jsonDecode(map['metadata'])
              : map['metadata'])
          : null,
    );
  }

  EnhancedMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? recipientId,
    String? groupId,
    MessageType? type,
    String? textContent,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    int? mediaDuration,
    int? mediaSize,
    String? mimeType,
    LocationData? location,
    CallData? callData,
    String? replyToMessageId,
    String? forwardedFromId,
    String? forwardedFromName,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? editedAt,
    DateTime? readAt,
    DateTime? deliveredAt,
    bool? isDeleted,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      recipientId: recipientId ?? this.recipientId,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      textContent: textContent ?? this.textContent,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      mediaSize: mediaSize ?? this.mediaSize,
      mimeType: mimeType ?? this.mimeType,
      location: location ?? this.location,
      callData: callData ?? this.callData,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      forwardedFromId: forwardedFromId ?? this.forwardedFromId,
      forwardedFromName: forwardedFromName ?? this.forwardedFromName,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Location data for location sharing
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;
  final double? accuracy;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
    this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'place_name': placeName,
      'accuracy': accuracy,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'],
      placeName: map['place_name'],
      accuracy:
          map['accuracy'] != null ? (map['accuracy'] as num).toDouble() : null,
    );
  }
}

/// Call data for call messages
class CallData {
  final CallType type;
  final CallStatus status;
  final int? duration; // In seconds
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String>? participants; // For group calls

  CallData({
    required this.type,
    required this.status,
    this.duration,
    this.startTime,
    this.endTime,
    this.participants,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'status': status.name,
      'duration': duration,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'participants': participants,
    };
  }

  factory CallData.fromMap(Map<String, dynamic> map) {
    return CallData(
      type: CallType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CallType.voice,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CallStatus.ended,
      ),
      duration: map['duration'],
      startTime:
          map['start_time'] != null ? DateTime.parse(map['start_time']) : null,
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      participants: map['participants'] != null
          ? List<String>.from(map['participants'])
          : null,
    );
  }
}

/// Enhanced conversation model with online status
class EnhancedConversation {
  final String id;
  final String name;
  final String? avatar;
  final bool isGroup;
  final String type; // 'supervisor', 'chw', 'partner', 'group'
  final EnhancedMessage? lastMessage;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isMuted;
  final bool isPinned;
  final List<String>? memberIds; // For groups
  final DateTime? createdAt;

  EnhancedConversation({
    required this.id,
    required this.name,
    this.avatar,
    this.isGroup = false,
    required this.type,
    this.lastMessage,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeen,
    this.isMuted = false,
    this.isPinned = false,
    this.memberIds,
    this.createdAt,
  });

  /// Get online status text
  String get onlineStatusText {
    if (isGroup) {
      final memberCount = memberIds?.length ?? 0;
      return '$memberCount members';
    }
    if (isOnline) return 'Online';
    if (lastSeen != null) {
      final diff = DateTime.now().difference(lastSeen!);
      if (diff.inMinutes < 60) {
        return 'Last seen ${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return 'Last seen ${diff.inHours}h ago';
      } else {
        return 'Last seen ${diff.inDays}d ago';
      }
    }
    return 'Offline';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'is_group': isGroup ? 1 : 0,
      'type': type,
      'last_message': lastMessage?.toMap(),
      'unread_count': unreadCount,
      'is_online': isOnline ? 1 : 0,
      'last_seen': lastSeen?.toIso8601String(),
      'is_muted': isMuted ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'member_ids': memberIds != null ? jsonEncode(memberIds) : null,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory EnhancedConversation.fromMap(Map<String, dynamic> map) {
    return EnhancedConversation(
      id: map['id'],
      name: map['name'],
      avatar: map['avatar'],
      isGroup: map['is_group'] == 1,
      type: map['type'],
      lastMessage: map['last_message'] != null
          ? EnhancedMessage.fromMap(map['last_message'] is String
              ? jsonDecode(map['last_message'])
              : map['last_message'])
          : null,
      unreadCount: map['unread_count'] ?? 0,
      isOnline: map['is_online'] == 1,
      lastSeen:
          map['last_seen'] != null ? DateTime.parse(map['last_seen']) : null,
      isMuted: map['is_muted'] == 1,
      isPinned: map['is_pinned'] == 1,
      memberIds: map['member_ids'] != null
          ? List<String>.from(map['member_ids'] is String
              ? jsonDecode(map['member_ids'])
              : map['member_ids'])
          : null,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  EnhancedConversation copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isGroup,
    String? type,
    EnhancedMessage? lastMessage,
    int? unreadCount,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isMuted,
    bool? isPinned,
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return EnhancedConversation(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isGroup: isGroup ?? this.isGroup,
      type: type ?? this.type,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Offline message queue item
class OfflineMessageQueueItem {
  final String id;
  final EnhancedMessage message;
  final DateTime queuedAt;
  final int retryCount;
  final String? lastError;

  OfflineMessageQueueItem({
    required this.id,
    required this.message,
    required this.queuedAt,
    this.retryCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': jsonEncode(message.toMap()),
      'queued_at': queuedAt.toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  factory OfflineMessageQueueItem.fromMap(Map<String, dynamic> map) {
    return OfflineMessageQueueItem(
      id: map['id'],
      message: EnhancedMessage.fromMap(jsonDecode(map['message'])),
      queuedAt: DateTime.parse(map['queued_at']),
      retryCount: map['retry_count'] ?? 0,
      lastError: map['last_error'],
    );
  }
}
