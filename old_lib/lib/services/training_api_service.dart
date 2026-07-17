import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/training_models.dart';
import 'auth_service.dart';

/// Training API Service
/// Handles all training-related API calls to the backend
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
class TrainingApiService {
  static final TrainingApiService instance = TrainingApiService._internal();
  TrainingApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Get training progress for current CHW
  /// GET /training/progress
  Future<TrainingProgressResponse> getTrainingProgress() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/training/progress'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TrainingProgressResponse.fromJson(data['progress'] ?? data);
      } else if (response.statusCode == 401) {
        throw TrainingApiException('Unauthorized', statusCode: 401);
      } else {
        throw TrainingApiException(
          'Failed to get training progress: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TrainingApiException) rethrow;
      debugPrint('Error getting training progress: $e');
      throw TrainingApiException('Network error: $e');
    }
  }

  /// Update training progress for a module
  /// POST /training/progress
  Future<ModuleProgress> updateTrainingProgress(
    TrainingProgressUpdateRequest request,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/training/progress'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ModuleProgress.fromJson(data['module_progress'] ?? data);
      } else if (response.statusCode == 401) {
        throw TrainingApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw TrainingApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw TrainingApiException(
          'Failed to update training progress: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TrainingApiException) rethrow;
      debugPrint('Error updating training progress: $e');
      throw TrainingApiException('Network error: $e');
    }
  }

  /// Submit quiz answers and get results
  /// POST /training/quiz/submit
  Future<QuizResultResponse> submitQuiz(QuizSubmitRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/training/quiz/submit'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return QuizResultResponse.fromJson(data['result'] ?? data);
      } else if (response.statusCode == 401) {
        throw TrainingApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw TrainingApiException('Quiz not found', statusCode: 404);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw TrainingApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw TrainingApiException(
          'Failed to submit quiz: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TrainingApiException) rethrow;
      debugPrint('Error submitting quiz: $e');
      throw TrainingApiException('Network error: $e');
    }
  }

  /// Get list of available training modules
  /// GET /training/modules
  Future<List<TrainingModule>> getTrainingModules() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/training/modules'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final modules = data['modules'] ?? data['data'] ?? [];
        return (modules as List)
            .map((item) => TrainingModule.fromJson(item))
            .toList();
      } else if (response.statusCode == 401) {
        throw TrainingApiException('Unauthorized', statusCode: 401);
      } else {
        throw TrainingApiException(
          'Failed to get training modules: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TrainingApiException) rethrow;
      debugPrint('Error getting training modules: $e');
      throw TrainingApiException('Network error: $e');
    }
  }

  /// Get specific training module by ID
  /// GET /training/modules/{id}
  Future<TrainingModule> getTrainingModule(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/training/modules/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TrainingModule.fromJson(data['module'] ?? data);
      } else if (response.statusCode == 401) {
        throw TrainingApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw TrainingApiException('Module not found', statusCode: 404);
      } else {
        throw TrainingApiException(
          'Failed to get training module: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TrainingApiException) rethrow;
      debugPrint('Error getting training module: $e');
      throw TrainingApiException('Network error: $e');
    }
  }

  /// Get quiz history for current CHW
  /// GET /training/quiz/history
  Future<List<QuizResultResponse>> getQuizHistory({
    String? moduleId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (moduleId != null) queryParams['module_id'] = moduleId;

      final uri = Uri.parse('$_baseUrl/training/quiz/history')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] ?? data['history'] ?? data['data'] ?? [];
        return (results as List)
            .map((item) => QuizResultResponse.fromJson(item))
            .toList();
      } else if (response.statusCode == 401) {
        throw TrainingApiException('Unauthorized', statusCode: 401);
      } else {
        throw TrainingApiException(
          'Failed to get quiz history: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TrainingApiException) rethrow;
      debugPrint('Error getting quiz history: $e');
      throw TrainingApiException('Network error: $e');
    }
  }

  /// Mark module as started
  /// POST /training/modules/{id}/start
  Future<ModuleProgress> startModule(String moduleId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/training/modules/$moduleId/start'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ModuleProgress.fromJson(data['module_progress'] ?? data);
      } else if (response.statusCode == 401) {
        throw TrainingApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw TrainingApiException('Module not found', statusCode: 404);
      } else {
        throw TrainingApiException(
          'Failed to start module: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TrainingApiException) rethrow;
      debugPrint('Error starting module: $e');
      throw TrainingApiException('Network error: $e');
    }
  }

  /// Mark module as completed
  /// POST /training/modules/{id}/complete
  Future<ModuleProgress> completeModule(String moduleId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/training/modules/$moduleId/complete'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ModuleProgress.fromJson(data['module_progress'] ?? data);
      } else if (response.statusCode == 401) {
        throw TrainingApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw TrainingApiException('Module not found', statusCode: 404);
      } else {
        throw TrainingApiException(
          'Failed to complete module: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TrainingApiException) rethrow;
      debugPrint('Error completing module: $e');
      throw TrainingApiException('Network error: $e');
    }
  }

  /// Get training leaderboard
  /// GET /training/leaderboard
  Future<LeaderboardResponse> getLeaderboard({
    String? period, // weekly, monthly, all_time
    int? limit,
    String? facilityId,
    String? region,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};

      if (period != null) queryParams['period'] = period;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (facilityId != null) queryParams['facility_id'] = facilityId;
      if (region != null) queryParams['region'] = region;

      final uri = Uri.parse('$_baseUrl/training/leaderboard')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LeaderboardResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw TrainingApiException('Unauthorized', statusCode: 401);
      } else {
        throw TrainingApiException(
          'Failed to get leaderboard: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TrainingApiException) rethrow;
      debugPrint('Error getting leaderboard: $e');
      throw TrainingApiException('Network error: $e');
    }
  }

  /// Get current user's rank on the leaderboard
  /// GET /training/leaderboard/my-rank
  Future<LeaderboardEntry> getMyRank({
    String? period,
    String? facilityId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};

      if (period != null) queryParams['period'] = period;
      if (facilityId != null) queryParams['facility_id'] = facilityId;

      final uri = Uri.parse('$_baseUrl/training/leaderboard/my-rank')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LeaderboardEntry.fromJson(data['entry'] ?? data);
      } else if (response.statusCode == 401) {
        throw TrainingApiException('Unauthorized', statusCode: 401);
      } else {
        throw TrainingApiException(
          'Failed to get my rank: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TrainingApiException) rethrow;
      debugPrint('Error getting my rank: $e');
      throw TrainingApiException('Network error: $e');
    }
  }
}
