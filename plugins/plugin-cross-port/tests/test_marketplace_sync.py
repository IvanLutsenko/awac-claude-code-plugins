import importlib.util
import unittest
from pathlib import Path


PLUGIN_ROOT = Path(__file__).resolve().parents[1]


def load_module():
    spec = importlib.util.spec_from_file_location(
        "marketplace_sync", PLUGIN_ROOT / "scripts" / "marketplace_sync.py"
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


ms = load_module()


class MarketplaceSyncTest(unittest.TestCase):
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
        canonical = {
            "name": "team",
            "version": "1.0.0",
            "owner": {"name": "T"},
            "plugins": [],
        }
        self.assertEqual(ms.seed_cc_marketplace(canonical)["owner"], {"name": "T"})

    def test_plugin_source_path_rejects_escape_outside_plugins_dir(self):
        with self.assertRaises(ValueError):
            ms.plugin_source_path(Path("/repo/outside/foo"), Path("/repo"), Path("plugins"))

    def test_cc_entry_recomputes_path_and_preserves_category(self):
        market = {"plugins": [{"name": "foo", "category": "testing"}]}
        ms.upsert_cc_entry(
            market,
            {"name": "foo", "version": "2.0.0", "description": "D"},
            "./plugins/foo",
            "development",
        )
        self.assertEqual(market["plugins"][0]["source"], "./plugins/foo")
        self.assertEqual(market["plugins"][0]["category"], "testing")

    def test_codex_entry_preserves_authentication_and_products(self):
        market = {
            "plugins": [
                {
                    "name": "foo",
                    "policy": {
                        "installation": "INSTALLED_BY_DEFAULT",
                        "authentication": "ON_USE",
                        "products": ["codex"],
                    },
                }
            ]
        }
        ms.upsert_codex_entry(market, {"name": "foo"}, "./plugins/foo", "synced", "Development")
        self.assertEqual(market["plugins"][0]["policy"]["authentication"], "ON_USE")
        self.assertEqual(market["plugins"][0]["policy"]["products"], ["codex"])

    def test_codex_entry_marks_failed_plugin_not_available(self):
        market = {"plugins": []}
        ms.upsert_codex_entry(market, {"name": "foo"}, "./plugins/foo", "failed", "Development")
        self.assertEqual(market["plugins"][0]["policy"]["installation"], "NOT_AVAILABLE")

    def test_reconcile_order_matches_canonical_order(self):
        market = {"plugins": [{"name": "b"}, {"name": "a"}]}
        self.assertEqual(
            [p["name"] for p in ms.reconcile_order(market, ["a", "b"])["plugins"]],
            ["a", "b"],
        )

    def test_remove_entry_drops_only_named_plugin(self):
        market = {"plugins": [{"name": "a"}, {"name": "b"}]}
        self.assertEqual([p["name"] for p in ms.remove_entry(market, "a")["plugins"]], ["b"])


if __name__ == "__main__":
    unittest.main()
