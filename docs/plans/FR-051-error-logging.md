# FR-051 Error Logging — Plan

> Request (verbatim): FR-051 Error Logging
> Status: **approved**
> Target: AppSource

Issue #92 asks for application errors to be recorded with date, user, error message, object ID and operation. Phase 1 records every error that stops one of the app's unattended processes: the two daily monitoring jobs (codeunits 50111, 50114) and the scheduling of those jobs (codeunit 50115, `TryEnsureMonitoringJobs`). Entries go into a new table that administrators read on a new list page. When a job fails, the log entry must survive the rollback, and the job queue entry must still end in Error with the original message.

## What exists today

- No error log exists. The only error the app already catches is in `TryEnsureMonitoringJobs` (`app/src/Monitoring/EQMMonitoringJobMgt.Codeunit.al`, lines 92-110); it only goes to telemetry as EQM0004 with the error code.
- `EQM Warranty Alert Job` (50111) and `EQM Maintenance Monitor Job` (50114) run their logic straight from OnRun. Their errors reach only the standard Job Queue Log Entry.
- AL has no global error hook. Learn (AL error handling): log an error that happens within a rolled-back transaction in a new session or to telemetry. The design logs after the failed `Codeunit.Run` has rolled back, in its own isolated `Codeunit.Run`.
- Patterns reused: immutable log table with insert flag (`EQM Equipment Audit Entry` 50112); log list page (`EQM Maintenance Log Entries` 50121); write-transaction guard (FR-018 `TryEnsureMonitoringJobs`); test seam via `[InternalEvent]` (FR-050 50140); manual test subscriber (50152, 50185); permission matrix tests (50162); `.github/scripts/xlf_sync.py` (FR-055).

Later phases (not planned here):
- Phase 2: errors of interactive actions (post maintenance, approve/reject request, demo data) and API calls, keeping ErrorInfo actions.
- Phase 3: retention policy (needs install/upgrade registration, on the stop list) and telemetry signal EQM0010 "Application error logged" (Operation and ErrorCode only).
- Phase 4: Role Center or Setup cue "Errors in the last 7 days".

## Definition of done

- [ ] New enum 50113 "EQM Error Operation", table 50115 "EQM Error Log Entry", page 50141 "EQM Error Log", codeunits 50142 "EQM Error Log Mgt." and 50143 "EQM Monitoring Job Runner" exist in `app/src/ErrorLog/`.
- [ ] When codeunit 50111 or 50114 fails in a job queue run:
  - Exactly one entry is written and committed, even though the job's own work is rolled back.
  - The entry holds: Logged At, User ID (job user), Operation ("Warranty Alert Job" / "Overdue Maintenance Job"), Object ID (50111 / 50114), Error Message (original text), Error Code and Error Call Stack.
  - The job still fails with the same message text, so the job queue entry ends in Error as today.
- [ ] When a job succeeds, no entry is written.
- [ ] When `TryEnsureMonitoringJobs` fails with reason Error, one entry with Operation "Schedule Monitoring Jobs" and Object ID 50115 is written. The function still returns false and still logs EQM0004. Reasons WriteTransaction and CannotCreateTask write no entry.
- [ ] If writing the log entry fails, the original error is unchanged and nothing else breaks.
- [ ] If a write transaction is already open when a job codeunit starts, the job runs exactly as before (no isolation); the error propagates unchanged and unlogged.
- [ ] Texts longer than the field are cut and never cause an error. An empty error text writes no entry.
- [ ] Entries cannot be inserted directly or modified. They can be deleted by users with Delete permission.
- [ ] Only EQM - Administrator can read and delete entries (tabledata `RD`). Reader, Manager and API Consumer have no tabledata entry. Any user can write an entry through the inherent permission on the insert procedure. Reader has `X` on the four new objects that need it.
- [ ] The Equipment Setup page has a Navigation action "Error Log" visible only when the user can read the log. The page is also in Tell Me (Administration).
- [ ] All new captions, ToolTips and labels are in `.g.xlf`, `pt-PT.xlf`, `es-ES.xlf`, and `xlf_sync.py check` passes.
- [ ] Test codeunits 50154, 50155, 50160 exist and compile. Test 50162 has 2 new tests.
- [ ] `.github/coverage/coverage-register.json` has the new objects in scope and the traces from step 17. `repo_checks.py` shows no integrity errors.
- [ ] app/ and test/ compile with 0 errors and 0 warnings. Tests reported as "Not verified: tests not executed locally, CI result pending".
- [ ] Docs: `docs/features/FR-051-error-logging.md`, `docs/help/FR-051-error-logging.md`, `## FR-051` in `CHANGELOG.md`, sandbox checks ER-SB1..ER-SB5 in `docs/TODO.md`.

