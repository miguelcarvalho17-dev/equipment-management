#!/usr/bin/env python3
"""Version policy check (FR-049). Major.Minor come from app/app.json, Build and Revision from AL-Go CI/CD.

Rules (the message starts with the rule ID):
  VER1  app/app.json (and test/app.json when present) has a version in Major.Minor.Build.Revision form.
  VER2  app/app.json keeps Build and Revision at 0 (AL-Go versioningStrategy 0 stamps them).
  VER3  .AL-Go/settings.json repoVersion equals Major.Minor of app/app.json.
  VER4  .AL-Go/settings.json versioningStrategy is 0 when present.
  VER5  test/app.json depends on the app with a minimum version that is not above the app version.
  VER6  With --base: the app version is not lower than on the base branch.
  VER7  With --base: warning when Major or Minor was raised (upgrade and release-notes reminder).

Usage: version_check.py [--base <git ref>]
Stdlib only, Python 3.9 compatible. Errors exit 1; warnings are printed as GitHub annotations.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VERSION_RE = re.compile(r"^\d+\.\d+\.\d+\.\d+$")
SETTINGS_FILE = ".AL-Go/settings.json"


def parse_version(text):
    if not isinstance(text, str) or not VERSION_RE.match(text):
        return None
    return tuple(int(part) for part in text.split("."))


def load_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def fmt(version):
    return ".".join(str(part) for part in version)


def run(root=ROOT, base_app_json=None):
    root = Path(root)
    errors, warnings, summary = [], [], []

    app_path = root / "app" / "app.json"
    app = None
    app_version = None
    if app_path.exists():
        try:
            app = load_json(app_path)
        except ValueError:
            app = None
    if app is not None:
        app_version = parse_version(app.get("version"))
    if app_version is None:
        errors.append("VER1 app/app.json is missing or its version is not in Major.Minor.Build.Revision form.")
        return errors, warnings, summary

    test_path = root / "test" / "app.json"
    test_app = None
    if test_path.exists():
        try:
            test_app = load_json(test_path)
        except ValueError:
            test_app = None
        if test_app is None or parse_version(test_app.get("version")) is None:
            errors.append("VER1 test/app.json version is not in Major.Minor.Build.Revision form.")

    summary.append(
        f"App version: {fmt(app_version)} (Major.Minor from app/app.json; "
        "Build and Revision stamped by AL-Go CI/CD, versioningStrategy 0)")

    if app_version[2] != 0 or app_version[3] != 0:
        errors.append(
            f"VER2 app/app.json version {fmt(app_version)} has Build or Revision other than 0. "
            "Build and Revision are set by AL-Go CI/CD (versioningStrategy 0); keep them 0 in app.json.")

    settings = None
    settings_path = root / SETTINGS_FILE
    if settings_path.exists():
        try:
            settings = load_json(settings_path)
        except ValueError:
            settings = None
    expected = f"{app_version[0]}.{app_version[1]}"
    if not isinstance(settings, dict):
        errors.append(f"VER3 {SETTINGS_FILE} is missing or not valid JSON; it must set repoVersion to \"{expected}\".")
    else:
        repo_version = settings.get("repoVersion")
        if repo_version != expected:
            errors.append(
                f"VER3 {SETTINGS_FILE} repoVersion is {json.dumps(repo_version)} but Major.Minor of app/app.json "
                f"is \"{expected}\". Set repoVersion to \"{expected}\".")
        if "versioningStrategy" in settings and settings["versioningStrategy"] != 0:
            errors.append(
                f"VER4 {SETTINGS_FILE} versioningStrategy is {json.dumps(settings['versioningStrategy'])}; "
                "this project uses versioningStrategy 0.")

    if test_app is None:
        if not test_path.exists():
            summary.append("test/app.json not found: VER5 skipped.")
    else:
        app_id = app.get("id")
        dependency = None
        for item in test_app.get("dependencies", []):
            if isinstance(item, dict) and item.get("id") == app_id:
                dependency = item
                break
        if dependency is None:
            errors.append("VER5 test/app.json has no dependency on the app id from app/app.json.")
        else:
            minimum = parse_version(dependency.get("version"))
            if minimum is None:
                errors.append("VER5 the test app dependency on the app has a version that is not Major.Minor.Build.Revision.")
            elif minimum > app_version:
                errors.append(
                    f"VER5 the test app depends on app version {fmt(minimum)}, which is higher than the app "
                    f"version {fmt(app_version)}.")

    if base_app_json is not None:
        base_version = None
        try:
            base_version = parse_version(json.loads(base_app_json).get("version"))
        except (ValueError, AttributeError):
            base_version = None
        if base_version is None:
            warnings.append("VER6 skipped: the base app.json is not valid JSON or has no parsable version.")
        else:
            if app_version < base_version:
                errors.append(
                    f"VER6 app version {fmt(app_version)} is lower than the base version {fmt(base_version)}.")
            elif app_version[:2] > base_version[:2]:
                warnings.append(
                    f"VER7 app version raised from {fmt(base_version)} to {fmt(app_version)}: before releasing, "
                    "check upgrade steps (docs/features/FR-044-data-upgrade-support.md, 'How to add an upgrade step') "
                    "and the release notes in CHANGELOG.md.")

    return errors, warnings, summary


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base")
    args = parser.parse_args()
    base_text = None
    if args.base:
        result = subprocess.run(
            ["git", "show", f"{args.base}:app/app.json"], cwd=ROOT, capture_output=True, text=True, check=False)
        base_text = result.stdout if result.returncode == 0 else None
    errors, warnings, summary = run(ROOT, base_text)
    for line in summary:
        print(line)
    for msg in warnings:
        print(f"::warning::{msg}")
    for msg in errors:
        print(f"::error::{msg}")
    if errors:
        sys.exit(1)
    print("Version policy: OK")


if __name__ == "__main__":
    main()
