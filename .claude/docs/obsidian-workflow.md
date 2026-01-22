# Obsidian Workflow Guide

## Overview

This project uses **Obsidian** as the single source of truth for:
- Project documentation
- Bug tracking
- Session logging
- Context preservation between Claude Code sessions

## Quick Setup

1. **Install obsidian-tracker plugin:**
   ```bash
   /plugin marketplace add https://github.com/IvanLutsenko/awac-claude-code-plugins
   /plugin install obsidian-tracker
   cd plugins/obsidian-tracker/mcp && npm install && npm run build
   ```

2. **Configure your vault path** in `plugins/obsidian-tracker/.mcp.json`:
   ```json
   {
     "mcpServers": {
       "obsidian": {
         "command": "node",
         "args": ["mcp/index.js"],
         "env": {
           "OBSIDIAN_VAULT": "/Users/lutse/Documents/GitHub/obsidian/MCP/Projects"
         }
       }
     }
   }
   ```

## Commands Reference

| Command | Description |
|---------|-------------|
| `/projects` | List all projects |
| `/projects [name]` | Show project details |
| `/project-new` | Create new project |
| `/project-bug [project] --title "X"` | Create bug report |
| `/session-log [project]` | Log current session |

## When to Use Obsidian

1. **Persistent bugs** - Issues spanning multiple sessions
2. **Project context** - Architecture decisions, patterns
3. **Session continuity** - Log what was done and what's next
4. **Knowledge base** - Documentation for future reference

## Example Workflow

```bash
# Start of session
/projects awac-claude-code-plugins    # Review project status

# During debugging
/project-bug awac-claude-code-plugins --title "glm-toggle not indexing" --priority critical

# End of session
/session-log awac-claude-code-plugins  # Document progress
```

## Project Structure Template

```
{vault}/Projects/{project-name}/
├── !Project Dashboard.md    # Main overview
├── README.md                 # Description
├── {subproject}/
│   ├── README.md
│   └── BUG - {issue}.md
└── Sessions/
    └── Session - YYYY-MM-DD.md
```

## MCP Tools (Advanced)

Direct access via MCP tools:
- `obsidian://listProjects()` - List all
- `obsidian://getProject(name)` - Get details
- `obsidian://createProject(...)` - Create
- `obsidian://addBug(...)` - Add bug
- `obsidian://search(query)` - Search

## Tags Convention

- `#bug` - Bug reports
- `#claude-code` - Claude Code related
- `#project-name` - Project specific
- `#priority-{critical|high|medium|low}`
- `#status-{open|resolved}`

---

**See also:** `plugins/obsidian-tracker/README.md`
