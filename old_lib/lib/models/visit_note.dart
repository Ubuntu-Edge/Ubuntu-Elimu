
class VisitNote {
  final int? id;
  final String visitId;
  final DateTime timestamp;
  final String content;

  VisitNote({
    this.id,
    required this.visitId,
    required this.timestamp,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visitId': visitId,
      'timestamp': timestamp.toIso8601String(),
      'content': content,
    };
  }

  @override
  String toString() {
    return 'VisitNote{id: $id, visitId: $visitId, timestamp: $timestamp, content: $content}';
  }
}
