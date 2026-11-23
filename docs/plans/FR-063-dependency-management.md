# FR-063 Dependency Management — Plan

> Request (verbatim, GitHub issue #104): "FR-063 Dependency Management. External dependencies shall be documented and version-controlled. Requirements: Minimum BC Version; Dependency Matrix; Upgrade Notes. Related: FR-060 Developer Documentation. The test app dependencies (Library Assert, Any, Tests-TestLibraries) are listed in docs/TODO.md."
> Status: **approved**

## Request
Document the app's external dependencies and keep them under version control. Issue #104 asks for three things: the minimum Business Central version, a dependency matrix, and upgrade notes. Phase 1 adds one developer page (`docs/architecture/dependencies.md`) and a stdlib Python check (check 9 of `repo_checks.py`). The check fails a PR when `app/app.json` or `test/app.json` no longer match the documented matrix, and it warns on every dependency or platform change against `main`. Nothing in `app/`, `test/`, either `app.json`, `.AL-Go/*` or `.github/workflows/*` changes. No stop-list item is touched.
Target: AppSource

## Definition of done
- [ ] New `docs/architecture/dependencies.md` with these sections, in order: Minimum Business Central version, Manifest values (exact table format in step 1), Dependency matrix, Removed and unused dependencies, Standard modules used, Tooling dependencies, Upgrade notes, Known gaps, Related.
- [ ] New `.github/scripts/dependency_check.py` (stdlib only, Python 3.9 compatible) with rules DEP1 to DEP6 exactly as in step 2, `run(root, base_texts)`, `read_base_texts(root, base)`, and a CLI with `--base`.
- [ ] `.github/scripts/repo_checks.py` runs it as check 9 on every run. DEP6 runs only with `--base`. The docstring lists check 9.
- [ ] New `.github/scripts/test_dependency_check.py`. All tests pass locally (`python3 .github/scripts/test_dependency_check.py`), and so do the four existing Python test files.
- [ ] `python3 .github/scripts/dependency_check.py --base origin/main` prints `Dependency check: OK` with 0 warnings on this branch.
- [ ] `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-063-dependency-management` passes.
- [ ] `git diff --stat origin/main -- app/ test/ .AL-Go/ .github/workflows/ app/AppSourceCop.json` is empty.
- [ ] Docs: feature doc, help article, `CHANGELOG.md` heading `## FR-063 Dependency Management`, a `docs/TODO.md` section "FR-063 checks", and the link updates in step 9.
- [ ] CI: the Repo checks log of the PR shows the check 9 summary line and `Dependency check: OK`. Until the push, report "Not verified: CI result pending".

## Out of scope
- **Any change to `app/app.json` or `test/app.json` (stop list).** Specifically not done: aligning `platform` `1.0.0.0` to `29.0.0.0`; raising the test app's minimum dependency on the app from `1.0.0.0`; adding the "Any", "Tests-TestLibraries" or "Library - Lower Permissions" apps; filling the marketplace properties. These go under Known gaps or Later phases as user decisions.
- **AL-Go settings or workflow changes** (stop list and overwritten system files): pinning a CI build to the minimum release 29.0, or scheduling the Test Next Minor and Test Next Major workflows.
- **AL code, tests in `test/`, permission sets, translations.** No AL change, so no compile and no `.xlf` change.
- **The stale root `README.md`.** Already an FR-060 chore item.
- **The user guide.** `docs/user-guide/getting-started.md:18` already says "Business Central online, version 29.0 or later", which matches the manifests. Unchanged.

## Objects
No AL objects, so no IDs were allocated.

| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Docs page | – | Dependencies (minimum version, matrix, upgrade notes) | New | `docs/architecture/dependencies.md` |
| Python script | – | dependency_check.py | New | `.github/scripts/dependency_check.py` |
| Python tests | – | test_dependency_check.py | New | `.github/scripts/test_dependency_check.py` |
| Python script | – | repo_checks.py | Changed (check 9) | `.github/scripts/repo_checks.py` |
| Docs | – | plan, feature doc, help, CHANGELOG, TODO, index and link updates | New/Changed | `docs/...`, `CHANGELOG.md` |

## Events and standard symbols
| Symbol | Exact signature | Verified with al_symbolsearch |
|---|---|---|
| None (no AL code) | – | Not applicable. `al_symbolsearch` returned "No projects are loaded", so the owning app of each standard namespace is not attributed per namespace (see Risks). |
| In-repo `version_check.parse_version(text)` | Returns a tuple of four ints, or None. `.github/scripts/version_check.py:28` | Read in source |
| In-repo `version_check.run(root, base_app_json)` returning `(errors, warnings, summary)` | Pattern to copy for `run`/`main`. `.github/scripts/version_check.py:42,142` | Read in source |

Facts the page states, all checked in this session:
- **Manifests:**
  - `app/app.json`: `application` 29.0.0.0, `platform` 1.0.0.0, `runtime` 18.0, `target` Cloud, `dependencies` [].
  - `test/app.json`: the same application, platform, runtime and target. Dependencies:
    - Equipment Management `e6c30407-ec71-4f48-a790-70da80abc992`, minimum 1.0.0.0
    - Library Assert (Microsoft) `dd0be2ea-f733-4d65-bb34-a28f4624fb14`, 29.0.0.0
- **Learn:** runtime 18.0 ships with BC 2026 release wave 2 = 29.0.
- **Learn:** the `application` property propagates System Application, Business Foundation and Base Application.
- **Learn:** the AppSource minimum release is computed from `application`.
- **Learn:** Base Application `437dbf0e-84ff-417a-965d-ed2bb9650972` and System Application `63ca2fa4-4f03-4f2b-a480-172fef340d3f` must not be explicit dependencies (AS0085).
- **Tests-TestLibraries** `5d86850b-0d76-4eca-bd7b-951ad998e997` was removed in FR-026 (`docs/TODO.md:235`).
- **CI artifacts:** `.AL-Go/settings.json` sets no `artifact`. The Test Current, Test Next Minor and Test Next Major settings use `////latest`, `////nextminor` and `////nextmajor`. AL-Go v10.0 (`$schema` in `.AL-Go/settings.json`).

## Steps
1. **`docs/architecture/dependencies.md` (new).** Why: one page holds all three deliverables, inside the FR-060 `architecture/` folder (FR-060 decision: no new top-level folders).
   - **Opening lines.**
     - Line 1: `# Dependencies and supported versions`
     - Line 3: `> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-063-dependency-management; nothing is verified in a Business Central sandbox.`
     - Then an "In this article" list.
   - **Minimum Business Central version.**
     - The minimum is BC 2026 release wave 2 (29.0), online (`target` Cloud).
     - Derivation: `application` 29.0.0.0 is the minimum Application package, and `runtime` 18.0 needs a server with runtime 18 (Learn table). `platform` 1.0.0.0 adds no constraint (see Known gaps).
     - AppSource validates from that release up to the current production release, and the app is offered from 29.0 on.
     - Later versions are supported as long as the symbols the app uses exist. The forward checks are the manual Test Next Minor and Test Next Major workflows.
     - Consistent with `docs/user-guide/getting-started.md`.
   - **Manifest values.**
     - The table must use exactly this format, because DEP4 parses it:
       ```
       | Property | `app/app.json` | `test/app.json` | Meaning |
       |---|---|---|---|
       | `application` | `29.0.0.0` | `29.0.0.0` | Minimum Application package (System Application, Business Foundation, Base Application) |
       | `platform` | `1.0.0.0` | `1.0.0.0` | Minimum platform (System) symbols; no practical constraint, see Known gaps |
       | `runtime` | `18.0` | `18.0` | AL runtime; needs Business Central 29.0 or later |
       | `target` | `Cloud` | `Cloud` | Business Central online |
       ```
     - Add one sentence: "Repo checks check 9 (DEP4) compares this table with both app.json files; update it in the same pull request."
   - **Dependency matrix.**
     - Columns: App | Depends on | Publisher | App ID | Minimum version | Declared as | Why | Installed in customer tenants.
     - Rows:
       1. Equipment Management → Application | Microsoft | – | 29.0.0.0 | `application` property | standard tables, pages and codeunits | yes (part of Business Central).
       2. Equipment Management → no other app (`dependencies` is empty).
       3. Equipment Management Tests → Application | Microsoft | – | 29.0.0.0 | `application` | test symbols | no.
       4. Equipment Management Tests → Equipment Management | Miguel Carvalho | `e6c30407-ec71-4f48-a790-70da80abc992` | 1.0.0.0 | `dependencies` | app under test, internals through `internalsVisibleTo` | no.
       5. Equipment Management Tests → Library Assert | Microsoft | `dd0be2ea-f733-4d65-bb34-a28f4624fb14` | 29.0.0.0 | `dependencies` | `Codeunit "Library Assert"` in all 37 test codeunits | no (test framework, comes with the container).
     - Below the table, the inbound side: only the test app depends on the app. Partner extensions may depend on the public surface (link `../api/events.md`, `extension-structure.md#public-surface`).
   - **Removed and unused dependencies.** One table:
     - Tests-TestLibraries `5d86850b-0d76-4eca-bd7b-951ad998e997`: removed in FR-026. The HTTP tests failed with 401 in the AL-Go container, so the tests became table-level. Link FR-026.
     - Any (Microsoft test framework, "Any" library): never added. Tests use Locked labels with counters and `Random`.
     - Library - Lower Permissions: not added (FR-057 phase 4).
     - Library - Report Dataset: not added (FR-039 decision).
     - Note: the issue text lists Any and Tests-TestLibraries as test dependencies. The manifest has only Library Assert.
   - **Standard modules used.**
     - List the 17 namespaces from `grep -rhoE "^using (System|Microsoft)[A-Za-z.]*;" app/src | sort -u`:
       Microsoft.Foundation.Attachment, Microsoft.Foundation.NoSeries, Microsoft.HumanResources.Employee, Microsoft.Inventory.Location, Microsoft.Purchases.Vendor, System.DataAdministration, System.Device, System.Diagnostics, System.Environment, System.Environment.Configuration, System.Integration, System.Reflection, System.Security.AccessControl, System.Threading, System.Upgrade, System.Utilities, System.Visualization
     - For each, name one example standard object that `app/src` uses: open one file per namespace (from the grep with `-l`) and write the referenced Record or Codeunit name. Examples already known: Microsoft.Foundation.NoSeries is the No. Series table/codeunit, System.Upgrade is the Upgrade Tag codeunit, System.Threading is Job Queue Entry.
     - Add: "All are provided through the `application` property; which app (System Application, Business Foundation or Base Application) owns each namespace is not stated here (not verified with symbols)."
     - Link the extension points table in `README.md#extension-points-into-standard-business-central`.
   - **Tooling dependencies** (version-controlled in the repository, not installed in tenants):
     - AL-Go for GitHub v10.0 (`$schema` in `.AL-Go/settings.json`, template `AL-Go-AppSource@main`, updated by `UpdateGitHubGoSystemFiles`, a user decision)
     - the build artifact: no `artifact` in `.AL-Go/settings.json`, AL-Go default; TODO(verify) the BC version in a CI log
     - forward-check artifacts `////latest`, `////nextminor`, `////nextmajor`
     - analyzers CodeCop, UICop and AppSourceCop from the AL compiler of the build
     - Python 3.9+ standard library for `.github/scripts`
     - the VS Code AL Language extension
   - **Upgrade notes.** Five numbered subsections:
     - (a) **When Business Central gets a new version.** The app keeps working because `application` is a minimum. Before each release wave (April, October), run Test Next Minor and Test Next Major (Actions tab). Fix compiler obsolete warnings for standard symbols before they become Removed. AppSource revalidates.
     - (b) **Raising the minimum Business Central version** (stop list, user decision with a DECISIONS.md line):
       1. Raise `application` and `runtime` in both app.json files, plus `platform` if aligned.
       2. Raise the Library Assert minimum to the new application version (DEP5).
       3. FR-049 ties the Major to the BC major: set `version` to `<new major>.0.0.0` and `repoVersion` in `.AL-Go/settings.json` (VER3).
       4. Download symbols and compile both apps with no warnings.
       5. Update the Manifest values table (DEP4).
       6. In CHANGELOG release notes, state that customers on older Business Central keep the previous app version (AppSource availability follows `application`).
       7. Add upgrade code only if data changes (FR-044).
     - (c) **Adding a dependency** (stop list):
       - never add Base Application or System Application explicitly (AS0085, DEP3)
       - library apps are installed with the app, and a dependency app needs its own AppSource offer (Learn FAQ)
       - a library is updated in tenants only when the minimum version in app.json is raised
       - test-only libraries go into `test/app.json` only, and a Microsoft test library's version must not exceed `application` (DEP5)
       - add a matrix row in the same PR (DEP4)
     - (d) **Removing a dependency:** confirm that no symbol from it is used; move its row to "Removed and unused dependencies"; DEP6 warns on the PR.
     - (e) **Upgrading Equipment Management itself:** link FR-044 "How to add an upgrade step" and FR-062 (schema check); every release after 29.0.0.0 that changes data needs an upgrade step.
   - **Known gaps** (user decisions, not fixed):
     - `platform` is 1.0.0.0
     - the test app's minimum on the app is 1.0.0.0 (VER5 allows it)
     - CI builds on the AL-Go default artifact, not on the minimum release 29.0
     - forward checks are manual only
     - no `supportedLocales`
   - **Related:** FR-026, FR-044, FR-049, FR-060, FR-062, the CI/CD page; Learn URLs from References (runtime, `application` file, JSON files, technical validation, dependencies FAQ, AS0085).
2. **`.github/scripts/dependency_check.py` (new).** Why: makes "version-controlled" enforceable. The manifests are already in git; the check stops the matrix from drifting and flags every dependency change for a decision.
   - **Docstring:** purpose and the rules below, `Usage: dependency_check.py [--base <git ref>]`, "Stdlib only, Python 3.9 compatible. Errors exit 1; warnings are printed as GitHub annotations."
   - **Imports:** `sys.path.insert(0, str(Path(__file__).resolve().parent))`; `from version_check import parse_version`.
   - **Constants:**
     - `ROOT = Path(__file__).resolve().parents[2]`
     - `MATRIX_DOC = "docs/architecture/dependencies.md"`
     - `MANIFESTS = ("app/app.json", "test/app.json")`
     - `PLATFORM_PROPS = ("application", "platform", "runtime")`
     - `BASE_APPLICATION_ID = "437dbf0e-84ff-417a-965d-ed2bb9650972"`
     - `SYSTEM_APPLICATION_ID = "63ca2fa4-4f03-4f2b-a480-172fef340d3f"`
     - `ADVICE = "Changes to app.json are a stop-list decision (CLAUDE.md): log it in DECISIONS.md and update the matrix and upgrade notes in docs/architecture/dependencies.md."`
   - **Helper `load_manifest(root, rel)`:** returns `(data or None, exists)`. Read with `utf-8-sig`. Invalid JSON or a non-dict gives None.
   - **Helper `declared(manifest)`:** returns a dict of lowercase id → item, built from dict items of `manifest.get("dependencies", [])` that have a string `id`.
   - **`run(root=ROOT, base_texts=None)`** returns `(errors, warnings, summary)`:
     - **DEP1 (error).** `app/app.json` missing or invalid: "DEP1 app/app.json is missing or not a JSON object.", and return at once. For each existing manifest whose `application` or `runtime` is missing or not a non-empty string: "DEP1 <rel> has no \"<prop>\"." An invalid `test/app.json` gives DEP1 too. If `test/app.json` does not exist, add the summary line "test/app.json not found: DEP2 and DEP5 skipped."
     - **DEP2 (error).** For `application` and `runtime`: test value ≠ app value gives "DEP2 test/app.json <prop> is \"X\" but app/app.json has \"Y\". Build the test app against the same Business Central version."
     - **DEP3 (error).** Any manifest whose declared ids include BASE_APPLICATION_ID or SYSTEM_APPLICATION_ID: "DEP3 <rel> lists <name> in dependencies. Use the \"application\" property instead (AppSourceCop AS0085)."
     - **DEP4 (error).**
       - Doc missing: "DEP4 docs/architecture/dependencies.md is missing. It holds the dependency matrix (FR-063)."
       - Otherwise, for each prop in PLATFORM_PROPS: app_value = `str(app.get(prop))` if present, else `none`; test_value likewise (`none` when there is no test manifest or no prop). Check `re.search(r"^\|\s*`" + re.escape(prop) + r"`\s*\|\s*`" + re.escape(app_value) + r"`\s*\|\s*`" + re.escape(test_value) + r"`\s*\|", text, re.M)`. When it fails: "DEP4 docs/architecture/dependencies.md has no manifest-values row | `<prop>` | `<app_value>` | `<test_value>` |. Update the 'Manifest values' table."
       - For every declared id in both manifests whose lowercase id is not in `text.lower()`: "DEP4 dependency <name> (<id>) from <rel> is not in the dependency matrix in docs/architecture/dependencies.md."
     - **DEP5 (error).** Only when `test/app.json` is valid. For each test dependency with `publisher == "Microsoft"`:
       - `parse_version(version)` is None: "DEP5 test/app.json dependency <name> has a version that is not Major.Minor.Build.Revision."
       - otherwise, if `application` parses and the version > application: "DEP5 test/app.json dependency <name> requires <v>, which is above the test app's application <a>. It would not resolve on the minimum Business Central version."
     - **DEP6 (warning).** Only when `base_texts` is not None. For each rel in MANIFESTS:
       - base text None or not a JSON object: add summary "DEP6 skipped for <rel>: not readable on the base ref."
       - otherwise, a warning for each change:
         - each changed PLATFORM_PROPS value: "DEP6 <rel> <prop> changed from \"X\" to \"Y\". " + ADVICE
         - each dependency id added, removed or with a changed `version`: "DEP6 <rel> dependency <name> (<id>) added|removed|version changed from X to Y. " + ADVICE
     - **Summary line:** `Dependencies: app/app.json declares <n>, test/app.json declares <m>; minimum Business Central application <application>, runtime <runtime>`
   - **`read_base_texts(root, base)`:** returns a dict rel → stdout of `git show <base>:<rel>`, or None on a non-zero return. Use `subprocess.run(..., cwd=root, capture_output=True, text=True, check=False)`.
   - **`main()`:** argparse `--base`. Print the summary, `::warning::` and `::error::` lines; exit 1 on errors, else print `Dependency check: OK`. Same shape as `version_check.main`.
3. **`.github/scripts/repo_checks.py`.** Why: `RepoChecks.yaml` already runs it with `--base`, so no workflow edit is needed.
   - Add `import dependency_check  # noqa: E402` in alphabetical order (before `import schema_check`).
   - Add the docstring line `  9. Dependency matrix (FR-063): see dependency_check.py; DEP6 needs --base.`
   - Add `def check_dependencies(base)`: `base_texts = dependency_check.read_base_texts(ROOT, base) if base else None`; run, print the summary, pass the results to `warning()` and `error()`; print `Dependency check: OK` when there are no errors.
   - In `main()`, call `check_dependencies(args.base)` right after `check_language_files()`.
4. **`.github/scripts/test_dependency_check.py` (new).**
   - unittest, same pattern as `test_version_check.py`.
   - A `Fixture(app=..., test=..., doc=...)` class writes `app/app.json`, optionally `test/app.json`, and optionally `docs/architecture/dependencies.md` into a temp root.
   - A helper `matrix_doc(app, test, ids)` builds a valid doc from the manifests.
   - Default manifests mirror the real ones, with fake GUIDs plus the Library Assert id.
   - Cases are listed under Tests.
5. **Local verification.** Run in order, after steps 1 to 4 and 6 to 9:
   - `python3 .github/scripts/test_dependency_check.py`
   - `python3 .github/scripts/test_version_check.py`, `test_coverage_check.py`, `test_xlf_sync.py`, `test_schema_check.py` (paste all result lines into the handoff)
   - `python3 .github/scripts/dependency_check.py --base origin/main` (expect OK, 0 warnings)
   - `git fetch origin && python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-063-dependency-management`
6. **`docs/features/FR-063-dependency-management.md` (new, al-docs).** Contents: purpose and the deliverable-to-section map (Minimum BC Version, Dependency Matrix and Upgrade Notes, each mapped to its anchor in `dependencies.md`); the DEP1 to DEP6 rule table; verification status (no AL change, no AL tests, the Python results, CI pending, "No separate AppSource validation ran"); the conflicts found (the issue lists Any and Tests-TestLibraries but the manifest has only Library Assert; `platform` 1.0.0.0; the test minimum is 1.0.0.0); maintaining the page; open items and later phases; Related.
7. **`docs/help/FR-063-dependency-management.md` (new, al-docs).** Contributor-facing: where the matrix is; what to do before you add a dependency or raise the BC version (link upgrade notes; stop list); one row per DEP rule: what fails and how to fix it; how to run the check locally.
8. **`CHANGELOG.md`.** New top section `## FR-063 Dependency Management`:
   - Added: the page and check 9
   - Changed: the doc links
   - Fixed: None.
   - Obsolete: None.
   - Release notes: none for the app; contributors get a documented dependency matrix, the minimum Business Central version (29.0) and upgrade notes, with a check that keeps them in sync.
   - Note: no `app/` or `app.json` change, version stays 29.0.0.0, CI pending, Python tests not run in CI, no separate AppSource validation ran.
9. **Link updates (al-docs, minimal edits):**
   - `docs/README.md`: in the `architecture/` row add `[dependencies and supported versions](architecture/dependencies.md)`; add a "Where to start" bullet "To check the supported Business Central versions or add a dependency, read [dependencies](architecture/dependencies.md)."
   - `docs/architecture/README.md` line 32: change the `dependencies` cell from `none` to `none (see [Dependencies](dependencies.md))`; add the link under Related.
   - `docs/architecture/extension-structure.md` line 239: append "The dependency matrix is in [Dependencies](dependencies.md)."
   - `docs/architecture/appsource-readiness.md` line 42 evidence cell: append "; matrix in [Dependencies](dependencies.md)".
   - `docs/setup/README.md`: line 45 "eight checks" becomes "nine checks"; add item `9. **Dependency matrix (FR-063):** dependency_check.py. DEP6 (dependency changes against main) runs only with --base.`; Prerequisites line 19: append "Supported versions: [Dependencies](../architecture/dependencies.md)."
   - `docs/setup/ci-cd.md`: mermaid add `RC --> R9[9 Dependency matrix]`; after line 114 add the bullet "**Dependency checks** DEP1 to DEP6 run in Repo checks (check 9, FR-063). DEP6 warns on pull requests when a dependency, `application`, `platform` or `runtime` changes. See [Dependencies](../architecture/dependencies.md)."; Related: add FR-063.
   - `docs/release-notes/README.md` Versioning policy: add the bullet "Raising the minimum Business Central version follows the [upgrade notes](../architecture/dependencies.md#upgrade-notes)."
   - `docs/TODO.md`: new section `## FR-063 checks (no AL change; Repo checks result pending)` with: CI-1 the Repo checks log shows the check 9 summary and `Dependency check: OK`; TODO(verify) the BC version of the CI build artifact from a CI log; user decisions (stop list): `platform` to 29.0.0.0 in both manifests, test minimum on the app to 29.0.0.0, a CI build pinned to the minimum release, scheduled Next Minor and Next Major runs; run Test Next Major before the next release wave.

## Tests
Python unittest in `test_dependency_check.py`. No AL tests: there is no AL change. Existing AL tests are not affected. Existing Python tests are not affected, but all must be re-run.
- [SCENARIO] T0 real repo [GIVEN] the repository after step 1 [WHEN] `run(ROOT)` [THEN] no errors and no warnings.
- [SCENARIO] T1 consistent fixture [GIVEN] matching manifests and doc [WHEN] run [THEN] no errors, and the summary names application and runtime.
- [SCENARIO] T2 DEP1 negative [GIVEN] invalid JSON in app/app.json [THEN] only a DEP1 error. [GIVEN] test/app.json without `runtime` [THEN] a DEP1 error naming test/app.json.
- [SCENARIO] T3 DEP2 [GIVEN] test runtime `17.0` and app `18.0` [THEN] a DEP2 error. Positive: same values, no DEP2.
- [SCENARIO] T4 DEP3 [GIVEN] the System Application id in test dependencies [THEN] a DEP3 error. Positive: Library Assert only, no DEP3.
- [SCENARIO] T5 DEP4 [GIVEN] no doc [THEN] a DEP4 "missing" error. [GIVEN] the doc lacks a dependency id [THEN] a DEP4 error naming that id. [GIVEN] the doc row has the old application `28.0.0.0` [THEN] a DEP4 row error. Positive: an uppercase id in the manifest still matches the lowercase doc.
- [SCENARIO] T6 DEP5 [GIVEN] Library Assert `30.0.0.0` with application `29.0.0.0` [THEN] a DEP5 error. [GIVEN] version `29.0` [THEN] a DEP5 format error. Positive: `29.0.0.0` gives none, and a non-Microsoft dependency above application gives none.
- [SCENARIO] T7 DEP6 [GIVEN] a base with runtime `17.0` [THEN] exactly one DEP6 warning and no error. [GIVEN] a base without Library Assert [THEN] an "added" warning. [GIVEN] a base with another version [THEN] a "version changed" warning. Positive: identical base gives no warning; base text None gives the summary skip line and no warning.
- [SCENARIO] T8 no test app [GIVEN] no test/app.json and doc test cells `none` [THEN] no errors, and the summary says DEP2 and DEP5 were skipped.
- [SCENARIO] T9 read_base_texts [GIVEN] a temp git repo with a committed app/app.json [WHEN] `read_base_texts(root, "HEAD")` [THEN] it returns the text for app/app.json and None for test/app.json. An unknown ref gives None for both.

## Assumptions
- Assumed the issue's reference to "Any" and "Tests-TestLibraries" as test dependencies is out of date. FR-026 removed Tests-TestLibraries, Any was never added, and no test code uses either. The matrix records the real state plus a "Removed and unused" table, because adding them would change `test/app.json` (stop list) with no test that needs them.
- Assumed "Minimum BC Version" means documenting the current minimum (29.0, from `application` and `runtime`), not changing it. Changing it is an app.json change (stop list).
- Assumed "version-controlled" means the manifests in git plus a check that keeps the documented matrix equal to them and flags each change.
- Assumed the page belongs in `docs/architecture/` (FR-060 layout) rather than a new `docs/dependencies/` folder.
- Assumed DEP4's exact-row table format is acceptable. The error message prints the expected row, so a contributor can fix it without reading the script.

## DECISIONS
- FR-063 | Chose one page `docs/architecture/dependencies.md` with all three deliverables over three separate pages or a new folder, consistent with the FR-060 folder layout | Reversible: yes
- FR-063 | Chose docs plus a stdlib check 9 (`dependency_check.py`, DEP1–DEP6) over docs only, so the matrix cannot drift from `app.json` and every dependency change is flagged | Reversible: yes
- FR-063 | Chose DEP6 (dependency or platform change against `main`) as a warning over an error, because a user-approved stop-list change must still merge; DEP4 already forces the doc update | Reversible: yes
- FR-063 | Chose to document, not fix, `platform` 1.0.0.0 and the test app's minimum 1.0.0.0 on the app, because both are `app.json` changes (stop list); listed as user decisions | Reversible: yes
- FR-063 | Chose not to add Any, Tests-TestLibraries or Library - Lower Permissions to `test/app.json`, because no test needs them and it is a stop-list change | Reversible: yes
- FR-063 | Chose not to attribute each standard namespace to its owning Microsoft app, because the AL MCP had no project loaded to verify symbols; the page says all come through `application` | Reversible: yes
- FR-063 | Chose not to pin a CI build to the minimum release 29.0 (AL-Go settings change, user decision) and recorded it as a known gap | Reversible: yes

## Risks
- **CI builds on the AL-Go default artifact, not on 29.0.** The documented minimum is a manifest fact; it is not proven by a build on 29.0. The page marks this TODO(verify) and Known gaps. The reviewer should confirm the page does not claim tested support for 29.0.
- **The DEP4 table format is brittle.** A reformatted table fails the check. Mitigation: the error prints the exact expected row, and T5 covers it.
- **DEP6 is only a warning.** A dependency change could merge without a DECISIONS.md line. The reviewer treats a DEP6 warning without a matching decision as a BLOCKER.
- **Python tests do not run in CI** (workflow edits are on the stop list), same as the existing script tests. The developer must paste the local results.
- **Symbols not verified.** `al_symbolsearch` was unavailable ("No projects are loaded"). No AL symbol is used, but the namespace-to-object examples on the page come from reading `app/src`, not from symbols.
- **Learn facts may change over time** (runtime table, validation rules). The page cites the URLs and its "Applies to" line.
- Repo checks being a required status check is still TODO(verify) (FR-048).
- No separate AppSource validation ran.

## Later phases
- Phase 2 (user decisions, stop list): set `platform` to `29.0.0.0` in both manifests, and raise the test app's minimum on the app to `29.0.0.0`. DEP4/DEP6 will flag it, so update the table in the same PR.
- Phase 3 (user decision, AL-Go settings): add a CI build pinned to the minimum release, and scheduled Next Minor and Next Major runs.
- Phase 4: after the first release, add a per-release "Upgrade notes" entry (minimum BC version, dependency changes, upgrade steps) as part of the FR-049 release procedure.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-choosing-runtime — runtime 18.0 ships with BC 2026 release wave 2 (29.0); an extension needs a server with the same or later runtime.
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-application-app-file — `application` property; the Application app propagates System Application, Business Foundation and Base Application; Marketplace apps must use it (AS0100, AS0085).
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-json-files#appjson-file — `application`, `platform` and `dependencies` semantics; a dependency version is a minimum.
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission#against-which-releases-of-business-central-is-your-submission-validated — the AppSource minimum release is computed from `application`.
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0085 — no explicit Base or System Application dependencies (basis for DEP3).
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/app-faq-dependencies-libraries — library and dependency apps are installed automatically; libraries are updated only when the minimum version is raised.
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/upgrade/upgrade-to-microsoft-base-app-v19 — Base Application and System Application app IDs used by DEP3.
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-application#testing-best-practices — the Any library is part of the Microsoft test framework.
