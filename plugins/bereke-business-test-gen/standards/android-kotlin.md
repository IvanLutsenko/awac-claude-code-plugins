# Стандарты тестирования Android/Kotlin

## Используемые библиотеки

### JUnit Jupiter (JUnit 5)
Основной фреймворк для написания тестов.

```kotlin
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.DisplayName
```

### Truth (от Google)
Библиотека для более читаемых ассертов. **ОБЯЗАТЕЛЬНО использовать вместо JUnit assertions.**

```kotlin
import com.google.common.truth.Truth.assertThat

// ✅ Правильно
assertThat(result).isEqualTo(expected)
assertThat(list).isEmpty()
assertThat(value).isTrue()

// ❌ Неправильно - НЕ использовать JUnit assertions
assertEquals(expected, result)
assertTrue(value)
```

### MockK
Библиотека для мокирования зависимостей в Kotlin.

```kotlin
import io.mockk.mockk
import io.mockk.every
import io.mockk.coEvery
import io.mockk.verify
import io.mockk.coVerify
import io.mockk.just
import io.mockk.runs
import io.mockk.mockkStatic
import io.mockk.unmockkAll
import io.mockk.clearAllMocks
```

**Выбор между `mockk()` и `mockk(relaxed = true)`:**
- `mockk()` - когда нужен строгий контроль всех вызовов
- `mockk(relaxed = true)` - для сокращения boilerplate кода, фокус на важных взаимодействиях

### kotlinx-coroutines-test
Для тестирования корутин.

```kotlin
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestDispatcher
```

### Turbine
Для тестирования Flow в Kotlin.

```kotlin
import app.cash.turbine.test

viewModel.stateFlow.test {
    val item = awaitItem()
    assertThat(item).isEqualTo(expectedState)
    cancelAndIgnoreRemainingEvents()
}
```

### FlowTestUtils (Корпоративная утилита)
**ОБЯЗАТЕЛЬНО использовать** для верификации вызовов, возвращающих Flow, чтобы избежать утечек памяти при работе с Kover agent.

```kotlin
import kz.berekebank.business.core.utils.testing.FlowTestUtils

// ✅ Правильно - для методов возвращающих Flow
FlowTestUtils.coVerifyFlowCall {
    mockRepository.getDataFlow()
}

// Для обычных suspend методов
FlowTestUtils.verifyFlowCall {
    mockService.someMethod()
}

// ❌ Неправильно - НЕ использовать обычный coVerify для Flow
coVerify { mockRepository.getDataFlow() }  // Может привести к утечкам памяти!
```

## Подключение библиотек

Добавить в `build.gradle.kts` модуля:

```kotlin
plugins {
    alias(libs.plugins.business.testPlugin)
}
```

## Структура тестов

### Given-When-Then
Каждый тестовый метод **ОБЯЗАТЕЛЬНО** должен иметь структуру с комментариями:

```kotlin
@DisplayName("When validate call returns error - Then error is shown")
@Test
fun validateCall_error() = runTest {
    // Given: подготовка начальных данных и мокирование зависимостей
    val mockData = mockk<DataModel>(relaxed = true)
    coEvery { mockRepository.getData() } returns RequestResult.Success(mockData)

    // When: выполнение тестируемого действия
    val result = interactor.processData()

    // Then: проверка результатов
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    coVerify { mockRepository.getData() }
}
```

### Организация файлов

**Для простых классов:**
- Тесты в том же пакете, но в `src/test/` вместо `src/main/`
- Имя: `{ClassName}Test.kt`

**Для сложных классов (предпочтительный подход):**
- Создать базовый класс: `{ClassName}BaseTest.kt`
- Разделить тесты по функциональности:
  - `{ClassName}HandleIntentTest.kt`
  - `{ClassName}LoadDataTest.kt`
  - `{ClassName}ValidationTest.kt`

**Пример с @Nested для группировки:**

