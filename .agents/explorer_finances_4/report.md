# Finances & Split Bills Module — M3 Expressive & System Invariants Audit Report

**Date**: 2026-09-16  
**Auditor**: Finances Module Explorer (`explorer_finances_4`)  
**Target Module**: `lib/features/finances/` (Screens, Widgets, Providers, Data, Services) + Related Finance Dependencies  
**Parent Orchestrator**: `orchestrator_4` (`2a098395-618f-474c-b4b8-3e7cda1022cb`)  
**Mode**: Read-Only Non-Destructive Inspection (`git status` 100% pristine)  
**Overall Compliance Score**: **88%** (Grade: B+)

---

## 1. Executive Summary & Weighted Scorecard

A thorough, read-only architectural, design token, and code quality audit was performed across the entire Finances and Split Bills domain (`lib/features/finances/`, encompassing 33 Dart files and 16,305 lines of code) as well as its direct dependencies and external coupling (`lib/widgets/recurring_rules_sheet.dart`, `lib/widgets/sms_import_sheet.dart`, `lib/data/transaction_model.dart`, `lib/data/transaction_category.dart`, `lib/services/sms_service.dart`, `lib/services/sms_parser.dart`).

The evaluation was benchmarked against Google's Material 3 Expressive guidelines, single-source-of-truth tokens (`AppLayout`, `AppTheme`), and the 15 system invariants codified in `AGENTS.md`.

### Summary of Strengths:
- **100% Zero Frosted Blur / BackdropFilter Contamination**: Verified 0 occurrences of `BackdropFilter` or `ImageFilter.blur` across all 33 files. 100% pure solid surface container hierarchy (`surfaceContainerLowest` to `surfaceContainerHighest`).
- **100% `showCheckmark: false` Adherence**: Every single `FilterChip` and `ChoiceChip` (18/18 occurrences) strictly declares `showCheckmark: false`, keeping category and account avatars unblocked.
- **Top Header Symmetry & Cannonical Muscle Memory Sequence**: `financial_manager_screen.dart` strictly adheres to 16dp outer edge symmetry, 40x40 compact hit constraints, 60dp/72dp sub-pixel headroom, and the exact 4-slot top bar action hierarchy (`[ 🔍 Search ]` $\rightarrow$ `[ 🔄 Sync ]` $\rightarrow$ `[ ⋮ Tools ]` $\rightarrow$ `[ ⚙️ Settings ]`).
- **Standard FAB Bottom Clearance**: All 3 primary tabs (`financial_ledger_tab.dart`, `financial_analytics_tab.dart`, `split_bills_tab.dart`) consistently apply `AppLayout.fabBottomPadding = 96.0` to eliminate content clipping.
- **Robust Financial Domain Invariants**: Two-bank account model (`daily` vs `savings`), dual cash flow hero card calculations, 24-hour default SMS lookback, real-time sync banner with 1-tap cancellation, tombstone safety in `createSmsTransaction`, soft-delete undo parity (`restoreTransaction`), recurring rule propagation, and offline ML Kit OCR receipt parsing are fully operational.
- **Advanced M3 Expressive Adoption**: Proactive adoption of `ExpressiveWavyLinearProgress` in the SMS sync banner and `ExpressiveWavySlider` in `savings_goal_editor_sheet.dart`.

### Key Areas Requiring Alignment:
1. **Shape Scale Violations (Chips & Primary CTAs)**: Multiple buttons and chips use 8dp (`AppLayout.radiusS`) or 12dp (`AppLayout.radiusM`) or 16dp (`AppLayout.radiusL`) rounded rectangles instead of the M3 Expressive standard **1000dp Stadium pills** (`const StadiumBorder()` / `AppLayout.radiusStadium`).
2. **Rule 41 Parity (Raw Unicode Emojis in UI)**: Detected raw emojis in UI strings (`financial_ledger_tab.dart:227` contains `'🏦 Savings • '`; `sms_rules_screen.dart:750` contains `'🏷️ Title: '`).
3. **Touch Target Deficits (< 48x48dp)**: Color swatches in category/savings dialogs measure only 32x32dp or 36x36dp without 48dp gesture bounds. Category icon selection grids in 6-column layouts (~40dp) and hero card quick filter pills lack explicit 48dp minimum constraints.
4. **Sub-Screen App Bar Re-Export Stubs**: Sub-screens (`category_management_screen`, `sms_rules_screen`, `sms_contacts_screen`, `transaction_editor_screen`, `split_bill_editor_screen`) import `FrostedGlassSliverAppBar` through 1-line re-export stubs rather than directly importing `ExpressiveSliverAppBar`.
5. **State Duplication & Architectural Tech Debt**: `FinancialManagerScreen` is a monolithic 2,044-line widget managing its own `_transactions` state and direct SQLite queries, bypassing `FinancialManagerProvider`. A legacy 145-line `lib/widgets/recurring_rules_sheet.dart` coexists with the feature version (`lib/features/finances/presentation/widgets/recurring_rules_sheet.dart`).
6. **Generic Dollar Icons**: Amount fields in `split_bill_editor_screen.dart:630` and `receipt_scanner_sheet.dart:219` use generic `Icons.attach_money_rounded` instead of authentic user-configured currency symbols.

---

### Weighted Scorecard

