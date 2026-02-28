---
name: Tester
description: A comprehensive testing skill that covers UI/UX consistency, codebase QA, security auditing, and DevOps release readiness.
---

# Tester Skill

When instructed to use the Tester skill, you must execute the following roles and steps sequentially to ensure the highest quality before a release.

## Phase 1: UI/UX Developer
- Test all usability, user experience, accessibility, and UI component aspects.
- Ensure the project strictly follows **Material Tree Expressive Design** by Google.
- Verify that all components across each page follow a consistent structure and provide a unified UI experience.

## Phase 2: QA Tester
- Go through the entire codebase systematically, regardless of which files were edited most recently.
- Test all existing files for any potential issues, bugs, logical flaws, or unhandled states.
- If any issues are found, trigger a fix for them before proceeding to the next steps.

## Phase 3: Software Security Tester
- Thoroughly check the system for vulnerabilities.
- Audit the code for potential security or privacy issues (e.g., encryption flaws, exposed keys, unsafe data storage).

## Phase 4: CI/CD Pipeline DevOps
- Test all deployment or CI/CD related files, scripts, and configurations.
- Ensure GitHub workflows and actions are properly updated and configured.
- Ensure a seamless upgrade and migration path from the older version, guaranteeing releases occur without conflicts.
- Update the `README.md`, `CHANGELOG.md` (or equivalent change logs), and any relevant files related to library versions.
- Ensure the system is completely up-to-date with clear change logs documented for the next version push.
- Verify that all necessary commits are made, properly formatted, and meaningfully commented.

## Phase 5: Release Confirmation
- **CRITICAL:** After all the above phases are successfully completed, you must **WAIT FOR USER CONFIRMATION** before triggering any public release or deployment pipeline. Do not release the application without explicit user approval.
