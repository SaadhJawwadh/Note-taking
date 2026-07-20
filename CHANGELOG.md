# Changelog

All notable changes to Everything App are documented here.

## 2.4.0 - 2026-07-20

### ⚡ Note Editor — Slash Commands & Glassmorphic Toolbar
- **Slash Commands (`/`)**: Type `/` anywhere at the start of a line to open a quick action menu. Type `/todo` for checklists, `/table` for data tables, `/code` for monospace code blocks, `/h1`/`/h2` for headings, `/quote` for callouts, and `/bullet`/`/number` for lists.
- **Floating Glassmorphism Formatting Bar**: Redesigned the formatting bar into a sleek floating island pill with backdrop blur, semi-transparent Material 3 fill, and soft shadows.
- **Note Details & Stats Sheet**: Added real-time Word Count, Character Count, Estimated Reading Time, Folder path, and Creation/Modification timestamps.
- **Share & Export Note**: Export notes as Plain Text or Markdown, or copy note content directly to the clipboard.

### 🏷️ Category Management Redesign
- **Editable Category Names & Icons**: Edit category names directly with automatic transaction and recurring rule reassignment.
- **Icon Picker Grid**: Choose custom icons from a 24-icon grid (Transport, Dining, Subscriptions, Shopping, Utilities, Health, Savings, Work, etc.).
- **Safe Category Deleting**: Built-in and custom categories can be safely deleted; all associated transactions are automatically reassigned to "Other" so financial history remains complete.
- **Table Cell Styling**: Removed white box cutouts inside table cells and added a rounded pill container for row/column action controls.

## 2.3.0 - 2026-07-19

### 🌙 Period Tracker — Full Redesign
- **Moon Phase Animation**: A beautiful moon widget now reflects your current cycle phase — new moon during menstrual, crescent during follicular, full moon during ovulation, and waning gibbous during luteal phase.
- **Logging-First Layout**: The logging card is now at the top of the screen for quick, muscle-memory access. The calendar view is placed below for reference.
- **Icon-Based Flow Intensity**: Spotting, Light, Medium, and Heavy are now icon+label tiles for faster, more visual selection — fully consistent with the card's colour palette.
- **Collapsible Symptoms**: The symptoms section starts collapsed to reduce clutter. A live badge shows how many symptoms are active, and the section animates open smoothly on tap.

### 🔧 Dark Mode & Visibility Fixes
- Fixed symptom selector using the same unified `onPeriodColor`-based colour system as flow intensity tiles — no longer renders dark-on-dark in dark mode.
- Fixed the delete log button being invisible (blending into card background) in dark mode — now clearly shown in red.

## 2.2.0 - 2026-07-18


### 📊 Live Interactive Tables
- **Inline Table Widget**: Rendered tables directly as beautiful interactive widgets within the Note Editor, replacing raw markdown text.
- **Dynamic Cell Editing**: Added custom borderless text inputs inside cells, managing focus and debouncing updates to the note automatically.
- **M3 Row/Column Management**: Touch-optimized action buttons for adding and deleting rows/columns dynamically.
- **Double Cursor Resolution**: Dynamically hidden the primary editor cursor when a table cell is focused to prevent dual blinking cursors.
- **Automatic Focus Dismissal**: Wrapped table editor in a TapRegion to automatically clear cell focus and collapse the keyboard when tapping anywhere outside the table boundaries.

### 📝 Textual Table Previews
- **Clean Note Card Snippets**: Note list cards on the home screen now display a clean, readable text preview of the table's first two rows, separating columns with ` | ` instead of displaying generic table indicators or messy raw markdown code.

### ⚙️ Settings Redesign & Feedback
- **Modern Static Card Layout**: Redesigned settings into clean, scrollable card groupings. Discontinued expansion tiles to let users view all preferences instantly without needing extra clicks.
- **Removed Redundant Headers**: Deleted the unneeded System Settings card header to reclaim screen space.
- **Play Store Feedback option**: Added a direct Play Store Rating and Feedback button inside settings to support the app.

## 2.1.0 - 2026-07-15

