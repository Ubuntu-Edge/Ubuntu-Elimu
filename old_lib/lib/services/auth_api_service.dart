import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../models/auth_models.dart';

/// API Service for authentication endpoints
/// Handles all HTTP communication with the backend auth API
class AuthApiService {
  static final AuthApiService instance = AuthApiService._init();
  AuthApiService._init();

  /// Base URL for the API
  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net';
  static const String _apiVersion = '/api/v1';
  static const String _authPath = '/auth';

  /// Full auth base URL
  String get _authBaseUrl => '$_baseUrl$_apiVersion$_authPath';

  /// HTTP client with timeout
  final http.Client _client = http.Client();

  /// Default timeout for API calls
  static const Duration _timeout = Duration(seconds: 30);

  /// Get device info for API requests
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'device_id': Platform.isAndroid ? 'android' : 'ios',
        'device_name':
            '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'app_version': packageInfo.version,
      };
    } catch (e) {
      return {
        'device_id': 'unknown',
        'device_name': 'unknown',
      };
    }
  }

  /// Common headers for API requests
  Map<String, String> _getHeaders({String? accessToken}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  /// Handle API response and throw appropriate exceptions
  dynamic _handleResponse(http.Response response) {
    log('API Response [${response.statusCode}]: ${response.body}',
        name: 'AuthApiService');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    }

    // Handle validation errors (422)
    if (response.statusCode == 422) {
      final error = ValidationErrorResponse.fromJson(jsonDecode(response.body));
      throw AuthApiException(
        error.firstError,
        statusCode: 422,
        validationErrors: error,
      );
    }

    // Handle authentication errors
    if (response.statusCode == 401) {
      final body = jsonDecode(response.body);
      throw AuthApiException(
        body['detail'] ?? 'Authentication failed',
        statusCode: 401,
      );
    }

    // Handle not found
    if (response.statusCode == 404) {
      throw AuthApiException(
        'Resource not found',
        statusCode: 404,
      );
    }

    // Handle conflict (e.g., phone number already exists)
    if (response.statusCode == 409) {
      final body = jsonDecode(response.body);
      throw AuthApiException(
        body['detail'] ?? 'Conflict error',
        statusCode: 409,
      );
    }

    // Handle server errors
    if (response.statusCode >= 500) {
      throw AuthApiException(
        'Server error. Please try again later.',
        statusCode: response.statusCode,
      );
    }

    // Handle other errors
    try {
      final body = jsonDecode(response.body);
      throw AuthApiException(
        body['detail'] ?? body['message'] ?? 'Unknown error',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException(
        'Unknown error occurred',
        statusCode: response.statusCode,
      );
    }
  }

  /// Register a new user
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final requestBody = request.toJson();
      requestBody['device_id'] = deviceInfo['device_id'];
      requestBody['device_name'] = deviceInfo['device_name'];

      log('Registering user: ${request.phoneNumber}', name: 'AuthApiService');

      final response = await _client
          .post(
            Uri.parse('$_authBaseUrl/register'),
            headers: _getHeaders(),
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      final data = _handleResponse(response);
      return AuthResponse.fromJson(data);
    } on SocketException {
      throw AuthApiException('No internet connection', isNetworkError: true);
    } on TimeoutException {
      throw AuthApiException('Connection timed out', isNetworkError: true);
    } on http.ClientException {
      throw AuthApiException('Network error', isNetworkError: true);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      log('Register error: $e', name: 'AuthApiService');
      throw AuthApiException('Registration failed: $e');
    }
  }

  /// Login with phone and PIN
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final requestBody = request.toJson();
      requestBody['device_id'] = deviceInfo['device_id'];
      requestBody['device_name'] = deviceInfo['device_name'];

      log('Logging in user: ${request.phoneNumber}', name: 'AuthApiService');

      final response = await _client
          .post(
            Uri.parse('$_authBaseUrl/login'),
            headers: _getHeaders(),
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      final data = _handleResponse(response);
      return AuthResponse.fromJson(data);
    } on SocketException {
      throw AuthApiException('No internet connection', isNetworkError: true);
    } on TimeoutException {
      throw AuthApiException('Connection timed out', isNetworkError: true);
    } on http.ClientException {
      throw AuthApiException('Network error', isNetworkError: true);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      log('Login error: $e', name: 'AuthApiService');
      throw AuthApiException('Login failed: $e');
    }
  }

  /// Refresh access token
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      log('Refreshing token with refresh_token: ${refreshToken.substring(0, 20)}...', name: 'AuthApiService');

      final response = await _client
          .post(
            Uri.parse('$_authBaseUrl/refresh'),
            headers: _getHeaders(),
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(_timeout);

      log('Refresh token response status: ${response.statusCode}', name: 'AuthApiService');
      final data = _handleResponse(response);
      log('Token refresh successful', name: 'AuthApiService');
      return AuthResponse.fromJson(data);
    } on SocketException {
      log('Token refresh failed: No internet connection', name: 'AuthApiService');
      throw AuthApiException('No internet connection', isNetworkError: true);
    } on http.ClientException {
      log('Token refresh failed: Network error', name: 'AuthApiService');
      throw AuthApiException('Network error', isNetworkError: true);
    } on AuthApiException catch (e) {
      log('Token refresh failed: ${e.message} (status: ${e.statusCode})', name: 'AuthApiService');
      rethrow;
    } catch (e) {
      log('Token refresh error: $e', name: 'AuthApiService');
      throw AuthApiException('Token refresh failed: $e');
    }
  }

  /// Logout (invalidate token)
  Future<ApiResponse> logout(String accessToken) async {
    try {
      log('Logging out user', name: 'AuthApiService');

      final response = await _client
          .post(
            Uri.parse('$_authBaseUrl/logout'),
            headers: _getHeaders(accessToken: accessToken),
          )
          .timeout(_timeout);

      final data = _handleResponse(response);
      return ApiResponse.fromJson(data);
    } on SocketException {
      // Allow logout to proceed even without network
      return ApiResponse(success: true, message: 'Logged out locally');
    } on http.ClientException {
      return ApiResponse(success: true, message: 'Logged out locally');
    } catch (e) {
      if (e is AuthApiException) rethrow;
      log('Logout error: $e', name: 'AuthApiService');
      // Still return success for logout - we'll clear local state
      return ApiResponse(success: true, message: 'Logged out locally');
    }
  }

  /// Change password
  Future<ApiResponse> changePassword(
    String accessToken,
    ChangePasswordRequest request,
  ) async {
    try {
      log('Changing password', name: 'AuthApiService');

      final response = await _client
          .post(
            Uri.parse('$_authBaseUrl/change-password'),
            headers: _getHeaders(accessToken: accessToken),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      final data = _handleResponse(response);
      return ApiResponse.fromJson(data);
    } on SocketException {
      throw AuthApiException('No internet connection', isNetworkError: true);
    } on http.ClientException {
      throw AuthApiException('Network error', isNetworkError: true);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      log('Change password error: $e', name: 'AuthApiService');
      throw AuthApiException('Password change failed: $e');
    }
  }

  /// Change PIN
  Future<ApiResponse> changePin(
    String accessToken,
    ChangePinRequest request,
  ) async {
    try {
      log('Changing PIN', name: 'AuthApiService');

      final response = await _client
          .post(
            Uri.parse('$_authBaseUrl/change-pin'),
            headers: _getHeaders(accessToken: accessToken),
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      final data = _handleResponse(response);
      return ApiResponse.fromJson(data);
    } on SocketException {
      throw AuthApiException('No internet connection', isNetworkError: true);
    } on http.ClientException {
      throw AuthApiException('Network error', isNetworkError: true);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      log('Change PIN error: $e', name: 'AuthApiService');
      throw AuthApiException('PIN change failed: $e');
    }
  }

  /// Check if server is reachable
  Future<bool> isServerReachable() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get user profile for sync (GET /api/v1/sync/user-profile)
  Future<UserResponse> getUserProfile(String accessToken) async {
    try {
      log('Getting user profile for sync', name: 'AuthApiService');

      final response = await _client
          .get(
            Uri.parse('$_baseUrl$_apiVersion/sync/user-profile'),
            headers: _getHeaders(accessToken: accessToken),
          )
          .timeout(_timeout);

      final data = _handleResponse(response);
      return UserResponse.fromJson(data);
    } on SocketException {
      throw AuthApiException('No internet connection', isNetworkError: true);
    } on http.ClientException {
      throw AuthApiException('Network error', isNetworkError: true);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      log('Get user profile error: $e', name: 'AuthApiService');
      throw AuthApiException('Failed to get user profile: $e');
    }
  }

  /// Sync user profile and credentials (POST /api/v1/sync/user-profile)
  Future<UserProfileSyncResponse> syncUserProfile(
    String accessToken,
    UserProfileSyncRequest request,
  ) async {
    try {
      final requestBody = request.toJson();
      log('Syncing user profile with body: $requestBody', name: 'AuthApiService');

      final response = await _client
          .post(
            Uri.parse('$_baseUrl$_apiVersion/sync/user-profile'),
            headers: _getHeaders(accessToken: accessToken),
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      final data = _handleResponse(response);
      return UserProfileSyncResponse.fromJson(data);
    } on SocketException {
      throw AuthApiException('No internet connection', isNetworkError: true);
    } on http.ClientException {
      throw AuthApiException('Network error', isNetworkError: true);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      log('Sync user profile error: $e', name: 'AuthApiService');
      throw AuthApiException('Profile sync failed: $e');
    }
  }

  /// Dispose client
  void dispose() {
    _client.close();
  }
}

/// Custom exception for Auth API errors
class AuthApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;
  final ValidationErrorResponse? validationErrors;

  AuthApiException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
    this.validationErrors,
  });

  @override
  String toString() => message;

  /// Check if error is due to invalid credentials
  bool get isInvalidCredentials =>
      statusCode == 401 || message.toLowerCase().contains('invalid');

  /// Check if error is due to user already existing
  bool get isUserExists =>
      statusCode == 409 ||
      message.toLowerCase().contains('already') ||
      message.toLowerCase().contains('exists');

  /// Check if error is a validation error
  bool get isValidationError => statusCode == 422;
}
