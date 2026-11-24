# FR-054 Background Processing Optimization

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
Long-running processes run through the job queue (issue #95). This change does three things:

1. **Maintenance Calculation Job:** a third daily job that recalculates the stored next maintenance date of the equipment. Before, the stored date changed only when a user or a job saved the equipment. A date that was written without the normal checks, or a date that a partner's logic changed, stayed stale.
2. **Retention policies for the equipment logs:** the three log tables are registered in the standard Retention Policies framework, so an administrator can delete old entries automatically. Nothing is archived. The app's own deletion job is not built.
3. **Warranty alert job:** the job reads the existing alerts of the date window once, instead of once per equipment. Behaviour is unchanged.

Status: implemented on branch `feature/FR-054-background-processing-optimization`, not committed, not merged. Plan: `docs/plans/FR-054-background-processing-optimization.md` (status approved). Target: AppSource. App version stays 29.0.0.0 (unreleased, no bump). No `app.json` change, no new permission set, no new event, no new published procedure.

## Verification status
- **Review:** APPROVED. No BLOCKER and no MAJOR finding.
- **Tests: written, NOT executed locally.** Test codeunit 50172 "EQM Background Process. Tests" covers BP1 to BP9, BP-W1 and BP-W2. Test I4 is in "EQM Error Log Isolation Tests" (50155). RP1 to RP3 are in "EQM Upgrade Tests" (50177). There is no command-line test runner and no sandbox run yet. Not verified: tests not executed locally, CI result pending.
- **Build:** not recorded in this document. The compile result of `app/` and `test/` is reported with the pull request.
- **repo_checks.py:** not run by al-docs. The main agent runs it after this change.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the AppSource rules.
- **Sandbox:** not run. The checks BP-SB1 to BP-SB4 and RP-SB1 to RP-SB4 are in `docs/TODO.md`, section "FR-054 sandbox checks".

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Codeunit | 50145 | EQM Maintenance Calc. Job | New. Public job codeunit (its ID is stored in job queue entries). Its body runs through the monitoring job runner. |
| Codeunit | 50108 | EQM Maintenance Mgt. | New procedure `RecalculateNextMaintenanceDates` (internal), with its helpers and telemetry. |
| Codeunit | 50143 | EQM Monitoring Job Runner | New case branch for 50145. Error operation Maintenance Calculation Job. |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | `GenerateAlerts` reads the existing alerts of the date window once, into a dictionary. The per-equipment lookup is removed. |
| Codeunit | 50115 | EQM Monitoring Job Mgt. | `EnsureMonitoringJobs` creates a third daily entry at 05:00. The start time is a parameter of `EnsureJob`. |
| Codeunit | 50139 | EQM Upgrade Mgt. | Retention policy step, guarded by an upgrade tag. Called from `UpgradePerCompany`. |
| Enum | 50113 | EQM Error Operation | New value 4 "Maintenance Calculation Job". |
| Page | 50103 | EQM Equipment Setup | New status field "Maintenance Calculation Job" (visible when Maintenance Planning is on). AboutText names the third job. |
| Table | 50115 | EQM Error Log Entry | ToolTip of field Operation names the new job. |
| Permission set | 50100 | EQM - Reader | Execute on codeunit 50145. No other change. |
| Codeunit (test) | 50172 | EQM Background Process. Tests | New, not executed. |
| Codeunit (test) | 50155 | EQM Error Log Isolation Tests | New test I4. |
| Codeunit (test) | 50177 | EQM Upgrade Tests | New tests RP1 to RP3. |
| XLIFF | - | g / pt-PT / es-ES | New captions, ToolTips and labels. |

The job codeunit ID 50145 is permanent once released. Test codeunit 50172 was the FR-018 reservation.

## Maintenance Calculation Job
### What it does
- It recalculates the stored "Next Maintenance Date" of every equipment whose status is not final (Lost or Disposed). It uses the same calculation as the equipment card (`CalcNextMaintenanceDate`), so a partner's `OnBeforeCalcNextMaintenanceDate` subscriber is respected.
- It writes only the rows where the stored date differs from the calculated date. Each write uses `Modify(false)`: the change does not run the table's consistency checks or the audit trail. The change is a correction of a derived field.
- Final-status equipment is never written.
- It does nothing when Maintenance Planning is off.
- It sends no notification and changes no other field.

### How the job runs
- The job is one daily recurring entry, category EQM, at 05:00. Schedule Monitoring Jobs creates it when it is missing. The two existing entries (warranty alert job and overdue maintenance job) stay at 06:00 and are not changed.
- The job runs through the monitoring job runner (FR-051). When it fails, its error is written to the Equipment Error Log with the operation Maintenance Calculation Job, and the job queue entry still ends in state Error with the same message.
- The job reads the equipment first, collects the rows that need a correction, and then writes them. It does not write inside the read loop.
- It commits after every 1000 corrected dates, but only when it runs isolated (no transaction is open in the caller) and only after at least one correction (`UpdatedCount > 0`). A caller that has opened a transaction is never committed.
- Telemetry signal EQM0012 is logged once per run. It holds counts and a trigger only, no record numbers: `EquipmentChecked`, `DatesUpdated`, `PlannedOverdueCount`, `ReferenceDate`, `Trigger` (Scheduled or Manual).

### Permissions
- The job runs as the user of its job queue entry. That user needs read and modify rights on the equipment table. A user with only EQM - Reader fails at the first stale row, and the failure is logged. EQM - Reader has execute on the job codeunit.

## Warranty alert job
`GenerateAlerts` reads the non-cancelled alerts whose warranty end date falls in the alert window once, before the equipment loop. The loop checks each equipment and interval against that dictionary, instead of running one lookup per equipment. The alert key is equipment number, warranty end date and interval. The cancellation of stale alerts still runs first. Alerts created and their business events are unchanged.

## Retention policies
### Registered tables
The three tables are added to the allowed tables of the standard Retention Policies framework (Microsoft Learn: [Define retention policies](https://learn.microsoft.com/dynamics365/business-central/admin-data-retention-policies)).

| Table | Filter | Date field | Period on the filter line |
|---|---|---|---|
| EQM Error Log Entry | None | Logged At | Chosen by the administrator |
| EQM Warranty Alert | Locked, enabled: Status = Acknowledged or Cancelled | SystemModifiedAt | Locked: 1 Year |
| EQM Integration Event Entry | Locked, enabled: Processed = true | Processed At | Locked: 3 Months |

- The locked filter lines cannot be removed or changed by the administrator. Open warranty alerts and unprocessed integration event entries are therefore never selected by a policy (checked in the sandbox: RP-SB1).
- Learn: each line has its own period, and when the periods differ for the same data, the longest period is used. So a policy with a shorter period cannot shorten the locked periods of the matching records.
- **Not registered, by decision:** audit entries (`EQM Equipment Audit Entry`), the maintenance log, the maintenance history, equipment notes and equipment assignments. They are the record of what happened and are never selected by a policy.
- **No default policy is created.** Nothing is deleted until an administrator creates and enables a policy.

### How the tables are registered
- Step `UpgradeRetentionPolicyTables` in "EQM Upgrade Mgt." runs from `UpgradePerCompany`, which Install and Upgrade already call. It is guarded by the upgrade tag `MC-EQM-FR054-RetentionPolicyTables-20261120`, so each company runs it once.
- The tag is not pre-registered for new companies (`OnGetPerCompanyUpgradeTags`). Pre-registering it would mark a new company as done, and its tables would never be registered. New companies get the tables at the next install or upgrade. Phase 2 covers new companies without waiting.
- The registration calls are idempotent. The Boolean results are ignored.
- The Install (50104) and Upgrade (50134) codeunit files are unchanged.

### Job user
- Learn: the retention job queue entry must run as a user that can read and delete the data. To define policies, a user needs SUPER or the standard Retention Policy Setup permission set. The app does not assign that set.
- EQM - Administrator can read and delete the error log and integration event entries directly, but on the warranty alert table it has only indirect delete. A retention job for warranty alerts that runs as a non-SUPER EQM - Administrator fails with a permission error on that table. The check is RP-SB4. The permission sets are not changed.
- The help article `docs/help/FR-054-background-processing-optimization.md` gives the setup steps for administrators.

## Scheduling and setup page
- `EnsureMonitoringJobs` now ensures three entries. Existing entries are left as they are, whatever their status.
- Equipment Setup shows "Maintenance Calculation Job" in the Background Monitoring group, visible when Maintenance Planning is on. It shows "Not scheduled" when no entry exists.
- Monitoring Job Queue Entries shows all three entries.

## Translations
New captions, ToolTips and labels are in `app/Translations/` (g, pt-PT and es-ES). Locked labels are not translated. The language-file check of `xlf_sync.py` is part of `repo_checks.py`, which al-docs did not run.

## Design decisions
- **Standard Retention Policies instead of an own archive job.** The user chose Option A. Nothing is copied to an archive. Reversible: removing a table with `RemoveAllowedTable` is possible.
- **Locked filters for open warranty alerts and unprocessed integration entries.** An administrator cannot make a policy delete them.
- **Daily recalculation, not a new schedule table.** The stored date is the only stored maintenance calculation. It goes stale after `Modify(false)` or `Insert(false)`, after an import, or after a partner subscriber changes the calculation.
- **`Modify(false)` for the corrected date.** `SystemModifiedAt` still changes, so API delta sync sees the correction.
- **Collect, then update, with a commit every 1000 corrections.** Row locks are released during a long job, and each update is idempotent.
- **05:00 for the new entry.** It is outside business hours and does not change the existing 06:00 entries.
- **No subscription to `OnRefreshAllowedTables`.** The event is internal in the System Application.

## Known limitations and open points
- **The allowed-table list may be per company** (RP-SB2). A company created after install may not have the three tables until the next install or upgrade.
- **The Refresh action of the allowed tables may remove our tables** (RP-SB3). They come back only at the next upgrade.
- **Job user without permission:** the calculation job fails at the first stale row, and the retention job fails with a permission error. Both are logged or shown in the job queue. See the help article.
- **Possible "changed by another user" error:** a user who edits an equipment card while the job corrects that row can get this error. The window is small: only stale rows, at 05:00.
- **Partner subscribers** receive a record loaded with `SetLoadFields`. Other fields load on demand.
- **Time zone:** 05:00 runs in the job queue time zone.

## Out of scope
- An own archive job or archive tables. Retention Policies delete; nothing is copied.
- Default (pre-created) retention policies. Administrators create them.
- Phase 2: register the tables for companies created after install without waiting for the next upgrade.
- Phase 3: Generate Alerts and demo data actions offered as background jobs.
- Phase 4: a job-duration cue or telemetry.
- Job timeout or priority, and changes to the schedule, attempts or description of the existing entries.

## Related
- Help article: `docs/help/FR-054-background-processing-optimization.md`
- Changelog: `CHANGELOG.md`, entry FR-054
- Plan: `docs/plans/FR-054-background-processing-optimization.md`
- Sandbox checks: `docs/TODO.md`, section "FR-054 sandbox checks"
- Error log: `docs/features/FR-051-error-logging.md`, `docs/help/FR-051-error-logging.md`
- Automatic monitoring: `docs/help/FR-018-automated-background-processing.md`
- Microsoft Learn: [Define retention policies](https://learn.microsoft.com/dynamics365/business-central/admin-data-retention-policies), [Use job queues to schedule tasks](https://learn.microsoft.com/dynamics365/business-central/admin-job-queues-schedule-tasks), [Record.ReadIsolation property](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-readisolation-method)
