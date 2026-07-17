import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/referral_models.dart';
import 'auth_service.dart';

/// Referral API Service
/// Handles all referral-related API calls to the backend
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
class ReferralApiService {
  static final ReferralApiService instance = ReferralApiService._internal();
  ReferralApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Create a new referral
  /// POST /referrals
  Future<ReferralResponse> createReferral(ReferralCreateRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/referrals'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReferralResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => ReferralValidationError.fromJson(e))
            .toList();
        throw ReferralApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw ReferralApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReferralApiException(
          'Failed to create referral: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReferralApiException) rethrow;
      debugPrint('Error creating referral: $e');
      throw ReferralApiException('Network error: $e');
    }
  }

  /// List referrals with optional filters and pagination
  /// GET /referrals
  Future<ReferralListResponse> listReferrals({
    int page = 1,
    int perPage = 20,
    String? patientId,
    String? status,
    String? urgency,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (patientId != null && patientId.isNotEmpty) {
        queryParams['patient_id'] = patientId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (urgency != null && urgency.isNotEmpty) {
        queryParams['urgency'] = urgency;
      }

      final uri = Uri.parse('$_baseUrl/referrals').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReferralListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw ReferralApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReferralApiException(
          'Failed to list referrals: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReferralApiException) rethrow;
      debugPrint('Error listing referrals: $e');
      throw ReferralApiException('Network error: $e');
    }
  }

  /// Get referral details by ID
  /// GET /referrals/{referral_id}
  Future<ReferralResponse> getReferral(String referralId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/referrals/$referralId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReferralResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ReferralApiException('Referral not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw ReferralApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReferralApiException(
          'Failed to get referral: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReferralApiException) rethrow;
      debugPrint('Error getting referral: $e');
      throw ReferralApiException('Network error: $e');
    }
  }

  /// Update referral by ID
  /// PATCH /referrals/{referral_id}
  Future<ReferralResponse> updateReferral(
    String referralId,
    ReferralUpdateRequest request,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/referrals/$referralId'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReferralResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ReferralApiException('Referral not found', statusCode: 404);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => ReferralValidationError.fromJson(e))
            .toList();
        throw ReferralApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw ReferralApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReferralApiException(
          'Failed to update referral: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReferralApiException) rethrow;
      debugPrint('Error updating referral: $e');
      throw ReferralApiException('Network error: $e');
    }
  }

  /// Update referral status
  /// PATCH /referrals/{referral_id}/status
  Future<ReferralResponse> updateReferralStatus(
    String referralId,
    ReferralStatusUpdateRequest request,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/referrals/$referralId/status'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReferralResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ReferralApiException('Referral not found', statusCode: 404);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => ReferralValidationError.fromJson(e))
            .toList();
        throw ReferralApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw ReferralApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReferralApiException(
          'Failed to update referral status: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReferralApiException) rethrow;
      debugPrint('Error updating referral status: $e');
      throw ReferralApiException('Network error: $e');
    }
  }

  /// Delete referral by ID
  /// DELETE /referrals/{referral_id}
  Future<bool> deleteReferral(String referralId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/referrals/$referralId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw ReferralApiException('Referral not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw ReferralApiException('Unauthorized', statusCode: 401);
      } else {
        throw ReferralApiException(
          'Failed to delete referral: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ReferralApiException) rethrow;
      debugPrint('Error deleting referral: $e');
      throw ReferralApiException('Network error: $e');
    }
  }
}
