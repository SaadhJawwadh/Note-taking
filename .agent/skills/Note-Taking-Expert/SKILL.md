---
name: Note-Taking-Expert
description: Specialist in the Note-Taking module, handling Markdown editors, tagging systems, note grids (Masonry/Uniform), and bulk actions.
---

## Use this skill when
- Modifying `lib/screens/note_editor_screen.dart` or `lib/screens/home_screen.dart` (notes section).
- Updating `lib/data/note_model.dart` or note-related queries in `lib/data/database_helper.dart`.
- Implementing bulk actions (multi-select, batch archive/delete).
- Optimizing note grid performance (pagination, lazy loading).

## Relevant Files
- `lib/data/note_model.dart`
- `lib/screens/note_editor_screen.dart`
- `lib/screens/home_screen.dart` (Note-specific logic)
- `lib/data/database_helper.dart` (Note queries)
- `lib/utils/rich_text_utils.dart`

## Instructions
- **Database Schema**: Note tagging is now handled via the `note_tags` junction table (Version 13+). Always use indexed SQL joins for tag queries instead of JSON parsing.
- **UI Architecture**: Prefer high-performance **Masonry Grid** and **List** views. The Kanban view has been retired in favor of a more streamlined "Bundled Notes" inspired layout.
- **Styling**: Use soft, rounded corners (`BorderRadius.circular(24)`) and subtle `outlineVariant` borders (0.3 alpha) for note cards.
- **Animations**: Maintain the "Premium" look with `OpenContainer` transitions and snappy `FadeThrough` transitions for view switching.
- **Bulk Actions**: Utilize the refined selection mode (triggered by long-press) for batch tagging, archiving, or trashing.
