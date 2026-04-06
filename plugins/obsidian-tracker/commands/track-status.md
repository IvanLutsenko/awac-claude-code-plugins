---
description: Show current tracking status
allowed-tools: Bash(cat*), Read, mcp__plugin_obsidian-tracker_obsidian__getConfig, mcp__plugin_obsidian-tracker_obsidian__initVault, mcp__plugin_obsidian-tracker_obsidian__listProjects, mcp__plugin_obsidian-tracker_obsidian__getProject, mcp__plugin_obsidian-tracker_obsidian__listTasks, mcp__plugin_obsidian-tracker_obsidian__addTask, mcp__plugin_obsidian-tracker_obsidian__updateTask, mcp__plugin_obsidian-tracker_obsidian__addBug, mcp__plugin_obsidian-tracker_obsidian__closeBug, mcp__plugin_obsidian-tracker_obsidian__addSession, mcp__plugin_obsidian-tracker_obsidian__createProject, mcp__plugin_obsidian-tracker_obsidian__updateProject, mcp__plugin_obsidian-tracker_obsidian__archiveProject, mcp__plugin_obsidian-tracker_obsidian__restoreProject, mcp__plugin_obsidian-tracker_obsidian__search
---

# Track Status Command

Показывает текущий статус трекинга.

## Step 1: Check tracking

```bash
cat .claude/obsidian-tracking.json 2>/dev/null || echo "NO_TRACKING"
```

**Если NO_TRACKING:**
```
🔴 Трекинг не активен

Используй /track-start [project] чтобы начать.
```

**Если файл существует:**

Прочитай JSON и выведи:

```
🟢 Трекинг активен

- Проект: {project}
- Цель: {goal}
- Начат: {started}
- Продолжительность: {now - started}
- Actions записано: {actions.length}

Actions:
{actions.map(a => "  - " + a).join("\n")}

Команды:
- /track-stop — сохранить и завершить
- /clear — автоматически сохранит и завершит
```
