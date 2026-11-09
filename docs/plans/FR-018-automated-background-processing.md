# FR-018 Automated Background Processing

> Status: **Approved (default answers).** The user approved the plan with the proposed defaults for Q1-Q4 (and the
> defaults of Q5-Q12 stand). Revised after the symbol lookup in `docs/plans/FR-018-events.md` to match the verified
> Job Queue API; the design is unchanged (see "Revision after event verification").
> Source: GitHub issue #37. Branch: `feature/FR-018-automated-background-processing`.
> **Events: none subscribed, none published.** The standard Job Queue is used as a consumer only: two job codeunits
> with `TableNo = "Job Queue Entry"` and code that creates recurring entries through the public table procedure
> `ScheduleRecurrentJobQueueEntryWithRunDateFormula`. No standard behavior changes.
> Scope: main app only. **Two new codeunits** (50114, 50115) and changes to codeunits 50104 and 50108, page 50103 and
> permission sets 50100 and 50102. **No new table, field, page or enum. No version bump. No upgrade codeunit.** Tests
> deferred (Q11 default): test codeunit 50172 is reserved, and the tester step is skipped.
> Workflow for FR-018: al-event-finder (Job Queue API symbol lookup, done: `docs/plans/FR-018-events.md`) -> planner
> revision (this version) -> plan approved (default answers) -> developer -> reviewer -> build -> tester step SKIPPED
> (Q11) -> documenter -> appsource-validator. The open sandbox checks are listed in "Verification still open".

### Revision after event verification
Aligned with `docs/plans/FR-018-events.md` (symbols of Base Application 29.0.54011.57272). No design change:
- Category description label shortened to **'Equipment Management'** (Job Queue Category Description is Text[30]; the
  old label had 31 characters).
- "Object Type to Run" and Status are **Option** fields (not enums); Status has **7 values** (Ready, In Process, Error,
  On Hold, Finished, On Hold with Inactivity Timeout, Waiting) and is not editable.
- **Job Queue Category permission lines dropped** (table has InherentPermissions rimx). Job Queue Entry indirect `rim`
  stays on codeunit 50115 and EQM - Administrator until BG26 / BG-SB6 decide.
- Entries are created with the public table procedure **`ScheduleRecurrentJobQueueEntryWithRunDateFormula`** (Codeunit,
  ID, empty RecordId, category 'EQM', 3 attempts, formula `<1D>`, 06:00), then `Modify(true)` to set our Description.
  We therefore **do not set** the seven "Run on ..." flags or "Rerun Delay (sec.)" (daily comes from the `<1D>` formula;
  rerun delay stays at the standard default, because the overload that takes a rerun delay is internal). Earliest
  Start Date/Time is set by the standard procedure and may be the next 06:00 rather than immediate.
- `TryEnsureMonitoringJobs` gets a **`Database.IsInWriteTransaction()` guard** (telemetry reason 'WriteTransaction',
  returns false). This covers a multi-company install where a write transaction is already open in later companies;
  companies skipped that way get their entries only through the Schedule Monitoring Jobs action.
- BG-SB2 and BG-SB4 are now **mandatory**; BG-SB3 / BG11 get a multi-company install check.

## Goal
The daily monitoring of equipment runs by itself through Business Central Job Queue Entries: warranty monitoring
(FR-015/FR-016 warranty alerts) and maintenance due date validation (the FR-017 overdue rule) run every day without a
user starting them. The app creates its job queue entries automatically when it is installed in a company and when
the equipment setup is first created in a new company, never twice, and an administrator can re-create missing entries
and see their state from Equipment Setup.

### Requirement restated
- BG-R1 Daily monitoring runs through Job Queue Entries.
- BG-R2 Scheduled tasks: warranty monitoring, maintenance due date validation, notification generation.
- BG-R3 The processes run automatically; users do not have to run monitoring by hand (today an administrator must
  create the FR-016 job queue entry by hand, and without it a manager must choose Generate Alerts).

### What already exists and is reused (no logic is duplicated)
| Already present | Built in | Use in FR-018 |
|---|---|---|
| Codeunit 50111 "EQM Warranty Alert Job" (public, `TableNo = "Job Queue Entry"`, `OnRun` calls `GenerateAlerts(Today(), true, ...)`). Telemetry EQM0001 per run. | FR-016 | **Task 1 "Warranty monitoring", unchanged.** FR-018 only schedules it. Its ID is already documented in FR-016 help for manual entries, so existing manual entries are detected and reused. |
| Warranty Status (Active / Expiring Soon / Expired) calculated on read. | FR-015 | Nothing to process in the background; covered by task 1 through `CalcWarrantyStatus` inside `GenerateAlerts`. |
| Overdue rule: Open maintenance record more than 14 days after its Maintenance Date (`GetMaintenanceOverdueDays`, `SetOverdueMaintenanceFilter`, `CountOverdueMaintenance` in codeunit 50108). | FR-017 | **Task 2 "Maintenance due date validation"** runs this rule daily (Q1). |
| In-client notifications (warranty expiring, overdue maintenance, returned from maintenance) sent from page triggers, guarded by `GuiAllowed()`. | FR-017 | **Task 3 "Notification generation"**: no separate job (Q2). The warranty notifications are generated from the alerts task 1 creates; overdue notifications are generated from the rule task 2 checks. Background sessions cannot show notifications (FR-017, rejected alternative). |
| Install codeunit 50104 (`OnInstallAppPerCompany` -> `CreateDefaultData`). | FR-001 | Also schedules the monitoring jobs (isolated, never fails the install). |
| Equipment Setup page 50103; its `OnOpenPage` creates the defaults in a company without setup (Administrator only). | FR-001, NFR-002 | New-company path also schedules the jobs; new actions and a status group. |
| Permission sets 50100-50102 (Reader X on codeunits; Administrator indirect `ri` on No. Series as the pattern for standard tables written through our code). | NFR-002 | Same pattern for Job Queue Entry. |

