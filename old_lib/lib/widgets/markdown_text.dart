import 'package:flutter/material.dart';

class ManualMarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;

  const ManualMarkdownText(
    this.text, {
    super.key,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle =
        baseStyle ?? const TextStyle(fontSize: 14, color: Colors.black87);

    return SelectableText.rich(
      _buildTextSpans(text, defaultStyle),
    );
  }

  TextSpan _buildTextSpans(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check if line is a header (starts with ##)
      if (line.trim().startsWith('##')) {
        final headerText = line.replaceFirst(RegExp(r'^##\s*'), '');
        spans.add(TextSpan(
          text: headerText,
          style: baseStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 2.0,
          ),
        ));
      }
      // Check if line is a bullet point (starts with -)
      else if (line.trim().startsWith('-')) {
        final bulletText = line.replaceFirst(RegExp(r'^\s*-\s*'), '');
        spans.add(TextSpan(
          text: '  • ',
          style: baseStyle.copyWith(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ));
        spans.addAll(_parseInlineFormatting(bulletText, baseStyle));
      }
      // Regular line - parse inline formatting
      else {
        spans.addAll(_parseInlineFormatting(line, baseStyle));
      }

      // Add newline after each line (except the last one)
      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: baseStyle));
      }
    }

    return TextSpan(children: spans);
  }

  List<TextSpan> _parseInlineFormatting(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];

    // Pattern to match **bold text**
    final boldPattern = RegExp(r'\*\*(.+?)\*\*');

    int currentIndex = 0;

    // Find all bold patterns first
    final boldMatches = boldPattern.allMatches(text).toList();

    for (final match in boldMatches) {
      // Add text before the bold text
      if (match.start > currentIndex) {
        final beforeText = text.substring(currentIndex, match.start);
        // Check for italic in the before text
        spans.addAll(_parseItalic(beforeText, baseStyle));
      }

      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ));

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      final remainingText = text.substring(currentIndex);
      spans.addAll(_parseItalic(remainingText, baseStyle));
    }

    // If no bold was found, parse italic on the entire text
    if (spans.isEmpty) {
      spans.addAll(_parseItalic(text, baseStyle));
    }

    return spans;
  }

  List<TextSpan> _parseItalic(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final italicPattern = RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)');

    int currentIndex = 0;

    for (final match in italicPattern.allMatches(text)) {
      // Add text before the italic text
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }

      // Add the italic text
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ));

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
    }

    // If no italic was found, return the entire text
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }

    return spans;
  }
}

// Usage in your dialog:
// ManualMarkdownText(
//   aiAnalysisReport,
//   baseStyle: TextStyle(fontSize: 14, color: Colors.black87),
// )
