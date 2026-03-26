---
name: Health-Tracker-Expert
description: Specialist in the Health Tracker (Period Tracker) module, handling symptom logging, cycle predictions, intensity tracking, and privacy-first health data.
---

## Use this skill when
- Modifying `lib/screens/period_tracker_screen.dart`.
- Updating `lib/data/period_log_model.dart`.
- Refining cycle prediction algorithms.
- Updating health-related search queries in `lib/data/database_helper.dart`.

## Relevant Files
- `lib/data/period_log_model.dart`
- `lib/screens/period_tracker_screen.dart`
- `lib/data/database_helper.dart` (Period log queries)

## Instructions
- Prioritize privacy: Ensure health data remains local and is excluded from non-encrypted backups.
- Cycle predictions should use a rolling average of at least the last 3-6 months.
- Symptom logging UI should be tactile and use "Material You" seeds for visual comfort.
- Global search results for health logs should be descriptive yet discreet.
- Use `TableCalendar` or similar widgets for intuitive date selection.
