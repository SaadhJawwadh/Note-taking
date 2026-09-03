---
name: Product-Design-Engineering
description: Master product design engineering and interaction psychology distilled from Enrico Tartarotti. Synthesizes the 7 Levels of Tech Design, 100ms touch disambiguation, kinetic latency masking, intentional friction, direct manipulation, generative UI, and high-trust choice architecture into actionable engineering heuristics.
---

# Product Design Engineering & Interaction Psychology

Distilled from the design breakdowns, technical essays, and product philosophies of **Enrico Tartarotti** (tech founder, former Senior Product Manager at Amazon & Maze). This skill bridges interaction psychology, software engineering, and tactile ergonomics to craft intuitive, high-agency user experiences.

---

## 1. The 7 Levels of Tech Design Framework

Every digital product operates on seven interconnected levels. Flaws at any level degrade the entire user experience. Use this hierarchy to diagnose UX friction and architect new features:

```
┌────────────────────────────────────────────────────────┐
│ Level 7: Product Vision & Soul (Human Dignity & Purpose)│
├────────────────────────────────────────────────────────┤
│ Level 6: Product Strategy & Reframing (New Mental Model)│
├────────────────────────────────────────────────────────┤
│ Level 5: Structural Logic & Atomic Modularity (Data/UX)│
├────────────────────────────────────────────────────────┤
│ Level 4: Defaults & Choice Architecture (The Default)  │
├────────────────────────────────────────────────────────┤
│ Level 3: Technical Innovation & Hardware Synergy       │
├────────────────────────────────────────────────────────┤
│ Level 2: Interaction Physics & Behavioral Dynamics     │
├────────────────────────────────────────────────────────┤
│ Level 1: Micro-Details & Optical Integrity             │
└────────────────────────────────────────────────────────┘
```

### Level 1: Micro-Details & Optical Integrity
* **The "Unseen Precision" Principle**: Users cannot articulate sub-pixel misalignments or inconsistent stroke weights, but their nervous system subconsciously interprets them as unreliability or cheapness.
* **Optical vs Geometric Balance**: Center icons and glyphs according to visual weight, not bounding-box mathematical centers (e.g. play triangles need slight right-shifting; chevrons need optical vertical centering).
* **High-Contrast Certainty**: Surface borders, dividers, and scrims must use subtle alpha blending (`1px outlineVariant` at 20–35% alpha) to provide spatial separation without visual noise.

### Level 2: Interaction Physics & Behavioral Dynamics
* **The 100ms Touch Disambiguation**: Capacitive touchscreens enforce an intentional ~100ms ambiguity window between a *Tap* and a *Scroll*.
  - *Consumption Bias*: Touch OSs prioritize scrolling velocity over tapping precision.
  - *Engineering Countermeasure*: For creation interfaces, provide instant press down-states (within 16ms), generous tap-target bounds ($\ge 48 \times 48\text{dp}$), and clear touch cancellation buffers.
* **Kinetic Momentum & Elastic Boundaries**: Never hit hard stops. Scroll boundaries, swipe dismissals, and bottom sheets must use elastic rubber-banding and spring physics (`Curves.easeOutBack` or damping ratios) to mimic physical mass.
* **Context-Aware Behavioral Guards**: Intercept dangerous actions intelligently (e.g. banking apps muting alerts or hiding sensitive numbers during phone calls; editors ignoring accidental edge palms).

### Level 3: Technical Innovation & Hardware Synergy
* **Hardware-Aware UI Gating**: Capabilities (display refresh rates, NPU AI Core, haptic motors, biometrics) must be queried directly from hardware. Never expose UI controls for unsupported hardware (e.g., gate AI buttons on `settings.isAiActive`).
* **Zero-Distance Execution**: Keep critical state queries local. Zero-latency SQLite WAL mode writes beat network roundtrips every time.
* **Frame Budget Discipline**: Animations and gestures must lock to the hardware refresh rate (60Hz / 120Hz ProMotion). Wrap heavy graphics in `RepaintBoundary` and isolate list items.

### Level 4: Defaults & Choice Architecture (The Default Effect)
* **The 95% Default Rule**: Over 95% of users never change default settings. The default configuration *is* the product for almost all users.
* **Intentional vs Toxic Friction**:
  - *Remove Friction* from high-frequency, user-empowering loops (auto-saving notes, instant SMS ingestion, quick search).
  - *Inject Friction* into destructive or irreversible actions (deleting ledgers, wiping databases, master P2P overwrites) using multi-step confirmation modals with explicit verbal commitments.
* **Curated Simplicity (Hick’s Law)**: Do not paralyze users with infinite options. Group choices into smart, contextual defaults with progressive disclosure for power users.

### Level 5: Structural Logic & Atomic Modularity
* **Toolmaker vs Consumer (The Notion Invariant)**: Transform users from passive consumers into creative toolmakers by providing atomic, composable building blocks (tags, chips, blocks, metadata) instead of rigid hierarchical silos.
* **Orthogonal Primitives**: Decouple data categories from presentation modes. Notes can have folders, tags, colors, and dates independently without forced nesting.
* **Lossless Reversibility**: Every state transition must be undoable. Implement soft-deletes (`deletedAt` tombstones), undo SnackBars, and non-destructive merges.

### Level 6: Product Strategy & Reframing
* **Reframing Constraints as Superpowers**:
  - *Offline-First / Zero-Cloud*: What seems like a limitation (no cloud servers) is reframed as absolute privacy, zero latency, and perpetual data ownership.
  - *Local P2P Sync*: Reframes sync from an invisible cloud black-box into a tactile, peer-to-peer pairing ritual.
