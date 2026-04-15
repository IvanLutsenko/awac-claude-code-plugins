#!/usr/bin/env bats
# Tests for hooks/track-action.sh (PostToolUse:Edit|Write)

load helpers

setup() { setup_tracking_dir; }
teardown() { teardown_tracking_dir; }

@test "no tracking file → empty JSON, exit 0" {
  rm -f "$TRACKING_FILE"
  result=$(hook_input "$TEST_DIR" | "$HOOKS_DIR/track-action.sh")
  assert_valid_json "$result"
  [ "$result" = "{}" ]
}

@test "Edit tool → adds ✏️ action" {
  create_tracking_file
  result=$(tool_input_edit "$TEST_DIR" "/path/to/MyFile.kt" "Edit" | "$HOOKS_DIR/track-action.sh")
  [ "$result" = "{}" ]

  actions=$(jq -r '.actions[0]' "$TRACKING_FILE")
  [[ "$actions" == *"✏️"* ]]
  [[ "$actions" == *"MyFile.kt"* ]]
}

@test "Write tool → adds 📝 action" {
  create_tracking_file
  result=$(tool_input_edit "$TEST_DIR" "/path/to/NewFile.kt" "Write" | "$HOOKS_DIR/track-action.sh")
  [ "$result" = "{}" ]

  actions=$(jq -r '.actions[0]' "$TRACKING_FILE")
  [[ "$actions" == *"📝"* ]]
  [[ "$actions" == *"NewFile.kt"* ]]
}

@test "deduplication — same filename not added twice" {
  create_tracking_file_with_actions
  # existing.kt already in actions
  result=$(tool_input_edit "$TEST_DIR" "/some/path/existing.kt" "Edit" | "$HOOKS_DIR/track-action.sh")
  [ "$result" = "{}" ]

  count=$(jq '.actions | length' "$TRACKING_FILE")
  [ "$count" -eq 1 ]
}

@test "different filenames are both added" {
  create_tracking_file
  tool_input_edit "$TEST_DIR" "/path/to/A.kt" "Edit" | "$HOOKS_DIR/track-action.sh" >/dev/null
  tool_input_edit "$TEST_DIR" "/path/to/B.kt" "Edit" | "$HOOKS_DIR/track-action.sh" >/dev/null

  count=$(jq '.actions | length' "$TRACKING_FILE")
  [ "$count" -eq 2 ]
}

@test "empty file_path → skip, empty JSON" {
  create_tracking_file
  result=$(jq -n --arg cwd "$TEST_DIR" '{cwd: $cwd, tool_input: {file_path: ""}, tool_name: "Edit"}' | "$HOOKS_DIR/track-action.sh")
  [ "$result" = "{}" ]

  count=$(jq '.actions | length' "$TRACKING_FILE")
  [ "$count" -eq 0 ]
}

@test "tracking file itself is never tracked" {
  create_tracking_file
  result=$(tool_input_edit "$TEST_DIR" "${TEST_DIR}/.claude/obsidian-tracking.json" "Write" | "$HOOKS_DIR/track-action.sh")
  [ "$result" = "{}" ]

  count=$(jq '.actions | length' "$TRACKING_FILE")
  [ "$count" -eq 0 ]
}

@test "extracts basename from deep path" {
  create_tracking_file
  tool_input_edit "$TEST_DIR" "/very/deep/nested/path/to/Feature.kt" "Edit" | "$HOOKS_DIR/track-action.sh" >/dev/null

  action=$(jq -r '.actions[0]' "$TRACKING_FILE")
  [[ "$action" == *"Feature.kt"* ]]
  # Should NOT contain the full path
  [[ "$action" != *"/very/deep"* ]]
}
