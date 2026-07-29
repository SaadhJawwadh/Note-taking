# AI Rules and Guidelines for Note Book

All AI coding assistants (including Cursor, Copilot, Antigravity, and other LLM agents) working on this repository must strictly adhere to the following rules:

---

## 🚀 Rule 1: Use the Developer Map first to Save Tokens
Before executing any search queries, reading random files, or writing any code modifications, the AI **MUST** first read and reference the Developer Map/Knowledge Base file:
*   [.agent/map.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/map.md).

**Process**:
1.  Read the Developer Map to find which files, databases, or services are responsible for the requested feature or bug.
2.  Identify the specific narrow set of files that need to be read or edited.
3.  Only query, read, or edit those targeted files. Avoid broad directory-wide grep searches or opening unrelated files. This is critical for token conservation and context window management.

---

## 📱 Rule 2: Mandatorily Test Implementations in the Emulator
After implementing any new feature, code modification, or bug fix, the AI **MUST** run the app on an emulator/simulator or device and verify the implementation.

**Process**:
1.  **List Devices & Apps**: Use tools to list available devices or check running apps (e.g. `list_devices`, `list_running_apps`).
2.  **Launch & Sync**: Launch the app (e.g. `launch_app`) or perform a Hot Restart/Hot Reload (e.g. `hot_restart`, `hot_reload`) to sync the changes.
3.  **Validate Outcomes**: Read logs (e.g. `get_app_logs`) and look for runtime errors (e.g. `get_runtime_errors`) to proactively resolve issues.
4.  **Confirm Correctness**: Do not declare a task done until it has been verified to compile and run correctly on the device/emulator.

---

## 🛡️ Rule 3: Maintain R8 ProGuard Rules for Native Dependencies
When adding any new native Android plugin or dependency to `pubspec.yaml`, the AI **MUST** ensure R8 release builds will not strip required native classes or reflection entry points.

**Process**:
1.  **Check ProGuard Rules**: Inspect `android/app/proguard-rules.pro` and add explicit `-keep class <package_name>.** { *; }` rules for any new native plugin.
2.  **Verify Release Compilation**: Before finalizing release-related tasks, run `flutter build apk --release` to confirm that R8 code and resource shrinking finish with zero errors.

---

## 🎨 Rule 4: Material 3 Expressive UI/UX Enforcement
When creating or refactoring any UI component, screen, or theme in this application, the AI **MUST** refer to [.agent/skills/UI-UX-Specialist/design.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/.agent/skills/UI-UX-Specialist/design.md).

**Process**:
1.  **5-Tier Surface Container Tokens**: Use `surfaceContainerLow` $\rightarrow$ `surfaceContainerHighest` and `#000000` for OLED pitch black. Never write raw `Color(0xFF...)` inside screen widgets.
2.  **Component Specs**: Use standard M3 Expressive components: **FAB Menu**, **Split Buttons**, **Floating Glassmorphic Toolbars**, **SegmentedButton**, `SearchBar`, and `Badge.count`.
3.  **Typography**: Pair `Google Sans Text` / `Plus Jakarta Sans` for UI controls and headers with **`Inter`** tabular figures (`fontFeatures: [FontFeature.tabularFigures()]`) for financial ledgers and data numbers.
4.  **Spring Physics & Touch Targets**: Wrap tactile buttons in `buildExpressivePressable` (`scaleFactor: 0.96`, `150ms`, `Curves.easeOutBack`) and ensure all clickable icon buttons meet the minimum $48 \times 48\text{ dp}$ tap target size.
