# P2P Sync Engine M3 Expressive & Architectural Audit Report

**Date**: 2026-09-16  
**Auditor**: P2P Sync Engine Explorer (`explorer_sync_3`)  
**Parent Orchestrator**: `orchestrator_3` (`6ec8d34f-5c83-44cf-b500-0dacec388c7d`)  
**Working Directory**: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_sync_3`  
**Target Module**: `lib/features/sync/` and associated sync presentation entry points  
**Integrity Mode**: Read-only (Zero Source Code Modifications — `git status` 100% clean)

---

## 1. Executive Summary & Compliance Scorecard

A comprehensive, read-only inspection of the Peer-to-Peer (P2P) Device Sync module (`lib/features/sync/presentation/screens/p2p_sync_screen.dart`, `lib/features/sync/presentation/widgets/qr_scanner_dialog.dart`, `lib/features/sync/providers/p2p_sync_provider.dart`, `lib/features/sync/data/p2p_pairing_model.dart`, and associated services `p2p_sync_service.dart`, `sync_merge_service.dart`, `sync_crypto_service.dart`) was conducted.

The sync engine possesses a robust cryptographic and networking foundation: AES-256-GCM encrypted payloads, UDP beacon broadcasting on port 8766, HTTP REST synchronization on port 8765, immutable `deviceId` UUID generation, multi-network `DeviceEndpoint` tracking, and atomic Last-Write-Wins (LWW) delta merges across SQLite tables.

However, the user interface and presentation layer suffer from notable Material 3 Expressive regressions, legacy component aliases, missing connected corner morphing in paired device lists, inert animations, cramped trailing touch targets, unconfirmed destructive actions, and an architectural state-refresh omission where synced financial and health records fail to update in-memory providers upon sync completion.

### Compliance Scorecard

| Dimension | Weight | Score | Status | Key Observation |
|---|:---:|:---:|:---:|---|
| **1. Surface Elevation Hierarchy** | 20% | **17 / 20** (85%) | ⚠️ Tech Debt | 100% free of `BackdropFilter` and GPU blur; however, still references legacy `FrostedGlassSliverAppBar` and `AppCard.frosted` constructors. |
| **2. Shape Scale Hierarchy** | 20% | **13 / 20** (65%) | ❌ Deviant | Stadium pills for buttons and chips are compliant, but grouped paired devices list completely lacks Connected Corner Morphing (isolated cards with 16dp radii and 8dp gaps). Pair code badge uses 12dp squircle instead of stadium pill. |
| **3. Motion & Physics** | 15% | **6 / 15** (40%) | ❌ Deviant | `BouncingWidget` on primary CTA is completely inert (missing `onTap`); radar pulse animation during UDP beacon hosting is absent; uses standard `CircularProgressIndicator` instead of M3 Expressive wavy progress. |
| **4. Touch & Accessibility** | 20% | **11 / 20** (55%) | ❌ Deviant | Missing `Semantics(button: true)` across custom IconButtons; 3 trailing icon buttons cramped side-by-side ($144\text{dp}$ width) in peer cards; destructive "Unpair Device" lacks confirmation modal; QR scanner lacks `errorBuilder`, torch, and camera switch. |
| **5. Sync Invariants & Architecture** | 25% | **17 / 25** (68%) | ⚠️ Incomplete | Hero card dynamic opacities (55% light, 22% dark, 1.2px border), immutable UUIDs, and optical QR contrast are 100% compliant. However, `ignoreNextResumeLock` is missing on QR scanner push; sync completion only notifies `NoteProvider`, leaving Finances and Health in-memory state stale; missing bottom FAB clearance padding (`AppLayout.fabBottomPadding`). |
| **Overall Composite** | **100%** | **64%** | **Level 2 Priority** | Core transport and security are sound; presentation, shape scale, interaction safety, and reactive provider refreshes require targeted alignment. |

---

## 2. Detailed Findings by Dimension

### Dimension 1: Surface Elevation Hierarchy & Zero Blur (Score: 85%)

#### Compliant Aspects
- **Complete Elimination of Gaussian Blurs**: Ripgrep search across `lib/features/sync/` confirms zero occurrences of `BackdropFilter` or `ui.ImageFilter.blur`.
- **Solid Tonal Containers**: Background surfaces cleanly adhere to solid M3 container tokens:
  - `surfaceContainerLow` in `ExpressiveSliverAppBar` (aliased).
  - `surfaceContainerHigh` in `AppCard` (lines 482, 684, 712, 802, 848) and `AppDialog` (line 46).
  - `surfaceContainerHighest` for text field inputs and pair code containers.

#### Deviations & Technical Debt
1. **Legacy Header Re-Export Alias**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart`
     - Line 12: `import 'package:note_taking_app/core/ui/frosted_sliver_app_bar.dart';`
     - Line 295: `const FrostedGlassSliverAppBar(titleText: 'Master P2P Device Sync', showBackButton: true)`
   - **File**: `lib/features/sync/presentation/widgets/qr_scanner_dialog.dart`
     - Line 4: `import '../../../../core/ui/frosted_sliver_app_bar.dart';`
     - Line 45: `FrostedGlassSliverAppBar(titleText: 'Scan Pair QR Code', showBackButton: true)`
   - **Severity**: Medium (Technical Debt & Invariant Violation).
   - **Analysis**: Both screens import `frosted_sliver_app_bar.dart` and instantiate `FrostedGlassSliverAppBar`. Although `frosted_sliver_app_bar.dart` re-exports `expressive_sliver_app_bar.dart`, this violates Invariant 1 ("Seamless Borderless Surface Bars: Top app bars (ExpressiveSliverAppBar)") and Invariant 2 ("No Stubs / Direct Imports").
   - **Remediation**: Import `package:note_taking_app/core/ui/expressive_sliver_app_bar.dart` and replace `FrostedGlassSliverAppBar` with `ExpressiveSliverAppBar`.

