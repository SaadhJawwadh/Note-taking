---
name: skill-trainer
description: Automatically extracts learnings from recent session changes to create or update agent skills robustly. Use this when instructed to save learnings, update skills based on recent fixes, or ensure the agent remembers how to handle similar tasks in the future.
---

# Skill Trainer

## Purpose
The Skill Trainer distills knowledge from recent session activities (bug fixes, refactors, workflow executions) and persists that knowledge by updating existing skills or creating new ones. Its goal is continuous improvement of the agent's capabilities with minimal redundancy.

## Guidelines
1. **Absolute Git Permission**: All deployment or management skills MUST mandate explicit user consent BEFORE any `git commit`, `git tag`, or `git push`.
2. **Consent-First Deployment**: Ensure all deployment-related skills mandate explicit user consent before any remote tag push or workflow trigger.
3. **Analyze Context**: Review recent `git diff` outputs, chat history, and executed commands to understand the root cause of the issue and the solution applied.
4. **Be Smart and Learn**: Analyze past mistakes (e.g., unauthorized commits) and ensure newly created skills include preventative instructions to avoid redoing errors.

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
