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
/crash-report-android               # Analyze Android crash
/crash-report-ios                    # Analyze iOS crash
/crash-config                       # Configure plugin settings
```

**Status:** ✅ Production Ready | **Version:** 4.0.0

**What's New in 4.0.0:**
- Quality gate: `report-reviewer` agent validates mandatory fields before output
- Interactive `/crash-config` for language, branch, model, output format, Firebase
- Forensics model upgraded to Opus (Sonnet/Haiku as fallback)
- Configuration system via `.claude/crashlytics.local.md`
- Full English translation

**Features:**
- 4-step multi-agent pipeline: classifier → fetcher → forensics → reviewer
- Git blame forensics with mandatory assignee identification
- Code-level fixes (before/after) ready to copy-paste
- 3-level Firebase fallback: MCP → CLI API → Manual
- Configurable per-project settings

---

### Obsidian Tracker

Project tracking and bug logging with Obsidian integration. **Auto-tracks sessions via hooks.**

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
/project-bug my-project     # Create bug report
/track-stop                 # Save session to Obsidian
# or just /clear — auto-saves!
```

**Status:** ✅ Production Ready | **Version:** 2.0.0

**What's New in 2.0.0:**
- 🔄 **Auto-tracking**: Hooks automatically record your work
- 📝 **Auto-save on /clear**: Session logged to Obsidian automatically
- 🧠 **Survives /compact**: Tracking context preserved after compression
- 🎯 **MCP-based**: All commands now use MCP tools properly

**Features:**
- Auto-tracking via hooks (PreCompact, SessionStart, PostToolUse)
- Project management with Obsidian as single source of truth
- Bug tracking with priority levels
- Session logging (manual or automatic)
- MCP server for Obsidian vault access

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
