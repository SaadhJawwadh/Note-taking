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