## Out of scope

- Errors of interactive user actions, API calls, reports and page triggers (phase 2).
- Changes to EQM0001-EQM0009, business events, or the job logic itself (bodies are moved unchanged).
- Retention policy or automatic cleanup (needs install/upgrade code, stop list).
- A telemetry signal for logged errors (phase 3).
- Role Center action or cue.
- `app.json`, `test/app.json`, new permission sets, entitlement objects.
- Changing the existing Equipment Setup AboutText or AdditionalSearchTerms.

## Objects

`al_getnextobjectid` and `al_symbolsearch` returned "No AL projects are loaded", so IDs come from a source scan. If the developer's AL MCP has the project loaded, run `al_getnextobjectid` first and report any difference.

| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Enum | 50113 | EQM Error Operation | New | `app/src/ErrorLog/EQMErrorOperation.Enum.al` |
| Table | 50115 | EQM Error Log Entry | New | `app/src/ErrorLog/EQMErrorLogEntry.Table.al` |
| Page | 50141 | EQM Error Log | New | `app/src/ErrorLog/EQMErrorLog.Page.al` |
| Codeunit | 50142 | EQM Error Log Mgt. | New | `app/src/ErrorLog/EQMErrorLogMgt.Codeunit.al` |
| Codeunit | 50143 | EQM Monitoring Job Runner | New | `app/src/ErrorLog/EQMMonitoringJobRunner.Codeunit.al` |
| Codeunit | 50111 | EQM Warranty Alert Job | Changed (OnRun body) | `app/src/Warranty/EQMWarrantyAlertJob.Codeunit.al` |
| Codeunit | 50114 | EQM Maintenance Monitor Job | Changed (OnRun body) | `app/src/Monitoring/EQMMaintenanceMonitorJob.Codeunit.al` |
| Codeunit | 50115 | EQM Monitoring Job Mgt. | Changed (2 lines) | `app/src/Monitoring/EQMMonitoringJobMgt.Codeunit.al` |
| Page | 50103 | EQM Equipment Setup | Changed (1 action, 1 variable) | `app/src/Setup/EQMEquipmentSetup.Page.al` |
| PermissionSet | 50100 | EQM - Reader | Changed (4 lines) | `app/src/Permissions/EQMReader.PermissionSet.al` |
| PermissionSet | 50102 | EQM - Administrator | Changed (1 line) | `app/src/Permissions/EQMAdministrator.PermissionSet.al` |
| XLIFF | — | g / pt-PT / es-ES | Changed | `app/Translations/*.xlf` |
| Codeunit (test) | 50160 | EQM Error Log Test Subscr | New | `test/src/EQMErrorLogTestSubscr.Codeunit.al` |
| Codeunit (test) | 50154 | EQM Error Log Tests | New | `test/src/EQMErrorLogTests.Codeunit.al` |
| Codeunit (test) | 50155 | EQM Error Log Isolation Tests | New | `test/src/EQMErrorLogIsolationTests.Codeunit.al` |
| Codeunit (test) | 50162 | EQM Role Permission Tests | Changed (2 tests) | `test/src/EQMRolePermissionTests.Codeunit.al` |
| JSON | — | coverage register | Changed | `.github/coverage/coverage-register.json` |

## Events and standard symbols

No base-app event and no new base-app symbol is used. "Job Queue Entry" is already compiled into 50111, 50114, 50115. Platform methods checked on Microsoft Learn (al_symbolsearch unavailable): `Codeunit.Run` (return value commits; commit first if in a transaction), `GetLastErrorText/Code/CallStack`, `ClearLastError`, `Database.IsInWriteTransaction` (already used in 50115), `InherentPermissions` (method scope, runtime 9.0+), `InternalEvent` (as in 50140).

## Steps

1. **Enum 50113 "EQM Error Operation"** (`EQMErrorOperation.Enum.al`): `Extensible = false; Access = Internal; Caption = 'Error Operation';` values `0 " "`, `1 "Warranty Alert Job"`, `2 "Overdue Maintenance Job"`, `3 "Schedule Monitoring Jobs"`, each with Caption. XML summary: "The process of the app that raised a logged error."

