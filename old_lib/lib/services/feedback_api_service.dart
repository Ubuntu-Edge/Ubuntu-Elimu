import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/feedback_models.dart';
import 'auth_service.dart';

/// Feedback API Service
/// Handles all feedback-related API calls to the backend
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
class FeedbackApiService {
  static final FeedbackApiService instance = FeedbackApiService._internal();
  FeedbackApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Submit new feedback
  /// POST /feedback
  Future<FeedbackResponse> submitFeedback(FeedbackCreateRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/feedback'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FeedbackResponse.fromJson(data['feedback'] ?? data);
      } else if (response.statusCode == 401) {
        throw FeedbackApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw FeedbackApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw FeedbackApiException(
          'Failed to submit feedback: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FeedbackApiException) rethrow;
      debugPrint('Error submitting feedback: $e');
      throw FeedbackApiException('Network error: $e');
    }
  }

  /// List feedback with optional filters
  /// GET /feedback?page={page}&per_page={perPage}&type={type}&status={status}
  Future<FeedbackListResponse> listFeedback({
    int page = 1,
    int perPage = 20,
    String? type,
    String? status,
    String? priority,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final uri =
          Uri.parse('$_baseUrl/feedback').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FeedbackListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw FeedbackApiException('Unauthorized', statusCode: 401);
      } else {
        throw FeedbackApiException(
          'Failed to list feedback: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FeedbackApiException) rethrow;
      debugPrint('Error listing feedback: $e');
      throw FeedbackApiException('Network error: $e');
    }
  }

  /// Get feedback by ID
  /// GET /feedback/{id}
  Future<FeedbackResponse> getFeedback(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/feedback/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FeedbackResponse.fromJson(data['feedback'] ?? data);
      } else if (response.statusCode == 401) {
        throw FeedbackApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw FeedbackApiException('Feedback not found', statusCode: 404);
      } else {
        throw FeedbackApiException(
          'Failed to get feedback: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FeedbackApiException) rethrow;
      debugPrint('Error getting feedback: $e');
      throw FeedbackApiException('Network error: $e');
    }
  }

  /// Update feedback status (PATCH /feedback/{id})
  /// Only supervisors and admins can update feedback
  Future<FeedbackResponse> updateFeedback(
    String id,
    FeedbackUpdateRequest request,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/feedback/$id'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FeedbackResponse.fromJson(data['feedback'] ?? data);
      } else if (response.statusCode == 401) {
        throw FeedbackApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw FeedbackApiException('Feedback not found', statusCode: 404);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw FeedbackApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw FeedbackApiException(
          'Failed to update feedback: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FeedbackApiException) rethrow;
      debugPrint('Error updating feedback: $e');
      throw FeedbackApiException('Network error: $e');
    }
  }

  /// Delete feedback
  /// DELETE /feedback/{id}
  Future<void> deleteFeedback(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/feedback/$id'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw FeedbackApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw FeedbackApiException('Feedback not found', statusCode: 404);
      } else {
        throw FeedbackApiException(
          'Failed to delete feedback: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is FeedbackApiException) rethrow;
      debugPrint('Error deleting feedback: $e');
      throw FeedbackApiException('Network error: $e');
    }
  }
}
