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
}
