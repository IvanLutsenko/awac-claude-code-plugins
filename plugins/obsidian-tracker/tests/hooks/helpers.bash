#!/bin/bash
# Shared test helpers for hook bats tests

# BATS_TEST_DIRNAME is set by bats to the directory containing the .bats file
PLUGIN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOKS_DIR="${PLUGIN_ROOT}/hooks"
SCRIPTS_DIR="${PLUGIN_ROOT}/scripts"

setup_tracking_dir() {
  TEST_DIR="$(mktemp -d)"
  TRACKING_DIR="${TEST_DIR}/.claude"
  TRACKING_FILE="${TRACKING_DIR}/obsidian-tracking.json"
  mkdir -p "$TRACKING_DIR"
}

teardown_tracking_dir() {
  [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# Create a tracking file with given content or default
create_tracking_file() {
  local project="${1:-test-project}"
  local goal="${2-test goal}"
  local started_at="${3:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
  cat > "$TRACKING_FILE" <<EOF
{
  "project": "$project",
  "goal": "$goal",
  "actions": [],
  "startedAt": "$started_at"
}
EOF
}

# Create a tracking file with pre-existing actions
create_tracking_file_with_actions() {
  local project="${1:-test-project}"
  cat > "$TRACKING_FILE" <<EOF
{
  "project": "$project",
  "goal": "test goal",
  "actions": ["✏️ existing.kt"],
  "startedAt": "2026-01-01T00:00:00Z"
}
EOF
}

# Build hook stdin JSON with cwd
hook_input() {
  local cwd="${1:-$TEST_DIR}"
  echo "{\"cwd\":\"$cwd\"}"
}

# Build PostToolUse stdin JSON for Edit/Write
tool_input_edit() {
  local cwd="${1:-$TEST_DIR}"
  local file_path="$2"
  local tool_name="${3:-Edit}"
  jq -n --arg cwd "$cwd" --arg fp "$file_path" --arg tn "$tool_name" \
    '{cwd: $cwd, tool_input: {file_path: $fp}, tool_name: $tn}'
}

# Build PostToolUse stdin JSON for Bash (git commit)
tool_input_bash() {
  local cwd="${1:-$TEST_DIR}"
  local command="$2"
  local stdout="$3"
  jq -n --arg cwd "$cwd" --arg cmd "$command" --arg out "$stdout" \
    '{cwd: $cwd, tool_input: {command: $cmd}, tool_output: {stdout: $out}}'
}

# Assert output is valid JSON
assert_valid_json() {
  echo "$1" | jq . >/dev/null 2>&1 || {
    echo "Invalid JSON: $1"
    return 1
  }
}

# Assert JSON field equals value
assert_json_field() {
  local json="$1"
  local field="$2"
  local expected="$3"
  local actual
  actual=$(echo "$json" | jq -r "$field")
  [ "$actual" = "$expected" ] || {
    echo "Expected $field = '$expected', got '$actual'"
    return 1
  }
}

# Assert JSON field exists (not null)
assert_json_has() {
  local json="$1"
  local field="$2"
  local val
  val=$(echo "$json" | jq -r "$field")
  [ "$val" != "null" ] && [ -n "$val" ] || {
    echo "Expected $field to exist, got null/empty"
    return 1
  }
}
