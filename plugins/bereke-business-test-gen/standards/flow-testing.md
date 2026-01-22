# Flow Testing - Turbine + FlowTestUtils

**Цель**: Правила тестирования Flow методов с использованием Turbine и FlowTestUtils

---

## ⚠️ КРИТИЧНО: FlowTestUtils для верификации!

**ОБЯЗАТЕЛЬНО использовать FlowTestUtils** для verify вызовов Flow методов!

```kotlin
import kz.berekebank.business.core.utils.testing.FlowTestUtils
```

**Почему?** Предотвращение утечек памяти при работе с Kover coverage agent.

---

## Turbine для Тестирования Flow

```kotlin
import app.cash.turbine.test
```

### Pattern 1: Flow<DataState>

```kotlin
@DisplayName("When getData called - Then Flow emits Loading then Success")
@Test
fun getData_emitsLoadingThenSuccess() = runTest {
    // Given
    val expectedData = mockk<Data>(relaxed = true)
    coEvery { mockApi.fetchData() } returns Response.success(expectedData)

    // When & Then
    repository.getData().test {
        // First emission
        assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)

        // Second emission
        val success = awaitItem()
        assertThat(success).isInstanceOf(DataState.Success::class.java)
        assertThat((success as DataState.Success).data).isEqualTo(expectedData)

        // Complete
        awaitComplete()
    }

    // ✅ ВАЖНО: Используем FlowTestUtils для верификации!
    FlowTestUtils.coVerifyFlowCall {
        repository.getData()
    }
}
```

### Pattern 2: Flow<T> (simple type)

```kotlin
@DisplayName("When observeUpdates - Then Flow emits values")
@Test
fun observeUpdates_emitsValues() = runTest {
    // Given
    val flow = MutableStateFlow("initial")

    // When & Then
    flow.test {
        assertThat(awaitItem()).isEqualTo("initial")

        flow.value = "updated"
        assertThat(awaitItem()).isEqualTo("updated")

        cancelAndIgnoreRemainingEvents()
    }
}
```

### Pattern 3: Flow<PagingData<T>>

```kotlin
@DisplayName("When searchDocuments - Then returns PagingData flow")
@Test
fun searchDocuments_returnsPagingData() = runTest {
    // Given
    val query = "test query"

    // When & Then
    repository.searchDocuments(query).test {
        val pagingData = awaitItem()
        assertThat(pagingData).isNotNull()

        cancelAndIgnoreRemainingEvents()
    }

    // ✅ ВАЖНО: FlowTestUtils для Flow методов!
    FlowTestUtils.coVerifyFlowCall {
        repository.searchDocuments(query)
    }
}
```

---

## FlowTestUtils Methods

### coVerifyFlowCall (для suspend Flow методов)

```kotlin
// ✅ Правильно - для методов возвращающих Flow
FlowTestUtils.coVerifyFlowCall {
    mockRepository.getDataFlow()
}

// С exactly count
FlowTestUtils.coVerifyFlowCall(exactly = 2) {
    mockRepository.getUpdatesFlow()
}

// ❌ Неправильно - утечки памяти!
coVerify { mockRepository.getDataFlow() }
```

### verifyFlowCall (для обычных Flow методов)

```kotlin
// Для не-suspend методов возвращающих Flow
FlowTestUtils.verifyFlowCall {
    mockService.observeState()
}
```

### cleanupFlowResources (в tearDown)

```kotlin
@AfterEach
fun tearDown() {
    Dispatchers.resetMain()
    unmockkAll()
    clearAllMocks()

    // ✅ ОБЯЗАТЕЛЬНО: Очищаем Flow ресурсы!
    FlowTestUtils.cleanupFlowResources()
}
```

---

## Turbine Methods Reference

### awaitItem()

Ожидает следующую эмиссию:

```kotlin
flow.test {
    val item = awaitItem()
    assertThat(item).isEqualTo(expectedValue)
}
```

### awaitComplete()

Ожидает завершения Flow:

```kotlin
flow.test {
    val item = awaitItem()
    awaitComplete()  // Flow должен закончиться
}
```

### awaitError()

Ожидает ошибку:

```kotlin
flow.test {
    val error = awaitError()
    assertThat(error).isInstanceOf(NetworkException::class.java)
}
```

### cancelAndIgnoreRemainingEvents()

Отменяет Flow и игнорирует остальные события:

```kotlin
flow.test {
    val item = awaitItem()
    assertThat(item).isNotNull()

    // Закрываем поток, не ждем complete
    cancelAndIgnoreRemainingEvents()
}
```

### expectNoEvents()

Проверяет что нет новых эмиссий:

```kotlin
flow.test {
    expectNoEvents()  // Нет эмиссий

    triggerUpdate()

    val item = awaitItem()
    assertThat(item).isNotNull()
}
```

---

## Complete Flow Test Pattern

