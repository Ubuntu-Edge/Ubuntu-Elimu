import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:denizen_ai/denizen_ai.dart';

/// Educational AI Service powered by the on-device Denizen AI Engine.
/// Provides high-level educational inference workflows (Socratic tutoring,
/// structured summarization, flashcard generation, study plans, research reports, and exam grading).
class OfflineAIService {
  static final OfflineAIService _instance = OfflineAIService._internal();
  static OfflineAIService get instance => _instance;
  OfflineAIService._internal();

  final DenizenAI _denizen = DenizenAI();

  bool get isModelLoaded => _denizen.isModelLoaded;
  OfflineModel? get loadedModel => _denizen.engine.loadedModel;
  String? get loadedModelPath => _denizen.engine.loadedModelPath;

  // ─── Lifecycle ───────────────────────────────────────────────

  Future<void> initialize() async {
    await _denizen.engine.initialize();
  }

  Future<bool> loadModel({
    required String modelPath,
    required OfflineModel model,
    dynamic contextParams,
  }) async {
    return _denizen.engine.loadModel(
      modelPath: modelPath,
      model: model,
      contextParams: contextParams,
    );
  }

  Future<void> unloadModel() async {
    await _denizen.engine.unloadModel();
  }

  // ─── Generation Primitives ───────────────────────────────────

  Stream<String> generateResponseStream({
    required String prompt,
    required String systemPrompt,
    int maxTokens = 512,
    double temperature = 0.2,
    double topP = 0.9,
    int topK = 40,
    double repeatPenalty = 1.1,
  }) {
    return _denizen.engine.generateResponseStream(
      prompt: prompt,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      topK: topK,
      repeatPenalty: repeatPenalty,
    );
  }

  Future<String> generateResponse({
    required String prompt,
    required String systemPrompt,
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
    double repeatPenalty = 1.1,
  }) async {
    return _denizen.engine.generateResponse(
      prompt: prompt,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      topK: topK,
      repeatPenalty: repeatPenalty,
    );
  }

  // ─── JSON Generation (Structured Output) ─────────────────────

