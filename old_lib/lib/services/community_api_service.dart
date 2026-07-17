import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/community_models.dart';
import 'auth_service.dart';

/// Community API Service
/// Handles all community health mapping API calls
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
class CommunityApiService {
  static final CommunityApiService instance = CommunityApiService._internal();
  CommunityApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  // ==================== HOUSEHOLDS ====================

  /// Create household
  /// POST /community/households
  Future<Household> createHousehold(HouseholdRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/community/households'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Household.fromJson(data['household'] ?? data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw CommunityApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw CommunityApiException(
          'Failed to create household: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error creating household: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// List households with pagination and filters
  /// GET /community/households?chw_id={id}&page={page}&per_page={perPage}&village={village}&min_risk={min}&max_risk={max}
  Future<HouseholdListResponse> listHouseholds({
    String? chwId,
    int page = 1,
    int perPage = 20,
    String? village,
    int? minRisk,
    int? maxRisk,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (chwId != null) queryParams['chw_id'] = chwId;
      if (village != null) queryParams['village'] = village;
      if (minRisk != null) queryParams['min_risk'] = minRisk.toString();
      if (maxRisk != null) queryParams['max_risk'] = maxRisk.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final uri = Uri.parse('$_baseUrl/community/households')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HouseholdListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else {
        throw CommunityApiException(
          'Failed to list households: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error listing households: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// Get household details
  /// GET /community/households/{id}
  Future<Household> getHousehold(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/community/households/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Household.fromJson(data['household'] ?? data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw CommunityApiException('Household not found', statusCode: 404);
      } else {
        throw CommunityApiException(
          'Failed to get household: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error getting household: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// Update household
  /// PATCH /community/households/{id}
  Future<Household> updateHousehold(String id, HouseholdRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/community/households/$id'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Household.fromJson(data['household'] ?? data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw CommunityApiException('Household not found', statusCode: 404);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw CommunityApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw CommunityApiException(
          'Failed to update household: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error updating household: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// Delete household
  /// DELETE /community/households/{id}
  Future<void> deleteHousehold(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/community/households/$id'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw CommunityApiException('Household not found', statusCode: 404);
      } else {
        throw CommunityApiException(
          'Failed to delete household: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error deleting household: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  // ==================== SHARED RESOURCES ====================

  /// Create shared resource
  /// POST /community/resources
  Future<SharedResource> createResource(SharedResourceRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/community/resources'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SharedResource.fromJson(data['resource'] ?? data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw CommunityApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw CommunityApiException(
          'Failed to create resource: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error creating resource: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// List shared resources with filters
  /// GET /community/resources?type={type}&area={area}&status={status}&page={page}
  Future<SharedResourceListResponse> listResources({
    String? type,
    String? area,
    String? status,
    int page = 1,
    int perPage = 20,
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
      if (area != null) queryParams['area'] = area;
      if (status != null) queryParams['status'] = status;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final uri = Uri.parse('$_baseUrl/community/resources')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SharedResourceListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else {
        throw CommunityApiException(
          'Failed to list resources: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error listing resources: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// Get resource details
  /// GET /community/resources/{id}
  Future<SharedResource> getResource(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/community/resources/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SharedResource.fromJson(data['resource'] ?? data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw CommunityApiException('Resource not found', statusCode: 404);
      } else {
        throw CommunityApiException(
          'Failed to get resource: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error getting resource: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// Update shared resource
  /// PATCH /community/resources/{id}
  Future<SharedResource> updateResource(
    String id,
    SharedResourceRequest request,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/community/resources/$id'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SharedResource.fromJson(data['resource'] ?? data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw CommunityApiException('Resource not found', statusCode: 404);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw CommunityApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw CommunityApiException(
          'Failed to update resource: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error updating resource: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// Delete shared resource
  /// DELETE /community/resources/{id}
  Future<void> deleteResource(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/community/resources/$id'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw CommunityApiException('Resource not found', statusCode: 404);
      } else {
        throw CommunityApiException(
          'Failed to delete resource: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error deleting resource: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  // ==================== DISEASE CASES ====================

  /// Create disease case
  /// POST /community/disease-cases
  Future<DiseaseCase> createDiseaseCase(DiseaseCaseRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/community/disease-cases'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DiseaseCase.fromJson(data['case'] ?? data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw CommunityApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw CommunityApiException(
          'Failed to create disease case: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error creating disease case: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// List disease cases with filters
  /// GET /community/disease-cases?household_id={id}&disease={disease}&status={status}&period={days}
  Future<DiseaseCaseListResponse> listDiseaseCases({
    String? householdId,
    String? disease,
    String? status,
    int? periodDays,
    int page = 1,
    int perPage = 20,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (householdId != null) queryParams['household_id'] = householdId;
      if (disease != null) queryParams['disease'] = disease;
      if (status != null) queryParams['status'] = status;
      if (periodDays != null) queryParams['period'] = periodDays.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final uri = Uri.parse('$_baseUrl/community/disease-cases')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DiseaseCaseListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else {
        throw CommunityApiException(
          'Failed to list disease cases: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error listing disease cases: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// Get disease case details
  /// GET /community/disease-cases/{id}
  Future<DiseaseCase> getDiseaseCase(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/community/disease-cases/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DiseaseCase.fromJson(data['case'] ?? data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw CommunityApiException('Disease case not found', statusCode: 404);
      } else {
        throw CommunityApiException(
          'Failed to get disease case: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error getting disease case: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// Update disease case
  /// PATCH /community/disease-cases/{id}
  Future<DiseaseCase> updateDiseaseCase(
    String id,
    DiseaseCaseRequest request,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/community/disease-cases/$id'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DiseaseCase.fromJson(data['case'] ?? data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw CommunityApiException('Disease case not found', statusCode: 404);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw CommunityApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw CommunityApiException(
          'Failed to update disease case: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error updating disease case: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  /// Delete disease case
  /// DELETE /community/disease-cases/{id}
  Future<void> deleteDiseaseCase(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/community/disease-cases/$id'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw CommunityApiException('Disease case not found', statusCode: 404);
      } else {
        throw CommunityApiException(
          'Failed to delete disease case: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error deleting disease case: $e');
      throw CommunityApiException('Network error: $e');
    }
  }

  // ==================== RISK SCORES ====================

  /// Get risk score summary for an area
  /// GET /community/risk-scores?area={area}
  Future<RiskScoreSummary> getRiskScores({String? area}) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};

      if (area != null) queryParams['area'] = area;

      final uri = Uri.parse('$_baseUrl/community/risk-scores')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RiskScoreSummary.fromJson(data['risk_score_summary'] ?? data);
      } else if (response.statusCode == 401) {
        throw CommunityApiException('Unauthorized', statusCode: 401);
      } else {
        throw CommunityApiException(
          'Failed to get risk scores: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is CommunityApiException) rethrow;
      debugPrint('Error getting risk scores: $e');
      throw CommunityApiException('Network error: $e');
    }
  }
}
