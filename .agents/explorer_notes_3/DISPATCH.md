# Task Assignment: Notes Module M3 Expressive Audit

## Working Directory & Identity
- Working Directory: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_notes_3`
- Role: Codebase Explorer & M3 Expressive Inspector (Notes Module)
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
Inspect all files in `lib/features/notes/` and `lib/screens/home_screen.dart`:
- `lib/screens/home_screen.dart`
- `lib/features/notes/presentation/` (all screens and widgets including note cards, editor screen, selection toolbar, search bar, tag bar, trash screen, folder picker, note preview widgets)
- `lib/features/notes/data/` & `domain/` models/repositories if UI constants leak into them

## Evaluation Dimensions
1. **Surface Elevation Hierarchy**: 5 solid surface container levels (`surfaceContainerLowest` to `surfaceContainerHighest`). Confirm complete absence of `BackdropFilter` or frosted glass blurs.
2. **Shape Scale Hierarchy**: Stadium pills (1000dp) for tag chips, search capsules, action buttons; Squircles (12-16dp for note cards, 28dp for sheets/dialogs); connected corner morphing if lists/groups exist.
3. **Motion & Physics**: Spring physics on interactions, universal morphing FAB clearance (`AppLayout.fabBottomPadding = 96.0`), and `AppMorphingFab` usage.
4. **Touch & Accessibility**: Minimum 48x48dp hit targets, `Semantics(button: true)`.
5. **Top App Bar Invariant**: Left header structure (`Notes` + `[ 📁 Folder • Count ▾ ]` tonal scope pill), action order (`[ 🔍 Search ]`, `[ 🔄 Sync ]` (when paired), `[ ⋮ Tools ]`, `[ ⚙️ Settings ]`), 16dp edge margin symmetry, 40x40 min action constraints.
6. **Note Invariants**: Quill Delta sanitization, selection clamping, auto-purge 7-day lifecycle banner opacity, Google Takeout / Keep bookmark invariants.

## Output Deliverables
Write a detailed report to `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_notes_3/report.md` with:
- Executive Summary & Compliance Score (0-100%)
- Exact file paths and line ranges for all findings (Compliant, Deviant, Technical Debt)
- Detailed inventory of any remaining hardcoded values, legacy patterns, or visual inconsistencies
- Concrete recommendations and actionable roadmap for Notes Module
Write `handoff.md` and send a completion message to the parent orchestrator.

## 2026-09-16T04:50:14Z

<USER_REQUEST>
You are the Notes Module Explorer.
Your working directory is `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_notes_3`.
Your parent orchestrator is `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/orchestrator_3` (conversation ID: 6ec8d34f-5c83-44cf-b500-0dacec388c7d).

MANDATORY FIRST STEP:
Read `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/ORIGINAL_REQUEST.md` completely.
Read `/Users/saadhjawwadh/Documents/Code/Note taking/AGENTS.md` and `.agent/map.md`.
Read your task dispatch file at `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_notes_3/DISPATCH.md`.

STRICT NON-DESTRUCTIVE GUARDRAIL:
- ZERO SOURCE CODE MODIFICATIONS (`git status` must remain 100% clean and pristine).
- Read-only inspection and analysis only.

Perform a thorough inspection of all presentation files in `lib/features/notes/` and `lib/screens/home_screen.dart`.
Evaluate against:
- 5 solid surface container levels, zero BackdropFilter/frosted glass blurs.
- Shape scale hierarchy: Stadium pills for tag chips, search capsules; Squircles (12-16dp for note cards, 28dp for sheets/dialogs).
- Universal morphing FAB clearance (`AppLayout.fabBottomPadding = 96.0`) and `AppMorphingFab`.
- Top App Bar Invariants: `Notes` + `[ 📁 Folder • Count ▾ ]` scope pill, action order (`[ 🔍 Search ]`, `[ 🔄 Sync ]`, `[ ⋮ Tools ]`, `[ ⚙️ Settings ]`), 16dp edge margin symmetry, 40x40 min action constraints.
- Note Invariants: Quill Delta sanitization, selection clamping, auto-purge 7-day lifecycle banner opacity, Google Takeout / Keep bookmark invariants.

Output: Write your complete, structured findings to `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_notes_3/report.md` and `handoff.md`.
When finished, send a message to your parent with a concise summary and path to your report.
</USER_REQUEST>
