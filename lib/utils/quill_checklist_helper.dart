import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
    final extracted = <String>[];
    final doc = controller.document;
    final lines = getDocumentLines(doc).reversed;

    for (final line in lines) {
      if (line.style.attributes['list']?.value == 'checked') {
        final start = line.documentOffset;
        final len = line.length;
        final plainText = doc.toPlainText();
        String text = '';
        if (start < plainText.length) {
          final end = (start + len).clamp(0, plainText.length);
          text = plainText.substring(start, end).replaceAll('\n', '').trim();
        }
        if (text.isNotEmpty) {
          extracted.add(text);
        }
        doc.delete(start, len);
      }
    }

    // Clamp selection offset so it never exceeds doc.length - 1
    if (extracted.isNotEmpty) {
      final sel = controller.selection;
      final maxOffset = (doc.length - 1).clamp(0, double.infinity).toInt();
      if (sel.baseOffset > maxOffset || sel.extentOffset > maxOffset) {
        final safeOffset = sel.baseOffset.clamp(0, maxOffset);
        controller.updateSelection(
          TextSelection.collapsed(offset: safeOffset),
          ChangeSource.local,
        );
      }
    }

    return extracted.reversed.toList();
  }

  /// Restores a text string back into the controller document as an unchecked checklist item.
  static void restoreUncheckedItem(QuillController controller, String text) {
    final doc = controller.document;
    final plainText = doc.toPlainText();
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
