---
name: Tester
description: A comprehensive testing skill that covers UI/UX consistency, codebase QA, security auditing, and verification of settings and backups.
---

# Tester Skill

Use this skill to execute QA verifications, unit/widget tests, security audits, and layout validations.

## 1. UI/UX & Layout Verification
* **Material Design 3**: Verify components follow dynamic Material You themes, container colors (`surfaceContainerLow` for cards, `surfaceContainerHigh` for dialogs), and shape specifications.
* **Haptics and Snappiness**: Check that micro-animations (e.g. `OpenContainer` transitions) run smoothly and buttons provide tactile feedback.
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

## 3. Data Integrity & Backups Audit
* **Backup Completeness**: Ensure `BackupService.generateBackupJson` uses `SettingsProvider.toBackupMap()` to export settings. Never hardcode individual SharedPreferences keys, which go stale as new options are added.
* **Restore Operations**: Ensure `SettingsProvider.restoreFromBackupMap` calls **setter methods** (e.g., `await setShowFinancialManager(value)`) instead of assigning directly to private fields. Direct assignments skip saving to SharedPreferences, causing settings to revert on app restart.
* **Database Upgrades**: Verify `onUpgrade` database migrations (especially schema/junction table changes) preserve existing user data.

## 4. Security Auditing
* **SQLCipher**: Confirm that database connections are always opened securely with the key from KeyStore.
* **App Lock Screen**: Verify that background state detection locks the app after the idle timeout.
* **Picker Lock Bypasses**: Verify that screens using platform file/image pickers implement `AppLockScreen.ignoreNextResumeLock()` so that returning from the OS picker dialog does not trigger the app lock and unmount the screen state.
