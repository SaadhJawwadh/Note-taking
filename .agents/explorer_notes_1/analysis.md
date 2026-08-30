# Comprehensive Domain Audit & Architecture Blueprint: Notes Module

**Domain**: Notes & Rich Text Quill Editor (`lib/features/notes/`, `lib/data/note_model.dart`, `lib/providers/note_provider.dart`, `lib/utils/rich_text_utils.dart`, `lib/utils/quill_checklist_helper.dart`)  
**Auditor**: Notes Domain Specialist Explorer  
**Status**: Complete (Read-Only Audit)  
**Date**: 2026-08-30  

---

## 1. Executive Summary

A comprehensive architectural audit of the Notes domain was conducted across rich text delta processing, cursor boundaries, attribute scoping, auto-save timers, trash lifecycle, search/folders, and image embeds.

The Notes engine is functional and backed by SQLCipher encrypted storage, but the audit identified **7 critical architectural defects and reliability risks**:
1. **Delta Sanitization Stripping Legitimate Text Attributes**: In `NoteEditorScreen.initState`, operations with `contains('\n')` strip inline attributes (`bold`, `italic`, `strike`, `underline`) from the entire string (e.g. `'Heading Text\n'`), rather than properly splitting text from newline block endings.
2. **Inverted Selection Crashes (`RangeError`) in Image & Table Insertion**: `_pickImage` and `_showTableInsertionDialog` calculate replacement length as `extentOffset - baseOffset`. When a user selects text from right to left (`baseOffset > extentOffset`), `length` becomes negative, throwing an unhandled runtime `RangeError`.
3. **Stepper Flank Buttons Expand Selection Instead of Moving Cursor**: When the cursor is collapsed, tapping stepper flank buttons `[ ‹ ] [ › ] [ ▲ ] [ ▼ ]` updates `extentOffset` while leaving `baseOffset` static, accidentally converting single cursor navigation into an expanding highlight selection.
4. **P2P Sync Resurrection Bug in Trash Auto-Purge**: `NoteRepository.clearOldTrash()` deletes expired notes from `notes` and `note_tags` after $N$ days, but **fails to write tombstones into `deleted_notes`**. When syncing with peers that haven't purged yet, the remote peer resurrects the purged notes.
5. **Accidental Note Restoration on Trashed Note Opening**: Tapping a trashed note in `FilteredNotesScreen` opens `NoteEditorScreen(note: note)`. On auto-save, `saveNote()` instantiates a `Note` without passing `deletedAt` (defaulting to `null`), silently restoring the note to the active ledger without user intent.
6. **Paginated In-Memory Search Limitation**: `NoteProvider.setSearchQuery()` filters only the first 20 notes loaded in memory (`_notes`) via `_applySearchFilter()`, rather than executing SQLite queries via `NoteRepository.searchNotes()`, rendering notes beyond page 1 invisible to search.
7. **Unsandboxed Temporary Image Picker Paths**: `_pickImage` embeds raw temporary OS cache paths (`/cache/` or `tmp/`) directly into Quill Deltas. When the OS clears temporary cache files, note image embeds break permanently.

---

## 2. Scope-by-Scope Deep Audit & Observations

### Scope 1: Rich Text Quill Delta Sanitization, Normalization & JSON Serialization

#### Direct Observations
1. **Flawed Sanitization in `NoteEditorScreen.initState`** (`lib/features/notes/presentation/screens/note_editor_screen.dart`, lines 167–180):
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
   - **Root Cause**: If a single operation contains text followed by a newline (e.g. `{"insert": "Project Title\n", "attributes": {"bold": true, "header": 1}}`), `(op.data as String).contains('\n')` evaluates to `true`. The code removes `bold` from `cleanAttrs` and applies the stripped attributes to the entire `"Project Title\n"`, destroying the bold formatting on `"Project Title"`.
   - **Architectural Risk**: Legitimate formatted lines lose their inline styles upon note reloading. Furthermore, this sanitization is duplicated in `NoteEditorScreen` rather than encapsulated inside `RichTextUtils`.

2. **Un-trimmed Leading JSON Fallback** (`lib/utils/rich_text_utils.dart`, line 129):
   ```dart
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
   ```
   - **Observation**: If content has leading whitespace (e.g. `   [{"insert":...}]`), `content.startsWith('[')` returns `false`, causing the JSON to fall through to `markdownToDelta()`, corrupting the document.

