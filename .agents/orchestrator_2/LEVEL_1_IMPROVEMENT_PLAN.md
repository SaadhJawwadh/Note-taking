# Everything App — Level 1 Master Improvement Plan
## Cross-Domain Audit & Modernization Blueprint: Finances & Health/Periods

**Document Version**: 1.0.0  
**Author**: Project Orchestrator (`orchestrator_2`)  
**Audit Contributors**: `explorer_finances_2` & `explorer_health_2`  
**Date**: 2026-09-07T23:25:00+05:30  
**Target Modules**: `lib/features/finances/` & `lib/features/health/`  
**Scope Status**: Level 1 (Foundational, High-Impact, Low-Risk Enhancements Ready for Implementation)  

---

## 1. Executive Summary

A parallel multi-module audit of the **Finances** (`lib/features/finances/`) and **Periods & Health** (`lib/features/health/`) domains was conducted by two dedicated codebase exploration subagents (`explorer_finances_2` and `explorer_health_2`). Both modules exhibit strong underlying architectural foundations:
- **Finances**: Offline SQLCipher encrypted storage, dual-account ledger accounting (`AccountType.daily` vs `AccountType.savings`), 24-hour default SMS scan engine with tombstone checks and non-blocking chunking, two-way recurring rule propagation, 100% offline receipt OCR with bitmap downsampling (`cacheWidth: 300`), and full P2P sync / JSON backup serialization.
- **Periods & Health**: Rolling average cycle predictions with statistical outlier rejection ($15 \le \text{days} \le 60$), encrypted local persistence, discreet privacy-first notification text, and M3 borderless header chrome.

However, the deep investigation revealed critical **Level 1 deficiencies** across both domains:
1. **Algorithmic Discrepancies & Calculation Bugs**:
   - In Health, an overdue cycle modulo calculation (`(diff % _avgCycleLength) + 1`) causes late periods to cycle back to Day 1–5 Menstrual Phase while simultaneously flagging overdue status.
   - An internal contradiction between the in-app Phase Guide dialog (Days 6–13, 14–16) and provider phase calculations (Days 6–11, 12–16).
   - Hardcoded Days 12–16 Ovulatory Phase disconnected from dynamic cycle lengths (e.g., 22-day or 36-day cycles).
2. **Data Integrity & P2P Sync Tombstone Deficiencies**:
   - `PeriodLog` records lack soft-delete columns (`deletedAt`) and tombstone tables (`deleted_period_logs`). Deleting a log on Device A causes P2P sync with Device B to unconditionally resurrect the deleted log.
3. **Hardcoded Currency Assumptions**:
   - Split Bills and export services hardcode Sri Lankan Rupee (`'Rs.'`), failing to dynamically reflect user preferences when `settings.currency` is set to USD (`$`), EUR (`€`), GBP (`£`), or INR (`₹`).
4. **Master Invariant & Design System Violations (`AGENTS.md`)**:
   - **Static Colors (Invariant 1)**: Extensive use of raw `Colors.green`, `Colors.red`, `Colors.orange`, `Colors.teal`, and `Colors.pinkAccent` instead of `colorScheme` tokens or `AppSemanticColors`.
   - **Hero Card Container Opacity (Invariant 1 & Rule 42)**: `CyclePhaseHeroCard` uses `0.45` alpha in Light Mode instead of the mandated `0.50–0.55` (50%–55%).
   - **Touch Target Accessibility (Invariant 10)**: Multiple interactive elements ("Details >", pagination dots, "Restore", "Delete X", sync banner "Cancel", flow intensity selectors) fall below the mandated $48 \times 48\text{dp}$ touch target threshold.
   - **FAB Clearance (Invariant 8)**: `SplitBillsTab` ListView lacks `AppLayout.fabBottomPadding = 96.0`, obscuring bottom split bill cards.
   - **UI Primitives (Invariant 1)**: Widespread raw Flutter `Card` usage instead of atomic `AppCard` / `AppCard.tonal`.
   - **Raw Text Emojis (Invariant 10 / Rule 41)**: Raw Unicode glyphs (`✨`, `🏷️`, `📂`, `🏦`) embedded in UI labels.

This master plan structures all findings into prioritized, isolated Level 1 work packages complete with file paths, line citations, proposed technical solutions, and objective verification criteria.

---

## 2. Invariant Compliance Audit Matrix

