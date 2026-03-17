# AWAC Claude Code Plugins

Custom Claude Code plugins by Ivan Lutsenko

## Installation

Add the marketplace once, then install plugins as needed:

```bash
/plugin marketplace add https://github.com/IvanLutsenko/awac-claude-code-plugins
```

## Available Plugins

### Bereke Business Test Gen

Automated unit test generation for Kotlin/Android business logic with corporate standards.

📚 **[Full Documentation](plugins/bereke-business-test-gen/README.md)**

**Installation:**
```bash
/plugin install bereke-business-test-gen
```

**Quick Start:**
```bash
/test-class src/main/java/.../YourClass.kt      # Single class (2-15 min)
/test-module feature/auth                        # Full module coverage (30-90 min)
/test-diff [--branch origin/master]             # PR workflow (tests only for changed files)
/test-fix [--all] feature/auth                   # Auto-fix existing tests to standards
/validate-tests feature/auth                     # Validate tests against standards
```

**Status:** ✅ Production Ready | **Version:** 2.7.0

**What's New in 2.7.0:**
- 🔄 **PR Workflow**: `/test-diff` generates tests only for changed files
- 🔧 **Auto-fix**: `/test-fix` brings existing tests to corporate standards
- ✅ **Validation**: `/validate-tests` checks tests against all standards

**Key Features:**
- Multi-agent architecture (10+ specialized agents)
- Two-stage improvement loop (coverage 80%+ + quality score 3.0+/4.0)
- Auto edge case detection from method signatures
- Flow/PagingData testing with Turbine
- Full PR workflow support

---

### Crashlytics

Multi-platform crash analysis for Android & iOS with git blame forensics, code-level fixes, and quality gate reviewer.

📚 **[Full Documentation](plugins/crashlytics/README.md)**

**Installation:**
```bash
/plugin install crashlytics
```

**Quick Start:**
```bash
/crash-report ca8f7f21e3...        # Unified (auto-detects platform from config)
/crash-report-android               # Explicit Android
/crash-report-ios                    # Explicit iOS
/crash-config                       # Configure plugin settings
```

**Status:** ✅ Production Ready | **Version:** 4.1.1

**What's New in 4.1.1:**
- **Fix:** `experimental:mcp` → `mcp` — Firebase MCP graduated to GA, Crashlytics tools now available
- Updated troubleshooting and docs

**Features:**
- 4-step multi-agent pipeline: classifier → fetcher → forensics → reviewer
- Git blame forensics with mandatory assignee identification
- Code-level fixes (before/after) ready to copy-paste
- 3-level Firebase fallback: MCP (with retries) → CLI API → Manual
- Configurable per-project settings

---

### Obsidian Tracker

Project tracking, task management with kanban boards, bug logging, and session management via Obsidian. **Auto-tracks sessions via hooks.**

📚 **[Full Documentation](plugins/obsidian-tracker/README.md)**

**Installation:**
```bash
/plugin install obsidian-tracker
cd plugins/obsidian-tracker/mcp && npm install && npm run build
```

**Quick Start:**
```bash
/track-start my-project     # Start auto-tracking session
/projects                   # List all projects
/project-new                # Create new project
/task my-project "Fix bug"  # Create task on kanban board
/done my-project 1          # Mark task as done
/project-archive archive old-project  # Archive a project
/track-stop                 # Save session to Obsidian
```

**Status:** ✅ Production Ready | **Version:** 3.0.0

**What's New in 3.0.0:**
- Task management with kanban board (Backlog/In Progress/Review/Done)
- Project lifecycle: archive, restore, permanently delete
- New commands: `/task`, `/done`, `/today`, `/pulse`, `/import`, `/project-archive`

**Features:**
- Auto-tracking via hooks (PreCompact, SessionStart, PostToolUse)
- Project management with Obsidian as single source of truth
- Kanban task board with auto-increment IDs
- Project archiving and lifecycle management
- Bug tracking with priority levels
- Session logging (manual or automatic)

---

### Auto Theme

Automatically syncs Claude Code theme with macOS system appearance (dark/light mode).

**Installation:**
```bash
/plugin install auto-theme
```

**Status:** ✅ Production Ready | **Version:** 1.0.0

**How it works:**
- Hooks into `UserPromptSubmit` — checks macOS appearance on every message
- Detects dark/light mode via `defaults read -g AppleInterfaceStyle`
- Updates `~/.claude.json` theme key when system appearance changes
- Fast-path ~40ms when theme already matches (no file write)
- Preserves variant suffix (`-ansi`, `-daltonized`) if selected

---

### Locale Notifications

macOS notifications for Claude Code in your system language.

📚 **[Full Documentation](plugins/locale-notifications/README.md)**

**Installation:**
```bash
/plugin install locale-notifications
```

**Status:** ✅ Production Ready | **Version:** 2.0.0

**What's New in 2.0.0:**
- Auto-translation via Google Translate API — any language supported
- Local caching — one API call, then works offline
- Custom message support via config file

**How it works:**
- Hooks into Claude Code `Notification` events
- Detects system locale via `defaults read -g AppleLocale`
- Auto-translates and caches the notification message
- Displays native macOS notification via `osascript`

---

## Author

Ivan Lutsenko
GitHub: [@IvanLutsenko](https://github.com/IvanLutsenko)

## License

MIT - see [LICENSE](LICENSE)