2. **Obsolete Constructor Call `AppCard.frosted` on Top Hero Card**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:304`
     ```dart
     AppCard.frosted(
       backgroundColor: heroBg,
       border: BorderSide(
         color: heroBorder,
         width: 1.2,
       ),
       child: ...
     )
     ```
   - **Severity**: Low (Naming Debt).
   - **Analysis**: In `lib/core/ui/app_card.dart`, `AppCard.frosted` has been stripped of all blur filters and is pure solid surface. Calling `.frosted` is an obsolete naming pattern.
   - **Remediation**: Instantiate as `AppCard` directly with `backgroundColor: heroBg` and `border: BorderSide(color: heroBorder, width: 1.2)`.

---

### Dimension 2: Shape Scale Hierarchy & Connected Corner Morphing (Score: 65%)

#### Compliant Aspects
- **Status Badges**: Line 355 uses `AppChip(label: ..., isSelected: true)`. `AppChip` enforces `AppLayout.radiusStadium` (1000dp), rendering a soft, tactile M3 stadium pill.
- **Action Buttons**: Lines 97, 394, 444, 654, 674, 825, 833 use `FilledButton`, `FilledButton.tonal`, and `OutlinedButton`, all inheriting `shape: const StadiumBorder()` from `app_theme.dart`.
- **Dialogs & Sheets**: `_showPairDeviceDialog` uses `AppDialog` (inherits `radiusXXL` 28dp from `dialogTheme`), and `_showQrCodeModal` uses `AppBottomSheet` (inherits `radiusXXL` 28dp top squircle from `bottomSheetTheme`).

#### Deviations & Deficiencies
1. **Grouped Paired Devices List Lacks Connected Corner Morphing**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:707-797`
     ```dart
     ...syncProvider.pairedDevices.map((device) {
       final targetIp = device.ipAddress;
       return Padding(
         padding: const EdgeInsets.only(bottom: AppLayout.spaceS),
         child: AppCard(
           child: Row(
             ...
           ),
         ),
       );
     })
     ```
   - **Severity**: High (M3 Expressive Shape Hierarchy Violation).
   - **Analysis**: Invariant 1 in `AGENTS.md` strictly mandates:
     > *"Connected Corner Morphing for grouped lists (first item rounded top, middle items flat, last item rounded bottom)."*
     Currently, each paired device is wrapped in an isolated `AppCard` with individual 16dp rounded corners and `bottom: 8dp` spacing. When multiple devices are paired, the list appears fragmented rather than a unified M3 Expressive grouped surface container.
   - **Remediation**:
     Apply connected corner morphing based on index and length:
     - Single item (`length == 1`): `borderRadius: BorderRadius.circular(AppLayout.radiusL)` (16dp).
     - First item (`index == 0`): `borderRadius: const BorderRadius.vertical(top: Radius.circular(AppLayout.radiusL), bottom: Radius.circular(AppLayout.radiusXS))`.
     - Middle items (`0 < index < length - 1`): `borderRadius: BorderRadius.circular(AppLayout.radiusXS)` (4dp).
     - Last item (`index == length - 1`): `borderRadius: const BorderRadius.vertical(top: Radius.circular(AppLayout.radiusXS), bottom: Radius.circular(AppLayout.radiusL))`.
     - Replace `Padding(bottom: AppLayout.spaceS)` with a subtle 1px divider `Divider(height: 1, indent: 16, endIndent: 16)` inside a single grouped surface container, or connected cards with `0dp` margin and `1px` overlapping borders.

