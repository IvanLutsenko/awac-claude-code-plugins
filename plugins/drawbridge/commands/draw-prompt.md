---
description: Craft a target-tuned prompt and put it in clipboard. Does NOT open the browser.
argument-hint: "[-t gemini|chatgpt|grok|midjourney] <brief>"
allowed-tools: Bash(source:*), Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(bash:*), Bash(pbcopy:*), Bash(printf:*), Bash(cat:*), Bash(tail:*), Bash(python3:*), Bash(awk:*), Bash(date:*), Bash(mkdir:*), Bash(wc:*), Bash(mv:*), Skill, Read
---

# /draw-prompt — prompt only, no browser

Same flow as `/draw` but skip the `db_open_url` step. Useful when:
- the target tab is already open and focused
- the user wants to inspect the prompt before deciding which tool to use
- generating multiple variants for A/B comparison

## Steps

1. Parse `$ARGUMENTS` exactly like `/draw`.
2. Resolve target + translate flag (`db_default_target`, `db_translate_enabled`).
3. Invoke `prompt-crafting` skill.
4. `pbcopy` the prompt + `db_history_append`.
5. Report:
   ```
   target: <target>
   prompt copied to clipboard.
   ```
   followed by the prompt in a fenced block.
