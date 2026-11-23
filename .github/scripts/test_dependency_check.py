#!/usr/bin/env python3
"""Unit tests for dependency_check.py. Run: python3 .github/scripts/test_dependency_check.py"""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import dependency_check  # noqa: E402

APP_ID = "11111111-1111-1111-1111-111111111111"
ASSERT_ID = "dd0be2ea-f733-4d65-bb34-a28f4624fb14"


def default_app():
    return {"id": APP_ID, "name": "App", "application": "29.0.0.0", "platform": "1.0.0.0",
            "runtime": "18.0", "target": "Cloud", "dependencies": []}


def default_test():
    return {"id": "22222222-2222-2222-2222-222222222222", "name": "App Tests",
            "application": "29.0.0.0", "platform": "1.0.0.0", "runtime": "18.0", "target": "Cloud",
            "dependencies": [
                {"id": APP_ID, "name": "App", "publisher": "Pub", "version": "1.0.0.0"},
                {"id": ASSERT_ID, "name": "Library Assert", "publisher": "Microsoft", "version": "29.0.0.0"}]}


def matrix_doc(app, test, extra=""):
    lines = ["| Property | app | test | Meaning |", "|---|---|---|---|"]
    for prop in dependency_check.PLATFORM_PROPS:
        app_value = str(app.get(prop, "none")) if app is not None else "none"
        test_value = str(test.get(prop, "none")) if test is not None else "none"
        lines.append(f"| `{prop}` | `{app_value}` | `{test_value}` | text |")
    ids = []
    for manifest in (app, test):
        if manifest:
            ids += [d["id"] for d in manifest.get("dependencies", [])]
    return "\n".join(lines) + "\n\n" + "\n".join(f"- {i}" for i in ids) + "\n" + extra


class Fixture:
    def __init__(self, app=None, test="default", doc="default"):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.app = default_app() if app is None else app
        self.test = default_test() if test == "default" else test
        (self.root / "app").mkdir()
        (self.root / "app" / "app.json").write_text(json.dumps(self.app), encoding="utf-8")
        if self.test is not None:
            (self.root / "test").mkdir()
            (self.root / "test" / "app.json").write_text(json.dumps(self.test), encoding="utf-8")
        if doc == "default":
            doc = matrix_doc(self.app, self.test)
        if doc is not None:
            (self.root / "docs" / "architecture").mkdir(parents=True)
            (self.root / "docs" / "architecture" / "dependencies.md").write_text(doc, encoding="utf-8")

    def run(self, base_texts=None):
        return dependency_check.run(self.root, base_texts)

    def close(self):
        self.tmp.cleanup()


def starting(messages, rule):
    return [m for m in messages if m.startswith(rule)]


