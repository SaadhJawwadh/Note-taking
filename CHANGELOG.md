# Changelog

## [1.4.0] - 2025-12-18

### ✨ New Features
- **Material 3 Animations**: Integrated expressive transitions including `OpenContainer` for note cards, staggered list entrances, and fluid FAB morphing.
- **Enhanced Preview**: Note Editor preview now supports selectable text, clickable links, and proper rendering of local images.

### ⚡ Improvements
- **Accessibility**: Comprehensive audit ensuring proper semantic labels and hit targets across the app.
- **Code Quality**: Resolved all lint issues and redundant code for a cleaner codebase.
- **Preview Alignment**: Fixed alignment issues in the Note Editor preview mode.

## [1.3.2] - 2025-12-17

### 🚀 Enhancements
- **Editor Toolbar**: Redesigned the formatting toolbar as a floating **"Pill"** that adapts to keyboard visibility.
- **Settings**: Simplifed the "About" section to display the version number directly.

### 🛠️ Fixes & Cleanup
- **Security**: Reverted Biometric App Lock feature for better stability.
- **Dependencies**: Removed unused `local_auth` and related code.
- **UI**: Fixed bottom padding and layout issues in the Note Editor.

## [1.3.1] - 2025-12-17


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
