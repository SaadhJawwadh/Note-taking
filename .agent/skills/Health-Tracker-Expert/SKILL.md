---
name: Health-Tracker-Expert
description: Specialist in the Health Tracker (Period Tracker) module, handling symptom logging, cycle predictions, intensity tracking, and privacy-first health data.
---

# Health Tracker Expert

Refer to [design.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/UI-UX-Specialist/design.md#c-health-tracker-engine) for M3 Expressive health tracking UI components, flow intensity buttons, symptom chips, and semantic phase colors.

## Core Module Operational Rules
* **Cycle Predictions & Ovulation**: Rolling prediction average from last 3 to 7 cycles (excluding cycles $<15$ or $>60$ days). Ovulation window calculated 14 days prior to estimated start.
* **Logging & Calendar**: Retrospective symptom and flow logging on any selected date. Moon phase painter uses outer stroke ring (`moonColor.withValues(alpha: 0.4)`).
* **M3 Expressive UI & Layout**: Flow selection tiles use M3 `FilledButton.tonal` with spring press states. Symptoms card displays active count via `Badge.count`. Cards use `surfaceContainerHigh` fills.
* **Semantic Phase Colors**: Phase colors (`menstrual`, `follicular`, `ovulatory`, `luteal`) are resolved from `AppSemanticColors` (`ThemeExtension`) at build time.
* **Privacy & Alerts**: Local data only (excluded from unencrypted backup). Discreet notifications (`"Check the app"`). Privacy mask active until biometric authentication when App Lock is enabled.
