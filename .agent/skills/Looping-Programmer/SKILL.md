---
name: Looping-Programmer
description: Universal autonomous looping software engineer for any codebase. Executes a 4-tier audit-and-evolve loop: (1) Auto-fixes bugs, architectural debt, QA & DevOps pipelines; (2) Feature refinement, refactoring & performance optimization with green test gates; (3) UI/UX, accessibility & live modern design paradigm web research with interactive grilling; (4) Multi-tiered roadmap synthesis from small quick-wins to mighty architectural leaps with interactive feature selection.
---

# Looping-Programmer (Universal Autonomous Loop Engineer)

> An autonomous, rigorous, multi-tiered engineering loop designed to evaluate, stabilize, optimize, elevate, and evolve **any codebase** across four progressive cycles with built-in test gates, live modern design research, and interactive grilling.

When invoked, execute the following phased workflow systematically.

---

## 🔁 The 4-Tier Autonomous Engineering Loop

```
┌─────────────────────────────────────────────────────────────┐
│ Tier 0: Recon & Baseline Mapping (Stack, CI, Invariants)    │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Tier 1: System Stability, QA, Architectural & DevOps Fixes  │
│  - Compile / Lint / Test Suite Baseline                     │
│  - Security, Memory, Concurrency & Anti-Pattern Elimination │
│  - Build scripts, CI/CD, Containerization, Dependency Audit │
│  - [AUTO-FIX & VERIFY GREEN TESTS]                          │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Tier 2: Existing Feature Optimization & Hardening           │
│  - Performance profiling, state hygiene, query indexing     │
│  - Dead code pruning, DRY abstractions, edge case guards    │
│  - [AUTO-REFINE & VERIFY GREEN TESTS]                       │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Tier 3: UI/UX, Live Paradigm Research & Grilling Gate       │
│  - Token consistency, typography, responsive a11y (WCAG)    │
│  - Real-time web search: modern design posts, official docs │
│  - Interactive Alignment Interview (/grill-me gate)         │
│  - [PAUSE FOR USER CONFIRMATION VIA MODAL]                  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ Tier 4: Strategic Evolution Roadmap (Small to Mighty)       │
│  - Level 1: Quick-Win Delights (< 1 hour)                   │
│  - Level 2: High-Impact Enhancements (1–3 days)             │
│  - Level 3: Mighty Breakthroughs (Game-changing features)   │
│  - [INTERACTIVE FEATURE CHOOSER -> IMMEDIATE BUILD]         │
└─────────────────────────────────────────────────────────────┘
```

---

## Tier 0: Codebase Recon & Architecture Mapping (Read-Only)

Before modifying code:
1. **Manifest & Dependency Inspection**: Read `package.json`, `pubspec.yaml`, `Cargo.toml`, `pyproject.toml`, `go.mod`, or `build.gradle` to understand runtime, framework, and ecosystem versions.
2. **Rule & Map Discovery**: Check for `AGENTS.md`, `CLAUDE.md`, `.agent/map.md`, or README files to identify documented invariants, project standards, and domain structures.
3. **Static Baseline Execution**: Run the project's native linter and test suite (e.g., `flutter analyze`, `npm test`, `cargo test`, `pytest`) to establish a known baseline without altering code.

---

## Tier 1: Bugs, Architectural Debt, QA & DevOps Fixes (Autonomous Auto-Fix)

Execute systematic diagnostics and remediation:

### 1.1 Bugs & Logic Flaws
* Trace unhandled promises, uncaught exceptions, null dereferences, and race conditions.
* Verify error boundary containment and graceful degradation on network/storage failures.

### 1.2 Architectural Health
* Eliminate circular dependencies and tight coupling across domain layers.
* Enforce Single Source of Truth (SSOT) state management and clean separation of concerns (Repositories vs. Presentation vs. Data Sources).

### 1.3 QA & Test Suite Fortification
* Fix broken or flaky unit and integration tests.
* Add coverage for uncovered edge cases, boundary conditions, and mock failures.

