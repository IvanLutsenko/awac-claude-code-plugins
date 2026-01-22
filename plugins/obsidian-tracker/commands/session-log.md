---
description: Log current session to Obsidian project
allowed-tools: ["Write", "AskUserQuestion"]
---

# Session Log Command

Logs the current Claude Code session to the specified project.

## Arguments

- `project` - Project name (required)

## Logic

1. **Resolve project** (ask if not provided)

2. **Collect session info:**
   - Start time (from conversation history)
   - Goal/topic (summarize from messages)
   - Actions taken (list tool calls)
   - Results achieved
   - Next steps (ask user)

3. **Create/update session file:**
   - Path: `{project}/Sessions/Session - YYYY-MM-DD.md`
   - Append if exists, create if not

4. **Call MCP:** `obsidian://addSession(project, sessionData)`

5. **Output:** Confirmation with session summary
