# Settings, App Lock, Backups & Onboarding Domain Audit Report

## Executive Summary
This comprehensive, read-only architectural audit evaluates the **Settings & Preferences**, **App Lock**, **AES-256 Backups & Data Portability**, **Full-Screen Onboarding Wizard**, and **Hardware NPU AICore Intelligence Gating** modules (`lib/features/settings/`, `lib/services/backup_service.dart`, `lib/screens/app_lock_screen.dart`, `lib/services/gemini_nano_service.dart`, and associated widget/test suites) for **Everything App**.

The audit verified robust compliance with core invariants while identifying specific resilience enhancements, accessibility refinements, and missing native resume lock bypasses.

---

## 1. Domain Architectural Mapping & Component Inventory

| Component / Subsystem | Primary Source File | Associated Providers / Models | Key Architectural Role |
|---|---|---|---|
| **Onboarding Wizard** | `lib/features/settings/presentation/screens/onboarding_screen.dart` | `SettingsProvider`, `P2pSyncProvider`, `NoteProvider` | 5-slide interactive wizard, setup mode selection, live theme previews, modular feature toggles, NPU detection, pro-tips. |
| **Settings Control Hub** | `lib/features/settings/presentation/screens/settings_screen.dart` | `SettingsProvider` | Centralized preferences dashboard, real-time search with filter chips, hero status card, module toggles, currency/backup pickers. |
| **Settings State Manager** | `lib/features/settings/providers/settings_provider.dart` | `SharedPreferences`, `CustomSmsRule`, `CategoryDefinition` | Decoupled reactive `ChangeNotifier`, preferences persistence, backup map serialization/deserialization, AICore capability polling. |
| **Settings UI Primitives** | `lib/widgets/settings_widgets.dart` | `AppLayout`, `AppTheme`, `AppChip` | Reusable atomic settings components: `SettingsHeroCard`, `SettingsSection`, `SettingsTile`, `SettingsSwitchTile`, `SettingsSegmentedTile`. |
| **Backup & Export Service** | `lib/services/backup_service.dart` | `DatabaseHelper`, `TransactionRepository`, `RecurringRuleRepository` | Offline AES-256 JSON snapshot generation, passive WAL checkpointing, atomic restore, resilient SAF fallback, Workmanager auto-backup. |
| **App Lock Supervisor** | `lib/screens/app_lock_screen.dart` | `LocalAuthentication`, `SettingsProvider` | Root biometric/PIN authentication gate, inactivity timeout tracking, one-shot native picker bypass flag (`ignoreNextResumeLock`). |
| **On-Device AI Engine** | `lib/services/gemini_nano_service.dart`, `lib/services/local_ai_service.dart` | `gemini_nano_android`, `OfflineAiFallbackService` | Hardware-accelerated on-device LLM inference via Android AICore / Gemini Nano with heuristic NLP fallbacks. |

---

## 2. Detailed Findings by Audit Scope

### Scope 1: Full-Screen Onboarding Wizard (`OnboardingScreen`)
- **Slide Flow & Setup Choice**:
  - **Slide 1 (Welcome & Vision)**: Provides distinct paths for "Primary Device (New Notebook)" vs "Pair & Import from Primary Device" (`QrScannerScreen` + `P2pSyncProvider.syncBiDirectional`).
  - **Slide 2 (Personalization & Live Theme)**: Real-time interactive switching between System, Light, and Dark theme modes (`settings.setThemeMode`), immediately reflecting across the active widget tree. Dynamic Color extraction switch toggles Material You wallpaper palettes.
  - **Slide 3 (Modular Powerups)**: Contextual toggles for Financial Manager (revealing sub-cards for Auto SMS Background Sync, Savings Vault / Dual Accounts, and Custom Bank SMS Training), Period & Health Tracker, and Split Bills & Shared Debts.
  - **Slide 4 (On-Device Gemini AI Setup)**: Displays hardware NPU detection badge (`settings.isDeviceAiSupported`), cleanly explaining hardware acceleration vs rule-based heuristic engines, and provides user opt-in toggle (`settings.setUseOnDeviceAi`).
  - **Slide 5 (Ready to Explore & Pro-Tips)**: Interactive feature cards with direct navigation triggers (e.g. `"Configure P2P Sync ➔"` launching `P2pSyncScreen`).
