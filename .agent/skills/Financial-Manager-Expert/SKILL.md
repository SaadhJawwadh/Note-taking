---
name: Financial-Manager-Expert
description: Specialist in the Financial Management module, handling transaction tracking, SMS automated logging, categories, and financial reporting.
---

# Financial Manager Expert

Refer to [design.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/UI-UX-Specialist/design.md#b-financial-manager-engine) for M3 Expressive financial UI components, Split Buttons, Inter tabular typography rules, and ledger list specifications.

## Core Module Operational Rules
* **SMS Auto-Import Pipeline**: Decoupled `SmsParser` (regexes in `sms_constants.dart`) and `SmsService`. 5-minute transaction deduplication window. Reversals delete matching transaction within 7 days. Periodic 12-hour WorkManager sync.
* **Category & Keyword Matching**: Case-insensitive validation. Multi-word keywords take precedence over single-word keywords. Non-'Other' category deletion auto-reassigns past transactions to `'Other'`.
* **M3 Expressive UI & Typography**: Quick logging uses M3 **Split Buttons** (`+ Add Expense` paired with `+ Add Income` dropdown). All financial figures, ledgers, and balances use **`Inter`** with tabular figure formatting (`fontFeatures: [FontFeature.tabularFigures()]`). Analytics sub-navigation uses `SegmentedButton`.
* **Recurring Transactions & Home Widget**: `recurring_rules` table materialized via `RecurringRuleRepository.materializeDueRules()`. Android widget updates via `WidgetHelper` and WorkManager task (`kWidgetRefreshTaskName`).
* **On-Device Trend Forecasting**: Exponentially-Weighted Linear Regression ($w_i = \gamma^{n-1-i}$) with Huber-style outlier dampening ($Z > 1.8\sigma$).
