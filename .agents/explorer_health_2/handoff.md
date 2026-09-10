# Health & Period Tracker Domain Deep Audit — Handoff Report

**Agent**: `explorer_health_2` (Health Domain Specialist Explorer)  
**Parent / Caller**: `orchestrator_2` (`d0b69a61-2db4-4a7d-beca-3c60703f7007`)  
**Working Directory**: `/Users/saadhjawwadh/Documents/Code/Note taking/.agents/explorer_health_2/`  
**Handoff Type**: Hard Handoff (Investigation Complete)  
**Timestamp**: 2026-09-07T17:52:00Z  

---

## 1. Observation

Direct code observations across `lib/features/health/`, `lib/services/`, `lib/data/`, and `lib/screens/`:

### Area 1: Cycle Prediction Algorithms & Outlier Filtering
1. **Unsorted Logs Vulnerability**:
   - `lib/services/period_prediction_service.dart:53-65`:
     ```dart
     for (int i = 0; i < limit - 1; i++) {
       final currentPeriod = logs[i].startDate;
       final previousPeriod = logs[i + 1].startDate;
       ...
       final diff = currentUtc.difference(previousUtc).inDays;
       if (diff >= 15 && diff <= 60) {
         totalDays += diff;
         cyclesCount++;
       }
     }
     ```
     `PeriodPredictionService.calculateAverageCycleLength` and `calculateCycleStats` (lines 109-120) assume `logs` are pre-sorted descending by `startDate`. While `PeriodRepository.readAllPeriodLogs()` sorts by `startDate DESC`, when `customLogs` is passed or if user edits an historical log, unsorted lists result in negative differences that are silently filtered out or skew `latestLog = logs.first` (line 184).
2. **Fixed Luteal Phase Assumption (Non-Configurable)**:
   - `lib/services/period_prediction_service.dart:37`:
     `static const int lutealPhaseLengthDays = 14;`
     The luteal phase length is hardcoded to a constant 14 days without user configuration in Settings or detection based on symptom logs. For individuals with shorter (10–12 days) or longer (15–16 days) luteal phases, predicted ovulation (`estimateOvulationDate:197`) and fertile windows are permanently misaligned by 2 to 4 days.
3. **Redundant Iterative Calculations**:
   - `lib/features/health/providers/period_tracker_provider.dart:46-50`:
     ```dart
     _predictedNextPeriod = await PeriodPredictionService.estimateNextPeriod(_logs);
     _predictedOvulation = await PeriodPredictionService.estimateOvulationDate(_logs);
     _daysUntilNext = await PeriodPredictionService.daysUntilNextPeriod(_logs);
     _cycleStats = await PeriodPredictionService.calculateCycleStats(_logs);
     await _calculateCyclePhase();
     ```
     In a single `loadData()` invocation, `calculateAverageCycleLength(_logs)` is called 5 times independently (inside `estimateNextPeriod`, `estimateOvulationDate` -> `estimateNextPeriod`, `daysUntilNextPeriod` -> `estimateNextPeriod`, and directly in `_calculateCyclePhase`).
4. **Bleeding Duration Calculation Limits**:
   - `lib/services/period_prediction_service.dart:84-95`:
     `for (final log in finishedLogs.take(6))` checks `if (days >= 1 && days <= 14)` and defaults to `5` days if no finished logs exist.

---

### Area 2: Phase Calculation Accuracy & Discrepancies
1. **Severe Internal Discrepancy between Phase Guide & Provider**:
   - `lib/features/health/presentation/screens/period_tracker_screen.dart:89-98` (`_showPhaseGuideDialog`):
     - Menstrual Phase: Days 1–5
     - Follicular Phase: **Days 6–13**
     - Ovulatory Phase: **Days 14–16**
     - Luteal Phase: Days 17–28
   - `lib/features/health/providers/period_tracker_provider.dart:78-90` (`_calculateCyclePhase`):
     - Menstrual Phase: Days 1–5
     - Follicular Phase: **Days 6–11**
     - Ovulatory Phase: **Days 12–16**
     - Luteal Phase: Days 17+
     The in-app UI guide displays completely different phase day boundaries than the provider calculates.