3. **Checklist Preview Attribute Detection** (`lib/utils/rich_text_utils.dart`, lines 204–214):
   ```dart
   if (text == '\n') {
     final listAttr = op.attributes?['list'] as String?;
     if (listAttr == 'checked') {
       hasChecklistItems = true;
       hasCheckedItems = true;
       isChecked = true;
     } else if (listAttr == 'unchecked') {
       hasChecklistItems = true;
       line = '☐ $line';
     }
   }
   ```
   - **Observation**: If a delta op has `text == 'Todo item\n'`, `text == '\n'` is `false`. The checklist attribute is ignored, and the card preview fails to display checklist checkboxes (`☐`).

---

### Scope 2: Selection Clamping, Cursor Boundary Validation & Index Out-of-Bounds Guards

#### Direct Observations
1. **Negative Length RangeError in Dialogs & Embeds** (`lib/features/notes/presentation/screens/note_editor_screen.dart`, lines 952–955 and lines 1234–1242):
   ```dart
   // In _pickImage (line 952):
   final index = _quillController.selection.baseOffset;
   final length = _quillController.selection.extentOffset - index;
   _quillController.replaceText(index, length, BlockEmbed.image(pickedFile.path), null);

   // In _showTableInsertionDialog (line 1234):
   final index = _quillController.selection.baseOffset;
   final length = _quillController.selection.extentOffset - index;
   _quillController.replaceText(index, length, TableBlockEmbed(jsonStr), null);
   ```
   - **Root Cause**: In Flutter, selecting backwards (dragging right-to-left) sets `baseOffset > extentOffset`. `extentOffset - index` yields a negative number.
   - **Crash**: `_quillController.replaceText` throws an unhandled `ArgumentError` or `RangeError: Value should be >= 0`.

2. **Stepper Cursor Nudge Selection Expansion Bug** (`note_editor_screen.dart`, lines 472, 503, 525, 555):
   ```dart
   void _nudgeSelectionRight({bool byWord = false}) {
     ...
     _quillController.updateSelection(
       TextSelection(baseOffset: selection.baseOffset, extentOffset: newExtent),
       ChangeSource.local,
     );
   }
   ```
   - **Root Cause**: When the cursor is collapsed (`baseOffset == extentOffset`), updating only `extentOffset` creates an active text selection highlight between `baseOffset` and `newExtent`, instead of moving the cursor.
   - **Fix**: Check `if (selection.isCollapsed)` and call `TextSelection.collapsed(offset: newExtent)`.

3. **Synchronous Mutation During Document Listener** (`note_editor_screen.dart`, lines 254–278):
   ```dart
   void _checkCodeBlockAutoExit(Delta change) {
     ...
     _quillController.replaceText(pos - 1, 1, '', null);
   }
   ```
   - **Observation**: Invoked directly inside `_quillController.document.changes.listen` without `WidgetsBinding.instance.addPostFrameCallback`. Mutating the document during change dispatch can trigger re-entrant listener notifications and mid-render painting exceptions.

---

### Scope 3: Attribute Scope Invariants (Inline vs Block Boundary Isolation)

#### Direct Observations
1. **Quill Delta Attribute Architecture**:
   - Block attributes (`list: checked`, `list: unchecked`, `header: 1|2|3`, `blockquote: true`, `code-block: true`) must reside exclusively on line-terminating `\n` characters (length 1).
   - Inline attributes (`bold: true`, `italic: true`, `strike: true`, `underline: true`) must reside on text characters.
2. **Sanitization Normalization Protocol**:
   - Splitting mixed ops into text insertion + newline insertion:
     ```dart
     static Delta normalizeDelta(Delta delta) {
       final normalized = Delta();
       for (final op in delta.toList()) {
         if (op.isInsert && op.data is String) {
           final text = op.data as String;
           if (text.contains('\n') && text != '\n') {
             // Split text and newline
             final parts = text.split('\n');
             for (int i = 0; i < parts.length; i++) {
               if (parts[i].isNotEmpty) {
                 final inlineAttrs = _filterInlineAttributes(op.attributes);
                 normalized.insert(parts[i], inlineAttrs);
               }
               if (i < parts.length - 1) {
                 final blockAttrs = _filterBlockAttributes(op.attributes);
                 normalized.insert('\n', blockAttrs);
               }
             }
             continue;
           } else if (text == '\n') {
             final blockAttrs = _filterBlockAttributes(op.attributes);
             normalized.insert('\n', blockAttrs);
             continue;
           }
         }
         normalized.push(op);
       }
       return normalized;
     }
     ```

