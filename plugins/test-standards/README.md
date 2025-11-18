# Test Standards Plugin

Автоматическая генерация и валидация unit тестов для Android/Kotlin по корпоративным стандартам Bereke Business.

## Быстрый старт

### Claude Code

```bash
# Добавь marketplace
/plugin marketplace add awac https://github.com/IvanLutsenko/awac-claude-code-plugins

# Установи plugin
/plugin install test-standards@awac

# Проверка
/help  # должны появиться новые команды
```

### ChatGPT

1. Создай Custom GPT
2. Загрузи файл `standards/android-kotlin.md` в Knowledge
3. В Instructions добавь:
   ```
   Ты - эксперт по Android/Kotlin тестированию.
   Следуй стандартам из загруженного файла android-kotlin.md.
   Всегда используй @DisplayName, Given-When-Then, Truth assertions.
   ```

### Claude.ai (без CLI)

1. Перейди в Settings → Skills
2. Создай новый Skill "Test Standards"
3. Загрузи `standards/android-kotlin.md`
4. Skill автоматически активируется при запросах о тестах

### Cursor / Windsurf / Aider

Добавь в `.cursorrules` / `.windsurfrules` / `.aider.conf.yml`:

```markdown
# Test Standards for Android/Kotlin

[Вставь содержимое standards/android-kotlin.md]
```

### GitHub Copilot

Создай `.github/copilot-instructions.md`:

```markdown
# Testing Standards

When generating tests for Android/Kotlin:
[Вставь ключевые правила из standards/android-kotlin.md]
```

### Другие LLM инструменты

Используй `standards/android-kotlin.md` как system prompt или загрузи в контекст инструмента.

## Команды (только для Claude Code)

### `/generate-test [file]`
Создаёт тест для одного класса.

```bash
/generate-test feature/auth/domain/LoginUseCase.kt
```

### `/validate-test [file]`
Проверяет тест на соответствие стандартам.

```bash
/validate-test feature/auth/LoginUseCaseTest.kt
```

### `/test-module-business-core [module]`
Покрывает тестами бизнес-логику модуля: ViewModel, UseCase, Interactor, Repository.

```bash
/test-module-business-core feature/auth
```

### `/test-module-all [module]`
Покрывает тестами ВСЕ классы модуля где это имеет смысл (бизнес-логика + validators + formatters + utils).

```bash
/test-module-all feature/auth
```

## Slash команды vs Агент (Claude Code)

**Используй slash команды** когда:
- Знаешь точный путь к файлу или модулю
- Задача простая и конкретная
- Нужен быстрый результат

**Используй агента** когда:
- Нужно покрыть сложный модуль с анализом что тестировать
- Нужна валидация + автоматическое исправление
- Хочешь видеть прогресс через TodoWrite
- Модуль большой и нужен пошаговый отчёт

**Примеры:**

```bash
# Slash команда - быстро и просто
/generate-test feature/auth/LoginUseCase.kt

# Агент - сложная задача с анализом
> Используй test-engineer для покрытия feature/qr-signing всеми тестами.
> Проанализируй какие классы требуют тестов, создай план и покрой их.
```

## Полные стандарты

См. [`standards/android-kotlin.md`](standards/android-kotlin.md)

## Лицензия

MIT - см. [LICENSE](../../LICENSE)
