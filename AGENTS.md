# Everything App — Master Agent Kernel & Single Source of Truth

You are Antigravity, the AI pair programmer working on **Everything App** (offline-first note-taking, financial manager, health tracker, and local P2P sync with on-device AI).
This document is the canonical, authoritative Single Source of Truth (SSOT) for all architectural standards, engineering invariants, and developer workflows.

---

## 1. Core Architecture & Tech Stack

* **Framework & Language**: Flutter (>=3.27.0) with Dart (>=3.6.0).
* **State Management**: Reactive state management with `package:provider` (`ChangeNotifier`). Decoupled domain providers registered globally in `main.dart`'s root `MultiProvider`.
* **Local Storage & Security**: Fully local, offline-first SQLCipher encrypted SQLite (`sqflite_sqlcipher` with WAL mode enabled) protected by Android KeyStore / iOS Keychain (`flutter_secure_storage`). AES-256 encrypted JSON backups via `BackupService`.
* **Design System**: Strict Material 3 Expressive theming (`AppTheme` / `AppLayout`) with dynamic Material You wallpaper color extraction (`dynamic_color`), OLED pitch-black dark mode, Google Sans Flex variable typography, and seamless borderless frosted glass chrome.
* **On-Device Intelligence**: Hardware-aware on-device AI (`gemini_nano_android` / AICore) strictly gated by `settings.isAiActive`.
* **Peer-to-Peer Device Sync**: Zero-cloud, bi-directional LWW Wi-Fi sync engine using direct REST HTTP server (Port 8765) and UDP radio beacon (Port 8766).

---

## 2. Directory Structure & Module Map

Consult the detailed [Developer Map (.agent/map.md)](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/map.md) before searching or modifying code:

```
lib/
├── core/                               # Shared design system, UI primitives, and router
│   ├── constants/app_constants.dart    # App metadata, curated currencies (CurrencyInfo)
│   ├── routes/app_router.dart          # Centralized route strings and M3 shared-axis transitions
│   ├── theme/                          # Single Source of Truth Design Tokens
│   │   ├── app_layout.dart             # Spacings (spaceXS–XXL), radii (radiusS–MAX), spring curves
│   │   └── app_theme.dart              # M3 ColorSchemes, 15-role typography, InkSparkle
│   └── ui/                             # Standard Atomic UI Component Library
│       ├── app_card.dart               # Surface container card (standard, tonal, frosted)
│       ├── app_bottom_sheet.dart       # Drag-handled modal sheet with responsive width bounds
│       ├── app_chip.dart               # Standardized tag, category, and phase badge pill
│       ├── app_dialog.dart             # Responsive confirmation and prompt dialogs
│       └── frosted_sliver_app_bar.dart # Seamless borderless glassmorphic header
├── features/                           # Feature-Driven Domain Bundles
│   ├── notes/                          # Lossless Quill Delta notes, tags, auto-purge trash
│   ├── finances/                       # SMS auto-import ledger, categories, recurring rules, AI refine
│   ├── health/                         # Menstrual cycle predictions, ovulation, discreet alerts
│   ├── settings/                       # App preferences, full-screen onboarding wizard, backups, lock
│   └── sync/                           # Master P2P device sync engine, pairing wizard, QR scanner
├── data/                               # Database helpers, models, and migrations
└── services/                           # Background sync, Workmanager isolates, notifications, AI
```

---

## 3. Non-Negotiable System Invariants

### 🎨 Invariant 1: Single Source of Truth Theme & Core UI Primitives
* **No Magic Values**: Never hardcode padding, margins, border radii, motion curves, or static colors inside screen widgets.
* **Tokens**: Reference layout tokens from `AppLayout` and semantic colors from `Theme.of(context).colorScheme` or `AppSemanticColors`.
* **Shared UI Library**: Always use `AppCard`, `AppBottomSheet`, `AppChip`, `AppDialog`, and `FrostedGlassSliverAppBar` from `lib/core/ui/`.
* **Seamless Borderless Bars**: Top app bars (`FrostedGlassSliverAppBar`) and bottom navigation bars MUST be 100% borderless (`border: null`), relying on pure backdrop blur (`sigma 16.0`) and translucent `surfaceContainerLow` fill.
* **Dynamic Hero Card Opacities**: Hero cards (`SettingsHeroCard`, Net Balance, P2P Sync Status, Cycle Moon Phase, Trash Auto-Purge Banner) must dynamically adjust container opacity (50%–55% alpha in Light Mode; 20%–22% alpha in Dark Mode) with subtle 1.2px accent borders.

