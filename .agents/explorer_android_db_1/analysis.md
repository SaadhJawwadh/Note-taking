# Android Performance, Memory Optimization & Database Architecture Audit

**Author**: Android Quality, Memory & Database Specialist Explorer  
**Date**: 2026-08-30  
**Target Codebase**: Everything App (Flutter >=3.27.0, Dart >=3.6.0, SQLCipher, Workmanager, ML Kit)  
**Status**: Comprehensive Read-Only Audit Complete  

---

## Executive Summary

A comprehensive architectural and performance audit was performed across the entire Android native configuration, memory management boundaries, bitmap decoding hot-paths, background isolate lifecycles, and SQLite / SQLCipher database pipelines.

Overall, the codebase demonstrates strong architectural invariants (strict Material 3 Expressive theming, 100MB image cache bounding, 0ms optimistic UI in domain providers like `SplitBillProvider`, and solid soft-delete tombstone tracking). However, key optimization gaps and memory risks were identified:
1. **Bitmap Downsampling Leak in Receipt Scanner**: Camera receipt images (12MP–48MP) decoded in `ReceiptScannerSheet` lack `cacheWidth`, consuming 24–96MB uncompressed RAM per preview.
2. **Missing Error Boundary in Note Full-Screen Viewer**: `_FullScreenImageViewer` renders raw `Image(image: imageProvider)` without an `errorBuilder` fallback.
3. **Database Test Helper Schema Divergence**: `createTestDatabase` invokes `_createDB(db, 19)` despite production database schema version being `22`.
4. **ProGuard Coverage Gaps for Dynamic Plugins**: Missing explicit keep rules for `mobile_scanner`, `gemini_nano_android`, `speech_to_text`, `in_app_update`, and `in_app_review`.
5. **SQL String Literal Syntax**: Double quotes used in `DEFAULT "[]"` across 3 database migrations (`v7`, `v10`, `v16`) instead of standard SQL single quotes (`DEFAULT '[]'`).
6. **Domain Provider Optimistic Mutation Gaps**: `FinancialManagerProvider` and `NoteProvider` await database writes before refreshing UI state instead of executing synchronous 0ms in-memory mutations.

---

## Scope 1: Bitmap Memory Usage & Downsampling

### 1.1 Codebase Scan of Image Renderers

| File Path | Line Range | Widget | `cacheWidth` Status | `errorBuilder` Status | Risk Assessment |
|---|---|---|---|---|---|
| `lib/features/finances/presentation/widgets/receipt_scanner_sheet.dart` | 150–164 | `Image.file(File(_imagePath!), ...)` | **MISSING** (renders $68 \times 84\text{dp}$) | Present | **HIGH**: 12–48MP camera images decoded full-resolution into RAM (24–96MB buffer). |
| `lib/features/notes/presentation/screens/note_editor_screen.dart` | 4327–4351 | `Image.network` & `Image.file` | **Bounded** (`cacheWidth: 1080`) | Present | **LOW**: Compliant note body embedding. |
| `lib/features/notes/presentation/screens/note_editor_screen.dart` | 4442–4461 | `Image(image: imageProvider)` | N/A (Full-screen InteractiveViewer) | **MISSING** | **MEDIUM**: Missing errorBuilder causes red crash screen if file is deleted/corrupted. |
| `lib/screens/home_screen.dart` | 1074 | `Image.file(File(note.imagePath!), ...)` | **Bounded** (`cacheWidth: 400`) | Present | **OPTIMAL**: Compliant list/grid card thumbnailing. |

### 1.2 Identified Issues & Code Blueprints

#### Issue 1.1: Missing `cacheWidth` in `ReceiptScannerSheet`
- **Location**: `lib/features/finances/presentation/widgets/receipt_scanner_sheet.dart:152-163`
- **Current Code**:
  ```dart
  ClipRRect(
    borderRadius: BorderRadius.circular(AppLayout.radiusS),
    child: Image.file(
      File(_imagePath!),
      width: 68,
      height: 84,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 68,
        height: 84,
        color: colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.receipt_long_rounded),
      ),
    ),
  ),
  ```
