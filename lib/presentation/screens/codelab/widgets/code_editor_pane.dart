import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';

class CodeEditorPane extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onRun;
  final VoidCallback onAskAi;
  final String? emptyStateHint;

  const CodeEditorPane({
    super.key,
    required this.controller,
    required this.onRun,
    required this.onAskAi,
    this.emptyStateHint,
  });

  @override
  State<CodeEditorPane> createState() => _CodeEditorPaneState();
}

class _CodeEditorPaneState extends State<CodeEditorPane> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _linesScrollController = ScrollController();
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _updateLineCount();
    widget.controller.addListener(_updateLineCount);

    _scrollController.addListener(() {
      if (_linesScrollController.hasClients) {
        _linesScrollController.jumpTo(_scrollController.offset);
      }
    });
  }

  void _updateLineCount() {
    final count = '\n'.allMatches(widget.controller.text).length + 1;
    if (count != _lineCount) {
      setState(() => _lineCount = count);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _linesScrollController.dispose();
    super.dispose();
  }

  void _insertSnippet(String snippet) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, snippet);
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + snippet.length),
      );
    } else {
      widget.controller.text += snippet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UEColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Editor Top Bar
          _buildEditorTopBar(),
          // Quick Syntax Snippet Helper Chips
          _buildSnippetBar(),
          // Editor Content Area (Line numbers + TextField)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line Numbers Gutter
                _buildLineNumbers(),
                // Code Input Area
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 16, 24),
                      child: TextField(
                        controller: widget.controller,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13.5,
                          height: 1.5,
                          color: Color(0xFFE2E8F0),
                          letterSpacing: 0.3,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: widget.emptyStateHint ?? '<!-- Write your HTML/CSS/JS code here -->',
                          hintStyle: const TextStyle(color: UEColors.textDim, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: UEColors.surface,
        border: Border(bottom: BorderSide(color: UEColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(TablerIcons.code, size: 18, color: UEColors.accent),
          const SizedBox(width: 8),
          Text(
            'index.html',
            style: UETypography.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: UEColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Copy Code
          IconButton(
            icon: const Icon(TablerIcons.copy, size: 16, color: UEColors.textSecondary),
            tooltip: 'Copy Code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.controller.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          // Ask AI Button
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: UEColors.violet.withValues(alpha: 0.15),
              foregroundColor: UEColors.violet,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onAskAi,
            icon: const Icon(TablerIcons.sparkles, size: 15),
            label: const Text('Ask AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          // Run Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: UEColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onRun,
            icon: const Icon(TablerIcons.player_play, size: 15),
            label: const Text('Run', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSnippetBar() {
    final snippets = [
      '<button>',
      '<div>',
      '<style>',
      '<script>',
      'function()',
      'const',
      'let',
      'if()',
      'for()',
      '{ }',
      'console.log()',
      'document.getElementById()',
    ];

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF131720),
        border: Border(bottom: BorderSide(color: UEColors.border, width: 0.5)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: snippets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final snippet = snippets[index];
          return Center(
            child: InkWell(
              onTap: () => _insertSnippet(snippet),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2330),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: UEColors.border.withValues(alpha: 0.5)),
                ),
                child: Text(
                  snippet,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF93C5FD),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLineNumbers() {
    return Container(
      width: 42,
      padding: const EdgeInsets.fromLTRB(4, 12, 6, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1118),
        border: Border(right: BorderSide(color: Color(0xFF1E2330), width: 1)),
      ),
      child: SingleChildScrollView(
        controller: _linesScrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_lineCount, (i) {
            return SizedBox(
              height: 13.5 * 1.5,
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
