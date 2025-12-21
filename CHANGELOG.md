# Changelog

## [1.7.0] - 2025-12-22

### ✨ New Features
- **Rebranding**: App title updated to "Note book".
- **Visuals**:
  - **Adaptive Formatting**: Quote and Code blocks in the editor now adapt to the note's page color, ensuring perfect visibility in all themes (Dark/Light/Colored).
  - **Home Screen Thumbnails**: Note card images are now displayed as compact, rounded thumbnails (120px height) for a cleaner grid layout.
  - **Editor Previews**: Images in the editor use a fixed height (200px) and rounded corners to match the design language.
  - **Uniform Toolbar**: Bottom formatting toolbar now has perfectly uniform spacing between icons.
- **Tags**:
  - Renamed "All Notes" filter to "All" for simplicity.
  - Consistent "filled pill" style for tags on note cards.

### 🐛 Fixes
- **Stability**: Fixed a `RenderFlex` overflow crash on the Home Screen note cards (157px height constraint issue resolved).
- **Layout**: Fixed non-uniform padding in Manage Tags screen.
- **Consistency**: Standardized image alignment across the app.

### 🧹 Maintenance
- Removed unused legacy styling code.
- Verified 0 analysis issues.
