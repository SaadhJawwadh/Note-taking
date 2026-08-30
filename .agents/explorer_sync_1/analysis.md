# Zero-Cloud P2P Device Sync Engine — Comprehensive Domain Architecture Audit & Optimization Blueprint

**Auditor**: P2P Sync Engine Domain Specialist Explorer  
**Target Module**: `lib/features/sync/`, `lib/services/p2p_sync_service.dart`, `lib/services/sync_merge_service.dart`, `lib/services/sync_crypto_service.dart`, `lib/services/backup_service.dart`, and associated tests  
**Working Directory**: `.agents/explorer_sync_1/`  
**Date**: 2026-08-30  
**Status**: Completed (Read-Only Investigation)  

---

## 1. Executive Summary & Architectural Overview

Everything App's Zero-Cloud Peer-to-Peer (P2P) Device Sync Engine provides local-network data synchronization without reliance on central cloud infrastructure, third-party user accounts, or external servers. The engine operates on two core network channels:
1. **REST HTTP Server (`Port 8765`)**: Serves direct bi-directional delta merges, initial QR pairing handshakes, master snapshots, and diagnostic ping requests.
2. **UDP Radio Beacon (`Port 8766`)**: Broadcasts encrypted 2-second discovery beacons on local subnet broadcast addresses to detect peers seamlessly.

All network communication is end-to-end encrypted using **AES-256 in CBC mode** with dynamic 16-byte Initialization Vectors (IV), derived via SHA-256 from user-configured 6-digit pair codes.

### Key Architectural Invariants Verified:
* **Invariant 1 & Design System Compliance**: P2P Sync screens adhere to `AppLayout` tokens, `AppCard.frosted`, `AppChip`, and `FrostedGlassSliverAppBar`.
* **Invariant 2 (Root Provider Registration)**: `P2pSyncProvider` is cleanly registered in `main.dart`'s root `MultiProvider` and exposes singleton access `P2pSyncProvider.activeInstance`.
* **Invariant 5 (Local-First Security & WAL Mode)**: Batch merges execute inside an atomic SQLite transaction over SQLCipher with `PRAGMA journal_mode = WAL;`.
* **Invariant 6 (Zero-Cloud P2P Sync & Bi-Directional Merge)**: LWW 2-way delta merge algorithms check `dateModified`, `deletedAt`, and tombstones (`deleted_notes`, `deleted_transaction_sms_ids`) with 5-second clock skew tolerance.

---

## 2. Deep Dive Scope 1: Bi-Directional LWW 2-Way Delta Merge Algorithms

### 2.1 Notes Delta Merge & Clock Skew Tolerance
**Source**: `lib/services/sync_merge_service.dart` (Lines 77–176)

#### Implementation Analysis:
* **Tombstone Pre-filtering**: Before merging notes, `SyncMergeService` extracts all local and incoming remote tombstone IDs from `deleted_notes`. If a remote note ID exists in `tombstoneIds`, it is strictly prevented from resurrection; if present locally, it is immediately deleted from SQLite (`batch.delete('notes', where: 'id = ?', whereArgs: [id])`).
* **Soft-Deleted Note (`deletedAt`) Handling**:
  ```dart
  // Lines 134-151: Remote soft-deleted vs Local active
  if (remoteDeletedAt != null && localDeletedAt == null) {
    final remoteDelDate = DateTime.tryParse(remoteDeletedAt) ?? remoteMod;
    if (remoteDelDate.isAfter(localMod) ||
        remoteDelDate.isAtSameMomentAs(localMod) ||
        remoteMod.isAfter(localMod) ||
        remoteMod.difference(localMod).inSeconds.abs() <= 5) {
      batch.update('notes', remoteRow, where: 'id = ?', whereArgs: [id], conflictAlgorithm: ConflictAlgorithm.replace);
      notesMerged++;
      continue;
    }
  }
  ```
  The 5-second clock skew window (`remoteMod.difference(localMod).inSeconds.abs() <= 5`) ensures that if a user deletes a note on Device A within moments of viewing/editing on Device B, the deletion is honored across slight hardware clock skews.