2. **Table 50115 "EQM Error Log Entry"** (`EQMErrorLogEntry.Table.al`), shape of table 50112. `Caption = 'Error Log Entry'`, `DataClassification = CustomerContent`, `Access = Internal`. Every field `Editable = false` with Caption and ToolTip:

   | No. | Name | Type | Other | ToolTip |
   |---|---|---|---|---|
   | 1 | "Entry No." | Integer | AutoIncrement | 'Specifies the number of the error log entry.' |
   | 2 | "Logged At" | DateTime | | 'Specifies the date and time when the error happened.' |
   | 3 | "User ID" | Code[50] | EndUserIdentifiableInformation | 'Specifies the user who ran the process that failed. For a job queue entry, this is the user that the job runs as.' |
   | 4 | Operation | Enum "EQM Error Operation" | SystemMetadata | 'Specifies the process that failed: the warranty alert job, the overdue maintenance job, or the scheduling of these jobs.' |
   | 5 | "Object ID" | Integer | SystemMetadata, BlankZero | 'Specifies the ID of the codeunit that ran the process that failed.' |
   | 6 | "Error Message" | Text[2048] | | 'Specifies the error message. It can contain data from the records that were processed.' |
   | 7 | "Error Code" | Text[250] | SystemMetadata | 'Specifies the classification of the error that the platform returned, for support.' |
   | 8 | "Error Call Stack" | Text[2048] | SystemMetadata | 'Specifies the AL call stack at the moment of the error, for support.' |

   Key `PK("Entry No.")` clustered. Fieldgroups `DropDown("Entry No.", "Logged At", Operation, "Error Message")`, `Brick("Logged At", Operation, "Error Message", "User ID")`. Global `InsertAllowed: Boolean`. Labels `InsertNotAllowedErr`, `ModifyNotAllowedErr` (%1 entry no.), `RenameNotAllowedErr` (%1). OnInsert errors unless `InsertAllowed`, then resets it; OnModify and OnRename error; no OnDelete guard. `internal procedure AllowInsertFromErrorLog()` sets the flag.

3. **Page 50141 "EQM Error Log"** (`EQMErrorLog.Page.al`); then add `LookupPageId`/`DrillDownPageId` to the table. List page, `Caption = 'Equipment Error Log'`, `ApplicationArea = All`, `UsageCategory = Administration`, AdditionalSearchTerms, AboutTitle/AboutText, `SourceTableView = sorting("Entry No.") order(descending)`, `Editable = false`, `InsertAllowed = false`, `ModifyAllowed = false`, `DeleteAllowed = true`. Repeater: Entry No. (hidden), Logged At, Operation, Error Message, User ID, Object ID, Error Code (hidden), Error Call Stack (hidden). Action `ShowDetails` ('Show Details', Image ViewDetails) shows `Message(ErrorDetailsMsg, "Error Message", "Error Call Stack")`; promoted in Category_Process.

4. **Codeunit 50142 "EQM Error Log Mgt."** (`Access = Internal`, no Permissions property). Globals for a pending entry. `OnRun` inserts the pending entry if there is one.
   - `LogError(Operation, ObjectId, ErrorMessage, ErrorCode, ErrorCallStack): Boolean` — empty message → false. If `Database.IsInWriteTransaction()` the entry is written in the caller's transaction; otherwise a local `ErrorLogWriter: Codeunit "EQM Error Log Mgt."` gets `SetPendingEntry` and `exit(ErrorLogWriter.Run())` (isolated, commits, never raises into the caller).
   - `LogLastError(Operation, ObjectId): Boolean` — passes `GetLastErrorText/Code/CallStack`.
   - `SetPendingEntry(...)`.
   - `[InherentPermissions(PermissionObjectType::TableData, Database::"EQM Error Log Entry", 'I', InherentPermissionsScope::Permissions)] local procedure InsertPendingEntry()` — Init, set Logged At (`CurrentDateTime()`), User ID (`UserId()`), Operation, Object ID, message/code/stack each via `CopyStr(..., 1, MaxStrLen(...))`, `AllowInsertFromErrorLog(); Insert(true)`.
   - No UI, no explicit Commit, no `Format(enum)`.

5. **Codeunit 50143 "EQM Monitoring Job Runner"** (`Access = Internal`). `OnRun` raises `OnBeforeRunMonitoringJob(JobCodeunitId)` then `case` on the job id to `RunWarrantyAlertJob()` / `RunMaintenanceMonitorJob()` (bodies moved verbatim from 50111/50114, including the `Commit()` and its comment). `SetJob`. `RunJob(JobCodeunitId, Operation)`: if in a write transaction, `JobRunner.Run()` as before and exit; else `ClearLastError(); if JobRunner.Run() then exit; ErrorText := GetLastErrorText(); ErrorLogMgt.LogLastError(...); Error(OriginalErrorTok, ErrorText);` where `OriginalErrorTok` is a Locked `'%1'` label (never `Error(ErrorText)`). `[InternalEvent(false)] internal procedure OnBeforeRunMonitoringJob(JobCodeunitId: Integer)` as the test seam.

