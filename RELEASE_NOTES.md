
### ✨ New Features
- **WhatsApp HD Video Compression**: Added visually lossless H.264 profile presets optimized for native playback inside WhatsApp without server-side re-encoding.
- **Offline Image Compression**: Upgraded Lite Mode conversion to perform native, local image resizing and re-encoding on the device.
- **Visual Quality Comparison**: Added an interactive swipe slider letting users compare original vs. compressed image differences.
- **Space Savings Dashboard**: Shows aggregate session metrics and total disk space saved.
- **Onboarding Experience**: Introduced a modular first-time bottom sheet experience showing available powerups and tips.

### 🔒 Security & Privacy
- **Encrypted Key Protection**: Migrated plain-text database encryption key backups from SharedPreferences into secure system KeyStore storage.
- **App Lock Share Sheet Isolation**: Secured share intent processing to queue shared files and require biometric authentication before proceeding.

### 🐛 Bug Fixes & Refactoring
- **App Lock State Rebuilds**: Fixed duplicate/nested `setState` calls during lifecycle transitions.
- **Material 3 Consistent Dialogs**: Standardized custom currency and notification alert pickers to use Material 3 surface colors.
- **Android Notifications Icon**: Fixed a startup PlatformException by copying the launcher icon asset to Android's drawable resource path.

