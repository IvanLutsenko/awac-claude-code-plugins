# Bereke Business Test Gen - Краткая инструкция

## Что это?

**Bereke Business Test Gen** - AI инструмент для автоматической генерации unit тестов на Kotlin/Android.

Генерирует тесты по корпоративным стандартам (@DisplayName, Given-When-Then, Truth assertions, max 80 chars/line).

**Время:** 2-5 мин на класс | 20-30 мин на модуль

---

## Установка (Claude Code)

```bash
/plugin marketplace add https://github.com/IvanLutsenko/awac-claude-code-plugins
/plugin install bereke-business-test-gen
```

---

## Две команды для всех случаев

### Тест для одного класса (быстро)

```bash
/test-class src/main/java/.../YourClass.kt
```

**Результат:** Готовый тест + покрытие класса (2-5 мин)

---

### Полное покрытие модуля (полно)

```bash
/test-module feature/auth
```

**Включает:** ViewModel, UseCase, Repository, Validators, Utils
**Исключает:** UI компоненты, Data classes, DI modules
**Результат:** Тесты для всех нужных классов + статистика (20-30 мин)

---

## Другие платформы

| Платформа | Как использовать |
|-----------|------------------|
| **Claude Desktop** | Добавить как MCP сервер в `claude_desktop_config.json` |
| **ChatGPT Desktop** | Загрузить `standards/android-kotlin-quick-ref.md` в Knowledge |
| **Gemini Web** | Загрузить standards в начало разговора |

---

## Требования к тестам

✅ Обязательно:
- @DisplayName (без backticks)
- Given-When-Then структура
- Truth assertions (assertThat)
- Prefix `mock` для моков
- **Максимум 80 символов на строку**

---

## Примеры

**Быстро проверить на одном классе:**
```bash
/test-class src/main/java/kz/berekebank/business/core/auth/LoginRepository.kt
```

**Покрыть весь модуль feature/push:**
```bash
/test-module feature/push
```

---

## Документация

- [Full Plugin Docs](https://github.com/IvanLutsenko/awac-claude-code-plugins/tree/main/plugins/bereke-business-test-gen)
- [Test Standards](https://github.com/IvanLutsenko/awac-claude-code-plugins/blob/main/plugins/bereke-business-test-gen/standards/android-kotlin.md)

**Версия:** 2.0.0 | **Статус:** ✅ Production Ready
