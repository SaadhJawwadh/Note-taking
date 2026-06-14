# AI Rules and Guidelines for Note Book

All AI coding assistants (including Cursor, Copilot, Antigravity, and other LLM agents) working on this repository must strictly adhere to the following rules:

---

## 🚀 Rule 1: Use the Developer Map first to Save Tokens
Before executing any search queries, reading random files, or writing any code modifications, the AI **MUST** first read and reference the Developer Map/Knowledge Base file:
*   [README.md](file:///Users/saadhjawwadh/Documents/Code/Note%20taking/README.md) (or the corresponding [developer_knowledge_base.md](file:///Users/saadhjawwadh/.gemini/antigravity-cli/brain/c57512f9-b0a1-43f2-b764-f65713536318/developer_knowledge_base.md) artifact).

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
