import 'dart:convert';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:markdown/markdown.dart' as md;

class RichTextUtils {
  /// Converts Markdown string to Quill Delta object.
  static Delta markdownToDelta(String markdown) {
    if (markdown.trim().isEmpty) {
      return Delta()..insert('\n');
    }

    final mdDocument =
        md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);

    final converter = MarkdownToDelta(markdownDocument: mdDocument);
    final delta = converter.convert(markdown);

    if (delta.isEmpty) {
      return Delta()..insert('\n');
    }

    // Ensure it ends with a newline
    final lastOp = delta.last;
    if (lastOp.isInsert &&
        lastOp.data is String &&
        !(lastOp.data as String).endsWith('\n')) {
      delta.insert('\n');
    }

    return delta;
  }

  /// Converts Quill Delta object to Markdown string.
  static String deltaToMarkdown(Delta delta) {
    if (delta.isEmpty) return '';

    // Using markdown_quill's DeltaToMarkdown feature
    final converter = DeltaToMarkdown();
    return converter.convert(delta);
  }

  /// Serialises a Delta to a lossless JSON string for storage.
  static String deltaToJson(Delta delta) {
    return jsonEncode(delta.toJson());
  }

  /// Loads content from storage: tries Delta JSON first, falls back to Markdown for old notes.
  static Delta contentToDelta(String content) {
    if (content.isEmpty) return Delta()..insert('\n');
    if (content.startsWith('[')) {
      try {
        final ops = jsonDecode(content) as List;
        return Delta.fromJson(ops);
      } catch (_) {}
    }
    return markdownToDelta(content); // legacy Markdown fallback
  }

  /// Extracts plain text from either Delta JSON or Markdown content for card preview.
  ///
  /// For Quill Delta content, detects checklist items from `list` attributes on
  /// newline ops and prepends ☑ / ☐ accordingly. Returns at most [maxLines] lines,
  /// appending "..." when content is truncated.
  static String contentToPlainText(String content, {int maxLines = 4}) {
    if (content.isEmpty) return '';
    if (content.startsWith('[')) {
      try {
        final ops = jsonDecode(content) as List;
        final delta = Delta.fromJson(ops);

        final allLines = <String>[];
        final lineBuffer = StringBuffer();

        for (final op in delta.toList()) {
          if (!op.isInsert) continue;
          if (op.data is! String) continue; // skip embedded blots (images etc.)

          final text = op.data as String;
          var start = 0;

          for (int i = 0; i < text.length; i++) {
            if (text[i] == '\n') {
              lineBuffer.write(text.substring(start, i));
              var line = lineBuffer.toString();

              // List prefix only for single-newline ops carrying list attributes
              if (text == '\n') {
                final listAttr = op.attributes?['list'] as String?;
                if (listAttr == 'checked') {
                  line = '☑ $line';
                } else if (listAttr == 'unchecked') {
                  line = '☐ $line';
                }
              }

              allLines.add(line);
              lineBuffer.clear();
              start = i + 1;
            }
          }

          // Remainder after the last newline (or the whole text if no newline)
          if (start < text.length) {
            lineBuffer.write(text.substring(start));
          }
        }

        // Include any unterminated final line
        if (lineBuffer.isNotEmpty) allLines.add(lineBuffer.toString());

        // Remove trailing blank lines
        while (allLines.isNotEmpty && allLines.last.trim().isEmpty) {
          allLines.removeLast();
        }

        if (allLines.isEmpty) return '';
        final taken = allLines.take(maxLines).join('\n');
        return allLines.length > maxLines ? '$taken...' : taken;
      } catch (_) {}
    }
    // Legacy Markdown: strip common syntax characters for a rough plain-text preview
    final stripped = content
        .replaceAll(RegExp(r'[#*_`>\[\]!]'), '')
        .trim()
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (stripped.isEmpty) return '';
    final taken = stripped.take(maxLines).join('\n');
    return stripped.length > maxLines ? '$taken...' : taken;
  }
}
