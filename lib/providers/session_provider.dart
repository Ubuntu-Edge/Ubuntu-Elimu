import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:denizen_ai/denizen_ai.dart';
import '../models/chat_message.dart';
import 'document_provider.dart';

class SessionProvider with ChangeNotifier {
  final DenizenAI _denizen = DenizenAI();
  DenizenSession? _activeSession;

  List<ChatMessage> _chatMessages = [];
  bool _isGenerating = false;
  bool _isOffline = true;
  String? _activeDocumentId;
  String _activeSessionTitle = 'Socratic Tutor';
  String _activeSessionMeta = 'Offline · EN';

  late Box _sessionBox;
  bool _isInitialized = false;

  List<ChatMessage> get chatMessages => _chatMessages;
  bool get isGenerating => _isGenerating;
  bool get isOffline => _isOffline;
  String get activeSessionTitle => _activeSessionTitle;
  String get activeSessionMeta => _activeSessionMeta;
  String? get activeDocumentId => _activeDocumentId;

  // ─── Init ────────────────────────────────────────────────────

  Future<void> init() async {
    _sessionBox = await Hive.openBox('tutor_sessions');
    _loadSession();
    _rebuildDenizenSession();
    _isInitialized = true;
    notifyListeners();
  }

  void _rebuildDenizenSession({
    bool socratic = true,
    String language = 'English',
    List<String>? contextChunks,
  }) {
    final context = (contextChunks != null && contextChunks.isNotEmpty)
        ? '\n\n[DOCUMENT KNOWLEDGE BASE]:\n${contextChunks.take(3).join('\n---\n')}\n'
        : '';

    final systemPrompt = socratic
        ? 'You are an expert Socratic tutor for Ubuntu Elimu. You guide students step-by-step through questions instead of directly giving answers. Encourage critical thinking, be patient, and respond in $language.$context'
        : 'You are a direct, clear study assistant for Ubuntu Elimu. Answer questions plainly with worked examples where helpful. Be encouraging, concise, and respond in $language.$context';

    _activeSession = _denizen.createSession(
      systemPrompt: systemPrompt,
      maxTokens: 2048,
    );
  }

  void _loadSession() {
    final stored = _sessionBox.get('messages');
    if (stored != null) {
      final list = List<Map>.from(stored);
      _chatMessages = list.map((e) {
        return ChatMessage(
          id: e['id'],
          role: e['role'] == 'user' ? MessageRole.user : MessageRole.ai,
          content: e['content'],
          timestamp: DateTime.parse(e['timestamp']),
        );
      }).toList();
    } else {
      _chatMessages = [
        ChatMessage(
          id: 'welcome',
          role: MessageRole.ai,
          content:
              "Hello! I'm your Socratic tutor powered by Denizen AI. Upload a document from your Library and ask me anything — I'll guide you through it step-by-step!",
          timestamp: DateTime.now(),
        ),
      ];
    }

    _activeDocumentId = _sessionBox.get('activeDocumentId');
    _activeSessionTitle =
        _sessionBox.get('activeSessionTitle') ?? 'Socratic Tutor';
  }

  void _saveSession() {
    final list = _chatMessages.map((m) => {
      'id': m.id,
      'role': m.role == MessageRole.user ? 'user' : 'ai',
      'content': m.content,
      'timestamp': m.timestamp.toIso8601String(),
    }).toList();
    _sessionBox.put('messages', list);
    _sessionBox.put('activeDocumentId', _activeDocumentId);
    _sessionBox.put('activeSessionTitle', _activeSessionTitle);
  }

  // ─── Document Selection ──────────────────────────────────────

  void setActiveDocument(String documentId, String documentName) {
    _activeDocumentId = documentId;
    _activeSessionTitle = documentName;
    _activeSessionMeta = 'Offline · EN';
    _rebuildDenizenSession();
    _saveSession();
    notifyListeners();
  }

  void clearActiveDocument() {
    _activeDocumentId = null;
    _activeSessionTitle = 'Socratic Tutor';
    _activeSessionMeta = 'Offline · EN';
    _rebuildDenizenSession();
    _saveSession();
    notifyListeners();
  }

  // ─── Send Message ────────────────────────────────────────────

  Future<void> sendMessage(
    String text, {
    required DocumentProvider docProvider,
    bool socratic = true,
    String language = 'the same language the student uses',
  }) async {
    if (text.trim().isEmpty) return;
    if (!_isInitialized) await init();

    // Add user message
    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    _chatMessages.add(userMsg);
    _isGenerating = true;
    notifyListeners();

    // Add empty AI message placeholder for streaming
    final aiMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_ai';
    final aiMsg = ChatMessage(
      id: aiMsgId,
      role: MessageRole.ai,
      content: '',
      timestamp: DateTime.now(),
    );
    _chatMessages.add(aiMsg);
    notifyListeners();

    try {
      // Check model is loaded
      if (!_denizen.isModelLoaded) {
        _updateLastMessage(
          'No model loaded. Please go to Settings to download and activate a model first.',
        );
        _isGenerating = false;
        notifyListeners();
        return;
      }

      // Get relevant chunks if a document is selected
      List<String> chunks = [];
      if (_activeDocumentId != null) {
        chunks = docProvider.getRelevantChunks(_activeDocumentId!, text);
      }

      // Ensure session is configured with current Socratic/Language/Chunk settings
      _rebuildDenizenSession(
        socratic: socratic,
        language: language,
        contextChunks: chunks,
      );

      // Stream response via DenizenSession
      final stream = _activeSession!.streamChat(text);
      final buffer = StringBuffer();

      await for (final token in stream) {
        buffer.write(token);
        _updateLastMessage(buffer.toString());
      }
    } catch (e) {
      debugPrint('❌ Tutor streaming error: $e');
      _updateLastMessage('Sorry, an error occurred during inference: $e');
    } finally {
      _isGenerating = false;
      _saveSession();
      notifyListeners();
    }
  }

  void _updateLastMessage(String content) {
    if (_chatMessages.isEmpty) return;
    final last = _chatMessages.last;
    _chatMessages[_chatMessages.length - 1] = ChatMessage(
      id: last.id,
      role: last.role,
      content: content,
      timestamp: last.timestamp,
    );
    notifyListeners();
  }

  // ─── Status & Management ─────────────────────────────────────

  void toggleOffline() {
    _isOffline = !_isOffline;
    notifyListeners();
  }

  void clearChat() {
    _rebuildDenizenSession();
    _chatMessages = [
      ChatMessage(
        id: 'welcome',
        role: MessageRole.ai,
        content:
            'Session reset. Socratic tutor is ready. What would you like to explore?',
        timestamp: DateTime.now(),
      ),
    ];
    _saveSession();
    notifyListeners();
  }

  void updateActiveSession(String title, String meta) {
    _activeSessionTitle = title;
    _activeSessionMeta = meta;
    notifyListeners();
  }
}
