---
description: Log current session to Obsidian project
allowed-tools: ["Read", "Write", "Bash", "AskUserQuestion"]
---

# Session Log Command

Logs the current Claude Code session to the specified project.

## Step 0: Auto-Init (ОБЯЗАТЕЛЬНО выполни первым!)

**СНАЧАЛА** проверь конфигурацию. Выполни ЭТУ ТОЧНУЮ команду:

```bash
cat ~/.config/obsidian-tracker/config.json 2>/dev/null || echo "NOT_FOUND"
```

**Если файл существует** и содержит `"initialized": true`:
- Извлеки `vaultPath` из JSON
- Переходи к Arguments

**Если файл НЕ существует (NOT_FOUND)**:
1. Спроси путь к Obsidian vault через AskUserQuestion:
   - Опция 1: `~/Documents/Obsidian/Projects`
   - Опция 2: `~/Documents/GitHub/obsidian/MCP/Projects`
   - Опция 3: Другой путь

2. Создай конфиг:
   ```bash
   mkdir -p ~/.config/obsidian-tracker
   ```
   Затем используй Write tool для создания `~/.config/obsidian-tracker/config.json`:
   ```json
   {"vaultPath": "/полный/путь/к/vault", "initialized": true}
   ```

3. Выведи: `✅ Obsidian Tracker инициализирован: {vault_path}`

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
