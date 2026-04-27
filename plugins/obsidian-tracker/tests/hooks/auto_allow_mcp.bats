#!/usr/bin/env bats
# Tests for hooks/auto-allow-mcp.sh (PermissionRequest)

load helpers

permission_input() {
  local tool_name="$1"
  jq -n --arg tn "$tool_name" '{tool_name: $tn}'
}

@test "read-only tool (getResumeContext) → allow" {
  result=$(permission_input "mcp__obsidian-tracker__getResumeContext" | "$HOOKS_DIR/auto-allow-mcp.sh")
  assert_valid_json "$result"
  assert_json_field "$result" ".hookSpecificOutput.hookEventName" "PermissionRequest"
  assert_json_field "$result" ".hookSpecificOutput.permissionDecision" "allow"
}

@test "read-only tool (listProjects) → allow" {
  result=$(permission_input "mcp__obsidian-tracker__listProjects" | "$HOOKS_DIR/auto-allow-mcp.sh")
  assert_json_field "$result" ".hookSpecificOutput.permissionDecision" "allow"
}

@test "read-only tool (search) → allow" {
  result=$(permission_input "mcp__obsidian-tracker__search" | "$HOOKS_DIR/auto-allow-mcp.sh")
  assert_json_field "$result" ".hookSpecificOutput.permissionDecision" "allow"
}

@test "mutating tool (addTask) → allow" {
  result=$(permission_input "mcp__obsidian-tracker__addTask" | "$HOOKS_DIR/auto-allow-mcp.sh")
  assert_json_field "$result" ".hookSpecificOutput.permissionDecision" "allow"
}

@test "mutating tool (createProject) → allow" {
  result=$(permission_input "mcp__obsidian-tracker__createProject" | "$HOOKS_DIR/auto-allow-mcp.sh")
  assert_json_field "$result" ".hookSpecificOutput.permissionDecision" "allow"
}

@test "mutating tool (linkEntity) → allow" {
  result=$(permission_input "mcp__obsidian-tracker__linkEntity" | "$HOOKS_DIR/auto-allow-mcp.sh")
  assert_json_field "$result" ".hookSpecificOutput.permissionDecision" "allow"
}

@test "destructive tool (deleteProject) → fall-through (no decision)" {
  result=$(permission_input "mcp__obsidian-tracker__deleteProject" | "$HOOKS_DIR/auto-allow-mcp.sh")
  [ "$result" = "{}" ]
}

@test "destructive tool (deleteTask) → fall-through (no decision)" {
  result=$(permission_input "mcp__obsidian-tracker__deleteTask" | "$HOOKS_DIR/auto-allow-mcp.sh")
  [ "$result" = "{}" ]
}

@test "destructive tool (restoreProject) → fall-through (no decision)" {
  result=$(permission_input "mcp__obsidian-tracker__restoreProject" | "$HOOKS_DIR/auto-allow-mcp.sh")
  [ "$result" = "{}" ]
}

@test "unrelated tool (Bash) → fall-through" {
  result=$(permission_input "Bash" | "$HOOKS_DIR/auto-allow-mcp.sh")
  [ "$result" = "{}" ]
}

@test "different MCP server (mcp__bereke-jira__jira_search) → fall-through" {
  result=$(permission_input "mcp__bereke-jira__jira_search" | "$HOOKS_DIR/auto-allow-mcp.sh")
  [ "$result" = "{}" ]
}

@test "empty tool_name → fall-through" {
  result=$(echo '{}' | "$HOOKS_DIR/auto-allow-mcp.sh")
  [ "$result" = "{}" ]
}

@test "malformed input (not JSON) → does not crash, returns fall-through" {
  result=$(echo 'not json' | "$HOOKS_DIR/auto-allow-mcp.sh" 2>/dev/null)
  [ "$result" = "{}" ]
}

@test "exit code is 0 for both allow and fall-through" {
  permission_input "mcp__obsidian-tracker__addTask" | "$HOOKS_DIR/auto-allow-mcp.sh" >/dev/null
  [ "$?" -eq 0 ]
  permission_input "mcp__obsidian-tracker__deleteProject" | "$HOOKS_DIR/auto-allow-mcp.sh" >/dev/null
  [ "$?" -eq 0 ]
}
