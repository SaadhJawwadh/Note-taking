# Settings, Onboarding & Shell Screens M3 Expressive Audit Report

- **Auditor**: Settings & Screens Explorer (`explorer_settings_3`)
- **Working Directory**: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_settings_3`
- **Target Modules**: `lib/features/settings/`, `lib/screens/`, `lib/widgets/settings_widgets.dart`, `lib/widgets/whats_new_sheet.dart`
- **Execution Mode**: Read-Only Inspection (Zero Source Code Modifications)
- **Timestamp**: 2026-09-16T05:10:00Z

---

## 1. Executive Summary & Domain Compliance Score

A thorough read-only static analysis and architectural audit was conducted across all presentation screens, sheets, dialogs, state managers, and widget helpers within the Settings, Onboarding, App Lock, Changelog, and Shell Navigation domains.

The overall domain compliance score is **83.5%**. The subsystem exhibits high adherence to the local-first security model, zero-cloud privacy guarantees, and hardware-aware AI gating, but contains specific deviations in shape scale tokens, touch target bounds on secondary action pills, raw Unicode text emojis, and backup serialization coverage.

### Compliance Scorecard

| Evaluation Dimension | Compliance | Grade | Status & Key Highlights |
|---|---|---|---|
| **1. Surface Elevation & Zero Blur** | 98% | **A+** | **Zero `BackdropFilter` or blur contamination** across all settings and shell screens. 5 solid surface container tiers used throughout (`surfaceContainerLowest` to `surfaceContainerHighest`). Legacy naming artifacts (`AppCard.frosted`, `FrostedGlassSliverAppBar`) exist as aliases only. |
| **2. Shape Scale Hierarchy** | 78% | **C+** | Setting cards correctly use 16dp squircles, but `SettingsSection` applies 28dp (`radiusXL`) instead of 16dp (`radiusL`). Grouped lists lack connected corner morphing (`_Divider` returns `SizedBox.shrink()`). Onboarding and What's New primary CTA buttons and tag pills use 8–16dp squircles instead of 1000dp Stadium pills (`radiusStadium`). |
| **3. Motion & Physics** | 88% | **B+** | Smooth spring curves (`animDefault`, `curveFast`, `curveEmphasizedDecelerate`), staggered list animations, and haptic feedback on toggles. Minor issue: `SettingsTile` features duplicate haptic vibrations due to nested `ListTile.onTap` and `BouncingWidget.onTap`. |
| **4. Touch & Accessibility** | 74% | **C** | Primary buttons adhere to $\ge 48 \times 48\text{dp}$. However, `SettingsHeroCard` compact action chips (`[ 🔒 Protected ]`, `[ ☁️ Manual Backup ]`), Onboarding Pro-tip action buttons (`TextButton` with `minimumSize: Size.zero`), and App Lock's fallback disable button violate minimum 48dp touch bounds. Several custom interactive containers omit `Semantics(button: true)`. |
| **5. Settings Invariants** | 92% | **A-** | Full-screen onboarding replayability is 100% compliant. Hardware-aware AI gating strictly enforces `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`). `ignoreNextResumeLock` is properly invoked before file pickers and external URLs. Deviation: `SettingsHeroCard` container uses 45% alpha in Light Mode instead of the mandated 50%–55%. |
| **6. Architecture & Modularity** | 71% | **C-** | 1-line re-export stubs (`lib/data/settings_provider.dart`, `lib/widgets/frosted_glass_sliver_app_bar.dart`, `lib/core/ui/frosted_sliver_app_bar.dart`) violate Invariant 2. Raw `AlertDialog` and raw `showModalBottomSheet` are used instead of `AppDialog` and `AppBottomSheet`. Backup serialization in `SettingsProvider` is missing 7 recently added settings fields. Raw Unicode emojis persist in Changelog and What's New headers. |

---

## 2. In-Depth Evaluation by Dimension

### Dimension 1: Surface Elevation Hierarchy & Zero Frosted Glass Blur
- **Invariant Requirement**: 5 solid surface container levels (`surfaceContainerLowest` to `surfaceContainerHighest`). Pure solid surface headers (`ExpressiveSliverAppBar`) with zero blur. Complete absence of `BackdropFilter` or frosted glass blurs.
- **Audit Findings**:
  - **Zero `BackdropFilter`**: Grep inspection confirms 0 instances of `BackdropFilter` across `lib/features/settings/`, `lib/screens/`, `lib/widgets/settings_widgets.dart`, and `lib/widgets/whats_new_sheet.dart`.
  - **Solid Surface Header**: `SettingsScreen` (`settings_screen.dart:238`) and `HomeScreen` use `ExpressiveSliverAppBar`, which binds directly to `colorScheme.surfaceContainerLow` with `elevation: 0`, `border: null`, and zero blur.
  - **Navigation Shell**: `HomeScreen` (`home_screen.dart:731-738`) builds `NavigationBar` with `surfaceContainerLow`, `border: null`, and `backgroundColor: Colors.transparent`, ensuring edge-to-edge depth with zero GPU blur overhead.
  - **App Lock Screen**: `AppLockScreen` (`app_lock_screen.dart:276`) uses solid theme-aware backdrop (`isDark ? Colors.black : colorScheme.surface`).
  - **Legacy Naming Artifacts**:
    - `app_lock_screen.dart:280`: Uses `AppCard.frosted()`. Internally, `AppCard.frosted` was updated to solid `surfaceContainerHigh` / `surfaceContainer` with `blurSigma: 0.0` (zero blur), but the constructor name `.frosted` is a legacy artifact.
    - `changelog_screen.dart:18`: Imports `FrostedGlassSliverAppBar`, which is a 1-line re-export of `ExpressiveSliverAppBar`.

### Dimension 2: Shape Scale Hierarchy
- **Invariant Requirement**:
  - Tactile Stadium Pills ($1000\text{dp}$ / `StadiumBorder`): CTA buttons, tag pills, theme chips, filter pills.
  - Squircles: $12\text{dp}$–$16\text{dp}$ (`radiusL`) for setting cards; $28\text{dp}$ (`radiusXL`) for dialogs and modal bottom sheets.
  - Connected corner morphing in grouped setting list items.
- **Audit Findings**:
  - **`SettingsHeroCard` (`lib/widgets/settings_widgets.dart:45`)**: Outer card uses `BorderRadius.circular(AppLayout.radiusL)` (16dp squircle) — **Compliant**.
  - **`SettingsSection` (`lib/widgets/settings_widgets.dart:377`)**: Outer container uses `borderRadius: BorderRadius.circular(AppLayout.radiusXL)` (28dp). **Deviant**: 28dp is the modal dialog/sheet token; setting cards must use 12–16dp (`radiusL`).
  - **Grouped Setting Items & Connected Corners**: `SettingsSection` places all children in a single `Column` inside one container. It does not use connected corner morphing. Furthermore, `_Divider` (`settings_screen.dart:1963-1967`) builds `const SizedBox.shrink()`, so list tiles lack separating visual dividers.
  - **`OnboardingScreen` Primary Action Button (`onboarding_screen.dart:207`)**: Next / Get Started CTA button uses `borderRadius: BorderRadius.circular(AppLayout.radiusL)` (16dp squircle) instead of a Stadium pill (`AppLayout.radiusStadium` / $1000\text{dp}$). **Deviant**.
  - **`OnboardingScreen` Step Badge (`onboarding_screen.dart:108`)**: Uses `borderRadius: BorderRadius.circular(AppLayout.radiusS)` (8dp) instead of `AppLayout.radiusStadium`. **Deviant**.
  - **`OnboardingScreen` Pro-Tip CTA Buttons (`onboarding_screen.dart:1136`)**: Uses `borderRadius: BorderRadius.circular(AppLayout.radiusS)` (8dp) instead of `AppLayout.radiusStadium`. **Deviant**.
  - **`WhatsNewSheet` Container (`whats_new_sheet.dart:115`)**: Uses `Radius.circular(AppLayout.radiusXXL)` (32dp) instead of the standard 28dp squircle (`AppLayout.radiusXL`). **Deviant**.
  - **`WhatsNewSheet` Action Button (`whats_new_sheet.dart:299`)**: "Awesome, Got It!" button uses `borderRadius: BorderRadius.circular(AppLayout.radiusL)` (16dp) with manual `BoxShadow` instead of M3 Expressive Stadium pill (`StadiumBorder()`). **Deviant**.
  - **`WhatsNewSheet` Category & Version Badges (`whats_new_sheet.dart:173, 217`)**: Both use `AppLayout.radiusS` (8dp) instead of `AppLayout.radiusStadium`. **Deviant**.

### Dimension 3: Motion & Physics
- **Invariant Requirement**: Spring physics tokens (`AppLayout.springFast`, `AppLayout.springSpatial`), deceleration curves, fluid micro-interactions with haptic feedback.
- **Audit Findings**:
  - **Page View Transitions**: `OnboardingScreen` (`onboarding_screen.dart:46, 58`) uses `duration: AppLayout.animDefault` and `curve: AppLayout.curveFast`.
  - **Bottom Navigation Bar Transitions**: `HomeScreen` (`home_screen.dart:715-717`) uses `AnimatedSwitcher` with `AppLayout.animDefault`, `AppLayout.curveEmphasizedDecelerate`, and `AppLayout.curveEmphasizedAccelerate`.
  - **Staggered Animations**: `SettingsScreen` and `WhatsNewSheet` leverage `flutter_staggered_animations` (`SlideAnimation`, `FadeInAnimation`) for fluid list entry.
  - **Micro-interactions & Haptics**: Toggles trigger `HapticFeedback.selectionClick()` or `lightImpact()`.
  - **Duplicate Haptics / Nested Gesture Trap**:
    In `SettingsTile` (`settings_widgets.dart:494, 502-508`):
    `ListTile(onTap: () { HapticFeedback.selectionClick(); onTap!(); })` is wrapped inside `BouncingWidget(onTap: () { HapticFeedback.selectionClick(); onTap!(); })`. This can trigger double haptic clicks and causes `ListTile`'s internal `InkWell` to compete with `BouncingWidget`'s gesture detector.

### Dimension 4: Touch & Accessibility
- **Invariant Requirement**: Minimum $48 \times 48\text{dp}$ touch target hit bounds (`BoxConstraints(minWidth: 48, minHeight: 48)`), `Semantics(button: true)`, clear screen reader labeling.
- **Audit Findings**:
  - **`SettingsHeroCard` Micro-Action Chips (`settings_widgets.dart:144, 215`)**:
    The `[ 🔒 Protected ]` / `[ 🔓 Unlocked ]` and `[ ☁️ Manual Backup ]` action chips pass `isCompact: true` to `AppChip`. The resulting touch target is only $\sim 28\text{dp}$ high and lacks a minimum $48 \times 48\text{dp}$ hit constraint or padded gesture wrapper. **Severe A11y Violation**.
  - **`SettingsHeroCard` Theme SegmentedButton (`settings_widgets.dart:278`)**:
    Sets `tapTargetSize: MaterialTapTargetSize.shrinkWrap` and `visualDensity: VisualDensity.compact`, collapsing segment button touch heights below 48dp on compact viewports.
  - **`OnboardingScreen` Pro-Tip CTA Buttons (`onboarding_screen.dart:1127-1144`)**:
    Feature cards provide deep links ("Configure P2P Sync ➔", "Import Notes Now ➔") using `TextButton` styled with `padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6)`, `minimumSize: Size.zero`, and `tapTargetSize: MaterialTapTargetSize.shrinkWrap`. This produces a touch target of $\sim 26\text{dp}$ vertical height. **Severe A11y Violation**.
  - **`OnboardingScreen` Theme Tiles (`onboarding_screen.dart:1161-1205`)**:
    `_buildThemeOptionTile` provides sufficient physical height ($\sim 64\text{dp}$), but lacks `Semantics(button: true, selected: isSelected)`.
  - **`AppLockScreen` Disable Fallback Button (`app_lock_screen.dart:379-391`)**:
    `TextButton.icon(onPressed: ..., label: Text('Disable App Lock'))` has no minimum size constraint and renders at $\sim 36\text{dp}$ vertical height.
  - **`SettingsScreen` Top Search Clear Button (`settings_screen.dart:287-300`)**:
    `IconButton` sets `constraints: const BoxConstraints()`, `visualDensity: VisualDensity.compact`, and `padding: EdgeInsets.zero`, producing a $\sim 24 \times 24\text{dp}$ tap area.

### Dimension 5: Settings Invariants
- **Dynamic Hero Card Opacities**:
  - *Invariant*: 50%–55% alpha in Light Mode; 20%–22% alpha in Dark Mode with 1.2px accent borders.
  - *Observed (`settings_widgets.dart:44-49`)*:
    `color: colorScheme.primaryContainer.withValues(alpha: isDark ? 0.20 : 0.45)`
    `border: Border.all(color: colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.40), width: 1.2)`
    **Deviant**: Light Mode container opacity is **0.45 (45%)**, which is below the mandated 50%–55% range. Dark mode (20%) and border width (1.2px) are compliant.
- **Hardware-Aware AI Gating (`isAiActive`)**:
  - *Invariant*: UI controls must query `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`).
  - *Observed*:
    - `settings_screen.dart:401`: `isAiEnabled: settings.isAiActive` passed to `SettingsHeroCard`. **Compliant**.
    - `settings_screen.dart:492, 966`: Gemini Nano AI switch tile is gated on `if (settings.isDeviceAiSupported)`. **Compliant**.
    - `onboarding_screen.dart:876`: Hardware status badge checks `settings.isDeviceAiSupported`. **Compliant**.
    - `settings_provider.dart:118`: Canonical definition `bool get isAiActive => _useOnDeviceAi && _isDeviceAiSupported;`. **Compliant**.
- **Onboarding Replayability**:
  - *Invariant*: Full-screen onboarding wizard must be launchable anytime from Settings.
  - *Observed*:
    - `settings_screen.dart:813-826`: Under the About section, "Replay Setup & Intro" pushes `OnboardingScreen(isReplay: true)`. **100% Compliant**.
- **`AppLockScreen.ignoreNextResumeLock` / `withLockIgnored`**:
  - *Invariant*: External intents, file pickers, and share sheets must bypass resume lock checks.
  - *Observed*:
    - `settings_screen.dart:1679`: `AppLockScreen.ignoreNextResumeLock()` invoked before `FilePicker.platform.getDirectoryPath()`. **Compliant**.
    - `settings_screen.dart:1694`: `AppLockScreen.ignoreNextResumeLock()` invoked in `_launchUrl()` before `launchUrl()`. **Compliant**.
    - `backup_service.dart:267, 310, 617, 728`: Invoked before directory and file pickers. **Compliant**.
    - `note_migration_service.dart:52`: Uses `AppLockScreen.withLockIgnored(...)`. **Compliant**.
    - *Edge Case*: In `BackupService.exportBackup` (`backup_service.dart:291`), if the directory picker is cancelled or unsupported, fallback `Share.shareXFiles` is invoked. The initial `ignoreNextResumeLock()` was consumed upon returning from the picker; launching the share sheet without re-arming `ignoreNextResumeLock()` can cause lock screen interception when returning from the share sheet.

### Dimension 6: Architecture, Modularity & Technical Debt
- **1-Line Re-export Stub Violations (Invariant 2)**:
  - `lib/data/settings_provider.dart` contains only `export '../features/settings/providers/settings_provider.dart';`.
  - `lib/widgets/frosted_glass_sliver_app_bar.dart` contains only `export '../core/ui/frosted_sliver_app_bar.dart';`.
  - `lib/core/ui/frosted_sliver_app_bar.dart` contains only `export 'expressive_sliver_app_bar.dart';`.
  - Invariant 2 explicitly states: *"No Stubs / Direct Imports: Import screens and repositories directly from feature directories. Do NOT create 1-line re-export stub files."*
- **Indirect Stub Imports**:
  - `app_lock_screen.dart:9`: `import '../data/settings_provider.dart';`
  - `whats_new_sheet.dart:5`: `import '../data/settings_provider.dart';`
  - `changelog_screen.dart:3`: `import '../widgets/frosted_glass_sliver_app_bar.dart';`
- **Raw Dialogs & Bottom Sheets Instead of Core UI Primitives**:
  - `settings_screen.dart:575, 1036`: Uses raw `showModalBottomSheet(...)` to open `RecurringRulesSheet` instead of `AppBottomSheet.show(...)` or `RecurringRulesSheet.show(context)`.
  - `settings_screen.dart:1761-1794`: In `_showDefaultPaymentInfoDialog`, uses raw `showDialog(...)` with `AlertDialog(...)` instead of `AppDialog.show(...)`.
- **Prohibition of Raw Text Emojis (Rule 41 Violation)**:
  - `changelog_screen.dart:36, 45, 51`: Category titles contain raw Unicode emoji glyphs (`"🌟 What's New"`, `"🚀 Improvements"`, `"🐛 Fixes"`).
  - `whats_new_sheet.dart:34, 61, 88`: Category titles contain raw Unicode emoji glyphs (`"🌟 What's New"`, `"🚀 Improvements"`, `"🐛 Fixes"`).
- **Missing Backup Serialization in `SettingsProvider`**:
  - In `SettingsProvider.toBackupMap()` (`settings_provider.dart:643-664`) and `restoreFromBackupMap()` (`settings_provider.dart:666-758`), the following 7 newly added settings are completely omitted:
    1. `showSplitBills`
    2. `enableSavingsVault`
    3. `account1Name`
    4. `account2Name`
    5. `categoryAccountRouting`
    6. `defaultPaymentInfo`
    7. `trashAutoPurgeDays`
  - When a user backs up and restores their database on a new device, all dual-account names, default category routing, WhatsApp payment details, and split bills visibility reset to factory defaults!

---

## 3. Inventory of Deviations, Hardcoded Values & Visual Inconsistencies

### Table 1: Design System & Token Deviations

| File | Line(s) | Observed Code / Pattern | Invariant / Target Token | Rationale |
|---|---|---|---|---|
| `lib/widgets/settings_widgets.dart` | 44 | `alpha: isDark ? 0.20 : 0.45` | `alpha: isDark ? 0.20 : 0.52` | Hero cards must use 50%–55% alpha in Light Mode for vibrant non-muddy fills. |
| `lib/widgets/settings_widgets.dart` | 41, 342 | `padding: const EdgeInsets.only(bottom: 20)` | `EdgeInsets.only(bottom: AppLayout.spaceL)` | Replace magic number 20 with 16dp/24dp layout tokens. |
| `lib/widgets/settings_widgets.dart` | 347 | `padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4)` | `AppLayout.spaceS`, `AppLayout.spaceXS` | Replace magic numbers 12, 8, 4 with layout tokens. |
| `lib/widgets/settings_widgets.dart` | 354 | `borderRadius: BorderRadius.circular(6)` | `BorderRadius.circular(AppLayout.radiusXS)` | Replace magic number 6 with radius token. |
| `lib/widgets/settings_widgets.dart` | 377 | `BorderRadius.circular(AppLayout.radiusXL)` (28dp) | `BorderRadius.circular(AppLayout.radiusL)` (16dp) | Card containers must use 12–16dp squircles; 28dp is reserved for dialogs and sheets. |
| `lib/widgets/settings_widgets.dart` | 104-130, 186-230 | Hardcoded color literals (`0xFF10B981`, `0xFF059669`, `0xFFF43F5E`, etc.) | Semantic tokens from `colorScheme` / `AppSemanticColors` | Hero badges should reference theme extension semantic tokens rather than static ARGB constants. |
| `lib/features/settings/presentation/screens/onboarding_screen.dart` | 108 | `BorderRadius.circular(AppLayout.radiusS)` (8dp) | `BorderRadius.circular(AppLayout.radiusStadium)` | Header step/replay badge must be a tactile stadium pill. |
| `lib/features/settings/presentation/screens/onboarding_screen.dart` | 207 | `BorderRadius.circular(AppLayout.radiusL)` (16dp) | `BorderRadius.circular(AppLayout.radiusStadium)` | Primary onboarding CTA button must be a 1000dp Stadium pill. |
| `lib/features/settings/presentation/screens/onboarding_screen.dart` | 1136 | `BorderRadius.circular(AppLayout.radiusS)` (8dp) | `BorderRadius.circular(AppLayout.radiusStadium)` | Pro-tip card action button must use Stadium pill radius. |
| `lib/widgets/whats_new_sheet.dart` | 115 | `Radius.circular(AppLayout.radiusXXL)` (32dp) | `Radius.circular(AppLayout.radiusXL)` (28dp) | Standard M3 modal sheet squircle top corners are 28dp. |
| `lib/widgets/whats_new_sheet.dart` | 173, 217 | `BorderRadius.circular(AppLayout.radiusS)` (8dp) | `BorderRadius.circular(AppLayout.radiusStadium)` | Version tag and category header pills must use Stadium pill radius. |
| `lib/widgets/whats_new_sheet.dart` | 299 | `BorderRadius.circular(AppLayout.radiusL)` (16dp) | `BorderRadius.circular(AppLayout.radiusStadium)` | Primary "Awesome, Got It!" CTA must use Stadium pill radius. |
| `lib/widgets/whats_new_sheet.dart` | 300-305 | `boxShadow: [BoxShadow(color: ..., blurRadius: 10)]` | M3 surface tonal elevation / `AppLayout.softShadow` | Eliminate arbitrary drop shadow on action button. |
| `lib/screens/app_lock_screen.dart` | 281-283 | `margin: 24, padding: 32, borderRadius: 28` | `AppLayout.spaceXL`, `AppLayout.spaceXXL`, `AppLayout.radiusXL` | Replace magic numbers 24, 32, 28 with design tokens. |
| `lib/screens/app_lock_screen.dart` | 301, 320, 336 | `padding: 20`, `height: 24`, `height: 16` | `AppLayout.spaceL`, `AppLayout.spaceXL`, `AppLayout.spaceM` | Replace hardcoded spacing numbers. |

---

### Table 2: Touch & Accessibility Deviations

| File | Line(s) | UI Element | Observed Touch Bound | Requirement |
|---|---|---|---|---|
| `lib/widgets/settings_widgets.dart` | 144-159 | `AppChip` (`Protected` / `Unlocked`) | $\sim 28\text{dp}$ height (`isCompact: true`) | Enforce minimum $48 \times 48\text{dp}$ tap area (`BoxConstraints(minWidth: 48, minHeight: 48)`). |
| `lib/widgets/settings_widgets.dart` | 214-232 | `AppChip` (`Manual Backup`) | $\sim 28\text{dp}$ height (`isCompact: true`) | Enforce minimum $48 \times 48\text{dp}$ tap area. |
| `lib/widgets/settings_widgets.dart` | 278 | `SegmentedButton<ThemeMode>` | `shrinkWrap` & `compact` density | Ensure segments maintain minimum 48dp touch bounds. |
| `lib/features/settings/presentation/screens/onboarding_screen.dart` | 1127-1144 | Pro-tip `TextButton` ("Configure P2P Sync ➔") | `padding: (12, 6)`, `minSize: Size.zero` ($\sim 26\text{dp}$ height) | Enforce `minimumSize: const Size(48, 48)` with `Semantics(button: true)`. |
| `lib/screens/app_lock_screen.dart` | 379-391 | `TextButton.icon` ("Disable App Lock") | Default TextButton height ($\sim 36\text{dp}$) | Enforce `minimumSize: const Size(160, 48)` with `Semantics(button: true)`. |
| `lib/features/settings/presentation/screens/settings_screen.dart` | 287-300 | Search clear `IconButton` | `constraints: const BoxConstraints()` | Enforce `BoxConstraints(minWidth: 40, minHeight: 40)` matching top bar action standards. |

---

### Table 3: Technical Debt, Modularity & Invariants

| File | Line(s) | Issue / Violation | Architectural Remediation |
|---|---|---|---|
| `lib/data/settings_provider.dart` | 1-2 | 1-line re-export stub violating Invariant 2. | Migrate callers (`app_lock_screen.dart:9`, `whats_new_sheet.dart:5`) to direct import and delete stub. |
| `lib/widgets/frosted_glass_sliver_app_bar.dart` | 1-2 | 1-line re-export stub chain. | Migrate caller (`changelog_screen.dart:3`) to `lib/core/ui/expressive_sliver_app_bar.dart` and delete stubs. |
| `lib/core/ui/frosted_sliver_app_bar.dart` | 1-2 | 1-line re-export stub. | Delete stub once references are updated. |
| `lib/features/settings/presentation/screens/settings_screen.dart` | 575, 1036 | Raw `showModalBottomSheet` for recurring rules. | Standardize on `AppBottomSheet.show` or `RecurringRulesSheet.show(context)`. |
| `lib/features/settings/presentation/screens/settings_screen.dart` | 1761-1794 | Raw `showDialog` with `AlertDialog` for payment info. | Standardize on `AppDialog.show` with responsive width bounds. |
| `lib/screens/changelog_screen.dart` | 36, 45, 51 | Raw Unicode emojis (`🌟`, `🚀`, `🐛`) in headers. | Replace with plain text and official Material Symbols (`Icons.auto_awesome_rounded`, etc.). |
| `lib/widgets/whats_new_sheet.dart` | 34, 61, 88 | Raw Unicode emojis (`🌟`, `🚀`, `🐛`) in headers. | Replace with plain text and official Material Symbols. |
| `lib/features/settings/providers/settings_provider.dart` | 643-758 | 7 settings missing in `toBackupMap` & `restoreFromBackupMap`. | Serialize `showSplitBills`, `enableSavingsVault`, `account1Name`, `account2Name`, `categoryAccountRouting`, `defaultPaymentInfo`, `trashAutoPurgeDays`. |
| `lib/features/settings/presentation/screens/settings_screen.dart` | 134-170, 183-217, etc. | `ListTile` items in modal bottom sheets lack `Material` wrapper. | Wrap in `Material(color: Colors.transparent)` to prevent ink ripple clipping. |
| `lib/widgets/settings_widgets.dart` | 494, 502-508 | Nested duplicate `onTap` in `SettingsTile` and `BouncingWidget`. | Move `onTap` solely to `BouncingWidget` or `ListTile`, avoiding duplicate haptic invocations. |

---

## 4. Concrete Recommendations & Actionable Implementation Roadmap

### Phase 1: Foundational M3 Token & A11y Fixes (High Impact, Low Risk)

#### 1.1 Align `SettingsHeroCard` Opacity to Invariant
In `lib/widgets/settings_widgets.dart`:
```dart
// Before (line 44):
color: colorScheme.primaryContainer.withValues(alpha: isDark ? 0.20 : 0.45),