### Requirement traceability (default answers)
| Task in the issue | How FR-018 covers it |
|---|---|
| Warranty monitoring | Job queue entry 1 runs codeunit 50111 daily (FR-016 alert generation: cancel stale, create due 90/60/30 alerts). |
| Maintenance due date validation | Job queue entry 2 runs new codeunit 50114 daily: counts overdue maintenance with the FR-017 rule and records the result in telemetry (EQM0002). No data is changed (Q1). |
| Notification generation | The data behind every notification is kept current by entries 1 and 2; FR-017 shows the notifications when users open the pages. No third entry (Q2). |
| Runs automatically | Entries are created by install, by first setup in a new company, or by one administrator action; they recur daily at 06:00 (next run date formula `<1D>`). |

## Approach and rejected alternatives
- Chosen: **one recurring Job Queue Entry per scheduled task (two entries: codeunit 50111 and new codeunit 50114), in
  a job queue category "EQM", created by an internal "ensure" procedure that only adds entries that are missing.** Each
  entry is created by the standard public procedure `ScheduleRecurrentJobQueueEntryWithRunDateFormula` (which inserts
  and enqueues the entry; sandbox-confirmed in BG-SB2), followed by `Modify(true)` for our Description. The ensure
  procedure runs from the install codeunit, from the Equipment Setup page when the setup is first created, and from a
  "Schedule Monitoring Jobs" action. On the automatic paths it runs isolated (`Codeunit.Run` with a return value, only
  when no write transaction is open) so a scheduling failure is logged and never fails the install or blocks the setup
  page. Each task is isolated by the platform: a failing entry gets status Error and a Job Queue Log Entry, the other
  entry is not affected. The shared category makes the platform run the two entries one after the other.
- Rejected: **setting all fields ourselves and running codeunit 453 "Job Queue - Enqueue".** Its insert behavior is not
  verifiable from symbols and Status is not editable; the public procedure sets category, attempts, formula and start
  time in one documented call. `Insert(true)` + `Restart()` remains the fallback only if BG-SB2 fails.
- Rejected: **one combined "daily monitoring" entry that runs all steps.** Step isolation would need `Commit` between
  steps and `Codeunit.Run` with a return value inside the job, plus a custom log (Q3).
- Rejected: **a third job for "notification generation".** A background session cannot show BC notifications
  (FR-017); an email digest needs email accounts, recipients and setup (Q2).
- Rejected: **stored "maintenance alerts" or a maintenance schedule.** New table, page, statuses; separate feature (Q1).
- Rejected: **leaving entry creation to the administrator (FR-016 Q6 default).** Violates BG-R3.
- Rejected: **subscribing to the standard company-initialize event.** Needs an events report and a subscription; the
  setup-page path covers new companies (Q4).
- Rejected: **an upgrade codeunit now.** Nothing is released (version stays 29.0.0.0).
- Rejected: **new setup fields (starting time, enable flags per task).** The schedule is edited on the standard Job
  Queue Entry card (Q5).
- Rejected: **published events.** Permanent public API for no stated need (Q10).
- Rejected: **changing codeunit 50111.** It already does task 1 and is the documented ID for manual entries.

## Objects
IDs in use (checked in `app/src` on this branch before FR-018): tables 50100-50107, pages 50100-50120, codeunits
50103-50113, queries 50100-50103, enums 50100-50106, page extension 50100, permission sets 50100-50102, permission set
extension 50103. Test app: no objects; test codeunits 50150-50171 are reserved by FR-001 to FR-017, none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Codeunit | 50114 | EQM Maintenance Monitor Job | New | Public, `TableNo = "Job Queue Entry"`; `OnRun` runs the daily overdue maintenance check |
| Codeunit | 50115 | EQM Monitoring Job Mgt. | New | Internal: ensure (create missing) job queue entries and category, isolated try with write-transaction guard, status text, show entries, telemetry |
| Codeunit | 50104 | EQM Install | Modify (own) | Schedules the monitoring jobs (isolated) before creating default data |
| Codeunit | 50108 | EQM Maintenance Mgt. | Modify (own) | New internal `CheckOverdueMaintenance` with telemetry EQM0002 |
| Page | 50103 | EQM Equipment Setup | Modify (own) | Group "Background Monitoring" (two status fields), actions Schedule Monitoring Jobs and Monitoring Job Queue Entries, schedule on first setup creation |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | X on codeunits 50114, 50115 |
| PermissionSet | 50102 | EQM - Administrator | Modify (own) | Indirect `rim` on Job Queue Entry only (no Job Queue Category line: InherentPermissions rimx) |

Not changed: all tables; pages other than 50103; codeunits 50103, 50105-50107, 50109-50113 (**50111 unchanged**);
queries; enums; page extension 50100; permission sets 50101 and extension 50103; the profile; `app/app.json`; `test/`.

New files (namespace `MiguelCarvalho.EquipmentManagement`), in a new feature folder `app/src/Monitoring/`:
`EQMMaintenanceMonitorJob.Codeunit.al`, `EQMMonitoringJobMgt.Codeunit.al`.

Next free IDs after FR-018: tables 50108, pages 50121, codeunits 50116, queries 50104, enums 50107, page extensions
50101, permission sets 50104. Test app: **test codeunit 50172 reserved for FR-018 "EQM Background Processing
Tests"**, not built now (Q11).

### Verified platform names (from `docs/plans/FR-018-events.md`)
- Table 472 "Job Queue Entry" (namespace `System.Threading`): fields used `ID` (Guid, PK), "Object Type to Run"
  (**Option**, member `Codeunit`; write `JobQueueEntry."Object Type to Run"::Codeunit`), "Object ID to Run" (Integer),
  Description (Text[250]), Status (**Option, 7 values**, not editable), "Job Queue Category Code" (Code[10]). No
  InherentPermissions. Public procedure `ScheduleRecurrentJobQueueEntryWithRunDateFormula(ObjType: Option; ObjID:
  Integer; RecId: RecordId; JobQueueCategoryCode: Code[10]; MaxAttemptsToRun: Integer; NextRunDateFormula:
  DateFormula; StartingTime: Time)`; the overloads with RerunDelay or JobTimeout are internal and not usable.
- Table 471 "Job Queue Category": `Code` Code[10], `Description` **Text[30]**, InherentPermissions **rimx**.
- Page 672 "Job Queue Entries" (List on table 472).
- `Format(JobQueueEntry.Status)` returns the translated OptionCaption.

