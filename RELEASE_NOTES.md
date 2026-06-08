# Note Book — Release v1.32.0

This is a major architectural release focusing on intelligence, extreme performance, and long-term stability.

### 🧠 AI-Enhanced Finances
- **Smart SMS Descriptions**: The app now leverages on-device AI (Gemini Nano) to automatically clean up and professionalize noisy bank SMS messages. "Purchase at Uber 1500" becomes "Uber Trip", giving you a cleaner, more intuitive financial log.

### ⚡ Extreme Performance
- **Instant Previews**: We've revolutionized how the Note grid loads. Previews are now pre-computed in plain-text when you save a note, eliminating scroll jank and dramatically speeding up the Home screen, no matter how many notes you have.
- **Database-Level Filtering**: Pagination and tag filtering are now handled directly by the SQLite engine, saving memory and ensuring accurate, lightning-fast searches.
- **Batched Bulk Actions**: Archiving or deleting dozens of notes at once now happens instantly using atomic database batches.

### 🏗️ Bulletproof Architecture
- **Repository Pattern**: We completely dismantled the monolithic database helper. Notes, Transactions, and Period Logs are now managed by dedicated, highly-testable repositories.
- **Robust Navigation**: Navigating between your Notes, Finances, and Tracker is now seamless. We've implemented `IndexedStack` to ensure you never lose your scroll position or state when switching tabs.
- **Centralized Design Tokens**: The entire app's padding, spacing, and animations have been unified under a single design system for a perfectly consistent, premium feel.
- **Backward-Compatible Backups**: Your data is safe. The backup system seamlessly handles the new preview structures, ensuring flawless restores from any previous app version.

---
Enjoy the fastest, smartest version of Note Book yet!