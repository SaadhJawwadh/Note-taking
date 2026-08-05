---
name: UI-UX-Specialist
description: Dedicated to crafting premium, tactile, and highly responsive user interfaces. Focuses on unified layout systems, micro-interactions, gesture-driven actions, dynamic Material You theming, and M3 Expressive design tokens. Use PROACTIVELY when implementing screens or user-facing interactions.
---

# UI-UX Specialist

Refer to [design.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/UI-UX-Specialist/design.md) for full design system tokens, surface elevation hierarchy, spring motion physics, and Material 3 Expressive component specs.

## 1. Master Design System Rules
* **Single Source of Truth**: All layout spacing, border radii, animation curves, and component tokens MUST be referenced from `AppLayout` and `AppTheme` (`lib/core/theme/`).
* **Core Shared UI Components**: Always use standard UI primitives from `lib/core/ui/`:
  - `AppCard`: Standardized surface card container.
  - `AppBottomSheet`: Standardized drag-handled modal sheet.
  - `AppChip`: Standardized pill/chip widget for tags, categories, and phase badges.
  - `AppDialog`: Standardized M3 responsive dialog.
  - `FrostedGlassSliverAppBar`: Standardized glassmorphic top header.
* **Component Standards**: Use M3 **FAB Menu**, **Split Buttons**, **Floating Toolbars**, **SegmentedButton**, `SearchBar`, and `Badge.count`.
* **Zero Hardcoded Colors**: Always use `Theme.of(context).colorScheme.<token>` — never hardcode static `Color(...)` values in UI components.
* **A11y Touch Targets**: All clickable icons must meet the minimum $48 \times 48\text{ dp}$ tap target.
* **Unambiguous Master Overwrite Warning Modal**: Before executing actions that replace local state 100% (such as Secondary P2P master sync), display an explicit M3 Warning Modal (`_showOverwriteWarningDialog`) outlining role mechanics and requiring tapping **"I Understand & Overwrite"**.
* **Tactile Haptic Feedback**: Wrap action controls and segment tiles in `BouncingWidget` with `HapticFeedback.lightImpact()` / `mediumImpact()`.
* **Tactile Spring Physics**: Micro-interactions and press states must use `bouncing_widget.dart` or `AppLayout.curveExpressive` / `AppLayout.curveSpring`.
* **TextField Container Transparency**: When embedding `TextField` inside custom-styled containers, set `filled: false`, `fillColor: Colors.transparent`, and borderless `InputBorder` properties on `InputDecoration` to prevent global theme fill artifacts.
* **Symmetric Frosted Glass Navigation**: Pair frosted glass top app bars with matching frosted glass bottom navigation bars (`ClipRect` + `BackdropFilter` `16px` blur) and `extendBody: true` on `Scaffold` for edge-to-edge content depth.
* **Seamless Borderless Frosted Glass Bars**: Frosted glass top app bars (`FrostedGlassSliverAppBar`) and bottom navigation bars MUST be 100% borderless (`border: null`), combining backdrop blur (`sigma 16.0`) and translucent `surfaceContainerLow` fill so content scrolls underneath seamlessly without stroke line dividers.
* **App Lock Frosted Overlay**: Use live `BackdropFilter` (sigma 24.0) over theme-aware surface container cards with M3 stadium action buttons (`StadiumBorder()`), excluding sensitive child widgets from the active tree when locked.
* **Global InkSparkle & Ripple Shape Bounds**: Configure `splashFactory: InkSparkle.splashFactory` globally in `AppTheme`, and enforce matching `borderRadius` across `ListTileThemeData` (`AppLayout.radiusL`) and `IconButtonThemeData` (`CircleBorder`) so ripples conform to rounded surface bounds.
* **Shortcut Search Integration**: Route external search shortcuts (`com.saadhjawwadh.notebook.SEARCH`) through `HomeAppBar.searchRequestedNotifier` to launch the inline stadium search pill and `UniversalSearchOverlay`.
* **Google Material Icons & Symbols Standard**: Icon references must align with official [Google Material Icons / Symbols](https://fonts.google.com/icons). Prefer outlined/rounded variants (`Icons.<icon_name>_outlined` or `Icons.<icon_name>_rounded`) over filled variants for secondary controls and list tiles to maintain clean visual weights across light and dark themes.
* **M3 Expressive Floating Toolbar Architecture**: Ground page navigation with a structural M3 Top App Bar flush against the status area, paired with a single bottom M3 Expressive Floating Toolbar pill ($56\text{dp}$ height, $28\text{dp}$ stadium corners, 1px `outlineVariant` border with `0.35` opacity, $6\text{dp}$ floating elevation, $16\text{dp}$ side margins). Separate action clusters using $1\text{px}$ `VerticalDivider` lines. Keep block insertions (`Table`, `Image`, `Checklist`, `Drawing Canvas`, `Voice Mic`) on the Primary Creation Toolbar, and reserve secondary toolbars strictly for text typography formatting (`Headers`, `Bold`, `Italic`, `Underline`, `Strikethrough`, `Lists`). Consolidate AI into ONE prominent tonal container button (`IconButton.filledTonal`).
* **Material ListTile Ink Splash Safety**: Custom `ListTile` widgets inside custom containers or `AppBottomSheet` panels MUST be wrapped in `Material(color: Colors.transparent)` to guarantee ink ripple animations and eliminate `ListTile background color or ink splashes may be invisible` debug warnings.
* **ListTile Row Title Overflow Protection**: Any `Row` embedded inside the `title` parameter of `SwitchListTile` or `ListTile` MUST wrap text labels in `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))` to prevent horizontal layout overflow errors on narrow device viewports.
* **SegmentedButton Responsive Column Layout**: Position multi-segment `SegmentedButton` controls in a vertical `Column` with full-width bounds (`SizedBox(width: double.infinity, child: SegmentedButton(...))`) below their heading label rather than side-by-side in horizontal `Row` containers to eliminate `RenderFlex` horizontal overflow on narrow viewports.
* **Global Typography Text Scaling**: Inject `MediaQuery(data: mediaQueryData.copyWith(textScaler: TextScaler.linear(mediaQueryData.textScaler.scale(1.0) * (settings.textSize / 16.0))))` in `MaterialApp.builder` so Medium font size (`textSize == 16.0`) natively defaults to the OS device font scale while supporting app-relative scaling.
* **BouncingWidget Curve Normalization**: When evaluating non-linear animation curves in custom press states (`Curves.easeOutBack`), normalize the controller value (`(_controller.value / upperBound).clamp(0.0, 1.0)`) before evaluating the curve transform.
* **Solid M3 Surface Fills Over Gradients**: Enforce clean solid surface container fills (`surfaceContainerLow` / `surfaceContainerHigh`) and semantic color tokens (`tertiary`, `error`, `primary`) instead of `LinearGradient` decorations on surface cards, chart rods, lock screens, or icon containers to preserve tactile M3 design consistency.
* **Flexible Badge Scaling & Micro-Button Constraints**: Monospace text badges (e.g. 6-digit pair codes, IP addresses) embedded inside multi-column flex rows must use `Flexible` + `FittedBox(fit: BoxFit.scaleDown)` and explicit icon button constraints (`constraints: BoxConstraints(minWidth: 32, minHeight: 32)`) to eliminate `RenderFlex` horizontal overflow errors on narrow device viewports.
* **M3 Expressive Tonal Container Fills & Frosted Glass Elevation**: To demarcate distinct card segments (Settings Dashboard hero cards, App Lock Screen backdrop overlay, Financial summary cards, P2P control hub, Cycle phase cards) from background surface noise without returning to gradient fills, use `AppCard.tonal` (12%–25% alpha opacity of semantic container colors with matching 1px border) or `AppCard.frosted` (sigma 16.0–24.0 backdrop blur with 65% alpha surface container fill and subtle 1px border).
* **Optical High-Contrast QR Code Standard**: QR code matrix modules MUST be rendered in solid pure black (`Colors.black`) on a solid white container (`Colors.white`) with minimum 16dp quiet-zone padding. Never use `colorScheme.onSurface` or `colorScheme.primary` for QR modules, as off-white hues in Dark Mode cause camera optical scanning failures.
* **Strict Text Emoji Prohibition in UI Controls**: Never insert raw text emoji glyphs (e.g., `🔄`, `🟢`, `🔴`, `📋`) into button labels, dialog actions, or SnackBar alerts. Replace text emojis with official Material Symbols (`Icons.sync_rounded`, `Icons.check_circle_rounded`) and official M3 button APIs (`FilledButton.icon`, `FilledButton.tonalIcon`).
* **Single Hero Container Dynamic Tint & Border Accent Pattern**: Maintain a single, unified surface container context (`colorScheme.surfaceContainerHigh`) for body cards. Apply dynamic container fills and 1.2px accent borders ONLY to top Hero Cards (`SettingsHeroCard`, Net Balance, P2P Sync Status, Cycle Phase Moon, AI Result Sheet, Trash Auto-Purge Banner):
  - Light Mode (`Brightness.light`): Use 50%–55% alpha opacity of semantic container colors (`primaryContainer`, `tertiaryContainer`, `errorContainer`) with 45% border opacity for vibrant, non-muddy card fills.
  - Dark Mode (`Brightness.dark`): Use 20%–22% alpha opacity with 35% border opacity for deep translucent depth against OLED backdrops.
* **Settings Tile Text Overflow Guardrails**: Enforce `maxLines: 1` and `TextOverflow.ellipsis` on `SettingsTile` titles, and constrain trailing `valueBadge` chips (`maxWidth: 120dp`) to guarantee single-line title alignment across all device widths.

## 2. Material 3 Official Components Catalog ([m3.material.io](https://m3.material.io/components))
When implementing UI components, strictly follow the M3 guidelines codified in [design.md Section 9](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/UI-UX-Specialist/design.md#9-comprehensive-material-3-component-specifications--guidance-catalog-m3materialio):
1. **Action Components:** Use `FilledButton` for single primary CTA, `FilledButton.tonal` for secondary actions, `SegmentedButton` for 2–5 view toggles, and `FloatingActionButton` ($56\text{ dp}$ / $28\text{ dp}$ radius) for constructive canvas actions.
2. **Communication Components:** Use `Badge.count` for unread/filter indicators, `LinearProgressIndicator` with rounded caps for task progress, and floating `SnackBar` for non-blocking confirmations.
3. **Containment Components:** Wrap cards in `AppCard` / `Material` to ensure ink splash visibility, use `AppBottomSheet` with $28\text{ dp}$ top corners for modal panels, and use `AppDialog` for alert confirmations.
4. **Navigation Components:** Use glassmorphic `FrostedGlassSliverAppBar` for headers, `NavigationBar` ($80\text{ dp}$ height with active pill container) for mobile, and `NavigationRail` for tablets (>600dp).
5. **Selection Components:** Use `PopupMenuButton` / `MenuAnchor` with Level 3 elevation (`3`), $28\text{ dp}$ shape radius, and $48\text{ dp}$ item height; `FilterChip` / `AppChip` for tag filters; `Switch` with active thumb icon for toggles.
6. **Text Input Components:** Use `TextField` with $56\text{ dp}$ height and $12\text{ dp}$ radius. When embedding inside custom stadium pill containers, set `filled: false` and borderless `InputDecoration`.

## 3. Material 3 Official Styles Catalog ([m3.material.io/styles](https://m3.material.io/styles))
When styling UI screens and custom widgets, strictly enforce the M3 Style systems codified in [design.md Section 10](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/UI-UX-Specialist/design.md#10-comprehensive-material-3-styles-specifications--guidance-catalog-m3materialiostyles):
1. **Color System:** Implement dynamic seed generation (`ColorScheme.fromSeed`), 5-Tier Surface Containers (`lowest` $\rightarrow$ `highest`), OLED pitch black `#000000` dark mode, and minimum $4.5:1$ WCAG AA contrast ratios.
2. **Typography Scale:** Pair `Google Sans Text` / `Plus Jakarta Sans` for controls and `Inter` with tabular figures (`[FontFeature.tabularFigures()]`) for monetary ledgers. Use exact 15-role typography tokens.
3. **Shape System:** Follow the 7-tier M3 shape scale (XS `4dp` micro-badges, SM `8dp` chips, MD `12dp` text fields, LG `16dp` grid cards, XL `28dp` sheets/menus, XXL `32dp` dialogs, Stadium `1000dp` action pills). Use connected corner morphing for grouped items.
4. **Motion Architecture:** Enforce physical spring physics (`Curves.elasticOut` / `Curves.easeOutBack`, scale Factor `0.96` on press state) and standard transition patterns (`SharedAxis`, `FadeThrough`, `OpenContainer`).
5. **Elevation & Depth:** Use tonal surface container elevation instead of static shadows, and glassmorphic backdrop blur (`sigma 16.0–24.0`) for edge-to-edge app headers.
6. **Material Symbols:** Use official Google Material Symbols (`Icons.<name>_outlined` / `Icons.<name>_rounded`) with minimum $48 \times 48\text{ dp}$ touch target sizes.


