# UI/UX Consistency, Material 3 Expressive & Touch Accessibility Matrix

**Document Version**: 1.0.0  
**Author**: Project Orchestrator (`orchestrator_1`)  
**Workspace**: `/Users/saadhjawwadh/Documents/Code/Note taking`  
**Authoritative Invariants**: `AGENTS.md` Invariants 1, 8, 10, 13, 14, and Rule 41

---

## 1. Executive Summary

This matrix establishes the complete inventory of design token discrepancies, touch target accessibility bounds, header chrome alignment, hero card opacities, and raw Unicode emoji replacements across all user interface surfaces.

---

## 2. Design Token Consistency & Static Color Replacement Matrix

| File Path & Line | Current Non-Compliant Code | Issue | Prescribed Token Replacement | Rationale |
|---|---|---|---|---|
| `lib/features/finances/presentation/widgets/split_bills_tab.dart:194–196` | `Colors.green.withValues(alpha: 0.18)` / `Colors.red.withValues(alpha: 0.18)` | Hardcoded static colors | `AppSemanticColors.success.withValues(alpha: 0.18)` / `colorScheme.error.withValues(alpha: 0.18)` | Dynamic Material You wallpaper compliance |
| `lib/features/finances/presentation/widgets/split_bills_tab.dart:214–289` | `Colors.green` / `Colors.red` for "Owed" / "Owe" cards | Hardcoded static colors | `AppSemanticColors.success` / `colorScheme.error` | WCAG AA contrast in dark and light modes |
| `lib/features/finances/presentation/widgets/settle_up_sheet.dart:72–106` | `Colors.green` / `Colors.red` for debt pill indicators | Hardcoded static colors | `AppSemanticColors.success` / `colorScheme.error` | Theme token single-source-of-truth |
| `lib/features/finances/presentation/widgets/burn_rate_forecast_card.dart:24–28` | `Colors.teal`, `Colors.green`, `Colors.orange` | Static color returns | `AppSemanticColors.success`, `colorScheme.primary`, `AppSemanticColors.warning` | Seamless OLED & wallpaper adaptation |
| `lib/features/finances/presentation/widgets/category_budgets_card.dart:131–141` | `Colors.orange`, `Colors.teal`, `Colors.green` for pace tags | Static color returns | `AppSemanticColors.warning`, `colorScheme.primary`, `AppSemanticColors.success` | Consistency with AppTheme palette |
| `lib/features/health/presentation/widgets/cycle_insights_card.dart:18–20` | `Colors.green`, `Colors.teal`, `Colors.orange` | Static color returns | `AppSemanticColors.success`, `colorScheme.primary`, `AppSemanticColors.warning` | Palette token unification |
| `lib/features/settings/presentation/screens/settings_screen.dart:724–725` | `iconColor: Colors.amber.shade700`, `iconBackgroundColor: Colors.amber.withValues(alpha: 0.2)` | Hardcoded Amber | `colorScheme.tertiary` / `colorScheme.tertiaryContainer` | M3 Expressive container pairing |
| `lib/features/notes/presentation/screens/note_editor_screen.dart:1630` | `Icon(Icons.auto_awesome, color: Colors.amber)` | Static color | `Icon(Icons.auto_awesome_rounded, color: colorScheme.primary)` | Material 3 primary accent alignment |
| `lib/features/finances/presentation/screens/transaction_editor_screen.dart:919` | `Icon(Icons.auto_awesome, color: Colors.amber)` | Static color | `Icon(Icons.auto_awesome_rounded, color: colorScheme.primary)` | Consistent AI sparkle styling |

---

## 3. Touch Target Accessibility Matrix ($\ge 48 \times 48\text{dp}$)

