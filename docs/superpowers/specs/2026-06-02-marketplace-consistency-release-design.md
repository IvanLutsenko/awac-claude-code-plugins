# Marketplace Consistency Release Design

## Goal

Ship one repository-wide maintenance release that fixes confirmed tooling bugs,
removes committed dependency artifacts, and restores consistency across Claude
Code and Codex marketplace metadata.

## Scope

The release covers five bounded changes:

1. Fix `plugin-cross-port` generation behavior:
   - remove stale generated Codex skills when a Claude Code command is deleted;
   - remove stale generated Claude Code commands when a Codex skill is deleted;
   - interpret `manually_maintained` paths relative to the plugin root, matching
     the documented decision-file format.
2. Fix `scripts/publish-plugin.py` so it updates the root Claude Code
   marketplace and, for dual-target plugins, the Codex manifest version.
3. Make `plugins/obsidian-tracker/scripts/start-tracking.sh` generate valid JSON
   for project names, goals, and actions containing quotes or backslashes.
4. Remove tracked `plugins/obsidian-tracker/mcp/node_modules/` files. Keep
   `package-lock.json`; dependency installation remains `npm install`.
5. Normalize repository metadata:
   - add required Codex marketplace root metadata;
   - align stale README and `CLAUDE.md` versions with plugin manifests;
   - align Obsidian MCP package and server versions with the plugin version;
   - document the fixes as one release.

## Architecture

The converters remain deterministic Python scripts with no external runtime
dependencies. Generated-file cleanup is limited to converter-owned output
directories and preserves entries listed in `manually_maintained`.

Release automation remains a single Python script. It updates explicit
repository metadata files instead of broad search-and-replace across unrelated
content.

Obsidian tracking remains a shell entry point, but delegates JSON encoding to
`python3` so shell interpolation cannot corrupt state.

## Tests

Add first-party regression tests:

- `plugins/plugin-cross-port/tests/test_converters.py`
  - stale CC-to-Codex skill cleanup;
  - stale Codex-to-CC command cleanup;
  - plugin-root-relative `manually_maintained` preservation.
- `tests/test_publish_plugin.py`
  - root Claude marketplace update;
  - dual-target Codex manifest update.
- `plugins/obsidian-tracker/tests/hooks/start_tracking.bats`
  - JSON remains valid when values contain quotes and backslashes.

Run existing suites:

- Python unit tests for new regressions;
- Crashlytics validator smoke tests;
- Obsidian Bats suite;
- Obsidian MCP Vitest suite and TypeScript build;
- shell syntax checks, Python AST parse, and JSON parse;
- Codex converter dry-runs.

## Commit Plan

1. `docs: add marketplace consistency release design`
2. `chore(obsidian-tracker): remove tracked node_modules`
3. `fix(plugin-cross-port): preserve decisions and remove stale generated files`
4. `fix(publish): synchronize marketplace and dual-target versions`
5. `fix(obsidian-tracker): encode tracking state as valid json`
6. `chore(release): synchronize marketplace metadata and documentation`

## Non-Goals

- Rewriting plugin command content.
- Migrating the remaining Claude-only plugins to Codex in this release.
- Reorganizing Obsidian MCP implementation files.
- Changing user-level configuration or secrets.
