import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../models/family_models.dart';
import 'auth_service.dart';

/// API Service for Family endpoints
/// Handles all HTTP communication with the backend Family API
class FamilyApiService {
  static final FamilyApiService instance = FamilyApiService._init();
  FamilyApiService._init();

  /// Base URL for the API
  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net';
  static const String _apiVersion = '/api/v1';
  static const String _familiesPath = '/families';

  /// Full families base URL
  String get _familiesBaseUrl => '$_baseUrl$_apiVersion$_familiesPath';

  /// HTTP client with timeout
  final http.Client _client = http.Client();

  /// Default timeout for API calls
  static const Duration _timeout = Duration(seconds: 30);

  /// Common headers for API requests using centralized auth
  Future<Map<String, String>> _getHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// Handle API response and throw appropriate exceptions
  dynamic _handleResponse(http.Response response) {
    log('Family API Response [${response.statusCode}]: ${response.body}',
        name: 'FamilyApiService');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    }

    // Handle validation errors (422)
    if (response.statusCode == 422) {
      final error = ValidationErrorResponse.fromJson(jsonDecode(response.body));
      throw FamilyApiException(
        error.firstError,
        statusCode: 422,
        validationErrors: error.detail,
      );
    }

    // Handle authentication errors
    if (response.statusCode == 401) {
      final body = jsonDecode(response.body);
      throw FamilyApiException(
        body['detail'] ?? 'Authentication failed',
        statusCode: 401,
      );
    }

    // Handle not found
    if (response.statusCode == 404) {
      throw FamilyApiException(
        'Family not found',
        statusCode: 404,
      );
    }

    // Handle foreign key errors
    if (response.statusCode == 400) {
      final body = jsonDecode(response.body);
      throw FamilyApiException(
        body['detail'] ?? 'Invalid request',
        statusCode: 400,
      );
    }

    // Handle server errors
    if (response.statusCode >= 500) {
      throw FamilyApiException(
        'Server error. Please try again later.',
        statusCode: response.statusCode,
      );
    }

    // Handle other errors
    try {
      final body = jsonDecode(response.body);
      throw FamilyApiException(
        body['detail'] ?? body['message'] ?? 'Unknown error',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is FamilyApiException) rethrow;
      throw FamilyApiException(
        'Unknown error occurred',
        statusCode: response.statusCode,
      );
    }
  }

  /// Create a new family
  /// POST /api/v1/families
  Future<FamilyResponse> createFamily(FamilyCreateRequest request) async {
    try {
      log('Creating family: ${request.familyName}', name: 'FamilyApiService');

      final headers = await _getHeaders();
      final response = await _client
          .post(
            Uri.parse(_familiesBaseUrl),
            headers: headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      final data = _handleResponse(response);
      return FamilyResponse.fromJson(data);
    } on FamilyApiException {
      rethrow;
    } catch (e) {
      log('Create family error: $e', name: 'FamilyApiService');
      throw FamilyApiException('Failed to create family: ${e.toString()}');
    }
  }

  /// List families with filtering and pagination
  /// GET /api/v1/families
  Future<FamilyListResponse> listFamilies({
    int page = 1,
    int perPage = 20,
    String? searchQuery,
    String? village,
  }) async {
    try {
      log('Fetching families list, page: $page', name: 'FamilyApiService');

      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }
      if (village != null && village.isNotEmpty) {
        queryParams['village'] = village;
      }

      final uri = Uri.parse(_familiesBaseUrl).replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      
      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);

      final data = _handleResponse(response);
      return FamilyListResponse.fromJson(data);
    } on FamilyApiException {
      rethrow;
    } catch (e) {
      log('List families error: $e', name: 'FamilyApiService');
      throw FamilyApiException('Failed to fetch families: ${e.toString()}');
    }
  }

  /// Get family details by ID
  /// GET /api/v1/families/{family_id}
  Future<FamilyResponse> getFamily(String familyId) async {
    try {
      log('Fetching family: $familyId', name: 'FamilyApiService');

      final headers = await _getHeaders();
      final response = await _client
          .get(
            Uri.parse('$_familiesBaseUrl/$familyId'),
            headers: headers,
          )
          .timeout(_timeout);

      final data = _handleResponse(response);
      return FamilyResponse.fromJson(data);
    } on FamilyApiException {
      rethrow;
    } catch (e) {
      log('Get family error: $e', name: 'FamilyApiService');
      throw FamilyApiException('Failed to fetch family: ${e.toString()}');
    }
  }

  /// Update a family
  /// PATCH /api/v1/families/{family_id}
  Future<FamilyResponse> updateFamily(String familyId, FamilyUpdateRequest request) async {
    try {
      log('Updating family: $familyId', name: 'FamilyApiService');

      final headers = await _getHeaders();
      final response = await _client
          .patch(
            Uri.parse('$_familiesBaseUrl/$familyId'),
            headers: headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      final data = _handleResponse(response);
      return FamilyResponse.fromJson(data);
    } on FamilyApiException {
      rethrow;
    } catch (e) {
      log('Update family error: $e', name: 'FamilyApiService');
      throw FamilyApiException('Failed to update family: ${e.toString()}');
    }
  }

  /// Delete a family
  /// DELETE /api/v1/families/{family_id}
  Future<bool> deleteFamily(String familyId) async {
    try {
      log('Deleting family: $familyId', name: 'FamilyApiService');

      final headers = await _getHeaders();
      final response = await _client
          .delete(
            Uri.parse('$_familiesBaseUrl/$familyId'),
            headers: headers,
          )
          .timeout(_timeout);

      _handleResponse(response);
      return true;
    } on FamilyApiException {
      rethrow;
    } catch (e) {
      log('Delete family error: $e', name: 'FamilyApiService');
      throw FamilyApiException('Failed to delete family: ${e.toString()}');
    }
  }
}
