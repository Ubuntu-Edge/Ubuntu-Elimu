import 'dart:convert';
import 'package:dio/dio.dart';
import 'base_ai_provider.dart';

/// SECURE PROXY VERSION (Option 3)
/// The API Key is GONE from this code. It lives safely on your server.
class GroqAIProvider implements AIProvider {
  final Dio _dio = Dio();
  
  // 🌍 ACTION REQUIRED: Replace this with your deployed proxy URL
  // While testing locally with the Node.js server, use 'http://10.0.2.2:3000'
  final String _proxyUrl = 'https://your-deployed-proxy.com'; 
  
  final String _model = 'llama-3.3-70b-versatile';

  GroqAIProvider();

  @override
  Future<String> generate(
    String prompt, {
    required String systemPrompt,
    int maxTokens = 512,
    double temperature = 0.7,
  }) async {
    try {
      final response = await _dio.post(
        '$_proxyUrl/v1/chat/completions',
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
        },
      );
      // The proxy returns the standard Groq response format
      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      return 'Proxy Error: Could not connect to AI service.';
    }
  }

  @override
  Stream<String> streamGenerate(
    String prompt, {
    required String systemPrompt,
    int maxTokens = 512,
    double temperature = 0.7,
  }) async* {
    try {
      final response = await _dio.post(
        '$_proxyUrl/v1/chat/completions',
        options: Options(responseType: ResponseType.stream),
        data: {
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': maxTokens,
          'temperature': temperature,
          'stream': true,
        },
      );

      // Cast to ResponseBody first, then stream to correct type
      final stream = (response.data as ResponseBody).stream;
      await for (final chunk in stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
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
      yield 'Streaming failed. Proxy may be offline.';
    }
  }

  @override
  Future<Map<String, dynamic>?> generateJson(
    String prompt, {
    required String systemPrompt,
    int maxTokens = 800,
  }) async {
    final raw = await generate(
      prompt,
      systemPrompt: '$systemPrompt\n\nIMPORTANT: Return ONLY valid JSON.',
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
