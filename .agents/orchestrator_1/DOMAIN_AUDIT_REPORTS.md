# Everything App — Domain-Specific Modular Feature Audits (Zero-Conflict Work Packages)

**Document Version**: 1.0.0 (Master Synthesis)  
**Author**: Project Orchestrator (`orchestrator_1`)  
**Scope**: Notes, Finances & Split Bills, Health Tracker, Settings & Onboarding, P2P Sync Engine, Core Infrastructure  
**Constraint Enforced**: Read-only planning phase — ZERO source modifications executed.

---

## Module 1: Notes Domain (`lib/features/notes/`)

### 1. Architectural Overview & Invariants
The Notes domain is built on Flutter Quill with a custom SQLCipher SQLite backend (`note_repository.dart`) and reactive `NoteProvider`. It features rich text styling, folder hierarchies, tag indexing, and a 7-day trash auto-purge lifecycle.

### 2. High-Signal Findings & Defect Catalog

#### Defect N-01: Destructive Delta Sanitization Strips Legitimate Formatting
- **File & Line**: `lib/features/notes/presentation/screens/note_editor_screen.dart:167–180`
- **Root Cause**: `initState` iterates over Quill Delta operations and checks `if (op.data is String && (op.data as String).contains('\n') && op.attributes != null)`. It then indiscriminately strips `bold`, `italic`, `underline`, and `strike` from the entire operation.
- **Impact**: When a user creates a bold header like `"Project Plan\n"`, Quill packs text and the newline into one operation `{"insert": "Project Plan\n", "attributes": {"bold": true}}`. On note reload, this sanitization removes `bold: true`, causing permanent formatting loss on disk.
- **Work Package Blueprint (WP-N1)**:
  Extract delta normalization to a standalone utility `RichTextUtils.sanitizeDelta(Delta delta)` that splits operations on `\n`: applying inline attributes exclusively to text substrings and line attributes (e.g. `header`, `list`) exclusively to `\n` characters.

#### Defect N-02: Inverted Selection `RangeError` Crash on Image/Table Insertion
- **File & Line**: `lib/features/notes/presentation/screens/note_editor_screen.dart:952–955, 1234–1242`
- **Root Cause**: Insertion routines compute replacement range as:
  ```dart
  final index = _quillController.selection.baseOffset;
  final length = _quillController.selection.extentOffset - index;
  ```
  When user selects text from right-to-left, `baseOffset > extentOffset`, resulting in `length < 0`. Passing a negative length to `_quillController.replaceText()` throws an unhandled `RangeError`.
- **Work Package Blueprint (WP-N2)**:
  Introduce `_getNormalizedSelectionRange()`:
  ```dart
  (int, int) _getNormalizedSelectionRange() {
    final sel = _quillController.selection;
    final start = math.min(sel.baseOffset, sel.extentOffset);
    final end = math.max(sel.baseOffset, sel.extentOffset);
    return (math.max(0, start), math.max(0, end - start));
  }
  ```

#### Defect N-03: Stepper Flank Navigation Accidental Selection Expansion
- **File & Line**: `note_editor_screen.dart:472–475, 503–506, 525–528, 554–557`
- **Root Cause**: Split-axis flank buttons call `_quillController.updateSelection(TextSelection(baseOffset: selection.baseOffset, extentOffset: newExtent))` even when `selection.isCollapsed` is true.
- **Impact**: Moving the cursor left/right/up/down turns a collapsed cursor into an expanding text highlight span.
- **Work Package Blueprint (WP-N3)**:
  When `selection.isCollapsed`, set `baseOffset = newExtent` and `extentOffset = newExtent` so the cursor moves cleanly without highlighting.

#### Defect N-04: Missing Tombstones in Trash Auto-Purge (`clearOldTrash()`)
- **File & Line**: `lib/features/notes/data/note_repository.dart:336–354`
- **Root Cause**: Auto-purge executes `txn.delete('notes', where: 'id = ?', whereArgs: [id])` without inserting the purged ID into `deleted_notes`.
- **Impact**: During subsequent P2P sync, remote peers that still retain the note will see no local tombstone and re-insert the purged note into the local database (P2P ghost resurrection).
- **Work Package Blueprint (WP-N4)**:
  Insert records into `deleted_notes (note_id, deleted_at)` inside the same atomic SQLite transaction before deleting from `notes`.

