/// Notification API Service
/// Handles in-app notifications (different from NotificationService for local notifications)
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Notification Type Enum (from API spec)
enum NotificationType {
  task,
  alert,
  message,
  reminder,
  system,
  other,
  // Legacy mappings
  followup,
  sync,
  referral,
}

/// Notification Priority Enum (from API spec)
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// App Notification Model (matches API response)
class AppNotification {
  final String id;
  final String userId;
  final String notificationType;
  final String title;
  final String message;
  final String priority;
  final String? actionUrl;
  final Map<String, dynamic>? actionData;
  final Map<String, dynamic>? notificationMetadata;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.priority = 'normal',
    this.actionUrl,
    this.actionData,
    this.notificationMetadata,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['chw_id'] ?? '',
      notificationType: json['notification_type'] ?? json['type'] ?? 'system',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'normal',
      actionUrl: json['action_url'],
      actionData: json['action_data'] != null
          ? Map<String, dynamic>.from(json['action_data'])
          : null,
      notificationMetadata: json['notification_metadata'] != null
          ? Map<String, dynamic>.from(json['notification_metadata'])
          : (json['metadata'] != null
              ? Map<String, dynamic>.from(json['metadata'])
              : null),
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Get type as enum
  NotificationType get type {
    switch (notificationType.toLowerCase()) {
      case 'task':
        return NotificationType.task;
      case 'alert':
        return NotificationType.alert;
      case 'message':
        return NotificationType.message;
      case 'reminder':
        return NotificationType.reminder;
      case 'system':
        return NotificationType.system;
      case 'followup':
        return NotificationType.followup;
      case 'sync':
        return NotificationType.sync;
      case 'referral':
        return NotificationType.referral;
      case 'other':
      default:
        return NotificationType.other;
    }
  }

  /// Get type string for display
  String get typeLabel {
    switch (type) {
      case NotificationType.task:
        return 'Task';
      case NotificationType.alert:
        return 'Alert';
      case NotificationType.message:
        return 'Message';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.system:
        return 'System';
      case NotificationType.followup:
        return 'Follow-up';
      case NotificationType.sync:
        return 'Sync';
      case NotificationType.referral:
        return 'Referral';
      case NotificationType.other:
        return 'Other';
    }
  }

  bool get isUnread => !isRead;
  Duration get age => DateTime.now().difference(createdAt);

  String get timeAgo {
    final duration = age;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Notification List Response (matches API spec)
class NotificationListResponse {
  final List<AppNotification> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  NotificationListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      items: (json['items'] as List<dynamic>? ??
              json['data'] as List<dynamic>? ??
              [])
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] ?? json['pagination']?['total_count'] ?? 0,
      page: json['page'] ?? json['pagination']?['page'] ?? 1,
      perPage: json['per_page'] ?? json['pagination']?['per_page'] ?? 20,
      totalPages:
          json['total_pages'] ?? json['pagination']?['total_pages'] ?? 1,
    );
  }

  /// For backwards compatibility
  List<AppNotification> get data => items;
  int get totalCount => total;
  int get unreadCount => items.where((n) => !n.isRead).length;
}

/// Unread Count Response (matches API spec)
class UnreadCountResponse {
  final int unreadCount;
  final int totalCount;

  UnreadCountResponse({
    required this.unreadCount,
    required this.totalCount,
  });

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: json['unread_count'] ?? json['count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
    );
  }
}

/// Notification API Exception
class NotificationApiException implements Exception {
  final String message;
  final int? statusCode;

  NotificationApiException(this.message, {this.statusCode});

  @override
  String toString() => 'NotificationApiException: $message';
}

