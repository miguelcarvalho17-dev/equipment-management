# FR-018 Automated Background Processing

## Purpose
The daily monitoring runs by itself through Business Central job queue entries: one entry creates warranty alerts (FR-016), one checks overdue maintenance (FR-017 rule). The app creates the entries on install, when the setup is first created in a new company, and on demand from Equipment Setup. Equipment Setup shows the state of both entries.

Status: describes the code as implemented (uncommitted changes on branch `feature/FR-018-automated-background-processing`). Build result and review verdict are not part of the documenter input: TODO(verify). **No automated tests (deferred, plan decision Q11; test codeunit 50172 reserved, nothing written). Nothing was run in a sandbox; the checks in "Not verified" are open.** App version stays 29.0.0.0.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Codeunit | 50114 | EQM Maintenance Monitor Job | New, public (`TableNo = "Job Queue Entry"`). `OnRun` calls `CheckOverdueMaintenance(Today(), true)`. No other logic. |
| Codeunit | 50115 | EQM Monitoring Job Mgt. | New, `Access = Internal`. Creates the job queue category and entries, reports their state, opens the entries list, logs telemetry. |
| Codeunit | 50108 | EQM Maintenance Mgt. | New internal procedure `CheckOverdueMaintenance(ReferenceDate, IsScheduled): Integer`. Telemetry EQM0002. |
| Codeunit | 50104 | EQM Install | `OnInstallAppPerCompany` calls `TryEnsureMonitoringJobs` before `CreateDefaultData`. |
| Page | 50103 | EQM Equipment Setup | Group Background Monitoring (two read-only status fields), actions Schedule Monitoring Jobs and Monitoring Job Queue Entries, `AboutText`, search terms. `OnOpenPage` calls `TryEnsureMonitoringJobs` when it creates the setup. |
| Codeunit | 50111 | EQM Warranty Alert Job | Unchanged. Now scheduled by codeunit 50115. |
| PermissionSet | 50100 / 50102 | EQM - Reader / EQM - Administrator | See Permissions. |

## Behavior
**Entries created** (one per codeunit, 50111 and 50114), through the standard `ScheduleRecurrentJobQueueEntryWithRunDateFormula` on table "Job Queue Entry":
- Object type Codeunit, empty record ID, job queue category `EQM` (description "Equipment Management", created when missing).
- Maximum no. of attempts 3, next run date formula `<1D>` (daily), starting time 06:00.
- The code does not set the "Run on ..." flags or the rerun delay; they keep the defaults of the standard procedure. The first run may be the next 06:00 rather than immediately. TODO(verify) (BG-SB2, BG-SB4).
- Description is then set to "Equipment Management: create warranty alerts" or "Equipment Management: check overdue maintenance" and the entry is modified.
- The entry belongs to the user whose session created it (TODO(verify) BG-SB2).

**Never twice.** `JobExists` looks for any entry for the codeunit in the company (any status, category or user). If one exists it is counted as existing and not changed, so manual entries made as described in the FR-016 help are reused, and entries in Error or On Hold are not restarted.

**When entries are created**
| Trigger | Telemetry trigger value | Notes |
|---|---|---|
| App install in a company (`OnInstallAppPerCompany`) | Install | Runs first, before any write of the install. Never fails the install. |
| Equipment Setup opened in a company without setup (Administrator only) | SetupCreated | Runs before the defaults are written. |
| Action Schedule Monitoring Jobs on Equipment Setup | Action | Raises errors normally; shows how many entries were created and how many already existed. |

`TryEnsureMonitoringJobs` (install and first setup) returns false and logs telemetry EQM0004 instead of raising an error when:
- `Database.IsInWriteTransaction()` is true (Reason `WriteTransaction`). In a multi-company install a later company may be skipped this way; opening Equipment Setup does not help there because the setup already exists. Use the action in that company.
- `TaskScheduler.CanCreateTask()` is false (Reason `CannotCreateTask`).
- The isolated `Codeunit.Run` fails (Reason `Error`, with `ErrorCode`).

**Warranty job (50111).** Unchanged: `GenerateAlerts(Today(), true, ...)`, telemetry EQM0001.

**Maintenance job (50114).** Counts Open maintenance records more than 14 days after the Maintenance Date (the FR-017 rule, `CountOverdueMaintenance`) and logs the count. It changes no data, sends no notification and shows no message. The result is visible only in telemetry and the job queue log. `CheckOverdueMaintenance` treats `0D` as today.

**Notifications.** There is no separate notification job. Notifications stay session based (FR-017); background sessions send none.

**Equipment Setup.** Fields "Warranty Alert Job" and "Overdue Maintenance Job" show the Status caption of the entry (Ready, In Process, Error, On Hold, Finished, ...), "Not scheduled" when none exists, or blank when the user cannot read job queue entries. The first entry found is shown. Values are read in `OnAfterGetRecord`. The action Schedule Monitoring Jobs (Process, promoted) is enabled only when the user can write the setup; Monitoring Job Queue Entries (Navigation) opens the standard Job Queue Entries page filtered to the two codeunits.

