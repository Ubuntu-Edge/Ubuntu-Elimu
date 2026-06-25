import 'dart:convert';
import 'package:dio/dio.dart';
import 'base_ai_provider.dart';

class GroqAIProvider implements AIProvider {
  final String apiKey;
  final Dio _dio = Dio();
  final String _model = 'llama-3.1-70b-versatile';

  GroqAIProvider(this.apiKey);

  @override
  Future<String> generate(
    String prompt, {
    String systemPrompt = '',
    int maxTokens = 512,
    double temperature = 0.7,
  }) async {
    try {
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': _model,
          'messages': [
            if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
        },
      );
      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      return 'Error connecting to Groq: $e';
    }
  }

  @override
  Stream<String> streamGenerate(
    String prompt, {
    String systemPrompt = '',
    int maxTokens = 512,
    double temperature = 0.7,
  }) async* {
    try {
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'model': _model,
          'messages': [
            if (systemPrompt.isNotEmpty) {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
          'stream': true,
        },
      );

      final stream = response.data.stream;
      await for (final chunk in stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;
        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6);
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            final content = json['choices'][0]['delta']['content'] ?? '';
            yield content;
          } catch (_) {}
        }
      }
    } catch (e) {
      yield 'Error streaming from Groq: $e';
    }
  }

  @override
  Future<Map<String, dynamic>?> generateJson(
    String prompt, {
    String systemPrompt = '',
    int maxTokens = 800,
  }) async {
    final raw = await generate(
      prompt,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
    );
    try {
      final clean = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(clean);
    } catch (e) {
      return null;
    }
  }
}
