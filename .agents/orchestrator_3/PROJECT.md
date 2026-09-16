# Project: Comprehensive M3 Expressive Audit & Architectural Assessment

## Architecture & Domain Decomposition
The audit covers 6 orthogonal domains across Everything App:
1. **Core UI & Theming (`lib/core/`)**:
   - `lib/core/theme/app_layout.dart`, `app_theme.dart`
   - `lib/core/ui/` (`app_card.dart`, `app_bottom_sheet.dart`, `app_chip.dart`, `app_dialog.dart`, `expressive_sliver_app_bar.dart`, `expressive_split_button.dart`, `expressive_wavy_slider.dart`, `expressive_wavy_progress.dart`, `expressive_shape_morph_indicator.dart`, `app_morphing_fab.dart`)
   - `lib/core/routes/app_router.dart`
2. **Notes Module (`lib/features/notes/` & `lib/screens/home_screen.dart`)**:
   - `lib/screens/home_screen.dart`
   - `lib/features/notes/presentation/` (`notes_screen.dart`, `note_editor_screen.dart`, `note_card.dart`, `notes_search_bar.dart`, `notes_selection_toolbar.dart`, `tag_chip_bar.dart`, `trash_screen.dart`, `folder_picker_sheet.dart`, etc.)
3. **Finances & Split Bills (`lib/features/finances/`)**:
   - `financial_manager_screen.dart`, `transaction_editor_screen.dart`, `budget_screen.dart`, `split_bills_screen.dart`, `settle_up_sheet.dart`, `receipt_camera_sheet.dart`, `sms_sync_banner.dart`, `financial_hero_card.dart`, `category_chips.dart`, `account_selector.dart`, etc.
4. **Health Tracker (`lib/features/health/`)**:
   - `period_tracker_screen.dart`, `cycle_history_screen.dart`, `symptom_logger_sheet.dart`, `cycle_hero_card.dart`, `phase_guide_sheet.dart`, `ovulation_indicator.dart`, etc.
5. **Settings & Screens (`lib/features/settings/` & `lib/screens/`)**:
   - `settings_screen.dart`, `backup_screen.dart`, `app_lock_screen.dart`, `changelog_screen.dart`, `whats_new_sheet.dart`, `onboarding_screen.dart`, `preferences_sheet.dart`, etc.
6. **P2P Sync Engine (`lib/features/sync/`)**:
   - `sync_screen.dart`, `device_pairing_sheet.dart`, `qr_scanner_sheet.dart`, `sync_status_card.dart`, `peer_list_tile.dart`, etc.

## Evaluation Dimensions (M3 Expressive & System Invariants)
- **Surface Elevation Hierarchy**: 5 solid surface container levels (`surfaceContainerLowest` to `surfaceContainerHighest`), ZERO frosted glass / `BackdropFilter` blurs.
- **Shape Scale Hierarchy**: Stadium pills (1000dp) for chips/capsules/buttons, Squircles (12-16dp for cards, 28dp for dialogs/sheets), and connected corner morphing.
- **Motion & Physics**: Spring physics tokens (`springFast`, `springSpatial`, `springBouncy`) and decelerate curves.
- **Touch & Accessibility**: Hit targets >= 48x48dp, semantic labels, 1px accent chart borders, authentic currency & category symbols.
- **System Invariants**: Invariants 1-15 from `AGENTS.md` (e.g., FAB clearance 96dp, universal morphing FAB, tonal scope pills, top bar action order, two-bank accounts, soft-delete parity, WAL mode, etc.).

## Execution Plan
| # | Step | Assignee | Deliverable | Status |
|---|------|----------|-------------|--------|
| 1 | Core UI & Theme Audit | `teamwork_preview_explorer` (core) | `.agents/explorer_core_3/report.md` | IN_PROGRESS |
| 2 | Notes Module Audit | `teamwork_preview_explorer` (notes) | `.agents/explorer_notes_3/report.md` | IN_PROGRESS |
| 3 | Finances & Split Bills Audit | `teamwork_preview_explorer` (finances) | `.agents/explorer_finances_3/report.md` | IN_PROGRESS |
| 4 | Health Tracker Audit | `teamwork_preview_explorer` (health) | `.agents/explorer_health_3/report.md` | IN_PROGRESS |
| 5 | Settings & Screens Audit | `teamwork_preview_explorer` (settings) | `.agents/explorer_settings_3/report.md` | IN_PROGRESS |
| 6 | P2P Sync Engine Audit | `teamwork_preview_explorer` (sync) | `.agents/explorer_sync_3/report.md` | IN_PROGRESS |
| 7 | Synthesis & Master Roadmap | Orchestrator | `M3_EXPRESSIVE_COMPLIANCE_AND_ROADMAP.md` | PLANNED |
| 8 | Handoff & Notification | Orchestrator | `handoff.md` + `send_message` to Sentinel | PLANNED |
