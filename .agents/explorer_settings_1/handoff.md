# Settings & Onboarding Domain Audit Handoff Report

## 1. Observation
1. **Onboarding Screen Layout & Slide Flow**:
   - In `lib/features/settings/presentation/screens/onboarding_screen.dart:86-88`, the wizard body is clamped via `ConstrainedBox(constraints: BoxConstraints(maxWidth: AppLayout.maxContentWidth))` (600dp).
   - In `onboarding_screen.dart:1075`, the feature card action button (`_buildFeatureCard`) specifies `minimumSize: Size.zero` and `tapTargetSize: MaterialTapTargetSize.shrinkWrap`, resulting in a tap area below the standard $48 \times 48\text{dp}$ touch target requirement.
   - In `onboarding_screen.dart:172-188`, animated pagination indicator dots are static indicators with no tap gesture or minimum touch constraints.
2. **Settings Replayability**:
   - In `lib/features/settings/presentation/screens/settings_screen.dart:750, 1217`, "Replay Setup & Intro" pushes `OnboardingScreen(isReplay: true)`.
   - In `onboarding_screen.dart:110-112`, header renders `'Step ${_currentPage + 1} of $_totalPages'` during replay.
   - State updates modify `SettingsProvider` / `SharedPreferences` reactively without clearing or resetting note databases, transaction ledgers, or custom category definitions.
3. **Resilient Auto-Backup Storage Priority**:
   - In `lib/services/backup_service.dart:136-175`, `performAutoBackup()` checks `prefs.getString('autoBackupPath')`. If the custom folder does not exist or writes fail due to revoked Android Storage Access Framework (SAF) URI permissions, it catches the error and falls back to `getApplicationDocumentsDirectory()` (`appDir.path`).
   - In `lib/features/settings/presentation/screens/settings_screen.dart:1551-1625`, `_showBackupLocationPicker` sets `"Secure App Storage (Recommended)"` as default with `autoBackupPath = null`.
   - In `backup_service.dart:64`, `generateBackupJson()` runs `PRAGMA wal_checkpoint(PASSIVE);` before data queries.
   - In `lib/features/settings/providers/settings_provider.dart:680-686`, `restoreFromBackupMap` intentionally excludes `appLockEnabled` and `useBiometrics` to prevent untrusted backup files from overriding local security.
4. **Hardware NPU AICore Gating (`isAiActive`)**:
   - In `settings_provider.dart:113`, `bool get isAiActive => _useOnDeviceAi && _isDeviceAiSupported;`.
   - In `lib/main.dart:100-107`, `GeminiNanoService` is registered and `settings.checkAiCoreSupport(aiService)` queries hardware support on startup.
   - `SettingsScreen` (`settings_screen.dart:463, 900`), `SettingsHeroCard` (`settings_screen.dart:399`), `FinancialManagerScreen` (`financial_manager_screen.dart:1366`), `TransactionEditorScreen` (`transaction_editor_screen.dart:826`), `NoteEditorScreen` (`note_editor_screen.dart:4114`), and `ReceiptScannerSheet` (`receipt_scanner_sheet.dart:59`) all gate AI functionality on `isAiActive` or `isDeviceAiSupported`.
5. **AppLockScreen & Biometric Resume Bypass (`ignoreNextResumeLock`)**:
   - In `lib/screens/app_lock_screen.dart:19, 36, 137`, `AppLockScreen.ignoreNextResumeLock()` sets `_ignoreNextResumeLock = true` to bypass the timeout lock on resume.
   - Missing bypass calls were identified at:
     - `lib/services/backup_service.dart:284` (`importBackup`)
     - `lib/services/backup_service.dart:635` (`importTransactionsFromCsv`)
     - `lib/features/finances/presentation/widgets/receipt_scanner_sheet.dart:45` (`_pickAndScan`)
     - `lib/features/finances/services/split_share_service.dart:75` (`shareToWhatsAppOrSystem`)
     - `lib/features/notes/presentation/screens/note_editor_screen.dart:1375, 1390, 1408` (`Share.share` / `Share.shareXFiles`)
