import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:denizen_ai/denizen_ai.dart' hide ChatMessage;
import '../models/chat_message.dart';
import 'document_provider.dart';

class SessionProvider with ChangeNotifier {
  final DenizenAI _denizen = DenizenAI();
  DenizenSession? _activeSession;
  Completer<void>? _activeLock;
  StreamSubscription<String>? _activeStreamSub;

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

  void stopGeneration() {
    if (_isGenerating) {
      _activeStreamSub?.cancel();
      _activeStreamSub = null;
      _isGenerating = false;
      _saveSession();
      notifyListeners();
    }
  }

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
    DocumentProvider? docProvider,
  }) {
    String context = '';
    if (contextChunks != null && contextChunks.isNotEmpty) {
      final joined = contextChunks.join('\n\n---\n\n');
      context = '\n\nYou are a helpful document assistant. Use the following document content as your knowledge base:\n\n$joined\n\nAnswer based ONLY on the above content.';
    }

    final systemPrompt = context.isNotEmpty
        ? 'You are an expert academic tutor for Ubuntu Elimu. $context'
        : (socratic
            ? 'You are an expert academic tutor for Ubuntu Elimu. Help the student understand their study topics clearly. Be encouraging, patient, concise, and respond in $language.'
            : 'You are a direct, clear study assistant for Ubuntu Elimu. Answer questions directly and concisely in $language.');

    _activeSession = _denizen.createSession(
      systemPrompt: systemPrompt,
      maxTokens: 512,
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
          generationSeconds: e['generationSeconds'] != null
              ? (e['generationSeconds'] as num).toDouble()
              : null,
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
      if (m.generationSeconds != null) 'generationSeconds': m.generationSeconds,
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

  void startNewSession() {
    stopGeneration();
    _chatMessages.clear();
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

    // Add user message and show generating state immediately
    _chatMessages.add(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    ));
    _isGenerating = true;
    notifyListeners();

    // Wait for any ongoing generation to finish
    while (_activeLock != null) {
      await _activeLock!.future;
    }

    await _processMessage(text, socratic, docProvider, language);
  }

  Future<void> _processMessage(String text, bool socratic, DocumentProvider docProvider, String language) async {
    final currentLock = Completer<void>();
    _activeLock = currentLock;

    try {
      if (!_denizen.isModelLoaded) {
        _chatMessages.add(ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_ai',
          role: MessageRole.ai,
          content: 'No model loaded. Please go to Settings to download and activate a model first.',
          timestamp: DateTime.now(),
        ));
        _isGenerating = false;
        notifyListeners();
        return;
      }

      List<String> chunks = [];
      if (_activeDocumentId != null) {
        chunks = await docProvider.getRelevantChunks(_activeDocumentId!, text);
      }

      _rebuildDenizenSession(
        socratic: socratic,
        language: language,
        contextChunks: chunks,
        docProvider: docProvider,
      );

      // Add the AI placeholder bubble only now — inference is about to start
      _chatMessages.add(ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_ai',
        role: MessageRole.ai,
        content: '',
        timestamp: DateTime.now(),
      ));
      notifyListeners();

      final sw = Stopwatch()..start();
      final stream = _activeSession!.streamChat(text);
      final buffer = StringBuffer();

      await _activeStreamSub?.cancel();
      _activeStreamSub = stream.listen(
        (token) {
          buffer.write(token);
          _updateLastMessage(buffer.toString());
        },
        onError: (e) {
          sw.stop();
          debugPrint('❌ Tutor streaming error: $e');
          _updateLastMessage('Sorry, an error occurred during inference: $e');
          _isGenerating = false;
          _saveSession();
          notifyListeners();
          if (!currentLock.isCompleted) currentLock.complete();
        },
        onDone: () {
          sw.stop();
          final sec = sw.elapsedMilliseconds / 1000.0;
          _updateLastMessage(
            buffer.toString(),
            generationSeconds: sec,
          );
          _isGenerating = false;
          _saveSession();
          notifyListeners();
          _activeLock = null;
          if (!currentLock.isCompleted) currentLock.complete();
        },
      );
    } catch (e) {
      debugPrint('❌ Tutor streaming error: $e');
      _updateLastMessage('Sorry, an error occurred during inference: $e');
      _isGenerating = false;
      _saveSession();
      notifyListeners();
      _activeLock = null;
      if (!currentLock.isCompleted) currentLock.complete();
    }
  }

  void _updateLastMessage(String content, {double? generationSeconds}) {
    if (_chatMessages.isEmpty) return;
    final last = _chatMessages.last;
    _chatMessages[_chatMessages.length - 1] = ChatMessage(
      id: last.id,
      role: last.role,
      content: content,
      timestamp: last.timestamp,
      language: last.language,
      model: last.model,
      citation: last.citation,
      generationSeconds: generationSeconds ?? last.generationSeconds,
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
