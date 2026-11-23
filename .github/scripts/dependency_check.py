#!/usr/bin/env python3
"""Dependency matrix check (FR-063). Keeps docs/architecture/dependencies.md equal to the app.json files.

Rules (the message starts with the rule ID):
  DEP1  app/app.json (and test/app.json when present) is a JSON object with "application" and "runtime".
  DEP2  test/app.json has the same "application" and "runtime" as app/app.json.
  DEP3  No manifest lists Base Application or System Application in dependencies (AppSourceCop AS0085).
  DEP4  docs/architecture/dependencies.md has the manifest-values rows and every declared dependency id.
  DEP5  Microsoft dependencies of the test app have a valid version that is not above its application.
  DEP6  With --base: warning for every change of application, platform, runtime or dependencies.

Usage: dependency_check.py [--base <git ref>]
Stdlib only, Python 3.9 compatible. Errors exit 1; warnings are printed as GitHub annotations.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from version_check import parse_version  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
MATRIX_DOC = "docs/architecture/dependencies.md"
MANIFESTS = ("app/app.json", "test/app.json")
PLATFORM_PROPS = ("application", "platform", "runtime")
BASE_APPLICATION_ID = "437dbf0e-84ff-417a-965d-ed2bb9650972"
SYSTEM_APPLICATION_ID = "63ca2fa4-4f03-4f2b-a480-172fef340d3f"
ADVICE = (
    "Changes to app.json are a stop-list decision (CLAUDE.md): log it in DECISIONS.md and update the matrix "
    "and upgrade notes in docs/architecture/dependencies.md.")


def load_manifest(root, rel):
    path = Path(root) / rel
    if not path.exists():
        return None, False
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except ValueError:
        return None, True
    return (data if isinstance(data, dict) else None), True


def declared(manifest):
    items = manifest.get("dependencies", [])
    result = {}
    if not isinstance(items, list):
        return result
    for item in items:
        if isinstance(item, dict) and isinstance(item.get("id"), str):
            result[item["id"].lower()] = item
    return result


def dep_name(item):
    return item.get("name") or item.get("id")


def prop_text(manifest, prop):
    if manifest is None or prop not in manifest:
        return "none"
    return str(manifest.get(prop))


def run(root=ROOT, base_texts=None):
    root = Path(root)
    errors, warnings, summary = [], [], []

    app, app_exists = load_manifest(root, "app/app.json")
    if app is None:
        errors.append("DEP1 app/app.json is missing or not a JSON object.")
        return errors, warnings, summary
    test, test_exists = load_manifest(root, "test/app.json")
    if test_exists and test is None:
        errors.append("DEP1 test/app.json is not a JSON object.")
    manifests = [("app/app.json", app)]
    if test is not None:
        manifests.append(("test/app.json", test))
    for rel, data in manifests:
        for prop in ("application", "runtime"):
            value = data.get(prop)
            if not isinstance(value, str) or not value:
                errors.append(f"DEP1 {rel} has no \"{prop}\".")
    if not test_exists:
        summary.append("test/app.json not found: DEP2 and DEP5 skipped.")

    if test is not None:
        for prop in ("application", "runtime"):
            if prop in test and prop in app and test[prop] != app[prop]:
                errors.append(
                    f"DEP2 test/app.json {prop} is \"{test[prop]}\" but app/app.json has \"{app[prop]}\". "
                    "Build the test app against the same Business Central version.")

    for rel, data in manifests:
        ids = declared(data)
        for forbidden_id, name in ((BASE_APPLICATION_ID, "Base Application"),
                                   (SYSTEM_APPLICATION_ID, "System Application")):
            if forbidden_id in ids:
                errors.append(
                    f"DEP3 {rel} lists {name} in dependencies. "
                    "Use the \"application\" property instead (AppSourceCop AS0085).")

    doc_path = root / MATRIX_DOC
    if not doc_path.exists():
        errors.append(f"DEP4 {MATRIX_DOC} is missing. It holds the dependency matrix (FR-063).")
    else:
        text = doc_path.read_text(encoding="utf-8-sig")
        for prop in PLATFORM_PROPS:
            app_value = prop_text(app, prop)
            test_value = prop_text(test, prop)
            pattern = (r"^\|\s*`" + re.escape(prop) + r"`\s*\|\s*`" + re.escape(app_value)
                       + r"`\s*\|\s*`" + re.escape(test_value) + r"`\s*\|")
            if not re.search(pattern, text, re.M):
                errors.append(
                    f"DEP4 {MATRIX_DOC} has no manifest-values row | `{prop}` | `{app_value}` | `{test_value}` |. "
                    "Update the 'Manifest values' table.")
        lowered = text.lower()
        for rel, data in manifests:
            for dep_id, item in declared(data).items():
                if dep_id not in lowered:
                    errors.append(
                        f"DEP4 dependency {dep_name(item)} ({item['id']}) from {rel} is not in the dependency "
                        f"matrix in {MATRIX_DOC}.")

    if test is not None:
        application = parse_version(test.get("application"))
        for item in declared(test).values():
            if item.get("publisher") != "Microsoft":
                continue
            version = parse_version(item.get("version"))
            if version is None:
                errors.append(
                    f"DEP5 test/app.json dependency {dep_name(item)} has a version that is not "
                    "Major.Minor.Build.Revision.")
            elif application is not None and version > application:
                errors.append(
                    f"DEP5 test/app.json dependency {dep_name(item)} requires {item.get('version')}, which is "
                    f"above the test app's application {test.get('application')}. It would not resolve on the "
                    "minimum Business Central version.")

    if base_texts is not None:
        current = {"app/app.json": app, "test/app.json": test}
        for rel in MANIFESTS:
            base = None
            if base_texts.get(rel) is not None:
                try:
                    base = json.loads(base_texts[rel])
                except ValueError:
                    base = None
            if not isinstance(base, dict):
                summary.append(f"DEP6 skipped for {rel}: not readable on the base ref.")
                continue
            now = current[rel]
            if now is None:
                continue
            for prop in PLATFORM_PROPS:
                if base.get(prop) != now.get(prop):
                    warnings.append(
                        f"DEP6 {rel} {prop} changed from \"{base.get(prop)}\" to \"{now.get(prop)}\". {ADVICE}")
            base_deps, now_deps = declared(base), declared(now)
            for dep_id, item in now_deps.items():
                if dep_id not in base_deps:
                    warnings.append(
                        f"DEP6 {rel} dependency {dep_name(item)} ({item['id']}) added. {ADVICE}")
                elif base_deps[dep_id].get("version") != item.get("version"):
                    warnings.append(
                        f"DEP6 {rel} dependency {dep_name(item)} ({item['id']}) version changed from "
                        f"{base_deps[dep_id].get('version')} to {item.get('version')}. {ADVICE}")
            for dep_id, item in base_deps.items():
                if dep_id not in now_deps:
                    warnings.append(
                        f"DEP6 {rel} dependency {dep_name(item)} ({item['id']}) removed. {ADVICE}")

    summary.append(
        f"Dependencies: app/app.json declares {len(declared(app))}, test/app.json declares "
        f"{len(declared(test)) if test is not None else 0}; minimum Business Central application "
        f"{app.get('application')}, runtime {app.get('runtime')}")
    return errors, warnings, summary


def read_base_texts(root, base):
    result = {}
    for rel in MANIFESTS:
        proc = subprocess.run(
            ["git", "show", f"{base}:{rel}"], cwd=root, capture_output=True, text=True, check=False)
        result[rel] = proc.stdout if proc.returncode == 0 else None
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base")
    args = parser.parse_args()
    base_texts = read_base_texts(ROOT, args.base) if args.base else None
    errors, warnings, summary = run(ROOT, base_texts)
    for line in summary:
        print(line)
    for msg in warnings:
        print(f"::warning::{msg}")
    for msg in errors:
        print(f"::error::{msg}")
    if errors:
        sys.exit(1)
    print("Dependency check: OK")


if __name__ == "__main__":
    main()
