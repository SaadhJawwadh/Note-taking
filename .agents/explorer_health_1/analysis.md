# Health Tracker Domain Audit & Architectural Blueprint

**Author**: Health Tracker Domain Specialist Explorer  
**Date**: 2026-08-30  
**Scope**: `lib/features/health/`, `lib/services/period_prediction_service.dart`, `lib/services/notification_service.dart`, `lib/data/period_log_model.dart`, related database models and tests  
**Status**: Comprehensive Read-Only Audit Complete  

---

## 1. Executive Summary & Architecture Overview

The **Health Tracker** domain in Everything App provides an offline-first, mathematically rigorous, privacy-centric menstrual cycle and symptom tracking system. Built with Flutter, Dart, SQLCipher encryption, and Material 3 Expressive theming, the feature operates with zero cloud dependencies and absolute data sovereignty.

### Module Topology

```
lib/features/health/
├── data/
│   └── period_repository.dart                # SQLite CRUD operations, notification rescheduling triggers
├── presentation/
│   ├── screens/
│   │   └── period_tracker_screen.dart        # Main scrollable view, FrostedGlass SliverAppBar, phase guide
│   └── widgets/
│       ├── cycle_insights_card.dart          # 3-metric statistics card & regularity scoring pill
│       ├── cycle_phase_hero_card.dart        # M3 tonal hero card with dynamic canvas lunar visualizer
│       ├── period_calendar_card.dart         # TableCalendar with custom phase & prediction builders
│       ├── period_log_dashboard_card.dart    # Day-focused logging, flow intensity, collapsible symptoms
│       └── period_log_editor_sheet.dart      # Modal bottom sheet for manual date/symptom editing
└── providers/
    └── period_tracker_provider.dart          # ChangeNotifier managing predictions, phases & optimistic state

lib/data/
├── period_log_model.dart                     # PeriodLog entity (id, startDate, endDate, intensity, symptoms)
├── database_constants.dart                   # TableNames.periodLogs and PeriodLogFields constants
└── database_helper.dart                      # Schema definition, PRAGMA WAL mode, performance indexes

lib/services/
├── period_prediction_service.dart            # Mathematical prediction engine (rolling averages, stdDev)
├── notification_service.dart                 # Pre-scheduled discreet local alerts (T-2d, T-1d, T+1d)
├── backup_service.dart                       # AES-256 encrypted JSON backup & restore
└── sync_merge_service.dart                   # P2P bi-directional LWW Wi-Fi delta merge engine
```

---

## 2. Audit Scope 1: Rolling Average Predictions, Period Duration & Ovulation Estimation

### 2.1 Cycle Length Rolling Average Calculation
* **File**: `lib/services/period_prediction_service.dart` (Lines 41–72)
* **Algorithm**:
  - Requires at least 2 logs to compute intervals; falls back to `normalCycleLengthDays = 28` if `< 2` logs.
  - Samples up to the most recent 7 logs (`final limit = logs.length > 7 ? 7 : logs.length;`), computing up to 6 cycle deltas.
  - Interval delta is calculated in UTC day differences:
    $$\Delta = \text{Date}_{\text{current}} - \text{Date}_{\text{previous}}$$
  - Averages all valid intervals and rounds to nearest integer:
    $$\text{AvgCycleLength} = \text{round}\left(\frac{\sum \Delta_i}{N}\right)$$
* **Fallback**: Returns 28 days if no intervals meet the outlier criteria.

```dart
// lib/services/period_prediction_service.dart:53-65
for (int i = 0; i < limit - 1; i++) {
  final currentPeriod = logs[i].startDate;
  final previousPeriod = logs[i + 1].startDate;

  final currentUtc = DateTime.utc(currentPeriod.year, currentPeriod.month, currentPeriod.day);
  final previousUtc = DateTime.utc(previousPeriod.year, previousPeriod.month, previousPeriod.day);

  final diff = currentUtc.difference(previousUtc).inDays;
  if (diff >= 15 && diff <= 60) {
    totalDays += diff;
    cyclesCount++;
  }
}
```