```kotlin
class ConversionCacheImplTest {

    private lateinit var cache: ConversionCacheImpl

    @BeforeEach
    fun setUp() {
        cache = ConversionCacheImpl()
    }

    @Nested
    inner class Initialization {

        @DisplayName("WHEN initialized THEN data is default")
        @Test
        fun initialized_dataIsDefault() = runTest {
            // Given & When
            // (initialization в setUp)

            // Then
            cache.conversionData.test {
                val item = awaitItem()
                assertThat(item).isEqualTo(ConversionData())
                cancelAndIgnoreRemainingEvents()
            }
        }
    }

    @Nested
    inner class DataUpdate {

        @DisplayName("WHEN setData called THEN data is updated")
        @Test
        fun setData_dataUpdated() = runTest {
            // Given
            val expectedData = ConversionData(buyingValue = "100")

            // When
            cache.setData(expectedData)

            // Then
            cache.conversionData.test {
                val item = awaitItem()
                assertThat(item).isEqualTo(expectedData)
                cancelAndIgnoreRemainingEvents()
            }
        }
    }
}
```

## Соглашения по именованию

### Имена тестовых классов
- `{ClassName}Test` для простых классов
- `{ClassName}BaseTest` для базового класса с setup
- `{ClassName}{Functionality}Test` для разделённых тестов

Примеры:
- `QrSigningRepositoryImplTest`
- `QrSigningViewModelBaseTest`
- `QrSigningViewModelHandleIntentTest`

### Имена тестовых методов

**ОБЯЗАТЕЛЬНО использовать @DisplayName:**

```kotlin
@DisplayName("When validate call returns error - Then error is shown")
@Test
fun validateCall_error() = runTest {
    // тест
}

@DisplayName("When auth factor is MySignPass - Then confirmWithPin is called")
@Test
fun authFactorMySignPass_confirmWithPinCalled() = runTest {
    // тест
}

@DisplayName("WHEN initialized THEN conversionData is default")
@Test
fun initialized_conversionDataDefault() = runTest {
    // тест
}
```

**Формат @DisplayName:**
- `"When [условие/действие] - Then [ожидаемый результат]"`
- `"WHEN [условие] THEN [результат]"` (для @Nested классов)

**Формат имени метода:** `{funcName}_{condition}__{result/action}`
- Короткое, camelCase имя
- Описание логики в @DisplayName
- Примеры:
  - `validateCall_error()`
  - `getSignInfo_success()`
  - `authFactorMySignPass_confirmWithPinCalled()`
  - `initialized_dataIsDefault()`

### Имена мокированных переменных

**ОБЯЗАТЕЛЬНО использовать префикс `mock`:**

```kotlin
private val mockQrSigningInteractor: QrSigningInteractor = mockk(relaxed = true)
private val mockResourceProvider: ResourceProvider = mockk()
private val mockNavigator: NavigationController = mockk()
```

## Слои бизнес-логики для тестирования

### UseCase
UseCase содержат бизнес-логику и должны быть покрыты тестами.

```kotlin
class LoginUseCaseTest {

    private val mockRepository: AuthRepository = mockk(relaxed = true)
    private lateinit var useCase: LoginUseCase

    @BeforeEach
    fun setUp() {
        useCase = LoginUseCase(mockRepository)
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
    }

    @DisplayName("When login with valid credentials - Then return Success")
    @Test
    fun loginValidCredentials_returnsSuccess() = runTest {
        // Given
        val username = "user"
        val password = "pass"
        val mockUser = mockk<User>()
        coEvery { mockRepository.login(username, password) } returns RequestResult.Success(mockUser)

        // When
        val result = useCase.execute(username, password)

        // Then
        assertThat(result).isInstanceOf(RequestResult.Success::class.java)
        assertThat((result as RequestResult.Success).result).isEqualTo(mockUser)
        coVerify { mockRepository.login(username, password) }
    }
}
```

### Interactor
Interactor координирует UseCase и содержит бизнес-логику.

