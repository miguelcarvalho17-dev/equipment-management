#!/usr/bin/env python3
"""Unit tests for coverage_check.py. Run: python3 .github/scripts/test_coverage_check.py"""
import json
import os
import sys
import tempfile
import unittest
from unittest import mock
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import coverage_check  # noqa: E402

LOGIC_FILE = "app/src/Mgt.Codeunit.al"
CP_FILE = "app/src/Rule.Codeunit.al"
API_FILE = "app/src/Api.Page.al"
EQUIPMENT_API = "EQM Equipment API"


def codeunit(unit_id, name, body):
    return f'codeunit {unit_id} "{name}"\n{{\n{body}\n}}\n'


def test_codeunit(tests):
    """tests: [(name, attributes, body)] -> a test codeunit 50999."""
    text = ""
    for name, attrs, body in tests:
        text += f"    {attrs}\n    procedure {name}()\n    begin\n{body}\n    end;\n\n"
    return codeunit(50999, "EQM Fixture Tests", text)


def proc(modifier, name, body="        exit;"):
    return f"    {modifier}procedure {name}()\n    begin\n{body}\n    end;\n\n"


class Fixture:
    def __init__(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "app" / "src").mkdir(parents=True)
        (self.root / "test" / "src").mkdir(parents=True)
        self.register = {"enforce": False, "targets": {"businessLogic": 80, "criticalProcesses": 100, "apis": 80},
                         "scope": {"businessLogic": {"tables": [], "codeunits": []}, "apis": {"pages": []}},
                         "criticalProcesses": [], "traces": []}

    def app(self, rel, text):
        (self.root / rel).write_text(text, encoding="utf-8")

    def tests(self, text, name="Fixture.Codeunit.al"):
        (self.root / "test" / "src" / name).write_text(text, encoding="utf-8")

    def logic(self, *members, unit_id=50100, name="EQM Mgt"):
        self.app(LOGIC_FILE, codeunit(unit_id, name, "".join(members)))
        self.register["scope"]["businessLogic"]["codeunits"].append(unit_id)

    def run(self):
        path = self.root / "register.json"
        path.write_text(json.dumps(self.register), encoding="utf-8")
        return coverage_check.run(self.root, path)

    def close(self):
        self.tmp.cleanup()


def logic_percent(lines):
    line = next(item for item in lines if item.startswith("Business Logic procedure reach"))
    return float(line.split(":")[1].split("%")[0])


def cp_percent(lines):
    line = next(item for item in lines if item.startswith("Critical Process rule coverage"))
    return float(line.split(":")[1].split("%")[0])


class CoverageCheckCase(unittest.TestCase):
    def setUp(self):
        self.fx = Fixture()
        self.addCleanup(self.fx.close)

    def rule_fixture(self, positive, negative, gap=False, extra_site=False):
        sites = "        Error(NewErr, 'x');\n" if extra_site else ""
        self.fx.app(CP_FILE, codeunit(50101, "EQM Rule",
                                      proc("internal ", "Check", "        Error(KnownErr);\n" + sites)))
        rule = {"file": CP_FILE, "procedure": "Check", "key": "KnownErr", "positive": positive,
                "negative": negative}
        if gap:
            rule["gap"] = True
        self.fx.register["criticalProcesses"] = [{"id": "CP1", "name": "X", "rules": [rule],
                                                  "objects": [{"type": "codeunit", "id": 50101}]}]

    def has_error(self, errors, *fragments):
        return any(all(f in e for f in fragments) for e in errors)


