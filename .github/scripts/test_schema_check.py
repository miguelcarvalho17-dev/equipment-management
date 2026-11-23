#!/usr/bin/env python3
"""Unit tests for schema_check.py. Run: python3 .github/scripts/test_schema_check.py"""
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import schema_check  # noqa: E402

ROOT = schema_check.ROOT
NS = "namespace Test.App;\n\n"


def table(oid, name, fields=(), keys=(("PK", "\"No.\""),), props=(), ns=NS, kind="table", extends=None):
    head = f'{kind} {oid} "{name}"' + (f' extends "{extends}"' if extends else "")
    out = [ns + head, "{"]
    out += [f"    {p}" for p in props]
    out += ["    fields", "    {"]
    for fid, fname, ftype, fprops in fields:
        quoted = f'"{fname}"' if " " in fname or "." in fname else fname
        out += [f"        field({fid}; {quoted}; {ftype})", "        {"]
        out += [f"            {p}" for p in fprops]
        out += ["        }"]
    out += ["    }", "    keys", "    {"]
    for kname, kfields in keys:
        out += [f"        key({kname}; {kfields})", "        {", "        }"]
    out += ["    }", "}", ""]
    return "\n".join(out)


def enum(oid, name, values, extensible=None, props=(), ns=NS):
    out = [ns + f'enum {oid} "{name}"', "{"]
    if extensible is not None:
        out.append(f"    Extensible = {'true' if extensible else 'false'};")
    out += [f"    {p}" for p in props]
    for ordinal, vname, vprops in values:
        out += [f"    value({ordinal}; {vname})", "    {"]
        out += [f"        {p}" for p in vprops]
        out += ["    }"]
    out += ["}", ""]
    return "\n".join(out)


def codeunit(oid, name, props=(), ns=NS):
    out = [ns + f'codeunit {oid} "{name}"', "{"] + [f"    {p}" for p in props]
    out += ["    procedure Foo()", "    begin", "    end;", "}", ""]
    return "\n".join(out)


PENDING = ["ObsoleteState = Pending;", "ObsoleteReason = 'Moved.';", "ObsoleteTag = '29.1';"]
REMOVED = ["ObsoleteState = Removed;", "ObsoleteReason = 'Moved.';", "ObsoleteTag = '29.2';"]
F_NO = (1, "No.", "Code[20]", [])
F_DESC = (2, "Description", "Text[50]", [])


class Fixture:
    def __init__(self, base, head, exceptions=None):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "app" / "src").mkdir(parents=True)
        for index, text in enumerate(head):
            (self.root / "app" / "src" / f"o{index}.al").write_text(text, encoding="utf-8")
        self.base = {f"app/src/o{i}.al": text for i, text in enumerate(base)}
        self.exceptions = None
        if exceptions is not None:
            self.exceptions = self.root / "ex.json"
            self.exceptions.write_text(exceptions, encoding="utf-8")

    def run(self):
        return schema_check.run(self.root, self.base, self.exceptions)


def check(base, head, exceptions=None):
    fixture = Fixture(base, head, exceptions)
    try:
        return fixture.run()
    finally:
        fixture.tmp.cleanup()


def has(messages, text):
    return any(text in m for m in messages)


