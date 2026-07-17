/// Engagement API Service
/// Handles community events and campaigns
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1/engagement
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/engagement_models.dart';
import 'auth_service.dart';

// Re-export models for convenience
export '../models/engagement_models.dart';

/// Engagement API Service
/// Handles community events and campaigns with correct /engagement endpoints
class EngagementApiService {
  static final EngagementApiService instance = EngagementApiService._internal();
  EngagementApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  // ==================== COMMUNITY EVENTS ====================

  /// Create a new event
  /// POST /engagement/events
  Future<CommunityEvent> createEvent(EventRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/engagement/events'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CommunityEvent.fromJson(data['event'] ?? data);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw EngagementApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw EngagementApiException(
          'Failed to create event: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error creating event: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  /// Get community events with filters
  /// GET /engagement/events
  Future<EventListResponse> getEvents({
    String? eventType,
    String? status,
    String? targetArea,
    DateTime? startDate,
    DateTime? endDate,
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
      if (eventType != null && eventType.isNotEmpty) {
        queryParams['event_type'] = eventType;
      }
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (targetArea != null && targetArea.isNotEmpty) {
        queryParams['target_area'] = targetArea;
      }
      if (startDate != null) {
        queryParams['start_date'] =
            startDate.toIso8601String().replaceAll('Z', '');
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().replaceAll('Z', '');
      }
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final uri = Uri.parse('$_baseUrl/engagement/events')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EventListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else {
        throw EngagementApiException(
          'Failed to get events: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error getting events: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  /// Get event by ID
  /// GET /engagement/events/{event_id}
  Future<CommunityEvent> getEvent(String eventId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/engagement/events/$eventId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CommunityEvent.fromJson(data['event'] ?? data);
      } else if (response.statusCode == 404) {
        throw EngagementApiException('Event not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else {
        throw EngagementApiException(
          'Failed to get event: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error getting event: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  /// Update event
  /// PATCH /engagement/events/{event_id}
  Future<CommunityEvent> updateEvent(
      String eventId, EventRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/engagement/events/$eventId'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CommunityEvent.fromJson(data['event'] ?? data);
      } else if (response.statusCode == 404) {
        throw EngagementApiException('Event not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw EngagementApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw EngagementApiException(
          'Failed to update event: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error updating event: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  /// Delete event
  /// DELETE /engagement/events/{event_id}
  Future<void> deleteEvent(String eventId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/engagement/events/$eventId'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw EngagementApiException('Event not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else {
        throw EngagementApiException(
          'Failed to delete event: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error deleting event: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  // ==================== CAMPAIGNS ====================

  /// Create a new campaign
  /// POST /engagement/campaigns
  Future<Campaign> createCampaign(CampaignRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/engagement/campaigns'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Campaign.fromJson(data['campaign'] ?? data);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw EngagementApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw EngagementApiException(
          'Failed to create campaign: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error creating campaign: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  /// Get campaigns with filters
  /// GET /engagement/campaigns
  Future<CampaignListResponse> getCampaigns({
    String? campaignType,
    String? status,
    String? targetArea,
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
      if (campaignType != null && campaignType.isNotEmpty) {
        queryParams['campaign_type'] = campaignType;
      }
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (targetArea != null && targetArea.isNotEmpty) {
        queryParams['target_area'] = targetArea;
      }
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;

      final uri = Uri.parse('$_baseUrl/engagement/campaigns')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CampaignListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else {
        throw EngagementApiException(
          'Failed to get campaigns: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error getting campaigns: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  /// Get campaign by ID
  /// GET /engagement/campaigns/{campaign_id}
  Future<Campaign> getCampaign(String campaignId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/engagement/campaigns/$campaignId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Campaign.fromJson(data['campaign'] ?? data);
      } else if (response.statusCode == 404) {
        throw EngagementApiException('Campaign not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else {
        throw EngagementApiException(
          'Failed to get campaign: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error getting campaign: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  /// Update campaign
  /// PATCH /engagement/campaigns/{campaign_id}
  Future<Campaign> updateCampaign(
      String campaignId, CampaignRequest request) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$_baseUrl/engagement/campaigns/$campaignId'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Campaign.fromJson(data['campaign'] ?? data);
      } else if (response.statusCode == 404) {
        throw EngagementApiException('Campaign not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw EngagementApiException(
          'Validation error',
          statusCode: 422,
          errors: data['errors'],
        );
      } else {
        throw EngagementApiException(
          'Failed to update campaign: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error updating campaign: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  /// Delete campaign
  /// DELETE /engagement/campaigns/{campaign_id}
  Future<void> deleteCampaign(String campaignId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/engagement/campaigns/$campaignId'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw EngagementApiException('Campaign not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else {
        throw EngagementApiException(
          'Failed to delete campaign: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error deleting campaign: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  // ==================== CAMPAIGN PARTICIPANTS ====================

  /// Register a participant for a campaign
  /// POST /engagement/campaigns/{campaign_id}/register
  Future<CampaignParticipant> registerParticipant(
    String campaignId,
    CampaignRegistrationRequest request,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/engagement/campaigns/$campaignId/register'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CampaignParticipant.fromJson(data['participant'] ?? data);
      } else if (response.statusCode == 404) {
        throw EngagementApiException('Campaign not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 400) {
        throw EngagementApiException(
          'Registration failed',
          statusCode: 400,
        );
      } else {
        throw EngagementApiException(
          'Failed to register participant: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error registering participant: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  /// Get campaign participants
  /// GET /engagement/campaigns/{campaign_id}/participants
  Future<ParticipantListResponse> getParticipants(
    String campaignId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      final uri =
          Uri.parse('$_baseUrl/engagement/campaigns/$campaignId/participants')
              .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ParticipantListResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw EngagementApiException('Campaign not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw EngagementApiException('Unauthorized', statusCode: 401);
      } else {
        throw EngagementApiException(
          'Failed to get participants: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EngagementApiException) rethrow;
      debugPrint('Error getting participants: $e');
      throw EngagementApiException('Network error: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Get upcoming events (status = planned)
  Future<EventListResponse> getUpcomingEvents(
      {int page = 1, int perPage = 20}) async {
    return getEvents(
      status: EventStatus.planned,
      page: page,
      perPage: perPage,
    );
  }

  /// Get ongoing events
  Future<EventListResponse> getOngoingEvents(
      {int page = 1, int perPage = 20}) async {
    return getEvents(
      status: EventStatus.ongoing,
      page: page,
      perPage: perPage,
    );
  }

  /// Get active campaigns
  Future<CampaignListResponse> getActiveCampaigns(
      {int page = 1, int perPage = 20}) async {
    return getCampaigns(
      status: CampaignStatus.active,
      page: page,
      perPage: perPage,
    );
  }

  /// Get events by type
  Future<EventListResponse> getEventsByType(
    String eventType, {
    int page = 1,
    int perPage = 20,
  }) async {
    return getEvents(
      eventType: eventType,
      page: page,
      perPage: perPage,
    );
  }

  /// Get campaigns by type
  Future<CampaignListResponse> getCampaignsByType(
    String campaignType, {
    int page = 1,
    int perPage = 20,
  }) async {
    return getCampaigns(
      campaignType: campaignType,
      page: page,
      perPage: perPage,
    );
  }
}
