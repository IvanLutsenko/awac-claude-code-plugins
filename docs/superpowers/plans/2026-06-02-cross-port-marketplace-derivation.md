# Marketplace Reconciliation 0.6.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `plugin-cross-port 0.6.0` with deterministic attach, sync and check workflows for dual-target Claude Code and Codex marketplaces, including mixed per-plugin source-of-truth, best-effort failure reporting, safe removal, and a strict pre-commit integration.

**Architecture:** Keep the existing per-plugin converters as transformation engines and introduce focused orchestration modules. `plugin_state.py` owns JSON-compatible YAML state, `marketplace_sync.py` owns pure marketplace transformations, `reconcile.py` owns filesystem reconciliation and transactional per-plugin rollback, and `cross_port.py` exposes the CLI. The pre-commit hook delegates to the CLI instead of inferring conversion direction itself.

**Tech Stack:** Python 3 standard library only, Bash, `unittest`, JSON, minimal YAML subset already used by the plugin.

**Spec:** `docs/superpowers/specs/2026-06-02-cross-port-marketplace-derivation-design.md`

---

## Release Boundary

This plan implements `0.6.0` only.

Do not implement `plugin adapt`, adaptation plans, snapshot hashes, semantic
criticality, or automatic LLM rewriting. Those belong to `0.7.0`.

---

## File Structure

Create:

- `plugins/plugin-cross-port/scripts/plugin_state.py`
  - Read and write repo-level and plugin-level state.
  - Extend the existing dependency-free YAML subset only as far as required.
- `plugins/plugin-cross-port/scripts/marketplace_sync.py`
  - Pure marketplace root and entry transformations.
  - Preserve root metadata and ordered entries.
- `plugins/plugin-cross-port/scripts/reconcile.py`
  - Attach, sync, check, safe deletion and best-effort rollback.
- `plugins/plugin-cross-port/scripts/cross_port.py`
  - `argparse` CLI router.
- `plugins/plugin-cross-port/tests/helpers.py`
  - Temporary repository builders used by orchestration tests.
- `plugins/plugin-cross-port/tests/test_plugin_state.py`
- `plugins/plugin-cross-port/tests/test_marketplace_sync.py`
- `plugins/plugin-cross-port/tests/test_reconcile.py`
- `plugins/plugin-cross-port/tests/test_cli.py`
- `plugins/plugin-cross-port/tests/test_pre_commit_hook.py`

Modify:

- `plugins/plugin-cross-port/scripts/convert_cc_to_codex.py`
  - Support orchestration without direct marketplace side effects.
  - Keep backward-compatible standalone behavior.
- `plugins/plugin-cross-port/scripts/convert_codex_to_cc.py`
  - Same boundary for reverse conversion.
- `plugins/plugin-cross-port/tests/test_converters.py`
  - Preserve current regression coverage and add orchestration-mode tests.
- `.githooks/pre-commit`
  - Replace direction guessing with one CLI invocation.
- `plugins/plugin-cross-port/references/config.md`
- `plugins/plugin-cross-port/references/mapping.md`
- `plugins/plugin-cross-port/references/continuous-mode.md`
- `plugins/plugin-cross-port/references/decision-file.md`
- `plugins/plugin-cross-port/README.md`
- `plugins/plugin-cross-port/skills/cc-to-codex/SKILL.md`
- `plugins/plugin-cross-port/skills/codex-to-cc/SKILL.md`
- `plugins/plugin-cross-port/skills/maintain-dual-target/SKILL.md`
- `plugins/plugin-cross-port/.claude-plugin/plugin.json`
- `plugins/plugin-cross-port/.codex-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `.agents/plugins/marketplace.json`
- `CLAUDE.md`

---

### Task 1: Add Shared Test Helpers

**Files:**
- Create: `plugins/plugin-cross-port/tests/helpers.py`
- Modify: `plugins/plugin-cross-port/tests/test_converters.py`

- [ ] **Step 1: Create temporary repository builders**

Create `tests/helpers.py` with:

```python
import json
from pathlib import Path


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def make_cc_marketplace(repo: Path, names: list[str]) -> Path:
    path = repo / ".claude-plugin" / "marketplace.json"
    write_json(path, {
        "name": "sample-marketplace",
        "version": "1.0.0",
        "description": "Sample marketplace",
        "owner": {"name": "Tester"},
        "plugins": [
            {
                "name": name,
                "version": "1.0.0",
                "description": f"{name} plugin.",
                "source": f"./plugins/{name}",
                "category": "development",
            }
            for name in names
        ],
    })
    return path


def make_codex_marketplace(repo: Path, names: list[str]) -> Path:
    path = repo / ".agents" / "plugins" / "marketplace.json"
    write_json(path, {
        "name": "sample-marketplace",
        "interface": {"displayName": "Sample Marketplace"},
        "plugins": [
            {
                "name": name,
                "source": {"source": "local", "path": f"./plugins/{name}"},
                "policy": {
                    "installation": "AVAILABLE",
                    "authentication": "ON_INSTALL",
                },
                "category": "Development",
            }
            for name in names
        ],
    })
    return path


