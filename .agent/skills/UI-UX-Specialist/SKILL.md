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
* **Tactile Spring Physics**: Micro-interactions and press states must use `bouncing_widget.dart` or `AppLayout.curveExpressive` / `AppLayout.curveSpring`.
* **TextField Container Transparency**: When embedding `TextField` inside custom-styled containers, set `filled: false`, `fillColor: Colors.transparent`, and borderless `InputBorder` properties on `InputDecoration` to prevent global theme fill artifacts.
* **Symmetric Frosted Glass Navigation**: Pair frosted glass top app bars with matching frosted glass bottom navigation bars (`ClipRect` + `BackdropFilter` `16px` blur) and `extendBody: true` on `Scaffold` for edge-to-edge content depth.
* **Light Mode Frosted Glass Contrast**: Pair 0.80 alpha backdrop blur with dynamic `surfaceContainerLow` fill and a subtle bottom border (`BorderSide(color: outlineVariant.withValues(alpha: 0.35), width: 1)`) for edge-to-edge light mode definition.
* **App Lock Frosted Overlay**: Use live `BackdropFilter` (sigma 24.0) over theme-aware surface container cards with M3 stadium action buttons (`StadiumBorder()`), excluding sensitive child widgets from the active tree when locked.
* **Global InkSparkle & Ripple Shape Bounds**: Configure `splashFactory: InkSparkle.splashFactory` globally in `AppTheme`, and enforce matching `borderRadius` across `ListTileThemeData` (`AppLayout.radiusL`) and `IconButtonThemeData` (`CircleBorder`) so ripples conform to rounded surface bounds.
* **Shortcut Search Integration**: Route external search shortcuts (`com.saadhjawwadh.notebook.SEARCH`) through `HomeAppBar.searchRequestedNotifier` to launch the inline stadium search pill and `UniversalSearchOverlay`.
