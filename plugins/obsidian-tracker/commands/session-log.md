---
description: Log current session to Obsidian project
argument-hint: "[project-name]"
---

# Session Log Command

Logs the current Claude Code session to the specified project.

## Step 0: Check Configuration

Вызови MCP tool:
```
mcp__plugin_obsidian_tracker_obsidian__getConfig
```

**Если `initialized: false`:** выполни инициализацию как в `/projects` команде.

## Arguments

- `project-name` (optional) - Project to log session to

## Logic

1. **Resolve project:**

   Если project-name не указан:
   ```
   mcp__plugin_obsidian_tracker_obsidian__listProjects
   ```
   Покажи список и спроси через AskUserQuestion.

2. **Collect session info:**
   - Goal: Summarize main topic from conversation
   - Actions: List key tool calls and operations
   - Results: What was achieved
   - Next steps: Ask user via AskUserQuestion

3. **Create session via MCP:**
   ```
   mcp__plugin_obsidian_tracker_obsidian__addSession
   с параметрами:
     project = project name
     goal = session goal
     actions = ["action1", "action2", ...]
     results = what was achieved
     nextSteps = next steps
   ```

4. **Output:**
   ```
   📝 Session logged to "{project}"
   📁 Path: {path}

   Summary:
   - Goal: {goal}
   - Actions: {count} recorded
   - Next: {nextSteps}
   ```
