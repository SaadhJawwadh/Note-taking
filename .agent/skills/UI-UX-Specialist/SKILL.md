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

## Instructions

### 1. Tactile & Responsive Interfaces
- Always prioritize a tactile feel. The app must respond immediately to touches with appropriate ripple effects, elevation changes, or scaling animations.
- Add intuitive feedback loops for user actions: always provide Snackbar "Undo" toasts immediately after a destructive or curating action (e.g. archiving/trashing).

### 2. Modern Design Language & Theming
- Ensure consistent typography, spacing, and padding. Default to soft, rounded corners (e.g., `BorderRadius.circular(20)` to `24`) for cards, dialogs, and specific UI elements.
- Use dynamic color theming aggressively. Derive background and border colors using `ColorScheme.fromSeed(...)` paired with precise surface mapping (`surfaceContainerHigh`, `surfaceContainerLow`) to blend colors elegantly, maintaining cohesion across light/dark modes.
- Avoid flat, generic white or black containers unless strictly specified. Always add subtle tinted backgrounds.

### 3. Unified View Architectures
- When dealing with collections of items (like notes), provide multi-modal views to cater to different user mental models:
  - **List View** for high-density reading.
  - **Masonry/Staggered Grid** for visual-heavy mixed content.
  - **Uniform Grid** for organized, rigid alignment.
  - **Kanban Boards** for state-based or tag-based organization.
  - **Settings & Configuration**: Refactor massive endless option lists into structured, categorized `ExpansionTile` groups. This dramatically reduces cognitive load and keeps advanced configuration discoverable but hidden.
- Implement seamless state management to switch between these layouts fluently.

### 4. Advanced Gestures & Micro-interactions
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
