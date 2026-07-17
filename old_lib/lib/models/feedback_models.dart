/// Feedback Models for API Integration
/// Supports: Submit, List, Get, Update, Delete
/// Base URL: https://augment-chws-backend-chd8f3b2b4deg0hj.uaenorth-01.azurewebsites.net/api/v1
library;

/// Feedback types (from API spec)
class FeedbackType {
  static const String bug = 'bug';
  static const String suggestion = 'suggestion';
  static const String question = 'question';
  static const String complaint = 'complaint';
  static const String praise = 'praise';
  static const String featureRequest = 'feature_request';
  static const String performance = 'performance';
  static const String other = 'other';
  // Legacy mappings
  static const String feature = 'feature_request';
  static const String improvement = 'suggestion';
  static const String general = 'other';

  static const List<String> all = [
    bug,
    suggestion,
    question,
    complaint,
    praise,
    featureRequest,
    performance,
    other
  ];
}

/// Feedback status (from API spec)
class FeedbackStatus {
  static const String pending = 'pending';
  static const String inReview = 'in_review';
  static const String acknowledged = 'acknowledged';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String closed = 'closed';
  static const String wontFix = 'wont_fix';
  static const String duplicate = 'duplicate';
  // Legacy mapping
  static const String reviewed = 'in_review';

  static const List<String> all = [
    pending,
    inReview,
    acknowledged,
    inProgress,
    resolved,
    closed,
    wontFix,
    duplicate
  ];
}

/// Feedback priority (from API spec)
class FeedbackPriority {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';

  static const List<String> all = [low, medium, high, critical];
}

/// Feedback category (recommended values from API spec)
class FeedbackCategory {
  static const String sync = 'sync';
  static const String ui = 'ui';
  static const String performance = 'performance';
  static const String data = 'data';
  static const String login = 'login';
  static const String general = 'general';

  static const List<String> all = [sync, ui, performance, data, login, general];
}

/// Request model for creating feedback (POST /api/v1/feedback)
class FeedbackCreateRequest {
  final String type; // Required: FeedbackType
  final String category; // Required: FeedbackCategory
  final String title; // Required: min 1, max 200 chars
  final String description; // Required: min 1 char
  final int? rating; // Optional: 1-5
  final String? screenshotUrl; // Optional: max 500 chars
  final List<String>? attachments; // Optional: array of attachment URLs
  final Map<String, dynamic>?
      deviceInfo; // Optional: platform, os_version, device_model, etc.
  final String? appVersion; // Optional: max 20 chars
  final String? errorMessage; // Optional: for bug reports
  final String? stackTrace; // Optional: for bug reports
  final String? stepsToReproduce; // Optional: for bug reports
  final List<String>? tags; // Optional: for categorization

  FeedbackCreateRequest({
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    this.rating,
    this.screenshotUrl,
    this.attachments,
    this.deviceInfo,
    this.appVersion,
    this.errorMessage,
    this.stackTrace,
    this.stepsToReproduce,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': type,
      'category': category,
      'title': title,
      'description': description,
    };

    if (rating != null) map['rating'] = rating;
    if (screenshotUrl != null) map['screenshot_url'] = screenshotUrl;
    if (attachments != null) map['attachments'] = attachments;
    if (deviceInfo != null) map['device_info'] = deviceInfo;
    if (appVersion != null) map['app_version'] = appVersion;
    if (errorMessage != null) map['error_message'] = errorMessage;
    if (stackTrace != null) map['stack_trace'] = stackTrace;
    if (stepsToReproduce != null) map['steps_to_reproduce'] = stepsToReproduce;
    if (tags != null) map['tags'] = tags;

    return map;
  }
}

/// Request model for updating feedback status (PATCH /api/v1/feedback/{id})
/// Only supervisors and admins can update feedback
class FeedbackUpdateRequest {
  final String? status; // FeedbackStatus
  final String? priority; // FeedbackPriority
  final String? responseMessage; // Response to user
  final String? internalNotes; // Internal notes (not shown to user)
  final List<String>? tags; // Tags for categorization