### 2.2 Period Bleeding Duration Calculation
* **File**: `lib/services/period_prediction_service.dart` (Lines 75–96)
* **Algorithm**:
  - Filters logs where `endDate != null` (completed bleeding episodes).
  - Takes the latest 6 completed logs.
  - Duration is inclusive of start and end days:
    $$\text{Duration} = (\text{EndDate} - \text{StartDate})_{\text{inDays}} + 1$$
  - Outlier filtering: Only counts durations where $1 \le \text{Duration} \le 14$ days.
  - Fallback: Defaults to 5 days if no completed logs exist.

### 2.3 Cycle Regularity & Statistical Score
* **File**: `lib/services/period_prediction_service.dart` (Lines 99–174)
* **Mathematical Model**:
  - Calculates the sample mean ($\mu$) and variance ($\sigma^2$) across recorded valid cycle lengths:
    $$\mu = \frac{1}{N}\sum_{i=1}^N \Delta_i, \quad \sigma = \sqrt{\frac{1}{N}\sum_{i=1}^N (\Delta_i - \mu)^2}$$
  - Calculates maximum variation: $\text{maxDiff} = \max_i |\Delta_i - \text{round}(\mu)|$.
  - Regularity Score:
    $$\text{Score} = \text{clamp}\Big(100.0 - (\sigma \times 12.0),\, 20.0,\, 100.0\Big)$$
  - Regularity Tier Mapping:
    - $\sigma \le 1.5\text{ days} \implies$ `'Very Regular'`
    - $\sigma \le 3.0\text{ days} \implies$ `'Regular'`
    - $\sigma \le 5.5\text{ days} \implies$ `'Mildly Irregular'`
    - $\sigma > 5.5\text{ days} \implies$ `'Irregular'`
    - Single cycle recorded $\implies$ Default score $90.0\%$, `'Regular'`.

### 2.4 Next Period & Ovulation Estimation
* **File**: `lib/services/period_prediction_service.dart` (Lines 178–211)
* **Formulas**:
  - **Estimated Next Period**:
    $$\text{NextPeriodStart} = \text{LatestLog.startDate} + \text{Duration}(\text{days}: \text{AvgCycleLength})$$
  - **Ovulation Date** (based on clinical 14-day luteal phase invariant):
    $$\text{OvulationDate} = \text{NextPeriodStart} - \text{Duration}(\text{days}: 14)$$
  - **Days Until Next Period**:
    $$\text{DaysUntilNext} = \text{NextPeriodStart}_{\text{UTC}} - \text{Today}_{\text{UTC}}$$
    (Positive = upcoming in $X$ days; Negative = overdue by $X$ days; $0$ = expected today).

### 2.5 Phase Progress & Physiological Guidance
* **File**: `lib/features/health/providers/period_tracker_provider.dart` (Lines 58–89)
* **Cycle Day Calculation**:
  $$\text{CycleDay} = \Big((\text{Today}_{\text{UTC}} - \text{LatestStartDate}_{\text{UTC}})_{\text{inDays}} \pmod{\text{AvgCycleLength}}\Big) + 1$$
* **Phase Boundaries**:
  - **Days 1–5**: `Menstrual Phase` — *"Flow begins. Progesterone and estrogen levels drop. Rest and nurture yourself."*
  - **Days 6–11**: `Follicular Phase` — *"Estrogen rises, boosting energy, mood, and focus. Great time for planning."*
  - **Days 12–16**: `Ovulatory Phase` — *"Estrogen peaks, triggering ovulation. High energy and social openness."*
  - **Days 17–Avg**: `Luteal Phase` — *"Progesterone peaks, winding down energy. Prioritize self-care."*

---

## 3. Audit Scope 2: Outlier Filtering & Overlap Protection

### 3.1 Cycle Interval Outlier Filter
* **Observation**: Both `calculateAverageCycleLength` (line 61) and `calculateCycleStats` (line 117) apply strict bounding:
  ```dart
  if (diff >= 15 && diff <= 60)
  ```
* **Clinical Rationale**:
  - Cycles $< 15$ days represent non-menstrual intermenstrual spotting, hormonal breakthrough bleeding, or duplicate user entries.
  - Cycles $> 60$ days represent missed cycles (amenorrhea), pregnancy, postpartum gaps, or periods of app non-usage.
  - Including these extremes would heavily distort standard deviation and skew future calendar predictions.

### 3.2 Bleeding Duration Outlier Filter
* **Observation**: `calculateAveragePeriodDuration` (line 88) applies:
  ```dart
  if (days >= 1 && days <= 14)
  ```
