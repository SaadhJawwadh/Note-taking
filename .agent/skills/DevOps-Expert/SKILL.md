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
    - The `release.yml` should automate versioning based on git tags (`v*`).
    - Always generate SHA256 checksums for all release artifacts.
    - Automate the creation of GitHub Releases with attached `.aab` and `.apk` files.
- **Clean Builds**: Always run `flutter clean` before a final production build to avoid stale artifact issues.
