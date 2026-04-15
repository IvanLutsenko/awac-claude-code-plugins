---
description: "Close an active decision"
argument-hint: "[decision-id]"
allowed-tools:
  - mcp__plugin_obsidian-tracker_obsidian__closeDecision
  - mcp__plugin_obsidian-tracker_obsidian__listDecisions
  - mcp__plugin_obsidian-tracker_obsidian__getDecision
  - mcp__plugin_obsidian-tracker_obsidian__listProjects
  - mcp__plugin_obsidian-tracker_obsidian__findProjectByLocalPath
  - AskUserQuestion
  - Read
---

# /decision-close — Close Decision

## Steps

1. **Determine project** from tracking file or `findProjectByLocalPath`.

2. **Resolve decision ID:**
   - If argument provided (e.g., `1` or `DEC-001`), use it directly.
   - Otherwise, call `listDecisions` with status="Active" and show the list. Ask user to pick.

3. **Show the decision** via `getDecision` so the user can confirm.

4. **Ask for close reason** (optional) via `AskUserQuestion`.

5. **Close** via `closeDecision`.

6. **Confirm** closure.