| UI Component | File Path & Lines | Current Effective Hit Area | Deficit | Required Remediation Wrapper |
|---|---|---|---|---|
| **Minimal Chart "Details >" Link** | `lib/features/finances/presentation/widgets/minimal_chart_deck.dart:156–180` | $\approx 48 \times 23\text{dp}$ | Height $< 48\text{dp}$ | `ConstrainedBox(constraints: const BoxConstraints(minWidth: 48, minHeight: 48))` + `Semantics(button: true, label: 'View detailed analytics')` |
| **Minimal Chart Pagination Dots** | `lib/features/finances/presentation/widgets/minimal_chart_deck.dart:227–254` | $\approx 20 \times 20\text{dp}$ | Width & Height $< 48\text{dp}$ | `InkWell(onTap: () => onPageSelected(i), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18), child: ...))` |
| **Finance Hero Mode Switcher Dots** | `lib/features/finances/presentation/screens/financial_manager_screen.dart:728–754` | $\approx 15 \times 17\text{dp}$ | Width & Height $< 48\text{dp}$ | Padded gesture wrapper with `BoxConstraints(minWidth: 48, minHeight: 48)` |
| **Note Search Nav Buttons** | `lib/features/notes/presentation/screens/note_editor_screen.dart:2741, 2749, 2759` | $32 \times 32\text{dp}$ | Width & Height $< 48\text{dp}$ | `IconButton(constraints: const BoxConstraints(minWidth: 48, minHeight: 48), visualDensity: VisualDensity.compact)` |
| **Trash Restore & Delete Actions** | `lib/features/finances/presentation/widgets/financial_trash_sheet.dart:199–260` | $\approx 30 \times 30\text{dp}$ | Width & Height $< 48\text{dp}$ | Expand tap target to $48\times 48\text{dp}$ with `Semantics(button: true, label: 'Restore transaction')` |
| **Flow Level & Symptom Toggle Pills** | `lib/features/health/presentation/widgets/period_log_dashboard_card.dart:233, 276, 343` | $\approx 40 \times 25\text{dp}$ | Height $< 48\text{dp}$ | `AppChip` primitive or `BoxConstraints(minHeight: 48)` + `Semantics(button: true, selected: isSelected)` |
| **Sync Screen Key Copy Buttons** | `lib/features/sync/presentation/screens/p2p_sync_screen.dart:577, 624` | $32 \times 32\text{dp}$ | Width & Height $< 48\text{dp}$ | `IconButton(constraints: const BoxConstraints(minWidth: 48, minHeight: 48))` |
| **Onboarding Feature Action Buttons** | `lib/features/settings/presentation/screens/onboarding_screen.dart:1075` | Shrunk to zero | Height $< 48\text{dp}$ | `FilledButton.tonal(style: FilledButton.styleFrom(minimumSize: const Size(48, 48)))` |

---

## 4. Top App Bar Chrome, Symmetry & Headroom Matrix

| Header Component | File Path & Lines | Inspected Parameters | Status | Remediation |
|---|---|---|---|---|
| **Notes Top Header** | `lib/widgets/home/home_app_bar.dart:98–101` | `padding: top: statusBar + 4, bottom: 4` | **Slight Skew** | Align to standardized `top: statusBar + 6, bottom: 6, left: 16, right: 16` |
| **Finances Top Header** | `lib/features/finances/presentation/screens/financial_manager_screen.dart:500–560` | `FrostedGlassSliverAppBar`, sigma 16.0, `border: null` | **PASS** | Fully compliant with 16dp edge symmetry |
| **Health Top Header** | `lib/features/health/presentation/screens/period_tracker_screen.dart:292–327` | `FrostedGlassSliverAppBar`, tonal scope pill `[ 🌸 Day X • Phase ]` | **PASS** | Fully compliant with 16dp edge symmetry |
| **Action Hierarchy Order** | Notes, Finances, Health screens | `[Contextual Action]` $\to$ `[⋮ Tools]` $\to$ `[⚙️ Settings]` | **PASS** | Strict adherence across all tabs |
| **Tonal Scope Pill Contrast** | All module headers | `primaryContainer` alpha 0.35–0.45, 1.0px border | **PASS** | 100% legibility across wallpaper seeds |

---

## 5. Dynamic Hero Card Opacities & Accent Borders Matrix

| Hero Card Component | File Path & Lines | Light Mode Alpha | Dark Mode Alpha | Accent Border Width | Status & Remediation |
|---|---|---|---|---|---|
| **Settings Hero Card** | `lib/widgets/settings_widgets.dart:39` | `0.55` (55%) | `0.22` (22%) | `1.2px` | **PASS** (Reference implementation) |
| **P2P Sync Status Card** | `lib/features/sync/presentation/screens/p2p_sync_screen.dart:285` | `0.55` (55%) | `0.22` (22%) | `1.2px` | **PASS** |
| **Net Balance Hero Card (Positive)** | `lib/features/finances/presentation/screens/financial_manager_screen.dart:675` | `0.55` (55%) | `0.22` (22%) | `1.2px` | **PASS** |
| **Net Balance Hero Card (Negative)** | `lib/features/finances/presentation/screens/financial_manager_screen.dart:693` | `0.45` (45%) | `0.20` (20%) | `1.0px` | **GAP** $\to$ Align to `0.55` Light / `0.22` Dark / `1.2px` border |
| **Cycle Moon Phase Hero Card** | `lib/features/health/presentation/widgets/cycle_phase_hero_card.dart:41` | `0.45` (45%) | `0.20` (20%) | `1.0px` | **GAP** $\to$ Align to `0.55` Light / `0.22` Dark / `1.2px` border |
| **Trash Auto-Purge Banner** | `lib/features/notes/presentation/screens/filtered_notes_screen.dart:172` | `0.35` (35%) | `0.16` (16%) | `1.0px` | **GAP** $\to$ Align to `0.55` Light / `0.22` Dark / `1.2px` border |