| Evaluation Dimension | Weight | Score | Status | Key Highlights |
|---|---|---|---|---|
| **1. Surface Elevation Hierarchy & Zero Blurs** | 20% | **94%** | Highly Compliant | 0 `BackdropFilter` or `ImageFilter.blur` instances; pure solid surface containers (`surfaceContainerLow` to `surfaceContainerHighest`). Minor: few raw `Card` widgets instead of `AppCard`. |
| **2. Shape Scale Hierarchy** | 20% | **80%** | Deviations Present | Stadium pills used for scope pill, search bar, and sync banner. Multiple action buttons and chips use 8dp/12dp/16dp instead of `StadiumBorder()`. Modal sheet with 20dp in split bill editor. |
| **3. Motion, Physics & FAB Bottom Clearance** | 15% | **95%** | Highly Compliant | `AppLayout.fabBottomPadding = 96.0` enforced across all tabs; `AppMorphingFab` responds to scroll; donut charts enforce 1.5% minimum angle floor and bounded center text. |
| **4. Touch Targets & Accessibility (Rule 41)** | 15% | **84%** | Moderate Deviations | 40x40 compact top actions with 48x48 hitboxes. Deviations: 32x32dp color swatches, 6-col icon grids, hero quick account pills lack 48dp bounds; raw emojis in ledger and SMS rule titles. |
| **5. Top App Bar Invariants** | 15% | **90%** | Mostly Compliant | Canonical 4-slot order (`[ 🔍 Search ]`, `[ 🔄 Sync ]`, `[ ⋮ Tools ]`, `[ ⚙️ Settings ]`); left title + scope pill; 16dp outer symmetry; 60dp/72dp headroom. Deviation: sub-screens use re-export stub app bar. |
| **6. Financial Domain Invariants & Architecture** | 15% | **87%** | Architectural Debt | Perfect dual-account cash flow, tombstone guardrails, 24h SMS sync lookback, soft-delete undo parity, local OCR. Architectural debt: state duplication in `FinancialManagerScreen`, legacy duplicate recurring sheet. |
| **Overall Weighted Compliance Score** | **100%** | **88%** | **Grade: B+** | Solid foundational adherence; requires targeted shape scale polish, touch target bounds, emoji purging, and architectural decoupling. |

---

## 2. File Inventory & Status Matrix

Every file in `lib/features/finances/` (33 files, 16,305 lines) was cataloged and audited:

