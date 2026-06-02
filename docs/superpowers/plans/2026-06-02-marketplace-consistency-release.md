# Marketplace Consistency Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship one maintenance release that fixes cross-port generation, release synchronization, and Obsidian tracking JSON while removing committed dependencies and aligning metadata.

**Architecture:** Keep the existing Python converter and publisher entry points, adding focused helper functions covered by `unittest`. Keep Obsidian tracking as shell, but delegate JSON serialization to Python. Preserve existing plugin layout and release conventions.

**Tech Stack:** Python 3 standard library, Bash, Bats, TypeScript, Vitest, git.

---

### Task 1: Remove Committed Dependencies

**Files:**
- Delete: `plugins/obsidian-tracker/mcp/node_modules/**`

- [ ] **Step 1: Remove tracked dependency files**

Run:
```bash
git rm -r plugins/obsidian-tracker/mcp/node_modules
```

- [ ] **Step 2: Verify package metadata remains**

Run:
```bash
test -f plugins/obsidian-tracker/mcp/package-lock.json
git ls-files plugins/obsidian-tracker/mcp/node_modules | wc -l
```

Expected: `package-lock.json` exists and tracked dependency count is `0`.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(obsidian-tracker): remove tracked node_modules"
```

### Task 2: Fix Plugin Cross-Port Generation

**Files:**
- Create: `plugins/plugin-cross-port/tests/test_converters.py`
- Modify: `plugins/plugin-cross-port/scripts/convert_cc_to_codex.py`
- Modify: `plugins/plugin-cross-port/scripts/convert_codex_to_cc.py`

- [ ] **Step 1: Write failing converter regression tests**

Cover:
```python
def test_cc_to_codex_removes_stale_generated_skill(): ...
def test_cc_to_codex_preserves_plugin_relative_manually_maintained_skill(): ...
def test_codex_to_cc_removes_stale_generated_command(): ...
```

- [ ] **Step 2: Run tests and confirm failures**

Run:
```bash
python3 -m unittest discover -s plugins/plugin-cross-port/tests -v
```

Expected: stale generated files remain and documented relative paths are overwritten.

- [ ] **Step 3: Implement converter cleanup and path normalization**

Add helpers that:
- compare `manually_maintained` against plugin-root-relative paths;
- delete only stale converter-owned files;
- preserve manually maintained stale files;
- report removed files in converter summaries.

- [ ] **Step 4: Run tests and confirm pass**

```bash
python3 -m unittest discover -s plugins/plugin-cross-port/tests -v
```

- [ ] **Step 5: Commit**

```bash
git commit -m "fix(plugin-cross-port): preserve decisions and remove stale generated files"
```

### Task 3: Fix Publish Synchronization

**Files:**
- Create: `tests/test_publish_plugin.py`
- Modify: `scripts/publish-plugin.py`

- [ ] **Step 1: Write failing publisher regression tests**

Cover:
```python
def test_publish_updates_root_claude_marketplace(): ...
def test_publish_updates_codex_manifest_for_dual_target_plugin(): ...
```

- [ ] **Step 2: Run tests and confirm failures**

```bash
python3 -m unittest discover -s tests -v
```

- [ ] **Step 3: Implement explicit metadata updates**

Update:
- `.claude-plugin/marketplace.json`
- `plugins/<name>/.codex-plugin/plugin.json` when present
- existing README and `CLAUDE.md` references

- [ ] **Step 4: Run tests and confirm pass**

```bash
python3 -m unittest discover -s tests -v
```

- [ ] **Step 5: Commit**

```bash
git commit -m "fix(publish): synchronize marketplace and dual-target versions"
```

### Task 4: Encode Obsidian Tracking JSON Safely

**Files:**
- Modify: `plugins/obsidian-tracker/tests/hooks/start_tracking.bats`
- Modify: `plugins/obsidian-tracker/scripts/start-tracking.sh`

- [ ] **Step 1: Add failing Bats regression**

Add a case that passes quotes and backslashes in project, goal, and actions and validates the result with:
```bash
jq -e .
```

- [ ] **Step 2: Run focused Bats test and confirm failure**

```bash
bats plugins/obsidian-tracker/tests/hooks/start_tracking.bats
```

- [ ] **Step 3: Replace shell JSON interpolation**

Pass values as Python arguments and serialize with:
```python
json.dump({"project": project, "goal": goal, "actions": actions, "startedAt": timestamp}, sys.stdout, ensure_ascii=False, indent=2)
```

- [ ] **Step 4: Run focused Bats test and confirm pass**

```bash
bats plugins/obsidian-tracker/tests/hooks/start_tracking.bats
```

- [ ] **Step 5: Commit**

```bash
git commit -m "fix(obsidian-tracker): encode tracking state as valid json"
```

### Task 5: Synchronize Release Metadata

**Files:**
- Modify: `.agents/plugins/marketplace.json`
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `plugins/plugin-cross-port/.claude-plugin/plugin.json`
- Modify: `plugins/plugin-cross-port/.codex-plugin/plugin.json`
- Modify: `plugins/plugin-cross-port/README.md`
- Modify: `plugins/plugin-cross-port/.plugin-cross-port.yaml`
- Modify: `plugins/obsidian-tracker/mcp/package.json`
- Modify: `plugins/obsidian-tracker/mcp/package-lock.json`
- Modify: `plugins/obsidian-tracker/mcp/index.ts`
- Modify: `plugins/obsidian-tracker/mcp/dist/index.js`

- [ ] **Step 1: Add Codex marketplace root metadata**

Write:
```json
{
  "name": "awac-claude-code-plugins",
  "interface": {
    "displayName": "AWAC Claude Code Plugins"
  },
  "plugins": [...]
}
```

- [ ] **Step 2: Align stale versions**

Use Claude plugin manifests as source of truth for existing plugin versions. Set Obsidian MCP package and server version to `4.3.0`.

- [ ] **Step 3: Publish plugin-cross-port minor release**

Set `plugin-cross-port` to `0.5.0` and document stale cleanup, plugin-relative preservation, release synchronization, safe JSON serialization, and dependency cleanup.

- [ ] **Step 4: Refresh generated files**

Run:
```bash
npm run build --prefix plugins/obsidian-tracker/mcp
python3 plugins/plugin-cross-port/scripts/convert_cc_to_codex.py plugins/plugin-cross-port --repo-root . --force
```

- [ ] **Step 5: Commit**

```bash
git commit -m "chore(release): publish marketplace consistency fixes"
```

### Task 6: Verify Release

**Files:**
- Verify only

- [ ] **Step 1: Run Python regression tests**

```bash
python3 -m unittest discover -s plugins/plugin-cross-port/tests -v
python3 -m unittest discover -s tests -v
```

- [ ] **Step 2: Run plugin suites**

```bash
bash plugins/crashlytics/scripts/tests/run-tests.sh
bats plugins/obsidian-tracker/tests/plugin_structure.bats plugins/obsidian-tracker/tests/hooks/*.bats
npm test --prefix plugins/obsidian-tracker/mcp
npm run build --prefix plugins/obsidian-tracker/mcp
```

- [ ] **Step 3: Run static validation**

```bash
bash -n <all first-party shell scripts>
python3 -m json.tool <all first-party JSON files>
python3 -m compileall <first-party Python files>
```

- [ ] **Step 4: Verify repository state**

```bash
git status --short --branch
git log --oneline -n 8
```
