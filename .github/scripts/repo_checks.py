#!/usr/bin/env python3
"""Repository rule checks that the AL compiler cannot do (see CLAUDE.md).

Checks:
  1. Object IDs: unique per object type, and inside the idRanges of the app that owns them.
  2. Feature branches (feature/FR-NNN-*): plan, feature doc, help article and CHANGELOG entry exist.
  3. Plans changed in the PR no longer say DRAFT / waiting for approval in their status header.
  4. Warning only: AL code under app/src changed but the .g.xlf translation file did not.

Usage: repo_checks.py [--base <git ref>] [--branch <head branch name>]
Without --base, only the checks that need no diff run (1, and 2 when --branch is given).
Stdlib only. Errors exit 1; warnings are printed as GitHub annotations.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OBJECT_RE = re.compile(
    r'^\s*(table|tableextension|page|pageextension|codeunit|enum|enumextension|permissionset|'
    r'permissionsetextension|report|reportextension|query|xmlport|profile|controladdin)\s+(\d+)\b',
    re.IGNORECASE | re.MULTILINE)
errors = []


def error(msg, file=None):
    errors.append(msg)
    print(f"::error{' file=' + file if file else ''}::{msg}")


def warning(msg, file=None):
    print(f"::warning{' file=' + file if file else ''}::{msg}")


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout


def check_object_ids():
    for folder in ("app", "test"):
        app_json = ROOT / folder / "app.json"
        if not app_json.exists():
            continue
        ranges = [(r["from"], r["to"]) for r in json.loads(app_json.read_text(encoding="utf-8-sig"))["idRanges"]]
        seen = {}
        for al in sorted((ROOT / folder).rglob("*.al")):
            rel = al.relative_to(ROOT).as_posix()
            for kind, number in OBJECT_RE.findall(al.read_text(encoding="utf-8-sig")):
                kind, number = kind.lower(), int(number)
                if not any(lo <= number <= hi for lo, hi in ranges):
                    error(f"{kind} {number} is outside the {folder} ID range {ranges}.", rel)
                key = (kind, number)
                if key in seen:
                    error(f"Duplicate {kind} ID {number}: also used in {seen[key]}.", rel)
                else:
                    seen[key] = rel
    if not errors:
        print("Object IDs: OK")


def check_feature_files(branch):
    match = re.match(r"feature/(FR-\d+|NFR-\d+)-", branch or "")
    if not match:
        print(f"Feature files: skipped (branch '{branch}' is not feature/FR-NNN-*).")
        return
    fid = match.group(1)
    for folder, label in (("docs/plans", "technical plan"), ("docs/features", "feature doc"),
                          ("docs/help", "help article")):
        if not list((ROOT / folder).glob(f"{fid}-*.md")):
            error(f"{fid}: no {label} found at {folder}/{fid}-*.md.")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    if not re.search(rf"^##\s+{re.escape(fid)}\b", changelog, re.MULTILINE):
        error(f"{fid}: CHANGELOG.md has no '## {fid} ...' section.", "CHANGELOG.md")
    print(f"Feature files for {fid}: checked.")


def changed_files(base):
    out = git("diff", "--name-only", "--diff-filter=AM", f"{base}...HEAD")
    return [line for line in out.splitlines() if line]


def check_plan_headers(files):
    for rel in files:
        if not re.fullmatch(r"docs/plans/(N?FR-\d+)-.*\.md", rel) or "-events" in rel:
            continue
        header = "\n".join((ROOT / rel).read_text(encoding="utf-8").splitlines()[:12])
        status = re.search(r"^>\s*Status:.*(?:\n>.*)*", header, re.MULTILINE)
        text = status.group(0) if status else ""
        if not status:
            error("Plan has no '> Status:' header.", rel)
        elif re.search(r"\bDRAFT\b|waiting for (human )?approval|awaiting (user )?approval", text, re.IGNORECASE):
            error("Plan status still says DRAFT / waiting for approval. Update it to the approval state.", rel)


def check_translations(files):
    al_changed = [f for f in files if f.startswith("app/src/") and f.endswith(".al")]
    xlf_changed = any(f.startswith("app/Translations/") and f.endswith(".g.xlf") for f in files)
    if al_changed and not xlf_changed:
        warning("AL code changed but app/Translations/*.g.xlf was not updated. "
                "If captions, tooltips or labels changed, build in VS Code and commit the regenerated file.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base")
    parser.add_argument("--branch")
    args = parser.parse_args()
    check_object_ids()
    check_feature_files(args.branch)
    if args.base:
        files = changed_files(args.base)
        check_plan_headers(files)
        check_translations(files)
    if errors:
        print(f"\n{len(errors)} problem(s) found.")
        sys.exit(1)
    print("\nAll repository checks passed.")


if __name__ == "__main__":
    main()