class MappingIntegrity(CoverageCheckCase):
    def test_mapped_test_exists(self):
        # [GIVEN] codeunit 50999 with [Test] Foo, and a rule mapped positive and negative to it
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        exit;")]))
        ref = [{"codeunit": 50999, "test": "Foo"}]
        self.rule_fixture(ref, ref)
        # [WHEN] run
        errors, _, lines = self.fx.run()
        # [THEN] no errors and CP = 100%
        self.assertEqual([], errors)
        self.assertEqual(100.0, cp_percent(lines))

    def test_mapped_test_is_missing(self):
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        exit;")]))
        self.rule_fixture([{"codeunit": 50999, "test": "Foo"}], [{"codeunit": 50999, "test": "Bar"}])
        errors, _, _ = self.fx.run()
        self.assertTrue(self.has_error(errors, "50999", "Bar"), errors)

    def test_mapped_procedure_is_not_a_test(self):
        self.fx.tests(test_codeunit([("Foo", "", "        exit;")]))
        ref = [{"codeunit": 50999, "test": "Foo"}]
        self.rule_fixture(ref, ref)
        errors, _, _ = self.fx.run()
        self.assertTrue(self.has_error(errors, "50999", "Foo"), errors)

    def test_rule_site_is_not_registered(self):
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        exit;")]))
        ref = [{"codeunit": 50999, "test": "Foo"}]
        self.rule_fixture(ref, ref, extra_site=True)
        errors, _, _ = self.fx.run()
        self.assertTrue(self.has_error(errors, CP_FILE, "NewErr"), errors)

    def test_gap_lowers_cp_coverage(self):
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        exit;")]))
        ref = [{"codeunit": 50999, "test": "Foo"}]
        self.rule_fixture(ref, ref)
        self.fx.app(CP_FILE, codeunit(50101, "EQM Rule",
                                      proc("internal ", "Check", "        Error(KnownErr);\n        Error(OtherErr);")))
        second = {"file": CP_FILE, "procedure": "Check", "key": "OtherErr", "positive": [], "negative": [],
                  "gap": True}
        self.fx.register["criticalProcesses"][0]["rules"].append(second)
        errors, warnings, lines = self.fx.run()
        self.assertEqual(50.0, cp_percent(lines))
        self.assertEqual([], errors)
        self.assertTrue(any("Critical Process" in w for w in warnings), warnings)

    def test_unconditional_rule_needs_no_positive_test(self):
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        exit;")]))
        self.rule_fixture([], [{"codeunit": 50999, "test": "Foo"}])
        self.fx.register["criticalProcesses"][0]["rules"][0]["positiveNotApplicable"] = True
        self.fx.register["criticalProcesses"][0]["rules"][0]["note"] = "Unconditional rule."
        errors, _, lines = self.fx.run()
        self.assertEqual([], errors)
        self.assertEqual(100.0, cp_percent(lines))

    def test_duplicate_site_needs_its_own_entry(self):
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        exit;")]))
        ref = [{"codeunit": 50999, "test": "Foo"}]
        self.rule_fixture(ref, ref)
        self.fx.app(CP_FILE, codeunit(50101, "EQM Rule",
                                      proc("internal ", "Check", "        Error(KnownErr);\n        Error(KnownErr);")))
        errors, _, _ = self.fx.run()
        self.assertTrue(self.has_error(errors, "KnownErr#2"), errors)

    def test_not_applicable_flag_needs_a_note(self):
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        exit;")]))
        self.rule_fixture([], [{"codeunit": 50999, "test": "Foo"}])
        rule = self.fx.register["criticalProcesses"][0]["rules"][0]
        rule["positiveNotApplicable"] = True
        errors, _, _ = self.fx.run()
        self.assertTrue(self.has_error(errors, "positiveNotApplicable", "note"), errors)
        rule["note"] = "Unconditional rule."
        errors, _, _ = self.fx.run()
        self.assertEqual([], errors)

    def test_stale_register_entry_is_an_error(self):
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        exit;")]))
        ref = [{"codeunit": 50999, "test": "Foo"}]
        self.rule_fixture(ref, ref)
        self.fx.register["criticalProcesses"][0]["rules"].append(
            {"file": CP_FILE, "procedure": "Check", "key": "GoneErr", "positive": ref, "negative": ref})
        errors, _, _ = self.fx.run()
        self.assertTrue(self.has_error(errors, "GoneErr", "no matching"), errors)

    def test_missing_in_scope_object_is_an_error(self):
        self.fx.register["scope"]["businessLogic"]["codeunits"].append(59999)
        errors, _, _ = self.fx.run()
        self.assertTrue(self.has_error(errors, "59999"), errors)

    def test_traced_member_must_exist(self):
        self.fx.logic(proc("internal ", "Calc"))
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        exit;")]))
        self.fx.register["traces"] = [{"type": "codeunit", "id": 50100, "member": "Nope",
                                       "tests": [{"codeunit": 50999, "test": "Foo"}]}]
        errors, _, _ = self.fx.run()
        self.assertTrue(self.has_error(errors, "Nope"), errors)


