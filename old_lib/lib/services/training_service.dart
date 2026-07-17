/// Training Service
/// Implements CHW Training & Learning functionality
///
/// Features:
/// - Training module management
/// - Quiz generation and scoring
/// - Progress tracking
/// - Badge awarding
library;

import 'dart:math';
import '../models/training_module.dart';

class TrainingService {
  static final TrainingService instance = TrainingService._internal();
  factory TrainingService() => instance;
  TrainingService._internal();

  final Random _random = Random();

  // In-memory storage for training progress
  final Map<String, CHWTrainingProgress> _progressCache = {};

  /// Get all available training modules
  List<TrainingModule> getAllModules() {
    return _getDefaultModules();
  }

  /// Get modules by category
  List<TrainingModule> getModulesByCategory(TrainingCategory category) {
    return _getDefaultModules().where((m) => m.category == category).toList();
  }

  /// Get module by ID
  TrainingModule? getModuleById(String moduleId) {
    return _getDefaultModules().where((m) => m.id == moduleId).firstOrNull;
  }

  /// Generate daily quiz
  DailyQuiz generateDailyQuiz(String chwId) {
    // Get questions from different categories
    List<QuizQuestion> questions = [];

    for (var category in TrainingCategory.values) {
      var categoryQuestions = _getQuestionsForCategory(category);
      if (categoryQuestions.isNotEmpty) {
        questions
            .add(categoryQuestions[_random.nextInt(categoryQuestions.length)]);
      }
    }

    // Shuffle and take 5 questions
    questions.shuffle(_random);
    questions = questions.take(5).toList();

    return DailyQuiz(
      id: 'daily_${DateTime.now().toIso8601String().split('T')[0]}',
      date: DateTime.now(),
      questions: questions,
      isCompleted: false,
    );
  }

  /// Complete a quiz and calculate score
  Map<String, dynamic> completeQuiz({
    required String chwId,
    required Quiz quiz,
    required Map<String, dynamic> answers, // questionId -> selectedAnswer
  }) {
    int correctAnswersCount = 0;
    List<Map<String, dynamic>> results = [];

    for (var question in quiz.questions) {
      dynamic selectedAnswer = answers[question.id];
      bool isCorrect = question.checkAnswer(selectedAnswer);

      if (isCorrect) correctAnswersCount++;

      results.add({
        'questionId': question.id,
        'question': question.question,
        'selectedAnswer': selectedAnswer,
        'correctAnswer': question.correctAnswer,
        'isCorrect': isCorrect,
        'explanation': question.explanation,
      });
    }

    double score = quiz.questions.isEmpty
        ? 0
        : (correctAnswersCount / quiz.questions.length) * 100;

    bool passed = score >= quiz.passingScore;

    // Update progress
    _updateProgress(chwId, quiz.id, score, passed);

    return {
      'score': score,
      'correctAnswers': correctAnswersCount,
      'totalQuestions': quiz.questions.length,
      'passed': passed,
      'results': results,
    };
  }

  /// Update CHW training progress
  void _updateProgress(String chwId, String quizId, double score, bool passed) {
    var progress = _progressCache[chwId];

    if (progress == null) {
      // Create new progress
      _progressCache[chwId] = CHWTrainingProgress(
        chwId: chwId,
        totalModulesCompleted: passed ? 1 : 0,
        totalQuizzesPassed: passed ? 1 : 0,
        averageQuizScore: score,
        badges: [],
        currentStreak: 1,
        longestStreak: 1,
        categoryProgress: {},
        lastTrainingDate: DateTime.now(),
      );
    } else {
      // Update existing progress
      int newQuizzesPassed = progress.totalQuizzesPassed + (passed ? 1 : 0);
      double newAverageScore =
          ((progress.averageQuizScore * progress.totalQuizzesPassed) + score) /
              (newQuizzesPassed > 0 ? newQuizzesPassed : 1);

      _progressCache[chwId] = CHWTrainingProgress(
        chwId: chwId,
        totalModulesCompleted:
            progress.totalModulesCompleted + (passed ? 1 : 0),
        totalQuizzesPassed: newQuizzesPassed,
        averageQuizScore: newAverageScore,
        badges: progress.badges,
        currentStreak: progress.currentStreak + 1,
        longestStreak: progress.longestStreak < progress.currentStreak + 1
            ? progress.currentStreak + 1
            : progress.longestStreak,
        categoryProgress: progress.categoryProgress,
        lastTrainingDate: DateTime.now(),
      );
    }

    // Check for badge awards
    _checkAndAwardBadges(chwId);
  }

