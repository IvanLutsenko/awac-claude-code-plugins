# Combined Review Plugin

Multi-agent code review with CodeRabbit CLI integration.

**Version:** 1.0.0

---

## Installation

```bash
/plugin install combined-review
```

Optional (for full functionality):
```bash
# Install CodeRabbit CLI
curl -fsSL https://cli.coderabbit.ai/install.sh | sh

# Authenticate (opens browser)
coderabbit auth login
```

> Without CodeRabbit, the plugin works with 4 agents. CodeRabbit adds a 5th review layer.

---

## Quick Start

```bash
/review                                    # Uncommitted changes
/review 123                                # PR by number
/review feature/CPT-3617 feature/CPT-3600  # Branch diff
/review feature/X to feature/Y            # Same (with "to")
/review --base main                        # Current branch vs main
```

### Optional agents

```bash
/review feature/X feature/Y +comments     # Add comment analysis
/review feature/X feature/Y +types        # Add type design analysis
/review feature/X feature/Y +simplify     # Add code simplification
/review feature/X feature/Y all           # Run all agents
```

---

## Default Agents (5)

| Agent | Focus | Model |
|-------|-------|-------|
| **code-reviewer** | CLAUDE.md compliance, bugs, logic errors, code quality | Sonnet |
| **git-historian** | Git blame, history, reverted fixes, parallel work conflicts | Sonnet |
| **silent-failure-hunter** | Empty catches, swallowed errors, broad exceptions, silent fallbacks | Sonnet |
| **test-analyzer** | Test coverage quality, missing error/edge case tests | Sonnet |
| **CodeRabbit** | AI-powered review via CLI (if installed) | External |

## Optional Agents

| Agent | Trigger | Focus |
|-------|---------|-------|
| Comment Analyzer | `+comments` | Comment accuracy vs code, stale TODOs |
| Type Design Analyzer | `+types` | Encapsulation, invariants, enforcement |
| Code Simplifier | `+simplify` | Simplification without losing functionality |

---

## How It Works

1. **Parse arguments** — determine mode (PR / branch diff / uncommitted)
2. **Gather diff** — via `gh pr diff`, `git diff`, or `git diff branch1...branch2`
3. **Check CodeRabbit** — install if missing (with user consent), check auth
4. **Launch agents in parallel** — 4 default + CodeRabbit + optional
5. **Score and filter** — confidence 0-100, threshold >= 60, deduplicate
6. **Report** — grouped by severity, every finding with `file:line`

### Confidence scoring

- **0-25**: False positive, pre-existing issue
- **25-50**: Possible but unlikely
- **50-75**: Real issue, minor impact
- **75-100**: Confirmed issue, affects functionality

Findings below 60 are filtered out.

### False positive rules

Automatically skipped:
- Pre-existing issues (not in this diff)
- Linter/compiler/CI catches
- Stylistic nitpicks not in CLAUDE.md
- Intentional functionality changes
- Generic advice without specifics

---

## Output Format

Every finding includes file path and line number:

```
## Code Review: feature/X vs feature/Y

**Files:** 12 | **Lines:** +156 / -335 | **Commits:** 1

### Critical

1. `path/to/File.kt:42` — description [source: code-reviewer, confidence: 90]
   > code snippet

### Findings

1. `path/to/File.kt:100` — description [source: silent-failure-hunter, confidence: 75]

### Tests

1. `path/to/File.kt` — missing test for [scenario] [criticality: 8/10]

### CodeRabbit

[Deduplicated results from CodeRabbit CLI]

### Positive

- What's done well
```

---

## Changelog

### 1.0.0

- Initial release
- 4 default agents: code-reviewer, git-historian, silent-failure-hunter, test-analyzer
- CodeRabbit CLI integration with auto-install
- Support for PR, branch diff, and uncommitted changes
- Confidence scoring and false positive filtering
- Optional agents: +comments, +types, +simplify

---

## License

MIT
