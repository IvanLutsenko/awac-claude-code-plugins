# Obsidian Tracker

Project tracking and bug logging with Obsidian integration.

## Features

- **Project Management**: List, create, and view projects
- **Bug Tracking**: Create and manage bug reports
- **Session Logging**: Record Claude Code sessions
- **Search**: Find projects by tags or content
- **Bi-directional Sync**: Claude ↔ Obsidian

## Commands

- `/projects` - List all projects
- `/projects [name]` - Show project details
- `/project-new` - Create new project
- `/project-bug [project]` - Create bug report
- `/session-log [project]` - Log current session

## MCP Tools

- `obsidian://listProjects()` - List all projects
- `obsidian://getProject(name)` - Get project details
- `obsidian://createProject(...)` - Create project
- `obsidian://addBug(...)` - Add bug report
- `obsidian://addSession(...)` - Add session log
- `obsidian://search(query)` - Search by tag/content

## Setup

1. Configure vault path in `.mcp.json`:
   ```json
   {
     "mcpServers": {
       "obsidian": {
         "command": "node",
         "args": ["mcp/index.js"],
         "env": {
           "OBSIDIAN_VAULT": "/path/to/your/obsidian/vault"
         }
       }
     }
   }
   ```

2. Install dependencies:
   ```bash
   cd mcp && npm install && npm run build
   ```

3. Install plugin:
   ```bash
   /plugin install obsidian-tracker
   ```

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

1.0.0
