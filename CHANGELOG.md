# Changelog

All notable changes to Note Book are documented here.

## [1.14.0] - 2026-02-23

### ✨ New Features
- **Payments & Deposit Categories**: Two new built-in transaction categories covering instalments, EMI, KOKO buy-now-pay-later, loan repayments (Payments) and bank deposits, salary, and credited income (Deposit).
- **Smarter SMS Descriptions**: Descriptions are now structured and human-readable instead of raw scraped text:
  - Bank deposits → `"Deposit of 10,000 in Commercial Bank"`
  - Card purchases → `"Purchase at PickMe Food 1,559"`
  - KOKO/instalment → `"KOKO Instalment Simplytek"`
  - Fund transfers → `"Transfer to Recipient 5,000"`
  - ATM withdrawals → `"ATM Withdrawal 15,000"`
- **Cancelled + Reversed Orders Auto-Delete**: SMS messages that are both cancelled *and* reversed (e.g. a cancelled PickMe Food order refund) now correctly delete the original expense — previously they were silently ignored.
- **Bare Amount Parsing**: Instalment/due-reminder SMS messages without an LKR/Rs prefix (e.g. `"of 7895.98"`) are now parsed correctly.
- **Expanded Bank & Provider Whitelist**: Added KOKO, Nations Trust Bank (NTB), LOLC, FriMi, and PayApp to the recognised sender list.
- **Category Definitions in Backup**: Backups are now v4 — custom categories (names, keywords, colours) are exported and fully restored. Restoring a backup also reloads the in-memory category cache immediately.
- **Adaptive Colour Swatch Check**: The checkmark icon on colour swatches in the category editor now uses white or black based on the swatch's luminance, ensuring legibility on both light and dark colours.

### 🛠 Improvements
- `purchase`, `authorised`, `authorized` added to debit keyword list for broader card transaction detection.
- URL stripping added to PII removal so confirmation links never pollute descriptions.
- Masked card numbers with `#` prefix (e.g. `ending #4525`) now correctly stripped.
- Order ID / Order # patterns added to PII removal regex.
- Amount formatting: trailing `.00` dropped, thousands separator added (e.g. `10,000`).

### 🔒 Security / Data Integrity
- Database schema bumped to version 8; migration automatically adds Payments and Deposit categories to existing installs — no reinstall required.
- Backup version bumped 3 → 4; v1/v2/v3 backups continue to import correctly.

---

## [1.13.0] - 2026-02-22

### ✨ New Features
- **Custom Category Management**: Create your own transaction categories with a custom name, colour, and keywords. Built-in categories' keywords are also fully editable. Accessible from **Settings → Financial Manager → Manage Categories**.
- **Transaction Search**: Search bar on the Finances screen filters transactions by description or category in real time.
- **Date-Range Net Card**: The hero card at the top of the Finances screen now shows the net balance for the *currently selected date range* instead of an all-time figure.
- **Long-Press to Delete Transactions**: Long-press any transaction card for a confirmation dialog to delete it.
- **Note Checklist Preview**: Quill checklist items now appear with ☐ / ☑ symbols in home-screen note cards.
- **Note Preview Line Truncation**: Note card previews now show up to 4 lines of content (rich text and markdown) instead of a fixed character count.

### 🛠 SMS Import Improvements
- **Promotional SMS Skipped**: Messages matching promo/offer patterns (and lacking a real debit/credit keyword) are ignored.
- **Cancellation SMS Skipped**: Messages containing "cancelled", "transaction failed", "declined", etc. are not imported.
- **Reversal / Refund Handling**: Reversal SMS messages automatically delete the original expense within a 7-day window; no duplicate credit entry is created.
- **Better Income Detection**: Expanded credit keyword matching to catch salary, fund transfer, payment received, incoming transfer, and cash deposit.
- **Compound Keyword Priority**: Multi-word keywords are tested before single-word ones. "PickMe Food" → Food & Dining; "PickMe Ride" → Transport; "Uber Eats" → Food & Dining; "Uber" → Transport.

---

## [1.12.1] - 2026-02-22

### 🛠 Improvements & Fixes
- **SMS deduplication hardened**: Replaced two-step `smsExists` + `createTransaction` pattern with a single `createSmsTransaction` call backed by `ConflictAlgorithm.ignore`. Eliminates the race condition between the background isolate and foreground sync both passing the existence check before either insert completes.
- **SMS import period parity**: The "Import SMS Transactions" sheet in Settings now includes a "Last day" option, matching the period options in the Finances sync sheet.
- **Dead code removed**: Unused `syncInbox()` method removed from `SmsService`; all callers now use `syncInboxFrom(DateTime)`.

