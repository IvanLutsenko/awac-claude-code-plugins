#!/bin/bash
# PostToolUse:Edit/Write — auto-capture file changes to tracking
# Command-type: zero LLM overhead, directly updates tracking JSON

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

TRACKING_FILE="${CWD}/.claude/obsidian-tracking.json"

# No tracking → skip
if [ ! -f "$TRACKING_FILE" ]; then
  echo '{}'
  exit 0
fi

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
if [ -z "$FILE_PATH" ]; then
  echo '{}'
  exit 0
fi

# Don't track the tracking file itself
case "$FILE_PATH" in
  *obsidian-tracking.json*) echo '{}'; exit 0 ;;
esac

FILENAME=$(basename "$FILE_PATH")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "Edit"')

# Deduplicate: skip if this filename already in actions
if jq -e --arg f "$FILENAME" '[.actions[] | select(contains($f))] | length > 0' "$TRACKING_FILE" >/dev/null 2>&1; then
  echo '{}'
  exit 0
fi

# Build action label
if [ "$TOOL_NAME" = "Write" ]; then
  ACTION="📝 $FILENAME"
else
  ACTION="✏️ $FILENAME"
fi

# Atomic update
jq --arg a "$ACTION" '.actions += [$a]' "$TRACKING_FILE" > "${TRACKING_FILE}.tmp" 2>/dev/null \
  && mv "${TRACKING_FILE}.tmp" "$TRACKING_FILE" 2>/dev/null

echo '{}'