| # | File Path | Line Count | Layer | Compliance Status | Key Findings / Deviations |
|---|---|---|---|---|---|
| 1 | `presentation/screens/financial_manager_screen.dart` | 2,044 | Presentation (Screen) | Mostly Compliant (88%) | Canonical top app bar, 24h sync banner, dual account hero card. Monolithic state duplication; raw `showModalBottomSheet` at 394 & 1293; negative net cash flow light opacity is 0.45; account filter pills use 8dp squircle (<48dp). |
| 2 | `presentation/screens/transaction_editor_screen.dart` | 1,105 | Presentation (Screen) | Moderate Deviations (82%) | Recurring rule sync, AI description refine, authentic currency prefix. Chips use 8dp/12dp (`radiusS`/`radiusM`) instead of Stadium; 32dp color swatches in dialog; raw `AlertDialog` at 272 & 610; imports `FrostedGlassSliverAppBar` stub. |
| 3 | `presentation/screens/split_bill_editor_screen.dart` | 1,373 | Presentation (Screen) | Moderate Deviations (82%) | 0ms calculations, group tags, participant management. Chips and buttons use 8dp/12dp; generic `Icons.attach_money_rounded` at 630; raw `showModalBottomSheet` with 20dp radius at 234 & 291; imports `FrostedGlassSliverAppBar` stub. |
| 4 | `presentation/screens/category_management_screen.dart` | 944 | Presentation (Screen) | Moderate Deviations (83%) | `AppMorphingFab`, 96dp FAB padding. Uses raw `Card` instead of `AppCard`; raw `AlertDialog` at 64 & 126; 32dp color swatches without 48dp bounds; imports `FrostedGlassSliverAppBar` stub. |
| 5 | `presentation/screens/sms_rules_screen.dart` | 824 | Presentation (Screen) | Moderate Deviations (82%) | Daily sync manual trigger, rule test engine. Raw emoji `'🏷️'` at 750; raw `showModalBottomSheet` at 179; action buttons use 12dp rounded rectangle; uses raw `Card`; imports `FrostedGlassSliverAppBar` stub. |
| 6 | `presentation/screens/sms_contacts_screen.dart` | 303 | Presentation (Screen) | Mostly Compliant (86%) | Sender ID management, blocklist toggle. Uses raw `Card` instead of `AppCard`; imports `FrostedGlassSliverAppBar` stub from `lib/widgets/`. |
| 7 | `presentation/widgets/financial_ledger_tab.dart` | 260 | Presentation (Widget) | Mostly Compliant (88%) | `AppLayout.fabBottomPadding = 96.0`, `OpenContainer` transition, `AppCard`. Raw emoji `'🏦 '` in subtitle at 227; `OpenContainer` shape radius (12dp) conflicts with inner `AppCard` radius (16dp). |
| 8 | `presentation/widgets/financial_analytics_tab.dart` | 634 | Presentation (Widget) | Mostly Compliant (89%) | Donut chart with 1.5% angle floor & FittedBox; `AppCard`. Pill toggle options lack 48dp min constraints; `AnimatedSize` uses `Curves.easeInOutCubic` instead of spring physics. |
| 9 | `presentation/widgets/split_bills_tab.dart` | 1,022 | Presentation (Widget) | Mostly Compliant (88%) | Dynamic hero card opacities (0.20/0.50, 1.2px border); `showCheckmark: false`. Settle Up and Settle My Share buttons use 8dp squircle (`radiusS`) instead of Stadium; raw `Card` widgets. |
| 10 | `presentation/widgets/burn_rate_forecast_card.dart` | 319 | Presentation (Widget) | Highly Compliant (96%) | Strict `AppCard`, `AppChip`, semantic pacing indicators, 1.2px border, clean typography. |
| 11 | `presentation/widgets/category_budgets_card.dart` | 242 | Presentation (Widget) | Mostly Compliant (87%) | Dynamic budget progress, pacing warnings. `_showSetBudgetDialog` uses raw `AlertDialog`; row taps lack explicit 48dp hit constraints; standard progress bar could be wavy. |
| 12 | `presentation/widgets/savings_goals_card.dart` | 387 | Presentation (Widget) | Highly Compliant (94%) | `AppCard`, `AppChip`, `AppDialog.showConfirm`, responsive layout. Popup menu uses 12dp radius. |
| 13 | `presentation/widgets/savings_goal_editor_sheet.dart` | 574 | Presentation (Widget) | Mostly Compliant (87%) | `AppBottomSheet.show`, `ExpressiveWavySlider`. Chips use 8dp; color swatches (36dp) lack 48dp bounds; save button uses 12dp squircle instead of Stadium. |
| 14 | `presentation/widgets/savings_goal_deposit_sheet.dart` | 352 | Presentation (Widget) | Mostly Compliant (89%) | `AppBottomSheet.show`, authentic ledger integration. Confirm button uses 12dp squircle; raw `Card` liquidation box. |
| 15 | `presentation/widgets/recurring_rules_sheet.dart` | 594 | Presentation (Widget) | Mostly Compliant (88%) | `AppBottomSheet.show`, `showCheckmark: false`, dynamic category chips. Uses raw `Card` with 12dp radius at 529; duplicate legacy file exists in `lib/widgets/`. |
| 16 | `presentation/widgets/settle_up_sheet.dart` | 287 | Presentation (Widget) | Mostly Compliant (89%) | Strict cash flow contract, WhatsApp templates, `AppBottomSheet.show`. Action buttons use 12dp squircle instead of Stadium. |
| 17 | `presentation/widgets/receipt_scanner_sheet.dart` | 268 | Presentation (Widget) | Mostly Compliant (90%) | `AppBottomSheet.show`, `cacheWidth: 300`, `AppLockScreen.withLockIgnored`. Generic `Icons.attach_money_rounded` at 219 instead of authentic currency symbol. |
| 18 | `presentation/widgets/financial_trash_sheet.dart` | 282 | Presentation (Widget) | Highly Compliant (98%) | `AppBottomSheet.show`, `AppDialog.showConfirm`, 0ms optimistic UI, 48x48dp restore hit target, `restoreTransaction` parity. |
| 19 | `presentation/widgets/minimal_chart_deck.dart` | 982 | Presentation (Widget) | Highly Compliant (96%) | 1.5% donut angle floor, FittedBox center total, `LineTouchTooltipData` with 1px accent border, spring haptics. |
| 20 | `presentation/widgets/teach_sms_rule_sheet.dart` | 403 | Presentation (Widget) | Mostly Compliant (90%) | `AppBottomSheet.show`, `showCheckmark: false`. Save button uses 16dp squircle instead of Stadium. |
| 21 | `presentation/widgets/top_merchants_card.dart` | 141 | Presentation (Widget) | Highly Compliant (96%) | `AppCard`, ranked merchant list, bounded progress bars, clean typography. |
| 22 | `providers/financial_manager_provider.dart` | 187 | State Management | Moderate Deviations (82%) | MultiProvider registered. Lacks 0ms optimistic mutations (awaits SQLite then re-queries all); not consumed by `FinancialManagerScreen`. |
| 23 | `providers/savings_goal_provider.dart` | 101 | State Management | Mostly Compliant (88%) | MultiProvider registered, clean calculation getters. Lacks optimistic in-memory mutations before SQLite persistence. |
| 24 | `providers/split_bill_provider.dart` | 272 | State Management | Highly Compliant (96%) | MultiProvider registered, 0ms optimistic UI mutations on insert/update/delete/toggle, clean getters. |
| 25 | `data/transaction_repository.dart` | 493 | Data Access | Highly Compliant (96%) | SQLCipher WAL mode, tombstone protection (`bypassTombstones`), `restoreTransaction`, 30-day trash auto-cleanup. |
| 26 | `data/repositories/savings_goal_repository.dart` | 253 | Data Access | Highly Compliant (96%) | Soft-delete support, atomic deposit/withdrawal ledger syncing. |
| 27 | `data/repositories/split_bill_repository.dart` | 454 | Data Access | Highly Compliant (96%) | Soft-delete support, relational participant queries, summary metrics. |
| 28 | `data/models/savings_goal_model.dart` | 204 | Domain Model | Highly Compliant (100%) | Immutable, clean JSON/SQLite serialization, copyWith. |
| 29 | `data/models/split_bill_model.dart` | 283 | Domain Model | Highly Compliant (100%) | Immutable, relational participant mappings, cash flow getters. |
| 30 | `services/financial_export_service.dart` | 232 | Service | Highly Compliant (95%) | RFC 4180 CSV escaping, structured AI analysis prompts, `AppLockScreen.ignoreNextResumeLock()`. |
| 31 | `services/receipt_scanner_service.dart` | 180 | Service | Highly Compliant (95%) | 100% offline ML Kit text recognition, optional on-device Gemini Nano json extraction, regex fallback. |
| 32 | `services/spending_forecast_service.dart` | 236 | Service | Highly Compliant (98%) | Pure algorithmic daily burn rate, safe-to-spend, month-end projections. |
| 33 | `services/split_share_service.dart` | 98 | Service | Highly Compliant (95%) | WhatsApp template generation, clipboard copy, `AppLockScreen.ignoreNextResumeLock()`. |

### External Coupled Dependencies:
- `lib/widgets/recurring_rules_sheet.dart` (145 lines) — **Legacy Duplicate / Tech Debt**: Older version coexists with feature version; still imported by `settings_screen.dart` and `universal_search_overlay.dart`.
- `lib/widgets/sms_import_sheet.dart` (380 lines) — **Domain Location Violation**: Resides in generic `lib/widgets/` instead of `lib/features/finances/presentation/widgets/`.
- `lib/widgets/frosted_glass_sliver_app_bar.dart` (2 lines) — **Re-Export Stub Violation**: 1-line re-export forwarding to `frosted_sliver_app_bar.dart` which forwards to `expressive_sliver_app_bar.dart`.

---

## 3. In-Depth Evaluation against Invariants

### 3.1 Invariant 1: Single Source of Truth Theme & Core UI Primitives
* **Status**: **Mostly Compliant (87%)**
* **Surface Elevation Hierarchy (Zero Blurs)**:
  - An absolute `grep_search` confirmed **0 instances** of `BackdropFilter` and **0 instances** of `ImageFilter.blur` in `lib/features/finances/`.
  - Scaffolding uses transparent backgrounds, allowing the solid surface canvas to ground all views.
  - The 5-tier solid container scale is well utilized: `surfaceContainerLow` for headers, `surfaceContainer` for cards, `surfaceContainerHigh` for modal sheets and popup menus, `surfaceContainerHighest` for chips and inputs.