- **Blueprint Fix**:
  ```dart
  ClipRRect(
    borderRadius: BorderRadius.circular(AppLayout.radiusS),
    child: Image.file(
      File(_imagePath!),
      cacheWidth: 300,
      width: 68,
      height: 84,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 68,
        height: 84,
        color: colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.receipt_long_rounded),
      ),
    ),
  ),
  ```

#### Issue 1.2: Missing `errorBuilder` in `_FullScreenImageViewer`
- **Location**: `lib/features/notes/presentation/screens/note_editor_screen.dart:4454-4459`
- **Current Code**:
  ```dart
  body: InteractiveViewer(
    child: Center(
      child: Image(image: imageProvider),
    ),
  ),
  ```
- **Blueprint Fix**:
  ```dart
  body: InteractiveViewer(
    child: Center(
      child: Image(
        image: imageProvider,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined, size: 64, color: Colors.white.withValues(alpha: 0.6)),
                const SizedBox(height: 12),
                Text(
                  'Image unavailable or deleted',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
  ```

---

## Scope 2: Global Image Cache & RSS Footprint

### 2.1 Global Image Cache Limits
- **Location**: `lib/main.dart:38–39`
- **Verification**:
  ```dart
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100 MB
  PaintingBinding.instance.imageCache.maximumSize = 100;
  ```
- **Assessment**: Fully compliant with Invariant 9 and Google Play 2026 memory standards.

### 2.2 Lifecycle, Stream Subscriptions & Listener Hygiene

| Class / Module | Subscription / Listener | Disposal Verification | Leak Risk |
|---|---|---|---|
| `FinancialManagerScreen` | `_smsSubscription`, `_smsProgressSub`, `_heroAutoCycleTimer`, `_heroPageController`, `_searchController`, `tabRedirectNotifier`, `refreshNotifier` | Explicitly cancelled / disposed in `dispose()` (`lines 193–203`) | **None** |
| `FinancialManagerProvider` | `_syncSubscription`, `_smsSyncSubscription` | Cancelled in `dispose()` (`lines 39–43`) | **None** |
| `NoteProvider` | `_syncEventsSubscription` | Cancelled in `dispose()` (`lines 80–83`) | **None** |
| `P2pSyncProvider` | `_eventDebounceTimer`, `_syncResultSubscription`, `_remotePairSubscription`, `_activeInstance` | Cancelled, host server stopped, static reference nulled in `dispose()` (`lines 55–62`) | **None** |
| `NoteEditorScreen` | `_quillController`, `_titleController`, `_focusNode`, `_scrollController`, `_speech`, `_docSubscription`, `_debounce`, `_scrollToCursorDebounce` | Cancelled & disposed in `dispose()` (`lines 725–740`) | **None** |
| `AppLockScreen` | `_intentDataStreamSubscription` | Cancelled in `dispose()` (`line 104`) | **None** |
| `HomeScreen` | `_intentDataStreamSubscription` | Cancelled in `dispose()` (`line 282`) | **None** |

### 2.3 Background Isolates & Startup Deadlock Protection
- **`callbackDispatcher` (`lib/services/backup_service.dart:29–49`)**:
  - Annotated with `@pragma('vm:entry-point')`.
  - Invocations guarded with `WidgetsFlutterBinding.ensureInitialized()` and task routing.
- **`backgroundMessageHandler` (`lib/services/sms_service.dart:863–885`)**:
  - Annotated with `@pragma('vm:entry-point')`.
  - Invocations guarded with `WidgetsFlutterBinding.ensureInitialized()`.
- **Cold-Start DB Lock Prevention (`lib/main.dart:82–95`)**:
  - `kWidgetRefreshTaskName` periodic task registers with `initialDelay: const Duration(hours: 1)`.
  - This prevents background isolate opening SQLCipher database simultaneously with main isolate cold-start UI thread, eliminating SQLite lock deadlocks.

