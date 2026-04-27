---
description: Re-craft a prompt for the last brief — variation of the same target or a different one.
argument-hint: "[-t gemini|chatgpt|grok|midjourney]"
allowed-tools: Bash(source:*), Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(bash:*), Bash(pbcopy:*), Bash(open:*), Bash(printf:*), Bash(cat:*), Bash(tail:*), Bash(python3:*), Bash(awk:*), Bash(date:*), Bash(mkdir:*), Bash(wc:*), Bash(mv:*), Skill, Read
---

# /redraw — variation of last brief

## Steps

### 1. Read last entry

```bash
source ${CLAUDE_PLUGIN_ROOT}/scripts/lib.sh
LAST=$(db_history_last)
```

If empty — stop and report: `No history yet. Run /draw first.`

Parse `LAST` as JSON to extract `brief` and `target`.

### 2. Resolve effective target

If `$ARGUMENTS` contains `-t <target>`, use that (and validate). Otherwise reuse the last `target`.

### 3. Craft a fresh prompt

Invoke the `prompt-crafting` skill with the same brief and the resolved target. Even if target is the same, produce a noticeably different framing (different angle / lighting / mood) — this is "redraw", not "rerun".

### 4. Copy + log + open

Same as `/draw`:
- `pbcopy` the prompt
- `db_history_append "$TARGET" "$BRIEF" "$PROMPT"`
- `db_open_url "$(db_target_url "$TARGET")"`

### 5. Report

```
target: <target>  (was: <previous target>)
brief: <brief>

prompt copied. opening <url>.
```

Show the new prompt in a fenced block.
