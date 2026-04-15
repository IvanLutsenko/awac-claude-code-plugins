#!/usr/bin/env bats
# Tests for plugin.json validity, hook registration, and command files

setup() {
  PLUGIN_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  PLUGIN_JSON="${PLUGIN_ROOT}/.claude-plugin/plugin.json"
}

# --- plugin.json validity ---

@test "plugin.json exists" {
  [ -f "$PLUGIN_JSON" ]
}

@test "plugin.json is valid JSON" {
  jq . "$PLUGIN_JSON" >/dev/null 2>&1
}

@test "plugin.json has required fields" {
  jq -e '.name' "$PLUGIN_JSON" >/dev/null
  jq -e '.description' "$PLUGIN_JSON" >/dev/null
  jq -e '.version' "$PLUGIN_JSON" >/dev/null
}

@test "version follows semver" {
  version=$(jq -r '.version' "$PLUGIN_JSON")
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# --- Commands ---

@test "all command files referenced in plugin.json exist" {
  local missing=()
  while IFS= read -r cmd; do
    # Resolve relative to plugin.json's parent's parent (.claude-plugin/../commands/...)
    local full_path="${PLUGIN_ROOT}/${cmd#./}"
    [ -f "$full_path" ] || missing+=("$cmd")
  done < <(jq -r '.commands[]' "$PLUGIN_JSON")

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing command files: ${missing[*]}"
    return 1
  fi
}

@test "command files have YAML frontmatter" {
  while IFS= read -r cmd; do
    local full_path="${PLUGIN_ROOT}/${cmd#./}"
    head -1 "$full_path" | grep -q "^---$" || {
      echo "Missing frontmatter in $cmd"
      return 1
    }
  done < <(jq -r '.commands[]' "$PLUGIN_JSON")
}

@test "command files have description in frontmatter" {
  while IFS= read -r cmd; do
    local full_path="${PLUGIN_ROOT}/${cmd#./}"
    # Extract frontmatter between --- markers
    local fm
    fm=$(sed -n '/^---$/,/^---$/p' "$full_path" | head -20)
    echo "$fm" | grep -q "description:" || {
      echo "Missing description in $cmd"
      return 1
    }
  done < <(jq -r '.commands[]' "$PLUGIN_JSON")
}

# --- Hook scripts ---

@test "all hook scripts referenced in plugin.json exist" {
  local missing=()
  while IFS= read -r script; do
    # Replace ${CLAUDE_PLUGIN_ROOT} with actual plugin root
    local resolved="${script//\$\{CLAUDE_PLUGIN_ROOT\}/$PLUGIN_ROOT}"
    [ -f "$resolved" ] || missing+=("$script")
  done < <(jq -r '.. | objects | .command? // empty' "$PLUGIN_JSON" | grep -v '^$')

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing hook scripts: ${missing[*]}"
    return 1
  fi
}

@test "hook scripts are executable" {
  while IFS= read -r script; do
    local resolved="${script//\$\{CLAUDE_PLUGIN_ROOT\}/$PLUGIN_ROOT}"
    [ -x "$resolved" ] || {
      echo "Not executable: $script"
      return 1
    }
  done < <(jq -r '.. | objects | .command? // empty' "$PLUGIN_JSON" | grep -v '^$')
}

@test "hook events are valid Claude Code events" {
  local valid_events="PreToolUse PostToolUse PostToolUseFailure Notification UserPromptSubmit SessionStart SessionEnd Stop StopFailure SubagentStart SubagentStop PreCompact PostCompact PermissionRequest PermissionDenied"
  while IFS= read -r event; do
    echo "$valid_events" | grep -qw "$event" || {
      echo "Invalid hook event: $event"
      return 1
    }
  done < <(jq -r '.hooks | keys[]' "$PLUGIN_JSON")
}

@test "command hooks have timeout set" {
  local missing=()
  while IFS= read -r entry; do
    local has_timeout
    has_timeout=$(echo "$entry" | jq 'has("timeout")')
    if [ "$has_timeout" = "false" ]; then
      local cmd
      cmd=$(echo "$entry" | jq -r '.command')
      missing+=("$cmd")
    fi
  done < <(jq -c '.. | objects | select(.type == "command") | select(.command != null)' "$PLUGIN_JSON")

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing timeout on: ${missing[*]}"
    return 1
  fi
}

# --- MCP server ---

@test ".mcp.json exists and is valid JSON" {
  local mcp_ref
  mcp_ref=$(jq -r '.mcpServers' "$PLUGIN_JSON")
  local mcp_path="${PLUGIN_ROOT}/${mcp_ref#./}"
  [ -f "$mcp_path" ]
  jq . "$mcp_path" >/dev/null 2>&1
}

@test "MCP entry point exists (compiled)" {
  [ -f "${PLUGIN_ROOT}/mcp/dist/index.js" ]
}

@test "MCP package.json exists" {
  [ -f "${PLUGIN_ROOT}/mcp/package.json" ]
}

# --- Hook output schema compliance ---
# Regression tests for the hookSpecificOutput bug

@test "stop hook does not output hookSpecificOutput" {
  grep -q "hookSpecificOutput" "${PLUGIN_ROOT}/hooks/stop-autotrack.sh" && return 1 || true
}

@test "session hooks do not output hookSpecificOutput" {
  for script in session-startup.sh session-clear.sh session-resume.sh; do
    grep -q "hookSpecificOutput" "${PLUGIN_ROOT}/hooks/$script" && {
      echo "hookSpecificOutput found in $script"
      return 1
    }
  done
  true
}

@test "SessionStart and Stop hooks use systemMessage (not additionalContext)" {
  for script in session-startup.sh session-clear.sh session-resume.sh stop-autotrack.sh; do
    local path="${PLUGIN_ROOT}/hooks/$script"
    # If script has output (not just {}), it should use systemMessage
    if grep -q "jq -n" "$path"; then
      grep -q "systemMessage" "$path" || {
        echo "$script outputs JSON but doesn't use systemMessage"
        return 1
      }
    fi
  done
}
