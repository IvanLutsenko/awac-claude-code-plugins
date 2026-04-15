#!/bin/bash
# Stop hook — auto-track actions and bugs after each agent turn
# Command-type: if no tracking file, outputs {} (zero overhead)

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

TRACKING_FILE="${CWD}/.claude/obsidian-tracking.json"

if [ ! -f "$TRACKING_FILE" ]; then
  echo '{}'
  exit 0
fi

PROJECT=$(jq -r '.project // "unknown"' "$TRACKING_FILE" 2>/dev/null)

jq -n --arg project "$PROJECT" '{
  "systemMessage": ("Auto-track [" + $project + "]: update .claude/obsidian-tracking.json actions with meaningful changes. Call addBug/closeBug/addDecision MCP if relevant. Silent.")
}'
