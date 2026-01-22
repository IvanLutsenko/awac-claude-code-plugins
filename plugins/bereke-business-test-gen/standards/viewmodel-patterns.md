# ViewModel Test Patterns

**Цель**: Специфичные паттерны для тестирования ViewModel слоя

---

## ViewModel Role

ViewModel содержит UI логику:
- Intent handling (user actions)
- State management (StateFlow)
- Координация UseCase/Interactor
- Navigation
- Error handling для UI

---

## Standard ViewModel Test Structure

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class AuthViewModelTest {

    private lateinit var testDispatcher: TestDispatcher
    private val mockInteractor: AuthInteractor = mockk(relaxed = true)
    private val mockNavigator: NavigationController = mockk()
    private lateinit var viewModel: AuthViewModel

    @BeforeEach
    fun setUp() {
        testDispatcher = StandardTestDispatcher()
        Dispatchers.setMain(testDispatcher)

        viewModel = AuthViewModel(mockInteractor, mockNavigator)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        testDispatcher.scheduler.runCurrent()
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }
}
```

---

## Pattern 1: StateFlow Testing

**Use**: Для проверки изменений UI state

```kotlin
// Source
class ProfileViewModel(private val interactor: ProfileInteractor) : ViewModel() {

    private val _state = MutableStateFlow(ProfileState())
    val state: StateFlow<ProfileState> = _state.asStateFlow()

    fun loadProfile(userId: String) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true)

            when (val result = interactor.getProfile(userId)) {
                is RequestResult.Success -> {
                    _state.value = ProfileState(
                        isLoading = false,
                        profile = result.data
                    )
                }
                is RequestResult.Error -> {
                    _state.value = ProfileState(
                        isLoading = false,
                        error = result.error
                    )
                }
            }
        }
    }
}

// Test
@DisplayName("When loadProfile success - Then state updates correctly")
@Test
fun loadProfile_success_updatesState() = runTest(testDispatcher) {
    // Given
    val userId = "123"
    val expectedProfile = mockk<Profile>()
    coEvery {
        mockInteractor.getProfile(userId)
    } returns RequestResult.Success(expectedProfile)

    // When & Then
    viewModel.state.test {
        // Initial state
        val initial = awaitItem()
        assertThat(initial.isLoading).isFalse()
        assertThat(initial.profile).isNull()

        // Trigger load
        viewModel.loadProfile(userId)
        testDispatcher.scheduler.advanceUntilIdle()

        // Loading state
        val loading = awaitItem()
        assertThat(loading.isLoading).isTrue()

        // Success state
        val success = awaitItem()
        assertThat(success.isLoading).isFalse()
        assertThat(success.profile).isEqualTo(expectedProfile)
        assertThat(success.error).isNull()

        cancelAndIgnoreRemainingEvents()
    }

    coVerify { mockInteractor.getProfile(userId) }
}
```

---

## Pattern 2: Intent Handling

**Use**: Для проверки обработки user actions/intents

```kotlin
// Source
sealed class AuthIntent {
    data class Login(val username: String, val password: String) : AuthIntent()
    object Logout : AuthIntent()
}

class AuthViewModel(...) : ViewModel() {
    fun handleIntent(intent: AuthIntent) {
        when (intent) {
            is AuthIntent.Login -> handleLogin(intent.username, intent.password)
            AuthIntent.Logout -> handleLogout()
        }
    }

    private fun handleLogin(username: String, password: String) {
        // Login logic
    }
}

// Test
@DisplayName("When handleIntent Login - Then login is triggered")
@Test
fun handleIntent_login_triggersLogin() = runTest(testDispatcher) {
    // Given
    val username = "user"
    val password = "pass"
    val mockUser = mockk<User>()
    coEvery {
        mockInteractor.login(username, password)
    } returns RequestResult.Success(mockUser)

    // When
    viewModel.handleIntent(AuthIntent.Login(username, password))
    testDispatcher.scheduler.advanceUntilIdle()

    // Then
    coVerify { mockInteractor.login(username, password) }

    // Check state
    viewModel.state.value.let { state ->
        assertThat(state.isAuthenticated).isTrue()
        assertThat(state.user).isEqualTo(mockUser)
    }
}
```

---

## Pattern 3: Navigation Testing

**Use**: Для проверки navigation calls

```kotlin
// Source
class OnboardingViewModel(
    private val navigator: NavigationController
) : ViewModel() {

    fun complete() {
        navigator.navigate(Route.Home)
    }
}

// Test
@DisplayName("When complete - Then navigates to Home")
@Test
fun complete_navigatesToHome() = runTest(testDispatcher) {
    // Given
    every { mockNavigator.navigate(any()) } just runs

    // When
    viewModel.complete()
    testDispatcher.scheduler.advanceUntilIdle()

    // Then
    verify { mockNavigator.navigate(Route.Home) }
}
```

---

## Pattern 4: SharedFlow Events (One-Time Events)

**Use**: Для UI events типа "show toast", "show error dialog"

```kotlin
// Source
class PaymentViewModel(...) : ViewModel() {

    private val _events = MutableSharedFlow<PaymentEvent>()
    val events: SharedFlow<PaymentEvent> = _events.asSharedFlow()

    suspend fun processPayment(amount: BigDecimal) {
        when (val result = interactor.processPayment(amount)) {
            is RequestResult.Success -> {
                _events.emit(PaymentEvent.Success)
            }
            is RequestResult.Error -> {
                _events.emit(PaymentEvent.Error(result.error))
            }
        }
    }
}