```kotlin
@ExperimentalCoroutinesApi
class RepositoryFlowTest {

    private val mockApi: DataApi = mockk(relaxed = true)
    private lateinit var repository: RepositoryImpl

    @BeforeEach
    fun setUp() {
        repository = RepositoryImpl(mockApi)
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()  // ✅ ОБЯЗАТЕЛЬНО
    }

    @DisplayName("When getDataFlow - Then emits Loading, Success sequence")
    @Test
    fun getDataFlow_emitsLoadingSuccess() = runTest {
        // Given
        val expectedData = mockk<Data>()
        coEvery { mockApi.fetchData() } returns Response.success(expectedData)

        // When & Then
        repository.getDataFlow().test {
            // Loading state
            assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)

            // Success state
            val success = awaitItem()
            assertThat(success).isInstanceOf(DataState.Success::class.java)
            assertThat((success as DataState.Success).data).isEqualTo(expectedData)

            awaitComplete()
        }

        // ✅ ВАЖНО: Verify через FlowTestUtils!
        FlowTestUtils.coVerifyFlowCall {
            repository.getDataFlow()
        }
    }

    @DisplayName("When getDataFlow with error - Then emits Error state")
    @Test
    fun getDataFlow_error_emitsErrorState() = runTest {
        // Given
        val exception = NetworkException("Connection failed")
        coEvery { mockApi.fetchData() } throws exception

        // When & Then
        repository.getDataFlow().test {
            // Loading state
            assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)

            // Error state
            val error = awaitItem()
            assertThat(error).isInstanceOf(DataState.Error::class.java)

            awaitComplete()
        }

        // ✅ Verify
        FlowTestUtils.coVerifyFlowCall {
            repository.getDataFlow()
        }
    }
}
```

---

## StateFlow & SharedFlow Patterns

### StateFlow

```kotlin
@DisplayName("When state updated - Then StateFlow emits new value")
@Test
fun stateUpdated_stateFlowEmits() = runTest {
    // Given
    val viewModel = createViewModel()

    // When & Then
    viewModel.stateFlow.test {
        // Initial state
        val initial = awaitItem()
        assertThat(initial).isEqualTo(InitialState)

        // Trigger update
        viewModel.updateState(NewState)

        // New state
        val updated = awaitItem()
        assertThat(updated).isEqualTo(NewState)

        cancelAndIgnoreRemainingEvents()
    }
}
```

### SharedFlow

```kotlin
@DisplayName("When event emitted - Then SharedFlow receives it")
@Test
fun eventEmitted_sharedFlowReceives() = runTest {
    // Given
    val eventBus = EventBus()

    // When & Then
    eventBus.events.test {
        // Нет начальной эмиссии
        expectNoEvents()

        // Emit event
        eventBus.emit(Event.UserLoggedIn)

        // Receive
        val event = awaitItem()
        assertThat(event).isInstanceOf(Event.UserLoggedIn::class.java)

        cancelAndIgnoreRemainingEvents()
    }
}
```

---

## Common Mistakes

### ❌ Mistake 1: Using coVerify for Flow

```kotlin
// ❌ ПЛОХО - утечки памяти с Kover!
repository.getDataFlow().test {
    awaitItem()
    cancelAndIgnoreRemainingEvents()
}
coVerify { repository.getDataFlow() }  // ← WRONG!

// ✅ ХОРОШО
repository.getDataFlow().test {
    awaitItem()
    cancelAndIgnoreRemainingEvents()
}
FlowTestUtils.coVerifyFlowCall {  // ← CORRECT!
    repository.getDataFlow()
}
```

### ❌ Mistake 2: Forgetting cleanup

```kotlin
// ❌ ПЛОХО - Flow ресурсы не очищены
@AfterEach
fun tearDown() {
    unmockkAll()
}

// ✅ ХОРОШО
@AfterEach
fun tearDown() {
    unmockkAll()
    clearAllMocks()
    FlowTestUtils.cleanupFlowResources()  // ← ОБЯЗАТЕЛЬНО!
}
```

### ❌ Mistake 3: Not using test { }

```kotlin
// ❌ ПЛОХО - прямой collect без Turbine
@Test
fun badTest() = runTest {
    val items = mutableListOf<Item>()
    repository.getFlow().collect { items.add(it) }
    assertThat(items).isNotEmpty()
}

// ✅ ХОРОШО - используй Turbine
@Test
fun goodTest() = runTest {
    repository.getFlow().test {
        val item = awaitItem()
        assertThat(item).isNotNull()
        cancelAndIgnoreRemainingEvents()
    }
}
```

### ❌ Mistake 4: Not canceling infinite flows

```kotlin
// ❌ ПЛОХО - infinite Flow без cancel
@Test
fun badTest() = runTest {
    stateFlow.test {
        awaitItem()
        awaitItem()
        // Test висит - StateFlow бесконечный!
    }
}

// ✅ ХОРОШО
@Test
fun goodTest() = runTest {
    stateFlow.test {
        val item1 = awaitItem()
        val item2 = awaitItem()

        cancelAndIgnoreRemainingEvents()  // ← ОБЯЗАТЕЛЬНО для infinite flows
    }
}
```

---

## Quick Reference

| Action | Turbine Method |
|--------|----------------|
| Get next emission | `awaitItem()` |
| Wait for completion | `awaitComplete()` |
| Wait for error | `awaitError()` |
| Cancel and close | `cancelAndIgnoreRemainingEvents()` |
| Check no events | `expectNoEvents()` |

| Verify Flow Method | FlowTestUtils |
|-------------------|---------------|
| Suspend Flow method | `FlowTestUtils.coVerifyFlowCall { }` |
| Non-suspend Flow method | `FlowTestUtils.verifyFlowCall { }` |
| Cleanup (in tearDown) | `FlowTestUtils.cleanupFlowResources()` |

---

## Size

**~1500 tokens** - Comprehensive Flow testing guide
