---
description: Create a new project in Obsidian
allowed-tools: Read
---

# Project New Command

Creates a new project structure in Obsidian.

## Step 0: Check Configuration

Вызови MCP tool:
```
mcp__plugin_obsidian_tracker_obsidian__getConfig
```

**Если `initialized: false`:** выполни инициализацию как в `/projects` команде.

## Logic

1. **Collect project info via AskUserQuestion:**
   - Project name (ОБЯЗАТЕЛЬНО)
   - Description (ОБЯЗАТЕЛЬНО)

2. **Create project via MCP:**
   ```
   mcp__plugin_obsidian_tracker_obsidian__createProject
   с параметрами:
     name = project name
     description = description
   ```

3. **Output:**
   ```
   ✅ Project "{name}" created
   📁 Path: {path}

   Quick commands:
   - `/projects {name}` - view details
   - `/project-bug {name}` - add bug
   - `/session-log {name}` - log session
   ```
