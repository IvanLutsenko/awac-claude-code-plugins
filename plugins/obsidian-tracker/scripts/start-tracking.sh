#!/bin/bash
# Start tracking for a project
# Usage: start-tracking.sh <project-name> [goal] [actions...]
#
# Creates .claude/obsidian-tracking.json with ISO timestamp

PROJECT="${1:?Usage: start-tracking.sh <project-name> [goal] [actions...]}"
GOAL="${2:-}"
shift 2 2>/dev/null

# Build actions array
ACTIONS="[]"
if [ $# -gt 0 ]; then
  ACTIONS="[$(printf '"%s"' "$1")"
  shift
  for a in "$@"; do
    ACTIONS="$ACTIONS, $(printf '"%s"' "$a")"
  done
  ACTIONS="$ACTIONS]"
fi

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p .claude
cat > .claude/obsidian-tracking.json <<TRACKING
{
  "project": "$PROJECT",
  "goal": "$GOAL",
  "actions": $ACTIONS,
  "startedAt": "$TIMESTAMP"
}
TRACKING

echo "Tracking started: project=$PROJECT, goal=$GOAL, started=$TIMESTAMP"
