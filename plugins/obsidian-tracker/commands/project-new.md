---
description: Create a new project in Obsidian
allowed-tools: ["Write", "AskUserQuestion"]
---

# Project New Command

Creates a new project structure in Obsidian.

## Logic

1. **Ask user for project details via AskUserQuestion:**
   - Project name
   - Description
   - Repository URL (optional)
   - Local path (optional)

2. **Create project structure:**
   ```
   {project-name}/
   ├── !Project Dashboard.md
   └── README.md
   ```

3. **Generate dashboard using template:**
   - Fill in provided details
   - Set status: Active
   - Add creation date

4. **Update main Obsidian index** (if exists)

5. **Output:** Confirmation with path to new project