  /// Calculate level from points
  int _calculateLevel(int points) {
    if (points >= 5000) return 10;
    if (points >= 3500) return 9;
    if (points >= 2500) return 8;
    if (points >= 1800) return 7;
    if (points >= 1200) return 6;
    if (points >= 800) return 5;
    if (points >= 500) return 4;
    if (points >= 300) return 3;
    if (points >= 150) return 2;
    return 1;
  }

  /// Check and award badges
  void _checkAndAwardBadges(String chwId) {
    var progress = _progressCache[chwId];
    if (progress == null) return;

    Set<String> existingBadgeIds = progress.badges.map((b) => b.id).toSet();
    List<TrainingBadge> newBadges = [];

    // First module completed badge
    if (!existingBadgeIds.contains('first_module') &&
        progress.totalModulesCompleted >= 1) {
      newBadges.add(TrainingBadge(
        id: 'first_module',
        name: 'First Steps',
        description: 'Completed your first module',
        iconAsset: 'assets/badges/first_module.png',
        category: BadgeCategory.learning,
        earnedDate: DateTime.now(),
        isEarned: true,
      ));
    }

    // Perfect score badge
    if (!existingBadgeIds.contains('perfect_score') &&
        progress.averageQuizScore >= 100) {
      newBadges.add(TrainingBadge(
        id: 'perfect_score',
        name: 'Perfect Score',
        description: 'Scored 100% on a quiz',
        iconAsset: 'assets/badges/perfect.png',
        category: BadgeCategory.performance,
        earnedDate: DateTime.now(),
        isEarned: true,
      ));
    }

    // Streak badge
    if (!existingBadgeIds.contains('streak_7') && progress.currentStreak >= 7) {
      newBadges.add(TrainingBadge(
        id: 'streak_7',
        name: 'Weekly Warrior',
        description: '7-day learning streak',
        iconAsset: 'assets/badges/streak.png',
        category: BadgeCategory.consistency,
        earnedDate: DateTime.now(),
        isEarned: true,
      ));
    }

    // All modules badge
    if (!existingBadgeIds.contains('all_modules') &&
        progress.totalModulesCompleted >= 6) {
      newBadges.add(TrainingBadge(
        id: 'all_modules',
        name: 'Master CHW',
        description: 'Completed all training modules',
        iconAsset: 'assets/badges/master.png',
        category: BadgeCategory.expertise,
        earnedDate: DateTime.now(),
        isEarned: true,
      ));
    }

    if (newBadges.isNotEmpty) {
      _progressCache[chwId] = CHWTrainingProgress(
        chwId: chwId,
        totalModulesCompleted: progress.totalModulesCompleted,
        totalQuizzesPassed: progress.totalQuizzesPassed,
        averageQuizScore: progress.averageQuizScore,
        badges: [...progress.badges, ...newBadges],
        currentStreak: progress.currentStreak,
        longestStreak: progress.longestStreak,
        categoryProgress: progress.categoryProgress,
        lastTrainingDate: progress.lastTrainingDate,
      );
    }
  }

  /// Get CHW progress
  CHWTrainingProgress getProgress(String chwId) {
    return _progressCache[chwId] ??
        CHWTrainingProgress(
          chwId: chwId,
          totalModulesCompleted: 0,
          totalQuizzesPassed: 0,
          averageQuizScore: 0,
          badges: [],
          currentStreak: 0,
          longestStreak: 0,
          categoryProgress: {},
          lastTrainingDate: DateTime.now(),
        );
  }

  /// Get total points for a CHW
  int getTotalPoints(String chwId) {
    var progress = getProgress(chwId);
    return (progress.averageQuizScore * progress.totalQuizzesPassed).round();
  }

  /// Get current level for a CHW
  int getCurrentLevel(String chwId) {
    return _calculateLevel(getTotalPoints(chwId));
  }

  /// Get leaderboard
  List<Map<String, dynamic>> getLeaderboard() {
    var entries = _progressCache.entries.toList()
      ..sort((a, b) => getTotalPoints(b.key).compareTo(getTotalPoints(a.key)));

    return entries.take(10).map((e) {
      return {
        'chwId': e.key,
        'points': getTotalPoints(e.key),
        'level': getCurrentLevel(e.key),
        'badges': e.value.badges.length,
      };
    }).toList();
  }

