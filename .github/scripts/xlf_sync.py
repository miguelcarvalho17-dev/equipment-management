#!/usr/bin/env python3
"""XLIFF language file tool (FR-055). Keeps the translated .xlf files in step with the generated .g.xlf.

Commands:
  sync                          Create or update app/Translations/Equipment Management.<lang>.xlf for every
                                language from the .g.xlf. New units are pending (or copied from translation
                                memory), changed sources are marked for review, removed units are dropped.
  export <lang> <json> [--limit N]  Write pending units to a JSON batch, de-duplicated by source (default 150).
  import <lang> <json>          Apply the non-empty "target" entries of a batch. An entry with "id" applies to
                                that unit only, otherwise to every pending unit with the same source.
  check                         Verify the language files (rules below). Exit 1 on errors.

Rules of check (the message starts with the rule ID):
  TR1   The .g.xlf is missing or not well-formed.
  TR2   A language file is missing or not well-formed.
  TR3   A stray .xlf file that is neither the .g.xlf nor a supported language file.
  TR4   Wrong target-language, source-language not en-US, or original differs from the .g.xlf.
  TR5   A unit of the .g.xlf is missing in the language file.
  TR6   A unit of the language file does not exist in the .g.xlf (orphan).
  TR7   The source of a unit differs from the .g.xlf (stale).
  TR8   A unit is not translated or final, or has an empty target.
  TR9   The %n placeholders of the target differ from the source.
  TR10  The target is longer than the maxwidth of the unit.

Stdlib only, Python 3.9 compatible.
"""
import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LANGUAGES = ("pt-PT", "es-ES")
TRANSLATIONS = Path("app") / "Translations"
G_XLF = TRANSLATIONS / "Equipment Management.g.xlf"
NS = "urn:oasis:names:tc:xliff:document:1.2"
XML_SPACE = "{http://www.w3.org/XML/1998/namespace}space"
DONE_STATES = {"translated", "final"}
PENDING_STATES = {"needs-translation", "needs-review-translation"}
PLACEHOLDER_RE = re.compile(r"%\d+")
DEFAULT_LIMIT = 150


def language_path(lang):
    return TRANSLATIONS / f"Equipment Management.{lang}.xlf"


def _q(name):
    return f"{{{NS}}}{name}"


def _attr_name(name):
    return "xml:space" if name == XML_SPACE else name


def parse_file(path):
    """Return (file_attributes, units) for an xlf file. Raises ValueError when it cannot be read."""
    try:
        tree = ET.parse(path)
    except (ET.ParseError, OSError) as exc:
        raise ValueError(str(exc))
    file_el = tree.getroot().find(_q("file"))
    if file_el is None:
        raise ValueError("no <file> element")
    units = []
    for el in tree.getroot().iter(_q("trans-unit")):
        source = el.find(_q("source"))
        target = el.find(_q("target"))
        units.append({
            "id": el.get("id"),
            "attrs": [(_attr_name(k), v) for k, v in el.attrib.items() if k != "id"],
            "maxwidth": int(el.get("maxwidth")) if el.get("maxwidth") else None,
            "source": (source.text or "") if source is not None else "",
            "target": (target.text or "") if target is not None else None,
            "state": target.get("state", "") if target is not None else "",
            "notes": [([(k, v) for k, v in n.attrib.items()], n.text or "") for n in el.findall(_q("note"))],
        })
    return dict(file_el.attrib), units


