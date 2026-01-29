---
description: List all projects from Obsidian or show specific project details
argument-hint: "[project-name]"
---

# Projects Command

Lists all tracked projects from Obsidian or shows details for a specific project.

## Step 0: Check Configuration

Вызови MCP tool для проверки конфигурации:

```
mcp__plugin_obsidian_tracker_obsidian__getConfig
```

**Если `initialized: false` или `vaultPath: "NOT SET"`:**

1. Спроси путь к Obsidian vault через AskUserQuestion:
   - Опция 1: `~/Documents/Obsidian/Projects` (Recommended)
   - Опция 2: `~/Documents/GitHub/obsidian/MCP/Projects`
   - Опция 3: Другой путь

2. Вызови MCP tool для инициализации:
   ```
   mcp__plugin_obsidian_tracker_obsidian__initVault
   с параметром vaultPath = выбранный путь
   ```

3. Выведи: `✅ Obsidian Tracker инициализирован: {vault_path}`

**Если `initialized: true`:** переходи к Logic.

## Arguments

- `project-name` (optional) - Show details for specific project

## Examples

```
/projects                           # List all projects
/projects awac-claude-code-plugins  # Show specific project
```

## Logic

1. **If no argument provided:**

   Вызови:
   ```
   mcp__plugin_obsidian_tracker_obsidian__listProjects
   ```

   Выведи таблицу:
   | Project | Status | Bugs | Path |
   |---------|--------|------|------|
   | name    | Active | 2    | /... |

2. **If project-name provided:**

   Вызови:
   ```
   mcp__plugin_obsidian_tracker_obsidian__getProject
   с параметром name = project-name
   ```

   Выведи:
   - Project description
   - Open bugs (with count)
   - Recent sessions
   - Quick commands: `/project-bug {name}`, `/session-log {name}`