// After:
color: colorScheme.primaryContainer.withValues(alpha: isDark ? 0.20 : 0.52),
```

#### 1.2 Upgrade Setting Card Radius & Section Spacing
In `lib/widgets/settings_widgets.dart`:
```dart
// Before (line 377):
borderRadius: BorderRadius.circular(AppLayout.radiusXL), // 28dp

// After:
borderRadius: BorderRadius.circular(AppLayout.radiusL), // 16dp squircle
```

#### 1.3 Fix Micro-Touch Targets in `SettingsHeroCard`
Wrap the interactive `AppChip` widgets in `lib/widgets/settings_widgets.dart:144, 214` in minimum $48 \times 48\text{dp}$ hit bounds with `Semantics(button: true)`:
```dart
ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
  child: Center(
    child: AppChip(
      isCompact: true,
      icon: isAppLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
      label: isAppLockEnabled ? 'Protected' : 'Unlocked',
      isSelected: isAppLockEnabled,
      onTap: onAppLockTap,
      // ...
    ),
  ),
),
```

#### 1.4 Enforce Stadium Pills on Action Buttons & Tag Badges
1. In `lib/features/settings/presentation/screens/onboarding_screen.dart:207`:
   Change primary action button `borderRadius` from `AppLayout.radiusL` to `AppLayout.radiusStadium`.
2. In `lib/features/settings/presentation/screens/onboarding_screen.dart:108`:
   Change step badge `borderRadius` from `AppLayout.radiusS` to `AppLayout.radiusStadium`.
3. In `lib/features/settings/presentation/screens/onboarding_screen.dart:1136`:
   Change pro-tip action button `borderRadius` to `AppLayout.radiusStadium` and add `minimumSize: const Size(48, 48)`.
4. In `lib/widgets/whats_new_sheet.dart:299`:
   Change "Awesome, Got It!" button `borderRadius` to `AppLayout.radiusStadium` and eliminate raw `boxShadow`.

---

### Phase 2: Architecture, Modularity & Backup Parity

#### 2.1 Complete `SettingsProvider` Backup Serialization
Add the 7 missing fields to `toBackupMap` and `restoreFromBackupMap` in `lib/features/settings/providers/settings_provider.dart`:
```dart
// In toBackupMap():
'showSplitBills': _showSplitBills,
'enableSavingsVault': _enableSavingsVault,
'account1Name': _account1Name,
'account2Name': _account2Name,
'categoryAccountRouting': _categoryAccountRouting,
'defaultPaymentInfo': _defaultPaymentInfo,
'trashAutoPurgeDays': _trashAutoPurgeDays,

