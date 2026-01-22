# Mapper with Validation Test Template

**Size**: ~600 tokens | **Use**: Extension functions with validation logic

---

## Pattern

Mapper with validation (DTO → Domain model with null checks, defaults):

```kotlin
// Source
// DTO from API
data class UserProfileDto(
    val id: String?,
    val name: String?,
    val email: String?,
    val age: Int?,
    val isActive: Boolean?
)

// Domain model
data class UserProfile(
    val id: String,
    val name: String,
    val email: String,
    val age: Int,
    val isActive: Boolean
)

// Mapper extension with validation
fun UserProfileDto.toModel(): UserProfile? {
    // Required fields validation
    val validatedId = id ?: return null
    val validatedName = name ?: return null
    val validatedEmail = email ?: return null

    // Optional fields with defaults
    val validatedAge = age ?: DEFAULT_AGE  // e.g., 0 or 18
    val validatedIsActive = isActive ?: true  // Default to active

    return UserProfile(
        id = validatedId,
        name = validatedName.trim(),
        email = validatedEmail.lowercase(),
        age = validatedAge,
        isActive = validatedIsActive
    )
}

// Or with Result type:
fun UserProfileDto.toModelResult(): Result<UserProfile, ValidationError> {
    if (id.isNullOrBlank()) return Result.failure(ValidationError("id is required"))
    if (name.isNullOrBlank()) return Result.failure(ValidationError("name is required"))
    if (!email.isNullOrBlank() && !email.contains("@")) {
        return Result.failure(ValidationError("invalid email format"))
    }

    return Result.success(
        UserProfile(
            id = id,
            name = name.trim(),
            email = email.orEmpty().lowercase(),
            age = age ?: 0,
            isActive = isActive ?: true
        )
    )
}
```

---

## Generated Tests (nullable return version)

```kotlin
class UserProfileMapperTest {

    // ==================== Happy Path Tests ====================

    @DisplayName("When toModel with valid DTO - Then returns mapped UserProfile")
    @Test
    fun toModel_validDto_returnsMappedProfile() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "user_123",
            name = " John Doe ",
            email = "JOHN@EXAMPLE.COM",
            age = 30,
            isActive = false
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNotNull()
        assertThat(result!!.id).isEqualTo("user_123")
        assertThat(result.name).isEqualTo("John Doe")  // Trimmed
        assertThat(result.email).isEqualTo("john@example.com")  // Lowercased
        assertThat(result.age).isEqualTo(30)
        assertThat(result.isActive).isFalse()
    }

    @DisplayName("When toModel with all fields present - Then maps correctly")
    @Test
    fun toModel_allFieldsPresent_mapsCorrectly() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "abc",
            name = "Alice",
            email = "alice@test.com",
            age = 25,
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNotNull()
        assertThat(result?.id).isEqualTo("abc")
        assertThat(result?.name).isEqualTo("Alice")
        assertThat(result?.email).isEqualTo("alice@test.com")
        assertThat(result?.age).isEqualTo(25)
        assertThat(result?.isActive).isTrue()
    }

    // ==================== Null Required Field Tests ====================

    @DisplayName("When toModel with null id - Then returns null")
    @Test
    fun toModel_nullId_returnsNull() = runTest {
        // Given
        val dto = UserProfileDto(
            id = null,  // Required field null
            name = "Test",
            email = "test@test.com",
            age = 20,
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNull()
    }

    @DisplayName("When toModel with null name - Then returns null")
    @Test
    fun toModel_nullName_returnsNull() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "test_id",
            name = null,  // Required field null
            email = "test@test.com",
            age = 20,
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNull()
    }

    @DisplayName("When toModel with null email - Then returns null")
    @Test
    fun toModel_nullEmail_returnsNull() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "test_id",
            name = "Test",
            email = null,  // Required field null
            age = 20,
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNull()
    }

    // ==================== Default Value Tests ====================

    @DisplayName("When toModel with null age - Then uses default value")
    @Test
    fun toModel_nullAge_usesDefaultValue() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "test_id",
            name = "Test",
            email = "test@test.com",
            age = null,  // Optional field null
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNotNull()
        assertThat(result!!.age).isEqualTo(DEFAULT_AGE)  // Default value
    }

    @DisplayName("When toModel with null isActive - Then defaults to true")
    @Test
    fun toModel_nullIsActive_defaultsToTrue() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "test_id",
            name = "Test",
            email = "test@test.com",
            age = 25,
            isActive = null  // Optional field null
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNotNull()
        assertThat(result!!.isActive).isTrue()  // Default
    }

    // ==================== Empty/Blank String Tests ====================

    @DisplayName("When toModel with blank id - Then returns null or handles")
    @Test
    fun toModel_blankId_handlesAccordingly() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "   ",  // Blank but not null
            name = "Test",
            email = "test@test.com",
            age = 20,
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then - depends on validation (blank check after trim)
        // If blank is invalid:
        // assertThat(result).isNull()
        // If blank is valid (just trimmed):
        assertThat(result).isNotNull()
        assertThat(result!!.id).isEqualTo("")  // or trimmed value
    }

    @DisplayName("When toModel with blank name - Then trims or returns null")
    @Test
    fun toModel_blankName_trimsOrReturnsNull() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "test_id",
            name = "   ",  // Blank
            email = "test@test.com",
            age = 20,
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then
        // If blank name is invalid after trim:
        // assertThat(result).isNull()
        // If blank name is allowed:
        assertThat(result).isNotNull()
        assertThat(result!!.name).isEmpty()
    }

    // ==================== Field Transformation Tests ====================

    @DisplayName("When toModel - Then trims whitespace from name")
    @Test
    fun toModel_trimsWhitespaceFromName() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "test",
            name = "  \tJohn\tDoe\n  ",
            email = "john@test.com",
            age = 30,
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNotNull()
        assertThat(result!!.name).isEqualTo("John\tDoe")  // Trimmed
    }

    @DisplayName("When toModel - Then lowercases email")
    @Test
    fun toModel_lowercasesEmail() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "test",
            name = "Test",
            email = "JOHN.DOE@EXAMPLE.COM",
            age = 30,
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNotNull()
        assertThat(result!!.email).isEqualTo("john.doe@example.com")
    }

    // ==================== Edge Cases ====================

    @DisplayName("When toModel with all nulls - Then returns null")
    @Test
    fun toModel_allNulls_returnsNull() = runTest {
        // Given
        val dto = UserProfileDto(
            id = null,
            name = null,
            email = null,
            age = null,
            isActive = null
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNull()
    }

    @DisplayName("When toModel with zero age - Then keeps zero (not default)")
    @Test
    fun toModel_zeroAge_keepsZero() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "test",
            name = "Test",
            email = "test@test.com",
            age = 0,  // Explicit zero
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then
        assertThat(result).isNotNull()
        assertThat(result!!.age).isEqualTo(0)  // Zero is valid, not replaced by default
    }

    @DisplayName("When toModel with negative age - Then keeps negative or handles")
    @Test
    fun toModel_negativeAge_keepsOrHandles() = runTest {
        // Given
        val dto = UserProfileDto(
            id = "test",
            name = "Test",
            email = "test@test.com",
            age = -5,
            isActive = true
        )

        // When
        val result = dto.toModel()

        // Then - depends on validation
        assertThat(result).isNotNull()
        assertThat(result!!.age).isEqualTo(-5)  // Or might return null if invalid
    }
}
```

