import '../offline_ai_service.dart';
import 'base_ai_provider.dart';

class LocalAIProvider implements AIProvider {
  final OfflineAIService _service = OfflineAIService.instance;

  @override
  Future<String> generate(
    String prompt, {
    required String systemPrompt,
    int maxTokens = 512,
    double temperature = 0.7,
  }) {
    return _service.generateResponse(
      prompt: prompt,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  @override
  Stream<String> streamGenerate(
    String prompt, {
    required String systemPrompt,
    int maxTokens = 512,
    double temperature = 0.7,
  }) {
    return _service.generateResponseStream(
      prompt: prompt,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  @override
  Future<Map<String, dynamic>?> generateJson(
    String prompt, {
    required String systemPrompt,
    int maxTokens = 800,
  }) {
    return _service.generateJson(
      prompt: prompt,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
    );
  }
}
