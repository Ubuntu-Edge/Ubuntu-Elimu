import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/code_action.dart';
import 'code_delta_applier.dart';
import 'local_code_server.dart';
import 'offline_ai_service.dart';

enum AgentStep { thinking, actionProposed, deltaApplied, verifyingRuntime, success, error }

class AgentLoopUpdate {
  final AgentStep step;
  final String message;
  final CodeAction? action;
  final CodeDeltaResult? deltaResult;
  final String? finalCode;

  const AgentLoopUpdate({
    required this.step,
    required this.message,
    this.action,
    this.deltaResult,
    this.finalCode,
  });
}

/// On-Device Agentic Loop (Plan -> Act -> Observe -> Correct)
/// Orchestrates small, fast delta edits on edge LLMs with runtime verification.
class CodeLabAgentLoop {
  static final CodeLabAgentLoop _instance = CodeLabAgentLoop._internal();
  static CodeLabAgentLoop get instance => _instance;
  CodeLabAgentLoop._internal();

  final OfflineAIService _aiService = OfflineAIService.instance;
  final LocalCodeServer _server = LocalCodeServer.instance;

  /// Runs the agentic edit loop for a student's prompt against [currentCode].
  Stream<AgentLoopUpdate> runEditLoop({
    required String prompt,
    required String currentCode,
  }) async* {
    yield const AgentLoopUpdate(
      step: AgentStep.thinking,
      message: 'Analyzing project & planning delta edit...',
    );

    // If code is empty, do a scaffold
    if (currentCode.trim().isEmpty) {
      yield* _runScaffold(prompt);
      return;
    }

    // Step 1: Formulate Structured Delta Request
    const systemPrompt = '''You are an on-device code editing agent.
The user wants to make a specific change to an existing HTML/CSS/JS file.
Instead of rewriting the whole file, output a single JSON action object to apply a surgical edit.

Supported JSON Actions:
1. Search and Replace:
{"action": "search_replace", "target": "<exact string to replace>", "replacement": "<new replacement string>"}

2. Insert After:
{"action": "insert_after", "anchor": "<exact anchor string>", "code": "<new code to insert>"}

3. Replace Lines:
{"action": "replace_lines", "start": 10, "end": 15, "code": "<new code>"}

Rules:
- Target exact strings already present in the student's code.
- Keep edits minimal and precise (1-10 lines max).
- Return ONLY valid JSON (enclosed in ```json ... ``` or raw).''';

    final userMessage = '''Student Code:
```html
$currentCode
```

Requested Change:
"$prompt"

Output the JSON action now:''';

    String accumulatedOutput = '';
    try {
      final stream = _aiService.generateResponseStream(
        prompt: userMessage,
        systemPrompt: systemPrompt,
        maxTokens: 300,
        temperature: 0.1,
      );

      await for (final token in stream) {
        accumulatedOutput += token;
      }
    } catch (e) {
      yield AgentLoopUpdate(
        step: AgentStep.error,
        message: 'LLM Generation Error: $e',
      );
      return;
    }

    // Step 2: Parse Action
    final action = _parseAction(accumulatedOutput);
    if (action == null) {
      yield AgentLoopUpdate(
        step: AgentStep.error,
        message: 'Could not parse structured edit action from response: $accumulatedOutput',
      );
      return;
    }

    yield AgentLoopUpdate(
      step: AgentStep.actionProposed,
      message: 'Proposed action: ${_describeAction(action)}',
      action: action,
    );

    // Step 3: Apply Delta to Code Buffer
    final deltaResult = CodeDeltaApplier.applyAction(
      originalCode: currentCode,
      action: action,
    );

    if (!deltaResult.success) {
      yield AgentLoopUpdate(
        step: AgentStep.error,
        message: 'Edit failed to apply: ${deltaResult.errorMessage}',
        deltaResult: deltaResult,
      );
      return;
    }

    yield AgentLoopUpdate(
      step: AgentStep.deltaApplied,
      message: 'Applied delta (${deltaResult.diff.where((d) => d.type == DiffType.added).length} added, ${deltaResult.diff.where((d) => d.type == DiffType.removed).length} removed lines)',
      deltaResult: deltaResult,
      finalCode: deltaResult.updatedCode,
    );

    // Step 4: Hot-Reload and Observe Runtime Verification
    yield const AgentLoopUpdate(
      step: AgentStep.verifyingRuntime,
      message: 'Verifying on local browser runtime...',
    );

    _server.updateCode(deltaResult.updatedCode);

    // Check for runtime errors over 400ms observation window
    String? observedError;
    final errorCompleter = Completer<String?>();
    final sub = _server.errorStream.listen((err) {
      if (!errorCompleter.isCompleted) {
        errorCompleter.complete(err);
      }
    });

    // Wait up to 400ms for browser feedback
    Future.delayed(const Duration(milliseconds: 400)).then((_) {
      if (!errorCompleter.isCompleted) {
        errorCompleter.complete(null);
      }
    });

    observedError = await errorCompleter.future;
    await sub.cancel();

    if (observedError != null) {
      debugPrint('⚠️ Runtime error detected during agent loop: $observedError');
      yield AgentLoopUpdate(
        step: AgentStep.error,
        message: 'Runtime Error detected in browser: $observedError',
        deltaResult: deltaResult,
        finalCode: deltaResult.updatedCode,
      );
    } else {
      yield AgentLoopUpdate(
        step: AgentStep.success,
        message: 'Successfully updated & verified on-device! ⚡',
        deltaResult: deltaResult,
        finalCode: deltaResult.updatedCode,
      );
    }
  }

