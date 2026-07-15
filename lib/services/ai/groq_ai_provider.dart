import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'base_ai_provider.dart';

/// SECURE PROXY VERSION (Option 3)
/// The API Key is GONE from this code. It lives safely on your server.
class GroqAIProvider implements AIProvider {
  final String apiKey;
  final Dio _dio = Dio();
  
  // 🌍 Deployed proxy URL (used if apiKey is empty)
  final String _proxyUrl = 'https://your-deployed-proxy.com'; 
  
  final String _model = 'llama-3.3-70b-versatile';

  GroqAIProvider(this.apiKey);

  bool get _useProxy => apiKey.isEmpty;
  String get _url => _useProxy ? '$_proxyUrl/v1/chat/completions' : 'https://api.groq.com/openai/v1/chat/completions';
  
  Map<String, String> get _headers => _useProxy 
      ? {} 
      : {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };

  @override
  Future<String> generate(
    String prompt, {
    required String systemPrompt,
    int maxTokens = 512,
    double temperature = 0.7,
  }) async {
    try {
      final response = await _dio.post(
        _url,
        options: Options(headers: _headers),
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
      // The proxy/API returns the standard Groq response format
      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      return _useProxy 
          ? 'Proxy Error: Could not connect to AI service.'
          : 'Error connecting to Groq: $e';
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
        _url,
        options: Options(
          headers: _headers,
          responseType: ResponseType.stream,
        ),
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
        final trimmedChunk = chunk.trim();
        if (trimmedChunk.isEmpty) continue;
        if (trimmedChunk.startsWith('data: ')) {
          final data = trimmedChunk.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            final content = json['choices'][0]['delta']['content'] ?? '';
            yield content;
          } catch (_) {}
        }
      }
    } catch (e) {
      yield _useProxy 
          ? 'Streaming failed. Proxy may be offline.'
          : 'Error streaming from Groq: $e';
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
      final decoded = jsonDecode(clean);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        final jsonSub = raw.substring(start, end + 1);
        final decoded = jsonDecode(jsonSub);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Robust JSON decoding failed: $e. Raw response was: $raw');
    }
    return null;
  }
}