* **Local Soft-Deleted vs Remote Active**:
  ```dart
  // Lines 155-161
  if (localDeletedAt != null && remoteDeletedAt == null) {
    final localDelDate = DateTime.tryParse(localDeletedAt) ?? localMod;
    if (!remoteMod.isAfter(localDelDate)) {
      continue; // Keep local note in Trash
    }
  }
  ```
  A note in the local Trash is only restored if the remote modification occurred *strictly after* the local deletion timestamp.

#### Identified Risks & Improvement Opportunities:
1. **Equal Timestamp Tie-Breaking Gap**:
   In lines 163–172:
   ```dart
   if (remoteMod.isAfter(localMod)) {
     batch.update('notes', remoteRow, ...);
   }
   ```
   If two devices modify a note at the exact same ISO-8601 second (`remoteMod == localMod`) but have different content, neither device will update its copy, leading to silent divergence.
   *Recommendation*: Implement a deterministic tie-breaker when `remoteMod.isAtSameMomentAs(localMod)` (e.g., comparing SHA-256 hashes of content or device ID lexicographical ordering) to ensure both devices converge on the identical state.

### 2.2 Financial Transactions & Deduplication
**Source**: `lib/services/sync_merge_service.dart` (Lines 205–261)

#### Implementation Analysis:
* **SMS-Linked Transactions**: Identified by `smsId`. Checked against `tombstoneSmsIds` (`deleted_transaction_sms_ids`). If not in local database and not tombstoned, inserted via `batch.insert('transactions', remoteMap, conflictAlgorithm: ConflictAlgorithm.ignore)`.
* **Manual Transactions**: Identified by composite fingerprint `$date|$amt|$desc`. If not in `localTxFingerprints`, inserted locally.

#### Identified Architectural Vulnerabilities:
1. **SMS Transaction Mutation Sync Gap**:
   In lines 244–247:
   ```dart
   if (!localSmsMap.containsKey(smsId)) {
     batch.insert('transactions', remoteMap, conflictAlgorithm: ConflictAlgorithm.ignore);
     transactionsMerged++;
   }
   ```
   If an SMS transaction was already synced previously, but the user subsequently updated its category (e.g. from "Other" to "Groceries"), refined its description, or changed its account ("daily" vs "savings"), the remote changes are completely ignored because `localSmsMap.containsKey(smsId)` is true.
   *Root Cause*: The SQLite `transactions` table does not possess a `dateModified` column.
   *Recommendation*: Add `dateModified` to `TransactionModel` and `transactions` schema, enabling LWW updates for edited transactions across peers.
2. **Manual Transaction Editing Duplication**:
   Manual transactions lack a unique UUID primary key (they rely on SQLite autoincrement `_id`). When synced, `_id` is stripped. If a user edits a manual transaction's description or amount on Device A, its fingerprint `$date|$amt|$desc` changes. On subsequent sync with Device B, Device B does not recognize the new fingerprint and inserts a duplicate row.
   *Recommendation*: Introduce a UUID `txId` string column on `transactions` (preserving autoincrement `_id` for backward compatibility), allowing unique tracking and editing of manual transactions across devices.

### 2.3 Period Logs & Cycle Data
**Source**: `lib/services/sync_merge_service.dart` (Lines 295–304)

#### Implementation Analysis:
* `period_logs` are merged using `batch.insert('period_logs', map, conflictAlgorithm: ConflictAlgorithm.replace)`.
* Because `period_logs` uses a UUID `id` primary key, logs are safely upserted without duplication.

### 2.4 Split Bills & Shared Debts Synchronization Gap
**Source**: `lib/data/database_helper.dart` (Lines 320–355) vs `lib/services/backup_service.dart` (Lines 68–85) & `lib/services/sync_merge_service.dart`

#### Critical Finding:
* The Split Bills feature introduces three tables in database version 19+:
  - `split_bills` (`id TEXT PRIMARY KEY`, `title`, `totalAmount`, `payerName`, `isPayerUser`, `splitMode`, `date`, `status`, `deletedAt`)
  - `split_participants` (`id TEXT PRIMARY KEY`, `billId`, `contactName`, `shareAmount`, `hasPaid`, `paidAt`)
  - `split_contacts` (`id TEXT PRIMARY KEY`, `name`, `phoneNumber`, `upiId`, `lastUsedAt`)
