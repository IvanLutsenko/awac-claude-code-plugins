---
description: Create or update a bug report in Obsidian
allowed-tools: ["Read", "Write", "Bash", "AskUserQuestion"]
---

# Project Bug Command

Creates a bug report in the specified project.

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
- `--title` - Bug title (optional, will ask if not provided)
- `--priority` - Priority: critical|high|medium|low (default: medium)

## Examples

```
/project-bug awac-claude-code-plugins
/project-bug awac-claude-code-plugins --title "glm-toggle not indexing" --priority critical
```

## Logic

1. **Resolve project:**
   - If `project` not provided: show list via `obsidian://listProjects()` and ask
   - Validate project exists via `obsidian://getProject(project)`

2. **Collect bug info:**
   - If no `--title`: Ask via AskUserQuestion
   - If no `--priority`: Ask or default to "medium"
   - Ask for description (multi-line)

3. **Create bug file:**
   - Path: `{project}/BUG - {title}.md`
   - Use bug report template

4. **Call MCP:** `obsidian://addBug(project, bugData)`

5. **Update project dashboard** (add to "Known Issues" section)

6. **Output:** Confirmation with link to bug file