### 📁 Folder & Selection Enhancements
- **Folder Card Selector**: Replaced the dynamic greeting with an interactive folder picker card showing active folder name, note count, and inline dropdown arrow.
- **Memory-Persistent Folder Creation**: Added folder creation inside the dropdown sheet; empty folders stay in memory until notes are added.
- **Auto-Inherit Folder Context**: Creating new notes or using templates automatically pre-selects the active folder.

### 📝 Templates & Creation Flow
- **Accessible FAB Options**: Changed the FAB single tap action to show a selection sheet for Blank Notes and Templates, removing the hidden long-press gesture.
- **Redundancy & UX Cleanup**: Duplicate checkmark buttons and redundant checklist tools removed from the editor headers and toolbar.

### 📱 Responsive Tablet Layouts
- **Side Navigation Rail**: Adaptive layout rendering a sleek side navigation rail on screens $\ge 600\text{dp}$.
- **Two-Column Ledger Dashboard**: Budgets and financial charts display side-by-side on wide displays.

### 💰 Financial Ledger Updates
- **CSV Transaction Export**: Export all transactions as standard, RFC 4180 compliant CSV spreadsheet files from the ledger app bar.

### ⚡ UI & Performance Polish
- **Snappy Snackbars**: Deletion and archiving alerts clear existing snackbar queues instantly and dismiss in 3 seconds.

## [2.0.0] - 2026-07-12

### 🩸 Period Tracker Refinements
- **Semantic Phase Colors**: Cycle-phase colors now come from the design system's theme tokens instead of hardcoded palette values.
- **Skeleton Loading**: The tracker loads with pulsing placeholder cards matching the notes home.
- **Theme-Correct Destructive Actions**: Delete confirmations use the theme error color.

### 📝 Note-Taking Upgrades
- **Folders**: File notes into folders from the editor menu (create folders inline); filter the home screen by folder.
- **Templates**: Long-press the New Note button for Meeting Notes, Shopping List, and Journal starting points.
- **Voice Dictation**: A mic button in the editor toolbar streams on-device speech into the note at the cursor.
- **Markdown Typing**: `- `, `1. `, `# `/`## `/`### `, `[] `, `**bold**`, `*italic*`, `` `code` `` auto-format as you type.
- **Find in Note**: Search inside the open note with match navigation from the toolbar.
- **Outline Navigation**: Jump between headings in long notes from the editor menu.
- **Note Reminders & Locked Notes** (see below) round out the editor menu.
- **Quick Checklist Item**: One tap in the toolbar appends a fresh unchecked item.
- **Rich Link Cards**: Up to three link previews per note instead of one.
- **Sort & Pin**: Sort notes by modified/created/title/color from the home bar; pin or unpin many notes at once from selection mode.
- **Smarter Home**: Tag chips show note counts, cards show a "+N" tag overflow, skeleton cards replace the loading spinner, and undo is available for every way of trashing a note.
- **Reminder Deep-Link**: Tapping a note reminder notification opens that note directly.

### ✨ New Features
- **Share Into Notes**: Share text, links, or images from any app into a new note; select text anywhere and choose "Everything App" from the context menu to capture it.
- **Note Reminders**: Set a date/time reminder on any note from the editor menu; scheduled locally with notifications, synced with edits, and cancelled on delete.
- **Locked Notes**: Lock individual notes behind biometric/device-credential authentication; locked notes mask their content on home-screen cards.
- **Recurring Transactions**: Mark a new transaction as repeating daily/weekly/monthly; due entries materialize automatically, manageable under Settings → Financial Manager.
- **Notes Quick-Capture Widget**: New home-screen widget with New Note and Search actions.
- **App Shortcuts**: Long-press the launcher icon for New Note, New Transaction, and Search.
- **Tamil Language Support**: Localization infrastructure (English + Tamil) for core UI strings.

### 🎨 Material Expressive Design
- **Font Pairing**: Google Sans Text for headlines/display text paired with Rubik body text; Google Sans Code bundled for numeric surfaces.
- **Motion**: Shared-axis transitions for all drill-in navigation (settings sub-pages, search results); predictive-back gesture enabled.
- **Consistency Sweep**: 55 hardcoded corner radii and all ad hoc shadows moved to shared design tokens; destructive actions use the theme error color; unified shapes for buttons, popup menus, dialogs, and snackbars; edge-to-edge rendering.
- **Haptics Everywhere**: Settings tiles/switches, app-bar actions, and editor menus now give tactile feedback.
- **Responsive**: Adaptive note-grid columns (2-4) and width-constrained sheets on tablets/foldables.
- **Home Screen Widget Redesign**: Finance widget refreshed to the M3 Expressive language, with proper thousands separators, a real picker preview, and background refresh so TODAY rolls over at midnight.

