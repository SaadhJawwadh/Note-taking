# Note Book 📝

Hey! This is a simple, private note-taking app I built just for myself. I wanted something clean, fast, and fully local—no cloud, no accounts, just my notes.

If you're looking for a minimal place to jot down thoughts, code snippets, or life plans, feel free to use it!

## Features

- **🎨 Dynamic Colors**: Tags have distinct colors from a rich palette of 18 Material shades, and your notes automatically adopt them.
- **🏷️ Smart Tagging**: Organize everything with color-coded tags, sorted by most recently modified note.
- **📝 WYSIWYG Editor**: Write with a rich text editor supporting adaptive quotes, code blocks, and **smart image previews**.
- **☑ Checklist Preview**: Quill checklist items show ☐ / ☑ symbols directly on home-screen note cards.
- **📄 Smart Preview**: Note cards render rich formatting (bullet lists, headings, blockquotes) via Markdown, with up to 6 lines of preview.
- **📂 Organization**: Archive completed notes or move them to Trash (recoverable).
- **🔒 Fully Local & Encrypted**: Your data stays on your device. The entire SQLite database is encrypted at rest using SQLCipher (256-bit AES) with hardware keystore protection.
- **💾 Auto-Save**: Never lose a thought.
- **🌓 Dark Mode**: Looks great at night, with formatting that adapts to your note's color.
- **📱 Uniform Toolbar**: Formatting tools are neatly organized in a consistent bottom bar.
- **💰 Financial Manager**: Dedicated space to track daily expenses and income with a built-in calculator, 6-month chart, and custom date-range filtering.
- **🔍 Transaction Search**: Search transactions in real time by description or category.
- **🗑️ Long-Press Delete**: Long-press any transaction card to delete it with a confirmation dialog.
- **🏷 Transaction Categories**: Auto-categorises transactions into 10 categories — Transport, Food & Dining, Subscriptions, Shopping, Utilities, Health, Entertainment, Payments, Deposit, and Other — using compound keyword priority (e.g. "PickMe Food" → Food & Dining before "PickMe" → Transport).
- **⚙️ Custom Categories**: Create your own categories with a custom name, colour, and keywords — directly from the transaction editor or from Settings → Financial Manager → Manage Categories.
- **📲 SMS Auto-Import**: Automatically reads bank SMS messages (Sri Lankan banks) and creates transactions — even while the app is in the background. Promotional, cancelled, due-reminder, and duplicate messages are silently skipped; reversals/refunds automatically delete the original expense. Cross-sender deduplication (±5 min window) prevents duplicates when multiple bank apps fire for the same transaction.
- **📋 SMS Contacts**: Full SMS sender management under Settings → Financial Manager → SMS Contacts. View all 10 built-in Sri Lankan banks and custom senders. Block/unblock any sender with a toggle. Add non-bank services (e.g. KOKO, FriMi) to include them in auto-import.
- **🛡️ Secure Backup**: Complete data export (Notes + Finances + Categories + SMS Contacts + Settings) and automatic Google Cloud Backup support. Cloud backups explicitly exclude encryption keys to ensure your data remains completely secure if your cloud account is compromised. Restores from any previous backup version (v1–v6).

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

To release a new version, use the deploy script:

```bash
./deploy.sh 1.17.0
```

The script auto-computes the `versionCode` from the version number (`major×10000 + minor×100 + patch`), bumps `pubspec.yaml`, commits, tags, and pushes to GitHub to trigger the release pipeline.

That's it! Enjoy.