### Still open (not verifiable in symbols; developer at build, or sandbox)
- V2 Behavior of `ScheduleRecurrentJobQueueEntryWithRunDateFormula`: that it inserts and enqueues (Ready), which
  Earliest Start Date/Time, Run-on flags, Rerun Delay and No. of Minutes between Runs it sets, and that our
  `Modify(true)` Description is kept. **BG-SB2 and BG-SB4 (mandatory).** Fallback if it fails: stop and report; the
  alternative `Insert(true)` + `Restart()` needs a plan update.
- V5 `TaskScheduler.CanCreateTask()` compiles on runtime 18.0. **Fallback:** drop that guard.
- V6 What a recurring entry does after its last failed attempt (BG-SB5, R2).
- V7 `Codeunit.Run` isolation in `OnInstallAppPerCompany` and the multi-company install transaction (BG-SB3, BG11).
- V8 Delegated admin / admin center install behavior (documentation, R1).
- V9 Whether the Administrator `rim` line on Job Queue Entry is redundant with D365 BASIC (BG26, BG-SB6).
- V10 Text page variables in a Card group with `Editable = false` and page-level ToolTip compile without UICop warnings.
- V12 `Session.LogMessage` with `Dictionary of [Text, Text]` compiles without warnings.
- V13 Images `Calendar` and `JobListSetup` exist; **fallback:** remove the `Image` property.

### Codeunit 50114 "EQM Maintenance Monitor Job" (new)
`TableNo = "Job Queue Entry"`, default access (Public, same reason as 50111: the job queue runs it by ID), no
procedures. `using System.Threading;`. XML summary: "Runs from a job queue entry and checks every day which
maintenance records are overdue. Schedule it once a day; Equipment Setup does this automatically."
`OnRun`: local `MaintenanceMgt: Codeunit "EQM Maintenance Mgt."`; call `MaintenanceMgt.CheckOverdueMaintenance(Today(),
true)` (discard the result). Nothing else: no `Message`, `Confirm`, `Commit`, `Error`; the Job Queue Entry record is
not read or changed. An error inside (for example a permission error) is not caught: the job queue records it.

### Codeunit 50108 "EQM Maintenance Mgt." (change)
New internal procedure after `ShowOverdueMaintenanceRecords`, with XML doc comment:
`CheckOverdueMaintenance(ReferenceDate: Date; IsScheduled: Boolean): Integer`
1. When ReferenceDate = 0D: ReferenceDate := `Today()`.
2. OverdueCount := `CountOverdueMaintenance(ReferenceDate)` (existing FR-017 rule; no new filter logic).
3. Telemetry: dictionary with `OverdueCount` = `Format(OverdueCount, 0, 9)`, `OverdueDays` =
   `Format(GetMaintenanceOverdueDays(), 0, 9)`, `ReferenceDate` = `Format(ReferenceDate, 0, 9)`, `Trigger` =
   'JobQueue' or 'Manual'; `Session.LogMessage(OverdueCheckedTelemetryTok, OverdueCheckedTelemetryMsg,
   Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions)`.
4. `exit(OverdueCount)`.
Doc: "Checks how many maintenance records are overdue on the reference date and logs the result to telemetry. Changes
no data. 0D means today."
New labels on codeunit 50108, all `Locked = true`: `OverdueCheckedTelemetryTok` = 'EQM0002',
`OverdueCheckedTelemetryMsg` = 'Overdue maintenance checked.', `ScheduledTok` = 'JobQueue', `ManualTok` = 'Manual',
dimension names `OverdueCountDimTok` = 'OverdueCount', `OverdueDaysDimTok` = 'OverdueDays', `ReferenceDateDimTok` =
'ReferenceDate', `TriggerDimTok` = 'Trigger'. Put the telemetry in a `local procedure LogOverdueCheckTelemetry(...)`
like `LogGenerationTelemetry` in codeunit 50110. No equipment or record numbers in telemetry. No other change to 50108.

### Codeunit 50115 "EQM Monitoring Job Mgt." (new)
`Access = Internal`. `using System.Threading;`.
`Permissions = tabledata "Job Queue Entry" = rim;` (indirect; no Job Queue Category line because that table has
InherentPermissions rimx). Comment above the object: indirect only, EQM - Administrator gives the matching indirect
right, the category table has inherent permissions, creating an entry also needs Execute on the target codeunit (EQM -
Reader gives X), still needs a sandbox check.
XML summary: "Creates the job queue entries that run the equipment monitoring every day, and shows their state."
All procedures `internal` unless stated `local`, each internal one with an XML doc comment. No `Message`, `Confirm` or
`Commit`.

Global variables: `CallerTrigger: Text`.

Labels:
| Name | Text | Comment / Locked |
|---|---|---|
| `JobQueueCategoryCodeTok` | `EQM` | Locked |
| `JobQueueCategoryDescTxt` | `Equipment Management` | `MaxLength = 30` (Job Queue Category Description is Text[30]) |
| `WarrantyJobDescTxt` | `Equipment Management: create warranty alerts` | `MaxLength = 250` |
| `MaintenanceJobDescTxt` | `Equipment Management: check overdue maintenance` | `MaxLength = 250` |
| `NotScheduledTxt` | `Not scheduled` | Comment: 'Shown on Equipment Setup when no job queue entry exists for the monitoring job.' |
| `DailyFormulaTok` | `<1D>` | Locked |
| `JobsScheduledTelemetryTok` | `EQM0003` | Locked |
| `JobsScheduledTelemetryMsg` | `Monitoring job queue entries ensured.` | Locked |
| `JobsNotScheduledTelemetryTok` | `EQM0004` | Locked |
| `JobsNotScheduledTelemetryMsg` | `Monitoring job queue entries could not be created.` | Locked |
| `InstallTriggerTok` | `Install` | Locked |
| `SetupTriggerTok` | `SetupCreated` | Locked |
| `ActionTriggerTok` | `Action` | Locked |
| dimension names | `Created`, `Existing`, `Trigger`, `Reason`, `ErrorCode` | Locked |
| `WriteTransactionReasonTok` | `WriteTransaction` | Locked |
| `CannotCreateTaskReasonTok` | `CannotCreateTask` | Locked |
| `ErrorReasonTok` | `Error` | Locked |

