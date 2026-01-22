# Wrapper Method Test Template

**Use for**: Simple wrapper methods that delegate to a single dependency

**Pattern**: `suspend fun method() = dependency.method()`

---

## Template Code

```kotlin
@DisplayName("When {methodName} called - Then returns result from {dependencyName}")
@Test
fun {methodName}_success() = runTest {
    // Given
    val expected{ReturnType} = mockk<{ReturnType}>(relaxed = true)
    coEvery {
        mock{DependencyName}.{dependencyMethod}({params})
    } returns expected{ReturnType}

    // When
    val result = {classUnderTest}.{methodName}({params})

    // Then
    assertThat(result).isNotNull()
    assertThat(result).isEqualTo(expected{ReturnType})
    coVerify(exactly = 1) {
        mock{DependencyName}.{dependencyMethod}({params})
    }
}

@DisplayName("When {methodName} called and error occurs - Then error is returned")
@Test
fun {methodName}_error() = runTest {
    // Given
    val exception = RuntimeException("Test error")
    coEvery {
        mock{DependencyName}.{dependencyMethod}({params})
    } throws exception

    // When
    val result = {classUnderTest}.{methodName}({params})

    // Then
    assertThat(result).isInstanceOf(RequestResult.Error::class.java)
    coVerify(exactly = 1) {
        mock{DependencyName}.{dependencyMethod}({params})
    }
}
```

---

## Variables to Replace

- `{methodName}` - Name of method under test (e.g., "getData")
- `{dependencyName}` - Capitalized dependency name (e.g., "Api")
- `{DependencyName}` - Capitalized dependency class name (e.g., "DataApi")
- `{dependencyMethod}` - Method called on dependency (e.g., "getData")
- `{classUnderTest}` - Instance name (e.g., "repository")
- `{ReturnType}` - Return type (e.g., "Data", "User")
- `{params}` - Parameters passed (e.g., "userId" or empty)

---

## Example: Applied Template

**Source Method**:
```kotlin
class AuthRepository(private val api: AuthApi) {
    suspend fun getUser(userId: String): RequestResult<User> {
        return api.getUser(userId)
    }
}
```

**Generated Test**:
```kotlin
@DisplayName("When getUser called - Then returns result from Api")
@Test
fun getUser_success() = runTest {
    // Given
    val expectedUser = mockk<User>(relaxed = true)
    coEvery {
        mockApi.getUser("123")
    } returns RequestResult.Success(expectedUser)

    // When
    val result = repository.getUser("123")

    // Then
    assertThat(result).isNotNull()
    assertThat(result).isInstanceOf(RequestResult.Success::class.java)
    coVerify(exactly = 1) {
        mockApi.getUser("123")
    }
}

@DisplayName("When getUser called and error occurs - Then error is returned")
@Test
fun getUser_error() = runTest {
    // Given
    val exception = RuntimeException("Network error")
    coEvery {
        mockApi.getUser("123")
    } throws exception

    // When
    val result = repository.getUser("123")

    // Then
    assertThat(result).isInstanceOf(RequestResult.Error::class.java)
    coVerify(exactly = 1) {
        mockApi.getUser("123")
    }
}
```

---

## Size Estimate

- **Lines**: ~50-60 lines (2 tests)
- **Tokens**: ~500-600 tokens
- **Savings vs full generation**: 8000 tokens → 600 tokens (92% reduction)

---

## When to Use

✅ Use this template when:
- Method is `suspend fun`
- Method body is 1 line
- Method calls single dependency method
- No data transformation
- No if/when/try-catch

❌ Don't use template when:
- Method has business logic
- Method coordinates multiple dependencies
- Method transforms data
- Method is Flow-based

---

## Notes

- Template includes both happy path and error case
- Uses `mockk(relaxed = true)` for simplicity
- Follows corporate standards (Given-When-Then, Truth assertions, FlowTestUtils)
- Max 80 characters per line (detekt compliance)
