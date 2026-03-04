# Obsidian Tracker

Project tracking and bug logging with Obsidian integration. **Auto-tracks sessions via hooks.**

## Features

- **Project Management**: List, create, and view projects
- **Bug Tracking**: Create and manage bug reports
- **Session Logging**: Record Claude Code sessions
- **Auto-Tracking**: Automatic session logging via hooks
- **Search**: Find projects by tags

## Commands

| Command | Description |
|---------|-------------|
| `/projects` | List all projects |
| `/projects [name]` | Show project details |
| `/project-new` | Create new project |
| `/project-bug [project]` | Create bug report |
| `/session-log [project]` | Manual session log |
| `/track-start [project]` | Start auto-tracking |
| `/track-stop` | Stop tracking + save to Obsidian |
| `/track-status` | Show current tracking status |

## Auto-Tracking (NEW in v2.0)

### How it works

```
/track-start my-project
    ↓
Work normally, use TodoWrite
    ↓
Actions automatically recorded
    ↓
/clear or /track-stop
    ↓
Session saved to Obsidian
```

### Hooks

| Hook | Trigger | Type | Action |
|------|---------|------|--------|
| PreCompact | Before context compression | prompt | Preserves tracking info in summary |
| SessionStart:clear | `/clear` | command | Save session to Obsidian + cleanup |
| SessionStart:compact\|resume | Context compact, resume | command | Remind about active tracking |
| SessionStart:startup | Fresh session | command | Auto-detect project, start tracking |
| PostToolUse:TodoWrite | TodoWrite | prompt | Records completed todos to tracking file |

> SessionStart hooks use `command` type (bash scripts in `hooks/`) for resilience — they never error even if the MCP server is unavailable.

### Tracking file

Located at `.claude/obsidian-tracking.json`:
```json
{
  "project": "my-project",
  "goal": "Fix bugs",
  "started": "2024-01-29T10:00:00Z",
  "actions": ["✅ Fix search", "✅ Update docs"]
}
```

## MCP Tools

| Tool | Description |
|------|-------------|
| `initVault` | Initialize with vault path |
| `getConfig` | Get current configuration |
| `listProjects` | List all projects |
| `getProject` | Get project details |
| `createProject` | Create new project |
| `addBug` | Add bug report |
| `addSession` | Add session log |
| `search` | Search by tag (e.g., `tag:bug`) |

## Setup

1. Install plugin:
   ```bash
   /plugin install obsidian-tracker
   ```

2. Build MCP server:
   ```bash
   cd plugins/obsidian-tracker/mcp && npm install && npm run build
   ```

3. On first command use, you'll be prompted for your Obsidian vault path.

## Obsidian Structure

```
{vault}/Projects/{project-name}/
├── !Project Dashboard.md    # Main dashboard
├── README.md                 # Project description
├── BUG - {title}.md         # Bug reports
└── Sessions/
    └── Session - YYYY-MM-DD.md  # Session logs
```

## Version

2.3.0

## Changelog

### 2.3.0
- SessionStart hooks converted from `prompt` to `command` type (bash scripts in `hooks/`)
- Hooks no longer error when MCP server is unavailable — graceful degradation
- Added `hooks/session-clear.sh`, `hooks/session-resume.sh`, `hooks/session-startup.sh`

### 2.2.0
- `allowed-tools` in all 7 commands — MCP tools, Bash, Read auto-approved without manual confirm
- Tracking file creation via `Bash(cat <<EOF)` instead of Write tool (Write requires prior Read for new files)
- MCP tools (`getConfig`, `listProjects`, `getProject`, `addSession`, `addBug`) in allowed-tools
- Scoped `rm` permission: only `.claude/obsidian-tracking.json`

### 2.1.1
- Fixed MCP server not loading: changed command format to use `node` with `${CLAUDE_PLUGIN_ROOT}` instead of relative shell script path

### 2.1.0
- Added hooks for auto-tracking

### 2.0.0
- Initial release with MCP server and auto-tracking hooks
