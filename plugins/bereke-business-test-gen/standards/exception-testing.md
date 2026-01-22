# Exception Path Testing

**Size**: ~800 tokens | **Use**: Testing try-catch blocks, error paths, exception handling

---

## Goal

Ensure **ALL exception paths** are tested, not just happy path.

---

## Pattern 1: Simple Try-Catch

```kotlin
// Source
fun fetchData(id: String): Result<Data> {
    return try {
        val response = api.call(id)
        Result.Success(response)
    } catch (e: IOException) {
        Result.Failure(NetworkError)
    }
}

// Tests
@Test
fun fetchData_success_returnsData() = runTest {
    coEvery { mockApi.call("123") } returns mockData
    val result = repository.fetchData("123")
    assertThat(result).isInstanceOf(Result.Success::class.java)
}

@Test
fun fetchData_ioException_returnsNetworkError() = runTest {
    coEvery { mockApi.call("123") } throws IOException("Connection failed")
    val result = repository.fetchData("123")
    assertThat(result).isInstanceOf(Result.Failure::class.java)
    assertThat((result as Result.Failure).error).isInstanceOf(NetworkError::class.java)
}
```

---

## Pattern 2: Multiple Catch Blocks

```kotlin
// Source
fun processPayment(amount: BigDecimal): Result<Payment> {
    return try {
        val payment = bank.process(amount)
        Result.Success(payment)
    } catch (e: InsufficientFundsException) {
        Result.Failure(InsufficientFundsError)
    } catch (e: InvalidCardException) {
        Result.Failure(InvalidCardError)
    } catch (e: NetworkException) {
        Result.Failure(NetworkError)
    } catch (e: Exception) {
        Result.Failure(UnknownError(e.message))
    }
}

// Tests - ONE TEST PER CATCH BLOCK
@Test
fun processPayment_success() = runTest {
    coEvery { mockBank.process(any()) } returns mockPayment
    val result = paymentProcessor.processPayment(BigDecimal("100"))
    assertThat(result).isInstanceOf(Result.Success::class.java)
}

@Test
fun processPayment_insufficientFunds_returnsError() = runTest {
    coEvery { mockBank.process(any()) } throws InsufficientFundsException()
    val result = paymentProcessor.processPayment(BigDecimal("100"))
    assertThat(result).isInstanceOf(Result.Failure::class.java)
    assertThat((result as Result.Failure).error).isInstanceOf(InsufficientFundsError::class.java)
}

@Test
fun processPayment_invalidCard_returnsError() = runTest {
    coEvery { mockBank.process(any()) } throws InvalidCardException()
    val result = paymentProcessor.processPayment(BigDecimal("100"))
    assertThat(result).isInstanceOf(Result.Failure::class.java)
    assertThat((result as Result.Failure).error).isInstanceOf(InvalidCardError::class.java)
}

@Test
fun processPayment_networkError_returnsError() = runTest {
    coEvery { mockBank.process(any()) } throws NetworkException()
    val result = paymentProcessor.processPayment(BigDecimal("100"))
    assertThat(result).isInstanceOf(Result.Failure::class.java)
    assertThat((result as Result.Failure).error).isInstanceOf(NetworkError::class.java)
}

@Test
fun processPayment_unknownException_returnsError() = runTest {
    coEvery { mockBank.process(any()) } throws RuntimeException("Unexpected")
    val result = paymentProcessor.processPayment(BigDecimal("100"))
    assertThat(result).isInstanceOf(Result.Failure::class.java)
    assertThat((result as Result.Failure).error).isInstanceOf(UnknownError::class.java)
}
```

---

## Pattern 3: Nested Try-Catch

```kotlin
// Source
fun saveUserData(user: User): Result<Unit> {
    return try {
        try {
            database.save(user)
            Result.Success(Unit)
        } catch (e: DatabaseException) {
            // Try cache fallback
            cache.save(user)
            Result.Success(Unit)
        }
    } catch (e: CacheException) {
        Result.Failure(StorageError(e.message))
    }
}

// Tests
@Test
fun saveUserData_databaseSuccess() = runTest {
    every { mockDatabase.save(any()) } just runs
    val result = storage.saveUserData(mockUser)
    assertThat(result).isInstanceOf(Result.Success::class.java)
}

@Test
fun saveUserData_databaseFailure_cacheFallback() = runTest {
    every { mockDatabase.save(any()) } throws DatabaseException()
    every { mockCache.save(any()) } just runs
    val result = storage.saveUserData(mockUser)
    assertThat(result).isInstanceOf(Result.Success::class.java)
    verify { mockCache.save(mockUser) }  // Fallback used
}

@Test
fun saveUserData_bothFail_returnsError() = runTest {
    every { mockDatabase.save(any()) } throws DatabaseException()
    every { mockCache.save(any()) } throws CacheException()
    val result = storage.saveUserData(mockUser)
    assertThat(result).isInstanceOf(Result.Failure::class.java)
}
```