2. **6-Digit Pair Code Container Shape Inconsistency**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:555-575`
     ```dart
     decoration: BoxDecoration(
       color: colorScheme.primaryContainer.withValues(alpha: 0.5),
       borderRadius: BorderRadius.circular(AppLayout.radiusM), // 12dp squircle
       border: Border.all(
         color: colorScheme.primary.withValues(alpha: 0.3),
       ),
     ),
     ```
   - **Severity**: Low (Visual Inconsistency).
   - **Analysis**: Status badges and key identifiers across the app follow the Stadium Pill convention (`AppLayout.radiusStadium` = 1000dp). Using `AppLayout.radiusM` (12dp) creates a boxed appearance rather than an authentic tactile pill capsule.
   - **Remediation**: Use `borderRadius: BorderRadius.circular(AppLayout.radiusStadium)` to match other code and status badges.

---

### Dimension 3: Motion, Spring Physics & Radar Pulse Animations (Score: 40%)

#### Deviations & Deficiencies
1. **Completely Inert `BouncingWidget` on Primary CTA (Sync & Merge Now)**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:389-437`
     ```dart
     Expanded(
       flex: 3,
       child: SizedBox(
         height: 48,
         child: BouncingWidget(
           child: FilledButton.icon(
             onPressed: isSyncing
                 ? null
                 : () async { ... },
             icon: ...
             label: ...
           ),
         ),
       ),
     ),
     ```
   - **Severity**: High (Interaction Bug & Broken Micro-Interaction).
   - **Analysis**:
     In `lib/widgets/bouncing_widget.dart:40-56`, the animation controller only advances on tap down if `widget.onTap != null || widget.onLongPress != null`:
     ```dart
     void _onTapDown(TapDownDetails details) {
       if (widget.onTap != null || widget.onLongPress != null) {
         _controller.forward();
       }
     }
     ```
     Because `onTap` was passed to `FilledButton.icon` and NOT to `BouncingWidget`, `widget.onTap` is `null`. Furthermore, `FilledButton`'s internal `InkWell` captures touch events first. Consequently, the `BouncingWidget` NEVER animates, leaving the primary button static and non-reactive to spring physics. This violates the `BouncingWidget Dual-Gesture Wrapper Rule` in `UI-UX-Specialist/SKILL.md` (Rule 51).
   - **Remediation**: Pass `onTap` directly to `BouncingWidget(onTap: isSyncing ? null : () async { ... })` and use a styled container or button that does not swallow gestures, or remove the redundant `BouncingWidget` wrapper since `FilledButton` already provides Material 3 `InkSparkle` tactile feedback.

2. **Absence of Radar Pulse Animation During UDP Hosting / Discovery**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:482-662`
   - **Severity**: Medium (Missing M3 Motion Experience).
   - **Analysis**:
     The app broadcasts a UDP beacon on port 8766 every 2 seconds (`startUdpBeacon`) and listens for incoming connections. However, in the UI, the hosting card displays only a static router icon `Icon(Icons.router_rounded)` and static text (`Checking Wi-Fi...`).
     There is no animated radar pulse, glowing ripple, or sinusoidal wave to visually signal that the Wi-Fi interface is actively radiating discovery beacons.
   - **Remediation**: Wrap the hosting icon in an animated sinusoidal radar pulse (using `AnimationController` with `AppLayout.curveEmphasizedDecelerate` and concentric translucent primary rings expanding from 20dp to 36dp with fading opacity).

3. **Legacy Progress Indicator**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:328-332`
     ```dart
     SizedBox(
       width: 24,
       height: 24,
       child: CircularProgressIndicator(
         strokeWidth: 2.5,
         valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
       ),
     )
     ```
   - **Severity**: Low (M3 Expressive Alignment).
   - **Analysis**: Uses standard Material 2 `CircularProgressIndicator` instead of the newly introduced `ExpressiveShapeMorphIndicator` (`lib/core/ui/expressive_shape_morph_indicator.dart`) or `ExpressiveWavyProgress` (`lib/core/ui/expressive_wavy_progress.dart`), which provide lively shape transformations and sinusoidal waves.