  /// Get questions for a category
  List<QuizQuestion> _getQuestionsForCategory(TrainingCategory category) {
    switch (category) {
      case TrainingCategory.general:
        return _generalQuestions;
      case TrainingCategory.maternal:
        return _maternalQuestions;
      case TrainingCategory.childHealth:
        return _childHealthQuestions;
      case TrainingCategory.emergency:
        return _emergencyQuestions;
      case TrainingCategory.infectious:
        return _infectiousQuestions;
      case TrainingCategory.chronic:
        return _chronicQuestions;
      case TrainingCategory.nutrition:
        return _nutritionQuestions;
      case TrainingCategory.mentalHealth:
        return _generalQuestions; // Fallback
      case TrainingCategory.community:
        return _generalQuestions; // Fallback
    }
  }

  /// Create a LearningSection helper
  LearningSection _createSection(
      String id, String title, String content, List<String> keyPoints) {
    return LearningSection(
      id: id,
      title: title,
      content: content,
      contentType: LearningContentType.text,
      keyPoints: keyPoints,
    );
  }

  /// Default training modules
  List<TrainingModule> _getDefaultModules() {
    return [
      TrainingModule(
        id: 'basic_care_1',
        title: 'Introduction to Community Health',
        description: 'Learn the fundamentals of community health work',
        category: TrainingCategory.general,
        difficulty: DifficultyLevel.beginner,
        estimatedMinutes: 30,
        sections: [
          _createSection(
              's1',
              'What is Community Health?',
              'Introduction to community health concepts...',
              ['Community health definition', 'Importance of CHWs']),
          _createSection(
              's2',
              'Role of a CHW',
              'Understanding your role as a CHW...',
              ['Key responsibilities', 'Community liaison']),
          _createSection(
              's3',
              'Ethics and Confidentiality',
              'Ethical considerations in healthcare...',
              ['Patient rights', 'Confidentiality rules']),
          _createSection(
              's4',
              'Communication Skills',
              'Effective communication with patients...',
              ['Active listening', 'Empathy']),
        ],
        quizzes: [],
      ),
      TrainingModule(
        id: 'vital_signs_1',
        title: 'Measuring Vital Signs',
        description: 'How to accurately measure and interpret vital signs',
        category: TrainingCategory.general,
        difficulty: DifficultyLevel.beginner,
        estimatedMinutes: 45,
        sections: [
          _createSection(
              'v1',
              'Temperature Measurement',
              'How to measure body temperature...',
              ['Normal range', 'Methods']),
          _createSection(
              'v2',
              'Blood Pressure Basics',
              'Understanding blood pressure...',
              ['Systolic/Diastolic', 'Normal ranges']),
          _createSection(
              'v3',
              'Pulse and Respiratory Rate',
              'Measuring pulse and breathing...',
              ['Normal heart rate', 'Breathing assessment']),
          _createSection(
              'v4',
              'Recognizing Abnormal Values',
              'When to be concerned...',
              ['Warning signs', 'Referral criteria']),
        ],
        quizzes: [],
      ),
      TrainingModule(
        id: 'maternal_1',
        title: 'Antenatal Care Basics',
        description: 'Essential knowledge for supporting pregnant women',
        category: TrainingCategory.maternal,
        difficulty: DifficultyLevel.intermediate,
        estimatedMinutes: 60,
        sections: [
          _createSection(
              'm1',
              'Pregnancy Stages',
              'Understanding pregnancy trimesters...',
              ['First trimester', 'Second trimester', 'Third trimester']),
          _createSection(
              'm2',
              'Danger Signs in Pregnancy',
              'Recognizing warning signs...',
              ['Severe headache', 'Bleeding', 'Fever']),
          _createSection(
              'm3',
              'Nutrition During Pregnancy',
              'Dietary needs for pregnant women...',
              ['Iron-rich foods', 'Folic acid']),
          _createSection(
              'm4',
              'Birth Preparedness',
              'Preparing for delivery...',
              ['Birth plan', 'Emergency transport']),
        ],
        quizzes: [],
      ),
      TrainingModule(
        id: 'child_health_1',
        title: 'Child Growth Monitoring',
        description: 'Tracking and assessing child development',
        category: TrainingCategory.childHealth,
        difficulty: DifficultyLevel.intermediate,
        estimatedMinutes: 45,
        sections: [
          _createSection(
              'c1',
              'Growth Charts and MUAC',
              'Using growth monitoring tools...',
              ['MUAC tape', 'Growth charts']),
          _createSection(
              'c2',
              'Malnutrition Signs',
              'Recognizing malnutrition...',
              ['Wasting', 'Stunting', 'Underweight']),
          _createSection(
              'c3',
              'Immunization Schedule',
              'Understanding vaccination schedules...',
              ['Key vaccines', 'Timing']),
          _createSection('c4', 'Developmental Milestones',
              'Child development stages...', ['Motor skills', 'Language']),
        ],
        quizzes: [],
      ),
      TrainingModule(
        id: 'emergency_1',
        title: 'Emergency Recognition',
        description: 'Identifying and responding to health emergencies',
        category: TrainingCategory.emergency,
        difficulty: DifficultyLevel.advanced,
        estimatedMinutes: 40,
        sections: [
          _createSection(
              'e1',
              'Red Flag Symptoms',
              'Recognizing emergency signs...',
              ['Difficulty breathing', 'Unconsciousness']),
          _createSection(
              'e2',
              'When to Refer Immediately',
              'Referral criteria...',
              ['Emergency referral', 'Urgent referral']),
          _createSection('e3', 'First Aid Basics', 'Basic first aid skills...',
              ['Bleeding control', 'Recovery position']),
          _createSection(
              'e4',
              'Emergency Transport',
              'Organizing emergency transport...',
              ['Communication', 'Handover']),
        ],
        quizzes: [],
      ),
      TrainingModule(
        id: 'disease_1',
        title: 'Common Disease Management',
        description: 'Managing prevalent community health conditions',
        category: TrainingCategory.infectious,
        difficulty: DifficultyLevel.intermediate,
        estimatedMinutes: 50,
        sections: [
          _createSection('d1', 'Malaria Prevention and Treatment',
              'Understanding malaria...', ['Bed nets', 'ACT treatment']),
          _createSection('d2', 'Diarrheal Disease Management',
              'Managing diarrhea...', ['ORS', 'Zinc']),
          _createSection(
              'd3',
              'Respiratory Infections',
              'Recognizing respiratory illness...',
              ['Pneumonia signs', 'When to refer']),
          _createSection('d4', 'HIV/TB Awareness',
              'Understanding HIV and TB...', ['Prevention', 'Testing']),
        ],
        quizzes: [],
      ),
    ];
  }

