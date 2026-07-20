---
name: Note-Taking-Expert
description: Specialist in the Note-Taking module, handling Markdown/Delta editors, tag matching, note layouts (Masonry/List), and note lifecycle operations.
---

# Note-Taking Expert

Use this skill when modifying the note editor, home screen note feeds, note tagging, trash collection, or formats.

## 1. Notes Data & Sorting
* **Edit-Only Sorting**: Opening or viewing a note must **never** update its modified timestamp or bring it to the top of the feed. The `dateModified` timestamp must only update when actual text edits are saved.
* **Database Schema**: Note tagging uses the `note_tags` junction table. Use SQL joins for queries.
* **Auto-Trash Purge**: Soft-deleted notes (where `deletedAt` is populated) must be transactionally deleted after 7 days via `clearOldTrash()`.

## 2. Note cards & Previews
* **Rich Preview Generation**: When saving a note, generate a plain text `previewText` (up to 6 lines) from the quill delta:
  * For checklists, prepend unchecked boxes with `☐ ` and checked boxes with `☑ `.
  * Save the preview text directly to the database to avoid runtime parsing during feed rendering.
  * For tables, format the preview text by extracting the first two rows and joining columns with ` | ` (Option A format), rather than displaying raw markdown or simple placeholders.
* **Tag Blending**: Home cards must automatically match their background card colors to the colors of their primary tags.

## 3. UI, Feeds & Filters
* **View Modes**: Support switching between Masonry Grid, Uniform Grid, and List Views.
* **Transitions**: Use `OpenContainer` from the `animations` package for card-to-editor transitions.
* **Home Chip Exclusions**: Exclude special categories like `'Archived'` or `'Trash'` from the home screen tags filter row. These are handled on their own screens.
* **AI Tag Guardrails**: suggested tags from Gemini Nano must be strictly filtered against existing database tags. Discard any newly suggested/hallucinated tags that do not exist yet.

## 4. Editor State & Persistence (v2.0 learnings)
* **Content format**: Notes store lossless **Quill Delta JSON** (legacy Markdown parsed as fallback via `RichTextUtils.contentToDelta`). Inline image embeds (`{'insert': {'image': path}}`) survive round-trips; templates (`lib/data/note_templates.dart`) are hand-built Delta JSON.
* **hasChanges gate**: `saveNote()` skips writing when nothing changed vs the initial note. EVERY new editor-state field (reminderAt, isLocked, folder/category, ...) MUST be added to the `hasChanges` comparison, or its edits silently never save.
* **Reminders**: `NoteFields.reminderAt` + `NotificationService.scheduleNoteReminder` (id = `0x4E000000 | noteId.hashCode & 0xFFFFFF`). NEVER call `_notificationsPlugin.cancelAll()` — period rescheduling once wiped note reminders; cancel specific ids. Repository delete paths cancel reminders centrally (`softDeleteNote`/`bulkDelete`).
* **Locked notes**: `NoteFields.isLocked`; the auth gate lives INSIDE `NoteEditorScreen.build` (single choke point covering OpenContainer, search, archive entries); cards mask preview/image when locked.
* **Folders**: `NoteFields.category` doubles as the folder ('All Notes' = none). Filter via `readAllNotes(folder:)`; distinct list via `getAllFolders()`.
* **Quill 11 built-ins**: markdown-as-you-type = `QuillEditorConfig(characterShortcutEvents: standardCharactersShortcutEvents, spaceShortcutEvents: standardSpaceShorcutEvents)` (note the package's 'Shorcut' typo). `[]`→checklist needs a custom `SpaceShortcutEvent` replicating the internal key-phrase dance (the helper/enum aren't exported). Find-in-note = `QuillToolbarSearchButton`.
* **Undo pattern**: every trash path offers a snackbar Undo (`restoreNote`); post-pop editor deletes use `appScaffoldMessengerKey`.
* **Folder Note Counting**: The home feed utilizes lazy pagination (e.g., loading 20 notes at a time). Never rely on list length (e.g., `filteredNotes.length`) to display folder note counts in app bars. Always retrieve un-paginated count groupings directly from the database using queries like `SELECT category, COUNT(*)` and cache them in the provider on load.
* **Auto-Inherit Folder Context**: When triggering a new note or template bottom sheet from a specific folder view, forward the active folder (`noteProvider.selectedFolder`) to the note creator as the initial category so notes are automatically assigned to the active workspace folder.
* **Snackbars Clearing & Duration**: When displaying snackbar alerts for user actions (like trashing a note with an "Undo" action), always call `ScaffoldMessenger.of(context).clearSnackbars()` beforehand to clear the queue and set a snappy, user-friendly duration (e.g. 3 seconds) to prevent visual crowding.
* **Interactive Embed Cursors & Focus**: When embedding custom interactive blocks (like tables) containing internal text fields inside a scrollable `QuillEditor`, isolate cursors and handle focus dismissals cleanly:
  * Notify the parent editor to toggle `showCursor = false` when an internal cell is focused, preventing duplicate blinking cursors.
  * Wrap the embed widget in a `TapRegion` to capture clicks outside the block and clear cell focus.


## 5. Share-Into-Notes Pipeline
* `receive_sharing_intent` is PINNED to 1.7.0 (1.8+ is Swift-Package-Manager-only and fails `flutter pub get` when Xcode is incomplete). Text/URLs arrive as `SharedMediaFile.path` with type `text`/`url`.
* **Single source for cold-start shares**: only `AppLockScreen` calls `getInitialMedia()` (it is always mounted); it parks media in `AppLockScreen.pendingSharedMedia` and bumps `sharedMediaTick`. HomeScreen consumes the pending list and handles warm stream events itself when unlocked. Park by ASSIGNMENT (not append) so double-delivery collapses.
* Copy shared images out of the share cache into documents/`shared_images/` before embedding — cache files get purged.
* `PROCESS_TEXT` (text-selection menu) flows through MainActivity `pendingSharedText` + the widget channel's `getPendingSharedText`.


## 6. Slash Commands, Floating Toolbar & Note Stats (v2.3)
* **Slash Commands (`/`) Overlay**: Detect typing `/` at line start to trigger a floating Slash Command card above the keyboard. Filter commands in real time (`/todo`, `/table`, `/code`, `/h1`, `/quote`). Tapping a command automatically strips the typed query text and applies block formatting.
* **Typing Debouncing for Overlay Suggestions**: When displaying overlay suggestions (like tags or slash commands) in the note editor, debounce menu triggers until typing pauses (e.g., 500ms delay) to prevent distracting cursor movement while actively typing.
* **Floating Glassmorphic Formatting Bar**: Format toolbar uses backdrop blur (`BackdropFilter`), 90% opacity surface fill, rounded corners (`AppLayout.radiusXL`), and a soft elevation shadow, detached from screen edges.
* **Note Details & Export**: Note details bottom sheet calculates reading time ($\approx 200 \text{ wpm}$), word count, character count, and dates. Share notes in Plain Text, Markdown, or copy to clipboard.
