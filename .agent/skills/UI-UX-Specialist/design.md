# Material 3 Expressive Design System & Module Architecture Guide (`design.md`)
> **Target Framework:** Flutter 3.x+ (Dart)
> **Target IDE / Agent:** Antigravity IDE & AI Coding Assistants
> **App Domain:** Local-First Note-Taking, Financial Management, & Health Tracking System

---

## 1. Design Philosophy & M3 Expressive Core
Material 3 Expressive builds upon standard Material 3 by introducing bolder typography contrasts, fluid spring physics, tactile gesture feedback, asymmetric container geometry, and tactile surface depth.

### Core Principles
1. **Dynamic & Local-First:** High-contrast visuals tailored for ambient display, battery optimization (true OLED black `#000000`), and offline-first data autonomy.
2. **Expressive Geometry:** Asymmetric containers, custom squircles (`BorderRadius.circular(24.0)` to `32.0`), and connected list corner morphing.
3. **Tactile Motion:** Every gesture triggers spring-based physics (`Curves.elasticOut`, `Curves.easeOutBack`, scale transformations `0.96`).
4. **Content-First Hierarchy:** Backgrounds drop into subtle surface containers so user notes, rich text, and financial ledgers stand out.

---

## 2. Color System & 5-Tier Surface Tokens
M3 Expressive replaces flat background layers with a 5-tier Surface Container model for spatial depth.

### Surface Elevation Levels
| Surface Token | Light Theme Hex | Dark Theme Hex | OLED / Pitch Black | Usage / Application |
| :--- | :--- | :--- | :--- | :--- |
| `surfaceContainerLowest` | `#FFFFFF` | `#0F0F13` | `#000000` | Main canvas / Note editing screen |
| `surfaceContainerLow` | `#F7F2FA` | `#1A191E` | `#08080A` | App background behind grid cards |
| `surfaceContainer` | `#F3EDF7` | `#211F26` | `#121215` | Default card state, search bar |
| `surfaceContainerHigh` | `#ECE6F0` | `#2B2930` | `#1B1A20` | Hovered cards, modal bottom sheets |
| `surfaceContainerHighest` | `#E6E0E9` | `#36343B` | `#26242B` | Dialogs, elevated toolbars, FABs |

### Dynamic Accent Seeds & Semantic Tokens
```dart
const Color seedPrimary = Color(0xFF6750A4);   // Deep Expressive Violet
const Color seedSecondary = Color(0xFF625B71); // Neutral Slate
const Color seedTertiary = Color(0xFF7D5260);  // Warm Rose
const Color seedError = Color(0xFFB3261E);     // Crisp Alert Red
// Semantic phase & transaction colors live in AppSemanticColors ThemeExtension
```

---

## 3. Expressive Typography Scale & Font Pairing
* **UI Controls & Headers:** `Plus Jakarta Sans` or **`Google Sans Text`**
* **Financial Ledgers & Data Tables:** **`Inter`** with tabular figures (`fontFeatures: [FontFeature.tabularFigures()]`)
* **Extended Canvas & Reading:** `Newsreader` or `Literata`

| Type Role | Size / Line Height | Weight | Application |
| :--- | :--- | :--- | :--- |
| **Display Large** | 57pt / 64pt | 800 | Expressive Titles & Hero Headers |
| **Headline Medium** | 28pt / 36pt | 700 | Folder & Section Headers |
| **Title Medium** | 16pt / 24pt | 600 | Card Titles, Modal Headers |
| **Body Large** | 16pt / 24pt | 400 | Note Body Text & Long Descriptions |
| **Label Large** | 14pt / 20pt | 600 | Chip Labels, Action Buttons |

---

## 4. Shape System & Container Morphing
```dart
class M3Shapes {
  static const double xs = 8.0;   // Tags, Tooltips, Micro-badges
  static const double sm = 12.0;  // Input fields, Code blocks
  static const double md = 16.0;  // Standard Cards, Buttons
  static const double lg = 24.0;  // Note Cards, Floating App Bars
  static const double xl = 28.0;  // Modal Bottom Sheets
  static const double xxl = 32.0; // Expressive FABs, Hero Dialogs
}
```

---

## 5. Motion Architecture & Spring Physics
Transitions must feel physical and responsive to touch velocity.
* **Spring Curve:** `Cubic(0.34, 1.56, 0.64, 1.0)` (`Curves.elasticOut` / `Curves.easeOutBack`)
* **Transition Duration:** `300ms` (Card-morph via `OpenContainer`, drill-in via `SharedAxisTransition`)
* **Micro-Interactions (Press/Hover):** `150ms` (scaleFactor: `0.96`)

```dart
Widget buildExpressivePressable({required Widget child, required VoidCallback onTap}) {
  return BouncingButton(
    scaleFactor: 0.96,
    duration: const Duration(milliseconds: 150),
    curve: Curves.easeOutBack,
    onTap: onTap,
    child: child,
  );
}
```