- **Responsive Width Clamping & Layout**:
  - Body wrapped in `ConstrainedBox(constraints: BoxConstraints(maxWidth: AppLayout.maxContentWidth))` (600dp), ensuring balanced typography on tablets and foldables.
  - Each slide utilizes `SingleChildScrollView` to prevent keyboard or small-screen vertical overflows.
- **UI/UX & Touch Accessibility Findings**:
  - *Observation*: In `_buildFeatureCard` (`onboarding_screen.dart:1075`), the action button (`'Configure P2P Sync ➔'`) sets `minimumSize: Size.zero` and `tapTargetSize: MaterialTapTargetSize.shrinkWrap`.
  - *Impact*: Tap area is less than the standard $48 \times 48\text{dp}$ touch target requirement (AGENTS.md Invariant 10).
  - *Remediation*: Wrap with `BoxConstraints(minHeight: 48, minWidth: 48)` and provide `Semantics(button: true)`.
  - *Observation*: Slide indicator dots (`onboarding_screen.dart:172-188`) are currently static indicators.
  - *Improvement*: Allow direct page jumps on tapping pagination dots while enclosing each in a minimum $48 \times 48\text{dp}$ touch area.

---

### Scope 2: Settings Replayability
- **Re-Launch Safety**:
  - `SettingsScreen` provides a "Replay Setup & Intro" tile under the About section (`settings_screen.dart:750`, `1217`), navigating via `MaterialPageRoute(builder: (_) => const OnboardingScreen(isReplay: true))`.
  - Step counter badge in `OnboardingScreen` dynamically adapts: `widget.isReplay ? 'Step X of 5' : 'Welcome X/5'`.
  - Completing or skipping the replay wizard updates `hasSeenOnboarding_v1` and `lastSeenVersion` without resetting SQLite database tables, notes, transactions, tags, or user preferences.
- **Assessment**: Replayability architecture is clean, stateless with respect to data tables, reactive, and completely safe.

---

### Scope 3: Resilient Protected Auto-Backup Storage Priority
- **Storage Priority & SAF Fallback**:
  - `BackupService.performAutoBackup()` (`backup_service.dart:136-175`) evaluates `prefs.getString('autoBackupPath')`. If the directory is unavailable or write permissions are revoked (a common Android SAF issue after system reboots), it catches the exception and immediately falls back to `getApplicationDocumentsDirectory()` (`appDir.path`).
  - `SettingsScreen._showBackupLocationPicker` (`settings_screen.dart:1551-1625`) prioritizes `"Secure App Storage (Recommended)"` (`autoBackupPath == null`), describing it as `"Stored in protected app documents — never revoked across OS updates"`.
- **Atomic WAL & Data Snapshot Invariants**:
  - `generateBackupJson()` executes `PRAGMA wal_checkpoint(PASSIVE);` prior to querying `notes`, `tags`, `note_tags`, `transactions`, `category_definitions`, `sms_contacts`, `period_logs`, `recurring_rules`, `deleted_notes`, and `deleted_transaction_sms_ids`.
  - `restoreFromBackupData()` commits all data inside an atomic SQLite transaction batch (`db.transaction((txn) async { ... batch.commit(noResult: true); })`), followed by invalidation reloads (`TransactionCategory.reload()`, `SmsService.reloadSmsContacts()`, `WidgetHelper.updateWidgetData()`, `NoteProvider.refreshNotes()`).
  - Security configurations (`appLockEnabled`, `useBiometrics`) are purposefully excluded during `restoreFromBackupMap` (`settings_provider.dart:680-686`), preventing untrusted backup files from disabling device security.
  - Auto-backups maintain a 5-file rotation lifecycle (`_rotateBackups`), automatically pruning older backup files.

---

### Scope 4: Hardware NPU AICore Detection & Gating (`settings.isAiActive`)
- **Single Source of Truth**:
  - `SettingsProvider.isAiActive` (`settings_provider.dart:113`):
    ```dart
    bool get isAiActive => _useOnDeviceAi && _isDeviceAiSupported;
    ```
- **Lifecycle & Startup Registration**:
  - In `lib/main.dart` (lines 100-107), `LocalAiService` is registered as `GeminiNanoService()`.
  - `SettingsProvider.checkAiCoreSupport(aiService)` is invoked during provider creation, querying `GeminiNanoAndroid.isAvailable()` and calling `notifyListeners()`.
