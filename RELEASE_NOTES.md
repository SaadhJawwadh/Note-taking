
### ✨ New Features
- **Material 3 Finance Home Screen Widget**: Designed a resizable home screen widget displaying Today's spent, Monthly spent, and Monthly income.
- **Recent Transactions Feed**: Shows the top 3 recent transactions directly on the widget with dynamic text colors indicating debit/credit status.
- **Quick-Add Deep Linking**: Added a direct shortcut "+" button on the widget to deep link into the transaction editor with automatic lockscreen security gating.
- **Material You Design Integration**: Supports full Material You dynamic colors and M3 standard 28dp rounded corners on Android 12+ (API 31+).

### 🐛 Bug Fixes & Refactoring
- **RemoteViews Inflation Crash**: Resolved launcher crashes by replacing generic `<View>` elements with allowed layout views (e.g. `<FrameLayout>`).

