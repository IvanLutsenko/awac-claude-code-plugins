#!/bin/bash
# SessionStart:compact|resume — remind about active tracking
# Command-type hook: never errors even if MCP is unavailable

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

TRACKING_FILE="${CWD}/.claude/obsidian-tracking.json"

if [ ! -f "$TRACKING_FILE" ]; then
  echo '{}'
  exit 0
fi

PROJECT=$(jq -r '.project // "unknown"' "$TRACKING_FILE" 2>/dev/null)
GOAL=$(jq -r '.goal // ""' "$TRACKING_FILE" 2>/dev/null)

jq -n --arg project "$PROJECT" --arg goal "$GOAL" '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ("Obsidian Tracking active: " + $project + (if $goal != "" then " — " + $goal else "" end))
  }
}'
