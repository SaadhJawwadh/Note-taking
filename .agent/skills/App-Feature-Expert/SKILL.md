---
name: App-Feature-Expert
description: Unified specialist for all core app domain modules (Notes & Quill Editor, Financial Manager & SMS Parsing, Health Tracker & Cycle Predictions, Settings & App Lock). Enforces feature-driven architecture, decoupled providers, single-source-of-truth theme tokens, and shared core UI primitives.
---

# Unified App Feature Expert

Specialist skill governing domain modules, feature-driven architecture (`lib/features/`), single-source-of-truth theme tokens (`lib/core/theme/`), reusable core UI primitives (`lib/core/ui/`), and decoupled provider state management.

---

## 1. Modular Architecture & Single Source of Truth

- **Directory Structure**:
  - `lib/features/notes/`: Note model, repository, `NoteEditorProvider`, and editor/list screens.
  - `lib/features/finances/`: Transaction model, `TransactionRepository`, `FinancialManagerProvider`, and financial ledger/analytics screens.
  - `lib/features/health/`: Period log model, `PeriodRepository`, `PeriodTrackerProvider`, and cycle prediction screens.
  - `lib/features/settings/`: `SettingsProvider`, backup services, app lock, and settings screens.
  - `lib/core/theme/`: Single source of truth for design tokens (`AppTheme`, `AppLayout`, `AppSemanticColors`).
  - `lib/core/ui/`: Core shared UI primitives (`AppCard`, `AppBottomSheet`, `AppChip`, `AppDialog`, `FrostedGlassSliverAppBar`).
  - `lib/core/routes/`: Centralized router (`AppRouter`).

- **Single Source of Truth Rules**:
  - **No Magic Numbers / Hardcoded Styles**: All spacings, radii, animation curves, and colors MUST be referenced from `AppLayout` and `AppTheme` / `Theme.of(context).colorScheme`.
  - **Shared UI Primitives**: Use `AppCard` for cards, `AppBottomSheet` for modal sheets, `AppChip` for tag/filter pills, `AppDialog` for confirmation prompts, and `FrostedGlassSliverAppBar` for glassmorphic headers.
  - **Root Provider Registration Invariant**: Always register domain `ChangeNotifierProvider`s (`FinancialManagerProvider`, `NoteProvider`, `P2pSyncProvider`) in `main.dart`'s root `MultiProvider` list so state is globally accessible across screens, push routes, and modal bottom sheets.
  - **Variable Font System**: Always use `GoogleSansFlex` variable font (`GoogleSansFlex-VariableFont_*.ttf`) for font definitions. Avoid adding static font weight binaries (`Bold`, `Medium`, `Regular`) to assets.
  - **Overlay & Modal Provider Safety**: Modal bottom sheets (`AppBottomSheet`) and `PopupMenuButton` items run in separate `OverlayEntry` route contexts. Never wrap `PopupMenuButton.itemBuilder` entries in `Consumer<T>` or rely on route-scoped providers inside popups; use local state variables (e.g., `_trashedCount`) and convert popup sheets to `StatefulWidget`s that read repository singletons (`TransactionRepository.instance`) directly.
  - **Unified Dual-Gesture Sync Pattern**: Sync icons across feature headers (`HomeAppBar` for Notes, `FinancialManagerScreen` for Finances) MUST follow an identical dual-gesture interaction:
    - **Single Tap (`onTap`)**: `HapticFeedback.lightImpact()` + executes fast 24-hour background quick sync.
    - **Long Press (`onLongPress`)**: `HapticFeedback.mediumImpact()` + opens advanced option modal sheet (`P2pSyncScreen` for Notes, `SmsImportSheet` for Finances).
    - **Active State Progress**: Render `CircularProgressIndicator` (strokeWidth: 2) inside `SizedBox(width: 18, height: 18)` while background/foreground sync streams are active.
  - **SQLite WAL Mode & Performance Indexing Invariant**: In `DatabaseHelper.onOpen`, execute `PRAGMA journal_mode = WAL;` and `PRAGMA synchronous = NORMAL;` to allow non-blocking background writes. Create indexes on frequently queried columns (`notes(deletedAt)`, `notes(dateModified)`, `transactions(date)`, `transactions(smsId)`, `transactions(deletedAt)`, `deleted_transaction_sms_ids(smsId)`). PRAGMA queries in `sqflite_sqlcipher` MUST be executed via `db.rawQuery('PRAGMA ...;')` rather than `db.execute('PRAGMA ...;')` to prevent `Queries can be performed using SQLiteDatabase query or rawQuery methods only` runtime exceptions.
  - **Image Cache Memory Bounds**: In `main.dart`, set `PaintingBinding.instance.imageCache.maximumSizeBytes = 100MB` and `maximumSize = 100` to prevent memory spikes and OOM garbage collection pauses.

