#!/usr/bin/env python3
"""Static test coverage check (FR-047): procedure reach and rule coverage.

This is NOT line coverage. A member counts as reached when a test in test/src calls it by name,
or when .github/coverage/coverage-register.json declares a trace to an existing test.
Branches and lines inside a member are not measured.

Areas:
  Business Logic     procedure reach over the in-scope tables and codeunits.
  APIs               procedure reach over the API pages; only a test that runs the page itself counts.
  Critical Processes rule coverage: every Error(/TestField( site needs a positive and a negative test.

Integrity errors (missing objects, tests, members, unregistered rule sites) always fail.
Below-target results only warn while "enforce" is false in the register.

Usage: coverage_check.py        (run from anywhere; uses the repository root)
Stdlib only. Writes a Markdown table to GITHUB_STEP_SUMMARY when that variable is set.
"""
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REGISTER = Path(".github") / "coverage" / "coverage-register.json"
OBJECT_DECL_RE = re.compile(r'^\s*(table|codeunit|page)\s+(\d+)\s+("[^"]+"|\w+)', re.IGNORECASE | re.MULTILINE)
PROC_RE = re.compile(r'^\s*(local\s+|internal\s+|protected\s+)?procedure\s+("[^"]+"|\w+)', re.IGNORECASE)
TRIGGER_RE = re.compile(r'^\s*trigger\s+(\w+)', re.IGNORECASE)
FIELD_RE = re.compile(r'^\s*field\(\s*\d+\s*;\s*("[^"]+"|\w+)', re.IGNORECASE)
ATTR_RE = re.compile(r'^\s*\[')
PUBLISHER_RE = re.compile(r'\[\s*(IntegrationEvent|BusinessEvent|InternalEvent)\b', re.IGNORECASE)
ERROR_SITE_RE = re.compile(r'\bError\s*\(\s*([^,)]*)', re.IGNORECASE)
TESTFIELD_SITE_RE = re.compile(r'\bTestField\s*\(\s*("[^"]+"|\w+)', re.IGNORECASE)
AREA_LIMIT = 20


def _scan(text, keep_strings=True, keep_comments=False):
    """Walks AL text once, tracking quoted identifiers, string literals and comments."""
    out = []
    i, n = 0, len(text)
    mode = None
    while i < n:
        ch = text[i]
        if mode is None:
            if ch == "/" and text[i:i + 2] == "//" and not keep_comments:
                while i < n and text[i] != "\n":
                    i += 1
                continue
            if ch == '"':
                mode = '"'
            elif ch == "'":
                mode = "'"
                out.append(ch)
                i += 1
                continue
            out.append(ch)
        elif mode == '"':
            out.append(ch)
            if ch == '"' or ch == "\n":
                mode = None
        else:
            if ch == "'":
                if text[i:i + 2] == "''":
                    if keep_strings:
                        out.append("''")
                    i += 2
                    continue
                mode = None
                out.append(ch)
            elif ch == "\n":
                mode = None
                out.append(ch)
            elif keep_strings:
                out.append(ch)
        i += 1
    return "".join(out)


def strip_comments(text):
    """Removes // line comments (including /// doc lines), keeping strings and line structure."""
    return _scan(text)


def strip_strings(text):
    """Like strip_comments, and also empties single-quoted string literals."""
    return _scan(text, keep_strings=False)


def unquote(name):
    return name[1:-1] if len(name) >= 2 and name[0] == '"' and name[-1] == '"' else name


def read_al(path):
    return path.read_text(encoding="utf-8-sig")


def parse_members(text):
    """Returns [(line_no, name, kind, local, attrs)] for procedures and triggers, in order.

    kind is procedure, trigger, subscriber or publisher. Field OnValidate triggers are named
    '<Field>.OnValidate'.
    """
    members = []
    attrs = []
    field = None
    for no, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        if not stripped:
            continue
        fmatch = FIELD_RE.match(line)
        if fmatch:
            field = unquote(fmatch.group(1))
        if ATTR_RE.match(line):
            attrs.append(stripped)
            continue
        pmatch = PROC_RE.match(line)
        tmatch = TRIGGER_RE.match(line)
        if pmatch:
            joined = " ".join(attrs)
            if re.search(r'\[\s*EventSubscriber\s*\(', joined, re.IGNORECASE):
                kind = "subscriber"
            elif PUBLISHER_RE.search(joined):
                kind = "publisher"
            else:
                kind = "procedure"
            members.append((no, unquote(pmatch.group(2)), kind, bool(pmatch.group(1) and
                            pmatch.group(1).strip().lower() == "local"), joined))
        elif tmatch:
            name = tmatch.group(1)
            if name.lower() == "onvalidate" and field:
                name = f"{field}.OnValidate"
            members.append((no, name, "trigger", False, ""))
        attrs = []
    return members