---

### Dimension 4: Touch Targets & Accessibility Semantics (Score: 55%)

#### Compliant Aspects
- **Copy Icon Buttons**: Lines 580 and 629 specify `constraints: const BoxConstraints(minWidth: 48, minHeight: 48)`, `visualDensity: VisualDensity.compact`, satisfying the $48 \times 48\text{dp}$ touch target requirement.

#### Deviations & Accessibility Hazards
1. **Severe Touch Target Crowding in Paired Device Cards**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:753-793`
     ```dart
     if (targetIp != null && targetIp.isNotEmpty)
       IconButton(
         icon: const Icon(Icons.sync_rounded),
         color: colorScheme.primary,
         tooltip: 'Sync with ${device.deviceName}',
         onPressed: ...
       ),
     IconButton(
       icon: const Icon(Icons.edit_outlined),
       tooltip: 'Rename ${device.deviceName}',
       onPressed: ...
     ),
     IconButton(
       icon: const Icon(Icons.delete_outline_rounded),
       color: colorScheme.error,
       tooltip: 'Unpair Device',
       onPressed: ...
     ),
     ```
   - **Severity**: High (Touch Target Conflict & Visual Overflow Risk).
   - **Analysis**:
     Three full $48 \times 48\text{dp}$ `IconButton`s are placed side-by-side in the trailing slot of the device card row.
     Together with the leading avatar ($40\text{dp}$) and spacing ($16\text{dp}$), these trailing buttons consume $144\text{dp}$ of horizontal space. On standard mobile viewports ($360\text{dp}$ width), only $\approx 104\text{dp}$ remains for the device name and multi-network endpoint subtitle (`${device.endpoints.length} network endpoints • 192.168.1.15 • Last synced...`).
     This causes extreme text truncation. More critically, the "Unpair" button sits directly adjacent to "Rename", creating high risk of accidental unpairing on touch devices.
   - **Remediation**:
     Keep the primary action ("Sync") as a standalone trailing button, and consolidate secondary actions ("Rename Device", "Remove Network Endpoint", "Unpair Device") into an M3 `PopupMenuButton` (`Icons.more_vert_rounded`) with compact visual density.

2. **Unconfirmed Destructive Action (Instant Unpair)**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:791`
     ```dart
     IconButton(
       icon: const Icon(Icons.delete_outline_rounded),
       color: colorScheme.error,
       tooltip: 'Unpair Device',
       onPressed: () => syncProvider.unpairDevice(device.deviceId),
     )
     ```
   - **Severity**: High (Data Safety / Accidental Deletion).
   - **Analysis**: Tapping the trash icon immediately invokes `syncProvider.unpairDevice(device.deviceId)` and deletes the paired device from SharedPreferences WITHOUT any confirmation dialog. If a user accidentally grazes this button while attempting to sync or rename, the pairing session, derived cryptographic key, and network endpoints are permanently deleted.
   - **Remediation**: Wrap in `AppDialog.showConfirm`:
     ```dart
     onPressed: () async {
       final confirmed = await AppDialog.showConfirm(
         context: context,
         title: 'Unpair Device?',
         message: 'Are you sure you want to unpair "${device.deviceName}"? You will need to scan its QR code again to sync.',
         confirmLabel: 'Unpair',
         isDestructive: true,
       );
       if (confirmed == true) {
         await syncProvider.unpairDevice(device.deviceId);
       }
     }
     ```