---

## 2. Notes Engine & Quill Editor (`lib/features/notes/`)

- **Data Schema & Delta JSON**: Notes store lossless Quill Delta JSON. `dateModified` updates ONLY on text content save. Soft-deleted notes auto-purge after 7 days via `clearOldTrash()`.
- **Decoupled State (`NoteEditorProvider`)**: Auto-saving, dirty state tracking, title/content state, tag matching, and category selection are managed by `NoteEditorProvider`.
- **Locked Notes & Reminders**: App lock gate authenticates via `AppLockScreen`. Reminders use `NotificationService.scheduleNoteReminder` (`0x4E000000 | noteId.hashCode`).
- **Share-Into-Notes Pipeline**: Cold-start shares routed via `AppLockScreen.pendingSharedMedia`. Shared images copied to `shared_images/` before embedding.

### ⚠️ Flutter Quill Document & Attribute Scope Guardrails
- **Strict Attribute Scoping**:
  - Apply block attributes (`list: checked`, `list: unchecked`, `header`) strictly to line-ending `\n` characters (length 1).
  - Apply inline attributes (`strikeThrough`, `bold`, `italic`) strictly to text character ranges.
  - NEVER format inline attributes with length `0` or on `\n` line breaks, as this pollutes `Line.style` and causes `Line.retain` / `AttributeScope` crashes during Backspace keypresses.
- **Post-Frame Deferred Mutations**:
  - When extracting or restoring lines inside `document.changes.listen` or UI callbacks, wrap document edits in `WidgetsBinding.instance.addPostFrameCallback((_) { ... })`.
  - Prevents mid-render `RenderEditor` painting exceptions and `Null check operator used on null value` errors.
- **Selection Clamping**:
  - Always clamp `controller.selection` to `(doc.length - 1)` after deleting line nodes so cursor offsets never exceed current document text boundaries (`Range start X is out of text of length Y`).
- **Delta Serialization & Sanitization**:
  - Separate text insertions from newline block insertions when building Deltas for database persistence.
  - Sanitize loaded Deltas before `Document.fromDelta()` by stripping inline attributes from `\n` operations.

### 🖋️ Note Editor & Floating Precision Selection Invariants
* **Symmetrical Split-Axis Flanks**:
  - **Left Flank ($64\text{dp}$ Fixed)**: Horizontal stepper `[ ‹ ] [ › ]` (32dp per icon) with single-tap character nudges, double-tap & long-press word-boundary regex jumps, and `HapticFeedback.selectionClick()`.
  - **Right Flank ($64\text{dp}$ Fixed)**: Vertical stepper `[ ▲ ] [ ▼ ]` (32dp per icon) with line-level vertical navigation.
  - **Scrollable Center**: Center formatting tools (`Headings`, `B`, `I`, `U`, `S`, `Align`, `Indent`, `Quote`, `Code`) wrapped in `Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, ...))`.
* **Natural Dismissal & Clean Bottom Toolbar**:
  - Never render a manual `[ ✕ ]` close button on the floating pill. Tapping in the text collapses selection naturally.
  - Bottom toolbar stays permanently clean without mode-swapping glitches: `[Formatting] [AI Assist] | [Table] [Checklist] [Image] [Dictate] [Hide Keyboard]`.

---

## 3. Financial Manager & SMS Ledger (`lib/features/finances/`)