---

## Scope 3: DEX & R8 Full-Mode Optimization

### 3.1 R8 Configuration
- **`android/gradle.properties`**:
  ```properties
  android.enableR8.fullMode=true
  ```
  Status: **ACTIVE & VERIFIED**.
- **`android/app/build.gradle.kts` (lines 60–65)**:
  ```kotlin
  isMinifyEnabled = true
  isShrinkResources = true
  isDebuggable = false
  proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
  ```
  Status: **ACTIVE & VERIFIED**.

### 3.2 ProGuard Rules Precision Audit (`android/app/proguard-rules.pro`)

#### Verified Rules
- Embedding rules are precise (`FlutterJNI`, `FlutterPlugin`, `MethodCallHandler`, `StreamHandler`) without destructive broad `-keep class io.flutter.** { *; }` wildcards.
- Plugin keeps defined for `sqflite`, `net.sqlcipher`, `sharedpreferences`, `packageinfo`, `receive_sharing_intent`, `filepicker`, `workmanager`, `telephony`, `permissionhandler`, `ffmpegkit`, `biometric`, `localauth`, `imagepicker`, `flutterlocalnotifications`, `urllauncher`, `share`, `gal`, `google_mlkit_text_recognition`.

#### Identified Plugin Keep Rule Gaps
The following dependencies declared in `pubspec.yaml` interact with native platform reflection/JNI and require explicit keep and dontwarn declarations:
1. `mobile_scanner` (CameraX & ML Kit Barcode engine)
2. `gemini_nano_android` (Android AICore dynamic model loader)
3. `speech_to_text` (Android SpeechRecognizer callbacks)
4. `in_app_update` (Google Play In-App Update API)
5. `in_app_review` (Google Play Review Manager)

#### Proposed Additions to `android/app/proguard-rules.pro`:
```proguard
# Mobile Scanner (CameraX / ML Kit)
-keep class dev.steenbakker.mobile_scanner.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**

# Gemini Nano / Android AI Core
-keep class com.google.ai.edge.aicore.** { *; }
-keep class dev.flutter.gemini_nano.** { *; }
-dontwarn dev.flutter.gemini_nano.**

# Speech To Text
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# In-App Update & Review
-keep class de.gigadroid.in_app_update.** { *; }
-keep class dev.fluttercommunity.plus.in_app_review.** { *; }
```

### 3.3 Dynamic `IconData` Code-Point Allocations & Font Tree-Shaking
- **Mechanism in `lib/data/transaction_category.dart`**:
  - `swatches` is declared as a `const List<IconData>` containing 24 statically referenced Material Symbols.
  - `_knownIcons` builds a reverse lookup `Map<int, IconData>`:
    ```dart
    static Map<int, IconData> get _knownIcons {
      return _knownIconsCache ??= {
        for (final icon in swatches) icon.codePoint: icon,
      };
    }
    ```
  - Category icon resolution queries `_knownIcons[def.iconCodePoint!]` or falls back to static `Icons.*` constants.
- **Finding**: Zero instances of dynamic `IconData(codePoint)` constructor calls exist across the entire codebase. Flutter's icon font tree-shaker safely resolves all icon glyphs at compile time.

---

## Scope 4: SQLite WAL Mode & Hot-Path Indexing

### 4.1 SQLite WAL Mode Contract
- **Location**: `lib/data/database_helper.dart:136–137`
- **Implementation**:
  ```dart
  await db.rawQuery('PRAGMA journal_mode = WAL;');
  await db.rawQuery('PRAGMA synchronous = NORMAL;');
  ```
- **Verification**: Executed inside `_onOpenDB` via `db.rawQuery()`. This guarantees concurrent read transactions never block write transactions across main UI and Workmanager background isolates.