class DependencyCheckTests(unittest.TestCase):
    def fixture(self, **kwargs):
        fixture = Fixture(**kwargs)
        self.addCleanup(fixture.close)
        return fixture

    def test_real_repo_passes(self):
        errors, warnings, _ = dependency_check.run(dependency_check.ROOT, None)
        self.assertEqual(errors, [])
        self.assertEqual(warnings, [])

    def test_consistent_fixture_is_clean(self):
        errors, warnings, summary = self.fixture().run()
        self.assertEqual(errors, [])
        self.assertEqual(warnings, [])
        self.assertIn("application 29.0.0.0, runtime 18.0", " ".join(summary))

    def test_invalid_app_json_is_only_dep1(self):
        fixture = self.fixture()
        (fixture.root / "app" / "app.json").write_text("{not json", encoding="utf-8")
        errors, _, _ = fixture.run()
        self.assertEqual(len(errors), 1)
        self.assertTrue(errors[0].startswith("DEP1"))

    def test_test_manifest_without_runtime_is_dep1(self):
        test = default_test()
        del test["runtime"]
        errors, _, _ = self.fixture(test=test).run()
        dep1 = starting(errors, "DEP1")
        self.assertEqual(len(dep1), 1)
        self.assertIn("test/app.json", dep1[0])

    def test_runtime_mismatch_is_dep2(self):
        test = default_test()
        test["runtime"] = "17.0"
        errors, _, _ = self.fixture(test=test).run()
        self.assertEqual(len(starting(errors, "DEP2")), 1)

    def test_same_values_have_no_dep2(self):
        errors, _, _ = self.fixture().run()
        self.assertEqual(starting(errors, "DEP2"), [])

    def test_system_application_dependency_is_dep3(self):
        test = default_test()
        test["dependencies"].append({
            "id": dependency_check.SYSTEM_APPLICATION_ID, "name": "System Application",
            "publisher": "Microsoft", "version": "29.0.0.0"})
        errors, _, _ = self.fixture(test=test).run()
        self.assertEqual(len(starting(errors, "DEP3")), 1)

    def test_library_assert_only_has_no_dep3(self):
        errors, _, _ = self.fixture().run()
        self.assertEqual(starting(errors, "DEP3"), [])

    def test_missing_doc_is_dep4(self):
        errors, _, _ = self.fixture(doc=None).run()
        dep4 = starting(errors, "DEP4")
        self.assertEqual(len(dep4), 1)
        self.assertIn("is missing", dep4[0])

    def test_doc_without_dependency_id_is_dep4(self):
        fixture = self.fixture()
        doc = matrix_doc(fixture.app, fixture.test).replace(ASSERT_ID, "")
        (fixture.root / "docs" / "architecture" / "dependencies.md").write_text(doc, encoding="utf-8")
        errors, _, _ = fixture.run()
        dep4 = starting(errors, "DEP4")
        self.assertEqual(len(dep4), 1)
        self.assertIn(ASSERT_ID, dep4[0])

    def test_doc_row_with_old_application_is_dep4(self):
        fixture = self.fixture()
        doc = matrix_doc(fixture.app, fixture.test).replace("`29.0.0.0`", "`28.0.0.0`")
        (fixture.root / "docs" / "architecture" / "dependencies.md").write_text(doc, encoding="utf-8")
        errors, _, _ = fixture.run()
        self.assertEqual(len(starting(errors, "DEP4")), 1)
        self.assertIn("`application`", errors[0])

    def test_uppercase_manifest_id_matches_lowercase_doc(self):
        test = default_test()
        test["dependencies"][1]["id"] = ASSERT_ID.upper()
        fixture = self.fixture(test=test, doc=matrix_doc(default_app(), default_test()))
        errors, _, _ = fixture.run()
        self.assertEqual(starting(errors, "DEP4"), [])

    def test_version_above_application_is_dep5(self):
        test = default_test()
        test["dependencies"][1]["version"] = "30.0.0.0"
        errors, _, _ = self.fixture(test=test).run()
        self.assertEqual(len(starting(errors, "DEP5")), 1)

    def test_bad_version_format_is_dep5(self):
        test = default_test()
        test["dependencies"][1]["version"] = "29.0"
        errors, _, _ = self.fixture(test=test).run()
        dep5 = starting(errors, "DEP5")
        self.assertEqual(len(dep5), 1)
        self.assertIn("not Major.Minor.Build.Revision", dep5[0])

    def test_equal_version_and_non_microsoft_above_application_have_no_dep5(self):
        test = default_test()
        test["dependencies"][0]["version"] = "99.0.0.0"
        errors, _, _ = self.fixture(test=test).run()
        self.assertEqual(starting(errors, "DEP5"), [])

    def test_base_with_old_runtime_is_one_dep6_warning(self):
        fixture = self.fixture()
        base_app = default_app()
        base_app["runtime"] = "17.0"
        errors, warnings, _ = fixture.run({
            "app/app.json": json.dumps(base_app), "test/app.json": json.dumps(default_test())})
        self.assertEqual(errors, [])
        self.assertEqual(len(starting(warnings, "DEP6")), 1)
        self.assertEqual(len(warnings), 1)

    def test_base_without_library_assert_is_added_warning(self):
        base_test = default_test()
        del base_test["dependencies"][1]
        _, warnings, _ = self.fixture().run({
            "app/app.json": json.dumps(default_app()), "test/app.json": json.dumps(base_test)})
        self.assertEqual(len(warnings), 1)
        self.assertIn("added", warnings[0])

    def test_base_with_other_version_is_version_changed_warning(self):
        base_test = default_test()
        base_test["dependencies"][1]["version"] = "28.0.0.0"
        _, warnings, _ = self.fixture().run({
            "app/app.json": json.dumps(default_app()), "test/app.json": json.dumps(base_test)})
        self.assertEqual(len(warnings), 1)
        self.assertIn("version changed from 28.0.0.0 to 29.0.0.0", warnings[0])

    def test_identical_base_has_no_warning(self):
        _, warnings, _ = self.fixture().run({
            "app/app.json": json.dumps(default_app()), "test/app.json": json.dumps(default_test())})
        self.assertEqual(warnings, [])

    def test_unreadable_base_skips_dep6(self):
        errors, warnings, summary = self.fixture().run({"app/app.json": None, "test/app.json": None})
        self.assertEqual(errors, [])
        self.assertEqual(warnings, [])
        self.assertEqual(len(starting(summary, "DEP6 skipped")), 2)

    def test_no_test_app_skips_dep2_and_dep5(self):
        errors, _, summary = self.fixture(test=None).run()
        self.assertEqual(errors, [])
        self.assertIn("DEP2 and DEP5 skipped", " ".join(summary))

    def test_read_base_texts(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        (root / "app").mkdir()
        (root / "app" / "app.json").write_text("{}", encoding="utf-8")
        for args in (["init", "-q"], ["add", "."],
                     ["-c", "user.name=t", "-c", "user.email=t@example.com", "commit", "-q", "-m", "x"]):
            subprocess.run(["git", *args], cwd=root, check=True, capture_output=True)
        texts = dependency_check.read_base_texts(root, "HEAD")
        self.assertEqual(texts["app/app.json"], "{}")
        self.assertIsNone(texts["test/app.json"])
        unknown = dependency_check.read_base_texts(root, "no-such-ref")
        self.assertEqual(unknown, {"app/app.json": None, "test/app.json": None})


if __name__ == "__main__":
    unittest.main()
