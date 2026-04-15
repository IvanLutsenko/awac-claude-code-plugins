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

# Semantic review moved to /track-stop and SessionStart:clear.
# Stop hook is now silent — mechanical tracking handled by PostToolUse hooks.
echo '{}'
