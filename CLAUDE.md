# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Claude Code plugin marketplace containing custom plugins by Ivan Lutsenko. The repository provides specialized agents and slash commands for Android/Kotlin development workflows.

### Active Plugins

1. **bereke-business-test-gen** (v2.3.0) - Production Ready
   - Automated unit test generation for Kotlin/Android business logic
   - **NEW v2.3**: Quality validation (≥3.0/4.0 score) + auto edge case detection
   - **NEW v2.2**: Iterative coverage improvement loop (auto-improves to 80%+ coverage)
   - Enforces corporate test standards (Truth assertions, MockK, DisplayName, Given-When-Then)
   - Three agents: test-engineer (generator) + test-coverage-analyst (coverage) + test-quality-reviewer (quality)

2. **crashlytics** (v2.0.0) - Production Ready
   - Android Crashlytics crash analysis with git blame forensics
   - Code-level fixes with developer assignment
   - Firebase MCP server integration

## Plugin Development Architecture

### Plugin Structure
Each plugin follows the Claude Code plugin specification:

```
plugins/{plugin-name}/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata and manifest
├── .mcp.json                # Optional MCP server configuration
├── commands/                # Slash command definitions (.md files)
├── agents/                  # Agent definitions (.md files)
├── standards/               # Knowledge base documents
└── README.md               # Plugin documentation
```

### Key Configuration Files

**plugin.json** - Plugin manifest:
- Defines plugin metadata (name, version, description)
- Lists commands (slash command .md files)
- Lists agents (specialized agent .md files)
- Specifies MCP servers if needed
- Example from bereke-business-test-gen:
  ```json
  {
    "name": "bereke-business-test-gen",
    "version": "2.0.0",
    "commands": ["./commands/test-class.md", ...],
    "agents": ["./agents/test-engineer.md"],
    "mcpServers": "./.mcp.json"
  }
  ```

**.mcp.json** - MCP server configuration:
- Firebase plugin uses Firebase Tools MCP server
- Empty object `{}` if no MCP servers needed
- Example from crashlytics:
  ```json
  {
    "mcpServers": {
      "firebase": {
        "command": "sh",
        "args": ["-c", "NODE_OPTIONS='--max-old-space-size=4096' npx -y firebase-tools@latest experimental:mcp"]
      }
    }
  }
  ```

### Slash Commands

Slash commands are defined as markdown files with frontmatter:

```markdown
---
description: Command description shown in /help
argument-hint: "path/to/file"  # Optional argument hint
allowed-tools: ["Read", "Write", "Edit", "Bash"]  # Tool restrictions
---

## Command implementation instructions
[Detailed workflow for Claude to follow]
```

The command filename determines the slash command name:
- `commands/test-class.md` → `/test-class`
- `commands/crash-report.md` → `/crash-report`

### Agents

Agents are specialized AI personas with specific expertise, defined in markdown files:

```markdown
---
name: agent-name
description: Brief description of agent's role
tools: Read, Write, Edit, Glob, Grep, Bash, TodoWrite
model: sonnet  # or opus/haiku
color: green  # UI color indicator
---

Agent system prompt with instructions, workflows, and expertise
```

Agents are invoked automatically by slash commands or can be called directly via the Task tool.

## Plugin Development Patterns

### Bereke Business Test Gen Architecture

**Core concept**: Enforce Android unit test standards through automation with iterative coverage improvement.

**Multi-agent approach** (v2.3.0+):

1. **test-engineer** (Sonnet) - Primary test generator:
   - Loads corporate standards from `standards/android-kotlin.md`
   - **Auto-detects edge cases** from method signatures (v2.3.0+)
   - Finds existing test examples in target codebase using `find` commands
   - Generates tests following strict patterns (Truth, MockK, Given-When-Then)
   - Validates compilation and runs tests with Gradle
   - **Orchestrates two-stage improvement loop**