6. **Codeunits 50111 and 50114**: replace OnRun bodies with `JobRunner.RunJob(Codeunit::"<self>", "EQM Error Operation"::"<op>");`, only local `JobRunner`. Keep `TableNo`, usings, summaries; append "An error that stops the job is written to the equipment error log."

7. **Codeunit 50115 `TryEnsureMonitoringJobs`**: add local `ErrorLogMgt` and, after `LogNotScheduled(TriggerTok, ErrorReasonTok, GetLastErrorCode());`, call `ErrorLogMgt.LogLastError("EQM Error Operation"::"Schedule Monitoring Jobs", Codeunit::"EQM Monitoring Job Mgt.");`. Extend the doc sentence accordingly.

8. **Page 50103 "EQM Equipment Setup"**: in `area(Navigation)` after `MonitoringJobQueueEntries` add action `ErrorLog` (Caption 'Error Log', ToolTip, `Image = ErrorLog` with fallback `Log`, `RunObject = page "EQM Error Log"`, `Visible = CanReadErrorLog`). In OnOpenPage set `CanReadErrorLog := ErrorLogEntry.ReadPermission();`.

9. **Permission sets**: Reader gets `X` on table 50115, page 50141, codeunits 50142 and 50143 (no tabledata line). Administrator gets `tabledata "EQM Error Log Entry" = RD`. Manager and API Consumer unchanged.