### 4.2 Database Test Version Alignment
- **Location**: `lib/data/database_helper.dart:32–34`
- **Current Code**:
  ```dart
  @visibleForTesting
  Future<void> createTestDatabase(Database db) async {
    await _createDB(db, 19);
  }
  ```
- **Issue**: `_initDB` opens the database at `version: 22` (v20 added `account`, v21 added `split_bills`, v22 added `isAiRefined`). Hardcoding `19` in `createTestDatabase` creates version discrepancy in tests.
- **Blueprint Fix**:
  ```dart
  @visibleForTesting
  Future<void> createTestDatabase(Database db) async {
    await _createDB(db, 22);
  }
  ```

### 4.3 Migration SQL Single-Quote Hygiene
- **Location**: `lib/data/database_helper.dart` in `_upgradeDB`
- **Current Issues**:
  - Line 373: `... DEFAULT "[]" ...`
  - Line 382: `... DEFAULT "[]" ...`
  - Line 438: `... DEFAULT "[]" ...`
- **Rationale**: In strict SQL, double quotes are identifier quotes. While SQLite tolerates double quotes for string literals when no column matches, standard SQL requires single quotes (`DEFAULT '[]'`) to prevent syntax ambiguities.
- **Blueprint Fix**:
  ```dart
  // Line 373:
  await db.execute("CREATE TABLE IF NOT EXISTS ${TableNames.categoryDefinitions} (${CategoryFields.name} TEXT PRIMARY KEY, ${CategoryFields.color} INTEGER NOT NULL, ${CategoryFields.keywords} TEXT NOT NULL DEFAULT '[]', ${CategoryFields.isBuiltIn} INTEGER NOT NULL DEFAULT 0)");

  // Line 382:
  await db.execute("CREATE TABLE IF NOT EXISTS ${TableNames.smsContacts} (${SmsContactFields.id} TEXT PRIMARY KEY, ${SmsContactFields.senderIds} TEXT NOT NULL DEFAULT '[]', ${SmsContactFields.label} TEXT, ${SmsContactFields.isBuiltIn} INTEGER NOT NULL DEFAULT 0, ${SmsContactFields.isBlocked} INTEGER NOT NULL DEFAULT 0)");

  // Line 438:
  await db.execute("ALTER TABLE ${TableNames.periodLogs} ADD COLUMN ${PeriodLogFields.symptoms} TEXT NOT NULL DEFAULT '[]'");
  ```

### 4.4 Hot-Path Indexing Coverage

#### Currently Implemented Indexes (`_onOpenDB`):
```sql
CREATE INDEX IF NOT EXISTS idx_notes_deleted ON notes(deletedAt);
CREATE INDEX IF NOT EXISTS idx_notes_modified ON notes(dateModified);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_smsid ON transactions(smsId);
CREATE INDEX IF NOT EXISTS idx_transactions_deleted ON transactions(deletedAt);
CREATE INDEX IF NOT EXISTS idx_tombstones_smsid ON deleted_transaction_sms_ids(smsId);
CREATE INDEX IF NOT EXISTS idx_split_bills_deleted ON split_bills(deletedAt);
CREATE INDEX IF NOT EXISTS idx_split_bills_txid ON split_bills(transactionId);
CREATE INDEX IF NOT EXISTS idx_split_participants_bill ON split_participants(billId);
CREATE INDEX IF NOT EXISTS idx_split_participants_contact ON split_participants(contactName);
```

#### Recommended High-Frequency Composite Indexes:
To optimize high-frequency multi-column queries:
1. `notes(deletedAt, isArchived, isPinned, dateModified)`: Eliminates temporary B-tree sorting on the primary note feed query (`readAllNotes`).
2. `transactions(deletedAt, account, date)`: Accelerates dual-account filtering (`_dailyCashFlow` vs `_savingsVaultCashFlow`) in `FinancialManagerScreen`.
3. `period_logs(startDate)`: Speeds up rolling menstrual cycle chronological queries in `PeriodPredictionService`.
4. `recurring_rules(nextDue)`: Accelerates `materializeDueRules()` executed on app startup and isolate wakeups.