2. **test-coverage-analyst** (Haiku) - Coverage validator:
   - Analyzes kover XML coverage reports
   - Identifies uncovered public methods
   - Prioritizes gaps (critical/high/medium/low)
   - Returns actionable list of methods needing tests
   - **Called in Stage A of loop**

3. **test-quality-reviewer** (Haiku) - Quality validator (NEW v2.3.0):
   - Analyzes test strength (assertions count, verify usage)
   - **Detects critical issues** (coVerify for Flow = memory leak!)
   - Scores each test (0-4 points, min 3.0 average required)
   - Validates scenario coverage (happy/error/edge)
   - **Called in Stage B of loop**

**Two-Stage Improvement Loop** (v2.3.0):
```
test-engineer workflow:
1. Auto-detect edge cases from method signatures:
   - String? → null, empty, blank tests
   - Int → negative, zero, max tests
   - List<T> → empty, single, multiple tests

2. Generate initial tests with edge cases
3. Compile + run tests
4. Generate coverage report (koverXmlReport)

5. LOOP (max 3 iterations):
   STAGE A: Coverage Check
   a1. Call test-coverage-analyst via Task tool
   a2. If coverage < 80%:
       - Analyst returns uncovered methods
       - Generate tests for those methods

   STAGE B: Quality Check (NEW v2.3.0)
   b1. Call test-quality-reviewer via Task tool
   b2. Reviewer returns:
       - Critical issues (coVerify for Flow!)
       - Weak tests (score < 3)
       - Missing scenarios
   b3. If issues found:
       - Fix critical issues (PRIORITY #1)
       - Improve weak tests
       - Add missing scenarios

   SUCCESS CHECK:
   c. If coverage >= 80% AND quality >= 3.0 AND no critical:
      - Success! Exit loop
   d. Else: goto step 4 (repeat)

6. Output final report:
   - Coverage: LINE and INSTRUCTION %
   - Quality: X.X/4.0 average score
   - Total tests + iterations used
```

**Command variants**:
- `/test-class` - Single class with two-stage loop (2-15 min)
- `/test-module` - Full module, each class gets loop treatment (30-90 min)
- `/validate-tests` - Validate existing tests against standards

**Critical implementation details**:
- Test package must match source package exactly
- Maximum 80 character line length (detekt compliance)
- FlowTestUtils for coroutine/Flow testing (**verified by quality-reviewer**)
- Turbine for Flow<PagingData> testing (v2.1.0+)
- Tests ALL wrapper methods (v2.1.0+)
- **Auto edge case detection** from method signatures (v2.3.0+)
- **Automatic coverage gap detection** (v2.2.0+)
- **Quality validation** with scoring system (v2.3.0+)
- **Target: 80%+ LINE coverage AND 3.0+ quality score** (v2.3.0+)

### Crashlytics Plugin Architecture

**Core concept**: Crash analysis with mandatory git forensics

**Workflow enforcement**:
1. Classify stacktrace (exception type, component, trigger)
2. Find files in codebase using Glob/Grep
3. Execute git blame on crash location
4. Determine assignee from git history
5. Root cause analysis with code-level fix

**MCP integration**: Uses Firebase Tools MCP server for Crashlytics data access

**Output formats**:
- Detailed analysis (technical deep-dive)
- JIRA Brief (actionable issue format)

**Priority determination**:
- Critical: Payments, auth, >5% users, security
- High: Important features, 1-5% users, new crashes
- Medium: <1% users, edge cases

## Testing Plugin Development

When creating or modifying plugins:

1. **Validate plugin.json schema**:
   ```bash
   # Ensure all referenced files exist
   ls plugins/{plugin-name}/.claude-plugin/plugin.json
   ls plugins/{plugin-name}/commands/*.md
   ls plugins/{plugin-name}/agents/*.md
   ```

2. **Test slash command discovery**:
   ```bash
   # After installing plugin
   /help  # Should show new commands
   ```

