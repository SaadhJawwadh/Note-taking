---
name: release-management
description: Handles the end-to-end release process, ensuring local builds are tested and verified by the user before pushing tags to trigger CI/CD releases. Use this whenever preparing for a public version update.
---

# Release Management

## Purpose
Release Management ensures that any code being pushed to production is functional, stable, and verified. It prevents "broken releases" by mandating a local build and test cycle before public tags are created.

## Core Mandates
1. **Consent-First Releases**: NEVER push a git tag (`v*`) or trigger a GitHub Actions workflow without explicit, real-time user consent for that specific event.
2. **Local Build & Test First**: Never create a release tag without first building a local APK and providing it to the user for testing.
3. **Mandatory User Verification**: You must wait for explicit user confirmation that the local APK works as expected before asking for consent to push.
4. **Clean Analysis**: Ensure `flutter analyze` passes with zero errors before any build attempt.

## Release Workflow

### 1. Pre-build Verification
- Run `flutter analyze` to ensure the codebase is clean.
- Update `pubspec.yaml` with the correct version number.

### 2. Generate Local Test APK
- Run `flutter build apk --release`.
- **CRITICAL**: Once the build is complete, notify the user of the APK's absolute path so they can test it.
- *Wait for user feedback.*

### 3. Finalize Release
Only after the user confirms the APK is stable:
- **Seek Consent**: Explicitly ask the user: "The local APK is verified. May I now push the version tag to trigger the GitHub Release workflow?"
- **Git Commit/Tag/Push**: Only proceed if the user provides explicit confirmation.

## Common Troubleshooting
- **Build Errors**: Check ProGuard rules if the app crashes or shows a blank screen in release mode (especially SQLCipher native code).
- **Tag Conflicts**: If a tag already exists, ensure the version is bumped correctly in both `pubspec.yaml` and the git tag command.
