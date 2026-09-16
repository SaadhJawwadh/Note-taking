# Notes Module & Home Presentation M3 Expressive Audit Report

**Date**: 2026-09-16  
**Auditor**: Notes Module Explorer (`explorer_notes_3`)  
**Scope**: `lib/features/notes/`, `lib/screens/home_screen.dart`, `lib/widgets/home/`, `lib/widgets/editor/`, `lib/widgets/tag_filter_bar.dart`, and associated providers/services.  
**Mode**: Read-Only Non-Destructive Inspection (`git status` 100% pristine).

---

## 1. Executive Summary & Compliance Score

A rigorous, end-to-end audit was conducted across all 21 presentation and domain files in the Notes module and root container screens. The module was evaluated against Google's Material 3 Expressive guidelines, single-source-of-truth design tokens (`AppLayout`, `AppTheme`), and the core system invariants codified in `AGENTS.md`.

### Overall Compliance Score: **88%**

| Evaluation Dimension | Weight | Score | Status | Key Highlights |
|---|---|---|---|---|
| **1. Surface Elevation Hierarchy & Zero Blurs** | 20% | **94%** | Highly Compliant | 0 occurrences of `BackdropFilter` or `ImageFilter.blur` in entire module; pure solid M3 surface containers (`surfaceContainerLow` / `surfaceContainer`) used across headers and cards. Minor deviation in `NoteCard` default surface. |
| **2. Shape Scale Hierarchy** | 20% | **88%** | Mostly Compliant | Stadium pills (`radiusStadium` / `radiusMAX`) used for tags, chips, and search capsules; 16dp squircles for note cards. Deviations found in legacy 20dp/24dp modal sheets and raw `AlertDialog` shapes. |
| **3. Motion, Physics & FAB Clearance** | 15% | **84%** | Minor Deviations | `AppMorphingFab` reactively expands/collapses with spring animation on scroll. Critical deviation: `NoteViewBuilder` hardcodes bottom padding to `88` instead of `AppLayout.fabBottomPadding = 96.0`. |
| **4. Touch Targets & Accessibility** | 15% | **82%** | Moderate Deviations | Top action bar enforces 40x40 compact constraints with 48x48 hitboxes. Color swatches in `home_screen.dart` tag editor measure only 32x32dp without 48dp wrappers. Several editor buttons lack explicit constraints. |
| **5. Top App Bar Invariants** | 15% | **95%** | Highly Compliant | Canonical 4-slot muscle memory sequence (`[ 🔍 Search ]`, `[ 🔄 Sync ]`, `[ ⋮ Tools ]`, `[ ⚙️ Settings ]`); left header `Notes` + interactive Tonal Scope Pill `[ 📁 Folder • Count ▾ ]`; 16dp outer edge symmetry; full-width search transformation. |
| **6. Note Invariants & Engine Stability** | 15% | **87%** | Architectural Debt | Perfect Quill Delta attribute separation, strict selection clamping, and Google Keep Takeout bookmark extraction. Architectural debt: `NoteEditorProvider` and `VoiceDictationPill` are orphaned/unused; 7-day trash purge default conflicts with 30-day setting default; lack of 0ms optimistic UI in `NoteProvider`. |

---

## 2. Granular Dimension Assessment

### Dimension 1: Surface Elevation Hierarchy (5-Tier Solid Surfaces & Zero Blurs)
* **Status**: **Pass / Highly Compliant (94%)**
* **Findings**:
  - **Zero Frosted Glass Contamination**: Grep search across the entire project confirms `0` instances of `BackdropFilter` or `ImageFilter.blur`.
  - **Top App Bar**: `HomeAppBar` (`lib/widgets/home/home_app_bar.dart:101`) uses pure solid `surfaceContainerLow` with `border: null` and subtle tonal elevation.
  - **Cards & Containers**: `AppCard` (`lib/core/ui/app_card.dart:82-86`) dynamically assigns solid `surfaceContainerHigh` or `surfaceContainer`.
  - **Deviations**:
    - In `lib/screens/home_screen.dart:1087`: `NoteCard` falls back to `theme.colorScheme.surface` for uncolored notes instead of `theme.colorScheme.surfaceContainer` / `surfaceContainerLow`.
    - In `lib/features/notes/presentation/screens/note_editor_screen.dart:2686`: Editor uses `backgroundColor` directly without grounding on solid 5-tier surface containers.