```kotlin
@DisplayName("When startProcess called - Then repository method called with correct parameters")
@Test
fun startProcess_callsRepositoryWithCorrectParams() = runTest {
    // Given
    val inputData = mockk<InputData>()
    val expectedResult = OutputModel(id = "123", status = "success")

    coEvery {
        mockRepository.process(
            auth = true,
            data = inputData,
            type = ProcessType.STANDARD.name
        )
    } returns RequestResult.Success(expectedResult)

    // When
    val result = interactor.startProcess(inputData)

    // Then
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    assertThat((result as RequestResult.Success).result).isEqualTo(expectedResult)

    coVerify {
        mockRepository.process(
            auth = true,
            data = inputData,
            type = ProcessType.STANDARD.name
        )
    }
}
```

### ViewModel
ViewModel содержит UI логику и управляет состоянием.

### Repository
Repository содержит логику работы с данными.

## Классы НЕ требующие unit тестов

**Не покрывать тестами:**
- **UI компоненты:** Activity, Fragment, Composable функции
- **Data классы:** Data classes, DTO без логики
- **Mappers:** Простые extension функции маппинга (если нет сложной логики)
- **DI modules:** Koin/Dagger модули
- **Constants/Enums:** Объекты констант, простые enum
- **Sealed classes:** Без логики
- **Builder классы:** Простые builder без логики

**Требуют покрытия:**
- ViewModel (UI логика)
- UseCase (бизнес-логика)
- Interactor (координация UseCase)
- Repository (логика данных)
- Validators
- Formatters с логикой
- Utils с логикой
- Custom delegates
- State machines

## Мокирование зависимостей

### Создание моков

```kotlin
// Строгий мок - нужно определять все вызовы
private val mockRepository: Repository = mockk()

// Relaxed мок - возвращает дефолтные значения
private val mockRepository: Repository = mockk(relaxed = true)
```

### Настройка поведения

**Обычные функции:**
```kotlin
every { mockResourceProvider.getString(R.string.error) } returns "Ошибка"
every { mockLauncher.invoke(any()) } just runs
```

**Suspend функции:**
```kotlin
coEvery { mockRepository.getData(any()) } returns RequestResult.Success(data)
coEvery { mockInteractor.processData() } returns Unit
```

**Функции без возвращаемого значения:**
```kotlin
every { mockLauncher.launch() } just runs
coEvery { mockRepository.clearCache() } just runs
```

### Проверка вызовов

**⚠️ ВАЖНО: Для методов возвращающих Flow используйте FlowTestUtils!**

**Для Flow методов (ОБЯЗАТЕЛЬНО через FlowTestUtils):**
```kotlin
// ✅ Правильно
FlowTestUtils.coVerifyFlowCall {
    mockRepository.getDataFlow()
}

FlowTestUtils.coVerifyFlowCall(exactly = 2) {
    mockRepository.getUpdatesFlow()
}

// ❌ Неправильно - утечки памяти!
coVerify { mockRepository.getDataFlow() }
```

**Обычные функции:**
```kotlin
verify { mockResourceProvider.getString(R.string.error) }
verify(exactly = 2) { mockLauncher.invoke(any()) }
```

**Suspend функции (НЕ возвращающие Flow):**
```kotlin
coVerify { mockRepository.getData(any()) }
coVerify(exactly = 1) { mockInteractor.processData() }
```

### Мокирование статических функций

```kotlin
mockkStatic("kz.berekebank.business.feature.module.data.mappers.MapperKt") {
    coEvery { mockedDto.toModel() } returns mockedDomainModel

    // выполнение теста внутри блока
    val result = repository.getData()

    coVerify { mockedDto.toModel() }
}
```

## Тестирование асинхронного кода