* **Omission**: `generateBackupJson()`, `restoreFromBackupData()`, and `SyncMergeService.mergeRemoteData()` do NOT serialize or merge `split_bills`, `split_participants`, or `split_contacts`!
* **Impact**: Users syncing between two devices or restoring from backup files lose all Split Bills records and group debt settlements.
* **Remediation Blueprint**:
  1. Add `splitBills`, `splitParticipants`, and `splitContacts` queries to `generateBackupJson()` in `lib/services/backup_service.dart`.
  2. Add atomic batch restore in `BackupService.restoreFromBackupData()`.
  3. Add Step 8 in `SyncMergeService.mergeRemoteData()` to merge split bills with soft-delete `deletedAt` LWW support.

---

## 3. Deep Dive Scope 2: Stable Identity & Multi-Network Device Endpoint Topology

### 3.1 Immutable Device Identity (`deviceId`)
**Source**: `lib/services/p2p_sync_service.dart` (Lines 72–88) & `lib/features/sync/data/p2p_pairing_model.dart`

```dart
Future<String> getDeviceId() async {
  if (_deviceId != null) return _deviceId!;
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_deviceIdStorageKey);
    if (storedId != null && storedId.isNotEmpty) {
      _deviceId = storedId;
      return _deviceId!;
    }
    _deviceId = const Uuid().v4();
    await prefs.setString(_deviceIdStorageKey, _deviceId!);
  } catch (_) {
    _deviceId = const Uuid().v4();
  }
  return _deviceId!;
}
```
* **Storage Invariant**: `deviceId` is generated once as a UUID v4 and persisted in `SharedPreferences` under `p2p_local_device_id_v1`.
* **Identity Permanence**: Deduplication in `P2pSyncProvider._saveDevicesToStorage()` is strictly keyed by `deviceId`:
  ```dart
  final unique = <String, PairedDevice>{for (final device in _pairedDevices) device.deviceId: device};
  _pairedDevices = unique.values.toList();
  ```
  Devices are NEVER merged or overwritten by IP address or pair code alone.

### 3.2 Multi-Network `DeviceEndpoint` Topology
**Source**: `lib/features/sync/data/p2p_pairing_model.dart` (Lines 3–46, 74–96)

```dart
class DeviceEndpoint {
  final String ipAddress;
  final int port;
  final String? networkLabel;
  final DateTime? lastSeenAt;
  final DateTime? lastSyncedAt;
  ...
}
```
* **Multi-Network Support**: A single `PairedDevice` maintains an immutable `endpoints` list (e.g. Home Wi-Fi `192.168.1.50`, Work Wi-Fi `10.0.0.12`, Hotspot `192.168.43.1`).
* **Endpoint Selection Priority**: `preferredEndpoint` sorts endpoints by `lastSyncedAt ?? lastSeenAt` descending.
* **Connection Fallback in `syncDevice()`**:
  In `P2pSyncProvider.syncDevice(PairedDevice device)` (lines 308–330), the provider iterates through all sorted endpoints:
  ```dart
  final endpoints = [...device.endpoints]
    ..sort((a, b) => (b.lastSyncedAt ?? b.lastSeenAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.lastSyncedAt ?? a.lastSeenAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
  for (final endpoint in endpoints) {
    final result = await _service.syncBiDirectional(endpoint.ipAddress, device.pairCode, targetPort: endpoint.port);
    if (result.success) {
      ...
      return result;
    }
  }
  ```
* **Improvement Opportunity**: `sendTestPing()` in `P2pSyncProvider` (line 264) currently only tests `peer?.preferredEndpoint`. If the user moved to a new Wi-Fi network where the IP changed, `sendTestPing` fails immediately instead of iterating through alternative known endpoints. Adding the same loop to `sendTestPing()` improves connection resilience.

### 3.3 Custom Device Naming Hygiene
* The `isNameCustom` boolean flag in `PairedDevice` prevents incoming beacon broadcasts or handshake payloads from overwriting user-assigned custom device nicknames.

---

