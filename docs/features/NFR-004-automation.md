# NFR-004 Automation

## Purpose
Requirement: system monitoring processes run fully automated through Business Central Job Queue processing.
Status: **met in code, not verified in a sandbox.** NFR-004 adds no code. It traces the requirement to the objects delivered by FR-018 (see [FR-018](FR-018-automated-background-processing.md)). No AL change, no new object, no permission change, no automated tests. App version stays 29.0.0.0.

## Requirement and where it is met
| Requirement | Where it is met | Object |
|---|---|---|
| Warranty monitoring runs daily without a user starting it | Recurring entry: daily (`<1D>`), starting time 06:00, 3 attempts, category `EQM`, running the warranty alert job | Codeunit 50111 "EQM Warranty Alert Job" |
| Maintenance monitoring runs daily without a user starting it | Same, running the overdue check (`CheckOverdueMaintenance(Today(), true)`) | Codeunit 50114 "EQM Maintenance Monitor Job" |
| No manual start | Entries are created on app install per company (`OnInstallAppPerCompany`), when an Equipment Setup is first created in a company, and by the action Schedule Monitoring Jobs | Codeunit 50104 "EQM Install", codeunit 50115 "EQM Monitoring Job Mgt.", page 50103 "EQM Equipment Setup" |
| Job Queue only, no custom scheduler | Entries are created with the standard `ScheduleRecurrentJobQueueEntryWithRunDateFormula` of table "Job Queue Entry". The app creates no task through `TaskScheduler`; it only calls `TaskScheduler.CanCreateTask()` as a guard | Codeunit 50115 |
| Visibility | Status fields "Warranty Alert Job" and "Overdue Maintenance Job", action Monitoring Job Queue Entries, telemetry EQM0001 to EQM0004 | Page 50103, codeunits 50111, 50108, 50115 |

Details of behavior, permissions and telemetry: see the FR-018 feature doc. Standard Job Queue: [Use job queues to schedule tasks](https://learn.microsoft.com/dynamics365/business-central/admin-job-queue).

## Gaps (open, not fixed; plan decision Q1)
1. **Existing entries are never repaired.** `JobExists` matches any entry for the codeunit whatever its status. An entry On Hold, in Error or Finished counts as existing, so monitoring can stop without an alert. Equipment Setup shows the status; nothing notifies anyone.
2. **Companies skipped at install.** If a write transaction is open (multi-company install), scheduling is skipped (telemetry EQM0004, reason `WriteTransaction`). Those companies get entries only through the action Schedule Monitoring Jobs.
3. **No job for notification generation.** Notifications stay page-triggered (FR-017); background sessions send none. The maintenance job only logs a count.
4. **First run may be the next 06:00**, not immediate. Standard procedure behavior, TODO(verify) (BG-SB4).

## Not verified
Nothing was run in a Business Central sandbox, so "fully automated" is not proven. Acceptance is the FR-018 sandbox checks, listed in `docs/TODO.md` under "NFR-004 sandbox checks": BG-SB1, BG-SB2 (mandatory), BG-SB3, BG-SB4 (mandatory), BG-SB5, BG-SB6, BG-SB8. Build result and review verdict were not part of this step; build skipped because no code changed.

## Discrepancies plan vs code
None. Object IDs, names, schedule values (`<1D>`, 06:00, 3 attempts, category `EQM`), the install, first-setup and action triggers, and the `JobExists` behavior were checked against `app/src` and match.
