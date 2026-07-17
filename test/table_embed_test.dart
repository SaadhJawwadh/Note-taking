import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:note_taking_app/utils/rich_text_utils.dart';

void main() {
  group('TableBlockEmbed Unit Tests', () {
    test('markdownToDelta converts markdown table to TableBlockEmbed', () {
      const markdown = '''
# Title
Some text before.

| Col 1 | Col 2 | Col 3 |
|---|---|---|
| A1 | B1 | C1 |
| A2 | B2 | C2 |

Some text after.''';

      final delta = RichTextUtils.markdownToDelta(markdown);
      
      // Verify delta contains the table embed
      bool foundTable = false;
      for (final op in delta.toList()) {
        if (op.isInsert && op.data is TableBlockEmbed) {
          final embed = op.data as TableBlockEmbed;
          expect(embed.type, equals(TableBlockEmbed.tableType));
          final List<dynamic> cells = jsonDecode(embed.data);
          expect(cells.length, equals(3)); // Header + 2 data rows
          expect(cells[0], equals(['Col 1', 'Col 2', 'Col 3']));
          expect(cells[1], equals(['A1', 'B1', 'C1']));
          expect(cells[2], equals(['A2', 'B2', 'C2']));
          foundTable = true;
        }
      }
      expect(foundTable, isTrue);
    });

    test('deltaToMarkdown converts TableBlockEmbed back to markdown table', () {
      final delta = Delta()
        ..insert('Before table\n')
        ..insert(const TableBlockEmbed('[["H1","H2"],["A","B"]]'))
        ..insert('\nAfter table\n');

      final markdown = RichTextUtils.deltaToMarkdown(delta);
      expect(markdown, contains('| H1 | H2 |'));
      expect(markdown, contains('|---|---|'));
      expect(markdown, contains('| A | B |'));
    });

    test('contentToPlainText renders table embed cleanly for card previews', () {
      final delta = Delta()
        ..insert(const TableBlockEmbed('[["H1","H2"],["A","B"]]'))
        ..insert('\n');
      final jsonStr = RichTextUtils.deltaToJson(delta);
      
      final preview = RichTextUtils.contentToPlainText(jsonStr);
      expect(preview.trim(), equals('H1 | H2\nA | B'));
    });
  });
}
