# Validator Method Test Template

**Use for**: Simple validation methods that return Boolean

**Pattern**: `fun validate(param: Type): Boolean = expression`

---

## Template Code

```kotlin
@DisplayName("When {methodName} with valid {paramName} - Then returns true")
@Test
fun {methodName}_valid{ParamName}_returnsTrue() {
    // Given
    val {paramName} = {validValue}

    // When
    val result = {classUnderTest}.{methodName}({paramName})

    // Then
    assertThat(result).isTrue()
}

@DisplayName("When {methodName} with invalid {paramName} - Then returns false")
@Test
fun {methodName}_invalid{ParamName}_returnsFalse() {
    // Given
    val {paramName} = {invalidValue}

    // When
    val result = {classUnderTest}.{methodName}({paramName})

    // Then
    assertThat(result).isFalse()
}

@DisplayName("When {methodName} with null {paramName} - Then returns false")
@Test
fun {methodName}_null{ParamName}_returnsFalse() {
    // Given
    val {paramName}: {ParamType}? = null

    // When
    val result = {classUnderTest}.{methodName}({paramName})

    // Then
    assertThat(result).isFalse()
}

@DisplayName("When {methodName} with empty {paramName} - Then returns false")
@Test
fun {methodName}_empty{ParamName}_returnsFalse() {
    // Given
    val {paramName} = ""

    // When
    val result = {classUnderTest}.{methodName}({paramName})

    // Then
    assertThat(result).isFalse()
}
```

---

## Variables to Replace

- `{methodName}` - Name of validator method (e.g., "isValidPhone")
- `{paramName}` - Parameter name (e.g., "phone")
- `{ParamName}` - Capitalized parameter name (e.g., "Phone")
- `{ParamType}` - Parameter type (e.g., "String", "Int")
- `{classUnderTest}` - Instance name (e.g., "validator")
- `{validValue}` - Example valid value (e.g., "1234567890")
- `{invalidValue}` - Example invalid value (e.g., "123")

---

## Example: Applied Template

**Source Method**:
```kotlin
class PhoneValidator {
    fun isValidPhone(phone: String?): Boolean {
        return phone != null && phone.length in 10..11
    }
}
```

**Generated Test**:
```kotlin
@DisplayName("When isValidPhone with valid phone - Then returns true")
@Test
fun isValidPhone_validPhone_returnsTrue() {
    // Given
    val phone = "1234567890"

    // When
    val result = validator.isValidPhone(phone)

    // Then
    assertThat(result).isTrue()
}

@DisplayName("When isValidPhone with invalid phone - Then returns false")
@Test
fun isValidPhone_invalidPhone_returnsFalse() {
    // Given
    val phone = "123"

    // When
    val result = validator.isValidPhone(phone)

    // Then
    assertThat(result).isFalse()
}

@DisplayName("When isValidPhone with null phone - Then returns false")
@Test
fun isValidPhone_nullPhone_returnsFalse() {
    // Given
    val phone: String? = null

    // When
    val result = validator.isValidPhone(phone)

    // Then
    assertThat(result).isFalse()
}

@DisplayName("When isValidPhone with empty phone - Then returns false")
@Test
fun isValidPhone_emptyPhone_returnsFalse() {
    // Given
    val phone = ""

    // When
    val result = validator.isValidPhone(phone)

    // Then
    assertThat(result).isFalse()
}
```

---

## Size Estimate

- **Lines**: ~60-70 lines (4 tests: valid + invalid + null + empty)
- **Tokens**: ~600-700 tokens
- **Savings vs full generation**: 8000 tokens → 700 tokens (91% reduction)

---

## Auto Edge Cases for String Parameters

For `String?` parameter, ALWAYS generate:
- ✅ Valid value test
- ✅ Invalid value test
- ✅ Null test
- ✅ Empty string test
- ✅ Blank string test (if applicable)

For `Int` parameter, generate:
- ✅ Valid value test
- ✅ Negative test
- ✅ Zero test
- ✅ Max value test (if applicable)

For `List<T>` parameter, generate:
- ✅ Valid list test
- ✅ Empty list test
- ✅ Single item test

---

## When to Use

✅ Use this template when:
- Method returns `Boolean`
- Method is simple validation (no dependencies)
- Method has 1-2 parameters
- No suspend (synchronous)

❌ Don't use template when:
- Method calls dependencies (repository, api)
- Method has complex logic (loops, multiple conditions)
- Method is async (suspend fun)
- Method returns non-Boolean

---

## Notes

- Template includes comprehensive edge cases (null, empty, valid, invalid)
- No mocks needed (pure functions)
- Follows corporate standards (Given-When-Then, Truth assertions)
- Max 80 characters per line (detekt compliance)
