import '../models/code_action.dart';

/// Applies structured delta edits to source code deterministically with diff computation.
class CodeDeltaApplier {
  CodeDeltaApplier._();

  /// Applies a [CodeAction] to [originalCode] and returns a [CodeDeltaResult] with diffs.
  static CodeDeltaResult applyAction({
    required String originalCode,
    required CodeAction action,
  }) {
    switch (action) {
      case SearchReplaceAction(:final target, :final replacement):
        return _applySearchReplace(originalCode, target, replacement);

      case InsertAfterAction(:final anchor, :final code):
        return _applyInsertAfter(originalCode, anchor, code);

      case ReplaceLinesAction(:final startLine, :final endLine, :final code):
        return _applyReplaceLines(originalCode, startLine, endLine, code);

      case FullScaffoldAction(:final html):
        return _applyFullScaffold(originalCode, html);
    }
  }

  static CodeDeltaResult _applySearchReplace(String original, String target, String replacement) {
    if (target.trim().isEmpty) {
      return CodeDeltaResult(
        success: false,
        updatedCode: original,
        errorMessage: 'Search target cannot be empty.',
      );
    }

    if (!original.contains(target)) {
      // Try normalized trimmed matching
      final normalizedOriginal = original.replaceAll('\r\n', '\n');
      final normalizedTarget = target.replaceAll('\r\n', '\n');

      if (!normalizedOriginal.contains(normalizedTarget)) {
        return CodeDeltaResult(
          success: false,
          updatedCode: original,
          errorMessage: 'Could not find target code in project to replace.',
        );
      }
      final updated = normalizedOriginal.replaceFirst(normalizedTarget, replacement);
      return CodeDeltaResult(
        success: true,
        updatedCode: updated,
        diff: _computeDiff(normalizedOriginal, updated),
      );
    }

    final updated = original.replaceFirst(target, replacement);
    return CodeDeltaResult(
      success: true,
      updatedCode: updated,
      diff: _computeDiff(original, updated),
    );
  }

  static CodeDeltaResult _applyInsertAfter(String original, String anchor, String code) {
    if (anchor.trim().isEmpty) {
      return CodeDeltaResult(
        success: false,
        updatedCode: original,
        errorMessage: 'Anchor string cannot be empty.',
      );
    }

    final index = original.indexOf(anchor);
    if (index == -1) {
      return CodeDeltaResult(
        success: false,
        updatedCode: original,
        errorMessage: 'Could not find anchor "$anchor" in project.',
      );
    }

    final insertPosition = index + anchor.length;
    final prefix = original.substring(0, insertPosition);
    final suffix = original.substring(insertPosition);

    final updated = '$prefix\n$code$suffix';
    return CodeDeltaResult(
      success: true,
      updatedCode: updated,
      diff: _computeDiff(original, updated),
    );
  }

  static CodeDeltaResult _applyReplaceLines(String original, int startLine, int endLine, String code) {
    final lines = original.split('\n');
    if (startLine < 1 || startLine > lines.length || endLine < startLine) {
      return CodeDeltaResult(
        success: false,
        updatedCode: original,
        errorMessage: 'Invalid line range: $startLine to $endLine (total lines: ${lines.length}).',
      );
    }

    final zeroStart = startLine - 1;
    final zeroEnd = endLine > lines.length ? lines.length : endLine;

    final before = lines.sublist(0, zeroStart);
    final after = lines.sublist(zeroEnd);

    final newLines = code.split('\n');
    final combined = [...before, ...newLines, ...after].join('\n');

    return CodeDeltaResult(
      success: true,
      updatedCode: combined,
      diff: _computeDiff(original, combined),
    );
  }

  static CodeDeltaResult _applyFullScaffold(String original, String html) {
    final cleanHtml = html.trim();
    if (cleanHtml.isEmpty) {
      return CodeDeltaResult(
        success: false,
        updatedCode: original,
        errorMessage: 'Scaffold HTML cannot be empty.',
      );
    }

    return CodeDeltaResult(
      success: true,
      updatedCode: cleanHtml,
      diff: _computeDiff(original, cleanHtml),
    );
  }

  /// Simple fast line-by-line diff calculator for UI presentation.
  static List<DiffLine> _computeDiff(String oldText, String newText) {
    final oldLines = oldText.split('\n');
    final newLines = newText.split('\n');
    final List<DiffLine> diff = [];

    // Simple diff comparison for small code modifications
    final oldSet = oldLines.toSet();
    final newSet = newLines.toSet();

    for (final line in oldLines) {
      if (!newSet.contains(line) && line.trim().isNotEmpty) {
        diff.add(DiffLine(line, DiffType.removed));
      }
    }

    for (final line in newLines) {
      if (!oldSet.contains(line) && line.trim().isNotEmpty) {
        diff.add(DiffLine(line, DiffType.added));
      }
    }

    return diff;
  }
}
