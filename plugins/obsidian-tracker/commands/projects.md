---
description: List all projects from Obsidian or show specific project details
argument-hint: "[project-name]"
allowed-tools: ["Read", "Write", "Bash", "AskUserQuestion"]
---

# Projects Command

Lists all tracked projects from Obsidian or shows details for a specific project.

## Step 0: Auto-Init (ОБЯЗАТЕЛЬНО выполни первым!)

**СНАЧАЛА** проверь конфигурацию. Выполни ЭТУ ТОЧНУЮ команду:

```bash
cat ~/.config/obsidian-tracker/config.json 2>/dev/null || echo "NOT_FOUND"
```

**Если файл существует** и содержит `"initialized": true`:
- Извлеки `vaultPath` из JSON
- Переходи к Step 1

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

- `project-name` (optional) - Show details for specific project

## Examples

```
/projects                    # List all projects
/projects awac-claude-code-plugins  # Show specific project
```

## Logic

1. **If no argument:**
   - Call `obsidian://listProjects()` MCP tool
   - Display table with:
     - Project name
     - Status (Active/Archived)
     - Plugin count (if applicable)
     - Open bugs count
   - Show dashboards as links

2. **If project-name provided:**
   - Call `obsidian://getProject(projectName)` MCP tool
   - Display:
     - Project description
     - List of plugins/subprojects
     - Open bugs (with links)
     - Recent session logs
     - Quick commands for this project

3. **Output format:** Clean markdown table with Obsidian [[wiki-links]]
