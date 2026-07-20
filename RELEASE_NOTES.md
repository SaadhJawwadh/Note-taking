
### 🔍 In-Note Search & Text Navigation
- **Real-Time Search Bar**: Search text inside any note with instant query highlighting, case-sensitivity toggle, and keyboard-friendly next/previous match navigation (`▲` / `▼`).
- **Match Count Indicator**: Live match position badge (e.g. `1/5`) updates dynamically as you navigate matches or edit content.

### 🧠 Dual-Engine On-Device AI Architecture
- **Universal Device Support**: Powered by Android AI Core NPU on supported hardware, with zero-latency smart offline fallback for 100% of all Android devices.
- **Compact Material 3 AI Sheet**: Redesigned bottom sheet with compact high-density tiles, visual density styling, and instant preset AI tools.
- **Floating AI Selection Toolbar**: Highlight any text to trigger a floating `✨ AI Assist` toolbar directly over the keyboard.

### 🏷️ Smart & Reliable AI Tag Suggestions
- **Whole-Word Boundary Precision**: Replaced naive prefix matching with exact whole-word regex boundaries, eliminating false tag matches.
- **Dynamic Topic Detection**: Automatically detects note subject matter (e.g. `Movie`, `Work`, `Finance`, `Health`, `Travel`) if no existing tags match.
- **Dismissable Tag Chips**: Suggested tags render as M3 chips with `✕` dismiss icons for one-tap filtering.

### 📱 Universal Tablet Compatibility
- **Samsung Galaxy Tab S10+ Support**: Configured `<package android:name="com.google.android.aicore" />` queries and optional hardware flags (`telephony`, `camera`, `microphone` `required="false"`), making the app available on tablets, foldables, and Chromebooks.

