# NFR-001 Performance

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
Keeps the equipment list and the dashboard responsive with large datasets (issue #22). The requirement: the Equipment list opens in less than 3 seconds for up to 10,000 records, and dashboard figures are calculated with FlowFields or Queries. FR-053 (100k+ records, issue #94) is out of scope.

The change is small and additive. It adds three secondary keys to the equipment table and caches employee names on the Equipment list. No field, procedure, event, caption, permission or upgrade code changes. The version stays 29.0.0.0.

Status: implemented on branch `feature/NFR-001-performance`, not committed, not merged. Plan: `docs/plans/NFR-001-performance.md` (status approved). Target: AppSource.

## Audit (before the change)
- **Dashboard.** Every tile is already a FlowField (count, sum or average). The charts already use Queries. No AL loop calculates a dashboard figure. The requirement "FlowFields or Queries" was already met, so the change adds index support only.
- **Filters without an index.** The equipment table had no key on Status. Every Status view, every status drill-down and the dashboard FlowFields that filter on Status were a full scan of the table. The warranty and next-maintenance tiles had the same problem.
- **Employee lookup per row.** The Equipment list read the Employee table once for every row that had an assigned employee. The same employee was read again for each of their equipment.
- **Already indexed, no change.** Maintenance records, warranty alerts, equipment requests and the assignment history already had keys or SIFT indexes that cover their dashboard filters.

## What changed
### Keys on the equipment table
Three secondary keys are added after the existing assignment key. Existing keys are unchanged.

| Key | Fields | Used by |
|---|---|---|
| Status | Status. Included field: Purchase Cost | Status views and drill-downs on the list, the status FlowFields and the total assets value, the status query for the charts |
| WarrantyEndDate | Warranty End Date, Status | Warranty tiles and the warranty job ranges |
| NextMaintenanceDate | Next Maintenance Date, Status | Overdue maintenance tile and planned maintenance filters |

The keys are plain secondary indexes, not SIFT keys. A SIFT index on Status would make every equipment insert or status change update the same few summary rows. Plain indexes are enough for the size this requirement covers.

On upgrade, Business Central creates the three indexes on the equipment table. This is additive. It does not change any data.

### Employee names on the Equipment list
The Assigned Employee Name is read through a cache for the time the page is open.
- The first row of an employee reads the Employee record. Later rows of the same employee use the cached name.
- An employee who does not exist is cached as a blank name. The list shows a blank name, as before.
- Without read permission on Employee, the name stays blank and no read is attempted, as before.
- The cache lives only in the page. A name that changes while the list is open is shown with the old name until the list is opened again.

## Behaviour changes for users
- Status views, status drill-downs and the dashboard tiles that filter on status or on the warranty and maintenance dates respond faster on large tables.
- The Assigned Employee Name shows the same values as before. The name can be stale while the list is open (see above).
- No captions, ToolTips or pages change. No new permission is needed.

## Not changed (decided)
- **Maintenance cost per row on the list.** The percentage still calculates the total maintenance cost for each row. The value is cheap because the history table already has a SIFT index on the equipment and date. Reusing the value of a page FlowField would show a wrong percentage when a user hides the column while "Calculate only visible FlowFields" is on.
- **Cue page, queries, charts and dashboard procedures.** No change.
- **Per-alert lookups in the warranty job** and the FactBox counts. Out of scope; the first is a job, not a page path.
- **SIFT on the new keys.** Not needed at 10,000 records. It is a question for FR-053.

## Verification status
- **Compile:** the app compiles with no new warnings in `alc`. CodeCop, UICop and AppSourceCop are on.
- **AppSourceCop baseline:** compared by hand against the baseline. No AS0009, AS0010, AS0038 or AS0042 messages.
- **Review:** APPROVED by al-reviewer.
- **Tests:** test codeunit "EQM Performance Tests" has eight tests (P1 to P8 in the plan). They cover the list open time, a status view, the dashboard tiles and cue page, the status query, lost and disposed equipment, the employee name cache and blank names. The tests have not been executed locally. Not verified: tests not executed locally, CI result pending.
- **3-second target:** Not verified. The tests measure the server side page open time with 10,000 records through the test page. They do not measure web client rendering. The CI result is the first evidence. A check in a sandbox with 10,000 records is still open.
- **repo_checks.py:** not run by al-docs. The main agent runs it after this change.
- **No separate AppSource validation ran.** The reviewer checked the change against the plan and the AppSource rules.

## Open items
- Run the performance tests in CI and read the result (`Pull Request Build`). If a timing test fails, re-run it once. If it fails again, the 3-second target is not met for this change. Do not raise the budget silently.
- Sandbox check with 10,000 equipment records: open list, a status view and the dashboard, in the web client.
- Performance Toolkit scenarios are phase 2. They need a new app and the user's decision.

## Related
- Help article: `docs/help/NFR-001-performance.md`
- Changelog: `CHANGELOG.md`, entry NFR-001
- Plan: `docs/plans/NFR-001-performance.md`
- Microsoft Learn: [When are FlowFields calculated](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-flowfields#when-are-flowfields-calculated), [Calculate only visible FlowFields feature key](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/calculate-only-visible-flowfields-feature-key), [SIFT performance](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-sift-performance), [Included fields property](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-includedfields-property)
