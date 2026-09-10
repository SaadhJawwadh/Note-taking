# Handoff Report — Finances Domain Deep Audit & Level 1 Improvement Plan

**Agent**: `explorer_finances_2`  
**Folder**: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_finances_2/`  
**Parent**: `orchestrator_2` (`d0b69a61-2db4-4a7d-beca-3c60703f7007`)  
**Handoff Type**: Hard (Audit & Synthesis Complete)  
**Date**: 2026-09-07T17:55:00Z  

---

## 1. Observation

A comprehensive, line-by-line read-only audit of `lib/features/finances/`, related services (`lib/services/sms_*.dart`), data models, and database repositories was conducted against the Single Source of Truth (`AGENTS.md`, `.agent/map.md`, `App-Feature-Expert`, `UI-UX-Specialist`, `Tester`).

### 1.1 Invariant Verifications (Passing Baseline)

1. **SMS Ingestion & Deduplication**:
   - **Sandbox Senders Whitelist**: `lib/services/sms_constants.dart:14-15` whitelists `'BANK'`, `'ALERTS'`, `'CARD'`; `lib/services/sms_parser.dart:60-61, 132-133` explicitly whitelists `'BANK_SMS'` and `'TEST'`, matching test fixtures.
   - **PII Lookahead Ref Regex**: `lib/services/sms_constants.dart:94` defines `piiRefRegex = RegExp(r'...|\b(?=[A-Za-z0-9]*\d)[A-Za-z0-9]{10,}\b')`, verifying that words $>10$ characters without digits (e.g., "Supermarket", "Restaurant") are not stripped.
   - **Timestamp Normalization**: `lib/services/sms_parser.dart:397-403`:
     ```dart
     static DateTime resolveMessageDate(int? messageDate) {
       if (messageDate == null || messageDate <= 0) return DateTime.now();
       if (messageDate < 10000000000) {
         return DateTime.fromMillisecondsSinceEpoch(messageDate * 1000);
       }
       return DateTime.fromMillisecondsSinceEpoch(messageDate);
     }
     ```
     Correctly differentiates 10-digit second epochs from 13-digit millisecond epochs.
   - **Tombstone Ingestion Guardrail**: `lib/features/finances/data/transaction_repository.dart:36-48, 273-296`: `createSmsTransaction` invokes `smsExists(smsId)` by default (`bypassTombstones: false`), querying both active `transactions` and `deleted_transaction_sms_ids`.
   - **Non-Blocking Chunked Sync & Cancellation**: `lib/services/sms_service.dart:244-248` yields to the event loop every 25 messages (`await Future.delayed(Duration.zero)`). `cancelSync()` (lines 46-54) updates `_cancelRequested = true` and pushes cancellation to `syncProgressStream`. `financial_manager_screen.dart:1523-1539` wires the `[ Cancel ]` button on the progress banner directly to `SmsService.cancelSync()`.
   - **24-Hour Default Scan Engine**: `lib/services/sms_service.dart:555-565`: `startCutoff` defaults to `DateTime.now().subtract(const Duration(hours: 24))`.

2. **Recurring Rule Sync & Propagation**:
   - `lib/data/repositories/recurring_rule_repository.dart:69-93`: `findMatchingRule()` matches recurring rules using description, category, and expense type.
   - `lib/features/finances/presentation/screens/transaction_editor_screen.dart:75-91, 138-205`: Editing a recurring transaction propagates updates (`amount`, `description`, `category`, `frequency`) to `RecurringRuleRepository.instance.updateRule(updatedRule)` or deletes the rule when frequency is set to `null`.
   - `lib/data/repositories/recurring_rule_repository.dart:104-154`: `materializeDueRules()` enforces a $\pm 3$-day deduplication window.

3. **Two-Bank Account Cash Flow**:
   - `lib/data/transaction_model.dart:3-6, 29`: `AccountType.daily = 'daily'`, `AccountType.savings = 'savings'`.
   - `lib/features/finances/presentation/screens/financial_manager_screen.dart:290-301`: `_dailyCashFlow` computes non-savings cash flow (`t.account != AccountType.savings`), while `_savingsVaultCashFlow` computes savings vault cash flow (`t.account == AccountType.savings`).
   - `lib/features/finances/presentation/screens/financial_manager_screen.dart:891-970`: Tonal interactive quick-filter badges for Daily Operating and Savings Vault provide 0ms in-memory filtering.
   - `lib/services/sms_parser.dart:230-248`: `resolveAccount()` auto-routes transactions with `'saving'`, `'fixed deposit'`, `'fd interest'`, and `'vault'` keywords to `AccountType.savings`.

4. **Split Bills & Shared Debts Integration**:
   - `lib/features/settings/providers/settings_provider.dart:44-45, 480-482`: `showSplitBills` gating.
   - `lib/features/finances/presentation/screens/financial_manager_screen.dart:1987-2006`: Conditionally renders `[ Split Bills ]` tab.
   - `lib/features/finances/presentation/widgets/settle_up_sheet.dart:232-259`: Settle up creates an `Income` transaction in Daily Operating account (`AccountType.daily`, `category: CategoryConstants.deposit`) when a friend settles with the user. If friend paid for group, friends settling with friend are guarded by `isFriendSettlingWithFriend` (lines 232-236) and never enter the user's ledger.
   - `lib/services/backup_service.dart:80, 366, 492` & `lib/services/sync_merge_service.dart:326`: `split_bills`, `split_participants`, and `split_contacts` are fully serialized, restored, and merged.

5. **Memory & Downsampling Bounds**:
   - `lib/features/finances/presentation/widgets/receipt_scanner_sheet.dart:156-168`: `Image.file(File(_imagePath!), cacheWidth: 300, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ...)` bounds bitmap memory to 300px and provides errorBuilder fallback.

6. **Automated Test & Static Analysis Baseline**:
   - `flutter test test/currency_and_sms_enhancements_test.dart test/financial_trash_and_sms_fetch_test.dart test/split_bill_features_test.dart test/top_bar_search_and_sms_24h_sync_test.dart test/features/sms_and_recurring_overhaul_test.dart`: **46 / 46 tests passed (0 failures)**.
   - `flutter analyze lib/features/finances`: **0 errors, 0 warnings (clean)**.

---

### 1.2 Discovered Deficiencies & Non-Compliances (Level 1 Targets)

#### Finding 1 (Logic & Invariant Compliance): Hardcoded `'Rs.'` Currency Symbol in Split Bills & Export
- **File & Lines**:
  - `lib/features/finances/presentation/widgets/split_bills_tab.dart:191, 192, 238, 286, 476, 645`
  - `lib/features/finances/presentation/widgets/settle_up_sheet.dart:105`
  - `lib/features/finances/presentation/screens/split_bill_editor_screen.dart:563, 641, 642`
  - `lib/features/finances/services/split_share_service.dart:11, 55, 72` (default parameter `currencySymbol = 'Rs.'`)
  - `lib/features/finances/services/financial_export_service.dart:64, 113, 146` (default parameter `currency = 'Rs.'`)
- **Direct Code Evidence**:
  - `split_bills_tab.dart:191-192`: `'+Rs. ${net.toStringAsFixed(2)...}'` and `'-Rs. ${net.abs()...}'`
  - `split_bills_tab.dart:238`: `'Rs. ${owedToUser.toStringAsFixed(2)...}'`
  - `split_bills_tab.dart:286`: `'Rs. ${userOwes.toStringAsFixed(2)...}'`
  - `split_bills_tab.dart:476`: `'Rs. 0'`
  - `split_bills_tab.dart:645`: `'Rs. ${bill.totalAmount.toStringAsFixed(2)...}'`
  - `settle_up_sheet.dart:105`: `'Rs. ${absAmount.toStringAsFixed(2)...}'`
  - `split_bill_editor_screen.dart:563`: `'Rs. ${_equalShareAmount.toStringAsFixed(2)} / person'`
  - `split_bill_editor_screen.dart:641-642`: `'Rs. ${_equalShareAmount.toStringAsFixed(2)}'` / `'Rs. ${_remainingToAllocate.toStringAsFixed(2)}'`
- **Violation**: AGENTS.md Invariant 4 & 12: Currencies must strictly reflect the user's active currency (`settings.currency`). When switching to USD (`$`), EUR (`€`), GBP (`£`), or INR (`₹`), split bill screens continue to display Sri Lankan Rupee (`Rs.`).

#### Finding 2 (UI/UX & Design Tokens): Hardcoded Static Colors (`Colors.green`, `Colors.red`, `Colors.orange`, `Colors.teal`)
- **File & Lines**:
  - `lib/features/finances/presentation/widgets/split_bills_tab.dart:194, 196, 214, 216, 223, 228, 241, 443, 449, 482, 658, 668, 700, 705, 714, 724, 860, 864, 873, 883`
  - `lib/features/finances/presentation/widgets/settle_up_sheet.dart:74, 78, 86, 91, 108`
  - `lib/features/finances/presentation/widgets/burn_rate_forecast_card.dart:24-28`
  - `lib/features/finances/presentation/widgets/category_budgets_card.dart:131, 133, 135, 137, 141`
  - `lib/features/finances/presentation/screens/split_bill_editor_screen.dart:682`
- **Direct Code Evidence**:
  - `split_bills_tab.dart:196`: `textColor: net >= 0 ? Colors.green : Colors.red`
  - `split_bills_tab.dart:214`: `color: Colors.green.withValues(alpha: isDark ? 0.12 : 0.10)`
  - `settle_up_sheet.dart:108`: `color: isContactOwingUser ? Colors.green : Colors.red`
  - `burn_rate_forecast_card.dart:24-28`: returns `Colors.teal`, `Colors.green`, `Colors.orange`
  - `category_budgets_card.dart:131-141`: sets `Colors.orange`, `Colors.teal`, `Colors.green`
- **Violation**: AGENTS.md Invariant 1 & UI-UX-Specialist Rule: "Zero Hardcoded Colors: Always use `Theme.of(context).colorScheme.<token>` or `AppSemanticColors` — never hardcode static `Color(...)` or `Colors.green`/`Colors.red`". In dynamic Material You palettes and OLED pitch-black dark mode, raw colors clash and produce muddy, non-adaptive contrast.

#### Finding 3 (UI/UX & Accessibility): Touch Targets Below $48 \times 48\text{dp}$
- **File & Lines**:
  - `lib/features/finances/presentation/widgets/minimal_chart_deck.dart:158-183`: "Details >" link has `padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)` ($\approx 28\text{dp}$ height) without minimum constraints.
  - `lib/features/finances/presentation/widgets/minimal_chart_deck.dart:216-245`: Interactive pagination indicator dots have `padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8)` ($\approx 22\text{dp}$ height $\times$ $30\text{dp}$ width).
  - `lib/features/finances/presentation/widgets/financial_trash_sheet.dart:199-230`: "Restore" action has `padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)` ($\approx 24\text{dp}$ height).
  - `lib/features/finances/presentation/widgets/financial_trash_sheet.dart:232-254`: Permanent delete "X" icon button has `padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)` ($\approx 24\text{dp} \times 28\text{dp}$) and lacks `Semantics(button: true)`.
  - `lib/features/finances/presentation/screens/financial_manager_screen.dart:1523-1539`: SMS Sync Progress banner "Cancel" button has `padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)` ($\approx 22\text{dp}$ height).
  - `lib/features/finances/presentation/screens/financial_manager_screen.dart:895-969`: Dual-account quick-filter badges in Hero Card have `padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)` ($\approx 24\text{dp}$ height).
  - `lib/features/finances/presentation/screens/financial_manager_screen.dart:1216`: Date scope pill has `padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5)` ($\approx 22\text{dp}$ height).
- **Violation**: AGENTS.md Invariant 10: "All interactive micro-elements (sync buttons, date filter pills, 'Details >' links, pagination indicator dots) must enforce minimum $48 \times 48\text{dp}$ hit bounds (`BoxConstraints(minWidth: 48, minHeight: 48)` or padded gesture wrappers) and supply `Semantics(button: true)`."

#### Finding 4 (UI/UX & Invariant Compliance): Missing Bottom FAB Clearance (`fabBottomPadding = 96.0`) in `SplitBillsTab`
- **File & Lines**:
  - `lib/features/finances/presentation/widgets/split_bills_tab.dart:63`: `ListView(padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceM, vertical: AppLayout.spaceS))` applies only $8.0\text{dp}$ bottom padding.
- **Violation**: AGENTS.md Invariant 8: "No Obscured Content: Bottom scrollable content must never be clipped or obscured by floating buttons or bottom navigation chrome. Always apply `AppLayout.fabBottomPadding = 96.0` to sliver lists or bottom padding containers." The bottommost split bill card is obscured by the FAB.

#### Finding 5 (Invariant Compliance): Raw Flutter `Card` Usage Instead of Atomic `AppCard` Primitive
- **File & Lines**:
  - `lib/features/finances/presentation/screens/financial_manager_screen.dart:688`: Raw `Card(` for top hero balance summary card.
  - `lib/features/finances/presentation/screens/sms_rules_screen.dart:200, 252, 278, 538, 608, 761`: Raw `Card(` in 6 locations.
  - `lib/features/finances/presentation/screens/sms_contacts_screen.dart:82, 222`: Raw `Card(`.
  - `lib/features/finances/presentation/screens/category_management_screen.dart:194`: Raw `Card(` for custom category cards.
  - `lib/features/finances/presentation/widgets/recurring_rules_sheet.dart:529`: Raw `Card(` for recurring rules list.
- **Violation**: AGENTS.md Invariant 1: "Shared UI Library: Always use `AppCard`, `AppBottomSheet`, `AppChip`, `AppDialog`, and `FrostedGlassSliverAppBar` from `lib/core/ui/`."

#### Finding 6 (Invariant Compliance): Raw Unicode Emoji Glyphs in UI Labels (Rule 41 Violation)
- **File & Lines**:
  - `lib/features/finances/presentation/screens/transaction_editor_screen.dart:563`: `'Refined title & category with Gemini Nano ✨'` in SnackBar.
  - `lib/features/finances/presentation/screens/sms_rules_screen.dart:450, 455, 734`: `'🏷️ Title: ${parsed.description}'`, `'📂 Category: ${parsed.category}'`, `'🏷️ Title: ${rule.customDescription}'` in UI preview cards.
  - `lib/features/finances/presentation/widgets/financial_ledger_tab.dart:227`: `'${transaction.account == AccountType.savings ? '🏦 Savings • ' : ''}...'` in list tile subtitle.
- **Violation**: AGENTS.md Invariant 10 (Rule 41): "Strictly replace raw Unicode emoji glyphs (`🔮`, `🔴`, `🟢`, `📋`) in UI labels and badges with authentic Material Symbols (`Icons.auto_awesome_rounded`) and plain-language semantic labels."

#### Finding 7 (Design System Consistency): Chart Tooltip Radius Token Magic Number
- **File & Lines**:
  - `lib/features/finances/presentation/widgets/minimal_chart_deck.dart:501`: `tooltipRoundedRadius: 10`
- **Violation**: Hardcoded integer `10` instead of design token `AppLayout.radiusM` ($12.0\text{dp}$).

---

## 2. Logic Chain

1. **Premise 1 (Currency Invariant)**: The app supports 14 curated global currencies (`USD`, `EUR`, `GBP`, `INR`, `LKR`, etc.) selected in `SettingsProvider.currency`. Financial displays throughout the app must dynamically bind to `settings.currency`.
   - **Observation**: `split_bills_tab.dart:191, 238, 286, 645`, `settle_up_sheet.dart:105`, and `split_bill_editor_screen.dart:563, 641` interpolate literal `'Rs.'`.
   - **Inference**: Changing the currency in Settings updates the Ledger and Analytics tabs, but leaves the Split Bills tab displaying `Rs.`, causing user confusion and accounting inconsistencies.

2. **Premise 2 (Design System Token Invariant)**: M3 Expressive theming mandates dynamic color adaptation (`colorScheme.tertiary`, `colorScheme.error`, `AppSemanticColors`) and token-based layout (`AppLayout.fabBottomPadding = 96.0`, `AppLayout.radiusM`).
   - **Observation**: Multiple finance widgets hardcode `Colors.green`, `Colors.red`, `Colors.orange`, `Colors.teal`, and use raw `Card` containers without FAB bottom clearance.
   - **Inference**: In Dark OLED mode, `Colors.green` and `Colors.red` cause high-vibrancy optical glare, while the lack of bottom clearance renders the last split bill inaccessible behind the FAB.

3. **Premise 3 (Accessibility Invariant)**: Touch controls must supply $\ge 48 \times 48\text{dp}$ hit bounds to guarantee accessibility and eliminate missed taps on handheld mobile screens.
   - **Observation**: Micro-actions (pagination dots, "Details >", "Restore", "Delete X", "Cancel") have rendered heights between $22\text{dp}$ and $28\text{dp}$ without bounding constraints.
   - **Inference**: Wrapping these micro-elements in `ConstrainedBox(constraints: BoxConstraints(minWidth: 48, minHeight: 48))` or standard touch targets will eliminate mis-taps with zero visual distortion.

---

## 3. Caveats

1. **Scope Boundaries**: This audit is strictly read-only and covers `lib/features/finances/`, related services, and database persistence. No source code was modified during this exploration.
2. **WhatsApp External Formatting**: External WhatsApp message templates generated in `SplitShareService.formatBillSummary` contain friendly emojis (`🧾`, `🗓️`, `💳`, `👋`). These are intended for third-party chat messaging and are not considered internal UI violations under Rule 41.
3. **Hardware AI Fallback**: Automated tests and CI environments run with simulated heuristics when physical Gemini Nano hardware is absent.

---

## 4. Conclusion & Actionable Level 1 Improvement Roadmap

The Finances module possesses a rock-solid architectural core (Two-Bank accounts, 24h sync engine, tombstones, recurring rule propagation, 0ms optimistic UI, offline OCR). To elevate the module to production-grade polish, the following prioritized **Level 1 Work Packages** are recommended for immediate implementation:

### 📦 Package 1: Dynamic Currency Synchronization in Split Bills & Export
- **Goal**: Ensure 100% dynamic currency binding across all split bills screens and export tools.
- **Concrete Changes**:
  1. `lib/features/finances/presentation/widgets/split_bills_tab.dart`:
     - Line 191-192: Replace `'+Rs. ${net...}'` with `'+$currency ${net...}'`.
     - Line 238: Replace `'Rs. ${owedToUser...}'` with `'$currency ${owedToUser...}'`.
     - Line 286: Replace `'Rs. ${userOwes...}'` with `'$currency ${userOwes...}'`.
     - Line 476: Replace `'Rs. 0'` with `'$currency 0'`.
     - Line 645: Replace `'Rs. ${bill.totalAmount...}'` with `'$currency ${bill.totalAmount...}'`.
  2. `lib/features/finances/presentation/widgets/settle_up_sheet.dart:105`:
     - Access `final currency = context.read<SettingsProvider>().currency;`
     - Replace `'Rs. ${absAmount...}'` with `'$currency ${absAmount...}'`.
  3. `lib/features/finances/presentation/screens/split_bill_editor_screen.dart`:
     - Line 563: Replace `'Rs. ${_equalShareAmount...}'` with `'$currency ${_equalShareAmount...}'`.
     - Line 641-642: Replace `'Rs. ${_equalShareAmount...}'` and `'Rs. ${_remainingToAllocate...}'` with `'$currency ...'`.
  4. `lib/features/finances/services/split_share_service.dart:11, 55, 72`:
     - Default to `$currencySymbol` passed from `SettingsProvider.currency`.

### 📦 Package 2: Material 3 Semantic Colors & Zero-Hardcoded-Color Parity
- **Goal**: Replace raw `Colors.green`, `Colors.red`, `Colors.orange`, `Colors.teal` with `colorScheme.tertiary`, `colorScheme.error`, and `AppSemanticColors`.
- **Concrete Changes**:
  1. `lib/features/finances/presentation/widgets/split_bills_tab.dart`:
     - Map positive balances / paid status to `colorScheme.tertiary` (or `Theme.of(context).extension<AppSemanticColors>()?.success ?? colorScheme.tertiary`).
     - Map owing / unpaid balances to `colorScheme.error`.
  2. `lib/features/finances/presentation/widgets/settle_up_sheet.dart:74-108`:
     - Replace `Colors.green` with `colorScheme.tertiary` and `Colors.red` with `colorScheme.error`.
  3. `lib/features/finances/presentation/widgets/burn_rate_forecast_card.dart:21-34`:
     - `underPace`: `colorScheme.primary`
     - `onTrack`: `colorScheme.tertiary`
     - `overPace`: `colorScheme.errorContainer` / warning accent
     - `exhausted`: `colorScheme.error`
     - `noBudget`: `colorScheme.outline`
  4. `lib/features/finances/presentation/widgets/category_budgets_card.dart:130-142`:
     - Replace `Colors.orange` and `Colors.teal` with semantic tokens (`colorScheme.error`, `colorScheme.tertiary`, `colorScheme.primary`).

### 📦 Package 3: Touch Target Accessibility & Layout Clearance
- **Goal**: Meet $\ge 48 \times 48\text{dp}$ touch target bounds and eliminate obscured content.
- **Concrete Changes**:
  1. `lib/features/finances/presentation/widgets/split_bills_tab.dart:63`:
     - Update padding to `const EdgeInsets.fromLTRB(AppLayout.spaceM, AppLayout.spaceS, AppLayout.spaceM, AppLayout.fabBottomPadding)`.
  2. `lib/features/finances/presentation/widgets/minimal_chart_deck.dart`:
     - Lines 158-183: Wrap "Details >" `InkWell` with `ConstrainedBox(constraints: const BoxConstraints(minHeight: 48, minWidth: 48))` or adjust internal padding to meet 48dp height.
     - Lines 216-245: Wrap pagination indicator dots in `SizedBox(width: 48, height: 48, child: Center(child: AnimatedContainer(...)))`.
     - Line 501: Set `tooltipRoundedRadius: AppLayout.radiusM`.
  3. `lib/features/finances/presentation/widgets/financial_trash_sheet.dart`:
     - Lines 199-230: Wrap "Restore" button in `ConstrainedBox(constraints: const BoxConstraints(minHeight: 48))`.
     - Lines 232-254: Wrap Delete "X" icon in `IconButton` or `ConstrainedBox(constraints: const BoxConstraints(minWidth: 48, minHeight: 48))` with `Semantics(button: true, label: 'Permanently delete transaction')`.
  4. `lib/features/finances/presentation/screens/financial_manager_screen.dart`:
     - Lines 1523-1539: Wrap Cancel button on sync banner in `ConstrainedBox(constraints: const BoxConstraints(minHeight: 48, minWidth: 48))`.
     - Lines 895-969: Apply `constraints: const BoxConstraints(minHeight: 48)` on Dual-Account filter badges.
     - Lines 1205-1258: Apply `constraints: const BoxConstraints(minHeight: 48)` on top Date Scope Pill.

### 📦 Package 4: Atomic UI Modernization (`AppCard`) & Rule 41 Emoji Cleansing
- **Goal**: Consolidate cards onto `AppCard` and replace raw text emojis in UI controls with Material Symbols.
- **Concrete Changes**:
  1. Refactor raw `Card` in `financial_manager_screen.dart:688`, `sms_rules_screen.dart:200, 252, 278, 538, 608, 761`, `sms_contacts_screen.dart:82, 222`, `category_management_screen.dart:194`, and `recurring_rules_sheet.dart:529` to `AppCard` or `AppCard.tonal`.
  2. `transaction_editor_screen.dart:563`: Replace `'Refined title & category with Gemini Nano ✨'` with `'Refined title & category with Gemini Nano'`.
  3. `sms_rules_screen.dart:450, 455, 734`: Replace `'🏷️ Title:'` with `Row(children: [Icon(Icons.label_outline_rounded, size: 14), Text(' Title: ...')])`. Replace `'📂 Category:'` with `Row(children: [Icon(Icons.category_outlined, size: 14), Text(' Category: ...')])`.
  4. `financial_ledger_tab.dart:227`: Render a clean `AppChip` or `Icon(Icons.account_balance_outlined, size: 12)` badge for Savings transactions instead of text emoji `'🏦'`.

---

## 5. Verification Method

To independently verify this audit and validate subsequent Level 1 implementations:

### 5.1 Automated Test Execution
Run the finance test suite:
```bash
flutter test test/currency_and_sms_enhancements_test.dart \
             test/financial_trash_and_sms_fetch_test.dart \
             test/split_bill_features_test.dart \
             test/top_bar_search_and_sms_24h_sync_test.dart \
             test/features/sms_and_recurring_overhaul_test.dart
```
*Expected Result*: All 46 tests pass.

Run static analysis:
```bash
flutter analyze lib/features/finances
```
*Expected Result*: 0 errors, 0 warnings.

### 5.2 Unit & Widget Test Additions for Level 1 Improvements
1. **Dynamic Currency Assertion in Split Bills**:
   - Create a test in `test/split_bill_features_test.dart`: Initialize `SettingsProvider` with `currency = 'USD ($)'` or `'EUR (€)'`. Pump `SplitBillsTab`, `SplitBillEditorScreen`, and `SettleUpSheet`. Assert `find.textContaining('Rs.')` finds `nothing`, while `find.textContaining('\$')` or `find.textContaining('€')` finds exact matches.
2. **Touch Target Hit Bounds Verification**:
   - Write widget tests verifying `tester.getSize(find.bySemanticsLabel('View detailed financial analytics and charts')).height >= 48.0`.
   - Verify pagination indicator dots satisfy `tester.getSize(find.bySemanticsLabel('Switch to Expense Breakdown chart')).height >= 48.0`.
   - Verify `SplitBillsTab` scrollable list `padding.bottom == 96.0` (`AppLayout.fabBottomPadding`).
3. **Emoji Elimination Verification**:
   - Add a regex-based test asserting no raw Unicode emoji glyphs exist in user-visible `Text` widgets across `TransactionEditorScreen`, `SmsRulesScreen`, and `FinancialLedgerTab`.
