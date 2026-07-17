import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/visit_models.dart';
import 'auth_service.dart';

/// Visit API Service
/// Handles all visit-related API calls to the backend
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
class VisitApiService {
  static final VisitApiService instance = VisitApiService._internal();
  VisitApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Create a new visit
  /// POST /visits
  Future<VisitResponse> createVisit(VisitCreateRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/visits'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VisitResponse.fromJson(data);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => VisitValidationError.fromJson(e))
            .toList();
        throw VisitApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw VisitApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisitApiException(
          'Failed to create visit: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisitApiException) rethrow;
      debugPrint('Error creating visit: $e');
      throw VisitApiException('Network error: $e');
    }
  }

  /// List visits with optional filters and pagination
  /// GET /visits
  Future<VisitListResponse> listVisits({
    int page = 1,
    int perPage = 20,
    String? patientId,
    String? visitType,
    String? dateFrom,
    String? dateTo,
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
      if (visitType != null && visitType.isNotEmpty) {
        queryParams['visit_type'] = visitType;
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['date_from'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['date_to'] = dateTo;
      }

      final uri = Uri.parse('$_baseUrl/visits').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VisitListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw VisitApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisitApiException(
          'Failed to list visits: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisitApiException) rethrow;
      debugPrint('Error listing visits: $e');
      throw VisitApiException('Network error: $e');
    }
  }

  /// Get visit details by ID
  /// GET /visits/{visit_id}
  Future<VisitResponse> getVisit(String visitId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/visits/$visitId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VisitResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw VisitApiException('Visit not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw VisitApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisitApiException(
          'Failed to get visit: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisitApiException) rethrow;
      debugPrint('Error getting visit: $e');
      throw VisitApiException('Network error: $e');
    }
  }

  /// Update visit by ID
  /// PATCH /visits/{visit_id}
  Future<VisitResponse> updateVisit(
    String visitId,
    VisitUpdateRequest request,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/visits/$visitId'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VisitResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw VisitApiException('Visit not found', statusCode: 404);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errors = (errorData['detail'] as List?)
            ?.map((e) => VisitValidationError.fromJson(e))
            .toList();
        throw VisitApiException(
          'Validation error',
          statusCode: 422,
          validationErrors: errors,
        );
      } else if (response.statusCode == 401) {
        throw VisitApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisitApiException(
          'Failed to update visit: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisitApiException) rethrow;
      debugPrint('Error updating visit: $e');
      throw VisitApiException('Network error: $e');
    }
  }

  /// Delete visit by ID
  /// DELETE /visits/{visit_id}
  Future<bool> deleteVisit(String visitId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/visits/$visitId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw VisitApiException('Visit not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw VisitApiException('Unauthorized', statusCode: 401);
      } else {
        throw VisitApiException(
          'Failed to delete visit: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is VisitApiException) rethrow;
      debugPrint('Error deleting visit: $e');
      throw VisitApiException('Network error: $e');
    }
  }
}
