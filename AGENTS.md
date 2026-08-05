# Project Agent Guidelines & Master Rules

Refer to [.agent/rules.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/rules.md) for master rules and [map.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/map.md) for architectural maps.

## Summary Rules:
1. **Consult Developer Map First**: Refer to `map.md` before scanning or editing files.
2. **Single Source of Truth Theme & Core UI**: Use `AppTheme` / `AppLayout` (`lib/core/theme/`) for design tokens and `lib/core/ui/` (`AppCard`, `AppBottomSheet`, `AppChip`, `AppDialog`, `FrostedGlassSliverAppBar`) for UI components.
3. **Feature-Driven Architecture**: Place domain code in `lib/features/` (`notes`, `finances`, `health`, `settings`) with decoupled providers.
4. **Mandatory Analysis & Testing**: Run `flutter analyze` and `flutter test` after code changes.
5. **No Unprompted Git Commits/Pushes**: Request explicit user confirmation before committing or pushing.
6. **Seamless Borderless Bars & Hero Tints**: Keep top/bottom bars 100% borderless (`border: null`) and dynamically scale Hero Container alpha opacities (50%–55% Light Mode vs 20%–22% Dark Mode).
