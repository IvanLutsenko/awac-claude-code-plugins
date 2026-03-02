#!/bin/bash
# Sync Claude Code theme with macOS system appearance.
# Runs on every UserPromptSubmit — fast-path exits if theme already matches.

CLAUDE_JSON="$HOME/.claude.json"

if [[ ! -f "$CLAUDE_JSON" ]]; then
  exit 0
fi

# Detect macOS appearance: "Dark" if dark mode, empty/error if light mode
if defaults read -g AppleInterfaceStyle &>/dev/null; then
  TARGET_THEME="dark"
else
  TARGET_THEME="light"
fi

# Read current theme from claude.json (null/missing = default)
CURRENT_THEME=$(python3 -c "
import json, sys
try:
    d = json.load(open('$CLAUDE_JSON'))
    print(d.get('theme') or '')
except:
    print('')
" 2>/dev/null)

# Fast-path: already matches
if [[ "$CURRENT_THEME" == "$TARGET_THEME" ]]; then
  exit 0
fi

# Preserve variant suffix if present (e.g., dark-ansi -> light-ansi)
if [[ "$CURRENT_THEME" == *"-ansi" ]]; then
  TARGET_THEME="${TARGET_THEME}-ansi"
elif [[ "$CURRENT_THEME" == *"-daltonized" ]]; then
  TARGET_THEME="${TARGET_THEME}-daltonized"
fi

# Update theme in claude.json
python3 -c "
import json
path = '$CLAUDE_JSON'
with open(path) as f:
    d = json.load(f)
d['theme'] = '$TARGET_THEME'
with open(path, 'w') as f:
    json.dump(d, f, separators=(',', ':'))
" 2>/dev/null

exit 0
