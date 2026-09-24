/// Represents a structured delta edit proposed by the on-device AI coding agent.
sealed class CodeAction {
  const CodeAction();

  factory CodeAction.fromJson(Map<String, dynamic> json) {
    final actionType = json['action'] ?? json['tool'] ?? json['type'];

    switch (actionType) {
      case 'search_replace':
      case 'replace_text':
        return SearchReplaceAction(
          target: json['target']?.toString() ?? '',
          replacement: json['replacement']?.toString() ?? '',
        );
      case 'insert_after':
      case 'insert_code':
        return InsertAfterAction(
          anchor: json['anchor']?.toString() ?? json['after_target']?.toString() ?? '',
          code: json['code']?.toString() ?? json['content']?.toString() ?? '',
        );
      case 'replace_lines':
        return ReplaceLinesAction(
          startLine: int.tryParse(json['start']?.toString() ?? json['start_line']?.toString() ?? '1') ?? 1,
          endLine: int.tryParse(json['end']?.toString() ?? json['end_line']?.toString() ?? '1') ?? 1,
          code: json['code']?.toString() ?? json['content']?.toString() ?? '',
        );
      case 'full_scaffold':
      case 'full_rewrite':
      default:
        return FullScaffoldAction(
          html: json['html']?.toString() ?? json['code']?.toString() ?? json['content']?.toString() ?? '',
        );
    }
  }

  Map<String, dynamic> toJson();
}

class SearchReplaceAction extends CodeAction {
  final String target;
  final String replacement;

  const SearchReplaceAction({
    required this.target,
    required this.replacement,
  });

  @override
  Map<String, dynamic> toJson() => {
        'action': 'search_replace',
        'target': target,
        'replacement': replacement,
      };
}

class InsertAfterAction extends CodeAction {
  final String anchor;
  final String code;

  const InsertAfterAction({
    required this.anchor,
    required this.code,
  });

  @override
  Map<String, dynamic> toJson() => {
        'action': 'insert_after',
        'anchor': anchor,
        'code': code,
      };
}

class ReplaceLinesAction extends CodeAction {
  final int startLine;
  final int endLine;
  final String code;

  const ReplaceLinesAction({
    required this.startLine,
    required this.endLine,
    required this.code,
  });

  @override
  Map<String, dynamic> toJson() => {
        'action': 'replace_lines',
        'start': startLine,
        'end': endLine,
        'code': code,
      };
}

class FullScaffoldAction extends CodeAction {
  final String html;

  const FullScaffoldAction({
    required this.html,
  });

  @override
  Map<String, dynamic> toJson() => {
        'action': 'full_scaffold',
        'html': html,
      };
}

class CodeDeltaResult {
  final bool success;
  final String updatedCode;
  final String? errorMessage;
  final List<DiffLine> diff;

  const CodeDeltaResult({
    required this.success,
    required this.updatedCode,
    this.errorMessage,
    this.diff = const [],
  });
}

class DiffLine {
  final String text;
  final DiffType type;

  const DiffLine(this.text, this.type);
}

enum DiffType { added, removed, unchanged }
