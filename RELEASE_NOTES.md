
### 🏛️ Unified Frosted Glass Headers & Single-Scaffold Architecture
- **Reusable `FrostedGlassSliverAppBar` Component**: Modularized top header architecture across all 7+ sub-screens for 100% visual symmetry, 20px title alignment, and zero-border light/dark mode glassmorphism.
- **Single Outer Scaffold FAB Architecture**: Centralized floating action bar delegate floating 16dp above the bottom navigation bar across all tabs without clipping or double-padding.
- **Default Launch Folder Persistence**: Persists user default folder selection (`settings.defaultFolder`) on app launch.

### 🎨 Pixel-Aligned Header Layout & Light Mode Artifact Fixes
- **Borderless Glassmorphism**: Removed hard horizontal border strokes and double-container inner pills to resolve light-mode shadow artifacts.
- **Standardized Side Padding**: Aligned left title margins to `20px` and normalized right action buttons to standard `48x48dp` Material touch targets.

