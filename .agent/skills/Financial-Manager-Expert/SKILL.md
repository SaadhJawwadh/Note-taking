---
name: Financial-Manager-Expert
description: Specialist in the Financial Management module, handling transaction tracking, SMS automated logging, categories, and financial reporting.
---

## Use this skill when
- Modifying `lib/screens/financial_manager_screen.dart` or related component files.
- Updating `lib/data/transaction_model.dart` or `lib/data/transaction_category.dart`.
- Refining SMS parsing logic in `lib/services/sms_service.dart`.
- Adjusting financial search queries in `lib/data/database_helper.dart`.

## Relevant Files
- `lib/data/transaction_model.dart`
- `lib/data/transaction_category.dart`
- `lib/screens/financial_manager_screen.dart`
- `lib/services/sms_service.dart`
- `lib/services/sms_parser.dart` (Stateless regex parsing)
- `lib/services/sms_constants.dart` (Centralized bank regexes)
- `lib/data/database_helper.dart` (Financial queries)

## Instructions
- **SMS Pipeline**: Logic is decoupled into `SmsParser` (stateless parsing) and `SmsService` (permission/inbox management). Always centralize new bank regexes in `sms_constants.dart`.
- **Reversal Detection**: Use `SmsConstants.reversalSentinel` (`__reversal__`) to identify and auto-delete cancelled or refunded transactions.
- **Categorization**: Prefer user-defined rules over default keyword matching.
- **UI Architecture**: Financial components must integrate with the main `NavigationBar` if enabled.
- **Performance**: Use in-memory filtering for categories and search to ensure a "zero-lag" experience.