* **Asynchronous Velocity**: Convert synchronous bottlenecks into background jobs with optimistic local updates.

### Level 7: Product Vision & Soul
* **User Agency Over Extractive Metrics**: Reject dark patterns, infinite slot-machine loops, and fake urgency. Software should respect the user’s time, attention, and cognitive peace.
* **Calm Technology**: The best interface disappears when not in use. It surfaces high-density signal when needed and gets out of the way.

---

## 2. Kinetic Latency Masking & The Psychology of Waiting

Unoccupied time feels significantly longer than occupied time. Ambiguity generates user anxiety. Apply Tartarotti’s latency heuristics across all asynchronous operations:

| Latency Window | User Perception | Engineering Pattern |
| :--- | :--- | :--- |
| **0 – 100 ms** | Instantaneous / Direct Manipulation | Immediate visual state update; zero spinners; zero delays. |
| **100 – 300 ms** | Noticeable Delay | Tactile micro-press feedback (`BouncingWidget` + `HapticFeedback.lightImpact`). |
| **300 ms – 1.5 s** | Processing Time | **Optimistic UI**: Mutate local state immediately; display smooth pulsing skeleton loaders or subtle inline activity rings; sync in background. |
| **1.5 s – 5.0 s** | Heavy Computation | **Deterministic Progress**: Display exact-count progress banners (e.g. `Processing message 14 of 50...`) with a 1-tap `[ Cancel ]` button. |
| **> 5.0 s** | System Stall Risk | Non-blocking background worker with persistent status indicators and floating undo SnackBar upon completion. |

### The "Artificial Pacing" Paradox
* When executing heavy algorithmic tasks (e.g. biometric security verification, AI spend categorization, backup generation), instantaneous sub-10ms results can paradoxically lower perceived thoroughness and trust.
* Provide deliberate, rhythmic animation stages (Scan $\rightarrow$ Analyze $\rightarrow$ Verify $\rightarrow$ Complete) to communicate computational rigor and integrity.

---

## 3. The Architecture of Attention & Notifications

Notifications are attention-stealing interrupts. Structure every alert according to Tartarotti's 3 Layers:

1. **High Specificity Over Vague Urgency**:
   - *Bad (Anxiety Trap)*: `"You have an upcoming transaction."`
   - *Good (High Signal)*: `"$45.00 gym membership renews tomorrow from Daily Account."`
2. **Predictable Batching Over Dopamine Jitter**:
   - Never ping users with incremental updates.
   - Batch background tasks into scheduled daily summaries (e.g. daily 8:00 PM SMS auto-sync) or consolidated sync digests.
3. **Ambient Defensive Filtration**:
   - Use on-device intelligence to filter out noise, promotional spam, and duplicate alerts before they ever reach the system notification tray.

---

## 4. Tactility, Physicality & Sound Design

Modern glass screens possess zero natural tactile feedback. Digital interfaces must artificially synthesize physicality:

* **Multi-Stage Mechanical Haptics**:
  - `HapticFeedback.lightImpact()` on selection pills, chip taps, and segment toggles.
  - `HapticFeedback.mediumImpact()` on button presses, floating toolbar actions, and dialog confirmations.
  - `HapticFeedback.heavyImpact()` or vibration bursts on destructive deletions and security blocks.
  - `HapticFeedback.selectionClick()` on scrolling pickers and menu expansions.
* **The "Silent Tech" Antidote**:
  - Silent interfaces cause users to double-tap, question whether their tap registered, and experience fatigue.
  - Pair subtle tactile snaps with visual depth changes (scale bounces, container elevation shifts) to confirm user actions unequivocally.

---

## 5. Post-GUI & Generative UI Principles

Pure text chatboxes are a regression; voice-only interactions fail because human cognition depends on spatial anchors and direct manipulation.

* **Direct Manipulation Core**:
  - Interfaces must allow direct tactile manipulation (swiping to archive, dragging to reorder, pinching to zoom).
* **Dynamic Generative Assembly**:
  - Instead of forcing the user into static, rigid dashboards, assemble UI modules dynamically in response to intent (e.g., searching finances auto-switches to the Ledger tab; scanning a receipt auto-populates split debt cards).
* **The 1984 Invariants**:
  - **Visible State**: Always show what mode the user is in (search active, filter applied, synced).
  - **Immediate Feedback**: Every tap produces an immediate pixel and haptic reaction.
  - **Reversibility**: Everything can be undone with zero fear of data loss.
  - **Spatial Constancy**: Keep key anchors (Settings, Search, Sync) in predictable, muscle-memory positions.

---

## 6. Implementation Checklist for Developers

When designing or refining any screen, feature, or workflow in any digital product or application, verify:

- [ ] **Level 1**: Are all icons optically balanced, tap targets $\ge 48\text{dp}$, and borders subtle 1px outlines?
- [ ] **Level 2**: Does the interaction have elastic spring physics, touch cancellation safety, and immediate down-states?
- [ ] **Level 3**: Is the feature hardware-aware (device capabilities, local storage/database, display refresh rate)?
- [ ] **Level 4**: Is the default setting what 95% of users want? Is destructive friction properly placed?
- [ ] **Level 5**: Can the user undo this? Are data primitives composable and non-destructive?
- [ ] **Level 6**: Does the feature reframe constraints (e.g. offline-first privacy) into a user benefit?
- [ ] **Level 7**: Does this screen treat the user with dignity, eliminating deceptive patterns and raw emoji noise?