* **Shape Scale Hierarchy**:
  - **Stadium Pills (1000dp)**: Top Folder Scope Pill (`financial_manager_screen.dart:1210`), Search Bar capsule (`financial_manager_screen.dart:1088`), Sync progress banner (`financial_manager_screen.dart:1043`), and `AppChip` instances in `burn_rate_forecast_card.dart:106`.
  - **Squircles**: `AppCard` defaults to 16dp squircle (`AppLayout.radiusL`); `AppBottomSheet` enforces 28dp squircle (`AppLayout.radiusXXL`).
  - **Deviations**:
    - `transaction_editor_screen.dart:906, 916`: Category chips use `RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusS))` (8dp squircle) instead of `const StadiumBorder()`.
    - `transaction_editor_screen.dart:938`: ActionChip uses 12dp squircle (`AppLayout.radiusM`).
    - `split_bill_editor_screen.dart:654, 694`: Date button (12dp) and category chips (8dp).
    - `savings_goal_editor_sheet.dart:345, 492`: Month preset chips and category chips use 8dp (`AppLayout.radiusS`).
    - Primary CTA buttons (`Save Changes`, `Confirm Settle Up`, `Confirm Deposit`, `Save & Apply Rule`) in `savings_goal_editor_sheet.dart:561`, `settle_up_sheet.dart:206`, `savings_goal_deposit_sheet.dart:327`, and `teach_sms_rule_sheet.dart:393` use 12dp or 16dp rounded rectangles instead of `const StadiumBorder()`.
    - Modal bottom sheets in `split_bill_editor_screen.dart:314` hardcode `Radius.circular(AppLayout.radiusXL)` (20dp) instead of standard 28dp (`AppLayout.radiusXXL`).
* **Dynamic Hero Card Opacities**:
  - `split_bills_tab.dart:166`: `final heroAlpha = isDark ? 0.20 : 0.50;` with 1.2px accent border. Fully compliant with the 50%–55% light / 20%–22% dark standard.
  - `financial_manager_screen.dart:694-703`:
    - Positive cash flow: `tertiaryContainer` alpha is `0.55` in light mode, `0.22` in dark mode; border width 1.2. (Compliant).
    - Negative cash flow: `errorContainer` alpha is `0.45` in light mode (deviates slightly below the 0.50–0.55 standard) and `0.22` in dark mode.

---

### 3.2 Invariant 4: Authentic Currencies, SMS Deduplication, Dual Accounts & Recurring Sync
* **Status**: **Mostly Compliant (89%)**
* **Findings**:
  - **Authentic Currency Badges**: The top bar, ledger cards, hero cards, and analytics consistently render the authentic currency symbol (`$currency`, e.g. `Rs.`, `₹`, `$`, `€`).
    - *Deviation*: `split_bill_editor_screen.dart:630` and `receipt_scanner_sheet.dart:219` use generic `Icons.attach_money_rounded` for amount prefix icons instead of the active currency symbol.
  - **Two-Bank Account Model**: Transactions support explicit account tagging (`AccountType.daily` vs `AccountType.savings`). The hero card renders dual cash flow metrics (`${settings.account1Name}: $currency ${_dailyCashFlow}` vs `${settings.account2Name}: $currency ${_savingsVaultCashFlow}`), and allows 0ms filtering via interactive account pills (`financial_manager_screen.dart:893-970`).
  - **Recurring Rule Propagation**: `transaction_editor_screen.dart:150-170` updates the matching rule definition in `RecurringRuleRepository.instance.updateRule(updatedRule)` whenever an existing recurring transaction is modified.
  - **Tombstone Ingestion Guardrail**: `TransactionRepository.createSmsTransaction` (`transaction_repository.dart:29-48`) strictly queries `smsExists(smsId)` against active transactions and `deleted_transaction_sms_ids`, rejecting re-imports unless `bypassTombstones: true` is set.
  - **Soft-Delete Undo Parity**: All undo deletion handlers across `financial_manager_screen.dart:1933, 1955`, `transaction_editor_screen.dart:360`, `financial_trash_sheet.dart:211`, and `financial_manager_provider.dart:164` invoke `restoreTransaction(id)` (`UPDATE transactions SET deletedAt = NULL`), guaranteeing primary key integrity.
  - **SMS 24-Hour Default Lookback & Real-Time Sync Banner**: Scheduled and quick sync default to the last 24 hours. The persistent progress banner (`financial_manager_screen.dart:1035-1102`) renders directly below the top bar using solid `primaryContainer`, Stadium border, an animated `ExpressiveWavyLinearProgress`, and a 1-tap `[ Cancel ]` button calling `SmsService.cancelSync()`.

---

### 3.3 Invariant 8: Standard FAB Bottom Clearance & Universal Morphing Protocol
* **Status**: **Pass / Highly Compliant (95%)**
* **Findings**:
  - **FAB Clearance**: `AppLayout.fabBottomPadding = 96.0` is strictly enforced at the scroll termination of all primary views:
    - `financial_ledger_tab.dart:82`: `padding: const EdgeInsets.fromLTRB(16, 0, 16, AppLayout.fabBottomPadding)`
    - `financial_analytics_tab.dart:125`: `padding: const EdgeInsets.fromLTRB(16, 6, 16, AppLayout.fabBottomPadding)`
    - `split_bills_tab.dart:67`: `padding: const EdgeInsets.fromLTRB(AppLayout.spaceM, AppLayout.spaceS, AppLayout.spaceM, AppLayout.fabBottomPadding)`
    - `category_management_screen.dart:181`: `padding: const EdgeInsets.fromLTRB(16, 16, 16, AppLayout.fabBottomPadding)`
    - `transaction_editor_screen.dart:1080`: `const SizedBox(height: AppLayout.fabBottomPadding)`
  - **Universal Morphing FAB**: In `home_screen.dart:936`, `_buildFinancesFAB` renders `AppMorphingFab`, collapsing from stadium capsule into a 56x56dp circular FAB upon downward fling and expanding on upward scroll, with dynamic contextual switching between 'New Transaction' and 'New Split Bill'. Sub-screens (`category_management_screen.dart:318`, `split_bill_editor_screen.dart:572`, `transaction_editor_screen.dart:1088`) also utilize `AppMorphingFab`.
  - **Donut Chart Precision**:
    - `minimal_chart_deck.dart:714` and `financial_analytics_tab.dart:431` enforce the **1.5% minimum angle floor**: `entry.value.clamp(widget.totalExpense * 0.015, double.infinity)`.
    - Center hole totals are explicitly bounded inside `SizedBox(width: 52, height: 52)` with `FittedBox(fit: BoxFit.scaleDown)` (`minimal_chart_deck.dart:725-730`, `financial_analytics_tab.dart:451-456`), preventing numbers from touching chart rings.