def esc(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def esc_attr(text):
    return esc(text).replace('"', "&quot;")


def _attrs(pairs):
    return "".join(f' {k}="{esc_attr(v)}"' for k, v in pairs)


def write_language_file(path, lang, g_units, lang_units, g_path=None):
    """Write the language file in the exact layout of the .g.xlf. lang_units maps unit id to a unit dict."""
    g_text = Path(g_path or (Path(path).parent / G_XLF.name)).read_text(encoding="utf-8")
    header = g_text.split("\n")[:2]
    file_attrs, _ = parse_file(Path(g_path or (Path(path).parent / G_XLF.name)))
    original = file_attrs.get("original", "")
    lines = list(header)
    lines.append(f'  <file datatype="xml" source-language="en-US" target-language="{esc_attr(lang)}" '
                 f'original="{esc_attr(original)}">')
    lines.append("    <body>")
    lines.append('      <group id="body">')
    for g in g_units:
        unit = lang_units[g["id"]]
        attrs = [("id", g["id"])] + g["attrs"]
        lines.append(f"        <trans-unit{_attrs(attrs)}>")
        lines.append(f"          <source>{esc(g['source'])}</source>")
        lines.append(f'          <target state="{esc_attr(unit["state"])}">{esc(unit["target"] or "")}</target>')
        for note_attrs, note_text in g["notes"]:
            lines.append(f"          <note{_attrs(note_attrs)}>{esc(note_text)}</note>")
        lines.append("        </trans-unit>")
    lines.append("      </group>")
    lines.append("    </body>")
    lines.append("  </file>")
    lines.append("</xliff>")
    ending = "\n" if g_text.endswith("\n") else ""
    Path(path).write_bytes(("\n".join(lines) + ending).encode("utf-8"))


def _load_existing(path):
    if not Path(path).exists():
        return {}
    try:
        _, units = parse_file(path)
    except ValueError:
        return {}
    return {u["id"]: u for u in units}


def sync(root=ROOT):
    """Create or update the language files. Returns summary lines."""
    root = Path(root)
    _, g_units = parse_file(root / G_XLF)
    out = []
    for lang in LANGUAGES:
        path = root / language_path(lang)
        existing = _load_existing(path)
        memory = {}
        for u in existing.values():
            if u["state"] in DONE_STATES and u["target"]:
                memory.setdefault(u["source"], u["target"])
        result = {}
        for g in g_units:
            old = existing.get(g["id"])
            if old is not None and old["source"] == g["source"]:
                result[g["id"]] = {"target": old["target"] or "", "state": old["state"] or "needs-translation"}
            elif old is not None:
                result[g["id"]] = {"target": old["target"] or "",
                                   "state": "needs-review-translation" if old["target"] else "needs-translation"}
            elif g["source"] in memory:
                result[g["id"]] = {"target": memory[g["source"]], "state": "translated"}
            else:
                result[g["id"]] = {"target": "", "state": "needs-translation"}
        dropped = len(set(existing) - {g["id"] for g in g_units})
        write_language_file(path, lang, g_units, result, root / G_XLF)
        done = sum(1 for r in result.values() if r["state"] in DONE_STATES)
        out.append(f"{lang}: {len(result)} units, {done} translated, {len(result) - done} pending, "
                   f"{dropped} dropped")
    return out


def _read_lang(root, lang):
    _, g_units = parse_file(Path(root) / G_XLF)
    _, units = parse_file(Path(root) / language_path(lang))
    return g_units, {u["id"]: u for u in units}


def _note_text(g):
    developer = next((t for a, t in g["notes"] if dict(a).get("from") == "Developer"), "")
    generator = next((t for a, t in g["notes"] if dict(a).get("from") == "Xliff Generator"), "")
    return f"{developer} | {generator}"


def export_batch(root, lang, json_path, limit=DEFAULT_LIMIT):
    """Write pending units to a JSON batch, de-duplicated by source. Returns the number of entries."""
    g_units, units = _read_lang(root, lang)
    batch, seen = [], set()
    for g in g_units:
        unit = units.get(g["id"])
        if unit is None or unit["state"] in DONE_STATES and unit["target"]:
            continue
        if g["source"] in seen:
            continue
        seen.add(g["source"])
        batch.append({"source": g["source"], "notes": _note_text(g), "current": unit["target"] or "",
                      "target": ""})
        if len(batch) >= limit:
            break
    Path(json_path).write_text(json.dumps(batch, ensure_ascii=False, indent=1), encoding="utf-8")
    return len(batch)


def _problem(source, target, maxwidth):
    if Counter(PLACEHOLDER_RE.findall(source)) != Counter(PLACEHOLDER_RE.findall(target)):
        return "placeholders differ from the source"
    if maxwidth is not None and len(target) > maxwidth:
        return f"{len(target)} characters exceeds maxwidth {maxwidth}"
    return None


def import_batch(root, lang, json_path):
    """Apply a batch. Returns (applied_count, problems)."""
    root = Path(root)
    g_units, units = _read_lang(root, lang)
    g_by_id = {g["id"]: g for g in g_units}
    entries = json.loads(Path(json_path).read_text(encoding="utf-8"))
    applied, problems = 0, []
    for entry in entries:
        target = entry.get("target") or ""
        if not target:
            continue
        source = entry.get("source", "")
        if entry.get("id"):
            ids = [entry["id"]] if entry["id"] in g_by_id else []
        else:
            ids = [g["id"] for g in g_units
                   if g["source"] == source and not (units[g["id"]]["state"] in DONE_STATES
                                                     and units[g["id"]]["target"])]
        bad = None
        for unit_id in ids:
            bad = _problem(g_by_id[unit_id]["source"], target, g_by_id[unit_id]["maxwidth"])
            if bad:
                break
        if bad:
            problems.append(f"IMPORT: {source}: {bad}")
            continue
        for unit_id in ids:
            units[unit_id]["target"] = target
            units[unit_id]["state"] = "translated"
        applied += len(ids)
    write_language_file(root / language_path(lang), lang, g_units, units, root / G_XLF)
    return applied, problems


def run(root=ROOT):
    root = Path(root)
    errors, warnings, summary = [], [], []
    try:
        g_attrs, g_units = parse_file(root / G_XLF)
    except ValueError as exc:
        errors.append(f"TR1 {G_XLF.as_posix()} is missing or not well-formed: {exc}")
        return errors, warnings, summary
    g_by_id = {g["id"]: g for g in g_units}
    expected = {language_path(lang).name for lang in LANGUAGES} | {G_XLF.name}
    translations = root / TRANSLATIONS
    if translations.is_dir():
        for stray in sorted(p for p in translations.glob("*.xlf") if p.name not in expected):
            errors.append(f"TR3 {(TRANSLATIONS / stray.name).as_posix()} is not a supported language file "
                          f"(supported: {', '.join(LANGUAGES)}).")
    for lang in LANGUAGES:
        rel = language_path(lang).as_posix()
        path = root / language_path(lang)
        if not path.exists():
            errors.append(f"TR2 {rel} is missing. Run python3 .github/scripts/xlf_sync.py sync.")
            continue
        try:
            attrs, units = parse_file(path)
        except ValueError as exc:
            errors.append(f"TR2 {rel} is not well-formed: {exc}")
            continue
        if attrs.get("target-language") != lang:
            errors.append(f"TR4 {rel}: target-language is '{attrs.get('target-language')}', expected '{lang}'.")
        if attrs.get("source-language") != "en-US":
            errors.append(f"TR4 {rel}: source-language is '{attrs.get('source-language')}', expected 'en-US'.")
        if attrs.get("original") != g_attrs.get("original"):
            errors.append(f"TR4 {rel}: original is '{attrs.get('original')}', expected "
                          f"'{g_attrs.get('original')}'.")
        by_id = {}
        for u in units:
            if u["id"] in by_id:
                errors.append(f"TR6 {rel}: unit '{u['id']}' appears twice.")
            by_id[u["id"]] = u
        for g in g_units:
            if g["id"] not in by_id:
                errors.append(f"TR5 {rel}: unit '{g['id']}' is missing. Run xlf_sync.py sync.")
        for unit_id in by_id:
            if unit_id not in g_by_id:
                errors.append(f"TR6 {rel}: unit '{unit_id}' does not exist in the .g.xlf (orphan). "
                              f"Run xlf_sync.py sync.")
        translated = same = 0
        for g in g_units:
            u = by_id.get(g["id"])
            if u is None:
                continue
            if u["source"] != g["source"]:
                errors.append(f"TR7 {rel}: unit '{g['id']}' has a stale source. Run xlf_sync.py sync.")
            if u["state"] not in DONE_STATES or not u["target"]:
                errors.append(f"TR8 {rel}: unit '{g['id']}' is not translated (state '{u['state']}', "
                              f"source '{g['source']}').")
                continue
            translated += 1
            if u["target"] == g["source"]:
                same += 1
            if Counter(PLACEHOLDER_RE.findall(g["source"])) != Counter(PLACEHOLDER_RE.findall(u["target"])):
                errors.append(f"TR9 {rel}: unit '{g['id']}' placeholders differ from the source "
                              f"('{g['source']}' vs '{u['target']}').")
            if g["maxwidth"] is not None and len(u["target"]) > g["maxwidth"]:
                errors.append(f"TR10 {rel}: unit '{g['id']}' target has {len(u['target'])} characters, "
                              f"maxwidth is {g['maxwidth']}.")
        summary.append(f"{lang}: {len(units)} units, {translated} translated, {same} identical to source")
    return errors, warnings, summary


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("sync")
    sub.add_parser("check")
    exp = sub.add_parser("export")
    exp.add_argument("lang", choices=LANGUAGES)
    exp.add_argument("json")
    exp.add_argument("--limit", type=int, default=DEFAULT_LIMIT)
    imp = sub.add_parser("import")
    imp.add_argument("lang", choices=LANGUAGES)
    imp.add_argument("json")
    args = parser.parse_args(argv)

    if args.command == "sync":
        for line in sync(ROOT):
            print(line)
    elif args.command == "export":
        count = export_batch(ROOT, args.lang, args.json, args.limit)
        print(f"{args.lang}: exported {count} pending source strings to {args.json}")
    elif args.command == "import":
        applied, problems = import_batch(ROOT, args.lang, args.json)
        for problem in problems:
            print(problem)
        print(f"{args.lang}: applied {applied} units, {len(problems)} rejected")
        if problems:
            sys.exit(1)
    else:
        errors, warnings, summary = run(ROOT)
        for line in summary:
            print(line)
        for msg in warnings:
            print(f"::warning::{msg}")
        for msg in errors:
            print(f"::error::{msg}")
        print(f"{len(errors)} errors")
        if errors:
            sys.exit(1)


if __name__ == "__main__":
    main()
