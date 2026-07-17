import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart' show AIService, AIServiceException;
import '../services/offline_ai_service.dart';
import '../services/connectivity_service.dart';
import './offline_model_provider.dart';

/// Mode for AI inference
enum AIMode {
  online, // Use online API (existing)
  offline, // Use offline llama.cpp model
}

class ChatProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;
  final AIService _aiService = AIService.instance;
  final OfflineAIService _offlineAIService = OfflineAIService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  final Uuid _uuid = const Uuid();

  // Persistence key for AI mode
  static const String _aiModeKey = 'chat_ai_mode';

  // AI mode selection - persisted across app restarts
  AIMode _aiMode = AIMode.online;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentSessionId;
  bool _isInitialized = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get sessionId => _currentSessionId;
  AIMode get aiMode => _aiMode;
  bool get isInitialized => _isInitialized;

  /// Check if offline mode is available (model loaded)
  bool get isOfflineAvailable => _offlineAIService.isModelLoaded;

  /// Check if device is online
  bool get isOnline => _connectivityService.isOnline;

  ChatProvider() {
    // Initialize connectivity service but don't auto-switch modes
    // User manually chooses between online/offline
    _connectivityService.addListener(_handleConnectivityChange);
    // Immediately start async initialization (will complete in background)
    _initialize();
  }

  /// Main initialization that sets up AI mode
  Future<void> _initialize() async {
    await _initializeAIMode();
    _isInitialized = true;
    notifyListeners();
  }

  /// Initialize AI mode from saved preference or auto-detect
  Future<void> _initializeAIMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_aiModeKey);

    if (savedMode != null) {
      // Restore saved mode
      _aiMode = savedMode == 'offline' ? AIMode.offline : AIMode.online;
      debugPrint(
          '💾 Restored AI mode: ${_aiMode == AIMode.online ? "Online" : "Offline"}');
    } else {
      // Smart detection: if offline model is loaded, default to offline
      // Note: This might not work if OfflineModelProvider hasn't loaded yet
      // UI will call checkAndUpdateModeFromModelState() after both providers ready
      if (_offlineAIService.isModelLoaded) {
        _aiMode = AIMode.offline;
        debugPrint('🤖 Offline model detected - defaulting to offline mode');
      } else {
        _aiMode = AIMode.online;
        debugPrint(
            '🌐 No offline model yet - defaulting to online mode (will recheck)');
      }
    }
    notifyListeners();
  }

  /// Called by UI when OfflineModelProvider is available
  /// Rechecks if offline model is loaded and updates mode accordingly
  Future<void> checkAndUpdateModeFromModelState(
      OfflineModelProvider modelProvider) async {
    debugPrint('🔍 Checking mode against model state...');
    debugPrint('  Offline model loaded: ${_offlineAIService.isModelLoaded}');
    debugPrint(
        '  Current mode: ${_aiMode == AIMode.online ? "Online" : "Offline"}');

    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_aiModeKey);
    debugPrint('  Saved mode preference: $savedMode');

    // Only auto-update if:
    // 1. No saved preference exists (user hasn't manually chosen)
    // 2. Model is actually loaded in OfflineAIService
    // 3. Currently in online mode
    if (savedMode == null &&
        _offlineAIService.isModelLoaded &&
        _aiMode == AIMode.online) {
      debugPrint(
          '✅ Model loaded after ChatProvider init - auto-switching to offline mode');
      _aiMode = AIMode.offline;
      await prefs.setString(_aiModeKey, 'offline');
      notifyListeners();
    } else {
      debugPrint('ℹ️  No mode change needed');
    }
  }

  /// Monitor connectivity changes for informational purposes
  /// Does NOT auto-switch modes - user controls that manually
  void _handleConnectivityChange() {
    // Just notify listeners so UI can show connectivity status
    // Don't change the user's selected mode
    notifyListeners();
    debugPrint(
        '📡 Connectivity changed: ${_connectivityService.isOnline ? "Online" : "Offline"}');
  }

  /// Switch AI mode (online/offline)
  Future<void> setAIMode(AIMode mode) async {
    // If switching to offline, check if model is loaded
    if (mode == AIMode.offline && !_offlineAIService.isModelLoaded) {
      debugPrint('❌ Cannot switch to offline mode: no model loaded');
      return;
    }
    _aiMode = mode;

    // Persist the mode
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _aiModeKey, mode == AIMode.online ? 'online' : 'offline');

    notifyListeners();
    debugPrint(
        '✅ AI mode switched to: ${mode == AIMode.online ? "Online" : "Offline"}');
  }

  /// Toggle between online and offline mode
  Future<void> toggleAIMode() async {
    final newMode = _aiMode == AIMode.online ? AIMode.offline : AIMode.online;
    await setAIMode(newMode);
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
      // Check connectivity and model availability
      if (_aiMode == AIMode.offline && !_offlineAIService.isModelLoaded) {
        // No offline model loaded - provide helpful guidance
        final index = _messages.indexWhere((m) => m.id == aiResponse.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
              message: "No offline AI model is currently loaded.\n\n"
                  "To use the AI assistant offline:\n"
                  "1. Tap the menu (⋮) in the top right\n"
                  "2. Select 'Download Models'\n"
                  "3. If you haven't downloaded a model, download one (e.g., Phi-3.5 Mini - 2.4 GB)\n"
                  "4. If you have a downloaded model, tap 'Use Now' or select it from the list\n"
                  "5. Return here to chat\n\n"
                  "Or, connect to the internet to use online mode.");
        }
        final finalMessage = _messages.firstWhere((m) => m.id == aiResponse.id);
        _dbService.createChatMessage(finalMessage);
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Smart routing: Check actual conditions, not just mode
      // If in online mode but no internet AND offline model available, use offline
      final hasInternet = _connectivityService.isOnline;
      final hasOfflineModel = _offlineAIService.isModelLoaded;

      debugPrint('📡 Routing decision:');
      debugPrint('  Mode: ${_aiMode == AIMode.online ? "Online" : "Offline"}');
      debugPrint('  Has Internet: $hasInternet');
      debugPrint('  Has Offline Model: $hasOfflineModel');

      if (_aiMode == AIMode.online) {
        // User wants online mode
        if (hasInternet) {
          // Has internet - try online, fallback to offline on error
          debugPrint('  ✅ Trying online service...');
          try {
            await _handleOnlineResponse(text, patientId, aiResponse);
          } on AIServiceException catch (e) {
            debugPrint('  ⚠️ Online service failed: ${e.message}');
            if (hasOfflineModel && e.isNetworkError) {
              // Fallback to offline model
              debugPrint('  🔄 Falling back to offline model');
              await _handleOfflineResponse(
                  text, patientId, aiResponse, systemPrompt);
            } else {
              // No offline model available, show error
              final index = _messages.indexWhere((m) => m.id == aiResponse.id);
              if (index != -1) {
                _messages[index] = _messages[index].copyWith(
                    message: hasOfflineModel
                        ? "Online service error: ${e.message}\n\nSwitching to offline mode. Please try again."
                        : "Online service error: ${e.message}\n\nNo offline model available. Please check your connection or download an offline model.");
              }
              final finalMessage =
                  _messages.firstWhere((m) => m.id == aiResponse.id);
              _dbService.createChatMessage(finalMessage);
              _isLoading = false;
              notifyListeners();
              return;
            }
          }
        } else if (hasOfflineModel) {
          // No internet but has offline model - auto-fallback to offline
          debugPrint('  ⚠️ No internet, falling back to offline model');
          await _handleOfflineResponse(
              text, patientId, aiResponse, systemPrompt);
        } else {
          // No internet and no offline model - show error
          debugPrint('  ❌ No internet and no offline model');
          final index = _messages.indexWhere((m) => m.id == aiResponse.id);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
                message:
                    "No internet connection and no offline model available.\n\n"
                    "Please connect to the internet or download an offline model.");
          }
          final finalMessage =
              _messages.firstWhere((m) => m.id == aiResponse.id);
          _dbService.createChatMessage(finalMessage);
          _isLoading = false;
          notifyListeners();
          return;
        }
      } else {
        // User wants offline mode - use offline service
        debugPrint('  📱 Using offline service');
        await _handleOfflineResponse(text, patientId, aiResponse, systemPrompt);
      }

      // Once streaming is complete, save the final message
      final finalMessage = _messages.firstWhere((m) => m.id == aiResponse.id);
      _dbService.createChatMessage(finalMessage);
    } catch (e) {
      final index = _messages.indexWhere((m) => m.id == aiResponse.id);
      if (index != -1) {
        _messages[index] =
            _messages[index].copyWith(message: "Sorry, an error occurred: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle online AI response (existing behavior)
  Future<void> _handleOnlineResponse(
      String text, String patientId, ChatMessage aiResponse) async {
    final stream =
        _aiService.generateResponseStream("For patient $patientId: $text");
    String currentResponse = '';

    await for (var token in stream) {
      currentResponse += token;
      final index = _messages.indexWhere((m) => m.id == aiResponse.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(message: currentResponse);
        notifyListeners();
      }
    }
  }

  /// Handle offline AI response (new functionality)
  Future<void> _handleOfflineResponse(String text, String patientId,
      ChatMessage aiResponse, String? systemPrompt) async {
    try {
      // Use the same structured prompt as the online service so the card UI renders correctly
      final effectiveSystemPrompt =
          systemPrompt ?? AIService.offlineSystemPrompt;

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

      // Post-process the completed response: strip markdown, normalise sections, safety filter
      final processed = _aiService.processOfflineResponse(currentResponse);
      final index = _messages.indexWhere((m) => m.id == aiResponse.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(message: processed);
        notifyListeners();
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
                "2. Using a different model\n"
                "3. Switching to online mode if you have internet");
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