---

## Generated Tests (Result type version)

```kotlin
// For Result<T, E> return type:

@DisplayName("When toModelResult with valid data - Then returns Success")
@Test
fun toModelResult_validData_returnsSuccess() = runTest {
    // Given
    val dto = UserProfileDto(
        id = "test",
        name = "Test",
        email = "test@example.com",
        age = 25,
        isActive = true
    )

    // When
    val result = dto.toModelResult()

    // Then
    assertThat(result.isSuccess).isTrue()
    val profile = result.getOrNull()
    assertThat(profile).isNotNull()
    assertThat(profile!!.id).isEqualTo("test")
}

@DisplayName("When toModelResult with blank id - Then returns Failure")
@Test
fun toModelResult_blankId_returnsFailure() = runTest {
    // Given
    val dto = UserProfileDto(
        id = "",  // Blank
        name = "Test",
        email = "test@example.com",
        age = 25,
        isActive = true
    )

    // When
    val result = dto.toModelResult()

    // Then
    assertThat(result.isFailure).isTrue()
    val error = result.exceptionOrNull()
    assertThat(error).isInstanceOf(ValidationError::class.java)
    assertThat(error?.message).contains("id")
}

@DisplayName("When toModelResult with invalid email - Then returns Failure")
@Test
fun toModelResult_invalidEmail_returnsFailure() = runTest {
    // Given
    val dto = UserProfileDto(
        id = "test",
        name = "Test",
        email = "invalid-email",  // No @
        age = 25,
        isActive = true
    )

    // When
    val result = dto.toModelResult()

    // Then
    assertThat(result.isFailure).isTrue()
    assertThat(result.exceptionOrNull()?.message).contains("email")
}
```

---

## Template Variables

| Variable | Description |
|----------|-------------|
| `{Dto}` | DTO class name |
| `{Model}` | Domain model name |
| `{requiredFields}` | List of required nullable fields |
| `{optionalFields}` | List of optional fields with defaults |
| `{DEFAULT_*}` | Default value constants |

---

## Coverage Checklist

- [ ] Happy path (all fields present)
- [ ] Null required field → null/Result.failure
- [ ] Null optional field → default value
- [ ] Empty/blank string handling
- [ ] Field transformations (trim, lowercase)
- [ ] All nulls scenario
- [ ] Zero values for numeric types
- [ ] Negative values (if applicable)
- [ ] Special characters in strings
- [ ] Boundary values (max length, etc.)
