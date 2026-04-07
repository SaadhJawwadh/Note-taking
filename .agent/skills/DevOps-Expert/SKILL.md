# DevOps-Expert

Specialist in Flutter CI/CD, Android release optimization, and Play Store delivery.

## Use this skill when
- Modifying GitHub Actions workflows (`.github/workflows/`).
- Adjusting `android/app/build.gradle.kts` or `android/build.gradle.kts`.
- Configuring ProGuard rules (`proguard-rules.pro`).
- Handling native dependency conflicts (JVM targets, NDK).
- Preparing App Bundles (`.aab`) for Play Store upload.

## Relevant Files
- `.github/workflows/release.yml`
- `android/app/build.gradle.kts`
- `android/gradle.properties`
- `android/app/proguard-rules.pro`

## Instructions
- **JVM Targets**: Always ensure a consistent `jvmTarget = "17"` across all Android subprojects to avoid build failures with modern plugins.
- **Resource Shrinking**: Disable resource shrinking (`isShrinkResources = false`) if the project uses local custom fonts or dynamically loaded assets.
- **ProGuard Integrity**: 
    - Audit `proguard-rules.pro` to ensure it `-keep`s essential native namespaces.
    - **SQLCipher**: Always use `-keep class net.sqlcipher.** { *; }` and keep `net.sqlcipher.database.SQLiteDatabase` to prevent blank screens or crashes in encrypted release builds.
- **Play Store Bundles**: Prefer `flutter build appbundle` for production releases to allow Google Play to serve optimized APKs.
- **Dependency Desugaring**: Use `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` or higher to support modern Java APIs on older Android devices.
- **CI/CD Pipeline**: 
    - **CRITICAL**: Do NOT trigger GitHub workflows or push tags (`v*`) without explicit user consent for each specific release event.
    - The `release.yml` should automate versioning based on git tags (`v*`).
    - Always generate SHA256 checksums for all release artifacts.
    - Automate the creation of GitHub Releases with attached `.aab` and `.apk` files.
- **Clean Builds**: Always run `flutter clean` before a final production build to avoid stale artifact issues.
- **Static Analysis Gate**: Run `flutter analyze` before every release build. Zero errors/warnings is a hard requirement. CI/CD will fail on any lint issue.
- **Version Bump Convention (this project)**:
  - Minor version (new features or critical fixes): `1.X.0+Y` where `Y = X * 100 * 100` — e.g. `1.20.0+12000`
  - Patch version (small fixes): `1.X.Y+Z` — e.g. `1.19.6+11906`
  - Always bump both `pubspec.yaml` AND the git tag consistently.
- **Database Self-Healing in Release Builds**: If SQLCipher throws Code 26 (`file is not a database`) in production, the DB file may be corrupted from a prior crash. Ensure `_initDB` wraps `openDatabase` in a try/catch that deletes the corrupt file and its WAL/SHM siblings and retries once. This prevents a corrupted device from being permanently stuck.

