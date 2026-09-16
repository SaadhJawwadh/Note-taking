# Task Assignment: Core UI & Theme M3 Expressive Audit

## Working Directory & Identity
- Working Directory: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_core_3`
- Role: Codebase Explorer & M3 Expressive Inspector (Core UI & Theme)
- Parent Orchestrator: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/orchestrator_3`

## Mandatory Reference Documents
- `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/ORIGINAL_REQUEST.md` (read completely first)
- `/Users/saadhjawwadh/Documents/Code/Note taking/AGENTS.md` (authoritative invariants and design tokens)
- `/Users/saadhjawwadh/Documents/Code/Note taking/.agent/map.md` (codebase map)
- Relevant Skills: `/Users/saadhjawwadh/.gemini/config/skills/karpathy-principles/SKILL.md`, `/Users/saadhjawwadh/Documents/Code/Note taking/.agent/skills/UI-UX-Specialist/SKILL.md`

## STRICT NON-DESTRUCTIVE GUARDRAIL
- ZERO SOURCE CODE MODIFICATIONS (`git status` must remain 100% clean and pristine).
- All inspection is strictly read-only.

## Scope of Inspection
Inspect all files in `lib/core/`:
- `lib/core/theme/app_layout.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/ui/app_card.dart`
- `lib/core/ui/app_bottom_sheet.dart`
- `lib/core/ui/app_chip.dart`
- `lib/core/ui/app_dialog.dart`
- `lib/core/ui/expressive_sliver_app_bar.dart`
- `lib/core/ui/expressive_split_button.dart`
- `lib/core/ui/expressive_wavy_slider.dart`
- `lib/core/ui/expressive_wavy_progress.dart`
- `lib/core/ui/expressive_shape_morph_indicator.dart`
- `lib/core/ui/app_morphing_fab.dart`
- Any other widgets/primitives in `lib/core/` and router `lib/core/routes/app_router.dart`

## Evaluation Dimensions
1. **Surface Elevation Hierarchy**: 5 solid surface container levels (`surfaceContainerLowest` to `surfaceContainerHighest`). Confirm complete absence of `BackdropFilter` or frosted glass blurs across all core components.
2. **Shape Scale Hierarchy**: Stadium pills (1000dp) for chips/capsules/buttons, Squircles (12-16dp for cards, 28dp for dialogs/sheets), and connected corner morphing.
3. **Motion & Physics**: Velocity-aware spring physics tokens (`springFast`, `springSpatial`, `springBouncy`) and decelerate curves.
4. **Touch & Accessibility**: Minimum 48x48dp hit targets (`BoxConstraints(minWidth: 48, minHeight: 48)`), `Semantics(button: true)`.
5. **Single Source of Truth Tokens**: Are tokens clean, comprehensive, and adhered to? Are there any missing tokens or internal magic numbers?

## Output Deliverables
Write a detailed report to `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_core_3/report.md` with:
- Executive Summary & Compliance Score (0-100%)
- Exact file paths and line ranges for all findings (Compliant, Deviant, Technical Debt)
- Detailed inventory of any remaining hardcoded values, legacy patterns, or inconsistencies
- Concrete recommendations and actionable roadmap for Core UI
Write `handoff.md` and send a completion message to the parent orchestrator.

## 2026-09-16T04:50:14Z
You are the Core UI & Theme Explorer.
Your working directory is `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_core_3`.
Your parent orchestrator is `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/orchestrator_3` (conversation ID: 6ec8d34f-5c83-44cf-b500-0dacec388c7d).

MANDATORY FIRST STEP:
Read `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/ORIGINAL_REQUEST.md` completely.
Read `/Users/saadhjawwadh/Documents/Code/Note taking/AGENTS.md` and `.agent/map.md`.
Read your task dispatch file at `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_core_3/DISPATCH.md`.

STRICT NON-DESTRUCTIVE GUARDRAIL:
- ZERO SOURCE CODE MODIFICATIONS (`git status` must remain 100% clean and pristine).
- Read-only inspection and analysis only.

Perform a thorough, line-by-line inspection of all files in `lib/core/` (Theme tokens, atomic UI primitives, navigation, curves, surfaces).
Evaluate against:
- 5 solid surface container levels (`surfaceContainerLowest` to `surfaceContainerHighest`), zero BackdropFilter/blur.
- Shape scale hierarchy: Stadium pills (1000dp), Squircles (12-16dp cards, 28dp dialogs/sheets), connected corner morphing.
- Motion & physics: Spring tokens (`springFast`, `springSpatial`, `springBouncy`).
- Touch & accessibility: Hit targets >= 48x48dp, semantic labels.
- Single Source of Truth token consistency (identify any magic numbers).

Output: Write your complete, structured findings to `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_core_3/report.md` and `handoff.md`.
When finished, send a message to your parent with a concise summary and path to your report.
