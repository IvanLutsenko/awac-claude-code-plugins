#!/usr/bin/env bats
# Tests for hooks/stop-autotrack.sh (Stop hook)

load helpers

setup() { setup_tracking_dir; }
teardown() { teardown_tracking_dir; }

@test "no tracking file → empty JSON" {
  rm -f "$TRACKING_FILE"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/stop-autotrack.sh")
  assert_valid_json "$result"
  [ "$result" = "{}" ]
}

@test "tracking file exists → returns systemMessage" {
  create_tracking_file "my-project"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/stop-autotrack.sh")
  assert_valid_json "$result"
  assert_json_has "$result" '.systemMessage'
}

@test "systemMessage contains project name" {
  create_tracking_file "bereke-business"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/stop-autotrack.sh")
  msg=$(echo "$result" | jq -r '.systemMessage')
  [[ "$msg" == *"bereke-business"* ]]
}

@test "systemMessage contains tracking instructions" {
  create_tracking_file
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/stop-autotrack.sh")
  msg=$(echo "$result" | jq -r '.systemMessage')
  [[ "$msg" == *"OBSIDIAN AUTO-TRACK"* ]]
  [[ "$msg" == *"obsidian-tracking.json"* ]]
  [[ "$msg" == *"addBug"* ]]
  [[ "$msg" == *"addDecision"* ]]
}

@test "does NOT use hookSpecificOutput (was the bug)" {
  create_tracking_file
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/stop-autotrack.sh")
  has_hso=$(echo "$result" | jq 'has("hookSpecificOutput")')
  [ "$has_hso" = "false" ]
}

@test "output has no additionalContext at root level" {
  create_tracking_file
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/stop-autotrack.sh")
  has_ac=$(echo "$result" | jq 'has("additionalContext")')
  [ "$has_ac" = "false" ]
}