---

## Pattern 4: Finally Block

```kotlin
// Source
fun processData(data: ByteArray): ProcessResult {
    val stream = ByteArrayInputStream(data)
    try {
        return parser.parse(stream)
    } catch (e: ParseException) {
        return ProcessResult.Error(e.message)
    } finally {
        stream.close()  // Always executed
    }
}

// Tests
@Test
fun processData_success_closesStream() = runTest {
    val mockStream = mockk<ByteArrayInputStream>(relaxed = true)
    every { mockParser.parse(any()) } returns ProcessResult.Success
    every { mockStream.close() } just runs

    val result = processor.processData(byteArrayOf(1, 2, 3))

    assertThat(result).isInstanceOf(ProcessResult.Success::class.java)
    verify { mockStream.close() }  // Verify finally block
}

@Test
fun processData_error_closesStream() = runTest {
    val mockStream = mockk<ByteArrayInputStream>(relaxed = true)
    every { mockParser.parse(any()) } throws ParseException("Parse error")
    every { mockStream.close() } just runs

    val result = processor.processData(byteArrayOf())

    assertThat(result).isInstanceOf(ProcessResult.Error::class.java)
    verify { mockStream.close() }  // Verify finally block even on error
}
```

---

## Pattern 5: Re-throw (Different Exception Type)

```kotlin
// Source
fun executeOperation(): OperationResult {
    try {
        api.execute()
        return OperationResult.Success
    } catch (e: ApiException) {
        throw DomainException("Operation failed", e)  // Wrapped
    }
}

// Tests
@Test
fun executeOperation_success() = runTest {
    coEvery { mockApi.execute() } just runs
    val result = operation.executeOperation()
    assertThat(result).isEqualTo(OperationResult.Success)
}

@Test
fun executeOperation_apiException_wrapsToDomainException() = runTest {
    coEvery { mockApi.execute() } throws ApiException("API Error")
    assertThrows<DomainException> {
        operation.executeOperation()
    }
}

@Test
fun executeOperation_wrappedExceptionHasCause() = runTest {
    val apiException = ApiException("API Error")
    coEvery { mockApi.execute() } throws apiException

    val exception = assertThrows<DomainException> {
        operation.executeOperation()
    }

    assertThat(exception.cause).isInstanceOf(ApiException::class.java)
    assertThat(exception.message).contains("Operation failed")
}
```

---

## Pattern 6: Suspend Function with Try-Catch

```kotlin
// Source
suspend fun fetchUser(id: String): User? {
    return try {
        val response = api.getUser(id)
        response.body()?.toModel()
    } catch (e: HttpException) {
        logger.error("HTTP error", e)
        null
    } catch (e: IOException) {
        logger.error("Network error", e)
        null
    }
}

// Tests
@Test
fun fetchUser_success_returnsUser() = runTest {
    val userDto = mockk<UserDto>()
    coEvery { mockApi.getUser("123") } returns Response.success(userDto)
    every { userDto.toModel() } returns mockUser

    val result = repository.fetchUser("123")

    assertThat(result).isEqualTo(mockUser)
}

@Test
fun fetchUser_httpException_returnsNull() = runTest {
    coEvery { mockApi.getUser("123") } throws HttpException(Response.error<Any>(404, mockResponseBody))

    val result = repository.fetchUser("123")

    assertThat(result).isNull()
    // Verify logging occurred
}

@Test
fun fetchUser_ioException_returnsNull() = runTest {
    coEvery { mockApi.getUser("123") } throws IOException("Network error")

    val result = repository.fetchUser("123")

    assertThat(result).isNull()
}
```

---

## Pattern 7: RunCatching / RunCatching Extension

```kotlin
// Source
fun parseJson(json: String): Config = runCatching {
    Json.decodeFromString<ConfigDto>(json).toConfig()
}.getOrElse { e ->
    Config.Default  // Fallback on any exception
}

// Tests
@Test
fun parseJson_validJson_returnsConfig() = runTest {
    val json = """{"key":"value"}"""
    val result = parser.parseJson(json)
    assertThat(result).isNotEqualTo(Config.Default)
}

@Test
fun parseJson_invalidJson_returnsDefault() = runTest {
    val json = "invalid json"
    val result = parser.parseJson(json)
    assertThat(result).isEqualTo(Config.Default)
}

@Test
fun parseJson_emptyString_returnsDefault() = runTest {
    val result = parser.parseJson("")
    assertThat(result).isEqualTo(Config.Default)
}

@Test
fun parseJson_throwsException_returnsDefault() = runTest {
    every { mockConfig.toConfig() } throws SerializationException("Error")
    val result = parser.parseJson("{}")
    assertThat(result).isEqualTo(Config.Default)
}
```