### Dimension 2: Shape Scale Hierarchy
* **Status**: **Mostly Compliant (88%)**
* **Findings**:
  - **Stadium Pills (1000dp / `StadiumBorder`)**:
    - Tag chips in `TagFilterBar` and `AppChip` use `AppLayout.radiusStadium`.
    - Note tag pills in `NoteCard` (`home_screen.dart:1209`) use `AppLayout.radiusStadium`.
    - Top bar Folder Scope Pill (`home_app_bar.dart:468`) uses `AppLayout.radiusStadium`.
    - Top bar search bar (`home_app_bar.dart:127`) uses `AppLayout.radiusMAX`.
    - Dictation status pill (`voice_dictation_pill.dart:32`) uses `AppLayout.radiusMAX`.
  - **Squircles (12–16dp Cards, 28dp Sheets/Dialogs)**:
    - `NoteCard` uses `AppLayout.radiusL` (16dp).
    - `NoteMigrationSheet` uses `AppBottomSheet` (28dp).
    - `NoteColorPickerSheet` uses `AppBottomSheet` (28dp).
    - `EditorNoteDetailsSheet` (`editor_note_details_sheet.dart:34`) uses `Radius.circular(28)`.
    - `EditorTableDialog` (`editor_table_dialog.dart:53`) uses `AppLayout.radiusXXL` (28dp).
  - **Deviations**:
    - `HomeAppBar._showFolderPicker` (`home_app_bar.dart:315`): Uses `showModalBottomSheet` with `Radius.circular(20)` instead of `AppBottomSheet` or 28dp (`AppLayout.radiusXXL`).
    - `NoteEditorScreen._showImageOptions` (`note_editor_screen.dart:1011`): Uses `Radius.circular(20)`.
    - `NoteEditorScreen._showAiOptionsSheet` (`note_editor_screen.dart:1829`): Uses `Radius.circular(24)`.
    - `NoteEditorScreen` image options (`note_editor_screen.dart:4436`): Uses `Radius.circular(20)`.
    - `HomeScreen` folder/tag dialogs (`home_screen.dart:463, 490, 554`): Raw `AlertDialog` without `AppDialog` or 28dp shape styling.
    - `EditorTableDialog` (`editor_table_dialog.dart:150`): Counter box uses hardcoded `BorderRadius.circular(8)` instead of `AppLayout.radiusS`.

### Dimension 3: Motion, Physics & FAB Bottom Clearance
* **Status**: **Minor Deviations (84%)**
* **Findings**:
  - **Universal Morphing FAB**: `HomeScreen` implements `AppMorphingFab` (`home_screen.dart:991`), dynamically responding to `UserScrollNotification` to collapse into a 56x56dp circular FAB on downward fling and expand on upward scroll.
  - **Spring Micro-interactions**: `NoteCard` wrapped in `BouncingWidget` with `HapticFeedback.lightImpact()`.
  - **OpenContainer Transitions**: `NoteViewBuilder` (`note_view_builder.dart:220`) implements `OpenContainer` with `ContainerTransitionType.fadeThrough` for seamless elevation-free note expansion.
  - **Deviations**:
    - **FAB Bottom Clearance**: In `lib/widgets/home/note_view_builder.dart:97`:
      ```dart
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 88),
      ```
      Hardcodes bottom padding to `88` instead of the invariant standard `AppLayout.fabBottomPadding = 96.0`.
    - `FilteredNotesScreen` (`filtered_notes_screen.dart:251`): Sliver list uses `padding: const EdgeInsets.all(16.0)` with only 16dp bottom padding.

