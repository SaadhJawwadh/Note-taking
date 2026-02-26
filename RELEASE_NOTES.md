# Note Book v1.16.2 — Edge Case Fixes & Release Stability

## Bug Fixes

### Q+ Fund Transfers
Fixed an edge case where "Fund Transfer" messages initiated via `ComBank_Q+` were parsing incorrectly. They now correctly debit from the net balance.

### Editor Padding Anomalies
Resolved visual overlap and padding anomalies in the Note Editor. Blockquotes and Headers (`H1`-`H3`) now render with the correct Material 3 spacing and no longer inadvertently inherit inline-code background colours.

## Improvements & Stability

### GitHub Release Fonts
Disabled a native Android resource shrinker that was aggressively stripping the `Rubik` font files during the GitHub Actions CI pipeline. Font rendering in the production APK is now 100% identical to the local development build.

### Zero Lint Warnings
Cleared all remaining static analysis warnings (deprecated properties, flow control structures). The codebase officially passes `flutter analyze` with 0 issues.

## Upgrade Guide

**From any version**: Install the new APK over the existing one. The Android `versionCode` automatically increments so no uninstalls or data migrations are required.

---

*Fully local. No data leaves your device.*
