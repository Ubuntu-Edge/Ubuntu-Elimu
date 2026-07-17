import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/reminder_models.dart';
import 'auth_service.dart';

/// Reminder API Service
/// Handles all reminder-related API calls to the backend
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
class ReminderApiService {
  static final ReminderApiService instance = ReminderApiService._internal();
  ReminderApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Create a new reminder
  /// POST /reminders
  Future<ReminderResponse> createReminder(ReminderCreateRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/reminders'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReminderResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => ReminderValidationError.fromJson(e))
            .toList();
        throw ReminderApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw ReminderApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReminderApiException(
          'Failed to create reminder: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReminderApiException) rethrow;
      debugPrint('Error creating reminder: $e');
      throw ReminderApiException('Network error: $e');
    }
  }

  /// List reminders with optional filters and pagination
  /// GET /reminders
  Future<ReminderListResponse> listReminders({
    int page = 1,
    int perPage = 20,
    String? type,
    String? priority,
    bool? completed,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (priority != null && priority.isNotEmpty) queryParams['priority'] = priority;
      if (completed != null) queryParams['completed'] = completed.toString();
      if (dateFrom != null && dateFrom.isNotEmpty) queryParams['date_from'] = dateFrom;
      if (dateTo != null && dateTo.isNotEmpty) queryParams['date_to'] = dateTo;

      final uri = Uri.parse('$_baseUrl/reminders').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReminderListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw ReminderApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReminderApiException(
          'Failed to list reminders: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReminderApiException) rethrow;
      debugPrint('Error listing reminders: $e');
      throw ReminderApiException('Network error: $e');
    }
  }

  /// Get reminder details by ID
  /// GET /reminders/{reminder_id}
  Future<ReminderResponse> getReminder(String reminderId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/reminders/$reminderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReminderResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ReminderApiException('Reminder not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw ReminderApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReminderApiException(
          'Failed to get reminder: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReminderApiException) rethrow;
      debugPrint('Error getting reminder: $e');
      throw ReminderApiException('Network error: $e');
    }
  }

  /// Update reminder by ID
  /// PATCH /reminders/{reminder_id}
  Future<ReminderResponse> updateReminder(
    String reminderId,
    ReminderUpdateRequest request,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/reminders/$reminderId'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReminderResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ReminderApiException('Reminder not found', statusCode: 404);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => ReminderValidationError.fromJson(e))
            .toList();
        throw ReminderApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw ReminderApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReminderApiException(
          'Failed to update reminder: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReminderApiException) rethrow;
      debugPrint('Error updating reminder: $e');
      throw ReminderApiException('Network error: $e');
    }
  }

  /// Complete a reminder
  /// POST /reminders/{reminder_id}/complete
  Future<ReminderResponse> completeReminder(
    String reminderId, {
    ReminderCompleteRequest? request,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/reminders/$reminderId/complete'),
        headers: headers,
        body: request != null ? jsonEncode(request.toJson()) : null,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReminderResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ReminderApiException('Reminder not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw ReminderApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReminderApiException(
          'Failed to complete reminder: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReminderApiException) rethrow;
      debugPrint('Error completing reminder: $e');
      throw ReminderApiException('Network error: $e');
    }
  }

  /// Snooze a reminder until a later time
  /// POST /reminders/{reminder_id}/snooze?snooze_until={datetime}
  Future<ReminderResponse> snoozeReminder(
    String reminderId,
    String snoozeUntil, // ISO 8601 format
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/reminders/$reminderId/snooze')
          .replace(queryParameters: {'snooze_until': snoozeUntil});
      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReminderResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ReminderApiException('Reminder not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw ReminderApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReminderApiException(
          'Failed to snooze reminder: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReminderApiException) rethrow;
      debugPrint('Error snoozing reminder: $e');
      throw ReminderApiException('Network error: $e');
    }
  }

  /// Delete reminder by ID
  /// DELETE /reminders/{reminder_id}
  Future<bool> deleteReminder(String reminderId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/reminders/$reminderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw ReminderApiException('Reminder not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw ReminderApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReminderApiException(
          'Failed to delete reminder: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReminderApiException) rethrow;
      debugPrint('Error deleting reminder: $e');
      throw ReminderApiException('Network error: $e');
    }
  }
}