#### Defect N-05: Accidental Note Restoration on Viewing Trashed Note
- **File & Line**: `note_editor_screen.dart:1049–1063`
- **Root Cause**: `saveNote()` constructs a `Note` object without propagating `deletedAt: widget.note?.deletedAt`.
- **Impact**: Opening a trashed note from Trash view triggers auto-save after 2 seconds, which resets `deletedAt` to `null` and silently restores the note to the active notebook.
- **Work Package Blueprint (WP-N5)**:
  Preserve `deletedAt: widget.note?.deletedAt` in `saveNote()`.

#### Defect N-06: Paginated In-Memory Search Limitation
- **File & Line**: `lib/providers/note_provider.dart:178–189`
- **Root Cause**: `_applySearchFilter()` filters only in-memory `_notes` (the first 20 items loaded on page 1) instead of querying `NoteRepository.searchNotes()`.
- **Work Package Blueprint (WP-N6)**:
  Wire `NoteProvider.setSearchQuery(query)` to trigger asynchronous SQLite `NoteRepository.searchNotes(query)` with 200ms debounce.

#### Defect N-07: Unsandboxed Temporary Image Picker Cache Paths
- **File & Line**: `note_editor_screen.dart:946–964`
- **Root Cause**: `pickedFile.path` from `ImagePicker` points to the OS temporary cache directory (`/cache/`).
- **Work Package Blueprint (WP-N7)**:
  Copy picked image files into sandboxed app storage (`getApplicationDocumentsDirectory() / 'note_images/'`) before embedding paths in Quill Delta JSON.

---

## Module 2: Finances & Split Bills Domain (`lib/features/finances/`)

### 1. Architectural Overview & Invariants
Finances features a Two-Bank Account ledger (`daily` operating vs `savings` vault), automated SMS transaction ingestion with 24-hour default lookback, recurring rule propagation, 100% offline Google ML Kit receipt OCR, and group debt splitting.

### 2. High-Signal Findings & Architectural Verification

#### Verified Invariants (100% Sound):
1. **Two-Bank Account Model**: `TransactionModel.account` strictly isolates `'daily'` from `'savings'`. `FinancialManagerScreen:291–301` separates `_dailyCashFlow` and `_savingsVaultCashFlow`. Deposits are auto-routed to `AccountType.savings` via `SmsParser.resolveAccount()`.
2. **SMS Sandbox Whitelisting & Manifest Parity**: Recognized test senders (`'BANK_SMS'`, `'CARD'`, `'ALERTS'`, `'BANK'`) are whitelisted. Only declared `Permission.sms` is queried. 10-digit and 13-digit epochs are normalized via `SmsParser.resolveMessageDate()`.
3. **Tombstone Ingestion Guardrail**: `createSmsTransaction` queries `smsExists(smsId)` against both `transactions` and `deleted_transaction_sms_ids` by default.
4. **24-Hour Scan Lookback & Real-Time Frosted Banner**: Quick sync scans the last 24 hours (`DateTime.now().subtract(const Duration(hours: 24))`), processes messages in chunks of 25 with `_cancelRequested` token, and displays a frosted progress banner with 1-tap `[ Cancel ]`.
5. **Recurring Rule Propagation**: Editing a recurring transaction in `TransactionEditorScreen:75–91` matches the master `RecurringRule` via `findMatchingRule()` and updates future cycles atomically.
6. **Split Bills Cash Flow Contract**: Master expenses record full bank debit; friend debt repayments settled in `SettleUpSheet:181–203` record as `Income` in the Daily Operating account.

#### Target Work Packages for Finances & Split Bills:
- **Work Package F-01 (Thumbnail Downsampling)**: Add `cacheWidth: 300` to `Image.file` in `ReceiptScannerSheet:152` to eliminate multi-megabyte RAM spikes when scanning 48MP camera receipts.
- **Work Package F-02 (AppLock Bypass)**: Call `AppLockScreen.ignoreNextResumeLock()` in `ReceiptScannerSheet._pickAndScan` and `SplitShareService.shareToWhatsAppOrSystem`.
- **Work Package F-03 (Split Bills Bottom Clearance)**: Add `AppLayout.fabBottomPadding = 96.0` to `SplitBillsTab`'s `ListView` to prevent navigation bar clipping.
- **Work Package F-04 (Token Unification)**: Replace raw `Colors.green` / `Colors.red` with `AppSemanticColors.success` / `colorScheme.error` in `SplitBillsTab` and `SettleUpSheet`.

---

## Module 3: Health Tracker Domain (`lib/features/health/`)

### 1. Architectural Overview & Invariants
Health Tracker provides offline, non-cloud menstrual cycle rolling average predictions, period duration analysis, 14-day luteal phase ovulation tracking, lunar phase canvas math, and discreet lock screen notifications.

