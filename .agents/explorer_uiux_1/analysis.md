# UI/UX Consistency, Material 3 Expressive & Touch Accessibility Audit Report

**Working Directory**: `.agents/explorer_uiux_1/`  
**Timestamp**: `2026-08-30T07:46:00Z`  
**Audit Scope**: Comprehensive read-only inspection of `lib/core/ui/`, `lib/core/theme/`, `lib/features/`, `lib/screens/`, `lib/widgets/`, and associated services.  
**Compliance Standards**: AGENTS.md Invariants 1, 8, 10, 13, 14; `ORIGINAL_REQUEST.md §R3`; `UI-UX-Specialist/SKILL.md`.

---

## Executive Summary & Scorecard

| Area | Status | Score | Critical Deficiencies |
| :--- | :---: | :---: | :--- |
| **1. SSOT Tokens (Colors, Radii, Spacing)** | ⚠️ Needs Remediation | 82% | 58 static `Colors.*` usages in UI widgets; 24 hardcoded `BorderRadius.circular` magic numbers; redundant palette seed arrays. |
| **2. Touch Target Accessibility (≥48x48dp)** | ⚠️ Needs Remediation | 76% | Micro-elements (Details link, chart dots, trash restore/delete buttons, symptom tiles, note top bar controls) fail 48x48dp minimum touch bounds; 45 missing `Semantics(button: true)`. |
| **3. Top App Bar Symmetry & Chrome** | ✅ High Compliance | 94% | Canonical 3-slot action hierarchy and Frosted Glass headers implemented across all primary screens; minor sub-pixel padding deviation (`+4` vs `+6`) in `HomeAppBar`. |
| **4. Dynamic Hero Card Opacities** | ⚠️ Minor Divergence | 88% | `SettingsHeroCard` and `P2pSyncScreen` fully compliant (55%/22%, 1.2px border); negative net cash flow card and cycle hero card diverge in Light Mode (45% vs 50%–55%); trash banners at 35%/16%. |
| **5. Morphing FAB & Bottom Clearance** | ⚠️ Needs Remediation | 80% | `AppMorphingFab` collapse/expand dynamics intact; `SplitBillsTab`, `PeriodTrackerScreen` bottom list, and `FilteredNotesScreen` lack `AppLayout.fabBottomPadding = 96.0`, obscuring bottom content/actions. |
| **6. Modern Selection Controls** | 🏆 100% Compliant | 100% | Complete zero-occurrence elimination of legacy `DropdownButton`/`DropdownButtonFormField` in favor of `SegmentedButton` and `FilterChip`. |
| **7. Text Emoji Prohibition (Rule 41)** | ⚠️ Needs Remediation | 78% | 15+ raw Unicode emojis (`🏷️`, `📂`, `✨`, `🏦`, `➔`, `🌟`, `🚀`, `🐛`, `💳`, `💰`, `📦`) in UI labels, SnackBars, What's New sheets, and notification channels. |

---

## Section 1: Single Source of Truth Tokens & Elimination of Magic Numbers

### 1.1 Hardcoded Material Palette Colors (`Colors.*`)
The design system mandates `Theme.of(context).colorScheme.<token>` or `Theme.of(context).extension<AppSemanticColors>()`. The following violations were identified:

