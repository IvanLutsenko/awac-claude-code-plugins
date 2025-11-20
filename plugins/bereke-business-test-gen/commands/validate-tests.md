---
description: Валидация всех unit тестов в модуле на соответствие корпоративным стандартам
argument-hint: "path/to/module"
allowed-tools: ["Read", "Grep", "Bash"]
---

## Задача

Проверить ВСЕ unit тесты в указанном модуле на соответствие корпоративным стандартам.
Выявить критические нарушения (confidence ≥ 80) и вывести детальный отчет.

## Workflow

### Шаг 1: Загрузи стандарты

```
!cat ~/.claude/plugins/marketplaces/awac-claude-code-plugins/plugins/bereke-business-test-gen/standards/android-kotlin.md
```

### Шаг 2: Найди все тесты в модуле

```bash
find {module_path}/src/test -name "*Test.kt" -type f
```

Создай список всех найденных тестов.

### Шаг 3: Для каждого теста выполни проверку

Проверь КРИТИЧЕСКИЕ требования (confidence >= 80):

#### ✅ ОБЯЗАТЕЛЬНО:

1. **@DisplayName присутствует** (без backticks!)
   ```kotlin
   ✅ @DisplayName("When X - Then Y")
   ❌ fun `when x then y`()
   ```

2. **Given-When-Then структура** с комментариями
   ```kotlin
   ✅ // Given
     // When
     // Then
   ❌ Без комментариев
   ```

3. **Truth assertions** (assertThat)
   ```kotlin
   ✅ assertThat(result).isTrue()
   ❌ assertTrue(result)
   ❌ assertEquals(expected, actual)
   ```

4. **Mock префиксы** (mock*)
   ```kotlin
   ✅ private val mockRepository: Repository
   ❌ private val repository: Repository
   ```

5. **FlowTestUtils для Flow методов**
   ```kotlin
   ✅ FlowTestUtils.coVerifyFlowCall { ... }
   ❌ coVerify { mockRepository.getFlow() }
   ```

6. **tearDown с cleanup**
   ```kotlin
   ✅ FlowTestUtils.cleanupFlowResources()
   ❌ Только unmockkAll()
   ```

7. **Пакет теста = пакет класса**
   ```kotlin
   ✅ Source: kz.berekebank.business.core.push.push_impl.data.repositories
   ✅ Test:   kz.berekebank.business.core.push.push_impl.data.repositories
   ❌ Test:   kz.berekebank.business.core.push.push_impl.domain.repositories
   ```

#### ❌ ЗАПРЕЩЕНО:

- Backticks в именах методов
- JUnit assertions (assertEquals, assertTrue, assertFalse)
- Thread.sleep()
- Неиспользуемые импорты
- Обычный coVerify для Flow методов

### Шаг 4: Создай отчет

```markdown
## ✅ Валидация модуля: {MODULE_NAME}

### Общая статистика

**Всего тестов:** 15
**Валидных:** 12 (80%)
**С нарушениями:** 3 (20%)

### Критические нарушения (confidence >= 80)

#### Файл: RepositoryTest.kt
- ❌ Confidence: 100 - Backticks в названии теста `when data loads then updates`
- ❌ Confidence: 90 - Отсутствует @DisplayName в методе testMethod()
- ⚠️  Confidence: 70 - Найдены неиспользуемые импорты

**Рекомендация:** Исправить backticks и добавить @DisplayName

#### Файл: InteractorTest.kt
- ❌ Confidence: 100 - Используется assertEquals вместо assertThat
- ❌ Confidence: 100 - Нет FlowTestUtils.cleanupFlowResources() в tearDown

**Рекомендация:** Заменить на Truth assertions и добавить cleanup

#### Файл: ValidatorTest.kt
- ⚠️  Confidence: 75 - Нарушены Given-When-Then комментарии в 2 тестах

**Рекомендация:** Добавить структурные комментарии

### Классификация

| Уровень | Количество | Статус |
|---------|-----------|--------|
| 🔴 Critical (90-100) | 2 | ❌ Требует исправления |
| 🟡 Warning (70-89) | 3 | ⚠️  Рекомендуется исправить |
| 🟢 OK (< 70) | 10 | ✅ Соответствует стандартам |

### Дополнительные проверки

**Lint анализ:**
```bash
./gradlew :{module}:lintDebugUnitTest
```

**Компиляция:**
```bash
./gradlew :{module}:compileDebugUnitTestKotlin
```

**Запуск тестов:**
```bash
./gradlew :{module}:testDebugUnitTest
```

**Покрытие:**
```bash
./gradlew :{module}:koverVerify
```

### Действия

1. ✅ **Критические нарушения** - ДОЛЖНЫ быть исправлены немедленно
2. ⚠️  **Предупреждения** - Рекомендуется исправить перед коммитом
3. 🟢 **OK** - Может оставаться как есть

### Итог

**Статус:** ❌ Валидация НЕ прошла

**Требуемые действия:**
1. Исправить backticks в RepositoryTest.kt
2. Добавить @DisplayName в InteractorTest.kt
3. Заменить assertEquals на assertThat во всех файлах
4. Добавить FlowTestUtils.cleanupFlowResources()
5. После исправлений - переvalidировать модуль
```

### Шаг 5: Выведи результаты

Покажи:
1. Список файлов с нарушениями (critical only)
2. Количество нарушений по типам
3. Рекомендации по исправлению
4. Дальнейшие шаги

## Пример использования

```bash
# Валидировать весь модуль
/bereke-business-test-gen:validate-test-module feature/auth

# Валидировать impl модуль
/bereke-business-test-gen:validate-test-module feature/qr-signing/qr-signing-impl

# Валидировать core модуль
/bereke-business-test-gen:validate-test-module core/push/push-impl
```

## Автоматизация (опционально)

Для частой валидации создай скрипт:

```bash
#!/bin/bash
MODULE="$1"

echo "🔍 Валидация модуля: $MODULE"
echo ""

# Найди все тесты с нарушениями
echo "❌ Backticks в тестах:"
grep -r 'fun `' "${MODULE}/src/test" --include="*.kt" | head -5

echo ""
echo "❌ assertEquals (должен быть assertThat):"
grep -r 'assertEquals\|assertTrue\|assertFalse' "${MODULE}/src/test" --include="*.kt" | head -5

echo ""
echo "❌ Нет @DisplayName:"
grep -B 1 '@Test' "${MODULE}/src/test" -r --include="*.kt" | grep -v '@DisplayName' | head -5

echo ""
echo "✅ Проверка завершена. Исправь найденные нарушения!"
```

Используй как:
```bash
./validate-module.sh feature/auth
```

## Критические требования для прохождения валидации

✅ ОБЯЗАТЕЛЬНО:
- Все тесты имеют @DisplayName (без backticks)
- Given-When-Then структура с комментариями
- Только Truth assertions (assertThat)
- Mock префиксы (mock*)
- FlowTestUtils для Flow
- Полный tearDown с cleanupFlowResources
- Пакет теста = пакет класса
- Все тесты компилируются и запускаются

❌ ЗАПРЕЩЕНО:
- Backticks в именах
- JUnit assertions
- Thread.sleep()
- Неиспользуемые импорты
- Обычный coVerify для Flow
