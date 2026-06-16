import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class SessionProvider with ChangeNotifier {
  final List<ChatMessage> _chatMessages = [
    ChatMessage(
      id: 'welcome',
      text: 'Good morning! Ready to tackle your studies? Ask me anything about Organic Chemistry Ch. 7, or your uploaded files. How can I guide you today?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  String _activeSessionTitle = 'Organic Chemistry — Ch.7';
  String _activeSessionMeta = '45 min ago · Power mode · EN→SW';

  bool _isOffline = true;
  bool _isGenerating = false;

  List<ChatMessage> get chatMessages => _chatMessages;
  String get activeSessionTitle => _activeSessionTitle;
  String get activeSessionMeta => _activeSessionMeta;
  bool get isOffline => _isOffline;
  bool get isGenerating => _isGenerating;

  void toggleOffline(bool value) {
    _isOffline = value;
    notifyListeners();
  }

  void updateActiveSession(String title, String meta) {
    _activeSessionTitle = title;
    _activeSessionMeta = meta;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _chatMessages.add(userMsg);
    _isGenerating = true;
    notifyListeners();

    // Simulate Socratic Offline AI responses
    await Future.delayed(const Duration(milliseconds: 1500));

    String aiResponse = _generateSocraticResponse(text);

    final aiMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_ai',
      text: aiResponse,
      isUser: false,
      timestamp: DateTime.now(),
      citations: ['Biochem Lecture Notes — W4.pdf', 'Thermodynamics Slides.pptx'],
    );

    _chatMessages.add(aiMsg);
    _isGenerating = false;
    notifyListeners();
  }

  String _generateSocraticResponse(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('chemistry') || lower.contains('organic')) {
      return 'Interesting question. Before we define the reaction mechanism for Chapter 7, what is the first step you typically take to identify the electrophile and nucleophile in a polar reaction? What features on a molecule suggest high electron density?';
    } else if (lower.contains('thermodynamics') || lower.contains('heat') || lower.contains('entropy')) {
      return 'Excellent topic! Thermodynamics helps us understand reaction spontaneity. How would you describe the relationship between enthalpy (ΔH) and entropy (ΔS) in relation to Gibbs Free Energy (ΔG)? Under what temperature conditions is a reaction spontaneous if both ΔH and ΔS are positive?';
    } else if (lower.contains('upload') || lower.contains('doc') || lower.contains('pdf')) {
      return 'I have scanned your local files. If you look at "Biochem Lecture Notes — W4.pdf", it discusses protein folding. What intermolecular forces hold the secondary structure together? Let\'s discuss.';
    } else {
      return 'That\'s a great question to explore. Rather than jump straight to the answer, let\'s break it down. What do you think is the fundamental principle underlying this concept? If we look at the variables involved, which ones can we measure or control?';
    }
  }

  void clearChat() {
    _chatMessages.clear();
    _chatMessages.add(
      ChatMessage(
        id: 'welcome',
        text: 'Session reset. Socratic tutor mode is active. What concept should we explore next?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
