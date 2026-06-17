import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../services/database_service.dart';
import '../services/offline_ai_service.dart';

class ChatProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;
  final OfflineAIService _offlineAIService = OfflineAIService.instance;
  final Uuid _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentSessionId;
  bool _isInitialized = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get sessionId => _currentSessionId;
  bool get isInitialized => _isInitialized;

  /// Check if offline mode is available (model loaded)
  bool get isOfflineAvailable => _offlineAIService.isModelLoaded;

  ChatProvider() {
    // Immediately start async initialization (will complete in background)
    _initialize();
  }

  /// Main initialization
  Future<void> _initialize() async {
    _isInitialized = true;
    notifyListeners();
  }

  // Load the chat history for a specific patient.
  // It will find the most recent session and load its messages.
  Future<void> loadChatHistory(String patientId, {String? patientName}) async {
    _isLoading = true;
    notifyListeners();

    final allMessages = await _dbService.getChatMessagesByPatient(patientId);
    if (allMessages.isNotEmpty) {
      // Find the most recent session ID
      allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _currentSessionId = allMessages.first.sessionId;
      // Filter messages to only include the current session
      _messages =
          allMessages.where((m) => m.sessionId == _currentSessionId).toList();
      // Sort them back into chronological order
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else {
      // If no history, start a fresh session
      startNewSession(patientId, patientName: patientName);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load a specific chat session by ID
  Future<void> loadSpecificSession(String patientId, String sessionId) async {
    _isLoading = true;
    notifyListeners();

    final allMessages = await _dbService.getChatMessagesByPatient(patientId);
    _currentSessionId = sessionId;
    _messages = allMessages.where((m) => m.sessionId == sessionId).toList();
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _isLoading = false;
    notifyListeners();
  }

  // Start a new conversation, which clears the screen and creates a new session ID
  void startNewSession(String patientId, {String? patientName}) {
    _currentSessionId = _uuid.v4();
    final displayName = patientName ?? 'this patient';
    final initialMessage = ChatMessage(
      id: _uuid.v4(),
      patientId: patientId,
      sessionId: _currentSessionId!,
      sender: 'AI',
      message: 'Hello! How can I assist you with $displayName today?',
      timestamp: DateTime.now(),
    );
    _messages = [initialMessage];
    // We don't save the initial message to DB until the user sends something.
    notifyListeners();
  }

  // Send a message and stream the response
  Future<void> sendMessage(String text, String patientId,
      {String? systemPrompt}) async {
    if (text.isEmpty) return;

    // Wait for initialization to complete before sending
    if (!_isInitialized) {
      debugPrint('⏳ Waiting for ChatProvider initialization...');
      // Wait up to 5 seconds for initialization
      int attempts = 0;
      while (!_isInitialized && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (!_isInitialized) {
        debugPrint('❌ ChatProvider initialization timeout');
        return;
      }
      debugPrint('✅ ChatProvider initialized, proceeding with message');
    }

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      patientId: patientId,
      sessionId: _currentSessionId!,
      sender: 'You',
      message: text,
      timestamp: DateTime.now(),
    );

    // If it's the first message of a new session, save the initial AI message too
    if (_messages.length == 1 && _messages.first.sender == 'AI') {
      _dbService.createChatMessage(_messages.first);
    }

    _dbService.createChatMessage(userMessage);
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    // AI Response placeholder
    final aiResponse = ChatMessage(
      id: _uuid.v4(),
      patientId: patientId,
      sessionId: _currentSessionId!,
      sender: 'AI',
      message: '', // Start with an empty message
      timestamp: DateTime.now(),
    );
    _messages.add(aiResponse);
    notifyListeners();

    try {
      if (!_offlineAIService.isModelLoaded) {
        final index = _messages.indexWhere((m) => m.id == aiResponse.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            message: 'No offline model loaded. Please download and load a model first.',
          );
        }
        final finalMessage = _messages.firstWhere((m) => m.id == aiResponse.id);
        _dbService.createChatMessage(finalMessage);
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _handleOfflineResponse(text, patientId, aiResponse, systemPrompt);

      // Once streaming is complete, save the final message
      final finalMessage = _messages.firstWhere((m) => m.id == aiResponse.id);
      _dbService.createChatMessage(finalMessage);
    } catch (e) {
      final index = _messages.indexWhere((m) => m.id == aiResponse.id);
      if (index != -1) {
        _messages[index] =
            _messages[index].copyWith(message: "Sorry, an error occurred: $e");
      }
    } final {
    _isLoading = false;
    notifyListeners();
  }
  }

  /// Handle offline AI response
  Future<void> _handleOfflineResponse(String text, String patientId,
      ChatMessage aiResponse, String? systemPrompt) async {
    try {
      final effectiveSystemPrompt = systemPrompt ??
          'You are a Socratic study tutor. Guide students through their material using questions.';

      String currentResponse = '';

      // Stream raw tokens so the user sees activity while the model generates
      await for (var token in _offlineAIService.generateResponseStream(
        prompt: text,
        systemPrompt: effectiveSystemPrompt,
      )) {
        currentResponse += token;
        final index = _messages.indexWhere((m) => m.id == aiResponse.id);
        if (index != -1) {
          _messages[index] =
              _messages[index].copyWith(message: currentResponse);
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in offline response: $e');
      debugPrint('Stack trace: $stackTrace');

      // Update message with error instead of crashing
      final index = _messages.indexWhere((m) => m.id == aiResponse.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
            message: "Sorry, the offline AI model encountered an error.\n\n"
                "Error: $e\n\n"
                "Try:\n"
                "1. Reloading the model from the Download Models screen\n"
                "2. Using a different model");
        notifyListeners();
      }
    }
  }

  // Permanently deletes all conversations for a patient
  Future<void> deleteAllHistory(String patientId) async {
    await _dbService.deleteChatHistory(patientId);
    _messages = [];
    startNewSession(patientId);
  }
}