#!/usr/bin/env python3
"""Unit tests for version_check.py. Run: python3 .github/scripts/test_version_check.py"""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import version_check  # noqa: E402

APP_ID = "11111111-1111-1111-1111-111111111111"


def app_json(version):
    return json.dumps({"id": APP_ID, "version": version})


class Fixture:
    def __init__(self, app_version="29.0.0.0", repo_version="29.0", strategy=None, dependency="1.0.0.0",
                 test_version="1.0.0.0", with_test=True):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "app").mkdir()
        (self.root / "app" / "app.json").write_text(app_json(app_version), encoding="utf-8")
        if with_test:
            (self.root / "test").mkdir()
            (self.root / "test" / "app.json").write_text(json.dumps({
                "id": "22222222-2222-2222-2222-222222222222",
                "version": test_version,
                "dependencies": [{"id": APP_ID, "version": dependency}]}), encoding="utf-8")
        settings = {"country": "us"}
        if repo_version is not None:
            settings["repoVersion"] = repo_version
        if strategy is not None:
            settings["versioningStrategy"] = strategy
        (self.root / ".AL-Go").mkdir()
        (self.root / ".AL-Go" / "settings.json").write_text(json.dumps(settings), encoding="utf-8")

    def run(self, base=None):
        return version_check.run(self.root, base)

    def close(self):
        self.tmp.cleanup()


def starting(messages, rule):
    return [m for m in messages if m.startswith(rule)]


class VersionCheckTests(unittest.TestCase):
    def fixture(self, **kwargs):
        fixture = Fixture(**kwargs)
        self.addCleanup(fixture.close)
        return fixture

    def test_real_repo_passes(self):
        errors, _, summary = version_check.run(version_check.ROOT, None)
        self.assertEqual(errors, [])
        self.assertIn("App version: 29.0.0.0", " ".join(summary))

    def test_valid_fixture_is_clean(self):
        errors, warnings, _ = self.fixture(strategy=0).run()
        self.assertEqual(errors, [])
        self.assertEqual(warnings, [])

    def test_invalid_app_version_is_ver1(self):
        errors, _, _ = self.fixture(app_version="29.0.0").run()
        self.assertEqual(len(errors), 1)
        self.assertTrue(errors[0].startswith("VER1"))

    def test_missing_app_json_is_ver1(self):
        fixture = self.fixture()
        (fixture.root / "app" / "app.json").unlink()
        errors, _, _ = fixture.run()
        self.assertTrue(errors[0].startswith("VER1"))

    def test_invalid_test_version_is_ver1(self):
        errors, _, _ = self.fixture(test_version="1.0").run()
        self.assertEqual(len(starting(errors, "VER1")), 1)

    def test_build_not_zero_is_ver2(self):
        errors, _, _ = self.fixture(app_version="29.0.5.0").run()
        self.assertEqual(len(starting(errors, "VER2")), 1)

    def test_wrong_repo_version_is_ver3(self):
        errors, _, _ = self.fixture(repo_version="1.0").run()
        self.assertEqual(len(starting(errors, "VER3")), 1)

    def test_missing_repo_version_is_ver3(self):
        errors, _, _ = self.fixture(repo_version=None).run()
        self.assertEqual(len(starting(errors, "VER3")), 1)

    def test_missing_settings_file_is_ver3(self):
        fixture = self.fixture()
        (fixture.root / ".AL-Go" / "settings.json").unlink()
        errors, _, _ = fixture.run()
        self.assertEqual(len(starting(errors, "VER3")), 1)

    def test_wrong_strategy_is_ver4(self):
        errors, _, _ = self.fixture(strategy=3).run()
        self.assertEqual(len(starting(errors, "VER4")), 1)

    def test_missing_strategy_is_not_ver4(self):
        errors, _, _ = self.fixture().run()
        self.assertEqual(starting(errors, "VER4"), [])

    def test_dependency_above_app_is_ver5(self):
        errors, _, _ = self.fixture(dependency="29.1.0.0").run()
        self.assertEqual(len(starting(errors, "VER5")), 1)

    def test_dependency_equal_to_app_is_not_ver5(self):
        errors, _, _ = self.fixture(dependency="29.0.0.0").run()
        self.assertEqual(starting(errors, "VER5"), [])

    def test_unparsable_dependency_is_ver5(self):
        errors, _, _ = self.fixture(dependency="29.0").run()
        self.assertEqual(len(starting(errors, "VER5")), 1)

    def test_missing_dependency_is_ver5(self):
        fixture = self.fixture()
        (fixture.root / "test" / "app.json").write_text(
            json.dumps({"id": "x", "version": "1.0.0.0", "dependencies": []}), encoding="utf-8")
        errors, _, _ = fixture.run()
        self.assertEqual(len(starting(errors, "VER5")), 1)

    def test_missing_test_app_skips_ver5(self):
        errors, _, summary = self.fixture(with_test=False).run()
        self.assertEqual(errors, [])
        self.assertTrue(any("VER5 skipped" in line for line in summary))

    def test_lower_than_base_is_ver6(self):
        errors, _, _ = self.fixture().run(app_json("29.1.0.0"))
        self.assertEqual(len(starting(errors, "VER6")), 1)

    def test_raised_minor_is_ver7_warning(self):
        errors, warnings, _ = self.fixture(app_version="29.1.0.0", repo_version="29.1").run(app_json("29.0.0.0"))
        self.assertEqual(errors, [])
        self.assertEqual(len(starting(warnings, "VER7")), 1)

    def test_equal_to_base_has_no_ver7(self):
        errors, warnings, _ = self.fixture().run(app_json("29.0.0.0"))
        self.assertEqual(errors, [])
        self.assertEqual(starting(warnings, "VER7"), [])

    def test_numeric_compare_not_text(self):
        errors, _, _ = self.fixture(app_version="29.10.0.0", repo_version="29.10").run(app_json("29.9.0.0"))
        self.assertEqual(starting(errors, "VER6"), [])

    def test_invalid_base_json_skips_ver6(self):
        errors, warnings, _ = self.fixture().run("not json")
        self.assertEqual(errors, [])
        self.assertEqual(len(starting(warnings, "VER6 skipped")), 1)

    def test_no_base_has_no_ver6_or_ver7(self):
        errors, warnings, _ = self.fixture().run(None)
        self.assertEqual(starting(errors, "VER6"), [])
        self.assertEqual(starting(warnings, "VER7"), [])


if __name__ == "__main__":
    unittest.main()
