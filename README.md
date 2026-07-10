# Everything App 📝

[![Get it on Google Play](https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png)](https://play.google.com/store/apps/details?id=com.saadhjawwadh.notebook)

Everything App is a fully offline, private, and secure workspace designed to manage your thoughts, track your finances, and monitor your health without sending a single byte of data to external servers.

Built with **Flutter (Dart 3)** and backed by an encrypted **SQLCipher** database, Everything App combines security, modern aesthetics, and smart features into a single workspace.

---

## ✨ Key Features

### 1. 📝 Rich WYSIWYG Notes
* **Fully Formatted Notes**: Write and organize notes using headers, checklists, blockquotes, lists, and images (powered by `flutter_quill`).
* **Visual Categorization**: Associate tags with notes. Note backgrounds dynamically adapt to matching tag color schemes.
* **Auto-Saving & previews**: Note content debounces and autosaves. Home cards display clean previews with list checkbox symbols (☐/☑).
* **Grid & List Layouts**: Render notes in uniform grid, masonry grid, or simple list view with smooth Material transitions.

### 2. 💳 Private Financial Manager
* **Dual-Entry Ledger**: Track income, expenses, and current balances locally.
* **Smart SMS Auto-Import**: Listens for transaction SMS messages (optimized for Sri Lankan bank alerts) and parses transaction types, amounts, and dates in the background.
* **Automatic Reversals & Deduplication**: Detects refund messages and auto-reverses logs within 7 days, filtering out duplicate bank application notifications.
* **Graphs & Trends**: High-performance line charts depicting monthly income vs expense trends.
* **Inline Calculator**: Built-in simple mathematical operator support when entering transaction amounts.

### 3. 🩸 Health Tracker (Period Log)
* **Privacy-First Cycle Tracking**: Offline cycle prediction based on your log history.
* **Prediction Algorithm**: Outlier-aware calculations that ignore cycle anomalies (such as < 15 or > 60 days) to prevent skewing future prediction dates.
* **Ovulation Prediction**: Computes fertile/ovulation windows using standard luteal phase offset models.
* **Discreet Alerts**: Notifies you of upcoming cycles with customizable private text (e.g., "Check the app").

### 4. 🤖 Offline AI (Gemini Nano)
* **Summarization**: Generate bulleted summaries of note content locally. If Tamil text is detected, the summary language adapts automatically.
* **Tag Suggestions**: Recommends tags in the note editor based on your existing collection.
* **Selection Refine**: Refine selected paragraphs into Casualty, Professional, Expand, or Shorten tones on-device.
* **AI SMS Parsing**: Fallback extractor that parses banking SMS formats using native local models.

### 5. 🔒 High-Grade Security & Encryption
* **SQLCipher Storage**: The local SQLite database is fully encrypted at rest using 256-bit AES.
* **Keystore Integration**: Encryption keys are randomly generated and secured inside the Android KeyStore or iOS Keychain.
* **Automated Lock**: Locks screens immediately or after a custom idle background timeout. Supports Fingerprint, FaceID, or system PIN pattern bypass.

### 6. 🔄 Media Converter & Utilities
* **Dual-mode conversion**: Compress video/images using lightweight native APIs (Lite Mode) or download local FFmpeg binaries (FFmpeg Mode) for advanced formatting and metadata removal.

---

## 📥 How to Download & Install

Everything App can be installed directly from the Google Play Store or manually via GitHub Releases.

### 1. Google Play Store (Recommended)

[![Get it on Google Play](https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png)](https://play.google.com/store/apps/details?id=com.saadhjawwadh.notebook)

### 2. Manual Installation (GitHub Releases)

1. Navigate to the [GitHub Releases Page](https://github.com/SaadhJawwadh/Note-taking/releases).
2. Download the latest `.apk` file (e.g. `note-book-v1.34.0.apk`).
3. Open the downloaded file on your Android device.
4. When prompted, allow your web browser or file manager permission to **"Install unknown apps"**.
5. Follow the on-screen installer instructions to finish.

---

## 🛠️ Developer Setup & Builds

### Prerequisites
* Flutter SDK (Version **3.38.5** pinned)
* JDK 17
* Android SDK & Gradle

### Building Locally

1. **Clone the repository**:
   ```bash
   git clone https://github.com/SaadhJawwadh/Note-taking.git
   cd Note-taking
   ```

2. **Get Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App in Debug Mode**:
   ```bash
   flutter run
   ```

4. **Compile a Release APK**:
   ```bash
   flutter build apk --release
   ```
   *Note: If no `android/key.properties` file exists in the directory, local release builds will default to signing with the debug certificate (`~/.android/debug.keystore`).*
