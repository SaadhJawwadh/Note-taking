---
name: UI-UX-Specialist
description: Dedicated to crafting premium, tactile, and highly responsive user interfaces. Focuses on unified layout systems (Grid, List), micro-interactions, gesture-driven actions, and dynamic Material You theming to ensure the app feels "alive" and modern. Use PROACTIVELY when implementing screens or user-facing interactions.
---

# UI-UX Specialist

Use this skill when designing, implementing, or refining layouts, micro-animations, gestures, theming, or transitions.

## 1. Design Language & Theming (Material 3)
* **Material 3 Enforced**: Always ensure `useMaterial3: true` is configured in `ThemeData`.
* **Dynamic Colors**: Use `ColorScheme` tokens carefully:
  * `surfaceContainerLow` / `surfaceContainer` for card structures.
  * `surfaceContainerHigh` / `surfaceContainerHighest` for toolbars, search bars, and dialogs.
  * `outlineVariant` for subtle borders/dividers and `outline` for strong borders.
* **Typography Scale**: Align all text styling to official M3 specs:
  * Headings: `headlineLarge`, `headlineMedium`, `headlineSmall`
  * Titles: `titleLarge`, `titleMedium`, `titleSmall`
  * Body: `bodyLarge`, `bodyMedium`, `bodySmall`
* **Geometry**: Corner radius should be `8` to `12` for chips, `16` to `20` for standard cards/dialogs, and `28` for bottom sheets.

## 2. Component Mapping (Material 3)
* **Navigation**: Use `NavigationBar` for bottom menus, `NavigationRail` for tablets, and `NavigationDrawer` for desktop layout screens. Avoid legacy `BottomNavigationBar`.
* **Buttons**: Use `FilledButton` (primary), `FilledButton.tonal` / `OutlinedButton` (secondary), and `TextButton` (low-emphasis).
* **Information Cards**: Set `elevation: 0` unless specifically highlighting. Use `color: Theme.of(context).colorScheme.surfaceContainerLow` and add a subtle outline: `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1.0))`.
* **Input Fields**: Use `TextField` with M3 filled or outlined styles, using `surfaceContainerHighest` as the background fill color.
* **Toggles**: Use `SegmentedButton` instead of legacy toggle buttons.
* **Icons**: Semantic accuracy is critical. Do not use AI-associated icons (`Icons.auto_awesome`, `Icons.sparkles`) for non-AI tasks. Use standard icons like `Icons.shuffle` for random selections, and reserve AI icons strictly for actual AI services.

## 3. Gestures, Motion & Layout
* **snappy Transitions**: Use snappy transitions like `OpenContainer` (from `package:animations`) with durations around ~300ms.
* **List vs Grid**: Support List View (high density) and Masonry Grid (visual cards) switching seamlessly.
* **Hero Animation Safety**: To prevent `Hero._allHeroesFor` StackOverflow exceptions inside a `CustomScrollView` using `AnimationLimiter`, always wrap the `CustomScrollView` **itself** with `AnimationLimiter`, not its individual sliver children.
* **Unique Hero Tags**: Every FAB in the multi-tab navigation stack must have a unique `heroTag` (e.g. `heroTag: 'home_fab'`) to prevent animation conflicts.
* **Index Clamping**: Always clamp navigation indexes to `[0, activeTabsCount - 1]` to prevent index out of bounds crashes when tabs are dynamically toggled off in settings.

## 4. App Lock Overlay & Picker Safety
* **State-Preserving Lock Overlay**: When the app lock is triggered on app pause, display the lock screen as a `Stack` overlay on top of the child view rather than unmounting the child widget tree. This preserves background async actions and picker states. Unmount the child only when the session is fully unauthenticated.
* **Picker Lock Bypass**: Call `AppLockScreen.ignoreNextResumeLock()` immediately before invoking native platform dialogs (`FilePicker`, `ImagePicker`, directory pickers) to prevent the background-pause state from locking the session upon user return.
* **Share Intent Queuing**: When launching/resuming the app via a system share sheet while App Lock is active, the child view is completely unmounted. To prevent state loss, queue the shared intent paths in a static variable (e.g. `AppLockScreen.pendingSharedPaths`) and check/process the queue inside the child state's lifecycle immediately upon successful unlock.
* **Material 3 Dialog Standardizations**: All custom pickers or alert dialogs must explicitly set their background color using `Theme.of(context).colorScheme.surfaceContainerHigh` to align dialog styles with the official Material 3 guidelines and other picker widgets in the app.
