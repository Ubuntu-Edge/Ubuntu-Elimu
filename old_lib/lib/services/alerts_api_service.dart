/// Alerts API Service
/// Handles weather alerts, disease outbreaks, and local hazards
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

// Alert Severity Enum
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
  info, // Backend uses 'info' instead of 'low'
  warning, // Backend uses 'warning' instead of 'medium'
  severe, // Backend uses 'severe' instead of 'high'
}

// Alert Type Enum
enum AlertType { weather, disease, hazard }

/// Alert Model (matches backend API response)
class Alert {
  final String id;
  final String alertType; // weather, disease, hazard
  final String severity; // info, warning, severe, critical
  final String title;
  final String description;
  final String area;
  final String region;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final bool isBroadcast;
  final String? actionRequired;
  final String? source;
  final Map<String, dynamic>? alertMetadata;
  final String createdById;
  final bool isExpired;
  final DateTime createdAt;
  final DateTime updatedAt;

  Alert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.description,
    required this.area,
    required this.region,
    required this.startTime,
    this.endTime,
    required this.isActive,
    required this.isBroadcast,
    this.actionRequired,
    this.source,
    this.alertMetadata,
    required this.createdById,
    required this.isExpired,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? '',
      alertType: json['alert_type'] ?? '',
      severity: json['severity'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      area: json['area'] ?? '',
      region: json['region'] ?? '',
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime:
          json['end_time'] != null ? DateTime.tryParse(json['end_time']) : null,
      isActive: json['is_active'] ?? true,
      isBroadcast: json['is_broadcast'] ?? false,
      actionRequired: json['action_required'],
      source: json['source'],
      alertMetadata: json['alert_metadata'] != null
          ? Map<String, dynamic>.from(json['alert_metadata'])
          : null,
      createdById: json['created_by_id'] ?? '',
      isExpired: json['is_expired'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  // Helper getters for backward compatibility with UI code
  AlertSeverity get severityEnum => _parseSeverity(severity);
  AlertType get type => _parseType(alertType);
  List<String> get affectedAreas => [area, region];
  List<String> get recommendations =>
      actionRequired != null ? [actionRequired!] : [];
  int? get caseCount => alertMetadata?['cases_reported'];
  int? get deathCount => alertMetadata?['deaths'];
  bool get isAcknowledged => false; // Acknowledgement is tracked separately

  static AlertSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'info':
        return AlertSeverity.info;
      case 'low':
        return AlertSeverity.low;
      case 'warning':
        return AlertSeverity.warning;
      case 'medium':
        return AlertSeverity.medium;
      case 'severe':
        return AlertSeverity.severe;
      case 'high':
        return AlertSeverity.high;
      case 'critical':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.info;
    }
  }

  static AlertType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'weather':
        return AlertType.weather;
      case 'disease':
        return AlertType.disease;
      case 'hazard':
        return AlertType.hazard;
      default:
        return AlertType.weather;
    }
  }
}

/// Alert List Response (matches backend pagination)
class AlertListResponse {
  final List<Alert> data;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  AlertListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory AlertListResponse.fromJson(Map<String, dynamic> json) {
    return AlertListResponse(
      data: (json['items'] as List<dynamic>?)
              ?.map((item) => Alert.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? 0,
    );
  }

  // Backward compatibility
  bool get success => true;
  int get totalCount => total;
}

/// Acknowledgement Model
class AlertAcknowledgement {
  final String id;
  final String alertId;
  final String userId;
  final DateTime acknowledgedAt;
  final String? notes;

  AlertAcknowledgement({
    required this.id,
    required this.alertId,
    required this.userId,
    required this.acknowledgedAt,
    this.notes,
  });

  factory AlertAcknowledgement.fromJson(Map<String, dynamic> json) {
    return AlertAcknowledgement(
      id: json['id'] ?? '',
      alertId: json['alert_id'] ?? '',
      userId: json['user_id'] ?? '',
      acknowledgedAt:
          DateTime.tryParse(json['acknowledged_at'] ?? '') ?? DateTime.now(),
      notes: json['notes'],
    );
  }
}

/// Alerts API Exception
class AlertsApiException implements Exception {
  final String message;
  final int? statusCode;

  AlertsApiException(this.message, {this.statusCode});

