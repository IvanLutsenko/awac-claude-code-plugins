#!/usr/bin/env bats
# Tests for scripts/start-tracking.sh

load helpers

setup() {
  TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
}

teardown() {
  cd /
  [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

@test "creates .claude/obsidian-tracking.json" {
  "$SCRIPTS_DIR/start-tracking.sh" "my-project"
  [ -f ".claude/obsidian-tracking.json" ]
}

@test "JSON has correct project name" {
  "$SCRIPTS_DIR/start-tracking.sh" "my-project"
  project=$(jq -r '.project' .claude/obsidian-tracking.json)
  [ "$project" = "my-project" ]
}

@test "goal is set when provided" {
  "$SCRIPTS_DIR/start-tracking.sh" "proj" "fix stuff"
  goal=$(jq -r '.goal' .claude/obsidian-tracking.json)
  [ "$goal" = "fix stuff" ]
}

@test "empty goal when not provided" {
  "$SCRIPTS_DIR/start-tracking.sh" "proj"
  goal=$(jq -r '.goal' .claude/obsidian-tracking.json)
  [ "$goal" = "" ]
}

@test "startedAt is a valid ISO timestamp" {
  "$SCRIPTS_DIR/start-tracking.sh" "proj"
  ts=$(jq -r '.startedAt' .claude/obsidian-tracking.json)
  # Should match ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ
  [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "actions array is empty by default" {
  "$SCRIPTS_DIR/start-tracking.sh" "proj"
  count=$(jq '.actions | length' .claude/obsidian-tracking.json)
  [ "$count" -eq 0 ]
}

@test "actions are passed as extra arguments" {
  "$SCRIPTS_DIR/start-tracking.sh" "proj" "goal" "action1" "action2"
  count=$(jq '.actions | length' .claude/obsidian-tracking.json)
  [ "$count" -eq 2 ]
  first=$(jq -r '.actions[0]' .claude/obsidian-tracking.json)
  [ "$first" = "action1" ]
}

@test "output contains tracking started message" {
  result=$("$SCRIPTS_DIR/start-tracking.sh" "proj" "goal")
  [[ "$result" == *"Tracking started"* ]]
  [[ "$result" == *"proj"* ]]
}

@test "no argument → exits with error" {
  run "$SCRIPTS_DIR/start-tracking.sh"
  [ "$status" -ne 0 ]
}

@test "project with spaces in name" {
  "$SCRIPTS_DIR/start-tracking.sh" "my project" "some goal"
  project=$(jq -r '.project' .claude/obsidian-tracking.json)
  [ "$project" = "my project" ]
}