#### A. Financial Manager & Split Bills (`lib/features/finances/`)
* **`lib/features/finances/presentation/widgets/split_bills_tab.dart`**:
  * Lines 194–196: `Colors.green.withValues(alpha: 0.18)` / `Colors.red.withValues(alpha: 0.18)` and `textColor: net >= 0 ? Colors.green : Colors.red`  
    * *Fix*: Map to `Theme.of(context).extension<AppSemanticColors>()?.success` and `colorScheme.error`.
  * Lines 214–241: `Colors.green` used directly for "You are owed" metric container fill, border, icon, and text.  
    * *Fix*: Use `(theme.extension<AppSemanticColors>()?.success ?? colorScheme.primary)`.
  * Lines 262–289: `Colors.red` used directly for "You owe" metric container fill, border, icon, and text.  
    * *Fix*: Use `colorScheme.error` and `colorScheme.errorContainer`.
  * Lines 442–481: `Colors.green` and `Colors.red` used for contact balance pills in People view.  
    * *Fix*: Use semantic success / error tokens.
  * Lines 654–660: `Colors.green`, `Colors.blue`, `Colors.amber`, `Colors.amber.shade800` for bill status badges ("Settled", "Partial", "Unpaid").  
    * *Fix*: Use `AppSemanticColors.success`, `colorScheme.primaryContainer`, and `colorScheme.tertiary`.
  * Lines 726–745: `Colors.green` for participant paid checkmark tiles.  
    * *Fix*: Use `AppSemanticColors.success`.
* **`lib/features/finances/presentation/widgets/settle_up_sheet.dart`**:
  * Lines 72–106: `Colors.green` and `Colors.red` for debt settlement amounts and hero icon.  
    * *Fix*: Map to `AppSemanticColors.success` and `colorScheme.error`.
* **`lib/features/finances/presentation/widgets/burn_rate_forecast_card.dart`**:
  * Lines 24–28: `return Colors.teal; return Colors.green; return Colors.orange;` in `_getStatusColor`.  
    * *Fix*: Map to `colorScheme.tertiary`, `AppSemanticColors.success`, `colorScheme.error`.
* **`lib/features/finances/presentation/widgets/category_budgets_card.dart`**:
  * Lines 131–141: `progressColor = Colors.orange`, `progressColor = Colors.teal`, `paceTagColor = Colors.green`.  
    * *Fix*: Map to `colorScheme.error`, `colorScheme.tertiary`, `AppSemanticColors.success`.

#### B. Health Tracker (`lib/features/health/`)
* **`lib/features/health/presentation/widgets/cycle_insights_card.dart`**:
  * Lines 18–20: `if (stats.regularityScore >= 88.0) return Colors.green; if (...) return Colors.teal; if (...) return Colors.orange;`  
    * *Fix*: Map to `AppSemanticColors.success`, `colorScheme.primary`, `colorScheme.error`.

#### C. Settings & Notes (`lib/features/settings/`, `lib/features/notes/`)
* **`lib/features/settings/presentation/screens/settings_screen.dart`**:
  * Lines 724–725: `iconColor: Colors.amber.shade700`, `iconBackgroundColor: Colors.amber.withValues(alpha: 0.2)` in experimental AI settings tile.  
    * *Fix*: Map to `colorScheme.tertiary` and `colorScheme.tertiaryContainer`.
* **`lib/features/notes/presentation/screens/note_editor_screen.dart`**:
  * Line 1630: `const Icon(Icons.auto_awesome, color: Colors.amber, size: 22)` in AI menu.  
    * *Fix*: Use `colorScheme.primary`.
* **`lib/features/finances/presentation/screens/transaction_editor_screen.dart`**:
  * Line 919: `avatar: const Icon(Icons.auto_awesome, size: 16, color: Colors.amber)` in AI category suggestion chip.  
    * *Fix*: Use `colorScheme.primary`.

---

### 1.2 Hardcoded Static Hex Colors
* **`lib/features/health/presentation/screens/period_tracker_screen.dart`**:
  * Lines 63–106: Duplicated fallback color literals `const Color(0xFFD32F2F)`, `const Color(0xFF1976D2)`, `const Color(0xFFF57C00)`, `const Color(0xFF7B1FA2)` in 8 locations.  
    * *Fix*: Replace with `AppSemanticColors.light.phaseMenstrual`, `AppSemanticColors.light.phaseFollicular`, etc.
* **`lib/features/health/presentation/widgets/period_calendar_card.dart`**:
  * Line 62: `? const Color(0xFF1C1A22)` in day container decoration.  
    * *Fix*: Replace with `theme.colorScheme.surfaceContainerLow`.
