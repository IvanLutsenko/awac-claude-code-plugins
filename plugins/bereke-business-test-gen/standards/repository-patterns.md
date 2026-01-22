# Repository Test Patterns

**Цель**: Специфичные паттерны для тестирования Repository слоя

---

## Repository Role

Repository содержит логику работы с данными:
- Вызовы API
- Кэширование
- Маппинг DTO → Domain models
- Error handling
- Flow-based data streams

---

## Standard Repository Test Structure

```kotlin
@ExperimentalCoroutinesApi
class AuthRepositoryImplTest {

    private val mockApi: AuthApi = mockk(relaxed = true)
    private val mockCache: Cache = mockk(relaxed = true)
    private lateinit var repository: AuthRepositoryImpl

    @BeforeEach
    fun setUp() {
        repository = AuthRepositoryImpl(mockApi, mockCache)
    }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }
}
```

---

## Pattern 1: Simple Wrapper Method (✅ ТЕСТИРОВАТЬ!)

**Почему?** Проверяем правильность вызова API, обработку ошибок, маппинг

```kotlin
// Source
class AuthRepository(private val api: AuthApi) {
    suspend fun getUser(userId: String): RequestResult<User> {
        return api.getUser(userId)  // Simple wrapper
    }
}

// Test
@DisplayName("When getUser called - Then returns result from API")
@Test
fun getUser_success() = runTest {
    // Given
    val userId = "123"
    val expectedUser = mockk<User>(relaxed = true)
    coEvery { mockApi.getUser(userId) } returns RequestResult.Success(expectedUser)

    // When
    val result = repository.getUser(userId)

    // Then
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    assertThat((result as RequestResult.Success).data).isEqualTo(expectedUser)
    coVerify(exactly = 1) { mockApi.getUser(userId) }
}

@DisplayName("When getUser with error - Then error is returned")
@Test
fun getUser_error() = runTest {
    // Given
    val userId = "123"
    val exception = NetworkException("Connection failed")
    coEvery { mockApi.getUser(userId) } throws exception

    // When
    val result = repository.getUser(userId)

    // Then
    assertThat(result).isInstanceOf(RequestResult.Error::class.java)
    coVerify(exactly = 1) { mockApi.getUser(userId) }
}
```

---

## Pattern 2: Flow<DataState> Method

**Use**: Для методов возвращающих Flow с состояниями (Loading, Success, Error)

```kotlin
// Source
class DataRepository(private val api: DataApi) {
    fun getDataFlow(): Flow<DataState<Data>> = flow {
        emit(DataState.Loading)
        try {
            val response = api.fetchData()
            emit(DataState.Success(response))
        } catch (e: Exception) {
            emit(DataState.Error(e))
        }
    }
}

// Test
@DisplayName("When getDataFlow - Then emits Loading, Success sequence")
@Test
fun getDataFlow_success() = runTest {
    // Given
    val expectedData = mockk<Data>()
    coEvery { mockApi.fetchData() } returns expectedData

    // When & Then
    repository.getDataFlow().test {
        assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)

        val success = awaitItem()
        assertThat(success).isInstanceOf(DataState.Success::class.java)
        assertThat((success as DataState.Success).data).isEqualTo(expectedData)

        awaitComplete()
    }

    // ✅ ВАЖНО: FlowTestUtils для верификации!
    FlowTestUtils.coVerifyFlowCall {
        repository.getDataFlow()
    }
}

@DisplayName("When getDataFlow with error - Then emits Error state")
@Test
fun getDataFlow_error() = runTest {
    // Given
    val exception = NetworkException("API error")
    coEvery { mockApi.fetchData() } throws exception

    // When & Then
    repository.getDataFlow().test {
        assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)

        val error = awaitItem()
        assertThat(error).isInstanceOf(DataState.Error::class.java)

        awaitComplete()
    }

    FlowTestUtils.coVerifyFlowCall {
        repository.getDataFlow()
    }
}
```

---

## Pattern 3: Flow<PagingData> Method

**Use**: Для методов возвращающих paginated data через Flow

```kotlin
// Source
class DocumentRepository(private val api: DocumentApi) {
    fun searchDocuments(query: String): Flow<PagingData<Document>> {
        return api.searchDocuments(query)
    }
}

// Test
@DisplayName("When searchDocuments - Then returns PagingData Flow")
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

    FlowTestUtils.coVerifyFlowCall {
        repository.searchDocuments(query)
    }
}
```

---

## Pattern 4: With Mapper (mockkStatic)

**Use**: Когда Repository использует extension function для маппинга DTO → Model

