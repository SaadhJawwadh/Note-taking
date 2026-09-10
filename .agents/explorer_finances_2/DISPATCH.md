# Dispatch for explorer_finances_2

Target: lib/features/finances/
Role: Read-only exploration and deep audit for Finances domain.
Parent: orchestrator_2

## 2026-09-07T17:47:26Z
Scope: Audit the Finances module in lib/features/finances/ (and related finance services, models, repositories, widgets).
Key Audit Areas:
1. SMS Ingestion & Deduplication
2. Recurring Rule Sync & Propagation
3. Two-Bank Account Cash Flow
4. Split Bills & Shared Debts Integration
5. Memory & Downsampling Bounds
6. Invariant & Design System Alignment (AGENTS.md)
Output Requirements: progress.md, handoff.md, message to parent.