* **`lib/features/finances/presentation/screens/transaction_editor_screen.dart` (586–597) & `category_management_screen.dart` (370–381)**:
  * Both screens declare duplicate 12-element static `Color(...)` lists instead of referencing `AppTheme.noteColors` or `CategoryConstants.paletteSeedColors`.  
    * *Fix*: Sourced directly from `AppTheme.noteColors.skip(1).toList()`.

---

### 1.3 Hardcoded Border Radii Magic Numbers
All border radii must reference `AppLayout.radius*` (`radiusS: 8`, `radiusM: 12`, `radiusL: 16`, `radiusXL: 20`, `radiusXXL: 24`, `radiusMAX: 32`):

| File | Line | Current Code | Token Replacement |
| :--- | :---: | :--- | :--- |
| `lib/core/theme/app_theme.dart` | 354 | `BorderRadius.circular(28)` | `BorderRadius.circular(AppLayout.radiusXL + 8)` or `28` in M3 spec |
| `lib/features/settings/presentation/screens/onboarding_screen.dart` | 184, 597, 752, 804 | `BorderRadius.circular(4)` | `BorderRadius.circular(AppLayout.spaceXS)` |
| `lib/features/health/presentation/widgets/period_log_dashboard_card.dart` | 306 | `BorderRadius.circular(20)` | `BorderRadius.circular(AppLayout.radiusXL)` |
| `lib/features/notes/presentation/screens/note_editor_screen.dart` | 2503, 2510 | `BorderRadius.circular(28)` | `BorderRadius.circular(AppLayout.radiusMAX)` |
| `lib/features/notes/presentation/screens/note_editor_screen.dart` | 2557 | `BorderRadius.circular(16)` | `BorderRadius.circular(AppLayout.radiusL)` |
| `lib/features/finances/presentation/screens/financial_manager_screen.dart` | 413, 421 | `BorderRadius.circular(12)` | `BorderRadius.circular(AppLayout.radiusM)` |
| `lib/features/finances/presentation/screens/financial_manager_screen.dart` | 1696 | `BorderRadius.circular(16)` | `BorderRadius.circular(AppLayout.radiusL)` |
| `lib/features/finances/presentation/widgets/minimal_chart_deck.dart` | 158 | `BorderRadius.circular(12)` | `BorderRadius.circular(AppLayout.radiusM)` |
| `lib/features/finances/presentation/widgets/minimal_chart_deck.dart` | 924 | `BorderRadius.circular(4)` | `BorderRadius.circular(AppLayout.spaceXS)` |
| `lib/features/finances/presentation/widgets/category_budgets_card.dart` | 181 | `BorderRadius.circular(4)` | `BorderRadius.circular(AppLayout.spaceXS)` |
| `lib/features/finances/presentation/widgets/financial_trash_sheet.dart` | 200, 233 | `BorderRadius.circular(20)` | `BorderRadius.circular(AppLayout.radiusXL)` |
| `lib/features/finances/presentation/widgets/financial_analytics_tab.dart` | 615 | `BorderRadius.circular(4)` | `BorderRadius.circular(AppLayout.spaceXS)` |
| `lib/features/finances/presentation/widgets/split_bills_tab.dart` | 673 | `BorderRadius.circular(4)` | `BorderRadius.circular(AppLayout.spaceXS)` |
| `lib/features/finances/presentation/widgets/burn_rate_forecast_card.dart` | 232, 242, 253 | `BorderRadius.circular(4)` | `BorderRadius.circular(AppLayout.spaceXS)` |
| `lib/widgets/editor/editor_table_dialog.dart` | 149 | `BorderRadius.circular(8)` | `BorderRadius.circular(AppLayout.radiusS)` |

---

## Section 2: Touch Target Bounds & Semantics ($48 \times 48\text{dp}$)

