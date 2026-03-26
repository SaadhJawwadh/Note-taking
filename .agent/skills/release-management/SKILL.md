---
name: release-management
description: Handles the end-to-end release process, ensuring local builds are tested and verified by the user before pushing tags to trigger CI/CD releases. Use this whenever preparing for a public version update.
---

# Release Management

## Purpose
Release Management ensures that any code being pushed to production is functional, stable, and verified. It prevents "broken releases" by mandating a local build and test cycle before public tags are created.

## Core Mandates
1. **Absolute Permission Rule**: NEVER perform a `git commit`, `git tag`, or `git push` without explicit, real-time user consent for that specific action.
2. **Consent-First Releases**: NEVER trigger a GitHub Actions workflow or push a release tag without permission.
3. **Local Build & Test First**: Always build a local APK and provide it to the user for testing before asking for permission to commit or release.
4. **Mandatory User Verification**: You must wait for explicit user confirmation that the local APK works as expected before asking for consent to finalize the git lifecycle.

## Release Workflow

### 3. Finalize Release
Only after the user confirms the APK is stable:
- **Seek Permission to Commit**: Ask: "The APK is verified. May I now commit these changes to the repository?"
- **Seek Permission to Push**: Once committed, ask: "May I now push the tag to trigger the GitHub Release workflow?"
- **Execution**: Only proceed with the specific action if the user provides explicit confirmation.

## Common Troubleshooting
- **Build Errors**: Check ProGuard rules if the app crashes or shows a blank screen in release mode (especially SQLCipher native code).
- **Tag Conflicts**: If a tag already exists, ensure the version is bumped correctly in both `pubspec.yaml` and the git tag command.