- **UI Gating Audit Across All Modules**:
  - `SettingsScreen` (`settings_screen.dart:463`, `900`): Gated on `settings.isDeviceAiSupported`. If the device has no NPU, the Gemini Nano switch is hidden from both the main list and search results.
  - `SettingsHeroCard` (`settings_screen.dart:399`): Gated on `settings.isAiActive`.
  - `FinancialManagerScreen` (`financial_manager_screen.dart:1366`): Gated on `settings.isAiActive` for `ai_refine` menu option.
  - `TransactionEditorScreen` (`transaction_editor_screen.dart:826`): Suffix sparkle icon button in Description input is gated on `settings.isAiActive`.
  - `NoteEditorScreen` (`note_editor_screen.dart:4114`): Floating AI assist toolbar button is gated on `settings.isAiActive`.
  - `ReceiptScannerSheet` (`receipt_scanner_sheet.dart:59`): Passes `isAiActive: settings.isAiActive` to `ReceiptScannerService`.
- **Assessment**: AI gating strictly complies with Invariant 3. Non-NPU devices and emulators are completely shielded from non-functional AI UI triggers.

---

### Scope 5: AppLockScreen & Biometric Resume Handling (`ignoreNextResumeLock`)
- **Root Security Gate**:
  - `AppLockScreen` (`lib/screens/app_lock_screen.dart`) monitors `AppLifecycleState`.
  - Evaluates inactivity timeout (`settings.appLockTimeout`) upon `AppLifecycleState.resumed`.
  - Locks screen only when transitioning from `AppLifecycleState.paused` (true background), avoiding locks on transient `inactive` states.
- **One-Shot Bypass Flag**:
  - `AppLockScreen.ignoreNextResumeLock()` sets `_ignoreNextResumeLock = true`. When resuming, this flag consumes the event and prevents locking.
- **⚠️ Critical Vulnerability Findings — Missing Picker Bypasses**:
  1. `BackupService.importBackup(BuildContext context)` (`lib/services/backup_service.dart:284`): `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'])` lacks `AppLockScreen.ignoreNextResumeLock()`. Returning from file selection triggers app lock and can dismiss the import confirmation dialog.
  2. `BackupService.importTransactionsFromCsv(BuildContext context)` (`lib/services/backup_service.dart:635`): `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'txt'])` lacks `AppLockScreen.ignoreNextResumeLock()`.
  3. `ReceiptScannerSheet._pickAndScan(ImageSource source)` (`lib/features/finances/presentation/widgets/receipt_scanner_sheet.dart:45`): Camera & Gallery invocations via `_picker.pickImage(source: source)` lack `AppLockScreen.ignoreNextResumeLock()`.
  4. `SplitShareService.shareToWhatsAppOrSystem` (`lib/features/finances/services/split_share_service.dart:75`): `Share.share(...)` lacks `AppLockScreen.ignoreNextResumeLock()`.
  5. `NoteEditorScreen._showShareMenu` (`lib/features/notes/presentation/screens/note_editor_screen.dart:1375, 1390, 1408`): Plain text share, Markdown share, and `.md` file export share sheets lack `AppLockScreen.ignoreNextResumeLock()`.

---

### Scope 6: Dynamic Text Scaling, Font Size Adaptation, and Theme Token Bindings
- **Global Typography Scale Invariant**:
  - `lib/main.dart` (lines 143-152) wraps the application widget tree with:
    ```dart
    builder: (context, child) {
      final mediaQueryData = MediaQuery.of(context);
      final deviceFontScale = mediaQueryData.textScaler.scale(1.0);
      return MediaQuery(
        data: mediaQueryData.copyWith(
          textScaler: TextScaler.linear(deviceFontScale * (settings.textSize / 16.0)),
        ),
        child: AppLockScreen(child: child!),
      );
    }
    ```
  - Small: 14.0px ($0.875\times$), Medium: 16.0px ($1.0\times$), Large: 20.0px ($1.25\times$).
- **Design Tokens Consistency**:
  - All Settings widgets adhere to `AppLayout` spacing and radius tokens (`spaceS`–`spaceXXL`, `radiusM`–`radiusMAX`).
  - Colors are sourced dynamically from `Theme.of(context).colorScheme`.
  - `FrostedGlassSliverAppBar` implements borderless frosted chrome with backdrop filter blur (`sigma 16.0`).
  - Hero cards dynamically switch container alphas (55% light mode, 22% dark mode with 1.2px accent borders).
