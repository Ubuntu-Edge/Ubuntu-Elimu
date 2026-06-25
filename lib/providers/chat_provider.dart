import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_message.dart';
import '../services/ai/base_ai_provider.dart';
import 'settings_provider.dart';

class ChatProvider with ChangeNotifier {
  final Uuid _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentSessionId;
  bool _isInitialized = false;
  
  late Box _chatBox;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get sessionId => _currentSessionId;
  bool get isInitialized => _isInitialized;

  AIProvider _aiProvider;

  ChatProvider(this._aiProvider) {
    _initialize();
  }

  void updateAIProvider(AIProvider newProvider) {
    _aiProvider = newProvider;
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
      _messages = list.map((e) => ChatMessage(
        id: e['id'] ?? _uuid.v4(),
        role: e['role'] == 'user' ? MessageRole.user : MessageRole.ai,
        content: e['content'] ?? '',
        timestamp: DateTime.parse(e['timestamp'] ?? DateTime.now().toIso8601String()),
      )).toList();
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
      content: 'Hello! I am your Ubuntu Elimu assistant. How can I help you study today?',
      timestamp: DateTime.now(),
    );
    _messages = [initialMessage];
    notifyListeners();
  }

  Future<void> sendMessage(String text, SettingsProvider settings, {String? systemPrompt}) async {
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
    final aiResponse = ChatMessage(
      id: aiResponseId,
      role: MessageRole.ai,
      content: '',
      timestamp: DateTime.now(),
    );
    _messages.add(aiResponse);
    notifyListeners();

    try {
      final aiProvider = _aiProvider;
      
      // If using local, check if model is loaded
      if (settings.activeBackend == AIBackend.local && !settings.isModelDownloaded) {
         _updateMessage(aiResponseId, 'No offline model loaded. Please download a model in Settings first.');
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _handleAIResponse(aiProvider, text, aiResponseId, systemPrompt);
      
    } catch (e) {
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

  Future<void> _handleAIResponse(AIProvider aiProvider, String text, String aiResponseId, String? systemPrompt) async {
    try {
      final effectiveSystemPrompt = systemPrompt ??
          'You are a helpful study assistant. Guide the student through their learning material.';

      String currentResponse = '';

      await for (var token in aiProvider.streamGenerate(
        text,
        systemPrompt: effectiveSystemPrompt,
      )) {
        currentResponse += token;
        _updateMessage(aiResponseId, currentResponse);
      }
    } catch (e) {
      _updateMessage(aiResponseId, "Error during generation: $e");
    }
  }

  Future<void> clearHistory() async {
    await _chatBox.clear();
    _messages = [];
    startNewSession();
  }
}
