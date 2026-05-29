# Continuous Mode: Keeping Dual-Target in Sync

## Philosophy

- **Claude Code is source of truth** — never edit Codex-generated files directly unless you mark them `manually_maintained`.
- **Generated files are regenerated** on each converter run; manual edits are overwritten.
- **CI enforces sync** — if the converter produces diffs, the PR is blocked.

## GitHub Actions Example

```yaml
# .github/workflows/codex-sync.yml
name: Codex Sync

on:
  push:
    paths:
      - 'plugins/**/commands/**'
      - 'plugins/**/skills/**'
      - 'plugins/**/.claude-plugin/plugin.json'

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run converter for changed plugins
        run: |
          # Detect which plugins changed
          CHANGED=$(git diff --name-only HEAD~1 HEAD | grep '^plugins/' | cut -d/ -f1,2 | sort -u)
          for PLUGIN in $CHANGED; do
            echo "Syncing $PLUGIN"
            python3 scripts/convert_cc_to_codex.py "$PLUGIN" --repo-root . --strict
          done

      - name: Check for uncommitted changes
        run: |
          if [ -n "$(git status --porcelain)" ]; then
            echo "Codex files are out of sync. Run the converter locally:"
            echo "  python3 scripts/convert_cc_to_codex.py <plugin-path> --repo-root ."
            git diff
            exit 1
          fi
```

## Pre-commit Hook Example

```bash
#!/bin/bash
# .git/hooks/pre-commit
# Convert changed plugins before commit

CHANGED_PLUGINS=$(git diff --cached --name-only | grep '^plugins/' | cut -d/ -f1,2 | sort -u)

for PLUGIN in $CHANGED_PLUGINS; do
  if [ -f "$PLUGIN/.claude-plugin/plugin.json" ]; then
    echo "plugin-cross-port: syncing $PLUGIN"
    python3 scripts/convert_cc_to_codex.py "$PLUGIN" --repo-root . --force
    # Stage generated files
    git add "$PLUGIN/.codex-plugin/" "$PLUGIN/skills/generated-from-commands/" "$PLUGIN/.plugin-cross-port.yaml"
    git add ".agents/plugins/marketplace.json"
  fi
done
```

Install:
```bash
cp plugins/plugin-cross-port/references/continuous-mode.md /dev/null  # example only
chmod +x .git/hooks/pre-commit
```

## Local workflow

```bash
# After editing a plugin's commands
python3 scripts/convert_cc_to_codex.py plugins/obsidian-tracker --repo-root .

# Dry run to preview changes
python3 scripts/convert_cc_to_codex.py plugins/obsidian-tracker --repo-root . --dry-run

# Force overwrite including manually_maintained files
python3 scripts/convert_cc_to_codex.py plugins/obsidian-tracker --repo-root . --force

# Strict: fail if agents/hooks are unresolved in .plugin-cross-port.yaml
python3 scripts/convert_cc_to_codex.py plugins/obsidian-tracker --repo-root . --strict
```

## What triggers a re-sync

| Change | Re-sync needed? |
|---|---|
| Edit `commands/*.md` | Yes — regenerates corresponding skill |
| Add new command | Yes — creates new generated skill |
| Delete command | Yes — removes generated skill |
| Edit `skills/<name>/SKILL.md` | No — shared file, no generation |
| Edit `.claude-plugin/plugin.json` | Yes — version synced to Codex manifest |
| Edit `agents/*.md` | Warning only — manual action required |
| Edit hooks in `plugin.json` | Warning only — no Codex equivalent |

## Marking a generated file as manually maintained

After customizing a generated skill beyond what the converter produces:

```yaml
# plugins/my-plugin/.plugin-cross-port.yaml
manually_maintained:
  - skills/generated-from-commands/my-command/SKILL.md
```

The converter will skip this file on subsequent runs and emit a reminder notice instead.