| AGENTS.md Invariant | Finances Module Status | Health Module Status | System Finding & Impact |
|---|---|---|---|
| **Invariant 1: Token Usage & UI Primitives** | ⚠️ Partial Violation | ⚠️ Partial Violation | Raw `Card` used in 11+ locations. Static colors (`Colors.green`, `Colors.red`, etc.) clash with OLED pitch-black and dynamic wallpaper schemes. Hero card alpha in Health is `0.45` (must be `0.50–0.55`). Magic padding numbers (`20.0`) in hero card. |
| **Invariant 4: Currencies, Deduplication & Accounts** | ⚠️ Partial Violation | N/A | Core ledger correctly handles two-bank accounts and 24h SMS scan, but Split Bills hardcodes `'Rs.'` across 8+ UI files, ignoring user-configured currency. |
| **Invariant 6: Zero-Cloud P2P Sync & Tombstones** | ✅ Compliant | ❌ Violation | Split Bills and Finances enforce tombstone tables and LWW. Health `period_logs` has no `deletedAt` or `deleted_period_logs`, resulting in log resurrection on 2-way sync. |
| **Invariant 8: FAB Clearance & Morphing** | ⚠️ Partial Violation | ✅ Compliant | `SplitBillsTab` list applies only $8.0\text{dp}$ bottom padding instead of `AppLayout.fabBottomPadding = 96.0`. Bottom bill cards are obscured by the FAB. |
| **Invariant 9: Memory Downsampling** | ✅ Compliant | ✅ Compliant | Receipt scanner enforces `cacheWidth: 300` and provides `errorBuilder`. `MoonPhaseWidget` needs `RepaintBoundary` to prevent canvas repainting during scroll. |
| **Invariant 10: Touch Targets ($\ge 48\times 48\text{dp}$) & Rule 41** | ⚠️ Partial Violation | ⚠️ Partial Violation | "Details >", pagination dots, trash actions, sync banner "Cancel", and flow intensity options fall below $48\times 48\text{dp}$. Raw text emojis (`✨`, `🏷️`, `📂`, `🏦`) violate Rule 41. |
| **Invariant 14: Top Bar Symmetry & Scope Pills** | ✅ Compliant | ⚠️ Partial Violation | Health top bar scope pill `[ 🌸 Day X • Phase ]` is static and non-interactive (fails to open phase guide). Secondary FAB action is a no-op dummy tap. |

---

## 3. Prioritized Level 1 Work Packages — Finances Module

### Package FN-01: Dynamic Currency Synchronization in Split Bills & Exports
* **Category**: Logic & Invariant Compliance
* **Severity / Priority**: High (Level 1)
* **Target Files & Lines**:
  - `lib/features/finances/presentation/widgets/split_bills_tab.dart:191, 192, 238, 286, 476, 645`
  - `lib/features/finances/presentation/widgets/settle_up_sheet.dart:105`
  - `lib/features/finances/presentation/screens/split_bill_editor_screen.dart:563, 641, 642`
  - `lib/features/finances/services/split_share_service.dart:11, 55, 72`
  - `lib/features/finances/services/financial_export_service.dart:64, 113, 146`
* **Problem Description**:
  The user can configure 14 global currencies in `SettingsProvider.currency` (e.g. `USD ($)`, `EUR (€)`, `GBP (£)`, `INR (₹)`). While the main ledger adapts dynamically, the Split Bills module and export services interpolate hardcoded `'Rs.'` strings (`'+Rs. ${net}'`, `'Rs. ${bill.totalAmount}'`, `currencySymbol = 'Rs.'`). When non-LKR currencies are selected, split bill screens display conflicting currency symbols.
* **Proposed Technical Solution**:
  1. In `SplitBillsTab`, read `final currency = context.select<SettingsProvider, String>((s) => s.currencySymbol);` (or pass `settings.currencySymbol`). Replace all string literals `'Rs.'` with `'$currency'`.
  2. In `SettleUpSheet:105`, read `context.read<SettingsProvider>().currencySymbol` and render `'$currency ${absAmount.toStringAsFixed(2)}'`.
  3. In `SplitBillEditorScreen:563, 641`, bind share previews and remaining allocation amounts to the active currency symbol.
  4. In `SplitShareService` and `FinancialExportService`, pass the current currency symbol as a required argument or default to the user's active setting rather than `'Rs.'`.
* **Verification Criteria**:
  - **Widget Test**: Update `test/split_bill_features_test.dart` to initialize `SettingsProvider` with `currency = 'USD ($)'` and `'EUR (€)'`. Pump `SplitBillsTab`, `SplitBillEditorScreen`, and `SettleUpSheet`. Assert that `find.textContaining('Rs.')` finds 0 occurrences, while `find.textContaining('\$')` or `find.textContaining('€')` matches all balance metrics.

---

