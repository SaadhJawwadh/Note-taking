---
name: Onboarding-Expert
description: Specialist skill governing the app onboarding architecture, full-screen wizard (OnboardingScreen), live theme customization, modular feature setup, background auto-sync toggles, hardware NPU AI Core detection, and Settings replayability.
---

# Onboarding Expert Skill

Specialist skill governing the onboarding experience, setup screens, live theme previews, modular feature toggles, and Settings replayability for Everything App.

---

## 1. Onboarding Architecture & Entry Points

- **Primary Screen File**: `lib/features/settings/presentation/screens/onboarding_screen.dart`
- **First Launch Route**: Handled reactively in `lib/screens/home_screen.dart` when `!settings.hasSeenOnboarding`.
  ```dart
  if (settings.isInitialized && !settings.hasSeenOnboarding && !_onboardingChecked) {
    _onboardingChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }
  ```
- **Settings Replayability**: Reachable anytime via `lib/features/settings/presentation/screens/settings_screen.dart` under the About section ("Replay Setup & Intro"):
  ```dart
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const OnboardingScreen(isReplay: true),
    ),
  );
  ```

---

## 2. Page Structure & Interactive Setup Rules

1. **Page 1: Welcome & Vision (Setup Choice Mode)**
   - Introduces offline privacy, zero cloud lock-in, and local SQLCipher database encryption.
   - **Primary Device Choice Card**: Set up as new Primary notebook (proceeds with wizard).
   - **Pair & Import Choice Card**: Launches camera QR scanner to pull master database state from Primary phone in 1 step during onboarding.
2. **Page 2: Personalization & Live Theme Preview**
   - **Theme Mode Selector**: System, Light, Dark options (`settings.setThemeMode(...)`).
   - **Real-Time Visual Feedback**: Toggling theme modes immediately updates `Theme.of(context)` across the active widget tree.
   - **Dynamic Color Toggle**: Material You wallpaper color extraction (`settings.setUseDynamicColor(...)`).
3. **Page 3: Modular Powerups**
   - **Financial Manager**: Ledger, categories, and SMS parsing (`settings.setShowFinancialManager(...)`).
   - **Auto SMS Background Sync**: Contextual sub-card toggle (`settings.setDailySyncEnabled(...)`) when Financial Manager is enabled. Automatically triggers `SmsService.syncDailySyncSchedule()`.
   - **Period & Health Tracker**: Offline cycle predictions and discreet alerts (`settings.setIsPeriodTrackerEnabled(...)`).
4. **Page 4: On-Device Gemini AI Setup**
   - **NPU / Hardware Detection Badge**: Checks `settings.isDeviceAiSupported` (Android AI Core support).
   - **Local AI Toggle**: Offline text summarization and smart SMS categorization (`settings.setUseOnDeviceAi(...)`).
5. **Page 5: Ready to Explore & Pro-Tips**
   - Pro-tips cards for **Auto Sync & AES-256 Backups**, **App Lock & Security**, **Multi-Select Batch Actions**, and **Responsive Navigation**.

---

## 3. UI/UX Design System & Layout Rules

- **Single Source of Truth Tokens**: Reference all spacings, radii, and animation curves from `AppLayout` (`spaceXS`–`spaceXXL`, `radiusS`–`radiusMAX`, `animDefault`, `curveFast`).
- **Dynamic Theme Colors**: Access all colors exclusively via `Theme.of(context).colorScheme.<token>`. Never hardcode static `Color(...)` values.
- **Responsive Width Clamping**: Wrap top-level body content in `ConstrainedBox(maxWidth: AppLayout.maxContentWidth)` (600dp) so wizard pages look crisp on both phones and tablets.
- **Responsive Text Layouts**: Wrap all titles and status badge texts inside `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))` inside `Row` widgets to prevent horizontal layout overflow errors on narrow screens.
- **Tactile Haptic Feedback**: Wrap action controls and segment tiles in `BouncingWidget` with `HapticFeedback.lightImpact()` / `mediumImpact()`.

---

## 4. Testing & Verification Requirements

- **Widget Tests Setup**: Defined in `test/onboarding_test.dart`.
- **Surface Dimensions in Tests**: Configure test view dimensions to simulate mobile devices:
  ```dart
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  ```
- **Tap Interactions**: Use `warnIfMissed: false` when tapping list tiles or offscreen buttons inside PageView tests.
- **Mandatory Verification**: Run `flutter analyze` and `flutter test` after modifying any onboarding files.
