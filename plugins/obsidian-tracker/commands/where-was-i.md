---
description: "Show resume context: last session summary, active tasks, open bugs, decisions"
allowed-tools:
  - mcp__plugin_obsidian-tracker_obsidian__getResumeContext
  - mcp__plugin_obsidian-tracker_obsidian__listProjects
  - mcp__plugin_obsidian-tracker_obsidian__getProject
  - mcp__plugin_obsidian-tracker_obsidian__findProjectByLocalPath
  - mcp__plugin_obsidian-tracker_obsidian__listTasks
  - mcp__plugin_obsidian-tracker_obsidian__listDecisions
  - Read
  - "Bash(cat*)"
  - "Bash(date*)"
---

# /where-was-i — Resume Context

## Goal
Show the user a compact context block to quickly resume work on a project.

## Steps

1. **Determine project:**
   - If `.claude/obsidian-tracking.json` exists, use the project from it.
   - Otherwise, call `findProjectByLocalPath` with the current working directory.
   - If still no project, call `listProjects` and ask the user which project.

2. **Get resume context:**
   - Call `getResumeContext` with the resolved project name.

3. **Format output** as a compact block:

```
# Resume Context for {project}

## Current Focus
{suggestedAction}

## Last Session ({date})
Completed:
- {items}

Blockers: {items or "None"}

## Active Work
Tasks:
- [{status}] {title}

Bugs:
- [{priority}] {title}

## Recent Decisions
- {DEC-id}: {title}
```

4. **Keep it token-efficient:**
   - No descriptions, only titles and statuses.
   - Target ~300-500 tokens max.
   - If a section is empty, show "None" on one line, don't skip the section.

5. **If no data exists** (no summaries, no tasks, no bugs):
   - Say "No previous session data found for {project}. This looks like a fresh start."
