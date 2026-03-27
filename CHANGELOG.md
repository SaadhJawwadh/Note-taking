# Changelog

All notable changes to Note Book are documented here.

## [1.20.0] - 2026-03-27

### 🔒 Stability & Data Integrity (Critical Fixes)
- **Database Self-Healing**: If the encrypted database file is corrupted from a prior bad run, the app now automatically detects the corruption (SQLCipher Code 26), removes the corrupt file and WAL/SHM artifacts, and rebuilds a fresh database on the same launch — eliminating permanent crash loops.
- **Concurrent Initialization Lock**: Implemented a singleton Future lock in `DatabaseHelper.database` to guarantee `_initDB` runs exactly once per app session, preventing the race condition that caused SQLCipher HMAC page corruption.

### ✨ Backup Engine Overhaul (v9)
- **Complete Settings Export**: Backup export now captures **all** settings via `SettingsProvider.toBackupMap()`. Previous exports (v8 and earlier) were missing `noteViewMode`, `showFileConverter`, `customExpenseRules`, `customIncomeRules`, `preferredVideoFormat`, `preferredImageFormat`, `videoResolutionLimit`, and `keepMetadata`.
- **Settings Restore Hardened**: `restoreFromBackupMap` now calls setter methods (not direct field writes) ensuring all restored settings are atomically persisted to SharedPreferences.
- **Backup schema version → 9**. All v1–v8 backups import correctly.

### 🛠 Improvements
- **Animation Stability**: `AnimationLimiter` now correctly wraps the `CustomScrollView` (not slivers inside it) — resolving a `Hero._allHeroesFor` stack overflow during page transitions.
- **Workmanager cleanup**: Removed deprecated `isInDebugMode` parameter. `flutter analyze` → zero errors/warnings.

---

## [1.19.1] - 2026-03-26

### ✨ New Features
- **Streamlined UI/UX**: Removed the complex Kanban view in favor of a fast, high-performance List and Dynamic Grid interface inspired by Bundled Notes.
- **Dynamic Grid Layout**: Improved grid view with modern cards, better spacing, and subtle shadows for a premium feel.
- **Converter Lite Mode**: New optional "Lite Mode" for the File Converter that uses native mobile-friendly tools instead of the heavy FFmpeg engine — perfect for quick image conversions without the large download.
- **Converter in Toolbar**: The File Converter is now conveniently integrated into the main bottom navigation bar when enabled.

### 🛠 Improvements
- **Refined Selection Mode**: Long-pressing notes now instantly enters a more intuitive batch selection mode.
- **Modern Settings**: Re-designed the entire settings experience with categorized sections and a cleaner aesthetic.
- **Developer Consistency**: Enforced strict JVM 17 targets across all Android components for better stability and performance.

### 🐛 Bug Fixes
- **Build Errors**: Fixed several dependency and Kotlin compatibility issues that were preventing Android builds.
- **Tag Colors**: Fixed tag color synchronization in the note editor.

---

## [1.17.0] - 2026-02-27
- **Database Encryption at Rest**: The entire SQLite database (notes, financial transactions, period logs, SMS contacts) is now encrypted at rest using SQLCipher (256-bit AES).
- **Transparent Migration**: Existing unencrypted databases are automatically converted to the new encrypted format on the first app launch.
- **Improved Backup Security**:
  - The Android auto-backup rules (`backup_rules.xml` and `data_extraction_rules.xml`) now strictly exclude the device's secure keystore from being uploaded to Google Drive. The encryption key remains entirely offline, meaning your cloud backups cannot be decrypted by a malicious actor.
  - Device-to-device transfer (USB cable or direct Wi-Fi sync during phone setup) continues to correctly migrate the encryption keys to prevent data loss when upgrading devices.
- **Backup App Lock Hardening**: Security settings like `appLockEnabled` and `useBiometrics` are now explicitly ignored during a manual backup restore. This prevents an attacker from bypassing the app lock by importing a modified backup file where the lock is disabled.

## [1.16.2] - 2026-02-26

### 🐛 Bug Fixes
- **Q+ Transfer Expenses**: Fixed an issue where `ComBank_Q+` fund transfers were categorized ambiguously. They are now correctly identified as financial expenses.
- **Note Editor Layout**: Fixed corrupted blockquote and header padding caused by inherited inline-style overrides. Formats render natively using Material 3 text theming now.
- **Lint Cleanup**: Fixed deprecated `withOpacity` usages and unresolved flow control structures, passing a completely clean `flutter analyze`.

### 🛠 Security / DevOps
- **Release Fonts preserved**: Disabled aggressive Android resource shrinking (`isShrinkResources = false`) that was stripping bundled `Rubik` fonts in the GitHub Actions Android release build. Font rendering in production builds is now identical to local profiles.

---

## [1.16.1] - 2026-02-25
- **Calculator: Division-by-zero & invalid expressions**: Evaluating `1/0` or `0/0` previously stored `Infinity`/`NaN` as a transaction amount. These are now blocked — the calculator shows "Error" and "Use Value" closes without setting an amount.
- **Animation re-play on category filter**: Tapping a category chip in the Finances screen no longer re-animates the entire page from scratch (was caused by `AnimationLimiter` receiving a new `ValueKey` on every filter change).

