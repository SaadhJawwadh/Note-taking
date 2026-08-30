# Finances & Split Bills Domain — Comprehensive Architectural Audit & Work Package

**Working Directory**: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_finances_1/`  
**Target Modules**: `lib/features/finances/`, `lib/services/sms/`, `lib/data/` (financial models & repositories), `test/`  
**Status**: Completed (Read-Only Audit) — 177 / 177 automated tests passing  

---

## 1. Executive Summary

A comprehensive architectural audit of the **Finances & Split Bills** domain in Everything App was conducted against the Master Single Source of Truth (`AGENTS.md`), Developer Map (`.agent/map.md`), and `App-Feature-Expert` skill rules.

The domain implements a high-performance, offline-first financial ledger with:
1. **Two-Bank Account Model**: Decoupled `AccountType.daily` ('daily') and `AccountType.savings` ('savings') accounts with interactive dual-cash-flow hero metrics and 0ms optimistic list filtering.
2. **SMS Automation & Telephony Pipeline**: Local regex parsing with sandbox whitelisting (`'BANK_SMS'`, `'CARD'`, `'ALERTS'`, `'BANK'`), strict manifest permission parity (`Permission.sms`), timestamp normalization across 10-digit and 13-digit epochs, and PII lookahead assertions.
3. **Tombstone & Soft-Delete Invariant Safety**: `createSmsTransaction` enforces `smsExists(smsId)` by default against active transactions and `deleted_transaction_sms_ids`. Soft-delete undo restores records via `restoreTransaction(id)` rather than re-inserting records.
4. **SMS 24-Hour Default Lookback & Responsive Sync**: Sync engines default to scanning the past 24 hours in non-blocking 25-message chunks with instant user cancellation (`_cancelRequested`) and a real-time frosted progress banner.
5. **Recurring Payment Rule Propagation**: Edits to recurring transactions in `TransactionEditorScreen` propagate updates to master `RecurringRule`s via `findMatchingRule()`, and due occurrences are materialized idempotently with a $\pm 3$-day deduplication window.
6. **Split Bills & Shared Debts Ledger Interop**: Strict cash flow contracts (user payment = full receipt expense; participant settlement = daily account income; friend payment = expense recorded on settle-up) with 0ms optimistic UI.
7. **100% Offline Receipt OCR & Authentic Currencies**: On-device text recognition via Google ML Kit, markdown WhatsApp breakdown formatting via `SplitShareService`, and authentic currency metadata via `CurrencyInfo` (`AppConstants`).

---

## 2. Deep-Dive Domain Findings & Code Evidence

### 2.1 Two-Bank Account Architecture (`AccountType.daily` vs `AccountType.savings`)

#### Evidence & Implementation:
- **Model Definition** (`lib/data/transaction_model.dart:3-6, 17, 29, 73, 86`):
  ```dart
  class AccountType {
    static const String daily = 'daily';
    static const String savings = 'savings';
  }
  ```
- **Database Schema** (`lib/data/database_helper.dart:151-155`):
  - Column `account TEXT NOT NULL DEFAULT 'daily'` is defined on the `transactions` table.
- **Dynamic Cash Flow Hero Metrics** (`lib/features/finances/presentation/screens/financial_manager_screen.dart:291-301`):
  ```dart
  double get _dailyCashFlow {
    return _allDateFiltered
        .where((t) => t.account != AccountType.savings)
        .fold(0.0, (sum, t) => sum + (t.isExpense ? -t.amount : t.amount));
  }

  double get _savingsVaultCashFlow {
    return _allDateFiltered
        .where((t) => t.account == AccountType.savings)
        .fold(0.0, (sum, t) => sum + (t.isExpense ? -t.amount : t.amount));
  }
  ```
- **Interactive Dual Badges & 0ms Account Filtering** (`lib/features/finances/presentation/screens/financial_manager_screen.dart:892-970` and `268-270`):
  - Tapping either the Daily Operating or Savings Vault badge toggles `_selectedAccount` between `'all'`, `AccountType.daily`, and `AccountType.savings`.
  - `_applyFilters()` executes synchronously on the in-memory cached `_allDateFiltered` list with 0ms latency and no loading spinner jitter.
- **Auto-Deposit Routing** (`lib/services/sms_parser.dart:230-248`):
  ```dart
  static String resolveAccount({
    required String body,
    required String category,
    CustomSmsRule? matchingRule,
    Map<String, String>? categoryAccountRouting,
  }) {
    if (matchingRule != null && matchingRule.targetAccount != null && matchingRule.targetAccount!.trim().isNotEmpty) {
      return matchingRule.targetAccount!.trim();
    }
    if (categoryAccountRouting != null && categoryAccountRouting.containsKey(category)) {
      return categoryAccountRouting[category]!;
    }
    final bodyLower = body.toLowerCase();
    final isSavings = bodyLower.contains('saving') ||
                      bodyLower.contains('fixed deposit') ||
                      bodyLower.contains('fd interest') ||
                      bodyLower.contains('vault');
    return isSavings ? AccountType.savings : AccountType.daily;
  }
  ```

---

### 2.2 SMS Automation, Parsing & Telephony Safety

#### Evidence & Implementation:
- **Sandbox Test Sender Whitelisting** (`lib/services/sms_constants.dart:14-15` & `lib/services/sms_parser.dart:60-61, 132-133`):
  - `SmsConstants.bankSenders` includes `'BANK'`, `'ALERTS'`, `'CARD'`.
  - `SmsParser.isPotentiallyRelevant` & `parseMessage` verify:
    ```dart
    final isBank = SmsConstants.bankSenders.any((s) => address.toUpperCase().contains(s.toUpperCase())) ||
        address.toUpperCase().contains('BANK') ||
        address.toUpperCase().contains('ALERT') ||
        address.toUpperCase().contains('CARD') ||
        address == 'TEST' ||
        address == 'BANK_SMS';
    ```
- **Permission Manifest Parity** (`lib/services/sms_service.dart:190-213`):
  - `SmsService.requestPermissions()` and `SmsService.hasPermission()` strictly query `Permission.sms` (`READ_SMS` and `RECEIVE_SMS` in `AndroidManifest.xml`).
  - No undeclared companion permissions (such as `Permission.phone`) are queried, preventing permanent `PermissionStatus.denied` lockouts.
- **Epoch Timestamp Normalization** (`lib/services/sms_parser.dart:397-403`):
  ```dart
  static DateTime resolveMessageDate(int? messageDate) {
    if (messageDate == null || messageDate <= 0) return DateTime.now();
    if (messageDate < 10000000000) {
      return DateTime.fromMillisecondsSinceEpoch(messageDate * 1000);
    }
    return DateTime.fromMillisecondsSinceEpoch(messageDate);
  }
  ```
  - Accurately converts 10-digit second epochs and 13-digit millisecond epochs, preserving historical transaction dates.
- **PII Lookahead Assertions** (`lib/services/sms_constants.dart:94`):
  - `piiRefRegex` specifies `\b(?=[A-Za-z0-9]*\d)[A-Za-z0-9]{10,}\b` ensuring that reference stripping only matches alphanumeric strings containing at least one digit, preventing truncation of valid 10+ letter English words.
- **CEFTS Self-Transfer Neutrality** (`lib/services/sms_constants.dart:76, 80` & `lib/services/sms_parser.dart:198-200`):
  - Self-transfers (`CEFTS`, `to: saadh`, `saadh com`, etc.) are classified as `CategoryConstants.transfer`, cleanly omitting them from spending burn calculations (`financial_manager_provider.dart:130-139`).

---

### 2.3 Tombstone Ingestion Safety & Soft-Delete Undo Parity

#### Evidence & Implementation:
- **Tombstone Ingestion Guardrail** (`lib/features/finances/data/transaction_repository.dart:29-48, 273-296`):
  - `createSmsTransaction` invokes `smsExists(smsId)` by default (`bypassTombstones: false`).
  - `smsExists` queries both active/trashed transactions in `transactions` and permanent tombstones in `deleted_transaction_sms_ids`:
    ```dart
    Future<bool> smsExists(String smsId) async {
      if (smsId.isEmpty) return false;
      final db = await _db;
      final activeCheck = await db.query(TableNames.transactions, columns: [TransactionFields.id], where: '${TransactionFields.smsId} = ?', whereArgs: [smsId], limit: 1);
      if (activeCheck.isNotEmpty) return true;
      final tombstoneCheck = await db.query(TableNames.deletedTransactionSmsIds, columns: ['smsId'], where: 'smsId = ?', whereArgs: [smsId], limit: 1);
      return tombstoneCheck.isNotEmpty;
    }
    ```
- **Soft-Delete Undo Parity** (`lib/features/finances/data/transaction_repository.dart:155-165` & `lib/features/finances/presentation/screens/financial_manager_screen.dart:1907-1928`):
  - Undoing a deleted transaction calls `restoreTransaction(id)` (`UPDATE transactions SET deletedAt = NULL WHERE id = ?`).
  - Guarantees 0ms in-memory restoration without primary key collisions or tombstone re-import blocks.
- **30-Day Auto-Purge Lifecycle** (`lib/features/finances/data/transaction_repository.dart:216-246`):
  - `clearOldTransactionTrash(days: 30)` writes `smsId` to `deleted_transaction_sms_ids` before purging expired rows.

---

### 2.4 SMS 24-Hour Default Scan Engine, Non-Blocking Chunking & Sync Banner

#### Evidence & Implementation:
- **24-Hour Default Lookback** (`lib/services/sms_service.dart:555-565, 725-731`):
  - `performSmsSync` defaults `startCutoff = DateTime.now().subtract(const Duration(hours: 24))` when no explicit time is passed.
  - App launch catch-up sync (`performAppLaunchCatchUpSync`) scans the last 24 hours, eliminating skipped messages from incremental "fetch only new" cutoffs.
- **Non-Blocking Chunked Processing** (`lib/services/sms_service.dart:244-248`):
  - Yields to the Dart event loop every 25 messages (`if (processed % 25 == 0) await Future.delayed(Duration.zero);`).
- **Cancellation Flag (`_cancelRequested`)** (`lib/services/sms_service.dart:44-54, 239-242`):
  - `SmsService.cancelSync()` sets `_cancelRequested = true` and updates `syncProgressStream`.
- **Real-Time Frosted Sync Banner** (`lib/features/finances/presentation/screens/financial_manager_screen.dart:1465-1540`):
  - Rendered dynamically below the top app bar across all tabs (`Ledger`, `Budgets`, `Split Bills`).
  - Displays live scanning progress (`scanned / total • found found`) and includes an instant 1-tap `[ Cancel ]` button wired to `SmsService.cancelSync()`.

---

### 2.5 Recurring Rule Propagation & Transaction Sync

#### Evidence & Implementation:
- **Master Rule Lookup** (`lib/data/repositories/recurring_rule_repository.dart:69-93`):
  - `findMatchingRule()` matches recurring transactions by exact description, substring + category/amount match, or word tokens.
- **Two-Way Synchronization on Edit** (`lib/features/finances/presentation/screens/transaction_editor_screen.dart:75-91, 138-202`):
  - When editing a recurring transaction, updates to amount, description, category, and frequency propagate to `RecurringRuleRepository.instance.updateRule(updatedRule)`.
  - When frequency is toggled off (`_repeatFrequency == null`), `deleteRule(_matchedRuleId!)` deletes the master rule to stop future auto-generations while preserving past ledger entries.
- **Idempotent Materialization** (`lib/data/repositories/recurring_rule_repository.dart:104-154`):
  - `materializeDueRules()` reconciles due rules against existing transactions within a $\pm 3$-day window via `findMatchingRecurringTransaction()`, preventing duplicate charges.

---

### 2.6 Split Bills & Shared Debts Domain Integration

#### Evidence & Implementation:
- **Modular Integration & Provider Architecture** (`lib/features/finances/data/models/split_bill_model.dart`, `lib/features/finances/providers/split_bill_provider.dart`):
  - `SplitBillModel`, `SplitParticipantModel`, `SplitContactModel` with support for `SplitMode.equal` and `SplitMode.exact`.
  - In-memory reactive state in `SplitBillProvider` with 0ms optimistic UI mutations.
- **Ledger Cash Flow Contract**:
  - **User Pays**: Master expense records full receipt total in Daily Operating account (`AccountType.daily`).
  - **Settlement Received**: `SettleUpSheet` (`lib/features/finances/presentation/widgets/settle_up_sheet.dart:181-203`) records an `Income` transaction in the Daily Operating account (`category: CategoryConstants.deposit`, description: `"$contactName - Split settlement"`).
  - **Friend Pays**: Personal liability is recorded *only* upon settling up with the friend in `SettleUpSheet` as an `Expense` in the Daily Operating account.
- **Group Summary & People View** (`lib/features/finances/presentation/widgets/split_bills_tab.dart:65-98, 152-180`):
  - Dynamic Hero summary card calculates net balance (`owedToUser - userOwes`).
  - Segmented button provides 0ms toggling between People View and Bills View.

---

### 2.7 100% Offline Receipt OCR, WhatsApp Sharing & Authentic Currencies

#### Evidence & Implementation:
- **Offline ML Kit OCR** (`lib/features/finances/services/receipt_scanner_service.dart:26-58, 102-178`):
  - Uses `google_mlkit_text_recognition` (`TextRecognitionScript.latin`) locally on-device.
  - Heuristic regex engine searches for total keywords (`grand total`, `total amount`, `net amount`, `sub total`) and extracts currency amounts without cloud dependencies.
  - Seamlessly pre-fills `SplitBillEditorScreen` (`lib/features/finances/presentation/screens/split_bill_editor_screen.dart:182-196`).
- **WhatsApp Breakdown Dispatch** (`lib/features/finances/services/split_share_service.dart:6-44, 65-79`):
  - `formatBillSummary()` formats markdown breakdown messages with itemized participants and user-configured bank payment details.
  - Dispatches via system share sheet (`Share.share`) or copies to clipboard with haptic feedback.
- **Authentic Currency Badges** (`lib/utils/app_constants.dart:17-46`):
  - `CurrencyInfo` metadata supports 14 authentic currencies (`Rs.`, `₹`, `$`, `€`, `£`, `¥`, `د.إ`, `﷼`, `C$`, `A$`, `S$`, `RM`, `NZ$`, `CHF`) and custom codes.

---

## 3. Architecture & Invariants Compliance Matrix

| Invariant / Requirement | Compliance | Evidence File & Location |
|---|---|---|
| **Two-Bank Account Model** (`daily` vs `savings`) | ✅ 100% Compliant | `transaction_model.dart:3-6`, `financial_manager_screen.dart:291-301, 892-970` |
| **0ms Instant Account & Category Filtering** | ✅ 100% Compliant | `financial_manager_screen.dart:260-285` |
| **Auto-Deposit Routing** | ✅ 100% Compliant | `sms_parser.dart:230-248` |
| **SMS Sandbox Senders Whitelist** | ✅ 100% Compliant | `sms_constants.dart:14-15`, `sms_parser.dart:60-61, 132-133` |
| **SMS Permission Manifest Parity** (`Permission.sms`) | ✅ 100% Compliant | `sms_service.dart:190-213`, `AndroidManifest.xml:2-3` |
| **Timestamp Normalization** (10-digit & 13-digit epochs) | ✅ 100% Compliant | `sms_parser.dart:397-403` |
| **PII Lookahead Assertions** (`\b(?=[A-Za-z0-9]*\d)...`) | ✅ 100% Compliant | `sms_constants.dart:94` |
| **Tombstone Ingestion Safety** (`smsExists`) | ✅ 100% Compliant | `transaction_repository.dart:29-48, 273-296` |
| **Soft-Delete Undo Parity** (`restoreTransaction`) | ✅ 100% Compliant | `transaction_repository.dart:155-165`, `financial_manager_screen.dart:1907-1928` |
| **24-Hour Default SMS Scan Engine** | ✅ 100% Compliant | `sms_service.dart:555-565, 725-731` |
| **Non-Blocking Chunking (Yield every 25 msgs)** | ✅ 100% Compliant | `sms_service.dart:244-248` |
| **SMS Cancellation Token & Frosted Banner** | ✅ 100% Compliant | `sms_service.dart:44-54`, `financial_manager_screen.dart:1465-1540` |
| **Recurring Rule Propagation on Edit** | ✅ 100% Compliant | `transaction_editor_screen.dart:75-91, 138-202` |
| **Idempotent Recurring Materialization** ($\pm 3$-day window) | ✅ 100% Compliant | `recurring_rule_repository.dart:104-154` |
| **Split Bills Ledger Cash Flow Contract** | ✅ 100% Compliant | `settle_up_sheet.dart:181-203`, `split_bill_model.dart:98-150` |
| **100% Offline ML Kit OCR** | ✅ 100% Compliant | `receipt_scanner_service.dart:26-58` |
| **WhatsApp Markdown Breakdown Sharing** | ✅ 100% Compliant | `split_share_service.dart:6-44, 65-79` |
| **Authentic Currency Badges & Metadata** | ✅ 100% Compliant | `app_constants.dart:17-46` |
| **SQLite WAL Mode & Performance Indexing** | ✅ 100% Compliant | `database_helper.dart:134-150` |
| **FAB Bottom Clearance** (`fabBottomPadding = 96.0`) | ✅ 100% Compliant | `financial_ledger_tab.dart:82`, `split_bills_tab.dart:146` |

---

## 4. Test Suite Verification & Quality Assurance

Automated unit, widget, and integration tests across the Finances & Split Bills domain were executed via `flutter test`. All **177 / 177 tests passed** with zero regressions.

### Key Passing Test Suites:
1. `test/split_bill_features_test.dart`:
   - Validates equal split share calculations with user included (`expect(bill.userShare, 4000.0)`).
   - Validates friend-paid liability calculations (`expect(bill.totalUserOwes, 3000.0)`).
   - Validates custom exact split allocations.
   - Validates WhatsApp breakdown formatting and payment info embedding.
   - Validates `SettleUpSheet` rendering and ledger checkbox behavior.
   - Validates `SettingsProvider.enableSavingsVault` toggling.
2. `test/financial_trash_and_sms_fetch_test.dart`:
   - Validates soft deletion to Trash and exclusion from active queries.
   - Validates `smsExists` returning true for soft-deleted and permanently purged tombstones.
   - Validates `restoreTransaction` undo idempotency without crashes.
   - Validates promotional & OTP message rejection rules.
   - Validates `SmsParser.resolveMessageDate` across 10-digit and 13-digit epochs.
3. `test/top_bar_search_and_sms_24h_sync_test.dart`:
   - Validates Top Bar transaction search mode, hiding scope pill and auto-focusing query input.
   - Validates 24-hour default scan options in `SmsImportSheet`.
4. `test/features/sms_and_recurring_overhaul_test.dart`:
   - Validates COMBANK, Amana Bank, HNB, Sampath, and People's Bank parsing.
   - Validates CEFTS self-transfer zero-burn category assignment.
   - Validates merchant cleaning and recurring keyword auto-detection.

---

## 5. Zero-Conflict Improvement Proposals & Modular Recommendations

While the domain operates cleanly and passes all invariants, the following decoupled, non-breaking enhancements are recommended for future implementation cycles:

### Work Package F1: Split Bill Ledger Deep-Link Navigation
- **Scope**: When a split bill is settled via `SettleUpSheet` and recorded in the Daily Operating ledger, store the generated `transactionId` in `split_bills.transactionId` and expose a 1-tap `[ View in Ledger ]` action chip in `SplitBillEditorScreen`.
- **Target Files**: `lib/features/finances/data/models/split_bill_model.dart`, `lib/features/finances/presentation/screens/split_bill_editor_screen.dart`.
- **Isolation**: Purely visual/navigation; 100% backward compatible.

### Work Package F2: Offline Multi-Currency Split Conversion
- **Scope**: Allow split participants to record shares in alternative currencies (e.g., EUR or USD during group travel) with a fixed user-defined conversion rate to the base ledger currency.
- **Target Files**: `lib/features/finances/data/models/split_bill_model.dart`, `lib/features/finances/presentation/screens/split_bill_editor_screen.dart`.
- **Isolation**: Self-contained in `split_bill_model.dart` and editor screen.

### Work Package F3: Multi-Merchant Receipt OCR Line-Item Breakdown
- **Scope**: Enhance `ReceiptScannerService` to parse individual item rows into selectable chips in `SplitBillEditorScreen`, allowing 1-tap participant assignment per dish or item.
- **Target Files**: `lib/features/finances/services/receipt_scanner_service.dart`, `lib/features/finances/presentation/screens/split_bill_editor_screen.dart`.
- **Isolation**: Service-level regex enhancement; zero impact on core ledger or database schemas.
