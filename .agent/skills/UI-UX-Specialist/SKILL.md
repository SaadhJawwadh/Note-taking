---
name: UI-UX-Specialist
description: Dedicated to crafting premium, tactile, and highly responsive user interfaces. Focuses on unified layout systems (Grid, List), micro-interactions, gesture-driven actions, dynamic Material You theming, and Inter + Google Sans Text typography to ensure the app feels "alive" and modern. Use PROACTIVELY when implementing screens or user-facing interactions.
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
* **Settings Cards Layout**: Avoid expandable menus (`ExpansionTile`) in settings screens to eliminate automatic expansion bugs. Instead, display settings in static card containers grouped under clear uppercase header labels with sub-icons and letter spacing.
* **Analytics Sub-Segment Navigation**: Large multi-card analytics screens must be organized into `SegmentedButton` sub-views (`Trends 📈` -> `Breakdown 🍩` -> `Budgets 🎯`) to reduce vertical page height by 60%+ and eliminate cognitive overload on mobile.
* **Chart Y-Axis Alignment Parity (`fl_chart`)**: When displaying vertically stacked analytics charts (e.g. Trend Line Chart over Monthly Bar Chart), both charts MUST share the exact same `reservedSize` (e.g. `reservedSize: 52`) on `leftTitles` to guarantee their plot areas align pixel-for-pixel vertically.
* **Multi-Line Tooltip Bounds (`fl_chart`)**: In `LineTouchTooltipData`, format multi-field text as structured two-line `TextSpan` blocks and explicitly set `fitInsideHorizontally: true` and `fitInsideVertically: true` to prevent tooltip text from clipping off-screen or awkwardly wrapping inside line dots.
* **Dynamic Wallpaper Theme Opt-Out**: When implementing dynamic Monet palette extraction via `dynamic_color`, provide a user preference setting (e.g. `useDynamicColor`) that passes `null` for `lightDynamic` / `darkDynamic` into `ThemeData` creation so users can opt out of wallpaper theming and stick to static Material 3 palettes.

## 3. Gestures, Motion & Layout
* **Snappy Transitions**: Use snappy transitions like `OpenContainer` (from `package:animations`) with durations around ~300ms.
* **List vs Grid**: Support List View (high density) and Masonry Grid (visual cards) switching seamlessly.
* **Hero Animation Safety**: To prevent `Hero._allHeroesFor` StackOverflow exceptions inside a `CustomScrollView` using `AnimationLimiter`, always wrap the `CustomScrollView` **itself** with `AnimationLimiter`, not its individual sliver children.
* **Unique Hero Tags**: Every FAB in the multi-tab navigation stack must have a unique `heroTag` (e.g. `heroTag: 'home_fab'`) to prevent animation conflicts.
* **Index Clamping**: Always clamp navigation indexes to `[0, activeTabsCount - 1]` to prevent index out of bounds crashes when tabs are dynamically toggled off in settings.
* **Glassmorphism Guidelines**: Restrict `BackdropFilter` glassmorphism to Privacy Overlays (App Lock Screen) and Floating Toolbars/Navigation Bars. Avoid glassmorphism on grid cards to maintain 120 FPS render performance and battery efficiency.

## 4. App Lock Overlay & Picker Safety
* **State-Preserving Lock Overlay**: When the app lock is triggered on app pause, display the lock screen as a `Stack` overlay on top of the child view rather than unmounting the child widget tree. This preserves background async actions and picker states. Unmount the child only when the session is fully unauthenticated.
* **Picker Lock Bypass**: Call `AppLockScreen.ignoreNextResumeLock()` immediately before invoking native platform dialogs (`FilePicker`, `ImagePicker`, directory pickers) to prevent the background-pause state from locking the session upon user return.
* **External Link Lock Bypass**: Call `AppLockScreen.ignoreNextResumeLock()` before launching external URLs (such as app rating pages or GitHub repositories) to prevent the app from locking when the user returns from external browser/store apps.
* **Share Intent Queuing**: When launching/resuming the app via a system share sheet while App Lock is active, the child view is completely unmounted. To prevent state loss, queue the shared intent paths in a static variable (e.g. `AppLockScreen.pendingSharedPaths`) and check/process the queue inside the child state's lifecycle immediately upon successful unlock.
* **Material 3 Dialog Standardizations**: All custom pickers or alert dialogs must explicitly set their background color using `Theme.of(context).colorScheme.surfaceContainerHigh` to align dialog styles with the official Material 3 guidelines and other picker widgets in the app.

