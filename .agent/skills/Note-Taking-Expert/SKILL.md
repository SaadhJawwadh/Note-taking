---
name: Note-Taking-Expert
description: Specialist in the Note-Taking module, handling Markdown/Delta editors, tag matching, note layouts (Masonry/List), and note lifecycle operations.
---

# Note-Taking Expert

Refer to [design.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/UI-UX-Specialist/design.md#a-note-taking-engine) for complete M3 Expressive UI components, editor formatting toolbars, FAB menu specifications, and design tokens for notes.

## Core Module Operational Rules
* **Data Format & Schema**: Notes store lossless Quill Delta JSON. `dateModified` updates ONLY on text edit save. Soft-deleted notes auto-purge after 7 days via `clearOldTrash()`.
* **Editor State & Persistence**: `saveNote()` checks `hasChanges` comparison. Reminders use `NotificationService.scheduleNoteReminder` (id `0x4E000000 | noteId.hashCode`).
* **Locked Notes & Folders**: Auth gate lives inside `NoteEditorScreen.build`. Folder filtering uses `readAllNotes(folder:)`. Folder counts query un-paginated DB totals (`SELECT category, COUNT(*)`).
* **M3 Expressive UI Components**: Note creation uses the **FAB Menu** pattern; editor toolbar uses a detached glassmorphic toolbar (`surfaceContainerHighest` fill + `0.85` opacity + `12px` blur); note cards use `surfaceContainerLow` with dynamic corner morphing (`radiusL` to `radiusXL`).
* **Share-Into-Notes Pipeline**: `receive_sharing_intent` (pinned to `1.7.0`). Cold-start shares routed via `AppLockScreen.pendingSharedMedia`. Shared images copied to `shared_images/` before embedding.
