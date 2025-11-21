# Bereke Business Test Gen

Automated unit test generation for Kotlin/Android business logic with corporate standards.

## Quick Start

### Installation

```bash
# Add marketplace
/plugin marketplace add https://github.com/IvanLutsenko/awac-claude-code-plugins

# Install plugin
/plugin install bereke-business-test-gen

# Verify installation
/help  # Should show new commands
```

## Commands

### `/test-class [path/to/ClassName.kt]`

Generate a comprehensive unit test for a single class with coverage metrics.

**Example:**
```bash
/test-class src/main/java/kz/berekebank/business/core/auth/LoginRepository.kt
```

**Output:** Test file with LINE + INSTRUCTION coverage metrics

⏱️ **Time:** 2-5 minutes

---

### `/test-module [path/to/module]`

Generate unit tests for ALL classes in a module where unit tests make sense.

**Includes:**
- Business logic (ViewModel, UseCase, Interactor, Repository)
- Validators, Formatters, Utils with logic
- State machines, Custom delegates
- Cache implementations

**Excludes:**
- UI components (Activity, Fragment, Composable)
- Data classes without logic
- DI modules
- Constants/Enums

**Examples:**
```bash
/test-module feature/auth
/test-module core:push
```

**Output:** Full module coverage with statistics and recommendations

⏱️ **Time:** 20-30 minutes

---

### `/validate-tests [path/to/module]` (Optional)

Validate existing tests for compliance with standards.

```bash
/validate-tests feature/auth
```

**Output:** List of violations with confidence scoring

---

## How It Works

Both commands use the `test-engineer` agent which:

- ✅ Analyzes code structure and architecture
- ✅ Finds existing test examples in project
- ✅ Generates tests following corporate standards
- ✅ Compiles and runs tests
- ✅ Reports LINE + INSTRUCTION coverage metrics
- ✅ Provides improvement recommendations

## Test Standards

All generated tests follow strict corporate standards:

- **@DisplayName** for every test (no backticks)
- **Given-When-Then** structure with comments
- **Truth assertions** (`assertThat`)
- **MockK** for mocking with `mock` prefix
- **FlowTestUtils** for reactive testing
- **Max 80 characters per line** (detekt compliance)
- **Correct package structure** (test in same package as source)

See [`standards/android-kotlin.md`](standards/android-kotlin.md) for complete guide.

## Examples

Quick reference for test patterns:

- See [`standards/android-kotlin-quick-ref.md`](standards/android-kotlin-quick-ref.md) (50 lines)
- Full guide: [`standards/android-kotlin.md`](standards/android-kotlin.md) (600+ lines)

## Tips

1. **Use `/test-class` first** to understand the agent behavior on a single class
2. **Provide clear module paths** (feature/auth, core:analytics, etc.)
3. **Check coverage after generation** (LINE and INSTRUCTION metrics)
4. **Review generated tests** - they follow patterns from your codebase

## License

MIT - see [LICENSE](../../LICENSE)