10. **Compile app/** with `al_build` (al_compile does not regenerate `.g.xlf`, DECISIONS FR-056), then `al_getdiagnostics`. If the MCP has no project loaded, use the alc compiler as in FR-053/FR-066. Fix every warning.

11. **Translations**: `python3 .github/scripts/xlf_sync.py sync`, then per language export/fill/import and `xlf_sync.py check` (0 pending, 0 empty). Follow FR-055 glossary and sentence-case rule. New terms:

    | English | pt-PT | es-ES |
    |---|---|---|
    | Error Log | Registo de erros | Registro de errores |
    | Error Log Entry | Movimento do registo de erros | Mov. registro de errores |
    | Operation | Operação | Operación |
    | Error Message | Mensagem de erro | Mensaje de error |
    | Error Code | Código de erro | Código de error |
    | Error Call Stack | Pilha de chamadas do erro | Pila de llamadas del error |
    | Object ID | ID do objeto | Id. de objeto |
    | Show Details | Mostrar detalhes | Mostrar detalles |

    Enum captions: "Tarefa de alertas de garantia" / "Tarea de alertas de garantía"; "Tarefa de manutenção em atraso" / "Tarea de mantenimiento vencido"; "Agendar tarefas de monitorização" / "Programar tareas de supervisión". Keep `' '` for the blank value.

12. **Test codeunit 50160 "EQM Error Log Test Subscr"**: `EventSubscriberInstance = Manual`; `SetFailure(JobCodeunitId, Text)`, `GetRaisedCount()`; subscriber on `OnBeforeRunMonitoringJob` raises `Error(FailTok, FailText)` for the configured job.

13. **Test codeunit 50154 "EQM Error Log Tests"** (AutoRollback, `TestPermissions = Disabled`): scenarios E1-E8 below. Helpers: `OpenWriteTransaction()`, `LastEntryNo()`, `NewErrorText()`, `[TryFunction] TryRaise`. Locked labels for expected texts. Avoid test procedure names LogError, LogLastError, RunJob, SetJob, SetPendingEntry. At most one `asserterror` per test, last.

14. **Test codeunit 50155 "EQM Error Log Isolation Tests"** (AutoCommit, self-cleaning): scenarios I1-I3. Each test commits first and asserts no open write transaction; records start entry no.; binds 50160; runs the job codeunit with an uninserted Job Queue Entry; reads new entries into locals; deletes them and commits; asserts at the end.

15. **Test codeunit 50162**: add `AdministratorCanReadAndDeleteErrorLog` (`'Y--Y-'`) and `OtherRolesCannotReadErrorLog` (`'-----'` for Manager, Reader, API Consumer).

16. **Compile test/** with the refreshed app symbol in `test/.alpackages`. 0 errors, 0 warnings.

17. **`.github/coverage/coverage-register.json`**: add 50115 to `scope.businessLogic.tables` and 50142, 50143 to `...codeunits`; add traces (table 50115 `AllowInsertFromErrorLog` → 50154 `LogErrorStoresAllFields`; codeunit 50142 `SetPendingEntry` → 50154 `LogErrorStoresAllFields`; 50142 `OnRun` → 50155 `MonitorJobFailureIsLoggedAndJobStillFails`; 50143 `RunJob`, `SetJob`, `OnRun` → same). No trace for the publisher. Run `python3 .github/scripts/repo_checks.py` and add any further trace it reports.

18. **Docs**: feature doc, help doc, `## FR-051` CHANGELOG heading, `docs/TODO.md` section "FR-051 sandbox checks" ER-SB1..ER-SB5.

## Tests

Codeunit 50154 (AutoRollback):
- E1 `LogErrorStoresAllFields`: open write transaction; `LogError(...)` returns true; exactly one new entry with all fields, `User ID = UserId()`, Logged At between before/after timestamps.
- E2 `LogLastErrorStoresTheCaughtError`: after a failed `TryRaise`, `LogLastError` returns true; entry has text, error code, non-empty call stack, Operation and Object ID 50111.
- E3 (negative) `LogLastErrorWithoutErrorLogsNothing`: after `ClearLastError()`, returns false, no entry.
- E4 (boundary) `LongErrorTextIsCutNotRejected`: >2048-char message returns true; stored length 2048 and equals `CopyStr`.
- E5 (negative) `EntryCannotBeInsertedDirectly`: `asserterror Insert(true)` gives the insert-not-allowed error.
- E6 (negative) `EntryCannotBeModified`: `asserterror Modify(true)` gives the modify error with the entry number.
- E7 `EntryCanBeDeleted`: `Delete(true)` succeeds; Get returns false.
- E8 (negative) `JobErrorInOpenWriteTransactionIsRaisedUnchanged`: with an open write transaction and 50160 failing 50114 (text contains `%1`), `GetLastErrorText()` equals the text literally.

Codeunit 50155 (AutoCommit):
- I1 `MonitorJobFailureIsLoggedAndJobStillFails`: no open write transaction; 50114 fails; raised error equals the text literally; exactly one entry with Operation "Overdue Maintenance Job", Object ID 50114, message, `User ID = UserId()`, non-empty call stack.
- I2 `WarrantyJobFailureIsLoggedWithItsOperation`: same for 50111.
- I3 (negative) `SuccessfulMonitorJobLogsNothing`: no failure; `GetRaisedCount() = 1`; no entry.

Codeunit 50162: the two permission tests (step 15).

Existing tests likely affected: 50162 `ReaderHasExecuteOnEveryObjectOfTheApp` passes only after step 9. Others unaffected.

Sandbox checks (`docs/TODO.md`):
- ER-SB1: run Entry(50111) as a Reader-only user; job queue entry ends in Error with the same message and the log has one "Warranty Alert Job" entry (also proves the inherent insert permission).
- ER-SB2: make scheduling fail with reason Error; one "Schedule Monitoring Jobs" entry; Setup still opens.
- ER-SB3: Reader and Manager do not see the Setup action; opening the page from Tell Me gives a read-permission error.
- ER-SB4: Administrator can delete entries.
- ER-SB5: pt-PT and es-ES captions show.

## Assumptions

- "Application errors" in phase 1 = errors of the app's unattended processes (two monitoring jobs and their scheduling). Nobody sees those errors, platform telemetry already records error dialogs, and AL has no hook for interactive errors.
- "Date" = Logged At (DateTime, `CurrentDateTime()`), "User" = `UserId()`, "Object ID" = the codeunit that ran the failed operation, "Operation" = enum. Error Code and Error Call Stack added for support.
- An empty error text is not logged. The log is per company.
- The isolated `Codeunit.Run` (implicit commit) is not "Commit in business logic": it runs after the failed run has rolled back and is the platform's isolation mechanism.
- AL-Go's default codeunit-isolation test runner rolls back the commits in 50155; 50155 cleans up anyway.

## DECISIONS

- FR-051 Error Logging | Phase 1 = errors of the unattended monitoring jobs (50111, 50114) and their scheduling (50115) over logging every interactive error, because AL has no global error hook and wrapping user actions in Codeunit.Run changes transaction semantics and drops ErrorInfo actions | Reversible: yes
- FR-051 Error Logging | New table "EQM Error Log Entry" + list page over Job Queue Log Entry or the Error Message framework, because the issue asks for Operation and the scheduling failure has no job queue log | Reversible: no (published table and fields)
- FR-051 Error Logging | Run each job body through an internal runner codeunit with `if not Codeunit.Run`, log, then re-raise the original text with a Locked '%1' label, over subscribing to standard job queue error events (unverifiable) | Reversible: yes
- FR-051 Error Logging | Write the entry in its own isolated Codeunit.Run of the log codeunit (commits) over an explicit Commit or StartSession | Reversible: yes
- FR-051 Error Logging | A job started inside an open write transaction runs as before, unisolated and unlogged, over an error (same guard as FR-018) | Reversible: yes
- FR-051 Error Logging | InherentPermissions (TableData, 'I', scope Permissions) on the single insert procedure over indirect `i` in Reader (breaks FR-036 scenario 7) or Manager (loses the log for a Reader-only job user, FR-018 BG24) | Reversible: yes
- FR-051 Error Logging | Read and delete only for EQM - Administrator, Setup action visible only when ReadPermission() is true, because Error Message can carry customer data and User ID is EUII | Reversible: yes
- FR-051 Error Logging | Entries cannot be inserted directly or modified but can be deleted, because there is no retention policy in phase 1 | Reversible: yes
- FR-051 Error Logging | Fields Logged At, User ID, Operation (enum), Object ID, Error Message (2048, cut), Error Code (250), Error Call Stack (2048, cut), no Object Type field | Reversible: no (published fields)
- FR-051 Error Logging | Entry points Tell Me (Administration) and an Equipment Setup Navigation action, over the Role Center | Reversible: no (published actions)
- FR-051 Error Logging | `[InternalEvent] OnBeforeRunMonitoringJob` on the runner as test seam, consistent with FR-050 | Reversible: yes
- FR-051 Error Logging | Separate AutoCommit test codeunit (50155) with self-cleanup for the isolated path | Reversible: yes
- FR-051 Error Logging | No telemetry signal for logged errors in phase 1 (phase 3) | Reversible: yes
- FR-051 Error Logging | IDs: enum 50113, table 50115, page 50141, codeunits 50142/50143, test codeunits 50154/50155 (superseded FR-001 reservations) and 50160 (unbuilt FR-008 reservation), from a source scan because the AL MCP had no project loaded | Reversible: yes

## Risks

- **Re-raised error loses the original ErrorInfo and code in the job queue.** The Job Queue Log Entry keeps the same message text; its code and call stack now come from the re-raise, the originals are in the EQM error log. Help article must say "see the Equipment Error Log for the call stack".
- **InherentPermissions is a new pattern in this app**, not testable in CI; ER-SB1 checks it. If a reviewer considers it an "entitlement" (stop list), fallback: drop the attribute, add `tabledata "EQM Error Log Entry" = i` to EQM - Manager plus `Permissions = tabledata "EQM Error Log Entry" = ri` on 50142; Reader-only job users then write no entry.
- **Commits in tests (50155).** If CI does not isolate per codeunit, committed entries could leak. 50155 deletes its own entries before asserting; other tests filter `"Entry No." > StartEntryNo`. If CI shows different behaviour, move I1-I3 to sandbox checks and report; do not weaken assertions.
- **`IsInWriteTransaction` at test start**: 50154 opens a write transaction explicitly; 50155 commits first and asserts the precondition.
- **Job body moved.** The warranty job's `Commit()` now runs inside the isolated Codeunit.Run; semantics unchanged. Reviewer: diff moved bodies against originals.
- **Install path.** `TryEnsureMonitoringJobs` runs during OnInstallAppPerCompany; the isolated log write uses the same mechanism as FR-018; guarded by the write-transaction check.
- **Volume**: one entry per failing job per day per company; no cleanup in phase 1 (documented).
- **Privacy**: error text can contain record values; classified CustomerContent, Administrator-only; help article must say so.
- **`Image = ErrorLog`** unverified; fall back to `Log`.
- **Symbols not verified with al_symbolsearch**; no base-app event used; reviewer recompiles.
- **AppSourceCop**: only new objects, one new action, permission lines and OnRun body changes (no signature change); no breaking change expected. No separate AppSource validation ran.

## References

- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorcallstack-method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrorcode-method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext--method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-inherentpermissions-attribute
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-inherent-permissions
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-transactionmodel-attribute
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-testisolation-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-internalevent-attribute
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-image-property