  Future<Map<String, dynamic>?> generateJson({
    required String prompt,
    required String systemPrompt,
    int maxTokens = 800,
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final raw = await generateResponse(
          prompt: prompt,
          systemPrompt: systemPrompt,
          maxTokens: maxTokens,
          temperature: 0.2,
        );

        final cleaned = _extractJson(raw);
        if (cleaned != null) {
          return jsonDecode(cleaned) as Map<String, dynamic>;
        }
        debugPrint('⚠️ JSON parse failed attempt $attempt — retrying');
      } catch (e) {
        debugPrint('⚠️ JSON generation error attempt $attempt: $e');
      }
    }
    debugPrint('❌ JSON generation failed after $maxRetries retries');
    return null;
  }

  String? _extractJson(String raw) {
    String cleaned = raw
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;

    return cleaned.substring(start, end + 1);
  }

  // ─── Educational Workflows ───────────────────────────────────

  /// Summarize study chunks into structured JSON notes
  Future<Map<String, dynamic>?> summarizeChunks(List<String> chunks) async {
    final context = chunks.join('\n\n---\n\n');

    return generateJson(
      systemPrompt:
          'You are an expert study assistant. You help students understand '
          'academic material clearly and concisely. Always respond with valid '
          'JSON only. No preamble, no explanation, no markdown fences.',
      prompt: '''
Analyze the following study material and return a JSON object with this exact structure:
{
  "title": "short topic title",
  "summary": "2-3 sentence overview",
  "key_concepts": ["concept 1", "concept 2", "concept 3"],
  "exam_focus": ["important point 1", "important point 2"],
  "notes": ["detailed note 1", "detailed note 2", "detailed note 3"]
}

Study material:
$context
''',
      maxTokens: 800,
    );
  }

  /// Generate flashcards from document material
  Future<List<Map<String, dynamic>>?> generateFlashcards(
    List<String> chunks, {
    int count = 8,
  }) async {
    final context = chunks.join('\n\n---\n\n');

    final result = await generateJson(
      systemPrompt:
          'You are a flashcard generator for students. Create clear, concise '
          'question-answer pairs from the provided material. Always respond '
          'with valid JSON only. No preamble or markdown.',
      prompt: '''
Create exactly $count flashcards from this material. Return a JSON object:
{
  "flashcards": [
    {"q": "question text", "a": "answer text"},
    {"q": "question text", "a": "answer text"}
  ]
}

Material:
$context
''',
      maxTokens: 800,
    );

    if (result == null) return null;
    final list = result['flashcards'];
    if (list is! List) return null;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Generate a multi-day study plan
  Future<Map<String, dynamic>?> generateStudyPlan(
    List<String> chunks, {
    int days = 3,
  }) async {
    final context = chunks.take(3).join('\n\n---\n\n');

    return generateJson(
      systemPrompt:
          'You are an academic study planner. Create structured, realistic '
          'study plans for students. Always respond with valid JSON only.',
      prompt: '''
Create a $days-day study plan for this material. Return:
{
  "plan": [
    {
      "day": 1,
      "focus": "topic name",
      "tasks": ["task 1", "task 2"],
      "duration_minutes": 60
    }
  ],
  "tips": ["study tip 1", "study tip 2"]
}

Material overview:
$context
''',
      maxTokens: 700,
    );
  }

  /// Stream Socratic tutoring response with conversation context
  Stream<String> tutorStream({
    required String userMessage,
    required List<String> contextChunks,
    required List<Map<String, String>> history,
    bool socratic = true,
    String language = 'the same language the student uses',
  }) {
    final context = contextChunks.take(2).join('\n\n---\n\n');

    final recentHistory =
        history.length > 6 ? history.sublist(history.length - 6) : history;
    final historyText = recentHistory.map((m) {
      final role = m['role'] == 'user' ? 'Student' : 'Tutor';
      return '$role: ${m["content"]}';
    }).join('\n');

    final prompt = '''
${historyText.isNotEmpty ? "Previous conversation:\n$historyText\n\n" : ""}Student: $userMessage
''';

    final systemPrompt = socratic
        ? 'You are a Socratic tutor helping a student understand their study '
            'material. Never give direct answers — instead ask guiding questions '
            'that help the student think through the problem themselves. '
            'Be encouraging, patient, and concise. Respond in $language. '
            'Use this document as your knowledge base:\n\n$context'
        : 'You are a clear, direct study assistant helping a student understand '
            'their study material. Answer questions plainly, with worked examples '
            'where useful. Be encouraging, patient, and concise. Respond in '
            '$language. Use this document as your knowledge base:\n\n$context';

    return generateResponseStream(
      systemPrompt: systemPrompt,
      prompt: prompt,
      maxTokens: 400,
      temperature: 0.8,
    );
  }

  /// Grade an exam answer against ground truth
  Future<Map<String, dynamic>?> gradeAnswer({
    required String question,
    required String correctAnswer,
    required String studentAnswer,
  }) async {
    return generateJson(
      systemPrompt:
          'You are an exam grader. Grade student answers fairly and provide '
          'constructive feedback. Always respond with valid JSON only.',
      prompt: '''
Grade this student answer:

Question: $question
Correct answer: $correctAnswer
Student answer: $studentAnswer

Return:
{
  "score": 8,
  "max_score": 10,
  "feedback": "explanation of what was right/wrong",
  "correct": true
}
''',
      maxTokens: 300,
    );
  }

  /// Generate a deep research report
  Future<String> generateReport({
    required String topic,
    required String depth,
    required String length,
    required List<String> contextChunks,
  }) async {
    final context = contextChunks.join('\n\n---\n\n');
    final depthGuidance = _getDepthGuidance(depth);
    final lengthGuidance = _getLengthGuidance(length);

    return generateResponse(
      systemPrompt:
          'You are a research expert who writes clear, comprehensive reports. '
          'Your reports are well-structured, accurate, and use the provided '
          'material as the knowledge base. Write in a professional tone.',
      prompt: '''
Write a research report on the following topic:

Topic: $topic
Depth: $depthGuidance
Length: $lengthGuidance

Based on this material:
$context

Structure your report with clear sections including an introduction, main findings, and conclusion.
''',
      maxTokens: _getMaxTokensForLength(length),
      temperature: 0.7,
    );
  }

  String _getDepthGuidance(String depth) {
    switch (depth.toLowerCase()) {
      case 'shallow':
        return 'Surface level overview with basic concepts';
      case 'medium':
        return 'Moderate depth with key points and explanations';
      case 'deep':
        return 'In-depth analysis with detailed explanations and nuances';
      default:
        return 'Moderate depth with key points and explanations';
    }
  }

  String _getLengthGuidance(String length) {
    switch (length.toLowerCase()) {
      case 'short':
        return 'Concise (2-3 pages equivalent)';
      case 'medium':
        return 'Moderate length (4-6 pages equivalent)';
      case 'long':
        return 'Comprehensive (7-10 pages equivalent)';
      default:
        return 'Moderate length (4-6 pages equivalent)';
    }
  }

  int _getMaxTokensForLength(String length) {
    switch (length.toLowerCase()) {
      case 'short':
        return 600;
      case 'medium':
        return 1200;
      case 'long':
        return 2000;
      default:
        return 1200;
    }
  }

  Future<void> stopGeneration() async {
    await _denizen.engine.stopGeneration();
  }

  Future<void> dispose() async {
    await _denizen.engine.dispose();
  }

  bool get isAvailable => Platform.isAndroid && _denizen.isModelLoaded;

  Map<String, dynamic>? getModelInfo() {
    if (!_denizen.isModelLoaded || loadedModel == null) return null;
    return {
      'name': loadedModel!.name,
      'path': loadedModelPath,
      'status': 'loaded',
    };
  }
}
