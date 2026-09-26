
### 🌟 What's New
- **Expanded Global Multilingual Support**: Comprehensive localization architecture with an in-app language picker under *Settings > Appearance & UI*. Choose between **System Default** or explicitly select **English**, **தமிழ் (Tamil)**, **中文 (Simplified Chinese)**, **Português (Portuguese)**, **Español (Spanish)**, **Français (French)**, and **Deutsch (German)**. All labels, navigation tabs, bottom bars, and domain actions translate instantly without requiring an app restart.
- **Dedicated Savings Goals Sub-Tab in Budgets**: Integrated a dedicated `[Breakdown] ⇄ [Budgets] ⇄ [Savings]` segmented control inside the Budgets view. Eliminates nested whitespace issues while showcasing vibrant goal-tinted cards, glowing avatar icons, dynamic target currency formatting, 24 Material 3 goal colors, and instant deposit logging.
- **Dual-State Note Editor Keyboard Controls**: Polished the editor bottom action pill bar. The formatting toggle button cleanly morphs to a down arrow when open, removing duplicate keyboard hide icon confusion, while redundant menu options and unused voice dictation are removed.

### 🚀 Improvements
- **Contextual Selection & Toolbar AI Refine**: Selecting text and tapping AI Transaction or using the ledger toolbar refine now resolves transactions directly from storage with instant UI refresh notifications.
- **Streamlined APK Footprint & Permissions**: Removed obsolete voice typing dependencies (`record`, `audioplayers`) and eliminated unnecessary recording permissions from `AndroidManifest.xml` for maximum privacy and lighter binary size.

### 🐛 Fixes
- **MaterialApp Locale Resolution**: Wired `supportedLocales` to all localized language files so in-app language changes apply reactively to all screens.
- **Savings Goal Repository Schema & Menu Action**: Added proper handler in financial manager popup menu to directly summon the Savings Goal editor sheet, with full SQLite v24 table support.

