# FR-054 Background Processing Optimization — Plan

> Request (verbatim): FR-054 Background Processing Optimization
> Issue: #95 — "Long-running processes shall execute using Job Queue processing. Examples: Warranty Monitoring, Maintenance Calculations, Data Archiving. Related: Extends FR-018 Automated Background Processing and NFR-004 Automation (both done). Scope here is the new long-running processes (maintenance calculations, data archiving) and optimizing the existing ones."
> Status: **approved**

## Request

FR-054 (issue #95): long-running processes run through the Job Queue. This plan adds the two missing processes and optimizes the existing monitoring jobs (FR-018/FR-051):

- **Maintenance Calculations:** a new daily job that recalculates the stored next maintenance dates.
- **Data Archiving:** the standard Retention Policies framework (the user chose Option A). Its own job queue entry does the deleting.
- **Optimization:** the warranty alert job no longer reads the alert table once per equipment.

Target: AppSource

## Definition of done

- [ ] **New job codeunit.** Public codeunit 50145 "EQM Maintenance Calc. Job" (`TableNo = "Job Queue Entry"`) runs its body through "EQM Monitoring Job Runner" (50143). On failure, an error log entry is written with Operation "Maintenance Calculation Job" and Object ID 50145, and the job still fails with the original text.
- [ ] **What the job does.** It recalculates the stored "Next Maintenance Date" of every equipment that is not Lost or Disposed:
  - It uses `CalcNextMaintenanceDate()`, so a partner's `OnBeforeCalcNextMaintenanceDate` subscriber is respected.
  - Only stale rows are written, with `Modify(false)`. Final-status equipment is never touched.
  - It commits every 1000 updates, but only when it runs isolated. It never commits a transaction a caller opened.
  - It logs telemetry EQM0012 with counts only.
  - When the Maintenance Planning feature is off, it does nothing.
- [ ] **Scheduling.** `EnsureMonitoringJobs` creates a third daily recurring entry for 50145 at 05:00 in category EQM. The existing two entries stay at 06:00 and are never changed. "Monitoring Job Queue Entries" shows all three.
- [ ] **Setup page.** Equipment Setup shows a third status field "Maintenance Calculation Job" (visible when Maintenance Planning is on). The AboutText mentions the third job.
- [ ] **Warranty job optimization.** `GenerateAlerts` (50110) reads the non-cancelled alerts of the date window once into a Dictionary, instead of one `IsEmpty` per equipment. Behaviour is unchanged.
- [ ] **Enum and ToolTip.** Enum 50113 has value 4 "Maintenance Calculation Job". The ToolTip of field Operation on table 50115 mentions it.
- [ ] **Retention Policies.** After install or upgrade, three tables are allowed tables of the standard Retention Policies (`IsAllowedTable` returns true):
  - EQM Error Log Entry (50115): default date field "Logged At", no filter.
  - EQM Warranty Alert (50107): a locked, enabled filter line Status = Acknowledged|Cancelled, period "1 Year", date field SystemModifiedAt.
  - EQM Integration Event Entry (50110): a locked, enabled filter line Processed = true, period "3 Months", date field "Processed At".
  - Audit, maintenance log, history, notes and assignment tables are never registered.
  - Nothing is deleted until an administrator creates and enables a policy.
- [ ] **Upgrade step.** The registration runs once per company, guarded by upgrade tag `MC-EQM-FR054-RetentionPolicyTables-20261120`, from `EQM Upgrade Mgt.`.`UpgradePerCompany()`, which Install and Upgrade already call. The Install and Upgrade codeunit files are untouched. `app.json` is unchanged.
- [ ] **Permissions.** EQM - Reader has X on codeunit 50145, so test 50162 scenario 8 stays green.
- [ ] **Translations.** New captions, ToolTips and labels are in `.g.xlf`, `pt-PT.xlf` and `es-ES.xlf`, and `python3 .github/scripts/xlf_sync.py check` passes.
- [ ] **Tests.** New test codeunit 50172 "EQM Background Process. Tests"; test I4 in 50155; RP1-RP3 in 50177. The coverage register is updated, and `repo_checks.py` shows no integrity errors.
- [ ] **Build.** app/ and test/ compile with 0 errors and 0 warnings. Tests are reported as "Not verified: tests not executed locally, CI result pending".
- [ ] **Docs** (documenter):
  - `docs/features/FR-054-background-processing-optimization.md`
  - `docs/help/FR-054-background-processing-optimization.md`: the third job, and how to set up Retention Policies for the three tables, including job user permissions.
  - `## FR-054 Background Processing Optimization (version stays 29.0.0.0, no bump)` in `CHANGELOG.md`.
  - FR-054 sandbox checks in `docs/TODO.md`.
  - One sentence in the FR-018 and FR-051 help: the third job, and that the error log can now be cleaned by a retention policy.

## Out of scope

- Our own archive job or archive tables. Retention Policies delete; nothing is copied to an archive.
- Default (pre-created) retention policies. Administrators create them.
- Subscribing to `OnRefreshAllowedTables`: it is `internal` in the System Application.
- Changing the schedule, attempts or description of existing job queue entries.
- Running user-triggered actions (Generate Alerts, Create/Delete Demo Data) as background jobs (phase 3).
- Job timeout or priority (the standard overloads are internal, FR-018).
- `app.json`, `test/app.json`, the Install (50104) and Upgrade (50134) codeunit files, new permission sets, any change to existing permission lines, EQM0001-EQM0009.
- The `LockTable` strategy and the `Commit` in the warranty job.

Later phases:

- Phase 2: register the tables for companies created after install without waiting for the next upgrade (needs a verified company-initialize hook).
- Phase 3: Generate Alerts and demo data actions offer "run in background" through a one-off job queue entry.
- Phase 4: a job-duration cue or telemetry, if platform job queue telemetry is not enough.

## Objects

`al_symbolsearch` and `al_getnextobjectid` returned "No AL projects are loaded", so the IDs come from a source scan:

- App codeunits in use: 50103-50144 and 50149. Free: 50145-50148.
- Test codeunit 50172 is the unbuilt FR-018 reservation "EQM Background Process. Tests" (docs/TODO.md line 104).

If the developer's MCP has the project loaded, run `al_getnextobjectid` first and report any difference.

| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Enum | 50113 | EQM Error Operation | Changed (value 4) | app/src/ErrorLog/EQMErrorOperation.Enum.al |
| Codeunit | 50108 | EQM Maintenance Mgt. | Changed (new procedure + labels) | app/src/Maintenance/EQMMaintenanceMgt.Codeunit.al |
| Codeunit | 50145 | EQM Maintenance Calc. Job | New | app/src/Monitoring/EQMMaintenanceCalcJob.Codeunit.al |
| Codeunit | 50143 | EQM Monitoring Job Runner | Changed (case branch) | app/src/ErrorLog/EQMMonitoringJobRunner.Codeunit.al |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | Changed (preload, remove local AlertExists) | app/src/Warranty/EQMWarrantyAlertMgt.Codeunit.al |
| Codeunit | 50115 | EQM Monitoring Job Mgt. | Changed (third job, start time parameter) | app/src/Monitoring/EQMMonitoringJobMgt.Codeunit.al |
| Codeunit | 50139 | EQM Upgrade Mgt. | Changed (retention step + tag) | app/src/Install/EQMUpgradeMgt.Codeunit.al |
| Page | 50103 | EQM Equipment Setup | Changed (status field, AboutText) | app/src/Setup/EQMEquipmentSetup.Page.al |
| Table | 50115 | EQM Error Log Entry | Changed (1 ToolTip) | app/src/ErrorLog/EQMErrorLogEntry.Table.al |
| PermissionSet | 50100 | EQM - Reader | Changed (1 line) | app/src/Permissions/EQMReader.PermissionSet.al |
| XLIFF | - | g / pt-PT / es-ES | Changed | app/Translations/*.xlf |
| Codeunit (test) | 50172 | EQM Background Process. Tests | New | test/src/EQMBackgroundProcessTests.Codeunit.al |
| Codeunit (test) | 50155 | EQM Error Log Isolation Tests | Changed (test I4) | test/src/EQMErrorLogIsolationTests.Codeunit.al |
| Codeunit (test) | 50177 | EQM Upgrade Tests | Changed (RP1-RP3) | test/src/EQMUpgradeTests.Codeunit.al |
| JSON | - | coverage register | Changed | .github/coverage/coverage-register.json |

## Events and standard symbols

`al_symbolsearch` could not run, because the AL MCP has no project loaded. The Retention Policy symbols were checked against the System Application reference on Microsoft Learn instead.

| Symbol | Exact signature | Verified with al_symbolsearch |
|---|---|---|
| Codeunit 3905 "Reten. Pol. Allowed Tables", namespace `System.DataAdministration`, Access Public | - | No. Confirmed on Learn |
| AddAllowedTable (3-argument, used for 50107 and 50110) | `procedure AddAllowedTable(TableId: Integer; DefaultDateFieldNo: Integer; TableFilters: JsonArray): Boolean` | No. Confirmed on Learn |
| AddAllowedTable (2-argument, used for 50115) | `procedure AddAllowedTable(TableId: Integer; DefaultDateFieldNo: Integer): Boolean` | No. Confirmed on Learn |
| AddTableFilterToJsonArray (enum overload) | `procedure AddTableFilterToJsonArray(var TableFilters: JsonArray; RetentionPeriodEnum: Enum "Retention Period Enum"; DateFieldNo: Integer; Enabled: Boolean; Locked: Boolean; RecordRef: RecordRef)`. Learn: "If Locked is true, the line will also be enabled." | No. Confirmed on Learn |
| IsAllowedTable (used by tests) | `procedure IsAllowedTable(TableId: Integer): Boolean` | No. Confirmed on Learn |
| Enum 3900 "Retention Period Enum" (`System.DataAdministration`): values `"3 Months"`, `"1 Year"` | - | No. Confirmed on Learn |
| OnRefreshAllowedTables | `[IntegrationEvent(False,False)] internal procedure OnRefreshAllowedTables()`. **Internal: not subscribable from this app. Not used.** | No. Confirmed on Learn |
| Codeunit "Upgrade Tag" (`System.Upgrade`): `HasUpgradeTag`, `SetUpgradeTag` | as used in 50139 today | No. Already compiled in 50139 |
| Table 472 "Job Queue Entry" and `ScheduleRecurrentJobQueueEntryWithRunDateFormula(ObjType: Option; ObjID: Integer; RecId: RecordId; JobQueueCategoryCode: Code[10]; MaxAttemptsToRun: Integer; NextRunDateFormula: DateFormula; StartingTime: Time)` | as in 50115 today | No. Verified in docs/plans/FR-018-events.md and already compiled |
| `Record.ReadIsolation := IsolationLevel::UpdLock` | runtime 11.0+; this app is on runtime 18.0 | Learn |
| Own symbols: `Equipment.CalcNextMaintenanceDate(): Date` (internal), `Equipment.IsFinalStatus(Status)`, `FeatureMgt.IsEnabled(...)`, `JobRunner.RunJob(Integer; Enum "EQM Error Operation")`, `[InternalEvent] OnBeforeRunMonitoringJob(JobCodeunitIdToRun: Integer)` | read in source | Source read |

**Developer must check before step 7** (`al_symbolsearch` if the MCP loads, otherwise the compile):

- (a) The codeunit name "Reten. Pol. Allowed Tables" and namespace `System.DataAdministration` resolve.
- (b) The 3-argument AddAllowedTable overload `(Integer; Integer; JsonArray)` and the enum overload of `AddTableFilterToJsonArray` exist with the signatures above in Application 29.
- (c) The enum value names are `"3 Months"` and `"1 Year"`.

If any check fails, stop and report (`BLOCKED:`). Do not substitute another overload.

No standard event is subscribed and none is published.

## Steps

1. `app/src/ErrorLog/EQMErrorOperation.Enum.al`: add `value(4; "Maintenance Calculation Job") { Caption = 'Maintenance Calculation Job'; }`. The runner needs this value to log the new job.

2. `app/src/Maintenance/EQMMaintenanceMgt.Codeunit.al`: add a new procedure after `CheckOverdueMaintenance`.
   - **Signature:** `internal procedure RecalculateNextMaintenanceDates(ReferenceDate: Date; IsScheduled: Boolean; CommitPerBatch: Boolean; var CheckedCount: Integer; var UpdatedCount: Integer; var PlannedOverdueCount: Integer)`.
   - **XML doc:** "Recalculates the stored next maintenance date of all equipment that is not lost or disposed and corrects stale values. Commits after every 1000 updates when CommitPerBatch is true. 0D means today."
   - **Start:** set the three counts to 0. If ReferenceDate = 0D, use Today().
   - **Read phase.** Fresh local `Equipment`, PK order, no SetCurrentKey:
     - `SetLoadFields("No.", Status, "Last Maintenance Date", "Maintenance Frequency (Months)", "Next Maintenance Date")`, then `FindSet()`.
     - Skip rows where `Equipment.IsFinalStatus(Equipment.Status)` is true.
     - For each remaining row: `CheckedCount += 1` and `NewDate := Equipment.CalcNextMaintenanceDate()`.
     - If `NewDate <> "Next Maintenance Date"`, add "No." to a `List of [Code[20]]`.
     - If `(NewDate <> 0D) and (NewDate < ReferenceDate)`, add 1 to `PlannedOverdueCount`.
   - **Write phase,** after the loop ends, so no Commit happens inside a FindSet (FR-053 collect-then-modify):
     - `foreach` collected number: if `UpdateStoredNextMaintenanceDate(No)` returns true, add 1 to `UpdatedCount`.
     - Then, if `CommitPerBatch and (UpdatedCount mod GetRecalcCommitBatchSize() = 0)`, call `Commit()`.
     - Comment: releases row locks during a long job; every update is idempotent, so a later failure leaves only correct data.
   - **End:** call `LogRecalcTelemetry(ReferenceDate, IsScheduled, CheckedCount, UpdatedCount, PlannedOverdueCount)`.
   - **`local procedure UpdateStoredNextMaintenanceDate(EquipmentNo: Code[20]): Boolean`.** Fresh `EquipmentToUpdate` record:
     1. Set `ReadIsolation := IsolationLevel::UpdLock`.
     2. If `not Get(EquipmentNo)`, exit false. If the status is final, exit false.
     3. `NewDate := CalcNextMaintenanceDate()`. If it equals the stored value, exit false.
     4. Assign the field, call `Modify(false)`, exit true.
     - Comment: Modify(false) is deliberate. It corrects a derived field only and must not run consistency checks or audit on old data.
   - **`local procedure GetRecalcCommitBatchSize(): Integer`:** exit(1000).
   - **`local procedure LogRecalcTelemetry(...)`:** same shape as `LogOverdueCheckTelemetry`. New Locked labels:
     - `RecalcTelemetryTok` = 'EQM0012'
     - `RecalcTelemetryMsg` = 'Planned maintenance dates recalculated.'
     - `EquipmentCheckedDimTok` = 'EquipmentChecked'
     - `DatesUpdatedDimTok` = 'DatesUpdated'
     - `PlannedOverdueDimTok` = 'PlannedOverdueCount'
     - Reuse ReferenceDateDimTok, TriggerDimTok, ScheduledTok and ManualTok.
     - Use `Format(x, 0, 9)`, `Verbosity::Normal`, `DataClassification::SystemMetadata`, `TelemetryScope::All`. No record numbers in telemetry.
   - Extend the codeunit summary with "...and recalculates planned maintenance dates."

3. `app/src/Monitoring/EQMMaintenanceCalcJob.Codeunit.al` (new).
   - `namespace MiguelCarvalho.EquipmentManagement; using System.Threading;`
   - `codeunit 50145 "EQM Maintenance Calc. Job"` with `TableNo = "Job Queue Entry"` and default access (Public, like 50111/50114: its ID is stored in job queue entries).
   - XML summary: "Runs from a job queue entry and recalculates the next maintenance date of the equipment every day. Equipment Setup schedules it automatically. An error that stops the job is written to the equipment error log."
   - `OnRun`: local `JobRunner: Codeunit "EQM Monitoring Job Runner"`; `JobRunner.RunJob(Codeunit::"EQM Maintenance Calc. Job", "EQM Error Operation"::"Maintenance Calculation Job");`. Nothing else.

4. `app/src/ErrorLog/EQMMonitoringJobRunner.Codeunit.al`:
   - Add a case branch: `Codeunit::"EQM Maintenance Calc. Job": RunMaintenanceCalculationJob();`.
   - New `local procedure RunMaintenanceCalculationJob()`:
     - If `not FeatureMgt.IsEnabled("EQM Feature"::"Maintenance Planning")`, exit. Comment: with Maintenance Planning off, the dates are not recalculated.
     - Otherwise call `MaintenanceMgt.RecalculateNextMaintenanceDates(Today(), true, not Database.IsInWriteTransaction(), CheckedCount, UpdatedCount, PlannedOverdueCount)`. Comment: commits per batch only when isolated, and never commits a transaction a caller opened.
   - Update the param docs of `RunJob` and `SetJob` to "50111, 50114 or 50145".

5. `app/src/Warranty/EQMWarrantyAlertMgt.Codeunit.al`:
   - **In GenerateAlerts:** after `CancelledCount := CancelStaleAlerts();` and before the equipment loop, call `LoadExistingAlertKeys(ReferenceDate, ReferenceDate + AlertDays, ExistingAlertKeys)` with a local `Dictionary of [Text, Boolean]`.
   - **In the loop:** replace `if not AlertExists(...)` with `if not ExistingAlertKeys.ContainsKey(GetAlertKey(Equipment."No.", Equipment."Warranty End Date", AlertInterval))`. After `CreateAlert`, add the key.
   - **`local procedure LoadExistingAlertKeys(FromDate: Date; ToDate: Date; var ExistingAlertKeys: Dictionary of [Text, Boolean])`.** Fresh record:
     - `SetCurrentKey(Status, "Warranty End Date")` (an existing key).
     - `SetFilter(Status, '<>%1', Status::Cancelled)` and `SetRange("Warranty End Date", FromDate, ToDate)`.
     - `SetLoadFields("Equipment No.", "Warranty End Date", "Alert Interval")`, then `FindSet`, adding each key that is not already contained.
   - **`local procedure GetAlertKey(EquipmentNo: Code[20]; WarrantyEndDate: Date; AlertInterval: Enum "EQM Warranty Alert Interval"): Text`:** uses a Locked label `AlertKeyTok: Label '%1|%2|%3', Locked = true` with `Format(WarrantyEndDate, 0, 9)` and `AlertInterval.AsInteger()`.
   - **Remove** the local `AlertExists` (it would trigger AA0228, unused local).
   - `LockTable()` stays first, unchanged.
   - Equivalent to the old logic: the equipment loop only reads end dates within [FromDate, ToDate], so every alert that `AlertExists` could find is preloaded.

6. `app/src/Monitoring/EQMMonitoringJobMgt.Codeunit.al`:
   - New label `MaintenanceCalcJobDescTxt: Label 'Equipment Management: recalculate planned maintenance dates', MaxLength = 250;`.
   - Add `StartingTime: Time` (after JobDescription) to `EnsureJob` and to `CreateRecurringJob`. `CreateRecurringJob` passes `StartingTime` instead of the literal `060000T`.
   - In `EnsureMonitoringJobs`: the two existing calls pass `060000T`; add `EnsureJob(Codeunit::"EQM Maintenance Calc. Job", MaintenanceCalcJobDescTxt, 050000T, CreatedCount, ExistingCount)`.
   - In `ShowMonitoringJobs`: change the filter to `'%1|%2|%3'` with the third ID.
   - Update the comment above `CreateRecurringJob`. Public and internal signatures used elsewhere are unchanged.

7. `app/src/Install/EQMUpgradeMgt.Codeunit.al` (approved by the user's Option A answer). Do the symbol checks (a)-(c) first.
   - Add `using System.DataAdministration;`.
   - New label `RetentionPolicyTablesTagTok: Label 'MC-EQM-FR054-RetentionPolicyTables-20261120', Locked = true;`.
   - In `UpgradePerCompany()`, after `UpgradeDefaultWarrantyAlertDays();`, add `UpgradeRetentionPolicyTables();`.
   - **`internal procedure UpgradeRetentionPolicyTables()`:** if `UpgradeTag.HasUpgradeTag(GetRetentionPolicyTablesTag())`, exit. Otherwise call `AddRetentionPolicyAllowedTables()` and then `UpgradeTag.SetUpgradeTag(...)`.
   - **`internal procedure AddRetentionPolicyAllowedTables()`.** XML doc: "Adds the equipment log tables to the allowed tables of retention policies. Open warranty alerts and unprocessed integration event entries are protected by locked filters. Audit, history and maintenance log tables are never added." In order:
     1. `RetenPolAllowedTables.AddAllowedTable(Database::"EQM Error Log Entry", ErrorLogEntry.FieldNo("Logged At"));`
     2. Warranty Alert: `WarrantyAlert.SetFilter(Status, '%1|%2', WarrantyAlert.Status::Acknowledged, WarrantyAlert.Status::Cancelled); RecRef.GetTable(WarrantyAlert); RetenPolAllowedTables.AddTableFilterToJsonArray(AlertFilters, "Retention Period Enum"::"1 Year", WarrantyAlert.FieldNo(SystemModifiedAt), true, true, RecRef); RetenPolAllowedTables.AddAllowedTable(Database::"EQM Warranty Alert", WarrantyAlert.FieldNo(SystemModifiedAt), AlertFilters);`
     3. Integration Event Entry: `IntegrationEventEntry.SetRange(Processed, true); RecRef.Close(); RecRef.GetTable(IntegrationEventEntry); AddTableFilterToJsonArray(EntryFilters, "Retention Period Enum"::"3 Months", IntegrationEventEntry.FieldNo("Processed At"), true, true, RecRef); AddAllowedTable(Database::"EQM Integration Event Entry", IntegrationEventEntry.FieldNo("Processed At"), EntryFilters);`
     - Use separate JsonArray variables per table.
     - Ignore the Boolean results. Each call is idempotent.
   - **`internal procedure GetRetentionPolicyTablesTag(): Code[250]`:** returns the label. Doc: "Never change a shipped tag."
   - **Do NOT add this tag in `RegisterPerCompanyUpgradeTags`.** Add a comment explaining why: pre-registering would mark new companies as done, and then they would never register the tables. New companies get the tables on the next install or upgrade (phase 2 covers new companies immediately). Update the codeunit summary so it says not every tag is pre-registered.
   - The Install (50104) and Upgrade (50134) files are unchanged; they already call `UpgradePerCompany()`.

8. `app/src/Setup/EQMEquipmentSetup.Page.al`:
   - New var `MaintenanceCalcJobStatus: Text`.
   - New field in group BackgroundMonitoring after `MaintenanceJobStatus`: `field(MaintenanceCalcJobStatus; MaintenanceCalcJobStatus)` with Caption 'Maintenance Calculation Job', `Editable = false`, `Visible = MaintenancePlanningEnabled`, and ToolTip 'Specifies the status of the job queue entry that recalculates the next maintenance date of the equipment every day. Not scheduled means that no entry exists; choose Schedule Monitoring Jobs to create it.'
   - In `UpdateJobStatus`, add `MaintenanceCalcJobStatus := MonitoringJobMgt.GetJobStatusText(Codeunit::"EQM Maintenance Calc. Job");`.
   - AboutText: replace "one creates warranty alerts, one checks overdue maintenance." with "one creates warranty alerts, one checks overdue maintenance and one recalculates the next maintenance dates." Change nothing else.

9. `app/src/ErrorLog/EQMErrorLogEntry.Table.al`: the field 4 ToolTip becomes 'Specifies the process that failed: the warranty alert job, the overdue maintenance job, the maintenance calculation job, or the scheduling of these jobs.'

10. `app/src/Permissions/EQMReader.PermissionSet.al`: add `codeunit "EQM Maintenance Calc. Job" = X,` after `codeunit "EQM Maintenance Monitor Job" = X,`. No other permission set changes.

11. Compile app/:
    - Use `al_build` (it regenerates `.g.xlf`; see DECISIONS FR-056), then `al_getdiagnostics`.
    - If the MCP has no project loaded, use the extension's alc as in FR-051/FR-052, with CodeCop, UICop and AppSourceCop.
    - Fix every warning.

12. Translations: run `python3 .github/scripts/xlf_sync.py sync`, then export, fill, import and `check` for pt-PT and es-ES (FR-055 glossary, sentence case).
    - New or changed units: the enum value, `MaintenanceCalcJobDescTxt`, the new field caption and ToolTip, the changed AboutText, and the changed table ToolTip.
    - Translate "Maintenance Calculation Job" the same way as the existing "Overdue Maintenance Job".
    - Locked labels must not appear.

13. `test/src/EQMBackgroundProcessTests.Codeunit.al`, new codeunit 50172:
    - `Subtype = Test; TestPermissions = Disabled;`, AutoRollback on every test.
    - Local helpers in the shape of 50164 `CreateEquipment` and `CreateEquipmentWithPlan`, with one Counter and Locked `Tok` labels (FR-038).
    - Tests BP1-BP9, BP-W1 and BP-W2 (see Tests).

14. `test/src/EQMErrorLogIsolationTests.Codeunit.al`: add test I4. Subscriber 50160 needs no change.

15. `test/src/EQMUpgradeTests.Codeunit.al`: add RP1-RP3, using `using System.DataAdministration;` and `using System.Upgrade;`.

16. `.github/coverage/coverage-register.json`:
    - Add 50145 to `scope.businessLogic.codeunits`.
    - Add traces:
      - 50145 `OnRun` → 50172 `MaintCalcJobCorrectsStaleDate` and 50155 I4.
      - 50108 `RecalculateNextMaintenanceDates` → 50172 BP1.
      - 50139 `UpgradeRetentionPolicyTables`, `AddRetentionPolicyAllowedTables` and `GetRetentionPolicyTablesTag` → 50177 RP1/RP2.

17. Compile test/ (alc against the package cache), then run `python3 .github/scripts/repo_checks.py`.

## Tests

Assertions filter on the test's own records, because the job reads the whole company.

- [SCENARIO BP1] Stale date is corrected. [GIVEN] Equipment with a plan whose stored Next Maintenance Date was overwritten with a random wrong date via `Modify(false)`. [WHEN] `RecalculateNextMaintenanceDates(Today(), false, false, ...)` runs. [THEN] The stored date equals `CalcNextMaintenanceDate()`, and UpdatedCount >= 1.
- [SCENARIO BP2] (negative) A correct row is not written. [GIVEN] Equipment whose plan was set with `Modify(true)`. [WHEN] The recalculation runs. [THEN] The date and SystemModifiedAt are unchanged.
- [SCENARIO BP3] (negative) Final status is untouched. [GIVEN] A stale date, then Status Disposed set with `Modify(false)` (FR-045 M2). [WHEN] The recalculation runs. [THEN] The stale date is kept.
- [SCENARIO BP4] Plan removed. [GIVEN] Frequency set to 0 with `Modify(false)` while the stored next date is still filled. [WHEN] The recalculation runs. [THEN] The next date is 0D.
- [SCENARIO BP5] Planned overdue is counted. [GIVEN] A baseline run, then equipment whose recalculated date is before today. [WHEN] The recalculation runs again. [THEN] PlannedOverdueCount = baseline + 1.
- [SCENARIO BP6] (negative) Feature off. [GIVEN] Maintenance Planning disabled via `FeatureMgt.SetFeatureEnabled`, and a stale date. [WHEN] `Codeunit.Run(Codeunit::"EQM Maintenance Calc. Job", JobQueueEntry)`. [THEN] The date is unchanged and no error is raised.
- [SCENARIO BP7] `MaintCalcJobCorrectsStaleDate`. [GIVEN] Feature on, and a stale date. [WHEN] The job codeunit runs; a write transaction is open, so it runs unisolated and does not commit. [THEN] The date is corrected.
- [SCENARIO BP8] (negative) Ensure creates nothing when all three entries exist. [GIVEN] Job Queue Entries for 50111, 50114 and 50145 inserted with `Insert(false)` (ID := CreateGuid(), Status On Hold). [WHEN] `EnsureMonitoringJobs` runs. [THEN] Created = 0, Existing = 3, there is one entry per ID, and the status is unchanged.
- [SCENARIO BP9] `JobExists(Codeunit::"EQM Maintenance Calc. Job")`, two tests: false after its entries are deleted; true after one is inserted directly.
- [SCENARIO BP-W1] (negative) An acknowledged alert blocks re-creation. [GIVEN] Warranty end `Today()+1+Random(20)`, alerts generated once, and the alert acknowledged. [WHEN] `GenerateAlerts` runs again. [THEN] There is still exactly 1 alert, and it is Acknowledged.
- [SCENARIO BP-W2] Another interval does not block the due one. [GIVEN] Warranty end `Today()+1+Random(20)` and an Open "90 Days" alert for the same end date. [WHEN] `GenerateAlerts` runs. [THEN] A "30 Days" alert exists as well.
- [SCENARIO I4] (50155, AutoCommit) A failing calculation job is logged. [GIVEN] No write transaction, and 50160 `SetFailure(Codeunit::"EQM Maintenance Calc. Job", text with a placeholder)`. [WHEN] `asserterror Codeunit.Run(50145, JobQueueEntry)`. [THEN] The same text is raised; exactly one entry exists with Operation "Maintenance Calculation Job", Object ID 50145 and the original message. Clean up with `TakeNewEntries`.
- [SCENARIO RP1] (50177) Registration. [WHEN] `UpgradeMgt.AddRetentionPolicyAllowedTables()` runs. [THEN] `RetenPolAllowedTables.IsAllowedTable` is true for 50115, 50107 and 50110.
- [SCENARIO RP2] (50177) Tag-guarded and idempotent. [WHEN] `UpgradeRetentionPolicyTables()` runs twice. [THEN] The tag is set, no error is raised, and the three tables are still allowed.
- [SCENARIO RP3] (50177, negative) Audit and history tables are never allowed. [WHEN] `AddRetentionPolicyAllowedTables()` runs. [THEN] `IsAllowedTable` is false for "EQM Equipment Audit Entry", "EQM Maintenance Log Entry", "EQM Maintenance History Entry" and "EQM Equipment Assignment". Removal is not tested: `RemoveAllowedTable` called from the test app may be refused.

**Manual sandbox checks** (to go in `docs/TODO.md`):

- **BP-SB1:** Schedule Monitoring Jobs in an existing dev company creates only the 50145 entry (Created 1, Existing 2). The entry is Ready, starts at 05:00, and keeps its Description. Not automated (FR-018 V2).
- **BP-SB2:** The new job runs before the 06:00 jobs in category EQM.
- **BP-SB3:** With a job user that has only EQM - Reader, the job fails on the first stale row, and the error log shows it.
- **BP-SB4:** EQM0012 appears in telemetry.
- **RP-SB1:** Retention Policies page. New policies on the three tables show the locked filter lines, and "Apply to all records" cannot remove them. Deleting closed alerts and processed entries works as SUPER. Open alerts and unprocessed entries are never deleted.
- **RP-SB2:** Record whether the allowed-tables list is per company. Create a company after install and check whether the three tables are allowed there.
- **RP-SB3:** Record whether the standard Refresh action of the allowed tables removes our tables.
- **RP-SB4:** Run the retention job as a non-SUPER EQM - Administrator and record the permission error on the Warranty Alert table (Administrator has only indirect `d` there). Documentation input for the help.

**Existing tests likely affected:**

- `GenerateAlerts` callers: 50168 W11 and W14, 50199, 50158, 50184, 50187, 50151, 50176, and 50159 (performance).
- 50154 E8 and 50155 I1-I3 (runner).
- 50162 scenario 8 (Reader line).
- 50177 (UpgradePerCompany now also registers the retention tables).
- 50153 (translations).

## Assumptions

- **"Maintenance Calculations"** means a daily recalculation of the stored Next Maintenance Date (FR-019), plus a planned-overdue count in telemetry. It is the only stored maintenance calculation, and it goes stale after `Modify(false)`/`Insert(false)` paths, imports, or a changed partner subscriber.
- **"Optimizing the existing ones"** means removing the per-equipment `IsEmpty` in `GenerateAlerts` and adding a per-job start time to the ensure framework. Job durations are already covered by the platform's job queue lifecycle telemetry.
- **No install or upgrade code is needed for the third job.** The app is unreleased, install already ensures the jobs, and dev companies use Schedule Monitoring Jobs. FR-052's statement that a job needs install/upgrade registration applies after the first release (the FR-018 TODO rule).
- **The retention registration uses the existing tag-guarded `UpgradePerCompany` path,** which Install and Upgrade already call. Learn's example registers in `OnInstallAppPerCompany`, so the registration is treated as per company.
- **Locked filter periods:** 1 year for closed alerts, 3 months for processed integration entries. The error log has no filter, and its date field is "Logged At".
- **Test IDs:** 50172 is reused from the FR-018 reservation. Logic is placed in the existing 50108, because only 4 app codeunit IDs remain.

## DECISIONS

- FR-054 | Chose standard Retention Policies (Option A, user's answer) over our own archive job | Reversible: yes
- FR-054 | Chose to register 50115 (no filter, "Logged At"), 50107 (locked filter Acknowledged/Cancelled, 1 year, SystemModifiedAt) and 50110 (locked filter Processed, 3 months, "Processed At"), and never the audit, history, maintenance log, notes or assignment tables, over registering all log tables | Reversible: yes (RemoveAllowedTable exists)
- FR-054 | Chose locked (mandatory) filter lines over default suggestions, so open alerts and unprocessed entries can never be deleted by a policy. Admins cannot shorten those periods | Reversible: yes
- FR-054 | Chose a tag-guarded step in "EQM Upgrade Mgt." that is not pre-registered for new companies, over registering the tag in OnGetPerCompanyUpgradeTags, so companies created later get the tables at the next install or upgrade | Reversible: yes
- FR-054 | Chose not to subscribe to OnRefreshAllowedTables, because Learn shows it as internal | Reversible: yes
- FR-054 | Chose no permission change for the retention job user; the help says it runs as SUPER or a user with Delete on the tables | Reversible: yes
- FR-054 | Chose a daily recalculation of the stored Next Maintenance Date as "Maintenance Calculations" over a new schedule table | Reversible: yes
- FR-054 | Chose Modify(false) for the corrected date over Modify(true); SystemModifiedAt still changes, so API delta sync sees it | Reversible: yes
- FR-054 | Chose collect-then-update with a Commit every 1000 updates, only when isolated, over one transaction | Reversible: yes
- FR-054 | Chose an UpdLock re-read per stale row over FindSet(true) on the whole table | Reversible: yes
- FR-054 | Chose that the job skips everything when Maintenance Planning is off, consistent with the warranty job | Reversible: yes
- FR-054 | Chose 05:00 for the new entry, outside business hours per Learn, leaving existing entries untouched | Reversible: yes
- FR-054 | Chose telemetry ID EQM0012 (EQM0010/0011 are earmarked) with dimensions EquipmentChecked, DatesUpdated, PlannedOverdueCount, ReferenceDate, Trigger | Reversible: no (telemetry contract once released)
- FR-054 | Chose a Dictionary preload of non-cancelled alerts over one IsEmpty per equipment; LockTable unchanged | Reversible: yes
- FR-054 | Chose logic in existing 50108 plus one new public job codeunit 50145 | Reversible: no (job codeunit ID permanent at release)
- FR-054 | Chose test codeunit 50172 (FR-018 reservation) over widening test/app.json; the ensure-with-enqueue path is a sandbox check | Reversible: yes

## Risks

- **Symbols checked on Learn only, not with al_symbolsearch.** The developer must do checks (a)-(c) before step 7, and the reviewer should confirm the build.
- **OnRefreshAllowedTables is internal.** If an admin's Refresh rebuilds the list without our tables, they come back only at the next upgrade (RP-SB3).
- **Allowed-table list may be per company.** If so, companies created after install wait for the next upgrade (RP-SB2, phase 2).
- **Locked filter behaviour is unverified.** That locked filter lines cannot be bypassed with "Apply to all records" comes from the Learn wording and is not tested here (RP-SB1).
- **Non-SUPER Administrator lacks direct Delete on alerts.** EQM - Administrator has direct D on 50115 and 50110 but only indirect `d` on 50107, so a non-SUPER Administrator job user fails on alerts. Documented, not changed.
- **Partially loaded record for partner subscribers.** A partner's `OnBeforeCalcNextMaintenanceDate` receives a record loaded with SetLoadFields. Touching other fields loads them on demand, which is correct but slower.
- **Possible "changed by another user" error.** A user editing a card while the job corrects that row gets this error. Rare: only stale rows, at 05:00.
- **Job user without Modify on equipment.** It fails at the first stale row. The failure is logged and the entry goes to Error.
- **GenerateAlerts preload.** The reviewer must check that the preload runs after `CancelStaleAlerts` and uses exactly the equipment date range.
- **Time zone.** 05:00 runs in the job queue time zone (FR-018 R3).
- **No separate AppSource validation runs.** The reviewer checks AppSourceCop: only additions; one internal enum value; one local procedure removed; no public signature changes.

## References

- https://learn.microsoft.com/dynamics365/business-central/application/system-application/codeunit/system.dataadministration.reten.-pol.-allowed-tables
- https://learn.microsoft.com/dynamics365/business-central/application/system-application/enum/system.dataadministration.retention-period-enum
- https://learn.microsoft.com/dynamics365/business-central/admin-data-retention-policies
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-job-queue#job-queues-and-performance
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/performance/performance-developer#al-performance-patterns
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-readisolation-method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-read-isolation
- https://learn.microsoft.com/dynamics365/business-central/admin-job-queues-schedule-tasks