---

### Scope 4: Dirty State Management, Auto-Save Timers & Race Conditions

#### Direct Observations
1. **Decoupling Violation (`NoteEditorProvider` Bypassed)**:
   - `lib/features/notes/providers/note_editor_provider.dart` was created to encapsulate note editor state, dirty tracking, and auto-save timers.
   - However, `NoteEditorScreen` (`lib/features/notes/presentation/screens/note_editor_screen.dart`, 4855 lines) manages its own private timers (`_debounce`), dirty checks, and repository writes directly, completely bypassing `NoteEditorProvider`.
2. **Auto-Save Mutex & Re-entrancy Absence**:
   - `NoteEditorScreen.saveNote()` (line 998) does not maintain an `_isSaving` boolean guard.
   - Rapid typing + 2-second debounce + `PopScope` navigation invoking `await saveNote()` triggers concurrent save transactions on SQLite, risking race conditions on newly created drafts.
3. **P2P Sync Real-Time Notification Missing on Note Save**:
   - `NoteEditorScreen.saveNote()` does not call `P2pSyncProvider.activeInstance?.triggerEventSync()`. Local note saves fail to notify paired devices until manual sync is triggered.

---

### Scope 5: Trash Auto-Purge Lifecycle, Tombstone Sync & Accidental Restores

#### Direct Observations
1. **Tombstone Omission in `clearOldTrash`** (`lib/features/notes/data/note_repository.dart`, lines 336–354):
   ```dart
   Future<void> clearOldTrash([int days = 7]) async {
     if (days <= 0) return;
     final db = await _db;
     final cutoff = DateTime.now().subtract(Duration(days: days));
     await db.transaction((txn) async {
       final oldNotes = await txn.query(
         TableNames.notes,
         columns: [NoteFields.id],
         where: '${NoteFields.deletedAt} IS NOT NULL AND ${NoteFields.deletedAt} < ?',
         whereArgs: [cutoff.toIso8601String()],
       );
       for (final row in oldNotes) {
         final id = row[NoteFields.id] as String;
         await NotificationService.cancelNoteReminder(id);
         await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
         await txn.delete(TableNames.notes, where: '${NoteFields.id} = ?', whereArgs: [id]);
         // 🚨 MISSING: txn.insert('deleted_notes', {'id': id, 'deletedAt': now}, ...);
       }
     });
   }
   ```
   - **Critical Vulnerability**: In `sync_merge_service.dart`, `deleted_notes` is the authoritative tombstone table that prevents remote peers from resurrecting purged notes. Failing to write tombstones in `clearOldTrash()` allows paired peers to restore auto-purged notes during P2P sync.

2. **Accidental Note Restoration on Trashed Note Opening** (`note_editor_screen.dart`, lines 1049–1063):
   - When a trashed note is opened from `FilteredNotesScreen(filterType: FilterType.trash)`, `saveNote()` rebuilds `Note(...)` with `deletedAt: null` (omitted in constructor).
   - As soon as the 2-second debounce timer fires, SQLite writes `deletedAt = NULL`, unintentionally restoring the note to the active notes list.

---

### Scope 6: Folder Management, Tagging Hierarchy & Note Search

#### Direct Observations
1. **Paginated In-Memory Search Flaw in `NoteProvider`** (`lib/providers/note_provider.dart`, lines 178–189):
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
   - **Root Cause**: `_notes` contains only the current paginated batch (first 20 notes). Filtering in-memory ignores all notes beyond page 1 in SQLite.
   - **Fix**: When `_searchQuery.isNotEmpty`, `NoteProvider` must execute `_noteRepository.searchNotes(_searchQuery)` asynchronously to query all matching records across SQLite, and update `_filteredNotes` with full results.

2. **Ephemeral Empty Folders**:
   - Folders are derived dynamically from `notes.category`. Empty folders reside in `_emptyFolders = []` in memory. Restarting the app before adding notes to a newly created folder discards the folder.

---

### Scope 7: Image Embeds, Sandboxing, Downsampling & Memory Pressure

