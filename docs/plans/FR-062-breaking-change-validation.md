# FR-062 Breaking Change Validation — Plan

> Request (verbatim, GitHub issue #103): "FR-062 Breaking Change Validation. The solution shall prevent incompatible schema changes. Examples: Field Removal Validation; Enum Extension Strategy; Upgrade Processing. Related: FR-044 Data Upgrade Support, FR-061 (AppSourceCop breaking-change rules), FR-048 pipeline."
> Status: **approved**

## Request
Stop pull requests that make incompatible schema changes to the main app. That means removing or renaming objects, fields, keys or enum values, changing a field type, breaking enum extensibility, or obsoleting in the wrong order. Also document the enum extension strategy and the field-retirement and upgrade lifecycle. Phase 1 needs no stop-list change. It is a stdlib Python schema-compatibility check (check 8 of `repo_checks.py`) that compares the PR's `app/` AL source with the base branch. AppSourceCop's own binary baseline comparison stays phase 2, because it needs a first release.
Target: AppSource

Why not the AppSourceCop baseline now: Learn (AS0003) says the baseline is a previous `.app` version named by `version` in `AppSourceCop.json`, and no release exists yet (FR-049 deferred it). Editing `AppSourceCop.json` is on the stop list. The FR-049 gate 0a, checked against AL-Go v10.0, found that AL-Go passes the previous release apps to the AppSourceCop breaking-change check by itself. So once the user runs **Create release**, the Pull Request Build gets the binary baseline with no file edit. That is a user decision (phase 2), and nothing in phase 1 depends on it.

## Definition of done
- [ ] New `.github/scripts/schema_check.py` (stdlib only, Python 3.9 compatible). It implements rules SCH00 to SCH14 exactly as in step 1, has `run(root, base_files, exceptions_path)` and a CLI `--base <ref>`.
- [ ] `.github/scripts/repo_checks.py` calls it as check 8, only when `--base` is given. The docstring lists check 8.
- [ ] New `.github/schema/accepted-breaking-changes.json` with exactly `{"accepted": []}`.
- [ ] New `.github/scripts/test_schema_check.py`. All tests pass when run locally with `python3 .github/scripts/test_schema_check.py` (same pattern as `test_version_check.py`).
- [ ] `python3 .github/scripts/schema_check.py --base origin/main` on this branch prints `Schema check: OK` and 0 findings.
- [ ] A history run (step 6) against an older `main` commit gives 0 errors. Any error is explained in the handoff as a real past change or a parser defect, and parser defects are fixed.
- [ ] `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-062-breaking-change-validation` passes.
- [ ] No change to any `.al` file, `app.json`, `test/app.json`, `AppSourceCop.json`, `.AL-Go/*`, the ruleset or any `.github/workflows/*` file.
- [ ] Docs: this plan, plus `docs/features/FR-062-breaking-change-validation.md`, `docs/help/FR-062-breaking-change-validation.md`, `CHANGELOG.md` heading `## FR-062 Breaking Change Validation`, a `docs/TODO.md` section "FR-062 checks", and updates to `docs/setup/ci-cd.md`, `docs/setup/README.md`, `docs/architecture/appsource-readiness.md` (line 44) and `docs/features/FR-044-data-upgrade-support.md` (link from step 6 of "How to add an upgrade step").
- [ ] CI: the "Repo checks" log of the PR shows the check 8 summary line and `Schema check: OK`. Until the push: "Not verified: CI result pending".

## Out of scope
- AppSourceCop baseline (`version`, `baselinePackageCachePath`, `obsoleteTagVersion` in `app/AppSourceCop.json`) and the first GitHub release. Phase 2, user decision, stop list.
- Turning on AS0072 to AS0076 in the ruleset (stop list).
- The test app (`test/`). It is never installed in customer tenants.
- Public procedure and event signature changes (AS0018 and others), page control and API field contracts, report dataset columns. AppSourceCop covers these once the baseline exists (phase 2). A static check of API page fields is phase 4.
- `interface`, `profile` and `controladdin` objects (no numeric ID). Moving tables or fields between apps.
- Running the Python unit tests in CI (workflow edits are on the stop list).
- Any AL change. An audit found that every `case` over a status enum already has an `else` branch (`EQMEquipment.Table.al:839`, `EQMMaintenanceRecord.Table.al:275`, `EQMEquipmentRequest.Table.al:314`).

## Objects
No AL objects, so no IDs allocated.

| Type | Name | New/Changed | File |
|---|---|---|---|
| Python script | schema_check.py | New | `.github/scripts/schema_check.py` |
| Python tests | test_schema_check.py | New | `.github/scripts/test_schema_check.py` |
| Python script | repo_checks.py | Changed (check 8) | `.github/scripts/repo_checks.py` |
| JSON | accepted-breaking-changes.json | New | `.github/schema/accepted-breaking-changes.json` |
| Docs | plan, feature doc, help, changelog, TODO, ci-cd, setup README, appsource-readiness, FR-044 feature doc | New/Changed | `docs/...`, `CHANGELOG.md` |

## Events and standard symbols
| Symbol | Exact signature |
|---|---|
| None | No AL code, events or standard symbols are used |
| In-repo `coverage_check.strip_comments(text)` / `strip_strings(text)` / `unquote(name)` | `.github/scripts/coverage_check.py` lines 80, 85, 90. They keep line structure and remove `//` comments (strip_strings also empties `'...'` strings). They do not handle `/* */`. |
| In-repo `version_check.run(root, base_app_json)` returning `(errors, warnings, summary)` | Pattern to copy |

## Steps
1. **`.github/scripts/schema_check.py` (new).** Why: a static baseline-vs-head comparison is the only gate possible without a release or a stop-list edit. Content:
   - Module docstring: purpose, the rule table below, `Usage: schema_check.py [--base <git ref>]`, "Stdlib only, Python 3.9 compatible", "Baseline = AL source of app/ on the base ref (main), not a released .app; see FR-062 phase 2".
   - Import from coverage_check: `sys.path.insert(0, str(Path(__file__).resolve().parent))`, then `from coverage_check import strip_comments, strip_strings, unquote`.
   - Constants:
     - `ROOT = Path(__file__).resolve().parents[2]`
     - `APP_FOLDER = "app"`
     - `EXCEPTIONS_FILE = Path(".github") / "schema" / "accepted-breaking-changes.json"`
     - `DOC = "docs/features/FR-062-breaking-change-validation.md"`
     - `HEADER_RE = r'^\s*(table|tableextension|page|pageextension|codeunit|enum|enumextension|permissionset|permissionsetextension|report|reportextension|query|xmlport)\s+(\d+)\s+("[^"]+"|[\w.]+)(?:\s+extends\s+("[^"]+"|[\w.]+))?'` (re.I)
     - `NAMESPACE_RE = r'^\s*namespace\s+([\w.]+)\s*;'` (re.I | re.M)
     - `FIELD_RE = r'^\s*field\(\s*(\d+)\s*;\s*("[^"]+"|\w+)\s*;\s*(.+)\)\s*(\{.*)?$'` (re.I)
     - `KEY_RE = r'^\s*key\(\s*("[^"]+"|\w+)\s*;\s*(.+?)\)\s*(\{.*)?$'` (re.I)
     - `VALUE_RE = r'^\s*value\(\s*(\d+)\s*;\s*("[^"]+"|\w+)\s*\)'` (re.I)
     - `PROP_RE = r'^\s*(\w+)\s*=\s*(.*?)\s*;\s*$'` (does not match `:=` code lines)
     - `TAG_RE = r"^'\d+\.\d+'$"`
   - `read_head_files(root) -> dict[str, str]`: every `root/app/**/*.al`, key = POSIX path relative to root, read as `utf-8-sig`.
   - `read_base_files(root, base) -> dict or None`: `git ls-tree -r --name-only <base> -- app`, keep only `.al` paths, then `git show <base>:<path>` for each. Any non-zero return code gives `None`. Use `subprocess.run(..., cwd=root, capture_output=True, text=True, check=False)`.
   - `parse_sources(files) -> dict[(kind lower, id int)] -> obj`:
     - For each file: remove `/* ... */` and keep the newlines: `re.sub(r'/\*.*?\*/', lambda m: "\n" * m.group(0).count("\n"), text, flags=re.S)`.
     - Then `lines_c = strip_comments(t).split("\n")` and `lines_s = strip_strings(t).split("\n")`. Both lists have the same length.
     - `depth_before[i]` = running sum of `lines_s[k].count("{") - lines_s[k].count("}")` for k < i.
     - Generic helper `block(i) -> (end_line, props: dict lower-name -> raw value)`: start at header line i with `d0 = depth_before[i]`; walk j = i, i+1, ...; `opened` becomes True when the depth after a line is > d0; stop at the first j with `opened` and depth-after(j) == d0, or at EOF; props = `PROP_RE` matches on `lines_c[j]` for j > i with `depth_before[j] == d0 + 1` (or on the header line itself when it contains the whole `{ ... }`).
     - Object = `HEADER_RE` match on `lines_s`, with obj dict: `kind`, `id`, `name` (unquoted), `extends` (unquoted or None); `namespace` (first `NAMESPACE_RE` in the file or ""); `path`, `props`; `fields` {id: {name, type, props}}, `keys` [list in order: {name, fields: tuple of unquoted lowercased names, props}], `values` {ordinal: {name, props}}.
     - Members: scan only lines inside the object block. `FIELD_RE` only for kind in (table, tableextension). `KEY_RE` for the same kinds. `VALUE_RE` for (enum, enumextension). Each member's props come from `block(line)`.
     - Type normalisation: `re.sub(r"\s+", " ", t).strip().lower()`.
     - A duplicate (kind, id) keeps the first one (check 1 already reports duplicates).
     - Never raise on malformed input: an unclosed block ends at EOF.
   - Helpers: `state(props)`: lowercase `obsoletestate` or `"no"`. `extensible(props)`: `props.get("extensible","false").lower() == "true"`. `length_type(t)`: `re.fullmatch(r"(text|code)\[(\d+)\]", t)` gives (kind, int) or None.
   - `compare(base, head) -> list of findings`. Each finding is `(rule, severity "error"|"warning", key, message, path)`. `key` = `"<RULE> <kind> <id>"` plus optionally `" field <id>"`, `" key <name>"` or `" value <ordinal>"`. `message` starts with the rule ID, names object kind, ID and quoted name, member and what to do, and ends with `See <DOC>. [key: <key>]`.
     - **SCH01** error: object (kind, id) is in base and not in head. Exception: kind is not table/tableextension and the base object state is `pending`. Then it is a warning "removed after Pending".
     - **SCH02** error: same (kind, id) with a different name (exact, case-sensitive compare), or a different `extends` target.
     - **SCH03** error: namespace changed.
     - **SCH04** error: a base field ID is missing in head, whatever its ObsoleteState (AS0002).
     - **SCH05** error: field name changed (exact compare; AS0005 includes casing).
     - **SCH06** field type and FieldClass: error when the normalised type differs, except Text/Code of the same kind with a larger length; error when the length decreased (AS0080); error when `fieldclass` differs (default `normal`); warning when Text/Code length increased (AS0086).
     - **SCH07** error: table `tabletype` changed (default `normal`).
     - **SCH08** error: the first key (primary key) of a table differs in name or field tuple, or is gone; a base secondary key name is missing in head, unless its base state is `pending` (then warning); a secondary key with the same name has a different field tuple (AS0009/AS0010).
     - **SCH09** error: a base enum or enumextension ordinal is missing in head, unless the base enum object is `pending` (AS0083, then warning). Also error when the same ordinal has a different name (AS0082).
     - **SCH10** enums only: error when base is extensible and head is not (AS0050); warning when base is not extensible and head is ("one-way: cannot be undone; code over it needs `case ... else`").
     - **SCH11** error on an invalid obsolete transition for objects, fields, keys and values: base `removed` and head anything else; base `no` (or element new) and head `removed`, which skips Pending.
     - **SCH12** error: the element's head state is `pending`/`removed`, and the element is new or its state differs from base, but `obsoletereason` is missing or `''`, or `obsoletetag` is missing or does not match `TAG_RE`.
     - **SCH13** warning on table or field state changes: `no` to `pending`: "move data in an upgrade step in "EQM Upgrade Mgt." while Pending (FR-044, How to add an upgrade step); AL cannot read it once Removed"; `pending` to `removed`: "confirm the data was moved in an earlier release".
   - `load_exceptions(root, path) -> (entries, errors)`: a missing file means no entries. Invalid JSON, or a missing `accepted` list, gives **SCH14** error. Each entry needs non-empty string `key`, `reason` and `decision` (a DECISIONS.md line or issue link). Otherwise SCH14 error naming the entry index.
   - `run(root=ROOT, base_files=None, exceptions_path=None) -> (errors, warnings, summary)`: `base_files is None`: summary `Schema check: skipped (no base ref or base not readable)`, plus the warning `SCH00 schema check skipped: base AL source could not be read.` (when run without `--base` at all, the CLI prints only the summary). Otherwise parse both, compare, and apply exceptions. An error finding whose key equals an entry key becomes the warning `"<message> Accepted: <reason> (<decision>)."`. An entry that matches no finding gives the warning `SCH14 stale entry <key>: remove it from .github/schema/accepted-breaking-changes.json.` Summary line: `Schema check: base <n> objects, head <m> objects, <e> breaking, <w> warnings, <a> accepted`.
   - `main()`: argparse `--base`. Print summary, then `::warning::`/`::error::` lines, exit 1 on errors, else print `Schema check: OK`. Same pattern as `version_check.main`.
2. **`.github/schema/accepted-breaking-changes.json` (new):** exactly `{"accepted": []}` plus a trailing newline. Why: a pre-release break the user has approved through the stop list must still be mergeable without a workflow or ruleset edit. Each use is recorded with its decision.
3. **`.github/scripts/repo_checks.py`:** add `import schema_check  # noqa: E402` after `import coverage_check`; add docstring line `  8. Schema compatibility (FR-062): with --base, see schema_check.py.`; add `def check_schema(base)`: call `schema_check.run(ROOT, schema_check.read_base_files(ROOT, base))`, print the summary, then pass warnings and errors to the existing `warning()`/`error()`; when there are no errors, print `Schema check: OK`. In `main()`, call `check_schema(args.base)` inside the existing `if args.base:` block, after `check_translations(files)`. Why: `RepoChecks.yaml` already passes `--base "origin/$BASE_REF"` with `fetch-depth: 0`, so no workflow edit is needed.
4. **`.github/scripts/test_schema_check.py` (new):** unittest, `Fixture` class writing head `.al` files under a temp `root/app/src/` and passing base as a dict. Use AL text built from small helper functions: `table(id, name, fields, keys, props)` and `enum(id, name, values, extensible)`. Run it and paste the result line into the handoff.
5. **Local verification:** `python3 .github/scripts/schema_check.py --base origin/main` gives OK with 0 findings. `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-062-breaking-change-validation` passes (needs docs from step 7 first, so run it last).
6. **History run (parser sanity):** run `python3 .github/scripts/schema_check.py --base <sha>`, where `<sha>` = `git log --merges --grep "FR-044" -n 1 --format=%h main` (fall back to `HEAD~30`). Expected: 0 errors, because FR-044 to FR-060 were additive. Warnings are fine. Tabulate any finding. A finding caused by parsing is a defect: fix it and add a regression test. A finding caused by a real past change is reported, not fixed.
7. **Docs (al-docs):**
   - `docs/features/FR-062-breaking-change-validation.md`: the rule table SCH00 to SCH14 with AppSourceCop equivalents (AS0001, AS0002, AS0004, AS0005, AS0006, AS0007, AS0009, AS0010, AS0050, AS0080, AS0082, AS0083, AS0086, AS0090); **Field removal lifecycle** (Pending + ObsoleteReason + ObsoleteTag `'Major.Minor'`, then the data-move upgrade step while Pending (FR-044 checklist), then Removed in a later release; never delete the field from source); **Enum extension strategy** (extensible enums today: 50100 "EQM Equipment Status", 50102 "EQM Maintenance Type", 50108 "EQM Attachment Category"; all others `Extensible = false`; never delete or renumber values; never go extensible to non-extensible; false to true is one-way; every `case` over an extensible enum needs `else`; adding values to a non-extensible enum is allowed; enumextension 50100 on EventCategory follows the same value rules); **Upgrade processing** (link to FR-044); **Accepted breaking changes** (file format, needs a user decision and a DECISIONS.md line, stale entries removed in the next PR); limitations; phase 2 to 4.
   - `docs/help/FR-062-breaking-change-validation.md`: contributor-facing. What fails, how to read `[key: ...]`, how to fix (obsolete instead), how to run it locally.
   - `CHANGELOG.md`: `## FR-062 Breaking Change Validation` (version stays 29.0.0.0, no AL change).
   - `docs/TODO.md`: new "FR-062 checks" section. CI-1: Repo checks log shows the check 8 summary. Phase 2: first release, then the AppSourceCop baseline in Pull Request Build.
   - `docs/setup/ci-cd.md`: add a "Schema checks SCH01 to SCH14 run in Repo checks (check 8)" bullet next to line 112.
   - `docs/setup/README.md`: local command near line 42.
   - `docs/architecture/appsource-readiness.md` line 44: replace "FR-062 (breaking change validation) is not built" with the static check plus "binary baseline after first release".
   - `docs/features/FR-044-data-upgrade-support.md`: step 6 of "How to add an upgrade step" links the FR-062 lifecycle.

## Tests
Python unittest in `test_schema_check.py`. Data comes from helper builders, not from repo files, except T0.
- T0 Real repo is consistent with itself: base = `read_head_files(ROOT)`; run; no errors, no warnings.
- T1 Additive change passes (field, key, enum value added).
- T2/T2n SCH01: table removed gives error with key `SCH01 table 50100`; codeunit removed after base Pending gives warning only.
- T3 SCH01 for a non-Pending codeunit removal gives an error.
- T4/T4n SCH02: renamed table errors; same name none; changed `extends` on tableextension errors.
- T5 SCH03: namespace changed errors; unchanged none.
- T6/T6n SCH04: removed field errors; field kept with `ObsoleteState = Removed` (base Pending) gives no SCH04.
- T7 SCH04 still errors when the removed field was already Removed in base.
- T8 SCH05: case-only rename (`"No."` to `"NO."`) errors.
- T9 SCH06: `Integer` to `Text[30]` errors; `Code[20]` to `Code[10]` errors; `Code[20]` to `Text[20]` errors; `Text[50]` to `Text[100]` warning only; `FieldClass = FlowField` added errors.
- T10 SCH07: `TableType = Temporary` added errors.
- T11 SCH08: PK fields changed errors; secondary key removed errors; secondary key fields reordered errors; secondary key removed after base Pending warning only.
- T12 SCH09: value ordinal 3 removed errors; value 3 renamed errors; value removed while base enum was Pending warning only; enumextension value removed errors.
- T13 SCH10: `Extensible = true` to property deleted errors; false to true warns.
- T14 SCH11: field No to Removed errors; Removed to Pending errors; Pending to Removed no SCH11; Pending to No no error.
- T15 SCH12: new Pending without ObsoleteTag errors; tag `'v2'` errors; reason `''` errors; reason + tag `'29.1'` no SCH12.
- T16 SCH13: field No to Pending (complete metadata) gives exactly one warning and no errors.
- T17 Exceptions: matching key with reason and decision gives no error and an "Accepted" warning; missing `decision` gives SCH14 error; entry matching nothing gives stale warning; invalid JSON gives SCH14 error.
- T18 Robustness: `// field(9; X; Integer)` and a `/* key(...) */` block create no members; a string containing `{` does not shift depth; an unclosed brace does not raise.
- T19 Object-level ObsoleteState is not taken from a field.
- T20 `run(base_files=None)` gives no errors and a "skipped" summary.
- T21 `read_base_files` on a temp git repo returns committed text; unknown ref returns None.

Existing tests likely affected: none. The developer runs all four Python test files. No AL test changes. AL compile is not needed: no AL change.

## Assumptions
- Base branch (`main`) is the baseline because no release exists. Anything merged to `main` is treated as published.
- Exact (case-sensitive) name comparison, because AS0005 counts casing changes as renames.
- Enum value deletion is allowed only when the whole enum was Pending in base (AS0083).
- Non-table objects may be deleted after a Pending state in base.
- Temporary tables get the same field rules.
- Single-line `field(...)`, `key(...)`, `value(...)` and object headers, as the whole repo is written.
- ObsoleteTag format `'Major.Minor'`.
- Check 8 runs only on pull requests (with `--base`).

## DECISIONS
- FR-062 | Chose a static Python schema check in Repo checks (base `main` vs PR head) for phase 1 over the AppSourceCop binary baseline, because the baseline needs a released `.app` and an `AppSourceCop.json` edit (stop list), and no release exists | Reversible: yes
- FR-062 | Chose check 8 inside `repo_checks.py` over a new workflow, because `RepoChecks.yaml` already passes `--base` with full history and workflow edits are on the stop list | Reversible: yes
- FR-062 | Chose an exceptions file `.github/schema/accepted-breaking-changes.json`, where every entry needs a reason and a decision reference, over no escape hatch. Without it a user-approved pre-release break could never merge into protected `main` | Reversible: yes
- FR-062 | Chose to check only the main app, not the test app, because the test app is never installed in customer tenants | Reversible: yes
- FR-062 | Chose to check schema and object identity only, and leave procedures, events, page controls and API fields to AppSourceCop in phase 2 | Reversible: yes
- FR-062 | Chose Text/Code length increase as a warning (AS0086 is a warning) and all other type changes as errors | Reversible: yes
- FR-062 | Chose to require ObsoleteReason and an `'N.N'` ObsoleteTag whenever an element becomes Pending or Removed (SCH12, error) over a warning, as CLAUDE.md requires reason and tag | Reversible: yes
- FR-062 | Chose no AL change for the enum strategy (documentation plus SCH09/SCH10), because the audit found every status `case` already has `else` | Reversible: yes

## Risks
- **Baseline is `main`, not a release.** A Pending to Removed change in two PRs between releases passes, although tenants never saw the Pending version. Mitigation: SCH13 warns, and phase 2 catches it.
- **Regex parser, not a compiler.** Multi-line headers, `#if` blocks or unusual formatting could hide or invent findings. Mitigations: T18/T19, the history run in step 6, and SCH00 skip-with-warning.
- **Exceptions file can be misused as a suppression.** The reviewer treats an entry without a matching user decision as a BLOCKER. CLAUDE.md does not mention the file yet; a standing note there is a user edit.
- **Python unit tests are not run in CI**, same as the existing script tests. The developer must paste the local result.
- **Repo checks may not be a required status check** (FR-048 TODO(verify)). The owner should confirm branch protection.
- **AL-Go applying the previous release to AppSourceCop is from the FR-049 gate (AL-Go v10.0 sources), not from Learn.** Re-verify in phase 2.
- No separate AppSource validation ran.

## Later phases
- Phase 2: user runs AL-Go **Create release**. Then AppSourceCop in Pull Request Build compares against it. After that, decide on `obsoleteTagVersion` in `app/AppSourceCop.json` and AS0072 to AS0076 in the ruleset (both stop list).
- Phase 3: switch the `schema_check.py` baseline from `main` to the latest release tag.
- Phase 4: static contract check for API page fields and entity names, and report dataset columns.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0003
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop#configuration
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop#rules
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0004
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0080
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0086
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0083
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0050
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-obsolete-objects