## Telemetry
All with `DataClassification::SystemMetadata`, no personal data.
| Signal | When | Dimensions |
|---|---|---|
| EQM0002 | Each overdue check (Verbosity Normal) | OverdueCount, OverdueDays, ReferenceDate, Trigger (`JobQueue` or `Manual`) |
| EQM0003 | Entries ensured (Verbosity Normal) | Created, Existing, Trigger |
| EQM0004 | Entries could not be created (Verbosity Warning) | Trigger, Reason, ErrorCode |

## Extending (events)
Published: none. Subscribed: none (standard Job Queue API only). Procedures of codeunit 50115 and `CheckOverdueMaintenance` are internal and not partner API. Codeunit 50114 is public only because the job queue runs it by ID.

### Events report (docs/plans/FR-018-events.md, condensed)
Searched BC 29 Base Application 29.0.54011.57272 symbols (no base app source).
- **No event needed.** The feature only consumes the Job Queue.
- Standard members used: table "Job Queue Entry" (472) `ScheduleRecurrentJobQueueEntryWithRunDateFormula`; table "Job Queue Category" (471, Code[10], Description Text[30], inherent permissions rimx); page "Job Queue Entries" (672); `TaskScheduler.CanCreateTask`. "Object Type to Run" and Status are Option fields.
- Not verifiable in symbols: runtime behavior of the standard procedure, install isolation, recurrence after the last failed attempt (see "Not verified").

## Permissions
| Permission set | Change |
|---|---|
| 50100 EQM - Reader | Execute on codeunits 50114 and 50115. |
| 50102 EQM - Administrator | `tabledata "Job Queue Entry" = rim`. |
| 50101 EQM - Manager | No change. |

Codeunit 50115 has `Permissions = tabledata "Job Queue Entry" = rim` (indirect: it works only together with matching rights in the user's sets). Job Queue Category has inherent permissions. Who may create entries: Administrator (action, first setup) and the installing user. Creating an entry also needs Execute on the target codeunit, which Reader gives. Reader and Manager see the status fields only when they have read access to Job Queue Entry, otherwise blank. Whether the Administrator line is redundant with D365 BASIC: TODO(verify) (BG26, BG-SB6).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build; do not edit by hand. TODO(verify) that locked labels (telemetry IDs, trigger names, formula) are not translation units.

## Upgrade and compatibility
No stored field, no upgrade code. Permanent after release: codeunit ID 50114, job queue category code `EQM`, telemetry IDs EQM0002 to EQM0004. Uninstall does not remove the job queue entries; delete them manually on Job Queue Entries (plan Q8). Entries run as a named user; if that user is disabled or loses rights, the jobs fail (plan R5).

## Known limitations
- The maintenance job only logs a count; it changes no data and notifies nobody.
- Existing entries are never changed or restarted by the app, whatever their status.
- A recurring entry that uses up its 3 attempts may stay in Error and stop running: TODO(verify) (BG-SB5).
- A company skipped during a multi-company install needs the Schedule Monitoring Jobs action.
- Run time is 06:00 in the job session's time zone, which can differ from the users' (see FR-016).
- Two administrators scheduling at the same moment could create a duplicate entry.
- No setup field for the schedule; change it on the Job Queue Entry card.
- No automated tests.

## Not verified
Nothing was run in a Business Central sandbox. Open, all TODO(verify) (from the plan, "Verification still open"):
| Item | Check | Decides |
|---|---|---|
| Behavior of the standard schedule procedure (inserts and enqueues as Ready; which start time, Run-on flags, rerun delay it sets; Description kept) | BG-SB2 (mandatory) | Whether `CreateRecurringJob` stays as is; values for the help article |
| First run time, rerun delay, time zone | BG-SB4 (mandatory) | Help text "first run" |
| Install isolation, multi-company | BG-SB3 multi-company check, BG11 | Help sentence on skipped companies |
| Recurring entry after the last failed attempt | BG-SB5 | Help wording |
| Job Queue Entry line in EQM - Administrator | BG26, BG-SB6 | Keep or drop the line |
| `CanCreateTask` on runtime 18.0, page variables and tooltips, `Session.LogMessage`, images Calendar and JobListSetup | Build (BG-SB1) | Fallbacks in the plan |
| Delegated admin / admin center install | BG-SB3 if possible | Documentation only |
| Copied environments | BG-SB9 | Documentation only |

Also: build result and review verdict were not part of this step. Tests deferred: codeunit 50172 reserved.

## Discrepancies plan vs code
None found for the points checked (schedule values, guards, triggers, permissions, telemetry). The plan was revised to match the code. The code leaves "Run on" flags and rerun delay to the standard defaults, as the revised plan says.