---

### 3.4 Invariant 10: Touch Target Bounds & Semantic Labels (Rule 41)
* **Status**: **Moderate Deviations (84%)**
* **Findings**:
  - **Chart Tooltips**: `minimal_chart_deck.dart:499-506` specifies `LineTouchTooltipData` with `tooltipBorder: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3), width: 1.0)` and `tooltipRoundedRadius: AppLayout.radiusM`, complying with the 1px accent chart outline invariant.
  - **Top Action Hit Constraints**: All top bar buttons declare `constraints: const BoxConstraints(minWidth: 40, minHeight: 40)`, `visualDensity: VisualDensity.compact`, and `padding: EdgeInsets.zero`.
  - **Sync Cancel Button**: Enforces `constraints: const BoxConstraints(minWidth: 48, minHeight: 48)` and `Semantics(button: true)` (`financial_manager_screen.dart:1547`).
  - **Deviations**:
    - **Rule 41 Violations (Raw Text Emojis)**:
      - `financial_ledger_tab.dart:227`: `subtitle: Text('${transaction.account == AccountType.savings ? '🏦 Savings • ' : ''}...')`. Uses raw `'🏦'` emoji inside ledger transaction subtitles.
      - `sms_rules_screen.dart:750`: `Text('🏷️ Title: ${rule.customDescription}')`. Uses raw `'🏷️'` emoji in custom rule summaries.
    - **Touch Targets Below 48x48dp**:
      - `transaction_editor_screen.dart:681`: Color picker swatches render `CircleAvatar(radius: 16)` (32x32dp) wrapped in raw `GestureDetector` without 48dp hit bounds.
      - `category_management_screen.dart:555, 835`: Color swatches render `Container(width: 32, height: 32)` without 48dp bounds.
      - `savings_goal_editor_sheet.dart:517`: Color swatches render `Container(width: 36, height: 36)` without 48dp bounds.
      - `category_management_screen.dart:503, 783` and `transaction_editor_screen.dart:637`: 6-column icon selection grid renders touch targets measuring ~40x40dp without min 48dp wrappers.
      - `financial_manager_screen.dart:905, 943`: Dual account hero filter pills render with `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)` without a `minHeight: 48` constraint.
      - `financial_analytics_tab.dart:236`: `_pillOption` has only `vertical: 6` padding (~28dp total height) wrapped in raw `GestureDetector` without `Semantics(button: true)`.

---

### 3.5 Invariant 12: Split Bills & Shared Debts Domain Integration
* **Status**: **Pass / Highly Compliant (95%)**
* **Findings**:
  - **Modular Gating**: Gated by `settings.showSplitBills`. Conditionally integrated as the 3rd tab in `SegmentedButton` (`financial_manager_screen.dart:2016-2021`).
  - **Ledger Cash Flow Contract**:
    - When user pays for a group bill, master expense reflects the full receipt total.
    - Repayments settled in `SettleUpSheet` (`settle_up_sheet.dart:149-168`) record as `Income` in Daily Operating.
    - Friend-paid bills record personal liability only when the user settles their share (as `Expense`). Settlements between other parties are recorded purely in the Split tab without touching personal ledger tables (`settle_up_sheet.dart:125-147`).
  - **Offline OCR & Sharing**: Receipt scanning (`ReceiptScannerService`) operates locally via ML Kit with optional Gemini Nano assist. WhatsApp sharing (`SplitShareService`) produces clean text breakdowns.
  - **Resume Lock Bypass**: Handled properly via `AppLockScreen.withLockIgnored` in `receipt_scanner_sheet.dart:46`, `AppLockScreen.ignoreNextResumeLock()` in `split_share_service.dart:80, 88`, and `financial_export_service.dart:134`.

---

### 3.6 Invariant 13: Selection Controls Modernization & Legacy Dropdown Prohibition
* **Status**: **Pass / Highly Compliant (96%)**
* **Findings**:
  - **Zero Legacy Dropdowns**: Confirmed **0 instances** of `DropdownButton` or `DropdownButtonFormField` across the entire domain.
  - **Short Option Sets (2–4 choices)**: Implemented with `SegmentedButton<T>` (`financial_manager_screen.dart:2003-2040` for tabs; `transaction_editor_screen.dart:750` for expense/income toggle).
  - **Dynamic Filter Chips**: Category clouds sourced from `TransactionCategory.allNames`. 100% of selection chips declare `showCheckmark: false`.
  - **Chevron Modernization**: Standardized on `Icons.keyboard_arrow_down_rounded` (`financial_manager_screen.dart:1250`).

---

