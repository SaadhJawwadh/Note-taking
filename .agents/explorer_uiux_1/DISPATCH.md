## 2026-08-30T07:41:52Z
You are the UI/UX Consistency & Touch Accessibility Specialist Explorer.
Your mission: Conduct a comprehensive, read-only audit of UI/UX consistency, Material 3 Expressive theming, and touch accessibility across all user-facing screens and widgets (lib/core/ui/, lib/core/theme/, and all screens in lib/features/).

Authoritative references to inspect:
- /Users/saadhjawwadh/Documents/Code/Note taking/.agents/ORIGINAL_REQUEST.md (specifically §R3)
- /Users/saadhjawwadh/Documents/Code/Note taking/AGENTS.md (Invariants 1, 8, 10, 13, 14)
- /Users/saadhjawwadh/Documents/Code/Note taking/.agent/map.md
- /Users/saadhjawwadh/Documents/Code/Note taking/.agent/skills/UI-UX-Specialist/SKILL.md

Your designated working directory:
/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_uiux_1/

Scope to Audit:
1. Single Source of Truth Tokens: Scan screens and widgets for magic numbers, hardcoded paddings (e.g. EdgeInsets.all(16)), inline border radii, static colors (e.g. Colors.blue), and spring motion curves, mapping them to AppLayout and Theme.of(context).colorScheme / AppSemanticColors.
2. Touch Target Bounds: Audit all interactive micro-elements (sync buttons, date filter pills, 'Details >' links, pagination dots, action icons) for minimum 48x48dp hit bounds (BoxConstraints(minWidth: 48, minHeight: 48) or padded wrappers) and Semantics(button: true).
3. Top App Bar Symmetry & Chrome: Verify FrostedGlassSliverAppBar (sigma 16.0, border: null, surfaceContainerLow fill), 16dp edge margin symmetry, canonical 3-slot action hierarchy ([Contextual] -> [⋮ Tools] -> [⚙️ Settings]), Tonal Scope Pill styling & contrast, toolbarHeight = padding.top + 72.0, inner height = 60.0.
4. Dynamic Hero Card Opacities: Validate container opacity across hero cards (SettingsHeroCard, Net Balance, P2P Sync Status, Cycle Moon Phase, Trash Banner) for 50%–55% Light Mode, 20%–22% Dark Mode, and 1.2px accent borders.
5. Universal Morphing FAB & Bottom Clearance: Check AppMorphingFab collapse/expand behavior on scroll, and verify AppLayout.fabBottomPadding = 96.0 across all sliver lists.
6. Modern Selection Controls: Verify elimination of legacy DropdownButton/DropdownButtonFormField in favor of SegmentedButton or FilterChip sourced from TransactionCategory.allNames.
7. Prohibition of Raw Text Emojis (Rule 41): Check for raw Unicode emoji glyphs in UI badges/labels, mapping them to Material Symbols and semantic text.
