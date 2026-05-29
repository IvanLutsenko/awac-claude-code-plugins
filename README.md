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

Multi-platform crash analysis for Android & iOS with git blame forensics, code-level fixes, and a deterministic quality gate.

📚 **[Full Documentation](plugins/crashlytics/README.md)**

**Installation:**
```bash
/plugin install crashlytics
/crashlytics:install-permissions   # one-time: add read-only git/MCP to allowlist
```

**Quick Start:**
```bash
/crash-report ca8f7f21e3...        # Unified (auto-detects platform from config)
/crash-report-android               # Explicit Android
/crash-report-ios                    # Explicit iOS
/crash-config                       # Configure plugin settings
/crashlytics:install-permissions    # Add read-only allowlist to settings.json
```

**Status:** ✅ Production Ready | **Version:** 4.4.3

**What's New in 4.4.3:**
- Language-aware validator: `SECTION_ALIASES` для en/ru/es/de/fr/pt/it (фикс false 6/14 на не-английских отчётах). Forensics-агенты пишут headers всегда на английском, body — на target language.
- `BRANCH_REF` (= `origin/<default_branch>`) вместо хардкода `master` + обязательный `git fetch origin --quiet` перед blame/log/show. STEP 4.0 sanity-check «is the fix already merged in BRANCH_REF».
- `/crashlytics:install-permissions` — мерджит read-only allowlist в settings.json (user или project уровень на выбор).
- 7 smoke-tests фикстур (en/ru/es/de/fr/pt/it) в `scripts/tests/`.

**Features:**
- 4-step multi-agent pipeline: classifier → fetcher → forensics → validate-report.py
- Git blame forensics with mandatory assignee identification, on `origin/<default_branch>`
- Code-level fixes (before/after) ready to copy-paste
- MCP-primary fetch (`crashlytics_get_issue` + `crashlytics_batch_get_events`), REST `v1alpha` fallback, Manual mode for offline use
- Multi-language reports (English headers + body in any language)
- Configurable per-project settings

---

### Obsidian Tracker

Project tracking, task management with kanban boards, bug logging, decision records (ADR), and session management via Obsidian. **Auto-tracks sessions, actions, bugs, and commits via hooks.**

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

**Status:** ✅ Production Ready | **Version:** 3.2.0

**What's New in 3.2.0:**
- Smart project lookup — subprojects found by short name (no full path needed)
- `parent` parameter in `createProject` for subprojects
- New tools: `deleteTask`, `updateProject` (with context appending)
- Task skill distinguishes actionable tasks from project context

**Features:**
- Auto-tracking via hooks (PreCompact, SessionStart, PostToolUse)
- Project management with Obsidian as single source of truth
- Kanban task board with auto-increment IDs
- Project archiving and lifecycle management
- Bug tracking with priority levels
- Session logging (manual or automatic)

---

### Combined Review

Multi-agent code review with CodeRabbit CLI integration. 4 specialized agents + optional CodeRabbit for comprehensive review.

📚 **[Full Documentation](plugins/combined-review/README.md)**

**Installation:**
```bash
/plugin install combined-review
```

**Quick Start:**
```bash
/review                                    # Uncommitted changes
/review 123                                # PR by number
/review feature/X feature/Y               # Branch diff
/review --base main                        # Current branch vs main
/review feature/X feature/Y +comments all # All agents
```

**Status:** ✅ Production Ready | **Version:** 1.0.0

**Features:**
- 4 default agents: code-reviewer, git-historian, silent-failure-hunter, test-analyzer
- CodeRabbit CLI integration (auto-install)
- Supports PR, branch diff, and uncommitted changes
- Confidence scoring (0-100) with false positive filtering
- Optional agents: +comments, +types, +simplify

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

### Drawbridge

Bridge between a short brief and image-gen web UIs (Gemini Imagen 3, ChatGPT DALL-E 3, Grok Aurora, Midjourney). Crafts a target-tuned prompt, copies it to clipboard, opens the target — no API keys, no payments.

📚 **[Full Documentation](plugins/drawbridge/README.md)**

**Installation:**
```bash
/plugin install drawbridge
```

**Quick Start:**
```bash
/draw закат на байкале с медведем у воды        # default target from config
/draw -t midjourney cyberpunk samurai            # one-shot target override
/redraw -t chatgpt                               # variation of last brief, different target
/draw-prompt <brief>                             # prompt only, no browser open
/draw-config show                                # view defaults
/draw-config set default_target chatgpt          # change default
```

**Status:** 🔨 Beta | **Version:** 0.1.0

**Features:**
- Per-target prompt fine-tuning (Imagen prose / DALL-E structure / Aurora density / MJ tag syntax)
- Auto-translate brief to English (configurable)
- Settings via `~/.claude/drawbridge.local.md` with project-local override
- History of last 200 prompts for `/redraw`
- macOS only in 0.1.0

---

### Plugin Cross Port

Bridge between Claude Code and Codex plugin formats. One-shot conversion and continuous dual-target maintenance.

**[Full Documentation](plugins/plugin-cross-port/README.md)**

**Installation:**
```bash
/plugin install plugin-cross-port
```

**Quick Start:**
```bash
# Interactive (via skill)
Convert plugins/obsidian-tracker to Codex

# Deterministic script
python3 plugins/plugin-cross-port/scripts/convert_cc_to_codex.py plugins/obsidian-tracker --repo-root .
python3 plugins/plugin-cross-port/scripts/convert_cc_to_codex.py plugins/obsidian-tracker --repo-root . --dry-run
```

**Status:** 🔨 Beta | **Version:** 0.1.0

**Features:**
- CC manifest -> Codex manifest (removes hooks, adds interface block)
- `commands/*.md` -> `skills/generated-from-commands/` (automated)
- Idempotent: re-run without duplicates
- Decision file `.plugin-cross-port.yaml` tracks what was converted
- `--dry-run`, `--force`, `--strict` flags
- Codex marketplace entry management

---

### Clip Maker

Automated vertical clip creator for talks and presentations. Whisper + Claude + ffmpeg pipeline.

📚 **[Full Documentation](plugins/clip-maker/README.md)**

**Installation:**
```bash
/plugin install clip-maker
```

**Quick Start:**
```bash
/clip-maker ~/Downloads/my-talk.mp4           # Full pipeline
/clip-maker ~/Downloads/my-talk.mp4 --auto    # Auto mode
/transcribe ~/Downloads/my-talk.mp4            # Only transcribe
/find-moments ~/Downloads/transcript.json      # Only find moments
```

**Status:** 🔨 Beta | **Version:** 1.3.0

**Features:**
- Whisper transcription (local or API)
- Opus-powered moment finding from transcript
- Vision-based smart crop (speaker detection)
- ffmpeg vertical clip cutting (9:16)
- Auto-subtitles from transcript
- Social media copy generation (Shorts/Reels/TikTok)

---

## Setup

After cloning, enable git hooks (runs plugin tests before push):

```bash
git config core.hooksPath .githooks
```

## Author

Ivan Lutsenko
GitHub: [@IvanLutsenko](https://github.com/IvanLutsenko)

## License

MIT - see [LICENSE](LICENSE)