2. **Disconnection from Dynamic Cycle Length & Ovulation Prediction**:
   - `lib/features/health/providers/period_tracker_provider.dart:84`:
     `else if (cycleDay >= 12 && cycleDay <= 16) { _currentPhase = 'Ovulatory Phase'; }`
     This hardcodes the Ovulatory Phase to days 12–16 regardless of whether the user has a 21-day cycle or a 38-day cycle.
     Yet `PeriodPredictionService.estimateOvulationDate` calculates ovulation as `nextPeriod - 14 days`. For a 35-day cycle:
     - `PeriodCalendarCard` highlights Day 20–22 as ovulation.
     - `PeriodTrackerProvider` and `CyclePhaseHeroCard` report "Luteal Phase" starting on Day 17 (4 days *before* ovulation).
3. **Overdue / Late Cycle Modulo Bug**:
   - `lib/features/health/providers/period_tracker_provider.dart:74-76`:
     ```dart
     final diff = todayUtc.difference(startUtc).inDays;
     final cycleDay = (diff % _avgCycleLength) + 1;
     _currentCycleDay = cycleDay;
     ```
     When a period is late/overdue (e.g. `diff = 32` days on a 28-day cycle):
     `32 % 28 = 4`, `cycleDay = 5`.
     The user is told they are on **Day 5 • Menstrual Phase** or **Day 6 • Follicular Phase** ("Estrogen rises..."), while the bottom status simultaneously displays "Period overdue by 4 days".
4. **Future Date Modulo Bug**:
   - If `startUtc` is in the future (e.g. logged tomorrow or clock skew): `diff < 0`. In Dart, `-1 % 28` is `-1`, resulting in `cycleDay = 0`. Day 0 fails all conditional checks and falls through to `'Luteal Phase'` with `_currentCycleDay = 0`.
5. **Logged Bleeding Disconnect**:
   - If a user has an active ongoing period on Day 7, `_calculateCyclePhase` reports "Follicular Phase", ignoring active bleeding. If the period ended on Day 3, Days 4 and 5 still claim "Menstrual Phase: Flow begins".

---

### Area 3: Symptom Logging & Discreet Alerts
1. **iOS Darwin Notification Channel Gap**:
   - `lib/services/notification_service.dart:156-165`:
     ```dart
     const AndroidNotificationDetails androidPlatformChannelSpecifics =
         AndroidNotificationDetails(channelId, channelName, ...);
     const NotificationDetails platformChannelSpecifics =
         NotificationDetails(android: androidPlatformChannelSpecifics);
     ```
     `_scheduleNotification` omits `DarwinNotificationDetails` for iOS, leaving iOS notifications unconfigured.
   - `lib/services/notification_service.dart:77-84`: `requestPermissions()` only resolves `AndroidFlutterLocalNotificationsPlugin`, failing to request iOS permissions (`IOSFlutterLocalNotificationsPlugin`).
2. **Missing Notification Payload on Tap**:
   - `lib/services/notification_service.dart:167-174`:
     `_notificationsPlugin.zonedSchedule` passes no `payload`. Tapping a period notification does not route to the health screen.
3. **Redundant Duplicate Notification Scheduling**:
   - `lib/features/health/data/period_repository.dart:22, 45, 56`: `createPeriodLog`, `updatePeriodLog`, and `deletePeriodLog` call `NotificationService.schedulePeriodNotifications()`.
   - `lib/features/health/providers/period_tracker_provider.dart:53`: `loadData()` also calls `NotificationService.schedulePeriodNotifications()`.
   Every write operation triggers two consecutive scheduling passes.

---

