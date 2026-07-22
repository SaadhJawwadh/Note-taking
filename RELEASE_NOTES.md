
### 🔤 Offline Google Sans Text & Inter Typography
- **Embedded Asset Fonts**: Embedded Google Sans Text and Inter typography directly into app assets and Android native `res/font/` resources.
- **Zero Network Fetching**: Enforced `allowRuntimeFetching = false` for 100% offline font loading on both app screens and Android Home Screen widgets.

### 💳 Ledger Engine & SMS Auto-Discovery
- **1-Tap Ledger Deduplication**: Automatically detect and purge duplicate transaction entries within 120-second import windows.
- **Smart Bank Sender Auto-Discovery**: Automatically discover new bank SMS senders and whitelist them with one tap.

### ⚙️ Streamlined UI & SMS Import Rules
- **Single-View SMS Rules**: Streamlined SMS import rules to focus purely on transaction types with direct link to Category Management.
- **Render Overflow Fixes**: Fixed top bar status padding calculations on SMS rules screen to eliminate bottom overflows across screen sizes.
- **Cleaned Settings About Section**: Consolidated release links into a single version entry point.

### 🔒 Security & CI/CD Release Pipeline
- **Backup Rule Safety**: Resolved Android `FullBackupContent` lint rules for encrypted database backups.
- **Automated Play Console Deployment**: Configured GitHub Actions release workflow with Google Play Service Account automation.