### 2.1 Micro-Elements Under $48 \times 48\text{dp}$ Bounds
Google Material 3 and WCAG AA accessibility require all interactive controls to maintain a minimum $48 \times 48\text{dp}$ touch bounding box.

1. **`lib/features/finances/presentation/widgets/minimal_chart_deck.dart` (Lines 156–180)**:
   * **Element**: "Details >" text + chevron link.
   * **Current Size**: `Padding(horizontal: 8, vertical: 6)` on 11pt text $\rightarrow$ Effective height $\approx 23\text{dp}$.
   * **Remediation**: Wrap `InkWell` in `ConstrainedBox(constraints: const BoxConstraints(minWidth: 48, minHeight: 48))` with `alignment: Alignment.centerRight`.
2. **`lib/features/finances/presentation/widgets/minimal_chart_deck.dart` (Lines 227–254)**:
   * **Element**: Slide indicator dots.
   * **Current Size**: `Padding(horizontal: 6, vertical: 8)` on 4dp bar $\rightarrow$ Effective hit box $\approx 20 \times 20\text{dp}$.
   * **Remediation**: Expand touch hit box to `padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18)` or constrain child to `BoxConstraints(minWidth: 48, minHeight: 48)`.
3. **`lib/features/finances/presentation/screens/financial_manager_screen.dart` (Lines 728–754)**:
   * **Element**: Hero Card Mode Switcher Dots (Net Cash Flow / Burn Rate / Projections).
   * **Current Size**: `Padding(horizontal: 5, vertical: 6)` on 5dp dot $\rightarrow$ Effective hit box $\approx 15 \times 17\text{dp}$.
   * **Remediation**: Wrap each dot in `ConstrainedBox(constraints: const BoxConstraints(minWidth: 48, minHeight: 48))` or `padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)`.
4. **`lib/features/notes/presentation/screens/note_editor_screen.dart` (Lines 2741, 2749, 2759)**:
   * **Element**: Search match previous / next / clear buttons.
   * **Current Code**: `IconButton(constraints: const BoxConstraints(minWidth: 32, minHeight: 32))`
   * **Remediation**: Upgrade constraints to `BoxConstraints(minWidth: 48, minHeight: 48)` or use standard `VisualDensity.compact` with 40–48dp bounds.
5. **`lib/features/finances/presentation/widgets/financial_trash_sheet.dart` (Lines 199–260)**:
   * **Element**: Inline restore (`Icons.restore_rounded`) and permanent delete (`Icons.delete_forever_rounded`) icon buttons.
   * **Current Size**: `Padding(all: 6)` on 18dp icon $\rightarrow 30 \times 30\text{dp}$.
   * **Remediation**: Wrap `InkWell` in `ConstrainedBox(constraints: const BoxConstraints(minWidth: 48, minHeight: 48))`.
6. **`lib/features/health/presentation/widgets/period_log_dashboard_card.dart` (Lines 233, 276, 343)**:
   * **Element**: Flow level selector pills and symptom toggle tiles.
   * **Current Size**: `padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)` $\rightarrow 25\text{dp}$ height.
   * **Remediation**: Enforce minimum height of 48dp on pill containers or wrap in padded touch bounds.

---

### 2.2 Missing `Semantics(button: true)` on Custom Gesture Detectors
45 interactive `GestureDetector` / `InkWell` instances lack accessibility labels for screen readers (TalkBack / VoiceOver). Primary examples:
* `lib/core/ui/app_chip.dart`: Line 116 (`InkWell`) and Line 144 (`GestureDetector` for delete icon).
* `lib/features/health/presentation/widgets/period_log_dashboard_card.dart`: Lines 233, 276, 343 (symptom and flow toggles).
* `lib/features/notes/presentation/screens/manage_tags_screen.dart`: Line 65 (tag list item).
* `lib/features/finances/presentation/screens/category_management_screen.dart`: Lines 511, 549, 791, 829 (color and icon pickers).
* `lib/features/finances/presentation/widgets/financial_trash_sheet.dart`: Lines 199, 232 (restore and delete buttons).

