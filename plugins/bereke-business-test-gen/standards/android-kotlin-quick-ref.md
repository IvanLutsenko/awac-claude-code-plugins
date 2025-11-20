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

## 🎯 Test Coverage

For every **PUBLIC** method:
- ✅ Min 1 Happy Path test
- ✅ Min 1 Error Case test
- ❌ Don't test private methods directly

## 🔍 Quick Checklist

- [ ] @DisplayName (no backticks)
- [ ] Given-When-Then comments
- [ ] Truth assertions only
- [ ] mock* prefix for all mocks
- [ ] FlowTestUtils for Flow
- [ ] Full tearDown with cleanup
- [ ] Package matches source class
- [ ] Compiles: `./gradlew :module:compileDebugUnitTestKotlin`
- [ ] Tests pass: `./gradlew :module:testDebugUnitTest`
- [ ] Coverage OK: `./gradlew :module:koverVerify`

## 📚 Full Guide

For detailed examples: read `android-kotlin.md`

## 💡 Pro Tips

1. Use `mockk(relaxed = true)` for simple mocks
2. Use `runTest { }` for all coroutine tests
3. Name test methods: `method_condition_result()`
4. Put related tests in one class max 10-15 tests
5. Use example tests in codebase as reference
