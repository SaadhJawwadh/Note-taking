# Note Book v1.10.0 - Global Finance Update 🌍

In this release, we're taking the **Financial Manager** global! You can now customize how your finances are displayed with full multi-currency support.

## ✨ New Features

### 🌍 Multi-Currency Selection
- **Personalized Symbols**: Choose your preferred currency from Settings (LKR, USD, EUR, GBP, JPY, INR).
- **Default Currency**: Set to **LKR** by default for our Sri Lankan users.
- **Dynamic Updates**: Changing your currency in Settings instantly updates every screen in the app, from the Daily Dashboard to individual transactions.

### 💰 Smarter Financial Manager
- **Contextual UI**: The amount entry field now shows your selected currency prefix, helping you enter data accurately.
- **Improved Dashboards**: All summary cards (Income, Expense, Balance) now respect your global currency preference.

## 🛠 Technical Fixes
- **State Management**: Integrated `SettingsProvider` with the Financial Manager for real-time UI synchronization.
- **UI Consistency**: Standardized currency formatting across the app.
- **Code Optimization**: Unified asset management for currency symbols.

## 🚀 Migration Guide
- **Automatic**: Your existing financial data remains safe. The app will simply display your historical data using the new currency setting you choose.
- **Persistence**: Your currency choice is saved locally and survives app restarts.

---

*Verified & QA Tested on Android.*