3. **Test MCP server integration** (if applicable):
   ```bash
   # Check MCP server starts correctly
   cat plugins/{plugin-name}/.mcp.json
   ```

4. **Validate command frontmatter**:
   - Ensure `description` is clear and concise
   - Specify `allowed-tools` to restrict agent capabilities
   - Use `argument-hint` for commands expecting file paths

## Installation and Usage

### As Marketplace Author

```bash
# From plugin marketplace repository
cd /path/to/awac-claude-code-plugins

# Test individual plugin locally
/plugin install ./plugins/bereke-business-test-gen

# Publish changes
git add .
git commit -m "Update plugin"
git push
```

### As Marketplace User

```bash
# Add marketplace (one-time)
/plugin marketplace add https://github.com/IvanLutsenko/awac-claude-code-plugins

# Install specific plugin
/plugin install bereke-business-test-gen
/plugin install crashlytics

# Verify installation
/help  # Shows available commands
```

## Critical Patterns and Conventions

### Agent Tool Usage

**Bereke Test Engineer Agent**:
- ALWAYS loads standards before test generation
- Uses `find` to locate similar tests in codebase (pattern matching)
- Executes Gradle commands to validate test compilation
- Reports coverage with specific metrics (LINE, INSTRUCTION)
- Uses TodoWrite for multi-step workflows

**Crashlytics Agent**:
- MANDATORY git blame execution (not optional)
- Fallback strategies when code unavailable
- Multiple search approaches (Glob patterns, Grep content)
- Structured output with two distinct formats

### Standards and Knowledge Base

Both plugins use markdown documents as knowledge bases:
- `standards/android-kotlin.md` - Full standard (600+ lines)
- `standards/android-kotlin-quick-ref.md` - Quick reference (50 lines)

Agents load these dynamically using file paths like:
```
~/.claude/plugins/marketplaces/awac-claude-code-plugins/plugins/{plugin-name}/standards/{file}.md
```

### Common Tool Restrictions

Commands specify allowed tools to prevent unintended side effects:
- Read, Write, Edit - File operations
- Glob, Grep - Code search
- Bash - Git commands, Gradle builds
- TodoWrite - Progress tracking

### Language and Localization

- **bereke-business-test-gen**: Russian language in command definitions (market-specific)
- **crashlytics**: Russian language for analysis output (team preference)
- All technical code/commands use English identifiers

## Marketplace Configuration

**marketplace.json** structure:
```json
{
  "name": "awac-claude-code-plugins",
  "version": "1.0.0",
  "plugins": [
    {
      "name": "plugin-name",
      "version": "x.y.z",
      "source": "./plugins/plugin-name",
      "category": "testing" | "development"
    }
  ]
}
```

Categories help organize plugins in marketplace listings.

## Development Workflow

### Creating a New Plugin

1. Create plugin directory structure:
   ```bash
   mkdir -p plugins/{plugin-name}/{.claude-plugin,commands,agents,standards}
   ```

2. Create plugin.json manifest
3. Write command definitions (markdown with frontmatter)
4. Create agent definitions if needed
5. Add plugin to marketplace.json
6. Test locally before publishing

### Updating Existing Plugins

1. Increment version in plugin.json
2. Update version in marketplace.json
3. Document changes in plugin README.md
4. Test with `/plugin install ./plugins/{plugin-name}`
5. Commit and push changes

## Git Workflow

Standard git operations:
```bash
git status
git add plugins/{plugin-name}
git commit -m "feat(plugin-name): description"
git push origin main
```

Users will receive updates when they re-sync the marketplace.

## Documentation

- **[Obsidian Workflow Guide](.claude/docs/obsidian-workflow.md)** - Project tracking, bug logging, session management
- **[Plugin Development Patterns](#plugin-development-patterns)** - Architecture details
- **[Marketplace Configuration](#marketplace-configuration)** - marketplace.json reference
