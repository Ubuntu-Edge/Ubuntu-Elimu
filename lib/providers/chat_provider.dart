import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

import '../models/chat_message.dart';
import '../services/ai/base_ai_provider.dart';
import '../services/crash_logger_service.dart';
import 'settings_provider.dart';

class ChatProvider with ChangeNotifier {
  final Uuid _uuid = const Uuid();

  AIProvider _aiProvider; // ← store the provider directly

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentSessionId;
  bool _isInitialized = false;

  late Box _chatBox;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get sessionId => _currentSessionId;
  bool get isInitialized => _isInitialized;

  ChatProvider(this._aiProvider) {
    // ← accept AIProvider
    _initialize();
  }

  // ← called by ProxyProvider when SettingsProvider changes
  void updateAIProvider(AIProvider provider) {
    _aiProvider = provider;
    notifyListeners();
  }

  Future<void> _initialize() async {
    _chatBox = await Hive.openBox('chat_history');
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> loadChatHistory(String studentId) async {
    _isLoading = true;
    notifyListeners();

    final stored = _chatBox.get(studentId);
    if (stored != null) {
      final list = List<Map>.from(stored);
      _messages = list
          .map((e) => ChatMessage(
                id: e['id'] ?? _uuid.v4(),
                role: e['role'] == 'user' ? MessageRole.user : MessageRole.ai,
                content: e['content'] ?? '',
                timestamp: DateTime.parse(
                    e['timestamp'] ?? DateTime.now().toIso8601String()),
              ))
          .toList();
    } else {
      startNewSession();
    }

    _isLoading = false;
    notifyListeners();
  }

  void startNewSession() {
    _currentSessionId = _uuid.v4();
    final initialMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.ai,
      content:
          'Hello! I am your Ubuntu Elimu assistant. How can I help you study today?',
      timestamp: DateTime.now(),
    );
    _messages = [initialMessage];
    notifyListeners();
  }

  /// Send message with enhanced error handling
  Future<void> sendMessage(String text, SettingsProvider settings,
      {String? systemPrompt}) async {
    if (text.isEmpty) return;

    if (!_isInitialized) {
      int attempts = 0;
      while (!_isInitialized && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (!_isInitialized) return;
    }

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    final aiResponseId = _uuid.v4();
    _messages.add(ChatMessage(
      id: aiResponseId,
      role: MessageRole.ai,
      content: '',
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    try {
      if (settings.activeBackend == AIBackend.local &&
          !settings.isModelDownloaded) {
        _updateMessage(aiResponseId,
            'No offline model loaded. Please download a model in Settings first.');
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (settings.activeBackend == AIBackend.groq &&
          settings.groqApiKey.isEmpty) {
        _updateMessage(aiResponseId,
            'Groq API key not set. Please add your key in Settings.');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Wrap AI response in error boundary
      await _handleAIResponse(text, aiResponseId, systemPrompt);
    } catch (e, stackTrace) {
      debugPrint('❌ Chat error: $e\n$stackTrace');

      // Log to crash reporting
      CrashLoggerService.instance.logCrash(
        message: 'Chat message processing failed',
        error: e,
        stackTrace: stackTrace,
        context: {
          'messageLength': text.length,
          'backend': settings.activeBackend.toString(),
        },
      );

      _updateMessage(aiResponseId, "Sorry, an error occurred: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateMessage(String id, String newContent) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _messages[index] = ChatMessage(
        id: _messages[index].id,
        role: _messages[index].role,
        content: newContent,
        timestamp: _messages[index].timestamp,
      );
      notifyListeners();
    }
  }

  /// Handle AI response generation with timeout protection
  Future<void> _handleAIResponse(
      String text, String aiResponseId, String? systemPrompt) async {
    try {
      final effectiveSystemPrompt = systemPrompt ??
          'You are a helpful study assistant. Guide the student through their learning material.';

      String currentResponse = '';

      // Add timeout to prevent hanging indefinitely
      final stream = _aiProvider.streamGenerate(
        text,
        systemPrompt: effectiveSystemPrompt,
      );

      // Process stream with timeout protection
      try {
        final timeoutStream = stream.timeout(
          const Duration(minutes: 5),
          onTimeout: (sink) {
            debugPrint('⏱️ AI response generation timed out after 5 minutes');
            sink.addError(TimeoutException('Model response timed out'));
          },
        );

        await for (var token in timeoutStream) {
          currentResponse += token;
          _updateMessage(aiResponseId, currentResponse);
        }
      } on TimeoutException catch (e) {
        debugPrint('❌ Generation timeout: $e');
        _updateMessage(
            aiResponseId,
            currentResponse.isEmpty
                ? 'Response generation timed out. Try a shorter question.'
                : '$currentResponse\n\n[Response timeout - partial answer above]');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ AI generation error: $e\n$stackTrace');

      // Log to crash reporting
      CrashLoggerService.instance.logCrash(
        message: 'AI response generation failed',
        error: e,
        stackTrace: stackTrace,
        context: {'backend': _aiProvider.runtimeType.toString()},
      );

      _updateMessage(aiResponseId, "Error during generation: $e");
    }
  }

  Future<void> clearHistory() async {
    await _chatBox.clear();
    _messages = [];
    startNewSession();
  }
}
