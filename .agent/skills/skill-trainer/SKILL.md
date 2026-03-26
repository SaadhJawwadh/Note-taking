---
name: skill-trainer
description: Automatically extracts learnings from recent session changes to create or update agent skills robustly. Use this when instructed to save learnings, update skills based on recent fixes, or ensure the agent remembers how to handle similar tasks in the future.
---

# Skill Trainer

## Purpose
The Skill Trainer distills knowledge from recent session activities (bug fixes, refactors, workflow executions) and persists that knowledge by updating existing skills or creating new ones. Its goal is continuous improvement of the agent's capabilities with minimal redundancy.

## Guidelines
1. **Analyze Context**: Review recent `git diff` outputs, chat history, and executed commands to understand the root cause of the issue and the solution applied.
2. **Prefer Updating Over Creating**: Always check if the learning belongs in an existing skill (e.g., `DevOps-Expert`, `flutter-expert`). Only create a new skill if the domain is entirely unrepresented. Avoid creating needless skills.
3. **Be Minimal and Robust**: Do not add bloated explanations. Add clear, actionable bullet points to "Instructions" or "Common Fixes" sections. Only include what an agent needs to avoid repeating the same mistake.
4. **Follow the Skill Format**: Ensure all skills maintain their YAML frontmatter (`name` and `description`) and a concise Markdown body.

## Workflow

### 1. Extract Learnings
Identify the core takeaway:
- What failed or was requested?
- What was the technical solution?
- What command, code pattern, or configuration resolved it?

### 2. Locate Target Skill
Search the `.agent/skills/` directory for the most appropriate existing skill based on the domain (e.g., UI/UX, CI/CD, Flutter framework, etc.).

### 3. Apply the Update
Use the `replace` tool to inject the new learning into the existing `SKILL.md`. This typically goes under an `## Instructions` or similar troubleshooting section.
*Example format:*
`- **[Topic]**: [Context/Trigger] -> [Actionable Solution]`

### 4. Create New Skill (Only if Necessary)
If no existing skill fits, initialize a new minimal skill directory in `.agent/skills/<skill-name>/` containing only a `SKILL.md`. Give it a highly descriptive `description` in its frontmatter so the agent knows exactly when to trigger it.

### 5. Validate
Ensure the modified or newly created `SKILL.md` is syntactically valid (YAML frontmatter is intact) and the instructions are concise. Commit the changes to version control to persist the learnings for the repository.
