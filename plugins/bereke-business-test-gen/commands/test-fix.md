---
description: Автоисправление существующих тестов под корпоративные стандарты
argument-hint: "[--all|--assertions|--branches|--flow-verify|--display-names] path/to/module"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "TodoWrite", "Task"]
---

# Test Fix Command

Автоматический рефакторинг существующих unit тестов для соответствия корпоративным стандартам.

## Режимы

| Режим | Описание | Приоритет |
|-------|----------|-----------|
| `--all` | Все исправления | - |
| `--flow-verify` | coVerify → FlowTestUtils.coVerifyFlowCall | HIGH |
| `--branches` | Добавить тесты для непокрытых веток | HIGH |
| `--assertions` | assertTrue → assertThat | MEDIUM |
| `--display-names` | Добавить @DisplayName | LOW |

## Примеры

```bash
/test-fix --all feature/auth
/test-fix --flow-verify core/network
/test-fix --assertions core/domain
/test-fix --branches feature/payments/PaymentInteractorTest.kt
/test-fix --display-names feature/auth
```

## Режим: --flow-verify (HIGH Priority)

**Проблема**: `coVerify { flowMethod() }` вызывает memory leak!

**Исправление**:
```kotlin
// ❌ BEFORE - Memory leak!
@Test
fun getDataFlow_success() = runTest {
    repository.getDataFlow().test { ... }
    coVerify { mockRepo.getDataFlow() }
}

// ✅ AFTER - Correct
@Test
fun getDataFlow_success() = runTest {
    repository.getDataFlow().test { ... }
    FlowTestUtils.coVerifyFlowCall {
        mockRepo.getDataFlow()
    }
}
```

**Алгоритм**:
1. Найти все тестовые файлы в модуле:
   ```bash
   find ${MODULE_PATH}/src/test -name "*Test.kt"
   ```
2. Для каждого файла найти `coVerify` для Flow методов:
   ```bash
   grep -n "coVerify.*Flow\|coVerify.*flow" ${TEST_FILE}
   ```
3. Заменить на `FlowTestUtils.coVerifyFlowCall`
4. Добавить import если отсутствует

**Вывод**:
```
🔧 Flow Verify Fix Report
═══════════════════════════════════════════════════════

Module: feature/auth

Fixed files:
  ✅ AuthRepositoryTest.kt - 3 fixes
  ✅ LoginInteractorTest.kt - 1 fix
  ⏭️ TokenValidatorTest.kt - no Flow methods

Total: 4 memory leaks fixed!
```

---

## Режим: --branches (HIGH Priority)

**Проблема**: Тесты покрывают только happy path, ветки if/when не тестируются.

**Алгоритм**:
1. Вызвать `test-branch-analyzer` для source файла
2. Получить список непокрытых веток
3. Сгенерировать тесты для каждой ветки
4. Добавить в существующий тестовый файл

**Пример**:
```kotlin
// Source: PaymentInteractor.kt
fun processPayment(amount: Int): Result {
    if (amount <= 0) return Result.Error("Invalid amount")
    if (amount > MAX_AMOUNT) return Result.Error("Exceeds limit")
    return paymentRepo.process(amount)
}

// Existing test covers only success
@Test
fun processPayment_validAmount_success()

// After --branches:
@Test
fun processPayment_zeroAmount_returnsInvalidAmountError()

@Test
fun processPayment_negativeAmount_returnsInvalidAmountError()

@Test
fun processPayment_exceedsMaxAmount_returnsExceedsLimitError()
```

**Вывод**:
```
🌳 Branch Coverage Fix Report
═══════════════════════════════════════════════════════

File: PaymentInteractorTest.kt

Added tests for uncovered branches:
  ✅ processPayment_zeroAmount_returnsInvalidAmountError
  ✅ processPayment_negativeAmount_returnsInvalidAmountError
  ✅ processPayment_exceedsMaxAmount_returnsExceedsLimitError

Branch coverage: 33% → 100% (+67%)
```

---

## Режим: --assertions (MEDIUM Priority)

**Проблема**: Используются старые JUnit assertions вместо Truth.

**Замены**:
```kotlin
// ❌ BEFORE
assertTrue(result.isSuccess)
assertFalse(result.isEmpty)
assertEquals(expected, actual)
assertNotNull(result)
assertNull(result)

// ✅ AFTER
assertThat(result.isSuccess).isTrue()
assertThat(result.isEmpty).isFalse()
assertThat(actual).isEqualTo(expected)
assertThat(result).isNotNull()
assertThat(result).isNull()
```

**Алгоритм**:
1. Найти все тестовые файлы
2. Для каждого файла применить замены через Edit tool
3. Обновить imports:
   - Удалить: `import org.junit.Assert.*`
   - Добавить: `import com.google.common.truth.Truth.assertThat`

**Вывод**:
```
✨ Assertions Fix Report
═══════════════════════════════════════════════════════

Module: core/domain

Fixed files:
  ✅ UserValidatorTest.kt - 12 assertions
  ✅ AmountFormatterTest.kt - 8 assertions
  ✅ DateUtilsTest.kt - 5 assertions

Total: 25 assertions migrated to Truth
```

---

## Режим: --display-names (LOW Priority)

**Проблема**: Тесты без `@DisplayName` — непонятно что тестируется.

**Исправление**:
```kotlin
// ❌ BEFORE
@Test
fun login_validCredentials_success() = runTest { ... }

// ✅ AFTER
@Test
@DisplayName("login с валидными credentials возвращает success")
fun login_validCredentials_success() = runTest { ... }
```

**Алгоритм**:
1. Найти тесты без `@DisplayName`
2. Сгенерировать DisplayName из имени метода:
   - `login_validCredentials_success` → "login с валидными credentials возвращает success"
   - `processPayment_negativeAmount_error` → "processPayment с negative amount возвращает error"
3. Добавить аннотацию

**Вывод**:
```
📝 Display Names Fix Report
═══════════════════════════════════════════════════════

Module: feature/auth

Added @DisplayName:
  ✅ AuthRepositoryTest.kt - 8 tests
  ✅ LoginInteractorTest.kt - 5 tests
  ⏭️ TokenValidatorTest.kt - already has DisplayNames

Total: 13 @DisplayName annotations added
```

---

## Режим: --all

Выполняет все исправления в порядке приоритета:
1. `--flow-verify` (critical - memory leaks)
2. `--branches` (high - coverage)
3. `--assertions` (medium - style)
4. `--display-names` (low - readability)

**Вывод**:
```
🔧 Full Test Fix Report
═══════════════════════════════════════════════════════

Module: feature/auth

1. Flow Verify: 4 memory leaks fixed
2. Branches: 12 tests added, coverage +23%
3. Assertions: 25 migrated to Truth
4. Display Names: 13 added

✅ All fixes applied!

Run tests to verify:
./gradlew :feature:auth:test
```

## Зависимости

- **test-branch-analyzer** — анализ непокрытых веток
- **test-assertion-reviewer** — проверка assertions

## Безопасность

- Все изменения через Edit tool (не перезапись)
- Компиляция после каждого режима
- Rollback при ошибке компиляции