  // Sample questions for different categories
  final List<QuizQuestion> _generalQuestions = [
    QuizQuestion(
      id: 'bc_1',
      question: 'What is the normal body temperature range?',
      type: QuestionType.multipleChoice,
      options: ['35.0-36.0°C', '36.1-37.2°C', '38.0-39.0°C', '37.5-38.5°C'],
      correctAnswer: '36.1-37.2°C',
      explanation: 'Normal body temperature is typically 36.1-37.2°C (97-99°F)',
    ),
    QuizQuestion(
      id: 'bc_2',
      question: 'What is the normal resting heart rate for adults?',
      type: QuestionType.multipleChoice,
      options: ['40-50 bpm', '60-100 bpm', '100-120 bpm', '120-140 bpm'],
      correctAnswer: '60-100 bpm',
      explanation: 'Normal adult resting heart rate is 60-100 beats per minute',
    ),
    QuizQuestion(
      id: 'bc_3',
      question: 'What does confidentiality mean in healthcare?',
      type: QuestionType.multipleChoice,
      options: [
        'Sharing patient information with family',
        'Keeping patient information private and secure',
        'Only discussing cases with supervisors',
        'Recording everything in public records',
      ],
      correctAnswer: 'Keeping patient information private and secure',
      explanation:
          'Confidentiality means protecting patient information and only sharing with those who need to know for care',
    ),
  ];

  final List<QuizQuestion> _maternalQuestions = [
    QuizQuestion(
      id: 'mh_1',
      question: 'Which is a danger sign during pregnancy?',
      type: QuestionType.multipleChoice,
      options: [
        'Mild nausea in first trimester',
        'Frequent urination',
        'Severe headache with blurred vision',
        'Increased appetite',
      ],
      correctAnswer: 'Severe headache with blurred vision',
      explanation:
          'Severe headache with blurred vision can indicate preeclampsia, a serious condition requiring immediate care',
    ),
    QuizQuestion(
      id: 'mh_2',
      question: 'How many antenatal visits are recommended during pregnancy?',
      type: QuestionType.multipleChoice,
      options: ['2 visits', '4 visits', '8 visits', '1 visit'],
      correctAnswer: '8 visits',
      explanation:
          'WHO recommends at least 8 antenatal contacts for a positive pregnancy experience',
    ),
  ];