## 4. Deep Dive Scope 3: QR Pairing Handshake, UDP Beacon & REST HTTP Security

### 4.1 Cryptographic Security Model (`SyncCryptoService`)
**Source**: `lib/services/sync_crypto_service.dart` (Lines 1–61)

```
Pair Code (e.g. "482910") ──► UTF-8 Bytes ──► SHA-256 ──► 256-bit AES Key
Payload JSON ──────────────► AES-256-CBC (16-byte random IV) ──► Base64 Envelope
```

* **Key Derivation**: `sha256.convert(utf8.encode(secret.trim()))` produces a uniform 32-byte key.
* **Cipher Mode**: AES-256 in CBC mode with PKCS7 padding.
* **Payload Verification**: `decryptPayload` verifies JSON parsing after decryption. If wrong key produces garbled plaintext, `json.decode()` throws and the method safely returns `null`.
* **Zero-Knowledge Security**: No plaintext data ever travels across the local Wi-Fi network.

### 4.2 QR Pairing Handshake Flow
**Source**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart` (Lines 180–242) & `qr_scanner_dialog.dart`

```
┌────────────────────────────────────────┐         ┌────────────────────────────────────────┐
│             Primary Device             │         │            Secondary Peer              │
│  1. Generates 6-digit pairCode         │         │                                        │
│  2. Displays QR code containing:       │         │                                        │
│     {code, deviceId, name, ip, port}   │ ◄────── │  3. Scans QR code with camera          │
│                                        │  Scan   │     (QrScannerScreen / MobileScanner)  │
│                                        │         │                                        │
│  5. Receives encrypted handshake       │ ◄────── │  4. Calls pairNewDevice()              │
│     POST /api/sync/pair_handshake      │ Handshake  POST /api/sync/pair_handshake         │
│     Decrypts with pairCode             │         │                                        │
│  6. Saves peer to pairedDevices        │         │                                        │
│  7. Returns encrypted pair_ack         │ ──────► │  8. Receives pair_ack                  │
│                                        │   Ack   │  9. Saves primary to pairedDevices     │
│                                        │         │ 10. Triggers initial bi-directional    │
│                                        │         │     delta sync                         │
└────────────────────────────────────────┘         └────────────────────────────────────────┘
```

* **QR Scanner Architecture**: `QrScannerScreen` utilizes `MobileScanner` with a centered rounded bounding frame (`AppLayout.radiusL`), custom frosted app bar, and debounce logic (`_hasScanned`) preventing duplicate pops.

### 4.3 UDP Radio Beacon (Port 8766)
**Source**: `lib/services/p2p_sync_service.dart` (Lines 144–222)

* **Broadcasting**: Sends an encrypted UDP datagram to `255.255.255.255:8766` every 2.0 seconds while `startPrimaryHostServer` is active.
* **Listener**: Binds `RawDatagramSocket.bind(InternetAddress.anyIPv4, 8766)`.
* **Packet Validation**:
  - Rejects if decryption with pair code fails.
  - Ignores self-broadcasts (`senderDeviceId == await getDeviceId()`).
  - Emits discovered device on `_remoteDevicePairedController`.
* **Mobile OS Considerations**:
  - On some Android devices, broadcast packets to `255.255.255.255` are dropped by the Linux kernel unless directed to the specific subnet broadcast address (e.g. `192.168.1.255`).
  - Calculating the interface subnet broadcast address (`(ip & mask) | ~mask`) provides higher broadcast delivery rates on strict Wi-Fi routers.

### 4.4 REST HTTP Server Endpoint Security (Port 8765)
**Source**: `lib/services/p2p_sync_service.dart` (Lines 225–349)

| Endpoint | Method | Security Check | Payload Description | Response |
|---|---|---|---|---|
| `/api/sync/ping` | `POST` | Decrypts body with `pairCode` | `{action: 'ping', timestamp: ...}` | Encrypted `{status: 'pong', clientTime, serverTime, hostName}` |
| `/api/sync/pair_handshake` | `POST` | Decrypts body with `pairCode` | `{action: 'pair_handshake', deviceId, deviceName, role}` | Encrypted `{action: 'pair_ack', deviceId, deviceName, role}` |
| `/api/sync/pull_master` | `POST` | Decrypts body with `pairCode` | `{action: 'pull_master', timestamp: ...}` | Encrypted full backup snapshot JSON |
| `/api/sync/bidirectional_sync` | `POST` | Decrypts body with `pairCode` | Encrypted client backup manifest | Merges client data atomically into SQLite, responds with updated host backup JSON |

* **Security Guardrail**: Any request with an unparseable or incorrect key returns `HttpStatus.unauthorized` (`401`).
* **Connection Lifecycle**: Enclosed in `try/catch/finally` ensuring `await response.close()` is guaranteed, preventing memory/socket leaks.

---

## 5. Deep Dive Scope 4: Network Resilience, Socket Error Translation & Offline Queueing

### 5.1 Socket Error Translation Matrix
**Source**: `lib/services/p2p_sync_service.dart` (Lines 402–417)

```dart
static String formatUserFriendlyErrorMessage(dynamic e, [String? targetIp]) {
  final str = e.toString();
  final ipSuffix = (targetIp != null && targetIp.isNotEmpty) ? ' ($targetIp)' : '';
  if (str.contains('SocketException') || str.contains('Connection refused') || str.contains('No route to host')) {
    return '📡 Peer unreachable$ipSuffix. Make sure both devices are on the same Wi-Fi.';
  } else if (str.contains('TimeoutException') || str.contains('timed out')) {
    return '⏳ Connection timed out$ipSuffix. Open Note Taking on your peer device.';
  } else if (str.contains('HandshakeException') || str.contains('Pair Code mismatch')) {
    return '🔑 Pair code mismatch. Re-scan QR code or check 6-digit pair code.';
  } else if (str.contains('FormatException')) {
    return '⚠️ Unexpected data format received during sync.';
  }
  final firstLine = str.split('\n').first;
  return 'Sync error$ipSuffix: ${firstLine.length > 80 ? firstLine.substring(0, 80) : firstLine}';
}
```

### 5.2 Stream Read Timeouts (Defensive Hardening)
* **Vulnerability**: `HttpClient.connectionTimeout` (4s/8s) only sets the connection establishment limit. If the peer accepts the TCP socket connection but is suspended by Android Doze before replying, `utf8.decoder.bind(res).join()` can hang indefinitely.
* **Remediation**: Add `.timeout(const Duration(seconds: 12))` to response stream reads and request close calls:
  ```dart
  final res = await req.close().timeout(const Duration(seconds: 8));
  final responseBody = await utf8.decoder.bind(res).join().timeout(const Duration(seconds: 10));
  ```

### 5.3 Offline Auto-Sync Queueing & Beacon Wakeup
* **Current State**: `triggerEventSync()` starts a 3-second debounce timer. If devices are not currently on the same network, the attempt fails and stops.
* **Enhancement Opportunity**: When `P2pSyncProvider` receives a newly detected beacon from a paired device via `_remotePairSubscription`, if `_isAutoSyncEnabled` is active and the device has not been synced in >30 seconds, trigger `syncDevice(device)` automatically. This achieves 100% zero-touch auto-sync whenever two paired devices enter proximity on the same Wi-Fi.

---

## 6. Deep Dive Scope 5: Concurrency Safety, SQLite WAL Locking & Provider State Hygiene

### 6.1 SQLite Transaction Locking & WAL Mode
* `DatabaseHelper._onOpenDB` executes `PRAGMA journal_mode = WAL;` and `PRAGMA synchronous = NORMAL;`.
* `SyncMergeService.mergeRemoteData` encapsulates all operations in `await db.transaction((txn) async { ... })`.
* Inside the transaction, batch operations (`txn.batch()`) are committed with `await batch.commit(noResult: true)` for each table.
* **WAL Benefit**: Concurrent UI read queries (e.g. scrolling notes or viewing transactions) execute simultaneously without being blocked by incoming sync write transactions.

### 6.2 Provider State Notification Ecosystem
When a sync event occurs:

```
P2pSyncService._syncEventsController (broadcast stream)
  ├──► P2pSyncProvider (_handleSyncEvent) -> updates status & lastSyncedAt -> notifyListeners()
  ├──► NoteProvider (refreshNotes()) -> reloads notes & tags -> notifyListeners()
  ├──► FinancialManagerProvider (loadTransactions()) -> reloads ledger -> notifyListeners()
  ├──► [GAP] PeriodTrackerProvider (MISSING SUBSCRIPTION)
  └──► [GAP] SplitBillProvider (MISSING SUBSCRIPTION)
