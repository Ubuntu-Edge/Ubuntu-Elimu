/// Safety API Service
/// Handles safety check-ins, SOS alerts, and incident reporting (CRITICAL)
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Safety Check Record Model (matches backend API)
class SafetyCheck {
  final String id;
  final String userId;
  final String checkType; // "check-in" or "check-out"
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? notes;
  final DateTime checkTime;
  final DateTime createdAt;

  SafetyCheck({
    required this.id,
    required this.userId,
    required this.checkType,
    this.latitude,
    this.longitude,
    this.locationName,
    this.notes,
    required this.checkTime,
    required this.createdAt,
  });

  factory SafetyCheck.fromJson(Map<String, dynamic> json) {
    return SafetyCheck(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      checkType: json['check_type'] ?? 'check-in',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationName: json['location_name'],
      notes: json['notes'],
      checkTime: DateTime.tryParse(json['check_time'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  // Backward-compatibility getters for existing UI code
  String get type => checkType.replaceAll('-', '_'); // "check-in" -> "check_in"
  DateTime get timestamp => checkTime;
  String? get location => locationName;
}

/// SOS Alert Model (matches backend API)
class SOSAlert {
  final String id;
  final String userId;
  final String alertType;
  final String severity; // e.g., "high"
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String description;
  final String status; // active, resolved, cancelled
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? resolvedById;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SOSAlert({
    required this.id,
    required this.userId,
    required this.alertType,
    required this.severity,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.description,
    required this.status,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolvedById,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      alertType: json['alert_type'] ?? 'other',
      severity: json['severity'] ?? 'high',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationName: json['location_name'],
      description: json['description'] ?? '',
      status: json['status'] ?? 'active',
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.tryParse(json['acknowledged_at'])
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'])
          : null,
      resolvedById: json['resolved_by_id'],
      resolutionNotes: json['resolution_notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Incident Report Model (matches backend API)
class Incident {
  final String id;
  final String userId;
  final String incidentType; // safety, patient, equipment
  final String title;
  final String description;
  final String severity; // low, medium, high
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime incidentDate;
  final String status; // reported, investigating, resolved, closed
  final String? assignedToId;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Incident({
    required this.id,
    required this.userId,
    required this.incidentType,
    required this.title,
    required this.description,
    required this.severity,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.incidentDate,
    required this.status,
    this.assignedToId,
    this.resolvedAt,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      incidentType: json['incident_type'] ?? 'safety',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'medium',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationName: json['location_name'],
      incidentDate:
          DateTime.tryParse(json['incident_date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'reported',
      assignedToId: json['assigned_to_id'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'])
          : null,
      resolutionNotes: json['resolution_notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Emergency Contact Model (matches backend API)
class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? contactRelationship;
  final bool isPrimary;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.contactRelationship,
    required this.isPrimary,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      contactRelationship: json['contact_relationship'],
      isPrimary: json['is_primary'] ?? false,
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'contact_relationship': contactRelationship,
      'is_primary': isPrimary,
      'notes': notes,
    };
  }
}

/// Safety Check History Response (matches backend pagination)
class SafetyCheckHistoryResponse {
  final List<SafetyCheck> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  SafetyCheckHistoryResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory SafetyCheckHistoryResponse.fromJson(Map<String, dynamic> json) {
    return SafetyCheckHistoryResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => SafetyCheck.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}

/// Incident List Response (matches backend pagination)
class IncidentListResponse {
  final List<Incident> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  IncidentListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory IncidentListResponse.fromJson(Map<String, dynamic> json) {
    return IncidentListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => Incident.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}

/// Safety API Exception
class SafetyApiException implements Exception {
  final String message;
  final int? statusCode;

  SafetyApiException(this.message, {this.statusCode});

  @override
  String toString() => 'SafetyApiException: $message';
}

/// Safety API Service
class SafetyApiService {
  static final SafetyApiService instance = SafetyApiService._internal();
  SafetyApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  // ============ CHECK-IN/CHECK-OUT ============

  /// Check in
  /// POST /safety/check-in
  Future<SafetyCheck> checkIn({
    String? locationName,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'check_type': 'check-in',
      };
      if (locationName != null) body['location_name'] = locationName;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (notes != null) body['notes'] = notes;

      final response = await http.post(
        Uri.parse('$_baseUrl/safety/check-in'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SafetyCheck.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to check in: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error checking in: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  /// Check out
  /// POST /safety/check-out
  Future<SafetyCheck> checkOut({
    String? locationName,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'check_type': 'check-out',
      };
      if (locationName != null) body['location_name'] = locationName;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (notes != null) body['notes'] = notes;

      final response = await http.post(
        Uri.parse('$_baseUrl/safety/check-out'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SafetyCheck.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to check out: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error checking out: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  /// Get check history
  /// GET /safety/check-history
  Future<SafetyCheckHistoryResponse> getCheckHistory({
    String? chwId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (chwId != null && chwId.isNotEmpty) {
        queryParams['chw_id'] = chwId;
      }

      final uri = Uri.parse('$_baseUrl/safety/check-history')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SafetyCheckHistoryResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to get check history: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error getting check history: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  // ============ SOS ALERTS ============

  /// Trigger SOS alert
  /// POST /safety/sos-alert
  Future<SOSAlert> triggerSOSAlert({
    required String alertType,
    required String severity,
    double? latitude,
    double? longitude,
    String? locationName,
    required String description,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'alert_type': alertType,
        'severity': severity,
        'description': description,
      };
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (locationName != null) body['location_name'] = locationName;

      final response = await http.post(
        Uri.parse('$_baseUrl/safety/sos-alert'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SOSAlert.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to trigger SOS alert: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error triggering SOS alert: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  /// Get SOS alerts with filtering
  /// GET /safety/sos-alerts
  Future<List<SOSAlert>> getSOSAlerts({
    String? chwId,
    String? statusFilter,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (chwId != null && chwId.isNotEmpty) queryParams['chw_id'] = chwId;
      if (statusFilter != null && statusFilter.isNotEmpty)
        queryParams['status_filter'] = statusFilter;

      final uri = Uri.parse('$_baseUrl/safety/sos-alerts')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['items'] as List<dynamic>?)
                ?.map((e) => SOSAlert.fromJson(e))
                .toList() ??
            [];
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to get SOS alerts: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error getting SOS alerts: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  /// Update SOS alert status
  /// PATCH /safety/sos-alerts/{alert_id}
  Future<SOSAlert> updateSOSAlertStatus({
    required String alertId,
    required String status,
    String? resolutionNotes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'status': status,
      };
      if (resolutionNotes != null) body['resolution_notes'] = resolutionNotes;

      final response = await http.patch(
        Uri.parse('$_baseUrl/safety/sos-alerts/$alertId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SOSAlert.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 404) {
        throw SafetyApiException('SOS alert not found', statusCode: 404);
      } else {
        throw SafetyApiException(
          'Failed to update SOS alert: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error updating SOS alert: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  // ============ INCIDENTS ============

  /// Create incident report
  /// POST /safety/incidents
  Future<Incident> createIncident({
    required String incidentType,
    required String title,
    required String description,
    required String severity,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? incidentDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'incident_type': incidentType,
        'title': title,
        'description': description,
        'severity': severity,
        'incident_date': (incidentDate ?? DateTime.now()).toIso8601String(),
      };
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (locationName != null) body['location_name'] = locationName;

      final response = await http.post(
        Uri.parse('$_baseUrl/safety/incidents'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Incident.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to create incident: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error creating incident: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  /// Get incidents with filtering
  /// GET /safety/incidents
  Future<IncidentListResponse> getIncidents({
    String? chwId,
    String? statusFilter,
    String? incidentType,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (chwId != null && chwId.isNotEmpty) queryParams['chw_id'] = chwId;
      if (statusFilter != null && statusFilter.isNotEmpty)
        queryParams['status_filter'] = statusFilter;
      if (incidentType != null && incidentType.isNotEmpty)
        queryParams['incident_type'] = incidentType;

      final uri = Uri.parse('$_baseUrl/safety/incidents')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return IncidentListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to get incidents: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error getting incidents: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  /// Update incident status
  /// PATCH /safety/incidents/{incident_id}/status
  Future<Incident> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? assignedToId,
    String? resolutionNotes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'status': status,
      };
      if (assignedToId != null) body['assigned_to_id'] = assignedToId;
      if (resolutionNotes != null) body['resolution_notes'] = resolutionNotes;

      final response = await http.patch(
        Uri.parse('$_baseUrl/safety/incidents/$incidentId/status'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Incident.fromJson(data);
      } else if (response.statusCode == 404) {
        throw SafetyApiException('Incident not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to update incident status: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error updating incident status: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  // ============ EMERGENCY CONTACTS ============

  /// Get emergency contacts with filtering
  /// GET /safety/emergency-contacts
  Future<List<EmergencyContact>> getEmergencyContacts({String? chwId}) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};
      if (chwId != null && chwId.isNotEmpty) queryParams['chw_id'] = chwId;

      final uri = Uri.parse('$_baseUrl/safety/emergency-contacts')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['items'] as List<dynamic>?)
                ?.map((item) => EmergencyContact.fromJson(item))
                .toList() ??
            [];
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to get emergency contacts: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error getting emergency contacts: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  /// Add emergency contact
  /// POST /safety/emergency-contacts
  Future<EmergencyContact> addEmergencyContact({
    required String name,
    required String phone,
    String? contactRelationship,
    bool isPrimary = false,
    String? notes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'name': name,
        'phone': phone,
        'is_primary': isPrimary,
      };
      if (contactRelationship != null)
        body['contact_relationship'] = contactRelationship;
      if (notes != null) body['notes'] = notes;

      final response = await http.post(
        Uri.parse('$_baseUrl/safety/emergency-contacts'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return EmergencyContact.fromJson(data);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to add emergency contact: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error adding emergency contact: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  /// Update emergency contact
  /// PATCH /safety/emergency-contacts/{contact_id}
  Future<EmergencyContact> updateEmergencyContact({
    required String contactId,
    String? name,
    String? phone,
    String? contactRelationship,
    bool? isPrimary,
    String? notes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (contactRelationship != null)
        body['relationship'] = contactRelationship;
      if (isPrimary != null) body['is_primary'] = isPrimary;
      if (notes != null) body['notes'] = notes;

      final response = await http.patch(
        Uri.parse('$_baseUrl/safety/emergency-contacts/$contactId'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmergencyContact.fromJson(data);
      } else if (response.statusCode == 404) {
        throw SafetyApiException('Contact not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to update emergency contact: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error updating emergency contact: $e');
      throw SafetyApiException('Network error: $e');
    }
  }

  /// Delete emergency contact
  /// DELETE /safety/emergency-contacts/{contact_id}
  Future<bool> deleteEmergencyContact(String contactId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/safety/emergency-contacts/$contactId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw SafetyApiException('Contact not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw SafetyApiException('Unauthorized', statusCode: 401);
      } else {
        throw SafetyApiException(
          'Failed to delete emergency contact: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is SafetyApiException) rethrow;
      debugPrint('Error deleting emergency contact: $e');
      throw SafetyApiException('Network error: $e');
    }
  }
}
