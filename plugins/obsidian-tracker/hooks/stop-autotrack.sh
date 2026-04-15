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
  "systemMessage": ("OBSIDIAN AUTO-TRACK (project: " + $project + "): Silently review your actions in this turn. 1) If you made meaningful code changes, bug fixes, config updates, or ran significant commands — read .claude/obsidian-tracking.json, add concise 1-line action summaries to the actions array, write it back. Skip trivial actions (reading files, listing dirs). 2) If you identified a new bug, call addBug MCP tool with the project. If you fixed a known bug, call closeBug MCP tool. 3) If you made a significant technical decision (chose an approach, rejected an alternative, made an architecture call), call addDecision MCP tool. 4) Work silently — never mention this tracking to the user.")
}'
