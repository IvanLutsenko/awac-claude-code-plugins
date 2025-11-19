---
description: Валидация unit теста на соответствие корпоративным стандартам
argument-hint: "path/to/test/file.kt"
allowed-tools: ["Read", "Grep"]
---

## Задача

Проверить тест на соответствие корпоративным стандартам, репортировать ТОЛЬКО критические проблемы (confidence ≥ 80).

## Workflow

### Шаг 1: Загрузи стандарты и тест

```
!cat ~/.claude/plugins/marketplaces/awac-claude-code-plugins/plugins/test-standards/standards/android-kotlin.md
```

Прочитай тестовый файл для валидации.

### Шаг 2: Проверка критических требований

Проверь каждый аспект с высоким confidence (80+):

#### 1. Структура и именование (Critical - Confidence 90-100)

**Backticks ЗАПРЕЩЕНЫ:**
```kotlin
// ❌ Confidence: 100 - КРИТИЧЕСКОЕ нарушение
@Test
fun `when data loads then updates`() = runTest { }

// ✅ Правильно
@DisplayName("When data loads - Then updates")
@Test
fun dataLoads_updates() = runTest { }
```

**@DisplayName обязателен:**
```kotlin
// ❌ Confidence: 90 - нет @DisplayName
@Test
fun testMethod() = runTest { }

// ✅ Правильно
@DisplayName("When method called - Then success")
@Test
fun method_success() = runTest { }
```

**Имена моков:**
```kotlin
// ❌ Confidence: 90 - нет префикса mock
private val repository: Repository = mockk()

// ✅ Правильно
private val mockRepository: Repository = mockk()
```

#### 2. Given-When-Then (Confidence 80)

```kotlin
// ❌ Отсутствуют комментарии Given-When-Then
@Test
fun test() = runTest {
    val data = mockk<Data>()
    val result = service.execute()
    assertThat(result).isTrue()
}

// ✅ Правильно
@Test
fun test() = runTest {
    // Given
    val data = mockk<Data>()

    // When
    val result = service.execute()

    // Then
    assertThat(result).isTrue()
}
```

#### 3. Assertions (Critical - Confidence 100)

**Truth обязательно:**
```kotlin
// ❌ Confidence: 100 - ЗАПРЕЩЕНО
assertEquals(expected, actual)
assertTrue(condition)
assertFalse(condition)

// ✅ Правильно
assertThat(actual).isEqualTo(expected)
assertThat(condition).isTrue()
assertThat(condition).isFalse()
```

#### 4. Flow handling (Critical - Confidence 100)

**FlowTestUtils обязательно для Flow:**
```kotlin
// ❌ Confidence: 100 - УТЕЧКИ ПАМЯТИ!
coVerify { mockRepository.getDataFlow() }

// ✅ Правильно
FlowTestUtils.coVerifyFlowCall {
    mockRepository.getDataFlow()
}
```

**tearDown:**
```kotlin
// ❌ Confidence: 90 - нет cleanup
@AfterEach
fun tearDown() {
    unmockkAll()
}

// ✅ Правильно
@AfterEach
fun tearDown() {
    unmockkAll()
    clearAllMocks()
    FlowTestUtils.cleanupFlowResources()
}
```

#### 5. Корутины (Confidence 85)

```kotlin
// ❌ Thread.sleep запрещён
Thread.sleep(1000)

// ✅ Правильно
testDispatcher.scheduler.advanceUntilIdle()
```

#### 6. Мокирование (Confidence 85)

**Suspend функции:**
```kotlin
// ✅ coEvery для suspend
coEvery { mockRepo.getData() } returns data

// ✅ coVerify для проверки suspend
coVerify { mockRepo.getData() }
```

### Шаг 3: Confidence scoring

Оцени каждую проблему:

- **100**: Backticks, assertEquals, отсутствие FlowTestUtils для Flow
- **90**: Моки без `mock`, нет @DisplayName, неполный tearDown
- **85**: Thread.sleep, неправильные coEvery/coVerify
- **80**: Нет Given-When-Then комментариев
- **<80**: НЕ репортировать!

**⚠️ Репортируй ТОЛЬКО проблемы с confidence ≥ 80**

### Шаг 4: Формат отчета

```markdown
## ✅/❌ Валидация: {ИМЯ_ФАЙЛА}

### Критические проблемы (Confidence 90-100)

**1. [Confidence: 100] Использование запрещённых JUnit assertions**
- Файл: `path/to/Test.kt:42`
- Проблема: `assertEquals(expected, actual)`
- Стандарт: ОБЯЗАТЕЛЬНО использовать Truth assertions
- Исправление:
  ```kotlin
  // Заменить
  assertEquals(expected, actual)
  // На
  assertThat(actual).isEqualTo(expected)
  ```

**2. [Confidence: 100] Отсутствует FlowTestUtils для Flow**
- Файл: `path/to/Test.kt:65`
- Проблема: `coVerify { mockRepository.getDataFlow() }` - утечки памяти!
- Стандарт: ОБЯЗАТЕЛЬНО использовать FlowTestUtils
- Исправление:
  ```kotlin
  FlowTestUtils.coVerifyFlowCall {
      mockRepository.getDataFlow()
  }
  ```

**3. [Confidence: 100] Использование backticks в имени метода**
- Файл: `path/to/Test.kt:25`
- Проблема: ``` fun `when data loads then success`() ```
- Стандарт: ЗАПРЕЩЕНО использовать backticks
- Исправление:
  ```kotlin
  @DisplayName("When data loads - Then success")
  @Test
  fun dataLoads_success() = runTest { }
  ```

### Важные проблемы (Confidence 80-89)

**4. [Confidence: 85] Отсутствуют Given-When-Then комментарии**
- Файл: `path/to/Test.kt:30-45`
- Проблема: Тест без структурных комментариев
- Стандарт: ОБЯЗАТЕЛЬНА структура Given-When-Then
- Исправление: Добавить комментарии `// Given`, `// When`, `// Then`

### Положительные моменты

- ✅ Правильное использование @DisplayName
- ✅ Корректная структура Given-When-Then
- ✅ Все моки названы с префиксом mock

### Статистика

- Критических проблем: 3
- Важных проблем: 1
- Соответствие стандартам: ❌ Требуются исправления

### Приоритет исправлений

1. **Немедленно**: Backticks, JUnit assertions, FlowTestUtils
2. **Важно**: Given-When-Then, моки без префикса
3. **Желательно**: Дополнить edge cases
```

### Шаг 5: НЕ проверяй (false positives)

**НЕ считай проблемами:**
- `mockk(relaxed = true)` vs `mockk()` - оба ok
- Разные стили @DisplayName ("When-Then" vs "WHEN THEN")
- Порядок imports
- Длину методов
- Конкретное количество тестов

## Output

Краткий отчет с:
- Только проблемами confidence ≥ 80
- Конкретными строками кода
- Чёткими инструкциями по исправлению
- Ссылками на стандарты

## Пример использования

```bash
/validate-test feature/auth/LoginUseCaseTest.kt
/validate-test feature/documents/src/test/
```