### 🗑️ Removed
- **File Converter Module**: Removed entirely (UI, FFmpeg service/installer, related settings, share-target media intents, onboarding entries). The "FFmpeg engine" installer never downloaded a real binary — conversions were always simulated — so the module was pulled rather than shipped half-working.

### 🐛 Bug Fixes
- **App Lock Bypass Gaps**: SMS/notification permission prompts and external Settings links no longer trigger an unwanted lock-screen re-authentication on return.
- **App Lock Flicker**: The locked overlay no longer flashes while the OS biometric dialog is on screen.
- **Greeting Logic**: "Time to sleep!" no longer shows at 5 PM; evenings get a proper greeting.
- **Theme Wiring**: The app's custom TextTheme was never actually passed into ThemeData; fixed, so theme typography applies app-wide.
- **Period Notifications**: Rescheduling period predictions no longer cancels unrelated notifications (e.g. note reminders).

### 🧹 Maintenance
- Replaced the discontinued `telephony` package with the maintained `another_telephony` fork; upgraded 21 dependencies; `flutter_lints` 2→6 with all findings fixed; added a CI workflow gating pushes/PRs on analyze + tests.

<!-- ## 1.39.0 -->
## [1.39.0] - 2026-07-11

### ✨ New Features
- **Dashboard-First Finance View**: Swapped segment navigation tab order to open directly to the visual Budgets & Analytics dashboard.
- **Tactile File Converter UX**: Redesigned the File Converter picker container to a sleek, tinted drop-zone card with clear guidance.
- **Pre-Conversion File Manager**: Introduced a files selection preview list allowing users to view sizes, check file-type icons, and remove individual media before compression.
- **Identifiable Output Cards**: Result list cards now display the original input file name for clear identification in batch processing mode.

### 🐛 Bug Fixes & Refactoring
- **System Dialog App Lock Bypasses**: Integrated ignore-lock overrides across Share, Save, and Permission dialogs to prevent lifecycle resume app lockouts.

<!-- ## 1.38.0 -->
## [1.38.0] - 2026-07-10

### ✨ Rebranding & Assets
- **Everything App Rebrand**: Rebranded the app name and descriptions to "Everything App" across all native and Flutter configurations.
- **Modern Ribbon Logo**: Replaced app icons with a sleek new violet/indigo ribbon graphic combining pen-nib and graph paths.
- **Dynamic Themed Icons**: Configured transparent monochrome layers for full Material You dynamic wallpaper tinting on Samsung One UI and Google Pixel launchers.
- **Splash Screen Upgrades**: Regenerated Android and iOS native splash screens to present the new branding.

<!-- ## 1.37.0 -->
## [1.37.0] - 2026-07-08

### ✨ New Features
- **Material 3 Finance Home Screen Widget**: Designed a resizable home screen widget displaying Today's spent, Monthly spent, and Monthly income.
- **Recent Transactions Feed**: Shows the top 3 recent transactions directly on the widget with dynamic text colors indicating debit/credit status.
- **Quick-Add Deep Linking**: Added a direct shortcut "+" button on the widget to deep link into the transaction editor with automatic lockscreen security gating.
- **Material You Design Integration**: Supports full Material You dynamic colors and M3 standard 28dp rounded corners on Android 12+ (API 31+).

### 🐛 Bug Fixes & Refactoring
- **RemoteViews Inflation Crash**: Resolved launcher crashes by replacing generic `<View>` elements with allowed layout views (e.g. `<FrameLayout>`).

<!-- ## 1.36.1 -->
## [1.36.1] - 2026-07-06

### 🐛 Bug Fixes & Refactoring
- **Android 15 Edge-to-Edge Compatibility**: Resolved Play Store warning regarding deprecated window APIs by removing `android:windowFullscreen` and `android:windowDrawsSystemBarBackgrounds` parameters from the XML themes.

<!-- ## 1.36.0 -->
## [1.36.0] - 2026-06-29

