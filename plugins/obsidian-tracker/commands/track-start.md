---
description: Start tracking current session for Obsidian
argument-hint: "[project-name]"
---

# Track Start Command

Включает автоматический трекинг текущей сессии для логирования в Obsidian.

## Step 0: Check Configuration

Вызови MCP tool:
```
mcp__plugin_obsidian_tracker_obsidian__getConfig
```

**Если `initialized: false`:** выполни инициализацию как в `/projects` команде.

## Step 1: Check existing tracking

```bash
cat .claude/obsidian-tracking.json 2>/dev/null || echo "NO_TRACKING"
```

**Если трекинг уже активен:**
```
⚠️ Трекинг уже активен для проекта: {project}
Используй /track-stop чтобы завершить текущий.
```
Останови выполнение.

## Step 2: Resolve project

**Если project-name указан:** используй его.

**Если project-name НЕ указан:**
1. Получи список проектов:
   ```
   mcp__plugin_obsidian_tracker_obsidian__listProjects
   ```
2. Спроси через AskUserQuestion какой проект трекать.

## Step 3: Get goal

Спроси через AskUserQuestion:
- "Какая цель этой сессии?" (текстовый ввод)

## Step 4: Create tracking marker

Создай директорию и файл:

```bash
mkdir -p .claude
```

Используй Write tool для создания `.claude/obsidian-tracking.json`:
```json
{
  "project": "{project-name}",
  "goal": "{goal}",
  "started": "{ISO timestamp}",
  "actions": []
}
```

## Step 5: Confirm

```
🟢 Трекинг включён
- Проект: {project}
- Цель: {goal}
- Время: {started}

Твои действия будут автоматически записываться.
Используй /track-stop или /clear для сохранения в Obsidian.
```
