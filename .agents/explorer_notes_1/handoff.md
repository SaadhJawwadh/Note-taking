# Handoff Report: Notes Domain In-Depth Audit

**Sender**: Notes Domain Specialist Explorer (`explorer_notes_1`)  
**Recipient**: Lead Orchestrator (`parent`)  
**Date**: 2026-08-30  
**Status**: Task Complete (Hard Handoff)  

---

## 1. Observation

### Observation 1: Destructive Delta Sanitization in `NoteEditorScreen.initState`
- **File**: `/Users/saadhjawwadh/Documents/Code/Note taking/lib/features/notes/presentation/screens/note_editor_screen.dart` (lines 167–180)
- **Direct Code**:
  ```dart
  final sanitizedOps = <Operation>[];
  for (final op in delta.toList()) {
    if (op.data is String && (op.data as String).contains('\n') && op.attributes != null) {
      final cleanAttrs = Map<String, dynamic>.from(op.attributes!);
      cleanAttrs.remove('strike');
      cleanAttrs.remove('bold');
      cleanAttrs.remove('italic');
      cleanAttrs.remove('underline');
      sanitizedOps.add(Operation.insert(op.data, cleanAttrs.isEmpty ? null : cleanAttrs));
    } else {
      sanitizedOps.add(op);
    }
  }
  delta = Delta.fromOperations(sanitizedOps);
  ```
- **Impact**: Any operation containing text and a newline (e.g. `{"insert": "Title\n", "attributes": {"bold": true}}`) has its inline attributes stripped entirely from the text, destroying formatting on reload.

### Observation 2: Inverted Selection `RangeError` in Dialogs and Image Pickers
- **File**: `note_editor_screen.dart` (lines 952–955 and lines 1234–1242)
- **Direct Code**:
  ```dart
  // Line 952 (_pickImage):
  final index = _quillController.selection.baseOffset;
  final length = _quillController.selection.extentOffset - index;
  _quillController.replaceText(index, length, BlockEmbed.image(pickedFile.path), null);

  // Line 1234 (_showTableInsertionDialog):
  final index = _quillController.selection.baseOffset;
  final length = _quillController.selection.extentOffset - index;
  _quillController.replaceText(index, length, TableBlockEmbed(jsonStr), null);
  ```
- **Impact**: Dragging selection right-to-left sets `baseOffset > extentOffset`, causing `length` to be negative and triggering runtime exceptions in `replaceText`.

### Observation 3: Stepper Flank Navigation Accidental Selection Expansion
- **File**: `note_editor_screen.dart` (lines 472–475, 503–506, 525–528, 554–557)
- **Direct Code**:
  ```dart
  _quillController.updateSelection(
    TextSelection(baseOffset: selection.baseOffset, extentOffset: newExtent),
    ChangeSource.local,
  );
  ```
- **Impact**: When `selection.isCollapsed` is true, keeping `baseOffset` static while updating `extentOffset` converts single cursor navigation into an expanding highlight selection range.

### Observation 4: Missing Tombstones in `clearOldTrash()` Causing P2P Resurrection
- **File**: `/Users/saadhjawwadh/Documents/Code/Note taking/lib/features/notes/data/note_repository.dart` (lines 336–354)
- **Direct Code**:
  ```dart
  for (final row in oldNotes) {
    final id = row[NoteFields.id] as String;
    await NotificationService.cancelNoteReminder(id);
    await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
    await txn.delete(TableNames.notes, where: '${NoteFields.id} = ?', whereArgs: [id]);
    // Note: No insertion into deleted_notes tombstone table!
  }
  ```
- **Impact**: `SyncMergeService` relies on `deleted_notes` to prevent remote peers from sending purged notes back. Failing to record tombstones causes remote peers to resurrect auto-purged notes during P2P sync.

### Observation 5: Accidental Un-Trashing on Opening Trashed Notes
- **File**: `note_editor_screen.dart` (lines 1049–1063)
- **Direct Code**:
  ```dart
  final note = Note(
    id: _noteId,
    title: title,
    content: content,
    dateCreated: _dateCreated,
    dateModified: DateTime.now(),
    isPinned: isPinned,
    isArchived: isArchived,
    color: color,
    imagePath: widget.note?.imagePath,
    category: _folder,
    tags: tags,
    reminderAt: _reminderAt,
    isLocked: _isNoteLocked,
    // deletedAt is omitted, defaulting to null
  );
  ```
- **Impact**: Opening a note in `FilteredNotesScreen(filterType: FilterType.trash)` and allowing the 2s auto-save timer to run overwrites `deletedAt` with `null`, silently restoring the note to the active feed.

