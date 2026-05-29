# Claude Code → Codex Mapping

## Manifest

| Claude Code | Codex | Notes |
|---|---|---|
| `.claude-plugin/plugin.json` | `.codex-plugin/plugin.json` | Different schemas; no hooks in Codex |
| `name`, `version`, `description` | same | Direct copy |
| `author.name` | `author.name` | Only `name` field in Codex |
| `hooks` | — | No equivalent; warn |
| `commands` array | — | Commands become skills |
| `agents` array | — | Not supported; warn |
| `mcpServers` | `.mcp.json` | Same format |

## Components

| Claude Code | Codex | Conversion |
|---|---|---|
| `.mcp.json` | `.mcp.json` | Copy as-is |
| `skills/<name>/SKILL.md` | `skills/<name>/SKILL.md` | Shared directory, no conversion needed |
| `commands/<name>.md` | `skills/generated-from-commands/<name>/SKILL.md` | Automated via script |
| `agents/<name>.md` | — | Manual; no auto-conversion |
| `hooks/*` | — | Manual; no Codex equivalent |

## Field mapping: CC command → Codex skill

| CC command frontmatter | Codex SKILL.md frontmatter | Notes |
|---|---|---|
| `description` | `description` | Appended with trigger hint |
| `argument-hint` | — | Not used in Codex |
| `allowed-tools` | — | Removed; Codex uses `capabilities` in manifest |
| body (markdown) | body | Preserved with "Converted from" header |

## Codex manifest fields

```json
{
  "name": "plugin-name",
  "version": "0.1.0",
  "description": "...",
  "author": { "name": "..." },
  "skills": "./skills/",
  "interface": {
    "displayName": "...",
    "shortDescription": "...",
    "developerName": "...",
    "category": "Development",
    "capabilities": ["Read", "Write"]
  }
}
```

`capabilities` allowed values: `Read`, `Write`, `Execute`, `Network`.

## Known limitations

- **Hooks**: SessionStart, PostToolUse, PreCompact, Stop, etc. have no Codex equivalent. Functionality must be reimplemented as GitHub Actions or skill side-effects.
- **Agents**: Codex does not support a separate `agents/` concept. Multi-agent workflows must be inlined into skills.
- **allowed-tools**: CC's per-command tool allowlist has no Codex analog. Codex uses manifest-level `capabilities`.
- **MCP tool names**: Same `.mcp.json` format works, but tool IDs may differ between environments. Review generated skills for `mcp__*` references.
- **`${CLAUDE_PLUGIN_ROOT}`**: This CC variable is not available in Codex. Scripts referenced via this variable need path adjustment.