### Package FN-02: Material 3 Semantic Colors & Zero-Hardcoded-Color Parity
* **Category**: UI/UX & Design Tokens
* **Severity / Priority**: High (Level 1)
* **Target Files & Lines**:
  - `lib/features/finances/presentation/widgets/split_bills_tab.dart:194, 196, 214, 216, 223, 228, 241, 443, 449, 482, 658, 668, 700, 705, 714, 724, 860, 864, 873, 883`
  - `lib/features/finances/presentation/widgets/settle_up_sheet.dart:74, 78, 86, 91, 108`
  - `lib/features/finances/presentation/widgets/burn_rate_forecast_card.dart:24-28`
  - `lib/features/finances/presentation/widgets/category_budgets_card.dart:131, 133, 135, 137, 141`
  - `lib/features/finances/presentation/screens/split_bill_editor_screen.dart:682`
* **Problem Description**:
  Static colors (`Colors.green`, `Colors.red`, `Colors.orange`, `Colors.teal`) are hardcoded directly in containers, text, and avatars. In dynamic Material You palettes and dark OLED mode, these raw colors cause visual clashing, low contrast ratios, and harsh glare.
* **Proposed Technical Solution**:
  1. Settle Up and Split Bills:
     - Map positive balances / credit to `colorScheme.tertiary` or `Theme.of(context).extension<AppSemanticColors>()?.success ?? colorScheme.tertiary`.
     - Map negative balances / debt to `colorScheme.error`.
     - Replace translucent container fills with `colorScheme.tertiaryContainer.withValues(alpha: isDark ? 0.20 : 0.40)`.
  2. `BurnRateForecastCard`:
     - Replace static colors with semantic token mapping:
       * `underPace` $\rightarrow$ `colorScheme.primary`
       * `onTrack` $\rightarrow$ `colorScheme.tertiary`
       * `overPace` $\rightarrow$ `colorScheme.errorContainer`
       * `exhausted` $\rightarrow$ `colorScheme.error`
       * `noBudget` $\rightarrow$ `colorScheme.outline`
  3. `CategoryBudgetsCard`:
     - Replace `Colors.orange` and `Colors.teal` with `colorScheme.error`, `colorScheme.tertiary`, and `colorScheme.primary`.
* **Verification Criteria**:
  - **Static Analysis & Test**: Run `flutter analyze lib/features/finances`. Verify zero instances of `Colors.green`, `Colors.red`, `Colors.orange`, `Colors.teal` in `split_bills_tab.dart`, `settle_up_sheet.dart`, `burn_rate_forecast_card.dart`, and `category_budgets_card.dart`.
  - **Widget Test**: Pump `BurnRateForecastCard` and `CategoryBudgetsCard` in both light and dark theme contexts. Verify all progress bars and status indicators resolve valid `colorScheme` colors.

---

### Package FN-03: Touch Target Accessibility ($\ge 48\times 48\text{dp}$) & FAB Clearance
* **Category**: UI/UX & Invariant Compliance
* **Severity / Priority**: Medium (Level 1)
* **Target Files & Lines**:
  - `lib/features/finances/presentation/widgets/split_bills_tab.dart:63`
  - `lib/features/finances/presentation/widgets/minimal_chart_deck.dart:158-183, 216-245, 501`
  - `lib/features/finances/presentation/widgets/financial_trash_sheet.dart:199-230, 232-254`
  - `lib/features/finances/presentation/screens/financial_manager_screen.dart:895-969, 1205-1258, 1523-1539`
* **Problem Description**:
  1. `SplitBillsTab:63` applies only $8.0\text{dp}$ bottom padding to its `ListView`, violating Invariant 8 (`AppLayout.fabBottomPadding = 96.0`) and obscuring bottom cards behind the FAB.
  2. Multiple interactive micro-actions ("Details >", pagination dots, "Restore", "Delete X", sync banner "Cancel", and filter badges) have rendered heights between $22\text{dp}$ and $28\text{dp}$ without bounding constraints, violating Invariant 10 ($\ge 48\times 48\text{dp}$).
  3. `MinimalChartDeck:501` hardcodes `tooltipRoundedRadius: 10` instead of `AppLayout.radiusM` ($12.0\text{dp}$).
