# Codebase Knowledge Graph & Developer Map (`map.md`)
> **Target Audience:** AI Coding Assistants (Antigravity, Cursor, Copilot, Claude)
> **App Domain:** Local-First Note-Taking, Financial Management, & Health Tracking System
> **Framework:** Flutter 3.x+ (Dart) | **Database:** Encrypted SQLCipher SQLite

---

## 1. High-Level Architecture Overview

```
[UI Layer (Screens & Widgets)]
       │
       ▼
[State Management (ChangeNotifier Providers)]
 ├── NoteProvider (lib/providers/note_provider.dart)
 └── SettingsProvider (lib/data/settings_provider.dart)
       │
       ▼
[Repositories & Services]
 ├── NoteRepository, TransactionRepository, PeriodLogRepository, RecurringRuleRepository
 ├── BackupService, NotificationService, SmsService, GeminiNanoService
 └── PeriodPredictionService, FinancialRegressionEngine
       │
       ▼
[Data Layer (SQLCipher DB & SharedPreferences)]
 ├── DatabaseHelper (lib/data/database_helper.dart) ── Encrypted SQLite (AES-256)
 └── SharedPreferences (App settings, folder/tag filters, widget bridge values)
```

---

## 2. Comprehensive Directory & File Mapping

### A. Data Layer (`lib/data/`)
* **`database_helper.dart`**: Core SQLCipher SQLite connection manager, schema initialization (version 17), migrations (`onUpgrade`), and raw query executions.
* **`database_constants.dart`**: Table names (`notes`, `note_tags`, `transactions`, `period_logs`, `recurring_rules`, `sms_contacts`, `category_definitions`) and column keys.
* **`database_seed.dart`**: Default category seeds and initial configuration.
* **`settings_provider.dart`**: Master `ChangeNotifier` managing app preferences (App Lock, theme, active folder/tag, dynamic Monet colors, notification settings, SMS sync interval).
* **Models**:
  * `note_model.dart` (`Note`, Quill Delta content, `previewText`, `isLocked`, `reminderAt`, `category`).
  * `transaction_model.dart` (`Transaction`, amount, type `income`/`expense`, category, date, `smsSender`).
  * `period_log_model.dart` (`PeriodLog`, startDate, endDate, symptoms, flow intensity).
  * `recurring_rule_model.dart` (`RecurringRule`, category, amount, frequency, nextDue).
  * `transaction_category.dart` (`TransactionCategory`, `iconCodePoint` mapping, system vs custom categories).
  * `category_definition.dart` & `category_constants.dart`: Category metadata and defaults.
  * `note_templates.dart`: Pre-configured Quill Delta JSON templates.
  * `sms_contact.dart`: Bank SMS sender rules.
* **Repositories (`lib/data/repositories/`)**:
  * `note_repository.dart`: Note CRUD, SQL joins for tags, `clearOldTrash()` (7-day purge).
  * `transaction_repository.dart`: Transaction CRUD, income/expense aggregation queries.
  * `period_log_repository.dart`: Period log CRUD and rolling history fetchers.
  * `recurring_rule_repository.dart`: Materialize due recurring transactions (idempotent 36-period catch-up loop).

### B. Business Services (`lib/services/`)
* **`backup_service.dart`**: Full JSON backup export/import (notes, tags, transactions, recurring rules, categories) with password encryption. Health logs excluded for privacy.
* **`notification_service.dart`**: Local notifications (Note reminders: ID range `0x4E000000 | hash`; Period alerts: IDs 1–3).
* **`sms_service.dart`**: Android SMS receiver listener, notification dispatcher, 5-minute transaction deduplication, and 7-day reversal handling (`__reversal__`).
* **`sms_parser.dart`**: Stateless regex extractor parsing bank alerts (Commercial Bank, Sampath Bank, HNB, Nations Trust, BOC, HSBC).
* **`sms_constants.dart`**: Centralized regex patterns, credit/debit keywords, and sender IDs.
* **`gemini_nano_service.dart`**: On-device AI (Gemini Nano AICore channel) for text polishing, note summarization, tag suggestions, and fallback SMS parsing.
* **`offline_ai_fallback_service.dart`**: Rule-based fallback parsing when Gemini Nano is unavailable.
* **`period_prediction_service.dart`**: Menstrual cycle prediction algorithm computing 3–7 log rolling averages (excluding cycles $<15$ or $>60$ days) and luteal phase ovulation offset (14 days prior).
* **`financial_regression_engine.dart`**: Exponentially-weighted linear regression ($w_i = \gamma^{n-1-i}$) with Huber-style outlier dampening ($Z > 1.8\sigma$) for trend forecasting.
* **`update_rating_service.dart`**: In-app rating prompts and version update notifications.

