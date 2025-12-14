# Note Book

A fully local, offline-first note-taking application built with Flutter.

## Features
- **Offline First**: All data is stored locally on your device.
- **Markdown Support**: Write notes using Markdown with a live preview and formatting toolbar.
- **Material You**: Dynamic theming that adapts to your device's wallpaper and system settings.
- **Rich Organization**: Pin, Archive, and Delete notes. Search by title or content.
- **Privacy Focused**: No cloud sync, no tracking.

## App Flow

### 1. Dashboard (Home Screen)
- **View Notes**: All your notes are displayed in a staggered grid layout.
- **Preview**: Notes show a rendered Markdown preview directly on the card (up to 250 characters).
- **Search**: Tap the search icon to find notes instantly.
- **Navigation**: Access Settings, Archive, and Trash via the side drawer.

### 2. Creating & Editing Notes
- **Create**: Tap the `+` Floating Action Button to start a new note.
- **Edit**: Tap any existing note card to open the editor.
- **Markdown Toolbar**: Use the toolbar above the keyboard to insert formatting (Bold, Italic, Code, Lists, Checkboxes).
- **Preview Mode**: Toggle the "Eye" icon to switch between Editing (raw text) and Preview (rendered Markdown) modes.
- **Save**: Notes are saved automatically as you type.

### 3. Settings
- **Theme**: The app automatically uses your system's "Material You" dynamic colors (if available) or falls back to a dark theme.
- **Text Size**: Customize the font size for the editor and previews (Small, Medium, Large).
- **Data**: Backup and Import your notes database to keep your data safe.

## Development

### Prerequisites
- Flutter SDK (3.27.0 or stable)
- Java 17

### Build
To build the APK:
```bash
flutter pub get
flutter build apk --release
```

### GitHub Actions
This project includes a workflow to automatically build and release the APK:
1.  **Manual Trigger**: Go to Actions -> Build and Release APK -> Run workflow.
2.  **Tag Trigger**: Push a tag starting with `v` (e.g., `git tag v1.0.0 && git push origin v1.0.0`).
3.  **Release Trigger**: Publish a release in the GitHub UI.
