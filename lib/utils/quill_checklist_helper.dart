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

  /// Check if the block is a checklist block.
  static bool isChecklistBlock(Block block) {
    final val = block.style.attributes['list']?.value;
    return val == 'checked' || val == 'unchecked';
  }

  /// Check if a line needs formatting under the checked/unchecked state.
  static bool needsStrikeFormatting(Line line, bool checked) {
    if (line.length <= 1) return false;
    
    if (checked) {
      for (final child in line.children) {
        if (child is Leaf) {
          if (child.style.attributes['strike']?.value != true) {
            return true;
          }
        }
      }
      return false;
    } else {
      for (final child in line.children) {
        if (child is Leaf) {
          if (child.style.attributes['strike']?.value == true) {
            return true;
          }
        }
      }
      return false;
    }
  }

  /// Scans the document, updates checklist strikethroughs, and groups/sorts
  /// contiguous checklist items with unchecked first, followed by checked items.
  static void syncChecklists(QuillController controller) {
    final doc = controller.document;
    final allLines = getDocumentLines(doc);

    // Phase 1: Formatting updates (apply strike to checked, clear from unchecked)
    for (final line in allLines) {
      final listAttr = line.style.attributes['list']?.value;
      if (listAttr == 'checked') {
        if (needsStrikeFormatting(line, true)) {
          doc.format(line.documentOffset, line.length - 1, Attribute.strikeThrough);
        }
      } else if (listAttr == 'unchecked') {
        if (needsStrikeFormatting(line, false)) {
          final clearStrike = Attribute.clone(Attribute.strikeThrough, null);
          doc.format(line.documentOffset, line.length - 1, clearStrike);
        }
      }
    }

    // Phase 2: Reordering contiguous checklist blocks
    // Fetch root children and document delta after formatting phase to avoid stale/detached nodes
    final currentDocDelta = doc.toDelta();
    final rootChildren = doc.root.children.toList();
    
    int i = 0;
    while (i < rootChildren.length) {
      final child = rootChildren[i];
      if (child is Block && isChecklistBlock(child)) {
        // Find contiguous checklist group
        int startIndex = i;
        int endIndex = i;
        while (endIndex < rootChildren.length - 1) {
          final next = rootChildren[endIndex + 1];
          if (next is Block && isChecklistBlock(next)) {
            endIndex++;
          } else {
            break;
          }
        }

        final contiguousBlocks = rootChildren.sublist(startIndex, endIndex + 1).cast<Block>();
        final groupLines = <Line>[];
        for (final b in contiguousBlocks) {
          groupLines.addAll(b.children.cast<Line>());
        }

        // Check if group is already sorted (unchecked first, then checked)
        bool seenChecked = false;
        bool alreadySorted = true;
        for (final line in groupLines) {
          final isChecked = line.style.attributes['list']?.value == 'checked';
          if (isChecked) {
            seenChecked = true;
          } else {
            if (seenChecked) {
              alreadySorted = false;
              break;
            }
          }
        }

        if (!alreadySorted) {
          // Partition lines
          final uncheckedLines = <Line>[];
          final checkedLines = <Line>[];
          for (final line in groupLines) {
            final isChecked = line.style.attributes['list']?.value == 'checked';
            if (isChecked) {
              checkedLines.add(line);
            } else {
              uncheckedLines.add(line);
            }
          }

          final groupStart = groupLines.first.documentOffset;
          final groupLength = (groupLines.last.documentOffset + groupLines.last.length) - groupStart;

          // Build sorted delta
          var sortedDelta = Delta();
          for (final line in uncheckedLines) {
            final sliced = currentDocDelta.slice(line.documentOffset, line.documentOffset + line.length);
            sortedDelta = sortedDelta.concat(sliced);
          }
          for (final line in checkedLines) {
            final sliced = currentDocDelta.slice(line.documentOffset, line.documentOffset + line.length);
            sortedDelta = sortedDelta.concat(sliced);
          }

          // Build change delta
          final changeDelta = Delta();
          if (groupStart > 0) {
            changeDelta.retain(groupStart);
          }
          changeDelta.delete(groupLength);
          for (final op in sortedDelta.toList()) {
            changeDelta.push(op);
          }

          // Compute new cursor/selection positions
          final selection = controller.selection;
          
          int mapSelectionIndex(int selIndex) {
            if (selIndex < groupStart) return selIndex;
            if (selIndex > groupStart + groupLength) return selIndex;
            
            for (final line in groupLines) {
              final lineStart = line.documentOffset;
              final lineEnd = lineStart + line.length;
              if (selIndex >= lineStart && selIndex <= lineEnd) {
                final relative = selIndex - lineStart;
                
                int currentOffset = groupStart;
                final sortedLines = [...uncheckedLines, ...checkedLines];
                for (final sortedLine in sortedLines) {
                  if (sortedLine == line) {
                    return currentOffset + relative;
                  }
                  currentOffset += sortedLine.length;
                }
              }
            }
            return selIndex;
          }

          final newBase = mapSelectionIndex(selection.baseOffset);
          final newExtent = mapSelectionIndex(selection.extentOffset);

          // Apply reordering change
          doc.compose(changeDelta, ChangeSource.local);

          // Update selection
          controller.updateSelection(
            TextSelection(baseOffset: newBase, extentOffset: newExtent),
            ChangeSource.local,
          );

          break;
        }

        i = endIndex + 1;
      } else {
        i++;
      }
    }
  }
}
