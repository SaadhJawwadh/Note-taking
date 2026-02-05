# Note Book 📝

Hey! This is a simple, private note-taking app I built just for myself. I wanted something clean, fast, and fully local—no cloud, no accounts, just my notes.

If you're looking for a minimal place to jot down thoughts, code snippets, or life plans, feel free to use it!

## Features

- **🎨 Dynamic Colors**: Tags have distinct colors from a rich palette of 18 Material shades, and your notes automatically adopt them.
- **🏷️ Smart Tagging**: Organize everything with color-coded tags.
- **📝 WYSIWYG Editor**: Write with a rich text editor supporting adaptive quotes, code blocks, and **smart image previews**.
- **📂 Organization**: Archive completed notes or move them to Trash (recoverable).
- **🔒 Fully Local**: Your data stays on your device. Always.
- **💾 Auto-Save**: Never lose a thought.
- **🌓 Dark Mode**: Looks great at night, with formatting that adapts to your note's color.
- **📱 Uniform Toolbar**: Formatting tools are neatly organized in a consistent bottom bar.
- **💰 Financial Manager**: dedicated space to track daily expenses and income with a built-in calculator.
- **📤 Import/Export**: Backup your notes to a JSON file and take them anywhere.

## How to Install

Since this is a Flutter app, you can build it for Android, iOS, macOS, Windows, or Linux.

### Prerequisites
You need the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed on your machine.

### Steps

1.  **Clone the repo:**
    ```bash
    git clone https://github.com/SaadhJawwadh/Note-taking.git
    cd Note-taking
    ```

2.  **Get dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run it:**
    ```bash
    flutter run
    ```

### Releasing a New Version

To release a new version, use the provided helper script:

```bash
./bump_version.sh 1.8.0 1
```

This will automatically update `pubspec.yaml` to keep the build in sync. After that, commit your changes and push a new tag to GitHub to trigger the release workflow.

That's it! Enjoy.
