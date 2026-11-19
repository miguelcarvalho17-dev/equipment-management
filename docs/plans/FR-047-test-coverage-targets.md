# FR-047 Test Coverage Targets — Plan

> Request (verbatim): FR-047 Test Coverage Targets
> Status: **approved**
> Issue: #88. Target: AppSource. Tooling decision (user): static procedure reach + rule coverage in Repo checks, plus a manual VS Code Test Explorer run. (Measured line coverage in AL-Go CI was tried first and dropped: see Request.)

## Request

FR-047 (issue #88) sets minimum test coverage targets: Business Logic 80%, Critical Processes 100%, APIs 80%. The issue also asks for agreed measurement tooling.

The agreed tooling is static and manual. A first plan chose measured line coverage in AL-Go CI. Its verification gate failed: `Run-TestsInNavContainer` / `Run-TestsInBcContainer` has no code-coverage parameters (navcontainerhelper main, file commit 3a3090d; AL-Go v10.0 = 5e09994). So there is no measured line coverage in CI.

What the plan builds:
1. A coverage register.
2. A stdlib Python check, `.github/scripts/coverage_check.py`, run as check 5 of `repo_checks.py` in the existing Repo checks workflow. It computes **procedure reach** for Business Logic and APIs, and **rule coverage** for Critical Processes.
3. A documented manual procedure for measured procedure-level coverage: VS Code Test Explorer, "Coverage (Procedure)" profile, against a sandbox.

**The metric is procedure reach, not line coverage.** A member counts as reached when a test calls it, or when the register declares a trace to an existing test. Branches and lines inside a member are not measured. Phase 1 only reports (`enforce: false`).

Target: AppSource

Findings:
- The API target applies now: pages 50123–50126 exist (FR-026 to FR-028).
- No test runs those pages. Tests 50180–50182 test the table procedures behind them. API reach starts at 0%.
- The AL MCP had no project loaded, so `al_symbolsearch` and `al_getnextobjectid` could not be used. No AL symbols or IDs are needed in phase 1.

## Definition of done (phase 1)

- [ ] `.github/coverage/coverage-register.json` contains:
  - `enforce: false` and `targets {businessLogic: 80, criticalProcesses: 100, apis: 80}`;
  - `scope` (Business Logic objects, API pages, exclusions with reasons);
  - `criticalProcesses` CP1–CP6, with one entry per rule site;
  - `traces`.
- [ ] `.github/scripts/coverage_check.py` (stdlib only):
  - computes and prints Business Logic reach %, API reach % and CP rule coverage %, each with covered/total and the target;
  - lists uncovered members and CP gaps;
  - writes a Markdown table to `GITHUB_STEP_SUMMARY` when that variable is set.
- [ ] Integrity errors exit 1:
  - an in-scope object ID that does not exist;
  - a mapped or traced test that does not exist as `[Test]`;
  - a traced member that does not exist;
  - an `Error(`/`TestField(` site in a CP procedure with no register entry;
  - an API trace whose test does not run the page.
- [ ] Below target produces `::warning::` only while `enforce` is false.
- [ ] `.github/scripts/test_coverage_check.py` (unittest) passes: `python3 .github/scripts/test_coverage_check.py`.
- [ ] `repo_checks.py` calls the check as check 5. `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-047-test-coverage-targets` exits 0 (warnings allowed).
- [ ] Baseline percentages and the gap list are recorded in the feature doc and in `docs/TODO.md` "FR-047 checks".
- [ ] No change to `.github/workflows/*`, `.AL-Go/*`, `app/`, `test/`, either `app.json`, analyzers or rulesets.
- [ ] Docs:
  - plan `docs/plans/FR-047-test-coverage-targets.md` with a `> Status:` header;
  - `docs/features/FR-047-test-coverage-targets.md`, which says plainly "procedure reach, not line coverage" and describes the manual Test Explorer procedure;
  - `docs/help/FR-047-test-coverage-targets.md`;
  - `CHANGELOG.md` section `## FR-047 Test Coverage Targets (version stays 29.0.0.0, no bump)`;
  - `docs/TODO.md`.
- [ ] Reports say "No separate AppSource validation ran". The CI Repo checks result is pending until the push.

## Out of scope

- Measured line coverage in CI. BcContainerHelper has no coverage parameters, and the AL-Go v10.0 RunPipeline has no coverage hook.
- Any `.ps1` override, CSV parsing or artifact upload.
- New or changed AL tests to close gaps (phase 2).
- Table triggers (`OnInsert`/`OnModify`/`OnDelete`/`OnRename`) and field `OnValidate` in the Business Logic reach metric. Their rules are covered by the CP rule register.
- Non-API pages, reports, queries, charts and cues.

## Coverage scope

**Business Logic (target 80%, procedure reach)**
- Objects:
  - Tables 50100, 50102, 50103, 50105, 50106, 50108, 50110, 50111, 50112.
  - Codeunits 50103, 50105, 50106, 50107, 50108, 50109, 50110, 50111, 50112, 50113, 50114, 50115, 50116, 50117, 50118, 50119, 50120, 50121, 50122, 50130, 50131, 50132, 50133, 50135, 50136, 50137, 50138, 50139.
- In-scope members:
  - non-`local` procedures;
  - `trigger OnRun`;
  - procedures preceded by an `[EventSubscriber(` attribute.
- Excluded members:
  - other `local` procedures;
  - event publisher stubs (`[IntegrationEvent`/`[BusinessEvent`/`[InternalEvent`);
  - table and field triggers.
- Excluded objects:
  - codeunits 50104 "EQM Install" and 50134 "EQM Upgrade": Install/Upgrade subtypes that tests cannot run (AA0243); their logic is in 50139;
  - all non-API pages, reports 50100–50102, queries 50100–50103.

**APIs (target 80%, procedure reach)**
- Pages 50123, 50124, 50125, 50126.
- In-scope members: each `trigger OnOpenPage` and each non-local procedure. Today that is 7 members:
  - 50123: OnOpenPage, `assign`, `returnEquipment`;
  - 50124: OnOpenPage;
  - 50125: OnOpenPage;
  - 50126: OnOpenPage, `markProcessed`.
- An API member is covered only through a trace whose test procedure body contains `TestPage "<page name>"` or `Page::"<page name>"`. Tests that call the table procedure behind the page do not count.

**Critical Processes (target 100%, rule coverage)**
- Every `Error(` or `TestField(` site in the CP members needs at least one mapped positive `[Test]` and one mapped negative `[Test]`.
- 78 sites today: 50100 (34), 50111 (18), 50105 (14), 50132 (8), 50109 (3), 50103 (1).
- The three 50139 procedures count as one rule each: a positive test, plus a negative test that checks already-upgraded data is not changed.

| Process | Members |
|---|---|
| CP1 Equipment registration | 50100 `OnInsert`, `CheckEquipmentConsistency`, the `Check*` locals, field `OnValidate` |
| CP2 Assignment and return | 50100 `AssignEmployee`, `UnassignEmployee`, `CheckAssignedEmployeeAllowed`; codeunit 50106; 50103 `CheckNoAssignedEquipmentOnBeforeDeleteEmployee` |
| CP3 Status transitions | 50100 `Status` `OnValidate`, `CheckStatusTransitionAllowed`, `IsFinalStatus` |
| CP4 Maintenance | 50105 `CheckMaintenanceConsistency`, `CheckNotPosted`, `CheckEquipmentAllowsMaintenance`, `CheckMaintenanceDate`; 50109 `OnRun`; 50108 `PostWithConfirmation`; 50100 `StartMaintenance`, `CompleteMaintenance`, `UpdateLastMaintenanceFromPosting` |
| CP5 Request approval | 50111 `CheckRequestConsistency`, `CheckEmployeeEligible`, `CheckEquipmentTypeAllowed`, `CheckRequestDate`; 50132 `SendForApproval`, `Approve`, `Reject`, `AssignEquipment`, `CheckApproverAllowed`, `CheckNotRejected`, `CheckPending`, `CheckApproved` |
| CP6 Data upgrade | 50139 `UpgradePerCompany`, `UpgradeDefaultWarrantyAlertDays`, `InitDefaultWarrantyAlertDays` |

## Objects

| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| (no AL objects) | — | — | — | — |
| Data | — | Coverage register | New | `.github/coverage/coverage-register.json` |
| Script | — | Coverage check | New | `.github/scripts/coverage_check.py` |
| Script | — | Coverage check unit tests | New | `.github/scripts/test_coverage_check.py` |
| Script | — | Repo checks (adds check 5) | Changed | `.github/scripts/repo_checks.py` |
| Docs | — | Plan, feature doc, help, changelog, TODO | New/Changed | see Definition of done |

Phase 2 test codeunits will take test-range IDs from `al_getnextobjectid`. The IDs still free are 50151–50155, 50159, 50160, 50163, 50165–50167 and 50169–50176, all reserved in docs.

## Events and standard symbols

| Symbol | Exact signature | Verified with al_symbolsearch |
|---|---|---|
| None. No AL code changes | — | n/a. The MCP returned "No projects are loaded". App member names come from a grep of `app/src` on 2026-11-19. |

## Steps

1. **`.github/coverage/coverage-register.json`.** Create the register.
   - Keys:
     - `enforce` (false) and `targets`;
     - `scope`: `businessLogic {tables, codeunits}`, `apis {pages}`, `excluded [{type, id, reason}]`;
     - `criticalProcesses`: `[{id, name, rules: [{file, procedure, key, positive: [{codeunit, test}], negative: [...], gap}]}]`;
     - `traces`: `[{type, id, member, tests: [{codeunit, test}], note}]`.
   - Fill `rules` mechanically from each `Error(`/`TestField(` site in the CP members.
     - `key` is the Err label name, or `TestField:<Field>`.
     - The negative test is the test whose `ExpectedError` uses that label's text.
     - The positive test is the success test of the same procedure.
     - Start from the inventories in `docs/plans/FR-045-automated-unit-tests.md` and `docs/plans/FR-046-integration-tests.md`.
     - If no test exists, set `gap: true` with empty lists. Never guess a mapping.
   - Fill `traces` for event subscribers and for ambiguous names.
     - Pick a `[Test]` in the matching feature test codeunit whose WHEN raises the subscribed event:

       | Subscriber codeunit | Test codeunit |
       |---|---|
       | 50136 | 50192 |
       | 50121 | 50186 |
       | 50120 | 50184 |
       | 50131 | 50187 |
       | 50118 | 50179 |
       | 50103 | 50158 AF3 |
       | 50113 | 50158 NF tests or 50199 |
       | 50139 `RegisterPerCompanyUpgradeTags` | 50177 |

     - If no test raises the event, add no trace. The member then counts as uncovered and is listed as a gap.
     - Add no API traces in phase 1. No test runs an API page.
2. **`.github/scripts/coverage_check.py`.** Python 3, stdlib only, in the style of `repo_checks.py`.
   - `strip_comments(text)`: removes `//` line comments and `/// ` doc lines.
   - `index_objects(app_root)`: maps `(type, id)` to `{name, file, text}` from object declarations, using the regex style of `repo_checks.OBJECT_RE`.
   - `index_members(obj)`: returns `[(member, kind)]`.
     - Non-local `procedure (\w+)` and `trigger OnRun`/`OnOpenPage`.
     - `[EventSubscriber(`-attributed procedures (`kind = subscriber`).
     - Skips event publisher stubs and other local procedures.
   - `index_tests(test_root)`: returns `{codeunit_id: {test_name: body_text}}`, where a test is a procedure under an attribute block that contains `[Test]`. Also returns `test_declared_names`, the set of every procedure name declared in `test/src`.
   - `is_ambiguous(name)`: true when the name is declared as an in-scope member in more than one in-scope object, or is in `test_declared_names` (for example the FR-046 helper `CountAssignments` collides with 50106 `CountAssignments`).
   - `is_called(name, tests_text)`:
     - Searches comment-stripped `test/src` lines that do not match `^\s*(local |internal )?procedure\s+<name>\b`.
     - Counts as a call: `\.<name>\b` or `\b<name>\s*\(`.
     - The declaration-is-not-a-call rule applies.
   - `member_covered(obj, member, kind)`:
     - API page member: only a valid trace.
     - Subscriber: only a trace.
     - `OnRun`: test text contains `Codeunit::"<object name>"` or `Codeunit.Run(<id>`, or a trace exists.
     - Otherwise: `not is_ambiguous(name) and is_called(name)`, or a trace exists.
   - `check_integrity()`:
     - Errors for missing objects, missing tests or members, and API traces whose test body has no `TestPage "<page name>"`/`Page::"<page name>"`.
     - Errors for CP rule sites without an entry. Find each `Error(`/`TestField(` inside the listed CP procedures, take its first argument (the label name or `TestField:<Field>`), and compare with the `key`s.
   - `run(root) -> (errors, warnings, summary_lines)`.
     - Prints per area: `Business Logic procedure reach: NN.N% (c/t, target 80)`, `API procedure reach: ...`, `Critical Process rule coverage: ...`.
     - Then up to 20 uncovered members and the CP gaps.
     - Below target: `::warning::` when `enforce` is false, error when it is true.
     - Appends a Markdown table to `GITHUB_STEP_SUMMARY` when that variable is set.
   - `__main__`: runs against the repo root and exits 1 on errors.
3. **`.github/scripts/test_coverage_check.py`.** Add the unittest cases listed under Tests, using `tempfile.TemporaryDirectory` fixtures that each contain `app/src`, `test/src` and a register. Run until green.
4. **`.github/scripts/repo_checks.py`.**
   - Add `sys.path.insert(0, str(Path(__file__).parent))` and `import coverage_check`.
   - Add `check_coverage()`: call `coverage_check.run(ROOT)`, route its errors through `error()` and its warnings through `warning()`, and print the summary lines.
   - Call `check_coverage()` in `main()` after `check_object_ids()`.
   - Add check 5 to the module docstring.
   - Why: integrity and the coverage report then run on every PR through the existing `RepoChecks.yaml`, with no workflow edit.
5. **Run.** Run `python3 .github/scripts/coverage_check.py` and copy the baseline percentages and gaps into the docs.
6. **Docs.**
   - Feature doc:
     - the policy, scope and exclusions with reasons;
     - each metric, defined exactly, with the statement "procedure reach, not line coverage";
     - why: BcContainerHelper and AL-Go v10.0 have no coverage parameters (cite navcontainerhelper commit 3a3090d and AL-Go-Actions 5e09994);
     - the manual procedure: VS Code Test Explorer, run profile "Coverage (Procedure)", BC 28+ sandbox, run all tests, check the CodeLens on in-scope procedures, record the date and result in the feature doc;
     - the baseline and gaps;
     - how traces work.
   - Help: how to read the summary, add a rule entry when adding an error, add a trace, and flip `enforce`.
   - CHANGELOG section.
   - TODO "FR-047 checks": first CI Repo checks result; first manual Test Explorer coverage run; phase 2 items.
7. **Final check.** Run `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-047-test-coverage-targets`. It must exit 0.

## Tests

These tests live in `test_coverage_check.py`. There are no AL tests in phase 1.

**Mapping integrity**
- [SCENARIO] A mapped test exists. [GIVEN] `codeunit 50999` with `[Test] procedure Foo`, and a CP rule mapped positive and negative to 50999/Foo. [WHEN] `run`. [THEN] No errors, and CP = 100%.
- [SCENARIO] (negative) A mapped test is missing. [GIVEN] A mapping to 50999/Bar, which does not exist. [THEN] One error names 50999 and Bar, and the exit code is 1.
- [SCENARIO] (negative) The mapped procedure is not a test. [GIVEN] `procedure Foo` without `[Test]`. [THEN] Error.
- [SCENARIO] (negative) A rule site is not registered. [GIVEN] `Error(NewErr, ...)` in a CP procedure with no entry for `NewErr`. [THEN] An error names the file and key.
- [SCENARIO] A gap lowers CP coverage. [GIVEN] Two rules, one with `gap: true`. [THEN] CP = 50%, plus a warning, with no error while `enforce` is false.

**Procedure reach**
- [SCENARIO] A called procedure is reached. [GIVEN] An in-scope codeunit with `internal procedure Calc()`, and a test containing `Mgt.Calc(`. [THEN] Business Logic = 100%.
- [SCENARIO] A call without parentheses is reached. [GIVEN] A test containing `Rec.Calc;`. [THEN] Calc is covered.
- [SCENARIO] (negative) A declaration is not a call. [GIVEN] The only match is `local procedure Calc()` in `test/src`. [THEN] Calc is not covered.
- [SCENARIO] (negative) A comment is not a call. [GIVEN] `// Calc(` in a test. [THEN] Not covered.
- [SCENARIO] (negative) Ambiguous across objects. [GIVEN] `GetStatusStyle` declared in two in-scope objects and called once, with no trace. [THEN] Neither is covered.
- [SCENARIO] (negative) Ambiguous with a test helper. [GIVEN] App `CountAssignments`, and a test helper `local procedure CountAssignments` that is called. [THEN] Not covered without a trace.
- [SCENARIO] A trace covers an ambiguous member. [GIVEN] A trace for the ambiguous member to an existing test. [THEN] Covered.
- [SCENARIO] Local procedures and publishers are excluded. [GIVEN] An uncalled `local procedure Helper()` and an `[IntegrationEvent] local procedure OnBeforeX`. [THEN] Neither is in the denominator.
- [SCENARIO] A subscriber needs a trace. [GIVEN] An `[EventSubscriber(...)] local procedure Sub` whose name a test happens to contain. [THEN] Not covered without a trace.
- [SCENARIO] OnRun is reached through Codeunit.Run. [GIVEN] A test containing `Codeunit.Run(Codeunit::"EQM X", Rec)`. [THEN] OnRun of "EQM X" is covered.

**API pages**
- [SCENARIO] (negative) An API member traced to a table-procedure test. [GIVEN] A trace whose test body has no `TestPage "EQM Equipment API"`. [THEN] An integrity error, and the member is not covered.
- [SCENARIO] An API member traced to a page test. [GIVEN] A test body with `TestPage "EQM Equipment API"`. [THEN] Covered.

**Enforcement and output**
- [SCENARIO] Enforce mode. [GIVEN] `enforce: true` and Business Logic at 50%. [THEN] An error, and exit 1.
- [SCENARIO] Step summary. [GIVEN] `GITHUB_STEP_SUMMARY` set to a temp file. [THEN] The file contains a three-row Markdown table.

Existing tests affected: none. Repo checks gains check 5. An integrity error in the register fails every PR by design. Below-target results only warn.

## Assumptions

- Procedure reach plus declared traces is an acceptable stand-in for coverage, because no CI coverage tool exists (gate finding) and the user chose the static approach.
- Calls without parentheses are legal for parameterless procedures, so `\.<name>\b` also counts as a call.
- Table and field triggers are excluded from Business Logic reach, because the CP rule register already covers their rules and they are never called by name.
- Critical Processes 100% means rule coverage, and CP1–CP6 are the critical processes (user-confirmed).
- No API traces in phase 1, because no existing test runs an API page.
- `GITHUB_STEP_SUMMARY` is available in the Repo checks job, as in any GitHub Actions step. If it is unset, the summary goes to the log only.

## DECISIONS

- FR-047 tooling | Chose static procedure reach and rule coverage in Repo checks plus a manual VS Code Test Explorer "Coverage (Procedure)" run, over measured line coverage in AL-Go. Supersedes the earlier Option A choice, because BcContainerHelper Run-TestsInBcContainer has no coverage parameters (navcontainerhelper 3a3090d, AL-Go-Actions v10.0 5e09994) | Reversible: yes
- FR-047 metric | Chose a member covered = called by name in test/src (comments and declarations excluded), or declared trace. Ambiguous names (declared in more than one in-scope object or in test/src) and subscribers need a trace | Reversible: yes
- FR-047 API rule | Chose that an API page member counts only when a traced test runs the page itself, over counting table-procedure tests | Reversible: yes
- FR-047 critical processes | Chose rule coverage (positive and negative test per Error/TestField site) for CP1–CP6 | Reversible: yes
- FR-047 scope | Excluded table and field triggers from reach (covered by the CP rules), and excluded non-API pages, reports, queries and codeunits 50104/50134 | Reversible: yes
- FR-047 rollout | Chose report-only (`enforce: false`) in phase 1 | Reversible: yes
- FR-047 script | Chose one new `coverage_check.py` called from `repo_checks.py` (no workflow edit), over extending `repo_checks.py` inline | Reversible: yes

## Risks

- **The number is not line coverage.** Reaching a procedure does not prove its branches ran. Name matching can also overstate: a call in a test proves the call is on a test path, not that every path inside it ran. The feature doc, help, CHANGELOG and every summary line must say "procedure reach". The manual Test Explorer run is the measured cross-check, and its output is not recorded automatically.
- **Indirect reach is understated.** Procedures run only through triggers or events show as uncovered until a trace is added. Reviewers should accept traces only to tests whose WHEN really raises the path.
- **Regex parsing of AL.** Unusual formatting can be missed, for example an attribute and a procedure on the same line, or multi-line signatures. The unit tests pin the supported forms. The reviewer should spot-check the uncovered list against the source.
- **Register drift.** A new `Error(` in a CP procedure without a register entry fails Repo checks by design. Later feature plans must include register entries. Mention this in the help article.
- **Low baselines.** API reach is 0%, and CP gaps are likely. Phase 2 needs new test codeunits, and only 18 reserved-but-free test IDs remain. Widening `test/app.json` is on the stop list.
- **API TestPage feasibility is unverified.** It is not known whether a test can drive bound actions with `WebServiceActionContext` (`assign`, `returnEquipment`, `markProcessed`). Phase 2 may need a documented exclusion.
- **CI not yet run.** The Repo checks result is known only after the push. "Not verified" until then.

Later phases:
- (2) Close the CP gaps and add API page tests, then set `enforce: true`.
- (3) Revisit measured coverage if AL-Go or BcContainerHelper adds coverage support, or via `al runtests` once it has a coverage option.
- (4) Diff-based reach for PRs.

## References

- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-test-explorer-vscode#view-code-coverage-information: the manual "Coverage (Procedure)" profile in VS Code Test Explorer (BC 28+, sandbox or on-premises).
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-al-tool#run-tests: `al runtests` has no coverage option.
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/al-go/algo-overview: AL-Go docs live on GitHub; BcContainerHelper support in AL-Go ends 2027-10-01.
- https://github.com/microsoft/navcontainerhelper/blob/main/AppHandling/Run-TestsInNavContainer.ps1 (commit 3a3090d): no code-coverage parameters, as found by the developer.
- https://github.com/microsoft/AL-Go-Actions/tree/v10.0 (commit 5e09994): no coverage support, as found by the developer.
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-application: test codeunits and test methods.

No separate AppSource validation ran.
