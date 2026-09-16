# Task Assignment: Settings, Onboarding & Shell Screens M3 Expressive Audit

## Working Directory & Identity
- Working Directory: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_settings_3`
- Role: Codebase Explorer & M3 Expressive Inspector (Settings, Onboarding & Screens)
- Parent Orchestrator: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/orchestrator_3`

## Mandatory Reference Documents
- `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/ORIGINAL_REQUEST.md` (read completely first)
- `/Users/saadhjawwadh/Documents/Code/Note taking/AGENTS.md` (authoritative invariants and design tokens)
- `/Users/saadhjawwadh/Documents/Code/Note taking/.agent/map.md` (codebase map)
- Relevant Skills: `/Users/saadhjawwadh/Documents/Code/Note taking/.agent/skills/Onboarding-Expert/SKILL.md`, `/Users/saadhjawwadh/Documents/Code/Note taking/.agent/skills/UI-UX-Specialist/SKILL.md`

## STRICT NON-DESTRUCTIVE GUARDRAIL
- ZERO SOURCE CODE MODIFICATIONS (`git status` must remain 100% clean and pristine).
- All inspection is strictly read-only.

## Scope of Inspection
Inspect all files in `lib/features/settings/` and `lib/screens/`:
- `lib/screens/` (`settings_screen.dart`, `app_lock_screen.dart`, `changelog_screen.dart`, `backup_screen.dart`, `onboarding_screen.dart`, `whats_new_sheet.dart`, etc.)
- `lib/features/settings/presentation/` (all settings sub-screens, sheets, hero cards, and widgets)

## Evaluation Dimensions
1. **Surface Elevation Hierarchy**: 5 solid surface container levels (`surfaceContainerLowest` to `surfaceContainerHighest`). Confirm complete absence of `BackdropFilter` or frosted glass blurs across all settings and shell screens.
2. **Shape Scale Hierarchy**: Stadium pills (1000dp) for CTA buttons, tag pills, theme chips; Squircles (12-16dp for setting cards, 28dp for dialogs/sheets); connected corner morphing in grouped setting list items.
3. **Motion & Physics**: Spring physics tokens on switches/toggles/sheets, page transition curves.
4. **Touch & Accessibility**: Minimum 48x48dp hit targets, `Semantics(button: true)`.
5. **Settings Invariants**: `SettingsHeroCard` dynamic opacity (50-55% light, 20-22% dark with 1.2px accent border), on-device AI gating strictly on `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`), full-screen onboarding wizard replayability, ignoreNextResumeLock on native dialogs/file pickers.

## Output Deliverables
Write a detailed report to `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_settings_3/report.md` with:
- Executive Summary & Compliance Score (0-100%)
- Exact file paths and line ranges for all findings (Compliant, Deviant, Technical Debt)
- Detailed inventory of any remaining hardcoded values, legacy patterns, or visual inconsistencies
- Concrete recommendations and actionable roadmap for Settings & Shell Screens

## 2026-09-16T04:50:14Z

You are the Settings & Screens Explorer.
Your working directory is `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_settings_3`.
Your parent orchestrator is `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/orchestrator_3` (conversation ID: 6ec8d34f-5c83-44cf-b500-0dacec388c7d).

MANDATORY FIRST STEP:
Read `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/ORIGINAL_REQUEST.md` completely.
Read `/Users/saadhjawwadh/Documents/Code/Note taking/AGENTS.md` and `.agent/map.md`.
Read your task dispatch file at `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_settings_3/DISPATCH.md`.

STRICT NON-DESTRUCTIVE GUARDRAIL:
- ZERO SOURCE CODE MODIFICATIONS (`git status` must remain 100% clean and pristine).
- Read-only inspection and analysis only.

Perform a thorough inspection of all files in `lib/features/settings/` and `lib/screens/` (`settings_screen.dart`, `app_lock_screen.dart`, `changelog_screen.dart`, `backup_screen.dart`, `onboarding_screen.dart`, `whats_new_sheet.dart`, etc.).
Evaluate against:
- 5 solid surface container levels, zero BackdropFilter/frosted glass blurs.
- Shape scale hierarchy: Stadium pills (1000dp) for buttons/pills; Squircles (12-16dp for setting cards, 28dp for dialogs/sheets); connected corner morphing in grouped setting lists.
- Touch & Accessibility: >= 48x48dp hit targets, `Semantics(button: true)`.
- Settings Invariants: `SettingsHeroCard` dynamic opacity (50-55% light, 20-22% dark with 1.2px accent border), on-device AI gating strictly on `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`), full-screen onboarding wizard replayability, ignoreNextResumeLock on native dialogs/file pickers.

Output: Write your complete, structured findings to `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_settings_3/report.md` and `handoff.md`.
When finished, send a message to your parent with a concise summary and path to your report.
