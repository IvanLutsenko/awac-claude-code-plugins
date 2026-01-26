---
description: List all projects from Obsidian or show specific project details
argument-hint: "[project-name]"
allowed-tools: ["Read", "Write", "Bash", "AskUserQuestion"]
---

# Projects Command

Lists all tracked projects from Obsidian or shows details for a specific project.

## Step 0: Auto-Init (выполняется автоматически!)

**Перед началом работы** проверь конфигурацию:

```yaml
1. Проверить config:
   - Прочитай: ~/.config/obsidian-tracker/config.json
   - Если файл существует и "initialized": true → переходи к Step 1

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
