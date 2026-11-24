# FR-063 Dependency Management

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
External dependencies are documented and version-controlled (GitHub issue #104). One developer page, `docs/architecture/dependencies.md`, holds the minimum Business Central version, the dependency matrix and the upgrade notes. Check 9 of `repo_checks.py` keeps the page equal to `app/app.json` and `test/app.json`.

Plan: `docs/plans/FR-063-dependency-management.md` (approved).

| Deliverable of the issue | Section in `dependencies.md` |
|---|---|
| Minimum BC Version | [Minimum Business Central version](../architecture/dependencies.md#minimum-business-central-version) and [Manifest values](../architecture/dependencies.md#manifest-values) |
| Dependency Matrix | [Dependency matrix](../architecture/dependencies.md#dependency-matrix), [Removed and unused dependencies](../architecture/dependencies.md#removed-and-unused-dependencies), [Standard modules used](../architecture/dependencies.md#standard-modules-used), [Tooling dependencies](../architecture/dependencies.md#tooling-dependencies) |
| Upgrade Notes | [Upgrade notes](../architecture/dependencies.md#upgrade-notes) and [Known gaps](../architecture/dependencies.md#known-gaps) |

## Status
- Branch `feature/FR-063-dependency-management`. Files not committed at the time of writing.
- New: `docs/architecture/dependencies.md`, `.github/scripts/dependency_check.py`, `.github/scripts/test_dependency_check.py`.
- Changed: `.github/scripts/repo_checks.py` (check 9), and link updates in the docs pages.
- No AL change. No change to `app.json`, `.AL-Go/` or any workflow. App version stays 29.0.0.0.

## Rules
The check prints a summary line `Dependencies: ...` and `Dependency check: OK` when there are no errors. The rule ID starts every message.

| Rule | Severity | What it finds |
|---|---|---|
| DEP1 | Error | `app/app.json` is missing or not a JSON object, `test/app.json` (when present) is not a JSON object, or a manifest has no `application` or `runtime`. A missing `test/app.json` is not an error; DEP2 and DEP5 are skipped and the summary says so |
| DEP2 | Error | The test app has a different `application` or `runtime` than the app |
| DEP3 | Error | A manifest lists Base Application or System Application in `dependencies` (AppSourceCop AS0085) |
| DEP4 | Error | `docs/architecture/dependencies.md` is missing, lacks a Manifest values row that matches the manifests, or lacks the id of a declared dependency |
| DEP5 | Error | A Microsoft dependency of the test app has a version that is not Major.Minor.Build.Revision, or is above the test app's `application` |
| DEP6 | Warning | With `--base`: `application`, `platform`, `runtime` or a dependency (added, removed, version changed) differs from the base ref |

DEP6 is a warning because a change approved by the user (stop list) must still merge. DEP4 forces the page update in the same pull request.

## Verification status
- **AL:** no AL change, so no AL compile and no AL tests.
- **Python tests:** `.github/scripts/test_dependency_check.py` has 22 tests. Run locally; see the handoff for the result lines. CI does not run Python tests.
- **CI:** not verified. The result of check 9 is in the "Repo checks" log of the pull request, after the push.
- **AppSource validation:** no separate AppSource validation ran.
- **Symbols:** `al_symbolsearch` had no project loaded. The namespace examples on the page come from reading `app/src`, not from symbols. Which Microsoft app owns each namespace is not stated.

## Conflicts found
- The issue lists Any and Tests-TestLibraries as test dependencies. The manifest has only Library Assert. Tests-TestLibraries was removed in FR-026, and Any was never added. The page records the real state.
- `platform` is `1.0.0.0` in both manifests, not `29.0.0.0`.
- The test app's minimum dependency on the app is `1.0.0.0`.
- CI builds on the AL-Go default artifact, not on the minimum release 29.0. The page does not claim tested support for 29.0.

All of these are `app.json` or AL-Go settings changes (stop list) and are listed as user decisions.

## Maintaining the page
Update the Manifest values table and the matrix in the same pull request as any `app.json` change. The Manifest values table format is parsed by DEP4: keep the rows `| \`application\` | \`<app>\` | \`<test>\` | ... |` as they are. The error message prints the expected row.

## Open items and later phases
- Phase 2 (user decision, stop list): `platform` to `29.0.0.0`, and the test app's minimum on the app to `29.0.0.0`.
- Phase 3 (user decision, AL-Go settings): a CI build pinned to the minimum release, and scheduled Next Minor and Next Major runs.
- Phase 4: after the first release, a per-release upgrade notes entry in the FR-049 release procedure.
- Reviewer findings, MINOR, open in `.github/scripts/dependency_check.py` and its tests (not fixed in the docs step):
  - m1: DEP6 does not strip a UTF-8 byte order mark (BOM) from the base manifest text. A base file with a BOM is read as unreadable, so DEP6 is skipped for it and the summary says "DEP6 skipped".
  - m2: DEP6 gives no warning when `test/app.json` is deleted in the pull request. The manifest is skipped silently by DEP6 (DEP2 and DEP5 are skipped and the summary says so).
  - m3: no unit tests for DEP6 "removed", for DEP3 with the Base Application id or on `app.json`, or for DEP1 when `app/app.json` is missing.
- Open checks are in [`docs/TODO.md`](../TODO.md), section "FR-063 checks".

## Related
[Dependencies](../architecture/dependencies.md), [help article](../help/FR-063-dependency-management.md), [FR-026](FR-026-equipment-api.md), [FR-044](FR-044-data-upgrade-support.md), [FR-049](FR-049-release-management.md), [FR-060](FR-060-developer-documentation.md), [FR-062](FR-062-breaking-change-validation.md), [CI/CD](../setup/ci-cd.md)