// In restoreFromBackupMap():
if (map.containsKey('showSplitBills')) {
  final val = map['showSplitBills'];
  if (val is bool) await setShowSplitBills(val);
}
if (map.containsKey('enableSavingsVault')) {
  final val = map['enableSavingsVault'];
  if (val is bool) await setEnableSavingsVault(val);
}
if (map.containsKey('account1Name')) {
  final val = map['account1Name'];
  if (val is String && val.isNotEmpty) await setAccount1Name(val);
}
if (map.containsKey('account2Name')) {
  final val = map['account2Name'];
  if (val is String && val.isNotEmpty) await setAccount2Name(val);
}
if (map.containsKey('categoryAccountRouting')) {
  final val = map['categoryAccountRouting'];
  if (val is Map) {
    for (final e in val.entries) {
      await setCategoryAccountRouting(e.key.toString(), e.value?.toString());
    }
  }
}
if (map.containsKey('defaultPaymentInfo')) {
  final val = map['defaultPaymentInfo'];
  if (val is String) await setDefaultPaymentInfo(val);
}
if (map.containsKey('trashAutoPurgeDays')) {
  final val = map['trashAutoPurgeDays'];
  if (val is int) await setTrashAutoPurgeDays(val);
}
```

#### 2.2 Eliminate 1-Line Re-Export Stubs
1. Change imports in `app_lock_screen.dart` and `whats_new_sheet.dart` from `../data/settings_provider.dart` to `package:note_taking_app/features/settings/providers/settings_provider.dart` or relative feature path.
2. Change import in `changelog_screen.dart` from `../widgets/frosted_glass_sliver_app_bar.dart` to `package:note_taking_app/core/ui/expressive_sliver_app_bar.dart`.
3. Delete `lib/data/settings_provider.dart`, `lib/widgets/frosted_glass_sliver_app_bar.dart`, and `lib/core/ui/frosted_sliver_app_bar.dart`.

#### 2.3 Standardize Dialogs & Sheets on Core Primitives
1. Replace `AlertDialog` in `_showDefaultPaymentInfoDialog` (`settings_screen.dart:1763`) with `AppDialog`.
2. Replace raw `showModalBottomSheet` in `settings_screen.dart:575, 1036` with `RecurringRulesSheet.show(context)` or `AppBottomSheet.show(...)`.

#### 2.4 Replace Raw Text Emojis with Semantic Material Symbols
In `changelog_screen.dart` and `whats_new_sheet.dart`:
- Replace `"🌟 What's New"` with `Icons.stars_rounded` + `"What's New"`.
- Replace `"🚀 Improvements"` with `Icons.rocket_launch_rounded` + `"Improvements"`.
- Replace `"🐛 Fixes"` with `Icons.bug_report_rounded` + `"Fixes"`.

---

## 5. Verification Methods

1. **Static Analysis**:
   ```bash
   flutter analyze
   ```
   Expectation: 0 errors, 0 warnings.
2. **Widget & Unit Tests**:
   ```bash
   flutter test test/onboarding_test.dart
   flutter test test/upgrade_backward_compatibility_test.dart
   ```
   Expectation: All tests pass.
3. **Backup Parity Verification**:
   Create a unit test asserting that exporting a `SettingsProvider` instance configured with custom `account1Name`, `account2Name`, `showSplitBills: true`, `categoryAccountRouting`, and `defaultPaymentInfo` correctly round-trips via `toBackupMap()` and `restoreFromBackupMap()` without data loss.

