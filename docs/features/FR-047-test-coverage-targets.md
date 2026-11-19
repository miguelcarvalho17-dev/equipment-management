# FR-047 Test Coverage Targets

## Purpose
Sets minimum test coverage targets for the app (issue #88): Business Logic 80%, APIs 80% and Critical Processes 100%. The targets are measured by a static check that runs in Repo checks on every pull request. The check does not measure lines. It measures **procedure reach** for Business Logic and APIs, and **rule coverage** for the Critical Processes. The app does not change. No AL file, no `app.json` and no permission set changes.

**The metric is procedure reach, not line coverage.** A procedure counts as reached when a test in `test/src` calls it by name, or when the coverage register declares a trace to an existing test. Lines and branches inside a procedure are not measured. A reached procedure can still have code paths that no test runs.

Status: implemented on branch `feature/FR-047-test-coverage-targets`, not committed, not merged. App version stays 29.0.0.0, no bump. Plan: `docs/plans/FR-047-test-coverage-targets.md` (status approved). Phase 1 is report-only: `enforce` is `false` in the register.

## Verification status
- **Check script:** `.github/scripts/coverage_check.py` (stdlib Python), called as check 5 of `.github/scripts/repo_checks.py`. Baseline recorded by running the check on 2026-11-19.
- **Unit tests:** `.github/scripts/test_coverage_check.py` (unittest). Run with `python3 .github/scripts/test_coverage_check.py`. Not recorded as run in this document.
- **CI:** Repo checks result is pending until the branch is pushed. Not verified.
- **Manual coverage run:** not done. See "Manual coverage run" below.
- **AL tests:** not executed locally. This change adds no AL test.
- **AppSource validation:** No separate AppSource validation ran. The reviewer checked the change against the plan and the rules.
- **Review:** APPROVED.

## Targets and enforcement

| Area | Metric | Target | Baseline 2026-11-19 |
|---|---|---|---|
| Business Logic | Procedure reach | 80% | 44.0% (73/166) |
| APIs | Procedure reach | 80% | 0.0% (0/7) |
| Critical Processes | Rule coverage | 100% | 77.8% (63/81) |

Phase 1 (this change): `enforce` is `false`. Below target gives a warning in the Repo checks log. Integrity errors always fail the check.

## Metrics, defined exactly

**Business Logic procedure reach.**
- Counted members: non-local procedures, `trigger OnRun`, and procedures with an `[EventSubscriber(` attribute, in the in-scope tables and codeunits.
- Not counted: other `local` procedures, event publisher stubs (`[IntegrationEvent`, `[BusinessEvent`, `[InternalEvent`), and table and field triggers. The rules of table and field triggers are covered by the Critical Process rules.
- A member is reached when:
  - a test in `test/src` calls it as `.Name` or `Name(`. Comments, strings and declarations do not count; or
  - for `OnRun`: a test refers to `Codeunit::"<object name>"` or `Codeunit.Run(<id>`; or
  - a valid trace in the register names it.
- A name is **ambiguous** when it is declared as a non-local procedure in more than one in-scope object, or when any procedure in `test/src` has the same name (for example a test helper). An ambiguous name needs a trace. Every subscriber needs a trace.

**APIs procedure reach.**
- Counted members: each `trigger OnOpenPage` and each non-local procedure of the four API pages. Today that is 7 members.
- A member is reached only through a trace to a test whose body runs the page itself: `TestPage "<page name>"` or `Page::"<page name>"`. A test that calls the table procedure behind the page does not count.

**Critical Process rule coverage.**
- A rule is one `Error(` or `TestField(` key within one procedure of a critical process object. Repeats of the same key in one procedure are numbered `key`, `key#2`, `key#3`.
- A rule is covered when it has at least one mapped positive test and one mapped negative test. A rule with `positiveNotApplicable: true` (an unconditional rule, so no success path exists) needs only the negative test and a `note`.
- Field triggers are named `<Field>.OnValidate` (for example `Status.OnValidate`).
- Total: 81 rules today across CP1 to CP6.

## Scope and exclusions

**Business Logic**
- Tables 50100, 50102, 50103, 50105, 50106, 50108, 50110, 50111 and 50112.
- Codeunits 50103, 50105, 50106, 50107, 50108, 50109, 50110, 50111, 50112, 50113, 50114, 50115, 50116, 50117, 50118, 50119, 50120, 50121, 50122, 50130, 50131, 50132, 50133, 50135, 50136, 50137, 50138 and 50139.

**Excluded objects (with reasons, also in the register)**

| Object | Reason |
|---|---|
| Codeunit 50104 "EQM Install" | Install subtype. Tests cannot run it (AA0243). Its logic is in codeunit 50139. |
| Codeunit 50134 "EQM Upgrade" | Upgrade subtype. Tests cannot run it (AA0243). Its logic is in codeunit 50139. |
| All non-API pages | Not Business Logic. |
| Reports 50100 to 50102 | Not Business Logic. |
| Queries 50100 to 50103 | Not Business Logic. |

**APIs**
- Pages 50123, 50124, 50125 and 50126 (equipment, categories, assignments and integration events).

**Critical Processes (rule coverage)**

| Process | Members |
|---|---|
| CP1 Equipment registration | Equipment table: `OnInsert`, `CheckEquipmentConsistency`, the `Check*` local procedures, field `OnValidate` |
| CP2 Assignment and return | Equipment table: `AssignEmployee`, `UnassignEmployee`, `CheckAssignedEmployeeAllowed`; codeunit 50106; codeunit 50103 `CheckNoAssignedEquipmentOnBeforeDeleteEmployee` |
| CP3 Status transitions | Equipment table: `Status` `OnValidate`, `CheckStatusTransitionAllowed`, `IsFinalStatus` |
| CP4 Maintenance | Maintenance table and its checks; codeunit 50108 `PostWithConfirmation`; codeunit 50109 `OnRun`; equipment `StartMaintenance`, `CompleteMaintenance`, `UpdateLastMaintenanceFromPosting` |
| CP5 Request approval | Request table: `CheckRequestConsistency`, `CheckEmployeeEligible`, `CheckEquipmentTypeAllowed`, `CheckRequestDate`; codeunit 50132 approval procedures |
| CP6 Data upgrade | Codeunit 50139: `UpgradePerCompany`, `UpgradeDefaultWarrantyAlertDays`, `InitDefaultWarrantyAlertDays` |

Each of the three procedures in codeunit 50139 counts as one rule. Its positive test is the success path, and its negative test checks that already-upgraded data is not changed.

## Coverage register
File: `.github/coverage/coverage-register.json`.

- `enforce`: `false` in phase 1.
- `targets`: `businessLogic`, `criticalProcesses`, `apis`.
- `scope`: `businessLogic` (tables and codeunits), `apis` (pages), `excluded` (object, reason).
- `criticalProcesses`: each process has `id`, `name`, `objects` and `rules`. Each rule has `file`, `procedure`, `key`, `positive` and `negative` (lists of `{codeunit, test}`), and optionally `gap`, `positiveNotApplicable` and `note`.
- `traces`: each trace has `type`, `id`, `member`, `tests` and `note`. Phase 1 has 17 traces, all for event subscribers or ambiguous names.

**Rules for maintaining the register**
- `key` is the first argument of the `Error(` call (the label name, for example `CannotAssignFinalStatusErr`), or `TestField:<Field name>`. A call with the argument `''` has the key `''`.
- Every `Error(` and `TestField(` in an object listed under a process `objects` entry needs a rule entry. The check reads the whole object, so a site outside a critical procedure also needs an entry.
- **Whenever a critical process object gets a new `Error(` or `TestField(`, add a rule entry in the same change, with a positive and a negative test or a gap.** Otherwise Repo checks fails on the pull request.
- A rule entry without a matching site (for example after a message is removed) is an integrity error. Remove the entry.
- `positiveNotApplicable: true` without a `note` is an integrity error.
- A rule without a test is marked `gap: true` with empty lists and a `note`. Do not guess a mapping.

**Traces**
- A trace declares that a test reaches a member the static check cannot see: event subscribers, `OnRun` triggers reached indirectly, or names that are ambiguous.
- Accept a trace only when the test's WHEN really raises the path. A test that only shares a name does not count.
- No API trace exists in phase 1. No existing test runs an API page.

## Integrity errors and warnings

| Result | Cause | Effect |
|---|---|---|
| Integrity error | In-scope or process object does not exist | Repo checks fails |
| Integrity error | Trace object or member does not exist | Repo checks fails |
| Integrity error | A mapped or traced test is not a `[Test]` in the codeunit | Repo checks fails |
| Integrity error | An API trace whose test does not run the page | Repo checks fails |
| Integrity error | A rule file does not exist | Repo checks fails |
| Integrity error | A rule site has no register entry | Repo checks fails |
| Integrity error | A register entry has no matching site any more | Repo checks fails |
| Integrity error | `positiveNotApplicable` without a `note` | Repo checks fails |
| Warning | Business Logic, API or Critical Process result below target, while `enforce` is `false` | `::warning::` only |
| Error | Below target, while `enforce` is `true` | Repo checks fails |

The check prints three result lines, up to 20 uncovered members per area, and the Critical Process gaps. When `GITHUB_STEP_SUMMARY` is set, it also writes a Markdown table.

## Why there is no measured line coverage in CI
- AL-Go runs tests through BcContainerHelper (`Run-TestsInBcContainer`). That function has no code-coverage parameters (navcontainerhelper, `AppHandling/Run-TestsInNavContainer.ps1`, commit 3a3090d).
- AL-Go for GitHub v10.0 (AL-Go-Actions, commit 5e09994) has no coverage support. Its pipeline has no coverage hook.
- So the pipeline cannot produce a measured coverage number. The CI number is the static procedure reach from the check above. A measured cross-check is the manual Test Explorer run below.
- Revisit measured coverage when AL-Go or BcContainerHelper adds coverage support.

## Manual coverage run (VS Code Test Explorer)
Microsoft documents the "Coverage (Procedure)" run profile for Test Explorer. It collects procedure-level coverage and shows a CodeLens on the procedures and triggers that each test reached. See [Run AL tests from Visual Studio Code with Test Explorer](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-test-explorer-vscode#view-code-coverage-information).

Requirements: Business Central 28.0 or newer. An online sandbox or an on-premises server. Do not run it in production.

Steps:
1. Open the repository in VS Code with the AL Language extension, connected to a BC 28 or newer sandbox.
2. Open the Test Explorer. Select all tests in the test app.
3. Choose the run profile **Coverage (Procedure)** and run the tests.
4. Read the Test Results panel. Record the number of tests and the failures.
5. Open the in-scope procedures in `app/src` and look for the coverage CodeLens. Compare the result with the reach list printed by the check. Record the differences.
6. Record the date, the sandbox type, the test count and the result in the table below.

Notes from Microsoft: tests run from VS Code do not run under an AL test runner codeunit. A test that depends on events raised in a test runner can behave differently.

| Date | Sandbox | Tests run | Failures | Notes |
|---|---|---|---|---|
| Not run yet | — | — | — | — |

## Baseline (2026-11-19)

**Business Logic procedure reach: 44.0% (73/166, target 80).** 93 members are not reached. The check lists the first 20 in its log; run it locally to see the full list.

**API procedure reach: 0.0% (0/7, target 80).** Not reached:

| Page | Member |
|---|---|
| 50123 "EQM Equipment API" | `OnOpenPage`, `assign`, `returnEquipment` |
| 50124 "EQM Category API" | `OnOpenPage` |
| 50125 "EQM Assignment API" | `OnOpenPage` |
| 50126 "EQM Integration Event API" | `OnOpenPage`, `markProcessed` |

**Critical Process rule coverage: 77.8% (63/81, target 100).** 18 gaps:

| Process | Object | Member | Rule key | Gap |
|---|---|---|---|---|
| CP1 | 50100 | `AssistEdit` | `TestField:Equipment Nos.` | No test |
| CP2 | 50100 | `CheckAssignedEmployeeAllowed` | `EmployeeNotFoundErr` | No negative test. No test asserts this label. |
| CP3 | 50100 | `CheckStatusTransitionAllowed` | `CannotAssignFinalStatusErr` | No negative test. Only reachable by `Validate(Status, Assigned)` on final equipment. |
| CP3 | 50100 | `CheckStatusTransitionAllowed` | `NotAvailableForAssignmentErr` | No negative test |
| CP4 | 50105 | `AssistEdit` | `TestField:Maintenance Nos.` | No test |
| CP4 | 50105 | `CheckMaintenanceConsistency` | `TestField:Equipment No.` | No negative test |
| CP4 | 50105 | `CheckMaintenanceConsistency` | `TestField:Maintenance Date` | No negative test |
| CP4 | 50105 | `Equipment No..OnValidate` | `EquipmentCannotChangeErr` | No test. A test reaches the consistency check instead, not this trigger. |
| CP4 | 50105 | `OnInsert` | `InsertPostedErr` | No negative test |
| CP4 | 50105 | `OnInsert` | `TestField:Maintenance Nos.` | No negative test |
| CP4 | 50105 | `OnRename` | `RenameNotAllowedErr` | No negative test. Unconditional rule, so no positive test. |
| CP4 | 50109 | `OnRun` | `RecordNotSavedErr` | No negative test |
| CP4 | 50109 | `OnRun` | `AlreadyPostedErr#2` | No test. A history entry exists while the status is not Posted. |
| CP5 | 50111 | `AssistEdit` | `TestField:Request Nos.` | No test |
| CP5 | 50111 | `CheckRequestConsistency` | `TestField:Request Date` | No negative test |
| CP5 | 50132 | `AssignEquipment` | `EquipmentNotFoundErr` | No negative test |
| CP6 | 50139 | `UpgradePerCompany` | `upgrade` | No test |
| CP6 | 50139 | `UpgradeDefaultWarrantyAlertDays` | `upgrade` | No positive test |

## Phase plan
1. **Phase 1 (this change): report only.** Register, check, unit tests, docs. `enforce` is `false`.
2. **Phase 2:** close the 18 Critical Process gaps with new test codeunits. Add API page tests for the 7 API members, and check in a sandbox whether a test can drive the bound actions `assign`, `returnEquipment` and `markProcessed` through the page. Document any exclusion in the register. Then set `enforce` to `true`. Test IDs still free for this: 50151 to 50155, 50159, 50160, 50163, 50165 to 50167 and 50169 to 50176. Phase 2 test codeunits take their IDs from `al_getnextobjectid`. Widening the test ID range in `test/app.json` is on the stop list.
3. **Later:** revisit measured coverage when AL-Go or BcContainerHelper supports it, or when `al runtests` has a coverage option.
4. **Later:** diff-based reach for pull requests.

## Assumptions and risks
- **The number is not line coverage.** Reaching a procedure does not prove that its branches ran. A name match in a test proves that the call is on a test path, not that every path inside the procedure ran. The manual Test Explorer run is the measured cross-check.
- **Name matching can overstate reach.** Ambiguous names are not counted without a trace, which limits this.
- **Indirect reach is understated.** Procedures that run only through triggers or events show as uncovered until a trace is added.
- **Regex parsing of AL.** The check handles the forms the unit tests pin. An attribute and a procedure on the same line, or a multi-line signature, may be missed. The reviewer spot-checked the uncovered list against the source.
- **Register drift.** A new `Error(` or `TestField(` in a critical process object without an entry fails Repo checks by design. Later feature plans must include register entries.
- **Low baselines.** API reach is 0%, and the CP gaps need new tests in phase 2.
- **API TestPage feasibility is not verified.** It is not known whether a test can drive `assign`, `returnEquipment` and `markProcessed` through `WebServiceActionContext`.
- **CI not run yet.** The Repo checks result is pending until the push.

## Test status
- Check: written. Baseline recorded 2026-11-19.
- Unit tests of the check: written. Not recorded as run in this document.
- Repo checks in CI: pending until push.
- Manual Test Explorer coverage run: not done.
- Open items are in `docs/TODO.md`, section "FR-047 checks".

## Related
- Help article: `docs/help/FR-047-test-coverage-targets.md`
- Changelog: `CHANGELOG.md`, entry FR-047
- Plan: `docs/plans/FR-047-test-coverage-targets.md`
- Register: `.github/coverage/coverage-register.json`
- Check: `.github/scripts/coverage_check.py`
- Unit tests of the check: `.github/scripts/test_coverage_check.py`
- Test rules: `docs/features/FR-045-automated-unit-tests.md`, `docs/features/FR-046-integration-tests.md`
- Pipeline and Repo checks: `docs/help/FR-048-automated-build-pipeline.md`
