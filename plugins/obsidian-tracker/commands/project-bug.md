---
description: Create or update a bug report in Obsidian
allowed-tools: ["Write", "AskUserQuestion"]
---

# Project Bug Command

Creates a bug report in the specified project.

## Arguments

- `project` - Project name (required)
- `--title` - Bug title (optional, will ask if not provided)
- `--priority` - Priority: critical|high|medium|low (default: medium)

## Examples

```
/project-bug awac-claude-code-plugins
/project-bug awac-claude-code-plugins --title "glm-toggle not indexing" --priority critical
```

## Logic

1. **Resolve project:**
   - If `project` not provided: show list via `obsidian://listProjects()` and ask
   - Validate project exists via `obsidian://getProject(project)`

2. **Collect bug info:**
   - If no `--title`: Ask via AskUserQuestion
   - If no `--priority`: Ask or default to "medium"
   - Ask for description (multi-line)

3. **Create bug file:**
   - Path: `{project}/BUG - {title}.md`
   - Use bug report template

4. **Call MCP:** `obsidian://addBug(project, bugData)`

5. **Update project dashboard** (add to "Known Issues" section)

6. **Output:** Confirmation with link to bug file
