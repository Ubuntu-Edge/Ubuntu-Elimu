import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/message_models.dart';
import 'auth_service.dart';

/// Message API Service
/// Handles all message-related API calls to the backend
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
/// 
/// Endpoints:
/// - POST   /messages                    - Send a message
/// - GET    /messages                    - List messages
/// - GET    /messages/{id}               - Get message details
/// - PATCH  /messages/{id}               - Edit message
/// - DELETE /messages/{id}               - Delete message
/// - POST   /messages/{id}/mark-read     - Mark single message as read
/// - POST   /messages/mark-read          - Mark multiple messages as read
/// - GET    /messages/unread-count       - Get unread message count
/// - POST   /messages/{id}/archive       - Archive a message
/// - GET    /messages/groups             - List message groups
/// - POST   /messages/groups             - Create a message group
/// - GET    /messages/groups/{id}        - Get group details
/// - POST   /messages/groups/{id}/members - Add members to group
/// - DELETE /messages/groups/{id}/members/{user_id} - Remove member from group
class MessageApiService {
  static final MessageApiService instance = MessageApiService._internal();
  MessageApiService._internal();

  static const String _baseUrl = 'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Send a new message (POST /messages)
  /// Required: content
  /// Required (one of): recipient_id OR group_id
  Future<MessageResponse> sendMessage(MessageCreateRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => MessageValidationError.fromJson(e as Map<String, dynamic>))
            .toList();
        throw MessageApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to send message: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error sending message: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// List messages with optional filters (GET /messages)
  /// Filters: page, per_page, conversation_with, group_id, unread_only
  Future<MessageListResponse> listMessages({
    int page = 1,
    int perPage = 50,
    String? conversationWith,
    String? groupId,
    bool? unreadOnly,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (conversationWith != null && conversationWith.isNotEmpty) {
        queryParams['conversation_with'] = conversationWith;
      }
      if (groupId != null && groupId.isNotEmpty) {
        queryParams['group_id'] = groupId;
      }
      if (unreadOnly != null) {
        queryParams['unread_only'] = unreadOnly.toString();
      }

      final uri = Uri.parse('$_baseUrl/messages').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to list messages: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error listing messages: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Get message details by ID (GET /messages/{message_id})
  Future<MessageResponse> getMessage(String messageId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/messages/$messageId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw MessageApiException('Message not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to get message: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error getting message: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Edit a message (PATCH /messages/{message_id})
  /// Only sender can edit their own messages
  Future<MessageResponse> editMessage(String messageId, MessageUpdateRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/messages/$messageId'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw MessageApiException('Message not found', statusCode: 404);
      } else if (response.statusCode == 403) {
        throw MessageApiException('Not authorized to edit this message', statusCode: 403);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => MessageValidationError.fromJson(e as Map<String, dynamic>))
            .toList();
        throw MessageApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to edit message: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error editing message: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Delete a message (DELETE /messages/{message_id})
  /// Only sender can delete their own messages
  Future<MessageOperationResponse> deleteMessage(String messageId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/messages/$messageId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageOperationResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw MessageApiException('Message not found', statusCode: 404);
      } else if (response.statusCode == 403) {
        throw MessageApiException('Not authorized to delete this message', statusCode: 403);
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to delete message: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error deleting message: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Mark a single message as read (POST /messages/{message_id}/mark-read)
  Future<MessageOperationResponse> markMessageAsRead(String messageId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/$messageId/mark-read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageOperationResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw MessageApiException('Message not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to mark message as read: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error marking message as read: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Mark multiple messages as read (POST /messages/mark-read)
  /// Request body: Array of message UUIDs
  Future<MessageOperationResponse> markMultipleMessagesAsRead(List<String> messageIds) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/mark-read'),
        headers: headers,
        body: jsonEncode(messageIds),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageOperationResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw MessageApiException(
          'Validation error: ${errorData['detail']}',
          statusCode: 422,
        );
      } else {
        throw MessageApiException(
          'Failed to mark messages as read: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error marking messages as read: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Get unread message count (GET /messages/unread-count)
  Future<UnreadCountResponse> getUnreadCount() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/messages/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UnreadCountResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to get unread count: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error getting unread count: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Archive a message (POST /messages/{message_id}/archive)
  /// Soft delete for current user
  Future<MessageResponse> archiveMessage(String messageId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/$messageId/archive'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw MessageApiException('Message not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to archive message: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error archiving message: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  // ==================== GROUP OPERATIONS ====================

  /// List all message groups for current user (GET /messages/groups)
  Future<List<MessageGroupResponse>> listGroups() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/messages/groups'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((item) => MessageGroupResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to list groups: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error listing groups: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Create a new message group (POST /messages/groups)
  /// Required: name, member_ids (at least 1)
  /// Optional: description, group_type
  Future<MessageGroupResponse> createGroup(MessageGroupCreateRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/groups'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageGroupResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => MessageValidationError.fromJson(e as Map<String, dynamic>))
            .toList();
        throw MessageApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to create group: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error creating group: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Get group details by ID (GET /messages/groups/{group_id})
  Future<MessageGroupResponse> getGroup(String groupId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/messages/groups/$groupId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageGroupResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw MessageApiException('Group not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to get group: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error getting group: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Add members to a group (POST /messages/groups/{group_id}/members)
  /// Only admins can add members
  /// Request body: Array of user UUIDs
  Future<MessageGroupResponse> addGroupMembers(String groupId, List<String> memberIds) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/groups/$groupId/members'),
        headers: headers,
        body: jsonEncode(memberIds),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageGroupResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw MessageApiException('Group not found', statusCode: 404);
      } else if (response.statusCode == 403) {
        throw MessageApiException('Not authorized to add members', statusCode: 403);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw MessageApiException(
          'Validation error: ${errorData['detail']}',
          statusCode: 422,
        );
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to add members: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error adding group members: $e');
      throw MessageApiException('Network error: $e');
    }
  }

  /// Remove a member from a group (DELETE /messages/groups/{group_id}/members/{user_id})
  /// Admins can remove anyone, users can remove themselves
  Future<MessageOperationResponse> removeGroupMember(String groupId, String userId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/messages/groups/$groupId/members/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MessageOperationResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw MessageApiException('Group or member not found', statusCode: 404);
      } else if (response.statusCode == 403) {
        throw MessageApiException('Not authorized to remove member', statusCode: 403);
      } else if (response.statusCode == 401) {
        throw MessageApiException('Unauthorized', statusCode: 401);
      } else {
        throw MessageApiException(
          'Failed to remove member: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is MessageApiException) rethrow;
      debugPrint('Error removing group member: $e');
      throw MessageApiException('Network error: $e');
    }
  }
}
