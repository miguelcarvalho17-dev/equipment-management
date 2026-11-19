# FR-049 Release Management — Plan
> Request (verbatim): FR-049 Release Management (GitHub issue #90)
> Status: **approved**
> Branch feature/FR-049-release-management. No AL code, no app.json change, no events report.

## Request
Issue #90: "The solution shall support automated versioning. Version Format: Major.Minor.Build.Revision. Example: 4.0.0.0. Business Value: Simplifies deployment and maintenance. Related: FR-048 Automated Build Pipeline, FR-044 (every release after 29.0.0.0 needs an upgrade codeunit)."

Most of this is already in place. AL-Go `versioningStrategy` 0 is active by default: Major.Minor come from `app/app.json` (29.0) and CI/CD stamps Build and Revision. This feature:
- makes that policy explicit;
- lines up the artifact and release numbers with the app version (today `1.0.<run>.0` while the `.app` is `29.0.x`);
- adds a static version guard to Repo checks;
- documents the release and version-bump procedure, including the FR-044 upgrade checklist;
- does not touch `app.json`, AL code or AL-Go system workflows.

Target: AppSource

## Definition of done
- [ ] Step 0 verification gate done and findings recorded in the feature doc: AL-Go v10.0 semantics of `versioningStrategy` 0 and `repoVersion`, and whether IncrementVersionNumber updates `repoVersion`.
- [ ] `.AL-Go/settings.json` has `"repoVersion": "29.0"` and `"versioningStrategy": 0`, nothing else changes. `python3 -m json.tool .AL-Go/settings.json` succeeds.
- [ ] New `.github/scripts/version_check.py` (stdlib only, Python 3.9 compatible) with `run(root, base_app_json=None) -> (errors, warnings, summary)` implementing VER1–VER7.
- [ ] New `.github/scripts/test_version_check.py` (unittest) passes.
- [ ] `.github/scripts/test_coverage_check.py` still passes.
- [ ] `repo_checks.py` runs the version check as check 6; `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-049-release-management` exits 0 and prints an `App version: 29.0.0.0 ...` summary line.
- [ ] No change to `app/`, `test/`, either `app.json`, `.github/workflows/*`, `.github/AL-Go-Settings.json` (unless the step 0 fallback applies), rulesets or `AppSourceCop.json`.
- [ ] Docs: `docs/features/FR-049-release-management.md`, `docs/help/FR-049-release-management.md`, `CHANGELOG.md` section `## FR-049 Release Management (version stays 29.0.0.0, no bump)` at the top, `docs/TODO.md` section `## FR-049 checks ...`, `docs/help/FR-048-automated-build-pipeline.md` line 21 corrected to the new artifact names.
- [ ] Reports say "No separate AppSource validation ran" and "Not verified: CI result pending" until a push.

## Out of scope
- Bumping the version in `app/app.json` or `test/app.json` (stop list); stays 29.0.0.0.
- Running Create release or Increment Version Number (user decision, as FR-048 Q2).
- Editing AL-Go system workflows (UpdateGitHubGoSystemFiles would overwrite them).
- PublishToAppSource / Partner Center delivery and secrets (stop list).
- Release branches and hotfix procedure, FR-062 AppSourceCop baseline, app signing.
- Changing `.github/Test *.settings.json` (`versioningStrategy` 15 is AL-Go's own for test workflows).
- Rewriting the FR-048 plan and feature doc (historical). Only its help article is corrected.
- Later phases: (2) user-run first release `29.0.<build>`, then bump main to 29.1; (3) release-branch hotfix procedure; (4) automated AppSource delivery (needs secrets, stop list).

## Objects
No AL objects, no IDs.

| Type | Name | New/Changed | File |
|---|---|---|---|
| AL-Go project settings | repoVersion, versioningStrategy | Changed | `.AL-Go/settings.json` |
| Python script | Version check | New | `.github/scripts/version_check.py` |
| Python tests | Version check unit tests | New | `.github/scripts/test_version_check.py` |
| Python script | Repo checks (+ check 6) | Changed | `.github/scripts/repo_checks.py` |
| Doc | Feature doc | New | `docs/features/FR-049-release-management.md` |
| Doc | Help | New | `docs/help/FR-049-release-management.md` |
| Doc | Changelog, TODO, FR-048 help line 21 | Changed | `CHANGELOG.md`, `docs/TODO.md`, `docs/help/FR-048-automated-build-pipeline.md` |

## Events and standard symbols
None. Non-AL facts to be checked by the step 0 gate:

| Symbol | Expected behaviour |
|---|---|
| AL-Go `versioningStrategy` = 0 | Major.Minor from each app.json. Build = CI/CD `run_number` (+ `runNumberOffset`). Revision = `run_attempt` − 1 |
| AL-Go `repoVersion` | Major.Minor used for artifact and build names (default 1.0 gives `...-Apps-1.0.<run>.0`). Does not change app versions under strategy 0 |
| IncrementVersionNumber (v10.0) | Updates app.json versions, dependency versions and `repoVersion`. `.github/RELEASENOTES.copy.md` line 710 (v5.3) says repoVersion handling was fixed |
| Create release inputs | `buildVersion`, `name`, `tag`, `releaseType`, `updateVersionNumber`, `useGhTokenWorkflow` (read in `.github/workflows/CreateRelease.yaml`) |

## Steps
0. **Verification gate.** Read-only, needs `gh`.
   - a. `gh api -H "Accept: application/vnd.github.raw" "repos/microsoft/AL-Go/contents/Scenarios/settings.md?ref=v10.0"` (404 → `?ref=main`). Grep `versioningStrategy`, `repoVersion`, `runNumberOffset`, `skipUpgrade`. Confirm the table. If strategy 0 does NOT take Major.Minor from app.json with Build = run number: stop and return BLOCKED with the actual text.
   - b. `gh api -H "Accept: application/vnd.github.raw" "repos/microsoft/AL-Go-Actions/contents/IncrementVersionNumber/IncrementVersionNumber.ps1?ref=v10.0"`, grep `repoVersion`. Decision fixed:
     - updates `.AL-Go/settings.json`: plan as written;
     - updates only `.github/AL-Go-Settings.json`: put both keys there instead, and point VER3/VER4 at that file;
     - updates neither: keep `.AL-Go/settings.json` and make VER3 a warning, not an error. Record which branch applied.
   - c. `gh run list --workflow CICD.yaml --branch main -L 1 --json databaseId`, then `gh api repos/{owner}/{repo}/actions/runs/<id>/artifacts --jq '.artifacts[].name'`. Record the "before" artifact names. In the build log (`gh run view <id> --log | grep -iE "app version|29\.0\."`) record the stamped `.app` version.
   - Put all findings in the feature doc under "Verification gate".
1. **`.AL-Go/settings.json`**: insert `"repoVersion": "29.0",` and `"versioningStrategy": 0,` directly after `"country": "us",`. Change nothing else. Validate with `python3 -m json.tool`.
2. **`.github/scripts/version_check.py`** (new). Stdlib only, mirroring `coverage_check.py`. Shebang plus docstring listing the rules. `ROOT = Path(__file__).resolve().parents[2]`. Python 3.9 compatible: no `X | None`, no `match`.
   - `parse_version(text)`: tuple of 4 ints or `None` unless full match `^\d+\.\d+\.\d+\.\d+$`.
   - `load_json(path)`: reads with `utf-8-sig`.
   - `run(root=ROOT, base_app_json=None)`: returns `(errors, warnings, summary)`, each list of str.
   - `main()`: argparse `--base`. With `--base`, reads base text via `git show <base>:app/app.json` (`subprocess.run(..., check=False)`; non-zero → `None`). Prints summary, `::warning::`/`::error::` lines, exits 1 on errors.
   - Rules (message starts with rule ID):
     - **VER1 (error):** `app/app.json` missing or `version` does not parse; also when `test/app.json` exists and its `version` does not parse.
     - **VER2 (error):** `app/app.json` Build or Revision ≠ 0. "Build and Revision are set by AL-Go CI/CD (versioningStrategy 0); keep them 0 in app.json".
     - **VER3 (error, or warning per gate 0b):** settings file missing, `repoVersion` missing, or ≠ `"<Major>.<Minor>"` of `app/app.json`.
     - **VER4 (error):** `versioningStrategy` present and ≠ 0 (missing is OK).
     - **VER5 (error):** `test/app.json` exists and has no dependency with `id` equal to the app `id`, or that dependency's `version` does not parse or is greater than the app version (tuple compare). Missing `test/app.json`: skip with a summary note.
     - **VER6 (error, only with base):** current app version lower than base (tuple compare). Base not valid JSON or no parsable version: warning "VER6 skipped: ..." and no error.
     - **VER7 (warning, only with base):** Major or Minor higher than base. "VER7 app version raised from X to Y: before releasing, check upgrade steps (docs/features/FR-044-data-upgrade-support.md, 'How to add an upgrade step') and the release notes in CHANGELOG.md".
   - Summary line: `App version: <v> (Major.Minor from app/app.json; Build and Revision stamped by AL-Go CI/CD, versioningStrategy 0)`.
3. **`.github/scripts/test_version_check.py`** (new): unittest using a `tempfile.TemporaryDirectory` fixture writing `app/app.json`, `test/app.json`, `.AL-Go/settings.json` (pattern of `test_coverage_check.py`); cases under Tests; run until green.
4. **`.github/scripts/repo_checks.py`**: add docstring item `6. App version policy (FR-049): see version_check.py`; add `import version_check  # noqa: E402` next to `coverage_check`; add `check_versions(base)` which gets `base_text` via `subprocess.run(["git", "show", f"{base}:app/app.json"], cwd=ROOT, capture_output=True, text=True, check=False)` when `base` is set (`None` on non-zero or no base), calls `version_check.run(ROOT, base_text)`, prints the summary, sends warnings to `warning()` and errors to `error()`, prints `Version policy: OK` when no errors. In `main()` call `check_versions(args.base)` right after `check_coverage()`. Nothing else.
5. **Docs** (al-docs, after review):
   - `docs/features/FR-049-release-management.md`: Versioning policy (Major = BC major of `application` (29), raised with `application` as a user decision; Minor = feature release to AppSource; Build = CI/CD run number; Revision = run attempt − 1); Where to see the version (Extension Management, `.app` file name, artifacts `equipment-management-main-Apps-29.0.<run>.0`); Release procedure (1 main green; 2 FR-044 upgrade checklist; 3 run **Create release** with buildVersion `latest`, tag `<Major>.<Minor>.<Build>` of the promoted build e.g. `29.0.57`, name `Equipment Management 29.0.57`, releaseType Release, updateVersionNumber `+0.1`; 4 review and merge the version-bump PR (VER1–VER7 validate it); 5 upload the `.app` to Partner Center manually); Bump without a release (**Increment Version Number** `+0.1` or absolute `29.1`); Version check rules VER1–VER7; Verification gate findings; Not verified.
   - `docs/help/FR-049-release-management.md` (contributor / release manager): which version am I running, how to create a release, how to raise the version, what each VER error means and how to fix it, "bump PR has no checks" workaround (close and reopen the PR), never rename `CICD.yaml` (resets run number; if it happens set `runNumberOffset`).
   - `CHANGELOG.md`: insert before line 4 `## FR-049 Release Management (version stays 29.0.0.0, no bump)` with Added / Changed / Fixed / Obsolete, `Release notes: None (build tooling only).` and a Note line (no AL code, no app.json change, gate result, not verified items, "No separate AppSource validation ran"), same format as FR-047.
   - `docs/TODO.md`: append `## FR-049 checks (no AL change; Repo checks and CI result pending)`: run `test_version_check.py` locally; after merge confirm main CI/CD artifacts are `...-29.0.<run>.0`; on the first bump PR confirm VER3 passes and checks trigger; first release = phase 2 (user decision). Leave line 174 open.
   - `docs/help/FR-048-automated-build-pipeline.md` line 21: replace "Artifact names end in `1.0.<run>.0`. The `.app` inside keeps the version from `app.json` (29.0.x)." with "Artifact names end in `<Major>.<Minor>.<run>.0` (29.0.<run>.0 since FR-049), the same Major.Minor as the `.app` inside. See docs/help/FR-049-release-management.md."
6. Final local run: `python3 .github/scripts/test_version_check.py`, `python3 .github/scripts/test_coverage_check.py`, `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-049-release-management`. All exit 0. No AL compile needed (no AL change); say so.
7. After the user asks to push (main agent): check the PR's "Repo checks" log shows `App version: 29.0.0.0` and `Version policy: OK`, and that PR Build artifact names use 29.0. Main-branch artifact names only after merge (TODO entry).

## Tests
Python unittest in `test_version_check.py`. No AL tests (no AL change).
- T0 The real repo passes: `run(ROOT, None)` gives errors == [] and summary contains "App version: 29.0.0.0".
- T1 Valid fixture (app 29.0.0.0, repoVersion "29.0", strategy 0, test app 1.0.0.0 depending on app id at 1.0.0.0), base None: no errors, no warnings.
- T2 (neg) app version "29.0.0": one error starting "VER1".
- T3 (neg) app version 29.0.5.0: a "VER2" error.
- T4 (neg) repoVersion "1.0" (a) and missing (b): a "VER3" error each (or warning if gate 0b took the "neither" branch).
- T5 (neg) versioningStrategy 3: "VER4" error. Key missing: no VER4.
- T6 (neg) test dependency 29.1.0.0 with app 29.0.0.0: "VER5" error. Positive pair: dependency 29.0.0.0, no VER5.
- T7 (neg) base 29.1.0.0, current 29.0.0.0 (repoVersion 29.0): "VER6" error.
- T8 base 29.0.0.0, current 29.1.0.0, repoVersion 29.1: no errors and one "VER7" warning. Paired negative: base equals current, no VER7.
- T9 Numeric compare: base 29.9.0.0, current 29.10.0.0: no VER6.
- T10 (neg) base text "not json": no errors, a warning starting "VER6 skipped".
- T11 Base None, valid fixture: neither VER6 nor VER7.

## Assumptions
- The issue's "4.0.0.0" is only a format example; the app stays 29.0.0.0 and its Major matches `application` 29.0.0.0.
- "Automated versioning" is met by AL-Go stamping Build and Revision on every CI/CD run plus workflow-driven Major.Minor bumps; no custom stamping script.
- The test app's own version (1.0.x) does not matter for releases (never submitted to AppSource); only its dependency minimum is checked (VER5).
- `.AL-Go/settings.json` edits are not on the stop list (FR-048 edited it the same way).
- The bump PR from Create release / Increment Version Number counts as the user's own change to `app.json`: the user runs the workflow and merges. Agents never edit `app.json`.
- `app.json` and `CLAUDE.md` agree (29.0.0.0, runtime 18.0, range 50100–50149).

## Risks
- AL-Go semantics come from release notes and memory, not Learn; step 0 is a hard gate with fixed fallbacks and the reviewer checks the findings are recorded.
- PRs opened by workflows with GITHUB_TOKEN do not trigger other workflows; the bump PR may show no checks. Workaround: close and reopen. `useGhTokenWorkflow` needs a secret (stop list), documented only.
- Run-number resets if `CICD.yaml` is renamed or recreated; Build numbers go down. Never rename it; otherwise set `runNumberOffset`.
- Create release with `latest` right after the artifact-name change: run the first release only after a green CI/CD run on main with 29.0 artifacts, or pass an explicit `buildVersion`.
- VER6 guards only PR changes; acceptable since `main` is protected.
- Local python3 may be 3.9: no PEP 604 or `match`.
- AppSource: Partner Center rejects a re-upload of the same version with different content; strategy 0 gives every CI run a unique Build. No separate AppSource validation ran.
- Not verified until push: Repo checks result in CI and new artifact names.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/app-faq-update
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-app-identity
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-hotfixing-appsource-app
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/version-numbers
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/al-go/algo-overview
- Local: `.github/RELEASENOTES.copy.md` lines 616, 710, 1418–1422; `docs/plans/FR-048-automated-build-pipeline.md`; `docs/plans/FR-044-data-upgrade-support.md`; `.github/workflows/CreateRelease.yaml`; `.github/workflows/IncrementVersionNumber.yaml`; `.github/scripts/repo_checks.py`; `.github/scripts/coverage_check.py`
