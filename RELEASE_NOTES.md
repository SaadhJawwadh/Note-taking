### 🌟 What's New
- **Financial Trash Bin & Permanent Tombstones**: Soft-delete financial transactions with a 30-day auto-purge retention period and dedicated Financial Trash Bin modal.
- **Permanent SMS Tombstones**: Manually deleted SMS transactions write their `smsId` to permanent tombstone storage (`deleted_transaction_sms_ids`), preventing background auto-sync from re-importing deleted transactions.

### 🚀 Improvements
- **Expanded Bank SMS Auto-Import Engine**: Updated Sri Lankan bank SMS regex patterns and sender mappings for DFCC, NDB, Commercial Bank, HNB, Sampath, Union Bank, and HSBC with improved multi-currency and account number parsing.
- **WYSIWYG Note Editor Polish**: Integrated theme-aware text selection handles and cursor colors, refined rich-text delta-to-markdown conversion accuracy, and improved soft keyboard bottom inset handling.
- **App Lock Lifecycle Resilience**: Fixed app lock screen resume behavior in `MainActivity` on Android, ensuring seamless biometric session restoration without lockout loops.

### 🐛 Fixes & Tests
- **Comprehensive Test Suite**: Added complete unit test coverage for financial trash operations, soft deletion, and SMS import tombstone verification (`financial_trash_and_sms_fetch_test.dart`).