### Dimension 4: Touch Targets & Accessibility ($\ge 48\times 48\text{dp}$)
* **Status**: **Moderate Deviations (82%)**
* **Findings**:
  - `HomeAppBar`: All 4 action buttons declare `constraints: const BoxConstraints(minWidth: 40, minHeight: 40)`, `visualDensity: VisualDensity.compact`, and `padding: EdgeInsets.zero`.
  - `NoteColorPickerSheet`: Color presets enforce `width: 48, height: 48` hit bounds.
  - `ManageTagsScreen`: Tag color presets enforce `SizedBox(width: 48, height: 48)`.
  - `HomeAppBar` scope pill provides explicit `Semantics(button: true, label: 'Folder: ...')`.
  - `NoteSearchReplaceBar`: Stepper buttons enforce `constraints: const BoxConstraints(minWidth: 48, minHeight: 48)`.
  - **Deviations**:
    - `home_screen.dart:514-515`: `_editTag` dialog renders color swatches as `Container(width: 32, height: 32)` wrapped in `GestureDetector` without 48x48 bounds.
    - `note_editor_screen.dart:2835-2881`: Top bar `IconButton`s (Back, Tags, History Undo/Redo) lack explicit 40x40 min constraints.
    - `note_editor_screen.dart:3620, 3638, 4093, 4109`: Floating toolbar directional stepper icons are sized `32x36dp` without 48dp gesture padding.
    - `manage_tags_screen.dart:253-268`: List item trailing Edit/Delete buttons lack compact constraints.

### Dimension 5: Top App Bar Invariants
* **Status**: **Pass / Highly Compliant (95%)**
* **Findings**:
  - **Left Header Structure**: `Notes` (bold 18pt) paired with interactive Tonal Scope Pill `[ 📁 Folder • Count ▾ ]`.
  - **Scope Pill Contrast Standard**: Styled with `colorScheme.primaryContainer.withValues(alpha: isDark ? 0.35 : 0.45)`, `1.0px` primary outline border (`colorScheme.primary.withValues(alpha: 0.28)`), `Icons.folder_outlined`, and `Icons.keyboard_arrow_down_rounded`.
  - **Action Hierarchy**:
    1. `[ 🔍 Search ]` (transforms header into full-width search mode)
    2. `[ 🔄 Sync ]` (conditionally visible when P2P devices are paired; tap = quick sync, long press = P2P hub)
    3. `[ ⋮ Notes Tools ]` (consolidates view mode, sort options, manage folders, manage tags, import notes, archived, trash)
    4. `[ ⚙️ Settings ]` (universal terminal anchor)
  - **16dp Edge Symmetry**: Left and right margins strictly enforce 16dp with zero inner spacers (`home_app_bar.dart:96-97`).
  - **Sub-Pixel Headroom**: `toolbarHeight: statusBarHeight + 72.0` with inner container `height: 60` (`home_app_bar.dart:81, 107`).
  - **Deviations**:
    - Top bar search mode back button and clear button (`home_app_bar.dart:198, 245`) lack explicit 40x40 min constraints.

