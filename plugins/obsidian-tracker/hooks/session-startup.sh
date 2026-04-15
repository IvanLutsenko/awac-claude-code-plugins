#!/bin/bash
# SessionStart:startup — orphan recovery + auto-detect project
# Command-type hook: never errors even if MCP is unavailable

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

TRACKING_FILE="${CWD}/.claude/obsidian-tracking.json"

# Phase A: Check for orphaned session from previous terminal close
if [ -f "$TRACKING_FILE" ]; then
  STARTED_AT=$(jq -r '.startedAt // ""' "$TRACKING_FILE" 2>/dev/null)
  PROJECT=$(jq -r '.project // "unknown"' "$TRACKING_FILE" 2>/dev/null)

  IS_STALE=false
  if [ -n "$STARTED_AT" ]; then
    # Calculate age in seconds
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
    # Orphaned session — save data to temp file, short prompt
    ORPHAN_FILE="${CWD}/.claude/obsidian-orphan.json"
    cp "$TRACKING_FILE" "$ORPHAN_FILE" 2>/dev/null
    jq -n --arg project "$PROJECT" --arg cwd "$CWD" '{
      "systemMessage": ("Orphan session [" + $project + "]: recover from .claude/obsidian-orphan.json — call addSession MCP, delete both files, auto-detect new project via findProjectByLocalPath(" + $cwd + "). Notify user briefly.")
    }'
  else
    # Active session (recent) — just remind
    jq -n --arg project "$PROJECT" '{
      "systemMessage": ("Obsidian Tracking already active: " + $project)
    }'
  fi
  exit 0
fi

# Phase B: No tracking file — auto-detect project via findProjectByLocalPath
jq -n --arg cwd "$CWD" '{
  "systemMessage": ("Auto-detect project: findProjectByLocalPath(" + $cwd + "). If found, create .claude/obsidian-tracking.json and notify user. If not — silent.")
}'
