import 'package:flutter/material.dart';

class MarkdownFormattingController extends TextEditingController {
  final Map<String, TextStyle> patternMap;
  final TextStyle? baseStyle;

  MarkdownFormattingController({super.text, this.baseStyle})
      : patternMap = {
          // Headings (e.g. # H1) - Match only at start of line
          r'(?m)^#{1,6}\s.*': const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
          // Bold (**text**)
          r'\*\*(.*?)\*\*': const TextStyle(fontWeight: FontWeight.bold),
          // Italic (_text_)
          r'_[^_]+_': const TextStyle(fontStyle: FontStyle.italic),
          // Strikethrough (~~text~~)
          r'~~(.*?)~~': const TextStyle(decoration: TextDecoration.lineThrough),
          // Code (`text`)
          r'`(.*?)`': TextStyle(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
          ),
          // Quote (> text) - Match only at start of line
          r'(?m)^>.*': const TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.blueAccent,
          ),
          // Link ([text](url))
          r'\[.*?\]\(.*?\)': const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          // Checkbox logic
          r'(?m)^- \[ \] .*': const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          r'(?m)^- \[x\] .*': const TextStyle(
            color: Colors.grey,
            decoration: TextDecoration.lineThrough,
          ),
        };

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final List<TextSpan> children = [];
    final String text = this.text;
    style = style?.merge(baseStyle) ?? baseStyle;

    if (text.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    // Combined regex for performance and priority
    final combinedRegex = RegExp(
      r'(^#{1,6}\s.*$)|(^>.*$)|(\*\*.*?\*\*)|(_[^_]+_)|(~~.*?~~)|(`.*?`)|(\[.*?\]\(.*?\))|(^- \[ \] .*$)|(^- \[x\] .*$)',
      multiLine: true,
    );

    text.splitMapJoin(
      combinedRegex,
      onMatch: (m) {
        final String match = m[0]!;
        TextStyle? activeStyle = style;

        if (match.startsWith('#')) {
          double sizeScale = 1.0;
          if (match.startsWith('# ')) {
            sizeScale = 1.35;
          } else if (match.startsWith('## ')) {
            sizeScale = 1.2;
          } else {
            sizeScale = 1.1;
          }
          activeStyle = activeStyle!.merge(TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: (activeStyle.fontSize ?? 16) * sizeScale,
            color: Colors.blueAccent,
          ));
        } else if (match.startsWith('>')) {
          activeStyle = activeStyle!.merge(patternMap[r'(?m)^>.*']);
        } else if (match.startsWith('**')) {
          activeStyle = activeStyle!.merge(patternMap[r'\*\*(.*?)\*\*']);
        } else if (match.startsWith('_')) {
          activeStyle = activeStyle!.merge(patternMap[r'_[^_]+_']);
        } else if (match.startsWith('~~')) {
          activeStyle = activeStyle!.merge(patternMap[r'~~(.*?)~~']);
        } else if (match.startsWith('`')) {
          activeStyle = activeStyle!.merge(patternMap[r'`(.*?)`']);
        } else if (match.startsWith('[')) {
          activeStyle = activeStyle!.merge(patternMap[r'\[.*?\]\(.*?\)']);
        } else if (match.startsWith('- [ ]')) {
          activeStyle = activeStyle!.merge(patternMap[r'(?m)^- \[ \] .*']);
        } else if (match.startsWith('- [x]')) {
          activeStyle = activeStyle!.merge(patternMap[r'(?m)^- \[x\] .*']);
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
