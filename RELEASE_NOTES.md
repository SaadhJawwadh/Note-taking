# Note Book v1.14.2 — QA Hardening & Backup Completeness

## What's New

### SMS Sender Whitelist (Settings → Financial Manager)
Add any non-bank sender ID (e.g. **KOKO**, FriMi) to auto-import their debit/credit messages. Banks are always included by default. Changes take effect immediately without restarting the app.

| Action | How to do it |
|--------|-------------|
| Add a sender | Settings → Financial Manager → SMS Sender Whitelist → type ID → **Add** |
| Remove a sender | Long-press (or tap trash icon) on any entry in the list |

### KOKO Repeat Entries — Fixed
KOKO's daily "due tomorrow / due today" reminders were each imported as separate transactions. They are now silently skipped. Only SMS containing an actual debit confirmation are processed.

### Backup Now Includes SMS Whitelist
Backups are now **version 5**. Your custom sender whitelist is exported and fully restored along with notes, transactions, and categories. All previous backup versions (v1–v4) continue to import without issues.

### QA Hardening
- Whitelist sender matching is now **case-insensitive** — adding `koko` matches SMS from `KOKO` and vice versa.
- Reversal sentinel value exposed as a typed constant (`SmsService.reversalSentinel`) — eliminates duplicate string literals in the codebase.
- 0 analysis issues · Clean 69 MB release APK

## Upgrade Guide

**From any previous version**: Install the new APK. The database and backup format migrate automatically — no data is lost and no reinstall is needed.

---

*Fully local. No data leaves your device.*
