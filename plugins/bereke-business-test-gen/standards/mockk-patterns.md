# MockK Patterns

**Цель**: Правила использования MockK для мокирования зависимостей

---

## MockK Import

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

---

## Создание Моков

### Strict Mock (default)

```kotlin
// Строгий мок - нужно определять ВСЕ вызовы
private val mockRepository: Repository = mockk()
```

**Use when**: Нужен полный контроль над всеми взаимодействиями

### Relaxed Mock

```kotlin
// Relaxed мок - возвращает дефолтные значения
private val mockRepository: Repository = mockk(relaxed = true)
```

**Use when**: Фокус только на важных взаимодействиях, остальное не критично

### Naming Convention

**ОБЯЗАТЕЛЬНО использовать префикс `mock`:**

```kotlin
// ✅ Правильно
private val mockRepository: AuthRepository = mockk(relaxed = true)
private val mockApi: DataApi = mockk()
private val mockNavigator: NavigationController = mockk()

// ❌ Неправильно
private val repository: AuthRepository = mockk()
private val api: DataApi = mockk()
```

---

## Настройка Поведения (Stubbing)

### Обычные функции

```kotlin
every { mockResourceProvider.getString(R.string.error) } returns "Ошибка"
every { mockFormatter.format(any()) } returns "formatted"
every { mockValidator.isValid(any()) } returns true
```

### Suspend функции

```kotlin
coEvery { mockRepository.getData(any()) } returns RequestResult.Success(data)
coEvery { mockApi.fetchUser("123") } returns Response.success(userDto)
coEvery { mockInteractor.processData() } returns Unit
```

### Void методы (just runs)

```kotlin
// Для обычных функций
every { mockLauncher.launch() } just runs

// Для suspend функций
coEvery { mockRepository.clearCache() } just runs
coEvery { mockApi.logEvent(any()) } just runs
```

### Throwing Exceptions

```kotlin
// Обычные функции
every { mockValidator.validate(any()) } throws ValidationException()

// Suspend функции
coEvery { mockApi.getData() } throws NetworkException("Connection failed")
```

### Параметр any()

```kotlin
// Любой параметр
coEvery { mockRepository.getData(any()) } returns data

// Конкретное значение
coEvery { mockRepository.getData("123") } returns data

// Комбинация
coEvery {
    mockApi.request(
        url = any(),
        method = "POST"
    )
} returns response
```

---

## Verify (Проверка Вызовов)

### Обычные функции

```kotlin
verify { mockResourceProvider.getString(R.string.error) }
verify(exactly = 1) { mockFormatter.format(any()) }
verify(exactly = 2) { mockLauncher.invoke(any()) }
verify(atLeast = 1) { mockValidator.isValid(any()) }
```

### Suspend функции (НЕ Flow)

```kotlin
coVerify { mockRepository.getData(any()) }
coVerify(exactly = 1) { mockApi.fetchUser("123") }
coVerify(exactly = 2) { mockInteractor.processData() }
```

### ⚠️ ВАЖНО: НЕ использовать coVerify для Flow!

```kotlin
// ❌ НЕПРАВИЛЬНО для Flow методов
coVerify { mockRepository.getDataFlow() }  // Утечки памяти!

// ✅ ПРАВИЛЬНО - используй FlowTestUtils (см. flow-testing.md)
FlowTestUtils.coVerifyFlowCall {
    mockRepository.getDataFlow()
}
```

### Verify Order

```kotlin
verifyOrder {
    mockRepository.step1()
    mockRepository.step2()
    mockRepository.step3()
}

// Для suspend
coVerifyOrder {
    mockApi.authenticate()
    mockApi.fetchData()
}
```

### Verify Sequence

```kotlin
verifySequence {
    mockService.prepare()
    mockService.execute()
    mockService.cleanup()
}
```

---

## Мокирование Статических Функций

### Extension Functions