- **Responsive Layout Protection**:
  - `SettingsHeroCard` wraps title and subtitle in `Expanded` and `FittedBox(fit: BoxFit.scaleDown)` to ensure zero text clipping at maximum text scaling (2.0x).
  - Search filter chips in `SettingsScreen` use horizontal scroll view with compact chips (`AppChip`).

---

## 3. Decoupled, Zero-Conflict Work Package Blueprint

### Work Package: Settings & Onboarding Polish & Lock Bypass Hardening

#### Sub-Task 1: Add Missing `AppLockScreen.ignoreNextResumeLock()` Calls
*Target Files*:
- `lib/services/backup_service.dart` (lines 280, 631)
- `lib/features/finances/presentation/widgets/receipt_scanner_sheet.dart` (line 43)
- `lib/features/finances/services/split_share_service.dart` (line 65)
- `lib/features/notes/presentation/screens/note_editor_screen.dart` (lines 1373, 1388, 1406)

*Proposed Changes*:
```dart
// lib/services/backup_service.dart: In importBackup()
static Future<void> importBackup(BuildContext context) async {
  try {
    AppLockScreen.ignoreNextResumeLock(); // Add bypass before opening native picker
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
...

// lib/services/backup_service.dart: In importTransactionsFromCsv()
static Future<void> importTransactionsFromCsv(BuildContext context) async {
  try {
    AppLockScreen.ignoreNextResumeLock(); // Add bypass before opening native picker
    FilePickerResult? result;
...

// lib/features/finances/presentation/widgets/receipt_scanner_sheet.dart: In _pickAndScan()
Future<void> _pickAndScan(ImageSource source) async {
  try {
    AppLockScreen.ignoreNextResumeLock(); // Add bypass before launching camera/gallery
    final XFile? file = await _picker.pickImage(source: source);
...

// lib/features/finances/services/split_share_service.dart: In shareToWhatsAppOrSystem()
static Future<void> shareToWhatsAppOrSystem(
  SplitBillModel bill, {
  String currencySymbol = 'Rs.',
  String? defaultPaymentInfo,
}) async {
  final text = formatBillSummary(
    bill,
    currencySymbol: currencySymbol,
    defaultPaymentInfo: defaultPaymentInfo,
  );
  AppLockScreen.ignoreNextResumeLock(); // Add bypass before opening share sheet
  await Share.share(
    text,
    subject: 'Split Bill: ${bill.title}',
  );
}
```

#### Sub-Task 2: Touch Target Accessibility Compliance in `OnboardingScreen`
*Target File*:
- `lib/features/settings/presentation/screens/onboarding_screen.dart` (line 1075)

*Proposed Changes*:
```dart
// Enforce minimum 48x48dp touch bounds on feature card action buttons
if (actionLabel != null && onAction != null) ...[
  const SizedBox(height: AppLayout.spaceS),
  Semantics(
    button: true,
    label: actionLabel,
    child: TextButton(
      onPressed: onAction,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(48, 48), // Enforce 48dp minimum touch bounds
        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        foregroundColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusS),
        ),
      ),
      child: Text(
        actionLabel,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ),
  ),
],
```

#### Sub-Task 3: Interactive Pagination Indicators for Onboarding Wizard
*Target File*:
- `lib/features/settings/presentation/screens/onboarding_screen.dart` (lines 172-188)

*Proposed Changes*:
```dart
// Wrap indicator dots with BouncingWidget / Semantics for direct navigation
Row(
  children: List.generate(_totalPages, (index) {
    final isActive = index == _currentPage;
    return Semantics(
      button: true,
      label: 'Go to slide ${index + 1}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _pageController.animateToPage(
            index,
            duration: AppLayout.animDefault,
            curve: AppLayout.curveFast,
          );
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: AppLayout.animShort,
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }),
),
```

---

## 4. Test Suite Validation & Verification Matrix

All test suites verify cleanly with zero failures and 0 analyzer warnings:
- `test/onboarding_test.dart`: 6 tests passing (Welcome slide rendering, slide navigation, theme mode toggling, module toggles, P2P sync navigation).
- `test/settings_and_lock_test.dart`: 6 tests passing (App lock defaults, timeout persistence, backup map serialization, security config restore filtering, AppLockScreen widget gating, timeout duration validation).
- `test/settings_search_test.dart`: 1 test passing (Settings search query filtering and clear button).
- `test/backup_service_test.dart`: 2 tests passing (Database schema initialization, backup JSON generation without SQL column id errors).
- `flutter analyze`: 0 issues found.