3. **Missing `Semantics(button: true)` & Accessible Labels**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:507, 516, 577, 626, 754, 778, 787`
   - **Severity**: Medium (Accessibility Defect).
   - **Analysis**: Interactive icon buttons supply tooltips but lack `Semantics(button: true, label: ...)` wrappers, preventing screen readers (TalkBack / VoiceOver) from announcing them unambiguously as actionable controls with localized descriptions.

4. **QR Scanner Accessibility & Fault Tolerance Defects**:
   - **File**: `lib/features/sync/presentation/widgets/qr_scanner_dialog.dart:28-65`
   - **Severity**: High (Accessibility & Sensor Failure Handling).
   - **Analysis**:
     - **Missing `errorBuilder`**: `MobileScanner` is instantiated without an `errorBuilder`. If camera permission is denied by the user, or the camera hardware is occupied, the user is presented with a black screen and no corrective action.
     - **Missing Flashlight / Torch Toggle**: Scanning a device screen in low-light environments frequently fails without torch illumination.
     - **Missing Camera Flip Toggle**: On devices with damaged primary rear lenses, users cannot switch to the front camera.
     - **Missing Manual Entry Fallback**: If scanning fails, there is no direct CTA inside the scanner sheet to fall back to manual 6-digit IP/code entry.

---

### Dimension 5: Sync Invariants & Multi-Domain Architectural State Refresh (Score: 68%)

#### Compliant Aspects
- **Dynamic Hero Card Opacities & 1.2px Border Accent**:
  - `lib/features/sync/presentation/screens/p2p_sync_screen.dart:284-290`
    - Light Mode: `colorScheme.primaryContainer.withValues(alpha: 0.55)` (55% alpha).
    - Dark Mode: `colorScheme.primaryContainer.withValues(alpha: 0.22)` (22% alpha).
    - Border Width: `1.2`.
    - Border Opacity: 45% in light mode, 35% in dark mode.
    - Matches Invariant 1 in `AGENTS.md` with 100% precision.
- **Immutable deviceId UUIDs & Multi-Network Endpoints**:
  - `P2pSyncService.getDeviceId()` generates an immutable UUID v4 persisted in `p2p_local_device_id_v1`.
  - `PairedDevice` maintains an immutable `deviceId` UUID with multi-network `DeviceEndpoint` lists, preventing duplicate peer entries when IPs change across home/work Wi-Fi networks. Complies with Invariant 6.
- **Optical High-Contrast QR Code Standard**:
  - `lib/features/sync/presentation/screens/p2p_sync_screen.dart:197-218`:
    - Container background: `Colors.white` with 16dp quiet-zone padding.
    - Eye shape: `QrEyeShape.square` with `Colors.black`.
    - Data modules: `QrDataModuleShape.circle` with `Colors.black`.
    - Zero off-white or theme color contamination, guaranteeing reliable optical camera capture across both light and dark modes.

#### Violations & Architectural Deficiencies
1. **Missing `ignoreNextResumeLock` on QR Scanner Navigation**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:98-102`
     ```dart
     onPressed: () async {
       final scanned = await Navigator.push<String>(
         context,
         MaterialPageRoute(builder: (_) => const QrScannerScreen()),
       );
     ```
   - **Severity**: High (Security / Usability Invariant Violation).
   - **Analysis**:
     Invariant 5 and 12 in `AGENTS.md` mandate:
     > *"Local Auth / Dialog Resume: Screens invoking native file pickers, camera, or share sheets must call `AppLockScreen.ignoreNextResumeLock()` to prevent unintentional app locking on resume."*
     When `QrScannerScreen` launches, Android OS permission dialogs or camera initialization can cause `AppLifecycleState` to transition to `inactive`/`paused`. When returning or resuming, `AppLockScreen` locks the application, kicking the user out of the pairing wizard and forcing biometric/PIN re-entry.
   - **Remediation**: Call `AppLockScreen.ignoreNextResumeLock();` immediately before `Navigator.push(context, ...)`.

