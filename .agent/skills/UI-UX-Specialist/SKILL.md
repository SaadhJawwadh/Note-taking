---
name: UI-UX-Specialist
description: Dedicated to crafting premium, tactile, and highly responsive user interfaces. Focuses on unified layout systems (Grid, Kanban, List), micro-interactions, gesture-driven actions (swipe, drag-and-drop), and dynamic Material You theming to ensure the app feels "alive" and modern. Use PROACTIVELY when implementing new screens, animations, or user-facing interactions.
metadata:
  model: inherit
---

## Use this skill when

- Designing or implementing new user interfaces and layouts.
- Adding complex gesture-driven interactions like Drag-and-Drop, Swipe-to-Dismiss, or custom scrolling.
- Integrating fine-tuned micro-animations (e.g., `OpenContainer`, Hero animations, animated transitions).
- Implementing or refining typography, color blending, and Material You dynamic theming.
- Modernizing existing features to align with premium app aesthetics (e.g., taking inspiration from top-tier productivity apps).

## Do not use this skill when

- Working purely on backend logic, database modeling, or network requests.
- Writing CI/CD pipelines or DevOps scripts.
- Fixing internal logic bugs unrelated to the visual interface or user experience.

### 5. Seamless Security & Utilities
- **Session-Based Lock**: Implement app locks that persist for the duration of the app session (until the process is killed). This avoids frustrating re-authentications during quick task switches.
- **Utility Bypasses**: High-value utility modules (like Share Intent handlers or File Converters) should bypass the lock screen entirely if triggered externally. This ensures "zero-friction" for quick actions outside the app's main flow.
- **Manual Session Management**: Provide static `unlockSession()` helpers to allow cross-module authentication states.
- **State-Preserving Lock Overlay**: When the app goes to background, use a `Stack` overlay (lock screen on top of the child) instead of unmounting the child widget tree. Unmounting destroys in-progress async operations (e.g., native file pickers returning results). The child tree should only be unmounted when the session is fully locked out (`!_isSessionAuthenticated`).
- **Picker-Aware Lock Bypass**: Add a static `ignoreNextResumeLock()` one-shot flag pattern to the lock screen. Call it before every native picker invocation (`FilePicker`, `ImagePicker`, directory pickers). The flag is consumed on the next `AppLifecycleState.resumed` event, preventing the timeout from triggering a lock when the user is simply returning from a platform dialog.

## Instructions

### 1. Tactile & Responsive Interfaces
- Always prioritize a tactile feel. The app must respond immediately to touches with appropriate ripple effects, elevation changes, or scaling animations.
- Add intuitive feedback loops for user actions: always provide Snackbar "Undo" toasts immediately after a destructive or curating action (e.g. archiving/trashing).

### 2. Modern Design Language & Theming (Material 3)
- **Always enforce Material 3**: Ensure `useMaterial3: true` is configured in `ThemeData`.
- **Dynamic Color Roles**: Derive background, container, and outline colors using `ColorScheme` tokens. Map container colors carefully:
  - Use `surfaceContainerLow` or `surfaceContainer` for card-like structures.
  - Use `surfaceContainerHigh` or `surfaceContainerHighest` for highlighting elements (like toolbars, dialogs).
  - Use `outlineVariant` for subtle borders/dividers and `outline` for prominent element boundaries.
- **Typography Scale**: Align all text styling to official M3 typography specifications:
  - Headings: `headlineLarge`, `headlineMedium`, `headlineSmall`
  - Titles: `titleLarge`, `titleMedium`, `titleSmall`
  - Body: `bodyLarge`, `bodyMedium`, `bodySmall`
  - Captions/Labels: `labelLarge`, `labelMedium`, `labelSmall`
- **Component Geometry**: Enforce M3 corner radii (e.g., `8` to `12` for chips, `16` to `20` for standard cards/dialogs, `28` for bottom sheets/large dialogs).