```kotlin
// Source
class UserRepository(private val api: UserApi) {
    suspend fun getUser(id: String): RequestResult<User> {
        val dto = api.fetchUser(id)
        return RequestResult.Success(dto.toModel())  // Extension function
    }
}

// Test
@DisplayName("When getUser - Then DTO is mapped to Model")
@Test
fun getUser_mapsDto() = runTest {
    // Given
    val userId = "123"
    val userDto = mockk<UserDto>(relaxed = true)
    val expectedUser = mockk<User>(relaxed = true)

    coEvery { mockApi.fetchUser(userId) } returns userDto

    mockkStatic("kz.berekebank.data.mappers.UserMapperKt") {
        coEvery { userDto.toModel() } returns expectedUser

        // When
        val result = repository.getUser(userId)

        // Then
        assertThat(result).isInstanceOf(RequestResult.Success::class.java)
        assertThat((result as RequestResult.Success).data).isEqualTo(expectedUser)

        coVerify { mockApi.fetchUser(userId) }
        coVerify { userDto.toModel() }
    }
}
```

---

## Pattern 5: With Cache Logic

**Use**: Repository с кэшированием

```kotlin
// Source
class CachedRepository(
    private val api: Api,
    private val cache: Cache
) {
    suspend fun getData(forceRefresh: Boolean = false): RequestResult<Data> {
        if (!forceRefresh) {
            val cached = cache.get()
            if (cached != null) return RequestResult.Success(cached)
        }

        val fresh = api.fetchData()
        cache.put(fresh)
        return RequestResult.Success(fresh)
    }
}

// Tests
@DisplayName("When getData with cache hit - Then returns cached data")
@Test
fun getData_cacheHit() = runTest {
    // Given
    val cachedData = mockk<Data>()
    every { mockCache.get() } returns cachedData

    // When
    val result = repository.getData(forceRefresh = false)

    // Then
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    assertThat((result as RequestResult.Success).data).isEqualTo(cachedData)

    verify { mockCache.get() }
    coVerify(exactly = 0) { mockApi.fetchData() }  // API not called
}

@DisplayName("When getData with forceRefresh - Then fetches from API")
@Test
fun getData_forceRefresh() = runTest {
    // Given
    val freshData = mockk<Data>()
    coEvery { mockApi.fetchData() } returns freshData

    // When
    val result = repository.getData(forceRefresh = true)

    // Then
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    coVerify { mockApi.fetchData() }
    verify { mockCache.put(freshData) }  // Cached
}
```

---

## Common Repository Scenarios

### Happy Path

```kotlin
@Test
fun method_validInput_returnsSuccess() = runTest {
    // Given
    coEvery { mockApi.method() } returns expectedResult

    // When
    val result = repository.method()

    // Then
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    coVerify { mockApi.method() }
}
```

### Error Handling

```kotlin
@Test
fun method_apiThrows_returnsError() = runTest {
    // Given
    val exception = NetworkException("Connection failed")
    coEvery { mockApi.method() } throws exception

    // When
    val result = repository.method()

    // Then
    assertThat(result).isInstanceOf(RequestResult.Error::class.java)
    coVerify { mockApi.method() }
}
```

### Null Response

```kotlin
@Test
fun method_nullResponse_handlesGracefully() = runTest {
    // Given
    coEvery { mockApi.method() } returns null

    // When
    val result = repository.method()

    // Then
    assertThat(result).isInstanceOf(RequestResult.Error::class.java)
    // Or Success with null, depending on contract
}
```

---

## Important Notes

### ✅ DO Test Wrapper Methods

```kotlin
// ✅ ТЕСТИРОВАТЬ даже если это простой wrapper
suspend fun getData() = api.getData()

// Причины:
// 1. Проверка правильности вызова API
// 2. Проверка обработки ошибок
// 3. Проверка маппинга (если есть)
// 4. Документация контракта
```

### ✅ Use FlowTestUtils for Flow Methods

```kotlin
// ✅ ВСЕГДА для методов возвращающих Flow
FlowTestUtils.coVerifyFlowCall {
    repository.getDataFlow()
}

// ❌ НЕ использовать coVerify (утечки памяти!)
coVerify { repository.getDataFlow() }
```

### ✅ Test Error Scenarios

Для каждого Repository метода тестируй:
- ✅ Happy path (success)
- ✅ API error (network exception)
- ✅ Null response (if applicable)
- ✅ Empty data (if applicable)

---

## Quick Checklist for Repository Tests

- [ ] Test wrapper methods (validate API calls)
- [ ] Test Flow methods with Turbine
- [ ] Use FlowTestUtils.coVerifyFlowCall for Flow
- [ ] Test error scenarios (exceptions)
- [ ] Test cache logic (if applicable)
- [ ] Test mapping logic (mockkStatic if needed)
- [ ] Cleanup in tearDown (FlowTestUtils.cleanupFlowResources)

---

## Size

**~1000 tokens** - Repository-specific patterns
