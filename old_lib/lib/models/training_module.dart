// CHW Training Module Models
// Implements Built-in CHW Training & Learning
// 
// Features:
// - Quizzes based on actual cases
// - Bite-sized learning modules
// - Progress tracking
// - Competency badges

class TrainingModule {
  final String id;
  final String title;
  final String description;
  final TrainingCategory category;
  final DifficultyLevel difficulty;
  final int estimatedMinutes;
  final List<LearningSection> sections;
  final List<Quiz> quizzes;
  final String? iconAsset;
  final bool isCompleted;
  final double completionPercentage;

  TrainingModule({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.sections,
    required this.quizzes,
    this.iconAsset,
    this.isCompleted = false,
    this.completionPercentage = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'difficulty': difficulty.name,
      'estimatedMinutes': estimatedMinutes,
      'sections': sections.map((s) => s.toMap()).toList(),
      'quizzes': quizzes.map((q) => q.toMap()).toList(),
      'iconAsset': iconAsset,
      'isCompleted': isCompleted,
      'completionPercentage': completionPercentage,
    };
  }

  factory TrainingModule.fromMap(Map<String, dynamic> map) {
    return TrainingModule(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: TrainingCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TrainingCategory.general,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      estimatedMinutes: map['estimatedMinutes'],
      sections: (map['sections'] as List)
          .map((s) => LearningSection.fromMap(s))
          .toList(),
      quizzes: (map['quizzes'] as List)
          .map((q) => Quiz.fromMap(q))
          .toList(),
      iconAsset: map['iconAsset'],
      isCompleted: map['isCompleted'] ?? false,
      completionPercentage: (map['completionPercentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum TrainingCategory {
  maternal,       // Pregnancy & childbirth
  childHealth,    // Under-5 care
  infectious,     // Disease prevention
  chronic,        // Chronic disease management
  emergency,      // Emergency response
  nutrition,      // Nutrition counseling
  mentalHealth,   // Mental health awareness
  community,      // Community engagement
  general,        // General skills
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
}

class LearningSection {
  final String id;
  final String title;
  final String content;
  final LearningContentType contentType;
  final String? imageAsset;
  final String? videoUrl;
  final List<String> keyPoints;
  final bool isCompleted;

  LearningSection({
    required this.id,
    required this.title,
    required this.content,
    required this.contentType,
    this.imageAsset,
    this.videoUrl,
    required this.keyPoints,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'contentType': contentType.name,
      'imageAsset': imageAsset,
      'videoUrl': videoUrl,
      'keyPoints': keyPoints,
      'isCompleted': isCompleted,
    };
  }

  factory LearningSection.fromMap(Map<String, dynamic> map) {
    return LearningSection(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      contentType: LearningContentType.values.firstWhere(
        (e) => e.name == map['contentType'],
        orElse: () => LearningContentType.text,
      ),
      imageAsset: map['imageAsset'],
      videoUrl: map['videoUrl'],
      keyPoints: List<String>.from(map['keyPoints']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

enum LearningContentType {
  text,
  video,
  interactive,
  caseStudy,
}

class Quiz {
  final String id;
  final String title;
  final List<QuizQuestion> questions;
  final int passingScore; // Percentage
  final int? bestScore;
  final int? attempts;
  final DateTime? lastAttemptDate;

  Quiz({
    required this.id,
    required this.title,
    required this.questions,
    this.passingScore = 70,
    this.bestScore,
    this.attempts,
    this.lastAttemptDate,
  });

  bool get isPassed => (bestScore ?? 0) >= passingScore;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'passingScore': passingScore,
      'bestScore': bestScore,
      'attempts': attempts,
      'lastAttemptDate': lastAttemptDate?.toIso8601String(),
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      title: map['title'],
      questions: (map['questions'] as List)
          .map((q) => QuizQuestion.fromMap(q))
          .toList(),
      passingScore: map['passingScore'] ?? 70,
      bestScore: map['bestScore'],
      attempts: map['attempts'],
      lastAttemptDate: map['lastAttemptDate'] != null
          ? DateTime.parse(map['lastAttemptDate'])
          : null,
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final dynamic correctAnswer; // String for single, List<String> for multiple
  final String? explanation;
  final String? relatedCaseId; // Link to actual patient case

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.relatedCaseId,
  });

  bool checkAnswer(dynamic userAnswer) {
    if (type == QuestionType.multipleChoice) {
      return userAnswer == correctAnswer;
    } else if (type == QuestionType.multiSelect) {
      if (userAnswer is List && correctAnswer is List) {
        return Set.from(userAnswer).containsAll(correctAnswer) &&
               Set.from(correctAnswer).containsAll(userAnswer);
      }
    } else if (type == QuestionType.trueFalse) {
      return userAnswer == correctAnswer;
    }
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type.name,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'relatedCaseId': relatedCaseId,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'],
      question: map['question'],
      type: QuestionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: List<String>.from(map['options']),
      correctAnswer: map['correctAnswer'],
      explanation: map['explanation'],
      relatedCaseId: map['relatedCaseId'],
    );
  }
}

enum QuestionType {
  multipleChoice,
  multiSelect,
  trueFalse,
  shortAnswer,
}

/// Badge/Achievement for completing training
class TrainingBadge {
  final String id;
  final String name;
  final String description;
  final String iconAsset;
  final BadgeCategory category;
  final DateTime? earnedDate;
  final bool isEarned;

  TrainingBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.category,
    this.earnedDate,
    this.isEarned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconAsset': iconAsset,
      'category': category.name,
      'earnedDate': earnedDate?.toIso8601String(),
      'isEarned': isEarned,
    };
  }

  factory TrainingBadge.fromMap(Map<String, dynamic> map) {
    return TrainingBadge(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      iconAsset: map['iconAsset'],
      category: BadgeCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => BadgeCategory.learning,
      ),
      earnedDate: map['earnedDate'] != null
          ? DateTime.parse(map['earnedDate'])
          : null,
      isEarned: map['isEarned'] ?? false,
    );
  }
}

enum BadgeCategory {
  learning,      // Completed modules
  performance,   // High quiz scores
  consistency,   // Daily/weekly streaks
  community,     // Helping community
  expertise,     // Mastery in area
}

/// CHW Training Progress
class CHWTrainingProgress {
  final String chwId;
  final int totalModulesCompleted;
  final int totalQuizzesPassed;
  final double averageQuizScore;
  final List<TrainingBadge> badges;
  final int currentStreak; // Days
  final int longestStreak;
  final Map<String, double> categoryProgress; // Category -> completion %
  final DateTime lastTrainingDate;

  CHWTrainingProgress({
    required this.chwId,
    required this.totalModulesCompleted,
    required this.totalQuizzesPassed,
    required this.averageQuizScore,
    required this.badges,
    required this.currentStreak,
    required this.longestStreak,
    required this.categoryProgress,
    required this.lastTrainingDate,
  });

  int get totalBadges => badges.where((b) => b.isEarned).length;

  Map<String, dynamic> toMap() {
    return {
      'chwId': chwId,
      'totalModulesCompleted': totalModulesCompleted,
      'totalQuizzesPassed': totalQuizzesPassed,
      'averageQuizScore': averageQuizScore,
      'badges': badges.map((b) => b.toMap()).toList(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'categoryProgress': categoryProgress,
      'lastTrainingDate': lastTrainingDate.toIso8601String(),
    };
  }

  factory CHWTrainingProgress.fromMap(Map<String, dynamic> map) {
    return CHWTrainingProgress(
      chwId: map['chwId'],
      totalModulesCompleted: map['totalModulesCompleted'],
      totalQuizzesPassed: map['totalQuizzesPassed'],
      averageQuizScore: (map['averageQuizScore'] as num).toDouble(),
      badges: (map['badges'] as List)
          .map((b) => TrainingBadge.fromMap(b))
          .toList(),
      currentStreak: map['currentStreak'],
      longestStreak: map['longestStreak'],
      categoryProgress: Map<String, double>.from(map['categoryProgress']),
      lastTrainingDate: DateTime.parse(map['lastTrainingDate']),
    );
  }
}

/// Daily quiz for quick learning
class DailyQuiz {
  final String id;
  final DateTime date;
  final List<QuizQuestion> questions;
  final String? relatedTopic;
  final bool isCompleted;
  final int? score;

  DailyQuiz({
    required this.id,
    required this.date,
    required this.questions,
    this.relatedTopic,
    this.isCompleted = false,
    this.score,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'questions': questions.map((q) => q.toMap()).toList(),
      'relatedTopic': relatedTopic,
      'isCompleted': isCompleted,
      'score': score,
    };
  }

  factory DailyQuiz.fromMap(Map<String, dynamic> map) {
    return DailyQuiz(
      id: map['id'],
      date: DateTime.parse(map['date']),
      questions: (map['questions'] as List)
          .map((q) => QuizQuestion.fromMap(q))
          .toList(),
      relatedTopic: map['relatedTopic'],
      isCompleted: map['isCompleted'] ?? false,
      score: map['score'],
    );
  }
}