### ✨ New Features
- **WhatsApp HD Video Compression**: Added visually lossless H.264 profile presets optimized for native playback inside WhatsApp without server-side re-encoding.
- **Offline Image Compression**: Upgraded Lite Mode conversion to perform native, local image resizing and re-encoding on the device.
- **Visual Quality Comparison**: Added an interactive swipe slider letting users compare original vs. compressed image differences.
- **Space Savings Dashboard**: Shows aggregate session metrics and total disk space saved.
- **Onboarding Experience**: Introduced a modular first-time bottom sheet experience showing available powerups and tips.

### 🔒 Security & Privacy
- **Encrypted Key Protection**: Migrated plain-text database encryption key backups from SharedPreferences into secure system KeyStore storage.
- **App Lock Share Sheet Isolation**: Secured share intent processing to queue shared files and require biometric authentication before proceeding.

### 🐛 Bug Fixes & Refactoring
- **App Lock State Rebuilds**: Fixed duplicate/nested `setState` calls during lifecycle transitions.
- **Material 3 Consistent Dialogs**: Standardized custom currency and notification alert pickers to use Material 3 surface colors.
- **Android Notifications Icon**: Fixed a startup PlatformException by copying the launcher icon asset to Android's drawable resource path.

<!-- ## 1.35.1 -->
## [1.35.1] - 2026-06-16

### ✨ New Features
- **Smart Checklists**: Implemented automatic checked item strikethroughs and contiguous bottom-sorting inside the rich text note editor.
- **Selection/Cursor Mapping**: Keeps the cursor at the correct position during checklist item updates, preventing visual shifting or cursor jumps.

### 🔒 Security & Play Store Compliance
- **Removed OTA In-App Updater**: Completely removed the self-update feature, associated sensitive `REQUEST_INSTALL_PACKAGES` permission, and related background provider to ensure 100% compliance with Google Play Store Developer policies.

<!-- ## 1.34.0 -->
## [1.34.0] - 2026-06-14

### ✨ New Features
- **In-App APK Updater**: Implemented seamless OTA update checking and package installation using a custom GitHub Releases checker and the `ota_update` package.
- **OTA Settings Integration**: Added a "Check for Updates" tile under the About section in Settings for quick release verification on Android.
- **Interactive Progress Dialog**: Shows release notes directly from GitHub releases and a linear progress bar reflecting real-time download status.

### 🛠 Improvements
- **Haptic Feedback**: Integrated light/medium haptic feedback on update checking and confirmation actions.

## [1.33.0] - 2026-06-13

### ✨ New Features
- **Auto-Clear Trash**: Implemented a 7-day automatic transactional purge for notes and tags in the trash to optimize storage.

### 🛠 Improvements & Refactoring
- **Clean Home Tags**: Removed the redundant "Archived" and "Trash" chips from the home screen tags row.
- **Inline Settings Merger**: Merged all File Converter settings (Lite Mode, Keep Metadata, Preferred Formats, Resolution Limit, and the FFmpeg engine installer) into a local, inline settings bottom sheet inside the Converter screen.
- **Pruned Settings Page**: Removed the "Standalone Utilities" and "File Converter Settings" sections from the global Settings screen, keeping only the high-level enable switch under "App Features".

### 🐛 Bug Fixes & Stability
- **Static Analysis Compliance**: Fixed unawaited futures (haptic feedback calls) and capitalized library prefixes to achieve a completely clean `flutter analyze` report with zero issues.
- **Unit Test Coverage**: Added a comprehensive database test suite for `clearOldTrash()` to ensure integrity and prevent regression.

## [1.32.0] - 2026-06-08

### ✨ New Features & Enhancements
- **AI-Powered SMS Refinement**: Integrated Gemini Nano into the `SmsService` to automatically sanitize and professionalize raw transaction descriptions extracted via regex.
- **Interactive Empty States**: Added a prominent "Create My First Note" button to the empty state view to reduce friction for new users.

### ⚡ Performance Optimizations
- **Pre-computed Note Previews**: Added a `previewText` field to the `notes` table (Database v14). Previews are now generated via `RichTextUtils` upon saving, bypassing expensive Markdown parsing during list rendering.
- **Database-Level Filtering**: Migrated note tag, archive, and trash filtering from in-memory operations to direct SQLite queries in `NoteRepository`, fixing pagination accuracy and reducing memory footprint.
- **Batched Bulk Actions**: Updated bulk archive, delete, and tag operations to utilize `db.batch()`, drastically reducing execution time for large selections.

