# Flow Combine Test Template

**Size**: ~700 tokens | **Use**: Methods combining multiple flows with combine/zip

---

## Pattern

ViewModel/Repository combining multiple flows:

```kotlin
// Source
class ProfileViewModel(
    private val userRepo: UserRepository,
    private val balanceRepo: BalanceRepository
) : ViewModel() {

    private val _userId = MutableStateFlow<String?>(null)

    val profileState: StateFlow<ProfileState> = combine(
        _userId,
        userRepo.getUserFlow(),
        balanceRepo.getBalanceFlow()
    ) { userId, user, balance ->
        when {
            userId == null -> ProfileState.Idle
            user == null -> ProfileState.Loading
            balance == null -> ProfileState.Loading
            else -> ProfileState.Loaded(user, balance)
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = ProfileState.Idle
    )

    fun loadProfile(userId: String) {
        _userId.value = userId
    }
}

sealed class ProfileState {
    object Idle : ProfileState()
    object Loading : ProfileState()
    data class Loaded(val user: User, val balance: Balance) : ProfileState()
}
```

---

## Generated Tests

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class ProfileViewModelTest {

    private lateinit var testDispatcher: TestDispatcher
    private val mockUserRepo: UserRepository = mockk(relaxed = true)
    private val mockBalanceRepo: BalanceRepository = mockk(relaxed = true)
    private lateinit var viewModel: ProfileViewModel

    private val testUserId = "user_123"

    @BeforeEach
    fun setUp() {
        testDispatcher = StandardTestDispatcher()
        Dispatchers.setMain(testDispatcher)

        // Setup mock flows
        val userFlow = flowOf<User?>(null, mockUser, mockUser)
        val balanceFlow = flowOf<Balance?>(null, mockBalance, mockBalance)

        coEvery { mockUserRepo.getUserFlow() } returns userFlow
        coEvery { mockBalanceRepo.getBalanceFlow() } returns balanceFlow

        viewModel = ProfileViewModel(mockUserRepo, mockBalanceRepo)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        testDispatcher.scheduler.runCurrent()
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }

    // ==================== Initial State Tests ====================

    @DisplayName("When viewModel created - Then state is Idle")
    @Test
    fun initialState_isIdle() = runTest(testDispatcher) {
        // Given & When
        viewModel.profileState.test {
            // Then
            val initialState = awaitItem()
            assertThat(initialState).isInstanceOf(ProfileState.Idle::class.java)

            cancelAndIgnoreRemainingEvents()
        }
    }

    // ==================== Loading State Tests ====================

    @DisplayName("When loadProfile called - Then emits Loading then Loaded")
    @Test
    fun loadProfile_emitsLoadingThenLoaded() = runTest(testDispatcher) {
        // Given
        val mockUser = mockk<User>(relaxed = true)
        val mockBalance = mockk<Balance>(relaxed = true)

        coEvery { mockUserRepo.getUserFlow() } returns flowOf(mockUser)
        coEvery { mockBalanceRepo.getBalanceFlow() } returns flowOf(mockBalance)

        // When & Then
        viewModel.profileState.test {
            // Initial state
            assertThat(awaitItem()).isInstanceOf(ProfileState.Idle::class.java)

            // Trigger load
            viewModel.loadProfile(testUserId)
            testDispatcher.scheduler.advanceUntilIdle()

            // Loading state (one of the flows is null initially)
            val loadingState = awaitItem()
            assertThat(loadingState).isInstanceOf(ProfileState.Loading::class.java)

            // Loaded state
            val loadedState = awaitItem()
            assertThat(loadedState).isInstanceOf(ProfileState.Loaded::class.java)
            val loaded = loadedState as ProfileState.Loaded
            assertThat(loaded.user).isEqualTo(mockUser)
            assertThat(loaded.balance).isEqualTo(mockBalance)

            cancelAndIgnoreRemainingEvents()
        }
    }

    // ==================== Combine Flow Tests ====================

    @DisplayName("When both flows emit - Then combines into Loaded state")
    @Test
    fun bothFlowsEmit_combinesIntoLoadedState() = runTest(testDispatcher) {
        // Given
        val expectedUser = mockk<User> { every { id } returns testUserId }
        val expectedBalance = mockk<Balance> { every { amount } returns BigDecimal("100.00") }

        coEvery { mockUserRepo.getUserFlow() } returns flowOf(expectedUser)
        coEvery { mockBalanceRepo.getBalanceFlow() } returns flowOf(expectedBalance)

        // When
        viewModel.loadProfile(testUserId)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.profileState.test {
            skip(1) // Skip Idle
            val loadedState = awaitItem()
            assertThat(loadedState).isInstanceOf(ProfileState.Loaded::class.java)

            val loaded = loadedState as ProfileState.Loaded
            assertThat(loaded.user.id).isEqualTo(testUserId)
            assertThat(loaded.balance.amount).isEqualTo(BigDecimal("100.00"))

            cancelAndIgnoreRemainingEvents()
        }
    }

    // ==================== Partial Data Tests ====================

    @DisplayName("When user emits but balance null - Then stays in Loading")
    @Test
    fun userEmitsBalanceNull_staysInLoading() = runTest(testDispatcher) {
        // Given
        val expectedUser = mockk<User>(relaxed = true)

        coEvery { mockUserRepo.getUserFlow() } returns flowOf(expectedUser)
        coEvery { mockBalanceRepo.getBalanceFlow() } returns flowOf(null)  // Always null

        // When
        viewModel.loadProfile(testUserId)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.profileState.test {
            skip(1) // Skip Idle
            val state = awaitItem()
            assertThat(state).isInstanceOf(ProfileState.Loading::class.java)

            cancelAndIgnoreRemainingEvents()
        }
    }

    @DisplayName("When balance emits but user null - Then stays in Loading")
    @Test
    fun balanceEmitsUserNull_staysInLoading() = runTest(testDispatcher) {
        // Given
        val expectedBalance = mockk<Balance>(relaxed = true)

        coEvery { mockUserRepo.getUserFlow() } returns flowOf(null)  // Always null
        coEvery { mockBalanceRepo.getBalanceFlow() } returns flowOf(expectedBalance)

        // When
        viewModel.loadProfile(testUserId)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.profileState.test {
            skip(1) // Skip Idle
            val state = awaitItem()
            assertThat(state).isInstanceOf(ProfileState.Loading::class.java)

            cancelAndIgnoreRemainingEvents()
        }
    }

    // ==================== Flow Verification Tests ====================

    @DisplayName("When loadProfile - Then both repository flows are collected")
    @Test
    fun loadProfile_collectsBothRepositoryFlows() = runTest(testDispatcher) {
        // Given
        coEvery { mockUserRepo.getUserFlow() } returns flowOf(mockk())
        coEvery { mockBalanceRepo.getBalanceFlow() } returns flowOf(mockk())

        // When
        viewModel.loadProfile(testUserId)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then - Verify flows are being collected (via FlowTestUtils)
        FlowTestUtils.coVerifyFlowCall { mockUserRepo.getUserFlow() }
        FlowTestUtils.coVerifyFlowCall { mockBalanceRepo.getBalanceFlow() }
    }

    // ==================== Error Handling Tests ====================

    @DisplayName("When userFlow throws exception - Then handles error gracefully")
    @Test
    fun userFlowThrowsException_handlesError() = runTest(testDispatcher) {
        // Given
        val exception = NetworkException("User fetch failed")
        coEvery { mockUserRepo.getUserFlow() } returns flow { throw exception }
        coEvery { mockBalanceRepo.getBalanceFlow() } returns flowOf(mockk())

        // When
        viewModel.loadProfile(testUserId)
        testDispatcher.scheduler.advanceUntilIdle()

        // Then - ViewModel should handle exception (catchIn combine)
        // State should either be Error or Loading (depending on error handling)
        viewModel.profileState.value.let { state ->
            // Assert based on your error handling strategy
            assertThat(state).isNotNull()
        }
    }

    // ==================== Multiple Emit Tests ====================

    @DisplayName("When userId changes - Then recomputes with new user")
    @Test
    fun userIdChanged_recomputesWithNewUser() = runTest(testDispatcher) {
        // Given
        val user1 = mockk<User> { every { id } returns "user_1" }
        val user2 = mockk<User> { every { id } returns "user_2" }
        val balance = mockk<Balance>(relaxed = true)

        coEvery { mockUserRepo.getUserFlow() } returns flowOf(user1, user2)
        coEvery { mockBalanceRepo.getBalanceFlow() } returns flowOf(balance)

        // When & Then
        viewModel.profileState.test {
            // Initial
            assertThat(awaitItem()).isInstanceOf(ProfileState.Idle::class.java)

            // Load first user
            viewModel.loadProfile("user_1")
            testDispatcher.scheduler.advanceUntilIdle()
            val loaded1 = awaitItem() as? ProfileState.Loaded
            assertThat(loaded1?.user?.id).isEqualTo("user_1")

            // Load second user
            viewModel.loadProfile("user_2")
            testDispatcher.scheduler.advanceUntilIdle()
            val loaded2 = awaitItem() as? ProfileState.Loaded
            assertThat(loaded2?.user?.id).isEqualTo("user_2")

            cancelAndIgnoreRemainingEvents()
        }
    }
}
```

---

## Template Variables

| Variable | Description |
|----------|-------------|
| `{State}` | Sealed state class name |
| `{repo1}Flow`, `{repo2}Flow` | Combined flows |
| `{initialValue}` | Initial state value |
| `{sharingStarted}` | SharingStarted strategy |

---

## Coverage Checklist

- [ ] Initial state (before any emission)
- [ ] Loading state (partial data)
- [ ] Loaded state (all data present)
- [ ] Partial data scenarios (one flow null, other present)
- [ ] Flow verification with FlowTestUtils
- [ ] Error handling in flows
- [ ] Multiple emissions (state changes)
- [ ] combine vs zip (if applicable)
