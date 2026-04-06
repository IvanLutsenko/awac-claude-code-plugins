---
description: Create a new project in Obsidian
allowed-tools: Read, mcp__plugin_obsidian-tracker_obsidian__getConfig, mcp__plugin_obsidian-tracker_obsidian__initVault, mcp__plugin_obsidian-tracker_obsidian__listProjects, mcp__plugin_obsidian-tracker_obsidian__getProject, mcp__plugin_obsidian-tracker_obsidian__listTasks, mcp__plugin_obsidian-tracker_obsidian__addTask, mcp__plugin_obsidian-tracker_obsidian__updateTask, mcp__plugin_obsidian-tracker_obsidian__addBug, mcp__plugin_obsidian-tracker_obsidian__closeBug, mcp__plugin_obsidian-tracker_obsidian__addSession, mcp__plugin_obsidian-tracker_obsidian__createProject, mcp__plugin_obsidian-tracker_obsidian__updateProject, mcp__plugin_obsidian-tracker_obsidian__archiveProject, mcp__plugin_obsidian-tracker_obsidian__restoreProject, mcp__plugin_obsidian-tracker_obsidian__search
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

2. **Detect subproject intent:**
   Если пользователь упоминает "подпроект", "в проекте X", "sub" — это подпроект.
   Вызови `listProjects`, найди родительский проект и передай его имя в `parent`.

3. **Create project via MCP:**
   ```
   mcp__plugin_obsidian_tracker_obsidian__createProject
   с параметрами:
     name = project name
     description = description
     parent = parent project name (если подпроект)
   ```

4. **Output:**
   ```
   Project "{name}" created
   Path: {path}

   Quick commands:
   - `/projects {name}` - view details
   - `/project-bug {name}` - add bug
   - `/session-log {name}` - log session
   ```