### Observation 6: In-Memory Search Ignoring Notes Beyond Page 1
- **File**: `/Users/saadhjawwadh/Documents/Code/Note taking/lib/providers/note_provider.dart` (lines 178–189)
- **Direct Code**:
  ```dart
  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredNotes = List.from(_notes);
    } else {
      _filteredNotes = _notes.where((note) {
        final titleMatch = note.title.toLowerCase().contains(_searchQuery);
        final contentMatch = note.content.toLowerCase().contains(_searchQuery);
        final tagMatch = note.tags.any((t) => t.toLowerCase().contains(_searchQuery));
        return titleMatch || contentMatch || tagMatch;
      }).toList();
    }
  }
  ```
- **Impact**: `_notes` only contains the paginated in-memory page (first 20 notes). Notes on pages 2+ in SQLite are never matched.

### Observation 7: Unsandboxed Temporary Image Picker Cache Paths
- **File**: `note_editor_screen.dart` (lines 946–964)
- **Direct Code**:
  ```dart
  final pickedFile = await picker.pickImage(source: source);
  if (pickedFile != null) {
    ...
    _quillController.replaceText(index, length, BlockEmbed.image(pickedFile.path), null);
  }
  ```
- **Impact**: `pickedFile.path` points to temporary OS cache storage. Clearing cache destroys embedded images in notes.

---

## 2. Logic Chain

1. **From Observation 1**: Delta operations created by Quill often contain text with a trailing newline (e.g. `"Heading\n"`). Checking `op.data.contains('\n')` and removing inline attributes without splitting `text` from `\n` strips inline attributes from the text portion $\to$ **Root Cause of lost bold/italic formatting on reload**.
2. **From Observation 2**: User gestures on touch screens often select backwards. Because `extentOffset < baseOffset`, subtraction produces negative length $\to$ `replaceText` requires non-negative length $\to$ **Unhandled `RangeError` during table and image insertions**.
3. **From Observation 3**: Split-axis flank buttons are designed for single-character or line cursor movements. When selection is collapsed, setting `baseOffset: selection.baseOffset` and `extentOffset: newExtent` creates a non-collapsed selection span $\to$ **Cursor navigation accidentally highlights text**.
4. **From Observation 4**: In a multi-device P2P network, deletion is propagated via tombstones. When `clearOldTrash()` deletes rows without writing to `deleted_notes`, paired devices still have the note record $\to$ during sync, `SyncMergeService` sees the remote record with no corresponding tombstone $\to$ **Remote peer re-inserts the note into local database**.
5. **From Observation 5**: Trashed notes are viewed in `NoteEditorScreen`. When auto-save triggers, `saveNote()` writes `deletedAt: null` $\to$ **Viewing a trashed note silently restores it**.
6. **From Observation 6**: `NoteProvider` limits in-memory `_notes` to 20 items for fast rendering. Searching against `_notes` instead of executing `NoteRepository.searchNotes()` filters only the loaded subset $\to$ **Search fails on older notes**.
7. **From Observation 7**: `ImagePicker` writes to transient OS cache. Without copying files to `note_images/` in app document storage $\to$ **Images become broken links upon OS cache clearance**.

---

## 3. Caveats

- **No Caveats**. Full codebase audit of `lib/features/notes/`, `lib/data/note_model.dart`, `lib/providers/note_provider.dart`, `lib/utils/rich_text_utils.dart`, `lib/utils/quill_checklist_helper.dart`, and all related tests was executed.

---

## 4. Conclusion

The Notes module has high architectural fidelity with SQLCipher and Material 3 design tokens, but requires **5 focused, zero-conflict work packages**:
1. **Work Package A**: Implement `RichTextUtils.sanitizeDelta()` to properly isolate inline attributes to text and block attributes to `\n`, trimming JSON input.
2. **Work Package B**: Implement `_getNormalizedSelectionRange()` and fix stepper cursor collapsed state updates in `NoteEditorScreen`.
3. **Work Package C**: Add tombstone writes (`deleted_notes`) in `NoteRepository.clearOldTrash()` and preserve `deletedAt` in `NoteEditorScreen.saveNote()`.
4. **Work Package D**: Wire `NoteProvider.setSearchQuery()` to `NoteRepository.searchNotes()` for global SQLite-backed search.
5. **Work Package E**: Copy picked images to `getApplicationDocumentsDirectory() / 'note_images/'` before embedding.

---

## 5. Verification Method

### Test Commands
```bash
# Run existing test suite
flutter test

# Run notes-specific test suite
flutter test test/note_repository_test.dart test/find_in_note_test.dart test/quill_checklist_helper_test.dart test/table_embed_test.dart test/folder_and_settings_search_test.dart
```

### Invalidation Conditions
- Any proposed change that causes existing tests to fail or introduces non-zero `flutter analyze` diagnostics.
- Any change that alters the Delta JSON storage format in SQLite in a backward-incompatible way.