def index_objects(app_root):
    """Maps (type, id) to {name, file, text} for every table, codeunit and page under app_root."""
    objects = {}
    for al in sorted(Path(app_root).rglob("*.al")):
        text = strip_comments(read_al(al))
        match = OBJECT_DECL_RE.search(text)
        if not match:
            continue
        key = (match.group(1).lower(), int(match.group(2)))
        objects[key] = {"name": unquote(match.group(3)), "file": al, "text": text}
    return objects


def index_members(obj):
    """Returns [(member, kind)] counted for Business Logic and API reach."""
    result = []
    for _, name, kind, is_local, _attrs in parse_members(obj["text"]):
        if kind == "publisher":
            continue
        if kind == "subscriber":
            result.append((name, "subscriber"))
        elif kind == "procedure":
            if not is_local:
                result.append((name, "procedure"))
        elif name in ("OnRun", "OnOpenPage"):
            result.append((name, "trigger"))
    return result


def index_tests(test_root):
    """Returns ({codeunit_id: {test_name: body}}, declared_names, {codeunit_id: [(line_no, line)]}).

    declared_names is every procedure name declared in test/src, lower-cased.
    """
    tests, declared, lines_by_unit = {}, set(), {}
    for al in sorted(Path(test_root).rglob("*.al")):
        text = strip_comments(read_al(al))
        match = re.search(r'^\s*codeunit\s+(\d+)\b', text, re.IGNORECASE | re.MULTILINE)
        if not match:
            continue
        unit = int(match.group(1))
        lines = text.splitlines()
        lines_by_unit[unit] = lines
        members = parse_members(text)
        for pos, (no, name, kind, _local, joined) in enumerate(members):
            if kind == "trigger":
                continue
            declared.add(name.lower())
            if not re.search(r'\[\s*Test\s*\]', joined, re.IGNORECASE):
                continue
            end = len(lines)
            for later in members[pos + 1:]:
                start = later[0] - 1
                while start > no and ATTR_RE.match(lines[start - 1]):
                    start -= 1
                end = start
                break
            tests.setdefault(unit, {})[name] = "\n".join(lines[no - 1:end])
    return tests, declared, lines_by_unit


def is_called(name, lines_by_unit):
    """True when a non-declaration line in test/src calls name as Rec.Name or Name(."""
    pattern = re.compile(rf'(\.\s*{re.escape(name)}\b|\b{re.escape(name)}\s*\()', re.IGNORECASE)
    decl = re.compile(rf'^\s*(local\s+|internal\s+)?procedure\s+{re.escape(name)}\b', re.IGNORECASE)
    for lines in lines_by_unit.values():
        for line in lines:
            if decl.match(line):
                continue
            if pattern.search(strip_strings(line)):
                return True
    return False


def percent(covered, total):
    return 100.0 if total == 0 else 100.0 * covered / total