class SchemaCheckTests(unittest.TestCase):
    def test_t0_real_repo_is_consistent(self):
        errors, warnings, _ = schema_check.run(ROOT, schema_check.read_head_files(ROOT))
        self.assertEqual([], errors)
        self.assertEqual([], warnings)

    def test_t1_additive_change_passes(self):
        base = [table(50100, "T", [F_NO]), enum(50101, "E", [(0, "A", [])])]
        head = [table(50100, "T", [F_NO, F_DESC], [("PK", '"No."'), ("Desc", "Description")]),
                enum(50101, "E", [(0, "A", []), (1, "B", [])])]
        errors, warnings, _ = check(base, head)
        self.assertEqual([], errors)
        self.assertEqual([], warnings)

    def test_t2_table_removed(self):
        errors, _, _ = check([table(50100, "T", [F_NO])], [])
        self.assertTrue(has(errors, "[key: SCH01 table 50100]"))

    def test_t2n_codeunit_removed_after_pending_warns(self):
        errors, warnings, _ = check([codeunit(50101, "C", PENDING)], [])
        self.assertEqual([], errors)
        self.assertTrue(has(warnings, "SCH01"))

    def test_t3_codeunit_removed_errors(self):
        errors, _, _ = check([codeunit(50101, "C")], [])
        self.assertTrue(has(errors, "[key: SCH01 codeunit 50101]"))

    def test_t4_rename_and_extends(self):
        errors, _, _ = check([table(50100, "T", [F_NO])], [table(50100, "T2", [F_NO])])
        self.assertTrue(has(errors, "SCH02"))
        errors, _, _ = check([table(50100, "T", [F_NO])], [table(50100, "T", [F_NO])])
        self.assertEqual([], errors)
        base = [table(50100, "X", [], [], kind="tableextension", extends="Customer")]
        head = [table(50100, "X", [], [], kind="tableextension", extends="Vendor")]
        errors, _, _ = check(base, head)
        self.assertTrue(has(errors, "SCH02"))

    def test_t5_namespace(self):
        errors, _, _ = check([table(50100, "T", [F_NO])], [table(50100, "T", [F_NO], ns="namespace Other.App;\n")])
        self.assertTrue(has(errors, "SCH03"))
        errors, _, _ = check([table(50100, "T", [F_NO])], [table(50100, "T", [F_NO])])
        self.assertFalse(has(errors, "SCH03"))

    def test_t6_field_removed(self):
        errors, _, _ = check([table(50100, "T", [F_NO, F_DESC])], [table(50100, "T", [F_NO])])
        self.assertTrue(has(errors, "[key: SCH04 table 50100 field 2]"))

    def test_t6n_field_kept_removed_has_no_sch04(self):
        base = [table(50100, "T", [F_NO, (2, "Description", "Text[50]", PENDING)])]
        head = [table(50100, "T", [F_NO, (2, "Description", "Text[50]", REMOVED)])]
        errors, _, _ = check(base, head)
        self.assertFalse(has(errors, "SCH04"))
        self.assertFalse(has(errors, "SCH11"))

    def test_t7_already_removed_field_deleted(self):
        removed = ["ObsoleteState = Removed;", "ObsoleteReason = 'x';", "ObsoleteTag = '29.1';"]
        errors, _, _ = check([table(50100, "T", [F_NO, (2, "D", "Text[50]", removed)])],
                             [table(50100, "T", [F_NO])])
        self.assertTrue(has(errors, "SCH04"))

    def test_t8_case_only_rename(self):
        errors, _, _ = check([table(50100, "T", [(1, "No.", "Code[20]", [])])],
                             [table(50100, "T", [(1, "NO.", "Code[20]", [])])])
        self.assertTrue(has(errors, "SCH05"))

    def test_t9_types(self):
        def run(old, new, extra=()):
            return check([table(50100, "T", [F_NO, (2, "D", old, [])])],
                         [table(50100, "T", [F_NO, (2, "D", new, list(extra))])])
        self.assertTrue(has(run("Integer", "Text[30]")[0], "SCH06"))
        self.assertTrue(has(run("Code[20]", "Code[10]")[0], "SCH06"))
        self.assertTrue(has(run("Code[20]", "Text[20]")[0], "SCH06"))
        errors, warnings, _ = run("Text[50]", "Text[100]")
        self.assertEqual([], errors)
        self.assertTrue(has(warnings, "SCH06"))
        self.assertTrue(has(run("Decimal", "Decimal", ["FieldClass = FlowField;"])[0], "SCH06"))

    def test_t10_table_type(self):
        errors, _, _ = check([table(50100, "T", [F_NO])], [table(50100, "T", [F_NO], props=["TableType = Temporary;"])])
        self.assertTrue(has(errors, "SCH07"))

    def test_t11_keys(self):
        two = [("PK", '"No."'), ("Desc", "Description")]
        base = [table(50100, "T", [F_NO, F_DESC], two)]
        errors, _, _ = check(base, [table(50100, "T", [F_NO, F_DESC], [("PK", "Description"), ("Desc", "Description")])])
        self.assertTrue(has(errors, "SCH08"))
        errors, _, _ = check(base, [table(50100, "T", [F_NO, F_DESC], [("PK", '"No."')])])
        self.assertTrue(has(errors, "[key: SCH08 table 50100 key Desc]"))
        multi = [("PK", '"No."'), ("Two", 'Description, "No."')]
        errors, _, _ = check([table(50100, "T", [F_NO, F_DESC], multi)],
                             [table(50100, "T", [F_NO, F_DESC], [("PK", '"No."'), ("Two", '"No.", Description')])])
        self.assertTrue(has(errors, "SCH08"))

    def test_t11n_secondary_key_removed_after_pending(self):
        base_text = table(50100, "T", [F_NO, F_DESC], [("PK", '"No."'), ("Desc", "Description")])
        base_text = base_text.replace("        key(Desc; Description)\n        {\n",
                                      "        key(Desc; Description)\n        {\n            ObsoleteState = Pending;\n")
        errors, warnings, _ = check([base_text], [table(50100, "T", [F_NO, F_DESC])])
        self.assertEqual([], errors)
        self.assertTrue(has(warnings, "SCH08"))

    def test_t12_enum_values(self):
        base = [enum(50101, "E", [(0, "A", []), (3, "C", [])])]
        errors, _, _ = check(base, [enum(50101, "E", [(0, "A", [])])])
        self.assertTrue(has(errors, "[key: SCH09 enum 50101 value 3]"))
        errors, _, _ = check(base, [enum(50101, "E", [(0, "A", []), (3, "D", [])])])
        self.assertTrue(has(errors, "SCH09"))
        pending = [enum(50101, "E", [(0, "A", []), (3, "C", [])], props=PENDING)]
        errors, warnings, _ = check(pending, [enum(50101, "E", [(0, "A", [])], props=PENDING)])
        self.assertEqual([], errors)
        self.assertTrue(has(warnings, "SCH09"))
        ext = NS + 'enumextension 50100 "X" extends "Y"\n{\n    value(5; V)\n    {\n    }\n}\n'
        ext_head = NS + 'enumextension 50100 "X" extends "Y"\n{\n}\n'
        errors, _, _ = check([ext], [ext_head])
        self.assertTrue(has(errors, "SCH09"))

    def test_t13_extensible(self):
        base = [enum(50101, "E", [(0, "A", [])], extensible=True)]
        errors, _, _ = check(base, [enum(50101, "E", [(0, "A", [])])])
        self.assertTrue(has(errors, "SCH10"))
        errors, warnings, _ = check([enum(50101, "E", [(0, "A", [])], extensible=False)],
                                    [enum(50101, "E", [(0, "A", [])], extensible=True)])
        self.assertEqual([], errors)
        self.assertTrue(has(warnings, "SCH10"))

    def test_t14_obsolete_transitions(self):
        def run(old, new):
            return check([table(50100, "T", [F_NO, (2, "D", "Text[50]", old)])],
                         [table(50100, "T", [F_NO, (2, "D", "Text[50]", new)])])[0]
        removed = ["ObsoleteState = Removed;", "ObsoleteReason = 'x';", "ObsoleteTag = '29.1';"]
        self.assertTrue(has(run([], removed), "SCH11"))
        self.assertTrue(has(run(removed, PENDING), "SCH11"))
        self.assertFalse(has(run(PENDING, removed), "SCH11"))
        self.assertEqual([], run(PENDING, []))

    def test_t15_obsolete_metadata(self):
        def run(props):
            return check([table(50100, "T", [F_NO, (2, "D", "Text[50]", [])])],
                         [table(50100, "T", [F_NO, (2, "D", "Text[50]", props)])])[0]
        self.assertTrue(has(run(["ObsoleteState = Pending;", "ObsoleteReason = 'x';"]), "SCH12"))
        self.assertTrue(has(run(["ObsoleteState = Pending;", "ObsoleteReason = 'x';", "ObsoleteTag = 'v2';"]), "SCH12"))
        self.assertTrue(has(run(["ObsoleteState = Pending;", "ObsoleteReason = '';", "ObsoleteTag = '29.1';"]), "SCH12"))
        self.assertFalse(has(run(PENDING), "SCH12"))

    def test_t16_data_warning(self):
        errors, warnings, _ = check([table(50100, "T", [F_NO, (2, "D", "Text[50]", [])])],
                                    [table(50100, "T", [F_NO, (2, "D", "Text[50]", PENDING)])])
        self.assertEqual([], errors)
        self.assertEqual(1, len(warnings))
        self.assertIn("SCH13", warnings[0])

    def test_t17_exceptions(self):
        base = [table(50100, "T", [F_NO, F_DESC])]
        head = [table(50100, "T", [F_NO])]
        key = "SCH04 table 50100 field 2"
        good = json.dumps({"accepted": [{"key": key, "reason": "Pre-release.", "decision": "DECISIONS.md FR-1"}]})
        errors, warnings, summary = check(base, head, good)
        self.assertEqual([], errors)
        self.assertTrue(has(warnings, "Accepted: Pre-release."))
        self.assertIn("1 accepted", summary[0])
        bad = json.dumps({"accepted": [{"key": key, "reason": "Pre-release."}]})
        errors, _, _ = check(base, head, bad)
        self.assertTrue(has(errors, "SCH14"))
        self.assertTrue(has(errors, "SCH04"))
        stale = json.dumps({"accepted": [{"key": "SCH04 table 1 field 1", "reason": "r", "decision": "d"}]})
        _, warnings, _ = check(base, base, stale)
        self.assertTrue(has(warnings, "SCH14 stale entry"))
        errors, _, _ = check(base, base, "{not json")
        self.assertTrue(has(errors, "SCH14"))
        errors, _, _ = check(base, base, "{}")
        self.assertTrue(has(errors, "SCH14"))

    def test_t18_robustness(self):
        text = (NS + 'table 50100 "T"\n{\n    // field(9; X; Integer)\n    /* key(Old; X)\n    {\n    } */\n'
                "    Caption = 'a { b';\n    fields\n    {\n        field(1; \"No.\"; Code[20])\n        {\n"
                "            Caption = 'x {';\n        }\n    }\n    keys\n    {\n        key(PK; \"No.\")\n"
                "        {\n        }\n    }\n}\n")
        obj = schema_check.parse_sources({"app/a.al": text})[("table", 50100)]
        self.assertEqual([1], list(obj["fields"]))
        self.assertEqual(["PK"], [k["name"] for k in obj["keys"]])
        broken = NS + 'table 50100 "T"\n{\n    fields\n    {\n        field(1; A; Integer)\n        {\n'
        parsed = schema_check.parse_sources({"app/b.al": broken})
        self.assertIn(("table", 50100), parsed)

    def test_t19_object_state_not_from_field(self):
        obj = schema_check.parse_sources(
            {"a.al": table(50100, "T", [(2, "D", "Text[50]", PENDING)])})[("table", 50100)]
        self.assertEqual("no", schema_check.state(obj["props"]))
        self.assertEqual("pending", schema_check.state(obj["fields"][2]["props"]))

    def test_t20_no_base(self):
        errors, warnings, summary = schema_check.run(ROOT, None)
        self.assertEqual([], errors)
        self.assertIn("skipped", summary[0])
        self.assertTrue(has(warnings, "SCH00"))

    def test_t20b_unreadable_base_prints_no_ok(self):
        script = Path(__file__).resolve().parent / "schema_check.py"
        result = subprocess.run([sys.executable, str(script), "--base", "no-such-ref"],
                                cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(0, result.returncode)
        self.assertIn("Schema check: skipped", result.stdout)
        self.assertIn("::warning::SCH00", result.stdout)
        self.assertNotIn("Schema check: OK", result.stdout)

    def test_t21_read_base_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp)
            (repo / "app" / "src").mkdir(parents=True)
            (repo / "app" / "src" / "a.al").write_text("table 1 X\n{\n}\n", encoding="utf-8")
            (repo / "app" / "app.json").write_text("{}", encoding="utf-8")

            def git(*args):
                subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", *args],
                               cwd=repo, check=True, capture_output=True)
            git("init", "-q")
            git("add", ".")
            git("commit", "-q", "-m", "init")
            files = schema_check.read_base_files(repo, "HEAD")
            self.assertEqual(["app/src/a.al"], list(files))
            self.assertIn("table 1 X", files["app/src/a.al"])
            self.assertIsNone(schema_check.read_base_files(repo, "no-such-ref"))


if __name__ == "__main__":
    unittest.main()
