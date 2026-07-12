
### 🩸 Period Tracker Refinements
- **Semantic Phase Colors**: Cycle-phase colors now come from the design system's theme tokens instead of hardcoded palette values.
- **Skeleton Loading**: The tracker loads with pulsing placeholder cards matching the notes home.
- **Theme-Correct Destructive Actions**: Delete confirmations use the theme error color.

### 📝 Note-Taking Upgrades
- **Folders**: File notes into folders from the editor menu (create folders inline); filter the home screen by folder.
- **Templates**: Long-press the New Note button for Meeting Notes, Shopping List, and Journal starting points.
- **Voice Dictation**: A mic button in the editor toolbar streams on-device speech into the note at the cursor.
- **Markdown Typing**: `- `, `1. `, `# `/`## `/`### `, `[] `, `**bold**`, `*italic*`, `` `code` `` auto-format as you type.
- **Find in Note**: Search inside the open note with match navigation from the toolbar.
- **Outline Navigation**: Jump between headings in long notes from the editor menu.
- **Note Reminders & Locked Notes** (see below) round out the editor menu.
- **Quick Checklist Item**: One tap in the toolbar appends a fresh unchecked item.
- **Rich Link Cards**: Up to three link previews per note instead of one.
- **Sort & Pin**: Sort notes by modified/created/title/color from the home bar; pin or unpin many notes at once from selection mode.
- **Smarter Home**: Tag chips show note counts, cards show a "+N" tag overflow, skeleton cards replace the loading spinner, and undo is available for every way of trashing a note.
- **Reminder Deep-Link**: Tapping a note reminder notification opens that note directly.

### ✨ New Features
- **Share Into Notes**: Share text, links, or images from any app into a new note; select text anywhere and choose "Everything App" from the context menu to capture it.
- **Note Reminders**: Set a date/time reminder on any note from the editor menu; scheduled locally with notifications, synced with edits, and cancelled on delete.
- **Locked Notes**: Lock individual notes behind biometric/device-credential authentication; locked notes mask their content on home-screen cards.
- **Recurring Transactions**: Mark a new transaction as repeating daily/weekly/monthly; due entries materialize automatically, manageable under Settings → Financial Manager.
- **Notes Quick-Capture Widget**: New home-screen widget with New Note and Search actions.
- **App Shortcuts**: Long-press the launcher icon for New Note, New Transaction, and Search.
- **Tamil Language Support**: Localization infrastructure (English + Tamil) for core UI strings.

### 🎨 Material Expressive Design
- **Font Pairing**: Google Sans Text for headlines/display text paired with Rubik body text; Google Sans Code bundled for numeric surfaces.
- **Motion**: Shared-axis transitions for all drill-in navigation (settings sub-pages, search results); predictive-back gesture enabled.
- **Consistency Sweep**: 55 hardcoded corner radii and all ad hoc shadows moved to shared design tokens; destructive actions use the theme error color; unified shapes for buttons, popup menus, dialogs, and snackbars; edge-to-edge rendering.
- **Haptics Everywhere**: Settings tiles/switches, app-bar actions, and editor menus now give tactile feedback.
- **Responsive**: Adaptive note-grid columns (2-4) and width-constrained sheets on tablets/foldables.
- **Home Screen Widget Redesign**: Finance widget refreshed to the M3 Expressive language, with proper thousands separators, a real picker preview, and background refresh so TODAY rolls over at midnight.

### 🗑️ Removed
- **File Converter Module**: Removed entirely (UI, FFmpeg service/installer, related settings, share-target media intents, onboarding entries). The "FFmpeg engine" installer never downloaded a real binary — conversions were always simulated — so the module was pulled rather than shipped half-working.

### 🐛 Bug Fixes
- **App Lock Bypass Gaps**: SMS/notification permission prompts and external Settings links no longer trigger an unwanted lock-screen re-authentication on return.
- **App Lock Flicker**: The locked overlay no longer flashes while the OS biometric dialog is on screen.
- **Greeting Logic**: "Time to sleep!" no longer shows at 5 PM; evenings get a proper greeting.
- **Theme Wiring**: The app's custom TextTheme was never actually passed into ThemeData; fixed, so theme typography applies app-wide.
- **Period Notifications**: Rescheduling period predictions no longer cancels unrelated notifications (e.g. note reminders).

### 🧹 Maintenance
- Replaced the discontinued `telephony` package with the maintained `another_telephony` fork; upgraded 21 dependencies; `flutter_lints` 2→6 with all findings fixed; added a CI workflow gating pushes/PRs on analyze + tests.