  @override
  String toString() => 'AlertsApiException: $message';
}

/// Alerts API Service
class AlertsApiService {
  static final AlertsApiService instance = AlertsApiService._internal();
  AlertsApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  /// List alerts with optional filters
  /// GET /alerts
  Future<AlertListResponse> listAlerts({
    AlertType? type,
    AlertSeverity? severity,
    String? area,
    bool? isActive,
    int page = 1,
    int perPage = 20,
    bool retryOnAuth = true,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (type != null) queryParams['alert_type'] = type.name;
      if (severity != null) queryParams['severity'] = severity.name;
      if (area != null && area.isNotEmpty) queryParams['area'] = area;
      if (isActive != null) queryParams['is_active'] = isActive.toString();

      final uri =
          Uri.parse('$_baseUrl/alerts').replace(queryParameters: queryParams);
      debugPrint('Alert API - Request: $uri');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AlertListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        debugPrint('Alert API - Got 401, attempting token refresh');
        // Try to refresh token and retry once
        if (retryOnAuth) {
          final refreshed = await AuthService.instance.refreshAccessToken();
          if (refreshed) {
            debugPrint('Alert API - Token refreshed, retrying request');
            return listAlerts(
              type: type,
              severity: severity,
              area: area,
              isActive: isActive,
              page: page,
              perPage: perPage,
              retryOnAuth: false, // Don't retry again to avoid infinite loop
            );
          } else {
            debugPrint(
                'Alert API - Token refresh failed, user needs to login again');
            // Force logout if token refresh failed
            await AuthService.instance.logout();
          }
        }
        throw AlertsApiException('Unauthorized - please login again',
            statusCode: 401);
      } else {
        throw AlertsApiException(
          'Failed to list alerts: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlertsApiException) rethrow;
      debugPrint('Error listing alerts: $e');
      throw AlertsApiException('Network error: $e');
    }
  }

  /// Create a new alert (Admin/Supervisor only)
  /// POST /alerts
  Future<Alert> createAlert({
    required String alertType,
    required String severity,
    required String title,
    required String description,
    required String area,
    required String region,
    required DateTime startTime,
    DateTime? endTime,
    bool isActive = true,
    bool isBroadcast = false,
    String? actionRequired,
    String? source,
    Map<String, dynamic>? alertMetadata,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'alert_type': alertType,
        'severity': severity,
        'title': title,
        'description': description,
        'area': area,
        'region': region,
        'start_time': startTime.toIso8601String(),
        'is_active': isActive,
        'is_broadcast': isBroadcast,
      };

      if (endTime != null) body['end_time'] = endTime.toIso8601String();
      if (actionRequired != null) body['action_required'] = actionRequired;
      if (source != null) body['source'] = source;
      if (alertMetadata != null) body['alert_metadata'] = alertMetadata;

      final response = await http.post(
        Uri.parse('$_baseUrl/alerts'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Alert.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AlertsApiException(
            'Unauthorized - Admin/Supervisor access required',
            statusCode: 401);
      } else if (response.statusCode == 403) {
        throw AlertsApiException('Forbidden - Insufficient permissions',
            statusCode: 403);
      } else {
        throw AlertsApiException(
          'Failed to create alert: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlertsApiException) rethrow;
      debugPrint('Error creating alert: $e');
      throw AlertsApiException('Network error: $e');
    }
  }

  /// Update an existing alert (Admin/Supervisor only)
  /// PATCH /alerts/{alert_id}
  Future<Alert> updateAlert({
    required String alertId,
    String? title,
    String? description,
    String? area,
    String? region,
    DateTime? endTime,
    bool? isActive,
    String? actionRequired,
    Map<String, dynamic>? alertMetadata,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{};

      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (area != null) body['area'] = area;
      if (region != null) body['region'] = region;
      if (endTime != null) body['end_time'] = endTime.toIso8601String();
      if (isActive != null) body['is_active'] = isActive;
      if (actionRequired != null) body['action_required'] = actionRequired;
      if (alertMetadata != null) body['alert_metadata'] = alertMetadata;

      final response = await http.patch(
        Uri.parse('$_baseUrl/alerts/$alertId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Alert.fromJson(data);
      } else if (response.statusCode == 401) {
        throw AlertsApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw AlertsApiException('Alert not found', statusCode: 404);
      } else {
        throw AlertsApiException(
          'Failed to update alert: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlertsApiException) rethrow;
      debugPrint('Error updating alert: $e');
      throw AlertsApiException('Network error: $e');
    }
  }

  /// Delete an alert (Admin/Supervisor only)
  /// DELETE /alerts/{alert_id}
  Future<bool> deleteAlert(String alertId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/alerts/$alertId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw AlertsApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw AlertsApiException('Alert not found', statusCode: 404);
      } else {
        throw AlertsApiException(
          'Failed to delete alert: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlertsApiException) rethrow;
      debugPrint('Error deleting alert: $e');
      throw AlertsApiException('Network error: $e');
    }
  }

  /// Get alert by ID
  /// GET /alerts/{alert_id}
  Future<Alert> getAlert(String alertId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/alerts/$alertId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Alert.fromJson(data);
      } else if (response.statusCode == 404) {
        throw AlertsApiException('Alert not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw AlertsApiException('Unauthorized', statusCode: 401);
      } else {
        throw AlertsApiException(
          'Failed to get alert: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlertsApiException) rethrow;
      debugPrint('Error getting alert: $e');
      throw AlertsApiException('Network error: $e');
    }
  }

  /// Acknowledge an alert
  /// POST /alerts/{alert_id}/acknowledge
  Future<AlertAcknowledgement> acknowledgeAlert(String alertId,
      {String? notes}) async {
    try {
      final headers = await _getAuthHeaders();
      // Always send a JSON body with notes (empty string if null)
      final body = {'notes': notes ?? ''};

      final response = await http.post(
        Uri.parse('$_baseUrl/alerts/$alertId/acknowledge'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AlertAcknowledgement.fromJson(data);
      } else if (response.statusCode == 404) {
        throw AlertsApiException('Alert not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw AlertsApiException('Unauthorized', statusCode: 401);
      } else {
        throw AlertsApiException(
          'Failed to acknowledge alert: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlertsApiException) rethrow;
      debugPrint('Error acknowledging alert: $e');
      throw AlertsApiException('Network error: $e');
    }
  }

  /// Get weather alerts only
  Future<AlertListResponse> getWeatherAlerts(
      {int page = 1, int perPage = 20}) async {
    return listAlerts(
        type: AlertType.weather, isActive: true, page: page, perPage: perPage);
  }

  /// Get disease alerts only
  Future<AlertListResponse> getDiseaseAlerts(
      {int page = 1, int perPage = 20}) async {
    return listAlerts(
        type: AlertType.disease, isActive: true, page: page, perPage: perPage);
  }

  /// Get hazard alerts only
  Future<AlertListResponse> getHazardAlerts(
      {int page = 1, int perPage = 20}) async {
    return listAlerts(
        type: AlertType.hazard, isActive: true, page: page, perPage: perPage);
  }

  /// Get critical alerts only (severe or critical severity)
  Future<AlertListResponse> getCriticalAlerts(
      {int page = 1, int perPage = 20}) async {
    return listAlerts(
        severity: AlertSeverity.critical,
        isActive: true,
        page: page,
        perPage: perPage);
  }

  /// Get total alert counts by type
  Future<Map<String, int>> getAlertCounts() async {
    try {
      final allAlerts = await listAlerts(isActive: true, perPage: 1);
      final weatherAlerts =
          await listAlerts(type: AlertType.weather, isActive: true, perPage: 1);
      final diseaseAlerts =
          await listAlerts(type: AlertType.disease, isActive: true, perPage: 1);
      final hazardAlerts =
          await listAlerts(type: AlertType.hazard, isActive: true, perPage: 1);
      final criticalAlerts = await listAlerts(
          severity: AlertSeverity.critical, isActive: true, perPage: 1);

      return {
        'weather': weatherAlerts.total,
        'disease': diseaseAlerts.total,
        'hazard': hazardAlerts.total,
        'critical': criticalAlerts.total,
        'total': allAlerts.total,
      };
    } catch (e) {
      debugPrint('Error getting alert counts: $e');
      return {
        'weather': 0,
        'disease': 0,
        'hazard': 0,
        'critical': 0,
        'total': 0,
      };
    }
  }
}
