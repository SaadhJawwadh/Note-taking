import 'package:flutter/material.dart';

class MarkdownFormattingController extends TextEditingController {
  final Map<String, TextStyle> patternMap;
  final TextStyle? baseStyle;

  MarkdownFormattingController({String? text, this.baseStyle})
      : patternMap = {
          // Headings (e.g. # H1 or ## H2)
          r'^#{1,6}\s.*': const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent, // Distinct color for headings
          ),
          // Bold (**text**)
          r'\*\*(.*?)\*\*': const TextStyle(fontWeight: FontWeight.bold),
          // Italic (_text_)
          r'_(.*?)_': const TextStyle(fontStyle: FontStyle.italic),
          // Strikethrough (~~text~~)
          r'~~(.*?)~~': const TextStyle(decoration: TextDecoration.lineThrough),
          // Code (`text`)
          r'`(.*?)`': TextStyle(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
          ),
          // Quote (> text)
          r'^>.*': const TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
          // Link ([text](url))
          r'\[.*?\]\(.*?\)': const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          // Checkbox logic handled visually usually, but we can dim checked items
          r'- \[x\] .*': const TextStyle(
            color: Colors.grey,
            decoration: TextDecoration.lineThrough,
          ),
        },
        super(text: text);

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final List<TextSpan> children = [];
    final String text = this.text;
    style = style?.merge(baseStyle) ?? baseStyle; // Merge with base

    if (text.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    // Very simple localized pairing. For complex overlap, a full parser is needed.
    // This simple approach iterates patterns. To do it "Right" usually requires a tokenizer.
    // However, for immediate feedback on simple MD, we can just apply matches.
    // But applying multiple styles to one span is tricky with just regex replacement.

    // BETTER APPROACH: Use regex to find all matches, sort them, and fill gaps.
    // But overlapping is the problem (e.g. **_bold italic_**).
    // Let's implement a simplified loop that prioritizes patterns or just applies the first match found?
    // standard `flutter_markdown` parsing is heavy.
    // Let's use a simpler known library or write a basic one.
    // Given the request is "realtime preview", highlighting is key.

    // We will use a simplified approach: Split text by newlines for line-based rules (Headings, Quotes).
    // Then for inline, parse segments.

    text.splitMapJoin(
      RegExp(
          r'(^#{1,6}\s.*$)|(^>.*$)|(\*\*.*?\*\*)|(_.*?_)|(~~.*?~~)|(`.*?`)|(\[.*?\]\(.*?\))',
          multiLine: true),
      onMatch: (m) {
        final String match = m[0]!;
        TextStyle? activeStyle = style;

        if (RegExp(r'^#{1,6}\s').hasMatch(match)) {
          double sizeScale = 1.0;
          if (match.startsWith('# '))
            sizeScale = 1.5;
          else if (match.startsWith('## '))
            sizeScale = 1.3;
          else
            sizeScale = 1.1;

          activeStyle = activeStyle!.merge(TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: (activeStyle.fontSize ?? 16) * sizeScale,
              color: patternMap[r'^#{1,6}\s.*']?.color));
        } else if (match.startsWith('>')) {
          activeStyle = activeStyle!.merge(patternMap[r'^>.*']);
        } else if (match.startsWith('**')) {
          activeStyle = activeStyle!.merge(patternMap[r'\*\*(.*?)\*\*']);
        } else if (match.startsWith('_')) {
          activeStyle = activeStyle!.merge(patternMap[r'_(.*?)_']);
        } else if (match.startsWith('~~')) {
          activeStyle = activeStyle!.merge(patternMap[r'~~(.*?)~~']);
        } else if (match.startsWith('`')) {
          activeStyle = activeStyle!.merge(patternMap[r'`(.*?)`']);
        } else if (match.startsWith('[')) {
          activeStyle = activeStyle!.merge(patternMap[r'\[.*?\]\(.*?\)']);
        }

        children.add(TextSpan(text: match, style: activeStyle));
        return '';
      },
      onNonMatch: (n) {
        children.add(TextSpan(text: n, style: style));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }
}
