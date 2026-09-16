# Health Tracker Module — M3 Expressive & System Invariant Audit Report

**Date**: 2026-09-16  
**Auditor**: Health Tracker Explorer (`explorer_health_3`)  
**Target Module**: `lib/features/health/` (Screens, Widgets, Providers, Data, Services)  
**Parent Orchestrator**: `orchestrator_3` (`6ec8d34f-5c83-44cf-b500-0dacec388c7d`)  
**Overall Compliance Score**: **93.5%** (Grade: A-)

---

## 1. Executive Summary

A comprehensive, read-only architectural, design system, and code quality audit was performed on the Health Tracker domain module (`lib/features/health/`) and its direct dependencies (`PeriodPredictionService`, `NotificationService`, `MoonPhaseWidget`).

The module demonstrates exceptional architectural maturity:
- **Zero Frosted Glass / BackdropFilter Contamination**: 100% pure solid surface container hierarchy across all views.
- **Rule 41 Parity (Zero Raw Emojis)**: Completely purged of raw emoji glyphs in favor of official Material Symbols.
- **Top Header Symmetry**: Full adherence to 16dp outer edge padding, 40x40 compact hit constraints, sub-pixel headroom (60dp / 72dp), and the canonical 3-slot action rhythm (`[ 📅 Today ]` $\rightarrow$ `[ ⋮ Health Tools ]` $\rightarrow$ `[ ⚙️ Settings ]`).
- **Mathematical Invariants**: Rolling average cycle calculations (3–7 cycles), strict outlier filtering ($<15$ or $>60$ days), and discreet notification scheduling are fully operational.
- **Dynamic Hero Card Opacities**: Lunar hero card operates at 52% container alpha in light mode and 20% in dark mode, precisely within the mandated 50–55% light / 20–22% dark standard.

Key areas requiring alignment for 100% compliance:
1. **Shape Scale Violations**: Symptom chips in `PeriodLogDashboardCard` use 12dp squircle corners (`AppLayout.radiusM`) instead of 1000dp Stadium pills (`AppLayout.radiusStadium` / `AppChip`); primary CTAs (`Start Period`, `Save Log`) use 16dp rounded rectangles instead of M3 Expressive `StadiumBorder()`.
2. **Hardcoded Color**: `const Color(0xFF1C1A22)` in `PeriodCalendarCard:62` for dark-mode `onPeriodColor`.
3. **Scroll Repaint Isolation**: Absence of `RepaintBoundary` around `PeriodCalendarCard`.
4. **Dialog Standardization**: `_showPhaseGuideDialog` uses raw unstyled `AlertDialog` rather than `AppBottomSheet` or `AppDialog`.
5. **Architectural Gaps**: Missing dedicated cycle history list with connected corner morphing, and lack of an in-screen privacy mask / biometric gate on the active tracker screen.

---

## 2. Detailed Dimension-by-Dimension Assessment

### 2.1 Surface Elevation Hierarchy & Zero Frosted Blur
- **Status**: **Compliant** (Score: 98%)
- **Findings**:
  - `grep_search` confirmed **0 instances** of `BackdropFilter` or `ImageFilter.blur` in `lib/features/health/`.
  - Scaffolding uses transparent backgrounds, letting the home screen’s solid `surface` background provide foundation.
  - **5-Tier Solid Containers**:
    - `colorScheme.surfaceContainerLow`: Top app bar header background (`period_tracker_screen.dart:284`), calendar card (`period_calendar_card.dart:66`), and flow segment background (`period_log_editor_sheet.dart:249`).
    - `colorScheme.surfaceContainerHigh`: Hero cards, `CycleInsightsCard:37`, `PeriodLogDashboardCard:92`, and tools overflow menu (`period_tracker_screen.dart:398`).
    - `colorScheme.surfaceContainerHighest`: Metric tile fills in `CycleInsightsCard:152`, unselected flow and symptom buttons (`period_log_dashboard_card.dart:251, 370`), and today indicator fill (`period_calendar_card.dart:119`).
- **Deviations**:
  - `period_tracker_screen.dart:130`: `_showPhaseGuideDialog` instantiates raw `AlertDialog` without explicitly specifying `backgroundColor: colorScheme.surfaceContainerHigh`.

---

