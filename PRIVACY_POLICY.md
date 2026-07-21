# Privacy Policy

**Last Updated: July 21, 2026**

This Privacy Policy describes how **Everything App** (package name: `com.saadhjawwadh.notebook`), a mobile application developed for offline-first personal note-taking, financial management, and health tracking, handles your information. 

By using the Application, you agree to the practices described in this policy.

---

## 1. Absolute Privacy Commitment (Zero Data Collection)

Everything App is designed as a **fully local, offline-first application**. We operate under a strict privacy model:
* **Zero External Data Collection**: We do not run, lease, or maintain any external databases or cloud servers to collect, upload, transmit, or process your personal data.
* **No User Accounts**: You do not need to register, create an account, or log in to use the Application.
* **Encryption at Rest**: All notes, checklists, financial transactions, health logs, categories, and settings are stored locally on your device in a database encrypted using **SQLCipher (256-bit AES encryption)**.

---

## 2. Data Retention Policy

Google Play User Data Policies require explicit disclosure of data retention practices:
* **Zero Remote Retention**: Because Everything App does not collect, transmit, or store any data on external servers or cloud services, **we (the developer) do not retain or store any user data**.
* **Local Retention Duration**: All user-generated content (notes, transaction logs, health tracker logs, app settings) is retained **exclusively on your local device** for as long as the application remains installed, or until you explicitly delete the data.

---

## 3. Data Deletion Instructions (User Control & Data Deletion)

Google Play Policies require clear instructions on how users can delete their data. Since all data resides locally on your device and there are no cloud accounts or server databases, you have total control over your data:

### A. In-App Deletion
* **Individual Entries**: You can delete individual notes, transaction entries, categories, and health tracker entries at any time using the delete actions within the app.
* **Clear Data**: You can reset or clear data within the app settings.

### B. Complete Local Data Wipe via Device Settings
* You can instantly and permanently purge all stored database entries, preferences, and cached media by clearing app storage via your device's operating system settings:
  * **Android**: Open **Settings** → **Apps** → **Everything App** → **Storage & Cache** → **Clear Storage / Clear Data**.

### C. Uninstalling the Application
* Uninstalling Everything App from your device will permanently erase all local application files, database files, and cached media stored by the application (excluding any manual `.json` backup files you explicitly exported to external device directories).

### D. Submitting Data Deletion Inquiries
* If you have any questions or need assistance regarding data management or deletion, you may submit an inquiry via the official GitHub issue tracker: [https://github.com/SaadhJawwadh/Note-taking/issues](https://github.com/SaadhJawwadh/Note-taking/issues).

---

## 4. Permissions and Sensitive Data Processing

The Application requests specific device permissions to enable core offline features. All data accessed through these permissions remains entirely on your device.

### A. SMS Permissions (`READ_SMS` and `RECEIVE_SMS`)
* **Purpose**: Used exclusively to automate financial logging by importing incoming bank transaction alerts.
* **How it is processed**: When a new SMS is received, the Application checks the sender against a built-in or user-configured list of bank senders. If a match is found, the SMS body is parsed locally on your device to extract transaction details (amount, category, merchant).
* **Data Handling**: **No SMS content is ever transmitted off your device.** SMS processing happens 100% locally.

### B. Health Tracker Data (Period & Cycle Tracking)
* **Purpose**: Allows users to log menstrual cycles, symptoms, and receive discreet reminders.
* **Data Handling**: All health entries and prediction metrics are strictly confidential and stored locally in the encrypted SQLCipher database. **No health data is ever transmitted, shared, or backed up to any external servers.**

### C. Biometric / Local Authentication (`USE_BIOMETRIC` / `USE_FINGERPRINT`)
* **Purpose**: Used to lock the Application and secure your notes, financial ledger, and health records.
* **How it is processed**: Verification is handled entirely by the Android Operating System's secure hardware (Keystore/TEE). 
* **Data Handling**: The Application never accesses, reads, or stores your biometric credentials (such as fingerprint templates or facial recognition data). It only receives a `success` or `failure` response from the Android OS.

### D. Storage and Media Access
* **Purpose**: Enables you to attach images, drawings, or compressed media to your notes.
* **How it is processed**: The Application accesses files only when you manually pick them using the system file/image selector.
* **Data Handling**: Files are copied or processed locally within the Application's secure directory. No media files are shared or uploaded to the cloud.

---

## 5. On-Device Artificial Intelligence (Gemini Nano)

If enabled, the Application utilizes Google's **Gemini Nano** engine for text summarization, tag suggestions, paragraph refining, and financial SMS parsing fallback.
* **Local Execution**: This AI engine runs **completely offline on your device's native hardware**.
* **Zero Transmission**: Your notes, transaction descriptions, and text prompts are never uploaded to Google Cloud or any other third-party API. All LLM inference happens entirely in the device memory.

---

## 6. Backups and Data Portability

* **Manual Backups**: When you choose to export your data (Settings → Backup & Restore), the Application serializes your database into a `.json` file and saves it in a directory of your choice. You are fully responsible for the security and storage of this file.
* **Google Auto-Backup**: If you have Android System Backups enabled, a backup of the Application's encrypted database is managed by the OS and uploaded to your personal Google Drive. The Application's secure keystore is explicitly excluded from these backups to ensure your data remains unreadable by third parties.

---

## 7. Third-Party Services and Analytics

Because the Application is completely offline, it does not integrate with third-party analytics (such as Google Analytics or Firebase), tracking SDKs, advertising networks, or third-party payment gateways. No data is shared with or sold to third parties.

---

## 8. Children's Privacy

Because the Application does not collect, store, or share any personal information from any user, it does not collect or process personal data from children under the age of 13.

---

## 9. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Any changes will be documented in the repository's `CHANGELOG.md` and updated in this document. We encourage you to review this page periodically for updates.

---

## 10. Contact Information

If you have any questions or feedback about this Privacy Policy, please contact the developer via the official repository issue tracker:
* **GitHub Repository**: [https://github.com/SaadhJawwadh/Note-taking](https://github.com/SaadhJawwadh/Note-taking)
* **Issue Tracker**: [https://github.com/SaadhJawwadh/Note-taking/issues](https://github.com/SaadhJawwadh/Note-taking/issues)

