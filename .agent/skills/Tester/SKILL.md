---
name: Tester
description: A comprehensive testing skill that covers UI/UX consistency, codebase QA, security auditing, and DevOps release readiness.
---

# Tester Skill

When instructed to use the Tester skill, you must execute the following roles and steps sequentially to ensure the highest quality before a release.

## Phase 1: UI/UX Developer
- Test all usability, user experience, accessibility, and UI component aspects.
- Ensure the project strictly follows **Material Tree Expressive Design** by Google.
- Verify multi-view layouts (e.g. Kanban, Masonry Grid, List) persist correctly and perform smoothly.
- Test complex interactive widgets like `Dismissible` swipe actions (Archive/Trash) and ensure Undo functions correctly.
- Test drag-and-drop states (e.g. Kanban drag to new columns) for both visual state and Database persistence.
- Verify that all components across each page follow a consistent structure and provide a unified UI experience.

## Phase 2: QA Tester
- Go through the entire codebase systematically, regardless of which files were edited most recently.
- Test all existing files for any potential issues, bugs, logical flaws, or unhandled states.
- If any issues are found, trigger a fix for them before proceeding to the next steps.

## Phase 3: Software Security Tester
- Thoroughly check the system for vulnerabilities.
- Audit the code for potential security or privacy issues (e.g., encryption flaws, exposed keys, unsafe data storage).

## Phase 4: CI/CD Pipeline DevOps
- **Android Release Consistency**: Ensure strict **JVM 17** targets are enforced across all subprojects to prevent `Inconsistent JVM Target` errors.
- **Resource Management**: Verify `isShrinkResources = false` in `build.gradle.kts` if the app relies on dynamically referenced assets like `Rubik` fonts.
- **ProGuard Integrity**: Audit `proguard-rules.pro` to ensure it `-keep`s essential native namespaces (e.g., `com.shounakmulay.telephony`, `net.sqlcipher`).
- **Play Store Readiness**: Ensure the `release.yml` workflow builds both the Universal APK and the Play Store App Bundle (`.aab`).
- **Database Migrations**: Rigorously test `onUpgrade` logic (e.g., v12 to v13 junction table migration) to ensure zero data loss for existing users.
- **Dependency Audit**: Verify all core dependencies (like `Workmanager` 0.9.0) use their latest stable and compatible APIs.

## Phase 5: Release Confirmation
- **CRITICAL:** After all the above phases are successfully completed, you must **WAIT FOR USER CONFIRMATION** before triggering any public release or deployment pipeline. Do not release the application without explicit user approval.
