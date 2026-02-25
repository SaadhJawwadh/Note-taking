# Note Book v1.15.0 — SMS Contacts, Cross-Sender Dedup & Blocking

## What's New

### SMS Contacts (Settings → Financial Manager)
The old **SMS Sender Whitelist** is now a full **SMS Contacts** screen. All 10 built-in Sri Lankan banks and your custom senders appear in a single grouped list with toggle switches.

| Action | How |
|--------|-----|
| Block a sender | Tap the switch next to any bank or custom sender to turn it off |
| Unblock a sender | Tap the switch again to re-enable importing |
| Add a custom sender | Type the sender ID (e.g. KOKO) and tap **Add** |
| Remove a custom sender | Tap the delete icon next to a custom entry |

### Cross-Sender Deduplication
When the same amount appears from two different senders within **5 minutes** (e.g. COMBANK and COMBANK Q+ for the same purchase), only the first transaction is saved. No more duplicate entries from parallel bank SMS.

### Default Import = Last Day
The Import SMS Transactions sheet now defaults to **"Last day"** instead of "Last 30 days" for faster daily syncs.

### Backup v6
Backups now export the full `sms_contacts` table (banks + custom senders + block states). Restoring a v5 backup automatically migrates old whitelist entries as custom contacts. All previous backup versions (v1-v5) continue to import correctly.

## Upgrade Guide

**From any previous version**: Install the new APK. The database migrates automatically from v9 to v10 — existing whitelist entries become custom contacts, and 10 banks are seeded. No data is lost and no reinstall is needed.

---

*Fully local. No data leaves your device.*
