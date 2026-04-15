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
    # Orphaned session — prompt to save and restart
    TRACKING_DATA=$(jq -c . "$TRACKING_FILE" 2>/dev/null || echo '{}')
    jq -n --arg data "$TRACKING_DATA" --arg cwd "$CWD" --arg project "$PROJECT" '{
      "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": ("OBSIDIAN ORPHAN RECOVERY: Found stale tracking file from previous session. Data: " + $data + ". Please: 1) Call addSession MCP tool with project=" + $project + ", goal and actions from data, results=\"Auto-saved: session recovered from previous terminal close\". 2) Delete .claude/obsidian-tracking.json. 3) Then call findProjectByLocalPath with localPath=" + $cwd + " to auto-detect project for new session. If found, create new .claude/obsidian-tracking.json via Bash: mkdir -p .claude && echo {project,goal,startedAt,actions} > .claude/obsidian-tracking.json. 4) Briefly notify user about recovered session.")
      }
    }'
  else
    # Active session (recent) — just remind
    jq -n --arg project "$PROJECT" '{
      "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": ("Obsidian Tracking already active: " + $project)
      }
    }'
  fi
  exit 0
fi

# Phase B: No tracking file — auto-detect project via findProjectByLocalPath
jq -n --arg cwd "$CWD" '{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ("Auto-detect Obsidian project: Call findProjectByLocalPath MCP tool with localPath=" + $cwd + ". If found (found=true), pick the non-subproject match (or first match). Create .claude/obsidian-tracking.json via Bash: mkdir -p .claude && echo {\"project\":\"NAME\",\"goal\":\"\",\"startedAt\":\"ISO_TIMESTAMP\",\"actions\":[]} > .claude/obsidian-tracking.json. Briefly notify user. If MCP unavailable or no match, do nothing silently.")
  }
}'
