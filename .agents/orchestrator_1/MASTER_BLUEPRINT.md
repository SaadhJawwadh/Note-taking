# Everything App — Master Codebase Audit & Improvement Blueprint

**Master Architecture Index & Synthesis Document**  
**Author**: Project Orchestrator (`orchestrator_1`)  
**Workspace Root**: `/Users/saadhjawwadh/Documents/Code/Note taking`  
**Date**: 2026-08-30  
**Status**: COMPLETE (Audit & Planning Phase)

---

## 1. Master Architectural Assessment

The Everything App codebase has been evaluated against Google Play 2026 Android Quality & Memory Optimization standards, Material 3 Expressive design tokens, and the Single Source of Truth invariants in `AGENTS.md`.

### Core Strengths:
1. **Security & Offline-First Foundation**: SQLCipher AES-256 database encryption with SQLite Write-Ahead Logging (`PRAGMA journal_mode = WAL;`) and Android KeyStore / iOS Keychain token storage.
2. **Material 3 Expressive Design System**: Seamless borderless frosted glass top bars (`sigma 16.0`), dynamic Material You wallpaper palettes, OLED pitch-black dark mode, and standardized atomic primitives (`AppCard`, `AppBottomSheet`, `AppChip`, `AppDialog`).
3. **Hardware-Aware On-Device Intelligence**: Clean hardware AI capability gating via `settings.isAiActive` (`_useOnDeviceAi && _isDeviceAiSupported`) preventing crashes on non-NPU hardware.
4. **Resilient Financial Accounting**: Strict Two-Bank Account model (`daily` operating vs `savings` vault), 24-hour default SMS scan lookback with non-blocking chunking, 100% offline receipt OCR, and permanent tombstone deletion safety.
5. **Zero-Cloud P2P Device Sync**: Peer-to-peer Wi-Fi synchronization with AES-256-CBC encryption, immutable UUID identities, and LWW 2-way delta merge with 5-second clock skew tolerance.

---

## 2. Deliverables & Artifact Index

The comprehensive audit deliverables are organized into decoupled, high-signal reports in `.agents/orchestrator_1/`:

| Deliverable Document | Absolute Path | Core Contents & Scope |
|---|---|---|
| **Domain-Specific Audit Reports** | [`DOMAIN_AUDIT_REPORTS.md`](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agents/orchestrator_1/DOMAIN_AUDIT_REPORTS.md) | Isolated, zero-conflict findings and code blueprints for Notes, Finances, Health, Settings/Onboarding, Sync, and Core UI. |
| **Android Quality & Memory Optimization Report** | [`ANDROID_QUALITY_AND_MEMORY_REPORT.md`](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agents/orchestrator_1/ANDROID_QUALITY_AND_MEMORY_REPORT.md) | Bitmap memory bounding (`cacheWidth`), global image cache bounds (100MB/100 entries), R8 full-mode ProGuard keep rules, DEX icon tree-shaking, and SQLite WAL indexing. |
| **UI/UX Consistency Matrix** | [`UI_UX_CONSISTENCY_MATRIX.md`](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agents/orchestrator_1/UI_UX_CONSISTENCY_MATRIX.md) | Exhaustive token mapping (58 static colors to `AppSemanticColors`/`colorScheme`), 48x48dp touch accessibility bounds, header symmetry, hero container alphas, and Rule 41 Unicode emoji replacements. |
| **Conflict-Free Execution Roadmap** | [`EXECUTION_ROADMAP.md`](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agents/orchestrator_1/EXECUTION_ROADMAP.md) | 5-phase sequential execution schedule with strict file ownership isolation boundaries, gate verification commands, and backward compatibility invariants. |

---

## 3. High-Priority Remediation Summary

| Ref # | Module | Critical Discovery | Remediation Blueprint | Impact |
|---|---|---|---|---|
| **N-01** | Notes | `NoteEditorScreen:167` strips inline styles if operation contains `\n` | Implement non-destructive `RichTextUtils.sanitizeDelta()` | Preserves bold/italic text styles across reloads |
| **N-02** | Notes | Right-to-left selection causes negative length and `RangeError` on image/table insert | Implement `_getNormalizedSelectionRange()` | Eliminates runtime crash during editing |
| **N-04** | Notes | `clearOldTrash()` deletes rows without writing to `deleted_notes` | Insert records into `deleted_notes` within atomic transaction | Prevents auto-purged notes from resurrecting on P2P sync |
| **SY-01** | P2P Sync | Split bills omitted from `BackupService` JSON and `SyncMergeService` | Add split bill/participant tables to backup & delta merge | Prevents data loss of split debts across sync and backup restore |
| **SY-02** | P2P Sync | HTTP stream decoder lacks timeout protection | Wrap with `.timeout(const Duration(seconds: 10))` | Prevents sync client hanging on sleeping peer device |
| **HT-01** | Health | `PeriodTrackerProvider.loadData()` unconditionally sets `_isLoading = true` | Add `{bool showLoading = false}` parameter | Eliminates skeleton screen flash on symptom logging |
| **ST-01** | Settings | Missing `ignoreNextResumeLock()` before 5 native pickers/shares | Call `AppLockScreen.ignoreNextResumeLock()` | Prevents app lock overlay cancelling active file pickers / scans |
| **AQ-01** | Android | Missing `cacheWidth` in `ReceiptScannerSheet:152` | Add `cacheWidth: 300` | Reduces image decode RAM from ~96MB to ~360KB (>98% drop) |
| **AQ-02** | Android | Missing R8 keep rules for 5 native dynamic plugins | Update `android/app/proguard-rules.pro` | Prevents reflection class stripping in release APK builds |
| **UX-01** | UI/UX | 6 micro-control categories under 48x48dp hit bounds | Wrap with `BoxConstraints(minWidth: 48, minHeight: 48)` + `Semantics` | Full compliance with Android accessibility guidelines |

---

## 4. Verification & Baseline Status

- **Static Analysis**: `flutter analyze` completed with **0 errors, 0 warnings, 0 hints**.
- **Automated Test Suites**: `flutter test` completed with **177 / 177 tests passing (100% green)**.
- **Backward Compatibility**: All proposed blueprints preserve existing SQLite schemas, JSON contracts, and public provider APIs without breaking changes.
