import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:note_taking_app/utils/quill_checklist_helper.dart';
import 'package:flutter/material.dart';

void main() {
  group('QuillChecklistHelper Tests', () {
    test('syncChecklists - checked items get struck out, unchecked items get strike cleared, and sorted', () {
      final doc = Document.fromDelta(Delta()
        ..insert('Task 1')
        ..insert('\n', {'list': 'checked'})
        ..insert('Task 2')
        ..insert('\n', {'list': 'unchecked'})
      );
      final controller = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      QuillChecklistHelper.syncChecklists(controller);

      final docDelta = controller.document.toDelta();
      final ops = docDelta.toList();

      // Check Task 2 (should be first, unchecked, not struck)
      expect(ops[0].data, equals('Task 2'));
      expect(ops[0].attributes?['strike'], isNull);

      // Check Task 1 (should be second, checked, struck)
      expect(ops[2].data, equals('Task 1'));
      expect(ops[2].attributes?['strike'], isTrue);
    });

    test('syncChecklists - reorders contiguous checklists so checked items go to bottom', () {
      final controller = QuillController(
        document: Document.fromDelta(Delta()
          ..insert('Task 1')
          ..insert('\n', {'list': 'checked'})
          ..insert('Task 2')
          ..insert('\n', {'list': 'unchecked'})
        ),
        selection: const TextSelection.collapsed(offset: 13), // End of Task 2
      );

      QuillChecklistHelper.syncChecklists(controller);

      final text = controller.document.toPlainText();
      expect(text, equals('Task 2\nTask 1\n'));

      // Check that Task 1 is struck and Task 2 is not
      final ops = controller.document.toDelta().toList();
      expect(ops[0].data, equals('Task 2'));
      expect(ops[0].attributes?['strike'], isNull);
      expect(ops[2].data, equals('Task 1'));
      expect(ops[2].attributes?['strike'], isTrue);

      // Verify selection mapping: original offset 13 was at the end of 'Task 2', which moved to offset 6.
      expect(controller.selection.baseOffset, equals(6));
    });
  });
}