## 5. Design Tokens Are Law (Material Expressive, v2.0+)
* **Radius/Spacing/Shadow tokens**: Never hardcode `BorderRadius.circular(N)`, spacing, or `BoxShadow(color: Colors.black...)`. Use `AppLayout.radiusS/M/L/XL/XXL/MAX`, `AppLayout.spaceX`, and `AppLayout.softShadow(context)` (theme-aware). Deliberate shape steps: cards 16 (`radiusL`) < buttons 20 (`radiusXL`) < FAB `StadiumBorder`; dialogs 28 (M3 spec).
* **Semantic colors**: Success/income and cycle-phase colors live in the `AppSemanticColors` `ThemeExtension` (in `app_theme.dart`). Destructive actions use `colorScheme.error` — never `Colors.red`. Access via `Theme.of(context).extension<AppSemanticColors>()`.
* **Font pairing**: `Google Sans Text` owns `display*`, `headline*`, and `titleLarge` (plus the AppBar title); **`Inter`** owns `titleMedium/Small`, `body*`, `label*` (offering superior tabular numeric alignment for financial ledgers and clean legibility for notes). Raw `TextStyle(fontSize: ...)` without a textTheme reference will NOT inherit the display font — route hero text through textTheme slots.
* **textTheme wiring gotcha**: A customized `TextTheme` built in `createTheme` does nothing unless explicitly passed as `ThemeData(textTheme: ...)` — the top-level `fontFamily:` shorthand silently bypasses it.
* **Theme-level surface shapes**: `popupMenuTheme`, `dialogTheme`, `snackBarTheme`, and `bottomSheetTheme` (with `maxWidth: AppLayout.maxContentWidth` for tablets) are defined centrally so ad hoc menus/dialogs inherit the design automatically. Don't restyle them per-screen.
* **Motion split**: Card-morph launches use `OpenContainer`; every other drill-in navigation uses `AppRoute.push(context, page)` (SharedAxis horizontal, `lib/utils/app_route.dart`).
* **Adaptive grids**: Note grids compute columns as `(width / 220).floor().clamp(2, 4)` for tablets/foldables; keep `columnCount` in `AnimationConfiguration.staggeredGrid` in sync.
* **Skeletons over spinners**: First-load states use the shared `SkeletonCard` (`lib/widgets/skeleton_card.dart`) shaped like the incoming content, not a centered `CircularProgressIndicator`.
* **Global keys**: `appNavigatorKey` / `appScaffoldMessengerKey` (`lib/utils/app_globals.dart`) let services and popped routes navigate or show snackbars.

## 6. Android Home Screen Widgets (M3 & RemoteViews)
* **Material 3 Corner Radius**: In Android 12+ (API 31+), home widgets must use a corner radius of `28dp` (Material 3 spec), while older platforms use `16dp` or `24dp`. Define these dynamically in `res/values/dimens.xml` and `res/values-v31/dimens.xml`.
* **3x2 & 4x2 Fixed Grid Lock**: Set `android:targetCellWidth="3"`, `android:targetCellHeight="2"`, and `android:resizeMode="horizontal"`. This locks height to 2 cells (~110dp–140dp) while allowing horizontal expansion.
* **Material You Dynamic Colors (Android 12+)**: Define `res/values-v31/colors.xml` and `res/values-night-v31/colors.xml` using Android system Monet tokens (`@android:color/system_accent1_...`, `@android:color/system_neutral1_...`) so widgets dynamically match the user's phone wallpaper.
* **RemoteViews Inflation Guardrails**: Generic `<View>` tags are forbidden in `RemoteViews` layouts and will crash the system launcher with an `InflateException`. Always use supported containers like `<FrameLayout>` or `<ImageView>` with a solid background color.
* **Type-Safe Bridge Data**: Flutter SharedPreferences can write numerical values in formats that Kotlin `SharedPreferences.getFloat()` fail to cast. Format all numbers/arrays into JSON strings or clean string representations before saving.