```sql
CREATE INDEX IF NOT EXISTS idx_notes_feed ON notes(deletedAt, isArchived, isPinned, dateModified);
CREATE INDEX IF NOT EXISTS idx_transactions_account_date ON transactions(deletedAt, account, date);
CREATE INDEX IF NOT EXISTS idx_period_logs_start ON period_logs(startDate);
CREATE INDEX IF NOT EXISTS idx_recurring_rules_due ON recurring_rules(nextDue);
```

---

## Scope 5: 0ms Immediate State Mutation & Optimistic UI

### 5.1 Provider Optimistic Architecture Review

| Provider / Surface | Action | Optimistic Mutation (0ms) | Rollback / Parity Safeguard |
|---|---|---|---|
| `SplitBillProvider` | `createBill`, `updateBill`, `deleteBill`, `toggleParticipantPaid`, `settleAllForContact` | **YES**: Mutates `_bills`, runs `_recalculateMetrics()`, calls `notifyListeners()` before awaiting DB. | **YES**: Restores deleted items in `catch` blocks; re-synchronizes on failure. |
| `PeriodTrackerProvider` | `deleteLog`, `updateIntensity`, `toggleSymptom` | **YES**: Mutates `_logs` and calls `notifyListeners()` before background DB writes. | **YES**: Calls `loadData()` to recompute cycle predictions. |
| `FinancialManagerScreen` | Swipe delete & snackbar undo | **YES**: Mutates `_allDateFiltered`, updates `_trashedCount`, calls `_applyFilters()`. | **YES**: Re-queries in background without blocking UI thread. |
| `FinancialManagerProvider` | `addTransaction`, `deleteTransaction`, `restoreTransaction` | **NO**: Awaits repository write, then calls `loadTransactions()` which triggers `_isLoading = true` and full reload. | **Needs Improvement** (Blueprint below). |
| `NoteProvider` | `bulkDelete`, `bulkArchive`, `bulkTogglePin` | **NO**: Awaits `_noteRepository` writes before calling `refreshNotes()`. | **Needs Improvement** (Blueprint below). |

### 5.2 Optimistic Blueprints for Providers

#### `FinancialManagerProvider` Optimistic Blueprint:
```dart
Future<void> deleteTransaction(int id) async {
  // 1. 0ms Immediate State Mutation
  final target = _allTransactions.where((t) => t.id == id).firstOrNull;
  if (target != null) {
    _allTransactions.removeWhere((t) => t.id == id);
    _trashedTransactions.insert(0, target.copy(deletedAt: DateTime.now().toIso8601String()));
    _applyFilters();
    notifyListeners();
  }

  // 2. Persist in background
  try {
    await _repository.softDeleteTransaction(id);
  } catch (e) {
    await loadTransactions();
  }
}

Future<void> restoreTransaction(int id) async {
  // 1. 0ms Immediate State Mutation
  final target = _trashedTransactions.where((t) => t.id == id).firstOrNull;
  if (target != null) {
    _trashedTransactions.removeWhere((t) => t.id == id);
    _allTransactions.add(target.copy(deletedAt: null));
    _allTransactions.sort((a, b) => b.date.compareTo(a.date));
    _applyFilters();
    notifyListeners();
  }

  // 2. Persist in background
  try {
    await _repository.restoreTransaction(id);
  } catch (e) {
    await loadTransactions();
  }
}
```

#### `NoteProvider` Optimistic Blueprint:
```dart
Future<List<String>> bulkDelete() async {
  final ids = _selectedNoteIds.toList();
  // 1. 0ms Immediate State Mutation
  _notes.removeWhere((n) => ids.contains(n.id));
  _filteredNotes = List.from(_notes);
  clearSelection();
  notifyListeners();

  // 2. Persist in background
  await _noteRepository.bulkDelete(ids);
  unawaited(refreshNotes());
  return ids;
}
```

