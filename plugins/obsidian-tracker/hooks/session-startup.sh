#!/bin/bash
# SessionStart:startup — auto-detect project and start tracking
# Command-type hook: never errors even if MCP is unavailable

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

TRACKING_FILE="${CWD}/.claude/obsidian-tracking.json"

# Already tracking — just remind
if [ -f "$TRACKING_FILE" ]; then
  PROJECT=$(jq -r '.project // "unknown"' "$TRACKING_FILE" 2>/dev/null)
  jq -n --arg project "$PROJECT" '{
    "hookSpecificOutput": {
      "additionalContext": ("Obsidian Tracking already active: " + $project)
    }
  }'
  exit 0
fi

# No tracking file — ask Claude to try auto-detect via MCP
jq -n --arg cwd "$CWD" '{
  "hookSpecificOutput": {
    "additionalContext": ("Auto-detect Obsidian project: Try calling mcp__plugin_obsidian_tracker_obsidian__listProjects to find a project matching cwd=" + $cwd + ". If project found, create .claude/obsidian-tracking.json with {\"project\":name, \"goal\":\"\", \"actions\":[], \"startedAt\":ISO timestamp} and briefly notify user. If MCP unavailable or no project matches, do nothing silently.")
  }
}'
