/// Travel API Service
/// Handles CHW movement tracking with GPS breadcrumbs for safety
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
///
/// Endpoints:
/// POST /travel/entries - Create travel entry (GPS breadcrumb)
/// GET /travel/entries - List travel entries
/// GET /travel/summary - Get travel summaries (daily aggregation)
/// GET /travel/current-location - Get current location
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Entry Type Enum - Types of GPS breadcrumb entries
/// start: Beginning of a journey
/// end: End of a journey
/// checkpoint: Intermediate location ping
/// visit: Arrived at a patient/location for a visit
enum EntryType { start, end, checkpoint, visit }

// Legacy TravelType for backwards compatibility with screens
enum TravelType {
  homeVisit,
  outreach,
  training,
  referral,
  supply,
  meeting,
  other
}

/// Travel Entry Model - Represents a GPS breadcrumb entry
class TravelEntry {
  final String id;
  final String chwId;
  final EntryType entryType;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? activity;
  final String? notes;
  final DateTime entryTime;
  final DateTime travelDate;
  final double? distanceKm;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Legacy fields for screen compatibility
  final TravelType type;
  final String? destination;
  final DateTime startTime;
  final DateTime? endTime;
  final double? distance;

  TravelEntry({
    required this.id,
    required this.chwId,
    required this.entryType,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.activity,
    this.notes,
    required this.entryTime,
    required this.travelDate,
    this.distanceKm,
    required this.createdAt,
    required this.updatedAt,
    // Legacy fields with defaults
    this.type = TravelType.other,
    this.destination,
    DateTime? startTime,
    this.endTime,
    this.distance,
  }) : startTime = startTime ?? entryTime;

  factory TravelEntry.fromJson(Map<String, dynamic> json) {
    final entryType = _parseEntryType(json['entry_type']);
    final entryTime =
        DateTime.tryParse(json['entry_time'] ?? '') ?? DateTime.now();

    return TravelEntry(
      id: json['id'] ?? '',
      chwId: json['chw_id'] ?? '',
      entryType: entryType,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      locationName: json['location_name'],
      activity: json['activity'],
      notes: json['notes'],
      entryTime: entryTime,
      travelDate:
          DateTime.tryParse(json['travel_date'] ?? '') ?? DateTime.now(),
      distanceKm: json['distance_km']?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      // Map to legacy fields for screen compatibility
      type: _mapEntryTypeToTravelType(entryType),
      destination: json['location_name'],
      startTime: entryTime,
      endTime: entryType == EntryType.end ? entryTime : null,
      distance: json['distance_km']?.toDouble(),
    );
  }

  static EntryType _parseEntryType(String? type) {
    switch (type?.toLowerCase()) {
      case 'start':
        return EntryType.start;
      case 'end':
        return EntryType.end;
      case 'checkpoint':
        return EntryType.checkpoint;
      case 'visit':
        return EntryType.visit;
      default:
        return EntryType.checkpoint;
    }
  }

  static TravelType _mapEntryTypeToTravelType(EntryType entryType) {
    switch (entryType) {
      case EntryType.visit:
        return TravelType.homeVisit;
      case EntryType.start:
      case EntryType.end:
      case EntryType.checkpoint:
        return TravelType.other;
    }
  }

  String get entryTypeString {
    switch (entryType) {
      case EntryType.start:
        return 'start';
      case EntryType.end:
        return 'end';
      case EntryType.checkpoint:
        return 'checkpoint';
      case EntryType.visit:
        return 'visit';
    }
  }

  String get entryTypeLabel {
    switch (entryType) {
      case EntryType.start:
        return 'Journey Start';
      case EntryType.end:
        return 'Journey End';
      case EntryType.checkpoint:
        return 'Checkpoint';
      case EntryType.visit:
        return 'Visit';
    }
  }

  bool get isOngoing => entryType == EntryType.start;
  Duration? get duration => endTime?.difference(startTime);
}

/// Travel Summary Model - Daily aggregation of travel data
class TravelSummary {
  final String? chwId;
  final DateTime date;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final int checkpointsCount;
  final int visitsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Legacy getters for screen compatibility
  int get totalTrips => visitsCount > 0 ? visitsCount : 1;
  double get totalDistance => totalDistanceKm;
  int get totalDuration => totalDurationMinutes;
  Map<String, int> get tripsByType =>
      {'visit': visitsCount, 'checkpoint': checkpointsCount};