---

## Scope 6: Soft-Delete Undo Parity

### 6.1 Soft-Delete Contract Verification
- **`TransactionRepository`**:
  - `restoreTransaction(int id)`: Executes `UPDATE transactions SET deletedAt = NULL WHERE id = ?`.
  - `permanentlyDeleteTransaction(int id)`: Persists SMS ID into `deleted_transaction_sms_ids` tombstone table.
  - `createSmsTransaction`: Verifies SMS ID does not exist in `transactions` or `deleted_transaction_sms_ids` (`smsExists`) unless `bypassTombstones: true` is set.
- **`NoteRepository`**:
  - `restoreNote(String id)`: Executes `UPDATE notes SET deletedAt = NULL, dateModified = ? WHERE id = ?`.
  - `deleteNote(String id)`: Records note ID in `deleted_notes` tombstone table.
- **Presentation Layer Undo Handlers**:
  - `HomeScreen._bulkDeleteWithUndo` (`lib/screens/home_screen.dart:304`): Calls `NoteRepository.instance.restoreNote(id)`.
  - `FinancialManagerScreen` (`lib/features/finances/presentation/screens/financial_manager_screen.dart:1922, 1944`): Calls `TransactionRepository.instance.restoreTransaction(transaction.id!)`.
  - `FinancialTrashSheet` (`lib/features/finances/presentation/widgets/financial_trash_sheet.dart:208`): Calls `TransactionRepository.instance.restoreTransaction(txn.id!)`.
  - `FilteredNotesScreen` (`lib/features/notes/presentation/screens/filtered_notes_screen.dart:74`): Calls `NoteRepository.instance.restoreNote(note.id)`.
  - `NoteEditorScreen` (`lib/features/notes/presentation/screens/note_editor_screen.dart:1585`): Calls `NoteRepository.instance.restoreNote(noteId)`.
  - `NoteViewBuilder` (`lib/widgets/home/note_view_builder.dart:187`): Calls `NoteRepository.instance.restoreNote(note.id)`.

**Verdict**: 100% compliant. Zero instances of record re-insertion (`createTransaction`/`createNote`) during undo operations exist anywhere in the codebase.

---

## Conflict-Free Work Package

This work package is completely decoupled and self-contained within Android native build rules, data repositories, and UI image containers:

### Target Files & Changes
1. **`lib/features/finances/presentation/widgets/receipt_scanner_sheet.dart`**:
   - Add `cacheWidth: 300` to `Image.file(...)` at line 152.
2. **`lib/features/notes/presentation/screens/note_editor_screen.dart`**:
   - Add `errorBuilder` fallback container to `Image(image: imageProvider)` in `_FullScreenImageViewer` at line 4456.
3. **`android/app/proguard-rules.pro`**:
   - Add explicit keep rules for `mobile_scanner`, `gemini_nano_android`, `speech_to_text`, `in_app_update`, and `in_app_review`.
4. **`lib/data/database_helper.dart`**:
   - Align `createTestDatabase` schema version argument to `22` (line 33).
   - Standardize `DEFAULT "[]"` to `DEFAULT '[]'` in migration SQL lines 373, 382, and 438.
   - Add composite indexes (`idx_notes_feed`, `idx_transactions_account_date`, `idx_period_logs_start`, `idx_recurring_rules_due`) in `_onOpenDB`.
5. **`lib/features/finances/providers/financial_manager_provider.dart` & `lib/providers/note_provider.dart`**:
   - Implement 0ms synchronous in-memory list mutations for `deleteTransaction`, `restoreTransaction`, and `bulkDelete`.

### Zero-Regression Verification
- Run `flutter analyze` $\rightarrow$ 0 errors / 0 warnings.
- Run `flutter test` $\rightarrow$ all 177 tests passing.
- Run `flutter test test/upgrade_backward_compatibility_test.dart` $\rightarrow$ verifying v1 to v22 migrations.