* **Proposed Technical Solution**:
  1. In `SplitBillsTab:63`, update padding:
     `padding: const EdgeInsets.fromLTRB(AppLayout.spaceM, AppLayout.spaceS, AppLayout.spaceM, AppLayout.fabBottomPadding)`.
  2. In `MinimalChartDeck`:
     - Lines 158-183: Wrap "Details >" link in `ConstrainedBox(constraints: const BoxConstraints(minHeight: 48, minWidth: 48))` with `alignment: Alignment.centerRight`.
     - Lines 216-245: Wrap pagination indicator dots in `SizedBox(width: 48, height: 48, child: Center(child: ...))` with `Semantics(button: true)`.
     - Line 501: Set `tooltipRoundedRadius: AppLayout.radiusM`.
  3. In `FinancialTrashSheet`:
     - Lines 199-230: Wrap "Restore" button in `ConstrainedBox(constraints: const BoxConstraints(minHeight: 48))`.
     - Lines 232-254: Wrap permanent delete icon in `IconButton(constraints: const BoxConstraints(minWidth: 48, minHeight: 48), ...)` with `Semantics(button: true, label: 'Permanently delete transaction')`.
  4. In `FinancialManagerScreen`:
     - Lines 1523-1539: Apply `BoxConstraints(minWidth: 48, minHeight: 48)` on the sync banner "Cancel" button.
     - Lines 895-969: Apply `BoxConstraints(minHeight: 48)` on the Daily Operating and Savings Vault filter badges.
* **Verification Criteria**:
  - **Widget Test**: Assert `tester.getSize(find.text('Details >')).height >= 48.0`.
  - **Widget Test**: Assert `tester.getSize(find.bySemanticsLabel('Switch to Expense Breakdown chart')).height >= 48.0`.
  - **Widget Test**: Verify `SplitBillsTab`'s underlying `ListView` has `padding.bottom == 96.0`.

---

### Package FN-04: Atomic UI Modernization (`AppCard`) & Rule 41 Emoji Cleansing
* **Category**: Invariant Compliance & Architecture
* **Severity / Priority**: Medium (Level 1)
* **Target Files & Lines**:
  - `lib/features/finances/presentation/screens/financial_manager_screen.dart:688`
  - `lib/features/finances/presentation/screens/sms_rules_screen.dart:200, 252, 278, 450, 455, 538, 608, 734, 761`
  - `lib/features/finances/presentation/screens/sms_contacts_screen.dart:82, 222`
  - `lib/features/finances/presentation/screens/category_management_screen.dart:194`
  - `lib/features/finances/presentation/widgets/recurring_rules_sheet.dart:529`
  - `lib/features/finances/presentation/screens/transaction_editor_screen.dart:563`
  - `lib/features/finances/presentation/widgets/financial_ledger_tab.dart:227`
* **Problem Description**:
  1. Raw Flutter `Card` widgets are used in multiple settings and dialog screens rather than the centralized `AppCard` primitive from `lib/core/ui/app_card.dart`.
  2. Raw text emojis (`✨`, `🏷️`, `📂`, `🏦`) are embedded in UI strings and badges, violating Invariant 10 (Rule 41).
* **Proposed Technical Solution**:
  1. Refactor raw `Card` containers to `AppCard` or `AppCard.tonal`.
  2. In `TransactionEditorScreen:563`, replace `'Refined title & category with Gemini Nano ✨'` with `'Refined title & category with Gemini Nano'`.
  3. In `SmsRulesScreen:450, 455, 734`, replace text emojis `'🏷️ Title:'` and `'📂 Category:'` with structured `Row` widgets pairing `Icon(Icons.label_outline_rounded, size: 14)` and `Icon(Icons.category_outlined, size: 14)` with plain text labels.
  4. In `FinancialLedgerTab:227`, replace `'${transaction.account == AccountType.savings ? '🏦 Savings • ' : ''}'` with an `AppChip` or `Icon(Icons.account_balance_outlined, size: 12)` badge.
* **Verification Criteria**:
  - **Static Regex Check**: Search `lib/features/finances` for raw Unicode emojis in user-facing `Text` and `SnackBar` widgets; verify 0 matches.
  - **Widget Test**: Pump `SmsRulesScreen` and `FinancialLedgerTab`; verify cards render with `AppCard` styling and Material icons.

---

## 4. Prioritized Level 1 Work Packages — Periods & Health Module

### Package HT-01: Dynamic Phase Calculation & Overdue Modulo Safeguard
* **Category**: Logic & Medical Accuracy
* **Severity / Priority**: Critical (Level 1)
* **Target Files & Lines**:
  - `lib/features/health/providers/period_tracker_provider.dart:60-91`
  - `lib/services/period_prediction_service.dart:37, 53-65, 180-210`
