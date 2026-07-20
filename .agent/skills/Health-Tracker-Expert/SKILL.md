---
name: Health-Tracker-Expert
description: Specialist in the Health Tracker (Period Tracker) module, handling symptom logging, cycle predictions, intensity tracking, and privacy-first health data.
---

# Health Tracker Expert

Use this skill when modifying the menstrual calendar, symptoms log, dynamic cycle prediction algorithms, or local predictions notification scheduling.

## 1. Cycle Predictions & Ovulation
* **Predictions Average**: Cycle predictions must compute rolling averages from the last 3 to 7 logs, dynamically filtering out outliers (cycles $<15$ days or $>60$ days).
* **Ovulation Window**: Calculate fertile/ovulation dates exactly 14 days prior to the estimated start date of the next period (standard luteal phase assumption).

## 2. Calendar UI & Logging
* **Retrospective Logging**: Enable users to log symptoms, notes, and flow intensity (Spotting, Light, Medium, Heavy) on any selected past date, not just today's date.
* **Material You Blending**: Integrate soft Material You seed colors for the calendar states.

## 3. Privacy & Alerts
* **Offline Storage**: Health data is completely local and must be excluded from unencrypted backup exports.
* **Discreet Alerts**: Local prediction notifications must use customizable discreet text (e.g. `"Check the app"`) to preserve absolute privacy.

## 3. Theming & Notifications (v2.0)
* **Phase colors are semantic tokens**: menstrual/follicular/ovulatory/luteal come from `AppSemanticColors` (ThemeExtension in `app_theme.dart`) via `_resolvePhaseColor(context)` — never hardcode `Colors.red.shade300` etc. Resolve colors at build time, not in async state computation.
* **Notification id discipline**: period notifications own ids 1-3; reschedule by cancelling those ids only — `cancelAll()` destroys note reminders and other channels.
* **Loading**: use the shared `SkeletonCard` list, not a full-screen spinner.
* **Privacy mask**: tracker details stay masked until device auth when App Lock is on (`_isPrivacyMasked` + LocalAuthentication) — preserve this in any redesign.

## 4. Logging-First Layout & Phase Animations (v2.3)
* **Logging-First Hierarchy**: Position the daily flow & symptom logging card at the top of the screen for instant muscle-memory access upon opening the tab.
* **Moon Phase Display**: Render live moon phase animations reflecting cycle phase (new moon for menstrual, crescent for follicular, full moon for ovulation, waning gibbous for luteal).
* **Collapsible Symptoms & Icon Tiles**: Symptoms card starts collapsed with an active count badge and expands on tap. Flow intensity (Spotting, Light, Medium, Heavy) uses icon+label selector tiles.
* **Dark Mode Contrast Tokens**: Use `onPeriodColor` palette tokens for chip text and delete log icons so interactive elements remain clearly visible in dark mode.
