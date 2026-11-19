#!/usr/bin/env python3
"""Unit tests for xlf_sync.py. Run: python3 .github/scripts/test_xlf_sync.py"""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import xlf_sync  # noqa: E402

HEADER = ('﻿<?xml version="1.0" encoding="utf-8"?>\n'
          '<xliff version="1.2" xmlns="urn:oasis:names:tc:xliff:document:1.2" '
          'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
          'xsi:schemaLocation="urn:oasis:names:tc:xliff:document:1.2 xliff-core-1.2-transitional.xsd">\n')

UNITS = [
    ("Table 1 - NamedType 1", None, "Value %1 of %2", "%1 = first, %2 = second"),
    ("Table 1 - Property 2", 10, "Laptop", ""),
    ("Table 1 - Property 3", None, "Description", ""),
]


def g_text(units=UNITS):
    lines = [HEADER.rstrip("\n")]
    lines.append('  <file datatype="xml" source-language="en-US" target-language="en-US" original="Equipment Management">')
    lines.append("    <body>")
    lines.append('      <group id="body">')
    for unit_id, maxwidth, source, developer in units:
        width = f' maxwidth="{maxwidth}"' if maxwidth else ""
        lines.append(f'        <trans-unit id="{unit_id}"{width} size-unit="char" translate="yes" xml:space="preserve">')
        lines.append(f"          <source>{source}</source>")
        lines.append(f'          <note from="Developer" annotates="general" priority="2">{developer}</note>')
        lines.append(f'          <note from="Xliff Generator" annotates="general" priority="3">{unit_id}</note>')
        lines.append("        </trans-unit>")
    lines.append("      </group>")
    lines.append("    </body>")
    lines.append("  </file>")
    lines.append("</xliff>")
    return "\n".join(lines)


class Fixture:
    def __init__(self, units=UNITS):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / xlf_sync.TRANSLATIONS).mkdir(parents=True)
        self.write_g(units)
        self.batch = self.root / "batch.json"

    def write_g(self, units):
        (self.root / xlf_sync.G_XLF).write_bytes(g_text(units).encode("utf-8"))

    def path(self, lang):
        return self.root / xlf_sync.language_path(lang)

    def text(self, lang):
        return self.path(lang).read_text(encoding="utf-8")

    def units(self, lang):
        return {u["id"]: u for u in xlf_sync.parse_file(self.path(lang))[1]}

    def sync(self):
        return xlf_sync.sync(self.root)

    def run(self):
        return xlf_sync.run(self.root)

    def translate_all(self, lang, prefix="T:"):
        entries = [{"source": u["source"], "target": prefix + u["source"]}
                   for u in xlf_sync.parse_file(self.root / xlf_sync.G_XLF)[1]]
        self.batch.write_text(json.dumps(entries), encoding="utf-8")
        return xlf_sync.import_batch(self.root, lang, self.batch)

    def complete(self):
        self.sync()
        for lang in xlf_sync.LANGUAGES:
            self.translate_all(lang)

    def replace(self, lang, old, new):
        text = self.text(lang)
        assert old in text, old
        self.path(lang).write_bytes(text.replace(old, new, 1).encode("utf-8"))

    def close(self):
        self.tmp.cleanup()


def starting(messages, rule):
    return [m for m in messages if m.startswith(rule)]