* **Problem Description**:
  1. **Overdue Modulo Reset Bug**:
     In `PeriodTrackerProvider:74-76`:
     ```dart
     final diff = todayUtc.difference(startUtc).inDays;
     final cycleDay = (diff % _avgCycleLength) + 1;
     _currentCycleDay = cycleDay;
     ```
     When a period is overdue (e.g., `diff = 32` days on a 28-day cycle), `32 % 28 = 4`, setting `cycleDay = 5`. The user is told they are on **Day 5 • Menstrual Phase** ("Flow begins..."), while the bottom status simultaneously displays "Period overdue by 4 days".
  2. **Negative Diff Bug**:
     If `startUtc` is in the future (e.g. tomorrow due to timezone or clock skew), `diff < 0`. In Dart, `-1 % 28` is `-1`, resulting in `cycleDay = 0` (falling through to Luteal Phase with Day 0).
  3. **Hardcoded Ovulatory Days**:
     Lines 83–86 hardcode the Ovulatory Phase to Days 12–16 regardless of cycle length. For a 35-day cycle, ovulation actually occurs around Day 21 ($35 - 14$), but the provider marks Day 17–35 as Luteal Phase (4 days before ovulation occurs).
  4. **Unsorted Logs Skew**:
     `PeriodPredictionService.calculateAverageCycleLength` assumes logs are sorted descending. If unsorted or custom lists are passed, negative differences are produced and skipped.
* **Proposed Technical Solution**:
  1. Dynamic Phase Calculation:
     Calculate ovulation day dynamically as `ovulationDay = (_avgCycleLength - PeriodPredictionService.lutealPhaseLengthDays).clamp(8, _avgCycleLength - 4)`.
     Define dynamic boundaries:
     - **Menstrual Phase**: If active period exists or `cycleDay <= avgPeriodDuration` (default 5).
     - **Follicular Phase**: `cycleDay > avgPeriodDuration` up to `ovulationDay - 2`.
     - **Ovulatory Phase**: `ovulationDay - 1` through `ovulationDay + 1` (peak fertility window).
     - **Luteal Phase**: `cycleDay > ovulationDay + 1` up to `_avgCycleLength`.
  2. Overdue Cycle Safeguard:
     If `diff >= _avgCycleLength`:
     Set `_currentCycleDay = diff + 1` (do NOT modulo). Mark phase as `'Luteal Phase (Late)'` or `'Late / Overdue'` with guidance text: "Period expected. Delayed by ${diff - _avgCycleLength + 1} days".
     If `diff < 0`, clamp to `cycleDay = 1`.
  3. Pre-sort Logs:
     Ensure `PeriodPredictionService.calculateAverageCycleLength` executes `final sortedLogs = List<PeriodLog>.from(logs)..sort((a, b) => b.startDate.compareTo(a.startDate));`.
* **Verification Criteria**:
  - **Unit Test**: Create `test/period_tracker_phase_calculation_test.dart`:
    * Test short cycle (21 days): Verifies ovulation on Day 7, luteal on Days 9–21.
    * Test long cycle (35 days): Verifies ovulation on Day 21, luteal on Days 23–35.
    * Test overdue cycle (Day 32 on 28-day cycle): Verifies `cycleDay == 33`, phase does NOT reset to Menstrual Phase.
    * Test future start date: Verifies graceful clamping to Day 1.

---

### Package HT-02: Phase Guide Dialog Alignment & Interactive Scope Pill
* **Category**: UI/UX & Invariant Alignment
* **Severity / Priority**: High (Level 1)
* **Target Files & Lines**:
  - `lib/features/health/presentation/screens/period_tracker_screen.dart:80-108, 292-327`
* **Problem Description**:
  1. `_showPhaseGuideDialog` displays hardcoded day ranges:
     - Follicular Phase: **Days 6–13**
     - Ovulatory Phase: **Days 14–16**
     This directly contradicts `PeriodTrackerProvider`'s phase calculation (Follicular: **Days 6–11**, Ovulatory: **Days 12–16**).
  2. The top bar scope pill `[ 🌸 Day X • Phase ]` (lines 292–327) is a static `Container` with no gesture handler. In Notes (`[ 📁 Folder ▾ ]`) and Finances (`[ 📅 Date Range ▾ ]`), tapping the scope pill opens an interactive modal.
* **Proposed Technical Solution**:
  1. Update `_showPhaseGuideDialog` to present dynamic day ranges based on the user's current `avgCycleLength` or display unified physiological explanations without conflicting static numbers.
  2. Wrap the scope pill in a `BouncingWidget` or `InkWell(onTap: () => _showPhaseGuideDialog(context))` with `Semantics(button: true, label: 'View cycle phase guide')`, matching Invariant 14.
* **Verification Criteria**:
  - **Widget Test**: Pump `PeriodTrackerScreen`. Tap `find.bySemanticsLabel('View cycle phase guide')`. Assert `find.text('Cycle Phase Guide')` is displayed. Verify displayed day ranges match the active provider calculations.

---

