#!/usr/bin/env bats
# Tests for hooks/session-resume.sh (SessionStart:compact|resume)

load helpers

setup() { setup_tracking_dir; }
teardown() { teardown_tracking_dir; }

@test "no tracking file → empty JSON" {
  rm -f "$TRACKING_FILE"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-resume.sh")
  assert_valid_json "$result"
  [ "$result" = "{}" ]
}

@test "tracking file exists → systemMessage with project name" {
  create_tracking_file "resume-project" "my goal"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-resume.sh")
  assert_valid_json "$result"
  assert_json_has "$result" '.systemMessage'
  msg=$(echo "$result" | jq -r '.systemMessage')
  [[ "$msg" == *"resume-project"* ]]
}

@test "goal is included in systemMessage" {
  create_tracking_file "proj" "fix the auth bug"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-resume.sh")
  msg=$(echo "$result" | jq -r '.systemMessage')
  [[ "$msg" == *"fix the auth bug"* ]]
}

@test "empty goal → no dash separator" {
  create_tracking_file "proj" ""
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-resume.sh")
  msg=$(echo "$result" | jq -r '.systemMessage')
  [[ "$msg" == *"proj"* ]]
  # Should not have trailing " — "
  [[ "$msg" != *" — "* ]]
}

@test "no hookSpecificOutput" {
  create_tracking_file
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/session-resume.sh")
  has_hso=$(echo "$result" | jq 'has("hookSpecificOutput")')
  [ "$has_hso" = "false" ]
}