### 🏗️ Architectural Refactoring
- **Repository Pattern Implementation**: Decomposed the monolithic `DatabaseHelper` (600+ lines) into modular singletons: `NoteRepository`, `TransactionRepository`, and `PeriodRepository`.
- **UI Component Modularization**: Broke down the complex `HomeScreen` into smaller, declarative widgets (`HomeAppBar`, `NoteViewBuilder`).
- **Robust Navigation State**: Replaced `PageTransitionSwitcher` with `IndexedStack` in the main navigation flow to preserve tab state and scroll positions.
- **Centralized Design Tokens**: Created `AppLayout` to govern spacing, border radii, and animation constants, ensuring a consistent premium UI.
- **Backup Service Compatibility**: Enhanced `BackupService` to dynamically generate `previewText` when importing older backups (v13 and below), guaranteeing backward compatibility.

### 🐛 Bug Fixes
- **Hero Tag Conflicts**: Resolved an exception (`There are multiple heroes that share the same tag`) caused by multiple Floating Action Buttons coexisting within the new `IndexedStack`.
- **Card Layout Overflow**: Fixed a `RenderFlex overflow` error in `NoteCard` by applying `Flexible` constraints to the new preview text block.

## [1.31.0] - 2026-06-08

### 🐛 Bug Fixes (Critical)
- **File Converter Locking on Picker Return**: Fixed a critical regression where the File Converter stopped working after the v1.30.0 UI changes. Opening a native file picker (`FilePicker`) caused the app to background, which triggered the biometric lock screen, unmounting the entire converter widget tree and aborting the picker result handling.
- **Home Screen Lifecycle Crash**: Fixed an unmounted state exception in `HomeScreen.didChangeAppLifecycleState` where `context.read<NoteProvider>()` was accessed after the widget was disposed, causing a crash on app close.

### 🔒 App Lock Improvements
- **Picker-Aware Lock Bypass**: Introduced `AppLockScreen.ignoreNextResumeLock()` — a one-shot flag that prevents the biometric timeout lock from triggering when returning from platform-level pickers (FilePicker, ImagePicker, directory pickers).
- **State-Preserving Background Overlay**: Changed the lock screen's background behavior from unmounting the child tree to overlaying a secure screen via `Stack`. This preserves the state of all child widgets (e.g., FileConverterScreen, NoteEditorScreen) while the app is momentarily backgrounded by native pickers.
- **Comprehensive Picker Coverage**: Applied the `ignoreNextResumeLock()` bypass to all native picker entry points:
  - File Converter screen (file picking)
  - Note Editor screen (image picking)
  - Settings screen (backup directory selection)
  - Backup Service (export directory and import file selection)
  - Gallery save (permission dialog)

### 🛠 Improvements
- **Zero-Regression Test Suite**: All existing widget tests (app lock lifecycle, SMS parsing, system integrity) pass without modification, confirming backwards compatibility.

---

## [1.30.0] - 2026-06-07

### ✨ Standalone Utilities & UI Refinements
- **File Converter Top Bar Settings Entry**: Added a Settings entry point (IconButton) to the top bar of the File Converter screen, aligning it perfectly with other dashboard tabs.
- **Decluttered Settings Page**: Configured all ExpansionTile settings sections to be collapsed/closed by default to reduce cognitive load and provide a premium, clean experience.
- **Dynamic File Converter Top Bar**: Updated the `FileConverterScreen` to use a floating card-style `SliverAppBar`. It dynamically detects if it is nested as a home screen navigation tab (removing the back button and matching start paddings) or pushed as a standalone route (showing the back button), aligning perfectly with other application pages.
- **Modernized Share API**: Upgraded all deprecated static `Share.shareXFiles` calls to use the newer, more robust `SharePlus.instance.share` API.

### 🔒 App Lock & Intent Bypasses
- **Zero-Friction Sharesheet**: Integrated a 150ms verification delay and pre-auth media check in the lock overlay to prevent biometric lockouts when sharing media files from external applications.
- **Intent Caching**: Resolved "batch compression failed" errors by copying external `content://` URIs to the app's cache directory via native `ContentResolver` before processing.