### Package HT-03: Flow Intensity Modernization & Touch Bounds ($\ge 48\times 48\text{dp}$)
* **Category**: UI/UX & Invariant Compliance
* **Severity / Priority**: High (Level 1)
* **Target Files & Lines**:
  - `lib/features/health/presentation/widgets/period_log_dashboard_card.dart:145-154, 227-270`
* **Problem Description**:
  1. The 4-tier flow intensity selector (`Spotting`, `Light`, `Medium`, `Heavy`) in the dashboard card uses raw `GestureDetector` widgets with padding of only $8.0\text{dp}$ vertical and lacks `Semantics(button: true)`.
  2. Edit and Delete action `IconButton`s use `size: 18` and `visualDensity: VisualDensity.compact` without minimum $48\times 48\text{dp}$ touch target constraints.
* **Proposed Technical Solution**:
  1. Refactor the flow selector to use `SegmentedButton<String>` with `showSelectedIcon: false` (matching the modern pattern in `PeriodLogEditorSheet:231`) or wrap each item in `ConstrainedBox(constraints: const BoxConstraints(minHeight: 48, minWidth: 48))` with `Semantics(button: true)`.
  2. Apply `constraints: const BoxConstraints(minWidth: 48, minHeight: 48)` and `padding: EdgeInsets.zero` to the card's Edit and Delete action buttons.
* **Verification Criteria**:
  - **Widget Test**: Assert `tester.getSize(find.bySemanticsLabel('Spotting')).height >= 48.0`.
  - **Widget Test**: Assert `tester.getSize(find.byTooltip('Edit Period Log')).width >= 48.0`.

---

### Package HT-04: Material 3 Semantic Colors & Token Parity in Health Cards
* **Category**: UI/UX & Design Tokens
* **Severity / Priority**: Medium (Level 1)
* **Target Files & Lines**:
  - `lib/features/health/presentation/widgets/cycle_insights_card.dart:18-21, 91`
  - `lib/features/settings/presentation/screens/settings_screen.dart:634, 638`
* **Problem Description**:
  `CycleInsightsCard` hardcodes `Colors.green`, `Colors.teal`, `Colors.orange`, and `Colors.pinkAccent`. In `SettingsScreen`, the health module settings card hardcodes `const Color(0xFFF43F5E)`. These static colors violate Invariant 1.
* **Proposed Technical Solution**:
  1. In `CycleInsightsCard:18-21`:
     - Regularity score $\ge 88.0 \rightarrow colorScheme.primary`
     - Regularity score $\ge 75.0 \rightarrow colorScheme.tertiary`
     - Regularity score $\ge 60.0 \rightarrow colorScheme.errorContainer`
     - Regularity score $< 60.0 \rightarrow colorScheme.error`
  2. Line 91: Replace `Colors.pinkAccent` with `semantic?.phaseMenstrual ?? colorScheme.error`.
  3. In `SettingsScreen:634, 638`: Replace `Color(0xFFF43F5E)` with `colorScheme.tertiary`.
* **Verification Criteria**:
  - **Static Analysis**: Verify zero occurrences of `Colors.green`, `Colors.teal`, `Colors.orange`, `Colors.pinkAccent` in `cycle_insights_card.dart`.
  - **Widget Test**: Pump `CycleInsightsCard` under light and dark theme modes; assert zero static color assertions fail.

---

### Package HT-05: Hero Card Dynamic Alpha, Layout Tokens & Canvas Optimization
* **Category**: Invariant Compliance & Performance
* **Severity / Priority**: Medium (Level 1)
* **Target Files & Lines**:
  - `lib/features/health/presentation/widgets/cycle_phase_hero_card.dart:40-54`
  - `lib/widgets/moon_phase_painter.dart:25-47`
* **Problem Description**:
  1. `CyclePhaseHeroCard:41-42` uses `phaseColor.withValues(alpha: isDark ? 0.20 : 0.45)`. The Light Mode alpha is `0.45` instead of the mandated `0.50–0.55` (50%–55%) per Invariant 1 & Rule 42.
  2. Lines 45 & 53 hardcode magic numbers `padding: const EdgeInsets.all(20.0)` and `SizedBox(width: 20)` instead of `AppLayout.spaceL` ($16\text{dp}$) or `AppLayout.spaceXL` ($24\text{dp}$).
  3. `MoonPhaseWidget` paints a custom canvas with `BoxShadow(blurRadius: 20)` on every frame during scrolling without a `RepaintBoundary`.