### 🏗️ Invariant 2: Feature-Driven Domain Architecture & Root Provider Registration
* **Domain Modularization**: Place domain models, repositories, providers, and presentation screens inside `lib/features/<module>/`.
* **Decoupled Providers**: Encapsulate queries, calculations, and auto-save timers in `ChangeNotifier` providers.
* **Root Provider Registration**: Always register domain providers (`FinancialManagerProvider`, `NoteProvider`, `P2pSyncProvider`, `SettingsProvider`) in `main.dart`'s root `MultiProvider` list so state is globally accessible across routes and modal sheets.
* **No Stubs / Direct Imports**: Import screens and repositories directly from feature directories. Do NOT create 1-line re-export stub files.

### 🤖 Invariant 3: Hardware-Aware AI Capability Gating (`isAiActive`)
* Never gate AI UI triggers on `useOnDeviceAi` alone.
* AI sparkle icons, toolbar assist buttons, and refine menu actions MUST query `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`) so emulators and devices lacking on-device Gemini Nano/AICore hardware cleanly hide non-functional controls.

### 💳 Invariant 4: Authentic Currencies, SMS Deduplication & PII Safety
* **Authentic Symbol Badges**: Render authentic tonal circular avatars displaying the genuine currency symbol (e.g. `Rs.`, `₹`, `$`, `€`, `£`, `¥`, `د.إ`, `﷼`, `C$`, `A$`, `S$`, `RM`, `NZ$`, `CHF`), bold code, and full name instead of generic dollar icons.
* **PII Lookahead Assertions**: Reference number stripping regexes MUST require digit lookaheads (`\b(?=[A-Za-z0-9]*\d)[A-Za-z0-9]{10,}\b`) to avoid truncating legitimate 10+ character English words.
* **SMS Sandbox Whitelisting**: SMS parsing engines must recognize simulated test senders (`'BANK_SMS'`, `'CARD'`, `'ALERTS'`, `'BANK'`) as verified financial senders.
* **Tombstone Table Retention**: Permanently purged transactions persist their `smsId` to `deleted_transaction_sms_ids` to permanently prevent deleted SMS transactions from being re-imported.

### 🔒 Invariant 5: Local-First Security & SQLite WAL Mode
* **SQLCipher Password Contract**: Pass explicit encryption keys to `openDatabase()`. In `DatabaseHelper.onOpen`, execute `PRAGMA journal_mode = WAL;` via `db.rawQuery(...)` for non-blocking concurrent writes.
* **Local Auth / Dialog Resume**: Screens invoking native file pickers or share sheets must call `AppLockScreen.ignoreNextResumeLock()` to prevent unintentional app locking on resume.

### 🔄 Invariant 6: Zero-Cloud P2P Sync & Bi-Directional Merge
* **LWW 2-Way Delta Merges**: Execute non-destructive merges over local Wi-Fi. Soft-deletes check `deletedAt` with 5-second clock skew tolerance.
* **Stable Identity & Multi-Network Endpoints**: Each peer retains an immutable `deviceId` UUID with multiple saved `DeviceEndpoint`s (e.g., home and office Wi-Fi). Never deduplicate peers by IP or pair code.

### 🛡️ Invariant 7: Absolute Permission Rule & Major/Minor Release Gates
* **No Unprompted Git Actions**: NEVER run `git commit`, `git tag`, or `git push` without explicit, real-time user confirmation.
* **Mandatory Analysis & Testing**: Run `flutter analyze` (0 errors/warnings) and `flutter test` (all tests passing) before committing or building.
* **Major vs. Minor Documentation Strategy**:
  - **Major Releases (`X.0.0`)**: Review `OnboardingScreen` slides; optionally bump onboarding key (`hasSeenOnboarding_v2`) if core workflows changed.
  - **Minor/Patch Releases (`X.Y.Z`)**: Existing users bypass onboarding. `PLAY_STORE_NOTES.md` and `WhatsNewSheet` present the **cumulative headline features from the current minor cycle (`X.Y.x`)** alongside the latest patch fixes.
* **4-File Parity**: Update `PLAY_STORE_NOTES.md` (`<en-US>` and `<ta-IN>`, < 450 characters each), `lib/screens/changelog_screen.dart`, `lib/widgets/whats_new_sheet.dart`, and `CHANGELOG.md` atomically before compiling release APKs or running `./deploy.sh`.