### 3.7 Invariant 14: Top App Bar Symmetry, Tonal Scope Pills, Search Integration & Action Order
* **Status**: **Mostly Compliant (90%)**
* **Findings**:
  - **Left Header Structure**: `Finances` (18pt bold `titleLarge`) paired directly with interactive Tonal Scope Pill `[ 📅 Date Range ▾ ]` below (`financial_manager_screen.dart:1195-1258`).
  - **Tonal Scope Pill Contrast Standard**: Uses `colorScheme.primaryContainer.withValues(alpha: isDark ? 0.35 : 0.45)`, `1.0px` primary outline border (`colorScheme.primary.withValues(alpha: 0.28)`), `Icons.calendar_today_outlined`, and `Icons.keyboard_arrow_down_rounded`.
  - **Action Bar Canonical Order**:
    1. `[ 🔍 Search ]` (`IconButton`, line 1262)
    2. `[ 🔄 Sync ]` (`BouncingWidget` quick/advanced sync, line 1278)
    3. `[ ⋮ Finances Tools ]` (`PopupMenuButton`, line 1321)
    4. `[ ⚙️ Settings ]` (`IconButton`, line 1462)
  - **Top Bar Search Integration**: Tapping search switches to `Ledger` tab, enters full-width search mode (`_isSearching`), eliminates inline search fields, and provides clear button (`financial_manager_screen.dart:1105-1180`).
  - **Edge Symmetry & Headroom**: 16dp horizontal padding with zero inner spacers; `toolbarHeight: MediaQuery.of(context).padding.top + 72.0` and inner container `height: 60.0`.
  - **Deviation**: Sub-screens (`category_management_screen.dart`, `sms_rules_screen.dart`, `sms_contacts_screen.dart`, `transaction_editor_screen.dart`, `split_bill_editor_screen.dart`) import `FrostedGlassSliverAppBar` through 1-line re-export stubs instead of directly importing `ExpressiveSliverAppBar` from `lib/core/ui/`.

---

### 3.8 Invariant 9 & Android Quality, Memory Optimization
* **Status**: **Pass / Highly Compliant (98%)**
* **Findings**:
  - **Bitmap Downsampling Bounds**: `receipt_scanner_sheet.dart:156-168` specifies bounded `cacheWidth: 300`, `fit: BoxFit.cover`, and an `errorBuilder` fallback container on `Image.file`.
  - **Stream/Timer Disposal**: All stream subscriptions (`_syncSubscription`, `_smsSyncSubscription` in `financial_manager_provider.dart:40-41`) and text controllers are disposed.

---

## 4. Specific Deviations & Technical Debt Catalog