  FeedbackUpdateRequest({
    this.status,
    this.priority,
    this.responseMessage,
    this.internalNotes,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (status != null) map['status'] = status;
    if (priority != null) map['priority'] = priority;
    if (responseMessage != null) map['response_message'] = responseMessage;
    if (internalNotes != null) map['internal_notes'] = internalNotes;
    if (tags != null) map['tags'] = tags;

    return map;
  }
}

/// Response model for feedback (all fields from API spec)
class FeedbackResponse {
  final String id;
  final String userId;
  final String type;
  final String category;
  final String title;
  final String description;
  final int? rating;
  final String? priority;
  final String status;
  final String? screenshotUrl;
  final List<String>? attachments;
  final Map<String, dynamic>? deviceInfo;
  final String? appVersion;
  final String? errorMessage;
  final String? stackTrace;
  final String? stepsToReproduce;
  final String? responseMessage;
  final String? respondedById;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;
  final String? resolvedById;
  final String? resolutionNotes;
  final String? internalNotes;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedbackResponse({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    this.rating,
    this.priority,
    required this.status,
    this.screenshotUrl,
    this.attachments,
    this.deviceInfo,
    this.appVersion,
    this.errorMessage,
    this.stackTrace,
    this.stepsToReproduce,
    this.responseMessage,
    this.respondedById,
    this.respondedAt,
    this.resolvedAt,
    this.resolvedById,
    this.resolutionNotes,
    this.internalNotes,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      id: json['id'] ?? json['feedback_id'] ?? '',
      userId: json['user_id'] ?? json['chw_id'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      title: json['title'] ?? json['subject'] ?? '',
      description: json['description'] ?? json['message'] ?? '',
      rating: json['rating'],
      priority: json['priority'],
      status: json['status'] ?? 'pending',
      screenshotUrl: json['screenshot_url'],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      deviceInfo: json['device_info'] != null
          ? Map<String, dynamic>.from(json['device_info'])
          : null,
      appVersion: json['app_version'],
      errorMessage: json['error_message'],
      stackTrace: json['stack_trace'],
      stepsToReproduce: json['steps_to_reproduce'],
      responseMessage: json['response_message'] ?? json['response'],
      respondedById: json['responded_by_id'] ?? json['responded_by'],
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())
          : null,
      resolvedById: json['resolved_by_id'],
      resolutionNotes: json['resolution_notes'],
      internalNotes: json['internal_notes'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Check if feedback is still pending
  bool get isPending => status == FeedbackStatus.pending;

  /// Check if feedback is resolved or closed
  bool get isResolved =>
      status == FeedbackStatus.resolved || status == FeedbackStatus.closed;

  /// Check if feedback has a response
  bool get hasResponse =>
      responseMessage != null && responseMessage!.isNotEmpty;

  /// Get number of days since feedback was created
  int get daysOpen => DateTime.now().difference(createdAt).inDays;

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'category': category,
      'title': title,
      'description': description,
      'rating': rating,
      'priority': priority,
      'status': status,
      'screenshot_url': screenshotUrl,
      'attachments': attachments?.join(','),
      'device_info': deviceInfo?.toString(),
      'app_version': appVersion,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'steps_to_reproduce': stepsToReproduce,
      'response_message': responseMessage,
      'responded_by_id': respondedById,
      'responded_at': respondedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by_id': resolvedById,
      'resolution_notes': resolutionNotes,
      'internal_notes': internalNotes,
      'tags': tags?.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Response model for feedback list (matches API response format)
class FeedbackListResponse {
  final bool success;
  final List<FeedbackResponse> data;
  final FeedbackPaginationMeta pagination;

  FeedbackListResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory FeedbackListResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackListResponse(
      success: json['success'] ?? true,
      data: (json['data'] as List<dynamic>? ??
              json['feedback'] as List<dynamic>? ??
              [])
          .map(
              (item) => FeedbackResponse.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: FeedbackPaginationMeta.fromJson(
          json['pagination'] ?? json['meta'] ?? {}),
    );
  }
}

/// Pagination metadata for feedback lists (matches API response)
class FeedbackPaginationMeta {
  final int page;
  final int perPage;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  FeedbackPaginationMeta({
    required this.page,
    required this.perPage,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory FeedbackPaginationMeta.fromJson(Map<String, dynamic> json) {
    final page = json['page'] ?? json['current_page'] ?? 1;
    final totalPages = json['total_pages'] ?? json['last_page'] ?? 1;
    return FeedbackPaginationMeta(
      page: page,
      perPage: json['per_page'] ?? json['limit'] ?? 20,
      totalCount: json['total_count'] ?? json['total'] ?? 0,
      totalPages: totalPages,
      hasNext: json['has_next'] ?? (page < totalPages),
      hasPrev: json['has_prev'] ?? (page > 1),
    );
  }

  /// For backwards compatibility
  bool get hasMore => hasNext;
}

/// Exception for feedback API errors
class FeedbackApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  FeedbackApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'FeedbackApiException: $message (status: $statusCode)';
}