def make_cc_plugin(repo: Path, name: str) -> Path:
    plugin = repo / "plugins" / name
    write_json(plugin / ".claude-plugin" / "plugin.json", {
        "name": name,
        "version": "1.0.0",
        "description": f"{name} plugin.",
        "author": {"name": "Tester"},
    })
    return plugin


def make_codex_plugin(repo: Path, name: str) -> Path:
    plugin = repo / "plugins" / name
    write_json(plugin / ".codex-plugin" / "plugin.json", {
        "name": name,
        "version": "1.0.0",
        "description": f"{name} plugin.",
        "author": {"name": "Tester"},
        "skills": "./skills/",
        "interface": {
            "displayName": name.replace("-", " ").title(),
            "shortDescription": f"{name} plugin",
            "developerName": "Tester",
            "category": "Development",
            "capabilities": ["Read"],
        },
    })
    skill = plugin / "skills" / "main" / "SKILL.md"
    skill.parent.mkdir(parents=True, exist_ok=True)
    skill.write_text("---\nname: main\ndescription: Main skill\n---\n\nBody\n", encoding="utf-8")
    return plugin
```

- [ ] **Step 2: Refactor existing converter tests to import helpers**

Replace duplicated JSON setup in `tests/test_converters.py` with:

```python
from helpers import make_cc_plugin, make_codex_marketplace, make_codex_plugin
```

In `setUp`, call:

```python
make_codex_marketplace(self.repo_root, [])
```

Delegate existing instance helper methods to shared helpers.

- [ ] **Step 3: Run regression tests**

Run:

```bash
python3 -m unittest discover -s plugins/plugin-cross-port/tests -v
```

Expected: existing `3` tests pass.

- [ ] **Step 4: Commit**

```bash
git add plugins/plugin-cross-port/tests
git commit -m "test(plugin-cross-port): add marketplace fixture helpers"
```

---

### Task 2: Add Dependency-Free State I/O

**Files:**
- Create: `plugins/plugin-cross-port/scripts/plugin_state.py`
- Create: `plugins/plugin-cross-port/tests/test_plugin_state.py`

- [ ] **Step 1: Write failing state tests**

Create `tests/test_plugin_state.py` covering:

```python
import importlib.util
import tempfile
import unittest
from pathlib import Path


PLUGIN_ROOT = Path(__file__).resolve().parents[1]