  Stream<AgentLoopUpdate> _runScaffold(String prompt) async* {
    const systemPrompt = '''You are an expert STEM coding tutor.
Write a complete, single-file HTML5 project with CSS and JS for the student's request.
Return JSON: {"action": "full_scaffold", "html": "<complete html>"}''';

    String raw = '';
    try {
      final stream = _aiService.generateResponseStream(
        prompt: 'Build project: "$prompt"',
        systemPrompt: systemPrompt,
        maxTokens: 800,
        temperature: 0.3,
      );

      await for (final token in stream) {
        raw += token;
      }
    } catch (e) {
      yield AgentLoopUpdate(step: AgentStep.error, message: 'Scaffold error: $e');
      return;
    }

    final action = _parseAction(raw);
    if (action is FullScaffoldAction) {
      _server.updateCode(action.html);
      yield AgentLoopUpdate(
        step: AgentStep.success,
        message: 'Project scaffolded successfully! 🚀',
        action: action,
        finalCode: action.html,
      );
    } else {
      // Fallback extract HTML directly
      final html = _extractHtml(raw);
      _server.updateCode(html);
      yield AgentLoopUpdate(
        step: AgentStep.success,
        message: 'Project scaffolded successfully! 🚀',
        finalCode: html,
      );
    }
  }

  CodeAction? _parseAction(String text) {
    try {
      final jsonBlock = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```', caseSensitive: false);
      final match = jsonBlock.firstMatch(text);
      final rawJson = match != null ? match.group(1)! : text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1);

      final Map<String, dynamic> parsed = jsonDecode(rawJson);
      return CodeAction.fromJson(parsed);
    } catch (e) {
      debugPrint('JSON parse fallback: $e');
      return null;
    }
  }

  String _describeAction(CodeAction action) {
    switch (action) {
      case SearchReplaceAction(:final target):
        return 'Replace "$target"';
      case InsertAfterAction(:final anchor):
        return 'Insert after "$anchor"';
      case ReplaceLinesAction(:final startLine, :final endLine):
        return 'Replace lines $startLine-$endLine';
      case FullScaffoldAction():
        return 'Full project scaffold';
    }
  }

  String _extractHtml(String raw) {
    final block = RegExp(r'```(?:html)?\s*([\s\S]*?)\s*```', caseSensitive: false);
    final match = block.firstMatch(raw);
    return match != null ? match.group(1)!.trim() : raw.trim();
  }
}
