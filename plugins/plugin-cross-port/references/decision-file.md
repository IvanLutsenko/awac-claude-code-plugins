# Decision File Format: `.plugin-cross-port.yaml`

Each attached plugin gets a `.plugin-cross-port.yaml` at its root. This file
records the plugin-level source of truth and generated files that have been
manually customized. Repository-level marketplace state lives in
`.plugin-cross-port.marketplace.yaml`.

## Schema

```yaml
version: 2
plugin: plugin-name
source_of_truth: claude-code
status: synced

# Files the converter must NOT overwrite (manually maintained)
manually_maintained:
  - skills/generated-from-commands/my-command/SKILL.md
  - .codex-plugin/plugin.json
```

## Fields

**`version`** — schema version. Attached plugins use `2`; legacy version `1`
files remain readable.

**`plugin`** — plugin name, matches `.claude-plugin/plugin.json`.

**`source_of_truth`** — `claude-code` or `codex`. Direction is never inferred
from changed files.

**`status`** — `synced`, `needs-review`, or `failed`.

**`manually_maintained`** — list of relative paths (from plugin root). The converter skips overwriting these. Add a path here after manually editing a generated file you want to preserve.

## Repository Marketplace State

```json
{
  "version": 1,
  "source_of_truth": "claude-code",
  "source_marketplace": ".claude-plugin/marketplace.json",
  "targets": {
    "codex": ".agents/plugins/marketplace.json"
  },
  "plugins": {
    "plugin-name": {
      "path": "plugins/plugin-name",
      "source_of_truth": "claude-code",
      "status": "synced"
    }
  }
}
```

The marketplace source owns root metadata, active plugin set, ordering, and
plugin directory removal. Plugin state owns conversion direction.

## Example: obsidian-tracker after conversion

```yaml
version: 2
plugin: obsidian-tracker
source_of_truth: claude-code
status: synced
manually_maintained: []
```