* **Rationale**: Filters out accidental unclosed period logs (e.g. user started a period months ago and forgot to set an end date).

### 3.3 Strict Overlap Guardrail
* **File**: `lib/features/health/providers/period_tracker_provider.dart` (Lines 128–144)
* **Implementation**:
  ```dart
  bool checkOverlap(DateTime start, DateTime? end, [String? excludeId]) {
    final s1 = DateTime.utc(start.year, start.month, start.day);
    final e1 = end != null ? DateTime.utc(end.year, end.month, end.day) : DateTime.utc(2999, 12, 31);

    for (final log in _logs) {
      if (excludeId != null && log.id == excludeId) continue;
      final s2 = DateTime.utc(log.startDate.year, log.startDate.month, log.startDate.day);
      final e2 = log.endDate != null
          ? DateTime.utc(log.endDate!.year, log.endDate!.month, log.endDate!.day)
          : DateTime.utc(2999, 12, 31);

      if (s1.isBefore(e2.add(const Duration(days: 1))) && e1.isAfter(s2.subtract(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }
  ```
* **Verification**: Prevents overlapping entries across `createLog()`, `updateLog()`, `togglePeriodStatus()`, and `PeriodLogEditorSheet`.

---

## 4. Audit Scope 3: Semantic Phase Tokens & M3 Expressive Visual Design

### 4.1 Theme Token Definitions (`AppSemanticColors`)
* **File**: `lib/core/theme/app_theme.dart` (Lines 9–67)
* **Tokens**:
  | Token | Light Mode Value | Dark Mode Value | Semantic Role |
  |---|---|---|---|
  | `phaseMenstrual` | `#D32F2F` (Crimson Red) | `#EF9A9A` (Soft Coral) | Menstrual Flow |
  | `phaseFollicular` | `#1976D2` (Ocean Blue) | `#90CAF9` (Sky Blue) | Estrogen Rise |
  | `phaseOvulatory` | `#F57C00` (Deep Amber) | `#FFCC80` (Warm Sun) | Peak Fertility |
  | `phaseLuteal` | `#7B1FA2` (Royal Purple) | `#CE93D8` (Lavender) | Progesterone Phase |

### 4.2 Cycle Moon Phase Hero Card (`CyclePhaseHeroCard`)
* **File**: `lib/features/health/presentation/widgets/cycle_phase_hero_card.dart`
* **Visual Specifications**:
  - Uses `AppCard.tonal` with dynamic container alpha: `phaseColor.withValues(alpha: isDark ? 0.20 : 0.45)`.
  - 1.2px accent border: `phaseColor.withValues(alpha: isDark ? 0.35 : 0.45)`.
  - Border radius: `AppLayout.radiusXL` (28dp).
  - Lunar progression value:
    $$\text{phaseValue} = \text{clamp}\left(\frac{\text{cycleDay} - 1}{\text{avgCycleLength}},\, 0.0,\, 1.0\right)$$
    - $0.0 / 1.0$ = New Moon (Menstrual start)
    - $0.5$ = Full Moon (Ovulation peak)
* **Canvas Trigonometric Rendering (`MoonPhasePainter`)**:
  - **File**: `lib/widgets/moon_phase_painter.dart` (Lines 51–140)
  - Custom canvas geometry drawing unlit background circle, glowing outer ring (`blurRadius: 20`), and waxing/waning elliptical arcs based on control factor:
    $$\text{control} = \frac{\text{phase} - 0.25}{0.25} \quad (\text{Waxing}), \quad \text{control} = \frac{\text{phase} - 0.75}{0.25} \quad (\text{Waning})$$

### 4.3 Period & Ovulation Calendar Card (`PeriodCalendarCard`)
* **File**: `lib/features/health/presentation/widgets/period_calendar_card.dart`
* **Calendar Builders**:
  - **Logged Period Days**: Solid circle filled with `phaseMenstrual` color.
  - **Predicted Period Days (5-day window)**: Translucent outlined circle with `phaseMenstrual.withValues(alpha: 0.20)`.
  - **Ovulation Window (3-day window)**: Outlined circle in `colorScheme.tertiaryContainer`.
  - **Today / Selected Marker**: High-contrast outline ring preserving underlying phase dot.

