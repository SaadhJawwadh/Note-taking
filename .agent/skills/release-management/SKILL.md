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
5. **Mandatory Play Store Listing Update**: ALWAYS update `PLAY_STORE_NOTES.md` with bilingual release notes (`<en-US>` and `<ta-IN>`) under 450 characters BEFORE running `./deploy.sh` or tagging a release.

---

## Release Workflow

### Step 1: Quality Gate, Documentation & Play Store Listing Sync
Before bumping the version or running deployment, ensure all of the following are done:
* `flutter analyze` → **zero errors/warnings**. CI/CD will fail on any lint issues.
* `flutter test` → **all tests passing**. Running the full test suite locally is mandatory to catch regressions.
* `CHANGELOG.md` entry is documented under `## X.Y.Z - YYYY-MM-DD` (without brackets around the version number). Write for everyday general users—**avoid technical developer jargon** (no "SQLCipher", "WorkManager", "ChangeNotifier", "Delta JSON", "BackdropFilter"). Group all entries into 3 explicit categories using expressive emojis:
  * 🌟 **What's New** (New user-facing features)
  * 🚀 **Improvements** (UI polish, performance, usability enhancements)
  * 🐛 **Fixes** (Bug fixes and stability improvements)
* **Changelog Screen (MANDATORY for every release)**: Update `lib/screens/changelog_screen.dart` by adding a new `_buildVersionSection(context, version: 'vX.Y.Z', date: '...', isLatest: true, changes: [...])` entry at the top of the list.
* **What's New Sheet (MANDATORY — must match pubspec version)**: Update `lib/widgets/whats_new_sheet.dart` cards for THIS release's features (3–5 cards max). The version string passed to `WhatsNewSheet(currentVersion: ...)` in `home_screen.dart` must match the version in `pubspec.yaml` exactly, otherwise the sheet will not show on first launch of the new version. Verify by grepping `WhatsNewSheet` in `home_screen.dart` and confirming the version string is updated. Both `changelog_screen.dart` and `whats_new_sheet.dart` must ALWAYS be updated together as a single atomic step.
* **Play Console Listing Notes (`PLAY_STORE_NOTES.md`) (MANDATORY BEFORE DEPLOYMENT)**:
  * Update `PLAY_STORE_NOTES.md` at project root with current bilingual release notes in English (`<en-US>`) and Tamil (`<ta-IN>`).
  * Target everyday users with friendly emojis.
  * **500 Character Maximum Limit**: Keep total character count under **450 characters** per language block to prevent Google Play API publication failures.
* **Codebase Knowledge Graph (`map.md`)**: Ensure [.agent/map.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/map.md) is updated with any new files or feature architecture.
* **Cumulative Patch & Minor Release Notes Policy**: For all sub-versions and patch releases (e.g., `2.17.1`, `2.17.2`), release notes in `PLAY_STORE_NOTES.md`, `lib/widgets/whats_new_sheet.dart`, `lib/screens/changelog_screen.dart`, and `CHANGELOG.md` MUST include the cumulative set of user-facing changes since the base major/minor release (`2.17.0`) so users updating directly from older versions see all new features, UI improvements, and stability fixes added across the release series.
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

**Release-mode emulator smoke test is mandatory, not optional.** Install the release APK on the emulator and cold-start it. Verify: first frame renders, the What's New sheet fires with the right version, and each module tab opens.

### Step 3: Run Release Automation
Execute the automated deploy script to bump, tag, and publish:
```bash
flutter analyze && ./deploy.sh <version>
```

```xml
<en-US>
🌟 What's New
• Smart search and new folder organizing options.

🚀 Improvements
• Faster page loading and refreshed Material 3 styling.

🐛 Fixes
• Fixed minor checklist and notification bugs.
</en-US>
<ta-IN>
🌟 புதிய அம்சங்கள்
• ஸ்மார்ட் தேடல் மற்றும் புதிய கோப்பு அமைப்புகள்.

🚀 மேம்பாடுகள்
• வேகமான செயல்பாடு மற்றும் புதிய வடிவமைப்பு.

🐛 பிழை திருத்தங்கள்
• விழிப்பூட்டல் மற்றும் சரிபார்ப்பு பட்டியல் பிழைகள் சரி செய்யப்பட்டன.
</ta-IN>
```
`./deploy.sh` and GitHub Actions will read `PLAY_STORE_NOTES.md` to automatically publish multilingual WhatsNew notes directly to Google Play Console.

---

## Gradle & Build Configuration Guidelines

* **JVM Targets**: Always ensure a consistent `jvmTarget = "17"` across all Android subprojects in `build.gradle.kts` to prevent compiler mismatch failures.
* **R8 Code & Resource Shrinking**: Release builds use `isMinifyEnabled = true` and `isShrinkResources = true`. When adding any new third-party Flutter plugin that uses native Android code, reflection, or native channels:
  1. Add a corresponding `-keep class <package_name>.** { *; }` rule to `android/app/proguard-rules.pro`.
  2. Always build a local release APK (`flutter build apk --release`) to verify R8 compiles without class-stripping errors.
* **ProGuard Core Rules**: Ensure core drivers (SQLCipher, sqflite, Pigeon, WorkManager, LocalAuth) are protected in `android/app/proguard-rules.pro`:
  ```proguard
  -keep class net.sqlcipher.** { *; }
  -keep class net.sqlcipher.database.SQLiteDatabase { *; }
  -keep class com.tekartik.sqflite.** { *; }
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