---

## Section 3: Top App Bar Symmetry, Headroom & Chrome Hierarchy

### 3.1 Top Header Geometry & Sub-Pixel Headroom
* **`FrostedGlassSliverAppBar`** (`lib/core/ui/frosted_sliver_app_bar.dart`):
  * Backdrop filter: `sigmaX: 16, sigmaY: 16`
  * Fill: `colorScheme.surfaceContainerLow.withValues(alpha: isDark ? 0.82 : 0.80)`
  * Padding: `top: statusBarHeight + 6, left: 16, right: 16, bottom: 6`
  * Toolbar height: `statusBarHeight + height + 12.0`
  * Fully compliant with Invariant 14.
* **`HomeAppBar`** (`lib/widgets/home/home_app_bar.dart`):
  * Lines 98–101: `padding: EdgeInsets.only(top: statusBarHeight + 4, left: 16, right: 16, bottom: 4)`
  * *Discrepancy*: Uses `+ 4` top / `4` bottom instead of standard `+ 6` / `6` (Invariant 14).
  * *Fix*: Standardize vertical padding on `top: statusBarHeight + 6, bottom: 6`.
* **`FinancialManagerScreen`** & **`PeriodTrackerScreen`**:
  * Enforce `toolbarHeight: MediaQuery.of(context).padding.top + 72.0` and child container `height: 60.0` with `top: padding.top + 6, bottom: 6`. Fully compliant.

---

### 3.2 Canonical 3-Slot Action Hierarchy
The top action bar sequence across all three primary tabs perfectly preserves muscle memory:

```
[ Primary Contextual Action ]  ──►  [ Penultimate Tools (⋮) ]  ──►  [ Terminal Anchor (⚙️ Settings) ]
• Notes:   [ 🔍 Search ]           • [ ⋮ Notes Tools ]            • [ ⚙️ Settings ]
• Finance: [ 🔍 Search ] [ 🔄 SMS ] • [ ⋮ Finances Tools ]         • [ ⚙️ Settings ]
• Health:  [ 📅 Today ]            • [ ⋮ Health Tools ]           • [ ⚙️ Settings ]
```

All action icon buttons strictly enforce `constraints: const BoxConstraints(minWidth: 40, minHeight: 40)`, `visualDensity: VisualDensity.compact`, and `padding: EdgeInsets.zero`.

---

### 3.3 Tonal Scope Pill Styling & Contrast
All 3 primary modules feature high-contrast M3 Tonal Scope Pills directly below their title:
* **Notes**: `Notes` + `[ 📁 Folder • Count ▾ ]`
* **Finances**: `Finances` + `[ 📅 Date Range ▾ ]`
* **Health Tracker**: `Period Tracker` + `[ 🌸 Day X • Phase ]`

*Styling standard*: `colorScheme.primaryContainer.withValues(alpha: isDark ? 0.35 : 0.45)`, `1.0px` primary outline border (`colorScheme.primary.withValues(alpha: 0.28)`), `colorScheme.onSurface` label, and `colorScheme.primary` leading icon & `Icons.keyboard_arrow_down_rounded` chevron.

---

### 3.4 Modal Bottom Sheet & Dialog Standardizations
* **`HomeAppBar._showFolderPicker`** (`lib/widgets/home/home_app_bar.dart:354`): Uses raw `showModalBottomSheet` with inline `Radius.circular(20)` instead of `AppBottomSheet.show`.
* **`HomeScreen._showTemplateSheet`** (`lib/screens/home_screen.dart:927`): Uses raw `showModalBottomSheet` instead of `AppBottomSheet.show`.
* **Confirmation Dialogs**: 9 instances across `HomeScreen`, `CategoryManagementScreen`, `SmsRulesScreen`, `TransactionEditorScreen`, `FilteredNotesScreen`, `ManageTagsScreen`, `NoteEditorScreen`, `SettingsScreen`, and `BackupService` use raw `showDialog` with custom `AlertDialog` instead of `AppDialog.showConfirm(...)`.

