#!/usr/bin/env bats
# Tests for hooks/session-startup.sh (SessionStart:startup)

load helpers

setup() { setup_tracking_dir; }
teardown() { teardown_tracking_dir; }

@test "no tracking file → empty JSON (tracking starts on first command)" {
  rm -f "$TRACKING_FILE"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-startup.sh")
  assert_valid_json "$result"
  [ "$result" = "{}" ]
}

@test "recent tracking file (<300s) → active session message" {
  create_tracking_file "active-project" "doing stuff"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-startup.sh")
  assert_valid_json "$result"
  msg=$(echo "$result" | jq -r '.systemMessage')
  [[ "$msg" == *"active-project"* ]]
}

@test "stale tracking file (>300s) → orphan recovery" {
  # Create tracking file with old timestamp (10 minutes ago)
  if command -v gdate &>/dev/null; then
    OLD_TS=$(gdate -d "10 minutes ago" -u +%Y-%m-%dT%H:%M:%SZ)
  else
    OLD_TS=$(date -u -v-10M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
  fi
  create_tracking_file "stale-project" "old goal" "$OLD_TS"

  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-startup.sh")
  assert_valid_json "$result"
  msg=$(echo "$result" | jq -r '.systemMessage')
  [[ "$msg" == *"Orphan session"* ]]
  [[ "$msg" == *"stale-project"* ]]
}

@test "no hookSpecificOutput in any path" {
  # Test no-file path
  rm -f "$TRACKING_FILE"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-startup.sh")
  has_hso=$(echo "$result" | jq 'has("hookSpecificOutput")')
  [ "$has_hso" = "false" ]

  # Test active-session path
  create_tracking_file
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-startup.sh")
  has_hso=$(echo "$result" | jq 'has("hookSpecificOutput")')
  [ "$has_hso" = "false" ]
}

@test "no tracking file → no systemMessage" {
  rm -f "$TRACKING_FILE"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-startup.sh")
  [ "$result" = "{}" ]
}
