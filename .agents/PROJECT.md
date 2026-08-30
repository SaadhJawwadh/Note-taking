# Project: Everything App Multi-Module Audit & Improvement Blueprint

## Architecture
Everything App is an offline-first Flutter application featuring:
- Notes & Rich Text Editor (`lib/features/notes/`)
- Financial Manager & Split Bills (`lib/features/finances/`)
- Health Tracker & Cycle Predictions (`lib/features/health/`)
- Settings, App Lock, Backups & Onboarding (`lib/features/settings/`)
- Zero-Cloud P2P Device Sync Engine (`lib/features/sync/`)
- Core Design System & Shared Primitives (`lib/core/`)
- Encrypted SQLite with WAL mode (`lib/data/`)
- Background Services, Isolates & Hardware AI (`lib/services/`, `android/`)

## Feature Inventory
| # | Feature Domain | Scope Description | Milestone | Source |
|---|----------------|-------------------|-----------|--------|
| 1 | Notes Module | Delta sanitization, selection clamping, attribute scope invariants, dirty state, trash auto-purge (7-day lifecycle) | M1: Notes Audit | ORIGINAL_REQUEST §R1 |
| 2 | Finances & Split Bills | Dual-account model, SMS regex parsing, recurring rule propagation, offline receipt OCR, WhatsApp sharing, 24h default sync banner | M2: Finances Audit | ORIGINAL_REQUEST §R1 |
| 3 | Health Tracker | Menstrual cycle rolling average prediction, outlier filtering (<15 or >60 days), semantic phase tokens, discreet alerts, biometric privacy | M3: Health Audit | ORIGINAL_REQUEST §R1 |
| 4 | Settings & Onboarding | Full-screen onboarding wizard, replayability, protected auto-backup storage, hardware NPU AICore detection (`isAiActive`), dynamic text scaling | M4: Settings Audit | ORIGINAL_REQUEST §R1 |
| 5 | P2P Sync Engine | Bi-directional LWW 2-way delta merge, immutable deviceId UUIDs, multi-network DeviceEndpoint lists, QR handshake, socket error translation | M5: Sync Audit | ORIGINAL_REQUEST §R1 |
| 6 | Android Quality, Memory & DB | Bitmap downsampling (`cacheWidth`, `errorBuilder`), RSS & swap footprint, imageCache bounds, DEX/R8 full-mode, ProGuard rules, PRAGMA WAL, indexes, 0ms optimistic UI, soft-delete undo parity | M6: Android & DB Audit | ORIGINAL_REQUEST §R2, §R4 |
| 7 | UI/UX & Touch A11y | Design token consistency (`AppLayout`, `colorScheme`), 48x48dp tap targets, borderless frosted chrome (`FrostedGlassSliverAppBar`), 16dp edge symmetry, top bar action order, dynamic hero alphas | M7: UI/UX Audit | ORIGINAL_REQUEST §R3 |
| 8 | Master Synthesis & Roadmap | Comprehensive blueprints, Android Quality & Memory report, UI/UX consistency matrix, conflict-free execution roadmap | M8: Master Synthesis | ORIGINAL_REQUEST Acceptance Criteria |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Notes Domain Audit | Deep audit of `lib/features/notes/` | none | DONE |
| 2 | Finances & Split Bills Audit | Deep audit of `lib/features/finances/` | none | DONE |
| 3 | Health Tracker Audit | Deep audit of `lib/features/health/` | none | DONE |
| 4 | Settings & Onboarding Audit | Deep audit of `lib/features/settings/` | none | DONE |
| 5 | P2P Sync Engine Audit | Deep audit of `lib/features/sync/` | none | DONE |
| 6 | Android Quality, Memory & DB Audit | Audit of `android/`, `lib/data/`, `lib/services/`, image cache & R8 | none | DONE |
| 7 | UI/UX & Touch A11y Audit | Audit across all UI screens for tokens, tap targets, frosted chrome | none | DONE |
| 8 | Master Blueprint & Synthesis | Synthesis of isolated reports, matrices, memory report, and execution roadmap | M1-M7 | DONE |

## Published Artifacts
- Master Blueprint: `.agents/orchestrator_1/MASTER_BLUEPRINT.md`
- Domain Reports: `.agents/orchestrator_1/DOMAIN_AUDIT_REPORTS.md`
- Android Quality & Memory Report: `.agents/orchestrator_1/ANDROID_QUALITY_AND_MEMORY_REPORT.md`
- UI/UX Consistency Matrix: `.agents/orchestrator_1/UI_UX_CONSISTENCY_MATRIX.md`
- Execution Roadmap: `.agents/orchestrator_1/EXECUTION_ROADMAP.md`
- Orchestrator Handoff: `.agents/orchestrator_1/handoff.md`
