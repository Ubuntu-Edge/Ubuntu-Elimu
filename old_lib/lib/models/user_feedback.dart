import 'dart:convert';

/// Model representing user feedback submitted through the app
class UserFeedback {
  final String id;
  final String userId;
  final FeedbackType type;
  final FeedbackCategory category;
  final String title;
  final String description;
  final int? rating; // 1-5 star rating
  final String? screenshotPath;
  final Map<String, dynamic>? deviceInfo;
  final DateTime createdAt;
  final FeedbackStatus status;
  final String? responseMessage;
  final DateTime? respondedAt;

  UserFeedback({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    this.rating,
    this.screenshotPath,
    this.deviceInfo,
    required this.createdAt,
    this.status = FeedbackStatus.pending,
    this.responseMessage,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'category': category.name,
      'title': title,
      'description': description,
      'rating': rating,
      'screenshot_path': screenshotPath,
      'device_info': deviceInfo != null ? jsonEncode(deviceInfo) : null,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'response_message': responseMessage,
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  factory UserFeedback.fromMap(Map<String, dynamic> map) {
    return UserFeedback(
      id: map['id'],
      userId: map['user_id'],
      type: FeedbackType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FeedbackType.suggestion,
      ),
      category: FeedbackCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => FeedbackCategory.general,
      ),
      title: map['title'],
      description: map['description'],
      rating: map['rating'],
      screenshotPath: map['screenshot_path'],
      deviceInfo: map['device_info'] != null
          ? jsonDecode(map['device_info'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FeedbackStatus.pending,
      ),
      responseMessage: map['response_message'],
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'])
          : null,
    );
  }

  UserFeedback copyWith({
    String? id,
    String? userId,
    FeedbackType? type,
    FeedbackCategory? category,
    String? title,
    String? description,
    int? rating,
    String? screenshotPath,
    Map<String, dynamic>? deviceInfo,
    DateTime? createdAt,
    FeedbackStatus? status,
    String? responseMessage,
    DateTime? respondedAt,
  }) {
    return UserFeedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      responseMessage: responseMessage ?? this.responseMessage,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

/// Types of feedback
enum FeedbackType {
  bug,
  suggestion,
  question,
  complaint,
  praise,
}

/// Categories of feedback
enum FeedbackCategory {
  general,
  patientManagement,
  triage,
  training,
  aiAssistant,
  notifications,
  performance,
  userInterface,
  dataSync,
  security,
  other,
}

/// Status of feedback
enum FeedbackStatus {
  pending,
  inReview,
  resolved,
  closed,
}

/// Extension methods for FeedbackType
extension FeedbackTypeExtension on FeedbackType {
  String get displayName {
    switch (this) {
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.suggestion:
        return 'Suggestion';
      case FeedbackType.question:
        return 'Question';
      case FeedbackType.complaint:
        return 'Complaint';
      case FeedbackType.praise:
        return 'Praise';
    }
  }

  String get icon {
    switch (this) {
      case FeedbackType.bug:
        return '🐛';
      case FeedbackType.suggestion:
        return '💡';
      case FeedbackType.question:
        return '❓';
      case FeedbackType.complaint:
        return '😕';
      case FeedbackType.praise:
        return '⭐';
    }
  }
}

/// Extension methods for FeedbackCategory
extension FeedbackCategoryExtension on FeedbackCategory {
  String get displayName {
    switch (this) {
      case FeedbackCategory.general:
        return 'General';
      case FeedbackCategory.patientManagement:
        return 'Patient Management';
      case FeedbackCategory.triage:
        return 'Smart Triage';
      case FeedbackCategory.training:
        return 'Training';
      case FeedbackCategory.aiAssistant:
        return 'AI Assistant';
      case FeedbackCategory.notifications:
        return 'Notifications';
      case FeedbackCategory.performance:
        return 'Performance';
      case FeedbackCategory.userInterface:
        return 'User Interface';
      case FeedbackCategory.dataSync:
        return 'Data & Sync';
      case FeedbackCategory.security:
        return 'Security';
      case FeedbackCategory.other:
        return 'Other';
    }
  }
}

/// Extension methods for FeedbackStatus
extension FeedbackStatusExtension on FeedbackStatus {
  String get displayName {
    switch (this) {
      case FeedbackStatus.pending:
        return 'Pending';
      case FeedbackStatus.inReview:
        return 'In Review';
      case FeedbackStatus.resolved:
        return 'Resolved';
      case FeedbackStatus.closed:
        return 'Closed';
    }
  }
}