### 🔘 Invariant 8: Standard FAB Bottom Clearance & Universal Morphing Protocol
* **No Obscured Content**: Bottom scrollable content must never be clipped or obscured by floating buttons or bottom navigation chrome. Always apply `AppLayout.fabBottomPadding = 96.0` to sliver lists or bottom padding containers.
* **Universal Morphing FAB**: All floating action buttons must use `AppMorphingFab` (`lib/core/ui/app_morphing_fab.dart`), reacting to `UserScrollNotification` to dynamically collapse into a $56 \times 56\text{dp}$ circular button on downward scroll and expand back to the stadium button on upward scroll.
* **Donut Chart Precision**: Donut chart center hole labels must be explicitly bounded inside a `SizedBox` with `FittedBox(fit: BoxFit.scaleDown)` to prevent text from touching chart rings, and slices must enforce a minimum 1.5% angle floor so micro-slivers remain visible.

### 🖼️ Invariant 9: R8 Full-Mode Optimization & Bitmap Memory Downsampling
* **R8 Full-Mode Hygiene**: Maintain `android.enableR8.fullMode=true` in `android/gradle.properties`. Avoid broad wildcards like `-keep class io.flutter.** { *; }` in `proguard-rules.pro` that disable dead code elimination and method inlining passes.
* **Bitmap Downsampling Bounds**: Never decode raw 12–48MP images without bounding parameters. All `Image.file`, `Image.network`, and `Image.asset` preview widgets MUST supply `cacheWidth` (e.g. `cacheWidth: 1080` for note embeds, `cacheWidth: 400` for grid/list cards) and provide `errorBuilder` fallbacks to prevent OOM memory pressure.
* **Global Image Cache Bounds**: `main.dart` must maintain `imageCache.maximumSizeBytes = 100 * 1024 * 1024` (100MB) and `maximumSize = 100`.

---

## 4. Token & Command Economy (LLM OS Principles)

1. **Consult Developer Map First**: Read [.agent/map.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/map.md) to locate exact files, providers, and schemas before querying or editing.
2. **Targeted Reading**: Use `grep_search` and bounded line slices (`view_file` with `StartLine`/`EndLine`). Never mass-scan the workspace, `build/`, `.dart_tool/`, or lockfiles.
3. **Reactive Wakeup**: Do not poll or loop while waiting for asynchronous commands or background tasks. The system will automatically wake up upon task completion.

---

## 5. Specialized Workspace Skills

Activate deep procedural skills in [.agent/skills/](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/) for complex workflows:

* **[App-Feature-Expert](file:///.agent/skills/App-Feature-Expert/SKILL.md)**: Domain architecture specialist for Notes (Quill Delta scope guardrails, auto-save), Financial Manager (SMS regex parsing, AI refine, recurring rules), Health Tracker (cycle prediction algorithms), and Settings.
* **[UI-UX-Specialist](file:///.agent/skills/UI-UX-Specialist/SKILL.md)**: M3 Expressive design tokens, spring physics, seamless borderless bars, dynamic hero container alpha tints, and touch accessibility ($48 \times 48\text{dp}$).
* **[Onboarding-Expert](file:///.agent/skills/Onboarding-Expert/SKILL.md)**: Full-screen onboarding wizard (`OnboardingScreen`), live theme previews, modular feature setup, NPU AICore detection, and Settings replayability.
* **[release-management](file:///.agent/skills/release-management/SKILL.md)**: End-to-end release procedures, R8/ProGuard verification, local APK smoke testing, bilingual `PLAY_STORE_NOTES.md` sync, and `./deploy.sh` automation.
* **[Tester](file:///.agent/skills/Tester/SKILL.md)**: Comprehensive QA verification, viewport setups for full-screen widget tests, path provider mocks, SQLCipher & Workmanager isolate validation.
* **[skill-trainer](file:///.agent/skills/skill-trainer/SKILL.md)**: Protocol for extracting session learnings, updating skills, and maintaining the developer map.
* **[Loop-Engineer](file:///.agent/skills/Loop-Engineer/SKILL.md)**: Universal 4-tier autonomous loop engineering harness grounded in Flow Engineering, TDD self-healing, monotonic zero-regression verifiers, live UI/UX research with interactive grilling, and Small-to-Mighty roadmaps.