### Area 4: Offline Database Safety & Data Integrity
1. **Missing Soft-Delete (`deletedAt`) & Tombstones in `period_logs`**:
   - `lib/data/period_log_model.dart:4-18`: `PeriodLog` has only `id`, `startDate`, `endDate`, `intensity`, `notes`, `symptoms`. No `deletedAt`, no `updatedAt`/`dateModified`.
   - `lib/features/health/data/period_repository.dart:51-60`: `deletePeriodLog(id)` executes a HARD DELETE:
     `await db.delete(TableNames.periodLogs, where: '${PeriodLogFields.id} = ?', whereArgs: [id]);`
   - `lib/services/sync_merge_service.dart:294-301`:
     ```dart
     if (remoteData.containsKey('periodLogs') && remoteData['periodLogs'] is List) {
       for (final item in remoteData['periodLogs'] as List) {
         batch.insert('period_logs', Map<String, Object?>.from(item), conflictAlgorithm: ConflictAlgorithm.replace);
         periodLogsMerged++;
       }
     }
     ```
     Because there are no soft-deletes or tombstone tables for `period_logs`, when a user deletes a log on Device A, syncing with Device B unconditionally re-inserts and resurrects the deleted log on Device A!
   - Lack of `updatedAt` means P2P sync cannot perform Last-Write-Wins (LWW) merge on symptom edits.

---

### Area 5: Visual Timeline Fidelity & UI/UX
1. **Missing `RepaintBoundary` on MoonPhaseWidget Canvas**:
   - `lib/widgets/moon_phase_painter.dart:25-47` & `lib/features/health/presentation/widgets/cycle_phase_hero_card.dart:48-52`:
     `MoonPhaseWidget` contains custom canvas painting and `BoxShadow` with `blurRadius: 20`, but is not wrapped in `RepaintBoundary`. This causes full repaint passes during scroll on `CustomScrollView`.
2. **Home FAB Secondary Action is a No-Op**:
   - `lib/screens/home_screen.dart:887-893`:
     ```dart
     secondaryAction: IconButton(
       tooltip: 'Jump to Today',
       icon: Icon(Icons.today, color: colorScheme.onTertiaryContainer, size: 20),
       onPressed: () async {
         await HapticFeedback.lightImpact();
       },
     ),
     ```
     The secondary action on `_buildTrackerFAB` vibrates on tap but performs no action (never scrolls or focuses today).
3. **Flow Intensity Missing Touch Constraints & Semantics**:
   - `lib/features/health/presentation/widgets/period_log_dashboard_card.dart:233-268`:
     Flow intensity options use raw `GestureDetector` without `Semantics(button: true)` or minimum $48\times 48\text{dp}$ touch target constraints.
4. **Action Icon Compact Hit Constraints**:
   - `lib/features/health/presentation/widgets/period_log_dashboard_card.dart:145-154`:
     Edit and Delete `IconButton`s use `size: 18` and `visualDensity: VisualDensity.compact` without minimum $48\times 48\text{dp}$ touch constraints.

---

### Area 6: Invariant & Design System Alignment (AGENTS.md)
1. **Hardcoded Static Colors (Violation of Invariant 1)**:
   - `lib/features/health/presentation/widgets/cycle_insights_card.dart:18-21`:
     ```dart
     if (stats.regularityScore >= 88.0) return Colors.green;
     if (stats.regularityScore >= 75.0) return Colors.teal;
     if (stats.regularityScore >= 60.0) return Colors.orange;
     ```
   - `lib/features/health/presentation/widgets/cycle_insights_card.dart:91`:
     `color: Colors.pinkAccent`
   - `lib/features/settings/presentation/screens/settings_screen.dart:634, 638`:
     `accentColor: const Color(0xFFF43F5E)`, `iconColor: const Color(0xFFF43F5E)`
2. **Dynamic Hero Card Opacities (Violation of Invariant 1 & Rule 42)**:
   - `lib/features/health/presentation/widgets/cycle_phase_hero_card.dart:41-42`:
     `color: phaseColor.withValues(alpha: isDark ? 0.20 : 0.45)`
     Uses `0.45` alpha in Light Mode instead of the required `0.50–0.55` (50%–55%) alpha for hero cards.
3. **Magic Numbers in Hero Card Padding (Violation of Invariant 1)**:
   - `lib/features/health/presentation/widgets/cycle_phase_hero_card.dart:45, 53`:
     `padding: const EdgeInsets.all(20.0)` and `const SizedBox(width: 20)` instead of `AppLayout.spaceL` (16) or `AppLayout.spaceXL` (24).