* **Proposed Technical Solution**:
  1. Update hero card container color:
     `color: phaseColor.withValues(alpha: isDark ? 0.20 : 0.52)`
  2. Replace magic numbers:
     - `padding: const EdgeInsets.all(AppLayout.spaceL)`
     - `SizedBox(width: AppLayout.spaceM)`
  3. Wrap `MoonPhaseWidget` inside a `RepaintBoundary` to isolate the custom painter from scroll invalidations.
* **Verification Criteria**:
  - **Widget Test**: In light mode, verify `CyclePhaseHeroCard` container decoration color alpha is between $0.50$ and $0.55$.
  - **Static Analysis**: Verify `AppLayout.spaceL` is used for hero card padding.

---

### Package HT-06: Home Screen Health FAB Secondary Action Connection
* **Category**: UI/UX & Functional Polish
* **Severity / Priority**: Low (Level 1)
* **Target Files & Lines**:
  - `lib/screens/home_screen.dart:887-893`
* **Problem Description**:
  The secondary action button on `_buildTrackerFAB` (`Icons.today`, "Jump to Today") triggers light haptic feedback but does not perform any UI navigation or date selection:
  ```dart
  secondaryAction: IconButton(
    tooltip: 'Jump to Today',
    icon: Icon(Icons.today, color: colorScheme.onTertiaryContainer, size: 20),
    onPressed: () async {
      await HapticFeedback.lightImpact();
    },
  ),
  ```
* **Proposed Technical Solution**:
  Connect `secondaryAction` to select today's date in `PeriodTrackerProvider` or scroll the health calendar to the current month:
  ```dart
  onPressed: () async {
    await HapticFeedback.lightImpact();
    final provider = context.read<PeriodTrackerProvider>();
    provider.selectDay(DateTime.now());
  }
  ```
* **Verification Criteria**:
  - **Widget Test**: Tap `find.byTooltip('Jump to Today')`. Verify `provider.selectedDay` updates to today's date.

---

### Package HT-07: Prediction Performance & Duplicate Load Elimination
* **Category**: Performance & Code Hygiene
* **Severity / Priority**: Medium (Level 1)
* **Target Files & Lines**:
  - `lib/features/health/providers/period_tracker_provider.dart:45-53`
* **Problem Description**:
  In `PeriodTrackerProvider.loadData()`, `PeriodPredictionService.calculateAverageCycleLength(_logs)` is called 5 times asynchronously:
  1. `estimateNextPeriod(_logs)`
  2. `estimateOvulationDate(_logs)` (which internally calls `estimateNextPeriod`)
  3. `daysUntilNextPeriod(_logs)` (which internally calls `estimateNextPeriod`)
  4. `calculateCycleStats(_logs)`
  5. `_calculateCyclePhase()`
* **Proposed Technical Solution**:
  Refactor `PeriodPredictionService` to accept optional `precomputedAvgCycleLength: _avgCycleLength` or compute the average once in `loadData()` and reuse it across all prediction methods.
* **Verification Criteria**:
  - **Benchmark / Unit Test**: Profile `loadData()` with 50 logs; assert execution time is reduced by $>50\%$.

---

### Package HT-08: iOS Notification Channel Configuration & Navigation Payload
* **Category**: Platform Integration & Privacy Safety
* **Severity / Priority**: High (Level 1)
* **Target Files & Lines**:
  - `lib/services/notification_service.dart:77-84, 156-174`
* **Problem Description**:
  1. `_scheduleNotification` specifies `AndroidNotificationDetails` but leaves `NotificationDetails(android: ...)` without `DarwinNotificationDetails`, failing to configure iOS alerts.
  2. `requestPermissions()` resolves only `AndroidFlutterLocalNotificationsPlugin`, failing to request notification permissions on iOS devices.
  3. Scheduled notifications pass `payload: null`. Tapping a notification opens the app to the default tab without routing to the Health module.
* **Proposed Technical Solution**:
  1. Add `DarwinNotificationDetails` with discreet notification presentation options.
  2. In `requestPermissions()`, request authorization via `IOSFlutterLocalNotificationsPlugin.requestPermissions(alert: true, badge: true, sound: true)`.
  3. Pass `payload: 'route:health'` and handle notification tap in `AppRouter` or `main.dart` to navigate directly to the Period Tracker tab.
* **Verification Criteria**:
  - **Unit Test**: Verify `NotificationDetails` contains both Android and Darwin platform specifications.
  - **Unit Test**: Verify scheduled notifications include payload `'route:health'`.

---

### Package HT-09: P2P Sync Tombstone & Soft-Delete Parity for `period_logs`
* **Category**: Data Integrity & Invariant Compliance
* **Severity / Priority**: Critical (Level 1)
* **Target Files & Lines**:
  - `lib/data/period_log_model.dart:4-30`
  - `lib/features/health/data/period_repository.dart:51-60`
  - `lib/services/sync_merge_service.dart:294-301`
  - `lib/services/backup_service.dart:82, 368, 495`
