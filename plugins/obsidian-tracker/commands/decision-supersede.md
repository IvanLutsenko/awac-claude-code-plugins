---
description: "Supersede a decision with a new one"
argument-hint: "[decision-id]"
allowed-tools:
  - mcp__plugin_obsidian-tracker_obsidian__supersedeDecision
  - mcp__plugin_obsidian-tracker_obsidian__listDecisions
  - mcp__plugin_obsidian-tracker_obsidian__getDecision
  - mcp__plugin_obsidian-tracker_obsidian__listProjects
  - mcp__plugin_obsidian-tracker_obsidian__findProjectByLocalPath
  - AskUserQuestion
  - Read
---

# /decision-supersede — Supersede Decision

## Steps

1. **Determine project** from tracking file or `findProjectByLocalPath`.

2. **Resolve old decision ID:**
   - If argument provided, use it.
   - Otherwise, list active decisions and ask.

3. **Show the old decision** for context.

4. **Collect new decision info** via `AskUserQuestion`:
   - Title, Context, Decision, Consequences for the replacement.

5. **Supersede** via `supersedeDecision`.
   - This creates the new decision and marks the old one as Superseded with a backlink.

6. **Confirm** with both old and new decision IDs.