class Checker:
    def __init__(self, root, register_path=None):
        self.root = Path(root)
        path = Path(register_path) if register_path else self.root / REGISTER
        self.register = json.loads(path.read_text(encoding="utf-8-sig"))
        self.errors, self.warnings, self.lines = [], [], []
        self.objects = index_objects(self.root / "app" / "src")
        self.tests, self.declared, self.test_lines = index_tests(self.root / "test" / "src")
        self.members = {}
        self.valid_traces = {}

    def scope_keys(self):
        scope = self.register.get("scope", {})
        logic = [("table", i) for i in scope.get("businessLogic", {}).get("tables", [])]
        logic += [("codeunit", i) for i in scope.get("businessLogic", {}).get("codeunits", [])]
        apis = [("page", i) for i in scope.get("apis", {}).get("pages", [])]
        return logic, apis

    def test_exists(self, ref):
        return ref.get("test") in self.tests.get(ref.get("codeunit"), {})

    def check_integrity(self):
        logic, apis = self.scope_keys()
        for key in logic + apis:
            if key not in self.objects:
                self.errors.append(f"Coverage register: in-scope {key[0]} {key[1]} does not exist in app/src.")
            else:
                self.members[key] = index_members(self.objects[key])
        self.check_traces()
        self.check_rules()

    def check_traces(self):
        for trace in self.register.get("traces", []):
            key = (trace.get("type", "").lower(), trace.get("id"))
            label = f"trace {key[0]} {key[1]} {trace.get('member')}"
            if key not in self.objects:
                self.errors.append(f"Coverage register: {label}: object does not exist.")
                continue
            names = [m for m, _ in self.members.get(key) or index_members(self.objects[key])]
            if trace.get("member") not in names:
                self.errors.append(f"Coverage register: {label}: member does not exist.")
                continue
            ok = bool(trace.get("tests"))
            for ref in trace.get("tests", []):
                if not self.test_exists(ref):
                    self.errors.append(f"Coverage register: {label}: test {ref.get('codeunit')}/"
                                       f"{ref.get('test')} does not exist as [Test].")
                    ok = False
                elif key[0] == "page":
                    name = self.objects[key]["name"]
                    body = self.tests[ref["codeunit"]][ref["test"]]
                    if not re.search(rf'TestPage\s+"{re.escape(name)}"|Page::"{re.escape(name)}"', body,
                                     re.IGNORECASE):
                        self.errors.append(f"Coverage register: {label}: test {ref['codeunit']}/{ref['test']} "
                                           f'does not run the page ("{name}"); table-procedure tests do not '
                                           f"count for API reach.")
                        ok = False
            if ok:
                self.valid_traces[(key, trace["member"].lower())] = True

    def rule_sites(self, key):
        """Returns [(member, rule key)] for every Error(/TestField( site, in source order.

        Repeats of the same key in one member are numbered: key, key#2, key#3.
        """
        obj = self.objects[key]
        members = parse_members(obj["text"])
        found = []
        for regex, build in ((ERROR_SITE_RE, lambda g: g.strip()),
                             (TESTFIELD_SITE_RE, lambda g: "TestField:" + unquote(g))):
            for match in regex.finditer(obj["text"]):
                line = obj["text"].count("\n", 0, match.start()) + 1
                member = "(object)"
                for no, name, _kind, _local, _attrs in members:
                    if no <= line:
                        member = name
                found.append((match.start(), member, build(match.group(1))))
        sites, seen = [], {}
        for _, member, rule_key in sorted(found):
            seen[(member, rule_key)] = seen.get((member, rule_key), 0) + 1
            count = seen[(member, rule_key)]
            sites.append((member, rule_key if count == 1 else f"{rule_key}#{count}"))
        return sites

    def check_rules(self):
        registered = set()
        for process in self.register.get("criticalProcesses", []):
            for rule in process.get("rules", []):
                rel = rule.get("file", "")
                if not (self.root / rel).exists():
                    self.errors.append(f"Coverage register: {process.get('id')} rule {rel}: file does not exist.")
                registered.add((rel, rule.get("procedure"), rule.get("key")))
                if rule.get("positiveNotApplicable") and not rule.get("note"):
                    self.errors.append(f"Coverage register: {process.get('id')} rule {rule.get('procedure')}/"
                                       f"{rule.get('key')}: positiveNotApplicable needs a note that says why.")
                for side in ("positive", "negative"):
                    for ref in rule.get(side, []):
                        if not self.test_exists(ref):
                            self.errors.append(
                                f"Coverage register: {process.get('id')} rule {rule.get('procedure')}/"
                                f"{rule.get('key')}: {side} test {ref.get('codeunit')}/{ref.get('test')} "
                                f"does not exist as [Test].")
        scanned = {}
        for process in self.register.get("criticalProcesses", []):
            for ref in process.get("objects", []):
                okey = (ref.get("type", "").lower(), ref.get("id"))
                if okey in self.objects:
                    rel = self.objects[okey]["file"].relative_to(self.root).as_posix()
                    scanned[rel] = {(m, k) for m, k in self.rule_sites(okey)}
        for process in self.register.get("criticalProcesses", []):
            for rule in process.get("rules", []):
                rel = rule.get("file", "")
                if rel in scanned and (rule.get("procedure"), rule.get("key")) not in scanned[rel]:
                    self.errors.append(f"Coverage register: {process.get('id')} rule {rel}: "
                                       f"{rule.get('procedure')} / {rule.get('key')} has no matching "
                                       f"Error(/TestField( site any more.")
        for process in self.register.get("criticalProcesses", []):
            for ref in process.get("objects", []):
                key = (ref.get("type", "").lower(), ref.get("id"))
                if key not in self.objects:
                    self.errors.append(f"Coverage register: {process.get('id')} object {key[0]} {key[1]} "
                                       f"does not exist.")
                    continue
                rel = self.objects[key]["file"].relative_to(self.root).as_posix()
                for member, rule_key in self.rule_sites(key):
                    if (rel, member, rule_key) not in registered:
                        self.errors.append(f"{rel}: rule site {member} / {rule_key} has no entry in the "
                                           f"coverage register ({process.get('id')}).")

    def covered_logic(self, key, member, kind):
        if (key, member.lower()) in self.valid_traces:
            return True
        if kind == "subscriber" or key[0] == "page":
            return False
        obj = self.objects[key]
        if member == "OnRun":
            text = "\n".join("\n".join(lines) for lines in self.test_lines.values())
            return bool(re.search(rf'Codeunit::"{re.escape(obj["name"])}"|Codeunit\.Run\(\s*{key[1]}\b',
                                  text, re.IGNORECASE))
        return not self.is_ambiguous(member) and is_called(member, self.test_lines)

    def is_ambiguous(self, member):
        if member.lower() in self.declared:
            return True
        owners = 0
        for key in self.in_scope_logic:
            if any(m.lower() == member.lower() for m, kind in self.members.get(key, []) if kind == "procedure"):
                owners += 1
        return owners > 1

    def reach(self, keys):
        covered, uncovered = 0, []
        for key in keys:
            for member, kind in self.members.get(key, []):
                if self.covered_logic(key, member, kind):
                    covered += 1
                else:
                    uncovered.append(f"{key[0]} {key[1]} {self.objects[key]['name']}: {member}")
        return covered, uncovered

    def rule_coverage(self):
        total, covered, gaps = 0, 0, []
        for process in self.register.get("criticalProcesses", []):
            for rule in process.get("rules", []):
                total += 1
                missing = []
                if not rule.get("positive") and not rule.get("positiveNotApplicable"):
                    missing.append("positive")
                if not rule.get("negative"):
                    missing.append("negative")
                if rule.get("gap") or missing:
                    reason = "gap" if rule.get("gap") else "missing " + "+".join(missing)
                    gaps.append(f"{process.get('id')} {Path(rule.get('file', '')).name}: "
                                f"{rule.get('procedure')} / {rule.get('key')} ({reason})")
                else:
                    covered += 1
        return covered, total, gaps

    def run(self):
        self.check_integrity()
        logic, apis = self.scope_keys()
        self.in_scope_logic = [k for k in logic if k in self.objects]
        targets = self.register.get("targets", {})
        enforce = bool(self.register.get("enforce"))
        rows = []
        logic_cov, logic_unc = self.reach(self.in_scope_logic)
        logic_tot = sum(len(self.members.get(k, [])) for k in self.in_scope_logic)
        api_keys = [k for k in apis if k in self.objects]
        api_cov, api_unc = self.reach(api_keys)
        api_tot = sum(len(self.members.get(k, [])) for k in api_keys)
        cp_cov, cp_tot, cp_gaps = self.rule_coverage()
        rows.append(("Business Logic", "procedure reach", logic_cov, logic_tot, targets.get("businessLogic", 0)))
        rows.append(("APIs", "procedure reach", api_cov, api_tot, targets.get("apis", 0)))
        rows.append(("Critical Processes", "rule coverage", cp_cov, cp_tot, targets.get("criticalProcesses", 0)))
        names = {"Business Logic": "Business Logic procedure reach", "APIs": "API procedure reach",
                 "Critical Processes": "Critical Process rule coverage"}
        for area, _metric, cov, tot, target in rows:
            pct = percent(cov, tot)
            self.lines.append(f"{names[area]}: {pct:.1f}% ({cov}/{tot}, target {target})")
            if pct < target:
                msg = (f"{names[area]} is {pct:.1f}% ({cov}/{tot}), below the target of {target}%. "
                       f"This is procedure reach / rule coverage, not line coverage.")
                if enforce:
                    self.errors.append(msg)
                else:
                    self.warnings.append(msg)
        self.list_items("Uncovered Business Logic members", logic_unc)
        self.list_items("Uncovered API members", api_unc)
        self.list_items("Critical Process gaps", cp_gaps)
        self.write_summary(rows)
        return self.errors, self.warnings, self.lines

    def list_items(self, title, items):
        if not items:
            return
        self.lines.append(f"{title} ({len(items)}, showing {min(len(items), AREA_LIMIT)}):")
        self.lines.extend(f"  - {item}" for item in items[:AREA_LIMIT])

    def write_summary(self, rows):
        path = os.environ.get("GITHUB_STEP_SUMMARY")
        if not path:
            return
        table = ["### Test coverage (procedure reach, not line coverage)", "",
                 "| Area | Metric | Result | Target |", "|---|---|---|---|"]
        for area, metric, cov, tot, target in rows:
            table.append(f"| {area} | {metric} | {percent(cov, tot):.1f}% ({cov}/{tot}) | {target}% |")
        with open(path, "a", encoding="utf-8") as handle:
            handle.write("\n".join(table) + "\n")


def run(root=ROOT, register_path=None):
    """Returns (errors, warnings, summary_lines)."""
    return Checker(root, register_path).run()


def main():
    errors, warnings, lines = run(ROOT)
    print("\n".join(lines))
    for msg in warnings:
        print(f"::warning::{msg}")
    for msg in errors:
        print(f"::error::{msg}")
    if errors:
        print(f"\n{len(errors)} coverage check problem(s) found.")
        sys.exit(1)


if __name__ == "__main__":
    main()
