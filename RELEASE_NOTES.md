# Note Book v1.12.1 — SMS Deduplication Hardening

Patch release focused on reliability and consistency of SMS transaction import.

## What's Fixed

### Deduplication Race Condition
Previously, if the background SMS broadcast receiver and a manual foreground sync ran at the same time, both could pass an existence check before either insert completed — resulting in a duplicate transaction. This is now fixed: a single atomic `INSERT OR IGNORE` at the database level guarantees that the same SMS can never be imported more than once, even under concurrent access.

### SMS Import Period Parity
The **Settings → Financial Manager → Import SMS Transactions** sheet now includes a **Last day** option, consistent with the period options in the Finances screen sync sheet.

### Code Cleanup
Removed the unused `syncInbox()` method from `SmsService`. All import flows now use `syncInboxFrom(DateTime)`.

---

*Fully local. No data leaves your device.*
