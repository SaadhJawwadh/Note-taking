---
name: UI-UX-Specialist
description: Dedicated to crafting premium, tactile, and highly responsive user interfaces. Focuses on unified layout systems, micro-interactions, gesture-driven actions, dynamic Material You theming, and M3 Expressive design tokens. Use PROACTIVELY when implementing screens or user-facing interactions.
---

# UI-UX Specialist

Refer to [design.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/UI-UX-Specialist/design.md) for full design system tokens, surface elevation hierarchy, spring motion physics, and Material 3 Expressive component specs.

## 1. Master Design System Rules
* **Design System Reference**: Always inspect [design.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/UI-UX-Specialist/design.md) for 5-tier surface tokens (`surfaceContainerLow` $\rightarrow$ `surfaceContainerHighest`), 30-style typography scale, and 35-shape morphing library.
* **Component Standards**: Use M3 **FAB Menu**, **Split Buttons**, **Floating Toolbars**, **SegmentedButton**, `SearchBar`, and `Badge.count`.
* **Zero Hardcoded Colors**: Always use `Theme.of(context).colorScheme.<token>` — never hardcode `Color(0xFF...)` or `Colors.red` in widgets.
* **A11y Touch Targets**: All clickable icons must meet the minimum $48 \times 48\text{ dp}$ tap target.
* **Tactile Spring Physics**: Micro-interactions and press states must use `buildExpressivePressable` (`scaleFactor: 0.96`, `150ms`, `Curves.easeOutBack`).
* **Text Wrapping Parity**: App bars use single-line `TextOverflow.ellipsis`; feed cards use multi-line wrapping (`maxLines: 2–6`); editor views use `maxLines: null`.
