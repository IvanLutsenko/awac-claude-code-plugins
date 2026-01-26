---
description: Create a new project in Obsidian
allowed-tools: ["Read", "Write", "Bash", "AskUserQuestion"]
---

# Project New Command

Creates a new project structure in Obsidian.

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

## Logic

1. **Ask user for project details via AskUserQuestion:**
   - Project name
   - Description
   - Repository URL (optional)
   - Local path (optional)

2. **Create project structure:**
   ```
   {project-name}/
   ├── !Project Dashboard.md
   └── README.md
   ```

3. **Generate dashboard using template:**
   - Fill in provided details
   - Set status: Active
   - Add creation date

4. **Update main Obsidian index** (if exists)

5. **Output:** Confirmation with path to new project
