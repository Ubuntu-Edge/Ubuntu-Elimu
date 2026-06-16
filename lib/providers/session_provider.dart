import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class SessionProvider with ChangeNotifier {
  final List<ChatMessage> _chatMessages = [
    ChatMessage(
      id: 'welcome',
      role: MessageRole.ai,
      content: 'Good morning! Ready to tackle your studies? Ask me anything about Organic Chemistry Ch. 7, or your uploaded files. How can I guide you today?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  bool _isOffline = true;
  bool _isGenerating = false;

  String _activeSessionTitle = 'Organic Chemistry — Ch.7';
  String _activeSessionMeta = '45 min ago · Power mode · EN→SW';

  List<ChatMessage> get chatMessages => _chatMessages;
  bool get isOffline => _isOffline;
  bool get isGenerating => _isGenerating;
  String get activeSessionTitle => _activeSessionTitle;
  String get activeSessionMeta => _activeSessionMeta;

  void toggleOffline() {
    _isOffline = !_isOffline;
    notifyListeners();
  }

  void updateActiveSession(String title, String meta) {
    _activeSessionTitle = title;
    _activeSessionMeta = meta;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    _chatMessages.add(userMsg);
    _isGenerating = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    final aiResponse = _generateSocraticResponse(text);

    final aiMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_ai',
      role: MessageRole.ai,
      content: aiResponse,
      timestamp: DateTime.now(),
      citation: const CitationRef(
        docName: 'Biochem Lecture Notes — W4.pdf',
        page: 7,
        excerpt: 'Nucleophiles attack electrophilic carbons...',
      ),
    );

    _chatMessages.add(aiMsg);
    _isGenerating = false;
    notifyListeners();
  }

  String _generateSocraticResponse(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('chemistry') || lower.contains('organic')) {
      return 'Interesting question. Before we define the reaction mechanism for Chapter 7, what is the first step you typically take to identify the electrophile and nucleophile in a polar reaction? What features on a molecule suggest high electron density?';
    } else if (lower.contains('thermodynamics') ||
        lower.contains('heat') ||
        lower.contains('entropy')) {
      return 'Excellent topic! Thermodynamics helps us understand reaction spontaneity. How would you describe the relationship between enthalpy (ΔH) and entropy (ΔS) in relation to Gibbs Free Energy (ΔG)?';
    } else if (lower.contains('upload') ||
        lower.contains('doc') ||
        lower.contains('pdf')) {
      return 'I have scanned your local files. If you look at "Biochem Lecture Notes — W4.pdf", it discusses protein folding. What intermolecular forces hold the secondary structure together? Let\'s discuss.';
    } else {
      return 'That\'s a great question to explore. Rather than jump straight to the answer, let\'s break it down. What do you think is the fundamental principle underlying this concept?';
    }
  }

  void clearChat() {
    _chatMessages.clear();
    _chatMessages.add(
      ChatMessage(
        id: 'welcome',
        role: MessageRole.ai,
        content: 'Session reset. Socratic tutor mode is active. What concept should we explore next?',
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