| # | File Path | Line Range | Category | Observation & Current Code | Invariant / Target Standard | Severity | Recommended Token Replacement |
|---|---|---|---|---|---|---|---|
| 1 | `presentation/widgets/financial_ledger_tab.dart` | 227 | Rule 41 (Emoji) | `'${transaction.account == AccountType.savings ? '🏦 Savings • ' : ''}...'` | Invariant 10: Strictly replace raw emoji glyphs with Material Symbols or plain text labels | Medium | Remove raw `'🏦'`, render `AppChip` with `Icons.account_balance_rounded` or text label `'Savings • '` |
| 2 | `presentation/screens/sms_rules_screen.dart` | 750 | Rule 41 (Emoji) | `'🏷️ Title: ${rule.customDescription}'` | Invariant 10: Prohibition of raw text emojis in UI | Medium | Replace with `Icon(Icons.label_outline_rounded, size: 14)` + text |
| 3 | `presentation/screens/transaction_editor_screen.dart` | 906–907 | Shape Scale | `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusS))` (8dp) | Invariant 1: Stadium Pills (1000dp) standard for chips and tags | Medium | `shape: const StadiumBorder()` |
| 4 | `presentation/screens/transaction_editor_screen.dart` | 916–917 | Shape Scale | `ActionChip(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusS)))` | Invariant 1: Stadium Pills for ActionChips | Low | `shape: const StadiumBorder()` |
| 5 | `presentation/screens/transaction_editor_screen.dart` | 931 | Hardcoded Color | `Icon(Icons.auto_awesome, size: 16, color: Colors.amber)` | Invariant 1: Zero hardcoded colors; use theme tokens | Low | `color: colorScheme.tertiary` |
| 6 | `presentation/screens/transaction_editor_screen.dart` | 938 | Shape Scale | `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM))` (12dp) | Invariant 1: Stadium Pills for chips | Low | `shape: const StadiumBorder()` |
| 7 | `presentation/screens/transaction_editor_screen.dart` | 681–689 | Touch Target | `CircleAvatar(radius: 16)` (32x32dp) wrapped in raw `GestureDetector` | Invariant 10: Hit targets must be $\ge 48\times 48$dp with Semantics | Medium | Wrap in `ConstrainedBox(constraints: BoxConstraints(minWidth: 48, minHeight: 48))` + `Semantics(button: true)` |
| 8 | `presentation/screens/transaction_editor_screen.dart` | 634–668 | Touch Target | 6-column GridView for category icons (~40x40dp) | Invariant 10: Touch targets $\ge 48\times 48$dp | Low | Add 48dp minimum constraints or reduce to 5 columns |
| 9 | `presentation/screens/transaction_editor_screen.dart` | 272, 610 | Dialog Standards | Instantiates raw unstyled `AlertDialog` | Invariant 1: Use `AppDialog` with 28dp radius | Low | Refactor to `AppDialog` / `AppDialog.showConfirm` |
| 10 | `presentation/screens/split_bill_editor_screen.dart` | 630 | Authentic Currency | `prefixIcon: const Icon(Icons.attach_money_rounded)` | Invariant 4: Authentic currency symbol badges instead of generic dollar icons | Medium | Replace with `Text(settings.currency)` or currency avatar |
| 11 | `presentation/widgets/receipt_scanner_sheet.dart` | 219 | Authentic Currency | `prefixIcon: Icon(Icons.attach_money_rounded)` | Invariant 4: Authentic currency symbol badges | Medium | Replace with `Text(currency)` or authentic symbol |
| 12 | `presentation/screens/split_bill_editor_screen.dart` | 654 | Shape Scale | `OutlinedButton.icon` uses 12dp squircle (`radiusM`) | Invariant 1: Stadium pills for primary buttons | Low | `shape: const StadiumBorder()` |
| 13 | `presentation/screens/split_bill_editor_screen.dart` | 694–696 | Shape Scale | Category `FilterChip` uses 8dp squircle (`radiusS`) | Invariant 1: Stadium pills for filter chips | Medium | `shape: const StadiumBorder()` |
| 14 | `presentation/screens/split_bill_editor_screen.dart` | 314 | Sheet Radius | `BorderRadius.vertical(top: Radius.circular(AppLayout.radiusXL))` (20dp) | Invariant 1: Bottom sheets enforce 28dp (`AppLayout.radiusXXL`) | Low | Replace with `AppBottomSheet` or 28dp |
| 15 | `presentation/screens/split_bill_editor_screen.dart` | 234, 291 | Bottom Sheet | Direct `showModalBottomSheet` calls | Invariant 1: Standardize on `AppBottomSheet` | Low | Migrate to `AppBottomSheet.show` |
| 16 | `presentation/widgets/split_bills_tab.dart` | 527, 813 | Shape Scale | Settle Up buttons use 8dp squircle (`radiusS`) | Invariant 1: Stadium pills for action buttons | Medium | `shape: const StadiumBorder()` |
| 17 | `presentation/screens/category_management_screen.dart` | 194–204 | Component Library | Uses raw `Card` with hardcoded border styling | Invariant 1: Always use `AppCard` from `lib/core/ui/` | Low | Replace `Card` with `AppCard` |
| 18 | `presentation/screens/category_management_screen.dart` | 64, 126 | Dialog Standards | Raw `AlertDialog` for reset & delete category | Invariant 1: Always use `AppDialog.showConfirm` | Low | Replace with `AppDialog.showConfirm` |
| 19 | `presentation/screens/category_management_screen.dart` | 555, 835 | Touch Target | Category color swatches measure 32x32dp | Invariant 10: Tap targets $\ge 48\times 48$dp | Medium | Wrap in 48x48dp constrained gesture boxes |
| 20 | `presentation/screens/financial_manager_screen.dart` | 696 | Hero Opacity | Negative cash flow light container alpha is `0.45` | Invariant 1: Dynamic Hero Card Opacities: 50%–55% Light Mode | Low | Change `0.45` to `0.52` or `0.55` |
| 21 | `presentation/screens/financial_manager_screen.dart` | 904, 942 | Shape Scale & Touch | Hero account filter pills use 8dp squircle (<48dp) | Invariant 1 & 10: Stadium pills with $\ge 48$dp tap targets | Medium | Use `AppLayout.radiusStadium` + `minHeight: 48` |
| 22 | `presentation/screens/financial_manager_screen.dart` | 394, 1293 | Bottom Sheet | Raw `showModalBottomSheet` without `AppBottomSheet` | Invariant 1: Always use `AppBottomSheet` | Low | Migrate to `AppBottomSheet.show` |
| 23 | `presentation/widgets/financial_analytics_tab.dart` | 155 | Motion Curve | `AnimatedSize(curve: Curves.easeInOutCubic)` | Invariant 1: Velocity-aware spring physics or `curveEmphasizedDecelerate` | Low | Use `AppLayout.curveEmphasizedDecelerate` |
| 24 | `presentation/widgets/financial_analytics_tab.dart` | 236 | Touch Target | `_pillOption` has only 6dp vertical padding (<30dp) | Invariant 10: Touch targets $\ge 48\times 48$dp | Low | Add `constraints: BoxConstraints(minHeight: 48)` |
| 25 | `presentation/widgets/category_budgets_card.dart` | 33 | Dialog Standards | Raw `AlertDialog` for set monthly budget | Invariant 1: Standardize dialogs on `AppDialog` | Low | Refactor to `AppDialog` |
| 26 | `presentation/widgets/category_budgets_card.dart` | 156 | Touch Target | Budget item rows lack explicit 48dp minimum bounds | Invariant 10: Enforce $\ge 48$dp touch targets | Low | Wrap in `ConstrainedBox(constraints: BoxConstraints(minHeight: 48))` |
| 27 | `presentation/widgets/savings_goal_editor_sheet.dart` | 345, 492 | Shape Scale | Preset month chips and category chips use 8dp | Invariant 1: Stadium pills for chips | Medium | `shape: const StadiumBorder()` |
| 28 | `presentation/widgets/savings_goal_editor_sheet.dart` | 517 | Touch Target | Color swatches measure 36x36dp without 48dp wrapper | Invariant 10: Touch targets $\ge 48\times 48$dp | Low | Wrap in 48x48dp hit box |
| 29 | `presentation/widgets/savings_goal_editor_sheet.dart` | 561 | Shape Scale | Save Goal button uses 12dp squircle (`radiusM`) | Invariant 1: Stadium pills for primary CTAs | Medium | `shape: const StadiumBorder()` |
| 30 | `presentation/widgets/savings_goal_deposit_sheet.dart` | 327 | Shape Scale | Confirm Deposit button uses 12dp squircle | Invariant 1: Stadium pills for primary CTAs | Medium | `shape: const StadiumBorder()` |
| 31 | `presentation/widgets/settle_up_sheet.dart` | 189, 206 | Shape Scale | Send Reminder and Settle Up buttons use 12dp | Invariant 1: Stadium pills for primary CTAs | Medium | `shape: const StadiumBorder()` |
| 32 | `presentation/widgets/teach_sms_rule_sheet.dart` | 394 | Shape Scale | Save Rule button uses 16dp squircle (`radiusL`) | Invariant 1: Stadium pills for primary CTAs | Medium | `shape: const StadiumBorder()` |
| 33 | `presentation/screens/sms_rules_screen.dart` | 172, 189 | Shape Scale | Outlined/Filled shortcut buttons use 12dp squircle | Invariant 1: Stadium pills for action buttons | Low | `shape: const StadiumBorder()` |
| 34 | `presentation/widgets/recurring_rules_sheet.dart` | 529 | Component Library | Uses raw `Card` instead of `AppCard` | Invariant 1: Always use `AppCard` | Low | Replace `Card` with `AppCard` |
| 35 | Multiple sub-screens (5 files) | Various | Re-export Stubs | Import `FrostedGlassSliverAppBar` from `lib/widgets/` | Invariant 2 & 14: Direct imports from `lib/core/ui/expressive_sliver_app_bar.dart` | Medium | Update imports to `ExpressiveSliverAppBar` |
| 36 | `lib/widgets/recurring_rules_sheet.dart` | 1–145 | Architectural Debt | Legacy duplicate file coexists with feature sheet | Invariant 2: Domain Modularization & Single Source | High | Delete legacy file; update `universal_search_overlay` and `settings_screen` imports to feature version |
| 37 | `lib/widgets/sms_import_sheet.dart` | 1–380 | Architectural Debt | Domain finance widget located in root `lib/widgets/` | Invariant 2: Domain Modularization | Medium | Move to `lib/features/finances/presentation/widgets/` |
| 38 | `presentation/screens/financial_manager_screen.dart` | 55 | Architectural Debt | Screen maintains independent `_transactions` state | Invariant 2: Decoupled Providers & Single Source of Truth | High | Refactor screen to consume `FinancialManagerProvider` reactively |
| 39 | `providers/financial_manager_provider.dart` | 154–177 | 0ms Optimistic UI | Delete/restore waits for SQLite then reloads from DB | R4: Synchronous in-memory mutation before DB persistence | High | Add optimistic list mutations in provider methods |