### Dimension 6: Note Domain Invariants & Engine Health
* **Status**: **Mostly Compliant / High Architectural Debt (87%)**
* **Findings**:
  - **Rich Text Delta Sanitization**: `RichTextUtils.sanitizeDelta()` cleanly separates inline attributes (`bold`, `italic`, `strikeThrough`, `underline`) from line block attributes (`header`, `list`, `blockquote`, `code-block`, `align`, `indent`). Properly formats inline styling on text characters and block styling on trailing newlines (`\n`).
  - **Selection Clamping**: Clamped across cursor operations, word-boundary regex jumps, and line navigation (`clamp(0, docLen - 1)`).
  - **Consecutive Checklist Isolation**: `QuillChecklistHelper.extractAndRemoveCheckedLines()` isolates consecutive checked blocks without leaving orphan empty checkboxes.
  - **Google Takeout / Keep Invariants**:
    - Path filtering handles `Takeout/Keep/` ZIP entries correctly (`baseName != 'takeout.json'`).
    - Web bookmark links, titles, and descriptions are extracted from `data['annotations']`.
    - Companion images extracted and copied to sandboxed storage.
    - Preserves `isArchived = 1`.
  - **Hardware-Aware AI Gating**: Gemini AI Assist in `note_editor_screen.dart:4159` is strictly gated on `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`).
  - **Soft-Delete Undo Parity**: All deletion undo handlers call `restoreNote(id)` (`UPDATE notes SET deletedAt = NULL`) preventing primary key collisions.
  - **Deviations & Architectural Debt**:
    - **Trash Auto-Purge Lifecycle Discrepancy**:
      - `NoteRepository.clearOldTrash([int days = 7])`: Defaults to 7 days.
      - `SettingsProvider._trashAutoPurgeDays`: Defaults to 30 days (`settings_provider.dart:141, 257`).
      - `NoteProvider.refreshNotes()`: Reads `prefs.getInt('trashAutoPurgeDays') ?? 30` (`note_provider.dart:126`).
      - Invariant 1 and R1 require a strict 7-day auto-purge lifecycle for notes.
    - **Trash Hero Banner Opacity Discrepancy**:
      - `FilteredNotesScreen` (`filtered_notes_screen.dart:171-174`):
        Light mode fill: `0.35` (should be 50%–55%, `0.50–0.55`).
        Dark mode fill: `0.16` (should be 20%–22%, `0.20–0.22`).
        Border width: `1.0` (should be `1.2px`).
    - **Orphaned `NoteEditorProvider`**:
      - `NoteEditorProvider` (`lib/features/notes/providers/note_editor_provider.dart`) was created for decoupled dirty tracking, but is neither registered in `main.dart` nor consumed in `NoteEditorScreen`.
      - `NoteEditorScreen` remains an immense 4,893-line `StatefulWidget` managing state, timers, and SQLite operations internally.
    - **Orphaned `VoiceDictationPill`**:
      - `VoiceDictationPill` (`lib/features/notes/presentation/widgets/voice_dictation_pill.dart`) is not referenced anywhere in the app. Dictation in `NoteEditorScreen` only toggles mic icon color.
    - **Inlined Code Duplication**:
      - `NoteSearchReplaceBar` is declared in `lib/features/notes/presentation/widgets/note_search_replace_bar.dart`, but `NoteEditorScreen` duplicate-inlines the entire search bar (`note_editor_screen.dart:2701-2832`).
    - **Lack of 0ms Optimistic UI in `NoteProvider`**:
      - `bulkDelete()`, `bulkArchive()`, `bulkTogglePin()` in `NoteProvider` await the SQLite query and then trigger `refreshNotes()` from database, causing avoidable async delays instead of instant synchronous state mutation.
    - **Hardcoded Colors**:
      - `NoteCard` (`home_screen.dart:1175-1179`): Hardcoded `Colors.green` for checklist badge.
      - `NoteEditorScreen` (`note_editor_screen.dart:1699`): Hardcoded `Colors.amber` for AI icon.

---

## 3. Inventory of Deviations, Hardcoded Values & Inconsistencies

