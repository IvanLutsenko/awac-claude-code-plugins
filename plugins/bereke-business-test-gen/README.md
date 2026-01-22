# Bereke Business Test Gen

Automated unit test generation for Kotlin/Android business logic with corporate standards.

**Version 2.7.0** - PR Workflow + Test Refactoring! Smart skip logic + auto mocks.

**New in 2.7.0**:
- 🔀 `/test-diff`: Generate tests only for changed files in PR (vs target branch)
- 🔧 `/test-fix`: Auto-fix existing tests (flow-verify, assertions, branches)
- 🧠 Smart Skip: Content-aware DTO/UI filtering (not just file names)
- 🎭 Auto Mocks: Generate MockK stubs for all dependencies automatically

## Installation & Usage

Choose your tool below:

### Claude Code (CLI)

Best for automated test generation with slash commands.

```bash
# Add marketplace
/plugin marketplace add https://github.com/IvanLutsenko/awac-claude-code-plugins

# Install plugin
/plugin install bereke-business-test-gen

# Verify installation
/help  # Should show new commands
```

Then use:
```bash
/test-class src/main/java/.../YourClass.kt
/test-module feature/auth
```

---

### Claude Desktop

Use this plugin as an MCP server in Claude Desktop.

1. Edit Claude Desktop config file:
   - **macOS/Linux:** `~/.config/Claude/claude_desktop_config.json`
   - **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

2. Add this plugin as MCP server:
```json
{
  "mcpServers": {
    "bereke-test-gen": {
      "command": "node",
      "args": ["/path/to/awac-claude-code-plugins/plugins/bereke-business-test-gen/mcp-server.js"]
    }
  }
}
```

3. Restart Claude Desktop
4. Plugin will be available in conversations

---

### ChatGPT Desktop

Use test standards as knowledge base.

1. Open ChatGPT Desktop
2. In conversation, paste this at start:
```
I'll use these test standards for our conversation.

[PASTE CONTENTS OF standards/android-kotlin-quick-ref.md]
```

3. Then request test generation:
```
Generate unit test for this Kotlin class:

[PASTE YOUR CLASS CODE]

Follow the standards above.
```

---

### ChatGPT Code (CLI/API)

Use standards with ChatGPT via API or CLI tools.

**With OpenAI API:**
```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-4",
    "system": "[PASTE CONTENTS OF standards/android-kotlin.md]",
    "messages": [{
      "role": "user",
      "content": "Generate test for: [YOUR CLASS CODE]"
    }]
  }'
```

**With CLI tools (like aider):**
```bash
# Include standards in project context
cp standards/android-kotlin-quick-ref.md .cursorrules

# Or use with aider
aider --message "Generate test for this class:
[PASTE YOUR CLASS CODE]

Follow standards in standards/android-kotlin.md"
```

---

### Gemini Web

Use standards in Gemini conversations.

1. Open https://gemini.google.com

2. Paste test standards at start of conversation:
```
Follow these test standards:

[PASTE CONTENTS OF standards/android-kotlin-quick-ref.md]
```

3. Then request test generation:
```
Generate unit test for this Kotlin class:

[PASTE YOUR CLASS CODE]
```

---

### Gemini CLI

Use standards with Gemini API or CLI tools.

**With Google Gemini API:**
```bash
curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "system_instruction": {
      "parts": [{
        "text": "[PASTE CONTENTS OF standards/android-kotlin.md]"
      }]
    },
    "contents": {
      "parts": [{
        "text": "Generate test for: [YOUR CLASS CODE]"
      }]
    }
  }'
```

**With Gemini CLI tools:**
```bash
gemini --system-prompt="[PASTE standards/android-kotlin-quick-ref.md]" \
        --input="Generate test for: [YOUR CLASS CODE]"
```

---

## Commands (Claude Code Only)

The following slash commands are available only in Claude Code (CLI):

### `/test-class [path/to/ClassName.kt]`

Generate a comprehensive unit test for a single class with coverage metrics.

**Example:**
```bash
/test-class src/main/java/kz/berekebank/business/core/auth/LoginRepository.kt
```

**Output:** Test file with LINE + INSTRUCTION coverage metrics

⏱️ **Time:** 2-5 minutes

---

### `/test-diff [--branch target] [--dry-run]`

Generate tests only for changed files in current branch (PR workflow).

**Examples:**
```bash
/test-diff                           # vs origin/master
/test-diff --branch origin/develop   # vs develop
/test-diff --dry-run                 # preview without generation
```

**Features:**
- Smart skip for DTO/UI components
- Creates new tests or updates existing
- Reports coverage delta

⏱️ **Time:** 5-10 minutes (depending on diff size)

---

### `/test-fix [mode] [path]`

Auto-fix existing tests to match corporate standards.

**Modes:**
```bash
/test-fix --all feature/auth          # all fixes
/test-fix --flow-verify core/network  # fix memory leaks (coVerify → FlowTestUtils)
/test-fix --branches TestFile.kt      # add tests for uncovered branches
/test-fix --assertions core/domain    # assertTrue → assertThat
/test-fix --display-names feature     # add @DisplayName annotations
```

**Priority:**
1. `--flow-verify` - HIGH (memory leak fixes)
2. `--branches` - HIGH (coverage improvement)
3. `--assertions` - MEDIUM (style)
4. `--display-names` - LOW (readability)

⏱️ **Time:** 2-5 minutes per module

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

⏱️ **Time:** 5-8 minutes (15-class module with v2.5.0 parallel batches)

---

### `/validate-tests [path/to/module]` (Optional)

Validate existing tests for compliance with standards.

```bash
/validate-tests feature/auth
```

**Output:** List of violations with confidence scoring

---

## How It Works

**Claude Code (CLI) & Claude Desktop:**

Both platforms use the `test-engineer` agent which:

- ✅ Analyzes code structure and architecture
- ✅ Finds existing test examples in project
- ✅ Generates tests following corporate standards
- ✅ Compiles and runs tests
- ✅ Reports LINE + INSTRUCTION coverage metrics
- ✅ Provides improvement recommendations

**Other platforms (ChatGPT, Gemini):**

Use the test standards files as knowledge base. The LLM will generate tests based on your instructions using the standards provided.

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

**For Claude Code & Claude Desktop:**

1. **Use `/test-class` first** to understand the agent behavior on a single class
2. **Provide clear module paths** (feature/auth, core:analytics, etc.)
3. **Check coverage after generation** (LINE and INSTRUCTION metrics)
4. **Review generated tests** - they follow patterns from your codebase

**For all platforms:**

1. **Start with quick reference** - use `android-kotlin-quick-ref.md` before full standards
2. **Use specific class/method names** - be clear about what you want tested
3. **Review coverage** - always verify the generated tests meet your needs
4. **Follow the standards** - all standards are mandatory for consistent test quality

## License

MIT - see [LICENSE](../../LICENSE)
