# FR-045 Automated Unit Tests

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
Adds automated tests for five areas of the app: equipment creation, assignment logic, status changes, maintenance processing and warranty calculation. Before this change, these rules were covered only in part by the existing tests. The tests use the test app in `test/`. The app itself does not change.

Status: implemented on branch `feature/FR-045-automated-unit-tests`, not committed, not merged. App version stays 29.0.0.0. No change to `app/`, `app.json`, permission sets, captions or translations.

## Verification status
- **Build:** the five test codeunits were written and compiled with alc, because the AL MCP had no project loaded. Before the pull request, confirm that `test/` compiles with 0 errors and 0 warnings. The 5 AA0073 warnings in `EQMDashboardTests.Codeunit.al` predate this change and are not part of FR-045.
- **Review:** APPROVED.
- **Tests: written, NOT executed.** 52 test procedures in 5 codeunits. There is no command-line test runner and no sandbox here. Not verified: tests not executed locally, CI result pending. Nothing here claims the tests pass.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the AppSource rules.

## Test codeunits

| ID | Name | Tests | Area |
|---|---|---|---|
| 50150 | EQM Equipment Creation Tests | 5 | Required fields, warranty dates on Insert, future Last Maintenance Date, Next Maintenance Date |
| 50156 | EQM Assignment Tests | 7 | Issue example (create, assign, verify), privacy-blocked and unknown employee, open maintenance, return, reassign, direct employee change |
| 50157 | EQM Status Change Tests | 7 | Open maintenance and In Maintenance, manual In Maintenance on assigned equipment, Lost is final, disposal with open maintenance |
| 50164 | EQM Maintenance Tests | 17 | Registration, Lost and unknown equipment, future date, negative cost, posting, read-only and delete rules, planned dates |
| 50168 | EQM Warranty Tests | 16 | Expiring Soon and Expired boundaries, reference date 0D, days remaining, due interval, alert idempotency, disposed and expired equipment, end date change, Acknowledge |

Codeunit IDs 50150, 50156, 50157, 50164 and 50168 were reserved in earlier plans for deferred tests and were never used. The test app ID range (50150..50199) is unchanged.

The test codeunits follow the conventions of the existing tests: `TestPermissions = Disabled`, `[TransactionModel(TransactionModel::AutoRollback)]`, `[SCENARIO]/[GIVEN]/[WHEN]/[THEN]` comments, and at most one `asserterror` as the last action. Data uses Locked `Tok` labels with a prefix and a counter, and `Random()`. Thresholds come from the app getters. Confirm dialogs are answered by `[ConfirmHandler]` only in tests where a confirm really happens.

## Deviations from the plan
- M2 and W12 set Lost or Disposed with a direct Status assignment and `Modify(false)`.
- M13 uses direct assignment with `Modify(true)`.
- W1 to W4 use `Today()` as the reference date.
- W1 to W8 use in-memory equipment records.

## Open minor findings
- W1 to W4 use `Today()` as the reference date, while A1, A5 and A6 assert against `WorkDate()`. In CI the two may differ.
- Employee First Name literals are used in 3 test files.
- A3 cannot distinguish the two error sources (the table relation error and `EmployeeNotFoundErr`). It asserts the employee number only.

## Not in scope
- No test for NFR-005 maintenance log, FR-020 overdue monitoring, FR-018 jobs, FR-017 notifications, or TestPage UI tests. These are later phases.
- No change to the existing 25 test codeunits.
- No shared test library codeunit.

## Test status
- Five codeunits (52 tests): written and compiled; not executed locally. CI result pending.
- Open items are in `docs/TODO.md`, section "Tests" and section "FR-045 checks".

## Related
- Help article: `docs/help/FR-045-automated-unit-tests.md`
- Changelog: `CHANGELOG.md`, entry FR-045
- Plan: `docs/plans/FR-045-automated-unit-tests.md`
- Maintenance rules: `docs/features/FR-010-maintenance-registration.md`
- Warranty rules: `docs/features/FR-014-warranty-information.md`
