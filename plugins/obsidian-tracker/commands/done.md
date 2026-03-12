---
description: Complete a task and move to Done on kanban board
argument-hint: "<task-id> [--project name] [--actual 1h]"
allowed-tools: Bash(cat*), Bash(mkdir*), Read, mcp__plugin_obsidian-tracker_obsidian__getConfig, mcp__plugin_obsidian-tracker_obsidian__listProjects, mcp__plugin_obsidian-tracker_obsidian__listTasks, mcp__plugin_obsidian-tracker_obsidian__updateTask
---

# Done Command

Moves a task to Done column on kanban board. Optionally logs actual time spent.

## Arguments

- task-id (required) - Task ID number (e.g., 3)
- --project (optional) - Project name
- --actual (optional) - Actual time spent (e.g., "1h", "30m")

## Examples

```
/done 3 --actual 1h
/done 5 --project api
/done 1
```

## Logic

1. Парси аргументы: task-id (число), --project, --actual.

2. Определи проект:
   - Если --project указан — используй его
   - Если `.claude/obsidian-tracking.json` существует — прочитай project оттуда
   - Иначе — вызови `listProjects`, покажи список, спроси у пользователя

3. Если task-id не указан:
   Вызови `listTasks` для проекта.
   Покажи активные задачи (Backlog + In Progress + Review):
   ```
   | # | ID | Title | Status |
   ```
   Спроси у пользователя номер.

4. Вызови MCP tool:
   ```
   mcp__plugin_obsidian_tracker_obsidian__updateTask
   с параметрами: project, taskId, status="Done", actual
   ```

5. Выведи:
   ```
   TASK-{id} done! {from} → Done
   Actual: {actual}
   ```

6. **Auto-update tracking:**
   Если `.claude/obsidian-tracking.json` существует — добавь `"Completed TASK-{id}"` в actions.