  TravelSummary({
    this.chwId,
    required this.date,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.checkpointsCount,
    required this.visitsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TravelSummary.fromJson(Map<String, dynamic> json) {
    return TravelSummary(
      chwId: json['chw_id'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      totalDistanceKm: (json['total_distance_km'] ?? 0).toDouble(),
      totalDurationMinutes: json['total_duration_minutes'] ?? 0,
      checkpointsCount: json['checkpoints_count'] ?? 0,
      visitsCount: json['visits_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get formattedDuration {
    final hours = totalDurationMinutes ~/ 60;
    final minutes = totalDurationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  double get averageDistance =>
      totalTrips > 0 ? totalDistanceKm / totalTrips : 0.0;
}

/// Current Location Model - Most recent GPS location for a CHW
class CurrentLocation {
  final String? chwId;
  final double latitude;
  final double longitude;
  final String? locationName;
  final DateTime entryTime;
  final String? activity;

  // Legacy field for compatibility
  String? get address => locationName;
  DateTime get timestamp => entryTime;

  CurrentLocation({
    this.chwId,
    required this.latitude,
    required this.longitude,
    this.locationName,
    required this.entryTime,
    this.activity,
  });

  factory CurrentLocation.fromJson(Map<String, dynamic> json) {
    return CurrentLocation(
      chwId: json['chw_id'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      locationName: json['location_name'],
      entryTime: DateTime.tryParse(json['entry_time'] ?? '') ?? DateTime.now(),
      activity: json['activity'],
    );
  }
}

/// Travel Entry List Response
class TravelEntryListResponse {
  final bool success;
  final List<TravelEntry> data;
  final int totalCount;
  final int page;
  final int perPage;

  TravelEntryListResponse({
    required this.success,
    required this.data,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory TravelEntryListResponse.fromJson(Map<String, dynamic> json) {
    return TravelEntryListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => TravelEntry.fromJson(item))
              .toList() ??
          [],
      totalCount:
          json['pagination']?['total_count'] ?? json['total_count'] ?? 0,
      page: json['pagination']?['page'] ?? json['page'] ?? 1,
      perPage: json['pagination']?['per_page'] ?? json['per_page'] ?? 20,
    );
  }
}

/// Travel Summary List Response
class TravelSummaryListResponse {
  final bool success;
  final List<TravelSummary> data;
  final int totalCount;
  final int page;
  final int perPage;

  TravelSummaryListResponse({
    required this.success,
    required this.data,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory TravelSummaryListResponse.fromJson(Map<String, dynamic> json) {
    return TravelSummaryListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => TravelSummary.fromJson(item))
              .toList() ??
          [],
      totalCount:
          json['pagination']?['total_count'] ?? json['total_count'] ?? 0,
      page: json['pagination']?['page'] ?? json['page'] ?? 1,
      perPage: json['pagination']?['per_page'] ?? json['per_page'] ?? 20,
    );
  }
}

/// Travel API Exception
class TravelApiException implements Exception {
  final String message;
  final int? statusCode;

  TravelApiException(this.message, {this.statusCode});

  @override
  String toString() => 'TravelApiException: $message';
}

/// Travel API Service
class TravelApiService {
  static final TravelApiService instance = TravelApiService._internal();
  TravelApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  // ============ TRAVEL ENTRIES ============

  /// Get travel entries
  /// GET /travel/entries
  /// Query params: chw_id (optional), travel_date (optional), page, per_page
  Future<TravelEntryListResponse> getEntries({
    String? chwId,
    DateTime? travelDate,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (chwId != null) queryParams['chw_id'] = chwId;
      if (travelDate != null)
        queryParams['travel_date'] = travelDate.toIso8601String().split('T')[0];
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null)
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];

      final uri = Uri.parse('$_baseUrl/travel/entries')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TravelEntryListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw TravelApiException('Unauthorized', statusCode: 401);
      } else {
        throw TravelApiException(
          'Failed to get travel entries: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TravelApiException) rethrow;
      debugPrint('Error getting travel entries: $e');
      throw TravelApiException('Network error: $e');
    }
  }

  /// Create travel entry (GPS breadcrumb)
  /// POST /travel/entries
  /// Creates a new GPS breadcrumb entry for tracking CHW movement
  Future<TravelEntry> createEntry({
    required EntryType entryType,
    required double latitude,
    required double longitude,
    String? locationName,
    String? activity,
    String? notes,
    DateTime? travelDate,
    double? distanceKm,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'entry_type': _getEntryTypeString(entryType),
        'latitude': latitude,
        'longitude': longitude,
      };

      if (locationName != null) body['location_name'] = locationName;
      if (activity != null) body['activity'] = activity;
      if (notes != null) body['notes'] = notes;
      if (travelDate != null)
        body['travel_date'] = travelDate.toIso8601String().split('T')[0];
      if (distanceKm != null) body['distance_km'] = distanceKm;

      final response = await http.post(
        Uri.parse('$_baseUrl/travel/entries'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return TravelEntry.fromJson(data);
      } else if (response.statusCode == 401) {
        throw TravelApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        throw TravelApiException('Validation error: ${response.body}',
            statusCode: 422);
      } else {
        throw TravelApiException(
          'Failed to create travel entry: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TravelApiException) rethrow;
      debugPrint('Error creating travel entry: $e');
      throw TravelApiException('Network error: $e');
    }
  }

  /// Legacy method - Start travel entry (maps to createEntry with start type)
  Future<TravelEntry> startEntry({
    required TravelType type,
    String? purpose,
    String? destination,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    return createEntry(
      entryType: EntryType.start,
      latitude: latitude ?? 0.0,
      longitude: longitude ?? 0.0,
      locationName: destination,
      activity: purpose ?? _getLegacyTravelTypeString(type),
      notes: notes,
    );
  }

  // ============ SUMMARIES ============

  /// Get travel summaries (daily aggregation)
  /// GET /travel/summary
  /// Query params: chw_id (optional), start_date, end_date
  Future<TravelSummary> getSummary({
    String? chwId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};
      if (chwId != null) queryParams['chw_id'] = chwId;
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null)
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];

      final uri = Uri.parse('$_baseUrl/travel/summary')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // If API returns a list, aggregate or take first
        if (data is List && data.isNotEmpty) {
          return TravelSummary.fromJson(data.first);
        } else if (data['data'] is List && (data['data'] as List).isNotEmpty) {
          return TravelSummary.fromJson(data['data'].first);
        }
        return TravelSummary.fromJson(data);
      } else if (response.statusCode == 401) {
        throw TravelApiException('Unauthorized', statusCode: 401);
      } else {
        throw TravelApiException(
          'Failed to get travel summary: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TravelApiException) rethrow;
      debugPrint('Error getting travel summary: $e');
      throw TravelApiException('Network error: $e');
    }
  }

  /// Get travel summaries list
  /// GET /travel/summary
  Future<TravelSummaryListResponse> getSummaries({
    String? chwId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (chwId != null) queryParams['chw_id'] = chwId;
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null)
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];

      final uri = Uri.parse('$_baseUrl/travel/summary')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TravelSummaryListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw TravelApiException('Unauthorized', statusCode: 401);
      } else {
        throw TravelApiException(
          'Failed to get travel summaries: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TravelApiException) rethrow;
      debugPrint('Error getting travel summaries: $e');
      throw TravelApiException('Network error: $e');
    }
  }

  // ============ CURRENT LOCATION ============

  /// Get current location (most recent GPS breadcrumb)
  /// GET /travel/current-location
  /// Query params: chw_id (optional)
  Future<CurrentLocation> getCurrentLocation({String? chwId}) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};
      if (chwId != null) queryParams['chw_id'] = chwId;

      final uri = Uri.parse('$_baseUrl/travel/current-location')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CurrentLocation.fromJson(data);
      } else if (response.statusCode == 404) {
        throw TravelApiException('No current location found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw TravelApiException('Unauthorized', statusCode: 401);
      } else {
        throw TravelApiException(
          'Failed to get current location: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TravelApiException) rethrow;
      debugPrint('Error getting current location: $e');
      throw TravelApiException('Network error: $e');
    }
  }

  /// Legacy method - Update current location (maps to createEntry with checkpoint)
  Future<CurrentLocation> updateCurrentLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final entry = await createEntry(
      entryType: EntryType.checkpoint,
      latitude: latitude,
      longitude: longitude,
      locationName: address,
    );
    return CurrentLocation(
      latitude: entry.latitude,
      longitude: entry.longitude,
      locationName: entry.locationName,
      entryTime: entry.entryTime,
    );
  }

  /// Get ongoing travel (entries with start type that haven't ended)
  Future<TravelEntry?> getOngoingTravel() async {
    try {
      final response = await getEntries(perPage: 10);
      // Find most recent start entry without corresponding end
      for (final entry in response.data) {
        if (entry.entryType == EntryType.start) {
          return entry;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting ongoing travel: $e');
      return null;
    }
  }

  // ============ HELPER METHODS ============

  String _getEntryTypeString(EntryType type) {
    switch (type) {
      case EntryType.start:
        return 'start';
      case EntryType.end:
        return 'end';
      case EntryType.checkpoint:
        return 'checkpoint';
      case EntryType.visit:
        return 'visit';
    }
  }

  String _getLegacyTravelTypeString(TravelType type) {
    switch (type) {
      case TravelType.homeVisit:
        return 'Home Visit';
      case TravelType.outreach:
        return 'Outreach';
      case TravelType.training:
        return 'Training';
      case TravelType.referral:
        return 'Referral';
      case TravelType.supply:
        return 'Supply Run';
      case TravelType.meeting:
        return 'Meeting';
      case TravelType.other:
        return 'Other';
    }
  }
}