2. **Architectural State Refresh Omission: Provider Desynchronization on Sync Completion**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:67-68, 400-401, 764-765`
     ```dart
     await syncProvider.syncBiDirectional(
       targetIp: ip,
       onCompleted: () {
         noteProvider.refreshNotes();
       },
     );
     ```
   - **Severity**: Critical (Data Staleness & Architecture Flaw).
   - **Analysis**:
     `SyncMergeService.instance.mergeRemoteData(clientData)` atomically merges:
     1. Notes (`notes`)
     2. Transactions (`transactions`)
     3. Split Bills & Participants (`split_bills`, `split_participants`, `split_contacts`)
     4. Savings Goals (`savings_goals`)
     5. Menstrual Period Logs (`period_logs`)
     6. Category Definitions (`category_definitions`)
     7. Recurring Rules (`recurring_rules`)

     However, `P2pSyncScreen` only calls `noteProvider.refreshNotes()`.
     It completely neglects to refresh:
     - `FinancialManagerProvider.loadTransactions()`
     - `SplitBillProvider.loadSplitBills()`
     - `SavingsGoalProvider.loadSavingsGoals()`
     - `PeriodTrackerProvider.loadLogs()`

     As a direct consequence, if a user performs a manual sync or pairs a device from `P2pSyncScreen`, newly received financial transactions, shared split bills, target savings deposits, and menstrual logs are written to SQLite but are **NOT loaded into active provider memory**. When the user navigates back to Finances or Health, the screens display outdated data until the app process is terminated and restarted.
   - **Remediation**:
     Create a unified post-sync dispatcher or refresh all providers when `context.mounted`:
     ```dart
     void _refreshAllDomainProviders(BuildContext context) {
       if (!context.mounted) return;
       Provider.of<NoteProvider>(context, listen: false).refreshNotes();
       Provider.of<FinancialManagerProvider>(context, listen: false).loadTransactions();
       Provider.of<SplitBillProvider>(context, listen: false).loadSplitBills();
       Provider.of<SavingsGoalProvider>(context, listen: false).loadSavingsGoals();
       Provider.of<PeriodTrackerProvider>(context, listen: false).loadLogs();
     }
     ```

3. **Missing Bottom Scroll Clearance (`AppLayout.fabBottomPadding`)**:
   - **File**: `lib/features/sync/presentation/screens/p2p_sync_screen.dart:300`
     ```dart
     SliverPadding(
       padding: const EdgeInsets.all(AppLayout.spaceM),
       sliver: SliverList(...)
     )
     ```
   - **Severity**: Medium (Invariant 8 Violation).
   - **Analysis**: Invariant 8 dictates that scrollable views must supply `AppLayout.fabBottomPadding = 96.0` to prevent bottom chrome or gesture bars from clipping content. The last card ("Event Auto-Sync") terminates with only 16dp padding, leaving it crowded against the system navigation bar.
   - **Remediation**: Use:
     ```dart
     padding: const EdgeInsets.fromLTRB(
       AppLayout.spaceM,
       AppLayout.spaceM,
       AppLayout.spaceM,
       AppLayout.fabBottomPadding,
     ),
     ```

---

## 3. Inventory of Hardcoded Values, Legacy Patterns & Inconsistencies

| File Path | Line(s) | Value / Code Pattern | Issue Description | Token / Recommended Replacement |
|---|---|---|---|---|
| `p2p_sync_screen.dart` | 12 | `import '.../frosted_sliver_app_bar.dart';` | Legacy stub re-export import | `import 'package:note_taking_app/core/ui/expressive_sliver_app_bar.dart';` |
| `p2p_sync_screen.dart` | 32, 74, 113, 187 | `8765` | Magic port number | `P2pSyncService.httpSyncPort` |
| `p2p_sync_screen.dart` | 96, 443, 653 | `height: 48` | Hardcoded button height | Standard theme button style (`minimumSize: Size(0, 48)`) |
| `p2p_sync_screen.dart` | 98–102 | `Navigator.push<String>(...)` | Missing lock ignore on camera launch | `AppLockScreen.ignoreNextResumeLock();` before push |
| `p2p_sync_screen.dart` | 209 | `size: 210.0` | Magic double for QR code dimension | Named responsive token (e.g. `AppLayout.qrCodeSize = 220.0`) |
| `p2p_sync_screen.dart` | 228 | `letterSpacing: 4.0` | Magic typography letter spacing | Typography token / standard spacing |
| `p2p_sync_screen.dart` | 230, 363, 372, 551, 816 | `const SizedBox(height: 4)` | Magic spacing constant | `const SizedBox(height: AppLayout.spaceXS)` |
| `p2p_sync_screen.dart` | 295 | `FrostedGlassSliverAppBar(...)` | Legacy widget constructor name | `ExpressiveSliverAppBar(...)` |
| `p2p_sync_screen.dart` | 304 | `AppCard.frosted(...)` | Legacy card constructor name | `AppCard(...)` with explicit border & bg |
| `p2p_sync_screen.dart` | 317 | `padding: EdgeInsets.all(AppLayout.spaceS + 2)` | Math expression (10dp) inside padding | `AppLayout.paddingAllM` or dedicated token |
| `p2p_sync_screen.dart` | 336 | `size: 26` | Magic icon size | `AppLayout.iconM` or standard 24dp |
| `p2p_sync_screen.dart` | 393–436 | `BouncingWidget(child: FilledButton.icon(...))` | Inert bouncing widget; swallowed events | Remove `BouncingWidget` or configure `onTap` properly |
| `p2p_sync_screen.dart` | 556 | `EdgeInsets.symmetric(horizontal: 10, vertical: 6)` | Magic padding numbers | `AppLayout.paddingBadge` / design token |
| `p2p_sync_screen.dart` | 560 | `BorderRadius.circular(AppLayout.radiusM)` | 12dp radius instead of stadium pill | `BorderRadius.circular(AppLayout.radiusStadium)` |
| `p2p_sync_screen.dart` | 570 | `letterSpacing: 2.0` | Magic spacing | `AppLayout.letterSpacingCode` |
| `p2p_sync_screen.dart` | 607, 615 | `const SizedBox(height: 6)` / `(width: 6)` | Magic 6dp spacing | `AppLayout.spaceXS` or `spaceS` |
| `p2p_sync_screen.dart` | 711–796 | `syncProvider.pairedDevices.map((device) => AppCard(...))` | Isolated cards without connected corners | Grouped connected corner morphing |
| `p2p_sync_screen.dart` | 753–793 | 3 trailing `IconButton`s side-by-side | Horizontal cramping ($144\text{dp}$), unconfirmed delete | Split CTA + M3 `PopupMenuButton` (`⋮`) |
| `p2p_sync_screen.dart` | 791 | `onPressed: () => syncProvider.unpairDevice(...)` | Unconfirmed destructive delete | `AppDialog.showConfirm(...)` |
| `p2p_sync_screen.dart` | 300 | `SliverPadding(padding: EdgeInsets.all(AppLayout.spaceM))` | Missing bottom clearance | `bottom: AppLayout.fabBottomPadding` (96dp) |
| `qr_scanner_dialog.dart` | 4 | `import '.../frosted_sliver_app_bar.dart';` | Legacy stub re-export import | `import 'package:note_taking_app/core/ui/expressive_sliver_app_bar.dart';` |
| `qr_scanner_dialog.dart` | 28–42 | `MobileScanner(...)` | Missing `errorBuilder` for denied camera | Provide fallback error container & settings CTA |
| `qr_scanner_dialog.dart` | 45 | `FrostedGlassSliverAppBar(...)` | Legacy widget constructor name | `ExpressiveSliverAppBar(...)` |
| `qr_scanner_dialog.dart` | 53–54 | `width: 250, height: 250` | Hardcoded reticle dimensions | Proportional calculation (e.g. `size.width * 0.65`) |
| `qr_scanner_dialog.dart` | 58 | `width: 3` | Magic border width | `AppLayout.borderThick = 2.0` or standard token |

---

## 4. Prioritized Actionable Implementation Roadmap

```
                                  P2P SYNC ENGINE REMEDIATION
 ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
 │                                                                                             │
 │   PHASE 1: CRITICAL INVARIANTS, SECURITY & DATA INTEGRITY                                  │
 │   • Add AppLockScreen.ignoreNextResumeLock() to QrScanner navigation.                       │
 │   • Implement AppDialog.showConfirm() modal for "Unpair Device" destructive CTA.            │
 │   • Unify post-sync reactive dispatch to refresh Note, Finance, Split, & Health providers.  │
 │                                                                                             │
 ├─────────────────────────────────────────────────────────────────────────────────────────────┤
 │                                                                                             │
 │   PHASE 2: M3 EXPRESSIVE SHAPE SCALE & LAYOUT ALIGNMENT                                     │
 │   • Implement Connected Corner Morphing for paired devices list.                            │
 │   • Modernize trailing buttons: Standalone Sync CTA + M3 PopupMenuButton for device options.│
 │   • Standardize Pair Code badge to Stadium Pill (radiusStadium = 1000dp).                   │
 │   • Apply AppLayout.fabBottomPadding (96dp) for scroll clearance.                           │
 │   • Replace FrostedGlassSliverAppBar & AppCard.frosted with ExpressiveSliverAppBar/AppCard.│
 │                                                                                             │
 ├─────────────────────────────────────────────────────────────────────────────────────────────┤
 │                                                                                             │
 │   PHASE 3: MOTION, MICRO-INTERACTIONS & SENSOR RESILIENCE                                   │
 │   • Add sinusoidal radar pulse animation to Hosting card during active UDP beacon state.    │
 │   • Fix or remove inert BouncingWidget on "Sync & Merge Now" button.                        │
 │   • Add MobileScanner errorBuilder, torch toggle, and camera flip to QrScannerScreen.       │
 │   • Replace magic numbers (ports, paddings, sizes) with AppLayout & P2pSyncService tokens.  │
 │                                                                                             │
 └─────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Phase 1: Critical Invariants, Security & Data Integrity