### 4.4 Top Header Tonal Scope Pill
* **File**: `lib/features/health/presentation/screens/period_tracker_screen.dart` (Lines 292–327)
* **Design Token Compliance**:
  - Container fill: `phaseColor.withValues(alpha: isDark ? 0.22 : 0.16)`.
  - Outline: `Border.all(color: phaseColor.withValues(alpha: 0.35), width: 1.0)`.
  - Icon: `Icons.spa_rounded` (13dp).
  - Label: `Day X • Phase` (11pt `FontWeight.w600`).

---

## 5. Audit Scope 4: Discreet Notifications & Privacy Copy

### 5.1 Notification Scheduling Architecture
* **File**: `lib/services/notification_service.dart` (Lines 86–175)
* **Execution Points**:
  1. Triggered on period log creation, update, or deletion via `PeriodRepository`.
  2. Triggered on app launch via `SettingsProvider.loadSettings()` and `PeriodTrackerProvider.loadData()`.
  3. Triggered when `SettingsProvider.setIsPeriodTrackerEnabled(true)` is toggled.
* **Notification Rules**:
  - **Channel**: `period_tracker_channel`, `'Period Tracker Alerts'`.
  - **Time Normalization**: Standardized to 9:00 AM local time via `_normalizeTime(DateTime date)`.
  - **Scheduled Dates**:
    - **ID 1**: 2 days prior to predicted start (`nextPeriodDate.subtract(const Duration(days: 2))`).
    - **ID 2**: 1 day prior to predicted start (`nextPeriodDate.subtract(const Duration(days: 1))`).
    - **ID 3**: 1 day overdue (`nextPeriodDate.add(const Duration(days: 1))`).

### 5.2 Privacy Copy Guardrail
* **Notification Content**:
  - `title: 'Reminder'` (Completely non-revealing; contains zero medical or menstrual keywords).
  - `body: discreetText` (Defaults to `'Check the app'`; fully user-customizable in `SettingsScreen` via `_showNotificationTextDialog`).
* **ID Isolation**:
  - IDs 1, 2, and 3 are reserved exclusively for Period Tracker.
  - Note Reminders use high-range hash masks (`0x4E000000 | (noteId.hashCode & 0x00FFFFFF)`).
  - Pro-Tips use `0x544950`.
  - Blanket `cancelAll()` is strictly avoided so period updates never wipe user note reminders.

---

## 6. Audit Scope 5: Biometric Privacy Masking & Sensitive Data Protection

### 6.1 Database Storage Encryption
* **File**: `lib/data/database_helper.dart`
* Period logs are stored inside the encrypted SQLCipher table `period_logs`:
  ```sql
  CREATE TABLE IF NOT EXISTS period_logs (
    id TEXT PRIMARY KEY,
    startDate TEXT NOT NULL,
    endDate TEXT,
    intensity TEXT NOT NULL,
    notes TEXT NOT NULL DEFAULT '',
    symptoms TEXT NOT NULL DEFAULT '[]'
  );
  ```
* SQLite database is opened with a KeyStore/Keychain-backed 256-bit passphrase and WAL mode enabled (`PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL;`).

### 6.2 Resilient Backup Encryption
* **File**: `lib/services/backup_service.dart` (Lines 74, 116, 351, 467)
* `period_logs` are serialized into encrypted JSON backups (`exportEncryptedBackup`), guarded with AES-256-GCM encryption. Unencrypted exports of sensitive period logs are prohibited.

### 6.3 Full App Biometric Privacy Blur Mask
* **File**: `lib/screens/app_lock_screen.dart` (Lines 240–325)
* When App Lock is enabled:
  - App window is obscured behind a 25.0 sigma Gaussian blur `BackdropFilter` with `surfaceContainerLow` fill.
  - Underlying widget hierarchy is wrapped in `IgnorePointer(ignoring: true)` to prevent tap-throughs or accessibility screen-readers from reading cycle details while locked.
  - Biometric / PIN authentication prompt must succeed before health views are rendered.

### 6.4 Modular Feature Gating
* Period tracking is disabled by default (`isPeriodTrackerEnabled = false`).
* When disabled, the Health navigation destination, FAB, and background notification tasks remain completely inactive.

---

## 7. Audit Scope 6: 0ms Optimistic UI & Identified Critical Jitter Defect

