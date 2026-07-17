/// Training Models for API Integration
/// Supports: Progress, Update Progress, Quiz Submit
library;

/// Training content types
class TrainingContentType {
  static const String video = 'video';
  static const String document = 'document';
  static const String quiz = 'quiz';
  static const String interactive = 'interactive';
  static const String webinar = 'webinar';

  static const List<String> all = [video, document, quiz, interactive, webinar];
}

/// Training status
class TrainingStatus {
  static const String notStarted = 'not_started';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String failed = 'failed';

  static const List<String> all = [notStarted, inProgress, completed, failed];
}

/// Training module model
class TrainingModule {
  final String id;
  final String title;
  final String? description;
  final String contentType;
  final String? contentUrl;
  final int durationMinutes;
  final int orderIndex;
  final bool isRequired;
  final int? passingScore;
  final Map<String, dynamic>? metadata;

  TrainingModule({
    required this.id,
    required this.title,
    this.description,
    required this.contentType,
    this.contentUrl,
    required this.durationMinutes,
    required this.orderIndex,
    required this.isRequired,
    this.passingScore,
    this.metadata,
  });

  factory TrainingModule.fromJson(Map<String, dynamic> json) {
    return TrainingModule(
      id: json['id'] ?? json['module_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      contentType: json['content_type'] ?? 'document',
      contentUrl: json['content_url'],
      durationMinutes: json['duration_minutes'] ?? 0,
      orderIndex: json['order_index'] ?? json['order'] ?? 0,
      isRequired: json['is_required'] ?? true,
      passingScore: json['passing_score'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content_type': contentType,
      'content_url': contentUrl,
      'duration_minutes': durationMinutes,
      'order_index': orderIndex,
      'is_required': isRequired,
      'passing_score': passingScore,
      'metadata': metadata,
    };
  }
}

/// Training progress response
class TrainingProgressResponse {
  final String chwId;
  final List<ModuleProgress> moduleProgress;
  final int totalModules;
  final int completedModules;
  final double overallProgress; // 0.0 to 100.0
  final int totalQuizzesPassed;
  final int totalQuizzesFailed;
  final double averageQuizScore;
  final int totalTimeSpentMinutes;
  final DateTime? lastActivityAt;
  final List<String> certifications;
  final DateTime updatedAt;

  TrainingProgressResponse({
    required this.chwId,
    required this.moduleProgress,
    required this.totalModules,
    required this.completedModules,
    required this.overallProgress,
    required this.totalQuizzesPassed,
    required this.totalQuizzesFailed,
    required this.averageQuizScore,
    required this.totalTimeSpentMinutes,
    this.lastActivityAt,
    required this.certifications,
    required this.updatedAt,
  });

  factory TrainingProgressResponse.fromJson(Map<String, dynamic> json) {
    return TrainingProgressResponse(
      chwId: json['chw_id'] ?? '',
      moduleProgress: (json['module_progress'] as List? ?? [])
          .map((item) => ModuleProgress.fromJson(item))
          .toList(),
      totalModules: json['total_modules'] ?? 0,
      completedModules: json['completed_modules'] ?? 0,
      overallProgress: (json['overall_progress'] ?? 0).toDouble(),
      totalQuizzesPassed: json['total_quizzes_passed'] ?? 0,
      totalQuizzesFailed: json['total_quizzes_failed'] ?? 0,
      averageQuizScore: (json['average_quiz_score'] ?? 0).toDouble(),
      totalTimeSpentMinutes: json['total_time_spent_minutes'] ?? 0,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'])
          : null,
      certifications: List<String>.from(json['certifications'] ?? []),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'chw_id': chwId,
      'total_modules': totalModules,
      'completed_modules': completedModules,
      'overall_progress': overallProgress,
      'total_quizzes_passed': totalQuizzesPassed,
      'total_quizzes_failed': totalQuizzesFailed,
      'average_quiz_score': averageQuizScore,
      'total_time_spent_minutes': totalTimeSpentMinutes,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'certifications': certifications.join(','),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Progress for individual module
class ModuleProgress {
  final String moduleId;
  final String moduleTitle;
  final String status;
  final double progressPercent; // 0.0 to 100.0
  final int timeSpentMinutes;
  final int? quizScore;
  final int? quizAttempts;
  final bool? quizPassed;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastAccessedAt;

  ModuleProgress({
    required this.moduleId,
    required this.moduleTitle,
    required this.status,
    required this.progressPercent,
    required this.timeSpentMinutes,
    this.quizScore,
    this.quizAttempts,
    this.quizPassed,
    this.startedAt,
    this.completedAt,
    this.lastAccessedAt,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['module_id'] ?? '',
      moduleTitle: json['module_title'] ?? '',
      status: json['status'] ?? 'not_started',
      progressPercent:
          (json['progress_percent'] ?? json['progress'] ?? 0).toDouble(),
      timeSpentMinutes: json['time_spent_minutes'] ?? 0,
      quizScore: json['quiz_score'],
      quizAttempts: json['quiz_attempts'],
      quizPassed: json['quiz_passed'],
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module_id': moduleId,
      'module_title': moduleTitle,
      'status': status,
      'progress_percent': progressPercent,
      'time_spent_minutes': timeSpentMinutes,
      'quiz_score': quizScore,
      'quiz_attempts': quizAttempts,
      'quiz_passed': quizPassed,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
    };
  }
}

/// Request model for updating training progress
class TrainingProgressUpdateRequest {
  final String moduleId;
  final double progressPercent; // 0.0 to 100.0
  final int? timeSpentMinutes;
  final String? status;
  final DateTime? lastAccessedAt;
  final Map<String, dynamic>? metadata;

  TrainingProgressUpdateRequest({
    required this.moduleId,
    required this.progressPercent,
    this.timeSpentMinutes,
    this.status,
    this.lastAccessedAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'module_id': moduleId,
      'progress_percent': progressPercent,
    };

    if (timeSpentMinutes != null) map['time_spent_minutes'] = timeSpentMinutes;
    if (status != null) map['status'] = status;
    if (lastAccessedAt != null) {
      map['last_accessed_at'] = lastAccessedAt!.toIso8601String();
    }
    if (metadata != null) map['metadata'] = metadata;

    return map;
  }
}

/// Quiz answer model
class QuizAnswer {
  final String questionId;
  final dynamic answer; // Can be string, int, or list for multiple choice
  final int? timeTakenSeconds;

  QuizAnswer({
    required this.questionId,
    required this.answer,
    this.timeTakenSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'answer': answer,
      if (timeTakenSeconds != null) 'time_taken_seconds': timeTakenSeconds,
    };
  }
}

/// Request model for quiz submission
class QuizSubmitRequest {
  final String moduleId;
  final String quizId;
  final List<QuizAnswer> answers;
  final int totalTimeSeconds;
  final DateTime submittedAt;

  QuizSubmitRequest({
    required this.moduleId,
    required this.quizId,
    required this.answers,
    required this.totalTimeSeconds,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'module_id': moduleId,
      'quiz_id': quizId,
      'answers': answers.map((a) => a.toJson()).toList(),
      'total_time_seconds': totalTimeSeconds,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }
}

/// Response model for quiz result
class QuizResultResponse {
  final String quizId;
  final String moduleId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int passingScore;
  final bool passed;
  final int attemptNumber;
  final List<QuestionResult> questionResults;
  final String? feedback;
  final DateTime completedAt;

  QuizResultResponse({
    required this.quizId,
    required this.moduleId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.passingScore,
    required this.passed,
    required this.attemptNumber,
    required this.questionResults,
    this.feedback,
    required this.completedAt,
  });

  factory QuizResultResponse.fromJson(Map<String, dynamic> json) {
    return QuizResultResponse(
      quizId: json['quiz_id'] ?? '',
      moduleId: json['module_id'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      passingScore: json['passing_score'] ?? 70,
      passed: json['passed'] ?? false,
      attemptNumber: json['attempt_number'] ?? 1,
      questionResults: (json['question_results'] as List? ?? [])
          .map((item) => QuestionResult.fromJson(item))
          .toList(),
      feedback: json['feedback'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'quiz_id': quizId,
      'module_id': moduleId,
      'score': score,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'passing_score': passingScore,
      'passed': passed ? 1 : 0,
      'attempt_number': attemptNumber,
      'feedback': feedback,
      'completed_at': completedAt.toIso8601String(),
    };
  }
}

/// Result for individual quiz question
class QuestionResult {
  final String questionId;
  final String questionText;
  final dynamic userAnswer;
  final dynamic correctAnswer;
  final bool isCorrect;
  final String? explanation;

  QuestionResult({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.explanation,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['question_id'] ?? '',
      questionText: json['question_text'] ?? '',
      userAnswer: json['user_answer'],
      correctAnswer: json['correct_answer'],
      isCorrect: json['is_correct'] ?? false,
      explanation: json['explanation'],
    );
  }
}

/// Exception for training API errors
class TrainingApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  TrainingApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'TrainingApiException: $message (status: $statusCode)';
}

// ==================== LEADERBOARD ====================

/// Leaderboard period types
class LeaderboardPeriod {
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  static const String allTime = 'all_time';

  static const List<String> all = [weekly, monthly, allTime];
}

/// Leaderboard entry model
class LeaderboardEntry {
  final int rank;
  final String chwId;
  final String chwName;
  final String? facilityName;
  final String? avatarUrl;
  final int totalPoints;
  final int modulesCompleted;
  final int quizzesPassed;
  final double averageScore;
  final int totalTimeMinutes;
  final DateTime? lastActivityAt;
  final int? previousRank; // For showing rank change
  final int? rankChange; // Positive = up, Negative = down

  LeaderboardEntry({
    required this.rank,
    required this.chwId,
    required this.chwName,
    this.facilityName,
    this.avatarUrl,
    required this.totalPoints,
    required this.modulesCompleted,
    required this.quizzesPassed,
    required this.averageScore,
    required this.totalTimeMinutes,
    this.lastActivityAt,
    this.previousRank,
    this.rankChange,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      chwId: json['chw_id'] ?? json['user_id'] ?? '',
      chwName: json['chw_name'] ?? json['name'] ?? json['full_name'] ?? '',
      facilityName: json['facility_name'],
      avatarUrl: json['avatar_url'],
      totalPoints: json['total_points'] ?? json['points'] ?? 0,
      modulesCompleted: json['modules_completed'] ?? 0,
      quizzesPassed: json['quizzes_passed'] ?? 0,
      averageScore: (json['average_score'] ?? 0).toDouble(),
      totalTimeMinutes: json['total_time_minutes'] ?? 0,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'])
          : null,
      previousRank: json['previous_rank'],
      rankChange: json['rank_change'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'chw_id': chwId,
      'chw_name': chwName,
      'facility_name': facilityName,
      'avatar_url': avatarUrl,
      'total_points': totalPoints,
      'modules_completed': modulesCompleted,
      'quizzes_passed': quizzesPassed,
      'average_score': averageScore,
      'total_time_minutes': totalTimeMinutes,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'previous_rank': previousRank,
      'rank_change': rankChange,
    };
  }
}

/// Response model for leaderboard
class LeaderboardResponse {
  final String period;
  final List<LeaderboardEntry> entries;
  final int totalParticipants;
  final LeaderboardEntry? currentUserEntry;
  final DateTime? periodStartDate;
  final DateTime? periodEndDate;
  final DateTime generatedAt;

  LeaderboardResponse({
    required this.period,
    required this.entries,
    required this.totalParticipants,
    this.currentUserEntry,
    this.periodStartDate,
    this.periodEndDate,
    required this.generatedAt,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      period: json['period'] ?? 'all_time',
      entries: (json['entries'] as List? ??
              json['leaderboard'] as List? ??
              json['data'] as List? ??
              [])
          .map((item) => LeaderboardEntry.fromJson(item))
          .toList(),
      totalParticipants: json['total_participants'] ?? json['total'] ?? 0,
      currentUserEntry:
          json['current_user_entry'] != null || json['my_entry'] != null
              ? LeaderboardEntry.fromJson(
                  json['current_user_entry'] ?? json['my_entry'])
              : null,
      periodStartDate: json['period_start_date'] != null
          ? DateTime.parse(json['period_start_date'])
          : null,
      periodEndDate: json['period_end_date'] != null
          ? DateTime.parse(json['period_end_date'])
          : null,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'])
          : DateTime.now(),
    );
  }
}
