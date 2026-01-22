# Ultra-Compact Test Standards

**Size**: ~200 tokens | **Use**: Quick reference, template matching, quality checks

---

## Structure

```kotlin
@Test
@DisplayName("When {action} - Then {expected}")
fun {methodName}_{scenario}() = runTest {
    // Given
    val input = mockValue()
    coEvery { mockDep.method() } returns expected

    // When
    val result = classUnderTest.methodName(input)

    // Then
    assertThat(result).isNotNull()
    assertThat(result.field).isEqualTo(expected)
    coVerify { mockDep.method() }
}
```

## Assertions (Truth)

```kotlin
assertThat(actual).isEqualTo(expected)
assertThat(actual).isNotNull()
assertThat(actual).isInstanceOf(ExpectedType::class.java)
assertThat(list).hasSize(2)
assertThat(actual).isTrue() / isFalse()
```

## MockK

```kotlin
private val mockApi: Api = mockk(relaxed = true)

coEvery { mockApi.suspendMethod() } returns value
coEvery { mockApi.suspendMethod() } throws exception
verify { mockApi.method() }
coVerify(exactly = 1) { mockApi.suspendMethod() }
coVerify(exactly = 0) { mockApi.method() }

@BeforeEach
fun setUp() { /* init mocks */ }

@AfterEach
fun tearDown() {
    unmockkAll()
    clearAllMocks()
}
```

## Flow Testing (CRITICAL!)

```kotlin
// ✅ CORRECT for Flow methods
repository.getDataFlow().test {
    val item = awaitItem()
    assertThat(item).isNotNull()
    cancelAndIgnoreRemainingEvents()
}
FlowTestUtils.coVerifyFlowCall { repository.getDataFlow() }

// ❌ WRONG - Memory leak!
coVerify { repository.getDataFlow() }
```

## TestDispatcher (ViewModel)

```kotlin
private lateinit var testDispatcher: TestDispatcher

@BeforeEach
fun setUp() {
    testDispatcher = StandardTestDispatcher()
    Dispatchers.setMain(testDispatcher)
}

@AfterEach
fun tearDown() {
    Dispatchers.resetMain()
    FlowTestUtils.cleanupFlowResources()
}
```

## Scenarios

For each method:
- ✅ Happy path (success)
- ✅ Error case (exception/null)
- ✅ Edge cases (null/empty/negative for params)

## Naming

```
{methodName}_{scenario}_expectedResult()
Examples:
- login_validCredentials_returnsSuccess
- login_invalidCredentials_returnsError
- getData_emptyList_returnsEmpty
```

## Quality Checklist

- [ ] @DisplayName (no backticks)
- [ ] Given-When-Then comments
- [ ] Min 3 assertions per test
- [ ] coVerify for suspend methods
- [ ] FlowTestUtils.coVerifyFlowCall for Flow
- [ ] tearDown cleanup
