import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/enhanced_message.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

/// Service for handling enhanced messaging features
/// Includes audio messages, image messages, location sharing, and offline queue
class EnhancedMessagingService {
  static final EnhancedMessagingService _instance = EnhancedMessagingService._internal();
  factory EnhancedMessagingService() => _instance;
  EnhancedMessagingService._internal();

  final DatabaseService _db = DatabaseService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final _uuid = const Uuid();

  // Stream controllers for real-time updates
  final _messageStreamController = StreamController<EnhancedMessage>.broadcast();
  final _conversationStreamController = StreamController<List<EnhancedConversation>>.broadcast();
  final _onlineStatusController = StreamController<Map<String, bool>>.broadcast();

  Stream<EnhancedMessage> get messageStream => _messageStreamController.stream;
  Stream<List<EnhancedConversation>> get conversationStream => _conversationStreamController.stream;
  Stream<Map<String, bool>> get onlineStatusStream => _onlineStatusController.stream;

  Timer? _offlineQueueProcessor;
  Timer? _presenceHeartbeat;

  /// Initialize the messaging service
  Future<void> initialize() async {
    // Create necessary tables if they don't exist
    await _createMessagingTables();
    
    // Start offline queue processor
    _startOfflineQueueProcessor();
    
    // Start presence heartbeat
    _startPresenceHeartbeat();
    
    debugPrint('EnhancedMessagingService initialized');
  }