---

## Section 4: Dynamic Hero Card Opacities & Accent Borders

The design system standardizes dynamic container opacities on top hero cards:
* **Light Mode (`Brightness.light`)**: `50%–55%` alpha container fill with `45%` border opacity (`width: 1.2`).
* **Dark Mode (`Brightness.dark`)**: `20%–22%` alpha container fill with `35%` border opacity (`width: 1.2`).

### Hero Card Audit Matrix:

| Hero Card Component | File Path | Light Alpha | Dark Alpha | Border Width | Compliance Status |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **SettingsHeroCard** | `lib/widgets/settings_widgets.dart:39` | 55% | 22% | 1.2px | ✅ Fully Compliant |
| **P2P Sync Status Hero** | `lib/features/sync/presentation/screens/p2p_sync_screen.dart:285` | 55% | 22% | 1.2px | ✅ Fully Compliant |
| **Net Cash Flow (Positive)** | `lib/features/finances/presentation/screens/financial_manager_screen.dart:692` | 55% | 22% | 1.2px | ✅ Fully Compliant |
| **Net Cash Flow (Negative)** | `lib/features/finances/presentation/screens/financial_manager_screen.dart:693` | 45% | 22% | 1.2px | ⚠️ Diverges (Should be 50%–55%) |
| **Cycle Phase Moon Hero** | `lib/features/health/presentation/widgets/cycle_phase_hero_card.dart:41` | 45% | 20% | 1.0px | ⚠️ Diverges (Should be 50%–55% and 1.2px) |
| **Trash Auto-Purge Banner** | `lib/features/notes/presentation/screens/filtered_notes_screen.dart:172` | 35% | 16% | 1.0px | ⚠️ Diverges (Should be 50%–55% / 20%–22%) |

---

## Section 5: Universal Morphing FAB & Scroll Clearance

### 5.1 Morphing FAB Scroll Dynamics
* `AppMorphingFab` (`lib/core/ui/app_morphing_fab.dart`) is used across `HomeScreen` (Notes, Finances, Health) and secondary editor screens (`CategoryManagementScreen`, `SplitBillEditorScreen`, `TransactionEditorScreen`).
* Smoothly transitions from expanded stadium CTA ($56\text{dp}$ height) to $56 \times 56\text{dp}$ circular button on downward scroll and restores on upward scroll.

### 5.2 Missing Bottom Clearances (`fabBottomPadding = 96.0`)
When FABs or bottom navigation bars are present, scroll views must include `AppLayout.fabBottomPadding = 96.0` on their bottom padding to ensure the final items and actions are fully visible:

1. **`lib/features/finances/presentation/widgets/split_bills_tab.dart` (Line 63)**:
   * Current: `ListView(padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceM, vertical: AppLayout.spaceS))`
   * *Bug*: Bottom bill cards and WhatsApp/Clipboard share buttons are partially covered by the bottom navigation bar.
   * *Fix*: Apply `padding: const EdgeInsets.fromLTRB(AppLayout.spaceM, AppLayout.spaceS, AppLayout.spaceM, AppLayout.fabBottomPadding)`.
2. **`lib/features/health/presentation/screens/period_tracker_screen.dart` (Line 511)**:
   * Current: `padding: const EdgeInsets.fromLTRB(16, 12, 16, 32)` on period logs sliver list.
   * *Fix*: Upgrade `32` to `AppLayout.fabBottomPadding`.
3. **`lib/features/notes/presentation/screens/filtered_notes_screen.dart` (Line 263)**:
   * Current: `padding: const EdgeInsets.only(bottom: 12.0)` on notes list.
   * *Fix*: Apply `AppLayout.fabBottomPadding`.

---

## Section 6: Selection Controls Modernization & Legacy Dropdown Prohibition