1. **Prevent Unintentional App Locking**:
   - In `P2pSyncScreen._showPairDeviceDialog`, invoke `AppLockScreen.ignoreNextResumeLock()` immediately prior to `Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()))`.
2. **Prevent Accidental Peer Unpairing**:
   - In `P2pSyncScreen`, wrap `syncProvider.unpairDevice(device.deviceId)` inside `AppDialog.showConfirm`.
3. **Multi-Domain Reactive State Refresh**:
   - Update `onCompleted` callbacks across `P2pSyncScreen` to refresh `NoteProvider`, `FinancialManagerProvider`, `SplitBillProvider`, `SavingsGoalProvider`, and `PeriodTrackerProvider` so all domain modules immediately display synced records.

### Phase 2: M3 Expressive Shape Scale & Layout Polish
1. **Connected Corner Morphing**:
   - Replace isolated paired device `AppCard` widgets with connected corner geometry based on item index.
2. **Trailing Button De-cluttering**:
   - Replace the cramped 3-icon trailing cluster with a primary `IconButton` for "Sync" and an M3 `PopupMenuButton<String>` containing "Rename Device", "View Network Endpoints", and "Unpair Device".
3. **Shape Scale Uniformity**:
   - Update the 6-digit pair code badge from `radiusM` (12dp) to `radiusStadium` (1000dp).