---

## 5. Actionable Implementation Recommendations

### Phase 1: M3 Expressive Tokens, Shape Scale & Accessibility Polish (Zero-Risk UI Refinements)
1. **Rule 41 Purging**:
   - `financial_ledger_tab.dart:227`: Remove raw `'🏦'` emoji from transaction subtitle string. Replace with a tonal semantic badge or text label `'Savings • '`.
   - `sms_rules_screen.dart:750`: Remove raw `'🏷️'` emoji; render `Icon(Icons.label_outline_rounded, size: 14)`.
2. **Shape Scale Normalization (Stadium Pills)**:
   - Upgrade all selection chips (`FilterChip`, `ChoiceChip`) across `transaction_editor_screen.dart`, `split_bill_editor_screen.dart`, and `savings_goal_editor_sheet.dart` to `shape: const StadiumBorder()`.
   - Convert primary and secondary action buttons (`Save Changes`, `Confirm Deposit`, `Confirm Settle Up`, `Settle Up`, `Settle My Share`, `Save & Apply Rule`) to `shape: const StadiumBorder()`.
   - Update quick account filter pills in `FinancialHeroCard` (`financial_manager_screen.dart:904, 942`) to `AppLayout.radiusStadium`.
3. **Touch Target Enforcement ($\ge 48\times 48\text{dp}$)**:
   - Wrap 32x32dp and 36x36dp color swatches in `transaction_editor_screen.dart`, `category_management_screen.dart`, and `savings_goal_editor_sheet.dart` with `BoxConstraints(minWidth: 48, minHeight: 48)` and `Semantics(button: true)`.
   - Add `BoxConstraints(minHeight: 48)` to `_pillOption` in `financial_analytics_tab.dart` and the dual account filter pills in `financial_manager_screen.dart`.
4. **Authentic Currency Prefix Icons**:
   - Replace generic `Icons.attach_money_rounded` in `split_bill_editor_screen.dart:630` and `receipt_scanner_sheet.dart:219` with the authentic user currency symbol.
5. **Direct Header Imports**:
   - Replace `import '.../widgets/frosted_glass_sliver_app_bar.dart'` with `import '.../core/ui/expressive_sliver_app_bar.dart'` across `category_management_screen.dart`, `sms_rules_screen.dart`, `sms_contacts_screen.dart`, `transaction_editor_screen.dart`, and `split_bill_editor_screen.dart`.
6. **Hero Card Light Opacity Alignment**:
   - Adjust negative net cash flow light mode container alpha in `financial_manager_screen.dart:696` from `0.45` to `0.52`.

### Phase 2: Component Library & Architectural Cleanup (Domain Decoupling)
1. **Eliminate Duplicate `RecurringRulesSheet`**:
   - Update `lib/widgets/home/universal_search_overlay.dart` and `lib/features/settings/presentation/screens/settings_screen.dart` to import `lib/features/finances/presentation/widgets/recurring_rules_sheet.dart`.
   - Safely remove the legacy 145-line `lib/widgets/recurring_rules_sheet.dart`.
2. **Relocate `sms_import_sheet.dart`**:
   - Move `lib/widgets/sms_import_sheet.dart` into `lib/features/finances/presentation/widgets/` to satisfy Invariant 2 domain modularization.
3. **Standardize on `AppBottomSheet` and `AppDialog`**:
   - Refactor raw `showModalBottomSheet` calls in `financial_manager_screen.dart:394, 1293` and `split_bill_editor_screen.dart:234, 291` to `AppBottomSheet.show(...)`.
   - Replace raw `AlertDialog` instances in `transaction_editor_screen.dart:272, 610`, `category_management_screen.dart:64, 126, 466, 749`, and `category_budgets_card.dart:33` with `AppDialog` and `AppDialog.showConfirm`.
4. **Replace Raw `Card` with `AppCard`**:
   - Migrate raw `Card` occurrences in `category_management_screen.dart:194`, `recurring_rules_sheet.dart:529`, `sms_rules_screen.dart:200, 777`, `sms_contacts_screen.82, 222`, and `savings_goal_deposit_sheet.dart:250` to `AppCard`.

### Phase 3: Reactive State Unification & 0ms Optimistic UI (Core Stability)
1. **Unify `FinancialManagerScreen` with `FinancialManagerProvider`**:
   - Deprecate internal `_transactions` list and manual SQLite queries in `FinancialManagerScreen`.
   - Refactor the screen to consume `FinancialManagerProvider` reactively via `Consumer<FinancialManagerProvider>`, eliminating 300+ lines of duplicated query, filter, and cash flow calculation code.
2. **0ms Immediate State Mutation in `FinancialManagerProvider`**:
   - Update `addTransaction`, `deleteTransaction`, and `restoreTransaction` in `FinancialManagerProvider` to execute synchronous in-memory list mutations and trigger `notifyListeners()` before executing the background SQLite write, matching the robust optimistic pattern established in `SplitBillProvider`.