---

## [1.12.0] - 2026-02-22

### ✨ New Features
- **SMS Auto-Import**: Automatically detect and import bank transactions from incoming SMS messages. Works in the background (no app open required) via a dedicated Android broadcast receiver.
- **Transaction Categories**: 8 categories — Transport, Food & Dining, Subscriptions, Shopping, Utilities, Health, Entertainment, Other — auto-assigned by keyword matching from Sri Lankan bank SMS formats.
- **Category Filter Chips**: Horizontal filter row on the Finances screen. Only categories that have actual transactions in the selected date range are shown.
- **Category Picker in Editor**: Colour-coded FilterChip grid in the transaction editor to manually set or override the auto-detected category.
- **Category Badges**: Each transaction card shows a colour-coded pill badge for its category.
- **Settings → Import SMS Transactions**: Manual one-tap import from Settings with a period selector (Last 7 days / Last 30 days / Last 3 months / All time).
- **Finances Sync Button**: Quick-sync icon in the Finances AppBar triggers an inbox scan.
- **Real-time Foreground Listener**: New bank SMS received while the app is in the foreground is parsed and added instantly.

### 🛠 Improvements
- Default date range on the Finances screen changed from "today only" to the current calendar month.
- Context-aware empty state: when a category filter is active with no results, a "Clear filter" button appears inline.
- SMS deduplication via a stable composite `smsId` (message id + timestamp) prevents duplicate imports.
- `mounted` guards added to all async UI callbacks to prevent setState-after-dispose crashes.

### 🔒 Security / DevOps
- Release APKs now built with R8 minification + resource shrinking (`isMinifyEnabled = true`, `isShrinkResources = true`).
- ProGuard keep-rules added for Telephony, permission_handler, and sqflite plugins.
- CI: removed `--no-shrink` override; corrected APK filename (removed double-`v` regression).
- Dart SDK constraint tightened to `>=3.6.0 <4.0.0`; Flutter minimum pinned to `>=3.27.0`.
- `ThemeMode` restore from backup now bounds-checked (crash fix for malformed backup files).

---

## [1.11.1] - 2025-12-30

### 🐛 Fixes
- Patch stability release addressing minor regressions in the financial dashboard date display.

---

## [1.11.0] - 2025-12-28

### ✨ New Features
- **Advanced Date Filtering**: Tap the calendar icon in Finances to pick any custom date range.
- **Dynamic Dashboard**: Income, expense, and net-balance summary cards update in real time for the selected period.
- **6-Month Bar Chart**: Spending trend sparkline added to the dashboard.

### 🛠 Improvements
- All-time net-balance card added to the top of the Finances screen.
- Performance: in-memory transaction filtering optimised.

---

## [1.10.0] - 2025-12-25

### ✨ New Features
- **Google Cloud Backup**: Automatic device and cloud backup via Android's `data_extraction_rules.xml` (includes database and SharedPreferences).
- **Full Backup/Restore v3**: Backup JSON now includes settings (theme, currency, font, grid layout).

### 🛠 Improvements
- Backup confirmation dialog previews note/tag/transaction counts before importing.
- Duplicate transaction detection via content fingerprint.

---

## [1.9.0] - 2025-12-23

### ✨ New Features
- **Financial Manager**: Dedicated expense and income tracker.
- **Built-in Calculator**: Compute amounts directly in the transaction editor.
- **Currency Selection**: Choose your preferred currency in Settings → Financial Manager.
- **Transactions Backup**: Export/import now includes the full transactions table.

---

## [1.8.0] - 2025-12-22

### ✨ New Features
- **Trash / Soft Delete**: Deleted notes go to Trash and can be restored.
- **Archive**: Move notes out of the main list; view via Settings → Archive.
- **Manage Tags**: Rename or delete tags globally from Settings → Content.

---

## [1.7.0] - 2025-12-22

### ✨ New Features
- **Rebranding**: App title updated to "Note Book".
- **Adaptive Formatting**: Quote and Code blocks adapt to the note's page colour.
- **Home Screen Thumbnails**: Images display as compact rounded thumbnails on note cards.
- **Uniform Toolbar**: Bottom formatting toolbar now has uniform icon spacing.

### 🐛 Fixes
- Fixed `RenderFlex` overflow crash on Home Screen note cards.
- Standardised image alignment across the app.

### 🧹 Maintenance
- Removed unused legacy styling code.
- Verified 0 analysis issues.