---

## 6. Core Component Guidelines & Flutter Patterns

### A. Expressive Floating Action Button (FAB) & FAB Menu
* **Behavior:** Expanded on scroll-top, collapses to square-rounded icon (`BorderRadius.circular(24.0)`) on downward scroll.
* **FAB Menu Pattern:** Expands into a morphing container revealing secondary quick-action chips (`Text Note`, `Voice Note`, `Checklist`, `Scan`) with staggered entrance physics.

### B. Split Buttons
* **Pattern:** Combines a primary action `FilledButton` (e.g. `+ Add Expense`) with an attached sub-action menu toggle (`Icon(Icons.arrow_drop_down)`) for dual-function quick actions.

### C. Floating Formatting Toolbar
* **Placement:** Suspended above the software keyboard or bottom center.
* **Container:** `surfaceContainerHighest` fill with explicit `BackdropFilter` glassmorphic blur (`sigmaX: 12, sigmaY: 12`, opacity `0.85`, radius `32.0`) and `IconButton.filledTonal` active states.

### D. Expressive & Connected Lists
* **Geometry:** Connected list item geometry where top item morphs `radiusL` top corners, middle items are square, and bottom item morphs `radiusL` bottom corners.

### E. Search & Input Fields
* **In-Place Search Morphing:** Morph top bar in-place into `SearchBar` pill using `AnimatedSwitcher` (`180ms Curves.fastOutSlowIn`).
* **TextField Container Transparency:** When embedding `TextField` inside custom containers or pill headers, explicitly override `InputDecoration` with `filled: false`, `fillColor: Colors.transparent`, `border: InputBorder.none`, `enabledBorder: InputBorder.none`, and `focusedBorder: InputBorder.none` to prevent global `inputDecorationTheme` fill color artifacts.
* **Symmetric Navigation Bars:** Pair frosted glass app headers with matching frosted glass bottom navigation bars (`ClipRect` + `BackdropFilter` `16px` blur) and `extendBody: true` on `Scaffold` for edge-to-edge scrolling depth.

---

## 7. Module Architecture & Domain Specifications

### A. Note-Taking Engine
* **Data Format:** Lossless Quill Delta JSON stored in SQLite (`note_tags` junction table). Edit-only modified timestamps.
* **Feed Cards:** Masonry or List view using `surfaceContainerLow` fills, thin `outlineVariant` borders (`0.4` opacity), auto tag-color blending, and plain text preview text (up to 6 lines).
* **Slash Commands & Overlay:** Type `/` at line start to pop floating Slash Command card. Debounce typing overlays by `150ms`.

### B. Financial Manager Engine
* **Transaction Logging:** M3 **Split Buttons** (`+ Add Expense` paired with `+ Add Income` dropdown trigger).
* **Ledger Formatting:** All monetary values and ledger rows use **`Inter`** tabular figures (`fontFeatures: [FontFeature.tabularFigures()]`).
* **Analytics Navigation:** Sub-segment views organized via `SegmentedButton` (`Ledger 📜` -> `Trends 📈` -> `Breakdown 🍩` -> `Budgets 🎯`).
* **SMS Parsing & Sync:** Stateless `SmsParser` regexes in `sms_constants.dart`. 5-minute deduplication window. Periodic 12-hour WorkManager background sync.

### C. Health Tracker Engine
* **Cycle Predictions:** Rolling averages from last 3–7 logs (cycles 15–60 days). Ovulation calculated 14 days prior to next estimated start.
* **Flow & Symptom Tiles:** Flow intensity tiles use M3 `FilledButton.tonal` widgets with spring press states. Symptoms card displays active count via `Badge.count`.
* **Phase Semantic Colors:** Resolved from `AppSemanticColors` (`menstrual`, `follicular`, `ovulatory`, `luteal`).
* **Privacy & Alerts:** Local data only (excluded from unencrypted backup). Discreet notifications (`"Check the app"`).

---

## 8. Antigravity IDE Execution Rules & QA Constraints
1. **No Hardcoded Colors:** Never write `Color(0xFF...)` inside screen widgets. Always use `Theme.of(context).colorScheme.<token>`.
2. **Material 3 Enforced:** Root `MaterialApp` must configure `useMaterial3: true` in `ThemeData`.
3. **A11y Touch Targets:** All clickable icon buttons must reach a minimum $48 \times 48\text{ dp}$ tap target (`IconButton(padding: const EdgeInsets.all(12), ...)`).
4. **State Feedback:** Every list item or card must include explicit `InkWell` or `GestureDetector` feedback using `splashColor: colorScheme.primary.withValues(alpha: 0.12)`.
5. **Context & Mounted Safety:** Asynchronous callback gates must check `context.mounted` or state `mounted` before executing context operations.
6. **Dark / OLED Mode Safety:** Verify contrast ratios between `surfaceContainer` options and text in pitch black mode (`#000000`).
