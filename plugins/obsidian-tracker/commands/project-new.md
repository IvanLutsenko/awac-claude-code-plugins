---
description: Create a new project in Obsidian
allowed-tools: ["Read", "Write", "Bash", "AskUserQuestion"]
---

# Project New Command

Creates a new project structure in Obsidian.

## Step 0: Auto-Init (ОБЯЗАТЕЛЬНО выполни первым!)

**СНАЧАЛА** проверь конфигурацию. Выполни ЭТИ ТОЧНЫЕ команды:

```bash
# 1. Читай ИМЕННО этот файл (абсолютный путь):
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

2. Создай конфиг (выполни ОБЕ команды):
   ```bash
   mkdir -p ~/.config/obsidian-tracker
   ```
   Затем используй Write tool для создания файла `~/.config/obsidian-tracker/config.json`:
   ```json
   {"vaultPath": "/полный/путь/к/vault", "initialized": true}
   ```

3. Выведи: `✅ Obsidian Tracker инициализирован: {vault_path}`

## Logic

1. **Ask user for project details via AskUserQuestion:**
   - Project name (ОБЯЗАТЕЛЬНО)
   - Description (ОБЯЗАТЕЛЬНО)

   **НЕ спрашивай:** Repository URL, Local path — эти поля НЕ нужны при создании проекта. Они добавляются позже вручную если потребуется.

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
