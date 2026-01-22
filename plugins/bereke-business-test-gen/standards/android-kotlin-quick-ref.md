# Android/Kotlin Test Standards - Quick Reference

**One-pager для быстрого доступа к самым важным правилам.**

## ✅ ОБЯЗАТЕЛЬНО

### Структура теста
```kotlin
@ExperimentalCoroutinesApi
class {Class}Test {
    private val mock{Dep}: {Type} = mockk(relaxed = true)
    private lateinit var {classUnderTest}: {Class}

    @BeforeEach
    fun setUp() { {classUnderTest} = {Class}(mock{Dep}) }

    @AfterEach
    fun tearDown() {
        unmockkAll()
        clearAllMocks()
        FlowTestUtils.cleanupFlowResources()
    }

    @DisplayName("When X - Then Y")  // NO backticks!
    @Test
    fun methodName_condition_result() = runTest {
        // Given
        // When
        // Then
    }
}
```

### Assertions
```kotlin
✅ assertThat(value).isTrue()          // Truth
✅ assertThat(value).isEqualTo(expected)
✅ coEvery { mock.getData() } returns data  // suspend
❌ assertEquals(expected, actual)      // JUnit - FORBIDDEN
❌ assertTrue(value)                   // JUnit - FORBIDDEN
```

### Flow & Coroutines
```kotlin
✅ FlowTestUtils.coVerifyFlowCall { mock.getFlow() }
✅ FlowTestUtils.cleanupFlowResources() // in tearDown
✅ runTest { ... }
❌ coVerify { mock.getFlow() }         // FORBIDDEN for Flow
❌ Thread.sleep()                      // FORBIDDEN
```

### Turbine для Flow<T> и Flow<PagingData<T>>
```kotlin
import app.cash.turbine.test

// Flow<DataState>
flow.test {
    assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)
    val success = awaitItem()
    assertThat(success).isInstanceOf(DataState.Success::class.java)
    cancelAndIgnoreRemainingEvents()
}

// Flow<PagingData<T>>
repository.getPaginatedData(query).test {
    val pagingData = awaitItem()
    assertThat(pagingData).isNotNull()
    cancelAndIgnoreRemainingEvents()
}
```

## ❌ ЗАПРЕЩЕНО

| ❌ Wrong | ✅ Correct |
|---------|-----------|
| `fun \`when x then y\`` | `fun whenX_thenY()` + @DisplayName |
| No @DisplayName | @DisplayName("When X - Then Y") |
| `mockRepository` (no prefix) | `mockRepository` (with prefix) |
| assertEquals(...) | assertThat(...).isEqualTo(...) |
| assertTrue/assertFalse | assertThat(...).isTrue/isFalse |
| `coVerify { flowCall() }` | `FlowTestUtils.coVerifyFlowCall { }` |
| No tearDown cleanup | Full tearDown with cleanupFlowResources |
| Any unused imports | Clean imports only |

## 📦 Package Structure

```
Source: src/main/java/kz/berekebank.../data/repositories/PushRepository.kt
Test:   src/test/kotlin/kz.berekebank.../data/repositories/PushRepositoryTest.kt

✅ SAME package (only src/main → src/test changes)
❌ DIFFERENT package = ERROR
```

## 🎯 Test Coverage & Scenarios

For every **PUBLIC** method in Repository/UseCase/Interactor:

**Minimum scenarios**:
- ✅ Happy Path (success scenario)
- ✅ Error Case (API/network error)
- ✅ Edge Cases (auto-detect from parameters)

**Auto edge case detection**:
```
String? param → null, empty, blank
Int param → negative, zero, max
List<T> param → empty, single, multiple
Boolean param → true, false
```

**Example**:
```kotlin
fun processUser(name: String?, age: Int): Result<User>

Required tests:
✅ processUser_validInput_success()           // happy
✅ processUser_apiError_returnsError()        // error
✅ processUser_nameNull_returnsError()        // edge
✅ processUser_nameEmpty_returnsError()       // edge
✅ processUser_ageNegative_returnsError()     // edge
✅ processUser_ageZero_validCase()            // edge
```

**Coverage targets**:
- ✅ Test ALL wrapper methods (suspend fun getData() = api.getData())
- ✅ Test ALL Flow methods (use Turbine)
- ✅ Test ALL Flow<PagingData> methods (use Turbine)
- ❌ Don't test private methods directly
- ❌ Skip ONLY void methods without side effects

## 🔍 Quick Checklist

**Structure**:
- [ ] @DisplayName (no backticks)
- [ ] Given-When-Then comments
- [ ] Truth assertions only
- [ ] mock* prefix for all mocks
- [ ] FlowTestUtils.coVerifyFlowCall for Flow (NOT coVerify!)
- [ ] Full tearDown with FlowTestUtils.cleanupFlowResources()
- [ ] Package matches source class

**Scenarios**:
- [ ] Happy path test for each method
- [ ] Error case test for each method
- [ ] Edge cases for nullable/collection parameters

**Quality**:
- [ ] Min 3 assertions per test
- [ ] coVerify/verify for mock calls
- [ ] FlowTestUtils for ALL Flow methods (CRITICAL!)

**Validation**:
- [ ] Compiles: `./gradlew :module:compileDebugUnitTestKotlin`
- [ ] Tests pass: `./gradlew :module:testDebugUnitTest`
- [ ] Coverage: ≥80% LINE
- [ ] Quality score: ≥3.0/4.0

## 📚 Full Guide

For detailed examples: read `android-kotlin.md`

## 💡 Pro Tips

1. Use `mockk(relaxed = true)` for simple mocks
2. Use `runTest { }` for all coroutine tests
3. Name test methods: `method_condition_result()`
4. Put related tests in one class max 10-15 tests
5. Use example tests in codebase as reference
