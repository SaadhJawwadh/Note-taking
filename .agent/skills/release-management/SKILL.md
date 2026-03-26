---
name: release-management
description: Handles the end-to-end release process, ensuring local builds are tested and verified by the user before pushing tags to trigger CI/CD releases. Use this whenever preparing for a public version update.
---

# Release Management

## Purpose
Release Management ensures that any code being pushed to production is functional, stable, and verified. It prevents "broken releases" by mandating a local build and test cycle before public tags are created.

## Core Mandates
1. **Local Build & Test First**: Never create a release tag (`v*`) without first building a local APK and providing it to the user for testing.
2. **Mandatory User Verification**: You must wait for explicit user confirmation that the local APK works as expected before proceeding to tag and push.
3. **Clean Analysis**: Ensure `flutter analyze` passes with zero errors before any build attempt.

## Release Workflow

### 1. Pre-build Verification
- Run `flutter analyze` to ensure the codebase is clean.
- Update `pubspec.yaml` with the correct version number (e.g., `1.19.4+11904`).

### 2. Generate Local Test APK
- Run `flutter build apk --release`.
- **CRITICAL**: Once the build is complete, notify the user of the APK's absolute path (e.g., `build/app/outputs/flutter-apk/app-release.apk`) so they can install and test it locally.
- *Wait for user feedback.*

### 3. Finalize Release
Only after the user confirms the APK is stable:
- **Git Commit**: Commit all changes with a clear description of the release contents.
- **Git Tag**: Create the new version tag (e.g., `git tag v1.19.4`).
- **Push**: Push the commit and the tag to `main` (e.g., `git push origin main && git push origin v1.19.4`) to trigger the CI/CD pipeline (GitHub Actions).

## Common Troubleshooting
- **Build Errors**: Check ProGuard rules if the app crashes or shows a blank screen in release mode (especially SQLCipher native code).
- **Tag Conflicts**: If a tag already exists, ensure the version is bumped correctly in both `pubspec.yaml` and the git tag command.
