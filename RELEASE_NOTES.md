# Note Book — Release v1.22.0

This release focuses on architectural refinements, critical stability fixes, and a premium "Expressive Material" UI update.

### 📝 Core Improvements
- **NoteProvider Refactor**: Successfully migrated the Home Screen state management to a centralized `NoteProvider`, resulting in faster filtering and smoother transitions.
- **Database Self-Healing**: Enhanced resilience by automatically backing up corrupt database files instead of deleting them.
- **Improved SMS Pipeline**: Refined automated transaction logging with boundary-aware regex matching for 10+ major banks.

### 🛡️ Critical Fixes
- **Theme Crash**: Resolved a critical `ThemeData` brightness mismatch that caused app crashes on certain devices.
- **Backup Integrity**: Fixed a bug where custom expense/income rules were excluded from backups, ensuring 100% data preservation.
- **Naming Conflicts**: Corrected `GoogleFonts` implementation to resolve build-time errors.

### 🎨 Design & UX
- **Expressive Material**: Aligned the entire application with the new Design System (Material 3, Stadium FABs, and Rubik typography).
- **Tactile Transitions**: Integrated `OpenContainer` and `FadeThrough` animations for a premium feel.
- **Smart Tags**: Implemented MRU (Most Recently Used) tag sorting for quicker organization.

---
**Note Book** remains 100% local, 100% private, and 100% yours.
