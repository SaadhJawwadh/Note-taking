---
name: skill-trainer
description: Automatically extracts learnings from recent session changes to create or update agent skills robustly. Use this when instructed to save learnings, update skills based on recent fixes, or ensure the agent remembers how to handle similar tasks in the future.
---

# Skill Trainer

Use this skill when tasked to extract learnings, save session fixes, or update/create agent skills.

## 1. Core Guidelines
* **Absolute Git Permission**: All deployment, versioning, or command execution skills MUST mandate obtaining explicit user consent BEFORE running `git commit`, `git tag`, or `git push`.
* **No Redundancy**: Avoid creating new skills if the knowledge cleanly fits into existing ones (e.g. `UI-UX-Specialist`, `Tester`, `release-management`).

## 2. Training Workflow
1. **Extract Takeaways**: Review recent git diffs, command outputs, and session fixes to identify:
   * What failed or was requested.
   * What was the technical resolution.
   * What code patterns, guards, or configurations resolved it.
2. **Target Skill Selection**: Find the most appropriate target skill in `.agent/skills/`.
3. **Apply the Update**: Inject the new learning into the existing `SKILL.md` file under the corresponding section.
4. **Create New Skill**: If no existing skill covers the domain, initialize a minimal directory in `.agent/skills/<name>/` with a single frontmatter-annotated `SKILL.md`.
5. **Validate**: Ensure the file syntax is correct and formatting is consistent.