4. **Scope Pill Non-Interactive**:
   - `lib/features/health/presentation/screens/period_tracker_screen.dart:292-327`:
     Tonal scope pill `[ 🌸 Day X • Phase ]` is a static `Container` with no `onTap` gesture. In Notes and Finances, the scope pill triggers a modal selector. Tapping it here should open `_showPhaseGuideDialog(context)`.

---

## 2. Logic Chain

1. **Prediction Algorithms & Redundant Load Chains**:
   - Observation 1.1 shows that unsorted logs compromise cycle calculations. Sorting `logs` descending at the entry of `calculateAverageCycleLength` guarantees mathematical correctness even with custom or imported log lists.
   - Observation 1.3 shows that calling 5 separate async functions in `PeriodTrackerProvider.loadData()` causes 5 redundant calculations of the same rolling average. Passing the computed average into child calculations eliminates 80% of prediction overhead.
2. **Phase Calculation Soundness**:
   - Observations 2.1 & 2.2 reveal that hardcoding Days 12–16 as Ovulatory Phase contradicts both medical biology and the app's own `estimateOvulationDate` calculation. Calculating phases proportionally based on `avgCycleLength` and `ovulationDay = (avgCycleLength - lutealPhaseLengthDays)` aligns the calendar, top bar scope pill, and hero card.
   - Observation 2.3 shows that `diff % _avgCycleLength` causes overdue cycles to cycle back to Day 1–5, confusing users. When `diff >= avgCycleLength`, clamping the day to `diff + 1` and labeling the phase as "Luteal Phase (Late / Overdue)" maintains physiological coherence.
3. **P2P Sync Tombstone Invariant**:
   - Observation 4.1 demonstrates that without `deletedAt` or a tombstone table, P2P sync is not non-destructive and violates AGENTS.md Invariant 6. Applying soft-delete parity or tombstone tracking (`deleted_period_logs`) prevents resurrection.
4. **Design System & Invariant Compliance**:
   - Observations 5.3, 6.1, 6.2, 6.3 demonstrate violations of AGENTS.md Invariants 1, 10, and 13. Replacing static colors with `colorScheme` / `AppSemanticColors`, enforcing 50%–55% hero opacity, adding 48dp touch constraints, and replacing raw flow intensity gestures with `SegmentedButton` ensures full system consistency.

---

## 3. Caveats

1. **Medical Irregularity vs Clinical Amenorrhea**: Outlier filtering ($15 \le \text{cycle} \le 60$ days) intentionally ignores cycles outside this band to protect rolling averages from postpartum or medical anomalies. Users with cycles $>60$ days should see clear clinical guidance.
2. **Read-Only Scope**: In strict compliance with explorer instructions, zero modifications were made to production source code during this audit.
3. **Platform Differences**: Exact notification alarms on Android require `SCHEDULE_EXACT_ALARM` permissions; iOS notifications require Darwin authorization.

---

## 4. Conclusion & Level 1 Action Plan

The Health & Period Tracker module possesses strong foundations (SQLCipher local encryption, TableCalendar integration, M3 borderless header, discreet alert wording). However, it contains several critical logic discrepancies, missing P2P sync tombstones, and touch target / theme token invariant gaps.

### Level 1 Work Packages (Foundational, High-Impact, Low-Risk)

