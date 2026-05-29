# Decision File Format: `.plugin-cross-port.yaml`

Each converted plugin gets a `.plugin-cross-port.yaml` at its root. This file records conversion decisions, warnings, and which generated files have been manually customized.

## Schema

```yaml
version: 1
plugin: plugin-name
generated_at: "2026-05-29T00:00:00Z"
source_of_truth: claude-code

# What was converted automatically
decisions:
  skills_shared: true          # skills/ is shared; no conversion needed
  commands_converted: true     # commands/ -> skills/generated-from-commands/
  agents_converted: false      # agents/ requires manual conversion
  hooks_converted: false       # hooks have no Codex equivalent

# Conversion warnings from last run
warnings:
  - "agents/code-reviewer.md: not converted — add manually to skills/"
  - "hooks.SessionStart: no Codex equivalent"

# Files the converter must NOT overwrite (manually maintained)
manually_maintained:
  - skills/generated-from-commands/my-command/SKILL.md
  - .codex-plugin/plugin.json
```

## Fields

**`version`** — schema version, always `1` for now.

**`plugin`** — plugin name, matches `.claude-plugin/plugin.json`.

**`generated_at`** — ISO 8601 timestamp of last successful conversion run.

**`source_of_truth`** — always `claude-code`. Reserved for future bidirectional sync.

**`decisions`** — boolean flags recording what was auto-converted.

**`warnings`** — list of strings; updated on each run. Human-readable, no machine parsing expected.

**`manually_maintained`** — list of relative paths (from plugin root). The converter skips overwriting these. Add a path here after manually editing a generated file you want to preserve.

## Updating

The converter updates `generated_at` and `warnings` on every run. It does not modify `manually_maintained` automatically — that's always a human decision.

After a clean run with no warnings, `warnings: []`.

## Example: obsidian-tracker after conversion

```yaml
version: 1
plugin: obsidian-tracker
generated_at: "2026-05-29T10:00:00Z"
source_of_truth: claude-code

decisions:
  skills_shared: false          # obsidian-tracker has no skills/ yet
  commands_converted: true      # 19 commands converted
  agents_converted: false       # no agents/
  hooks_converted: false        # 5 hook types in plugin.json — no Codex equivalent

warnings:
  - "hooks.PermissionRequest: no Codex equivalent"
  - "hooks.PreCompact: no Codex equivalent"
  - "hooks.SessionStart: no Codex equivalent"
  - "hooks.PostToolUse: no Codex equivalent"
  - "hooks.Stop: no Codex equivalent"

manually_maintained: []
```
