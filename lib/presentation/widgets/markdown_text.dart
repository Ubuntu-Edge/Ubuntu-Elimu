import 'package:flutter/material.dart';

class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const MarkdownText({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> spans = [];
    final RegExp regex = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final Match match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: textAlign,
    );
  }
}