### 2. High-Signal Findings & Defect Catalog

#### Verified Invariants (100% Sound):
1. **Prediction Algorithms & Outlier Filtering**: `PeriodPredictionService:61` strictly filters intervals using `if (diff >= 15 && diff <= 60)` over the last 3–7 logs (`limit = logs.length > 7 ? 7 : logs.length;`). Bleeding duration strictly checks `days >= 1 && days <= 14`.
2. **Discreet Notifications**: `NotificationService:118` schedules alerts at 9:00 AM local time with title `'Reminder'` and non-revealing body text `'Check the app'` (configurable in Settings).
3. **Biometric Privacy**: Masked behind 25.0 sigma Gaussian blur when App Lock is active.

#### Defect HT-01: Optimistic UI Jitter on Symptom/Flow Logging
- **File & Line**: `lib/features/health/providers/period_tracker_provider.dart:40–42, 211, 232`
- **Root Cause**: `updateIntensity()` and `toggleSymptom()` perform 0ms in-memory mutations, but then invoke `await loadData()`. `loadData()` unconditionally executes `_isLoading = true; notifyListeners();`.
- **Impact**: `PeriodTrackerScreen:209–226` unmounts the entire view into `ListView(children: [SkeletonCard(), ...])`. Every symptom tap causes a jarring skeleton flash and resets scroll position.
- **Work Package Blueprint (WP-HT1)**:
  Update `loadData({bool showLoading = false})`:
  ```dart
  Future<void> loadData({bool showLoading = false}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    ...
  }
  ```

#### Quality Refinements:
- **WP-HT2 (Touch Targets)**: Enforce `BoxConstraints(minHeight: 48, minWidth: 48)` and `Semantics(button: true)` on symptom chips in `PeriodLogDashboardCard:343–368`.
- **WP-HT3 (Scroll Clearance)**: Set `bottom: AppLayout.fabBottomPadding` in `PeriodTrackerScreen:511`.
- **WP-HT4 (Database Index)**: Add composite index `idx_period_logs_start_date ON period_logs(startDate)`.
- **WP-HT5 (Stub Elimination)**: Remove 1-line re-export stub `lib/features/health/health.dart`.

---

## Module 4: Settings & Onboarding Domain (`lib/features/settings/`)

### 1. Architectural Overview & Invariants
Settings manages app preferences, the 5-slide interactive Onboarding Wizard (`OnboardingScreen`), replayability, AES-256 encrypted backups, biometric AppLock, and hardware NPU AI Core detection.

### 2. High-Signal Findings & Architectural Verification

#### Verified Invariants (100% Sound):
1. **Onboarding Responsive Clamping**: Clamped to `maxWidth: AppLayout.maxContentWidth` (600dp) for clean tablet layout.
2. **Settings Replayability**: `OnboardingScreen(isReplay: true)` updates `SettingsProvider` reactively without wiping SQLite databases or notes.
3. **Resilient Auto-Backup Storage Priority**: `BackupService.performAutoBackup()` defaults to sandboxed app documents (`getApplicationDocumentsDirectory()`) if custom SAF directories fail or lose permissions across Android OS updates.
4. **Hardware NPU AICore Gating**: All AI UI buttons across Settings, Note Editor, Finances, and Receipt Scanner query `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`).

#### Defect ST-01: Missing Resume Lock Bypass on Native Pickers & Share Sheets
- **File & Lines**:
  - `lib/services/backup_service.dart:284` (`importBackup`)
  - `lib/services/backup_service.dart:635` (`importTransactionsFromCsv`)
  - `lib/features/finances/presentation/widgets/receipt_scanner_sheet.dart:45` (`_pickAndScan`)
  - `lib/features/finances/services/split_share_service.dart:75` (`shareToWhatsAppOrSystem`)
  - `lib/features/notes/presentation/screens/note_editor_screen.dart:1375` (`_showShareMenu`)
- **Root Cause & Impact**: Opening native file pickers or share sheets pauses the Flutter activity. On resume, `AppLockScreen` triggers its timeout lock, cancelling active file imports or receipt scanning.
- **Work Package Blueprint (WP-ST1)**:
  Add `AppLockScreen.ignoreNextResumeLock()` immediately before invoking native picker or share dialogs.

#### Quality Refinements:
- **WP-ST2 (Onboarding Touch Targets)**: Expand feature setup action buttons and pagination indicator dots to $\ge 48\times 48\text{dp}$ touch bounds with `Semantics(button: true)`.

---