- **SMS Auto-Import & Sandbox Pipeline**: Decoupled regex parsing (`SmsParser` + `sms_constants.dart`) and `SmsService`. 5-minute transaction deduplication window. Reversals purge target transaction within 7 days. `SmsParser` allows long merchant descriptions up to 60 characters and recognizes sandbox test identifiers (`'BANK_SMS'`, `'CARD'`, `'ALERTS'`, `'BANK'`) alongside major banks. PII reference cleaners MUST use digit lookaheads (`\b(?=[A-Za-z0-9]*\d)[A-Za-z0-9]{10,}\b`) to avoid truncating legitimate 10+ character English words.
- **Currencies & Multi-Currency Extraction**: Curated currency metadata (`CurrencyInfo` in `AppConstants`) provides authentic symbols and supports custom currency codes. `SmsConstants.buildPreferredAmountRegex(currency)` prioritizes matching against the user's active preferred currency before general currency fallbacks.
- **One-Tap Category Learning**: When editing transactions, wrap category suggestions in a scoped `ListenableBuilder` tied to `_descriptionController` with stopword protection (`_stopwords`) to let users persist clean merchant keywords directly into `CategoryDefinition`.
- **Hardware-Aware AI Gating (`isAiActive`)**: All AI feature triggers across domain screens (`FinancialManagerScreen` overflow menu, `TransactionEditorScreen` description suffix icon, `NoteEditorScreen` floating toolbar) MUST be guarded by `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`) rather than `useOnDeviceAi` alone, preventing dead AI buttons on emulators and non-NPU devices.
- **Non-Blocking Background Progress Stream**: Background SMS fetches execute asynchronously using an atomic mutex guard (`_isSyncingLock`) and broadcast progress (`SmsSyncProgress`) over `syncProgressStream`, allowing the user to navigate the app while progress updates render reactively in a floating M3 progress pill.
- **Financial Trash Bin & Permanent Tombstones**: Soft-deleted transactions (`deletedAt != null`) are excluded from active ledger queries but retained for 30-day auto-purge retention. Permanently purged transactions write their `smsId` to `deleted_transaction_sms_ids` tombstone table so `smsExists()` never re-imports deleted transactions.
- **Native Telephony Channel Safety Guardrail**: Wrap `_startTelephonyListening()` and `listenIncomingSms` in safe try-catch blocks and verify `await hasPermission()` BEFORE invoking `telephony.listenIncomingSms()`. Prevents `IllegalStateException: Reply already submitted` crashes on Android when SMS permissions are revoked or denied.
- **AI Title Refinement Pipeline**: `refineSingleTransactionWithAi()` and `performBulkAiRefine()` clean up cryptic bank codes (e.g. `POS/12345/KEELLS`) into clean merchant titles. Reads original SMS body safely via `getOriginalSmsBody()` from native telephony logs.
- **Background Isolate & Workmanager Safety**: `backgroundMessageHandler` and `performDailyTransactionSync` MUST invoke `WidgetsFlutterBinding.ensureInitialized()` at entry to prevent isolate crashes when accessing `SharedPreferences`, `DatabaseHelper`, or platform channels. Task re-scheduling in `performDailyTransactionSync` MUST be wrapped in a `finally` block so daily sync chains never break on execution errors.
- **Service Initialization & Permission Grants**: `SmsService.init()` initializes telephony listening on launch if permission is granted and syncs Workmanager schedules. `requestPermissions()` automatically triggers listening and schedule sync upon grant.
- **Recurring Transactions Materialization**: `RecurringRuleRepository.instance.materializeDueRules()` MUST be invoked at app launch in `main.dart` and inside `FinancialManagerProvider.loadTransactions()`.
- **Tabular Figures & Typography**: All balance strings and financial figures use `Inter` with tabular figures (`fontFeatures: [FontFeature.tabularFigures()]`).
- **Trend Forecasting & Active Month-End Run-Rate**: `SpendingForecastService.calculateMonthlyForecast()` is the canonical source of truth for ongoing projections. On days 1–3, smoothly blend current daily burn with prior 3-month historical daily average to prevent rent/utility bill spikes.
- **Dynamic 3-Slide Visual Intelligence Deck (`MinimalChartDeck`)**:
  - **Dynamic Gating**: Gated on `totalBudget > 0` for 3 slides (Trajectory $\to$ Donut $\to$ Budget Pacing) or 2 slides (Trajectory $\to$ Donut).
  - **Context-Aware Deep Linking**: Tapping "Details >" inspects active page index and deep-links to sub-tabs (Slide 0/1 $\to$ Breakdown, Slide 2 $\to$ Budgets).
  - **Compact Badge Invariant**: Keep badges under 15 characters (e.g. `Est ~395.8k 🔮`) so deck titles never truncate into ellipsis on narrow screens.