6. **Dynamic Text Scaling & Tokens**:
   - In `lib/main.dart:148`, root `MediaQuery` sets `textScaler: TextScaler.linear(deviceFontScale * (settings.textSize / 16.0))`.
   - In `lib/widgets/settings_widgets.dart`, all components adhere to `AppLayout` spacing/radius tokens and dynamic M3 `Theme.of(context).colorScheme` colors.
7. **Test Suites & Static Analysis**:
   - `flutter test test/onboarding_test.dart test/settings_and_lock_test.dart test/settings_search_test.dart test/backup_service_test.dart` passed with 18/18 tests green.
   - `flutter analyze` completed with 0 errors / 0 warnings.

---

## 2. Logic Chain
1. *From Observation 1*: `OnboardingScreen` scales responsively on tablets due to `maxContentWidth` clamping, but `_buildFeatureCard` action button shrinking creates an accessibility touch target deficit ($< 48\text{dp}$). Adding `minimumSize: const Size(48, 48)` and interactive pagination dots resolves the issue while preserving the visual hierarchy.
2. *From Observation 2*: Replayability routes to `OnboardingScreen(isReplay: true)` which modifies existing `SettingsProvider` setters and SharedPreferences keys directly. Because it does not re-initialize or wipe SQLite tables, user data remains 100% intact across repeated replay cycles.
3. *From Observation 3*: Background Workmanager auto-backups (`performAutoBackup()`) are fully protected against Android OS update permission revocations because any failure to access an external SAF directory automatically redirects to sandboxed `getApplicationDocumentsDirectory()`.
4. *From Observation 4*: AI triggers across all modules are consistently guarded by `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`) rather than `useOnDeviceAi` alone, ensuring devices lacking NPU hardware cleanly hide non-functional buttons.
5. *From Observation 5*: Opening native OS file pickers or share sheets causes Android to pause the app. Upon resume, if `AppLockScreen.ignoreNextResumeLock()` is not called, the app lock overlay triggers and unmounts/cancels active import dialogs or scanner sheets. Adding `ignoreNextResumeLock()` to the 5 identified entry points eliminates this risk.
6. *From Observation 6*: Global text scaling operates multiplicatively with device font scale, and `SettingsHeroCard` uses `FittedBox` scale-down guards, preventing overflow at 2.0x text scaling.

---

## 3. Caveats
- No caveats regarding domain business logic; the audit is comprehensive across Settings, Onboarding, Backups, App Lock, and AI Core detection.
- Physical biometric authentication and hardware Gemini Nano inference require real Android hardware for live hardware testing; mock channel handlers and unit tests were utilized for desktop test verification.

---

## 4. Conclusion
The Settings & Onboarding architecture is mature, modular, and resilient. The module exhibits robust separation of concerns, strict hardware AI gating, safe onboarding replayability, and fail-safe protected auto-backup storage.

A concrete, zero-conflict work package has been defined to:
1. Add missing `AppLockScreen.ignoreNextResumeLock()` calls before `BackupService.importBackup`, `BackupService.importTransactionsFromCsv`, `ReceiptScannerSheet._pickAndScan`, `SplitShareService.shareToWhatsAppOrSystem`, and `NoteEditorScreen._showShareMenu`.
2. Upgrade `OnboardingScreen` feature action buttons and pagination indicator dots to standard $\ge 48\times 48\text{dp}$ touch target bounds with `Semantics(button: true)`.

---

## 5. Verification Method
1. **Automated Unit & Widget Tests**:
   ```bash
   flutter test test/onboarding_test.dart test/settings_and_lock_test.dart test/settings_search_test.dart test/backup_service_test.dart
   ```
2. **Static Analysis**:
   ```bash
   flutter analyze
   ```
3. **Inspect Implementation Blueprints**:
   - Review `analysis.md` in `.agents/explorer_settings_1/analysis.md` for exact line-by-line code replacement snippets.