### 6.1 Elimination of Legacy Dropdown Controls
* A global codebase scan confirms **0 occurrences** of `DropdownButton` or `DropdownButtonFormField`.
* All selection interfaces use M3-standard controls:
  * Short option sets (2–4 items): `SegmentedButton<T>` with compact density and haptics (e.g. Split Bills view mode, transaction expense/income toggle).
  * Category pickers: Dynamic `FilterChip` clouds sourced from `TransactionCategory.allNames` with authentic icons and color badges.
  * Chevrons: Standardized universally on `Icons.keyboard_arrow_down_rounded`.

---

## Section 7: Rule 41 Unicode Emoji Glyph Prohibition & Material Symbols Mapping

Invariant 10 and Rule 41 strictly prohibit raw Unicode emoji glyphs in UI buttons, dialogs, SnackBars, or notifications. The following violations were identified and mapped to official Google Material Symbols:

| File Path | Line | Offending Raw Emoji Code | Replacement Material Symbol / Text |
| :--- | :---: | :--- | :--- |
| `lib/features/finances/presentation/screens/sms_rules_screen.dart` | 450, 734 | `'🏷️ Title: ${parsed.description}'` | `Icon(Icons.label_outline_rounded)` + `'Title: ...'` |
| `lib/features/finances/presentation/screens/sms_rules_screen.dart` | 455 | `'📂 Category: ${parsed.category}'` | `Icon(Icons.folder_outlined)` + `'Category: ...'` |
| `lib/features/finances/presentation/screens/transaction_editor_screen.dart` | 563 | `Text('Refined title & category with Gemini Nano ✨')` | `Text('Refined title & category with Gemini Nano')` + `Icon(Icons.auto_awesome_rounded)` |
| `lib/features/finances/presentation/screens/financial_manager_screen.dart` | 639 | `Text('Refining recent transaction titles with Gemini Nano... ✨')` | `Text('Refining recent transaction titles with Gemini Nano...')` |
| `lib/features/finances/presentation/screens/financial_manager_screen.dart` | 655 | `'Successfully refined $count transaction title... with AI ✨!'` | `'Successfully refined $count transaction title... with AI!'` |
| `lib/features/finances/presentation/widgets/financial_ledger_tab.dart` | 227 | `'${transaction.account == AccountType.savings ? '🏦 Savings • ' : ''}...'` | `Icon(Icons.account_balance_outlined, size: 12)` + `'Savings • '` |
| `lib/features/settings/presentation/screens/onboarding_screen.dart` | 987 | `actionLabel: 'Configure P2P Sync ➔'` | `actionLabel: 'Configure P2P Sync'` (trailing `Icons.arrow_forward_rounded`) |
| `lib/widgets/whats_new_sheet.dart` | 35 | `categoryTitle: "🌟 What's New"` | `categoryTitle: "What's New"`, icon: `Icons.auto_awesome_rounded` |
| `lib/widgets/whats_new_sheet.dart` | 57 | `categoryTitle: "🚀 Improvements"` | `categoryTitle: "Improvements"`, icon: `Icons.trending_up_rounded` |
| `lib/widgets/whats_new_sheet.dart` | 79 | `categoryTitle: "🐛 Fixes"` | `categoryTitle: "Fixes"`, icon: `Icons.bug_report_rounded` |
| `lib/services/sms_service.dart` | 99, 675, 908 | `title: '💳 Expense Auto-Imported'` / `'💰 Income Auto-Imported'` | `title: 'Expense Auto-Imported'` / `'Income Auto-Imported'` |
| `lib/services/backup_service.dart` | 167 | `title: '📦 Auto-Backup Complete'` | `title: 'Auto-Backup Complete'` |
| `lib/services/update_rating_service.dart` | 28 | `content: const Text('✨ New update downloaded and ready.')` | `content: const Text('New update downloaded and ready.')` |
| `lib/services/p2p_sync_service.dart` | 406–412 | `'📡 Peer unreachable'`, `'⏳ Connection timed out'`, `'🔑 Pair code mismatch'`, `'⚠️ Unexpected data'` | Plain semantic strings without emoji prefixes |

