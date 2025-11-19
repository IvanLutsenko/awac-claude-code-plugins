---
description: Покрытие unit тестами всех классов модуля где есть смысл у тестов
argument-hint: "path/to/module"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "TodoWrite"]
---

## Задача

Создать unit тесты для ВСЕХ классов модуля, где unit тесты имеют смысл.

Включает:
- ✅ **Бизнес-логика:** ViewModel, UseCase, Interactor, Repository
- ✅ **Utils с логикой:** Validators, Formatters, Helpers
- ✅ **State machines**
- ✅ **Custom delegates**
- ✅ **Mappers со сложной логикой**
- ✅ **Cache implementations**

Исключает:
- ❌ UI компоненты (Activity, Fragment, Composable)
- ❌ Data classes без логики
- ❌ DI modules
- ❌ Константы/Enums без логики
- ❌ Простые Builder классы
- ❌ Sealed classes без логики

## Workflow

### Шаг 1: Загрузи стандарты

```
!cat ~/.claude/plugins/marketplaces/awac-claude-code-plugins/plugins/test-standards/standards/android-kotlin.md
```

### Шаг 2: Полное сканирование модуля

Найди ВСЕ Kotlin файлы в модуле:

```bash
find {module_path}/src/main -type f -name "*.kt" | grep -v "/di/" | grep -v "/models/"
```

### Шаг 3: Классификация классов

Для каждого найденного файла:

1. **Прочитай файл** - понять содержимое
2. **Классифицируй** по категориям:

**Категория A - Требуют тестов (высокий приоритет):**
- ViewModel
- UseCase
- Interactor
- Repository

**Категория B - Требуют тестов (средний приоритет):**
- Validator (содержит логику валидации)
- Formatter (содержит логику форматирования)
- Util/Helper с логикой
- Cache implementations
- State machines
- Custom delegates

**Категория C - НЕ требуют тестов:**
- Data class (простые DTO)
- DI modules (Koin/Dagger)
- Activity/Fragment
- Composable функции
- Enum без логики
- Sealed class без логики
- Constants
- Simple mappers (только присваивание полей)

### Шаг 4: Критерии "имеет смысл тестировать"

Класс требует тестов если:
- ✅ Содержит if/when условия
- ✅ Содержит циклы
- ✅ Содержит математические операции
- ✅ Содержит string манипуляции
- ✅ Содержит логику трансформации данных
- ✅ Координирует другие компоненты
- ✅ Управляет состоянием
- ✅ Содержит async операции (Flow, suspend)

Класс НЕ требует тестов если:
- ❌ Только data class поля
- ❌ Только UI код (@Composable)
- ❌ Только DI конфигурация
- ❌ Только константы
- ❌ Простой mapper (field.copy())

### Шаг 5: Анализ примера

**Требует теста:**
```kotlin
// Validator с логикой
class PhoneValidator {
    fun validate(phone: String): Boolean {
        if (phone.isEmpty()) return false
        val cleanPhone = phone.filter { it.isDigit() }
        return cleanPhone.length in 10..11
    }
}

// Formatter с логикой
class CurrencyFormatter {
    fun format(amount: Double): String {
        return when {
            amount >= 1_000_000 -> "${amount / 1_000_000}M"
            amount >= 1_000 -> "${amount / 1_000}K"
            else -> amount.toString()
        }
    }
}

// Util с логикой
class DateUtils {
    fun isExpired(timestamp: Long): Boolean {
        val now = System.currentTimeMillis()
        return timestamp < now - EXPIRY_DURATION
    }
}
```

**НЕ требует теста:**
```kotlin
// Простой data class
data class User(val id: String, val name: String)

// DI module
val appModule = module {
    single { AuthRepository(get()) }
}

// Простой mapper
fun UserDTO.toModel() = User(
    id = this.id,
    name = this.name
)

// Константы
object Constants {
    const val API_URL = "https://api.example.com"
}
```

### Шаг 6: Создание плана

Создай план в TodoWrite, сгруппированный по приоритетам:

```
=== Категория A: Бизнес-логика (8 классов) ===
1. AuthViewModel - нужен BaseTest + 3 файла
2. LoginUseCase - нужен тест
3. AuthInteractor - нужен тест
4. AuthRepository - уже покрыт ✅
...

=== Категория B: Utils и helpers (5 классов) ===
9. PhoneValidator - нужен тест
10. AmountFormatter - нужен тест
11. SessionCache - нужен тест
...

=== Категория C: Не требуют тестов (12 классов) ===
- UserDTO (data class)
- AppModule (DI)
- UserMapper (простой)
...

Итого к покрытию: 13 классов
```

### Шаг 7: Генерация тестов

Для каждого класса из Категорий A и B:

1. **Прочитай класс** - понять логику
2. **Найди примеры** - похожие тесты:
   ```bash
   # Для бизнес-логики
   find . -name "*{Type}*Test.kt" -path "*/test/*" | head -3

   # Для validators
   find . -name "*Validator*Test.kt" -path "*/test/*" | head -3

   # Для utils
   find . -name "*Utils*Test.kt" -path "*/test/*" | head -3
   ```
3. **Прочитай примеры** - понять паттерны
4. **Сгенерируй тест** - по стандартам
5. **Отметь выполненным** в TodoWrite

### Шаг 8: Приоритизация

Генерируй в порядке:

**1. Категория A (критичная бизнес-логика):**
- UseCase (чистая бизнес-логика)
- Interactor (координация)
- Repository (данные)
- ViewModel (UI логика)

