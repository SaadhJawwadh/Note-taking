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
* **Tag Blending**: Home cards must automatically match their background card colors to the colors of their primary tags.

## 3. UI, Feeds & Filters
* **View Modes**: Support switching between Masonry Grid, Uniform Grid, and List Views.
* **Transitions**: Use `OpenContainer` from the `animations` package for card-to-editor transitions.
* **Home Chip Exclusions**: Exclude special categories like `'Archived'` or `'Trash'` from the home screen tags filter row. These are handled on their own screens.
* **AI Tag Guardrails**: suggested tags from Gemini Nano must be strictly filtered against existing database tags. Discard any newly suggested/hallucinated tags that do not exist yet.
