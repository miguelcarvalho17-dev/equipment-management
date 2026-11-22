# Testing strategy

> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-060-developer-documentation; nothing is verified in a Business Central sandbox.

The app has a separate test app in `test/` with 37 test codeunits and 569 test procedures, plus 5 helper codeunits. Tests run in CI through AL-Go. This page describes the test layers, the conventions, the coverage targets, how the tests run and what is not covered.

**In this article**
- [Test layers](#test-layers)
- [Test codeunit catalogue](#test-codeunit-catalogue)
- [Conventions](#conventions)
- [Coverage targets](#coverage-targets)
- [How tests run](#how-tests-run)
- [Python checks](#python-checks)
- [Known gaps](#known-gaps)
- [Related](#related)

## Test layers

| Layer | Codeunits | What it checks | Feature |
|---|---|---|---|
| Unit | 50150, 50156, 50157, 50164, 50168 and most others | One business rule at a time on tables and codeunits | [FR-045](../features/FR-045-automated-unit-tests.md) |
| Integration | 50158 EQM Process Integration Tests | Several steps in one transaction and their effects across modules: assignment, maintenance, approval and notification flows | [FR-046](../features/FR-046-integration-tests.md) |
| API (table level) | 50180, 50181, 50182 | The table triggers and procedures that the API pages use, in the field order of a request | [FR-026](../features/FR-026-equipment-api.md), [FR-027](../features/FR-027-equipment-categories-api.md), [FR-028](../features/FR-028-assignment-history-api.md) |
| Permission | 50162 EQM Role Permission Tests | The structure of the permission sets, read from platform metadata | [FR-036](../features/FR-036-permission-sets.md), [FR-057](../features/FR-057-permission-review.md) |
| Data classification | 50163 | Reads the compiled metadata and checks every field | [FR-058](../features/FR-058-data-classification.md) |
| Upgrade | 50177 EQM Upgrade Tests | The steps in codeunit 50139 (Install and Upgrade subtype codeunits cannot be run from tests) | [FR-044](../features/FR-044-data-upgrade-support.md) |
| Performance | 50159 EQM Performance Tests | Large data set behaviour | [FR-053](../features/FR-053-large-dataset-support.md) |
| Translation | 50153 EQM Translation Tests | The language files | [FR-055](../features/FR-055-multi-language-support.md) |

**Why the API tests are table-level and not HTTP.** The first version of the equipment API tests used 25 HTTP tests through `Library - Graph Mgt`. They failed in CI with HTTP 401, because the AL-Go container uses UserPassword authentication and the library sends no credentials. The tests were replaced with table-level tests and the HTTP checks became manual sandbox checks (`docs/TODO.md`, section FR-026, and [FR-026](../features/FR-026-equipment-api.md), "Test status"). As a result no test runs an API page; see [Known gaps](#known-gaps).

## Test codeunit catalogue

Generated from `test/src` on 2026-11-22. "Tests" is the number of `[Test]` procedures in the file; "helper" marks the `... Test Subscr` codeunits, which are not run as tests and only record what a test needs to observe. The sum of the Tests column is 569.

| ID | Name | Tests | Area | Feature |
|---|---|---|---|---|
| 50150 | EQM Equipment Creation Tests | 5 | Unit: equipment creation, warranty and maintenance dates | FR-045 |
| 50151 | EQM Telemetry Tests | 12 | Telemetry signals | FR-050 |
| 50152 | EQM Telemetry Test Subscr | helper | Helper: records telemetry signals | FR-050 |
| 50153 | EQM Translation Tests | 8 | Translations (language files) | FR-055 |
| 50154 | EQM Error Log Tests | 8 | Error log | FR-051 |
| 50155 | EQM Error Log Isolation Tests | 4 | Error log isolation of jobs | FR-051, FR-054 |
| 50156 | EQM Assignment Tests | 7 | Unit: assignment | FR-045 |
| 50157 | EQM Status Change Tests | 7 | Unit: status changes | FR-045 |
| 50158 | EQM Process Integration Tests | 21 | Integration: assignment, maintenance, approval and notification flows | FR-046 |
| 50159 | EQM Performance Tests | 19 | Performance and large data sets | FR-053 |
| 50160 | EQM Error Log Test Subscr | helper | Helper: error log hooks | FR-051 |
| 50161 | EQM Dashboard Tests | 12 | Dashboard and Role Center | FR-038 |
| 50162 | EQM Role Permission Tests | 26 | Permission sets (structure) | FR-036, FR-057 |
| 50163 | EQM Data Classification Tests | 6 | Data classification | FR-058 |
| 50164 | EQM Maintenance Tests | 26 | Unit: maintenance | FR-045 |
| 50168 | EQM Warranty Tests | 16 | Unit: warranty | FR-045 |
| 50169 | EQM Usage Analytics Tests | 17 | Usage analytics | FR-052 |
| 50172 | EQM Background Process. Tests | 12 | Background processing | FR-054 |
| 50176 | EQM Demo Data Tests | 26 | Demo data | FR-066 |
| 50177 | EQM Upgrade Tests | 9 | Upgrade steps | FR-044, FR-054 |
| 50178 | EQM Equipment Picture Tests | 15 | Equipment pictures | FR-023 |
| 50179 | EQM Doc. Attachment Tests | 12 | Document attachments | FR-024 |
| 50180 | EQM Equipment API Tests | 35 | API: equipment (table level) | FR-026 |
| 50181 | EQM Category API Tests | 6 | API: categories (table level) | FR-027 |
| 50182 | EQM Assignment API Tests | 7 | API: assignments (table level) | FR-028 |
| 50183 | EQM Equipment Note Tests | 18 | Equipment notes | FR-025 |
| 50184 | EQM Business Events Tests | 12 | Business events | FR-029 |
| 50185 | EQM Business Event Test Subscr | helper | Helper: records business event raises | FR-029 |
| 50186 | EQM Integration Event Tests | 14 | Integration event outbox | FR-030 |
| 50187 | EQM Power Automate Tests | 3 | Power Automate events | FR-031 |
| 50188 | EQM Equipment Request Tests | 46 | Equipment requests | FR-032 |
| 50189 | EQM Request Approval Tests | 41 | Request approval | FR-033 |
| 50190 | EQM Request Appr. Test Subscr | helper | Helper: request approval hooks | FR-033 |
| 50191 | EQM Change Log Setup Tests | 7 | Change log setup | FR-034 |
| 50192 | EQM Audit Trail Tests | 21 | Audit trail | FR-035 |
| 50193 | EQM Audit Trail Test Subscr | helper | Helper: audit trail hooks | FR-035 |
| 50194 | EQM Equipment FactBox Tests | 16 | FactBoxes | FR-037 |
| 50195 | EQM Equipment Register Tests | 11 | Equipment Register report | FR-039 |
| 50196 | EQM Asset Utilization Tests | 10 | Asset Utilization report | FR-040 |
| 50197 | EQM Maint. Cost Analysis Tests | 12 | Maintenance Cost Analysis report | FR-041 |
| 50198 | EQM Feature Mgt. Tests | 22 | Feature management | FR-042 |
| 50199 | EQM Application Setup Tests | 20 | Application setup | FR-043 |

## Conventions

These were confirmed by reading the test files on this branch.

- **`Subtype = Test`** on every test codeunit (37 of 37) and **`TestPermissions = Disabled`** (37 of 37). Because of this, the tests run without lowered permissions. `Permissions Mock` did not lower the rights in CI, so reader tests that depended on it were removed (note in `docs/TODO.md`, section FR-023).
- **`[TransactionModel(TransactionModel::AutoRollback)]`** on the tests that write data (35 of 37 codeunits). The two others are 50162, which only reads permission metadata, and 50155, whose tests use `TransactionModel::AutoCommit` because the error log entry must survive the rollback of the job; each test commits first, reads and deletes the new entries, and commits again before it asserts ([FR-051](../features/FR-051-error-logging.md)).
- **`[SCENARIO]`, `[GIVEN]`, `[WHEN]`, `[THEN]`** comments in each test.
- **At most one `asserterror`, as the last action.** A failed statement rolls back the whole test transaction, so the error text is checked afterwards.
- **Test data** comes from Locked `Tok` labels with a prefix (for example `EQMCRT`) plus a counter, and from `Random()`. Tests do not depend on demo data or on other tests.
- **Handlers** (`ConfirmHandler`, `MessageHandler`, ...) for every UI interaction.
- **Internals** of the app are reached through `internalsVisibleTo` in `app/app.json`.
- **Library Assert** (`Assert: Codeunit "Library Assert"`) is the only test library dependency.

## Coverage targets

FR-047 sets targets and measures them with a static check ([FR-047](../features/FR-047-test-coverage-targets.md)). The metric is **procedure reach** (a procedure counts as reached when a test calls it by name or the register declares a trace), not line coverage, for Business Logic and for the APIs, and **rule coverage** for the Critical Processes (each `Error(` or `TestField(` needs a positive and a negative test).

| Area | Metric | Target |
|---|---|---|
| Business Logic | Procedure reach | 80% |
| APIs | Procedure reach | 80% |
| Critical Processes | Rule coverage | 100% |

- The register is `.github/coverage/coverage-register.json`. It has `"enforce": false`, so a result below target is a warning in the Repo checks log, not a failure. Integrity errors always fail.
- **Rule for contributors:** a new `Error(` or `TestField(` in a Critical Process object needs a register entry in the same change, with a positive and a negative test or a recorded gap. Otherwise Repo checks fails.
- **Current result.** `python3 .github/scripts/coverage_check.py` run on 2026-11-22 on this branch: Business Logic procedure reach 57.8% (118/204), API procedure reach 0.0% (0/7), Critical Process rule coverage 77.8% (63/81). All three are below target and only warn. The FR-047 baseline of 2026-11-19 was 44.0% (73/166), 0.0% (0/7) and 77.8% (63/81).
- The 18 Critical Process gaps and the plan to close them are in [FR-047](../features/FR-047-test-coverage-targets.md) and [`docs/TODO.md`](../TODO.md) ("FR-047 checks").
- Measured line coverage is not available in CI: AL-Go v10.0 has no coverage support. The manual cross-check is the Test Explorer run profile "Coverage (Procedure)" on a Business Central 28 or newer sandbox. It has not been run (FR-047, "Manual coverage run").

## How tests run

- **In CI.** AL-Go runs the test app on every pull request into `main` and on every push to `main` that is not markdown-only (see [CI/CD](../setup/ci-cd.md)). A failing test fails the build.
- **Locally.** Only with AL Test Runner or the Test Explorer in VS Code against a Business Central sandbox. There is no command-line test runner on macOS, and agents cannot run tests (`CLAUDE.md`).
- **Reading counts from CI:**
  ```text
  gh pr checks <pr>
  gh run view <run-id> --log | grep -E "tests,|passed"
  ```
  AL-Go prints `<app>, N tests, N passed, N failed, N skipped`.
- **Result recorded for this documentation.** CI/CD run 44925652127 on `main` (commit `e292f84`, the FR-058 merge, 2026-11-21): `Equipment Management Tests, 569 tests, 569 passed, 0 failed, 0 skipped`. The count equals the 569 `[Test]` procedures in this branch, which has not changed `test/`. Read from the run log on 2026-11-22. The run says nothing about this branch.
- The previous run on `main` (44920033270, commit `0aed031`, the FR-057 merge) failed: `563 tests, 562 passed, 1 failed`. The failing test was `InsertedNoteGetsSystemUserAndTime` in codeunit 50183 (`Assert.IsTrue failed. Created At should not be after the insert`). The next run passed. The cause is not analysed here.
- Earlier feature docs say "written, not executed, CI result pending" for tests that the later run above has since executed. For the claim "the tests pass", use the CI run, not the feature docs.

## Python checks

The repository checks have their own unit tests. Run them with Python 3.9 or newer:

```text
python3 .github/scripts/test_coverage_check.py
python3 .github/scripts/test_version_check.py
python3 .github/scripts/test_xlf_sync.py
```

Run in this session on 2026-11-22 with Python 3.9.6: 27, 22 and 31 tests, all OK.

## Known gaps

- **API pages:** no test runs an API page (0 of 7 members reached). Whether a test can drive the bound actions through `WebServiceActionContext` is not verified. See `docs/TODO.md`, "FR-047 checks".
- **Critical Process gaps:** 18 at the FR-047 baseline; current result above.
- **Test-app analyzers are off in CI** (`enableCodeAnalyzersOnTestApps` is `false`, see [CI/CD](../setup/ci-cd.md#al-go-settings)).
- **Not executed in a sandbox:** the tests run only in the AL-Go container. Manual sandbox checks per feature are open in [`docs/TODO.md`](../TODO.md).
- **UI flows:** no TestPage flows (Equipment Card and Request Card actions), no job queue runs and no Power Automate flows ([FR-046](../features/FR-046-integration-tests.md), "Not covered").
- **Assumption:** `GuiAllowed()` is true in the AL-Go test session; the confirm-handler and notification tests depend on it.

## Related

- [Extension structure](extension-structure.md#test-app)
- [CI/CD process](../setup/ci-cd.md)
- Feature docs: [FR-045](../features/FR-045-automated-unit-tests.md), [FR-046](../features/FR-046-integration-tests.md), [FR-047](../features/FR-047-test-coverage-targets.md)
- Microsoft Learn: [Test codeunits and test methods](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-test-codeunits-and-test-methods), [TestPermissions property](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-testpermissions-property), [Test Explorer and code coverage](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-test-explorer-vscode#view-code-coverage-information)
