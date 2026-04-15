#!/bin/bash
# SessionStart:clear — save tracking session before clearing
# Command-type hook: never errors even if MCP is unavailable

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

TRACKING_FILE="${CWD}/.claude/obsidian-tracking.json"

if [ ! -f "$TRACKING_FILE" ]; then
  echo '{}'
  exit 0
fi

jq -n '{
  "systemMessage": "Session clear: read .claude/obsidian-tracking.json, call addSession + addSessionSummary MCP, delete the file. Notify user."
}'