### Тестирование корутин

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class ViewModelTest {

    private lateinit var testDispatcher: TestDispatcher

    @BeforeEach
    fun setup() {
        testDispatcher = StandardTestDispatcher()
        Dispatchers.setMain(testDispatcher)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        testDispatcher.scheduler.runCurrent()
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }

    @DisplayName("When loadData called - Then data is loaded successfully")
    @Test
    fun loadData_success() = runTest(testDispatcher) {
        // Given
        val viewModel = createViewModel()

        // When
        viewModel.loadData()
        testDispatcher.scheduler.advanceUntilIdle()  // ждём завершения корутин

        // Then
        assertThat(viewModel.state.value.isLoading).isFalse()
    }
}
```

### Тестирование Flow с Turbine

```kotlin
@DisplayName("When data updates - Then Flow emits new state")
@Test
fun dataUpdates_flowEmitsNewState() = runTest {
    // Given
    val repository = createRepository()

    // When & Then
    repository.dataFlow.test {
        // Проверяем первый элемент
        val initialState = awaitItem()
        assertThat(initialState).isEqualTo(DataState.Loading)

        // Триггерим обновление
        repository.updateData(newData)

        // Проверяем новый элемент
        val updatedState = awaitItem()
        assertThat(updatedState).isInstanceOf(DataState.Success::class.java)

        cancelAndIgnoreRemainingEvents()
    }

    // ✅ ВАЖНО: Используем FlowTestUtils для верификации
    FlowTestUtils.coVerifyFlowCall {
        repository.dataFlow
    }
}
```

### Cleanup в tearDown

**ОБЯЗАТЕЛЬНО добавлять FlowTestUtils.cleanupFlowResources():**

```kotlin
@AfterEach
fun tearDown() {
    Dispatchers.resetMain()
    testDispatcher.scheduler.runCurrent()
    unmockkAll()
    clearAllMocks()

    // ✅ ВАЖНО: Очищаем Flow ресурсы для предотвращения утечек с Kover
    FlowTestUtils.cleanupFlowResources()
}
```

## Запрещённые практики

❌ **НЕ использовать JUnit assertions:**
```kotlin
// ❌ Плохо
assertEquals(expected, actual)
assertTrue(condition)

// ✅ Хорошо
assertThat(actual).isEqualTo(expected)
assertThat(condition).isTrue()
```

❌ **НЕ использовать Thread.sleep():**
```kotlin
// ❌ Плохо
Thread.sleep(1000)

// ✅ Хорошо
testDispatcher.scheduler.advanceUntilIdle()
```

❌ **НЕ использовать обычный coVerify для Flow:**
```kotlin
// ❌ Плохо - утечки памяти с Kover!
coVerify { mockRepository.getDataFlow() }

// ✅ Хорошо
FlowTestUtils.coVerifyFlowCall {
    mockRepository.getDataFlow()
}
```

❌ **НЕ использовать backticks в именах методов:**
```kotlin
// ❌ Плохо
@Test
fun `when data loads then state updates`() = runTest { }

// ✅ Хорошо
@DisplayName("When data loads - Then state updates")
@Test
fun dataLoads_stateUpdates() = runTest { }
```

❌ **НЕ забывать cleanup:**
```kotlin
@AfterEach
fun tearDown() {
    Dispatchers.resetMain()
    unmockkAll()
    clearAllMocks()
    FlowTestUtils.cleanupFlowResources()  // ✅ ОБЯЗАТЕЛЬНО
}
```

## Чек-лист для каждого теста

- [ ] ✅ Использован формат Given-When-Then с комментариями
- [ ] ✅ Используется @DisplayName для описания теста
- [ ] ✅ Имя метода короткое в camelCase
- [ ] ✅ Используются Truth assertions (`assertThat`)
- [ ] ✅ Моки названы с префиксом `mock`
- [ ] ✅ Для suspend функций используется `coEvery`/`coVerify`
- [ ] ✅ Для Flow методов используется `FlowTestUtils.coVerifyFlowCall`
- [ ] ✅ Для корутин используется `runTest` и `advanceUntilIdle`
- [ ] ✅ Для Flow используется Turbine
- [ ] ✅ Статические функции мокируются через `mockkStatic`
- [ ] ✅ В `tearDown` вызывается `FlowTestUtils.cleanupFlowResources()`
