import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/sync_models.dart';
import 'auth_service.dart';

/// Sync API Service
/// Handles all sync-related API calls to the backend
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
class SyncApiService {
  static final SyncApiService instance = SyncApiService._internal();
  SyncApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Push local changes to server
  /// POST /sync/push
  Future<SyncPushResponse> pushSync(SyncPushRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/push'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SyncPushResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SyncApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw SyncApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw SyncApiException(
          'Failed to push sync: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SyncApiException) rethrow;
      debugPrint('Error pushing sync: $e');
      throw SyncApiException('Network error: $e');
    }
  }

  /// Pull server changes
  /// POST /sync/pull
  Future<SyncPullResponse> pullSync(SyncPullRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/pull'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SyncPullResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SyncApiException('Unauthorized', statusCode: 401);
      } else {
        throw SyncApiException(
          'Failed to pull sync: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SyncApiException) rethrow;
      debugPrint('Error pulling sync: $e');
      throw SyncApiException('Network error: $e');
    }
  }

  /// Get sync status
  /// GET /sync/status
  Future<SyncStatusResponse> getSyncStatus() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/sync/status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SyncStatusResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SyncApiException('Unauthorized', statusCode: 401);
      } else {
        throw SyncApiException(
          'Failed to get sync status: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SyncApiException) rethrow;
      debugPrint('Error getting sync status: $e');
      throw SyncApiException('Network error: $e');
    }
  }

  /// Get user profile
  /// GET /users/profile
  Future<UserProfile> getUserProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/users/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data['user'] ?? data['profile'] ?? data);
      } else if (response.statusCode == 401) {
        throw SyncApiException('Unauthorized', statusCode: 401);
      } else {
        throw SyncApiException(
          'Failed to get user profile: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SyncApiException) rethrow;
      debugPrint('Error getting user profile: $e');
      throw SyncApiException('Network error: $e');
    }
  }

  /// Update user profile
  /// POST /users/profile or PUT /users/profile
  Future<UserProfile> updateUserProfile(UserProfileUpdateRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data['user'] ?? data['profile'] ?? data);
      } else if (response.statusCode == 401) {
        throw SyncApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw SyncApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw SyncApiException(
          'Failed to update user profile: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SyncApiException) rethrow;
      debugPrint('Error updating user profile: $e');
      throw SyncApiException('Network error: $e');
    }
  }

  /// Full sync (push then pull)
  /// Convenience method that performs both push and pull
  Future<({SyncPushResponse push, SyncPullResponse pull})> fullSync({
    required List<SyncPushItem> itemsToPush,
    required DateTime lastSyncAt,
    String? deviceId,
    List<String>? pullEntityTypes,
    int? pullLimit,
  }) async {
    // First push local changes
    final pushResponse = await pushSync(SyncPushRequest(
      items: itemsToPush,
      deviceId: deviceId,
      lastSyncAt: lastSyncAt,
    ));

    // Then pull server changes
    final pullResponse = await pullSync(SyncPullRequest(
      lastSyncAt: lastSyncAt,
      entityTypes: pullEntityTypes,
      deviceId: deviceId,
      limit: pullLimit,
    ));

    return (push: pushResponse, pull: pullResponse);
  }

  /// Incremental sync for a specific entity type
  /// POST /sync/{entityType}
  Future<SyncPullResponse> syncEntityType({
    required String entityType,
    required DateTime lastSyncAt,
    int? limit,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/$entityType'),
        headers: headers,
        body: jsonEncode({
          'last_sync_at': lastSyncAt.toIso8601String(),
          if (limit != null) 'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SyncPullResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SyncApiException('Unauthorized', statusCode: 401);
      } else {
        throw SyncApiException(
          'Failed to sync $entityType: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SyncApiException) rethrow;
      debugPrint('Error syncing $entityType: $e');
      throw SyncApiException('Network error: $e');
    }
  }

  /// Resolve sync conflict
  /// POST /sync/resolve-conflict
  Future<SyncPushResult> resolveConflict({
    required String entityType,
    required String entityId,
    required String resolution, // 'local', 'server', 'merge'
    Map<String, dynamic>? mergedData,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/resolve-conflict'),
        headers: headers,
        body: jsonEncode({
          'entity_type': entityType,
          'entity_id': entityId,
          'resolution': resolution,
          if (mergedData != null) 'merged_data': mergedData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SyncPushResult.fromJson(data['result'] ?? data);
      } else if (response.statusCode == 401) {
        throw SyncApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw SyncApiException('Conflict not found', statusCode: 404);
      } else {
        throw SyncApiException(
          'Failed to resolve conflict: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SyncApiException) rethrow;
      debugPrint('Error resolving conflict: $e');
      throw SyncApiException('Network error: $e');
    }
  }

  /// Reset sync state (for troubleshooting)
  /// POST /sync/reset
  Future<void> resetSyncState() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/sync/reset'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw SyncApiException('Unauthorized', statusCode: 401);
      } else {
        throw SyncApiException(
          'Failed to reset sync state: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SyncApiException) rethrow;
      debugPrint('Error resetting sync state: $e');
      throw SyncApiException('Network error: $e');
    }
  }
}
