---
description: Create or update a bug report in Obsidian
argument-hint: "[project-name]"
---

# Project Bug Command

Creates a bug report in the specified project.

## Step 0: Check Configuration

Вызови MCP tool:
```
mcp__plugin_obsidian_tracker_obsidian__getConfig
```

**Если `initialized: false`:** выполни инициализацию как в `/projects` команде.

## Arguments

- `project-name` (optional) - Project to add bug to
- `--title` - Bug title (optional, will ask if not provided)
- `--priority` - Priority: critical|high|medium|low (default: medium)

## Examples

```
/project-bug awac-claude-code-plugins
/project-bug awac-claude-code-plugins --title "Search broken" --priority high
```

## Logic

1. **Resolve project:**

   Если project-name не указан:
   ```
   mcp__plugin_obsidian_tracker_obsidian__listProjects
   ```
   Покажи список и спроси через AskUserQuestion.

2. **Collect bug info via AskUserQuestion:**
   - Title (если не передан через --title)
   - Priority: critical / high / medium / low
   - Description (multi-line)

3. **Create bug via MCP:**
   ```
   mcp__plugin_obsidian_tracker_obsidian__addBug
   с параметрами:
     project = project name
     title = bug title
     description = description
     priority = priority
   ```

4. **Output:**
   ```
   🐛 Bug created: "{title}"
   📁 Path: {path}
   🔴 Priority: {priority}
   ```
