---
description: Log current session to Obsidian project
allowed-tools: ["Read", "Write", "Bash", "AskUserQuestion"]
---

# Session Log Command

Logs the current Claude Code session to the specified project.

## Step 0: Auto-Init (выполняется автоматически!)

**Перед началом работы** проверь конфигурацию:

```yaml
1. Проверить config:
   - Прочитай: ~/.config/obsidian-tracker/config.json
   - Если файл существует и "initialized": true → переходи к Arguments

2. Если не инициализирован:
   - Спроси путь к vault через AskUserQuestion:
     - Опция 1: ~/Documents/Obsidian/Projects
     - Опция 2: ~/Documents/GitHub/obsidian/MCP/Projects
     - Опция 3: Другой путь (ввести вручную)

3. Создать config:
   - mkdir -p ~/.config/obsidian-tracker
   - Записать: {"vaultPath": "{user_path}", "initialized": true}

4. Подтвердить: "✅ Obsidian Tracker инициализирован: {vault_path}"
```

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