def load_module():
    spec = importlib.util.spec_from_file_location(
        "plugin_state", PLUGIN_ROOT / "scripts" / "plugin_state.py"
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class PluginStateTest(unittest.TestCase):
    def test_round_trip_nested_marketplace_state(self):
        state = load_module()
        payload = {
            "version": 1,
            "source_of_truth": "claude-code",
            "source_marketplace": ".claude-plugin/marketplace.json",
            "targets": {"codex": ".agents/plugins/marketplace.json"},
            "plugins": {
                "sample": {
                    "status": "failed",
                    "target": "codex",
                    "last_error": "manifest validation failed",
                }
            },
        }
        self.assertEqual(state.loads(state.dumps(payload)), payload)

    def test_plugin_state_defaults_to_version_two(self):
        state = load_module()
        payload = state.new_plugin_state("sample", "codex")
        self.assertEqual(payload, {
            "version": 2,
            "plugin": "sample",
            "source_of_truth": "codex",
            "status": "synced",
            "manually_maintained": [],
        })

    def test_load_missing_returns_default(self):
        state = load_module()
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "missing.yaml"
            self.assertEqual(state.load(path, default={"version": 1}), {"version": 1})

    def test_loads_legacy_plugin_state(self):
        state = load_module()
        payload = state.loads(
            "source_of_truth: claude-code\n"
            "manually_maintained:\n"
            "  - skills/generated-from-commands/main/SKILL.md\n"
        )
        self.assertEqual(payload["source_of_truth"], "claude-code")
        self.assertEqual(
            payload["manually_maintained"],
            ["skills/generated-from-commands/main/SKILL.md"],
        )
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_plugin_state.py -v
```

Expected: fail because `scripts/plugin_state.py` does not exist.

- [ ] **Step 3: Implement `plugin_state.py`**

Implement JSON-compatible YAML. JSON is a valid YAML subset, handles nested
state without a third-party parser, and remains readable:

```python
"""Dependency-free JSON-compatible YAML state for plugin-cross-port."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def dumps(payload: dict[str, Any]) -> str:
    return json.dumps(payload, indent=2, ensure_ascii=False) + "\n"


def loads(text: str) -> dict[str, Any]:
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        return _loads_legacy(text)
    if not isinstance(payload, dict):
        raise ValueError("State file must contain an object")
    return payload


def load(path: Path, *, default: dict[str, Any]) -> dict[str, Any]:
    if not path.exists():
        return dict(default)
    return loads(path.read_text(encoding="utf-8"))


def save(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(dumps(payload), encoding="utf-8")


def new_plugin_state(name: str, source_of_truth: str) -> dict[str, Any]:
    return {
        "version": 2,
        "plugin": name,
        "source_of_truth": source_of_truth,
        "status": "synced",
        "manually_maintained": [],
    }
```

Add `_loads_legacy(text)` for backward compatibility. It must parse the flat
top-level scalars and scalar lists emitted by the existing converters. Reject
nested legacy mappings with `ValueError`; new nested state is always written as
JSON-compatible YAML.

- [ ] **Step 4: Run state tests**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_plugin_state.py -v
```

Expected: `3` tests pass.

- [ ] **Step 5: Commit**

```bash
git add plugins/plugin-cross-port/scripts/plugin_state.py plugins/plugin-cross-port/tests/test_plugin_state.py
git commit -m "feat(plugin-cross-port): add dependency-free state io"
```

---

### Task 3: Add Pure Marketplace Reconciliation

**Files:**
- Create: `plugins/plugin-cross-port/scripts/marketplace_sync.py`
- Create: `plugins/plugin-cross-port/tests/test_marketplace_sync.py`

- [ ] **Step 1: Write failing marketplace tests**

Create tests for these public functions:

```python
seed_codex_marketplace(canonical: dict) -> dict
seed_cc_marketplace(canonical: dict) -> dict
plugin_source_path(plugin_path: Path, repo_root: Path, plugins_dir: Path) -> str
upsert_cc_entry(market: dict, manifest: dict, source_path: str, category: str) -> dict
upsert_codex_entry(market: dict, manifest: dict, source_path: str, status: str, category: str) -> dict
reconcile_order(market: dict, canonical_names: list[str]) -> dict
remove_entry(market: dict, plugin_name: str) -> dict
```

Implement these exact assertions in the tests:

```python
def test_seed_codex_marketplace_includes_required_root_metadata(self):
    self.assertEqual(
        ms.seed_codex_marketplace({"name": "team-tools"}),
        {
            "name": "team-tools",
            "interface": {"displayName": "Team Tools"},
            "plugins": [],
        },
    )

def test_seed_cc_marketplace_preserves_catalog_metadata(self):
    canonical = {"name": "team", "version": "1.0.0", "owner": {"name": "T"}, "plugins": []}
    self.assertEqual(ms.seed_cc_marketplace(canonical)["owner"], {"name": "T"})

def test_plugin_source_path_rejects_escape_outside_plugins_dir(self):
    with self.assertRaises(ValueError):
        ms.plugin_source_path(Path("/repo/outside/foo"), Path("/repo"), Path("plugins"))

def test_cc_entry_recomputes_path_and_preserves_category(self):
    market = {"plugins": [{"name": "foo", "category": "testing"}]}
    ms.upsert_cc_entry(market, {"name": "foo", "version": "2.0.0", "description": "D"}, "./plugins/foo", "development")
    self.assertEqual(market["plugins"][0]["source"], "./plugins/foo")
    self.assertEqual(market["plugins"][0]["category"], "testing")

def test_codex_entry_preserves_authentication_and_products(self):
    market = {"plugins": [{"name": "foo", "policy": {"installation": "INSTALLED_BY_DEFAULT", "authentication": "ON_USE", "products": ["codex"]}}]}
    ms.upsert_codex_entry(market, {"name": "foo"}, "./plugins/foo", "synced", "Development")
    self.assertEqual(market["plugins"][0]["policy"]["authentication"], "ON_USE")
    self.assertEqual(market["plugins"][0]["policy"]["products"], ["codex"])

def test_codex_entry_marks_failed_plugin_not_available(self):
    market = {"plugins": []}
    ms.upsert_codex_entry(market, {"name": "foo"}, "./plugins/foo", "failed", "Development")
    self.assertEqual(market["plugins"][0]["policy"]["installation"], "NOT_AVAILABLE")

def test_reconcile_order_matches_canonical_order(self):
    market = {"plugins": [{"name": "b"}, {"name": "a"}]}
    self.assertEqual([p["name"] for p in ms.reconcile_order(market, ["a", "b"])["plugins"]], ["a", "b"])

def test_remove_entry_drops_only_named_plugin(self):
    market = {"plugins": [{"name": "a"}, {"name": "b"}]}
    self.assertEqual([p["name"] for p in ms.remove_entry(market, "a")["plugins"]], ["b"])
```

Use only valid Codex policy values:

```python
{"installation": "INSTALLED_BY_DEFAULT", "authentication": "ON_USE"}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_marketplace_sync.py -v
```

Expected: fail because `scripts/marketplace_sync.py` does not exist.

- [ ] **Step 3: Implement pure transformations**

Implement `scripts/marketplace_sync.py` with no filesystem writes.

Required behavior:

```python
VALID_STATUSES = {"synced", "needs-review", "failed"}


def seed_codex_marketplace(canonical: dict) -> dict:
    name = canonical.get("name", "cross-port")
    display_name = canonical.get("interface", {}).get(
        "displayName", name.replace("-", " ").title()
    )
    return {"name": name, "interface": {"displayName": display_name}, "plugins": []}


def seed_cc_marketplace(canonical: dict) -> dict:
    root = {
        key: canonical[key]
        for key in ("$schema", "name", "version", "description", "owner")
        if key in canonical
    }
    root.setdefault("name", "cross-port")
    root["plugins"] = []
    return root
```

`upsert_cc_entry` overwrites manifest-owned fields and preserves existing
`category`.

`upsert_codex_entry`:

- always writes a local source object;
- preserves existing `policy.authentication`;
- preserves optional `policy.products`;
- writes `policy.installation = "AVAILABLE"` for `synced`;
- writes `policy.installation = "NOT_AVAILABLE"` for `needs-review` and
  `failed`;
- preserves existing `INSTALLED_BY_DEFAULT` only while status is `synced`.

`plugin_source_path` must resolve both paths, require the plugin to remain
inside `repo_root / plugins_dir`, and require `plugin_path.name` to match the
manifest plugin name in the caller before deletion.

- [ ] **Step 4: Run marketplace tests**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_marketplace_sync.py -v
```

Expected: `8` tests pass.

- [ ] **Step 5: Commit**

```bash
git add plugins/plugin-cross-port/scripts/marketplace_sync.py plugins/plugin-cross-port/tests/test_marketplace_sync.py
git commit -m "feat(plugin-cross-port): add pure marketplace reconciliation"
```

---

### Task 4: Isolate Converter Side Effects

**Files:**
- Modify: `plugins/plugin-cross-port/scripts/convert_cc_to_codex.py`
- Modify: `plugins/plugin-cross-port/scripts/convert_codex_to_cc.py`
- Modify: `plugins/plugin-cross-port/tests/test_converters.py`
- Modify: `plugins/plugin-cross-port/references/config.md`

- [ ] **Step 1: Write failing orchestration-mode tests**

Add:

```python
def test_cc_to_codex_can_skip_marketplace_side_effects(self):
    plugin = self.make_cc_plugin()
    converter = cc_to_codex.Converter(
        plugin, self.repo_root, False, False, False, sync_marketplace=False
    )
    self.assertEqual(converter.run(), 0)
    self.assertEqual(read_json(self.codex_marketplace)["plugins"], [])


def test_codex_to_cc_accepts_orchestration_mode(self):
    plugin = self.make_codex_plugin()
    converter = codex_to_cc.ReverseConverter(
        plugin, self.repo_root, False, False, False, sync_marketplace=False
    )
    self.assertEqual(converter.run(), 0)
```

- [ ] **Step 2: Run focused tests and verify failure**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_converters.py -v
```

Expected: fail because converter constructors do not accept
`sync_marketplace`.

- [ ] **Step 3: Add converter boundary**

Add constructor parameter:

```python
sync_marketplace: bool = True
```

Store:

```python
self.sync_marketplace = sync_marketplace
```

For `convert_cc_to_codex.py`, keep the existing direct Codex marketplace
upsert only when:

```python
if self.sync_marketplace:
    self.update_codex_marketplace(plugin_name)
```

Do not add direct marketplace writes to `convert_codex_to_cc.py`.
`reconcile.py` becomes the only owner of dual-marketplace reconciliation.

- [ ] **Step 4: Route plugin-state reads through `plugin_state`**

In both converters import:

```python
sys.path.insert(0, str(Path(__file__).resolve().parent))
from plugin_state import load as load_state
```

Replace `load_decision_file` bodies with:

```python
    def load_decision_file(self) -> dict:
        return load_state(
            self.plugin_path / ".plugin-cross-port.yaml",
            default={},
        )
```

This preserves legacy state reads while allowing attached plugins to use
nested JSON-compatible state.

- [ ] **Step 5: Add config keys**

In both converter `DEFAULT_CONFIG` dictionaries add:

```python
"cc_marketplace": ".claude-plugin/marketplace.json",
"marketplace_state": ".plugin-cross-port.marketplace.yaml",
```

Document these keys in `references/config.md`.

- [ ] **Step 6: Run all converter tests**

Run:

```bash
python3 -m unittest discover -s plugins/plugin-cross-port/tests -v
```

Expected: existing and new tests pass.

- [ ] **Step 7: Commit**

```bash
git add plugins/plugin-cross-port/scripts plugins/plugin-cross-port/tests plugins/plugin-cross-port/references/config.md
git commit -m "refactor(plugin-cross-port): isolate converter side effects"
```

---

### Task 5: Add Reconcile Orchestration

**Files:**
- Create: `plugins/plugin-cross-port/scripts/reconcile.py`
- Create: `plugins/plugin-cross-port/tests/test_reconcile.py`

- [ ] **Step 1: Write failing attach and sync tests**

Create fixture-backed tests. Use these exact scenarios and assertions:

| Test | Setup | Required assertions |
|---|---|---|
| `test_attach_cc_marketplace_converts_all_plugins_and_preserves_order` | CC marketplace entries `two`, `one`; both CC plugins exist | sibling Codex names are `["two", "one"]`; both `.codex-plugin/plugin.json` files exist |
| `test_attach_codex_marketplace_generates_cc_sibling` | one Codex marketplace entry and Codex plugin | generated CC marketplace contains `one`; generated `.claude-plugin/plugin.json` exists |
| `test_sync_supports_mixed_plugin_sources` | attached CC-first `one`, Codex-first `two`; mutate both authoritative manifests | target Codex version for `one` and target CC version for `two` match their authoritative manifests |
| `test_codex_first_metadata_updates_canonical_cc_entry` | CC marketplace is canonical; plugin `two` is Codex-first at `2.0.0` | canonical CC entry `two.version == "2.0.0"` |
| `test_failed_codex_target_is_not_available_and_other_plugins_continue` | valid CC plugin `one`; invalid CC plugin `two` missing manifest | Codex `two.policy.installation == "NOT_AVAILABLE"`; Codex `one.policy.installation == "AVAILABLE"` |
| `test_failed_cc_target_is_omitted_and_other_plugins_continue` | Codex canonical marketplace; valid `one`; invalid `two` missing manifest | generated CC names equal `["one"]`; report contains failed `two` |
| `test_deleted_canonical_entry_removes_plugin_directory` | attach two plugins, then remove `two` from canonical marketplace | `plugins/two` no longer exists after sync |
| `test_delete_rejects_path_escape_without_filesystem_changes` | state records attached plugin path outside configured `plugins_dir` | sync exits non-zero; outside sentinel still exists |
| `test_check_reports_stale_output_without_writes` | mutate generated manifest after clean sync | `check().exit_code == 1`; filesystem hash map is identical before and after check |

For best-effort rollback, construct one valid plugin and one invalid plugin
missing its authoritative manifest. Assert that the valid plugin remains
generated after sync reports failure for the invalid plugin.

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_reconcile.py -v
```

Expected: fail because `scripts/reconcile.py` does not exist.

- [ ] **Step 3: Implement `Reconciler`**

Create:

```python
class Reconciler:
    def __init__(self, repo_root: Path, *, dry_run: bool = False):
        self.repo_root = repo_root.resolve()
        self.dry_run = dry_run
        self.config = load_config(self.repo_root)
        self.marketplace_state_path = self.repo_root / self.config["marketplace_state"]
        self.results: list[PluginResult] = []

    def attach_marketplace(
        self,
        source: str,
        *,
        only: set[str] | None = None,
        exclude: set[str] | None = None,
    ) -> ReconcileReport:
        return self._reconcile_attach(source, only=only, exclude=exclude)

    def sync(
        self,
        *,
        changed_only: set[str] | None = None,
        stage: bool = False,
    ) -> ReconcileReport:
        return self._reconcile_sync(changed_only=changed_only, stage=stage)

    def check(self) -> ReconcileReport:
        return self._reconcile_check()
```

Add:

```python
@dataclass
class PluginResult:
    name: str
    status: str
    target: str
    error: str = ""


@dataclass
class ReconcileReport:
    results: list[PluginResult]
    changed_paths: list[Path]

    @property
    def exit_code(self) -> int:
        return 0 if all(result.status == "synced" for result in self.results) else 1
```

Required implementation rules:

1. Read root state with `plugin_state.load`.
2. Preserve canonical marketplace order.
3. Resolve local `source` strings for CC and `source.path` for Codex.
4. Snapshot target-owned files for one plugin before conversion.
5. Run existing converter with `sync_marketplace=False`.
6. On exception or non-zero conversion result, restore that plugin snapshot,
   record `failed`, and continue.
7. Write plugin-level state with version `2`.
8. Build sibling marketplace in memory, then write once.
9. For removed canonical entries, resolve path under `plugins_dir`, require
   directory basename match, then delete the entire directory.
10. In dry-run mode, collect changed paths without writing or deleting.
11. If `stage=True`, invoke:

```python
subprocess.run(["git", "add", "-A"], cwd=self.repo_root, check=True)
```

- [ ] **Step 4: Implement check comparison**

`check()` must snapshot file hashes, call the same sync path with `dry_run=True`,
and return exit `1` when `changed_paths` is non-empty or any plugin status is
not `synced`.

- [ ] **Step 5: Run reconcile tests**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_reconcile.py -v
```

Expected: `9` tests pass.

- [ ] **Step 6: Run all plugin-cross-port tests**

Run:

```bash
python3 -m unittest discover -s plugins/plugin-cross-port/tests -v
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add plugins/plugin-cross-port/scripts/reconcile.py plugins/plugin-cross-port/tests/test_reconcile.py
git commit -m "feat(plugin-cross-port): reconcile dual-target marketplaces"
```

---

### Task 6: Add CLI and Explicit Source Switching

**Files:**
- Create: `plugins/plugin-cross-port/scripts/cross_port.py`
- Create: `plugins/plugin-cross-port/tests/test_cli.py`
- Modify: `plugins/plugin-cross-port/scripts/reconcile.py`

- [ ] **Step 1: Write failing CLI tests**

Cover these exact CLI outcomes:

| CLI arguments | Required assertion |
|---|---|
| `marketplace attach` | non-zero because `--source` is required |
| `marketplace attach --source claude-code` with two fixtures | output contains `Synced:       2` |
| `marketplace attach --source claude-code --only one` | output contains `Synced:       1`; plugin `two` is not generated |
| `marketplace attach --source claude-code --exclude two` | output contains `Synced:       1`; plugin `two` is not generated |
| `marketplace sync` with an invalid authoritative plugin | return code `1` |
| `marketplace check` after generated-file mutation | return code `1` |
| `plugin convert plugins/one --from claude-code --to codex` without root state | return code `0`; no marketplace file created |
| `plugin attach plugins/one` | non-zero because `--source` is required |
| `plugin switch-source plugins/one --to codex` after clean sync | return code `0`; plugin state contains `"source_of_truth": "codex"` |
| `plugin switch-source plugins/one --to codex` after generated-file mutation | return code `1`; plugin state remains unchanged |

Invoke the script via:

```python
subprocess.run(
    [sys.executable, str(SCRIPT), "--repo-root", str(repo), *args],
    text=True,
    capture_output=True,
)
```

- [ ] **Step 2: Run CLI tests and verify failure**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_cli.py -v
```

Expected: fail because `scripts/cross_port.py` does not exist.

- [ ] **Step 3: Implement argparse router**

Expose:

```text
cross_port.py [--repo-root PATH] marketplace attach --source {claude-code,codex} [--only CSV] [--exclude CSV]
cross_port.py [--repo-root PATH] marketplace sync [--changed-only CSV] [--stage]
cross_port.py [--repo-root PATH] marketplace check
cross_port.py [--repo-root PATH] plugin convert PATH --from {claude-code,codex} --to {claude-code,codex}
cross_port.py [--repo-root PATH] plugin attach PATH --source {claude-code,codex}
cross_port.py [--repo-root PATH] plugin switch-source PATH --to {claude-code,codex}
```

Print a stable summary:

```text
Plugin Cross-Port Marketplace
=============================
Synced:       2
Needs review: 0
Failed:       1

FAILED crashlytics -> codex: missing .claude-plugin/plugin.json
```

Return report exit code.

- [ ] **Step 4: Implement plugin attach**

`plugin attach`:

1. require existing marketplace state;
2. require selected authoritative manifest;
3. write plugin state from `new_plugin_state`;
4. append the plugin to canonical marketplace if absent;
5. invoke reconcile sync for that plugin.

- [ ] **Step 5: Implement switch-source**

`plugin switch-source`:

1. run `marketplace check`;
2. reject if stale or failed;
3. require target manifest exists;
4. update only `source_of_truth`;
5. run sync for that plugin.

- [ ] **Step 6: Run CLI tests**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_cli.py -v
```

Expected: `9` tests pass.

- [ ] **Step 7: Commit**

```bash
git add plugins/plugin-cross-port/scripts plugins/plugin-cross-port/tests/test_cli.py
git commit -m "feat(plugin-cross-port): add marketplace cli"
```

---

### Task 7: Replace Pre-Commit Direction Guessing

**Files:**
- Modify: `.githooks/pre-commit`
- Create: `plugins/plugin-cross-port/tests/test_pre_commit_hook.py`

- [ ] **Step 1: Write failing hook tests**

Create temporary git repositories and assert:

| Test | Staged input | Required assertions |
|---|---|---|
| `test_authoritative_side_edit_runs_changed_only_sync` | mutate CC-first `commands/main.md` | hook exit `0`; staged names include `plugins/one/skills/generated-from-commands/main/SKILL.md` |
| `test_generated_side_edit_is_rejected` | mutate CC-first `.codex-plugin/plugin.json` | hook exit `1`; output contains `Source of truth: claude-code` |
| `test_staged_deletion_is_staged_after_sync` | remove canonical marketplace entry for `one` | hook exit `0`; `git diff --cached --name-only --diff-filter=D` includes files under `plugins/one/` |

For each test:

1. initialize a temp git repository;
2. set `core.hooksPath` to copied `.githooks`;
3. seed attached marketplace and plugin state;
4. stage one source edit;
5. execute copied `pre-commit`;
6. inspect exit code and staged files.

- [ ] **Step 2: Run hook tests and verify failure**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_pre_commit_hook.py -v
```

Expected: generated-side edit is not rejected by the existing hook.

- [ ] **Step 3: Replace hook implementation**

Keep only:

```bash
#!/bin/bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT="$REPO_ROOT/plugins/plugin-cross-port/scripts/cross_port.py"

[ -f "$SCRIPT" ] || exit 0
[ -f "$REPO_ROOT/.plugin-cross-port.marketplace.yaml" ] || exit 0

CHANGED=$(git diff --cached --name-only --diff-filter=ACDMRTUXB)
[ -n "$CHANGED" ] || exit 0

PLUGINS=$(
  printf '%s\n' "$CHANGED" |
    awk -F/ '$1 == "plugins" && NF >= 2 {print $2}' |
    sort -u |
    paste -sd, -
)

[ -n "$PLUGINS" ] || exit 0

python3 "$SCRIPT" --repo-root "$REPO_ROOT" \
  marketplace sync --changed-only "$PLUGINS" --stage
```

Ownership validation belongs in Python reconciliation, not shell.

- [ ] **Step 4: Add generated-side ownership validation**

In `reconcile.py`, when `changed_only` is provided:

1. inspect staged files with `git diff --cached --name-only`;
2. classify generated paths from plugin `source_of_truth`;
3. permit paths in `manually_maintained`;
4. return an error for unauthorized generated-side edits.

- [ ] **Step 5: Run hook tests**

Run:

```bash
python3 -m unittest plugins/plugin-cross-port/tests/test_pre_commit_hook.py -v
```

Expected: `3` tests pass.

- [ ] **Step 6: Commit**

```bash
git add .githooks/pre-commit plugins/plugin-cross-port/scripts/reconcile.py plugins/plugin-cross-port/tests/test_pre_commit_hook.py
git commit -m "fix(plugin-cross-port): enforce declared sync direction in hook"
```

---

### Task 8: Document Vendor and Continuous Workflows

**Files:**
- Modify: `plugins/plugin-cross-port/skills/cc-to-codex/SKILL.md`
- Modify: `plugins/plugin-cross-port/skills/codex-to-cc/SKILL.md`
- Modify: `plugins/plugin-cross-port/skills/maintain-dual-target/SKILL.md`
- Modify: `plugins/plugin-cross-port/references/mapping.md`
- Modify: `plugins/plugin-cross-port/references/continuous-mode.md`
- Modify: `plugins/plugin-cross-port/references/decision-file.md`
- Modify: `plugins/plugin-cross-port/references/config.md`
- Modify: `plugins/plugin-cross-port/README.md`

- [ ] **Step 1: Document explicit vendor phase**

In both one-shot skills add:

```markdown
## Phase 0: Vendor external plugins

When the plugin lives outside this repository, copy it into `plugins_dir`
before conversion. Review license and attribution, resolve name collisions,
discard stale foreign generated artifacts after review, and explicitly choose
the source of truth when attaching. Deterministic scripts never copy files
between repositories.
```

- [ ] **Step 2: Document CLI workflows**

Document:

```bash
python3 plugins/plugin-cross-port/scripts/cross_port.py marketplace attach --source claude-code
python3 plugins/plugin-cross-port/scripts/cross_port.py marketplace sync
python3 plugins/plugin-cross-port/scripts/cross_port.py marketplace check
python3 plugins/plugin-cross-port/scripts/cross_port.py plugin attach plugins/example --source codex
python3 plugins/plugin-cross-port/scripts/cross_port.py plugin switch-source plugins/example --to claude-code
```

- [ ] **Step 3: Document state schemas and publication asymmetry**

Explain:

- root and plugin-level source of truth;
- mixed repositories;
- Codex `NOT_AVAILABLE`;
- failed CC targets omitted from CC marketplace;
- full directory removal after canonical entry removal;
- Git as recovery mechanism;
- `plugin adapt` deferred to `0.7.0`.

- [ ] **Step 4: Run documentation search**

Run:

```bash
grep -RIn "Claude Code is always the source of truth\|source_of_truth: always\|BLOCKED\|authentication.*NONE" plugins/plugin-cross-port
```

Expected: no stale claims and no invalid policy values.

- [ ] **Step 5: Commit**

```bash
git add plugins/plugin-cross-port/README.md plugins/plugin-cross-port/references plugins/plugin-cross-port/skills
git commit -m "docs(plugin-cross-port): document marketplace reconciliation"
```

---

### Task 9: Publish Plugin Cross Port 0.6.0

**Files:**
- Modify: `plugins/plugin-cross-port/.claude-plugin/plugin.json`
- Modify: `plugins/plugin-cross-port/.codex-plugin/plugin.json`
- Modify: `plugins/plugin-cross-port/.plugin-cross-port.yaml`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `.agents/plugins/marketplace.json`
- Modify: `CLAUDE.md`
- Modify: `README.md`

- [ ] **Step 1: Bump plugin manifest**

Use the existing release helper:

```bash
python3 scripts/publish-plugin.py plugin-cross-port minor
```

Expected: `0.5.0 -> 0.6.0`, including both plugin manifests and root CC
marketplace.

- [ ] **Step 2: Add changelog**

Add:

```markdown
### 0.6.0
- Add marketplace attach, sync and check workflows
- Support mixed Claude Code-first and Codex-first plugins
- Reconcile ordered marketplace entries and preserve non-derived policy fields
- Mark unavailable Codex targets with NOT_AVAILABLE and omit broken CC targets
- Remove plugin directories when canonical marketplace entries are removed
- Replace hook direction guessing with declared source-of-truth enforcement
```

- [ ] **Step 3: Dogfood attach and sync**

Attach this repository as CC-first:

```bash
python3 plugins/plugin-cross-port/scripts/cross_port.py \
  --repo-root . marketplace attach --source claude-code
python3 plugins/plugin-cross-port/scripts/cross_port.py \
  --repo-root . marketplace sync
```

Inspect generated state before staging:

```bash
git diff -- .plugin-cross-port.marketplace.yaml \
  .claude-plugin/marketplace.json \
  .agents/plugins/marketplace.json \
  plugins/*/.plugin-cross-port.yaml
```

- [ ] **Step 4: Update root docs**

In `CLAUDE.md`:

- update `plugin-cross-port` to `v0.6.0`;
- state that attached plugins reconcile marketplace entries automatically;
- retain manual marketplace update instructions for plugins not attached to
  cross-port.

In root `README.md`, update plugin-cross-port status and features.

- [ ] **Step 5: Run marketplace check**

Run:

```bash
python3 plugins/plugin-cross-port/scripts/cross_port.py \
  --repo-root . marketplace check
```

Expected: exit `0`.

- [ ] **Step 6: Commit release metadata**

```bash
git add .plugin-cross-port.marketplace.yaml \
  .claude-plugin/marketplace.json \
  .agents/plugins/marketplace.json \
  CLAUDE.md README.md plugins/
git commit -m "chore(release): publish plugin-cross-port 0.6.0"
```

---

### Task 10: Verify Release

**Files:**
- Verify only

- [ ] **Step 1: Run plugin-cross-port unit tests**

```bash
python3 -m unittest discover -s plugins/plugin-cross-port/tests -v
```

Expected: all tests pass.

- [ ] **Step 2: Run marketplace check**

```bash
python3 plugins/plugin-cross-port/scripts/cross_port.py \
  --repo-root . marketplace check
```

Expected: exit `0`.

- [ ] **Step 3: Run repository regression suites**

```bash
python3 -m unittest discover -s tests -v
bash plugins/crashlytics/scripts/tests/run-tests.sh
HOME=/private/tmp/awac-obsidian-bats-home \
  bats $(find plugins/obsidian-tracker/tests -name '*.bats' -type f | sort)
npm test --prefix plugins/obsidian-tracker/mcp
npm run build --prefix plugins/obsidian-tracker/mcp
```

Expected:

- publish tests pass;
- Crashlytics fixtures pass;
- Obsidian Bats suite passes;
- Obsidian MCP Vitest suite passes;
- MCP TypeScript build passes.

- [ ] **Step 4: Run static validation**

```bash
find plugins -path '*/node_modules' -prune -o -name '*.sh' -type f -print0 |
  xargs -0 -n1 bash -n

python3 - <<'PY'
import ast
import json
from pathlib import Path

for path in Path(".").rglob("*.py"):
    if "node_modules" not in path.parts:
        ast.parse(path.read_text(encoding="utf-8"), filename=str(path))

for path in Path(".").rglob("*.json"):
    if "node_modules" not in path.parts:
        json.loads(path.read_text(encoding="utf-8"))

print("static-validation-ok")
PY
```

Expected: `static-validation-ok`.

- [ ] **Step 5: Verify git state**

```bash
git diff --check
git status --short --branch
git log --oneline --decorate -15
```

Expected: clean working tree with atomic implementation commits.

---

## Self-Review Checklist

Before implementation:

- [ ] Confirm `0.7.0` adaptation work is not pulled into this release.
- [ ] Confirm all new tests use `unittest`, not `pytest`.
- [ ] Confirm Codex policy tests use only valid values.
- [ ] Confirm deletion requires a resolved local path under `plugins_dir`.
- [ ] Confirm failed CC targets are omitted rather than assigned an invented
      disabled field.
- [ ] Confirm hook direction comes only from plugin-level state.
- [ ] Confirm ordinary sync preserves marketplace root metadata and canonical
      plugin order.
- [ ] Confirm `git add -A` is used only for explicitly requested `--stage`.