Procedures:
1. `trigger OnRun()` - local CreatedCount, ExistingCount; `EnsureMonitoringJobs(CreatedCount, ExistingCount,
   CallerTrigger)`. (Used only by `TryEnsureMonitoringJobs` for isolation.)
2. `GetInstallTrigger(): Text`, `GetSetupTrigger(): Text`, `GetActionTrigger(): Text` - return the three locked
   tokens (callers do not hard-code text).
3. `SetCallerTrigger(TriggerTok: Text)` - sets the global.
4. `TryEnsureMonitoringJobs(TriggerTok: Text): Boolean` - for automatic paths. In order:
   1. **When `Database.IsInWriteTransaction()`: `LogNotScheduled(TriggerTok, WriteTransactionReasonTok, '')`,
      exit(false).** `Codeunit.Run` with a return value is not allowed inside an open write transaction; this happens
      for example when the install runs for several companies in one transaction. Companies skipped this way get their
      entries only through the Schedule Monitoring Jobs action (opening Equipment Setup does not schedule because the
      setup already exists after install).
   2. When `not TaskScheduler.CanCreateTask()` (V5): `LogNotScheduled(TriggerTok, CannotCreateTaskReasonTok, '')`,
      exit(false).
   3. Local `MonitoringJobMgt: Codeunit "EQM Monitoring Job Mgt."`; `MonitoringJobMgt.SetCallerTrigger(TriggerTok)`;
      `ClearLastError()`; when `MonitoringJobMgt.Run()` returns true: exit(true).
   4. Otherwise `LogNotScheduled(TriggerTok, ErrorReasonTok, GetLastErrorCode())`; exit(false).
   Doc: "Creates the missing monitoring job queue entries without raising an error. Returns false and logs telemetry
   when they cannot be created, for example when a write transaction is already open or the user cannot schedule
   tasks."
5. `EnsureMonitoringJobs(var CreatedCount: Integer; var ExistingCount: Integer; TriggerTok: Text)` - raises errors
   (used by the action and by OnRun). In order:
   1. CreatedCount := 0; ExistingCount := 0.
   2. `EnsureJobQueueCategory()`.
   3. `EnsureJob(Codeunit::"EQM Warranty Alert Job", WarrantyJobDescTxt, CreatedCount, ExistingCount)`.
   4. `EnsureJob(Codeunit::"EQM Maintenance Monitor Job", MaintenanceJobDescTxt, CreatedCount, ExistingCount)`.
   5. `LogScheduled(TriggerTok, CreatedCount, ExistingCount)`.
   Doc: "Creates a daily recurring job queue entry for each monitoring job that has no entry in this company yet.
   Existing entries are never changed, whatever their status."
6. `local EnsureJob(CodeunitId: Integer; JobDescription: Text; var CreatedCount; var ExistingCount)` - when
   `JobExists(CodeunitId)`: ExistingCount += 1; else `CreateRecurringJob(CodeunitId, JobDescription)`; CreatedCount += 1.
7. `JobExists(CodeunitId: Integer): Boolean` - `SetJobFilter(JobQueueEntry, CodeunitId)`; `exit(not IsEmpty())`.
   **Any status, any category, any user** counts, so manual entries (FR-016 help) are reused, and entries On Hold or
   in Error are not duplicated.
8. `local SetJobFilter(var JobQueueEntry; CodeunitId: Integer)` - `SetRange("Object Type to Run",
   JobQueueEntry."Object Type to Run"::Codeunit)` (Option), `SetRange("Object ID to Run", CodeunitId)`.
9. `local CreateRecurringJob(CodeunitId: Integer; JobDescription: Text)` - the only place that decides how an entry is
   created (comment saying so, and that it needs the BG-SB2 check):
   1. `Evaluate(DailyFormula, DailyFormulaTok)` into a local DateFormula.
   2. `JobQueueEntry.ScheduleRecurrentJobQueueEntryWithRunDateFormula(JobQueueEntry."Object Type to Run"::Codeunit,
      CodeunitId, NoRecordId, GetJobQueueCategoryCode(), 3, DailyFormula, 060000T)` with a local empty `RecordId`.
      The standard procedure inserts the entry and makes it Ready; it sets "Recurring Job", "Next Run Date Formula",
      "Starting Time", "Maximum No. of Attempts to Run", category and Earliest Start Date/Time.
   3. `JobQueueEntry.Description := CopyStr(JobDescription, 1, MaxStrLen(JobQueueEntry.Description))`;
      `JobQueueEntry.Modify(true)`.
   **Not set by us:** the seven "Run on ..." flags (daily comes from the `<1D>` formula), "Rerun Delay (sec.)" (table
   default; the overload that takes it is internal), "No. of Minutes between Runs", "User ID", Status. Earliest Start
   Date/Time is whatever the standard procedure computes (may be the next 06:00, not immediate). BG-SB2/BG-SB4 record
   the actual values.
10. `local EnsureJobQueueCategory()` - when `not JobQueueCategory.Get(GetJobQueueCategoryCode())`: `Init()`, Code,
    Description := `CopyStr(JobQueueCategoryDescTxt, 1, MaxStrLen(JobQueueCategory.Description))`, `Insert(true)`. An
    existing category is not modified.
11. `local GetJobQueueCategoryCode(): Code[10]` - `CopyStr(JobQueueCategoryCodeTok, 1, 10)`.
12. `GetJobStatusText(CodeunitId: Integer): Text` - when `not JobQueueEntry.ReadPermission()`: exit(''). `SetJobFilter`;
    `SetLoadFields(Status)`; when `FindFirst()`: exit(`Format(JobQueueEntry.Status)`) (any of the 7 option captions);
    else exit(`NotScheduledTxt`). When several entries exist, the first is shown (accepted).
13. `ShowMonitoringJobs()` - Job Queue Entry `SetRange("Object Type to Run", ...::Codeunit)`; `SetFilter("Object ID to
    Run", '%1|%2', Codeunit::"EQM Warranty Alert Job", Codeunit::"EQM Maintenance Monitor Job")`;
    `Page.Run(Page::"Job Queue Entries", JobQueueEntry)`.
