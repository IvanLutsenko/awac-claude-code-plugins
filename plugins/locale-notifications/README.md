# Locale Notifications

Уведомления macOS с локализованными сообщениями для Claude Code.

## Установка

```bash
/plugin install locale-notifications
```

## Поддерживаемые локали

| Локаль | Сообщение |
|--------|-----------|
| `uk*` (Украинский) | Claude чекає на увагу |
| `ru*` (Русский) | Claude ждёт внимания |
| `kk*` (Казахский) | Claude назар аударуды күтуде |
| default (Английский) | Claude needs attention |

## Как работает

Плагин использует хук `Notification`, который срабатывает при любом уведомлении Claude Code:

1. Определяет системную локаль через `defaults read -g AppleLocale`
2. Выбирает сообщение в зависимости от локали
3. Показывает нативное уведомление macOS через `osascript`

## Требования

- macOS (использует `osascript` и `defaults`)
- Claude Code

## Лицензия

MIT