### 2.2 Shape Scale Hierarchy
- **Status**: **Deviant / Needs Polish** (Score: 80%)
- **Findings & Invariants**:
  - **Scope Pill**: Compliant. `period_tracker_screen.dart:311, 320` uses `BorderRadius.circular(AppLayout.radiusStadium)` (1000dp).
  - **Hero & Content Cards**:
    - `CyclePhaseHeroCard:43`, `CycleInsightsCard:39`, `PeriodCalendarCard:68`, and `PeriodLogDashboardCard:99` all specify `borderRadius: AppLayout.radiusXL` (20dp).
    - Standard card squircle radius across the design system is 12–16dp (`AppLayout.radiusL`). 20dp is slightly large, though visually consistent within the module.
  - **Symptom Tags Violation**:
    - `period_log_dashboard_card.dart:371`: Symptom chips use `borderRadius: BorderRadius.circular(AppLayout.radiusM)` (12dp) via raw `AnimatedContainer`. M3 Expressive invariant mandates **Stadium pills (1000dp)** for chips, tags, and pills. Should use `AppChip` or `AppLayout.radiusStadium`.
    - `period_log_editor_sheet.dart:261`: `FilterChip` instances use default Flutter rectangular borders rather than `shape: const StadiumBorder()`.
  - **Primary CTA Shape Scale Violation**:
    - `period_log_dashboard_card.dart:167, 189, 206`: `Start Period`, `Add Period Log`, and `Stop Period` buttons use `RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusL))` (16dp) instead of `const StadiumBorder()` (1000dp).
    - `period_log_editor_sheet.dart:285`: `Save Log` button uses `borderRadius: BorderRadius.circular(AppLayout.radiusL)` (16dp) instead of `const StadiumBorder()`.
  - **Connected Corner Morphing**:
    - Currently **absent**. Cycle logs are only presented as the single selected day on `PeriodLogDashboardCard` or month cells in `PeriodCalendarCard`. There is no vertical history list of past menstrual cycles with connected corner morphing (first item top-rounded, middle items square, last item bottom-rounded).

---

### 2.3 Motion & Physics, Universal Morphing FAB & Clearance
- **Status**: **Compliant** (Score: 95%)
- **Findings**:
  - **FAB Clearance**: `PeriodTrackerScreen:540` enforces `AppLayout.fabBottomPadding` (96dp) on the terminal sliver view, preventing the calendar and log controls from being obscured by bottom chrome.
  - **Universal Morphing FAB**: `HomeScreen:968` integrates `AppMorphingFab` for the period tracker tab with dynamic icon/label (`Log Period`), tertiary container theming, scroll-aware expansion (`_isFabExpanded`), and secondary quick action (`Jump to Today`).
  - **Sliver Entrance Motion**: `PeriodTrackerScreen:470-563` wraps each sliver card in `AnimationConfiguration.staggeredList` with 220ms `SlideAnimation(verticalOffset: 24.0)` and `FadeInAnimation`.
  - **Jump to Today Motion**: `PeriodTrackerScreen:47-51` triggers `_scrollController.animateTo(0, duration: AppLayout.animDefault, curve: AppLayout.curveExpressive)`.
- **Minor Deviations**:
  - `period_log_dashboard_card.dart:340`: `AnimatedSize` uses standard `Curves.easeInOut` rather than `AppLayout.curveEmphasizedDecelerate` or `AppLayout.springFast`.

---

