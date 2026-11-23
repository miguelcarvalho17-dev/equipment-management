#!/usr/bin/env python3
"""Schema compatibility check (FR-062). Compares the AL source of app/ with the base branch.

Rules (the message starts with the rule ID; AppSourceCop equivalent in brackets):
  SCH00  Warning: the base AL source could not be read, the check was skipped.
  SCH01  Object removed (AS0001 tables, AS0088/AS0089 other objects; a non-table object may go once it was Pending in base: warning).
  SCH02  Object renamed or its "extends" target changed (AS0006 tables, AS0090 other objects).
  SCH03  Namespace changed (AS0007).
  SCH04  Field removed, whatever its ObsoleteState (AS0002).
  SCH05  Field renamed, casing included (AS0005).
  SCH06  Field type or FieldClass changed; shorter Text/Code error (AS0080), longer warning (AS0086); type change AS0004.
  SCH07  Table type changed (no AppSourceCop rule).
  SCH08  Primary key changed, or secondary key removed or changed (AS0009, AS0010).
  SCH09  Enum value removed or renamed (AS0082 rename, AS0083 delete).
  SCH10  Enum Extensible changed: extensible to not extensible is an error (AS0050), the reverse warns.
  SCH11  Invalid obsolete transition (Removed reverted, or Removed set without Pending first).
  SCH12  Pending or Removed without ObsoleteReason and an ObsoleteTag in 'Major.Minor' form.
  SCH13  Warning: table or field becomes Pending or Removed; move the data in an upgrade step (FR-044).
  SCH14  Problem in .github/schema/accepted-breaking-changes.json; warning for a stale entry.

Usage: schema_check.py [--base <git ref>]
Stdlib only, Python 3.9 compatible. Errors exit 1; warnings are printed as GitHub annotations.
Baseline = AL source of app/ on the base ref (main), not a released .app; see FR-062 phase 2.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from coverage_check import strip_comments, strip_strings, unquote  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
APP_FOLDER = "app"
EXCEPTIONS_FILE = Path(".github") / "schema" / "accepted-breaking-changes.json"
DOC = "docs/features/FR-062-breaking-change-validation.md"
HEADER_RE = re.compile(
    r'^\s*(table|tableextension|page|pageextension|codeunit|enum|enumextension|permissionset|'
    r'permissionsetextension|report|reportextension|query|xmlport)\s+(\d+)\s+("[^"]+"|[\w.]+)'
    r'(?:\s+extends\s+("[^"]+"|[\w.]+))?', re.IGNORECASE)
NAMESPACE_RE = re.compile(r'^\s*namespace\s+([\w.]+)\s*;', re.IGNORECASE | re.MULTILINE)
FIELD_RE = re.compile(r'^\s*field\(\s*(\d+)\s*;\s*("[^"]+"|\w+)\s*;\s*(.+)\)\s*(\{.*)?$', re.IGNORECASE)
KEY_RE = re.compile(r'^\s*key\(\s*("[^"]+"|\w+)\s*;\s*(.+?)\)\s*(\{.*)?$', re.IGNORECASE)
VALUE_RE = re.compile(r'^\s*value\(\s*(\d+)\s*;\s*("[^"]+"|\w+)\s*\)', re.IGNORECASE)
PROP_RE = re.compile(r'^\s*(\w+)\s*=\s*(.*?)\s*;\s*$')
INLINE_PROP_RE = re.compile(r'^\s*(\w+)\s*=\s*(.*?)\s*$')
TAG_RE = re.compile(r"^'\d+\.\d+'$")
TABLE_KINDS = ("table", "tableextension")
ENUM_KINDS = ("enum", "enumextension")


def read_head_files(root):
    root = Path(root)
    files = {}
    for path in sorted((root / APP_FOLDER).rglob("*.al")):
        files[path.relative_to(root).as_posix()] = path.read_text(encoding="utf-8-sig")
    return files


def read_base_files(root, base):
    listing = subprocess.run(
        ["git", "ls-tree", "-r", "--name-only", base, "--", APP_FOLDER],
        cwd=root, capture_output=True, text=True, check=False)
    if listing.returncode != 0:
        return None
    files = {}
    for rel in listing.stdout.splitlines():
        if not rel.endswith(".al"):
            continue
        shown = subprocess.run(
            ["git", "show", f"{base}:{rel}"], cwd=root, capture_output=True, text=True, check=False)
        if shown.returncode != 0:
            return None
        files[rel] = shown.stdout.lstrip("﻿")
    return files


def normalise_type(text):
    return re.sub(r"\s+", " ", text).strip().lower()


def parse_sources(files):
    objects = {}
    for path in sorted(files):
        text = re.sub(r'/\*.*?\*/', lambda m: "\n" * m.group(0).count("\n"), files[path], flags=re.S)
        lines_c = strip_comments(text).split("\n")
        lines_s = strip_strings(text).split("\n")
        n = min(len(lines_c), len(lines_s))
        lines_c, lines_s = lines_c[:n], lines_s[:n]
        depth_before = [0] * (n + 1)
        for k in range(n):
            depth_before[k + 1] = depth_before[k] + lines_s[k].count("{") - lines_s[k].count("}")
        ns_match = NAMESPACE_RE.search("\n".join(lines_s))
        namespace = ns_match.group(1) if ns_match else ""

        def block(i):
            d0 = depth_before[i]
            line = lines_s[i]
            if "{" in line and depth_before[i + 1] == d0:
                inner = lines_c[i][lines_c[i].index("{") + 1:lines_c[i].rindex("}")] if "}" in lines_c[i] else ""
                props = {}
                for part in inner.split(";"):
                    m = INLINE_PROP_RE.match(part)
                    if m:
                        props[m.group(1).lower()] = m.group(2)
                return i, props
            opened = False
            j = i
            while j < n:
                if j > i and not opened:
                    stripped = lines_s[j].strip()
                    if stripped and not stripped.startswith("{"):
                        return i, {}
                if depth_before[j + 1] > d0:
                    opened = True
                if opened and depth_before[j + 1] == d0:
                    break
                j += 1
            end = min(j, n - 1)
            props = {}
            for k in range(i + 1, end + 1):
                if depth_before[k] == d0 + 1:
                    m = PROP_RE.match(lines_c[k])
                    if m:
                        props[m.group(1).lower()] = m.group(2)
            return end, props

        i = 0
        while i < n:
            m = HEADER_RE.match(lines_s[i])
            if not m:
                i += 1
                continue
            kind = m.group(1).lower()
            ident = (kind, int(m.group(2)))
            end, props = block(i)
            obj = {
                "kind": kind, "id": ident[1], "name": unquote(m.group(3)),
                "extends": unquote(m.group(4)) if m.group(4) else None,
                "namespace": namespace, "path": path, "props": props,
                "fields": {}, "keys": [], "values": {}}
            for k in range(i + 1, end + 1):
                if kind in TABLE_KINDS:
                    fm = FIELD_RE.match(lines_s[k])
                    if fm:
                        _, fprops = block(k)
                        obj["fields"].setdefault(int(fm.group(1)), {
                            "name": unquote(fm.group(2)), "type": normalise_type(fm.group(3)), "props": fprops})
                        continue
                    km = KEY_RE.match(lines_s[k])
                    if km:
                        _, kprops = block(k)
                        names = tuple(unquote(p.strip()).lower() for p in km.group(2).split(","))
                        obj["keys"].append({"name": unquote(km.group(1)), "fields": names, "props": kprops})
                elif kind in ENUM_KINDS:
                    vm = VALUE_RE.match(lines_s[k])
                    if vm:
                        _, vprops = block(k)
                        obj["values"].setdefault(int(vm.group(1)), {"name": unquote(vm.group(2)), "props": vprops})
            if ident not in objects:
                objects[ident] = obj
            i = max(end, i) + 1
    return objects


def state(props):
    return props.get("obsoletestate", "no").strip().lower()


def extensible(props):
    return props.get("extensible", "false").strip().lower() == "true"


def length_type(text):
    m = re.fullmatch(r"(text|code)\[(\d+)\]", text)
    return (m.group(1), int(m.group(2))) if m else None


class Findings:
    def __init__(self):
        self.items = []

    def add(self, rule, severity, obj, message, sub="", path=None):
        key = f"{rule} {obj['kind']} {obj['id']}" + (f" {sub}" if sub else "")
        text = f"{rule} {obj['kind']} {obj['id']} \"{obj['name']}\": {message} See {DOC}. [key: {key}]"
        self.items.append((rule, severity, key, text, path or obj["path"]))


def check_obsolete(findings, obj, base_props, head_props, sub, what, with_data_warning):
    base_state = state(base_props) if base_props is not None else "no"
    head_state = state(head_props)
    is_new = base_props is None
    if base_state == "removed" and head_state != "removed":
        findings.add("SCH11", "error", obj,
                     f"{what} was Removed and is now {head_state}; a Removed element cannot come back.", sub)
    if head_state == "removed" and base_state not in ("pending", "removed"):
        findings.add("SCH11", "error", obj,
                     f"{what} goes to Removed without being Pending first; set ObsoleteState = Pending "
                     "and keep it for a release.", sub)
    if head_state in ("pending", "removed") and (is_new or head_state != base_state):
        reason = head_props.get("obsoletereason", "").strip()
        tag = head_props.get("obsoletetag", "").strip()
        if reason in ("", "''") or not TAG_RE.match(tag):
            findings.add("SCH12", "error", obj,
                         f"{what} is {head_state} without ObsoleteReason or an ObsoleteTag in 'Major.Minor' "
                         "form (for example '29.1').", sub)
    if with_data_warning and not is_new and head_state != base_state:
        if base_state == "no" and head_state == "pending":
            findings.add("SCH13", "warning", obj,
                         f"{what} is now Pending: move its data in an upgrade step in \"EQM Upgrade Mgt.\" while "
                         "Pending (FR-044, How to add an upgrade step); AL cannot read it once Removed.", sub)
        elif base_state == "pending" and head_state == "removed":
            findings.add("SCH13", "warning", obj,
                         f"{what} is now Removed: confirm the data was moved in an earlier release.", sub)


def compare(base, head):
    findings = Findings()
    for ident, b in base.items():
        h = head.get(ident)
        if h is None:
            if b["kind"] not in TABLE_KINDS and state(b["props"]) == "pending":
                findings.add("SCH01", "warning", b, "object removed after it was Pending.")
            else:
                findings.add("SCH01", "error", b,
                             "object removed. Keep it and set ObsoleteState = Pending with ObsoleteReason and "
                             "ObsoleteTag instead.")
            continue
        if h["name"] != b["name"]:
            findings.add("SCH02", "error", h, f"object renamed from \"{b['name']}\". Keep the published name.")
        if b["extends"] is not None and h["extends"] != b["extends"]:
            findings.add("SCH02", "error", h, f"extends target changed from \"{b['extends']}\".")
        if h["namespace"] != b["namespace"]:
            findings.add("SCH03", "error", h,
                         f"namespace changed from \"{b['namespace']}\" to \"{h['namespace']}\".")
        if b["kind"] == "table":
            if b["props"].get("tabletype", "normal").strip().lower() != \
                    h["props"].get("tabletype", "normal").strip().lower():
                findings.add("SCH07", "error", h, "TableType changed.")
        if b["kind"] in TABLE_KINDS:
            compare_fields(findings, b, h)
            compare_keys(findings, b, h)
        if b["kind"] in ENUM_KINDS:
            compare_values(findings, b, h)
        if b["kind"] == "enum":
            was, now = extensible(b["props"]), extensible(h["props"])
            if was and not now:
                findings.add("SCH10", "error", h,
                             "enum is no longer Extensible; extensions of other apps would break.")
            elif now and not was:
                findings.add("SCH10", "warning", h,
                             "enum became Extensible. This is one-way and cannot be undone; code over it needs "
                             "'case ... else'.")
        check_obsolete(findings, h, b["props"], h["props"], "", "object", b["kind"] == "table")
    for ident, h in head.items():
        base_obj = base.get(ident)
        if base_obj is None:
            check_obsolete(findings, h, None, h["props"], "", "object", False)
        for fid, field in h["fields"].items():
            if base_obj is None or fid not in base_obj["fields"]:
                check_obsolete(findings, h, None, field["props"], f"field {fid}", f"field {fid}", False)
        for key in h["keys"]:
            if base_obj is None or key["name"] not in [k["name"] for k in base_obj["keys"]]:
                check_obsolete(findings, h, None, key["props"], f"key {key['name']}", f"key {key['name']}", False)
        for ordinal, value in h["values"].items():
            if base_obj is None or ordinal not in base_obj["values"]:
                check_obsolete(findings, h, None, value["props"], f"value {ordinal}", f"value {ordinal}", False)
    return findings.items


def compare_fields(findings, b, h):
    for fid, bf in b["fields"].items():
        hf = h["fields"].get(fid)
        sub = f"field {fid}"
        if hf is None:
            findings.add("SCH04", "error", h,
                         f"field {fid} \"{bf['name']}\" removed. Keep it and set ObsoleteState = Pending, "
                         "then Removed in a later release.", sub)
            continue
        if hf["name"] != bf["name"]:
            findings.add("SCH05", "error", h,
                         f"field {fid} renamed from \"{bf['name']}\" to \"{hf['name']}\".", sub)
        if hf["type"] != bf["type"]:
            bl, hl = length_type(bf["type"]), length_type(hf["type"])
            if bl and hl and bl[0] == hl[0] and hl[1] > bl[1]:
                findings.add("SCH06", "warning", h,
                             f"field {fid} \"{hf['name']}\" length increased from {bl[1]} to {hl[1]}.", sub)
            elif bl and hl and bl[0] == hl[0]:
                findings.add("SCH06", "error", h,
                             f"field {fid} \"{hf['name']}\" length decreased from {bl[1]} to {hl[1]}.", sub)
            else:
                findings.add("SCH06", "error", h,
                             f"field {fid} \"{hf['name']}\" type changed from {bf['type']} to {hf['type']}.", sub)
        if bf["props"].get("fieldclass", "normal").strip().lower() != \
                hf["props"].get("fieldclass", "normal").strip().lower():
            findings.add("SCH06", "error", h, f"field {fid} \"{hf['name']}\" FieldClass changed.", sub)
        check_obsolete(findings, h, bf["props"], hf["props"], sub, f"field {fid}", True)


def compare_keys(findings, b, h):
    head_keys = {k["name"]: k for k in h["keys"]}
    for index, bk in enumerate(b["keys"]):
        sub = f"key {bk['name']}"
        if b["kind"] == "table" and index == 0:
            hk = h["keys"][0] if h["keys"] else None
            if hk is None or hk["name"] != bk["name"] or hk["fields"] != bk["fields"]:
                findings.add("SCH08", "error", h, f"primary key \"{bk['name']}\" changed or removed.", sub)
            continue
        hk = head_keys.get(bk["name"])
        if hk is None:
            if state(bk["props"]) == "pending":
                findings.add("SCH08", "warning", h, f"key \"{bk['name']}\" removed after it was Pending.", sub)
            else:
                findings.add("SCH08", "error", h,
                             f"key \"{bk['name']}\" removed. Set ObsoleteState = Pending instead.", sub)
            continue
        if hk["fields"] != bk["fields"]:
            findings.add("SCH08", "error", h, f"key \"{bk['name']}\" fields changed.", sub)
        check_obsolete(findings, h, bk["props"], hk["props"], sub, f"key {bk['name']}", False)


def compare_values(findings, b, h):
    for ordinal, bv in b["values"].items():
        hv = h["values"].get(ordinal)
        sub = f"value {ordinal}"
        if hv is None:
            if b["kind"] == "enum" and state(b["props"]) == "pending":
                findings.add("SCH09", "warning", h,
                             f"value {ordinal} \"{bv['name']}\" removed while the enum was Pending.", sub)
            else:
                findings.add("SCH09", "error", h,
                             f"value {ordinal} \"{bv['name']}\" removed. Never delete or renumber enum values.", sub)
            continue
        if hv["name"] != bv["name"]:
            findings.add("SCH09", "error", h,
                         f"value {ordinal} renamed from \"{bv['name']}\" to \"{hv['name']}\".", sub)
        check_obsolete(findings, h, bv["props"], hv["props"], sub, f"value {ordinal}", False)


def load_exceptions(root, path=None):
    path = Path(path) if path else Path(root) / EXCEPTIONS_FILE
    if not path.exists():
        return [], []
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except ValueError as exc:
        return [], [f"SCH14 {EXCEPTIONS_FILE.as_posix()} is not valid JSON: {exc}."]
    if not isinstance(data, dict) or not isinstance(data.get("accepted"), list):
        return [], [f"SCH14 {EXCEPTIONS_FILE.as_posix()} must be an object with an \"accepted\" list."]
    entries, problems = [], []
    for index, entry in enumerate(data["accepted"]):
        missing = [name for name in ("key", "reason", "decision")
                   if not isinstance(entry, dict) or not isinstance(entry.get(name), str)
                   or not entry[name].strip()]
        if missing:
            problems.append(f"SCH14 {EXCEPTIONS_FILE.as_posix()} entry {index} needs non-empty "
                            f"{', '.join(missing)}.")
        else:
            entries.append(entry)
    return entries, problems


def run(root=ROOT, base_files=None, exceptions_path=None):
    root = Path(root)
    if base_files is None:
        return [], ["SCH00 schema check skipped: base AL source could not be read."], \
            ["Schema check: skipped (no base ref or base not readable)"]
    base = parse_sources(base_files)
    head = parse_sources(read_head_files(root))
    findings = compare(base, head)
    entries, problems = load_exceptions(root, exceptions_path)
    by_key = {entry["key"]: entry for entry in entries}
    errors, warnings = list(problems), []
    accepted = 0
    for rule, severity, key, text, _path in findings:
        if severity == "error":
            entry = by_key.get(key)
            if entry:
                warnings.append(f"{text} Accepted: {entry['reason']} ({entry['decision']}).")
                accepted += 1
            else:
                errors.append(text)
        else:
            warnings.append(text)
    present = {item[2] for item in findings}
    for entry in entries:
        if entry["key"] not in present:
            warnings.append(f"SCH14 stale entry {entry['key']}: remove it from "
                            f"{EXCEPTIONS_FILE.as_posix()}.")
    summary = (f"Schema check: base {len(base)} objects, head {len(head)} objects, {len(errors)} breaking, "
               f"{len(warnings)} warnings, {accepted} accepted")
    return errors, warnings, [summary]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base")
    args = parser.parse_args()
    base_files = read_base_files(ROOT, args.base) if args.base else None
    errors, warnings, summary = run(ROOT, base_files)
    for line in summary:
        print(line)
    for msg in warnings:
        print(f"::warning::{msg}")
    for msg in errors:
        print(f"::error::{msg}")
    if errors:
        sys.exit(1)
    if base_files is not None:
        print("Schema check: OK")


if __name__ == "__main__":
    main()
