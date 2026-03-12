---
description: Create a new task in an Obsidian project with kanban board
argument-hint: '"title" --project name --priority high --effort 2h'
allowed-tools: Bash(mkdir*), Bash(cat*), Read, mcp__plugin_obsidian-tracker_obsidian__getConfig, mcp__plugin_obsidian-tracker_obsidian__initVault, mcp__plugin_obsidian-tracker_obsidian__listProjects, mcp__plugin_obsidian-tracker_obsidian__addTask
---

# Task Command

Creates a task with auto-increment ID and adds to kanban board (Backlog column).

## Step 0: Check Configuration

Вызови `mcp__plugin_obsidian_tracker_obsidian__getConfig`.
Если `initialized: false` — выполни инициализацию как в `/projects`.

## Arguments

- title (required) - Task title (first quoted string or positional arg)
- --project (optional) - Project name
- --priority (optional) - critical|high|medium|low (default: medium)
- --effort (optional) - Time estimate (e.g., "2h", "1d", "30m")
- --assignee (optional) - Assignee name
- Любые дополнительные --key value передаются в extra (расширяемая YAML-схема)

## Examples

```
/task "Add rate limiting" --project api --priority high --effort 2h
/task "Fix login bug"
/task "Update docs" --project myapp --effort 30m --client Acme
```

## Logic

1. Парси аргументы из пользовательского ввода.

2. Если --project не указан:
   Вызови `listProjects`, покажи нумерованный список, спроси у пользователя.

3. Если title не указан:
   Спроси через AskUserQuestion.

4. Собери extra-поля: все --key value кроме project/priority/effort/assignee.

5. Вызови MCP tool:
   ```
   mcp__plugin_obsidian_tracker_obsidian__addTask
   с параметрами: project, title, priority, effort, assignee, extra
   ```

6. Выведи:
   ```
   TASK-{id}: "{title}"
   Board: Backlog | Priority: {priority} | Effort: {effort}
   ```

7. **Auto-update tracking:**
   Если `.claude/obsidian-tracking.json` существует — прочитай через Read, добавь `"Created TASK-{id}: {title}"` в actions, перезапиши через `Bash(cat*)`.