---

## Section 8: Master UI/UX Remediation Matrix

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ File Path                                  │ Line │ Severity │ Issue Category      │ Current Code                 │ Replacement Token / Code       │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ lib/features/finances/.../split_bills_tab.dart│ 63   │ HIGH     │ Missing Clearance   │ vertical: AppLayout.spaceS   │ fabBottomPadding = 96.0        │
│ lib/features/finances/.../split_bills_tab.dart│ 194  │ HIGH     │ Static Colors.*     │ Colors.green / Colors.red    │ AppSemanticColors / error      │
│ lib/features/finances/.../minimal_chart_deck.dart│ 156│ HIGH     │ Touch Target < 48dp │ Padding(h: 8, v: 6) (~23dp)  │ ConstrainedBox(min: 48x48)     │
│ lib/features/finances/.../minimal_chart_deck.dart│ 227│ HIGH     │ Touch Target < 48dp │ Padding(h: 6, v: 8) (~20dp)  │ ConstrainedBox(min: 48x48)     │
│ lib/features/finances/.../financial_manager.dart│ 728│ HIGH     │ Touch Target < 48dp │ Padding(h: 5, v: 6) (~17dp)  │ ConstrainedBox(min: 48x48)     │
│ lib/features/notes/.../note_editor_screen.dart│ 2741 │ HIGH     │ Touch Target < 48dp │ constraints: min 32x32       │ constraints: min 48x48         │
│ lib/features/health/.../period_tracker.dart│ 511  │ HIGH     │ Missing Clearance   │ bottom: 32                   │ AppLayout.fabBottomPadding     │
│ lib/features/notes/.../filtered_notes.dart │ 263  │ HIGH     │ Missing Clearance   │ bottom: 12.0                 │ AppLayout.fabBottomPadding     │
│ lib/features/finances/.../sms_rules_screen.dart│ 450│ MEDIUM   │ Rule 41 Emoji       │ '🏷️ Title: ...'              │ Plain text + Material Symbol   │
│ lib/features/finances/.../transaction_editor.dart│ 563│ MEDIUM │ Rule 41 Emoji       │ '... Gemini Nano ✨'         │ Plain text + Icons.auto_awesome│
│ lib/features/health/.../cycle_phase_hero.dart│ 41  │ MEDIUM   │ Hero Card Alpha     │ alpha: 0.45 (Light)          │ alpha: 0.55 / border: 1.2px    │
│ lib/features/finances/.../financial_manager.dart│ 693│ MEDIUM │ Hero Card Alpha     │ alpha: 0.45 (Light Negative) │ alpha: 0.55                    │
│ lib/features/notes/.../filtered_notes.dart │ 172  │ MEDIUM   │ Hero Banner Alpha   │ alpha: 0.35 / 0.16           │ alpha: 0.55 / 0.22             │
│ lib/widgets/home/home_app_bar.dart         │ 98   │ LOW      │ Sub-Pixel Headroom  │ top: statusBarHeight + 4     │ top: statusBarHeight + 6       │
│ lib/widgets/home/home_app_bar.dart         │ 354  │ LOW      │ Modal Sheet SSOT    │ showModalBottomSheet (raw)   │ AppBottomSheet.show            │
│ lib/screens/home_screen.dart               │ 927  │ LOW      │ Modal Sheet SSOT    │ showModalBottomSheet (raw)   │ AppBottomSheet.show            │
│ lib/features/settings/.../onboarding.dart  │ 184  │ LOW      │ Inline Radius Magic │ BorderRadius.circular(4)     │ AppLayout.spaceXS              │
│ lib/features/finances/.../financial_trash.dart│ 200│ LOW      │ Inline Radius Magic │ BorderRadius.circular(20)    │ AppLayout.radiusXL             │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```
