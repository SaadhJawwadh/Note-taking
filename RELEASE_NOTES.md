# Note Book v1.16.1 — Bug Fixes & Faster Animations

## Bug Fixes

### Calculator: Invalid Results No Longer Stored
Entering a division-by-zero expression (`1/0`) or other invalid input previously allowed `Infinity` or `NaN` to be saved as a transaction amount. The calculator now detects these and shows "Error" — pressing "Use Value" closes without setting an amount.

### Finance Screen: No More Full-Page Re-Animation on Filter Tap
Tapping a category chip previously re-animated the entire page (charts, summary cards, and all transaction rows) from scratch on every tap. This was caused by `AnimationLimiter` receiving a new `key` on every filter change. The root cause has been removed — filters now update the list instantly without any animation disruption.

## Improvements

### Faster, M3-Compliant Transitions
All motion now follows Material 3 Expressive guidelines:
- Stagger entrance duration: 375 ms → **220 ms**
- Container fade-through (open note / open transaction): 500 ms → **300 ms**
- Slide offset: 50 px → **24 px** (subtle, not dramatic)

Dashboard cards (6-month chart, summary, search bar, category chips) still animate in elegantly on initial page load. Transaction rows simply update in-place when filters change — no re-entry animation.

### Backup Logging
Backup error logging switched from `print()` to `debugPrint()`, conforming to Flutter's production lint rules.

## Upgrade Guide

**From any version (including v1.16.0)**: Install the new APK over the existing one. The `versionCode` (11601) is strictly higher than all previous releases, so Android accepts the upgrade without data loss or reinstall.

---

*Fully local. No data leaves your device.*
