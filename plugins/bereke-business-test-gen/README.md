# Bereke Business Test Gen

Automated unit test generation for Kotlin/Android business logic with corporate standards.

## Быстрый старт

### Claude Code

```bash
# Добавь marketplace
/plugin marketplace add https://github.com/IvanLutsenko/awac-claude-code-plugins

# Установи plugin
/plugin install bereke-business-test-gen

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

### `/test-class [path/to/ClassName.kt]`
Создаёт тест для одного класса + выводит покрытие класса.

```bash
/test-class src/main/java/kz/berekebank/business/core/auth/LoginRepository.kt
```

**Результат:** Тест с покрытием класса (LINE + INSTRUCTION metrics)

⏱️ **Время:** 2-5 минут

### `/test-coverage [path/to/module]`
Покрывает тестами ВСЕ классы модуля где это имеет смысл.

Включает:
- Бизнес-логика (ViewModel, UseCase, Interactor, Repository)
- Validators, Formatters, Utils с логикой
- State machines, Custom delegates
- Cache implementations

Исключает:
- UI компоненты (Activity, Fragment)
- Data classes без логики
- DI modules
- Константы/Enums

```bash
/test-coverage feature/auth
/test-coverage core:push
```

**Результат:** Полное покрытие модуля с итоговыми metrics

⏱️ **Время:** 20-30 минут

### `/validate-tests [path/to/module]` (опционально)
Проверяет существующие тесты на соответствие стандартам.

```bash
/validate-tests feature/auth
```

**Результат:** Список нарушений с confidence scoring

## Две команды на все случаи

```bash
# Один класс (быстро)
/test-class path/to/Class.kt

# Весь модуль (полно)
/test-coverage path/to/module

# Опционально: проверить старые тесты
/validate-tests path/to/module
```

Обе команды работают с `test-engineer` агентом который:
- ✅ Анализирует код
- ✅ Находит примеры тестов
- ✅ Генерирует тесты по стандартам
- ✅ Запускает компиляцию и тесты
- ✅ Выводит покрытие (LINE + INSTRUCTION)
- ✅ Дает рекомендации

## Полные стандарты

См. [`standards/android-kotlin.md`](standards/android-kotlin.md)

## Лицензия

MIT - см. [LICENSE](../../LICENSE)
