---
description: "Publish plugin changes: version bump, changelog, README updates, commit + push"
argument-hint: "<plugin_name> [patch|minor|major]"
allowed-tools: Bash(python3:*), Bash(git *:*), Read, Edit
---

# Publish Plugin

Publish plugin after changes: **$ARGUMENTS**

## Step 1: Parse arguments

Extract from `$ARGUMENTS`:
- `plugin_name` (required) — directory name under `plugins/`
- `bump_type` (optional, default: `patch`) — `patch`, `minor`, or `major`

If no arguments provided, detect which plugin was changed:
```yaml
Bash: cd /Users/lutse/projects/awac-claude-code-plugins && git diff --name-only HEAD | grep '^plugins/' | head -1 | cut -d/ -f2
```
If multiple plugins changed, ask user which one to publish.

## Step 2: Run version bump script

```yaml
Bash: cd /Users/lutse/projects/awac-claude-code-plugins && python3 scripts/publish-plugin.py {plugin_name} {bump_type}
```

Parse the YAML output — it shows old/new version and which files were updated.

## Step 3: Generate changelog

Look at what changed since last version:
```yaml
Bash: cd /Users/lutse/projects/awac-claude-code-plugins && git diff HEAD -- plugins/{plugin_name}/
```

Based on the diff, write a changelog entry in `plugins/{plugin_name}/README.md`:
- Find the `## Changelog` or `## Version History` section
- Add a new `### {new_version}` entry BEFORE the previous version
- Use concise bullet points describing what changed
- Prefix breaking changes with `**Breaking:**`

## Step 4: Update root README "What's New"

In the root `README.md`, find the plugin's section and update `**What's New in X.Y.Z:**` with a 1-line summary.

## Step 5: Verify

Check all files are consistent:
```yaml
Bash: cd /Users/lutse/projects/awac-claude-code-plugins && grep -rn "{new_version}" plugins/{plugin_name}/.claude-plugin/plugin.json plugins/{plugin_name}/README.md README.md CLAUDE.md
```

## Step 6: Commit + push

```yaml
Bash: cd /Users/lutse/projects/awac-claude-code-plugins && git add plugins/{plugin_name}/ README.md CLAUDE.md scripts/ && git commit -m "feat({plugin_name}): v{new_version} — {1-line summary}"
Bash: cd /Users/lutse/projects/awac-claude-code-plugins && git push
```
