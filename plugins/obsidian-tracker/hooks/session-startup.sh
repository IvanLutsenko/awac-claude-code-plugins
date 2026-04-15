#!/bin/bash
# SessionStart:startup — orphan recovery only
# Tracking now starts on first project interaction (commands), not on startup.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

TRACKING_FILE="${CWD}/.claude/obsidian-tracking.json"

# Orphaned session from previous terminal close
if [ -f "$TRACKING_FILE" ]; then
  STARTED_AT=$(jq -r '.startedAt // ""' "$TRACKING_FILE" 2>/dev/null)
  PROJECT=$(jq -r '.project // "unknown"' "$TRACKING_FILE" 2>/dev/null)

  IS_STALE=false
  if [ -n "$STARTED_AT" ]; then
    if command -v gdate &>/dev/null; then
      STARTED_EPOCH=$(gdate -d "$STARTED_AT" +%s 2>/dev/null || echo 0)
    else
      STARTED_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${STARTED_AT%%.*}" +%s 2>/dev/null || echo 0)
    fi
    NOW_EPOCH=$(date +%s)
    AGE=$(( NOW_EPOCH - STARTED_EPOCH ))
    [ "$AGE" -gt 300 ] && IS_STALE=true
  fi

  if [ "$IS_STALE" = true ]; then
    # Orphaned session — save to vault, then clean up
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    echo "{\"cwd\":\"$CWD\"}" | "$SCRIPT_DIR/session-clear.sh" >/dev/null 2>&1
    jq -n --arg project "$PROJECT" '{
      "systemMessage": ("Orphan session [" + $project + "] saved to vault.")
    }'
  else
    # Active session (recent) — confirm
    jq -n --arg project "$PROJECT" '{
      "systemMessage": ("Tracking active: " + $project)
    }'
  fi
  exit 0
fi

# No tracking file — do nothing. Tracking starts on first /where-was-i, /projects, /task, etc.
echo '{}'