```

#### Provider Notification Fix:
* `PeriodTrackerProvider`: Subscribe to `P2pSyncService.instance.syncEvents` and invoke `loadData()` when `result.success && (result.syncedCount > 0 || result.receivedCount > 0)`.
* `SplitBillProvider`: Subscribe to `P2pSyncService.instance.syncEvents` and invoke `loadBills()` and `loadRecentContacts()`.
* `SyncResult.syncedCount` in `P2pSyncService`: Sum all merged entities (`notesMerged + transactionsMerged + periodLogsMerged + categoriesMerged + splitBillsMerged`).

---

## 7. UI/UX Consistency, Material 3 Tokens & Touch Target Audit

Inspection of `P2pSyncScreen` (`lib/features/sync/presentation/screens/p2p_sync_screen.dart`):

| UI Element | Line(s) | Current Implementation | Audit Finding & Recommendation |
|---|---|---|---|
| **Top App Bar** | 295–298 | `FrostedGlassSliverAppBar(titleText: 'Master P2P Device Sync', showBackButton: true)` | ✅ Borderless frosted glass, 16dp edge margin compliant. |
| **Hero Status Card** | 304–310 | `AppCard.frosted(...)` with alpha `isDark ? 0.22 : 0.55` and `1.2px` accent border | ✅ Compliant with Invariant 1 (Dynamic Hero Card Opacities). |
| **Action Buttons** | 392, 443, 649 | `SizedBox(height: 48, child: FilledButton / OutlinedButton)` | ✅ Full $48\text{dp}$ touch target compliance. |
| **Copy Buttons** | 577–591, 624–638 | `IconButton(constraints: BoxConstraints(minWidth: 32, minHeight: 32))` | ⚠️ Hit bounds are $32\times 32\text{dp}$. Enforce minimum $48\times 48\text{dp}$ touch targets (`constraints: BoxConstraints(minWidth: 48, minHeight: 48)`) per Invariant 10. |
| **Unpair & Action Icons** | 750–789 | `IconButton` with default 48dp constraints | ✅ Compliant. |

---

## 8. Zero-Conflict Implementation Work Packages & Code Blueprints

Below are the isolated, conflict-free code blueprints ready for execution by implementer agents in subsequent phases.

### Work Package A: Split Bills Backup & P2P Delta Merge Integration

#### 1. Update `lib/services/backup_service.dart`:
```dart
// In generateBackupJson():
final splitBills = await db.query('split_bills');
final splitParticipants = await db.query('split_participants');
final splitContacts = await db.query('split_contacts');

