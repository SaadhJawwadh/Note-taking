# Handoff Report: Zero-Cloud P2P Device Sync Engine Audit

**Author**: P2P Sync Engine Domain Specialist Explorer  
**Working Directory**: `.agents/explorer_sync_1/`  
**Recipient**: Parent Orchestrator (`5c075409-518f-43b1-91ea-9f3496532050`)  
**Date**: 2026-08-30  
**Status**: Completed (Hard Handoff)  

---

## 1. Observation

### Exact File Paths, Line Numbers, and Code Snippets Observed:

1. **Split Bills Missing from Backup & Sync Merge**:
   - `lib/data/database_helper.dart` (lines 320–355): Creates tables `split_bills`, `split_participants`, `split_contacts`.
   - `lib/services/backup_service.dart` (lines 68–85, 345–390): `generateBackupJson()` and `restoreFromBackupData()` query and restore `notes`, `tags`, `note_tags`, `transactions`, `category_definitions`, `sms_contacts`, `period_logs`, `recurring_rules`, `deleted_notes`, `deleted_transaction_sms_ids`. **Tables `split_bills`, `split_participants`, and `split_contacts` are completely absent.**
   - `lib/services/sync_merge_service.dart` (lines 33–320): `mergeRemoteData()` merges tombstones, notes, tags, note-tags, transactions, categories, SMS contacts, period logs, and recurring rules. **Does not process `split_bills` or `split_participants`.**

2. **Notes Last-Write-Wins & 5-Second Clock Skew Tolerance**:
   - `lib/services/sync_merge_service.dart` (lines 135–151):
     ```dart
     if (remoteDeletedAt != null && localDeletedAt == null) {
       final remoteDelDate = DateTime.tryParse(remoteDeletedAt) ?? remoteMod;
       if (remoteDelDate.isAfter(localMod) ||
           remoteDelDate.isAtSameMomentAs(localMod) ||
           remoteMod.isAfter(localMod) ||
           remoteMod.difference(localMod).inSeconds.abs() <= 5) {
         batch.update(
           'notes',
           remoteRow,
           where: 'id = ?',
           whereArgs: [id],
           conflictAlgorithm: ConflictAlgorithm.replace,
         );
         notesMerged++;
         continue;
       }
     }
     ```
     Correctly evaluates 5-second clock skew tolerance on soft-delete merges.
   - Line 163: `if (remoteMod.isAfter(localMod))` lacks a deterministic tie-breaker when `remoteMod.isAtSameMomentAs(localMod)` with divergent content.

3. **Stable Identity & Multi-Network Endpoints**:
   - `lib/services/p2p_sync_service.dart` (lines 72–88): Device ID is an immutable UUID v4 stored in SharedPreferences under key `p2p_local_device_id_v1`.
   - `lib/features/sync/data/p2p_pairing_model.dart` (lines 3–46, 74–96): `DeviceEndpoint` supports multiple network locations (`ipAddress`, `port`, `networkLabel`, `lastSeenAt`, `lastSyncedAt`). `preferredEndpoint` sorts by `lastSyncedAt ?? lastSeenAt` descending.
   - `lib/features/sync/providers/p2p_sync_provider.dart` (lines 308–330): `syncDevice()` iterates through all known endpoints until one succeeds.
   - `lib/features/sync/providers/p2p_sync_provider.dart` (lines 264–278): `sendTestPing()` only tests `preferredEndpoint` without endpoint fallback iteration.

4. **Cryptographic Integrity & HTTP Server Endpoint Security**:
   - `lib/services/sync_crypto_service.dart` (lines 12–59): AES-256 in CBC mode with dynamic 16-byte IV, key derived via `sha256(utf8.encode(pairCode))`. Validates JSON post-decryption.
   - `lib/services/p2p_sync_service.dart` (lines 225–349): All endpoints (`/api/sync/ping`, `/api/sync/pair_handshake`, `/api/sync/pull_master`, `/api/sync/bidirectional_sync`) require encrypted body; returns 401 Unauthorized for malformed or mismatched pair codes. Enclosed in `try/catch/finally` with `await response.close()`.

5. **Network Timeout Limits & Stream Reading**:
   - `lib/services/p2p_sync_service.dart` (lines 433, 483, 532): Sets `HttpClient()..connectionTimeout = const Duration(seconds: 4)` or `8`.
   - Lines 439, 489, 538: `await utf8.decoder.bind(res).join()` lacks `.timeout()`, which could hang if the peer OS freezes or suspends during data transfer.

6. **Provider Notification Subscriptions**:
   - `lib/providers/note_provider.dart` (line 72): Listens to `syncEvents` -> calls `refreshNotes()`.
   - `lib/features/finances/providers/financial_manager_provider.dart` (line 23): Listens to `syncEvents` -> calls `loadTransactions()`.
   - `lib/features/health/providers/period_tracker_provider.dart`: Does **not** subscribe to `syncEvents`.
   - `lib/features/finances/providers/split_bill_provider.dart`: Does **not** subscribe to `syncEvents`.