### 3. Material 3 Component Mapping
Follow the official Flutter M3 implementation specifications (https://m3.material.io/develop/flutter) for all visual controls:
- **Navigation**: Use `NavigationBar` for bottom menus, `NavigationRail` for tablets, and `NavigationDrawer` for desktop layout screens. Avoid legacy `BottomNavigationBar`.
- **Buttons**:
  - Primary: `FilledButton` or `ElevatedButton`.
  - Secondary/Contextual: `FilledButton.tonal` or `OutlinedButton`.
  - Low-emphasis: `TextButton`.
- **Toggles**: Use `SegmentedButton` instead of outdated `ToggleButtons` or custom container-based selection rows.
- **Action Triggers**: Use `FloatingActionButton` (small, normal, large) or `FloatingActionButton.extended` with a stadium shape.
- **Information Cards**: Use `Card` with M3 attributes. Set `elevation: 0` unless specifically highlighting. Use `color: Theme.of(context).colorScheme.surfaceContainerLow`. Always add a subtle outline: `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1.0))`.
- **Input Fields**: Use `TextField` with M3 filled or outlined styles, utilizing `surfaceContainerHighest` as the background fill color.
- **Chips**: Use specific M3 chips (`FilterChip`, `InputChip`, `ActionChip`, `ChoiceChip`) with standard borders and selection state styling.
- **Dialogs & Sheets**: Use `showDragHandle: true` on `showModalBottomSheet`. Use standard `AlertDialog` with M3 title padding and container coloring.
- **Icons**: Semantic accuracy is critical. Do not use AI-associated icons (`Icons.auto_awesome`, `Icons.sparkles`) for non-AI tasks like generating random numbers or selecting colors. Reserve them strictly for actual AI functions (e.g., Gemini summaries). Use standard icons like `Icons.shuffle` for random selections.

### 4. Unified View Architectures
- When dealing with collections of items (like notes), provide multi-modal views to cater to different user mental models:
  - **List View** for high-density reading.
  - **Masonry/Staggered Grid** for visual-heavy mixed content.
  - **Uniform Grid** for organized, rigid alignment.
  - **Kanban Boards** for state-based or tag-based organization.
  - **Settings & Configuration**: Refactor massive endless option lists into structured, categorized `ExpansionTile` groups. This dramatically reduces cognitive load and keeps advanced configuration discoverable but hidden.
- Implement seamless state management to switch between these layouts fluently.

### 5. Advanced Gestures & Micro-interactions
- Utilize powerful gesture interactions seamlessly:
  - Swipe actions (using `Dismissible`) tailored to left/right curations.
  - Drag-and-Drop organization using `LongPressDraggable` and `DragTarget`, paired with visual drop-zone feedback.
- Refine layout transitions (like the `animations` package's `OpenContainer`) to use snappy, deliberate durations (around ~300ms) rather than slow fades.
- Manage visual clutter actively. Handle edge cases like lengthy text overflow, rich link previews, and empty states gracefully, leaving plenty of whitespace.
- **Frictionless Utility**: Design one-tap default behaviors for frequent actions. Bury complex multi-step dialogs inside long-presses or settings categories.
- **Standalone Utility Architecture**: For high-value secondary features (like File Converters), implement a "Standalone Module" pattern:
    - Accessible via a dedicated Home Screen app bar icon for quick entry.
    - Grouped under "Standalone Utilities" in `SettingsScreen` using `ExpansionTile` to avoid cluttering the main navigation.
    - Deeply integrated with OS Share Intents to provide value outside the app's core loop.

## Project-Specific UI Guidelines
- **Centralized Design Tokens**: Always use `AppLayout` (`lib/theme/app_layout.dart`) for spacing, border radii, icon sizes, and animation durations. Do not hardcode layout constants. This ensures a consistent, premium tactile feel.
- **Widget Decomposition**: Break down complex UI screens (like the dashboard) into declarative modular widgets (`HomeAppBar`, `NoteViewBuilder`) rather than monolithic `build` methods.
- **Empty States**: Empty states must be interactive. Always provide a clear, styled Call-To-Action (e.g., a "Create My First Note" `FilledButton.icon`) directly in the empty state view to reduce user friction.
- **Layout Constraints**: When adding text to grid components (like `NoteCard`), always wrap the text in `Flexible` or `Expanded` widgets to prevent `RenderFlex overflow` errors on smaller screens or with long data.
