/// Wellbeing API Service
/// Handles CHW mental health - mood tracking, resources, helplines, support
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
///
/// Endpoints:
/// POST /wellbeing/mood-log - Log mood (score 1-10)
/// GET /wellbeing/mood-history - Get mood history
/// GET /wellbeing/resources - Get wellbeing resources
/// GET /wellbeing/helplines - Get helplines
/// POST /wellbeing/support-request - Create support request
/// GET /wellbeing/tips - Get daily tips
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Mood Type Enum - Emotional states for mood logging
enum MoodType {
  happy,
  excited,
  tired,
  stressed,
  motivated,
  anxious,
  calm,
  frustrated,
  hopeful,
  overwhelmed,
}

/// Resource Category Enum
enum ResourceCategory {
  stress,
  burnout,
  selfCare,
  mindfulness,
  resilience,
  sleep,
  nutrition,
  exercise,
}

/// Resource Type Enum
enum ResourceType {
  article,
  video,
  audio,
  pdf,
  link,
  quiz,
}

/// Support Request Type Enum
enum SupportRequestType {
  counseling,
  peerSupport,
  professionalReferral,
  crisisIntervention,
}

/// Support Request Priority Enum
enum SupportPriority {
  low,
  medium,
  high,
  urgent,
}

/// Mood Log Model
class MoodLog {
  final String id;
  final String chwId;
  final int moodScore; // 1-10 scale
  final MoodType? moodType;
  final DateTime logDate;
  final String? notes;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Legacy getter for screen compatibility
  int get moodRating => (moodScore / 2).ceil(); // Convert 1-10 to 1-5
  DateTime get loggedAt => logDate;

