import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/message_models.dart';
import '../services/database_service.dart';
import '../services/message_api_service.dart';
import '../services/connectivity_service.dart';

/// MessageProvider - Manages messaging with offline-first approach
///
/// Features:
/// - Direct messaging between users
/// - Group messaging
/// - Offline-first: works offline, syncs when online
/// - Real-time message status updates
/// - Unread message tracking
class MessageProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final MessageApiService _messageApi = MessageApiService.instance;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final _uuid = const Uuid();

  // State
  List<Message> _messages = [];
  List<Message> _unreadMessages = [];
  List<MessageGroup> _groups = [];
  final Map<String, List<Message>> _conversationCache = {};
  int _unreadCount = 0;

  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  // Getters
  List<Message> get messages => _messages;
  List<Message> get unreadMessages => _unreadMessages;
  List<MessageGroup> get groups => _groups;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _connectivity.isOnline;
  String? get currentUserId => _currentUserId;

  /// Initialize the provider with current user ID
  void initialize(String userId) {
    _currentUserId = userId;
    debugPrint('MessageProvider initialized for user: $userId');
  }

  /// Load all messages for the current user
  /// Uses offline-first approach:
  /// - If online: fetches from API and syncs to local DB
  /// - If offline: loads from local DB only
  Future<void> loadMessages() async {
    if (_currentUserId == null) {
      _errorMessage = 'User not initialized';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (isOnline) {
        // Online: Fetch from API
        try {
          final response = await _messageApi.listMessages(perPage: 100);

          // Convert API responses to local Message models
          _messages =
              response.data.map((apiMessage) => apiMessage.toLocal()).toList();

          // Sync to local database
          await _db.syncMessagesFromApi(_messages);

          debugPrint('✅ Loaded ${_messages.length} messages from API');
        } catch (e) {
          debugPrint('❌ API fetch failed: $e, falling back to local DB');
          _messages = await _db.getMessagesForUser(_currentUserId!);
        }
      } else {
        // Offline: Load from local database
        _messages = await _db.getMessagesForUser(_currentUserId!);
        debugPrint(
            '📱 Loaded ${_messages.length} messages from local DB (offline)');
      }

      // Update unread messages
      await _updateUnreadMessages();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
      debugPrint('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for a specific conversation (direct message)
  Future<List<Message>> loadConversation(String otherUserId) async {
    if (_currentUserId == null) return [];

    _isLoading = true;
    notifyListeners();

    try {
      List<Message> conversationMessages;

      if (isOnline) {
        try {
          final response = await _messageApi.listMessages(
            conversationWith: otherUserId,
            perPage: 100,
          );
          conversationMessages = response.data.map((m) => m.toLocal()).toList();

          // Sync to local database
          for (final message in conversationMessages) {
            await _db.createOrUpdateMessage(message);
          }
        } catch (e) {
          debugPrint('❌ API fetch failed: $e, falling back to local DB');
          conversationMessages =
              await _db.getDirectMessages(_currentUserId!, otherUserId);
        }
      } else {
        conversationMessages =
            await _db.getDirectMessages(_currentUserId!, otherUserId);
      }

      _conversationCache[otherUserId] = conversationMessages;
      _errorMessage = null;
      return conversationMessages;
    } catch (e) {
      _errorMessage = 'Failed to load conversation: $e';
      debugPrint('Error loading conversation: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for a group
  Future<List<Message>> loadGroupMessages(String groupId) async {
    _isLoading = true;
    notifyListeners();

    try {
      List<Message> groupMessages;

      if (isOnline) {
        try {
          final response = await _messageApi.listMessages(
            groupId: groupId,
            perPage: 100,
          );
          groupMessages = response.data.map((m) => m.toLocal()).toList();

          // Sync to local database
          for (final message in groupMessages) {
            await _db.createOrUpdateMessage(message);
          }
        } catch (e) {
          debugPrint('❌ API fetch failed: $e, falling back to local DB');
          groupMessages = await _db.getGroupMessages(groupId);
        }
      } else {
        groupMessages = await _db.getGroupMessages(groupId);
      }

      _conversationCache['group_$groupId'] = groupMessages;
      _errorMessage = null;
      return groupMessages;
    } catch (e) {
      _errorMessage = 'Failed to load group messages: $e';
      debugPrint('Error loading group messages: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a message
  /// Uses offline-first approach:
  /// - If online: sends via API, then syncs to local DB
  /// - If offline: saves to local DB with pendingSync flag
  Future<bool> sendMessage(MessageCreateRequest request) async {
    if (_currentUserId == null) {
      _errorMessage = 'User not initialized';
      notifyListeners();
      return false;
    }

    try {
      final now = DateTime.now();

      if (isOnline) {
        // Online: Send via API
        try {
          final response = await _messageApi.sendMessage(request);
          final message = response.toLocal();

          // Save to local database
          await _db.createOrUpdateMessage(message);

          // Update local list
          _messages.insert(0, message);
          _updateConversationCache(message);

          debugPrint('✅ Message sent via API');
          notifyListeners();
          return true;
        } catch (e) {
          debugPrint('❌ API send failed: $e, saving locally');
          // Fall through to offline handling
        }
      }

      // Offline: Save locally with pending sync
      final localMessage = Message(
        id: _uuid.v4(),
        senderId: _currentUserId!,
        recipientId: request.recipientId,
        groupId: request.groupId,
        content: request.content,
        messageType: request.messageType ?? 'text',
        attachmentUrl: request.attachmentUrl,
        attachmentName: request.attachmentName,
        attachmentSize: request.attachmentSize,
        attachmentMimeType: request.attachmentMimeType,
        latitude: request.latitude,
        longitude: request.longitude,
        locationName: request.locationName,
        isRead: false,
        forwardedFromId: request.forwardedFromId,
        repliedToId: request.repliedToId,
        createdAt: now,
        updatedAt: now,
        pendingSync: true,
      );

      await _db.createOrUpdateMessage(localMessage);
      _messages.insert(0, localMessage);
      _updateConversationCache(localMessage);

      debugPrint('📱 Message saved locally (pending sync)');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send message: $e';
      debugPrint('Error sending message: $e');
      notifyListeners();
      return false;
    }
  }

  /// Edit a message
  Future<bool> editMessage(String messageId, String newContent) async {
    try {
      if (isOnline) {
        try {
          final request = MessageUpdateRequest(content: newContent);
          final response = await _messageApi.editMessage(messageId, request);
          final updatedMessage = response.toLocal();

          await _db.createOrUpdateMessage(updatedMessage);
          _updateMessageInLists(updatedMessage);

          debugPrint('✅ Message edited via API');
          notifyListeners();
          return true;
        } catch (e) {
          if (e is MessageApiException && e.statusCode == 403) {
            _errorMessage = 'Not authorized to edit this message';
            notifyListeners();
            return false;
          }
          debugPrint('❌ API edit failed: $e');
        }
      }

      // Offline or API failed: Update locally with pending sync
      final existingMessage = await _db.getMessageById(messageId);
      if (existingMessage == null) {
        _errorMessage = 'Message not found';
        notifyListeners();
        return false;
      }

      final updatedMessage = existingMessage.copyWith(
        content: newContent,
        originalContent: existingMessage.content,
        editedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pendingSync: true,
      );

      await _db.updateMessage(updatedMessage);
      _updateMessageInLists(updatedMessage);

      debugPrint('📱 Message edited locally (pending sync)');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to edit message: $e';
      debugPrint('Error editing message: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      if (isOnline) {
        try {
          await _messageApi.deleteMessage(messageId);
          await _db.deleteMessage(messageId);
          _removeMessageFromLists(messageId);

          debugPrint('✅ Message deleted via API');
          notifyListeners();
          return true;
        } catch (e) {
          if (e is MessageApiException && e.statusCode == 403) {
            _errorMessage = 'Not authorized to delete this message';
            notifyListeners();
            return false;
          }
          debugPrint('❌ API delete failed: $e');
        }
      }

      // Offline: Mark for deletion locally
      await _db.deleteMessage(messageId);
      _removeMessageFromLists(messageId);

      debugPrint('📱 Message deleted locally');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete message: $e';
      debugPrint('Error deleting message: $e');
      notifyListeners();
      return false;
    }
  }

  /// Archive a message
  Future<bool> archiveMessage(String messageId) async {
    try {
      if (isOnline) {
        try {
          await _messageApi.archiveMessage(messageId);
        } catch (e) {
          debugPrint('❌ API archive failed: $e');
        }
      }

      await _db.archiveMessage(messageId);
      _removeMessageFromLists(messageId);

      debugPrint('✅ Message archived');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to archive message: $e';
      debugPrint('Error archiving message: $e');
      notifyListeners();
      return false;
    }
  }

  /// Mark a message as read
  Future<void> markAsRead(String messageId) async {
    try {
      if (isOnline) {
        try {
          await _messageApi.markMessageAsRead(messageId);
        } catch (e) {
          debugPrint('❌ API mark read failed: $e');
        }
      }

      await _db.markMessageAsRead(messageId);

      // Update local state
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }

      await _updateUnreadMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Mark multiple messages as read
  Future<void> markMultipleAsRead(List<String> messageIds) async {
    try {
      if (isOnline) {
        try {
          await _messageApi.markMultipleMessagesAsRead(messageIds);
        } catch (e) {
          debugPrint('❌ API mark multiple read failed: $e');
        }
      }

      await _db.markMultipleMessagesAsRead(messageIds);

      // Update local state
      for (final messageId in messageIds) {
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }

      await _updateUnreadMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    try {
      if (isOnline) {
        try {
          final response = await _messageApi.getUnreadCount();
          _unreadCount = response.count;
          notifyListeners();
          return _unreadCount;
        } catch (e) {
          debugPrint('❌ API unread count failed: $e');
        }
      }

      if (_currentUserId != null) {
        _unreadCount = await _db.getUnreadMessageCount(_currentUserId!);
        notifyListeners();
        return _unreadCount;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // ==================== GROUP OPERATIONS ====================

  /// Load all groups for the current user
  Future<void> loadGroups() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (isOnline) {
        try {
          final apiGroups = await _messageApi.listGroups();
          _groups = apiGroups.map((g) => g.toLocal()).toList();

          // Sync to local database
          await _db.syncMessageGroupsFromApi(_groups);

          debugPrint('✅ Loaded ${_groups.length} groups from API');
        } catch (e) {
          debugPrint('❌ API fetch failed: $e, falling back to local DB');
          _groups = await _db.getMessageGroupsForUser(_currentUserId!);
        }
      } else {
        _groups = await _db.getMessageGroupsForUser(_currentUserId!);
        debugPrint(
            '📱 Loaded ${_groups.length} groups from local DB (offline)');
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load groups: $e';
      debugPrint('Error loading groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new group
  Future<MessageGroup?> createGroup(MessageGroupCreateRequest request) async {
    try {
      final now = DateTime.now();

      if (isOnline) {
        try {
          final response = await _messageApi.createGroup(request);
          final group = response.toLocal();

          await _db.createOrUpdateMessageGroup(group);

          // Add current user as member
          await _db.addGroupMember(group.id, _currentUserId!, role: 'admin');

          _groups.insert(0, group);

          debugPrint('✅ Group created via API');
          notifyListeners();
          return group;
        } catch (e) {
          debugPrint('❌ API create group failed: $e');
        }
      }

      // Offline: Create locally
      final localGroup = MessageGroup(
        id: _uuid.v4(),
        name: request.name,
        description: request.description,
        groupType: request.groupType,
        isActive: true,
        allowMemberMessages: true,
        createdById: _currentUserId!,
        createdAt: now,
        updatedAt: now,
        memberCount: request.memberIds.length + 1, // +1 for creator
        pendingSync: true,
      );

      await _db.createOrUpdateMessageGroup(localGroup);

      // Add current user as admin
      await _db.addGroupMember(localGroup.id, _currentUserId!, role: 'admin');

      // Add other members
      for (final memberId in request.memberIds) {
        await _db.addGroupMember(localGroup.id, memberId);
      }

      _groups.insert(0, localGroup);

      debugPrint('📱 Group created locally (pending sync)');
      notifyListeners();
      return localGroup;
    } catch (e) {
      _errorMessage = 'Failed to create group: $e';
      debugPrint('Error creating group: $e');
      notifyListeners();
      return null;
    }
  }

  /// Get group details
  Future<MessageGroup?> getGroupDetails(String groupId) async {
    try {
      if (isOnline) {
        try {
          final response = await _messageApi.getGroup(groupId);
          final group = response.toLocal();

          await _db.createOrUpdateMessageGroup(group);

          // Update in local list
          final index = _groups.indexWhere((g) => g.id == groupId);
          if (index != -1) {
            _groups[index] = group;
          } else {
            _groups.add(group);
          }

          notifyListeners();
          return group;
        } catch (e) {
          debugPrint('❌ API get group failed: $e');
        }
      }

      return await _db.getMessageGroupById(groupId);
    } catch (e) {
      debugPrint('Error getting group details: $e');
      return null;
    }
  }

  /// Add members to a group
  Future<bool> addGroupMembers(String groupId, List<String> memberIds) async {
    try {
      if (isOnline) {
        try {
          await _messageApi.addGroupMembers(groupId, memberIds);
        } catch (e) {
          if (e is MessageApiException && e.statusCode == 403) {
            _errorMessage = 'Not authorized to add members';
            notifyListeners();
            return false;
          }
          debugPrint('❌ API add members failed: $e');
        }
      }

      // Add locally
      for (final memberId in memberIds) {
        await _db.addGroupMember(groupId, memberId);
      }

      // Reload group to get updated member count
      await getGroupDetails(groupId);

      debugPrint('✅ Members added to group');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add members: $e';
      debugPrint('Error adding members: $e');
      notifyListeners();
      return false;
    }
  }

  /// Remove a member from a group
  Future<bool> removeGroupMember(String groupId, String userId) async {
    try {
      if (isOnline) {
        try {
          await _messageApi.removeGroupMember(groupId, userId);
        } catch (e) {
          if (e is MessageApiException && e.statusCode == 403) {
            _errorMessage = 'Not authorized to remove member';
            notifyListeners();
            return false;
          }
          debugPrint('❌ API remove member failed: $e');
        }
      }

      await _db.removeGroupMember(groupId, userId);

      // Reload group to get updated member count
      await getGroupDetails(groupId);

      debugPrint('✅ Member removed from group');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove member: $e';
      debugPrint('Error removing member: $e');
      notifyListeners();
      return false;
    }
  }

  /// Leave a group (remove self)
  Future<bool> leaveGroup(String groupId) async {
    if (_currentUserId == null) return false;

    final success = await removeGroupMember(groupId, _currentUserId!);
    if (success) {
      _groups.removeWhere((g) => g.id == groupId);
      notifyListeners();
    }
    return success;
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sync pending messages to server
  Future<void> syncPendingMessages() async {
    if (!isOnline) return;

    try {
      final pendingMessages = await _db.getPendingSyncMessages();

      for (final message in pendingMessages) {
        try {
          final request = MessageCreateRequest(
            content: message.content,
            recipientId: message.recipientId,
            groupId: message.groupId,
            messageType: message.messageType,
            attachmentUrl: message.attachmentUrl,
            attachmentName: message.attachmentName,
            attachmentSize: message.attachmentSize,
            attachmentMimeType: message.attachmentMimeType,
            latitude: message.latitude,
            longitude: message.longitude,
            locationName: message.locationName,
            forwardedFromId: message.forwardedFromId,
            repliedToId: message.repliedToId,
          );

          final response = await _messageApi.sendMessage(request);

          // Update local message with server ID and mark as synced
          await _db.markMessageSynced(message.id, newId: response.id);

          debugPrint('✅ Synced pending message: ${message.id}');
        } catch (e) {
          debugPrint('❌ Failed to sync message ${message.id}: $e');
          // Update sync error
          await _db.updateMessage(message.copyWith(syncError: e.toString()));
        }
      }
    } catch (e) {
      debugPrint('Error syncing pending messages: $e');
    }
  }

  /// Sync pending groups to server
  Future<void> syncPendingGroups() async {
    if (!isOnline) return;

    try {
      final pendingGroups = await _db.getPendingSyncMessageGroups();

      for (final group in pendingGroups) {
        try {
          final members = await _db.getGroupMembers(group.id);
          final memberIds = members.map((m) => m['user_id'] as String).toList();

          final request = MessageGroupCreateRequest(
            name: group.name,
            description: group.description,
            groupType: group.groupType,
            memberIds: memberIds,
          );

          final response = await _messageApi.createGroup(request);

          // Update local group with server ID and mark as synced
          await _db.markMessageGroupSynced(group.id, newId: response.id);

          debugPrint('✅ Synced pending group: ${group.id}');
        } catch (e) {
          debugPrint('❌ Failed to sync group ${group.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error syncing pending groups: $e');
    }
  }

  /// Full sync - sync all pending items
  Future<void> fullSync() async {
    if (!isOnline) return;

    await syncPendingGroups();
    await syncPendingMessages();
    await loadMessages();
    await loadGroups();
  }

  // ==================== HELPER METHODS ====================

  Future<void> _updateUnreadMessages() async {
    if (_currentUserId == null) return;

    _unreadMessages = await _db.getUnreadMessages(_currentUserId!);
    _unreadCount = _unreadMessages.length;
  }

  void _updateConversationCache(Message message) {
    final cacheKey = message.groupId != null
        ? 'group_${message.groupId}'
        : (message.recipientId ?? message.senderId);

    if (_conversationCache.containsKey(cacheKey)) {
      _conversationCache[cacheKey]!.insert(0, message);
    }
  }

  void _updateMessageInLists(Message message) {
    // Update in main list
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      _messages[index] = message;
    }

    // Update in conversation cache
    for (final key in _conversationCache.keys) {
      final convIndex =
          _conversationCache[key]!.indexWhere((m) => m.id == message.id);
      if (convIndex != -1) {
        _conversationCache[key]![convIndex] = message;
      }
    }
  }

  void _removeMessageFromLists(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    _unreadMessages.removeWhere((m) => m.id == messageId);

    for (final key in _conversationCache.keys) {
      _conversationCache[key]!.removeWhere((m) => m.id == messageId);
    }
  }

  /// Clear all cached data (for logout)
  void clearData() {
    _messages.clear();
    _unreadMessages.clear();
    _groups.clear();
    _conversationCache.clear();
    _unreadCount = 0;
    _currentUserId = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
