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
  static String contentToPlainText(String content, {int maxChars = 100}) {
    if (content.isEmpty) return '';
    if (content.startsWith('[')) {
      try {
        final ops = jsonDecode(content) as List;
        final delta = Delta.fromJson(ops);
        final plain = delta
            .toList()
            .where((op) => op.isInsert && op.data is String)
            .map((op) => op.data as String)
            .join()
            .replaceAll('\n', ' ')
            .trim();
        return plain.length > maxChars ? '${plain.substring(0, maxChars)}...' : plain;
      } catch (_) {}
    }
    // Legacy Markdown: strip common syntax characters for a rough plain-text preview
    final stripped = content
        .replaceAll(RegExp(r'[#*_`>\[\]!]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return stripped.length > maxChars ? '${stripped.substring(0, maxChars)}...' : stripped;
  }
}
