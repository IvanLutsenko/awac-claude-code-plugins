#!/usr/bin/env bats
# Tests for hooks/session-clear.sh (SessionStart:clear)

load helpers

setup() { setup_tracking_dir; }
teardown() { teardown_tracking_dir; }

@test "no tracking file → empty JSON" {
  rm -f "$TRACKING_FILE"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-clear.sh")
  assert_valid_json "$result"
  [ "$result" = "{}" ]
}

@test "tracking file exists → returns systemMessage with save instructions" {
  create_tracking_file "save-me"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-clear.sh")
  assert_valid_json "$result"
  assert_json_has "$result" '.systemMessage'
  msg=$(echo "$result" | jq -r '.systemMessage')
  [[ "$msg" == *"OBSIDIAN SESSION SAVE"* ]]
  [[ "$msg" == *"addSession"* ]]
  [[ "$msg" == *"addSessionSummary"* ]]
}

@test "systemMessage contains tracking data" {
  create_tracking_file "data-project" "my-goal"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-clear.sh")
  msg=$(echo "$result" | jq -r '.systemMessage')
  [[ "$msg" == *"data-project"* ]]
  [[ "$msg" == *"my-goal"* ]]
}

@test "no hookSpecificOutput" {
  create_tracking_file
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-clear.sh")
  has_hso=$(echo "$result" | jq 'has("hookSpecificOutput")')
  [ "$has_hso" = "false" ]
}