### 7.1 The Critical Defect Identified
* **Files Affected**:
  - `lib/features/health/providers/period_tracker_provider.dart` (Lines 190–234)
  - `lib/features/health/presentation/screens/period_tracker_screen.dart` (Lines 209–226)

#### The Execution Trace:
1. User taps a symptom chip (e.g. `'Cramps'`) or changes flow intensity (e.g. `'Heavy'`).
2. `toggleSymptom()` or `updateIntensity()` updates the local in-memory log optimistically:
   ```dart
   // lib/features/health/providers/period_tracker_provider.dart:224-228
   final idx = _logs.indexWhere((l) => l.id == log.id);
   if (idx != -1) {
     _logs[idx] = updated;
     notifyListeners(); // 0ms UI update
   }
   ```
3. Immediately afterwards, it triggers SQLite persistence and calls `loadData()`:
   ```dart
   await PeriodRepository.instance.updatePeriodLog(updated);
   await loadData();
   ```
4. `loadData()` begins with:
   ```dart
   // lib/features/health/providers/period_tracker_provider.dart:40-41
   _isLoading = true;
   notifyListeners();
   ```
5. `PeriodTrackerScreen.build()` evaluates `provider.isLoading`:
   ```dart
   // lib/features/health/presentation/screens/period_tracker_screen.dart:209-226
   if (provider.isLoading) {
     return Scaffold(
       body: SafeArea(
         child: ListView(
           padding: const EdgeInsets.all(16),
           children: const [
             SkeletonCard(height: 64),
             SkeletonCard(height: 180),
             SkeletonCard(height: 120),
             SkeletonCard(height: 320),
           ],
         ),
       ),
     );
   }
   ```
6. **Failure Mode**: The user sees the symptom chip toggle for ~16ms, followed immediately by the **entire screen being unmounted and replaced with flashing skeleton loading cards**! This destroys the user's scroll position, collapses the symptom section, and creates severe visual jitter.

---

## 8. Defect Matrix & Concrete Improvement Blueprints

| Defect ID | Severity | Category | File & Line Reference | Description |
|---|---|---|---|---|
| **HT-01** | **High** | 0ms Optimistic UI / Jitter | `period_tracker_provider.dart:40-56`, `211`, `232` | `loadData()` sets `_isLoading = true` during background reloads, causing full-screen skeleton flashing upon every symptom/flow toggle. |
| **HT-02** | **Medium** | Touch Accessibility (Invariant 10) | `period_log_dashboard_card.dart:343` | Symptom chips use ~30dp vertical touch targets without `BoxConstraints(minHeight: 48)` or `Semantics(button: true)`. |
| **HT-03** | **Medium** | FAB Bottom Clearance (Invariant 8) | `period_tracker_screen.dart:511` | Bottom padding on sliver list is `32dp` instead of `AppLayout.fabBottomPadding = 96.0`, risking clipping behind bottom chrome / FAB. |
| **HT-04** | **Low** | SQLite Query Indexing (Invariant 5) | `database_helper.dart:140-150` | Missing index on `period_logs(startDate)` for ordering queries in `readAllPeriodLogs()`. |
| **HT-05** | **Low** | Architecture Cleanliness (Invariant 2) | `lib/features/health/health.dart` | 1-line re-export stub file violates SSOT rule against re-export stubs. |

---

## 9. Concrete Code Blueprints (Implementation Proposals)

### 9.1 Blueprint for HT-01: Silent Background Refresh & Invariant 11 Compliance

#### Target File: `lib/features/health/providers/period_tracker_provider.dart`