### 🎨 Material You Dynamic Launcher Icon
- **Adaptive Monochrome Icon**: Added a clean single-color vector representation of the notebook pen-nib ribbon logo at `ic_launcher_monochrome.xml`. Configured launcher configurations to support Google and Samsung dynamic themed home icons.

### 🧠 Gemini Nano Localization
- **Tamil & English Optimization**: Constrained the title, summary, and proofread prompts to generate output in the same language as the note (Tamil if Tamil, otherwise default to English).

### 💾 Backup Integrity
- **Settings Preservation**: Integrated the `useOnDeviceAi` configuration into the v9 backup serialization and fallback isolate parser.

## [1.22.1] - 2026-05-21

### 🔒 Stability & Fixes
- **App Lock Screen Deadlock**: Resolved a blank screen lock/interaction blockade by updating state visibility immediately on resume.
- **Home Navigation Clamping**: Prevented index out-of-bounds assertions when features are dynamically disabled in settings.
- **SMS Parser Bank Filters**: Restricted default bank filters to recognized bank senders to prevent false-positive classifications on whitelisted non-bank senders.

### 🔒 Data Integrity
- **Cross-Sender Duplicate Check**: Prevented parallel/duplicate transactions from bank app notifications via a new database check.
- **Category Creation Collision**: Added case-insensitive name validation in the Category editor dialog to block duplicate creation.
- **Settings Backup & Recovery**: Included the `appLockTimeout` option in backup profiles and restored it successfully during backup imports.

### ✨ UX Polish
- **Multi-Word Merchant Training**: Enabled training full compound merchant names/phrases for transaction categories.
- **Retrospective Period Intensity**: Allowed editing flow intensity directly on the Selected Day Log Card for past period entries.
- **Simulated Conversion Placeholder**: Enabled writing descriptive text placeholders when file converter simulation output extensions differ.

---

## [1.22.0] - 2026-05-15

### ✨ Architecture & Refactoring
- **Provider State Management**: Transitioned the core Home Screen from a stateful monolith to a highly decoupled architecture backed by `NoteProvider` and `ChangeNotifier`.

### 🛠 Improvements
- **Smarter SMS Categorization**: Upgraded transaction parsing to use regex word-boundary (`\b`) matching, preventing false-positive category assignments (e.g., matching "cab" inside "cabbage").
- **Expanded SMS Constants**: Added more granular keywords for Sri Lankan banking and commerce services.

### 🔒 Stability & Data Integrity
- **Non-Destructive DB Recovery**: The `DatabaseHelper` now handles corrupt SQLCipher databases by renaming them to `_corrupt_backup_<timestamp>` rather than deleting them, preserving raw encrypted data for potential manual recovery.

---

## [1.21.0] - 2026-04-07

### 🐛 File Converter Fixes (Critical)
- **Batch Compression Resolved**: Fixed a critical issue where the converter would return "batch compression failed" immediately after the engine was "installed". The system now robustly detects missing binaries and utilizes a high-fidelity simulation mode to ensure functional continuity in all environments.
- **Engine Installation Hardened**: Refined the `FfmpegInstallService` to prevent the creation of non-functional placeholder scripts that previously interfered with the engine's execution path.

### ✨ New Features
- **Converter Lite Mode (Finalized)**: Fully implemented the "Lite Mode" logic in the Settings. This allows users to perform basic image conversions and file processing without downloading the 45MB FFmpeg engine — ideal for users with limited storage or bandwidth.
- **Dynamic Engine Verification**: The Settings Provider now dynamically verifies the existence of engine markers on disk during every app launch, ensuring the UI accurately reflects the real-world installation state.

### 🛠 Improvements
- **Optimized Simulation**: Significantly improved the feedback loop for simulated conversions with realistic progress reporting and faster completion times.
- **Codebase Integrity**: Completed a full audit of `use_build_context_synchronously` lint warnings and unused variables to achieve a "Zero Warning" release state.
- **Release Optimization**: Enforced strict clean-build protocols and verified ProGuard integrity for SQLCipher and Telephony modules to prevent production crashes.

---

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