| ID | Category | Target File & Lines | Description & Technical Solution |
|---|---|---|---|
| **HT-01** | Logic / Medical | `lib/features/health/providers/period_tracker_provider.dart:60-91` | **Dynamic Phase Calculation & Overdue Safeguard**: Compute ovulation day dynamically (`avgCycleLength - 14`). Split phases into: Menstrual (active bleeding or Days 1 to avgPeriodDuration), Follicular (end of bleeding to ovulation - 2), Ovulatory (ovulation - 1 to ovulation + 1), Luteal (post-ovulation to avgCycleLength). If `diff >= avgCycleLength`, maintain Late/Overdue Luteal phase instead of looping modulo back to Day 1. |
| **HT-02** | UI / Invariant | `lib/features/health/presentation/screens/period_tracker_screen.dart:80-108` | **Phase Guide Alignment & Interactive Scope Pill**: Align `_showPhaseGuideDialog` day ranges with dynamic provider definitions. Wrap top bar scope pill `[ 🌸 Day X • Phase ]` in `BouncingWidget` / `InkWell` to open `_showPhaseGuideDialog(context)` on tap. |
| **HT-03** | Invariant / UI | `lib/features/health/presentation/widgets/period_log_dashboard_card.dart:227-270` | **Flow Intensity Modernization & Touch Bounds**: Refactor 4-tier flow intensity selector into `SegmentedButton<String>` with `showSelectedIcon: false` (matching `PeriodLogEditorSheet:231`) or wrap each item in `Semantics(button: true)` with `BoxConstraints(minHeight: 48, minWidth: 48)`. |
| **HT-04** | Invariant / Tokens | `lib/features/health/presentation/widgets/cycle_insights_card.dart:18-21, 91` | **Eliminate Static Colors**: Replace `Colors.green`, `Colors.teal`, `Colors.orange` with semantic tokens (`colorScheme.primary`, `colorScheme.tertiary`, `colorScheme.error`). Replace `Colors.pinkAccent` with `semantic?.phaseMenstrual ?? colorScheme.error`. |
| **HT-05** | Invariant / Tokens | `lib/features/health/presentation/widgets/cycle_phase_hero_card.dart:40-54` | **Hero Card Alpha & Layout Tokens**: Update Light Mode container alpha to `0.52` (50%–55% range per Invariant 1). Replace magic numbers `20.0` with `AppLayout.spaceL` (16) and `AppLayout.spaceXL` (24). Wrap `MoonPhaseWidget` in `RepaintBoundary`. |
| **HT-06** | Logic / UI | `lib/screens/home_screen.dart:887-893` | **Fix Dummy FAB Action**: Connect `secondaryAction` on `_buildTrackerFAB` (`Icons.today`) to set `_focusedDay = DateTime.now()` and trigger scroll to top, eliminating the no-op tap. |
| **HT-07** | Performance | `lib/features/health/providers/period_tracker_provider.dart:45-50` | **Eliminate Redundant Prediction Recalculations**: Pass precomputed `_avgCycleLength` into `estimateNextPeriod`, `estimateOvulationDate`, and `daysUntilNextPeriod`, eliminating 4 redundant asynchronous loops per load. |
| **HT-08** | Platform / Safety | `lib/services/notification_service.dart:77-84, 156-174` | **iOS Notification Configuration & Navigation Payload**: Add `DarwinNotificationDetails` to `_scheduleNotification`, request iOS authorization in `requestPermissions()`, and supply payload `'health:tracker'` to open the tracker tab when tapped. |
| **HT-09** | Data / Sync | `lib/services/sync_merge_service.dart:294-301` & `lib/data/period_log_model.dart` | **P2P Sync Tombstone & Soft-Delete Parity**: Add `deleted_period_logs` tombstone table or `deletedAt` column to prevent deleted period records on Device A from resurrecting upon Wi-Fi sync with Device B. |

---

## 5. Verification Method

### Automated Independent Verification
1. **Run Health Unit & Provider Tests**:
   ```bash
   flutter test test/period_tracker_phase4_features_test.dart
   ```
   *Expectation*: All 4 tests pass (0 failures).
2. **Run Full Workspace Static Analysis**:
   ```bash
   flutter analyze
   ```
   *Expectation*: Zero issues found.

### Target Test Extensions for Implementation Phase
- `test/period_tracker_phase_calculation_test.dart`:
  - Unit test verifying dynamic phase calculation for short (22-day), standard (28-day), and long (36-day) cycles.
  - Unit test verifying that overdue days ($> \text{avgCycleLength}$) do NOT reset cycle day to Menstrual Phase.
  - Unit test verifying that unsorted `PeriodLog` lists calculate correct average cycle lengths.
  - Widget test verifying that `CycleInsightsCard` renders without static `Colors.*` tokens across light and dark themes.
  - Widget test verifying that tapping the scope pill opens the cycle phase guide dialog.