final payload = {
  ...
  'splitBills': splitBills,
  'splitParticipants': splitParticipants,
  'splitContacts': splitContacts,
  ...
};

// In restoreFromBackupData():
await txn.delete('split_bills');
await txn.delete('split_participants');
await txn.delete('split_contacts');

if (data.containsKey('splitBills') && data['splitBills'] is List) {
  for (final row in data['splitBills']) {
    batch.insert('split_bills', Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
if (data.containsKey('splitParticipants') && data['splitParticipants'] is List) {
  for (final row in data['splitParticipants']) {
    batch.insert('split_participants', Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
if (data.containsKey('splitContacts') && data['splitContacts'] is List) {
  for (final row in data['splitContacts']) {
    batch.insert('split_contacts', Map<String, Object?>.from(row), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
```

#### 2. Update `lib/services/sync_merge_service.dart`:
```dart
// Add splitBillsMerged to SyncMergeResult:
class SyncMergeResult {
  final int notesMerged;
  final int transactionsMerged;
  final int periodLogsMerged;
  final int categoriesMerged;
  final int splitBillsMerged;

  SyncMergeResult({
    this.notesMerged = 0,
    this.transactionsMerged = 0,
    this.periodLogsMerged = 0,
    this.categoriesMerged = 0,
    this.splitBillsMerged = 0,
  });
}

// In mergeRemoteData(), Step 8:
if (remoteData.containsKey('splitBills') && remoteData['splitBills'] is List) {
  final batch = txn.batch();
  for (final item in remoteData['splitBills'] as List) {
    if (item is Map) {
      batch.insert('split_bills', Map<String, Object?>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
      splitBillsMerged++;
    }
  }
  await batch.commit(noResult: true);
}
if (remoteData.containsKey('splitParticipants') && remoteData['splitParticipants'] is List) {
  final batch = txn.batch();
  for (final item in remoteData['splitParticipants'] as List) {
    if (item is Map) {
      batch.insert('split_participants', Map<String, Object?>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
  await batch.commit(noResult: true);
}
if (remoteData.containsKey('splitContacts') && remoteData['splitContacts'] is List) {
  final batch = txn.batch();
  for (final item in remoteData['splitContacts'] as List) {
    if (item is Map) {
      batch.insert('split_contacts', Map<String, Object?>.from(item), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
  await batch.commit(noResult: true);
}
```

### Work Package B: Stream Timeout & Network Hardening

#### Update `lib/services/p2p_sync_service.dart`:
```dart
// In syncBiDirectional() and pullMasterFromPrimary():
final res = await req.close().timeout(const Duration(seconds: 8));
if (res.statusCode == 200) {
  final responseBody = await utf8.decoder.bind(res).join().timeout(const Duration(seconds: 10));
  ...
}

// In sendTestPing():
final res = await req.close().timeout(const Duration(seconds: 4));
if (res.statusCode == 200) {
  final body = await utf8.decoder.bind(res).join().timeout(const Duration(seconds: 4));
  ...
}
```

### Work Package C: Provider Sync State Wiring & Beacon Auto-Sync

#### 1. Wire `PeriodTrackerProvider` (`lib/features/health/providers/period_tracker_provider.dart`):
```dart
StreamSubscription? _syncSubscription;

PeriodTrackerProvider() {
  loadData();
  _syncSubscription = P2pSyncService.instance.syncEvents.listen((result) {
    if (result.success && (result.syncedCount > 0 || result.receivedCount > 0)) {
      loadData();
    }
  });
}

@override
void dispose() {
  _syncSubscription?.cancel();
  super.dispose();
}
```

#### 2. Wire `SplitBillProvider` (`lib/features/finances/providers/split_bill_provider.dart`):
```dart
StreamSubscription? _syncSubscription;

SplitBillProvider() {
  loadBills();
  loadRecentContacts();
  _syncSubscription = P2pSyncService.instance.syncEvents.listen((result) {
    if (result.success && (result.syncedCount > 0 || result.receivedCount > 0)) {
      loadBills();
      loadRecentContacts();
    }
  });
}

@override
void dispose() {
  _syncSubscription?.cancel();
  super.dispose();
}
```

#### 3. Update `P2pSyncProvider` Touch Targets & Auto-Discovery (`lib/features/sync/presentation/screens/p2p_sync_screen.dart`):
* Update copy `IconButton` constraints from `BoxConstraints(minWidth: 32, minHeight: 32)` to `BoxConstraints(minWidth: 48, minHeight: 48)`.
* In `P2pSyncProvider.loadSettings()`, trigger auto-sync upon discovering a known paired peer via UDP beacon.

---

## 9. Verification & Test Plan

1. **Unit Tests**:
   - Run `flutter test test/features/sync/ test/services/p2p_sync_service_test.dart test/services/sync_crypto_service_test.dart test/tombstone_sync_backup_test.dart`.
   - Add unit test for Split Bills serialization and delta merge in `test/features/sync/sync_merge_test.dart`.
2. **Static Analysis**:
   - Run `flutter analyze lib/features/sync/ lib/services/sync_merge_service.dart lib/services/p2p_sync_service.dart lib/services/sync_crypto_service.dart`.
3. **Simulated Two-Device Integration Test**:
   - Simulate HTTP Server on localhost Port 8765 and Client connection to verify bi-directional merge and 5-second soft-delete tolerance.

---
