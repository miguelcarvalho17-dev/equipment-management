# FR-053 Large Dataset Support

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
Keeps the app usable in companies with 100,000+ equipment records and 1,000,000+ assignment records (issue #94). NFR-001 (#22) set the current target at 10,000 records and deferred the warranty job change to this feature. This is phase 1: indexes, one cache, one query and tests. No change to what users see, except speed.

Status: implemented on branch `feature/FR-053-large-dataset-support`, not committed, not merged. Plan: `docs/plans/FR-053-large-dataset-support.md` (status approved). Target: AppSource.

## Audit (before the change)
The audit checked the tables with the most rows and the code that reads them.

| Area | Finding | Action |
|---|---|---|
| Table 50103 Equipment Assignment (1M rows) | Readers that filter by equipment or employee already have an index (Assignment Mgt., FactBoxes, part 50105, page 50104 from the Employee card) | None |
| Page 50104 Equipment Assignments (unfiltered, newest first) | Reads the clustered index backward. Active entries sit near the tail. `OnAfterGetRecord` reads the employee per row (N+1) | Employee name cache (see below) |
| Table 50103, API delta reads on `lastModifiedDateTime` | No index on the system modified time | Key SystemModified |
| Table 50100 Equipment (100k rows) | Filters on Category Code and Status have no index that covers both (Request Approval Mgt. assign lookup, Dashboard Mgt. asset utilization) | Key CategoryStatus |
| Table 50100, API delta reads on `lastModifiedDateTime` | No index on the system modified time | Key SystemModified |
| FlowFields on equipment and assignments | Each is backed by an index or SIFT key | None. The NFR-001 decision against SIFT on Status holds at this size |
| Dashboard charts | Already use Queries 50100 to 50103 | None |
| Warranty job, `CancelStaleAlerts` | Reads the equipment record once per open alert, inside the lock of `GenerateAlerts` | One query (see below) |

Object IDs and the full list of changed objects are in the plan.

## What changed

### Keys
- **Equipment (table 50100):** two new secondary keys.
  - CategoryStatus (Category Code, Status): filters on category and status.
  - SystemModified (SystemModifiedAt): delta reads of the equipment API.
- **Equipment Assignment (table 50103):** one new secondary key.
  - SystemModified (SystemModifiedAt): delta reads of the assignment API. Without it, a delta read scans all assignments.
- No existing key, field or property changed. The new keys have no unique, clustered or included fields.
- The keys are built when the new version is installed. No data changes and no upgrade code. The build on about 1M assignment rows and about 100k equipment rows may lengthen the upgrade window.
- A published key can only be obsoleted, not removed. The new keys stay in the table.

### Equipment Assignments page (50104)
- The employee name is read once for each employee while the page is open. Each employee is read at most once per page session.
- A missing employee shows a blank name. The blank is kept in the cache, so the page does not read the same missing employee again.
- The name shown is the same as before.
- A user who cannot read employees gets a blank name, as on the Equipment List.
- A rename made while the page is open shows after the page is reopened.

### Warranty alert cancellation
- `CancelStaleAlerts` reads all open alerts once. Each alert is joined to its equipment in the same read.
- Stale alerts are collected first. Then each one is cancelled after the status is read again and is still Open. An alert that another user acknowledged in between stays Open.
- The same alerts are cancelled as before:
  - the equipment was deleted;
  - the warranty end date on the alert no longer matches the equipment;
  - the equipment is Lost or Disposed.
- New internal query "EQM Open Warranty Alerts". It runs inside the write transaction of `GenerateAlerts` (read-write intent), so it is never read from a read-only replica.
- The query is not in the API permission set.

### Permissions and translations
- Permission set EQM - Reader: execute on the new query. Manager and Administrator inherit it. API Consumer is unchanged.
- The query caption "Open Warranty Alerts" is in the translation file, with a Portuguese (Portugal) and a Spanish (Spain) text.

## Not changed (decided)
- **SIFT and columnstore for FlowFields.** Not needed at this size. Confirms NFR-001. Phase 3.
- **No Status or Assignment Date key on the assignment table.** The views read the clustered index backward. Each extra index costs on every write.
- **`OptimizeForTextSearch`** on Description, Manufacturer, Model and Serial No. Phase 2. It changes how search matches text, so it needs the user's approval.
- **Prefetching alerts in `GenerateAlerts`.** Phase 2.
- **Employee name cache** on the assignment part (50105) and on request pages. Not in scope.
- **`BuildMaintenanceCostBuffer`** (FR-041 decision). Not changed.
- **CategoryCode key on equipment.** Kept. The key is still used by `SetCurrentKey` in the category table.
- **Object IDs, app.json, events, fields, captions and ToolTips.** No new event, no new field, no change to an existing caption or ToolTip. The version stays 29.0.0.0.

## Write overhead of the new keys
- Equipment: each insert and delete updates two more indexes. The CategoryStatus index is updated when the category or status changes. The SystemModified index is updated on every modify, because the system modified time changes on every save.
- Assignment: each insert, modify and delete updates one more index. The SystemModified index is updated on every modify.
- The extra cost is small compared with the reads it removes, but it is not measured. Check it in the sandbox with a bulk insert of assignments.

## Testing
- Test codeunit 50159 "EQM Performance Tests" gets the new scenarios: list open on a large history (L1), missing employee name (L2), delta filter on the modified time (D1), keys exist (K1), asset utilization by category (C1, C2), stale alert cancellation (S1 to S5).
- The datasets in CI are smaller than the target. The CI sizes are:
  - 20,000 assignments;
  - 10,000 equipment records;
  - 1,000 alerts.
- The time limit is the NFR-001 budget of 3,000 ms.
- The 100,000 equipment and 1,000,000 assignment sizes are checked by hand in a sandbox. CI cannot hold that volume.
- **Reviewer note on the employee-name cache:** the cache is verified by code review and by the time budget only. Test L1 would pass without the cache, because the names are right and the list is fast enough at CI size. No test counts the employee reads.
- **Reviewer MINOR m1 (open):** test K1 has no `AutoRollback` attribute. K1 is read-only: it reads the key definitions and writes nothing, so the missing attribute does not change data.
- Existing regression codeunits (for example 50168, 50199 and 50187) are re-run in CI without change.

## Verification status
- **Tests:** Not verified: tests not executed locally, CI result pending. The flaky-timing risk applies to L1, C1 and S5: if one fails twice, it is reported, and the budget is not raised.
- **Compile:** not checked in this documentation step.
- **Review:** the reviewer note and MINOR m1 above.
- **AppSource validation:** no separate AppSource validation ran. The upgrade check for AS0009, AS0010 and AS0038 (the new indexes) is open.
- **repo_checks.py:** not run by al-docs. The main agent runs it after this report.

## Open items
- Run `Pull Request Build` and read the result for test codeunit 50159 and the regression codeunits.
- Sandbox check at full volume (100,000 equipment, 1,000,000 assignments):
  - the Equipment Assignments page opens within the budget and shows names;
  - an API delta read by `lastModifiedDateTime` returns only changed records;
  - the Equipment List and dashboard filters respond within the budget;
  - the daily warranty job finishes in an acceptable time;
  - the upgrade time with the new indexes is acceptable.
- Sandbox check of the write overhead (bulk insert of assignments before and after).
- Phase 2: `OptimizeForTextSearch` (needs the user's approval) and prefetching alerts in `GenerateAlerts`.
- Phase 3: a BCPT scenario at full volume (new app, needs the user's approval) and a review of the CategoryCode key.

## Related
- Help article: `docs/help/FR-053-large-dataset-support.md`
- Changelog: `CHANGELOG.md`, entry FR-053
- Plan: `docs/plans/FR-053-large-dataset-support.md`
- Performance target: `docs/features/NFR-001-performance.md` and `docs/help/NFR-001-performance.md`
- Microsoft Learn: [Table keys](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-table-keys), [System fields (data audit)](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields#data-audit-fields), [Extract data](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extract-data), [Query links and joins](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-query-links-joins#leftouterjoin), [Read isolation](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-read-isolation), [Calculate only visible FlowFields](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/calculate-only-visible-flowfields-feature-key), [Performance for developers](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/performance/performance-developer#efficient-data-access)
