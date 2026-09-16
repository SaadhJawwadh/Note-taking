# Task Assignment: Finances & Split Bills M3 Expressive Audit

## Working Directory & Identity
- Working Directory: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_finances_3`
- Role: Codebase Explorer & M3 Expressive Inspector (Finances Module)
- Parent Orchestrator: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/orchestrator_3`

## Mandatory Reference Documents
- `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/ORIGINAL_REQUEST.md` (read completely first)
- `/Users/saadhjawwadh/Documents/Code/Note taking/AGENTS.md` (authoritative invariants and design tokens)
- `/Users/saadhjawwadh/Documents/Code/Note taking/.agent/map.md` (codebase map)
- Relevant Skills: `/Users/saadhjawwadh/Documents/Code/Note taking/.agent/skills/App-Feature-Expert/SKILL.md`, `/Users/saadhjawwadh/Documents/Code/Note taking/.agent/skills/UI-UX-Specialist/SKILL.md`

## STRICT NON-DESTRUCTIVE GUARDRAIL
- ZERO SOURCE CODE MODIFICATIONS (`git status` must remain 100% clean and pristine).
- All inspection is strictly read-only.

## Scope of Inspection
Inspect all files in `lib/features/finances/`:
- `lib/features/finances/presentation/` (all screens and widgets: `financial_manager_screen.dart`, `transaction_editor_screen.dart`, `budget_screen.dart`, `split_bills_screen.dart`, `settle_up_sheet.dart`, `receipt_camera_sheet.dart`, `sms_sync_banner.dart`, `financial_hero_card.dart`, `category_chips.dart`, `account_selector.dart`, chart widgets, etc.)
- Any relevant presentation widgets in `lib/features/finances/`

## Evaluation Dimensions
1. **Surface Elevation Hierarchy**: 5 solid surface container levels (`surfaceContainerLowest` to `surfaceContainerHighest`). Confirm complete absence of `BackdropFilter` or frosted glass blurs across all finance screens, sheets, and dialogs.
2. **Shape Scale Hierarchy**: Stadium pills (1000dp) for account chips, filter pills, date scope capsules; Squircles (12-16dp for transaction cards, 28dp for sheets/dialogs); connected corner morphing in transaction lists.
3. **Motion & Physics**: Spring physics tokens, universal morphing FAB clearance (`AppLayout.fabBottomPadding = 96.0`), and `AppMorphingFab` usage.
4. **Touch & Accessibility**: Minimum 48x48dp hit targets, `Semantics(button: true)`, 1px accent chart borders (`BorderSide(color: colorScheme.primary.withValues(alpha: 0.3), width: 1.0)`), authentic currency symbol badges (tonal circular avatar, never generic $ icon).
5. **Top App Bar Invariant**: Left header structure (`Finances` + `[ 📅 Date Range ▾ ]` tonal scope pill), action order (`[ 🔍 Search ]`, `[ 🔄 Sync ]`, `[ ⋮ Tools ]`, `[ ⚙️ Settings ]`), search mode transformation (`_isSearching`) auto-switching to Ledger.
6. **Finance Invariants**: Dual accounts (`AccountType.daily` vs `AccountType.savings`), 24h default SMS sync banner with persistent 1-tap Cancel, donut chart center label bounds (FittedBox) and 1.5% angle floor, split bills isolation and settle-up cash flow contracts.

## Output Deliverables
Write a detailed report to `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_finances_3/report.md` with:
- Executive Summary & Compliance Score (0-100%)
- Exact file paths and line ranges for all findings (Compliant, Deviant, Technical Debt)
- Detailed inventory of any remaining hardcoded values, legacy patterns, or visual inconsistencies
- Concrete recommendations and actionable roadmap for Finances Module
Write `handoff.md` and send a completion message to the parent orchestrator.