14. `local LogScheduled(TriggerTok: Text; CreatedCount: Integer; ExistingCount: Integer)` and `local
    LogNotScheduled(TriggerTok: Text; ReasonTok: Text; ErrorCode: Text)` - `Session.LogMessage` with
    `Verbosity::Normal` (Scheduled) / `Verbosity::Warning` (NotScheduled), `DataClassification::SystemMetadata`,
    `TelemetryScope::All`; dimensions Created, Existing, Trigger (Scheduled) or Trigger, Reason, ErrorCode
    (NotScheduled). Reason is one of WriteTransaction, CannotCreateTask, Error. **Never log `GetLastErrorText()`**.

### Codeunit 50104 "EQM Install" (change)
`OnInstallAppPerCompany`: add local `MonitoringJobMgt: Codeunit "EQM Monitoring Job Mgt."`. **First** call
`MonitoringJobMgt.TryEnsureMonitoringJobs(MonitoringJobMgt.GetInstallTrigger())` (result ignored; it logs itself),
**then** the existing `DefaultData.CreateDefaultData()`. The order matters: the isolated `Codeunit.Run` must run before
any write in the transaction (comment says so). In a multi-company install, later companies may already be inside a
write transaction; the guard in `TryEnsureMonitoringJobs` then skips them (EQM0004, Reason WriteTransaction) and the
install continues. No UI, no `Commit`. Reinstalling the app (data kept) runs it again and creates only missing entries.

### Page 50103 "EQM Equipment Setup" (change)
- Variables: `MonitoringJobMgt: Codeunit "EQM Monitoring Job Mgt."`, `CanManage: Boolean`, `WarrantyJobStatus: Text`,
  `MaintenanceJobStatus: Text`, label `JobsScheduledMsg: Label '%1 monitoring job queue entries were created. %2
  already existed and were not changed.', Comment = '%1 = number of job queue entries created, %2 = number of job
  queue entries that already existed'`.
- Layout: after group `Numbering`, new `group(BackgroundMonitoring)` Caption 'Background Monitoring' with:
  - `field(WarrantyJobStatus; WarrantyJobStatus)` Caption 'Warranty Alert Job', `Editable = false`, ToolTip 'Specifies
    the status of the job queue entry that creates warranty alerts every day. Not scheduled means that no entry exists;
    choose Schedule Monitoring Jobs to create it.'
  - `field(MaintenanceJobStatus; MaintenanceJobStatus)` Caption 'Overdue Maintenance Job', `Editable = false`, ToolTip
    'Specifies the status of the job queue entry that checks overdue maintenance every day. Not scheduled means that no
    entry exists; choose Schedule Monitoring Jobs to create it.'
- Actions (after layout, before `var`, AL0926):
  - `area(Processing)`: `action(ScheduleMonitoringJobs)` Caption 'Schedule Monitoring Jobs', ToolTip 'Create the job
    queue entries that run the equipment monitoring every day, if they do not exist. Existing entries are not
    changed.', Image `Calendar` (V13), `Enabled = CanManage`. OnAction: local counts;
    `MonitoringJobMgt.EnsureMonitoringJobs(Created, Existing, MonitoringJobMgt.GetActionTrigger())`;
    `Message(JobsScheduledMsg, Created, Existing)`; `UpdateJobStatus()`; `CurrPage.Update(false)`.
  - `area(Navigation)`: `action(MonitoringJobQueueEntries)` Caption 'Monitoring Job Queue Entries', ToolTip 'View the
    job queue entries that run the equipment monitoring, to see when they ran, change the time or restart them.',
    Image `JobListSetup` (V13). OnAction: `MonitoringJobMgt.ShowMonitoringJobs()`.
  - `area(Promoted)`: `group(Category_Process)` Caption 'Process' with `actionref(ScheduleMonitoringJobs_Promoted;
    ScheduleMonitoringJobs)`.
- `OnOpenPage` (change, keep existing behavior): inside the existing `if not Rec.Get() then begin ... end` branch,
  after the `WritePermission` check and **before** `DefaultData.CreateDefaultData()`, call
  `MonitoringJobMgt.TryEnsureMonitoringJobs(MonitoringJobMgt.GetSetupTrigger())` (no write has happened yet in this
  branch). After the branch: `CanManage := Rec.WritePermission()` (the existing `CurrPage.Editable := false` stays).
  Opening the page when the setup already exists schedules nothing.
- New trigger `OnAfterGetRecord`: `UpdateJobStatus()`.
- `local procedure UpdateJobStatus()`: WarrantyJobStatus := `MonitoringJobMgt.GetJobStatusText(Codeunit::"EQM
  Warranty Alert Job")`; MaintenanceJobStatus := same for `Codeunit::"EQM Maintenance Monitor Job"`.
- `AdditionalSearchTerms` becomes 'equipment numbers, equipment number series, maintenance number series, equipment job
  queue, equipment monitoring'. Add `AboutTitle = 'About equipment setup'` and `AboutText = 'Set the number series for
  equipment and maintenance records. The app runs its monitoring every day through job queue entries: one creates
  warranty alerts, one checks overdue maintenance. They are created automatically; if one is missing, choose
  **Schedule Monitoring Jobs**.'`