// Test
@DisplayName("When processPayment success - Then emits Success event")
@Test
fun processPayment_success_emitsSuccessEvent() = runTest(testDispatcher) {
    // Given
    val amount = BigDecimal("100.00")
    coEvery {
        mockInteractor.processPayment(amount)
    } returns RequestResult.Success(Unit)

    // When & Then
    viewModel.events.test {
        // No initial events
        expectNoEvents()

        // Trigger payment
        viewModel.processPayment(amount)
        testDispatcher.scheduler.advanceUntilIdle()

        // Success event
        val event = awaitItem()
        assertThat(event).isInstanceOf(PaymentEvent.Success::class.java)

        cancelAndIgnoreRemainingEvents()
    }

    coVerify { mockInteractor.processPayment(amount) }
}
```

---

## Pattern 5: BaseTest for Complex ViewModels

**Use**: Когда ViewModel имеет >5 методов, создай BaseTest + разделенные тесты

```kotlin
// BaseTest
@OptIn(ExperimentalCoroutinesApi::class)
abstract class AuthViewModelBaseTest {

    protected lateinit var testDispatcher: TestDispatcher
    protected val mockAuthInteractor: AuthInteractor = mockk(relaxed = true)
    protected val mockBiometricHelper: BiometricHelper = mockk()
    protected val mockNavigator: NavigationController = mockk()
    protected lateinit var viewModel: AuthViewModel

    @BeforeEach
    fun setUp() {
        testDispatcher = StandardTestDispatcher()
        Dispatchers.setMain(testDispatcher)

        viewModel = AuthViewModel(
            authInteractor = mockAuthInteractor,
            biometricHelper = mockBiometricHelper,
            navigator = mockNavigator
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        testDispatcher.scheduler.runCurrent()
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }

    // Helper methods
    protected fun advanceTime() {
        testDispatcher.scheduler.advanceUntilIdle()
    }
}

// Specialized test files
class AuthViewModelLoginTest : AuthViewModelBaseTest() {

    @DisplayName("When login success - Then navigates to Home")
    @Test
    fun login_success_navigatesToHome() = runTest(testDispatcher) {
        // Test login scenarios
    }
}

class AuthViewModelBiometricTest : AuthViewModelBaseTest() {

    @DisplayName("When biometric auth - Then authenticates")
    @Test
    fun biometric_success() = runTest(testDispatcher) {
        // Test biometric scenarios
    }
}
```

---

## Common ViewModel Scenarios

### Loading State

```kotlin
@Test
fun loadData_showsLoading() = runTest(testDispatcher) {
    viewModel.state.test {
        viewModel.loadData()

        val loading = awaitItem()
        assertThat(loading.isLoading).isTrue()

        advanceUntilIdle()
        val loaded = awaitItem()
        assertThat(loaded.isLoading).isFalse()

        cancelAndIgnoreRemainingEvents()
    }
}
```

### Error Handling

```kotlin
@Test
fun loadData_error_showsError() = runTest(testDispatcher) {
    // Given
    val exception = NetworkException("Error")
    coEvery { mockInteractor.getData() } throws exception

    // When
    viewModel.loadData()
    advanceUntilIdle()

    // Then
    viewModel.state.value.let { state ->
        assertThat(state.error).isNotNull()
        assertThat(state.error?.message).contains("Error")
    }
}
```

### Validation

```kotlin
@Test
fun submit_invalidInput_showsValidationError() = runTest(testDispatcher) {
    // Given
    val invalidEmail = "not-an-email"

    // When
    viewModel.submit(invalidEmail)
    advanceUntilIdle()

    // Then
    viewModel.state.value.let { state ->
        assertThat(state.validationError).isNotNull()
    }

    // Interactor not called
    coVerify(exactly = 0) { mockInteractor.submit(any()) }
}
```

---

## Important Notes

### ✅ Use TestDispatcher

```kotlin
@BeforeEach
fun setUp() {
    testDispatcher = StandardTestDispatcher()
    Dispatchers.setMain(testDispatcher)  // ← ВАЖНО
}

@AfterEach
fun tearDown() {
    Dispatchers.resetMain()  // ← ВАЖНО
}
```

### ✅ advanceUntilIdle for Coroutines

```kotlin
// ✅ ПРАВИЛЬНО
viewModel.loadData()
testDispatcher.scheduler.advanceUntilIdle()  // Ждем корутины

// ❌ НЕПРАВИЛЬНО (без advance - корутины не завершатся)
viewModel.loadData()
// Сразу проверка - FAIL!
```

### ✅ Test StateFlow with Turbine

```kotlin
viewModel.state.test {
    val initial = awaitItem()
    // Trigger action
    viewModel.doSomething()
    advanceUntilIdle()

    val updated = awaitItem()
    assertThat(updated).isNotNull()

    cancelAndIgnoreRemainingEvents()
}
```

### ✅ Cleanup Flow Resources

```kotlin
@AfterEach
fun tearDown() {
    Dispatchers.resetMain()
    unmockkAll()
    clearAllMocks()
    FlowTestUtils.cleanupFlowResources()  // ← ОБЯЗАТЕЛЬНО
}
```

---

## Quick Checklist for ViewModel Tests

- [ ] Set up TestDispatcher (StandardTestDispatcher)
- [ ] Set Dispatchers.setMain() in setUp
- [ ] Reset Dispatchers.resetMain() in tearDown
- [ ] Use advanceUntilIdle() after triggering actions
- [ ] Test StateFlow with Turbine
- [ ] Test SharedFlow events
- [ ] Test navigation calls (verify)
- [ ] Test loading/error states
- [ ] Test validation logic
- [ ] Cleanup Flow resources in tearDown
- [ ] Use BaseTest for complex ViewModels (>5 methods)

---

## Size

**~1500 tokens** - ViewModel-specific patterns