class ProcedureReach(CoverageCheckCase):
    def test_called_procedure_is_reached(self):
        self.fx.logic(proc("internal ", "Calc"))
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        Mgt.Calc();")]))
        errors, _, lines = self.fx.run()
        self.assertEqual([], errors)
        self.assertEqual(100.0, logic_percent(lines))

    def test_call_without_parentheses_is_reached(self):
        self.fx.logic(proc("internal ", "Calc"))
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        Rec.Calc;")]))
        _, _, lines = self.fx.run()
        self.assertEqual(100.0, logic_percent(lines))

    def test_declaration_is_not_a_call(self):
        self.fx.logic(proc("internal ", "Calc"))
        helper = "    local procedure Calc()\n    begin\n        exit;\n    end;\n"
        self.fx.tests(codeunit(50999, "EQM Fixture Tests",
                               "    [Test]\n    procedure Foo()\n    begin\n        exit;\n    end;\n\n" + helper))
        _, _, lines = self.fx.run()
        self.assertEqual(0.0, logic_percent(lines))

    def test_comment_is_not_a_call(self):
        self.fx.logic(proc("internal ", "Calc"))
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        // Calc(\n        exit;")]))
        _, _, lines = self.fx.run()
        self.assertEqual(0.0, logic_percent(lines))

    def test_ambiguous_across_objects_needs_a_trace(self):
        self.fx.logic(proc("internal ", "GetStatusStyle"), unit_id=50100, name="EQM One")
        self.fx.app("app/src/Two.Codeunit.al", codeunit(50101, "EQM Two", proc("internal ", "GetStatusStyle")))
        self.fx.register["scope"]["businessLogic"]["codeunits"].append(50101)
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        Rec.GetStatusStyle();")]))
        _, _, lines = self.fx.run()
        self.assertEqual(0.0, logic_percent(lines))

    def test_ambiguous_with_a_test_helper_needs_a_trace(self):
        self.fx.logic(proc("internal ", "CountAssignments"))
        helper = "    local procedure CountAssignments(): Integer\n    begin\n        exit(0);\n    end;\n"
        self.fx.tests(codeunit(50999, "EQM Fixture Tests",
                               "    [Test]\n    procedure Foo()\n    begin\n        CountAssignments();\n    end;\n\n"
                               + helper))
        _, _, lines = self.fx.run()
        self.assertEqual(0.0, logic_percent(lines))

    def test_trace_covers_an_ambiguous_member(self):
        self.fx.logic(proc("internal ", "CountAssignments"))
        helper = "    local procedure CountAssignments(): Integer\n    begin\n        exit(0);\n    end;\n"
        self.fx.tests(codeunit(50999, "EQM Fixture Tests",
                               "    [Test]\n    procedure Foo()\n    begin\n        CountAssignments();\n    end;\n\n"
                               + helper))
        self.fx.register["traces"] = [{"type": "codeunit", "id": 50100, "member": "CountAssignments",
                                       "tests": [{"codeunit": 50999, "test": "Foo"}]}]
        errors, _, lines = self.fx.run()
        self.assertEqual([], errors)
        self.assertEqual(100.0, logic_percent(lines))

    def test_local_procedures_and_publishers_are_excluded(self):
        publisher = "    [IntegrationEvent(false, false)]\n    local procedure OnBeforeX()\n    begin\n    end;\n\n"
        self.fx.logic(proc("local ", "Helper"), publisher, proc("internal ", "Calc"))
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        Rec.Calc();")]))
        _, _, lines = self.fx.run()
        line = next(item for item in lines if item.startswith("Business Logic"))
        self.assertIn("(1/1,", line)

    def test_subscriber_needs_a_trace(self):
        subscriber = ("    [EventSubscriber(ObjectType::Table, Database::Foo, 'OnAfterInsertEvent', '', false, false)]\n"
                      "    local procedure Sub()\n    begin\n    end;\n\n")
        self.fx.logic(subscriber)
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        Mgt.Sub();")]))
        _, _, lines = self.fx.run()
        self.assertEqual(0.0, logic_percent(lines))
        self.fx.register["traces"] = [{"type": "codeunit", "id": 50100, "member": "Sub",
                                       "tests": [{"codeunit": 50999, "test": "Foo"}]}]
        _, _, lines = self.fx.run()
        self.assertEqual(100.0, logic_percent(lines))

    def test_onrun_is_reached_through_codeunit_run(self):
        self.fx.logic("    trigger OnRun()\n    begin\n    end;\n\n", name="EQM X")
        self.fx.tests(test_codeunit([("Foo", "[Test]", '        Codeunit.Run(Codeunit::"EQM X", Rec);')]))
        _, _, lines = self.fx.run()
        self.assertEqual(100.0, logic_percent(lines))


