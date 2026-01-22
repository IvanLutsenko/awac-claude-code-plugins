# Core Assertions - Truth Library

**Цель**: Базовые правила использования Truth assertions

---

## Truth (от Google)

Библиотека для более читаемых ассертов. **ОБЯЗАТЕЛЬНО использовать вместо JUnit assertions.**

```kotlin
import com.google.common.truth.Truth.assertThat
```

---

## Основные Patterns

### Boolean Assertions

```kotlin
// ✅ Правильно
assertThat(result).isTrue()
assertThat(condition).isFalse()

// ❌ Неправильно - НЕ использовать JUnit
assertTrue(result)
assertFalse(condition)
```

### Equality Assertions

```kotlin
// ✅ Правильно
assertThat(actual).isEqualTo(expected)
assertThat(result).isNotEqualTo(wrongValue)

// ❌ Неправильно - НЕ использовать JUnit
assertEquals(expected, actual)
assertNotEquals(wrongValue, result)
```

### Null Checks

```kotlin
// ✅ Правильно
assertThat(value).isNotNull()
assertThat(nullableValue).isNull()

// ❌ Неправильно - НЕ использовать JUnit
assertNotNull(value)
assertNull(nullableValue)
```

### Collections

```kotlin
// ✅ Правильно
assertThat(list).isEmpty()
assertThat(list).isNotEmpty()
assertThat(list).hasSize(3)
assertThat(list).contains(item)
assertThat(list).containsExactly(item1, item2, item3)

// ❌ Неправильно - НЕ использовать JUnit
assertTrue(list.isEmpty())
assertEquals(3, list.size)
```

### Type Checks

```kotlin
// ✅ Правильно
assertThat(result).isInstanceOf(RequestResult.Success::class.java)
assertThat(error).isInstanceOf(NetworkException::class.java)

// ❌ Неправильно - НЕ использовать JUnit
assertTrue(result is RequestResult.Success)
```

### Numbers

```kotlin
// ✅ Правильно
assertThat(amount).isGreaterThan(0)
assertThat(count).isAtLeast(1)
assertThat(value).isAtMost(100)

// ❌ Неправильно - НЕ использовать JUnit
assertTrue(amount > 0)
```

### Strings

```kotlin
// ✅ Правильно
assertThat(text).isEmpty()
assertThat(text).isNotEmpty()
assertThat(text).contains("substring")
assertThat(text).startsWith("prefix")
assertThat(text).endsWith("suffix")

// ❌ Неправильно - НЕ использовать JUnit
assertTrue(text.isEmpty())
assertTrue(text.contains("substring"))
```

---

## Given-When-Then Structure

Каждый тест **ОБЯЗАТЕЛЬНО** должен иметь комментарии:

```kotlin
@DisplayName("When validate call returns error - Then error is shown")
@Test
fun validateCall_error() = runTest {
    // Given: подготовка начальных данных
    val mockData = mockk<DataModel>(relaxed = true)
    coEvery { mockRepository.getData() } returns RequestResult.Success(mockData)

    // When: выполнение тестируемого действия
    val result = interactor.processData()

    // Then: проверка результатов с Truth assertions
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    assertThat((result as RequestResult.Success).data).isEqualTo(mockData)
}
```

---

## Chaining Assertions

Truth позволяет цепочку проверок:

```kotlin
// ✅ Правильно
assertThat(result)
    .isNotNull()
    .isInstanceOf(RequestResult.Success::class.java)

assertThat((result as RequestResult.Success).data)
    .isNotNull()
    .isEqualTo(expectedData)
```

---

## Common Mistakes

### ❌ Mistake 1: Using JUnit assertions

```kotlin
// ❌ Плохо
assertEquals(expected, actual)
assertTrue(condition)
assertNotNull(value)

// ✅ Хорошо
assertThat(actual).isEqualTo(expected)
assertThat(condition).isTrue()
assertThat(value).isNotNull()
```

### ❌ Mistake 2: No Given-When-Then comments

```kotlin
// ❌ Плохо
@Test
fun test() = runTest {
    val data = mockk<Data>()
    coEvery { mockRepo.getData() } returns data
    val result = service.process()
    assertThat(result).isNotNull()
}

// ✅ Хорошо
@Test
fun process_success() = runTest {
    // Given
    val expectedData = mockk<Data>()
    coEvery { mockRepository.getData() } returns expectedData

    // When
    val result = service.process()

    // Then
    assertThat(result).isNotNull()
    assertThat(result).isEqualTo(expectedData)
}
```

---

## Quick Reference

| Check | Truth Syntax |
|-------|--------------|
| Null | `assertThat(value).isNotNull()` |
| Not Null | `assertThat(value).isNull()` |
| Equality | `assertThat(actual).isEqualTo(expected)` |
| True | `assertThat(value).isTrue()` |
| False | `assertThat(value).isFalse()` |
| Empty | `assertThat(list).isEmpty()` |
| Size | `assertThat(list).hasSize(3)` |
| Contains | `assertThat(list).contains(item)` |
| Type | `assertThat(obj).isInstanceOf(Class::class.java)` |
| Greater | `assertThat(num).isGreaterThan(0)` |

---

## Size

**~500 tokens** - core patterns only
