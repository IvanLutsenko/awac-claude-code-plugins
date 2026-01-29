---
event: PreCompact
---

# Pre-Compact Hook: Сохранение контекста трекинга

Проверь наличие файла трекинга:

```bash
cat .claude/obsidian-tracking.json 2>/dev/null || echo "NO_TRACKING"
```

**Если файл существует (не NO_TRACKING):**

Прочитай JSON и добавь в свой ответ блок который будет включён в summary:

```
---
⚠️ OBSIDIAN TRACKING ACTIVE - DO NOT FORGET:
- Project: {project}
- Goal: {goal}
- Session started: {started}
- Actions recorded: {actions.length} items
- Tracking file: .claude/obsidian-tracking.json

After compact, check this file and continue tracking.
---
```

**Если NO_TRACKING:** ничего не делай, трекинг не активен.