### 1.4 DevOps & Build Pipeline
* Audit Dockerfiles, CI/CD workflows (`.github/workflows/`), build scripts, and environment variable sanitation.
* Resolve dependency vulnerabilities, deprecation warnings, and bloated bundle configurations.

> **Verification Gate**: Re-run the project test suite and linter. Only proceed to Tier 2 when 0 warnings/errors exist and all tests pass.

---

## Tier 2: Existing Feature Optimization & Refinement (Autonomous Auto-Refine)

Focus on polishing and hardening existing capabilities:

### 2.1 Performance & Resource Hygiene
* Profile and eliminate unnecessary re-renders, expensive compute passes, and unindexed database queries.
* Ensure memory leak prevention: cancel timers, dispose controllers/subscriptions, and release streams.

### 2.2 Refactoring & Code Economy
* Prune dead code, unused assets, orphaned styles, and redundant re-exports.
* Consolidate duplicated logic into reusable utility modules and domain services.

### 2.3 Non-Regression Verification
* Run linter and test suite after each atomic refactoring step to maintain 100% build green status.

---

## Tier 3: UI/UX, Live Modern Paradigm Research & Grilling Gate (Interactive Gate)

Elevate visual aesthetics, interaction fluidity, and accessibility:

### 3.1 Design System & Aesthetic Audit
* **Token Consistency**: Verify adherence to centralized spacing scales, typography hierarchy, border radii, and color palettes.
* **Modern Polish**: Ensure tactile touch targets ($\ge 48\text{dp}$), micro-interactions, smooth spring animations, and cohesive light/dark theme contrast.
* **Accessibility (a11y)**: Audit semantic labels, contrast ratios (WCAG 2.1 AA/AAA), screen reader accessibility, and keyboard navigation.

### 3.2 Live Research into Modern Best Practices
* Use `search_web` to search official framework documentation, design systems (e.g., Material 3 Expressive, iOS HIG, modern web fluid dynamics), and authoritative engineering blogs for state-of-the-art patterns relevant to the project's tech stack.
* Synthesize concrete, framework-idiomatic aesthetic improvements.

### 3.3 Interactive Alignment Gate (`/grill-me`)
* Formulate concrete design overhaul proposals.
* Present the architectural trade-offs and options to the user via the `ask_question` tool to grill and confirm aesthetic decisions before executing visual transformations.

---

## Tier 4: Multi-Tier Innovation Roadmap & Interactive Chooser (Small to Mighty)

Synthesize a feature expansion roadmap categorized by scope and impact:

| Level | Classification | Typical Scope | Characteristics |
|---|---|---|---|
| **Level 1** | **Quick-Win Delights** | < 1 hour | Haptic feedback, keyboard shortcuts, smart defaults, export shortcuts. |
| **Level 2** | **High-Impact Enhancements** | 1–3 days | Offline sync polish, batch operations, search filters, widget integrations. |
| **Level 3** | **Mighty Breakthroughs** | 1–2 weeks+ | On-device AI/NPU pipelines, zero-knowledge sync, peer-to-peer mesh, realtime collaborative canvases. |

For each proposed feature, specify:
1. **User Problem & Value Hypothesis**
2. **Technical Architecture & Data Model Impact**
3. **Implementation Complexity & Risk Profile**

### 4.1 Interactive Chooser & Immediate Build
* Present the curated Small-to-Mighty roadmap to the user via `ask_question` with selectable options.
* Upon user selection, seamlessly enter planning and execution mode to immediately implement the chosen feature.

---

## 🛡️ Autonomous Execution Invariants

1. **Permission Gate for Git Operations**: Never run `git commit`, `git tag`, or `git push` without explicit user confirmation.
2. **Incremental Atomicity**: Make focused, test-verified changes one tier at a time.
3. **Token & Context Economy**: Use ripgrep and targeted slice views; do not mass-read generated folders, lockfiles, or build artifacts.
4. **Zero Magic Values**: All UI changes must derive from established design tokens or theme definitions.
