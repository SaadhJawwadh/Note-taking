import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:markdown/markdown.dart' as md;

class TableBlockEmbed extends CustomBlockEmbed {
  const TableBlockEmbed(String data) : super(tableType, data);
  static const String tableType = 'table';
}

class RichTextUtils {
  /// Converts Markdown string to Quill Delta object.
  static Delta markdownToDelta(String markdown) {
    if (markdown.trim().isEmpty) {
      return Delta()..insert('\n');
    }

    final preprocessed = _preprocessMarkdownTables(markdown);

    final mdDocument =
        md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);

    final converter = MarkdownToDelta(markdownDocument: mdDocument);
    final delta = converter.convert(preprocessed);

    final postprocessed = _postprocessDeltaTables(delta);

    if (postprocessed.isEmpty) {
      return Delta()..insert('\n');
    }

    // Ensure it ends with a newline
    final lastOp = postprocessed.last;
    if (lastOp.isInsert) {
      if (lastOp.data is String) {
        if (!(lastOp.data as String).endsWith('\n')) {
          postprocessed.insert('\n');
        }
      } else {
        postprocessed.insert('\n');
      }
    }

    return postprocessed;
  }

  /// Converts Quill Delta object to Markdown string.
  static String deltaToMarkdown(Delta delta) {
    if (delta.isEmpty) return '';

    final buffer = StringBuffer();
    var currentDelta = Delta();

    for (final op in delta.toList()) {
      String? rawTableData;
      if (op.isInsert) {
        if (op.data is Map) {
          final map = op.data as Map;
          if (map.containsKey('table')) {
            rawTableData = map['table'] as String;
          }
        } else if (op.data is CustomBlockEmbed) {
          final embed = op.data as CustomBlockEmbed;
          if (embed.type == TableBlockEmbed.tableType) {
            rawTableData = embed.data as String;
          }
        }
      }

      if (rawTableData != null) {
        // Convert accumulated delta segment to markdown first
        if (currentDelta.isNotEmpty) {
          buffer.write(DeltaToMarkdown().convert(currentDelta));
          currentDelta = Delta();
        }

        // Generate raw GFM table string
        try {
          final List<dynamic> outer = jsonDecode(rawTableData);
          final cells = outer.map((r) => (r as List).map((c) => c.toString()).toList()).toList();

          buffer.write('\n\n');

          // Header row
          buffer.write('|');
          for (final cell in cells[0]) {
            buffer.write(' $cell |');
          }
          buffer.write('\n');

          // Separator row
          buffer.write('|');
          for (int i = 0; i < cells[0].length; i++) {
            buffer.write('---|');
          }
          buffer.write('\n');

          // Data rows
          for (int r = 1; r < cells.length; r++) {
            buffer.write('|');
            for (final cell in cells[r]) {
              buffer.write(' $cell |');
            }
            buffer.write('\n');
          }
          buffer.write('\n');
        } catch (_) {}
      } else {
        currentDelta.push(op);
      }
    }

    if (currentDelta.isNotEmpty) {
      buffer.write(DeltaToMarkdown().convert(currentDelta));
    }

    return buffer.toString();
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

          // Check for Table Embed (Map format when parsed from JSON)
          if (op.data is Map) {
            final map = op.data as Map;
            if (map.containsKey('table')) {
              final preview = _formatTablePreview(map['table'] as String);
              final lines = preview.split('\n');
              for (int idx = 0; idx < lines.length; idx++) {
                if (idx > 0) {
                  allLines.add(lineBuffer.toString());
                  lineBuffer.clear();
                }
                lineBuffer.write(lines[idx]);
              }
              continue;
            }
          }

          // Check for Table Embed (Object format in memory)
          if (op.data is CustomBlockEmbed) {
            final embed = op.data as CustomBlockEmbed;
            if (embed.type == TableBlockEmbed.tableType) {
              final preview = _formatTablePreview(embed.data as String);
              final lines = preview.split('\n');
              for (int idx = 0; idx < lines.length; idx++) {
                if (idx > 0) {
                  allLines.add(lineBuffer.toString());
                  lineBuffer.clear();
                }
                lineBuffer.write(lines[idx]);
              }
              continue;
            }
          }

          if (op.data is! String) continue; // skip other embedded blots

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

  /// Preprocesses markdown strings to find GFM tables and replace them with base64 placeholder tokens.
  static String _preprocessMarkdownTables(String markdown) {
    final lines = markdown.split(RegExp(r'\r?\n'));
    final processedLines = <String>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();

      // Check if this line looks like a table header
      if (line.startsWith('|') && i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();

        // Check if the next line is a valid separator line (e.g. |---|---|)
        final isSeparator = nextLine.startsWith('|') &&
            RegExp(r'^\|[\s\-:|]+$').hasMatch(nextLine);

        if (isSeparator) {
          final tableLines = <String>[];
          tableLines.add(lines[i]);
          tableLines.add(lines[i + 1]);

          int j = i + 2;
          while (j < lines.length) {
            final l = lines[j].trim();
            if (l.startsWith('|')) {
              tableLines.add(lines[j]);
              j++;
            } else {
              break;
            }
          }

          final rows = <List<String>>[];
          for (final tLine in tableLines) {
            // Split by | and trim
            var parts = tLine.split('|');
            if (parts.first.isEmpty) parts.removeAt(0);
            if (parts.isNotEmpty && parts.last.isEmpty) parts.removeLast();

            final row = parts.map((p) => p.trim()).toList();
            rows.add(row);
          }

          // Remove separator row (index 1)
          if (rows.length > 1) {
            rows.removeAt(1);
          }

          final jsonStr = jsonEncode(rows);
          final b64 = base64Encode(utf8.encode(jsonStr));
          processedLines.add(':::TABLE_EMBED_$b64:::');

          i = j;
          continue;
        }
      }

      processedLines.add(lines[i]);
      i++;
    }

    return processedLines.join('\n');
  }

  /// Scans the Delta for base64 table tokens and replaces them with TableBlockEmbed.
  static Delta _postprocessDeltaTables(Delta delta) {
    final newDelta = Delta();
    for (final op in delta.toList()) {
      if (op.isInsert && op.data is String) {
        final text = op.data as String;
        final pattern = RegExp(r':::TABLE_EMBED_(.+?):::');

        int lastMatchEnd = 0;
        final matches = pattern.allMatches(text);

        if (matches.isEmpty) {
          newDelta.push(op);
          continue;
        }

        for (final match in matches) {
          if (match.start > lastMatchEnd) {
            newDelta.insert(text.substring(lastMatchEnd, match.start), op.attributes);
          }

          final b64 = match.group(1)!;
          try {
            final jsonStr = utf8.decode(base64Decode(b64));
            newDelta.insert(TableBlockEmbed(jsonStr));
          } catch (_) {
            newDelta.insert(match.group(0)!, op.attributes);
          }

          lastMatchEnd = match.end;
        }

        if (lastMatchEnd < text.length) {
          newDelta.insert(text.substring(lastMatchEnd), op.attributes);
        }
      } else {
        newDelta.push(op);
      }
    }
    return newDelta;
  }

  static String _formatTablePreview(String tableJson) {
    try {
      final List<dynamic> outer = jsonDecode(tableJson);
      if (outer.isNotEmpty) {
        final previewRows = <String>[];
        for (final r in outer.take(2)) {
          final row = r as List;
          final rowText = row.map((c) => c.toString().trim()).join(' | ');
          previewRows.add(rowText);
        }
        if (previewRows.isNotEmpty) {
          return previewRows.join('\n');
        }
      }
    } catch (_) {}
    return '[Table]';
  }
}