| File Path | Line Range | Category | Observation & Current Code | Invariant / Target Standard |
|---|---|---|---|---|
| `lib/widgets/home/note_view_builder.dart` | 97 | FAB Clearance | `padding: const EdgeInsets.fromLTRB(16, 10, 16, 88)` | Must use `AppLayout.fabBottomPadding = 96.0` |
| `lib/features/notes/presentation/screens/filtered_notes_screen.dart` | 171–174 | Hero Card Opacity | `color: colorScheme.errorContainer.withValues(alpha: isDark ? 0.16 : 0.35)` | Light Mode: 50%–55% alpha; Dark Mode: 20%–22% alpha; 1.2px accent border |
| `lib/features/settings/providers/settings_provider.dart` | 141, 257 | Trash Lifecycle | `_trashAutoPurgeDays = prefs.getInt('trashAutoPurgeDays') ?? 30;` | Master Invariant 1 dictates 7-day auto-purge lifecycle (`default: 7`) |
| `lib/providers/note_provider.dart` | 126 | Trash Lifecycle | `final purgeDays = prefs.getInt('trashAutoPurgeDays') ?? 30;` | Align with 7-day lifecycle standard |
| `lib/screens/home_screen.dart` | 514–520 | Touch Target Bounds | Color swatches in `_editTag` have `width: 32, height: 32` | Must enforce minimum 48x48dp hit bounds (`BoxConstraints(minWidth: 48, minHeight: 48)`) |
| `lib/screens/home_screen.dart` | 1087 | Surface Hierarchy | `backgroundColor = theme.colorScheme.surface;` | Use `surfaceContainer` or `surfaceContainerLow` for surface cards |
| `lib/screens/home_screen.dart` | 1175–1179 | Hardcoded Colors | `Colors.green.withValues(alpha: 0.15)` and `Colors.green` | Replace with semantic color token or `AppSemanticColors` |
| `lib/widgets/home/home_app_bar.dart` | 315 | Shape Hierarchy | `_showFolderPicker`: `borderRadius: BorderRadius.vertical(top: Radius.circular(20))` | Standardize on `AppBottomSheet` or 28dp (`AppLayout.radiusXXL`) |
| `lib/widgets/home/home_app_bar.dart` | 272 | Shape Hierarchy | `_showCreateFolderDialog`: Raw `AlertDialog` | Standardize on `AppDialog` with 28dp squircle corners |
| `lib/features/notes/presentation/screens/note_editor_screen.dart` | 1011 | Shape Hierarchy | `_showImageOptions`: `Radius.circular(20)` | Standardize on `AppBottomSheet` or 28dp (`AppLayout.radiusXXL`) |
| `lib/features/notes/presentation/screens/note_editor_screen.dart` | 1829 | Shape Hierarchy | `_showAiOptionsSheet`: `Radius.circular(24)` | Standardize on `AppBottomSheet` or 28dp (`AppLayout.radiusXXL`) |
| `lib/features/notes/presentation/screens/note_editor_screen.dart` | 4436 | Shape Hierarchy | Image options modal: `Radius.circular(20)` | Standardize on `AppBottomSheet` or 28dp (`AppLayout.radiusXXL`) |
| `lib/features/notes/presentation/screens/note_editor_screen.dart` | 1699 | Hardcoded Colors | `color: Colors.amber` on AI icon | Replace with `theme.colorScheme.primary` |
| `lib/features/notes/presentation/screens/note_editor_screen.dart` | 2701–2832 | Code Duplication | Inlined search bar duplicate of `NoteSearchReplaceBar` | Reuse existing `NoteSearchReplaceBar` component |
| `lib/features/notes/presentation/screens/note_editor_screen.dart` | 2835–2881 | Touch Targets | Top bar back/tag/history buttons lack 40x40 min constraints | Enforce `BoxConstraints(minWidth: 40, minHeight: 40)` and `VisualDensity.compact` |
| `lib/widgets/editor/editor_table_dialog.dart` | 150 | Hardcoded Radii | `borderRadius: BorderRadius.circular(8)` | Use `AppLayout.radiusS` |
| `lib/providers/note_provider.dart` | 265–297 | 0ms Optimistic UI | `bulkDelete`, `bulkArchive`, `bulkTogglePin` await DB before state mutation | Mutate in-memory `_notes` synchronously before DB writes |
| `lib/features/notes/providers/note_editor_provider.dart` | 1–182 | Architectural Debt | Orphaned provider; not registered in `main.dart` or consumed | Integrate with `NoteEditorScreen` to decouple 4.8k LOC state |
| `lib/features/notes/presentation/widgets/voice_dictation_pill.dart` | 1–93 | Architectural Debt | Orphaned widget; not integrated into `NoteEditorScreen` | Integrate into editor during voice dictation |

---

## 4. Architectural Deep Dive: Notes Engine & State

### 1. The Monolithic Note Editor Screen (`4,893 LOC`)
`NoteEditorScreen` is currently the largest single presentation file in the application. It bundles:
- Quill document state, lifecycle listeners, and post-frame deferred mutations
- Auto-save timer and debouncing logic (1500ms)
- Selection nudging and directional stepper handlers
- Text search and find/replace algorithms
- Image picking, file copying, and full-screen viewers
- Voice dictation recognition and speech callbacks
- AI action sheets (summary, grammar, style, translation, tags)
- Link preview scraping and thumbnail cards
- Inlined custom table embedding and cell controllers
- Floating selection and bottom creation toolbar builders

**Technical Debt Assessment**:
While `NoteEditorProvider` was scaffolded to decouple dirty tracking, content updates, and auto-save timers, it was never wired in. As a result, any state update requires calling `setState()` on the root `StatefulWidget`, re-evaluating large widget trees.

### 2. Immediate 0ms Optimistic UI Gap in NoteProvider
In contrast to the `FinancialManagerProvider` and `PeriodTrackerProvider` which mutate in-memory collections instantly, `NoteProvider`:
```dart
Future<void> bulkArchive() async {
  await _noteRepository.bulkArchive(_selectedNoteIds.toList(), true);
  clearSelection();
  await refreshNotes(); // re-queries SQLite
}
```
Awaiting the background database query before triggering a full reload causes perceptible UI latency when archiving or deleting large batches of notes.

