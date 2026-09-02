import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

class QuillChecklistHelper {
  /// Returns a list of all Line nodes in the document.
  static List<Line> getDocumentLines(Document doc) {
    final lines = <Line>[];
    for (final child in doc.root.children) {
      if (child is Line) {
        lines.add(child);
      } else if (child is Block) {
        for (final subChild in child.children) {
          if (subChild is Line) {
            lines.add(subChild);
          }
        }
      }
    }
    return lines;
  }

  /// Returns statistics about the checklists in the document.
  static ChecklistStats getChecklistStats(Document doc) {
    int checked = 0;
    int unchecked = 0;
    for (final line in getDocumentLines(doc)) {
      final listAttr = line.style.attributes['list']?.value;
      if (listAttr == 'checked') {
        checked++;
      } else if (listAttr == 'unchecked') {
        unchecked++;
      }
    }
    return ChecklistStats(
      totalCount: checked + unchecked,
      checkedCount: checked,
      uncheckedCount: unchecked,
    );
  }

  /// Extracts all completed (checked) checklist items from the controller's document,
  /// removes them from the document, and returns their text contents.
  static List<String> extractAndRemoveCheckedLines(QuillController controller) {
    final doc = controller.document;
    final lines = getDocumentLines(doc);

    // Check if there are any checked checklist lines
    final hasChecked = lines.any((l) => l.style.attributes['list']?.value == 'checked');
    if (!hasChecked) return [];

    final extracted = <String>[];
    final originalDelta = doc.toDelta();
    var remainingDelta = Delta();

    for (final line in lines) {
      final start = line.documentOffset;
      final len = line.length;
      final isChecked = line.style.attributes['list']?.value == 'checked';

      if (isChecked) {
        final plainText = doc.toPlainText();
        String text = '';
        if (start < plainText.length) {
          final end = (start + len).clamp(0, plainText.length);
          text = plainText.substring(start, end).replaceAll('\n', '').trim();
        }
        if (text.isNotEmpty) {
          extracted.add(text);
        }
      } else {
        // Retain this line exactly in remainingDelta
        final lineDelta = originalDelta.slice(start, start + len);
        remainingDelta = remainingDelta.concat(lineDelta);
      }
    }

    // Quill documents must never be empty and must always terminate with '\n'
    if (remainingDelta.isEmpty) {
      remainingDelta = Delta()..insert('\n');
    } else {
      final lastOp = remainingDelta.last;
      if (lastOp.data is! String || !(lastOp.data as String).endsWith('\n')) {
        remainingDelta.insert('\n');
      }
    }

    // Atomically compose the diff between original and remaining delta
    final diff = originalDelta.diff(remainingDelta);
    final sel = controller.selection;
    controller.compose(diff, sel, ChangeSource.local);

    // Clamp selection offset so it never exceeds doc.length - 1
    final maxOffset = (controller.document.length - 1).clamp(0, double.infinity).toInt();
    if (controller.selection.baseOffset > maxOffset || controller.selection.extentOffset > maxOffset) {
      controller.updateSelection(
        TextSelection.collapsed(offset: maxOffset),
        ChangeSource.local,
      );
    }

    return extracted;
  }

  /// Restores a text string back into the controller document as an unchecked checklist item.
  static void restoreUncheckedItem(QuillController controller, String text) {
    final doc = controller.document;
    final plainText = doc.toPlainText();
    final isDocEmpty = plainText.trim().isEmpty;
    if (isDocEmpty) {
      // Document is completely blank: insert text directly at 0
      doc.insert(0, text);
      final lineEndPos = text.length;
      if (lineEndPos < doc.length) {
        doc.format(lineEndPos, 1, Attribute.unchecked);
      }
      final clearStrike = Attribute.clone(Attribute.strikeThrough, null);
      if (text.isNotEmpty) {
        doc.format(0, text.length, clearStrike);
      }
      controller.updateSelection(
        TextSelection.collapsed(offset: text.length.clamp(0, doc.length - 1)),
        ChangeSource.local,
      );
      return;
    }

    int lastNewlinePos = plainText.lastIndexOf('\n');
    if (lastNewlinePos <= 0) {
      lastNewlinePos = plainText.length > 1 ? plainText.length - 1 : 0;
    }
    if (lastNewlinePos > 0 && plainText[lastNewlinePos - 1] == '\n') {
      lastNewlinePos--;
    }

    // 1. Insert leading newline + item text
    doc.insert(lastNewlinePos, '\n$text');

    // 2. Format line-ending newline with Attribute.unchecked (block attribute)
    final lineEndPos = lastNewlinePos + 1 + text.length;
    if (lineEndPos < doc.length) {
      doc.format(lineEndPos, 1, Attribute.unchecked);
    }

    // 3. Clear strikethrough from text characters (inline attribute) if present
    final clearStrike = Attribute.clone(Attribute.strikeThrough, null);
    if (text.isNotEmpty) {
      doc.format(lastNewlinePos + 1, text.length, clearStrike);
    }

    // 4. Safely update selection to avoid stale node cursor exceptions
    controller.updateSelection(
      TextSelection.collapsed(offset: (lastNewlinePos + 1 + text.length).clamp(0, doc.length - 1)),
      ChangeSource.local,
    );
  }
}

class ChecklistStats {
  final int totalCount;
  final int checkedCount;
  final int uncheckedCount;

  const ChecklistStats({
    required this.totalCount,
    required this.checkedCount,
    required this.uncheckedCount,
  });

  double get completionPercentage =>
      totalCount == 0 ? 0.0 : (checkedCount / totalCount);

  int get completionPercentInt => (completionPercentage * 100).round();
}
