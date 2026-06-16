class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> citations;
  final bool isGenerating;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.citations = const [],
    this.isGenerating = false,
  });
}