### 3. Trash Lifecycle Inconsistency
- `NoteRepository.clearOldTrash([int days = 7])`: Enforces 7-day retention.
- `SettingsProvider`: Defaults to 30 days.
- `NoteProvider`: Defaults to 30 days.
- `AGENTS.md` and `ORIGINAL_REQUEST.md`: Specify 7-day auto-purge lifecycle.
Resolving this discrepancy requires aligning `SettingsProvider` and `NoteProvider` default fallbacks to 7 days.

---

## 5. Prioritized Actionable Roadmap

### Level 1: Immediate Token, Shape & Hit-Target Fixes (Low Risk, High Impact)
1. **Enforce `AppLayout.fabBottomPadding = 96.0` in `NoteViewBuilder`**:
   Replace `padding: const EdgeInsets.fromLTRB(16, 10, 16, 88)` with `EdgeInsets.fromLTRB(AppLayout.spaceL, AppLayout.spaceS, AppLayout.spaceL, AppLayout.fabBottomPadding)`.
2. **Align Hero Card Opacities in `FilteredNotesScreen`**:
   Update auto-purge banner container alpha to 50%–55% (Light) / 20%–22% (Dark) with 1.2px accent border.
3. **Standardize Modal Sheet Corners to 28dp (`AppLayout.radiusXXL`)**:
   Update `_showFolderPicker` in `HomeAppBar`, `_showImageOptions`, `_showAiOptionsSheet`, and full-screen image options in `NoteEditorScreen` from legacy 20dp/24dp to `AppBottomSheet` or 28dp.
4. **Fix 48dp Swatch Hit Bounds in `home_screen.dart`**:
   Wrap the 32x32 color swatches in `_editTag` with `SizedBox(width: 48, height: 48, child: Center(...))` (matching `ManageTagsScreen`).
5. **Eliminate Hardcoded Colors**:
   Replace `Colors.green` in `NoteCard` checklist chip with semantic container tokens; replace `Colors.amber` in `NoteEditorScreen` AI sheet with `colorScheme.primary`.

### Level 2: Component Integration & Clean Architecture (Medium Scope)
1. **Reuse `NoteSearchReplaceBar` in `NoteEditorScreen`**:
   Replace the 130 lines of inlined search row (`note_editor_screen.dart:2701-2832`) with `<NoteSearchReplaceBar ... />`.
2. **Integrate `VoiceDictationPill` in `NoteEditorScreen`**:
   Mount `VoiceDictationPill` above the bottom toolbar when `_isListening` is active, providing tactile visual feedback during speech input.
3. **Implement 0ms Optimistic UI in `NoteProvider`**:
   Synchronously mutate `_notes` (`removeWhere`, `add`, `sort`) in `bulkDelete`, `bulkArchive`, and `bulkTogglePin` before awaiting SQLite transactions.
4. **Harmonize Trash Auto-Purge Lifecycle to 7 Days**:
   Align `SettingsProvider` and `NoteProvider` default fallback from 30 days to 7 days to honor Invariant 1.

### Level 3: Note Editor Decomposition (Refactor)
1. **Activate `NoteEditorProvider`**:
   Register `NoteEditorProvider` in `main.dart` or scope it to `NoteEditorScreen` via `ChangeNotifierProvider`, migrating dirty tracking, auto-save timers, and folder/tag mutations into the provider.
2. **Extract Sub-Components from `NoteEditorScreen`**:
   Extract `TableWidget`, AI action sheets, and Link Preview cards into standalone modular files under `lib/features/notes/presentation/widgets/`.

---

## 6. Verification Status

- Automated Tests Verified:
  - `test/top_bar_search_and_sms_24h_sync_test.dart` (PASSED)
  - `test/note_migration_and_split_sync_test.dart` (PASSED)
  - `test/note_repository_test.dart` (PASSED)
- Total Passing Tests: **21/21 tests passing (100%)**.
- Zero Source Code Edits: `git status` confirmed 100% clean and pristine throughout this inspection turn.
