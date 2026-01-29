---
event: PostToolUse
match_tool: TodoWrite
---

# Post TodoWrite Hook: Запись actions в трекер

Проверь наличие файла трекинга:

```bash
cat .claude/obsidian-tracking.json 2>/dev/null || echo "NO_TRACKING"
```

**Если NO_TRACKING:** ничего не делай, трекинг не активен.

**Если файл существует:**

1. Прочитай текущий маркер (JSON)

2. Получи данные из TodoWrite tool_input:
   - Найди todos со `status: "completed"`
   - Извлеки их `content`

3. Для каждой завершённой задачи которой ещё нет в `actions`:
   - Добавь в массив `actions`: `"✅ {content}"`

4. Обнови файл .claude/obsidian-tracking.json:
   ```json
   {
     "project": "{existing project}",
     "goal": "{existing goal}",
     "started": "{existing started}",
     "actions": [
       "... existing actions ...",
       "✅ New completed todo"
     ]
   }
   ```

5. НЕ выводи ничего пользователю — работай тихо в фоне.

## Пример

До:
```json
{"project": "my-app", "goal": "Fix bugs", "started": "...", "actions": ["✅ Fix login"]}
```

TodoWrite добавил completed: "Fix search"

После:
```json
{"project": "my-app", "goal": "Fix bugs", "started": "...", "actions": ["✅ Fix login", "✅ Fix search"]}
```
