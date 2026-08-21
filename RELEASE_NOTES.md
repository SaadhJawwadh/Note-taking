
### 🐛 Fixes & Improvements
- **SMS Permission & Sync Detection**: Fixed SMS permission evaluation by removing undeclared phone permission requirements, restoring instant 1-tap quick sync and real-time bank SMS interception.
- **Tombstone Re-Import Safeguards**: Enhanced transaction ingestion to check the tombstone table, preventing permanently deleted transactions from being re-imported during historical scans unless explicitly enabled.
- **Sync Cancellation & Progress Controls**: Added an instant "Cancel" button to the SMS sync banner and batch processing chunks for seamless navigation across large inboxes.

