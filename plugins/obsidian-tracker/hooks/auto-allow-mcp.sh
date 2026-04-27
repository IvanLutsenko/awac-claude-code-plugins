#!/bin/bash
# PermissionRequest — auto-allow obsidian-tracker MCP tools (read-only + mutating).
# Destructive tools (deleteProject, deleteTask, restoreProject) are NOT auto-allowed —
# they fall through to the default permission flow and require explicit user approval.
#
# To override per-user, add the tool to "ask" or "deny" in ~/.claude/settings.json:
#   { "permissions": { "ask": ["mcp__obsidian-tracker__addTask"] } }

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Read-only: findProjectByLocalPath, getConfig, getDecision, getProject, getResumeContext,
#            initVault, listDecisions, listProjects, listTasks, search
# Mutating:  addBug, addDecision, addSession, addSessionSummary, addTask, archiveProject,
#            closeBug, closeDecision, createProject, linkEntity, supersedeDecision,
#            updateProject, updateTask
case "$TOOL_NAME" in
  mcp__obsidian-tracker__findProjectByLocalPath \
  | mcp__obsidian-tracker__getConfig \
  | mcp__obsidian-tracker__getDecision \
  | mcp__obsidian-tracker__getProject \
  | mcp__obsidian-tracker__getResumeContext \
  | mcp__obsidian-tracker__initVault \
  | mcp__obsidian-tracker__listDecisions \
  | mcp__obsidian-tracker__listProjects \
  | mcp__obsidian-tracker__listTasks \
  | mcp__obsidian-tracker__search \
  | mcp__obsidian-tracker__addBug \
  | mcp__obsidian-tracker__addDecision \
  | mcp__obsidian-tracker__addSession \
  | mcp__obsidian-tracker__addSessionSummary \
  | mcp__obsidian-tracker__addTask \
  | mcp__obsidian-tracker__archiveProject \
  | mcp__obsidian-tracker__closeBug \
  | mcp__obsidian-tracker__closeDecision \
  | mcp__obsidian-tracker__createProject \
  | mcp__obsidian-tracker__linkEntity \
  | mcp__obsidian-tracker__supersedeDecision \
  | mcp__obsidian-tracker__updateProject \
  | mcp__obsidian-tracker__updateTask)
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Auto-allowed by obsidian-tracker plugin (non-destructive operation)"
  }
}
EOF
    exit 0
    ;;
esac

# Not in our list — fall through to default permission flow.
echo '{}'
exit 0