**2. Категория B (вспомогательная логика):**
- Validators (критично для data integrity)
- Cache (важно для performance)
- Formatters
- State machines
- Utils/Helpers

### Шаг 9: Примеры тестов разных типов

**Validator:**
```kotlin
class PhoneValidatorTest {

    private lateinit var validator: PhoneValidator

    @BeforeEach
    fun setUp() {
        validator = PhoneValidator()
    }

    @DisplayName("When phone is valid 10 digits - Then returns true")
    @Test
    fun phoneValid10Digits_returnsTrue() {
        // Given
        val phone = "1234567890"

        // When
        val result = validator.validate(phone)

        // Then
        assertThat(result).isTrue()
    }

    @DisplayName("When phone is empty - Then returns false")
    @Test
    fun phoneEmpty_returnsFalse() {
        // Given
        val phone = ""

        // When
        val result = validator.validate(phone)

        // Then
        assertThat(result).isFalse()
    }

    @DisplayName("When phone has formatting characters - Then validates cleaned number")
    @Test
    fun phoneWithFormatting_validatesCleanedNumber() {
        // Given
        val phone = "+7 (123) 456-78-90"

        // When
        val result = validator.validate(phone)

        // Then
        assertThat(result).isTrue()
    }
}
```

**Formatter:**
```kotlin
class CurrencyFormatterTest {

    private lateinit var formatter: CurrencyFormatter

    @BeforeEach
    fun setUp() {
        formatter = CurrencyFormatter()
    }

    @DisplayName("When amount is millions - Then formats with M suffix")
    @Test
    fun amountMillions_formatsWithM() {
        // Given
        val amount = 2_500_000.0

        // When
        val result = formatter.format(amount)

        // Then
        assertThat(result).isEqualTo("2.5M")
    }

    @DisplayName("When amount is thousands - Then formats with K suffix")
    @Test
    fun amountThousands_formatsWithK() {
        // Given
        val amount = 5_500.0

        // When
        val result = formatter.format(amount)

        // Then
        assertThat(result).isEqualTo("5.5K")
    }
}
```

**Cache:**
```kotlin
@ExperimentalCoroutinesApi
class SessionCacheTest {

    private lateinit var cache: SessionCache

    @BeforeEach
    fun setUp() {
        cache = SessionCache()
    }

    @AfterEach
    fun tearDown() {
        FlowTestUtils.cleanupFlowResources()
    }

    @DisplayName("WHEN data is set THEN cache emits new value")
    @Test
    fun dataSet_cacheEmitsNewValue() = runTest {
        // Given
        val expected = SessionData(userId = "123")

        // When
        cache.setSession(expected)

        // Then
        cache.sessionFlow.test {
            val item = awaitItem()
            assertThat(item).isEqualTo(expected)
            cancelAndIgnoreRemainingEvents()
        }
    }
}
```

### Шаг 10: Итоговый отчет

```markdown
## ✅ Полное покрытие модуля: {MODULE_NAME}

### Статистика

**Всего Kotlin файлов:** 35

**Категория A - Бизнес-логика:** 8 классов
- До: 3 покрыто (38%)
- После: 8 покрыто (100%) ✅

**Категория B - Utils и helpers:** 5 классов
- До: 0 покрыто (0%)
- После: 5 покрыто (100%) ✅

**Категория C - Не требуют тестов:** 22 класса
- Data classes: 8
- DI modules: 3
- UI components: 7
- Simple mappers: 4

**Итого покрытие:** 13/13 классов (100%) ✅

### Созданные тесты

#### Бизнес-логика
1. ✅ AuthViewModelBaseTest + 3 файла
2. ✅ LoginUseCaseTest
3. ✅ LogoutUseCaseTest
4. ✅ AuthInteractorTest
5. ✅ AuthRepositoryImplTest

#### Validators & Formatters
6. ✅ PhoneValidatorTest
7. ✅ AmountFormatterTest
8. ✅ DateFormatterTest

#### Cache & State
9. ✅ SessionCacheTest
10. ✅ AuthStateMachineTest

#### Utils
11. ✅ DateUtilsTest
12. ✅ StringUtilsTest
13. ✅ CryptoHelperTest

### Классы не требующие тестов

**Data classes (8):**
- UserDTO, AuthResponseDTO, SessionData, ...

**DI modules (3):**
- AppModule, NetworkModule, ...

**UI components (7):**
- LoginScreen.kt, AuthActivity.kt, ...

**Simple mappers (4):**
- UserMapper.kt, AuthMapper.kt, ...

### Рекомендации

1. Запустить все тесты: `./gradlew :{module}:test`
2. Проверить покрытие: `./gradlew :{module}:koverHtmlReport`
3. Целевое покрытие: 80%+ для бизнес-логики
```

## Пример использования

```bash
# Покрыть весь модуль
/test-module-all feature/auth

# Покрыть impl модуль
/test-module-all feature/qr-signing/qr-signing-impl
```

## Критические требования

При генерации ВСЕХ тестов соблюдай:
- ✅ @DisplayName (без backticks)
- ✅ Given-When-Then структура
- ✅ Truth assertions
- ✅ Префикс mock для моков
- ✅ FlowTestUtils для Flow
- ✅ Полный tearDown с cleanupFlowResources
- ✅ Happy path + error handling + edge cases
- ✅ Анализируй каждый класс - тестировать ли его