### app.json, translations
- **app.json: no change.** Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf`; commit it. Locked labels (telemetry, tokens,
  category code, date formula) must not appear as translatable units.

## Data model and upgrade impact
- No new table or field in this app. Data written to **standard** tables, per company: one Job Queue Category "EQM"
  (Description 'Equipment Management') and up to two Job Queue Entries (customer data owned by the customer once
  created; administrators may change time, user, run days or status, or delete them).
- DataClassification: nothing new in this app. Telemetry (EQM0002-EQM0004) is `SystemMetadata` with counts, dates,
  trigger names, reason tokens and error codes only.
- Upgrade codeunit: **not needed** (nothing released, version unchanged). **From the first release on**, a version that
  adds a new monitoring job must call `TryEnsureMonitoringJobs` from an upgrade codeunit guarded by an upgrade tag (add
  to `docs/TODO.md`).
- Existing development installs: republishing the same version does not rerun install code, so entries are created by
  the Schedule Monitoring Jobs action (BG-SB2).
- Volume: two runs a day per company, each a filtered read (warranty: 91-day window, FR-016; maintenance: one `Count`
  on key `StatusDate`).

## Events
**Standard events: none subscribed, none needed** (confirmed by `docs/plans/FR-018-events.md`, confidence high for
names and signatures, medium for runtime behavior). The job codeunits are run by the job queue through `TableNo = "Job
Queue Entry"`. Entry creation uses the public table procedure `ScheduleRecurrentJobQueueEntryWithRunDateFormula` on
table 472; the Enqueue events of codeunit 453 are not used. Scheduling in companies created later relies on the
Equipment Setup path (Q4).

Published: **none** (Q10). Existing events are unchanged.

## Permissions
| Permission set | Change |
|---|---|
| 50100 EQM - Reader | Add `codeunit "EQM Maintenance Monitor Job" = X`, `codeunit "EQM Monitoring Job Mgt." = X` at the end of the codeunit block. |
| 50101 EQM - Manager | No change (includes Reader; RIM on warranty alerts already). |
| 50102 EQM - Administrator | Add `tabledata "Job Queue Entry" = rim` (indirect, next to the No. Series lines; `using System.Threading;`). **No Job Queue Category line** (InherentPermissions rimx). Keep the Job Queue Entry line until BG26 / BG-SB6 show whether D365 BASIC makes it redundant. |
| 50103 EQM D365 BASIC (ext) | No change. |

Creating an entry also needs Execute on the target codeunit (the table checks required permissions): EQM -
Administrator includes EQM - Manager, which includes EQM - Reader with X on 50111 and 50114.

Who runs what (each entry runs as its "User ID", the user who created or last set it to Ready):
| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See Background Monitoring status on Equipment Setup | yes (blank when no read on Job Queue Entry) | yes | yes |
| Schedule Monitoring Jobs action | no (disabled) | no (disabled) | yes |
| Monitoring Job Queue Entries action | opens; standard page rights apply | same | same |
| Be the user of the warranty job (needs RIM on alerts) | no (job fails, Error) | yes | yes |
| Be the user of the maintenance job (read only) | yes | yes | yes |

At install the entries run as the installing user (normally an administrator with SUPER). If that user is later
removed or loses rights, the jobs fail; the help explains how to set another user (Q7).

## Compatibility
- AppSource mode, development phase: nothing is released, no Obsolete handling needed.
- New permanent identifiers after the first release: codeunit **50114** (public, `OnRun` only; its ID is stored in
  customers' job queue entries and must never change), job queue category code **EQM**, telemetry IDs EQM0002-EQM0004
  (EQM0004 reasons WriteTransaction, CannotCreateTask, Error). Codeunit 50111 is unchanged. Codeunit 50115 and the new
  50108 procedure are internal.
- Only public standard API is used (table 472 fields and `ScheduleRecurrentJobQueueEntryWithRunDateFormula`, table 471,
  page 672). The defaults the standard procedure applies (run days, rerun delay, earliest start) are not ours and could
  change in a later base app version (R10).
- AppSource install rules: install code has no UI, is idempotent (reinstall and multiple companies create no
  duplicates), and does not fail the install when scheduling is impossible (write-transaction guard, CanCreateTask
  guard, isolated run).
- No uninstall hook exists in AL: after uninstall, the two entries stay and fail because their codeunits are gone. The
  help tells administrators to delete the entries of category EQM before uninstalling (Q8).
- Sandboxes copied from production: the platform's handling of job queue entries in copied environments applies (record
  in BG-SB9); nothing app-specific.
- Behavior changes: install now creates job queue entries; opening Equipment Setup in a company without setup also
  creates them. The FR-016 Generate Alerts action stays (optional manual run). No existing rule, field or text changes.
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-018-automated-background-processing.md` and `docs/help/FR-018-automated-background-processing.md`:
    the two jobs and what each does, the traceability table, when entries are created, schedule (daily at 06:00 via
    next run date formula 1D, 3 attempts; first run at the Earliest Start Date/Time shown on the entry, possibly the
    next 06:00), that in a multi-company install some companies may have no entries and need **Schedule Monitoring
    Jobs**, how to change time or user, how to restart an entry in Error, the status fields, delete before uninstall,
    permissions. Values not yet confirmed in BG-SB2/BG-SB4 are written as "not verified yet".
  - `docs/help/FR-016-warranty-alerts.md` section "Set up the daily job" and the matching `docs/features/` section:
    replace "It is not created automatically" and the manual steps with "created automatically (FR-018); use Schedule
    Monitoring Jobs if missing". `docs/help/FR-017-equipment-notifications.md`: one sentence that the data behind the
    notifications is refreshed daily.
  - `README.md` V2 progress: add background monitoring as built, not verified.
  - `CHANGELOG.md`: new top section `## FR-018 Automated Background Processing (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-018 sandbox checks" with the list in "Verification still open", and the
    upgrade-codeunit rule above.

## Test scenarios
**No automated tests in this iteration** (Q11 default, as in FR-003 to FR-017). Test codeunit 50172 "EQM Background
Processing Tests" is reserved, and the tester step is skipped. The list is the reference for the developer, the
reviewer and the tests written later (needs the test-app fix in `docs/TODO.md` and `internalsVisibleTo`). Automated
tests would delete the company's Job Queue Entries for codeunits 50111/50114 and category EQM in setup, and must not
depend on the job queue actually running (call the job codeunits directly with a Job Queue Entry record).

"Entry(X)" means a Job Queue Entry with Object Type to Run = Codeunit and Object ID to Run = X in the current company.
T = `Today()`.