class ApiPages(CoverageCheckCase):
    def api_fixture(self, test_body):
        self.fx.app(API_FILE, f'page 50123 "{EQUIPMENT_API}"\n{{\n    trigger OnOpenPage()\n    begin\n    end;\n}}\n')
        self.fx.register["scope"]["apis"]["pages"] = [50123]
        self.fx.tests(test_codeunit([("Foo", "[Test]", test_body)]))
        self.fx.register["traces"] = [{"type": "page", "id": 50123, "member": "OnOpenPage",
                                       "tests": [{"codeunit": 50999, "test": "Foo"}]}]

    def test_api_trace_to_a_table_procedure_test_is_an_error(self):
        self.api_fixture("        Equipment.AssignEmployee('X');")
        errors, _, lines = self.fx.run()
        self.assertTrue(self.has_error(errors, "50123", "Foo"), errors)
        self.assertTrue(any(item.startswith("API procedure reach: 0.0%") for item in lines), lines)

    def test_api_trace_to_a_page_test_covers_the_member(self):
        self.api_fixture(f'        EquipmentApi.OpenView();\n        TestPage "{EQUIPMENT_API}";')
        errors, _, lines = self.fx.run()
        self.assertEqual([], errors)
        self.assertTrue(any(item.startswith("API procedure reach: 100.0%") for item in lines), lines)


class EnforcementAndOutput(CoverageCheckCase):
    def test_enforce_turns_a_shortfall_into_an_error(self):
        self.fx.logic(proc("internal ", "Calc"), proc("internal ", "Other"))
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        Mgt.Calc();")]))
        self.fx.register["enforce"] = True
        errors, warnings, lines = self.fx.run()
        self.assertEqual(50.0, logic_percent(lines))
        self.assertTrue(self.has_error(errors, "Business Logic"), errors)
        self.assertFalse(any("Business Logic" in w for w in warnings))

    def test_shortfall_only_warns_without_enforce(self):
        self.fx.logic(proc("internal ", "Calc"), proc("internal ", "Other"))
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        Mgt.Calc();")]))
        errors, warnings, _ = self.fx.run()
        self.assertEqual([], errors)
        self.assertTrue(any("Business Logic" in w for w in warnings), warnings)

    def test_step_summary_has_a_three_row_table(self):
        self.fx.logic(proc("internal ", "Calc"))
        self.fx.tests(test_codeunit([("Foo", "[Test]", "        Mgt.Calc();")]))
        summary = self.fx.root / "summary.md"
        with mock.patch.dict(os.environ, {"GITHUB_STEP_SUMMARY": str(summary)}):
            self.fx.run()
        rows = [line for line in summary.read_text(encoding="utf-8").splitlines()
                if line.startswith("| ") and not line.startswith("| Area") and not line.startswith("|---")]
        self.assertEqual(3, len(rows), rows)
        self.assertIn("procedure reach", summary.read_text(encoding="utf-8"))


class Parsing(unittest.TestCase):
    def test_strip_comments_keeps_double_slash_inside_strings(self):
        text = "x := 'http://a'; // gone\n/// doc\ny := 1;"
        out = coverage_check.strip_comments(text)
        self.assertIn("http://a", out)
        self.assertNotIn("gone", out)
        self.assertNotIn("doc", out)


if __name__ == "__main__":
    unittest.main()