- **Android App Widget Dynamic Canvas Sparkline**: Render anti-aliased canvas sparklines in `FinanceWidgetProvider.kt` with gradient underfill and glowing forecast dots, fed by `WidgetHelper.dart` via `widget_sparkline_data`.

---

## 4. Health & Period Tracker (`lib/features/health/`)

- **Cycle Predictions & Ovulation**: Rolling average from last 3 to 7 cycles (excluding outliers $<15$ or $>60$ days). Ovulation window estimated 14 days prior to expected start.
- **Notification Rescheduling**: `NotificationService.schedulePeriodNotifications()` MUST be invoked in `PeriodRepository` when period logs are created, updated, or deleted, and in `SettingsProvider.loadSettings()` on app launch if enabled.
- **Semantic Phase Colors**: Resolved at build time via `AppSemanticColors` (`ThemeExtension`).
- **Privacy & Alerts**: Local data only (excluded from unencrypted backup). Discreet notification strings (`"Check the app"`). Privacy mask active until biometric authentication passes.

---

## 5. Settings & App Configuration (`lib/features/settings/`)

- **Settings State (`SettingsProvider`)**: Manages theme mode, dynamic color schemes, currency selection, custom transaction rules, app lock timeouts, and category budgets.
- **Hardware-Aware AI Support State**: `checkAiCoreSupport(LocalAiService)` checks Android AICore on launch, setting `_isDeviceAiSupported`. `isAiActive` provides a single source of truth for both hardware capability and user preference.
- **Schedule Sync On Preference Changes**: Setter methods (`setAutoBackupEnabled`, `setAutoBackupFrequency`, `setAutoBackupPath`, `setDailySyncEnabled`) MUST invoke their respective schedule sync helpers (`syncAutoBackupSchedule`, `syncDailySyncSchedule`) to guarantee Workmanager tasks stay in sync with stored preferences.
- **Backup & Restore**: Encryption-guarded backup JSON via `BackupService`. Excludes sensitive biometric settings to prevent override via untrusted files.

---

## 6. Master P2P Device Sync Engine (`lib/features/sync/`)

- **Bi-Directional Delta Merge Architecture**: Devices execute non-destructive 2-way LWW delta merges (`SyncMergeService.mergeRemoteData()`), merging notes, financial ledgers, period logs, and settings over Wi-Fi without losing local edits.
- **Tombstones vs. Soft-Deletes**:
  - **Permanent Purges**: Handled via `deleted_notes` tombstone table; purged IDs delete matching local notes.
  - **Soft-Deletes (`notes.deletedAt != null`)**: Merged by checking `deletedAt` date with a 5-second clock skew tolerance. Local soft-deleted notes are preserved in Trash and cannot be resurrected unless the remote edit timestamp is strictly *after* the local deletion timestamp.