```dart
// PROPOSED REFACTOR: Support silent reload without unmounting active UI
Future<void> loadData({bool showLoading = false}) async {
  if (showLoading || _logs.isEmpty) {
    _isLoading = true;
    notifyListeners();
  }

  _logs = await PeriodRepository.instance.readAllPeriodLogs();
  _predictedNextPeriod = await PeriodPredictionService.estimateNextPeriod(_logs);
  _predictedOvulation = await PeriodPredictionService.estimateOvulationDate(_logs);
  _daysUntilNext = await PeriodPredictionService.daysUntilNextPeriod(_logs);
  _cycleStats = await PeriodPredictionService.calculateCycleStats(_logs);
  await _calculateCyclePhase();

  if (!kIsWeb) {
    await NotificationService.schedulePeriodNotifications();
  }

  _isLoading = false;
  notifyListeners();
}

// In deleteLog, updateIntensity, toggleSymptom:
Future<void> deleteLog(String id) async {
  _logs.removeWhere((l) => l.id == id);
  notifyListeners(); // 0ms immediate update

  await PeriodRepository.instance.deletePeriodLog(id);
  await loadData(showLoading: false); // Silent background reload
}

Future<void> updateIntensity(PeriodLog log, String newIntensity) async {
  final updated = log.copyWith(intensity: newIntensity);
  final idx = _logs.indexWhere((l) => l.id == log.id);
  if (idx != -1) {
    _logs[idx] = updated;
    notifyListeners(); // 0ms immediate update
  }

  await PeriodRepository.instance.updatePeriodLog(updated);
  await loadData(showLoading: false); // Silent background reload
}

Future<void> toggleSymptom(PeriodLog log, String symptom) async {
  final updatedSymptoms = List<String>.from(log.symptoms);
  if (updatedSymptoms.contains(symptom)) {
    updatedSymptoms.remove(symptom);
  } else {
    updatedSymptoms.add(symptom);
  }
  final updated = log.copyWith(symptoms: updatedSymptoms);

  final idx = _logs.indexWhere((l) => l.id == log.id);
  if (idx != -1) {
    _logs[idx] = updated;
    notifyListeners(); // 0ms immediate update
  }

  await PeriodRepository.instance.updatePeriodLog(updated);
  await loadData(showLoading: false); // Silent background reload
}
```

### 9.2 Blueprint for HT-02: Touch Accessibility & Semantics

#### Target File: `lib/features/health/presentation/widgets/period_log_dashboard_card.dart`

```dart
// PROPOSED REFACTOR: Wrap symptom chips in accessible touch targets
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: _predefinedSymptoms.map((symptom) {
    final isSelected = selectedLog.symptoms.contains(symptom);
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$symptom symptom',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppLayout.radiusM),
          onTap: () async {
            await HapticFeedback.selectionClick();
            await widget.provider.toggleSymptom(selectedLog, symptom);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppLayout.radiusM),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.4)
                    : colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: Text(
              symptom,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }).toList(),
)
```

### 9.3 Blueprint for HT-03: Bottom Clearance Compliance

#### Target File: `lib/features/health/presentation/screens/period_tracker_screen.dart`

```dart
// Line 511: Replace hardcoded 32dp bottom padding with AppLayout.fabBottomPadding
Padding(
  padding: const EdgeInsets.fromLTRB(16, 12, 16, AppLayout.fabBottomPadding),
  child: PeriodCalendarCard(
    focusedDay: _focusedDay,
    selectedDay: _selectedDay,
    provider: provider,
    onDaySelected: (selected, focused) {
      setState(() {
        _selectedDay = selected;
        _focusedDay = focused;
      });
    },
    onPageChanged: (focused) {
      setState(() {
        _focusedDay = focused;
      });
    },
  ),
)
```

### 9.4 Blueprint for HT-04: Database Index on `period_logs(startDate)`

#### Target File: `lib/data/database_helper.dart`

```dart
// In _onOpenDB (lines 140-150):
await db.execute('CREATE INDEX IF NOT EXISTS idx_period_logs_start ON ${TableNames.periodLogs}(${PeriodLogFields.startDate});');
```

---

## 10. Verification Plan & Test Expansion Blueprint

### 10.1 Existing Test Suite Status
* Command: `flutter test test/period_tracker_phase4_features_test.dart`
* Status: **4/4 Tests Passing** (Calculations, regularities, overlaps, optimistic mutations).

### 10.2 Recommended Additional Tests
1. **Silent Background Reload Test**: Verify that calling `provider.toggleSymptom()` does NOT set `isLoading = true` when `showLoading == false`.
2. **Outlier Filtering Boundary Test**: Verify that cycles of 14 days and 61 days are strictly ignored in rolling average while cycles of 15 days and 60 days are included.
3. **Bleeding Duration Boundary Test**: Verify that bleeding durations of 0 days and 15 days are ignored while 1 day and 14 days are included.
4. **Database Index Verification Test**: Verify that `idx_period_logs_start` exists in `sqlite_master`.
