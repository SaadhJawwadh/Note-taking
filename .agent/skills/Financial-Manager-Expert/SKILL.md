---
name: Financial-Manager-Expert
description: Specialist in the Financial Management module, handling transaction tracking, SMS automated logging, categories, and financial reporting.
---

# Financial Manager Expert

Use this skill when modifying the financial dashboard, category management, transaction editor, or SMS auto-sync.

## 1. SMS Auto-Import Pipeline
* **Decoupled Architecture**: SMS logic is separated into `SmsParser` (pure stateless regex text extraction) and `SmsService` (listener, notification dispatcher, and database transactions).
* **Centralized Regexes**: All bank regexes, credit/debit keywords, and sender IDs must reside in `sms_constants.dart`.
* **SMS Deduplication**: Skip logs if another identical transaction occurred within $\pm5$ minutes (cross-sender/duplicate check).
* **Automatic Reversals**: Refund or reversal messages delete the matching target transaction within a 7-day window using the `__reversal__` sentinel.
* **Pre-Filtering & AI Parsing**: Use `isPotentiallyRelevant` filters (check amounts, keywords) to skip OTPs/cancellations before calling Gemini Nano. The AI parser must return clean merchant name, category, and direction (income vs expense) in one JSON payload.
* **Periodic Duration-Based Background Sync**: Use `Workmanager().registerPeriodicTask` for interval syncs (e.g., every 12 hours) to comply with Android Doze mode battery rules. For 24-hour daily sync, expose a conditional `Auto-Sync Time` picker and schedule initial delay using `calculateDailySyncDelay(timeStr)`.

## 2. Category & Keyword Rules
* **Case-Insensitive Validation**: Validate category names case-insensitively when creating/editing to avoid duplicate naming collisions.
* **Double-Level Matching**: Keywords match merchant names. Multi-word keywords (e.g. `"Keells Super"`) take precedence over single-word keywords (e.g. `"Keells"`) using cached matches.
* **Inline Calculator**: Support mathematical operators (+, -, *, /) directly inside the amount field via `CalculatorDialog`.

## 3. Home Screen Widget & Deep Linking
* **Android PendingIntent Re-use**: The Android OS caches `PendingIntents` using the destination Component and `requestCode` as keys. If deep link intent parameters (like custom action strings or extras) are modified, you MUST assign a new unique `requestCode` in the Kotlin widget provider to force the OS to invalidate its cache. Otherwise, the old intent action is run.
* **Startup Synchronization**: To prevent widgets from getting out-of-sync with Dart storage on app launch, call `WidgetHelper.updateWidgetData()` inside the App Home Screen's `initState()` to force update the widget's PendingIntents and shared states.


## 4. Recurring Transactions & Widget Analytics (v2.0)
* **Recurring rules**: `recurring_rules` table + `RecurringRuleRepository.materializeDueRules()` — idempotent, capped catch-up loop (36 periods max), advances `nextDue` with month-length clamping. Called at the top of the finance dashboard refresh; the transaction editor creates the rule only for NEW transactions ("Once/Daily/Weekly/Monthly" SegmentedButton); manage/delete via the sheet in Settings → Financial Manager. **Ledger is the first/default tab.**
* **Widget analytics tiers**: Dart (`WidgetHelper`) computes and writes prefs (spent today/month, NET + sign, budget % from summed `categoryBudgets`, top category); Kotlin renders by `OPTION_APPWIDGET_MIN_HEIGHT` tiers — stats always, budget bar ≥120dp (only when budgets exist), top category next, recent transactions ONLY ≥260dp. Use `NumberFormat('#,##0')` for thousands separators.
* **Widget freshness**: `updatePeriodMillis=1800000` redraws from prefs every ~30min; a 4h WorkManager task (`kWidgetRefreshTaskName`) recomputes prefs so TODAY rolls over at midnight. The task MUST keep its `initialDelay` (cold-start SQLCipher deadlock — see Tester skill).

## 5. Category Management & Custom Icons (v2.3)
* **Cascading Category Renaming**: Renaming a category must execute cascading SQLite updates across both `transactions` (`UPDATE transactions SET category = ... WHERE category = ...`) and `recurring_transactions` (`UPDATE recurring_rules SET category = ... WHERE category = ...`).
* **Custom Icon Persistence**: Store category icons as integer `iconCodePoint` in SQLite. Resolve icon displays using `TransactionCategory.iconFor(name)` with a `const Map<int, IconData>` lookup map to satisfy Flutter release tree-shaking rules.
* **Safe Category Deletion**: Non-'Other' categories can be deleted; always execute an automatic reassignment query updating past transactions and recurring rules to `'Other'` before dropping the category definition. 'Other' must remain protected from deletion.