  final List<QuizQuestion> _childHealthQuestions = [
    QuizQuestion(
      id: 'ch_1',
      question: 'What does MUAC measure?',
      type: QuestionType.multipleChoice,
      options: [
        'Height',
        'Weight',
        'Mid-upper arm circumference',
        'Head size',
      ],
      correctAnswer: 'Mid-upper arm circumference',
      explanation:
          'MUAC measures mid-upper arm circumference to quickly assess nutritional status',
    ),
    QuizQuestion(
      id: 'ch_2',
      question:
          'A MUAC measurement below 11.5cm in a child 6-59 months indicates:',
      type: QuestionType.multipleChoice,
      options: [
        'Normal nutrition',
        'Moderate acute malnutrition',
        'Severe acute malnutrition',
        'Obesity',
      ],
      correctAnswer: 'Severe acute malnutrition',
      explanation:
          'MUAC <11.5cm indicates severe acute malnutrition requiring urgent treatment',
    ),
  ];

  final List<QuizQuestion> _emergencyQuestions = [
    QuizQuestion(
      id: 'em_1',
      question: 'Which symptom requires immediate referral?',
      type: QuestionType.multipleChoice,
      options: [
        'Mild fever',
        'Runny nose',
        'Difficulty breathing at rest',
        'Mild headache',
      ],
      correctAnswer: 'Difficulty breathing at rest',
      explanation:
          'Difficulty breathing at rest is a red flag requiring immediate referral',
    ),
    QuizQuestion(
      id: 'em_2',
      question: 'What should you do first if a patient is unconscious?',
      type: QuestionType.multipleChoice,
      options: [
        'Give water',
        'Check for breathing and call for help',
        'Wait and observe',
        'Give medication',
      ],
      correctAnswer: 'Check for breathing and call for help',
      explanation:
          'Always check airway, breathing and call for emergency help first',
    ),
  ];

  final List<QuizQuestion> _infectiousQuestions = [
    QuizQuestion(
      id: 'dm_1',
      question: 'What is the best prevention for malaria?',
      type: QuestionType.multipleChoice,
      options: [
        'Taking vitamins',
        'Sleeping under insecticide-treated bed nets',
        'Drinking clean water',
        'Eating fruits',
      ],
      correctAnswer: 'Sleeping under insecticide-treated bed nets',
      explanation:
          'Insecticide-treated bed nets are one of the most effective malaria prevention methods',
    ),
    QuizQuestion(
      id: 'dm_2',
      question: 'ORS (Oral Rehydration Solution) is used to treat:',
      type: QuestionType.multipleChoice,
      options: [
        'Fever',
        'Cough',
        'Dehydration from diarrhea',
        'Headache',
      ],
      correctAnswer: 'Dehydration from diarrhea',
      explanation: 'ORS replaces fluids and electrolytes lost during diarrhea',
    ),
  ];

  final List<QuizQuestion> _chronicQuestions = [
    QuizQuestion(
      id: 'cr_1',
      question: 'Which is a sign of high blood pressure?',
      type: QuestionType.multipleChoice,
      options: [
        'Low energy',
        'Headaches and dizziness',
        'Increased appetite',
        'Weight loss',
      ],
      correctAnswer: 'Headaches and dizziness',
      explanation:
          'Headaches and dizziness can be symptoms of high blood pressure',
    ),
    QuizQuestion(
      id: 'cr_2',
      question: 'How often should diabetic patients check their blood sugar?',
      type: QuestionType.multipleChoice,
      options: [
        'Once a year',
        'Once a month',
        'Regularly as advised by their doctor',
        'Only when feeling sick',
      ],
      correctAnswer: 'Regularly as advised by their doctor',
      explanation:
          'Diabetic patients should monitor blood sugar regularly as per their treatment plan',
    ),
  ];

  final List<QuizQuestion> _nutritionQuestions = [
    QuizQuestion(
      id: 'nt_1',
      question: 'Exclusive breastfeeding is recommended for how long?',
      type: QuestionType.multipleChoice,
      options: ['3 months', '6 months', '12 months', '2 years'],
      correctAnswer: '6 months',
      explanation:
          'WHO recommends exclusive breastfeeding for the first 6 months of life',
    ),
    QuizQuestion(
      id: 'nt_2',
      question: 'Which food is a good source of iron?',
      type: QuestionType.multipleChoice,
      options: [
        'White rice',
        'Leafy green vegetables',
        'Sugar',
        'Cooking oil',
      ],
      correctAnswer: 'Leafy green vegetables',
      explanation: 'Leafy green vegetables are excellent sources of iron',
    ),
  ];
}
