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

### F. Iconography & Material Symbols Standard
* **Catalog Reference:** All UI icon identifiers must align with official [Google Material Icons / Symbols](https://fonts.google.com/icons).
* **Variant & Weight Guidelines:** Prefer outlined or rounded variants (`Icons.<name>_outlined`, `Icons.<name>_rounded`) for list tiles, section headers, and secondary actions to preserve a refined M3 visual balance. Use filled variants (`Icons.<name>`) primarily for active selection states (e.g. selected navigation bar tabs or selected toggle buttons).

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

---

## 9. Comprehensive Material 3 Component Specifications & Guidance Catalog (`m3.material.io`)

This catalog codifies all official components from [m3.material.io/components](https://m3.material.io/components) into target Flutter implementation patterns, shape tokens, elevation levels, and design rules.

---

### ⚡ Category 1: Action Components
Components that allow users to initiate actions, commit choices, or trigger state transitions.

#### 1. Buttons ([m3.material.io/components/buttons](https://m3.material.io/components/buttons/overview))
* **Variants:** Elevated (`ElevatedButton`), Filled (`FilledButton`), Filled Tonal (`FilledButton.tonal`), Outlined (`OutlinedButton`), Text (`TextButton`).
* **Shape & Elevation Tokens:** Height `40dp`, Corner Radius `AppLayout.radiusMAX` (Stadium `20dp`), Elevation `0` (Filled/Tonal) to `1` (Elevated).
* **Usage Guidance:**
  - **FilledButton:** Use for the single primary call-to-action per screen (e.g. *Save Note*, *Log Transaction*).
  - **FilledButton.tonal:** Use for secondary important actions (e.g. *Add Category*, *Filter Results*).
  - **OutlinedButton:** Use for medium-emphasis secondary choices (e.g. *Cancel*, *Export CSV*).
  - **TextButton:** Use for low-emphasis inline actions (e.g. *Skip*, *Learn More*).
  - **A11y & Touch:** Minimum tap target height $48\text{ dp}$.

#### 2. Floating Action Button (FAB) ([m3.material.io/components/floating-action-button](https://m3.material.io/components/floating-action-button/overview))
* **Variants:** Small FAB ($40\times 40\text{ dp}$), Standard FAB ($56\times 56\text{ dp}$), Large FAB ($96\times 96\text{ dp}$).
* **Shape & Elevation Tokens:** Corner Radius `AppLayout.radiusLG` (`16dp` squircle to `28dp`), Container `primaryContainer`, Foreground `onPrimaryContainer`, Elevation `3`.
* **Usage Guidance:** Use for the main constructive action on feed screens (e.g., *Create New Note*). Place at `floatingActionButtonLocation: FloatingActionButtonLocation.endFloat`.

#### 3. Extended FAB ([m3.material.io/components/extended-fab](https://m3.material.io/components/extended-fab/overview))
* **Variants:** `FloatingActionButton.extended` (Icon + Text Label).
* **Usage Guidance:** Morph between Extended FAB (scroll-top) and Standard FAB (scroll-down) using `NotificationListener<ScrollNotification>` to preserve content canvas space.

#### 4. Icon Buttons ([m3.material.io/components/icon-buttons](https://m3.material.io/components/icon-buttons/overview))
* **Variants:** Standard (`IconButton`), Filled (`IconButton.filled`), Filled Tonal (`IconButton.filledTonal`), Outlined (`IconButton.outlined`).
* **Usage Guidance:** Enforce `minimumSize: const Size(48, 48)` in global `iconButtonTheme`. Prefer outlined/rounded icons (`Icons.<name>_outlined`) for unselected states and filled icons for active toggles.

#### 5. Floating Toolbars ([m3.material.io/components/toolbars](https://m3.material.io/components/toolbars/overview))
* **Variants:** Standard Floating Pill ($56\text{dp}$ height), Compact Floating Pill ($48\text{dp}$ height).
* **Shape & Elevation Tokens:** Full Stadium pill (`AppLayout.radiusMAX` / `28dp` radius), Container `surfaceContainerHigh` / `surfaceContainerHighest`, 1px `outlineVariant` border with `0.35` opacity, Elevation `6` (`AppLayout.softShadow`).
* **Usage Guidance:**
  - Ground page navigation at the top with a structural M3 Top App Bar (flush with status area).
  - Use a single bottom M3 Floating Expressive Toolbar pill for creation and editing actions.
  - Group icons into functional clusters separated by $1\text{px}$ `VerticalDivider` lines.
  - Place block insertions (`Table`, `Image`, `Checklist`, `Drawing Canvas`, `Voice Mic`) on the primary bottom toolbar; reserve secondary docked toolbars strictly for text typography formatting (`Headers`, `Bold`, `Italic`, `Underline`, `Strikethrough`, `Lists`).

#### 5. Segmented Buttons ([m3.material.io/components/segmented-buttons](https://m3.material.io/components/segmented-buttons/overview))
* **Variants:** Single-select (`SegmentedButton<T>`), Multi-select.
* **Shape Tokens:** Height `40dp`, Corner Radius `AppLayout.radiusMAX`, Active Container `secondaryContainer`, Active Foreground `onSecondaryContainer`.
* **Usage Guidance:** Use for switching between 2 to 5 sub-views (e.g., Financial Manager `Ledger` / `Trends` / `Breakdown` / `Budgets`).

---

### 📢 Category 2: Communication Components
Components that provide system feedback, notifications, alerts, and progress states.

#### 1. Badges ([m3.material.io/components/badges](https://m3.material.io/components/badges/overview))
* **Variants:** Small dot badge ($6\text{ dp}$ radius), Numerical count badge (`Badge.count`).
* **Usage Guidance:** Attach to navigation icons or action chips to denote unread items, pending rules, or active filter counts. Container `error`, Foreground `onError`.

#### 2. Progress Indicators ([m3.material.io/components/progress-indicators](https://m3.material.io/components/progress-indicators/overview))
* **Variants:** Linear Progress (`LinearProgressIndicator`), Circular Progress (`CircularProgressIndicator`).
* **Usage Guidance:** Use `colorScheme.primary` for track fill and `surfaceContainerHighest` for background track. Round track borders using `strokeCap: StrokeCap.round`.

#### 3. Snackbars ([m3.material.io/components/snackbars](https://m3.material.io/components/snackbars/overview))
* **Variants:** Floating `SnackBar` with action label.
* **Tokens:** Container `inverseSurface`, Text `inverseOnSurface`, Action `inversePrimary`, Shape `AppLayout.radiusMD` (`12dp`).
* **Usage Guidance:** Display short non-blocking confirmation messages (e.g., *"Note moved to trash"* with an *"Undo"* action button).

#### 4. Tooltips ([m3.material.io/components/tooltips](https://m3.material.io/components/tooltips/overview))
* **Variants:** Plain Tooltip (`Tooltip`), Rich Tooltip.
* **Usage Guidance:** Wrap icon-only buttons with descriptive text tooltips to satisfy accessibility standards.

---

### 📦 Category 3: Containment Components
Containers that structure content into coherent spatial cards, sheets, lists, and dialogs.

#### 1. Bottom Sheets ([m3.material.io/components/bottom-sheets](https://m3.material.io/components/bottom-sheets/overview))
* **Variants:** Standard Bottom Sheet, Modal Bottom Sheet (`AppBottomSheet` / `showModalBottomSheet`).
* **Tokens:** Container `surfaceContainerLow` / `surfaceContainerHigh`, Radius `AppLayout.radiusXL` (`28dp` top corners), Drag handle $32\times 4\text{ dp}$ `outlineVariant`.
* **Usage Guidance:** Use for rich editor options, tag selectors, AI refiners, and quick filter panels.

#### 2. Cards ([m3.material.io/components/cards](https://m3.material.io/components/cards/overview))
* **Variants:** Elevated Card (`Card(elevation: 1)`), Filled Card (`AppCard` / `surfaceContainer`), Outlined Card (`outlineVariant` border stroke).
* **Usage Guidance:** All touchable cards must wrap `Material(color: ..., child: InkWell(child: Padding(...)))` to ensure ink ripple animations paint over container backgrounds.

#### 3. Carousel ([m3.material.io/components/carousel](https://m3.material.io/components/carousel/overview))
* **Variants:** Multi-browse, Hero, Uncontained.
* **Usage Guidance:** Use horizontal `ListView.builder` or `PageView` with spring physics for media attachments and onboarding feature slides.

#### 4. Dialogs ([m3.material.io/components/dialogs](https://m3.material.io/components/dialogs/overview))
* **Variants:** Basic Alert Dialog (`AppDialog` / `AlertDialog`), Full-screen Dialog.
* **Tokens:** Container `surfaceContainerHigh`, Corner Radius `AppLayout.radiusXXL` (`28dp` to `32dp`), Title `headlineSmall`.
* **Usage Guidance:** Use basic dialogs for destructive confirmations (*Delete note permanently*).

#### 5. Dividers ([m3.material.io/components/divider](https://m3.material.io/components/divider/overview))
* **Variants:** Inset / Indented Divider (`Divider(indent: 56, endIndent: 16)`).
* **Usage Guidance:** Use soft opacity (`outlineVariant.withValues(alpha: 0.2)`) or `SizedBox.shrink()` inside rounded container cards to prevent visual clutter.

#### 6. Lists ([m3.material.io/components/lists](https://m3.material.io/components/lists/overview))
* **Variants:** Single-line, Two-line, Three-line (`ListTile`).
* **Usage Guidance:** Configure `contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)` and `minLeadingWidth: 24`.

#### 7. Side Sheets ([m3.material.io/components/side-sheets](https://m3.material.io/components/side-sheets/overview))
* **Usage Guidance:** Ideal for tablet and desktop multi-pane layouts (e.g. active folder navigation drawer + note list preview).

---

### 🧭 Category 4: Navigation Components
Components that structure app hierarchy and view switching across compact and expanded displays.

#### 1. Top App Bar ([m3.material.io/components/top-app-bar](https://m3.material.io/components/top-app-bar/overview))
* **Variants:** Center-aligned (`CenterAlignedTopAppBar`), Small (`SliverAppBar`), Medium, Large (`FrostedGlassSliverAppBar`).
* **Usage Guidance:** Use glassmorphic backdrop blur (`16px`) and `surfaceContainerLow` transparent fills for edge-to-edge content depth.

#### 2. Bottom App Bar ([m3.material.io/components/bottom-app-bar](https://m3.material.io/components/bottom-app-bar/overview))
* **Variants:** `BottomAppBar` with embedded action icon buttons and FAB notch integration.

#### 3. Navigation Bar ([m3.material.io/components/navigation-bar](https://m3.material.io/components/navigation-bar/overview))
* **Variants:** Bottom Navigation Bar (`NavigationBar`).
* **Tokens:** Container `surfaceContainer`, Active Pill Indicator `secondaryContainer`, Active Icon `onSecondaryContainer`. Height `80dp`.

#### 4. Navigation Drawer ([m3.material.io/components/navigation-drawer](https://m3.material.io/components/navigation-drawer/overview))
* **Variants:** Modal Navigation Drawer (`NavigationDrawer`), Standard Navigation Drawer.
* **Shape Tokens:** Corner Radius `AppLayout.radiusXL` (`28dp` end corners), Item Pill Radius `AppLayout.radiusMAX`.

#### 5. Navigation Rail ([m3.material.io/components/navigation-rail](https://m3.material.io/components/navigation-rail/overview))
* **Usage Guidance:** Replace bottom `NavigationBar` with vertical `NavigationRail` when screen width exceeds `600dp` (Tablets / Foldables).

#### 6. Search ([m3.material.io/components/search](https://m3.material.io/components/search/overview))
* **Variants:** SearchBar Pill (`SearchBar`), Search View (`SearchAnchor`).
* **Shape Tokens:** Stadium Pill (`AppLayout.radiusMAX`), Height `48dp` to `56dp`, Container `surfaceContainerHigh`.

#### 7. Tabs ([m3.material.io/components/tabs](https://m3.material.io/components/tabs/overview))
* **Variants:** Primary Tabs (`TabBar` with active indicator pill), Secondary Tabs.

---

### 🔘 Category 5: Selection Components
Components that handle choices, range values, date/time inputs, and state toggles.

#### 1. Checkboxes ([m3.material.io/components/checkboxes](https://m3.material.io/components/checkboxes/overview))
* **Variants:** `Checkbox`, `CheckboxListTile`.
* **Tokens:** Active Container `primary`, Checkmark `onPrimary`, Corner Radius `4dp`.

#### 2. Chips ([m3.material.io/components/chips](https://m3.material.io/components/chips/overview))
* **Variants:** Assist Chip (`ActionChip`), Filter Chip (`FilterChip` / `AppChip`), Input Chip (`InputChip`), Suggestion Chip.
* **Shape Tokens:** Height `32dp`, Corner Radius `AppLayout.radiusSM` (`8dp`) to `AppLayout.radiusMAX` (`16dp`).

#### 3. Date Pickers ([m3.material.io/components/date-pickers](https://m3.material.io/components/date-pickers/overview))
* **Variants:** Modal Date Picker (`showDatePicker`), Date Range Picker (`showDateRangePicker`).
* **Tokens:** Container `surfaceContainerHigh`, Selected Day `primary`, Corner Radius `AppLayout.radiusXXL` (`28dp`).

#### 4. Menus ([m3.material.io/components/menus](https://m3.material.io/components/menus/overview))
* **Variants:** Dropdown Menu (`PopupMenuButton` / `MenuAnchor`), Exposed Dropdown (`DropdownMenu`).
* **Tokens:** Elevation `3`, Shadow Tint `shadow.withValues(alpha: 0.15)`, Shape `AppLayout.radiusXL` (`28dp`), Item Height `48dp`.

#### 5. Radio Buttons ([m3.material.io/components/radio-buttons](https://m3.material.io/components/radio-buttons/overview))
* **Variants:** `Radio<T>`, `RadioListTile<T>`.

#### 6. Sliders ([m3.material.io/components/sliders](https://m3.material.io/components/sliders/overview))
* **Variants:** Continuous Slider (`Slider`), Range Slider (`RangeSlider`).
* **Tokens:** Active Track `primary`, Inactive Track `secondaryContainer`, Thumb `primary`.

#### 7. Switches ([m3.material.io/components/switches](https://m3.material.io/components/switches/overview))
* **Variants:** `Switch`, `SwitchListTile`.
* **Tokens:** Active Track `primary`, Active Thumb `onPrimary`, Inactive Track `surfaceContainerHighest`, Inactive Outline `outline`.

#### 8. Time Pickers ([m3.material.io/components/time-pickers](https://m3.material.io/components/time-pickers/overview))
* **Variants:** Dial Time Picker (`showTimePicker`), Input Time Picker.

---

### ✍️ Category 6: Text Input Components
Components for text entry, search queries, and form editing.

#### 1. Text Fields ([m3.material.io/components/text-fields](https://m3.material.io/components/text-fields/overview))
* **Variants:** Filled Text Field (`TextField(decoration: InputDecoration(filled: true))`), Outlined Text Field (`InputDecoration(border: OutlinedInputBorder())`).
* **Shape & Color Tokens:** Height $56\text{ dp}$, Radius `AppLayout.radiusMD` (`12dp`), Focused Border `primary` ($2\text{ dp}$), Error Border `error` ($2\text{ dp}$).
* **Container Transparency Rule:** When embedding `TextField` inside custom rounded containers or stadium search bars, explicitly set `filled: false`, `fillColor: Colors.transparent`, and `border: InputBorder.none` to prevent double-fill artifacts.

---

## 10. Comprehensive Material 3 Styles Specifications & Guidance Catalog (`m3.material.io/styles`)

This catalog codifies all official style systems from [m3.material.io/styles](https://m3.material.io/styles) into target Flutter implementation patterns, theme extensions, physics curves, and design tokens.

---

### 🎨 Style 1: Color System ([m3.material.io/styles/color](https://m3.material.io/styles/color/overview))
* **Dynamic Color Generation:** Derive full light and dark `ColorScheme` palettes using seed colors (`ColorScheme.fromSeed(seedColor: ..., brightness: ...)`).
* **5-Tier Surface Container Model:**
  - `surfaceContainerLowest`: Pure canvas background (`#FFFFFF` light, `#0F0F13` dark, `#000000` pitch black OLED).
  - `surfaceContainerLow`: App background behind grid cards (`#F7F2FA` light, `#1A191E` dark).
  - `surfaceContainer`: Standard card container state, search pill.
  - `surfaceContainerHigh`: Hovered cards, modal bottom sheets, popover menus.
  - `surfaceContainerHighest`: Dialogs, floating toolbars, elevated action bars.
* **Accent Roles:** `primary` (main brand), `secondary` (filtering/toggles), `tertiary` (contrast accents), `error` (destructive states).
* **A11y Contrast Rules:** Ensure a minimum contrast ratio of $4.5:1$ for regular body text and $3:1$ for icons and large titles in both light and OLED dark modes.

---

### 🔤 Style 2: Typography Scale ([m3.material.io/styles/typography](https://m3.material.io/styles/typography/overview))
* **Font Pairings:**
  - Controls, Titles & App Bars: `Plus Jakarta Sans` or `Google Sans Text`.
  - Financial Ledgers & Data Tables: `Inter` with tabular figures (`fontFeatures: [FontFeature.tabularFigures()]`).
  - Extended Reading Canvas: `Newsreader` or `Literata`.
* **15-Role Type Scale:**
  - **Display (Large/Medium/Small):** 57pt/45pt/36pt — Hero titles and analytics stat callouts.
  - **Headline (Large/Medium/Small):** 32pt/28pt/24pt — Section headers and modal titles.
  - **Title (Large/Medium/Small):** 22pt/16pt/14pt — Card headers and list tile titles.
  - **Body (Large/Medium/Small):** 16pt/14pt/12pt — Note content and extended descriptions.
  - **Label (Large/Medium/Small):** 14pt/12pt/11pt — Buttons, chips, badges, and tab items.

---

### 📐 Style 3: Shape System & Geometry ([m3.material.io/styles/shape](https://m3.material.io/styles/shape/overview))
* **M3 Corner Radii Scale:**
  - **XS (`4dp`):** Micro-badges, checkbox corners.
  - **SM (`8dp`):** Input chips, code block containers.
  - **MD (`12dp`):** Text fields, snackbars, standard cards.
  - **LG (`16dp`):** Note grid cards, floating app bars.
  - **XL (`28dp`):** Modal bottom sheets, dropdown menus, navigation drawers.
  - **XXL (`32dp`):** Hero dialogs, floating formatting toolbars.
  - **Full Stadium (`1000dp`):** Action buttons, search pills, segmented buttons.
* **Asymmetric & Connected Morphing:** Apply connected list item geometry where the first item morphs top corners (`radiusL`), middle items remain square, and the last item morphs bottom corners (`radiusL`).

---

### 🎬 Style 4: Motion & Spring Physics ([m3.material.io/styles/motion](https://m3.material.io/styles/motion/overview))
* **Physical Motion Principle:** All interactive elements must react dynamically to touch velocity and press state.
* **Spring Curve Tokens:**
  - `AppLayout.curveExpressive` / `AppLayout.curveSpring`: `Cubic(0.34, 1.56, 0.64, 1.0)` (`Curves.elasticOut` / `Curves.easeOutBack`).
  - Press Micro-Interactions: Duration $150\text{ms}$, scale transformation `0.96` via `BouncingButton`.
* **Transition Patterns:**
  - **Shared Axis Transition:** Horizontal drill-in for hierarchical wizard flows.
  - **Fade Through Transition:** Cross-fade for bottom navigation view switches.
  - **Container Transform (`OpenContainer`):** Morph note feed card smoothly into full editor screen ($300\text{ms}$).

---

### 🏛️ Style 5: Elevation & Spatial Depth ([m3.material.io/styles/elevation](https://m3.material.io/styles/elevation/overview))
* **Tonal Elevation Model:** M3 replaces heavy drop shadows with tone-based surface container fills (`surfaceContainerLow` $\rightarrow$ `surfaceContainerHighest`).
* **Elevation Levels:**
  - `Level 0` ($0\text{ dp}$): Surface canvas background.
  - `Level 1` ($1\text{ dp}$): Cards, linear progress.
  - `Level 2` ($3\text{ dp}$): Dropdown menus, popovers, floating app bars.
  - `Level 3` ($6\text{ dp}$): Floating Action Buttons (FAB), dialogs.
  - `Level 4–5` ($8\text{–}12\text{ dp}$): Modal bottom sheets with backdrop scrim.
* **Glassmorphic Depth:** Use `BackdropFilter` with `16.0` to `24.0` sigma blur paired with $0.80$ alpha surface container fills for frosted top app bars and floating toolbars.

---

### 🔣 Style 6: Icons & Material Symbols ([m3.material.io/styles/icons](https://m3.material.io/styles/icons/overview))
* **Material Symbols Standard:** All UI icons must reference official [Google Material Symbols / Icons](https://fonts.google.com/icons).
* **Variable Axes:**
  - **Style Variant:** Prefer outlined/rounded variants (`Icons.<name>_outlined` or `Icons.<name>_rounded`) for list tiles, section headers, and secondary action buttons. Use filled variants (`Icons.<name>`) for active selected states.
  - **Optical Sizes:** $20\text{ dp}$ for inline chip icons, $24\text{ dp}$ for standard list tiles/app bar controls, $40\text{–}48\text{ dp}$ for hero feature icons.
  - **Minimum Touch Target:** Ensure all icon buttons wrap a minimum $48 \times 48\text{ dp}$ touch target.