Ensure
- BG1 Given no Entry(50111), no Entry(50114) and no category EQM, when `EnsureMonitoringJobs` runs, then category EQM
  exists with Description 'Equipment Management', and exactly one Entry(50111) and one Entry(50114) exist, each with
  category EQM, Recurring Job = true, Next Run Date Formula = 1D, Starting Time 06:00, Maximum No. of Attempts to Run
  = 3, Description = our label (not overwritten by the standard procedure), Status Ready, Earliest Start Date/Time
  filled; Created = 2, Existing = 0. The Run-on flags, Rerun Delay (sec.) and No. of Minutes between Runs are not
  asserted (set by the standard procedure; recorded in BG-SB2).
- BG2 (no duplicates) Given BG1 done, when it runs again, then still exactly one entry each; Created = 0, Existing = 2;
  no field of the entries changed.
- BG3 (manual entry reused) Given an Entry(50111) created by hand with no category, Status On Hold, Starting Time
  08:00, when ensure runs, then only Entry(50114) is created; the manual entry keeps its status, category and time;
  Created = 1, Existing = 1.
- BG4 (Error left alone) Given Entry(50114) with Status Error, when ensure runs, then it is not changed and no second
  Entry(50114) is created.
- BG5 Given category EQM exists with another description, when ensure runs, then the category is not modified.
- BG6 (negative) Given an entry with Object Type Report and Object ID 50111, then it does not count; Entry(50111) is
  created.
- BG7 (per company) Given entries exist in company A only, when ensure runs in company B, then both entries are
  created in B; A is unchanged.
- BG8 (try, no rights) Given a user who cannot create job queue entries (Reader only), when
  `TryEnsureMonitoringJobs` runs, then it returns false, no entry exists, no error is raised, and EQM0004 is logged with
  Reason Error (or CannotCreateTask).
- BG8a (try, write transaction open) Given a write transaction is already open (a record was inserted or modified
  earlier in the same transaction), when `TryEnsureMonitoringJobs` runs, then it returns false, no entry is created,
  no error is raised, and EQM0004 is logged with Reason WriteTransaction and an empty ErrorCode.
- BG9 (try, ok) Given an Administrator and no open write transaction, when `TryEnsureMonitoringJobs` runs, then it
  returns true and BG1 holds; EQM0003 is logged with Created 2, Trigger as passed.

Install and setup page
- BG10 Given a fresh company, when the app is installed, then both entries exist and the default setup, number series
  and categories exist (FR-001 behavior unchanged).
- BG11 (install does not fail) Given scheduling is impossible during install (the installing user cannot create
  tasks, or a write transaction is already open for this company), when the app is installed, then the install
  succeeds, the defaults exist and no entry exists; EQM0004 is logged with the matching Reason. **Multi-company
  variant:** given an environment with two or more companies, when the app is installed, then the install succeeds in
  all companies, the defaults exist in all of them, and each company has either both entries (EQM0003) or none
  (EQM0004 Reason WriteTransaction); never one entry or a duplicate.
- BG12 (reinstall) Given the app was installed and an administrator deleted Entry(50114), when the app is reinstalled,
  then Entry(50114) is created again and Entry(50111) is not duplicated.
- BG13 Given a company without setup, when an Administrator opens Equipment Setup, then the setup is created (existing
  behavior) and both entries are created.
- BG14 (negative) Given a company without setup, when a Reader or Manager opens Equipment Setup, then the existing
  setup-missing error appears and no entry is created.
- BG15 (negative) Given the setup exists and no entries exist, when anyone opens Equipment Setup, then no entry is
  created (opening never schedules; the status fields show "Not scheduled"). This is the state of a company skipped by
  the multi-company install guard; Schedule Monitoring Jobs (BG16) fixes it.
- BG16 Schedule Monitoring Jobs as Administrator with no entries: message "2 monitoring job queue entries were created.
  0 already existed and were not changed." (`[MessageHandler]`), status fields show the Ready caption. Again: "0 ... 2
  ...".
- BG17 (negative) For Reader and Manager, Schedule Monitoring Jobs is disabled.
- BG18 Monitoring Job Queue Entries opens the standard Job Queue Entries page showing exactly Entry(50111) and
  Entry(50114) (also manual ones without category).
- BG19 Status fields: no entry -> "Not scheduled"; entry On Hold -> On Hold caption; entry with any other of the 7
  status values -> that caption; Reader without read on Job Queue Entry -> blank, no error.

Jobs
- BG20 Given Open maintenance records dated T - 15 and T - 40, one Open dated T - 14 and one Posted dated T - 40, when
  `CheckOverdueMaintenance(T, false)` runs, then it returns 2, no record is modified, and EQM0002 is logged with
  OverdueCount 2, OverdueDays 14, Trigger Manual.
- BG21 `CheckOverdueMaintenance(0D, ...)` returns the same as with `Today()`.
- BG22 When codeunit 50114 is run with a Job Queue Entry record, then no UI appears, no data changes, and EQM0002 is
  logged with Trigger JobQueue.
- BG23 (regression) Codeunit 50111 run with a Job Queue Entry record still behaves as FR-016 WA26.
- BG24 (isolation) Given Entry(50111) runs as a user with only EQM - Reader (no Insert on warranty alerts), when both
  entries run, then Entry(50111) ends in Error with a Job Queue Log Entry, and Entry(50114) runs successfully and stays
  Ready for the next day.
- BG25 (no notifications in background) Running either job sends no notification and raises no error from FR-017 code
  (FR-017 NT38).

Permissions (`TestPermissions = Restrictive`)
- BG26 Administrator (not SUPER, with D365 BASIC + EQM - Administrator): Schedule Monitoring Jobs works with no
  permission error (indirect rights through codeunit 50115; category through inherent permissions). Then repeat
  without the Job Queue Entry line in EQM - Administrator to decide whether it is redundant (V9).
- BG27 Manager as job user: both jobs run with no permission error. Reader as job user: 50114 runs; 50111 fails on
  table 50107 (expected, BG24).

