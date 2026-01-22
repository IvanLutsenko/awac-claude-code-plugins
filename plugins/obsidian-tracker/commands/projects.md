---
description: List all projects from Obsidian or show specific project details
argument-hint: "[project-name]"
allowed-tools: ["Read", "AskUserQuestion"]
---

# Projects Command

Lists all tracked projects from Obsidian or shows details for a specific project.

## Arguments

- `project-name` (optional) - Show details for specific project

## Examples

```
/projects                    # List all projects
/projects awac-claude-code-plugins  # Show specific project
```

## Logic

1. **If no argument:**
   - Call `obsidian://listProjects()` MCP tool
   - Display table with:
     - Project name
     - Status (Active/Archived)
     - Plugin count (if applicable)
     - Open bugs count
   - Show dashboards as links

2. **If project-name provided:**
   - Call `obsidian://getProject(projectName)` MCP tool
   - Display:
     - Project description
     - List of plugins/subprojects
     - Open bugs (with links)
     - Recent session logs
     - Quick commands for this project

3. **Output format:** Clean markdown table with Obsidian [[wiki-links]]
