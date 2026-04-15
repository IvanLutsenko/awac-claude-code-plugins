---
description: "Link commits, PRs, tasks, or bugs to a decision"
argument-hint: "[decision-id]"
allowed-tools:
  - mcp__plugin_obsidian-tracker_obsidian__linkEntity
  - mcp__plugin_obsidian-tracker_obsidian__listDecisions
  - mcp__plugin_obsidian-tracker_obsidian__getDecision
  - mcp__plugin_obsidian-tracker_obsidian__listProjects
  - mcp__plugin_obsidian-tracker_obsidian__findProjectByLocalPath
  - mcp__plugin_obsidian-tracker_obsidian__listTasks
  - AskUserQuestion
  - Read
  - "Bash(git log*)"
  - "Bash(gh pr*)"
---

# /decision-link — Link Entity to Decision

## Steps

1. **Determine project** from tracking file or `findProjectByLocalPath`.

2. **Resolve decision ID:**
   - If argument provided, use it.
   - Otherwise, list decisions and ask.

3. **Ask what to link** via `AskUserQuestion`:
   - Commits (git hashes, short 7-char format)
   - PRs (#number or owner/repo#number)
   - Tasks (TASK-N)
   - Sessions (session IDs)

4. **Link** via `linkEntity` with entity="DEC-{id}" and the collected links.

5. **Confirm** the updated links.

Note: `linkEntity` works for any entity type (TASK, BUG, DEC). This command is a convenience wrapper focused on decisions.
