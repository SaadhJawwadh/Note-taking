# Note Book v1.17.0 — Secure Database & Hardened Backups

## 🔒 Security / Data Integrity
- **Database Encryption at Rest**: The entire SQLite database (notes, financial transactions, period logs, SMS contacts) is now encrypted at rest using SQLCipher (256-bit AES).
- **Transparent Migration**: Existing unencrypted databases are automatically converted to the new encrypted format on the first app launch.
- **Improved Backup Security**:
  - The Android auto-backup rules (`backup_rules.xml` and `data_extraction_rules.xml`) now strictly exclude the device's secure keystore from being uploaded to Google Drive. The encryption key remains entirely offline, meaning your cloud backups cannot be decrypted by a malicious actor.
  - Device-to-device transfer (USB cable or direct Wi-Fi sync during phone setup) continues to correctly migrate the encryption keys to prevent data loss when upgrading devices.
- **Backup App Lock Hardening**: Security settings like `appLockEnabled` and `useBiometrics` are now explicitly ignored during a manual backup restore. This prevents an attacker from bypassing the app lock by importing a modified backup file where the lock is disabled.

## Upgrade Guide

**From any version**: Install the new APK over the existing one. The Android `versionCode` automatically increments so no uninstalls are required. Your unencrypted database will safely migrate to an encrypted one on first launch.

---

*Fully local. No data leaves your device.*