---

## 6. Universal Morphing FAB & Bottom Scroll Clearance Matrix

| Scrollable View | File Path & Line | Current Bottom Padding | Status | Required Bottom Clearance |
|---|---|---|---|---|
| **Finances Ledger Tab** | `lib/features/finances/presentation/widgets/financial_ledger_tab.dart:420` | `AppLayout.fabBottomPadding = 96.0` | **PASS** | No clipping |
| **Finances Budgets Tab** | `lib/features/finances/presentation/widgets/category_budgets_card.dart:280` | `AppLayout.fabBottomPadding = 96.0` | **PASS** | No clipping |
| **Finances Split Bills Tab** | `lib/features/finances/presentation/widgets/split_bills_tab.dart:63` | `vertical: AppLayout.spaceS` (8dp) | **GAP (Clipping)** | Set `padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: AppLayout.fabBottomPadding)` |
| **Health Tracker Screen** | `lib/features/health/presentation/screens/period_tracker_screen.dart:511` | `bottom: 32.0` | **GAP (Clipping)** | Set `bottom: AppLayout.fabBottomPadding` (96.0) |
| **Filtered Notes Screen** | `lib/features/notes/presentation/screens/filtered_notes_screen.dart:263` | `bottom: 12.0` | **GAP (Clipping)** | Set `bottom: AppLayout.fabBottomPadding` (96.0) |

---

## 7. Rule 41 Unicode Emoji Glyph Replacement Matrix

| Offending File & Line | Current Text with Raw Unicode Emoji | Prescribed Semantic Text & Material Symbol Replacement |
|---|---|---|
| `lib/features/finances/presentation/screens/sms_rules_screen.dart:450` | `'🏷️ Title: ...'` | `Row(children: [Icon(Icons.label_outline_rounded, size: 14), Text(' Title: ...')])` |
| `lib/features/finances/presentation/screens/sms_rules_screen.dart:455` | `'📂 Category: ...'` | `Row(children: [Icon(Icons.folder_open_rounded, size: 14), Text(' Category: ...')])` |
| `lib/features/finances/presentation/screens/transaction_editor_screen.dart:563` | `'... Gemini Nano ✨'` | `'... Gemini Nano'` + `Icon(Icons.auto_awesome_rounded, size: 16, color: colorScheme.primary)` |
| `lib/features/finances/presentation/screens/financial_manager_screen.dart:639` | `'... Gemini Nano... ✨'` | `'... Gemini Nano...'` + `Icon(Icons.auto_awesome_rounded, size: 16, color: colorScheme.primary)` |
| `lib/features/finances/presentation/screens/financial_manager_screen.dart:655` | `'... with AI ✨!'` | `'... with AI!'` + `Icon(Icons.auto_awesome_rounded, size: 16, color: colorScheme.primary)` |
| `lib/features/finances/presentation/widgets/financial_ledger_tab.dart:227` | `'🏦 Savings • '` | `Row(children: [Icon(Icons.account_balance_rounded, size: 14), Text(' Savings • ')])` |
| `lib/features/settings/presentation/screens/onboarding_screen.dart:987` | `'Configure P2P Sync ➔'` | `Text('Configure P2P Sync')` + `Icon(Icons.arrow_forward_rounded, size: 16)` |
| `lib/widgets/whats_new_sheet.dart:35` | `"🌟 What's New"` | `Icon(Icons.auto_awesome_rounded, color: colorScheme.primary)` + `Text("What's New")` |
| `lib/widgets/whats_new_sheet.dart:57` | `"🚀 Improvements"` | `Icon(Icons.trending_up_rounded, color: colorScheme.secondary)` + `Text("Improvements")` |
| `lib/widgets/whats_new_sheet.dart:79` | `"🐛 Fixes"` | `Icon(Icons.bug_report_rounded, color: colorScheme.tertiary)` + `Text("Fixes")` |
| `lib/services/sms_service.dart:99, 675, 908` | `'💳 Expense Auto-Imported'`, `'💰 Income Auto-Imported'` | Notification titles: `'Expense Auto-Imported'`, `'Income Auto-Imported'` (clean plain text) |
| `lib/services/backup_service.dart:167` | `'📦 Auto-Backup Complete'` | Notification title: `'Auto-Backup Complete'` (clean plain text) |
| `lib/services/p2p_sync_service.dart:406–412` | `'📡 Syncing...'`, `'⏳ Waiting...'`, `'🔑 Pair error'`, `'⚠️ Failed'` | Clean status strings with accompanying Material Symbol icon bindings in presentation layer |