#### Direct Observations
1. **Unsandboxed Temporary Cache Image Paths** (`note_editor_screen.dart`, lines 946–964):
   ```dart
   Future<void> _pickImage(ImageSource source) async {
     final picker = ImagePicker();
     ...
     final pickedFile = await picker.pickImage(source: source);
     if (pickedFile != null) {
       ...
       _quillController.replaceText(index, length, BlockEmbed.image(pickedFile.path), null);
     }
   }
   ```
   - **Vulnerability**: `pickedFile.path` points to the OS temporary cache directory (`/data/user/0/.../cache/` or iOS `/tmp/`). When OS cache cleaner runs, embedded images become broken links.
   - **Resolution**: Copy picked files to persistent protected app storage (`(await getApplicationDocumentsDirectory()).path / 'note_images/'`) before embedding into Delta.

2. **Downsampling Conformance**:
   - `RoundedImageEmbedBuilder` properly specifies `cacheWidth: 1080` and `errorBuilder`.
   - `NoteCard` specifies `cacheWidth: 400` with fallback.
   - Memory footprint is compliant with Invariant 9, but requires sandboxed file isolation.

---

## 3. Work Packages & Implementation Blueprints

### Work Package A: Robust Delta Normalization & Sanitization Engine
**Target File**: `lib/utils/rich_text_utils.dart`

```dart
// Blueprint for RichTextUtils
class RichTextUtils {
  static const Set<String> _inlineAttributeKeys = {
    'bold', 'italic', 'strike', 'underline', 'color', 'background', 'font', 'size', 'link'
  };

  static const Set<String> _blockAttributeKeys = {
    'list', 'header', 'blockquote', 'code-block', 'align', 'direction', 'indent'
  };

  /// Normalizes and cleans Deltas so inline attributes never attach to newline characters,
  /// and block attributes never attach to text spans.
  static Delta sanitizeDelta(Delta delta) {
    final sanitized = Delta();
    for (final op in delta.toList()) {
      if (op.isInsert && op.data is String) {
        final text = op.data as String;
        if (text.contains('\n') && text != '\n') {
          final segments = text.split('\n');
          for (int i = 0; i < segments.length; i++) {
            if (segments[i].isNotEmpty) {
              final inlineAttrs = _filterAttributes(op.attributes, _inlineAttributeKeys);
              sanitized.insert(segments[i], inlineAttrs);
            }
            if (i < segments.length - 1) {
              final blockAttrs = _filterAttributes(op.attributes, _blockAttributeKeys);
              sanitized.insert('\n', blockAttrs);
            }
          }
          continue;
        } else if (text == '\n') {
          final blockAttrs = _filterAttributes(op.attributes, _blockAttributeKeys);
          sanitized.insert('\n', blockAttrs);
          continue;
        }
      }
      sanitized.push(op);
    }
    return sanitized;
  }

  static Map<String, dynamic>? _filterAttributes(Map<String, dynamic>? attrs, Set<String> allowedKeys) {
    if (attrs == null || attrs.isEmpty) return null;
    final filtered = <String, dynamic>{};
    for (final entry in attrs.entries) {
      if (allowedKeys.contains(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }
    return filtered.isEmpty ? null : filtered;
  }

  static Delta contentToDelta(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return Delta()..insert('\n');
    if (trimmed.startsWith('[')) {
      try {
        final ops = jsonDecode(trimmed) as List;
        return sanitizeDelta(Delta.fromJson(ops));
      } catch (_) {}
    }
    return sanitizeDelta(markdownToDelta(content));
  }
}
```

---

### Work Package B: Selection & Inverted Range Normalization
**Target File**: `lib/features/notes/presentation/screens/note_editor_screen.dart`

```dart
// Normalization Helper for all selection replacements
({int start, int length}) _getNormalizedSelectionRange() {
  final sel = _quillController.selection;
  if (!sel.isValid) return (start: 0, length: 0);
  final start = math.min(sel.baseOffset, sel.extentOffset);
  final end = math.max(sel.baseOffset, sel.extentOffset);
  return (start: start, length: end - start);
}

// Fixed Stepper Nudge:
void _nudgeSelectionRight({bool byWord = false}) {
  if (_isEditingTableCell) return;
  final selection = _quillController.selection;
  final docLen = _quillController.document.length;
  if (!selection.isValid || docLen <= 0) return;

  HapticFeedback.selectionClick();
  _focusNode.requestFocus();

  final currentExtent = selection.extentOffset;
  int newExtent;
  if (byWord) {
    final text = _quillController.document.toPlainText();
    int idx = currentExtent.clamp(0, text.length);
    while (idx < text.length && text[idx].trim().isNotEmpty) idx++;
    while (idx < text.length && text[idx].trim().isEmpty && text[idx] != '\n') idx++;
    newExtent = idx.clamp(0, docLen - 1);
  } else {
    newExtent = (currentExtent + 1).clamp(0, docLen - 1);
  }

  _quillController.updateSelection(
    selection.isCollapsed
        ? TextSelection.collapsed(offset: newExtent)
        : TextSelection(baseOffset: selection.baseOffset, extentOffset: newExtent),
    ChangeSource.local,
  );
}
```

