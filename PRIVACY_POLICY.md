# Privacy Policy

**Last Updated: June 16, 2026**

This Privacy Policy describes how **Everything App** (the "Application"), a mobile application developed for offline-first personal note-taking and financial management, handles your information. 

By using the Application, you agree to the practices described in this policy.

---

## 1. Absolute Privacy Commitment (Zero Data Collection)

Everything App is designed as a **fully local, offline-first application**. We operate under a strict privacy model:
* **No External Servers**: We do not run, lease, or maintain any external databases or cloud servers to collect, upload, or process your personal data.
* **No User Accounts**: You do not need to register, create an account, or log in to use the Application.
* **Encryption at Rest**: All notes, checklists, financial transactions, categories, and settings are stored locally on your device in a database encrypted using **SQLCipher (256-bit AES encryption)**.

---

## 2. Permissions and Sensitive Data Processing

The Application requests specific device permissions to enable core offline features. All data accessed through these permissions remains entirely on your device.

### A. SMS Permissions (`READ_SMS` and `RECEIVE_SMS`)
* **Purpose**: Used exclusively to automate financial logging by importing incoming bank transaction alerts.
* **How it is processed**: When a new SMS is received, the Application checks the sender against a built-in or user-configured whitelist of bank names. If a match is found, the SMS body is parsed locally on your device to extract transaction details (amount, category, merchant).
* **Data Handling**: **No SMS content is ever transmitted off your device.** The Application only reads messages from recognized banks/senders, and parses them locally.

### B. Biometric / Local Authentication (`USE_BIOMETRIC` / `USE_FINGERPRINT`)
* **Purpose**: Used to lock the Application and secure your notes and finances.
* **How it is processed**: Verification is handled entirely by the Android Operating System's secure hardware (Keystore/Tee). 
* **Data Handling**: The Application never accesses, reads, or stores your biometric credentials (such as fingerprint templates or facial recognition data). It only receives a `success` or `failure` response from the Android OS.

### C. Storage and Media Access
* **Purpose**: Enables you to attach images/drawings to your notes and import files into the local File Converter module.
* **How it is processed**: The Application accesses files only when you manually pick them using the system file/image selector.
* **Data Handling**: Files are copied or processed locally within the Application's secure cache directory. No media files are shared or uploaded to the cloud.

---

## 3. On-Device Artificial Intelligence (Gemini Nano)

If enabled, the Application utilizes Google's **Gemini Nano** engine to sanitize and refine transaction descriptions (e.g., correcting names or spelling).
* **Local Execution**: This AI engine runs **completely offline on your device's native hardware**.
* **Zero Transmission**: Your transaction descriptions and text prompts are never uploaded to Google Cloud or any other third-party API. All LLM inference happens entirely in the device memory.

---

## 4. Backups and Data Portability

* **Manual Backups**: When you choose to export your data (Settings → Backup & Restore), the Application serializes your database into a `.json` file and saves it in a directory of your choice. You are fully responsible for the security and hosting of this file.
* **Google Auto-Backup**: If you have Android System Backups enabled, a backup of the Application's encrypted database is managed by the OS and uploaded to your Google Drive. The Application's secure keystore is explicitly excluded from these backups to ensure your data remains unreadable by third parties.

---

## 5. Third-Party Services

Because the Application is completely offline, it does not integrate with third-party analytics (like Google Analytics or Firebase), tracking SDKs, advertising networks, or payment gateways. 

---

## 6. Children's Privacy

Because the Application does not collect, store, or share any personal information from any user, it does not collect or process personal data from children under the age of 13.

---

## 7. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Any changes will be documented in the repository's `CHANGELOG.md` and updated in this document. We encourage you to review this page periodically for updates.

---

## 8. Contact Information

If you have any questions or feedback about this Privacy Policy, please contact the developer via the official repository issue tracker:
* **GitHub Repository**: [https://github.com/SaadhJawwadh/Note-taking](https://github.com/SaadhJawwadh/Note-taking)