### 2.4 Touch & Accessibility (Touch Targets & Rule 41 Emojis)
- **Status**: **Compliant** (Score: 98%)
- **Findings**:
  - **Prohibition of Raw Text Emojis (Rule 41)**: **100% Clean**. `grep_search` confirmed 0 Unicode emoji glyphs in source. All status, flow, phase, and symptom markers use authentic Google Material Symbols:
    - Flow: `Icons.water_drop_outlined`, `Icons.water_drop`, `Icons.water`, `Icons.flood`
    - Phases: `Icons.spa_rounded`, `Icons.water_drop_rounded`, `Icons.wb_sunny_rounded`, `Icons.local_fire_department_rounded`, `Icons.nightlight_round`
    - Insights: `Icons.auto_graph_rounded`, `Icons.repeat_rounded`, `Icons.water_drop_outlined`, `Icons.swap_horiz_rounded`
    - Symptoms & Tools: `Icons.mood_outlined`, `Icons.edit_calendar_rounded`, `Icons.menu_book_rounded`, `Icons.tune_rounded`, `Icons.today_outlined`
  - **Touch Target Hit Bounds ($\ge 48 \times 48$dp)**:
    - Flow intensity buttons: Wrapped in `ConstrainedBox(constraints: const BoxConstraints(minHeight: 48))` with `Semantics(button: true, label: '$label flow', selected: isChosen)`.
    - Symptom chips: Wrapped in `ConstrainedBox(constraints: const BoxConstraints(minHeight: 48, minWidth: 48))` with `Semantics(button: true, selected: isSelected, label: symptom)`.
    - Log edit and delete buttons: `BoxConstraints(minWidth: 48, minHeight: 48)`.
    - Primary CTA buttons: `minimumSize: const Size(double.infinity, 52)` and `54`.
    - Date tiles in editor sheet: Standard `ListTile` and `SwitchListTile` ($\ge 48$dp).
    - Top bar icons: Compact 40x40dp as required by Invariant 14 for top app bars.

---

### 2.5 Top App Bar Invariants
- **Status**: **Compliant with Minor Tonal Pill Deviation** (Score: 95%)
- **Findings**:
  - **Left Header Stack**: Bold title (`Period Tracker`, 18pt bold, `titleLarge`) paired directly with interactive scope pill below.
  - **Action Order (Muscle Memory Sequence)**:
    1. Primary contextual action: `[ 📅 Today ]` (`Icons.today_outlined`, `period_tracker_screen.dart:364`)
    2. Penultimate overflow menu: `[ ⋮ Health Tools ]` (`Icons.more_vert_rounded`, `period_tracker_screen.dart:385`)
    3. Terminal right anchor: `[ ⚙️ Settings ]` (`Icons.settings_outlined`, `period_tracker_screen.dart:452`)
  - **Action Bar Constraints**: All 3 actions enforce `constraints: const BoxConstraints(minWidth: 40, minHeight: 40)`, `visualDensity: VisualDensity.compact`, and `padding: EdgeInsets.zero`.
  - **Headroom & Outer Margins**:
    - Horizontal padding: Strictly `16dp` left and `16dp` right (`EdgeInsets.only(top: padding.top + 6, left: 16, right: 16, bottom: 6)`).
    - Header height: `toolbarHeight: MediaQuery.of(context).padding.top + 72.0` with inner container `height: 60.0`, eliminating sub-pixel overflows.
  - **Overflow Menu Workflows**:
    1. `Log Cycle & Symptoms` (`PeriodLogEditorSheet`)
    2. `Cycle Phase Guide` (`_showPhaseGuideDialog`)
    3. `Cycle Preferences` (`SettingsScreen`)
- **Deviations**:
  - **Tonal Scope Pill Contrast Standard**:
    - `period_tracker_screen.dart:319`: Container background is `phaseColor.withValues(alpha: isDark ? 0.22 : 0.16)` with `phaseColor` text (`fontSize: 11`).
    - Invariant 14 states: *"Scope pills MUST use M3 Tonal Container styling (`colorScheme.primaryContainer.withValues(alpha: isDark ? 0.35 : 0.45)`) with a `1.0px` primary outline border (`colorScheme.primary.withValues(alpha: 0.28)`), `colorScheme.onSurface` label, and `colorScheme.primary` leading icon & dropdown chevron, guaranteeing 100% legibility across dynamic Material You wallpaper palettes."*
    - While `phaseColor` provides biological context, `alpha: 0.16` in Light Mode can wash out against lighter surfaces, and 11pt typography is below the standard 12–13pt label token.

---