```kotlin
mockkStatic("kz.berekebank.business.data.mappers.MapperKt") {
    // Настройка поведения
    coEvery { mockedDto.toModel() } returns mockedDomainModel

    // Выполнение теста ВНУТРИ блока
    val result = repository.getData()

    // Проверка
    assertThat(result).isNotNull()
    coVerify { mockedDto.toModel() }
}  // Автоматический unmock при выходе из блока
```

### Static Object Methods

```kotlin
mockkStatic("kotlinx.coroutines.CoroutineScopeKt") {
    every { CoroutineScope(any()).launch(any(), any(), any()) } returns mockJob

    // Test code
    val result = service.processAsync()

    verify { CoroutineScope(any()).launch(any(), any(), any()) }
}
```

---

## Setup & Teardown

### Standard Setup

```kotlin
class ServiceTest {

    private val mockRepository: Repository = mockk(relaxed = true)
    private val mockApi: Api = mockk()
    private lateinit var service: Service

    @BeforeEach
    fun setUp() {
        service = Service(mockRepository, mockApi)
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()         // Очистить ВСЕ моки
        clearAllMocks()      // Очистить recorded calls
    }
}
```

### With Dispatcher (для ViewModel)

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class ViewModelTest {

    private lateinit var testDispatcher: TestDispatcher
    private val mockInteractor: Interactor = mockk(relaxed = true)
    private lateinit var viewModel: ViewModel

    @BeforeEach
    fun setUp() {
        testDispatcher = StandardTestDispatcher()
        Dispatchers.setMain(testDispatcher)

        viewModel = ViewModel(mockInteractor)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()  // Для Flow
    }
}
```

---

## Common Patterns

### Repository Test Pattern

```kotlin
@Test
fun getData_success() = runTest {
    // Given
    val expectedData = mockk<Data>(relaxed = true)
    coEvery { mockApi.fetchData() } returns Response.success(expectedData)

    // When
    val result = repository.getData()

    // Then
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    coVerify(exactly = 1) { mockApi.fetchData() }
}
```

### UseCase Test Pattern

```kotlin
@Test
fun execute_validInput_returnsSuccess() = runTest {
    // Given
    val input = "valid input"
    val expectedOutput = mockk<Output>()
    coEvery { mockRepository.process(input) } returns RequestResult.Success(expectedOutput)

    // When
    val result = useCase.execute(input)

    // Then
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    assertThat((result as RequestResult.Success).data).isEqualTo(expectedOutput)
    coVerify { mockRepository.process(input) }
}
```

---

## Common Mistakes

### ❌ Mistake 1: Forgetting unmockkAll

```kotlin
// ❌ Плохо - моки живут между тестами
@AfterEach
fun tearDown() {
    clearAllMocks()
}

// ✅ Хорошо
@AfterEach
fun tearDown() {
    unmockkAll()      // ← ОБЯЗАТЕЛЬНО
    clearAllMocks()
}
```

### ❌ Mistake 2: Using coVerify for Flow

```kotlin
// ❌ Плохо - утечки памяти с Kover!
coVerify { mockRepository.getDataFlow() }

// ✅ Хорошо - используй FlowTestUtils
FlowTestUtils.coVerifyFlowCall {
    mockRepository.getDataFlow()
}
```

### ❌ Mistake 3: No mock prefix

```kotlin
// ❌ Плохо
private val repository: Repository = mockk()

// ✅ Хорошо
private val mockRepository: Repository = mockk()
```

---

## Quick Reference

| Action | Syntax |
|--------|---------|
| Create mock | `mockk<Type>()` or `mockk(relaxed = true)` |
| Stub function | `every { mock.method() } returns value` |
| Stub suspend | `coEvery { mock.method() } returns value` |
| Stub void | `every { mock.method() } just runs` |
| Verify call | `verify { mock.method() }` |
| Verify suspend | `coVerify { mock.method() }` |
| Verify count | `verify(exactly = 2) { mock.method() }` |
| Mock static | `mockkStatic("package.FileKt") { }` |
| Cleanup | `unmockkAll()` and `clearAllMocks()` |

---

## Size

**~800 tokens** - MockK patterns and examples
