#!/usr/bin/env bats
# Tests for hooks/stop-autotrack.sh (Stop hook)
# Stop hook is now silent — always returns {} regardless of tracking state.
# Semantic review moved to /track-stop and SessionStart:clear.

load helpers

setup() { setup_tracking_dir; }
teardown() { teardown_tracking_dir; }

@test "no tracking file → empty JSON" {
  rm -f "$TRACKING_FILE"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/stop-autotrack.sh")
  assert_valid_json "$result"
  [ "$result" = "{}" ]
}

@test "tracking file exists → still empty JSON (silent)" {
  create_tracking_file "my-project"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/stop-autotrack.sh")
  assert_valid_json "$result"
  [ "$result" = "{}" ]
}

@test "no systemMessage in output" {
  create_tracking_file
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/stop-autotrack.sh")
  has_sm=$(echo "$result" | jq 'has("systemMessage")')
  [ "$has_sm" = "false" ]
}

@test "no hookSpecificOutput in output" {
  create_tracking_file
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/stop-autotrack.sh")
  has_hso=$(echo "$result" | jq 'has("hookSpecificOutput")')
  [ "$has_hso" = "false" ]
}