### 2.6 Health Invariants & Algorithms
- **Status**: **Compliant** (Score: 95%)
- **Findings**:
  - **Dynamic Hero Card Opacity**:
    - `cycle_phase_hero_card.dart:41`: `color: phaseColor.withValues(alpha: isDark ? 0.20 : 0.52)`.
    - Exactly matches invariant: 52% in light mode (within 50–55% range); 20% in dark mode (within 20–22% range).
    - Border: `borderColor: phaseColor.withValues(alpha: isDark ? 0.35 : 0.45)`.
    - Border width: Hardcoded to 1.0 in `AppCard.tonal` (invariant calls for 1.2px accent borders).
  - **Cycle Rolling Average & Outlier Filtering**:
    - `PeriodPredictionService.calculateAverageCycleLength`: Averages cycles across up to the last 7 logs.
    - Outlier filtering: `if (diff >= 15 && diff <= 60)` strictly excludes cycle durations under 15 days or over 60 days from average and statistical variance calculations.
    - Bleeding duration filtering: `if (days >= 1 && days <= 14)` strictly excludes bleeding logs outside 1–14 days.
    - Fallback: Defaults to 28 days (`normalCycleLengthDays`).
  - **Ovulation & Luteal Phase**:
    - Luteal phase duration is fixed to 14 days (`lutealPhaseLengthDays = 14`).
    - Ovulation date estimated as `nextPeriod.subtract(const Duration(days: 14))`.
  - **Cycle Regularity Scoring**:
    - Calculates mathematical standard deviation of cycle lengths (`math.sqrt(variance)`).
    - Score formula: `(100.0 - (stdDev * 12.0)).clamp(20.0, 100.0)`.
    - Classifications: $\le 1.5$ ("Very Regular"), $\le 3.0$ ("Regular"), $\le 5.5$ ("Mildly Irregular"), $> 5.5$ ("Irregular").
  - **Discreet Notifications**:
    - Dedicated channel: `period_tracker_channel` ("Period Tracker Alerts").
    - Gated by `isPeriodTrackerEnabled`.
    - Notification text configurable by user via `discreetNotificationText` (default: `'Check the app'`). Title is `'Reminder'`.
    - Schedules 3 discrete notifications: 2 days before, 1 day before, and 1 day late.
    - Re-scheduled automatically on log creation, update, and deletion in `PeriodRepository`.
  - **Overdue Handling**:
    - `diff >= _avgCycleLength`: Preserves exact overdue count (`delayed by X days`) without modulo wrap-around distortion.
  - **0ms Optimistic UI**:
    - `PeriodTrackerProvider` mutates local list in 0ms for `deleteLog`, `updateIntensity`, and `toggleSymptom`, notifying listeners immediately before awaiting background SQLite updates.
- **Deviations / Feature Opportunities**:
  - **Biometric Privacy Masking on Screen**: While app-level biometric lock exists via `AppLockScreen`, there is no in-screen privacy mask or quick toggle on `PeriodTrackerScreen` to mask cycle details from shoulder-surfers in public.

---

## 3. Inventory of Deviations & Technical Debt

| Priority | File | Lines | Category | Issue Description | Proposed Remediation |
|---|---|---|---|---|---|
| **High** | `period_calendar_card.dart` | 61–64 | Design Tokens | Hardcoded dark color `const Color(0xFF1C1A22)` in `onPeriodColor`. | Replace with `colorScheme.surfaceContainerLow` or semantic token. |
| **High** | `period_log_dashboard_card.dart` | 371 | Shape Scale | Symptom tags use 12dp squircle (`radiusM`) instead of 1000dp Stadium pill. | Refactor to use `AppChip` or `BorderRadius.circular(AppLayout.radiusStadium)`. |
| **Medium** | `period_log_dashboard_card.dart` | 167, 189, 206 | Shape Scale | `Start Period`, `Add Period Log`, and `Stop Period` CTAs use 16dp radius (`radiusL`). | Replace with `shape: const StadiumBorder()` per M3 Expressive CTA standard. |
| **Medium** | `period_log_editor_sheet.dart` | 285 | Shape Scale | `Save Log` CTA button uses 16dp radius (`radiusL`). | Replace with `shape: const StadiumBorder()`. |
| **Medium** | `period_log_editor_sheet.dart` | 261 | Shape Scale | `FilterChip` in editor sheet lacks stadium border parameter. | Supply `shape: const StadiumBorder()`. |
| **Medium** | `period_log_editor_sheet.dart` | 160, 187, 204 | UI-UX Hygiene | `ListTile` and `SwitchListTile` inside modal sheet lack `Material(color: Colors.transparent)` wrapper. | Wrap in `Material(color: Colors.transparent)` to ensure ink splash ripples. |
| **Medium** | `period_log_editor_sheet.dart` | 134–144 | Responsiveness | Sheet lacks 75% height constraint (`ConstrainedBox(maxHeight: 0.75 * height)`) and chip cloud scroll boundary. | Add `ConstrainedBox` wrapper per UI-UX-Specialist Rule 65. |
| **Medium** | `period_calendar_card.dart` | 70–127 | Performance | `TableCalendar` with 35+ monthly cells is not isolated by `RepaintBoundary`. | Wrap `TableCalendar` in `RepaintBoundary` to optimize fling scroll FPS. |
| **Low** | `period_tracker_screen.dart` | 130–218 | Component Library | `_showPhaseGuideDialog` uses raw `AlertDialog` instead of `AppBottomSheet` or `AppDialog`. | Migrate to `AppBottomSheet` or `AppDialog` with M3 container styling. |
| **Low** | `period_tracker_screen.dart` | 319–346 | Contrast Standard | Scope pill uses `phaseColor` with 0.16 alpha in light mode and 11pt text. | Increase alpha to 0.28–0.35 or use `colorScheme.primaryContainer` with 12pt font. |
| **Low** | `cycle_phase_hero_card.dart` | 40–44 | Design Invariant | Hero card border width is 1.0 (from `AppCard.tonal`) instead of 1.2px accent border. | Add `borderWidth: 1.2` parameter to `AppCard.tonal`. |
| **Feature Gap** | `lib/features/health/` | N/A | Feature Parity | Absence of a Cycle History screen/sheet with connected corner morphing. | Implement `CycleHistorySheet` with connected list items. |
| **Feature Gap** | `period_tracker_screen.dart` | N/A | Privacy & A11y | Absence of an in-screen privacy mask / quick-blur shield. | Add discreet privacy eye toggle in app bar to mask dates and phase text. |