### Manual sandbox checks (for the user)
- BG-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` contains the new captions,
  ToolTips, messages, job descriptions and the category description, and no locked labels.
- **BG-SB2 (mandatory)** In the existing development company (app already installed): Equipment Setup shows "Not
  scheduled" twice; Schedule Monitoring Jobs creates both entries; status shows Ready; the message counts are right; a
  second click creates nothing. Open each entry and **record the actual values** of: Status, Earliest Start
  Date/Time, Recurring Job, Next Run Date Formula, Starting Time, the seven Run on ... flags, No. of Minutes between
  Runs, Maximum No. of Attempts to Run, Rerun Delay (sec.), Job Queue Category Code, User ID, and confirm that
  **Description is our label** (kept after `Modify(true)`). If the entry is not Ready, not recurring daily, or the
  Description is lost: stop and report (fallback needs a plan update).
- **BG-SB3** Install the app in a new sandbox (or uninstall with data kept and reinstall): both entries and category
  EQM exist, no duplicates. **Multi-company check:** in an environment with at least two companies (for example
  CRONUS plus a second company), install and record per company whether both entries exist or none (EQM0004 Reason
  WriteTransaction in telemetry if configured); the install must succeed in all companies. In each company without
  entries, Schedule Monitoring Jobs must create them. Record the result for the help article.
- **BG-SB4 (mandatory)** Record when the entries first run (at the Earliest Start Date/Time from BG-SB2: immediately or
  the next 06:00), the Earliest Start Date/Time after a run (expected next day 06:00), the Rerun Delay actually used
  after a failure, and the time zone used (R3).
- BG-SB5 Make the warranty job fail (job user without warranty alert insert): the entry shows Error with a log entry,
  the maintenance entry still runs; record what happens the next day to the failed recurring entry (V6, R2); restart it
  from the Job Queue Entries page.
- BG-SB6 Create a new company, open Equipment Setup as a non-SUPER Administrator: setup and both entries are created,
  no permission error (V9).
- BG-SB7 Non-SUPER Reader and Manager on Equipment Setup: status fields readable or blank, Schedule action disabled, no
  error.
- BG-SB8 Telemetry (if configured): EQM0002 once per maintenance run, EQM0001 once per warranty run, EQM0003/EQM0004 on
  scheduling (with Reason).
- BG-SB9 Copy production to a sandbox: record the status of the EQM entries in the copy.
- BG-SB10 Teaching tip and Tell Me ("equipment job queue") on Equipment Setup.

### Verification still open (must be recorded before the feature counts as verified)
| Item | Check | Decides |
|---|---|---|
| V2 standard procedure behavior | BG-SB2 (mandatory) | Whether `CreateRecurringJob` stays as is; values for the help article |
| First run time, rerun delay, time zone | BG-SB4 (mandatory) | Help text "first run", R3 |
| V7 install isolation, multi-company | BG-SB3 multi-company check, BG11 | R1; help sentence on skipped companies |
| V6 recurring entry after last failure | BG-SB5 | R2 wording in help |
| V9 Job Queue Entry line in EQM - Administrator | BG26, BG-SB6 | Keep or drop the line |
| V5, V10, V12, V13 | Build (BG-SB1) | Fallbacks above |
| V8 delegated admin / admin center | BG-SB3 if possible | Documentation only |
| Copied environments | BG-SB9 | Documentation only |

## Risks and open questions
Open questions (answered: the user approved the defaults; kept for the record):
- **Q1 Meaning of "maintenance due date validation".** Approved default: daily check of the FR-017 overdue rule, result
  to telemetry, no data change.
- **Q2 "Notification generation" in the background.** Approved default: no separate job; notifications are
  session-based (FR-017) and fed by the data tasks 1 and 2 keep current.
- **Q3 Entries per task.** Approved default: one entry per task (two), isolated by the platform.
- **Q4 Where entries are created.** Approved default: install (all existing companies, subject to the write-transaction
  guard), first setup creation in a new company, and the Administrator action.
- **Q5 Schedule.** Default: daily at 06:00 through next run date formula `<1D>`, 3 attempts, category EQM; the Run-on
  flags, rerun delay and first run time are the standard procedure's defaults (not set by us; the overload with a rerun
  delay is internal); changed on the standard Job Queue Entry card. Alternative: setup fields.
- **Q6 Existing entries in Error or On Hold.** Default: ensure never changes existing entries.
- **Q7 Job user.** Default: the installing user or the administrator who schedules.
- **Q8 Uninstall.** Default: documented manual cleanup.
- **Q9 Generate Alerts action (FR-016).** Default: kept as an optional manual run.
- **Q10 Extensibility.** Default: no published event.
- **Q11 Automated tests.** Default: deferred; test codeunit 50172 reserved; the sandbox checks are the verification.
- **Q12 Status display on Equipment Setup.** Default: two read-only status fields.

Risks:
- R1 Install-time scheduling: `Codeunit.Run` isolation inside an open write transaction is not allowed. The
  `IsInWriteTransaction` guard prevents an install failure but means that, in a multi-company install, some companies
  may get no entries until an administrator runs Schedule Monitoring Jobs there (opening Equipment Setup does not help,
  because the setup already exists). Mitigation: telemetry EQM0004 Reason WriteTransaction, status "Not scheduled" on
  Equipment Setup, help article, BG-SB3 multi-company check. The company-initialize subscription (Q4 alternative) would
  not fix this case either.
- R2 A recurring entry that exhausts its attempts may stay in Error and stop recurring (V6). Mitigation: 3 attempts,
  status visible on Equipment Setup, help article.
- R3 `Starting Time` and `Today()` in the job session may use a different time zone from the users (FR-016 R2).
- R4 Two administrators scheduling at the same moment could create a duplicate entry. Accepted; harmless and visible.
- R5 Entries run as a named user; if that user is disabled or loses rights, the jobs fail (Q7).
- R6 The maintenance job changes no data and is visible only in telemetry and the job queue log (Q1).
- R7 Codeunit 50114's ID and category EQM become permanent at the first release.
- R8 (resolved) Job Queue API names verified in `docs/plans/FR-018-events.md`; behavior of the standard procedure is
  still open (BG-SB2).
- R9 No automated tests (Q11): regressions are caught only by review and the sandbox checks.
- R10 Run-on flags, rerun delay and Earliest Start Date/Time are set by the standard
  `ScheduleRecurrentJobQueueEntryWithRunDateFormula`, not by us; the first run may be the next 06:00 rather than
  immediately, and a later base app version could change these defaults. Mitigation: BG-SB2/BG-SB4 record the values;
  administrators can edit the entry.
