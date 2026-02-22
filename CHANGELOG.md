# Changelog

All notable changes to Note Book are documented here.

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