- **Reactive UI Auto-Refresh Pattern**: Passive HTTP host servers merge payloads in background threads. Domain providers (`NoteProvider`, `FinancialManagerProvider`) MUST subscribe to `P2pSyncService.instance.syncEvents` to automatically re-query SQLite (`refreshNotes()`, `loadTransactions()`) whenever incoming or outgoing sync payloads are merged.
- **Direct REST HTTP Server (Port 8765) + UDP Radio Beacon (Port 8766)**: Direct socket connections bypass cloud servers and BLE daemons entirely, discovering peers and executing transfers in < 10 ms across dynamic DHCP IPs and VPN split-tunneling.
- **Deduplicated Device Cards**: Devices are strictly deduplicated by unique `deviceId`.
- **Stable Identity & Multi-Network Endpoints**: Persist each local device UUID (`P2pSyncService.getDeviceId`) and user-editable device name. A `PairedDevice` represents one immutable peer identity and may retain multiple `DeviceEndpoint`s (for example, home and work Wi-Fi); never deduplicate or replace peers by pair code or IP address. Migrate legacy `ipAddress` records into endpoint lists without deleting user pairings.
- **Pairing Contract**: QR payloads must carry a protocol version, peer `deviceId`, user-visible name, current IP, and port. A scanner must send its own persisted identity in the handshake; persist a new pairing only after the acknowledgement verifies the target, and use the acknowledged device ID for manual pairing to avoid duplicate cards. Preserve a user-renamed peer name when later discovery events arrive.
- **Per-Peer Sync Routing**: Ping, merge, and auto-sync must use the selected peer's pair secret and endpoint port. Try the most recently successful endpoint first, then fall back to the peer's other saved endpoints. Route save-event auto-sync through `P2pSyncProvider`, never through a synthetic record with an empty pair code.
- **Human-Readable Error Translation**: Use `P2pSyncService.formatUserFriendlyErrorMessage()` to translate raw network exceptions (`SocketException`, `TimeoutException`, `HandshakeFailed`) into clear actionable user guidance.
- **Dynamic Red Error Status Card**: Hero Status Card in `P2pSyncScreen` MUST dynamically render `colorScheme.errorContainer` background tint, `colorScheme.error` border, and `Icons.sync_problem_rounded` icon when `status == SyncStatus.error`.
- **UI Dialog Exception Guard**: Always wrap asynchronous network pairing and sync calls inside UI dialog `onConfirm` callbacks with `try-catch` to prevent unhandled Dart VM exceptions from bubbling up.
- **Android Emulator NAT & ADB Port Forwarding**:
  - Android Emulator internal NAT requires IP `10.0.2.2` (NOT physical router `192.168.1.x`) to reach host loopback.
  - Re-installing APKs via ADB clears port forward rules. Re-establish ADB port forwarding using `~/Library/Android/sdk/platform-tools/adb forward tcp:8765 tcp:8765` and verify via `adb forward --list`.
- **Permission-Lean Guardrail**: No Bluetooth (`BLUETOOTH_*`) or Location permissions required. Retains minimal network permissions (`INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`).
- **QR Scanner Platform Declarations**: Keep `android.permission.CAMERA` and `NSCameraUsageDescription` present for QR pairing while retaining optional camera hardware declarations for Wi-Fi tablets.

---

## 7. Canonical Feature Imports & Architecture Standards

- **No Re-Export Stubs**: Do NOT create or maintain 1-line re-export stub files in `lib/screens/`, `lib/theme/`, or `lib/data/repositories/`.
- **Direct Canonical Imports**: All screens and repositories must be imported directly from their feature module locations (`lib/features/<module>/presentation/screens/` and `lib/features/<module>/data/`).

---

## 8. Changelogs & Release Notes Standards

- **General User Target**: Release notes and changelogs MUST target everyday general users with friendly, non-technical language (avoid developer jargon such as "SQLCipher", "WorkManager", "State Provider", "Delta JSON", "BackdropFilter").
- **3-Category Grouping & Emojis**: Always group entries into 3 explicit categories using expressive emojis:
  - 🌟 **What's New** (New user-facing features)
  - 🚀 **Improvements** (Usability, UI polish, speed enhancements)
  - 🐛 **Fixes** (Bug fixes and stability resolutions)
- **Play Store Parity**: Maintain identical user-friendly structure across `PLAY_STORE_NOTES.md`, `lib/screens/changelog_screen.dart`, and `lib/widgets/whats_new_sheet.dart`.

---

## 9. Widget Testing & Viewport Configurations

- **Full-Screen Widget Test Viewport Configuration**: When writing widget tests for full-screen wizard screens or multi-page `PageView` components, configure mobile view dimensions to prevent offscreen layout clipping and false hit-test warnings:
  ```dart
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  ```
- **Gesture Hit-Test Tolerances**: Pass `warnIfMissed: false` when invoking `tester.tap()` on list tiles or offscreen buttons inside scrollable page views.

---

## 10. Global Typography & Dynamic Text Scaling

- **Global TextScaler Invariant**: `MaterialApp.builder` in `main.dart` wraps top-level app containers in `MediaQuery` with `textScaler: TextScaler.linear(settings.textSize / 16.0)` to enforce user-configured typography scaling globally across all features.
- **No Static Height Clippings**: Component layouts MUST honor dynamic text scaling without hardcoding static container heights that cause text clipping or overflow when scaled up to Large (20dp).

