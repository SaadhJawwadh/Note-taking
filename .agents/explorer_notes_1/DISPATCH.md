## 2026-08-30T07:41:52Z
Conduct a comprehensive, read-only audit of the Notes domain (lib/features/notes/ and related test files) for Everything App.

Authoritative references to inspect:
- /Users/saadhjawwadh/Documents/Code/Note taking/.agents/ORIGINAL_REQUEST.md
- /Users/saadhjawwadh/Documents/Code/Note taking/AGENTS.md
- /Users/saadhjawwadh/Documents/Code/Note taking/.agent/map.md
- /Users/saadhjawwadh/Documents/Code/Note taking/.agent/skills/App-Feature-Expert/SKILL.md

Scope to Audit:
1. Rich text Quill Delta sanitization, normalization, and JSON encoding/decoding.
2. Selection clamping, cursor boundary validation, and index out-of-bounds guards.
3. Attribute scope invariants (prevent inline attributes like bold/italic from leaking into subsequent lines/blocks).
4. Dirty state management, debounced auto-save timers, and race conditions during rapid typing or navigation.
5. Trash auto-purge (7-day lifecycle, soft-delete vs permanent delete, restoreNote(id) undo parity).
6. Folder management, tagging hierarchy, note search, and pin/archive operations.
7. Image embeds in notes (cacheWidth bounding, error handling, file persistence).