## Module 5: P2P Sync Engine Domain (`lib/features/sync/`)

### 1. Architectural Overview & Invariants
P2P Sync delivers zero-cloud, direct local Wi-Fi synchronization over REST HTTP (Port 8765) and UDP discovery beacon (Port 8766). It uses AES-256-CBC encryption derived from a 6-digit pair code and an LWW 2-way delta merge engine with 5-second clock skew tolerance.

### 2. High-Signal Findings & Defect Catalog

#### Critical Gap SY-01: Split Bills Omitted from Backup & P2P Sync Merge
- **Files & Lines**: `lib/services/backup_service.dart:68–85, 345–390`, `lib/services/sync_merge_service.dart:33–320`
- **Root Cause**: Tables `split_bills`, `split_participants`, and `split_contacts` are created in `DatabaseHelper:320–355`, but are completely omitted from `generateBackupJson()`, `restoreFromBackupData()`, and `SyncMergeService.mergeRemoteData()`.
- **Impact**: Restoring an AES-256 backup or pairing two devices over P2P sync results in silent data loss of all split bill records and debt settlements.
- **Work Package Blueprint (WP-SY1)**:
  1. Add `split_bills`, `split_participants`, and `split_contacts` extraction to `BackupService.generateBackupJson()` and restoration to `restoreFromBackupData()`.
  2. Implement `_mergeSplitBills()`, `_mergeSplitParticipants()`, and `_mergeSplitContacts()` in `SyncMergeService.mergeRemoteData()`.

#### Defect SY-02: Unbounded HTTP Stream Consumption Risk
- **File & Lines**: `lib/services/p2p_sync_service.dart:439, 489, 538`
- **Root Cause**: `await utf8.decoder.bind(res).join()` lacks stream timeout protection.
- **Impact**: If a remote peer sleeps or disconnects during transfer, the HTTP client hangs indefinitely.
- **Work Package Blueprint (WP-SY2)**:
  Wrap response body stream decoding with `.timeout(const Duration(seconds: 10))`.

#### Defect SY-03: Provider Sync Notification Wiring Gap
- **Files**: `lib/features/health/providers/period_tracker_provider.dart`, `lib/features/finances/providers/split_bill_provider.dart`
- **Root Cause**: While `NoteProvider` and `FinancialManagerProvider` subscribe to `P2pSyncService.instance.syncEvents`, Health and Split Bills providers do not.
- **Impact**: Remote updates merged in the background do not refresh Health and Split Bills screens until app restart.
- **Work Package Blueprint (WP-SY3)**:
  Subscribe `PeriodTrackerProvider` and `SplitBillProvider` to `P2pSyncService.instance.syncEvents` to invoke silent reloads (`loadData(showLoading: false)`).

#### Defect SY-04: Multi-Endpoint Ping Fallback
- **File & Line**: `lib/features/sync/providers/p2p_sync_provider.dart:264–278`
- **Work Package Blueprint (WP-SY4)**:
  Update `sendTestPing()` to iterate through all known `device.endpoints` until one succeeds, matching `syncDevice()`.

---

## Module 6: Core Infrastructure & Shared Primitives (`lib/core/`, `lib/data/`)

### 1. Architectural Overview & Invariants
Core Infrastructure provides the atomic Material 3 Expressive design library (`AppCard`, `AppBottomSheet`, `AppChip`, `AppDialog`, `FrostedGlassSliverAppBar`), theme tokens (`AppLayout`, `AppTheme`), SQLite WAL configuration (`DatabaseHelper`), and route transitions.

### 2. High-Signal Findings & Quality Refinements
- **WP-CR1 (Database Test Helper Skew)**: Align `DatabaseHelper.createTestDatabase(db)` from version 19 to version 22 (`database_helper.dart:33`).
- **WP-CR2 (Migration SQL Quotes)**: Standardize migration `DEFAULT "[]"` double quotes to standard SQL single quotes `DEFAULT '[]'` (`database_helper.dart:373, 382, 438`).
- **WP-CR3 (Composite SQLite Indexes)**: Create high-frequency query indexes:
  - `idx_transactions_date_account ON transactions(date, account)`
  - `idx_notes_modified_deleted ON notes(date_modified, deleted_at)`
  - `idx_split_bills_date ON split_bills(created_at, is_settled)`
  - `idx_period_logs_start ON period_logs(startDate)`
- **WP-CR4 (Home App Bar Padding Symmetry)**: Standardize `HomeAppBar` vertical padding from `+4` to `+6` to eliminate sub-pixel header jitter across tab switches.
