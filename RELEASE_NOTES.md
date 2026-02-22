# Note Book v1.12.0 — SMS Auto-Import & Transaction Categories

Finances just got smarter. Note Book can now read your bank SMS messages and automatically log transactions — no manual entry required.

## What's New

### 📲 SMS Auto-Import
- **Background import**: Incoming bank SMS messages are parsed and saved even when the app is closed.
- **Inbox sync**: Tap the sync icon in the Finances screen to import from your full SMS inbox, or go to **Settings → Financial Manager → Import SMS Transactions** to choose a date range (Last 7 days · Last 30 days · Last 3 months · All time).
- Supports Commercial Bank, Peoples Bank, HNB, Sampath, BOC, NDB, Seylan, and Amana Bank sender IDs.
- Deduplication is built-in — syncing multiple times won't create duplicates.

### 🏷 Transaction Categories
- Transactions are automatically categorised: **Transport, Food & Dining, Subscriptions, Shopping, Utilities, Health, Entertainment, Other**.
- Categories are detected by keyword matching the SMS body (e.g. "PickMe" → Transport, "Netflix" → Subscriptions).
- Each transaction card shows a **colour-coded badge** for its category.
- Override the auto-detected category in the transaction editor using the new **chip picker**.

### 🔍 Category Filter Chips
- A horizontal filter row on the Finances screen lets you isolate any single category.
- Only categories that have transactions in the current date range are shown.
- When a filter is active and produces no results, an inline **"Clear filter"** button appears.

### 📅 Finances Default Period
- The Finances screen now opens to the **current calendar month** by default.

## 🛠 Improvements & Fixes
- Release APKs are now built with **R8 minification + resource shrinking** — smaller, faster installs.
- `ThemeMode` crash fix when restoring from malformed backup files.
- All async callbacks now have `mounted` guards preventing errors on navigation.
- CI: corrected APK filename and enabled ProGuard for release builds.

---

*Fully local. No data leaves your device.*