/// Notification API Service
class NotificationApiService {
  static final NotificationApiService instance =
      NotificationApiService._internal();
  NotificationApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Get notifications
  /// GET /notifications?is_read={bool}&notification_type={type}&page={page}&per_page={perPage}
  Future<NotificationListResponse> getNotifications({
    bool? isRead,
    String? notificationType,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (isRead != null) queryParams['is_read'] = isRead.toString();
      if (notificationType != null)
        queryParams['notification_type'] = notificationType;

      final uri = Uri.parse('$_baseUrl/notifications')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw NotificationApiException('Unauthorized', statusCode: 401);
      } else {
        throw NotificationApiException(
          'Failed to get notifications: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NotificationApiException) rethrow;
      debugPrint('Error getting notifications: $e');
      throw NotificationApiException('Network error: $e');
    }
  }

  /// Get notification by ID
  /// GET /notifications/{notification_id}
  Future<AppNotification> getNotification(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/$notificationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppNotification.fromJson(data);
      } else if (response.statusCode == 404) {
        throw NotificationApiException('Notification not found',
            statusCode: 404);
      } else if (response.statusCode == 401) {
        throw NotificationApiException('Unauthorized', statusCode: 401);
      } else {
        throw NotificationApiException(
          'Failed to get notification: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NotificationApiException) rethrow;
      debugPrint('Error getting notification: $e');
      throw NotificationApiException('Network error: $e');
    }
  }

  /// Mark notification as read
  /// PATCH /notifications/{notification_id}/read
  Future<AppNotification> markAsRead(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppNotification.fromJson(data);
      } else if (response.statusCode == 404) {
        throw NotificationApiException('Notification not found',
            statusCode: 404);
      } else if (response.statusCode == 401) {
        throw NotificationApiException('Unauthorized', statusCode: 401);
      } else {
        throw NotificationApiException(
          'Failed to mark notification as read: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NotificationApiException) rethrow;
      debugPrint('Error marking notification as read: $e');
      throw NotificationApiException('Network error: $e');
    }
  }

  /// Mark all notifications as read
  /// PATCH /notifications/mark-all-read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/notifications/mark-all-read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw NotificationApiException('Unauthorized', statusCode: 401);
      } else {
        throw NotificationApiException(
          'Failed to mark all notifications as read: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NotificationApiException) rethrow;
      debugPrint('Error marking all notifications as read: $e');
      throw NotificationApiException('Network error: $e');
    }
  }

  /// Delete notification
  /// DELETE /notifications/{notification_id}
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications/$notificationId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw NotificationApiException('Notification not found',
            statusCode: 404);
      } else if (response.statusCode == 401) {
        throw NotificationApiException('Unauthorized', statusCode: 401);
      } else {
        throw NotificationApiException(
          'Failed to delete notification: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NotificationApiException) rethrow;
      debugPrint('Error deleting notification: $e');
      throw NotificationApiException('Network error: $e');
    }
  }

  /// Delete all read notifications
  /// DELETE /notifications/clear-read
  Future<bool> clearReadNotifications() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications/clear-read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw NotificationApiException('Unauthorized', statusCode: 401);
      } else {
        throw NotificationApiException(
          'Failed to clear read notifications: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NotificationApiException) rethrow;
      debugPrint('Error clearing read notifications: $e');
      throw NotificationApiException('Network error: $e');
    }
  }

  /// Get unread count
  /// GET /notifications/unread-count
  Future<UnreadCountResponse> getUnreadCount() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UnreadCountResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw NotificationApiException('Unauthorized', statusCode: 401);
      } else {
        throw NotificationApiException(
          'Failed to get unread count: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is NotificationApiException) rethrow;
      debugPrint('Error getting unread count: $e');
      throw NotificationApiException('Network error: $e');
    }
  }

  // ============ HELPER METHODS ============

  /// Get unread notifications
  Future<NotificationListResponse> getUnreadNotifications(
      {int page = 1, int perPage = 20}) async {
    return getNotifications(isRead: false, page: page, perPage: perPage);
  }

  /// Get read notifications
  Future<NotificationListResponse> getReadNotifications(
      {int page = 1, int perPage = 20}) async {
    return getNotifications(isRead: true, page: page, perPage: perPage);
  }

  /// Get notifications by type
  Future<NotificationListResponse> getNotificationsByType(
    String notificationType, {
    int page = 1,
    int perPage = 20,
  }) async {
    return getNotifications(
        notificationType: notificationType, page: page, perPage: perPage);
  }

  /// Get alert notifications
  Future<NotificationListResponse> getAlertNotifications(
      {int page = 1, int perPage = 20}) async {
    return getNotifications(
        notificationType: 'alert', page: page, perPage: perPage);
  }

  /// Get task notifications
  Future<NotificationListResponse> getTaskNotifications(
      {int page = 1, int perPage = 20}) async {
    return getNotifications(
        notificationType: 'task', page: page, perPage: perPage);
  }

  /// Get reminder notifications
  Future<NotificationListResponse> getReminderNotifications(
      {int page = 1, int perPage = 20}) async {
    return getNotifications(
        notificationType: 'reminder', page: page, perPage: perPage);
  }
}
