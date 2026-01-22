# Mapper Method Test Template

**Use for**: Simple mapper methods that convert one data class to another

**Pattern**: `fun SourceType.toTargetType() = TargetType(field1 = this.field1, ...)`

---

## Template Code

```kotlin
@DisplayName("When {methodName} called - Then all fields are mapped correctly")
@Test
fun {methodName}_mapsAllFields() {
    // Given
    val {sourceName} = {SourceType}(
        {field1Name} = {field1Value},
        {field2Name} = {field2Value},
        {field3Name} = {field3Value}
    )

    // When
    val result = {sourceName}.{methodName}()

    // Then
    assertThat(result).isNotNull()
    assertThat(result.{field1Name}).isEqualTo({field1Value})
    assertThat(result.{field2Name}).isEqualTo({field2Value})
    assertThat(result.{field3Name}).isEqualTo({field3Value})
}

@DisplayName("When {methodName} with null optional fields - Then maps with nulls")
@Test
fun {methodName}_withNullFields_mapsCorrectly() {
    // Given
    val {sourceName} = {SourceType}(
        {field1Name} = {field1Value},
        {optionalField}? = null
    )

    // When
    val result = {sourceName}.{methodName}()

    // Then
    assertThat(result).isNotNull()
    assertThat(result.{field1Name}).isEqualTo({field1Value})
    assertThat(result.{optionalField}).isNull()
}
```

---

## Variables to Replace

- `{methodName}` - Mapper method name (e.g., "toModel")
- `{SourceType}` - Source data class (e.g., "UserDto")
- `{TargetType}` - Target data class (e.g., "User")
- `{sourceName}` - Source instance variable name (e.g., "userDto")
- `{field1Name}`, `{field2Name}`, etc. - Field names
- `{field1Value}`, `{field2Value}`, etc. - Example values
- `{optionalField}` - Nullable field name

---

## Example: Applied Template

**Source Method**:
```kotlin
fun UserDto.toModel() = User(
    id = this.id,
    name = this.name,
    email = this.email
)
```

**Generated Test**:
```kotlin
@DisplayName("When toModel called - Then all fields are mapped correctly")
@Test
fun toModel_mapsAllFields() {
    // Given
    val userDto = UserDto(
        id = 123,
        name = "Test User",
        email = "test@example.com"
    )

    // When
    val result = userDto.toModel()

    // Then
    assertThat(result).isNotNull()
    assertThat(result.id).isEqualTo(123)
    assertThat(result.name).isEqualTo("Test User")
    assertThat(result.email).isEqualTo("test@example.com")
}
```

---

## Size Estimate

- **Lines**: ~40-50 lines (1-2 tests)
- **Tokens**: ~400-500 tokens
- **Savings vs full generation**: 8000 tokens → 500 tokens (94% reduction)

---

## When to Use

✅ Use this template when:
- Method is extension function or mapper method
- Method returns data class
- Method body is simple field assignment
- No business logic (if/when)
- No dependency calls

❌ Don't use template when:
- Method has if/when logic in mapping
- Method calls other methods (transformations)
- Method has complex calculations
- Method is async (suspend fun)

---

## Notes for Complex Mappers

If mapper has transformations, use full generation:
```kotlin
// ❌ Too complex for template (use full generation)
fun UserDto.toModel() = User(
    id = this.id,
    fullName = "${this.firstName} ${this.lastName}",  // transformation!
    status = when {
        this.isActive -> UserStatus.ACTIVE
        else -> UserStatus.INACTIVE
    }  // business logic!
)
```

---

## Notes

- Template tests field-by-field mapping
- No mocks needed (pure functions)
- Handles nullable fields
- Follows corporate standards (Given-When-Then, Truth assertions)
- Max 80 characters per line (detekt compliance)
