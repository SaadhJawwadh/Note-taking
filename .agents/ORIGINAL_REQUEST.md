# Original User Request

## Initial Request — 2026-08-30T07:40:49Z

Conduct a rigorous, parallel multi-module audit of the entire Everything App codebase (/Users/saadhjawwadh/Documents/Code/Note taking). Formulate decoupled, conflict-free improvement plans, bug fixes, and optimization blueprints across all feature domains (Notes, Finances & Split Bills, Health Tracker, Settings & Onboarding, P2P Sync, and Core Infrastructure) without breaking existing functionality or modifying source code in this planning phase.

Working directory: /Users/saadhjawwadh/Documents/Code/Note taking
Integrity mode: development

Reference Material:
- Android Quality & Memory Optimization / Device Migration: https://android-developers.googleblog.com/2026/08/app-quality-memory-optimization-secure-onboarding.html
- Single Source of Truth & Architecture Invariants: AGENTS.md and .agent/map.md
- Core Skills: App-Feature-Expert, UI-UX-Specialist, Onboarding-Expert, Tester, Loop-Engineer

## Requirements

### R1. Domain-Specific Modular Feature Audits (Zero-Conflict Work Packages)
Conduct an in-depth audit of each feature module and synthesize independent, modular work packages:
- Notes Module (lib/features/notes/): Rich text Quill Delta sanitization, selection clamping, attribute scope invariants, dirty state management, and trash auto-purge (7-day lifecycle).
- Finances & Split Bills (lib/features/finances/): Dual-account model (daily vs savings), SMS regex parsing & sandbox parity, recurring rule propagation, 100% offline receipt OCR, WhatsApp sharing, and 24h default sync banner.
- Health Tracker (lib/features/health/): Menstrual cycle rolling average prediction algorithms, outlier filtering (<15 or >60 days), semantic phase tokens, discreet notifications, and biometric privacy masking.
- Settings & Onboarding (lib/features/settings/): Full-screen onboarding wizard (OnboardingScreen), replayability, resilient protected auto-backup storage, hardware NPU AICore detection (isAiActive), and dynamic text scaling.
- P2P Sync Engine (lib/features/sync/): Bi-directional LWW 2-way delta merge, immutable deviceId UUIDs with multi-network DeviceEndpoint lists, QR pairing handshake integrity, and socket error translation.

### R2. Android Quality, Memory & DEX Optimization Standards
Evaluate and align the codebase against the latest Google Play performance & memory thresholds:
- Bitmap Memory Usage & Downsampling: Audit all Image.file, Image.network, and Image.asset usages to enforce bounded cacheWidth (e.g. 1080 for note body embeds, 400 for list cards) and fallback errorBuilder containers.
- Dynamic Anonymous RSS & Swap Footprint: Profile image cache bounds (maximumSizeBytes = 100MB, maximumSize = 100), stream/timer disposal, and background isolate memory hygiene.
- DEX Code & R8 Optimization: Verify R8 full-mode configuration (android.enableR8.fullMode=true), -keep rule precision in proguard-rules.pro, and elimination of dynamic IconData code-point allocations.

### R3. UI/UX Consistency, Material 3 Expressive & Touch Accessibility
Audit all user interface surfaces for complete design token consistency:
- Single Source of Truth Tokens: Eliminate all magic numbers, hardcoded paddings, static colors, and inline radii in favor of AppLayout and Theme.of(context).colorScheme.
- Touch Target Accessibility: Enforce minimum 48x48dp tap targets (BoxConstraints(minWidth: 48, minHeight: 48) and Semantics(button: true)) across all interactive micro-elements.
- Seamless Chrome & Symmetry: Enforce borderless frosted glass top bars (FrostedGlassSliverAppBar, sigma 16.0) and bottom navigation bars, 16dp edge margin symmetry, and the canonical 3-slot top app bar action hierarchy ([Contextual Action] -> [⋮ Tools] -> [⚙️ Settings]).
- Dynamic Hero Card Opacities: Validate dynamic container alphas (50%–55% Light Mode, 20%–22% Dark Mode) with subtle 1.2px accent borders.

### R4. Database Hot-Paths, 0ms Optimistic UI & Robustness
- SQLite WAL Mode & Indexing: Verify PRAGMA journal_mode = WAL; via db.rawQuery(), check column indexing on hot query paths, and validate single-quote migration syntax.
- 0ms Immediate State Mutation: Guarantee all user actions (delete, undo, pin, archive, toggle) update in-memory lists synchronously before background SQLite writes.
- Soft-Delete Undo Parity: Ensure undo handlers invoke restoreTransaction(id) / restoreNote(id) rather than re-inserting records.

## Acceptance Criteria

### Comprehensive Audit Blueprint
- [ ] Each domain module (Notes, Finances, Health, Settings/Onboarding, Sync, Core UI) has an isolated findings report with exact file links and zero cross-module dependency coupling.
- [ ] A dedicated Android Quality & Memory Optimization report details bitmap bounding, R8 hygiene, and memory pressure safeguards.
- [ ] UI/UX consistency matrix lists all non-compliant touch targets, magic numbers, or header asymmetries with exact token replacements from AppLayout / AppTheme.
- [ ] All proposed changes preserve 100% backward compatibility and passing status for existing test suites (flutter test) and static analysis (flutter analyze).
- [ ] A conflict-free execution roadmap specifies the exact order and isolation boundaries so feature teams can implement fixes independently in subsequent phases.
