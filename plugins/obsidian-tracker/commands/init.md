---
description: Initialize Obsidian Tracker with vault path
allowed-tools: ["AskUserQuestion"]
---

# Initialize Obsidian Tracker

First-time setup for Obsidian Tracker plugin.

## Logic

1. **Check current config:**
   - Call MCP tool `getConfig` to check if already initialized

2. **If not initialized, ask user for vault path:**
   - Use AskUserQuestion to get the vault path
   - Suggest common locations:
     - `~/Documents/Obsidian/Projects`
     - `~/Documents/GitHub/obsidian/MCP/Projects`
   - Allow custom path input

3. **Initialize vault:**
   - Call MCP tool `initVault` with user-provided path
   - Confirm success

4. **Output:**
   - Show configuration summary
   - Explain available commands

## Example Output

```
Obsidian Tracker initialized!

Vault path: /Users/you/Documents/Obsidian/Projects
Config file: ~/.config/obsidian-tracker/config.json

Available commands:
- /obsidian-tracker:projects - List all projects
- /obsidian-tracker:project-new - Create new project
- /obsidian-tracker:project-bug - Log a bug
- /obsidian-tracker:session-log - Log session
```
