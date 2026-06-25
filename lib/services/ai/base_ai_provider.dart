abstract class AIProvider {
  Future<String> generate(
    String prompt, {
    String systemPrompt = '',
    int maxTokens = 512,
    double temperature = 0.7,
  });

  Stream<String> streamGenerate(
    String prompt, {
    String systemPrompt = '',
    int maxTokens = 512,
    double temperature = 0.7,
  });

  Future<Map<String, dynamic>?> generateJson(
    String prompt, {
    String systemPrompt = '',
    int maxTokens = 800,
  });
}

