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
*   **Root Provider Registration Invariant**: Always register domain `ChangeNotifierProvider`s (`FinancialManagerProvider`, `NoteProvider`, `P2pSyncProvider`) in `main.dart`'s root `MultiProvider` list so state is globally accessible across screens, push routes, and modal bottom sheets.

---

## 📱 Rule 4: Mandatory Static Analysis & Verification
After implementing any feature or fix, the agent **MUST** verify code correctness.

**Process**:
1. Run `flutter analyze` to ensure **0 static analysis errors and warnings**.
2. Run `flutter test` to ensure all unit and widget tests pass cleanly.
3. Verify runtime execution via hot reload/hot restart on running devices/emulators.

---

## 🛡️ Rule 5: R8 Full Mode & Bitmap Downsampling Standards
1. **R8 Full Mode & ProGuard Hygiene**:
   - `android/gradle.properties` enforces `android.enableR8.fullMode=true` for maximum dead code elimination, constant folding, and method inlining.
   - When adding native Android plugins, inspect `android/app/proguard-rules.pro` and add explicit `-keep class <package_name>.** { *; }` rules. Avoid blanket wildcards like `-keep class io.flutter.** { *; }` that disable R8 optimization passes.
2. **Bitmap Memory Downsampling**:
   - Never decode raw high-resolution images ($12\text{–}48\text{MP}$) into memory without downsampling bounds.
   - All `Image.file`, `Image.network`, and `Image.asset` preview widgets MUST supply `cacheWidth` (e.g. `cacheWidth: 1080` for note body embeds, `cacheWidth: 400` for cards) and implement `errorBuilder` fallbacks.
   - Global image cache limits in `main.dart` must maintain `imageCache.maximumSizeBytes = 100 * 1024 * 1024` (100MB) to protect against OOM memory pressure.

---

## 🔒 Rule 6: Security & User Consent
* **Local Data First**: Data and encrypted backups remain local. Exclude sensitive biometric/auth settings from backup restoration.
* **No Unprompted Commits/Pushes**: Always obtain explicit user permission before executing `git commit` or `git push`.

---

## 🏷️ Rule 7: Major vs. Minor Release Protocols & Documentation Parity
Before running deployment scripts (`./deploy.sh`) or tagging a release:
1. **🌟 Major Releases (`X.0.0`)**:
   - Comprehensive review of `OnboardingScreen` slides. If foundational paradigms changed, bump onboarding key (e.g. `hasSeenOnboarding_v2`) to re-introduce the experience to all users.
   - Highlight headline pillar capabilities in `PLAY_STORE_NOTES.md` and `WhatsNewSheet`.
2. **🚀 Minor & Patch Releases (`X.Y.Z`)**:
   - **Onboarding Continuity**: Existing users are never re-prompted through onboarding (`hasSeenOnboarding_v1` remains `true`).
   - **Cumulative Marquee Notes**: `PLAY_STORE_NOTES.md` and `lib/widgets/whats_new_sheet.dart` MUST aggregate and present the **cumulative headline features from the current minor cycle (`X.Y.x`)**, updating on top of them with the latest patch optimizations/fixes.
3. **`PLAY_STORE_NOTES.md` (Mandatory)**: Always write updated, bilingual release notes (`<en-US>` and `<ta-IN>`) under 450 characters per section to `PLAY_STORE_NOTES.md` BEFORE triggering `./deploy.sh`.
4. **App Changelog Parity**: Ensure `CHANGELOG.md` and `lib/screens/changelog_screen.dart` maintain granular, chronological version sections.

---

## 🎨 Rule 8: Navigation & Hero Container Standards
1. **Seamless Borderless Bars**: Top App Bars (`FrostedGlassSliverAppBar`, custom header slivers) and Bottom Navigation Bars MUST be 100% borderless (`border: null`), relying on pure backdrop blur (`sigma 16.0`) and translucent `surfaceContainerLow` fill so content scrolls underneath seamlessly.
2. **Dynamic Light/Dark Hero Container Tint**: Hero cards (`SettingsHeroCard`, Net Balance, P2P Sync Status, Period Tracker Moon Phase, Trash Auto-Purge Banner) must dynamically adjust container opacity (50%–55% alpha in Light Mode; 20%–22% alpha in Dark Mode) to preserve vibrant fills without returning to gradient or dull grey decorations.
3. **SQLCipher Safety**: Always pass `password: ''` (or explicit key) to `openDatabase()` calls when using `sqflite_sqlcipher` to prevent runtime options cast crashes.

---

## 🤖 Rule 9: Hardware-Aware AI Capability Gating (`isAiActive`)
Never gate AI UI controls (refine buttons, sparkle icons, toolbar assist pills) on `useOnDeviceAi` alone.
* Always distinguish between user preference (`useOnDeviceAi`) and physical hardware availability (`isDeviceAiSupported`).
* UI controls MUST query `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`) to prevent displaying non-functional or error-prone AI triggers on emulators and devices lacking on-device Gemini Nano/AICore hardware.

---

## 💳 Rule 10: Currencies, SMS Parsing & PII Regex Invariants
* **Authentic Currency Badges**: Currency selection dialogs and settings tiles MUST render authentic tonal circular avatars displaying the genuine currency symbol (e.g. `Rs.`, `₹`, `$`, `€`, `£`, `¥`, `د.إ`, `﷼`, `C$`, `A$`, `S$`, `RM`, `NZ$`, `CHF`), bold code, and full name instead of generic dollar icons.
* **PII Number Sanitization**: Reference number stripping regexes MUST require digit lookahead assertions (`\b(?=[A-Za-z0-9]*\d)[A-Za-z0-9]{10,}\b`) to avoid truncating legitimate 10+ character English words.
* **SMS Sandbox Whitelisting**: SMS parsing engines must recognize simulated test senders (`'BANK_SMS'`, `'CARD'`, `'ALERTS'`, `'BANK'`) as verified financial senders to support sandbox test execution.

---

## 🔘 Rule 11: Standard FAB Clearance & Universal Morphing Protocol
* **No Obscured Content**: Bottom scrollable content must never be clipped or obscured by floating buttons or bottom navigation chrome. Always apply `AppLayout.fabBottomPadding = 96.0` to sliver lists or bottom padding containers.
* **Universal Morphing FAB**: All floating action buttons must use `AppMorphingFab` (`lib/core/ui/app_morphing_fab.dart`), reacting to `UserScrollNotification` to dynamically collapse into a $56 \times 56\text{dp}$ circular button on downward scroll and expand back to the stadium button on upward scroll.
* **Donut Chart Precision**: Donut chart center hole labels must be explicitly bounded inside a `SizedBox` with `FittedBox(fit: BoxFit.scaleDown)` to prevent text from touching chart rings, and slices must enforce a minimum 1.5% angle floor so micro-slivers remain visible.



