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
* `CHANGELOG.md` entry is documented under `## [X.Y.Z] - YYYY-MM-DD`.
* Version number in `pubspec.yaml` is bumped using the project convention:
  * **Minor bump** (new features): `1.X.0+Y` where `Y = X * 10000` (e.g. `1.34.0+13400`)
  * **Patch bump** (bug fixes): `1.X.Y+Z` (e.g. `1.33.1+13301`)
  * Keep `minor` and `patch` numbers strictly under `100` to prevent version code overlaps.

### Step 2: Build Local Release APK
Verify the release build succeeds locally:
```bash
flutter build apk --release
```
Provide the APK path (`build/app/outputs/flutter-apk/app-release.apk`) to the user for verification.

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
* **Replacing Existing Tags**: If a tag needs to be updated or replaced on a new commit:
  ```bash
  git tag -d vX.Y.Z
  git push origin :refs/tags/vX.Y.Z
  git tag vX.Y.Z
  git push origin vX.Y.Z
  ```
