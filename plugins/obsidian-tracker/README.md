# Obsidian Tracker

Project tracking, task management with kanban boards, bug logging, and session management via Obsidian. **Auto-tracks sessions via hooks.**

## Features

- **Project Management**: List, create, archive, restore, and delete projects
- **Task Management**: Kanban board with Backlog/In Progress/Review/Done columns
- **Bug Tracking**: Create and manage bug reports with priority levels
- **Session Logging**: Record Claude Code sessions (manual or automatic)
- **Auto-Tracking**: Automatic session logging via hooks
- **Project Lifecycle**: Active → Archived → Deleted
- **Search**: Find projects by tags or content

## Commands

| Command | Description |
|---------|-------------|
| `/projects` | List all projects |
| `/projects [name]` | Show project details |
| `/project-new` | Create new project |
| `/project-bug [project]` | Create bug report |
| `/project-archive [action] [project]` | Archive, restore, or delete a project |
| `/task [project] [title]` | Create a task on the kanban board |
| `/done [project] [task-id]` | Mark task as done |
| `/today [project]` | Show today's tasks and progress |
| `/pulse [project]` | Project health and activity overview |
| `/import [project]` | Import data into a project |
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
| `listProjects` | List all projects (supports `includeArchived`) |
| `getProject` | Get project details |
| `createProject` | Create new project |
| `archiveProject` | Archive a project (move to `_archive/`) |
| `restoreProject` | Restore an archived project |
| `deleteProject` | Permanently delete a project |
| `addTask` | Create task with auto-increment ID + kanban board |
| `updateTask` | Move task between kanban columns |
| `listTasks` | List tasks with board statuses |
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
{vault}/
├── {project-name}/
│   ├── !Project Dashboard.md    # Main dashboard (frontmatter: status, description, etc.)
│   ├── README.md                 # Project description
│   ├── Board.md                  # Kanban board (Backlog/In Progress/Review/Done)
│   ├── TASK-{id} - {title}.md   # Task files
│   ├── BUG - {title}.md         # Bug reports
│   └── Sessions/
│       └── Session - YYYY-MM-DD.md  # Session logs
└── _archive/
    └── {archived-project}/       # Archived projects (same structure)
```

## Version

3.0.0

## Changelog

### 3.0.0
- Task management: `addTask`, `updateTask`, `listTasks` with kanban board integration
- Project lifecycle: `archiveProject`, `restoreProject`, `deleteProject`
- `listProjects` now supports `includeArchived` parameter, `_archive/` folder
- New commands: `/task`, `/done`, `/today`, `/pulse`, `/import`, `/project-archive`

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