---

### Work Package C: Trash Auto-Purge Tombstones & Accidental Restore Prevention
**Target Files**: `lib/features/notes/data/note_repository.dart`, `lib/features/notes/presentation/screens/note_editor_screen.dart`

1. **Write Tombstones in `clearOldTrash`**:
   ```dart
   Future<void> clearOldTrash([int days = 7]) async {
     if (days <= 0) return;
     final db = await _db;
     final cutoff = DateTime.now().subtract(Duration(days: days));
     final now = DateTime.now().toIso8601String();
     await db.transaction((txn) async {
       final oldNotes = await txn.query(
         TableNames.notes,
         columns: [NoteFields.id],
         where: '${NoteFields.deletedAt} IS NOT NULL AND ${NoteFields.deletedAt} < ?',
         whereArgs: [cutoff.toIso8601String()],
       );
       for (final row in oldNotes) {
         final id = row[NoteFields.id] as String;
         await NotificationService.cancelNoteReminder(id);
         await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
         await txn.insert('deleted_notes', {'id': id, 'deletedAt': now}, conflictAlgorithm: ConflictAlgorithm.replace);
         await txn.delete(TableNames.notes, where: '${NoteFields.id} = ?', whereArgs: [id]);
       }
     });
   }
   ```

2. **Preserve `deletedAt` in `saveNote`**:
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
     deletedAt: widget.note?.deletedAt, // Preserve trash state!
   );
   ```

---

### Work Package D: Database-Backed Global Note Search in `NoteProvider`
**Target File**: `lib/providers/note_provider.dart`

```dart
void setSearchQuery(String query) {
  _searchQuery = query.trim().toLowerCase();
  if (_searchQuery.isEmpty) {
    _applySearchFilter();
    notifyListeners();
  } else {
    _performDatabaseSearch(_searchQuery);
  }
}

Future<void> _performDatabaseSearch(String query) async {
  try {
    final searchResults = await _noteRepository.searchNotes(query);
    _filteredNotes = searchResults;
    notifyListeners();
  } catch (e) {
    debugPrint('Error searching notes in DB: $e');
  }
}
```

---

### Work Package E: Sandboxed Image Embedding Pipeline
**Target File**: `lib/features/notes/presentation/screens/note_editor_screen.dart`

```dart
Future<void> _pickImage(ImageSource source) async {
  final picker = ImagePicker();
  try {
    AppLockScreen.ignoreNextResumeLock();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/note_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final fileName = '${const Uuid().v4()}_${path.basename(pickedFile.path)}';
      final permanentPath = '${imagesDir.path}/$fileName';
      await File(pickedFile.path).copy(permanentPath);

      final range = _getNormalizedSelectionRange();
      _quillController.replaceText(
        range.start,
        range.length,
        BlockEmbed.image(permanentPath),
        null,
      );
      if (mounted) Navigator.pop(context);
    }
  } catch (e) {
    debugPrint('Error picking image: $e');
    if (mounted) Navigator.pop(context);
  }
}
```

---

## 4. Verification & Testing Matrix

| Component | Target Verification Test | Expected Outcome |
|---|---|---|
| **Delta Normalization** | Unit test with mixed `{'bold': true, 'header': 1}` ops | Text keeps bold; newline keeps header attribute. |
| **Inverted Selection** | Test inserting table/image with `baseOffset: 10, extentOffset: 2` | Range normalized to `2..10`, zero crashes. |
| **Stepper Cursor** | Stepper tap with collapsed selection at index 5 | Extent and base both move to 6, selection stays collapsed. |
| **Trash Auto-Purge** | Verify `deleted_notes` rows after `clearOldTrash(7)` | Purged note ID inserted into `deleted_notes`. |
| **Trashed Note Edit** | Open trashed note, trigger `saveNote()` | `deletedAt` timestamp remains non-null. |
| **Database Note Search** | Search for note on page 3 (index > 20) | Note is retrieved and shown in `filteredNotes`. |
| **Image Sandboxing** | Pick image, delete original temp cache file | Note reloads and renders image cleanly from `note_images/`. |