  /// Create messaging tables in database
  Future<void> _createMessagingTables() async {
    final db = await _db.database;
    
    // Enhanced messages table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS enhanced_messages (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        sender_avatar TEXT,
        recipient_id TEXT,
        group_id TEXT,
        type TEXT NOT NULL,
        text_content TEXT,
        media_url TEXT,
        media_thumbnail_url TEXT,
        media_duration INTEGER,
        media_size INTEGER,
        mime_type TEXT,
        location TEXT,
        call_data TEXT,
        reply_to_message_id TEXT,
        forwarded_from_id TEXT,
        forwarded_from_name TEXT,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        edited_at TEXT,
        read_at TEXT,
        delivered_at TEXT,
        is_deleted INTEGER DEFAULT 0,
        metadata TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Enhanced conversations table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS enhanced_conversations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar TEXT,
        is_group INTEGER DEFAULT 0,
        type TEXT NOT NULL,
        last_message TEXT,
        unread_count INTEGER DEFAULT 0,
        is_online INTEGER DEFAULT 0,
        last_seen TEXT,
        is_muted INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        member_ids TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Offline message queue table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_message_queue (
        id TEXT PRIMARY KEY,
        message TEXT NOT NULL,
        queued_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');
    
    // User presence table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_presence (
        user_id TEXT PRIMARY KEY,
        is_online INTEGER DEFAULT 0,
        last_seen TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Create indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_recipient ON enhanced_messages(recipient_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_group ON enhanced_messages(group_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON enhanced_messages(timestamp DESC)');
  }

  /// Send a text message
  Future<EnhancedMessage> sendTextMessage({
    required String recipientId,
    String? groupId,
    required String text,
    required String senderId,
    required String senderName,
    String? replyToMessageId,
  }) async {
    final message = EnhancedMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      recipientId: groupId == null ? recipientId : null,
      groupId: groupId,
      type: MessageType.text,
      textContent: text,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      replyToMessageId: replyToMessageId,
    );
    
    return _sendMessage(message);
  }

  /// Send an audio message
  Future<EnhancedMessage> sendAudioMessage({
    required String recipientId,
    String? groupId,
    required String audioFilePath,
    required int durationSeconds,
    required String senderId,
    required String senderName,
  }) async {
    // Copy audio file to app storage
    final savedPath = await _saveMediaFile(audioFilePath, 'audio');
    
    final message = EnhancedMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      recipientId: groupId == null ? recipientId : null,
      groupId: groupId,
      type: MessageType.audio,
      mediaUrl: savedPath,
      mediaDuration: durationSeconds,
      mimeType: 'audio/m4a',
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
    
    return _sendMessage(message);
  }

  /// Send an image message
  Future<EnhancedMessage> sendImageMessage({
    required String recipientId,
    String? groupId,
    required String imageFilePath,
    String? caption,
    required String senderId,
    required String senderName,
  }) async {
    // Copy image file to app storage
    final savedPath = await _saveMediaFile(imageFilePath, 'images');
    
    // Generate thumbnail (in production, use image package)
    final thumbnailPath = savedPath; // For now, use same path
    
    final file = File(imageFilePath);
    final fileSize = await file.length();
    
    final message = EnhancedMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      recipientId: groupId == null ? recipientId : null,
      groupId: groupId,
      type: MessageType.image,
      textContent: caption,
      mediaUrl: savedPath,
      mediaThumbnailUrl: thumbnailPath,
      mediaSize: fileSize,
      mimeType: 'image/jpeg',
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
    
    return _sendMessage(message);
  }

  /// Send a location message
  Future<EnhancedMessage> sendLocationMessage({
    required String recipientId,
    String? groupId,
    required double latitude,
    required double longitude,
    String? address,
    String? placeName,
    required String senderId,
    required String senderName,
  }) async {
    final message = EnhancedMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      recipientId: groupId == null ? recipientId : null,
      groupId: groupId,
      type: MessageType.location,
      location: LocationData(
        latitude: latitude,
        longitude: longitude,
        address: address,
        placeName: placeName,
      ),
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
    
    return _sendMessage(message);
  }

  /// Record a call event
  Future<EnhancedMessage> recordCallEvent({
    required String recipientId,
    required CallType callType,
    required CallStatus callStatus,
    int? durationSeconds,
    required String senderId,
    required String senderName,
  }) async {
    final message = EnhancedMessage(
      id: _uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      type: MessageType.call,
      callData: CallData(
        type: callType,
        status: callStatus,
        duration: durationSeconds,
        endTime: DateTime.now(),
      ),
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );
    
    return _sendMessage(message);
  }

  /// Internal method to send/save a message
  Future<EnhancedMessage> _sendMessage(EnhancedMessage message) async {
    // Save to local database first
    await _saveMessageLocally(message);
    
    // Emit to stream
    _messageStreamController.add(message);
    
    // Check connectivity
    final isOnline = _connectivity.isOnline;
    
    if (isOnline) {
      // Try to send to server
      try {
        // In production, this would call the API
        // For now, simulate successful send
        final sentMessage = message.copyWith(
          status: MessageStatus.sent,
        );
        await _updateMessageStatus(sentMessage.id, MessageStatus.sent);
        
        // Update conversation
        await _updateConversationLastMessage(sentMessage);
        
        return sentMessage;
      } catch (e) {
        debugPrint('Failed to send message: $e');
        // Queue for offline sending
        await _queueMessageForOfflineSending(message);
        return message.copyWith(status: MessageStatus.queued);
      }
    } else {
      // Queue for offline sending
      await _queueMessageForOfflineSending(message);
      return message.copyWith(status: MessageStatus.queued);
    }
  }

  /// Save message to local database
  Future<void> _saveMessageLocally(EnhancedMessage message) async {
    final db = await _db.database;
    await db.insert('enhanced_messages', message.toMap());
  }

  /// Update message status
  Future<void> _updateMessageStatus(String messageId, MessageStatus status) async {
    final db = await _db.database;
    await db.update(
      'enhanced_messages',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Queue message for offline sending
  Future<void> _queueMessageForOfflineSending(EnhancedMessage message) async {
    final db = await _db.database;
    final queueItem = OfflineMessageQueueItem(
      id: _uuid.v4(),
      message: message,
      queuedAt: DateTime.now(),
    );
    await db.insert('offline_message_queue', queueItem.toMap());
    
    // Update message status to queued
    await _updateMessageStatus(message.id, MessageStatus.queued);
  }

  /// Update conversation with last message
  Future<void> _updateConversationLastMessage(EnhancedMessage message) async {
    final db = await _db.database;
    final conversationId = message.groupId ?? message.recipientId;
    if (conversationId == null) return;
    
    await db.update(
      'enhanced_conversations',
      {
        'last_message': message.toMap().toString(),
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );
    
    // Refresh conversation list
    final conversations = await getConversations();
    _conversationStreamController.add(conversations);
  }

  /// Get all conversations
  Future<List<EnhancedConversation>> getConversations() async {
    final db = await _db.database;
    final results = await db.query(
      'enhanced_conversations',
      orderBy: 'is_pinned DESC, created_at DESC',
    );
    
    return results.map((row) => EnhancedConversation.fromMap(row)).toList();
  }

  /// Get messages for a conversation
  Future<List<EnhancedMessage>> getMessages({
    String? recipientId,
    String? groupId,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _db.database;
    
    String whereClause;
    List<dynamic> whereArgs;
    
    if (groupId != null) {
      whereClause = 'group_id = ?';
      whereArgs = [groupId];
    } else if (recipientId != null) {
      whereClause = '(recipient_id = ? OR sender_id = ?) AND group_id IS NULL';
      whereArgs = [recipientId, recipientId];
    } else {
      return [];
    }
    
    final results = await db.query(
      'enhanced_messages',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    
    return results.map((row) => EnhancedMessage.fromMap(row)).toList();
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    String? recipientId,
    String? groupId,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    
    String whereClause;
    List<dynamic> whereArgs;
    
    if (groupId != null) {
      whereClause = 'group_id = ? AND read_at IS NULL';
      whereArgs = [groupId];
    } else if (recipientId != null) {
      whereClause = 'sender_id = ? AND read_at IS NULL';
      whereArgs = [recipientId];
    } else {
      return;
    }
    
    await db.update(
      'enhanced_messages',
      {
        'read_at': now,
        'status': MessageStatus.read.name,
      },
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    // Update unread count in conversation
    final conversationId = groupId ?? recipientId;
    await db.update(
      'enhanced_conversations',
      {'unread_count': 0},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    final db = await _db.database;
    await db.update(
      'enhanced_messages',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Save media file to app storage
  Future<String> _saveMediaFile(String filePath, String subFolder) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/media/$subFolder');
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    
    final fileName = '${_uuid.v4()}_${filePath.split('/').last}';
    final destinationPath = '${mediaDir.path}/$fileName';
    
    final sourceFile = File(filePath);
    await sourceFile.copy(destinationPath);
    
    return destinationPath;
  }

  /// Start the offline queue processor
  void _startOfflineQueueProcessor() {
    _offlineQueueProcessor?.cancel();
    _offlineQueueProcessor = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _processOfflineQueue();
    });
  }

  /// Process offline message queue
  Future<void> _processOfflineQueue() async {
    final isOnline = _connectivity.isOnline;
    if (!isOnline) return;
    
    final db = await _db.database;
    final queueItems = await db.query(
      'offline_message_queue',
      orderBy: 'queued_at ASC',
      limit: 10,
    );
    
    for (final item in queueItems) {
      try {
        final queueItem = OfflineMessageQueueItem.fromMap(item);
        
        // Try to send the message
        // In production, call API here
        
        // On success, remove from queue and update message status
        await db.delete(
          'offline_message_queue',
          where: 'id = ?',
          whereArgs: [queueItem.id],
        );
        
        await _updateMessageStatus(queueItem.message.id, MessageStatus.sent);
        
        debugPrint('Sent queued message: ${queueItem.message.id}');
      } catch (e) {
        debugPrint('Failed to send queued message: $e');
        
        // Update retry count
        await db.rawUpdate(
          'UPDATE offline_message_queue SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
          [e.toString(), item['id']],
        );
      }
    }
  }

  /// Start presence heartbeat
  void _startPresenceHeartbeat() {
    _presenceHeartbeat?.cancel();
    _presenceHeartbeat = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _updatePresence();
    });
  }

  /// Update user presence
  Future<void> _updatePresence() async {
    // In production, send heartbeat to server
    // For now, just update local timestamp
    debugPrint('Presence heartbeat sent');
  }

  /// Update online status for a user
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    final db = await _db.database;
    
    await db.insert(
      'user_presence',
      {
        'user_id': userId,
        'is_online': isOnline ? 1 : 0,
        'last_seen': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
    
    // Update conversation
    await db.update(
      'enhanced_conversations',
      {
        'is_online': isOnline ? 1 : 0,
        'last_seen': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    // Emit status update
    _onlineStatusController.add({userId: isOnline});
  }

  /// Create or get a conversation
  Future<EnhancedConversation> getOrCreateConversation({
    required String id,
    required String name,
    required String type,
    String? avatar,
    bool isGroup = false,
    List<String>? memberIds,
  }) async {
    final db = await _db.database;
    
    final existing = await db.query(
      'enhanced_conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (existing.isNotEmpty) {
      return EnhancedConversation.fromMap(existing.first);
    }
    
    final conversation = EnhancedConversation(
      id: id,
      name: name,
      avatar: avatar,
      isGroup: isGroup,
      type: type,
      memberIds: memberIds,
      createdAt: DateTime.now(),
    );
    
    await db.insert('enhanced_conversations', conversation.toMap());
    
    return conversation;
  }

  /// Pin/unpin a conversation
  Future<void> togglePinConversation(String conversationId) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE enhanced_conversations SET is_pinned = NOT is_pinned WHERE id = ?',
      [conversationId],
    );
    
    final conversations = await getConversations();
    _conversationStreamController.add(conversations);
  }

  /// Mute/unmute a conversation
  Future<void> toggleMuteConversation(String conversationId) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE enhanced_conversations SET is_muted = NOT is_muted WHERE id = ?',
      [conversationId],
    );
    
    final conversations = await getConversations();
    _conversationStreamController.add(conversations);
  }

  /// Get pending offline messages count
  Future<int> getPendingOfflineMessagesCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM offline_message_queue');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Force sync offline messages
  Future<void> forceSyncOfflineMessages() async {
    await _processOfflineQueue();
  }

  /// Dispose resources
  void dispose() {
    _offlineQueueProcessor?.cancel();
    _presenceHeartbeat?.cancel();
    _messageStreamController.close();
    _conversationStreamController.close();
    _onlineStatusController.close();
  }
}

// Placeholder for Sqflite helper - in production, import from sqflite package
class Sqflite {
  static int? firstIntValue(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return null;
    return results.first.values.first as int?;
  }
}
