---
allowed-tools: Read, Write, Edit, Glob, Grep, TodoWrite
description: Генерация unit теста для одного класса по корпоративным стандартам
---

## Задача

Сгенерировать unit тест для указанного класса, строго следуя корпоративным стандартам.

## Workflow

### Шаг 1: Загрузи стандарты

Прочитай файл со стандартами:
```
!cat ~/.claude/plugins/marketplaces/awac-claude-code-plugins/plugins/test-standards/standards/android-kotlin.md
```

### Шаг 2: Анализ исходного класса

1. Прочитай исходный файл
2. Определи слой архитектуры:
   - **ViewModel** - управление UI состоянием
   - **UseCase** - бизнес-логика
   - **Interactor** - координация UseCase
   - **Repository** - работа с данными
   - **Mapper** - преобразование данных
   - **Validator** - валидация
   - **Другое** - util, formatter и т.д.

3. Найди все зависимости для мокирования
4. Определи публичные методы для тестирования
5. Проверь использование корутин и Flow

### Шаг 3: Найди примеры в проекте

Используй `find` для поиска похожих тестов:

```bash
# Для Repository
find . -name "*RepositoryImplTest.kt" -path "*/test/*" | head -3

# Для Interactor
find . -name "*InteractorImplTest.kt" -path "*/test/*" | head -3

# Для UseCase
find . -name "*UseCaseTest.kt" -path "*/test/*" | head -3

# Для ViewModel
find . -name "*ViewModelBaseTest.kt" -path "*/test/*" | head -3
```

Прочитай 1-2 примера для понимания паттернов проекта.

### Шаг 4: Генерация теста

Создай тест со следующей структурой:

#### Обязательные элементы:

**1. Imports:**
```kotlin
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.DisplayName
import com.google.common.truth.Truth.assertThat
import io.mockk.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kz.berekebank.business.core.utils.testing.FlowTestUtils
```

**2. Структура класса:**
```kotlin
@ExperimentalCoroutinesApi
class {ClassName}Test {

    // Моки с префиксом mock
    private val mockDependency: Dependency = mockk(relaxed = true)
    private lateinit var classUnderTest: ClassName

    @BeforeEach
    fun setUp() {
        classUnderTest = ClassName(mockDependency)
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }

    // Тесты...
}
```

**3. Структура теста Given-When-Then:**
```kotlin
@DisplayName("When {condition} - Then {expected result}")
@Test
fun methodName_condition_result() = runTest {
    // Given: подготовка данных и моков
    val mockData = mockk<Data>(relaxed = true)
    coEvery { mockRepository.getData() } returns RequestResult.Success(mockData)

    // When: выполнение тестируемого действия
    val result = classUnderTest.execute()

    // Then: проверка результатов
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    coVerify { mockRepository.getData() }
}
```

### Шаг 5: Критические правила

✅ **ОБЯЗАТЕЛЬНО:**
- @DisplayName для каждого теста (без backticks!)
- Given-When-Then с комментариями
- Truth assertions (`assertThat`)
- Prefix `mock` для всех моков
- `FlowTestUtils.coVerifyFlowCall` для Flow методов
- `FlowTestUtils.cleanupFlowResources()` в tearDown

❌ **ЗАПРЕЩЕНО:**
- Backticks в именах методов
- JUnit assertions (assertEquals, assertTrue)
- Thread.sleep()
- Обычный coVerify для Flow

### Шаг 6: Покрытие

Сгенерируй тесты для:
- ✅ Happy path (успешный сценарий)
- ✅ Error handling (обработка ошибок)
- ✅ Edge cases (null, empty, большие значения)
- ✅ Все публичные методы

### Шаг 7: Специфика по слоям

**UseCase:**
```kotlin
@DisplayName("When execute with valid input - Then returns Success")
@Test
fun executeValidInput_returnsSuccess() = runTest {
    // Given
    val input = "validInput"
    val expected = mockk<Output>()
    coEvery { mockRepository.process(input) } returns RequestResult.Success(expected)

    // When
    val result = useCase.execute(input)

    // Then
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    coVerify { mockRepository.process(input) }
}
```

**Repository (с Flow):**
```kotlin
@DisplayName("When getData called - Then return Flow with DataState Success")
@Test
fun getData_returnsFlowWithSuccess() = runTest {
    // Given
    val mockedDto = mockk<DTO>(relaxed = true)
    val mockedModel = mockk<Model>(relaxed = true)

    mockkStatic("com.example.MapperKt") {
        coEvery { mockedDto.toModel() } returns mockedModel
        coEvery { mockApi.getData() } returns Response.success(mockedDto)

        // When & Then
        repository.getData().test {
            assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)
            val success = awaitItem()
            assertThat(success).isInstanceOf(DataState.Success::class.java)
            awaitComplete()
        }

        FlowTestUtils.coVerifyFlowCall { repository.getData() }
    }
}
```

**ViewModel (создай BaseTest если сложный):**
```kotlin
// BaseTest для сложных ViewModel
@ExperimentalCoroutinesApi
internal abstract class MyViewModelBaseTest {
    protected lateinit var testDispatcher: TestDispatcher
    protected val mockInteractor: Interactor = mockk(relaxed = true)
    protected lateinit var viewModel: MyViewModel

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

    protected fun initViewModel() {
        viewModel = MyViewModel(mockInteractor, testDispatcher)
    }
}
```

### Шаг 8: Валидация

Перед завершением проверь по чек-листу:
- [ ] @DisplayName присутствует (без backticks)
- [ ] Given-When-Then структура
- [ ] FlowTestUtils используется где нужно
- [ ] Все зависимости замоканы с префиксом mock
- [ ] tearDown с FlowTestUtils.cleanupFlowResources()
- [ ] Truth assertions

## Output

Выведи:
1. Путь к созданному файлу теста
2. Список сгенерированных тестовых методов
3. Примененные стандарты
4. Предложения для дополнительных тест-кейсов

## Пример использования

```bash
/generate-test feature/auth/domain/LoginUseCase.kt
/generate-test feature/documents/data/DocumentsRepositoryImpl.kt
```
