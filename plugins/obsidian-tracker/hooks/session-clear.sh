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
  "systemMessage": "Session clear: read .claude/obsidian-tracking.json. Before saving, review your actions this session — add meaningful 1-line summaries to the actions array, call addBug/addDecision MCP if relevant. Then call addSession + addSessionSummary MCP, delete the file. Notify user briefly."
}'
