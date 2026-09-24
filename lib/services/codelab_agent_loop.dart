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

  /// Max times we'll ask the model to fix its own malformed JSON before giving up.
  static const int _maxParseRetries = 2;

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

    // Step 1: Formulate Structured Delta Request (with retry-on-invalid-JSON)
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

    CodeAction? action;
    String lastRawOutput = '';
    String? lastParseError;

    for (var attempt = 0; attempt <= _maxParseRetries; attempt++) {
      final isRetry = attempt > 0;

      if (isRetry) {
        yield AgentLoopUpdate(
          step: AgentStep.thinking,
          message: 'Response wasn\'t valid JSON — asking the model to correct it (attempt $attempt/$_maxParseRetries)...',
        );
      }

      final requestPrompt = isRetry
          ? '''Your previous response could not be parsed as valid JSON.

Your previous response:
$lastRawOutput

Parse error: $lastParseError

Return ONLY a single valid JSON action object for this request, with no prose, no markdown fences unless closed properly, and no trailing commas:
"$prompt"'''
          : userMessage;

      String accumulatedOutput = '';
      try {
        final stream = _aiService.generateResponseStream(
          prompt: requestPrompt,
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

      lastRawOutput = accumulatedOutput;

      final parseAttempt = _tryParseAction(accumulatedOutput);
      if (parseAttempt.action != null) {
        action = parseAttempt.action;
        break;
      }

      lastParseError = parseAttempt.error;
      debugPrint('Parse attempt $attempt failed: $lastParseError');
    }

    if (action == null) {
      yield AgentLoopUpdate(
        step: AgentStep.error,
        message: 'Could not get a valid edit after ${_maxParseRetries + 1} attempts. '
            'Last response: ${_truncateForDisplay(lastRawOutput)}',
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

    String lastRaw = '';
    String? lastParseError;
    CodeAction? action;

    for (var attempt = 0; attempt <= _maxParseRetries; attempt++) {
      final isRetry = attempt > 0;

      if (isRetry) {
        yield AgentLoopUpdate(
          step: AgentStep.thinking,
          message: 'Response wasn\'t valid JSON — asking the model to correct it (attempt $attempt/$_maxParseRetries)...',
        );
      }

      final requestPrompt = isRetry
          ? '''Your previous response could not be parsed as valid JSON.

Your previous response:
$lastRaw

Parse error: $lastParseError

Return ONLY {"action": "full_scaffold", "html": "<complete html>"} with no prose and properly escaped HTML, for:
"$prompt"'''
          : 'Build project: "$prompt"';

      String raw = '';
      try {
        final stream = _aiService.generateResponseStream(
          prompt: requestPrompt,
          systemPrompt: systemPrompt,
          maxTokens: 800,
          temperature: isRetry ? 0.1 : 0.3, // tighten up on retry to favor valid structure over creativity
        );

        await for (final token in stream) {
          raw += token;
        }
      } catch (e) {
        yield AgentLoopUpdate(step: AgentStep.error, message: 'Scaffold error: $e');
        return;
      }

      lastRaw = raw;

      final parseAttempt = _tryParseAction(raw);
      if (parseAttempt.action is FullScaffoldAction) {
        action = parseAttempt.action;
        break;
      }

      // Even without valid JSON, a raw HTML block is a usable fallback —
      // only keep retrying if we can't even extract HTML from the response.
      final extracted = _extractHtml(raw);
      if (extracted.trim().isNotEmpty && _looksLikeHtml(extracted)) {
        _server.updateCode(extracted);
        yield AgentLoopUpdate(
          step: AgentStep.success,
          message: 'Project scaffolded successfully! 🚀',
          finalCode: extracted,
        );
        return;
      }

      lastParseError = parseAttempt.error ?? 'No usable HTML found in response.';
      debugPrint('Scaffold parse attempt $attempt failed: $lastParseError');
    }

    if (action is FullScaffoldAction) {
      final html = action.html;
      _server.updateCode(html);
      yield AgentLoopUpdate(
        step: AgentStep.success,
        message: 'Project scaffolded successfully! 🚀',
        action: action,
        finalCode: html,
      );
      return;
    }

    yield AgentLoopUpdate(
      step: AgentStep.error,
      message: 'Could not generate a working project after ${_maxParseRetries + 1} attempts. '
          'Last response: ${_truncateForDisplay(lastRaw)}',
    );
  }

  /// Action type strings CodeAction.fromJson recognizes explicitly.
  /// fromJson's `default` branch silently treats anything else as a full
  /// scaffold, so we validate the declared type ourselves first rather than
  /// trusting that fallback — an unrecognized type should be a parse
  /// failure (and trigger a retry), not a silent, likely-empty scaffold.
  static const _knownActionTypes = {
    'search_replace', 'replace_text',
    'insert_after', 'insert_code',
    'replace_lines',
    'full_scaffold', 'full_rewrite',
  };

  /// Attempts to parse an action from raw model output.
  /// Returns both the parsed action (if any) and a human-readable error for retry prompting.
  _ParseAttempt _tryParseAction(String text) {
    try {
      final jsonBlock = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```', caseSensitive: false);
      final match = jsonBlock.firstMatch(text);

      String rawJson;
      if (match != null) {
        rawJson = match.group(1)!;
      } else {
        final start = text.indexOf('{');
        final end = text.lastIndexOf('}');
        if (start == -1 || end == -1 || end <= start) {
          return _ParseAttempt(null, 'No JSON object found in response.');
        }
        rawJson = text.substring(start, end + 1);
      }

      final Map<String, dynamic> parsed = jsonDecode(rawJson);

      final declaredType = (parsed['action'] ?? parsed['tool'] ?? parsed['type'])?.toString();
      if (declaredType == null || !_knownActionTypes.contains(declaredType)) {
        return _ParseAttempt(
          null,
          'Unrecognized or missing "action" type: ${declaredType ?? "(none)"}. '
          'Expected one of: ${_knownActionTypes.join(", ")}.',
        );
      }

      final action = CodeAction.fromJson(parsed);
      final validationError = _validateAction(action);
      if (validationError != null) {
        return _ParseAttempt(null, validationError);
      }

      return _ParseAttempt(action, null);
    } catch (e) {
      return _ParseAttempt(null, 'JSON decode error: $e');
    }
  }

  /// CodeAction.fromJson fills missing fields with empty strings rather than
  /// failing, so a structurally-valid-but-empty action (e.g. a
  /// search_replace with no target) would otherwise sail through as
  /// "success" while doing nothing or corrupting the code. Catch that here.
  String? _validateAction(CodeAction action) {
    switch (action) {
      case SearchReplaceAction(:final target):
        if (target.trim().isEmpty) {
          return 'search_replace action is missing a "target" string to match against.';
        }
        return null;
      case InsertAfterAction(:final anchor, :final code):
        if (anchor.trim().isEmpty) {
          return 'insert_after action is missing an "anchor" string.';
        }
        if (code.trim().isEmpty) {
          return 'insert_after action has no "code" to insert.';
        }
        return null;
      case ReplaceLinesAction(:final code, :final startLine, :final endLine):
        if (code.trim().isEmpty) {
          return 'replace_lines action has no replacement "code".';
        }
        if (endLine < startLine) {
          return 'replace_lines action has end line ($endLine) before start line ($startLine).';
        }
        return null;
      case FullScaffoldAction(:final html):
        if (html.trim().isEmpty) {
          return 'full_scaffold action returned empty "html".';
        }
        return null;
    }
  }

  bool _looksLikeHtml(String text) {
    final lower = text.toLowerCase();
    return lower.contains('<html') || lower.contains('<!doctype') || lower.contains('<body') || lower.contains('<div');
  }

  String _truncateForDisplay(String text, {int maxLen = 160}) {
    final trimmed = text.trim();
    if (trimmed.length <= maxLen) return trimmed;
    return '${trimmed.substring(0, maxLen)}…';
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

class _ParseAttempt {
  final CodeAction? action;
  final String? error;
  const _ParseAttempt(this.action, this.error);
}