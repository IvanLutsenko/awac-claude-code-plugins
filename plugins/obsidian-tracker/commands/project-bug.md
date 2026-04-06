---
description: Create or update a bug report in Obsidian
argument-hint: "[project-name]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(mkdir*), Bash(cat*), Read, mcp__plugin_obsidian-tracker_obsidian__getConfig, mcp__plugin_obsidian-tracker_obsidian__initVault, mcp__plugin_obsidian-tracker_obsidian__listProjects, mcp__plugin_obsidian-tracker_obsidian__getProject, mcp__plugin_obsidian-tracker_obsidian__listTasks, mcp__plugin_obsidian-tracker_obsidian__addTask, mcp__plugin_obsidian-tracker_obsidian__updateTask, mcp__plugin_obsidian-tracker_obsidian__addBug, mcp__plugin_obsidian-tracker_obsidian__closeBug, mcp__plugin_obsidian-tracker_obsidian__addSession, mcp__plugin_obsidian-tracker_obsidian__createProject, mcp__plugin_obsidian-tracker_obsidian__updateProject, mcp__plugin_obsidian-tracker_obsidian__archiveProject, mcp__plugin_obsidian-tracker_obsidian__restoreProject, mcp__plugin_obsidian-tracker_obsidian__search
---

# Project Bug Command

Creates a bug report in the specified project.

## Step 0: Check Configuration

Вызови MCP tool:
```
mcp__plugin_obsidian_tracker_obsidian__getConfig
```

**Если `initialized: false`:** выполни инициализацию как в `/projects` команде.

## Arguments

- `project-name` (optional) - Project to add bug to
- `--title` - Bug title (optional, will ask if not provided)
- `--priority` - Priority: critical|high|medium|low (default: medium)

## Examples

```
/project-bug awac-claude-code-plugins
/project-bug awac-claude-code-plugins --title "Search broken" --priority high
```

## Logic

1. **Resolve project:**

   Если project-name не указан:
   ```
   mcp__plugin_obsidian_tracker_obsidian__listProjects
   ```
   Покажи нумерованный список:
   | # | Project | Status |
   |---|---------|--------|
   | 1 | name    | Active |

   Пользователь может ввести номер или имя проекта.

2. **Collect bug info via AskUserQuestion:**
   - Title (если не передан через --title)
   - Priority: critical / high / medium / low
   - Description (multi-line)

3. **Create bug via MCP:**
   ```
   mcp__plugin_obsidian_tracker_obsidian__addBug
   с параметрами:
     project = project name
     title = bug title
     description = description
     priority = priority
   ```

4. **Output:**
   ```
   🐛 Bug created: "{title}"
   📁 Path: {path}
   🔴 Priority: {priority}
   ```

5. **Auto-start tracking (если ещё не активен):**
   Если `.claude/obsidian-tracking.json` не существует — создай через скрипт:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/start-tracking.sh "{project}" "Bug: {title}" "Created bug: {title}"
   ```
   Выведи: `Tracking started for {project}`

   Если файл существует — прочитай его через Read, добавь в actions `Created bug: {title}` и перезапиши через Bash.
