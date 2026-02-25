# Note Book v1.16.0 — Inline Categories, Rich Previews & Polished UX

## What's New

### Inline Category Creation
Create new spending categories directly from the transaction editor — no need to navigate to Settings. A **"+ New"** chip at the end of the category list opens a quick dialog (name + colour picker), and the new category is auto-selected for the current transaction. A **"Manage"** link next to the "Category" label navigates to the full Category Management screen.

### Rich Note Previews
Note cards on the home screen now render bullet lists, headings, blockquotes, and other formatting via Markdown — instead of stripping everything to plain text.

### MRU Tag Sorting
The tag bar on the home screen sorts tags by **most recently modified** note, so your active projects always appear first.

### Smooth Financial Animations
- Category and search filtering is now **instant** (in-memory) — no loading spinners.
- Opening and closing transactions uses a smooth fade-through transition (500 ms).
- Switching categories replays staggered list animations.

### Unified Design System
All three main screens (Notes, Finances, Settings) now share:
- Identical `fadeThrough` container transitions (500 ms)
- Consistent staggered list animations (vertical slide + fade)
- Matching AppBar styling, FAB style (extended with label), empty-state colours, and spacing.

### Seamless CI/CD Updates
- GitHub Actions release workflow now **auto-computes `versionCode`** from the git tag (`major×10000 + minor×100 + patch`), guaranteeing Android accepts every update without uninstall.
- Optional release signing via GitHub Secrets (`KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`).
- SHA-256 checksum published alongside each APK.
- Updated to `softprops/action-gh-release@v2` with optional `RELEASE_NOTES.md` and auto-generated fallback.

### Background Backup Logging
Silent `catch` blocks in the auto-backup service now log errors to the system log (logcat), making backup failures debuggable without affecting user experience.

## Upgrade Guide

**From any previous version**: Install the new APK over the existing one. The `versionCode` (11600) is strictly higher than all previous releases (which used 1), so Android will accept the upgrade without data loss or reinstall.

---

*Fully local. No data leaves your device.*