4. **Header and Constructor Hygiene**:
   - Replace all `FrostedGlassSliverAppBar` imports and constructor invocations with `ExpressiveSliverAppBar`.
   - Replace `AppCard.frosted` with standard `AppCard`.
5. **Scroll Clearance**:
   - Apply `bottom: AppLayout.fabBottomPadding` to `SliverPadding`.

### Phase 3: Motion, Micro-Interactions & Scanner Resilience
1. **Hosting Radar Pulse**:
   - Implement an M3 animated radar ripple around the `Icons.router_rounded` icon in the Hosting card while the server is active.
2. **Micro-Interaction Repair**:
   - Remove the inert `BouncingWidget` wrapper on `FilledButton.icon` or implement true spring scaling.
3. **Scanner Fault Tolerance**:
   - Add `errorBuilder: (context, error, child) => ...` in `QrScannerScreen` to display a clean M3 permission/error state with an action to open app settings or enter code manually.
   - Add torch toggle and camera switch buttons in the scanner top bar.
4. **Tokenization**:
   - Replace magic port `8765` with `P2pSyncService.httpSyncPort`.
   - Replace hardcoded spacing (`4`, `6`, `10`) with `AppLayout.spaceXS` and `spaceS`.

---

## 5. Architectural Verification & Regression Guardrails

When these recommendations are implemented in subsequent phases, the following verification suite must pass:

1. **Static Analysis & Invariants**:
   ```bash
   flutter analyze
   ```
   Must produce 0 errors, 0 warnings, and 0 lints.
2. **Existing P2P Sync Automated Unit & Integration Tests**:
   ```bash
   flutter test test/services/p2p_sync_service_test.dart
   flutter test test/services/sync_crypto_service_test.dart
   flutter test test/features/sync/sync_merge_test.dart
   ```
   All test cases verifying AES-256 payload encryption, UDP datagram serialization, LWW soft-delete merges, and tombstone persistence must pass with 100% success.
3. **New Widget Test Requirements**:
   - `test/features/sync/p2p_sync_screen_test.dart`: Verify that `P2pSyncScreen` renders `ExpressiveSliverAppBar`, applies connected corner geometry across multiple paired devices, requires confirmation before unpairing, and calls `AppLockScreen.ignoreNextResumeLock()` before pushing `QrScannerScreen`.
   - `test/features/sync/qr_scanner_screen_test.dart`: Verify that `QrScannerScreen` handles camera initialization errors via `errorBuilder` without unhandled exceptions.
