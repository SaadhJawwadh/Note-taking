# Changelog

## [1.3.1] - 2025-12-17

### Refinement & Fixes
- **Security**: Removed biometric app lock (reverted).
- **Note Editor**:
    - **Fixed Bottom Bar**: Usage of standard bottom toolbar that respects keyboard layout.
    - **Pill Style Toolbars**: Enhanced visual consistency with new floating pill toolbar design.
- **Settings**: Removed "Check for Updates" button (now shows static version).
- **Cleanup**: Removed unused dependencies (`local_auth`).

## [1.3.0] - 2025-12-15

### Major Update
- **Feature Release**: Official release of the Unified Design Language and Advanced Formatting features.
- Includes all changes from v1.2.3.

## [1.2.3] - 2025-12-15

### Modified
- **Unified Design Language**: Implemented a floating "Pill" design for AppBars across Home, Editor, and Settings screens.
- **Formatting**: Added support for Headings (#), Strikethrough (~~), Code (`), and Blocks (>).
- **Note Editor**: Added real-time syntax highlighting for Markdown. Moved "Tags" button to the top toolbar.
- **Settings**: Renamed "Manage Categories" to "Manage Tags".

### Removed
- **Experimental**: Removed inline image insertion feature.

## [1.2.2] - 2025-12-15

### Changed
- **Default Note Color**: Moved configuration from global Settings to the Note Editor. You can now specific "Set as Default" or "Reset to Default" directly from the color picker within a note.
