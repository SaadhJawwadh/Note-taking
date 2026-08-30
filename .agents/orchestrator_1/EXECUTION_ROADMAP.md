# Everything App — Conflict-Free Multi-Phase Execution Roadmap

**Document Version**: 1.0.0  
**Author**: Project Orchestrator (`orchestrator_1`)  
**Workspace**: `/Users/saadhjawwadh/Documents/Code/Note taking`  
**Strategy**: Decoupled, modular work packages executed sequentially or in parallel without file ownership overlap.

---

## 1. Execution Principles & File Ownership Isolation

To guarantee 100% conflict-free execution during future implementation phases, the roadmap enforces strict file ownership boundaries across 5 sequential phases:
- **Zero Cross-Module Pollution**: A worker assigned to a module owns only files in that module's directory.
- **Contract-First Database Migrations**: Shared database helpers and schema additions are applied in Phase 1 before domain features consume them.
- **Continuous Monotonic Verification**: Every phase must pass `flutter analyze` (0 issues) and `flutter test` (all tests green) before advancing.

---

## 2. Multi-Phase Execution Schedule

```
┌────────────────────────────────────────────────────────────────────────┐
│ Phase 1: Core Infrastructure, Schema Indexes & R8 ProGuard Hygiene     │
│ (DatabaseHelper, Android ProGuard, ImageCache, Test Helper Alignment)   │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
         ┌─────────────────────────┴─────────────────────────┐
         ▼                                                   ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────────────┐
│ Phase 2A: Notes Domain Refinements   │  │ Phase 2B: Health Tracker Refinements │
│ - RichTextUtils Delta Sanitization   │  │ - Silent Background loadData        │
│ - Selection Clamping & Stepper Fix   │  │ - 48x48dp Symptom Touch Targets      │
│ - Trash Tombstone & Save Logic       │  │ - fabBottomPadding Clearance         │
│ - Sandboxed Image Paths              │  │ - Remove health.dart Stub            │
└──────────────────┬───────────────────┘  └──────────────────┬───────────────────┘
                   │                                         │
                   └───────────────────┬─────────────────────┘
                                       │
         ┌─────────────────────────────┴─────────────────────────────┐
         ▼                                                           ▼
┌───────────────────────────────────────────┐  ┌───────────────────────────────────────────┐
│ Phase 3A: P2P Sync & Backup Integration   │  │ Phase 3B: Settings & AppLock Refinements  │
│ - Split Bills Backup JSON & Delta Merge   │  │ - ignoreNextResumeLock at 5 Entry Points  │
│ - HTTP Stream Timeout Guard               │  │ - Onboarding 48dp Touch Targets           │
│ - Provider syncEvents Wiring              │  │ - Multi-Endpoint Test Ping Iteration      │
└─────────────────────┬─────────────────────┘  └─────────────────────┬─────────────────────┘
                      │                                              │
                      └──────────────────────┬───────────────────────┘
                                             │
                                             ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Phase 4: UI/UX Consistency, Semantic Colors & Touch Accessibility      │
│ - Static Color Token Unification (SplitBills, SettleUp, Budgets)       │
│ - 48x48dp Hit Target Constraints & Semantics across Micro-Controls     │
│ - Hero Card 55%/22% Opacity & 1.2px Border Parity                      │
│ - Rule 41 Unicode Emoji Replacement with Material Symbols              │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │
                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Phase 5: Final Validation & Release Gate Verification                  │
│ - Full Workspace Static Analysis (flutter analyze)                     │
│ - Complete Test Suite Execution (flutter test)                         │
│ - Multi-Module Regression & E2E Verification                           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Phase Work Packages

### Phase 1: Core Infrastructure, Schema Indexes & R8 ProGuard
- **Objective**: Establish foundational performance and schema optimizations.
- **Owned Files**:
  - `android/app/proguard-rules.pro`
  - `lib/data/database_helper.dart`
  - `lib/widgets/home/home_app_bar.dart`
- **Work Items**:
  1. Add explicit `-keep` and `-dontwarn` rules for `mobile_scanner`, `gemini_nano_android`, `speech_to_text`, `in_app_update`, `in_app_review` in `proguard-rules.pro`.
  2. Align `createTestDatabase(db)` to version `22` in `database_helper.dart:33`.
  3. Standardize migration double quotes `DEFAULT "[]"` to single quotes `DEFAULT '[]'` in `database_helper.dart`.
  4. Create composite indexes `idx_transactions_date_account`, `idx_notes_modified_deleted`, `idx_split_bills_active`, `idx_period_logs_start`.
  5. Standardize `HomeAppBar` vertical padding to `top: statusBar + 6, bottom: 6`.
- **Verification Gate**:
  ```bash
  flutter test test/upgrade_backward_compatibility_test.dart
  flutter analyze lib/data/ lib/widgets/home/
  ```

### Phase 2: Notes & Health Domain Refinements
- **Phase 2A (Notes) Owned Files**:
  - `lib/utils/rich_text_utils.dart`
  - `lib/features/notes/presentation/screens/note_editor_screen.dart`
  - `lib/features/notes/data/note_repository.dart`
  - `lib/providers/note_provider.dart`
- **Phase 2A Work Items**:
  1. Implement non-destructive `RichTextUtils.sanitizeDelta(Delta delta)` splitting text and `\n` attributes.
  2. Implement `_getNormalizedSelectionRange()` and fix collapsed stepper cursor navigation in `NoteEditorScreen`.
  3. Write tombstones to `deleted_notes` during `NoteRepository.clearOldTrash()`.
  4. Preserve `deletedAt: widget.note?.deletedAt` in `NoteEditorScreen.saveNote()`.
  5. Sandboxed copy of picked images to `getApplicationDocumentsDirectory() / 'note_images/'`.
  6. Add `errorBuilder` fallback in `_FullScreenImageViewer`.
- **Phase 2B (Health) Owned Files**:
  - `lib/features/health/providers/period_tracker_provider.dart`
  - `lib/features/health/presentation/screens/period_tracker_screen.dart`
  - `lib/features/health/presentation/widgets/period_log_dashboard_card.dart`
  - `lib/features/health/health.dart` (delete stub)
- **Phase 2B Work Items**:
  1. Add `{bool showLoading = false}` parameter to `PeriodTrackerProvider.loadData()` to eliminate optimistic skeleton flashing.
  2. Enforce `BoxConstraints(minHeight: 48, minWidth: 48)` and `Semantics(button: true)` on symptom chips in `PeriodLogDashboardCard`.
  3. Apply `AppLayout.fabBottomPadding = 96.0` to `PeriodTrackerScreen` bottom scroll view.
  4. Delete 1-line re-export stub `lib/features/health/health.dart`.
- **Verification Gate**:
  ```bash
  flutter test test/note_repository_test.dart test/period_tracker_phase4_features_test.dart test/find_in_note_test.dart
  flutter analyze lib/features/notes/ lib/features/health/
  ```

### Phase 3: P2P Sync, Split Bills & Settings Refinements
- **Phase 3A (Sync & Backup) Owned Files**:
  - `lib/services/backup_service.dart`
  - `lib/services/sync_merge_service.dart`
  - `lib/services/p2p_sync_service.dart`
  - `lib/features/sync/providers/p2p_sync_provider.dart`
  - `lib/features/finances/providers/split_bill_provider.dart`
- **Phase 3A Work Items**:
  1. Integrate `split_bills`, `split_participants`, and `split_contacts` into `BackupService` JSON export/import.
  2. Implement `_mergeSplitBills()`, `_mergeSplitParticipants()`, and `_mergeSplitContacts()` in `SyncMergeService`.
  3. Wrap HTTP response body stream decoding with `.timeout(const Duration(seconds: 10))` in `P2pSyncService`.
  4. Wire `PeriodTrackerProvider` and `SplitBillProvider` to `P2pSyncService.instance.syncEvents`.
  5. Add multi-endpoint fallback iteration in `P2pSyncProvider.sendTestPing()`.
- **Phase 3B (Settings & AppLock) Owned Files**:
  - `lib/features/settings/presentation/screens/onboarding_screen.dart`
  - `lib/features/finances/presentation/widgets/receipt_scanner_sheet.dart`
  - `lib/features/finances/services/split_share_service.dart`
- **Phase 3B Work Items**:
  1. Add `AppLockScreen.ignoreNextResumeLock()` to `BackupService.importBackup`, `BackupService.importTransactionsFromCsv`, `ReceiptScannerSheet._pickAndScan`, `SplitShareService.shareToWhatsAppOrSystem`, and `NoteEditorScreen._showShareMenu`.
  2. Add `cacheWidth: 300` to `ReceiptScannerSheet` camera thumbnail.
  3. Upgrade `OnboardingScreen` feature action buttons to $\ge 48\times 48\text{dp}$ touch target bounds.
- **Verification Gate**:
  ```bash
  flutter test test/features/sync/ test/services/p2p_sync_service_test.dart test/services/sync_crypto_service_test.dart test/onboarding_test.dart test/settings_and_lock_test.dart
  flutter analyze lib/features/sync/ lib/services/ lib/features/settings/
  ```

### Phase 4: UI/UX Consistency, Semantic Colors & Touch Accessibility
- **Owned Files**:
  - `lib/features/finances/presentation/widgets/split_bills_tab.dart`
  - `lib/features/finances/presentation/widgets/settle_up_sheet.dart`
  - `lib/features/finances/presentation/widgets/minimal_chart_deck.dart`
  - `lib/features/finances/presentation/screens/financial_manager_screen.dart`
  - `lib/features/finances/presentation/screens/sms_rules_screen.dart`
  - `lib/features/health/presentation/widgets/cycle_phase_hero_card.dart`
  - `lib/widgets/whats_new_sheet.dart`
- **Work Items**:
  1. Replace 58 hardcoded `Colors.*` usages with `AppSemanticColors` / `colorScheme`.
  2. Enforce $\ge 48\times 48\text{dp}$ touch target bounding boxes on Minimal Chart "Details >" link, pagination dots, finance hero mode dots, and trash action icons.
  3. Align negative net cash flow and cycle moon phase hero card opacities to `55%` Light / `22%` Dark / `1.2px` border.
  4. Add `AppLayout.fabBottomPadding = 96.0` to `SplitBillsTab`'s `ListView`.
  5. Replace 15+ raw Unicode emoji glyphs in UI labels, sheets, and notification titles with official Material Symbols and clean semantic text.
- **Verification Gate**:
  ```bash
  flutter test test/top_bar_search_and_sms_24h_sync_test.dart test/split_bill_features_test.dart
  flutter analyze
  ```

### Phase 5: Final Validation & Release Gate Verification
- **Objective**: Full end-to-end regression validation.
- **Verification Commands**:
  ```bash
  flutter analyze
  flutter test
  ```
- **Acceptance Invariants**:
  - 0 static analysis errors / warnings / hints.
  - 100% test pass rate across all 177+ automated tests.
  - Zero performance regressions in bitmap decoding or WAL database writes.
