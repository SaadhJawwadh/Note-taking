---
name: release-management
description: Handles the end-to-end release process, ensuring local builds are tested and verified by the user before pushing tags to trigger CI/CD releases. Use this whenever preparing for a public version update.
---

# Release Management & DevOps

## Purpose
Ensures that any code being pushed to production is functional, stable, and verified. It prevents "broken releases" by mandating a local build and test cycle before public tags are created.

## Core Mandates
1. **Absolute Permission Rule**: NEVER perform a `git commit`, `git tag`, or `git push` without explicit, real-time user consent for that specific action.
2. **Consent-First Releases**: NEVER trigger a GitHub Actions workflow or push a release tag without permission.
3. **Local Build & Test First**: Always build a local APK and provide it to the user for testing before asking for permission to commit or release.
4. **Mandatory User Verification**: Wait for explicit user confirmation that the local APK works as expected before final commit and push.

---

## Release Workflow

### Step 1: Quality Gate & Version Bump
Before bumping the version, ensure all of the following are done:
* `flutter analyze` → **zero errors/warnings**. CI/CD will fail on any lint issues.
* `flutter test` → **all tests passing**. Running the full test suite locally is mandatory to catch regressions.
* `CHANGELOG.md` entry is documented under `## X.Y.Z - YYYY-MM-DD` (without brackets around the version number). This ensures the automated deploy script's exact match string check (`grep -q "## $NEW_VERSION"`) passes successfully, while regex-based release notes extractors still capture the version segment.
* **What's New sheet (MANDATORY for every release)**: Update the feature cards in `lib/widgets/whats_new_sheet.dart` to describe THIS release's user-facing features in friendly, benefit-first language (5-7 cards max, lead with the biggest features). The sheet auto-fires once per version — it's gated on `SettingsProvider.lastSeenVersion` vs `PackageInfo` version in `home_screen._maybeShowWhatsNew` — so stale content from a previous release WILL be shown to every updating user. Never ship a release without refreshing it.
* Version number in `pubspec.yaml` is bumped using the project convention:
  * **Minor bump** (new features): `1.X.0+Y` where `Y = X * 10000` (e.g. `1.34.0+13400`)
  * **Patch bump** (bug fixes): `1.X.Y+Z` (e.g. `1.33.1+13301`)
  * Keep `minor` and `patch` numbers strictly under `100` to prevent version code overlaps.

### Step 2: Build Local Release APK & On-Device Smoke Test
Verify the release build succeeds locally:
```bash
flutter build apk --release
```
Provide the APK path (`build/app/outputs/flutter-apk/app-release.apk`) to the user for verification.

**Release-mode emulator smoke test is mandatory, not optional.** Install the release APK on the emulator and cold-start it: debug builds hide release-only startup races (a WorkManager background isolate opening the SQLCipher DB during app launch once deadlocked the app on the splash screen in release mode only). Verify: first frame renders, the What's New sheet fires with the right version, and each module tab opens. Diagnose stuck launches with `adb logcat -s flutter` and `adb shell dumpsys window | grep mCurrentFocus`; note that a `MissingPluginException` for activity-registered channels coming from the WorkManager isolate is expected and benign.

### Step 3: Run Release Automation
Execute the automated deploy script to bump, tag, and publish:
```bash
./deploy.sh <version>
```
* **Release Notes Extraction**: The script automatically extracts the version's notes from `CHANGELOG.md` into `RELEASE_NOTES.md` and commits it, which GitHub Actions parses to create the release body.

---

## Gradle & Build Configuration Guidelines

* **JVM Targets**: Always ensure a consistent `jvmTarget = "17"` across all Android subprojects in `build.gradle.kts` to prevent compiler mismatch failures.
* **Resource Shrinking**: Set `isShrinkResources = false` if the project uses dynamically loaded local assets (like icon packages or custom fonts) to prevent asset stripping.
* **ProGuard SQLCipher Rule**: Ensure SQLCipher is protected from shrinking in `android/app/proguard-rules.pro`:
  ```proguard
  -keep class net.sqlcipher.** { *; }
  -keep class net.sqlcipher.database.SQLiteDatabase { *; }
  ```
* **Flutter Icon Tree-Shaking Rule**:
  * **Zero Non-Constant `IconData` Calls**: Never instantiate `IconData(codePoint, ...)` using dynamic or runtime variables anywhere in Dart code. Flutter's release AOT compiler statically inspects `IconData` invocations to tree-shake font files and will abort the build with `Error: Avoid non-constant invocations of IconData`.
  * **Static Lookup Map Pattern**: Always resolve dynamic icon code points via a `const Map<int, IconData>` lookup table mapping code points to `const` icon constants (e.g. `Icons.directions_car_outlined`). Fall back to a `const` icon (e.g. `Icons.category_outlined`).
  * **CI/CD Flag Guardrail**: In GitHub Actions release workflows (`.github/workflows/release.yml`), always include `--no-tree-shake-icons` for both `flutter build apk --release --no-tree-shake-icons` and `flutter build appbundle --release --no-tree-shake-icons` as an extra fail-safe.
* **`deploy.sh` Pathspec Exclusion**: When checking git cleanliness before release, exclude version bump files (`pubspec.yaml` and `CHANGELOG.md`) using pathspecs (`git diff-index --quiet HEAD -- . ':!pubspec.yaml' ':!CHANGELOG.md'`).
* **Replacing Existing Tags**: If a tag needs to be updated or replaced on a new commit:
  ```bash
  git tag -d vX.Y.Z
  git push origin :refs/tags/vX.Y.Z
  git tag vX.Y.Z
  git push origin vX.Y.Z
  ```

---

## Play Store Listing Assets & Mockup Generation

### 1. App Icon & Feature Graphic Specifications
Google Play Console enforces strict dimensions for marketing assets. Use `sips` on macOS to resize/crop generated assets:
* **App Icon (512x512 PNG)**:
  ```bash
  sips -z 512 512 <source_icon.png> --out <dest_icon_512.png>
  ```
* **Feature Graphic (1024x500 PNG)**: Generate a 1024x1024 background asset first, then center-crop it to the correct aspect ratio:
  ```bash
  sips -c 500 1024 <source_graphic.png> --out <dest_graphic_1024x500.png>
  ```

### 2. Creating Mockups with Real Emulator Screenshots
To showcase real app workflows in mockups instead of placeholders:
1. Launch the app on the connected emulator:
   ```bash
   adb shell am start -n <package>/<main_activity>
   ```
2. Switch tabs or trigger actions by tapping exact coordinates (e.g., `x=540, y=2300` for bottom navigation bar):
   ```bash
   adb shell input tap <x> <y>
   ```
3. Capture screen contents directly to files:
   ```bash
   adb exec-out screencap -p > <output_path.png>
   ```
4. Pass the captured file path to `ImagePaths` in the `generate_image` tool, prompting it to overlay the screenshot inside a bezel-less smartphone frame on a custom gradient background.

### 3. Android Monochrome Launcher Override Gotcha
If regenerating adaptive icons using tools like `flutter_launcher_icons`, check for any pre-existing monochrome vector resource at `android/app/src/main/res/drawable/ic_launcher_monochrome.xml`. Delete this stale XML to allow the system launcher to fallback correctly to the newly generated transparent PNG layers.
