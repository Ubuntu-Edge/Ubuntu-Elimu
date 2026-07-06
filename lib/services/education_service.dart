import '../services/ai/base_ai_provider.dart';

class EducationService {
  final AIProvider aiProvider;

  EducationService(this.aiProvider);

  Future<List<Map<String, dynamic>>?> generateFlashcards(
    List<String> chunks, {
    int count = 8,
  }) async {
    final result = await aiProvider.generateJson(
      'Generate exactly $count flashcards in JSON format with "question" and "answer" fields based on this text:\n\n${chunks.join("\n\n")}',
      systemPrompt: 'You are an educational assistant. Create flashcards from the text provided.',
      maxTokens: 800, // Pass default
    );

    if (result == null) return null;

    final list = result['flashcards'] ?? result['data'];
    if (list is! List) return null;

    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>?> generateStudyPlan(
    List<String> chunks, {
    int days = 3,
  }) async {
    return aiProvider.generateJson(
      'Create a structured $days-day study plan in JSON format based on this material:\n\n${chunks.join("\n\n")}',
      systemPrompt: 'You are an expert study planner.',
      maxTokens: 800, // Pass default
    );
  }

  Future<String> summarize(List<String> chunks) async {
    return aiProvider.generate(
      'Provide a concise summary of the following text:\n\n${chunks.join("\n\n")}',
      systemPrompt: 'You are an expert summarizer.',
      maxTokens: 512, // Pass default
    );
  }
}
