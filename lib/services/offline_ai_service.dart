import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart' as llama;

import '../models/offline_model.dart';
import '../models/offline_context_params.dart';

class OfflineAIService {
  static final OfflineAIService _instance = OfflineAIService._internal();
  static OfflineAIService get instance => _instance;
  OfflineAIService._internal();

  llama.LlamaController? _controller;
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  String? _loadedModelPath;
  OfflineModel? _loadedModel;
  bool _stopRequested = false;

  bool get _isUnsupportedAbi {
    return defaultTargetPlatform == TargetPlatform.android &&
        const bool.fromEnvironment('EMULATOR', defaultValue: false);
  }

  bool get isAvailable => _isModelLoaded && !_isUnsupportedAbi;

  // ─── Model Lifecycle ────────────────────────────────────────

  Future<void> initialize() async {
    debugPrint('✅ OfflineAIService initialized');
  }

  Future<bool> loadModel({
    required String modelPath,
    required OfflineModel model,
    OfflineContextParams? contextParams,
  }) async {
    if (_isUnsupportedAbi) {
      debugPrint('⚠️ Emulator detected: skipping model load');
      _loadedModel = model;
      _loadedModelPath = modelPath;
      return false;
    }

    try {
      debugPrint('🔄 Loading model: $modelPath');

      _controller ??= llama.LlamaController();

      await _controller!.loadModel(
        modelPath: modelPath,
        threads: contextParams?.nThreads ?? 4,
        contextSize: contextParams?.nCtx ?? 2048,
        gpuLayers: contextParams?.nGpuLayers ?? 0,
      );

      _isModelLoaded = true;
      _loadedModelPath = modelPath;
      _loadedModel = model;

      debugPrint('✅ Model loaded: ${model.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to load model: $e');
      _isModelLoaded = false;
      return false;
    }
  }

  Future<void> unloadModel() async {
    await _controller?.dispose();
    _controller = null;
    _isModelLoaded = false;
    _loadedModelPath = null;
    _loadedModel = null;
    debugPrint('✅ Model unloaded');
  }

  // ─── Streaming ──────────────────────────────────────────────

  Stream<String> generateResponseStream({
    required String prompt,
    required String systemPrompt,
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
    double repeatPenalty = 1.1,
  }) async* {
    _stopRequested = false;

    if (_controller == null || !_isModelLoaded) {
      yield '⚠️ No model loaded.';
      return;
    }

    try {
      final stream = _controller!.generateChat(
        messages: [
          llama.ChatMessage(role: 'system', content: systemPrompt),
          llama.ChatMessage(role: 'user', content: prompt),
        ],
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        topK: topK,
        repeatPenalty: repeatPenalty,
      );

      await for (final token in stream) {
        if (_stopRequested) {
          await _controller?.stop();
          break;
        }
        yield token;
      }
    } catch (e) {
      yield '❌ Generation error: $e';
    }
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
    final buffer = StringBuffer();

    await for (final token in generateResponseStream(
      prompt: prompt,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      topK: topK,
      repeatPenalty: repeatPenalty,
    )) {
      buffer.write(token);
    }

    return buffer.toString().trim();
  }

  // ─── FIXED JSON GENERATION ──────────────────────────────────

  Future<Map<String, dynamic>?> generateJson({
    required String prompt,
    required String systemPrompt,
    int maxTokens = 800,
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      final raw = await generateResponse(
        prompt: prompt,
        systemPrompt:
        '$systemPrompt\nReturn ONLY valid JSON. No markdown, no text.',
        maxTokens: maxTokens,
      );

      try {
        final clean = raw
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final decoded = jsonDecode(clean);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {'data': decoded};
        }
      } catch (e) {
        debugPrint('⚠️ JSON parse failed (attempt $attempt): $raw');
      }
    }
    return null;
  }

  // ─── Education Features ─────────────────────────────────────

  Future<Map<String, dynamic>?> summarizeChunks(List<String> chunks) {
    return generateJson(
      systemPrompt: 'You are an expert summarizer for students.',
      prompt: 'Summarize:\n\n${chunks.join('\n\n')}',
    );
  }

  Future<List<Map<String, dynamic>>?> generateFlashcards(
      List<String> chunks, {
        int count = 8,
      }) async {
    final result = await generateJson(
      systemPrompt: 'You create flashcards.',
      prompt: 'Generate $count flashcards:\n\n${chunks.join('\n\n')}',
    );

    if (result == null) return null;

    final list = result['flashcards'];
    if (list is! List) return null;

    return list
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>?> generateStudyPlan(
      List<String> chunks, {
        int days = 3,
      }) {
    return generateJson(
      systemPrompt: 'You create study plans.',
      prompt: 'Create a $days-day plan:\n\n${chunks.join('\n\n')}',
    );
  }

  Stream<String> tutorStream({
    required String userMessage,
    required List<String> contextChunks,
    required List<Map<String, String>> history,
  }) {
    return generateResponseStream(
      systemPrompt:
      'You are a helpful tutor.\nContext:\n${contextChunks.join('\n')}',
      prompt: userMessage,
    );
  }

  Future<void> stopGeneration() async {
    _stopRequested = true;
  }

  Future<void> dispose() async {
    await stopGeneration();
    await unloadModel();
  }

  Map<String, dynamic>? getModelInfo() => {
    'name': _loadedModel?.name ?? 'None',
    'path': _loadedModelPath,
    'loaded': _isModelLoaded,
  };

  OfflineModel? get loadedModel => _loadedModel;
  String? get loadedModelPath => _loadedModelPath;
}