### C. State Management (`lib/providers/`)
* **`note_provider.dart`**: `ChangeNotifier` managing note feed state, active folder (`selectedFolder`), active tag (`selectedTag`), view mode (Masonry vs List), search query, and batch operations.

### D. Screens & Views (`lib/screens/`)
* **`home_screen.dart`**: App entry Scaffold, top app bar, bottom `NavigationBar`, note feed tabs, and `UniversalSearchOverlay` entrypoint.
* **`note_editor_screen.dart`**: Full Quill Delta rich text editor, slash commands overlay, floating formatting toolbar, image/table embeds, and word count stats.
* **`financial_manager_screen.dart`**: Financial dashboard, balance cards, `SegmentedButton` sub-views (`Ledger`, `Trends`, `Breakdown`, `Budgets`), and trend charts (`fl_chart`).
* **`transaction_editor_screen.dart`**: Income/expense logger with M3 **Split Buttons** and inline mathematical calculator.
* **`category_management_screen.dart`**: Custom category manager, icon picker, and cascading category rename/reassignment.
* **`period_tracker_screen.dart`**: Menstrual calendar, logging-first flow tiles (`FilledButton.tonal`), symptom chips, and moon phase illumination painter.
* **`settings_screen.dart`**: Settings cards layout, dynamic Monet toggle, module visibility toggles, backup export/import, and app lock configuration.
* **`app_lock_screen.dart`**: Stack overlay preserving state during app pause, handling biometric/PIN auth and native picker lock bypasses.
* **`changelog_screen.dart`**: Version release notes history viewer.
* **`filtered_notes_screen.dart`**, **`manage_tags_screen.dart`**, **`sms_contacts_screen.dart`**, **`sms_rules_screen.dart`**.

### E. Widgets & UI Components (`lib/widgets/`)
* **`universal_search_overlay.dart`**: Unified search overlay morphing top bar into Search Bar pill with debounced fuzzy matching across Notes, Transactions, and Settings.
* **`whats_new_sheet.dart`**: Release notification bottom sheet with version pills and staggered entrance animations.
* **`sms_import_sheet.dart`**: SMS auto-import verification sheet.
* **`moon_phase_painter.dart`**: Custom painter rendering live illuminated moon phase rings.
* **`skeleton_card.dart`**: Shared skeleton loading placeholders replacing circular progress spinners.
* **`home/`**: `home_app_bar.dart`, `note_card.dart`, `folder_drawer.dart`.

### F. Theme & Utilities (`lib/theme/` & `lib/utils/`)
* **`app_theme.dart`**: Material 3 `ThemeData` setup, `ColorScheme.fromSeed`, 30-style M3 typography scale, and `AppSemanticColors` (`ThemeExtension`).
* **`app_layout.dart`**: Design system tokens (`radiusS/M/L/XL/XXL/MAX`, spacing tokens, theme-aware soft shadows).
* **`app_globals.dart`**: Global keys (`appNavigatorKey`, `appScaffoldMessengerKey`).
* **`app_route.dart`**: SharedAxis horizontal transition route pusher.
* **`widget_helper.dart`**: Android Home Screen Widget SharedPreferences bridge writer.

---

## 3. Platform Integrations & System Channels

### Native Android Bridge (`android/`)
* **`MainActivity.kt`**: Native biometric auth channels, share intent handlers (`PROCESS_TEXT`, `SEND`), and PendingIntent shortcuts.
* **`WidgetProvider.kt`**: Android Home Screen RemoteViews widget provider (3x2 and 4x2 fixed grid lock) reading system Monet colors (`res/values-v31/colors.xml`).
* **`AndroidManifest.xml`**: Hardware features (`telephony`, `camera` marked `required="false"`), permissions, and WorkManager receiver declarations.

---

## 4. Key Cross-Module Dependency Rules & Flow Mapping

```
[Search Trigger / Widget Shortcut]
       │
       ▼
[UniversalSearchOverlay] ──(150ms debounce)──► [NoteProvider / DB Query]
       │
       ▼
[AppLockScreen Overlay]
  ├── Intercepts App Pause / Resume
  ├── Bypassed by AppLockScreen.ignoreNextResumeLock() before FilePicker/UrlLaunch
  └── Queues shared media in AppLockScreen.pendingSharedMedia
```

---

## 5. Automated Map Maintenance Protocol
1. **Skill Trainer Trigger**: Whenever `skill-trainer` extracts new session learnings, it MUST check and update `.agent/map.md` to map any new files, database columns, or service interfaces.
2. **Release Workflow Trigger**: Whenever `release-management` runs `./deploy.sh`, it MUST verify that `.agent/map.md` reflects all architectural changes made in that version.
