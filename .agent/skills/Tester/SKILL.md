---
name: Tester
description: A comprehensive testing skill that covers UI/UX consistency, codebase QA, security auditing, and verification of settings and backups.
---

# Tester Skill

Use this skill to execute QA verifications, unit/widget tests, security audits, and layout validations.

## 1. UI/UX & Material 3 Expressive Verification
* **Design System Reference**: Verify layouts adhere to [design.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/UI-UX-Specialist/design.md) (5-tier surface tokens `surfaceContainerLow` $\rightarrow$ `surfaceContainerHighest`, $48 \times 48\text{ dp}$ tap targets, spring physics).
* **Button Hierarchy Integrity**: Verify primary actions use `FilledButton` / `IconButton.filled`, secondary actions use `FilledButton.tonal` / `OutlinedButton`, dual actions use **Split Buttons**, and FAB groups expand via the **FAB Menu** pattern.
* **M3 Motion & Spring Physics**: Check that micro-animations and container morphs use spring-based physics (`Curves.elasticOut`, `Curves.fastOutSlowIn`) and maintain smooth 120 FPS render performance.
* **Typography & Emphasized Text**: Confirm that headings and editorial titles leverage M3 Emphasized text style slots (`Google Sans Text` weight 600) and numeric ledgers utilize tabular `Inter` font formatting.
* **Overflow Protection**: Verify all dynamically generated text is wrapped appropriately (`Flexible`/`Expanded`) to prevent `RenderFlex overflow` issues.
* **Visual Validation**: Capture screenshots of the mobile emulator (`emulator-5554`) to verify layouts:
  ```bash
  adb exec-out screencap -p > "screenshots/<filename>.png"
  ```

## 2. Codebase QA & Mocking
* **Test Suite execution**: Always run the full local test suite:
  ```bash
  flutter test
  ```
* **Path Provider Mocking**: Unit or widget tests utilizing filesystem paths must mock the path provider channel inside `setUp`:
  ```dart
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async => '.',
  );
  ```
* **Context safety**: Ensure all asynchronous callback gates check `context.mounted` or state `mounted` before executing context operations.
* **Async Provider Constructor Races**: `SettingsProvider` loads `SharedPreferences` asynchronously in its constructor (`loadSettings()`). In unit tests where a new instance is instantiated (`newSettings = SettingsProvider()`), insert `await Future.delayed(const Duration(milliseconds: 100))` before invoking methods like `restoreFromBackupMap` to prevent `loadSettings()` from finishing later and overwriting mock test state.
* **Widget Test Localization Delegates**: Any widget test rendering screens that reference `AppLocalizations.of(context)` (e.g. `SettingsScreen`) must include `localizationsDelegates: AppLocalizations.localizationsDelegates` and `supportedLocales: AppLocalizations.supportedLocales` inside `MaterialApp` in the test widget tree to prevent `null` localization exceptions.

## 3. Data Integrity & Backups Audit
* **Backup Completeness**: Ensure `BackupService.generateBackupJson` uses `SettingsProvider.toBackupMap()` to export settings. Never hardcode individual SharedPreferences keys, which go stale as new options are added.
* **Restore Operations**: Ensure `SettingsProvider.restoreFromBackupMap` calls **setter methods** (e.g., `await setShowFinancialManager(value)`) instead of assigning directly to private fields. Direct assignments skip saving to SharedPreferences, causing settings to revert on app restart.
* **Database Upgrades**: Verify `onUpgrade` database migrations (especially schema/junction table changes) preserve existing user data.

## 4. Security Auditing
* **SQLCipher**: Confirm that database connections are always opened securely with the key from KeyStore.
* **App Lock Screen**: Verify that background state detection locks the app after the idle timeout.
* **Picker & Native Dialog Lock Bypasses**: Verify that screens using platform file/image pickers, share sheets (`SharePlus.instance.share`), or gallery permission dialogs (`Gal.requestAccess`) implement `AppLockScreen.ignoreNextResumeLock()` so that returning from native OS dialogs or sheet interfaces does not trigger the app lock screen and unmount the active widget state.
* **Secure Key Storage**: Never store database encryption keys or backups in unencrypted `SharedPreferences`. Migrate legacy backups to `FlutterSecureStorage` on launch and remove them from plaintext storage immediately to prevent leakage.
* **Android Notifications Resource Resolution**: The `FlutterLocalNotificationsPlugin` looks for initialization icons in the app's `drawable` folder (e.g. `R.drawable.launcher_icon`). If the resource is only defined in `mipmap` directories, it will fail on startup with a `PlatformException(invalid_icon)`. Place a copy of the target icon inside the `drawable` folder to ensure successful native initialization.
* **Tablet & Large Screen Manifest Compatibility**: Ensure `android.hardware.telephony`, `camera`, and `microphone` features in `AndroidManifest.xml` have `android:required="false"` and `<supports-screens>` is configured. Otherwise, Wi-Fi tablets (e.g. Samsung Galaxy Tab S10+) will be automatically excluded from Play Store distribution.

## 5. Release-Mode & On-Device Verification (v2.0 learnings)
* **Debug hides release-only startup races.** A WorkManager task opening the SQLCipher DB in a background isolate during cold start deadlocked the app on the splash — release builds only. ALWAYS install the release APK on the emulator and cold-start it before shipping. Give background tasks an `initialDelay`, and wrap `main()`'s init `Future.wait` in a `.timeout()` so the first frame can never hang.
* **Diagnosing a stuck launch**: `adb logcat -s flutter` (engine + Dart prints), `adb shell dumpsys window | grep mCurrentFocus`, `adb shell pidof <package>`. Two "Impeller" engine lines = a background FlutterEngine (WorkManager) is also running.
* **Background isolate channels**: MethodChannels registered in `MainActivity.configureFlutterEngine` do NOT exist in WorkManager isolates — `MissingPluginException` from there is expected; code must catch it and prefs-only paths must still complete.
* **Drive the UI, don't assume**: a FAB `tooltip` swallowed the long-press that opened the template sheet — only caught by actually long-pressing on the emulator. Screenshot each new surface and LOOK at it.
* **Test-data parity**: `createTestDatabase` pins the CURRENT schema version — bump it together with `_initDB`'s `version:` and add the `onUpgrade` branch, or tests diverge from production schema.
* **Flutter↔Kotlin prefs types**: Dart `prefs.setInt` stores a Long — Kotlin must read `getLong(...)`, not `getInt(...)`, or widget code silently falls back to defaults.

## 6. R8 Optimization & ProGuard Verification
* **Release Build Compilation**: Run `flutter build apk --release` to verify that R8 shrinking completes cleanly without `ClassNotFoundException` or missing symbol warnings.
* **Plugin Stripping Check**: When adding a new Flutter plugin with Android native components, verify that `android/app/proguard-rules.pro` has a corresponding `-keep class` declaration.
* **On-Device ProGuard Audit**: Test key native features (SQLCipher DB decryption, Biometric auth, Share sheet, Camera/Gallery picking, Background WorkManager) on a release build (`app-release.apk`) to verify R8 has not stripped runtime reflection entry points.

## 7. Image Fallbacks & Database Version Alignment
* **Rich Text Image Fallbacks**: Verify `Image.file` and `Image.network` in custom embed builders implement `errorBuilder` to render a clean fallback icon (`broken_image_outlined`) when local image files are deleted from disk or URLs fail to resolve.
* **Database Test Version Alignment**: Verify `DatabaseHelper.createTestDatabase()` pins the exact schema version specified in `_initDB()` (version 17) so test database instances match production database schemas 100%.
