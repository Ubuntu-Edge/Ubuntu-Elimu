import 'dart:async';
import 'offline_ai_service.dart';

/// CodeLab AI Service specialized for offline edge models (Qwen 2.5 Coder, SmolLM2, Llama).
/// Provides structured generation of single-file web projects, code explanation,
/// and automated error debugging for students.
class CodeLabAIService {
  static final CodeLabAIService _instance = CodeLabAIService._internal();
  static CodeLabAIService get instance => _instance;
  CodeLabAIService._internal();

  final OfflineAIService _offlineAI = OfflineAIService.instance;

  bool get isModelLoaded => _offlineAI.isModelLoaded;

  /// Generates a single-file HTML/CSS/JS application based on the student's idea.
  Stream<String> generateWebProjectStream({
    required String studentPrompt,
    String? currentCode,
  }) async* {
    const systemPrompt = '''You are an expert, encouraging STEM and Computer Science tutor for students in Kenya.
Your task is to write clean, complete, self-contained single-file HTML5 code (with embedded <style> and <script> tags).
Rules:
1. Output the entire working HTML code inside a single ```html code block.
2. DO NOT use external CDNs or internet URLs for scripts/styles (must work 100% offline).
3. Use modern, beautiful CSS (vibrant colors, gradients, rounded cards, clean fonts).
4. Make it interactive with vanilla JavaScript and include clear, simple comments.
5. Keep explanations short and encouraging. Focus primarily on the code.''';

    String userMessage = 'Build a web project for this requirement:\n"$studentPrompt"';
    if (currentCode != null && currentCode.trim().isNotEmpty) {
      userMessage += '\n\nHere is the current code to modify/improve:\n```html\n$currentCode\n```';
    }

    yield* _offlineAI.generateResponseStream(
      prompt: userMessage,
      systemPrompt: systemPrompt,
      maxTokens: 1024,
      temperature: 0.3,
    );
  }

  /// Explains a specific code snippet or concept in beginner-friendly terms.
  Stream<String> explainCodeStream({
    required String codeSnippet,
    String? specificQuestion,
  }) async* {
    const systemPrompt = '''You are a friendly Computer Science tutor for Junior Secondary and High School students.
Explain the provided HTML/CSS/JavaScript code in simple, beginner-friendly terms.
Highlight:
- What each tag or function does
- How data flows
- Why it's useful
Keep your explanation clear, fun, and easy to understand.''';

    final prompt = 'Please explain this code:\n```\n$codeSnippet\n```'
        '${specificQuestion != null ? '\nQuestion: $specificQuestion' : ''}';

    yield* _offlineAI.generateResponseStream(
      prompt: prompt,
      systemPrompt: systemPrompt,
      maxTokens: 512,
      temperature: 0.4,
    );
  }

  /// Diagnoses a runtime JS error captured from the browser.
  Stream<String> debugErrorStream({
    required String fullCode,
    required String errorMessage,
  }) async* {
    const systemPrompt = '''You are a friendly offline code debugger.
A student ran their HTML/JS code and encountered a browser error.
Analyze the code and the error message, identify the line causing the problem, explain why it broke in simple words, and provide the fixed code.''';

    final prompt = '''Error Message:
$errorMessage

Student Code:
```html
$fullCode
```

Please explain what went wrong and provide the corrected code.''';

    yield* _offlineAI.generateResponseStream(
      prompt: prompt,
      systemPrompt: systemPrompt,
      maxTokens: 768,
      temperature: 0.2,
    );
  }

  /// Helper to extract clean HTML content from model markdown code blocks.
  String extractHtmlFromResponse(String rawText) {
    final codeBlockRegex = RegExp(r'```(?:html)?\s*([\s\S]*?)\s*```', caseSensitive: false);
    final match = codeBlockRegex.firstMatch(rawText);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }
    // If no code block found, return raw text if it looks like HTML
    if (rawText.contains('<html') || rawText.contains('<!DOCTYPE')) {
      return rawText.trim();
    }
    return rawText;
  }
}
