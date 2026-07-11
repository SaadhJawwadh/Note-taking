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

## 2. Category & Keyword Rules
* **Case-Insensitive Validation**: Validate category names case-insensitively when creating/editing to avoid duplicate naming collisions.
* **Double-Level Matching**: Keywords match merchant names. Multi-word keywords (e.g. `"Keells Super"`) take precedence over single-word keywords (e.g. `"Keells"`) using cached matches.
* **Inline Calculator**: Support mathematical operators (+, -, *, /) directly inside the amount field via `CalculatorDialog`.

## 3. Home Screen Widget & Deep Linking
* **Android PendingIntent Re-use**: The Android OS caches `PendingIntents` using the destination Component and `requestCode` as keys. If deep link intent parameters (like custom action strings or extras) are modified, you MUST assign a new unique `requestCode` in the Kotlin widget provider to force the OS to invalidate its cache. Otherwise, the old intent action is run.
* **Startup Synchronization**: To prevent widgets from getting out-of-sync with Dart storage on app launch, call `WidgetHelper.updateWidgetData()` inside the App Home Screen's `initState()` to force update the widget's PendingIntents and shared states.