class XlfSyncTests(unittest.TestCase):
    def fixture(self, **kwargs):
        fixture = Fixture(**kwargs)
        self.addCleanup(fixture.close)
        return fixture

    def test_real_repo_passes(self):
        errors, _, summary = xlf_sync.run(xlf_sync.ROOT)
        self.assertEqual(errors, [])
        self.assertEqual(len(summary), len(xlf_sync.LANGUAGES))

    def test_sync_creates_files_with_pending_units(self):
        f = self.fixture()
        lines = f.sync()
        for lang in xlf_sync.LANGUAGES:
            units = f.units(lang)
            self.assertEqual(len(units), 3)
            self.assertTrue(all(u["state"] == "needs-translation" and u["target"] == "" for u in units.values()))
        self.assertIn("3 pending", lines[0])

    def test_sync_keeps_g_layout(self):
        f = self.fixture()
        f.sync()
        text = f.text("pt-PT")
        self.assertTrue(text.startswith("﻿<?xml"))
        self.assertIn('target-language="pt-PT" original="Equipment Management"', text)
        self.assertEqual(text.count("<trans-unit"), 3)
        self.assertIn('<trans-unit id="Table 1 - Property 2" maxwidth="10" size-unit="char" translate="yes" '
                      'xml:space="preserve">', text)

    def test_sync_keeps_existing_translation(self):
        f = self.fixture()
        f.complete()
        f.sync()
        self.assertEqual(f.units("pt-PT")["Table 1 - Property 3"]["target"], "T:Description")
        self.assertEqual(f.units("pt-PT")["Table 1 - Property 3"]["state"], "translated")

    def test_sync_marks_changed_source_for_review(self):
        f = self.fixture()
        f.complete()
        f.write_g([UNITS[0], UNITS[1], ("Table 1 - Property 3", None, "Details", "")])
        f.sync()
        unit = f.units("es-ES")["Table 1 - Property 3"]
        self.assertEqual(unit["state"], "needs-review-translation")
        self.assertEqual(unit["target"], "T:Description")
        self.assertEqual(unit["source"], "Details")

    def test_sync_reuses_translation_memory(self):
        f = self.fixture()
        f.complete()
        f.write_g(UNITS + [("Table 2 - Property 9", None, "Description", "")])
        f.sync()
        unit = f.units("pt-PT")["Table 2 - Property 9"]
        self.assertEqual((unit["state"], unit["target"]), ("translated", "T:Description"))

    def test_sync_drops_removed_unit(self):
        f = self.fixture()
        f.complete()
        f.write_g(UNITS[:2])
        lines = f.sync()
        self.assertNotIn("Table 1 - Property 3", f.units("pt-PT"))
        self.assertIn("1 dropped", lines[0])

    def test_export_dedupes_and_respects_limit(self):
        f = self.fixture()
        f.write_g(UNITS + [("Table 2 - Property 9", None, "Description", "")])
        f.sync()
        self.assertEqual(xlf_sync.export_batch(f.root, "pt-PT", f.batch), 3)
        entries = json.loads(f.batch.read_text(encoding="utf-8"))
        self.assertEqual([e["source"] for e in entries], ["Value %1 of %2", "Laptop", "Description"])
        self.assertIn("%1 = first", entries[0]["notes"])
        self.assertEqual(xlf_sync.export_batch(f.root, "pt-PT", f.batch, limit=2), 2)

    def test_export_skips_translated_units(self):
        f = self.fixture()
        f.complete()
        self.assertEqual(xlf_sync.export_batch(f.root, "es-ES", f.batch), 0)

    def test_import_applies_to_all_units_with_source(self):
        f = self.fixture()
        f.write_g(UNITS + [("Table 2 - Property 9", None, "Description", "")])
        f.sync()
        f.batch.write_text(json.dumps([{"source": "Description", "target": "Descricao"}]), encoding="utf-8")
        applied, problems = xlf_sync.import_batch(f.root, "pt-PT", f.batch)
        self.assertEqual((applied, problems), (2, []))
        units = f.units("pt-PT")
        self.assertEqual(units["Table 1 - Property 3"]["target"], "Descricao")
        self.assertEqual(units["Table 2 - Property 9"]["state"], "translated")
        self.assertEqual(f.units("es-ES")["Table 1 - Property 3"]["state"], "needs-translation")

    def test_import_by_id_overrides_single_unit(self):
        f = self.fixture()
        f.write_g(UNITS + [("Table 2 - Property 9", None, "Description", "")])
        f.complete()
        f.batch.write_text(json.dumps([{"id": "Table 2 - Property 9", "source": "Description",
                                        "target": "Outra"}]), encoding="utf-8")
        applied, _ = xlf_sync.import_batch(f.root, "pt-PT", f.batch)
        self.assertEqual(applied, 1)
        self.assertEqual(f.units("pt-PT")["Table 2 - Property 9"]["target"], "Outra")
        self.assertEqual(f.units("pt-PT")["Table 1 - Property 3"]["target"], "T:Description")

    def test_import_rejects_placeholder_mismatch(self):
        f = self.fixture()
        f.sync()
        f.batch.write_text(json.dumps([{"source": "Value %1 of %2", "target": "Valor %1"}]), encoding="utf-8")
        applied, problems = xlf_sync.import_batch(f.root, "pt-PT", f.batch)
        self.assertEqual(applied, 0)
        self.assertEqual(len(problems), 1)
        self.assertTrue(problems[0].startswith("IMPORT: Value %1 of %2"))
        self.assertEqual(f.units("pt-PT")["Table 1 - NamedType 1"]["state"], "needs-translation")

    def test_import_accepts_reordered_placeholders(self):
        f = self.fixture()
        f.sync()
        f.batch.write_text(json.dumps([{"source": "Value %1 of %2", "target": "%2 e %1"}]), encoding="utf-8")
        applied, problems = xlf_sync.import_batch(f.root, "pt-PT", f.batch)
        self.assertEqual((applied, problems), (1, []))

    def test_import_rejects_maxwidth(self):
        f = self.fixture()
        f.sync()
        f.batch.write_text(json.dumps([{"source": "Laptop", "target": "Computador portatil"}]), encoding="utf-8")
        applied, problems = xlf_sync.import_batch(f.root, "pt-PT", f.batch)
        self.assertEqual(applied, 0)
        self.assertIn("maxwidth", problems[0])

    def test_import_ignores_empty_target(self):
        f = self.fixture()
        f.sync()
        f.batch.write_text(json.dumps([{"source": "Laptop", "target": ""}]), encoding="utf-8")
        self.assertEqual(xlf_sync.import_batch(f.root, "pt-PT", f.batch), (0, []))

    def test_check_complete_files_have_no_errors(self):
        f = self.fixture()
        f.complete()
        errors, warnings, summary = f.run()
        self.assertEqual(errors, [])
        self.assertEqual(warnings, [])
        self.assertEqual(summary[0], "pt-PT: 3 units, 3 translated, 0 identical to source")

    def test_missing_g_xlf_is_tr1(self):
        f = self.fixture()
        (f.root / xlf_sync.G_XLF).unlink()
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR1")), 1)

    def test_missing_language_file_is_tr2(self):
        f = self.fixture()
        f.complete()
        f.path("es-ES").unlink()
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR2")), 1)

    def test_malformed_language_file_is_tr2(self):
        f = self.fixture()
        f.complete()
        f.path("es-ES").write_text("<xliff", encoding="utf-8")
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR2")), 1)

    def test_stray_file_is_tr3(self):
        f = self.fixture()
        f.complete()
        (f.root / xlf_sync.TRANSLATIONS / "Equipment Management.de-DE.xlf").write_text("x", encoding="utf-8")
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR3")), 1)

    def test_wrong_target_language_is_tr4(self):
        f = self.fixture()
        f.complete()
        f.replace("pt-PT", 'target-language="pt-PT"', 'target-language="pt-BR"')
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR4")), 1)

    def test_different_original_is_tr4(self):
        f = self.fixture()
        f.complete()
        f.replace("es-ES", 'original="Equipment Management"', 'original="Other"')
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR4")), 1)

    def test_missing_unit_is_tr5(self):
        f = self.fixture()
        f.complete()
        f.write_g(UNITS + [("Table 2 - Property 9", None, "Extra", "")])
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR5")), 2)

    def test_orphan_unit_is_tr6(self):
        f = self.fixture()
        f.complete()
        f.write_g(UNITS[:2])
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR6")), 2)

    def test_stale_source_is_tr7(self):
        f = self.fixture()
        f.complete()
        f.write_g([UNITS[0], UNITS[1], ("Table 1 - Property 3", None, "Details", "")])
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR7")), 2)

    def test_pending_state_is_tr8(self):
        f = self.fixture()
        f.complete()
        f.replace("pt-PT", 'state="translated">T:Laptop', 'state="needs-review-translation">T:Laptop')
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR8")), 1)

    def test_empty_target_is_tr8(self):
        f = self.fixture()
        f.complete()
        f.replace("es-ES", '>T:Description</target>', "></target>")
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR8")), 1)

    def test_placeholder_difference_is_tr9(self):
        f = self.fixture()
        f.complete()
        f.replace("pt-PT", "T:Value %1 of %2", "T:Value %1 of %1")
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR9")), 1)

    def test_maxwidth_is_tr10(self):
        f = self.fixture()
        f.complete()
        f.replace("es-ES", ">T:Laptop<", ">T:Laptop computer<")
        errors, _, _ = f.run()
        self.assertEqual(len(starting(errors, "TR10")), 1)

    def test_identical_to_source_is_counted_not_flagged(self):
        f = self.fixture()
        f.sync()
        f.translate_all("pt-PT", prefix="")
        f.translate_all("es-ES")
        errors, warnings, summary = f.run()
        self.assertEqual((errors, warnings), ([], []))
        self.assertIn("3 identical to source", summary[0])

    def test_written_file_is_well_formed_and_escaped(self):
        f = self.fixture(units=[("Table 1 - Property 3", None, "Tom &amp; Jerry &lt;Tool&gt;", "")])
        f.sync()
        f.batch.write_text(json.dumps([{"source": "Tom & Jerry <Tool>", "target": "Tom & Jerry <Ferramenta>"}]),
                           encoding="utf-8")
        self.assertEqual(xlf_sync.import_batch(f.root, "pt-PT", f.batch), (1, []))
        self.assertIn("<target state=\"translated\">Tom &amp; Jerry &lt;Ferramenta&gt;</target>", f.text("pt-PT"))
        unit = f.units("pt-PT")["Table 1 - Property 3"]
        self.assertEqual(unit["source"], "Tom & Jerry <Tool>")
        self.assertEqual(unit["target"], "Tom & Jerry <Ferramenta>")


if __name__ == "__main__":
    unittest.main()