7. **UI/UX Touch Targets**:
   - `lib/features/sync/presentation/screens/p2p_sync_screen.dart` (lines 577–591, 624–638): Copy buttons use `IconButton(constraints: const BoxConstraints(minWidth: 32, minHeight: 32))`.

8. **Test Execution & Static Analysis Results**:
   - Command: `flutter test test/features/sync/ test/services/p2p_sync_service_test.dart test/services/sync_crypto_service_test.dart test/tombstone_sync_backup_test.dart`
   - Result: Exit code 0, all 16 tests passed.
   - Command: `flutter analyze lib/features/sync/ lib/services/sync_merge_service.dart lib/services/p2p_sync_service.dart lib/services/sync_crypto_service.dart`
   - Result: Exit code 0, 0 issues found.

---

## 2. Logic Chain

1. **Split Bills Gap**:
   - *Observation*: Table `split_bills` is created in `DatabaseHelper` v19+, but is omitted in `generateBackupJson()`, `restoreFromBackupData()`, and `SyncMergeService.mergeRemoteData()`.
   - *Inference*: P2P sync and backup restore will cause silent data loss of split bill records and debt settlements between paired devices.
   - *Conclusion*: Split bills must be integrated into backup JSON and sync delta merge steps.

2. **Network Resilience & Timeouts**:
   - *Observation*: `HttpClient.connectionTimeout` only bounds TCP socket connection setup. `utf8.decoder.bind(res).join()` has no timeout.
   - *Inference*: If a peer device is placed in deep sleep / battery saver after accepting connection, the sync client will hang indefinitely on stream consumption.
   - *Conclusion*: Response reading must be wrapped with `.timeout(const Duration(seconds: 10))`.

3. **Provider State Freshness**:
   - *Observation*: `NoteProvider` and `FinancialManagerProvider` update their in-memory models upon `syncEvents`, but `PeriodTrackerProvider` and `SplitBillProvider` do not.
   - *Inference*: When background P2P sync merges period logs or split bills, health and debt UI screens will show stale data until the app restarts or manually reloads.
   - *Conclusion*: Wire `PeriodTrackerProvider` and `SplitBillProvider` to `P2pSyncService.instance.syncEvents`.

4. **Multi-Endpoint Fallback in Ping**:
   - *Observation*: `syncDevice()` iterates through all endpoints, but `sendTestPing()` only tests `preferredEndpoint`.
   - *Inference*: When a user switches networks (e.g. from office to home), `preferredEndpoint` might be the old office IP, causing manual test pings to fail even though another valid endpoint exists in `device.endpoints`.
   - *Conclusion*: Add multi-endpoint iteration to `sendTestPing()`.

---

## 3. Caveats

- **UDP Broadcast on Cellular/Hotspots**: Some Wi-Fi routers and mobile hotspot APs block UDP broadcast packets on port 8766. Direct QR scan and IP input remain the 100% reliable fallback.
- **Transaction Modified Timestamps**: `transactions` table does not currently include a `dateModified` column. Modifying already-synced SMS transaction categories/accounts currently remains local until schema migration adds `dateModified`.
- **Read-Only Scope**: No source code files were edited during this audit.

---

## 4. Conclusion

The Zero-Cloud P2P Device Sync Engine is robust, cryptographically sound (AES-256-CBC with SHA-256 key derivation), and enforces strict local-first data privacy and WAL mode SQLite atomicity.

A decoupled, zero-conflict 3-part work package has been formulated:
1. **Work Package A**: Integrate `split_bills`, `split_participants`, and `split_contacts` into `BackupService` JSON and `SyncMergeService` delta merge.
2. **Work Package B**: Add `.timeout(const Duration(seconds: 10))` to HTTP stream decoders and add endpoint iteration to `sendTestPing()`.
3. **Work Package C**: Wire `PeriodTrackerProvider` and `SplitBillProvider` to `syncEvents`, and enforce $48\times 48\text{dp}$ touch targets on copy buttons.

---

## 5. Verification Method

To independently verify all findings:

1. **Inspect Analysis Report**:
   - File: `.agents/explorer_sync_1/analysis.md`
2. **Run Sync Unit Tests**:
   ```bash
   flutter test test/features/sync/ test/services/p2p_sync_service_test.dart test/services/sync_crypto_service_test.dart test/tombstone_sync_backup_test.dart
   ```
3. **Run Static Analysis on Sync Code**:
   ```bash
   flutter analyze lib/features/sync/ lib/services/sync_merge_service.dart lib/services/p2p_sync_service.dart lib/services/sync_crypto_service.dart
   ```