### 🛠 Improvements
- **Snappier transitions**: All stagger durations reduced (375 ms → 220 ms), container fade-through 500 ms → 300 ms, slide offset 50 px → 24 px — matches M3 Expressive motion guidelines.
- **Transaction rows**: Individual transaction cards no longer play a stagger entrance on every filter tap. Dashboard cards (chart, summary, search, chips) still animate in once on initial page load.
- **Backup logging**: `print()` replaced with `debugPrint()` — production-safe and conforms to Flutter lint rules.

---

## [1.16.0] - 2026-02-25

### ✨ New Features
- **Inline Category Creation**: Create new spending categories directly from the transaction editor via a "+ New" chip. Quick dialog with name + colour picker; new category is auto-selected.
- **Category Management Link**: "Manage" button next to the "Category" label in the transaction editor navigates to the full Category Management screen. Changes are reflected immediately on return.
- **Rich Note Previews**: Home screen note cards now render bullet lists, headings, blockquotes, and other formatting via Markdown instead of plain text.
- **MRU Tag Sorting**: Tags on the home screen sort by most recently modified note, so active projects appear first.

### 🛠 Improvements
- **Instant Category & Search Filtering**: Financial manager filters categories and search in-memory — eliminates loading spinners and DB round-trips.
- **Smooth Fade-Through Transitions**: Opening/closing notes and transactions uses Material fade-through (500 ms) across all screens.
- **Staggered Animation Replay**: Switching category filters replays the staggered list entrance animation.
- **Unified Design System**: Notes, Finances, and Settings screens now share identical transition types, AppBar styling, FAB format (extended with label), empty-state colours, animation directions, and spacing.
- **Background Backup Logging**: Silent catches in auto-backup service replaced with logged errors (visible in logcat).

### 🔒 Security / DevOps
- **Auto versionCode from git tag**: CI computes `versionCode = major×10000 + minor×100 + patch`, guaranteeing Android accepts every update without uninstall.
- **Optional release signing**: GitHub Secrets support for `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`.
- **SHA-256 checksums**: Published alongside each release APK.
- **Updated CI actions**: `softprops/action-gh-release@v2` with optional `RELEASE_NOTES.md`.
- **Keystore files excluded**: `.gitignore` updated for `key.properties`, `*.jks`, `*.keystore`.

---

## [1.15.0] - 2026-02-25

### ✨ New Features
- **SMS Contacts Management**: Replaced the simple SMS Sender Whitelist with a full **SMS Contacts** screen (Settings → Financial Manager → SMS Contacts). View all 10 built-in Sri Lankan banks and any custom senders in a single grouped list.
- **Block / Unblock Senders**: Toggle any bank or custom sender on/off with a switch. Blocked senders are completely ignored during SMS import — useful for suppressing duplicate notifications (e.g. block "COMBANK Q+" but keep "COMBANK").
- **Cross-Sender Deduplication**: When the same amount appears from two different senders within a ±5-minute window, only the first transaction is imported. Eliminates duplicates from bank apps that send parallel SMS (e.g. COMBANK and COMBANK Q+ for the same purchase).

### 🛠 Improvements
- **Default import period**: Import SMS Transactions sheet now defaults to **"Last day"** instead of "Last 30 days" for faster routine syncs.
- **Backup v6**: Exports/imports `sms_contacts` table. v5 backups (with `smsWhitelist` key) are automatically migrated during import — no data loss.
- **Database v10**: `sms_contacts` table replaces `sms_whitelist`. Existing whitelist entries are migrated as custom contacts automatically on upgrade.

### 🔒 Security / Data Integrity
- Cross-sender dedup prevents inflated expense totals from duplicate bank SMS.
- Blocked senders checked before allowed senders in the parsing pipeline — blocking always wins.
- Backup version bumped 5 → 6; v1–v5 backups continue to import correctly.

---

## [1.14.2] - 2026-02-23

### 🛠 Improvements
- **Backup v5 — SMS Whitelist included**: The full backup now exports and restores the SMS sender whitelist alongside notes, transactions, categories, and settings. Previous backups (v1–v4) continue to import without issues.
- **Case-insensitive whitelist matching**: Sender IDs stored in the whitelist are matched case-insensitively against incoming SMS senders (`KOKO` matches `koko` and vice versa).
- **Reversal sentinel as a typed constant**: `SmsService.reversalSentinel` is now a public static constant; the hardcoded `'__reversal__'` string literal in `financial_manager_screen.dart` has been replaced.
- **README updated**: Features list now reflects v1.14.x additions — 10 categories, SMS Sender Whitelist, due-reminder filtering, and v5 backup.

### 🔒 Security / Data Integrity
- Backup version bumped 4 → 5; v1/v2/v3/v4 backups continue to import correctly.

---

## [1.14.1] - 2026-02-23

### ✨ New Features
- **SMS Sender Whitelist**: User-managed whitelist under **Settings → Financial Manager → SMS Sender Whitelist**. Add non-bank services (e.g. KOKO, FriMi) whose debit/credit SMS should be auto-imported. Banks are included by default and do not need to be added.

### 🛠 Improvements
- **Due-reminder SMS skipped**: Daily reminder messages (e.g. "Your KOKO payment is due tomorrow") are now ignored and never imported as transactions. Only SMS that contain an actual debit confirmation keyword are processed — eliminating the repeated KOKO entries.
- **Banks-only default whitelist**: Non-bank SMS senders (KOKO, FriMi, PayApp) removed from the built-in sender set. They can be re-added individually via the new whitelist screen.

### 🔒 Security / Data Integrity
- Database schema bumped to version 9; migration automatically creates the `sms_whitelist` table on existing installs — no reinstall required.

---

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