  MoodLog({
    required this.id,
    required this.chwId,
    required this.moodScore,
    this.moodType,
    required this.logDate,
    this.notes,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MoodLog.fromJson(Map<String, dynamic> json) {
    return MoodLog(
      id: json['id'] ?? '',
      chwId: json['chw_id'] ?? '',
      moodScore: json['mood_score'] ?? json['mood_rating'] ?? 5,
      moodType: _parseMoodType(json['mood_type']),
      logDate: DateTime.tryParse(json['log_date'] ?? json['logged_at'] ?? '') ??
          DateTime.now(),
      notes: json['notes'],
      isPrivate: json['is_private'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  static MoodType? _parseMoodType(String? type) {
    if (type == null) return null;
    switch (type.toLowerCase()) {
      case 'happy':
        return MoodType.happy;
      case 'excited':
        return MoodType.excited;
      case 'tired':
        return MoodType.tired;
      case 'stressed':
        return MoodType.stressed;
      case 'motivated':
        return MoodType.motivated;
      case 'anxious':
        return MoodType.anxious;
      case 'calm':
        return MoodType.calm;
      case 'frustrated':
        return MoodType.frustrated;
      case 'hopeful':
        return MoodType.hopeful;
      case 'overwhelmed':
        return MoodType.overwhelmed;
      default:
        return null;
    }
  }

  String get moodLabel {
    if (moodScore >= 9) return 'Excellent';
    if (moodScore >= 7) return 'Good';
    if (moodScore >= 5) return 'Okay';
    if (moodScore >= 3) return 'Not Great';
    return 'Struggling';
  }

  String get moodEmoji {
    if (moodScore >= 9) return '😄';
    if (moodScore >= 7) return '🙂';
    if (moodScore >= 5) return '😐';
    if (moodScore >= 3) return '😕';
    return '😞';
  }

  String get moodTypeLabel {
    if (moodType == null) return '';
    switch (moodType!) {
      case MoodType.happy:
        return 'Happy';
      case MoodType.excited:
        return 'Excited';
      case MoodType.tired:
        return 'Tired';
      case MoodType.stressed:
        return 'Stressed';
      case MoodType.motivated:
        return 'Motivated';
      case MoodType.anxious:
        return 'Anxious';
      case MoodType.calm:
        return 'Calm';
      case MoodType.frustrated:
        return 'Frustrated';
      case MoodType.hopeful:
        return 'Hopeful';
      case MoodType.overwhelmed:
        return 'Overwhelmed';
    }
  }
}

/// Wellbeing Resource Model
class WellbeingResource {
  final String id;
  final String title;
  final String description;
  final ResourceType resourceType;
  final ResourceCategory? category;
  final String? url;
  final String? content;
  final String? thumbnailUrl;
  final int? durationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Legacy getter for screen compatibility
  String get type => resourceTypeString;
  List<String> get tags => category != null ? [categoryString] : [];
  int get readTime => durationMinutes ?? 5;

  WellbeingResource({
    required this.id,
    required this.title,
    required this.description,
    required this.resourceType,
    this.category,
    this.url,
    this.content,
    this.thumbnailUrl,
    this.durationMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WellbeingResource.fromJson(Map<String, dynamic> json) {
    return WellbeingResource(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      resourceType: _parseResourceType(json['resource_type'] ?? json['type']),
      category: _parseResourceCategory(json['category']),
      url: json['url'],
      content: json['content'],
      thumbnailUrl: json['thumbnail_url'],
      durationMinutes: json['duration_minutes'] ?? json['read_time'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  static ResourceType _parseResourceType(String? type) {
    switch (type?.toLowerCase()) {
      case 'article':
        return ResourceType.article;
      case 'video':
        return ResourceType.video;
      case 'audio':
        return ResourceType.audio;
      case 'pdf':
        return ResourceType.pdf;
      case 'link':
        return ResourceType.link;
      case 'quiz':
        return ResourceType.quiz;
      default:
        return ResourceType.article;
    }
  }

  static ResourceCategory? _parseResourceCategory(String? category) {
    if (category == null) return null;
    switch (category.toLowerCase()) {
      case 'stress':
        return ResourceCategory.stress;
      case 'burnout':
        return ResourceCategory.burnout;
      case 'self_care':
        return ResourceCategory.selfCare;
      case 'mindfulness':
        return ResourceCategory.mindfulness;
      case 'resilience':
        return ResourceCategory.resilience;
      case 'sleep':
        return ResourceCategory.sleep;
      case 'nutrition':
        return ResourceCategory.nutrition;
      case 'exercise':
        return ResourceCategory.exercise;
      default:
        return null;
    }
  }

  String get resourceTypeString {
    switch (resourceType) {
      case ResourceType.article:
        return 'article';
      case ResourceType.video:
        return 'video';
      case ResourceType.audio:
        return 'audio';
      case ResourceType.pdf:
        return 'pdf';
      case ResourceType.link:
        return 'link';
      case ResourceType.quiz:
        return 'quiz';
    }
  }

  String get categoryString {
    if (category == null) return '';
    switch (category!) {
      case ResourceCategory.stress:
        return 'stress';
      case ResourceCategory.burnout:
        return 'burnout';
      case ResourceCategory.selfCare:
        return 'self_care';
      case ResourceCategory.mindfulness:
        return 'mindfulness';
      case ResourceCategory.resilience:
        return 'resilience';
      case ResourceCategory.sleep:
        return 'sleep';
      case ResourceCategory.nutrition:
        return 'nutrition';
      case ResourceCategory.exercise:
        return 'exercise';
    }
  }

  String get typeLabel {
    switch (resourceType) {
      case ResourceType.article:
        return 'Article';
      case ResourceType.video:
        return 'Video';
      case ResourceType.audio:
        return 'Audio';
      case ResourceType.pdf:
        return 'PDF';
      case ResourceType.link:
        return 'Link';
      case ResourceType.quiz:
        return 'Quiz';
    }
  }

  String get formattedReadTime => '${durationMinutes ?? 5} min';
}

/// Helpline Model
class Helpline {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? website;
  final String? description;
  final String? hoursOfOperation;
  final String? region;
  final String? category;
  final List<String> services;
  final DateTime createdAt;

  Helpline({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.website,
    this.description,
    this.hoursOfOperation,
    this.region,
    this.category,
    required this.services,
    required this.createdAt,
  });

  factory Helpline.fromJson(Map<String, dynamic> json) {
    return Helpline(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      website: json['website'],
      description: json['description'],
      hoursOfOperation: json['hours_of_operation'],
      region: json['region'],
      category: json['category'],
      services:
          json['services'] != null ? List<String>.from(json['services']) : [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Support Request Model
class SupportRequest {
  final String id;
  final String chwId;
  final SupportRequestType requestType;
  final String description;
  final SupportPriority priority;
  final bool isAnonymous;
  final String status; // pending, assigned, in_progress, completed, cancelled
  final DateTime? scheduledAt;
  final String? assignedTo;
  final String? notes;
  final DateTime requestedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Legacy getter for compatibility
  String get type => requestTypeString;

  SupportRequest({
    required this.id,
    required this.chwId,
    required this.requestType,
    required this.description,
    this.priority = SupportPriority.medium,
    this.isAnonymous = false,
    required this.status,
    this.scheduledAt,
    this.assignedTo,
    this.notes,
    required this.requestedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportRequest.fromJson(Map<String, dynamic> json) {
    return SupportRequest(
      id: json['id'] ?? '',
      chwId: json['chw_id'] ?? '',
      requestType: _parseRequestType(json['request_type'] ?? json['type']),
      description: json['description'] ?? '',
      priority: _parsePriority(json['priority']),
      isAnonymous: json['is_anonymous'] ?? false,
      status: json['status'] ?? 'pending',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'])
          : null,
      assignedTo: json['assigned_to'],
      notes: json['notes'],
      requestedAt:
          DateTime.tryParse(json['requested_at'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  static SupportRequestType _parseRequestType(String? type) {
    switch (type?.toLowerCase()) {
      case 'counseling':
        return SupportRequestType.counseling;
      case 'peer_support':
        return SupportRequestType.peerSupport;
      case 'professional_referral':
        return SupportRequestType.professionalReferral;
      case 'crisis_intervention':
        return SupportRequestType.crisisIntervention;
      default:
        return SupportRequestType.counseling;
    }
  }

  static SupportPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return SupportPriority.low;
      case 'medium':
        return SupportPriority.medium;
      case 'high':
        return SupportPriority.high;
      case 'urgent':
        return SupportPriority.urgent;
      default:
        return SupportPriority.medium;
    }
  }

  String get requestTypeString {
    switch (requestType) {
      case SupportRequestType.counseling:
        return 'counseling';
      case SupportRequestType.peerSupport:
        return 'peer_support';
      case SupportRequestType.professionalReferral:
        return 'professional_referral';
      case SupportRequestType.crisisIntervention:
        return 'crisis_intervention';
    }
  }

  String get typeLabel {
    switch (requestType) {
      case SupportRequestType.counseling:
        return 'Counseling';
      case SupportRequestType.peerSupport:
        return 'Peer Support';
      case SupportRequestType.professionalReferral:
        return 'Professional Referral';
      case SupportRequestType.crisisIntervention:
        return 'Crisis Intervention';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case SupportPriority.low:
        return 'Low';
      case SupportPriority.medium:
        return 'Medium';
      case SupportPriority.high:
        return 'High';
      case SupportPriority.urgent:
        return 'Urgent';
    }
  }
}

/// Daily Tip Model
class DailyTip {
  final String id;
  final String title;
  final String content;
  final String? category;
  final DateTime date;
  final DateTime createdAt;

  DailyTip({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    required this.date,
    required this.createdAt,
  });

  factory DailyTip.fromJson(Map<String, dynamic> json) {
    return DailyTip(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Mood Log List Response
class MoodLogListResponse {
  final bool success;
  final List<MoodLog> data;
  final int totalCount;
  final int page;
  final int perPage;

  MoodLogListResponse({
    required this.success,
    required this.data,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory MoodLogListResponse.fromJson(Map<String, dynamic> json) {
    return MoodLogListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => MoodLog.fromJson(item))
              .toList() ??
          [],
      totalCount: json['pagination']?['total_count'] ?? 0,
      page: json['pagination']?['page'] ?? 1,
      perPage: json['pagination']?['per_page'] ?? 20,
    );
  }
}

/// Resource List Response
class ResourceListResponse {
  final bool success;
  final List<WellbeingResource> data;
  final int totalCount;
  final int page;
  final int perPage;

  ResourceListResponse({
    required this.success,
    required this.data,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory ResourceListResponse.fromJson(Map<String, dynamic> json) {
    return ResourceListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => WellbeingResource.fromJson(item))
              .toList() ??
          [],
      totalCount: json['pagination']?['total_count'] ?? 0,
      page: json['pagination']?['page'] ?? 1,
      perPage: json['pagination']?['per_page'] ?? 20,
    );
  }
}

/// Support Request List Response
class SupportRequestListResponse {
  final bool success;
  final List<SupportRequest> data;
  final int totalCount;
  final int page;
  final int perPage;

  SupportRequestListResponse({
    required this.success,
    required this.data,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory SupportRequestListResponse.fromJson(Map<String, dynamic> json) {
    return SupportRequestListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => SupportRequest.fromJson(item))
              .toList() ??
          [],
      totalCount: json['pagination']?['total_count'] ?? 0,
      page: json['pagination']?['page'] ?? 1,
      perPage: json['pagination']?['per_page'] ?? 20,
    );
  }
}

/// Wellbeing API Exception
class WellbeingApiException implements Exception {
  final String message;
  final int? statusCode;

  WellbeingApiException(this.message, {this.statusCode});

  @override
  String toString() => 'WellbeingApiException: $message';
}

/// Wellbeing API Service
class WellbeingApiService {
  static final WellbeingApiService instance = WellbeingApiService._internal();
  WellbeingApiService._internal();

  static const String _baseUrl =
      'https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1';

  /// Get authorization headers with JWT token
  /// Uses centralized AuthService which handles token refresh
  Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.instance.getAuthHeaders();
  }

  // ============ MOOD LOGS ============

  /// Log mood
  /// POST /wellbeing/mood-log
  /// Body: mood_score (1-10), mood_type (optional), log_date (optional), notes (optional), is_private (optional)
  Future<MoodLog> logMood({
    required int moodScore,
    MoodType? moodType,
    DateTime? logDate,
    String? notes,
    bool isPrivate = false,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'mood_score': moodScore.clamp(1, 10),
      };

      if (moodType != null) body['mood_type'] = _getMoodTypeString(moodType);
      if (logDate != null)
        body['log_date'] = logDate.toIso8601String().split('T')[0];
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;
      if (isPrivate) body['is_private'] = isPrivate;

      final response = await http.post(
        Uri.parse('$_baseUrl/wellbeing/mood-log'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MoodLog.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WellbeingApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        throw WellbeingApiException('Validation error: ${response.body}',
            statusCode: 422);
      } else {
        throw WellbeingApiException(
          'Failed to log mood: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WellbeingApiException) rethrow;
      debugPrint('Error logging mood: $e');
      throw WellbeingApiException('Network error: $e');
    }
  }

  /// Legacy method for backwards compatibility with moodRating (1-5)
  Future<MoodLog> logMoodLegacy({
    required int moodRating,
    String? notes,
    List<String>? stressors,
  }) async {
    // Convert 1-5 scale to 1-10 scale
    final moodScore = (moodRating * 2).clamp(1, 10);
    return logMood(moodScore: moodScore, notes: notes);
  }

  /// Get mood history
  /// GET /wellbeing/mood-history
  /// Query params: start_date, end_date, page, per_page
  Future<MoodLogListResponse> getMoodHistory({
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
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null)
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];

      final uri = Uri.parse('$_baseUrl/wellbeing/mood-history')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MoodLogListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WellbeingApiException('Unauthorized', statusCode: 401);
      } else {
        throw WellbeingApiException(
          'Failed to get mood history: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WellbeingApiException) rethrow;
      debugPrint('Error getting mood history: $e');
      throw WellbeingApiException('Network error: $e');
    }
  }

  /// Legacy method alias
  Future<MoodLogListResponse> getMoodLogs({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) =>
      getMoodHistory(
          startDate: startDate, endDate: endDate, page: page, perPage: perPage);

  // ============ RESOURCES ============

  /// Get wellbeing resources
  /// GET /wellbeing/resources
  /// Query params: category, resource_type, page, per_page
  Future<ResourceListResponse> getResources({
    ResourceCategory? category,
    ResourceType? resourceType,
    String? type, // Legacy support
    List<String>? tags, // Legacy support
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (category != null)
        queryParams['category'] = _getResourceCategoryString(category);
      if (resourceType != null)
        queryParams['resource_type'] = _getResourceTypeString(resourceType);
      // Legacy support
      if (type != null && type.isNotEmpty) queryParams['resource_type'] = type;

      final uri = Uri.parse('$_baseUrl/wellbeing/resources')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ResourceListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WellbeingApiException('Unauthorized', statusCode: 401);
      } else {
        throw WellbeingApiException(
          'Failed to get resources: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WellbeingApiException) rethrow;
      debugPrint('Error getting resources: $e');
      throw WellbeingApiException('Network error: $e');
    }
  }

  /// Get resource by ID
  /// GET /wellbeing/resources/{resource_id}
  Future<WellbeingResource> getResource(String resourceId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/wellbeing/resources/$resourceId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WellbeingResource.fromJson(data);
      } else if (response.statusCode == 404) {
        throw WellbeingApiException('Resource not found', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw WellbeingApiException('Unauthorized', statusCode: 401);
      } else {
        throw WellbeingApiException(
          'Failed to get resource: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WellbeingApiException) rethrow;
      debugPrint('Error getting resource: $e');
      throw WellbeingApiException('Network error: $e');
    }
  }

  // ============ HELPLINES ============

  /// Get helplines
  /// GET /wellbeing/helplines
  /// Query params: region (optional), category (optional)
  Future<List<Helpline>> getHelplines({
    String? region,
    String? category,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};
      if (region != null) queryParams['region'] = region;
      if (category != null) queryParams['category'] = category;

      final uri = Uri.parse('$_baseUrl/wellbeing/helplines')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List<dynamic>?)
                ?.map((item) => Helpline.fromJson(item))
                .toList() ??
            [];
      } else if (response.statusCode == 401) {
        throw WellbeingApiException('Unauthorized', statusCode: 401);
      } else {
        throw WellbeingApiException(
          'Failed to get helplines: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WellbeingApiException) rethrow;
      debugPrint('Error getting helplines: $e');
      throw WellbeingApiException('Network error: $e');
    }
  }

  // ============ SUPPORT REQUESTS ============

  /// Create support request
  /// POST /wellbeing/support-request
  /// Body: request_type, description, priority (optional), is_anonymous (optional)
  Future<SupportRequest> requestSupport({
    required SupportRequestType requestType,
    required String description,
    SupportPriority priority = SupportPriority.medium,
    bool isAnonymous = false,
    // Legacy support
    String? type,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'request_type': type ?? _getSupportRequestTypeString(requestType),
        'description': description,
        'priority': _getSupportPriorityString(priority),
        'is_anonymous': isAnonymous,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/wellbeing/support-request'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return SupportRequest.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WellbeingApiException('Unauthorized', statusCode: 401);
      } else if (response.statusCode == 422) {
        throw WellbeingApiException('Validation error: ${response.body}',
            statusCode: 422);
      } else {
        throw WellbeingApiException(
          'Failed to request support: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WellbeingApiException) rethrow;
      debugPrint('Error requesting support: $e');
      throw WellbeingApiException('Network error: $e');
    }
  }

  /// Get support requests
  /// GET /wellbeing/support-requests
  Future<SupportRequestListResponse> getSupportRequests({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final uri = Uri.parse('$_baseUrl/wellbeing/support-requests')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SupportRequestListResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WellbeingApiException('Unauthorized', statusCode: 401);
      } else {
        throw WellbeingApiException(
          'Failed to get support requests: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WellbeingApiException) rethrow;
      debugPrint('Error getting support requests: $e');
      throw WellbeingApiException('Network error: $e');
    }
  }

  // ============ DAILY TIPS ============

  /// Get daily tips
  /// GET /wellbeing/tips
  Future<DailyTip> getDailyTip() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/wellbeing/tips'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DailyTip.fromJson(data);
      } else if (response.statusCode == 404) {
        throw WellbeingApiException('No tip available', statusCode: 404);
      } else if (response.statusCode == 401) {
        throw WellbeingApiException('Unauthorized', statusCode: 401);
      } else {
        throw WellbeingApiException(
          'Failed to get daily tip: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is WellbeingApiException) rethrow;
      debugPrint('Error getting daily tip: $e');
      throw WellbeingApiException('Network error: $e');
    }
  }

  // ============ HELPER METHODS ============

  /// Get mood trend (average mood over time)
  Future<Map<String, dynamic>> getMoodTrend(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final logs = await getMoodHistory(
          startDate: startDate, endDate: endDate, perPage: 100);
      if (logs.data.isEmpty) {
        return {'average': 0.0, 'trend': 'neutral', 'count': 0};
      }

      final average =
          logs.data.map((l) => l.moodScore).reduce((a, b) => a + b) /
              logs.data.length;
      final trend = average >= 7
          ? 'positive'
          : average <= 4
              ? 'negative'
              : 'neutral';

      return {
        'average': average,
        'trend': trend,
        'count': logs.data.length,
      };
    } catch (e) {
      debugPrint('Error getting mood trend: $e');
      return {'average': 0.0, 'trend': 'neutral', 'count': 0};
    }
  }

  String _getMoodTypeString(MoodType type) {
    switch (type) {
      case MoodType.happy:
        return 'happy';
      case MoodType.excited:
        return 'excited';
      case MoodType.tired:
        return 'tired';
      case MoodType.stressed:
        return 'stressed';
      case MoodType.motivated:
        return 'motivated';
      case MoodType.anxious:
        return 'anxious';
      case MoodType.calm:
        return 'calm';
      case MoodType.frustrated:
        return 'frustrated';
      case MoodType.hopeful:
        return 'hopeful';
      case MoodType.overwhelmed:
        return 'overwhelmed';
    }
  }

  String _getResourceCategoryString(ResourceCategory category) {
    switch (category) {
      case ResourceCategory.stress:
        return 'stress';
      case ResourceCategory.burnout:
        return 'burnout';
      case ResourceCategory.selfCare:
        return 'self_care';
      case ResourceCategory.mindfulness:
        return 'mindfulness';
      case ResourceCategory.resilience:
        return 'resilience';
      case ResourceCategory.sleep:
        return 'sleep';
      case ResourceCategory.nutrition:
        return 'nutrition';
      case ResourceCategory.exercise:
        return 'exercise';
    }
  }

  String _getResourceTypeString(ResourceType type) {
    switch (type) {
      case ResourceType.article:
        return 'article';
      case ResourceType.video:
        return 'video';
      case ResourceType.audio:
        return 'audio';
      case ResourceType.pdf:
        return 'pdf';
      case ResourceType.link:
        return 'link';
      case ResourceType.quiz:
        return 'quiz';
    }
  }

  String _getSupportRequestTypeString(SupportRequestType type) {
    switch (type) {
      case SupportRequestType.counseling:
        return 'counseling';
      case SupportRequestType.peerSupport:
        return 'peer_support';
      case SupportRequestType.professionalReferral:
        return 'professional_referral';
      case SupportRequestType.crisisIntervention:
        return 'crisis_intervention';
    }
  }

  String _getSupportPriorityString(SupportPriority priority) {
    switch (priority) {
      case SupportPriority.low:
        return 'low';
      case SupportPriority.medium:
        return 'medium';
      case SupportPriority.high:
        return 'high';
      case SupportPriority.urgent:
        return 'urgent';
    }
  }
}