---

## 4. Prioritized Actionable Roadmap for Health Tracker

### Phase 1: Foundational Token & Shape Fixes (Low Risk, High Polish)
1. **Fix Hardcoded Color in Calendar**:
   - In `period_calendar_card.dart:62`, replace `const Color(0xFF1C1A22)` with `theme.colorScheme.surfaceContainerLow`.
2. **Standardize Symptom Tags to Stadium Pills**:
   - In `period_log_dashboard_card.dart:371`, replace `AppLayout.radiusM` with `AppLayout.radiusStadium`.
   - In `period_log_editor_sheet.dart:261`, pass `shape: const StadiumBorder()` to `FilterChip`.
3. **Align Primary Action Buttons to Stadium CTAs**:
   - In `period_log_dashboard_card.dart:167, 189, 206` and `period_log_editor_sheet.dart:285`, change button shapes to `shape: const StadiumBorder()`.
4. **Wrap Calendar in RepaintBoundary**:
   - In `period_calendar_card.dart:70`, wrap `TableCalendar` in `RepaintBoundary`.

### Phase 2: Sheet & Dialog Polish
1. **Modal Sheet Guardrails**:
   - In `period_log_editor_sheet.dart`, wrap `ListTile` widgets in `Material(color: Colors.transparent)`.
   - Constrain modal height to `MediaQuery.sizeOf(context).height * 0.75`.
2. **Phase Guide Modernization**:
   - Refactor `_showPhaseGuideDialog` in `period_tracker_screen.dart` to open as an `AppBottomSheet` with standard drag handle and M3 container styling.

### Phase 3: Advanced Health Features
1. **Cycle History with Connected Corner Morphing**:
   - Add a "Cycle History" item to `Health Tools` overflow menu opening a dedicated history view. Group logs by year with connected squircle cards (16dp top corners on first, 0dp on middle, 16dp bottom corners on last).
2. **In-Screen Privacy Mask**:
   - Add a quick privacy toggle (eye icon) in `PeriodTrackerScreen` header that blurs or masks cycle days and phase labels with `"••••••••"`, requiring a biometric prompt or tap to reveal.

---

## 5. Verification Command Blueprint

To verify these findings and ensure zero regressions when implementing recommendations:
```bash
# 1. Static code analysis (must have 0 errors, 0 warnings)
flutter analyze

# 2. Automated test suite for health tracker & predictions
flutter test test/period_prediction_test.dart
flutter test test/period_tracker_test.dart

# 3. Verify clean git status (zero unprompted modifications)
git status
```