* **Problem Description**:
  `PeriodLog` models contain no `deletedAt` timestamp. `PeriodRepository.deletePeriodLog(id)` performs a hard SQL delete (`DELETE FROM period_logs WHERE id = ?`). During Wi-Fi P2P sync, `SyncMergeService` batch inserts remote logs using `ConflictAlgorithm.replace`. Consequently, deleting a period record on Device A causes the deleted record to be resurrected when syncing with Device B.
* **Proposed Technical Solution**:
  1. Add `deleted_period_logs` tombstone table (matching `deleted_transaction_sms_ids` / `deleted_notes` pattern) or add `deletedAt` integer column to `period_logs`.
  2. In `PeriodRepository.deletePeriodLog(id)`:
     Record tombstone: `await db.insert('deleted_period_logs', {'id': id, 'deletedAt': DateTime.now().toIso8601String()})`.
  3. In `SyncMergeService.mergeRemoteData()`:
     Merge tombstones first and skip re-inserting period logs present in `deleted_period_logs`.
  4. Include `deleted_period_logs` in `BackupService` JSON exports and imports.
* **Verification Criteria**:
  - **Integration Test**: Create `test/period_p2p_sync_tombstone_test.dart`:
    * Insert period log on Device A and Device B.
    * Delete period log on Device A.
    * Perform simulated P2P sync between Device A and Device B.
    * Assert deleted period log is NOT resurrected on Device A, and is deleted on Device B.

---

## 5. Execution Roadmap & Isolation Boundaries

To ensure zero cross-module coupling and enable rapid, verifiable implementation, the packages are sequenced into 3 decoupled phases:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: Data Integrity & Critical Calculation Safeguards                   │
│ ├─ HT-01: Dynamic Phase Calculation & Overdue Modulo Safeguard              │
│ ├─ HT-09: P2P Sync Tombstone & Soft-Delete Parity for period_logs           │
│ └─ FN-01: Dynamic Currency Synchronization in Split Bills & Exports        │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: Design Token Invariants & Accessibility Modernization              │
│ ├─ FN-02: M3 Semantic Colors in Split Bills, Settle Up & Budget Cards       │
│ ├─ HT-04: M3 Semantic Colors in Cycle Insights & Settings                   │
│ ├─ FN-03: Touch Target Bounds (>=48dp) & SplitBillsTab FAB Clearance        │
│ ├─ HT-03: Flow Intensity SegmentedButton & Touch Target Bounds (>=48dp)     │
│ ├─ HT-05: Hero Card Dynamic Alpha (0.52) & Layout Tokens                    │
│ └─ FN-04: Atomic AppCard Adoption & Rule 41 Emoji Cleansing                 │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: Interactive Polish, Performance & Platform Hygiene                │
│ ├─ HT-02: Phase Guide Alignment & Interactive Scope Pill Tap               │
│ ├─ HT-06: Connect Home Health FAB Secondary Action (Jump to Today)         │
│ ├─ HT-07: Eliminate Redundant Prediction Recalculations in Provider         │
│ └─ HT-08: iOS Darwin Notification Configuration & Tap Navigation Payload   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Verification & Test Plan

All changes are verifiable via automated tests and static analysis. The baseline passing suite must remain green at every commit:

1. **Finances Verification Suite**:
   ```bash
   flutter test test/currency_and_sms_enhancements_test.dart \
                test/financial_trash_and_sms_fetch_test.dart \
                test/split_bill_features_test.dart \
                test/top_bar_search_and_sms_24h_sync_test.dart \
                test/features/sms_and_recurring_overhaul_test.dart
   ```
   *Baseline*: 46 / 46 passed.

2. **Health Verification Suite**:
   ```bash
   flutter test test/period_tracker_phase4_features_test.dart
   ```
   *Baseline*: 4 / 4 passed.

3. **Static Analysis**:
   ```bash
   flutter analyze lib/features/finances lib/features/health
   ```
   *Baseline*: 0 errors, 0 warnings.

4. **New Dedicated Test Suites to Implement**:
   - `test/features/finances/split_bill_dynamic_currency_test.dart` (validates FN-01)
   - `test/features/finances/touch_target_accessibility_test.dart` (validates FN-03)
   - `test/features/health/dynamic_cycle_phase_calculation_test.dart` (validates HT-01)
   - `test/features/health/period_sync_tombstone_test.dart` (validates HT-09)
   - `test/features/health/health_touch_target_test.dart` (validates HT-03 & HT-05)
