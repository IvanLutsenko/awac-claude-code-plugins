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

TRACKING_DATA=$(cat "$TRACKING_FILE" | jq -c . 2>/dev/null || echo '{}')

jq -n --arg data "$TRACKING_DATA" '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ("OBSIDIAN SESSION SAVE: .claude/obsidian-tracking.json exists. Data: " + $data + ". Please: 1) Try calling mcp__plugin_obsidian_tracker_obsidian__addSession with project, goal, actions from data, results=Session completed via /clear. If MCP tool is unavailable, warn user that session was not saved to Obsidian. 2) Delete .claude/obsidian-tracking.json regardless. 3) Briefly notify user of the result.")
  }
}'
