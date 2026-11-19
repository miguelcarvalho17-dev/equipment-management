# FR-046 Integration Tests — Plan

> Request (verbatim): FR-046 Integration Tests
> Status: **approved**

Issue #87: The solution shall include integration-level tests. Scenarios: Equipment Assignment Flow, Maintenance Flow, Approval Flow, Notification Flow. Business value: validates complete business processes. Depends on FR-045 (test app foundation) and, for the Approval Flow, FR-032/FR-033 (#70, #71).

## Request
FR-046 (issue #87) asks for integration-level tests for four complete business processes: Equipment Assignment Flow, Maintenance Flow, Approval Flow and Notification Flow. This plan first lists which existing tests already cover each flow, then plans only the missing end-to-end tests. They go into the existing test app. Nothing in `app/` changes.

Approval Flow check: FR-032 and FR-033 are built. The pieces are table 50111 "EQM Equipment Request", codeunit 50132 "EQM Request Approval Mgt." with `SendForApproval`, `Approve`, `Reject` and `AssignEquipment`, page 50135 "EQM Request Decision", and the tests 50188 and 50189. The Approval Flow is therefore planned in full.

Target: AppSource

Tooling note: the AL MCP returned "No AL projects are loaded" for `al_getnextobjectid` and `al_symbolsearch`, as in FR-038 to FR-045. The test codeunit ID comes from a scan of every `codeunit NNNNN` in `test/src`, plus the reservations in `docs/`. Every symbol below was checked against app source or against existing test code that already compiles.

## Test coverage (existing tests per flow, and what is missing)

| Flow | Already covered (file: tests) | What is not covered end to end (planned below) |
|---|---|---|
| Equipment Assignment | 50156 `EQMAssignmentTests`: A1 create+assign, A4 open maintenance blocks assign, A5 return closes entry, A6 reassign keeps history. 50180 `EQMEquipmentAPITests`: Assign/Return actions (6). 50182 `EQMAssignmentAPITests`: 7. 50192 `EQMAuditTrailTests`: Assigned and Returned entries, one step each. 50186 `EQMIntegrationEventTests`: Assigned and Returned outbox entries, one step each. 50184 business events. 50189: assign via request. | No test runs create, assign, return and reassign as one process and checks that the history, the audit trail sequence and the integration outbox sequence agree. No test for maintenance taking equipment back and then blocking reassignment in the same process. The Employee delete guard (codeunit 50103) is not tested at all: FR-001 test 50154 was never built. |
| Maintenance | 50164 `EQMMaintenanceTests` M1–M17: registration, posting via `Codeunit.Run`, history, status, planned dates. 50192: Returned before Sent to Maintenance, Updated(Available) on post. 50186 and 50184: maintenance events. 50194, 50197, 50161: cost and count reads. | No test uses the real user path `"EQM Maintenance Mgt.".PostWithConfirmation`, accepted or declined. The NFR-005 maintenance log (Registered, Changed, Posted, codeunit 50116) is never asserted. No test covers the whole process: assigned equipment goes to maintenance, a correction is made, the record is posted, the equipment is Available and is reassigned. No test checks that equipment becomes assignable only after the last open record is posted. |
| Approval | 50189 `EQMRequestApprovalTests` (40): every transition on its own, starting from a status set directly. `StatusChangedEventIsRaisedPerTransition` bypasses the self-approval check with the subscriber and asserts event counts only. 50188 `EQMEquipmentRequestTests`: table rules and numbering. | No test runs request creation from the number series through approval by a different approver to assignment, with its effects on equipment, assignment history, audit trail and outbox. No test checks that returning the equipment later leaves the request Completed. No test covers a rejection reached through the real flow. No test covers equipment that goes into maintenance between approval and assignment. |
| Notification | 50199 `EQMApplicationSetupTests`: `NoNotificationWhenNotificationsAreOff`, `NotificationIsSentWhenNotificationsAreOn`. Both call `SendReturnedFromMaintenanceNotification` directly. FR-017 tests were deferred (50171 reserved, never built). | No test produces a notification from a real business process: posting with confirmation, warranty alert generation, or overdue maintenance. No test for `ShowEquipmentNotifications`, the per-user switch-off in My Notifications, an acknowledged alert, or the 14-day overdue boundary. |

## Definition of done
- [ ] One new test codeunit 50158 "EQM Process Integration Tests" in `test/src/EQMProcessIntegrationTests.Codeunit.al` with the 21 [Test] procedures listed under Tests (Assignment 4, Maintenance 5, Approval 4, Notification 8).
- [ ] No test duplicates an existing one. Each test runs at least two business steps in sequence and asserts the effects across modules.
- [ ] Every flow rule has a positive and a negative test. Negative tests assert the specific error text, or a specific "nothing happened" state when the path has no error.
- [ ] Each test: `[TransactionModel(TransactionModel::AutoRollback)]`; the codeunit has `TestPermissions = Disabled`; `[SCENARIO]/[GIVEN]/[WHEN]/[THEN]` comments; at most one `asserterror`, as the last statement.
- [ ] Test data comes from Locked `Tok` labels with prefix `EQMPIT` plus a Counter, and from `Random()`. No literal business numbers: thresholds come from app getters (`GetMaintenanceOverdueDays`, `GetLongestIntervalDays`). No literal Employee First Name (fixes the FR-045 open MINOR pattern).
- [ ] No file under `app/` changes. Neither `app.json` changes.
- [ ] `test/` compiles with 0 errors and 0 warnings, and `app/` still compiles.
- [ ] Reports say: "Not verified: tests not executed locally, CI result pending." and "No separate AppSource validation ran."
- [ ] Docs updated as in Step 6.

## Out of scope
- Any change in `app/`, including fixes for behaviour a test reveals. The developer reports such findings and does not fix them.
- Changes to `test/app.json` (no Library Random, no new dependency), analyzers, rulesets.
- Changes to the existing 30 test codeunits.
- TestPage-driven UI flows (card actions), Role Center summary notifications (`ShowRoleCenterNotifications`), `ShowMaintenanceRecordNotification`, the notification action handlers, job queue runs, the API pages and Power Automate. These are later phases.
- FR-017 unit tests (reservation 50171 stays as it is).

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Codeunit (Subtype = Test) | 50158 | EQM Process Integration Tests | New | `test/src/EQMProcessIntegrationTests.Codeunit.al` |

ID basis: IDs in use in `test/src` are 50150, 50156, 50157, 50161, 50162, 50164, 50168 and 50177–50199. The free IDs are 50151–50155, 50158–50160, 50163, 50165–50167 and 50169–50176, all reserved in docs for deferred tests of earlier features. 50158 was reserved by FR-006 (assignment history tracking). Those scenarios are now largely covered by 50156 A5/A6 and 50182, so it is the reservation least likely to be needed. No permission set, caption, translation or DataClassification work is needed: test app only, no tables, no UI text.

## Events and standard symbols
`al_symbolsearch` was unavailable (no project loaded). Every symbol below was verified from app source or from existing test code that compiles.

| Symbol | Exact signature | Verified |
|---|---|---|
| Table 50100 `AssignEmployee` | `internal procedure AssignEmployee(EmployeeNo: Code[20])` | `app/src/Equipment/EQMEquipment.Table.al:434` |
| Table 50100 `UnassignEmployee` | `internal procedure UnassignEmployee(): Boolean`. Uses `Confirm Management.GetResponseOrDefault`, so a ConfirmHandler is needed | Source :453 |
| Codeunit 50108 `PostWithConfirmation` | `internal procedure PostWithConfirmation(var MaintenanceRecord: Record "EQM Maintenance Record"): Boolean`. Confirm `PostQst`, then `Codeunit.Run(50109)`, then the returned notification | `EQMMaintenanceMgt.Codeunit.al:258` |
| Codeunit 50108 `GetMaintenanceOverdueDays` | `internal procedure GetMaintenanceOverdueDays(): Integer` | Source :126 |
| Codeunit 50132 | `SendForApproval(var EquipmentRequest: Record "EQM Equipment Request")`, `Approve(var ...; Comment: Text[250])`, `Reject(var ...; Comment: Text[250])`, `AssignEquipment(var ...; EquipmentNo: Code[20])`, all `internal` | `EQMRequestApprovalMgt.Codeunit.al:30-112` |
| Codeunit 50112 "EQM Notification Mgt." | `ShowEquipmentNotifications(Equipment: Record "EQM Equipment")`, `RegisterDefaultNotifications()`, `GetWarrantyNotificationId(): Guid`, `GetOverdueMaintenanceNotificationId(): Guid`, `GetReturnedFromMaintenanceNotificationId(): Guid`, all `internal` | `EQMNotificationMgt.Codeunit.al` |
| Codeunit 50110 "EQM Warranty Alert Mgt." | `GenerateAlerts(ReferenceDate: Date; IsScheduled: Boolean; var CreatedCount: Integer; var CancelledCount: Integer)`, `AcknowledgeAlerts(var WarrantyAlert: Record "EQM Warranty Alert"): Integer`, `GetLongestIntervalDays(): Integer` | `EQMWarrantyAlertMgt.Codeunit.al:44,101,227` |
| Codeunit "EQM Feature Mgt." | `SetFeatureEnabled(Enum::"EQM Feature"::Notifications, false)` | Compiled test 50199:391 |
| Table "My Notifications" | `Disable(NotificationId: Guid): Boolean` | App codeunit 50112:322 |
| Employee `OnBeforeDeleteEvent` | Subscribed by app codeunit 50103 `CheckNoAssignedEquipmentOnBeforeDeleteEmployee` | `EQMEmployeeSubscribers.Codeunit.al:19` |
| Tables/fields | 50100 Status, "Assigned Employee No.", "Warranty End Date", SystemCreatedAt. 50105 "Maintenance Record" ("No.", "Equipment No.", "Maintenance Date", "Maintenance Type", Cost, Description, Status). "EQM Maintenance History Entry" ("Maintenance No.", "Equipment No.", Cost, "Maintenance Type", "Posted By"). "EQM Maintenance Log Entry" ("Entry No.", "Maintenance No.", "Action", "Field No.", "Old Value", "New Value", "User ID"). "EQM Equipment Audit Entry" ("Entry No.", "Equipment No.", "Event Type", "Status After", "Employee No.", "Assignment Entry No.", "Maintenance No."). "EQM Integration Event Entry" ("Entry No.", "Event Type", "Equipment No.", "Assignment Entry No."). "EQM Equipment Assignment" ("Entry No.", "Equipment No.", "Employee No.", Status, "Closing Date"). "EQM Equipment Request" (fields 1–13). "EQM Equipment Setup" ("Request Nos.", "Integration Events Enabled", "Default Warranty Alert Days"). "EQM Warranty Alert" ("Equipment No.", Status). "EQM Feature Setup" | Grep of field declarations in `app/src` |
| Enums | "EQM Audit Event Type" (Created, Updated, Assigned, Returned, "Sent to Maintenance", Disposed). "EQM Integration Event Type" ("Equipment Created", "Equipment Assigned", "Equipment Returned", ...). "EQM Maintenance Log Action" (Registered, Changed, Posted). "EQM Request Status". "EQM Maintenance Type" | Source |
| Library Assert | `AreEqual`, `AreNotEqual`, `IsTrue`, `IsFalse`, `ExpectedError`, `RecordCount`, `RecordIsEmpty` | Compiled tests |
| No. Series / No. Series Line | Pattern of 50189 `CreateNoSeries` | Compiled test 50189:1050 |

No events are published or subscribed by this change.

## Steps
Conventions (copy from `EQMAssignmentTests.Codeunit.al` and `EQMRequestApprovalTests.Codeunit.al`): namespace `MiguelCarvalho.EquipmentManagement.Tests`; usings `Microsoft.Foundation.NoSeries`, `Microsoft.HumanResources.Employee`, `MiguelCarvalho.EquipmentManagement`, `System.Environment.Configuration`, `System.TestLibraries.Utilities`, in the order the compiler and AA0477 accept; `Subtype = Test; TestPermissions = Disabled;`; a `/// <summary>` naming FR-046 and noting that one asserterror is always the last action. Add each label and global together with the first test that uses it, so that every step compiles without unused-variable warnings.

1. `test/src/EQMProcessIntegrationTests.Codeunit.al`: create the codeunit with the foundation, then the Assignment Flow tests AF1–AF4.
   - Globals: `Assert: Codeunit "Library Assert"`, `Counter: Integer`, `SentNotificationIds: List of [Text]`, `LastSentMessage: Text`.
   - Locked Tok labels: `EquipmentNoTok 'EQMPIT%1X'`, `CategoryCodeTok 'EQMPITC%1'`, `EmployeeNoTok 'EQMPITE%1'`, `MaintenanceNoTok 'EQMPITM%1'`, `FirstNameTok 'EQMPIT'`, `CounterFormatTok '<Integer,4><Filler Character,0>'`, `SequenceSeparatorTok ','`.
   - Copied error labels with the same Comment: `MaintenanceOpenAssignErr`: 'You cannot assign equipment %1 because it has open maintenance. Post the open maintenance records of the equipment first.'; `EmployeeHasAssignedEquipmentErr`: 'You cannot delete employee %1 because one or more equipment records are assigned to the employee.'
   - Local helpers: `Initialize()` (`WorkDate(Today())`; `FeatureSetup.DeleteAll()`, missing row = enabled; Get or Init+Insert "EQM Equipment Setup"; set `"Integration Events Enabled" := true` and `"Default Warranty Alert Days" := WarrantyAlertMgt.GetLongestIntervalDays()`, then `Modify(false)`; `Clear(SentNotificationIds); LastSentMessage := ''`), `NextId(): Text`, `CreateEmployee(var Employee)` (Active, not privacy blocked, First Name = FirstNameTok, `Insert(false)`), `CreateCategory(): Code[20]` (Active, `Insert(false)`), `CreateEquipment(var Equipment; CategoryCode: Code[20])` (explicit No. by direct assignment, Description = No., `Insert(true)`, then `Get`), `InitMaintenance(var MaintenanceRecord; EquipmentNo; MaintenanceDate: Date)` (explicit No., Description = No.), `GetAuditSequence(EquipmentNo): Text` (comma list of `"Event Type".AsInteger()` in Entry No. order), `GetOutboxSequence(EquipmentNo): Text`, `CountAssignments(EquipmentNo; Status): Integer`, `GetActiveAssignmentEntryNo(EquipmentNo): Integer`.
   - Handlers: `[ConfirmHandler] ConfirmYesHandler`, `[ConfirmHandler] ConfirmNoHandler`.
   - Add AF1–AF4.
2. Same file: add Maintenance Flow tests MF1–MF5 (user posting path and NFR-005 log).
   - Add helpers `CountLogEntries(MaintenanceNo; LogAction): Integer` and `GetLogSequence(MaintenanceNo): Text`.
   - Add `[SendNotificationHandler(true)] SendNotificationHandler(var TheNotification: Notification): Boolean`: adds `Format(TheNotification.Id)` to `SentNotificationIds`, sets `LastSentMessage := TheNotification.Message`, exits true.
   - Every test that calls `PostWithConfirmation` lists `SendNotificationHandler`.
3. Same file: add Approval Flow tests AP1–AP4.
   - Locked labels: `RequestSeriesTok 'EQMPITS%1'`, `RequestStartNoTok 'EQMPITR%1001'`, `OtherUserTok 'EQMPIT-OTHER'`, `JustificationTok`, `CommentTok`, `RejectCommentTok`.
   - Copied `RequestRejectedErr`: 'Equipment request %1 was rejected. A rejected request cannot be reopened; raise a new request instead.'
   - Helpers: `CreateRequestSeries(): Code[20]` (the 50189 pattern with Counter-based code and start number; sets `EquipmentSetup."Request Nos."`, `Modify(false)`), `CreateRequest(var Request; EmployeeNo; CategoryCode)` (blank "No.", Employee No., Requested Equipment Type, Justification, `Insert(true)`), `SendAndApprove(var Request)` (`SendForApproval`, then `"Sent for Approval By" := OtherUserTok; Modify(false)` as documented in 50189, then `Approve(Request, CommentTok)`).
4. Same file: add Notification Flow tests NF1–NF8.
   - Add `[RecallNotificationHandler(true)] RecallNotificationHandler(var TheNotification: Notification): Boolean` (exit true).
   - Add helper `CountSent(NotificationId: Guid): Integer` (compares `Format(NotificationId)` with the list).
   - Notification tests list `SendNotificationHandler,RecallNotificationHandler`. Add `ConfirmYesHandler` only where `PostWithConfirmation` runs.
   - Call `NotificationMgt.RegisterDefaultNotifications()` in each NF test before the action.
5. Compile `app/`, then `test/` (`al_compile` + `al_getdiagnostics`). If the MCP still has no project loaded, use the alc compiler directly as in FR-038 to FR-045, and compile `app/` from a scratchpad copy so that no `.g.xlf` is regenerated. Fix every warning without pragmas.
6. Docs (al-docs step): `docs/features/FR-046-integration-tests.md`; `docs/help/FR-046-integration-tests.md`; `CHANGELOG.md` section `## FR-046 Integration Tests (version stays 29.0.0.0, no bump)`; `docs/TODO.md` FR-046 section with "Not verified" items and later phases; `docs/features/FR-006-assignment-history-tracking.md` line 69 (the 50158 reservation is now used by FR-046). Run `python3 .github/scripts/repo_checks.py --base origin/main --branch feature/FR-046-integration-tests`.

## Tests
All tests are in codeunit 50158 and are AutoRollback.

**Assignment Flow**
- AF1 `AssignmentLifecycleKeepsHistoryAuditAndOutboxInStep` [ConfirmYesHandler]
  - SCENARIO: create, assign, return and reassign as one process.
  - GIVEN two active employees E1 and E2, and a new category.
  - WHEN equipment X is created, assigned to E1, returned (Yes), and assigned to E2.
  - THEN X is Assigned to E2. There are 2 assignment entries: Closed for E1 with Closing Date = WorkDate, and Active for E2.
  - THEN the audit sequence is exactly Created, Assigned, Returned, Assigned. The second Assigned entry has the Active assignment entry no.
  - THEN the outbox sequence is exactly Equipment Created, Equipment Assigned, Equipment Returned, Equipment Assigned.
  - Extends 50156 A6, 50192 scenarios 2–3, 50186 scenarios 1–3.
- AF2 `MaintenanceTakesEquipmentBackAndBlocksReassignment` (negative) [ConfirmYesHandler]
  - GIVEN X assigned to E1, then a maintenance record registered for X (Yes). Before the final step, assert X is In Maintenance with no employee, and the E1 entry is Closed.
  - WHEN X is assigned to E1 again.
  - THEN `asserterror` with `StrSubstNo(MaintenanceOpenAssignErr, X)`.
- AF3 `EmployeeWithAssignedEquipmentCannotBeDeleted` (negative)
  - GIVEN X assigned to E1. WHEN `E1.Delete(true)`. THEN `asserterror` with `StrSubstNo(EmployeeHasAssignedEquipmentErr, E1)`.
- AF4 `EmployeeCanBeDeletedAfterTheEquipmentIsReturned` [ConfirmYesHandler]
  - GIVEN X assigned to E1 and returned (Yes). WHEN `E1.Delete(true)`.
  - THEN `Employee.Get(E1)` is false. The Closed assignment entry of E1 still exists (history is kept). X is Available.

**Maintenance Flow**
- MF1 `AssignedEquipmentGoesThroughMaintenanceAndIsReassigned` [ConfirmYesHandler, SendNotificationHandler]
  - GIVEN X assigned to E1.
  - WHEN a Corrective record M (Today, random cost) is registered (Yes), posted with `MaintenanceMgt.PostWithConfirmation(M)` (Yes), then X is assigned to E1 again.
  - THEN PostWithConfirmation returned true and M is Posted. 1 history entry for M with X, cost, Corrective and Posted By = UserId.
  - THEN X is Assigned to E1, with 1 Closed and 1 Active assignment entry.
  - THEN the audit trail has Returned with Status After In Maintenance, then Sent to Maintenance with Maintenance No. M, then an Updated entry with Status After Available, then Assigned, in ascending Entry No.
  - Corrective is used so that planned dates do not add Updated entries (M15).
- MF2 `CorrectionBeforePostingIsLoggedAndReachesTheHistory` [ConfirmYesHandler, SendNotificationHandler]
  - GIVEN Available X and an open record M with cost C1.
  - WHEN `Validate(Cost, C2)` + `Modify(true)`, where C2 = C1 + 1 + Random(1000); then `PostWithConfirmation` (Yes).
  - THEN the log sequence for M is exactly Registered, Changed, Posted. The Changed entry has Field No. = `FieldNo(Cost)`, Old Value = `Format(C1,0,9)`, New Value = `Format(C2,0,9)`, User ID = UserId.
  - THEN the history entry Cost = C2.
- MF3 `DecliningThePostingConfirmationChangesNothing` (negative) [ConfirmNoHandler, SendNotificationHandler]
  - GIVEN Available X with open record M. WHEN `PostWithConfirmation(M)` (No).
  - THEN it returns false. M is Open. No history entry for M. The log for M is only Registered. X is In Maintenance. `SentNotificationIds.Count() = 0`.
- MF4 `EquipmentIsAssignableOnlyAfterTheLastOpenRecordIsPosted` [ConfirmYesHandler, SendNotificationHandler]
  - GIVEN Available X with open records M1 and M2, and employee E1.
  - WHEN M1 is posted (Yes). Assert X is still In Maintenance. Then M2 is posted (Yes), then X is assigned to E1.
  - THEN X is Assigned to E1 and has 2 history entries.
- MF5 `PostingOneOfTwoRecordsStillBlocksAssignment` (negative) [ConfirmYesHandler, SendNotificationHandler]
  - GIVEN X with open M1 and M2. M1 is posted (Yes). WHEN X is assigned to E1.
  - THEN `asserterror` with `StrSubstNo(MaintenanceOpenAssignErr, X)`.

**Approval Flow**
- AP1 `RequestIsApprovedAndCompletedWithEquipmentAssigned`
  - GIVEN active employee E1, category K, available X of K, and a request series.
  - WHEN request R for E1/K is created with a blank No. (`Insert(true)`), then `SendAndApprove(R)`, then `AssignEquipment(R, X)`.
  - THEN R has a series number, "No. Series" = the test series, Status Completed, Assigned Equipment No. = X. Sent for Approval By = OtherUserTok. Decided By = UserId. Decision Date = WorkDate. Decision Comment = CommentTok.
  - THEN X is Assigned to E1 with one Active entry.
  - THEN the audit trail has 1 Assigned entry with Employee No. E1 and the Active assignment entry no.
  - THEN the outbox has 1 Equipment Assigned entry with the same assignment entry no.
  - Extends 50189 scenarios 11 and 15.
- AP2 `ReturningEquipmentKeepsTheRequestCompleted` [ConfirmYesHandler]
  - GIVEN AP1 state. WHEN X is returned (Yes).
  - THEN R stays Completed with Assigned Equipment No. = X. X is Available. The E1 entry is Closed.
- AP3 `RejectedRequestCannotGetEquipment` (negative)
  - GIVEN R created and sent, then `Reject(R, RejectCommentTok)`. Before the final step, assert R is Rejected and Decided By = UserId.
  - WHEN `AssignEquipment(R, X)`. THEN `asserterror` with `StrSubstNo(RequestRejectedErr, R."No.")`.
- AP4 `ApprovedRequestCannotGetEquipmentThatWentIntoMaintenance` (negative)
  - GIVEN R approved via `SendAndApprove`, then a maintenance record registered for X (Available, no confirm).
  - WHEN `AssignEquipment(R, X)`. THEN `asserterror` with `StrSubstNo(MaintenanceOpenAssignErr, X)`.

**Notification Flow**
- NF1 `PostingTheLastRecordSendsTheReturnedNotification` [ConfirmYesHandler, SendNotificationHandler, RecallNotificationHandler]
  - GIVEN notifications registered, Available X with open M. WHEN `PostWithConfirmation(M)` (Yes).
  - THEN `CountSent(GetReturnedFromMaintenanceNotificationId()) = 1`, and LastSentMessage contains X."No.".
- NF2 `NoReturnedNotificationWhileOtherMaintenanceIsOpen` (negative) [same handlers]
  - GIVEN X with open M1 and M2. WHEN M1 is posted with confirmation (Yes). THEN the returned-notification count is 0.
- NF3 `UserWhoSwitchedOffTheNotificationGetsNone` (negative) [same handlers]
  - GIVEN registered notifications, and `MyNotifications.Disable(GetReturnedFromMaintenanceNotificationId())` for the current user. X with open M.
  - WHEN M is posted with confirmation (Yes). THEN the returned-notification count is 0, and M is Posted.
- NF4 `GeneratedWarrantyAlertShowsAWarrantyNotification` [SendNotificationHandler, RecallNotificationHandler]
  - GIVEN X with Warranty End Date = Today() + Random(30). `GenerateAlerts(Today(), false, Created, Cancelled)`. X re-read with Get (SystemCreatedAt filled).
  - WHEN `NotificationMgt.ShowEquipmentNotifications(X)`.
  - THEN `CountSent(GetWarrantyNotificationId()) = 1`, and LastSentMessage contains X."No.".
- NF5 `AcknowledgedAlertShowsNoWarrantyNotification` (negative) [same]
  - GIVEN as NF4, then the alerts of X acknowledged (`WarrantyAlert.SetRange("Equipment No.", X)` + `AcknowledgeAlerts`). WHEN ShowEquipmentNotifications(X). THEN the warranty count is 0.
- NF6 `OverdueMaintenanceShowsAnOverdueNotification` [same]
  - GIVEN X with an open record M dated `Today() - GetMaintenanceOverdueDays() - 1 - Random(30)`, and X re-read.
  - WHEN ShowEquipmentNotifications(X). THEN `CountSent(GetOverdueMaintenanceNotificationId()) = 1`, LastSentMessage contains M."No.", and `SentNotificationIds.Count() = 1`.
- NF7 `MaintenanceOpenExactlyTheOverdueDaysIsNotOverdue` (negative, boundary) [same]
  - GIVEN as NF6 but M is dated `Today() - GetMaintenanceOverdueDays()`. WHEN ShowEquipmentNotifications(X). THEN the overdue count is 0.
- NF8 `NotificationsFeatureOffSuppressesEquipmentNotifications` (negative) [same]
  - GIVEN Notifications feature turned off with `SetFeatureEnabled`, and X with an open warranty alert (as NF4) and an overdue open record (as NF6).
  - WHEN ShowEquipmentNotifications(X). THEN `SentNotificationIds.Count() = 0`.

Existing tests likely affected: none. No production code changes. Like 50189, Initialize sets WorkDate(Today()). CI run time grows by 21 tests.

## Assumptions
- One codeunit for the four flows instead of four. The flows share about ten helpers, and only 22 reserved-but-free test IDs are left for future features.
- "Integration-level" means a chain of real business calls in one transaction that checks effects across modules (history, audit trail, outbox, maintenance log, request, notifications), not TestPage UI. UI flows are a later phase.
- Simulating a different approver by overwriting "Sent for Approval By" with `Modify(false)` is acceptable. The technique is documented in 50189 and keeps the real self-approval check active.
- `GuiAllowed()` is true in the AL-Go test session. Existing ConfirmHandler tests (FR-045) and 50199 already depend on it.
- Explicit record numbers set by direct assignment (not Validate) are safe whatever the number series are. `TestManual` runs only in the "No." OnValidate (verified in tables 50100, 50105, 50111).
- `Employee.Delete(true)` on a fresh test employee runs the standard OnDelete without other errors (AF4).
- The audit trail writes no Updated entry for assign and return (verified by 50192 scenarios 2–3), so the AF1 sequence can be asserted exactly.
- `Assert.ExpectedError` is a contains check, as existing tests rely on.

## DECISIONS
- FR-046 structure | One test codeunit "EQM Process Integration Tests" with four flow sections over four codeunits, because the flows share helpers and free test IDs are scarce | Reversible: yes
- FR-046 test ID | 50158 (the FR-006 reservation, whose scenarios are largely covered by 50156 and 50182) over 50171 (FR-017, still needed) or widening `test/app.json` (stop list). ID from a source scan because the MCP had no project loaded | Reversible: yes
- FR-046 approval simulation | Overwrite "Sent for Approval By" with Modify(false) over binding test subscriber 50190 to bypass the self-approval check, so the real approver rule runs | Reversible: yes
- FR-046 maintenance path | `PostWithConfirmation` (user path, confirm and notification) over `Codeunit.Run(50109)`, because FR-045 covers the codeunit path and the confirmation path was untested | Reversible: yes
- FR-046 scope | Cover the Employee delete guard (codeunit 50103) inside the Assignment Flow; leave Role Center summary notifications, maintenance-card notification and TestPage flows to later phases | Reversible: yes

## Risks
- The MCP could not verify symbols or allocate IDs. The reviewer should recheck that 50158 is still unused in `test/src` and that the copied error texts match `app/` exactly.
- GuiAllowed in CI: if false, NF1, NF4 and NF6 would see no notification and the ConfirmHandlers would not be called. 50199 and FR-045 tests share this dependency. The reviewer should read the CI log for 50199 `NotificationIsSentWhenNotificationsAreOn`.
- Recall without a handler: `ShowEquipmentNotifications` always calls `Recall()`. Every NF test that calls it must list `RecallNotificationHandler`. Both notification handlers are optional (`(true)`). ConfirmYesHandler and ConfirmNoHandler are not optional: list them only where a confirm really happens.
- Warranty window: NF4, NF5 and NF8 depend on Initialize setting "Default Warranty Alert Days" to `GetLongestIntervalDays()`, and on a deleted Feature Setup. `GenerateAlerts` also processes other equipment in the company, so assertions filter on the test's own equipment or notification Id.
- Overdue boundary: NF6 and NF7 use `Today()` because codeunit 50112 uses `Today()`, not WorkDate. If the test crosses midnight, NF7 could flip. Accepted as negligible.
- AF4 depends on the standard Employee OnDelete. If it fails for an unrelated reason, the developer reports it and must not change `app/`.
- Exact sequences (AF1 audit and outbox, MF2 log) break if a later feature adds entries. That is intended.
- The CI result stays unknown until the push. A failing test may reveal an app defect; fixing it is outside this plan.
- Later phases: (2) TestPage flows (Equipment Card actions, Request Card actions); (3) Role Center and maintenance-card notifications, notification action handlers; (4) job-queue-driven flows (warranty job, overdue check), Power Automate and API flows.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-test-codeunits-and-test-methods
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-handlerfunctions-attribute
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-recallnotificationhandler-attribute
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-creating-handler-methods
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/notification/notification-recall-method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-application

No separate AppSource validation ran.