---

## Pattern 8: Flow with Exception Handling

```kotlin
// Source
fun getDataFlow(): Flow<DataState<Data>> = flow {
    emit(DataState.Loading)
    try {
        val data = api.fetchData()
        emit(DataState.Success(data))
    } catch (e: Exception) {
        emit(DataState.Error(e.message ?: "Unknown error"))
    }
}

// Tests
@Test
fun getDataFlow_success_emitsLoadingThenSuccess() = runTest {
    coEvery { mockApi.fetchData() } returns mockData

    repository.getDataFlow().test {
        assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)
        assertThat(awaitItem()).isInstanceOf(DataState.Success::class.java)
        cancelAndIgnoreRemainingEvents()
    }
}

@Test
fun getDataFlow_exception_emitsError() = runTest {
    coEvery { mockApi.fetchData() } throws RuntimeException("Error")

    repository.getDataFlow().test {
        assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)
        val error = awaitItem()
        assertThat(error).isInstanceOf(DataState.Error::class.java)
        assertThat((error as DataState.Error).message).contains("Error")
        cancelAndIgnoreRemainingEvents()
    }
}

@Test
fun getDataFlow_httpException_emitsHttpError() = runTest {
    coEvery { mockApi.fetchData() } throws HttpException(Response.error(404, mockResponseBody))

    repository.getDataFlow().test {
        assertThat(awaitItem()).isInstanceOf(DataState.Loading::class.java)
        val error = awaitItem()
        assertThat(error).isInstanceOf(DataState.Error::class.java)
        cancelAndIgnoreRemainingEvents()
    }
}
```

---

## Exception Test Naming Convention

```
{methodName}_{exceptionType}_expectedResult

Examples:
- fetchData_success_returnsData
- fetchData_ioException_returnsNetworkError
- fetchData_httpException_returnsHttpError
- saveUser_databaseException_returnsError
- login_invalidCredentials_throwsAuthenticationError
```

---

## Coverage Checklist

For each try-catch block:

- [ ] Success path (try block succeeds)
- [ ] First catch block exception
- [ ] Second catch block exception (if applicable)
- [ ] ... all catch blocks
- [ ] Generic/else catch block
- [ ] Finally block side effects verified
- [ ] Exception message verified
- [ ] Exception cause verified (for wrapped exceptions)
- [ ] Logging verified (if applicable)

---

## Common Exception Types to Test

```kotlin
// Network
IOException
SocketTimeoutException
UnknownHostException
HttpException (4xx, 5xx)

// Database
SQLiteException
SQLException

// Parsing/Serialization
JsonParseException
SerializationException
XmlPullParserException

// Business Logic
IllegalArgumentException
IllegalStateException
NullPointerException

// Custom
DomainException
ValidationException
NotFoundException
PermissionDeniedException
```

---

## Assertions for Exception Tests

```kotlin
// Exception type
assertThrows<IOException> {
    repository.fetchData("invalid")
}

// Exception message
val exception = assertThrows<ValidationException> {
    validator.validate(invalidData)
}
assertThat(exception.message).contains("Invalid email")

// Exception cause
val exception = assertThrows<DomainException> {
    service.execute()
}
assertThat(exception.cause).isInstanceOf(ApiException::class.java)

// Error result
val result = repository.fetchData("invalid")
assertThat(result).isInstanceOf(Result.Failure::class.java)
assertThat((result as Result.Failure).error.message).contains("Error")

// Null result on exception
val result = repository.fetchDataOrNull("invalid")
assertThat(result).isNull()
```

---

## Quick Template

```kotlin
@DisplayName("When {methodName} throws {ExceptionType} - Then returns {ExpectedResult}")
@Test
fun {methodName}_{exceptionType}_returns{ExpectedResult}() = runTest {
    // Given
    coEvery { mockDependency.method() } throws {ExceptionType}("{message}")

    // When
    val result = classUnderTest.{methodName}()

    // Then
    assertThat(result).isInstanceOf({ExpectedResult}::class.java)
    // OR
    assertThrows<{ExceptionType}> {
        classUnderTest.{methodName}()
    }
}
```
