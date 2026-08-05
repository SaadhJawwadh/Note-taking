# Master Rules & Developer Guidelines for Note Book

All AI coding assistants (including Cursor, Antigravity, Copilot, and LLM agents) working on this repository must strictly adhere to the following master rules:

---

## 🚀 Rule 1: Consult Developer Map First (Token Savings)
Before executing search queries, reading random files, or modifying code, the agent **MUST** first inspect the Developer Map:
*   [map.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/map.md) / [.agent/map.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/map.md).

**Process**:
1. Read the Developer Map to identify exact files, providers, and database schemas responsible for the requested feature or fix.
2. Target strictly the necessary set of files. Avoid broad workspace grep searches or scanning unrelated directories.

---

## 🎨 Rule 2: Single Source of Truth Theme & Core UI Primitives
Never hardcode layout margins, padding, border radii, animation curves, or colors directly inside screen widgets.

**Process**:
1. **Design Tokens**: Reference tokens from `AppLayout` and `AppTheme` (`lib/core/theme/`).
2. **Shared UI Primitives**: Use standardized UI components from `lib/core/ui/`:
   - `AppCard`: Standardized card container with single-source-of-truth surface fills.
   - `AppBottomSheet`: Standardized drag-handled modal sheet with responsive width limits.
   - `AppChip`: Standardized chip/pill widget for tags, categories, phase badges, and filters.
   - `AppDialog`: Standardized responsive confirmation and input dialogs.
   - `FrostedGlassSliverAppBar`: Standardized glassmorphic top header.
3. **Typography**: Pair `Google Sans Flex` / `Inter` for UI text with **`Inter`** tabular figures (`fontFeatures: [FontFeature.tabularFigures()]`) for financial ledgers and data numbers.
4. **Touch & Motion**: Wrap tactile buttons using `bouncing_widget.dart` or expressive pressables (`scaleFactor: 0.96`, `150ms`, `Curves.easeOutBack`).

---

## 📁 Rule 3: Feature-Driven Domain Architecture
New features and domain logic MUST follow the feature-driven architecture under `lib/features/`:
*   `lib/features/notes/`: Note model, `NoteRepository`, `NoteEditorProvider`, and editor/list screens.
*   `lib/features/finances/`: Transaction model, `TransactionRepository`, `FinancialManagerProvider`, and financial screens.
*   `lib/features/health/`: Period log model, `PeriodRepository`, `PeriodTrackerProvider`, and cycle prediction screens.
*   `lib/features/settings/`: `SettingsProvider`, backup services, app lock, and settings screens.
*   **Decoupled Providers**: Keep business logic, auto-save timers, filtering, and queries inside `ChangeNotifier` providers rather than monolithic widget `State` classes.

---

## 📱 Rule 4: Mandatory Static Analysis & Verification
After implementing any feature or fix, the agent **MUST** verify code correctness.

**Process**:
1. Run `flutter analyze` to ensure **0 static analysis errors and warnings**.
2. Run `flutter test` to ensure all unit and widget tests pass cleanly.
3. Verify runtime execution via hot reload/hot restart on running devices/emulators.

---

## 🛡️ Rule 5: R8 ProGuard Rules for Native Dependencies
When adding native Android plugins to `pubspec.yaml`, the agent **MUST** ensure R8 release builds will not strip required native classes or reflection entry points.

**Process**:
1. Inspect `android/app/proguard-rules.pro` and add explicit `-keep class <package_name>.** { *; }` rules for new native plugins.
2. Verify release build compilation via `flutter build apk --release` when requested.

---

## 🔒 Rule 6: Security & User Consent
* **Local Data First**: Data and encrypted backups remain local. Exclude sensitive biometric/auth settings from backup restoration.
* **No Unprompted Commits/Pushes**: Always obtain explicit user permission before executing `git commit` or `git push`.

---

## 🏷️ Rule 7: Mandatory Play Store Listing & Release Notes Sync
Before running deployment scripts (`./deploy.sh`) or tagging a release:
1. **`PLAY_STORE_NOTES.md` (Mandatory)**: Always write updated, bilingual release notes (`<en-US>` and `<ta-IN>`) under 450 characters per section to `PLAY_STORE_NOTES.md` BEFORE triggering `./deploy.sh`.
2. **App Changelog Parity**: Ensure `CHANGELOG.md`, `lib/screens/changelog_screen.dart`, `lib/widgets/whats_new_sheet.dart`, and `PLAY_STORE_NOTES.md` all feature identical, user-friendly benefit highlights for the new version.
