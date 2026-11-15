# FR-032 Equipment Request Process

> Status: **DRAFT, awaiting approval.** Source: GitHub issue #70 (milestone V3). Branch `feature/FR-032-equipment-request-process`. No events report: only this app's objects change, the only base touch is a UI action on the standard Employee Card page extension (as FR-004 D7). No version bump (29.0.0.0, unreleased), no upgrade code.
> **Open questions (the plan uses the recommended default, so each answer can be one word):**
> - **Q1 Status transitions.** **none** (recommended): FR-032 only stores requests; every new request is Open, Status is read-only, and the transitions (send, approve, reject, complete) belong to FR-033 Approval Workflow. **manual**: add actions Send for Approval / Approve / Reject / Complete / Reopen with a fixed transition table now (needs a replan; overlaps FR-033).
> - **Q2 Who raises requests.** **manager** (recommended): EQM - Manager and Administrator; Reader stays read-only (NFR-002 "a Reader changes nothing"). **reader**: Reader may also raise requests (self-service; `RI` in Reader).

## Goal
Users can raise an equipment request for an employee: who needs it, which type of equipment, why, and when it was requested. Each request gets a number from a number series and a status (Open, Pending Approval, Approved, Rejected, Completed). In this feature every request starts and stays Open; it can be corrected or deleted while Open and is locked once another feature moves it on.

## Approach and rejected alternatives
- Chosen: new document-like table "EQM Equipment Request" with its own number series (new field on "EQM Equipment Setup"), non-extensible status enum, list and card pages, all logic inside the table (pattern of table 50105 "EQM Maintenance Record"). "Requested Equipment Type" is a Code[20] related to **"EQM Equipment Category"** (active only), because categories already are the equipment types (LAPTOP, MONITOR, PHONE...), and FR-033/fulfilment can later match available equipment by "Category Code" without a mapping table.
- Rejected: a new "EQM Equipment Type" table. It duplicates the category master data and needs a mapping to equipment.
- Rejected: free text or an enum for the type. Text cannot be matched to equipment; an enum cannot be maintained by customers.
- Rejected: a management codeunit. With Q1 = none there is no process logic; the table holds the checks (as 50105). FR-033 adds the codeunit.
- Rejected: an API page, business events, notifications or a Role Center cue. Not requested; API reserve pages 50127-50129 and FR-038 (pending-approval KPI) cover them later.
- Rejected (FR-043 Application Setup): not found in the repo (no plan, no code). The existing "EQM Equipment Setup" (50102) is the setup table, as for Equipment Nos. and Maintenance Nos.

## Objects
IDs in use (checked `app/src`, `test/src`): tables 50100-50110, enums 50100-50109, pages 50100-50126 and 50130-50132 (50127-50129 API reserve), codeunits 50103-50122 and 50130-50131, pageext 50100-50101, permsets 50100-50102; test codeunits 50178-50187 (50150-50177 reserved, 50188 freed by FR-031). Folder `app/src/Request/`, namespace `MiguelCarvalho.EquipmentManagement`.
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50110 | EQM Request Status | New | `EQMRequestStatus.Enum.al`; 0 Open, 1 "Pending Approval", 2 Approved, 3 Rejected, 4 Completed; `Extensible = false` |
| Table | 50111 | EQM Equipment Request | New | `EQMEquipmentRequest.Table.al`; the request, checks, numbering, one event |
| Page | 50133 | EQM Equipment Requests | New | `EQMEquipmentRequests.Page.al`; List, Lookup/DrillDown/searchable |
| Page | 50134 | EQM Equipment Request Card | New | `EQMEquipmentRequestCard.Page.al`; Card, entry point for new requests |
| Table / Page / Codeunit | 50102 / 50103 / 50105 | EQM Equipment Setup / Setup page / EQM Default Data | Modify (own) | Field 5 "Request Nos.", its page control, default series EQREQ. **Additive change on public table 50102** |
| PageExtension | 50100 | EQM Employee Card | Modify (own) | Action "Equipment Requests" in group EQMEquipment |
| Page | 50110 | EQM Equipment Manager RC | Modify (own) | Embedding action "Equipment Requests" after AssignmentList |
| PermissionSet | 50100 / 50101 | EQM - Reader / Manager | Modify (own) | See Permissions |
| Codeunit (test) | 50188 | EQM Equipment Request Tests | New | `test/src/EQMEquipmentRequestTests.Codeunit.al` |

## Data model and upgrade impact
- Table 50111: Caption 'Equipment Request', `DataClassification = CustomerContent` at table level (no field overrides), `Access = Public`, LookupPageId/DrillDownPageId 50133, DataCaptionFields "No.", "Employee No.". Every field has Caption + ToolTip. Fields: 1 "No." Code[20] (OnValidate `TestManual` on "Request Nos." and clear "No. Series", as 50105). 2 "Employee No." Code[20], TableRelation Employee."No.", OnValidate: if not blank, CheckEmployeeEligible. 3 "Requested Equipment Type" Code[20], TableRelation "EQM Equipment Category" where(Active = const(true)), `ValidateTableRelation = false`, OnValidate: if not blank, CheckEquipmentTypeAllowed. 4 Justification Text[250]. 5 "Request Date" Date, OnValidate: not later than Today(). 6 Status Enum 50110, `Editable = false`, InitValue Open. 7 "No. Series" Code[20], TableRelation "No. Series", Editable false. 8 "Equipment Type Description" Text[100] FlowField lookup("EQM Equipment Category".Description where(Code = field("Requested Equipment Type"))), Editable false.
- Keys: PK "No." clustered; EmployeeStatus ("Employee No.", Status); StatusDate (Status, "Request Date"). Fieldgroups DropDown and Brick: "No.", "Employee No.", "Requested Equipment Type", "Request Date", Status.
- Triggers: **OnInsert** number series exactly as 50105 (TestField "Request Nos."; `AreRelated`; `GetNextNo`); blank "Request Date" := WorkDate(); Status <> Open -> Error(InsertNotOpenErr); CheckRequestConsistency(true). **OnModify** stored Status (SetLoadFields(Status), Get) <> Open -> Error(RequestNotOpenErr); then CheckRequestConsistency(false). **OnDelete** stored Status <> Open -> Error(DeleteNotOpenErr). **OnRename** Error(RenameNotAllowedErr).
- `internal procedure CheckRequestConsistency(IsNewRecord)`: TestField "Employee No.", "Requested Equipment Type", "Request Date"; Justification blank after `DelChr(.., '<>', ' ')` -> JustificationRequiredErr; employee must exist (EmployeeNotFoundErr); category must exist (CategoryNotFoundErr); Active/privacy check of the employee and Active check of the category only when IsNewRecord or the value differs from the stored record (a request stays editable after its employee leaves or its category is deactivated); request date not in the future; raise OnAfterCheckRequestConsistency(Rec).
- Local CheckEmployeeEligible: SetLoadFields(Status, "Privacy Blocked"); not found -> EmployeeNotFoundErr; Privacy Blocked -> EmployeePrivacyBlockedErr; Status <> Active -> EmployeeNotActiveErr. Local CheckEquipmentTypeAllowed: not found -> CategoryNotFoundErr; not Active -> CategoryInactiveErr. Also `internal procedure AssistEdit(): Boolean` (copy of 50105 on "Request Nos.") and `internal procedure GetStatusStyle(): Text` (Open Standard, Pending Approval Ambiguous, Approved Favorable, Rejected Unfavorable, Completed Subordinate; Locked `Tok` labels).
- Labels (one sentence each, Comment for placeholders): EmployeeNotFoundErr 'Employee %1 does not exist.'; EmployeeNotActiveErr 'You cannot raise an equipment request for employee %1 because the employee status is %2.'; EmployeePrivacyBlockedErr 'You cannot raise an equipment request for employee %1 because the employee is blocked for privacy reasons.'; CategoryNotFoundErr 'Equipment type %1 does not exist. Choose a category from the Equipment Categories page.'; CategoryInactiveErr 'You cannot request equipment type %1 because the category is not active.'; JustificationRequiredErr 'You must enter a justification for the equipment request.'; FutureDateErr 'The request date %1 is in the future. Enter a date that is not later than today (%2).'; InsertNotOpenErr 'Equipment request %1 must be created with the status Open.'; RequestNotOpenErr 'You cannot change equipment request %1 because its status is %2. Only open requests can be changed.'; DeleteNotOpenErr 'You cannot delete equipment request %1 because its status is %2. Only open requests can be deleted.'; RenameNotAllowedErr 'You cannot change the number of equipment request %1.'.
- Setup 50102 field 5 "Request Nos." Code[20], TableRelation "No. Series", ToolTip 'Specifies the number series used to assign numbers to new equipment requests.'. Default data 50105: labels RequestSeriesCodeTok 'EQREQ', RequestSeriesStartTok 'REQ00001', RequestSeriesDescriptionTxt 'Equipment Requests'; same block as Maintenance Nos.; update the doc comment.
- No upgrade codeunit (unreleased). Existing dev companies get a blank "Request Nos." (CreateDefaultData runs only on install or a missing setup record): inserting a request fails on TestField until an administrator fills it. Documented, see R2.

## Events
- Subscribed: none. Published (table 50111): `[IntegrationEvent(false, false)] local procedure OnAfterCheckRequestConsistency(EquipmentRequest: Record "EQM Equipment Request")`, no IsHandled, by value; doc comment as 50105's OnAfterCheckMaintenanceConsistency ("raise an error to reject the save"). Same extension point every EQM document table offers; no IsHandled so the status lock cannot be bypassed.

## Permissions
- EQM - Reader: `tabledata "EQM Equipment Request" = R`; X on table 50111, pages 50133 and 50134 (keep object-type grouping). Manager: `tabledata "EQM Equipment Request" = RIMD` (D because Open requests can be deleted). Administrator: no change (inherits; already RIMD on setup). Enum and pageext need no entries.

## Compatibility
- Additive. **Breaking-change risk: low.** New field on public table 50102 (additive), new action on own pageext 50100 and RC 50110. At the first AppSource release table 50111 (field IDs/names/types), enum 50110 values and the event signature become contracts. Making enum 50110 extensible later (FR-033) is non-breaking; the reverse would be breaking.

## Implementation steps
1. Enum 50110 with `/// <summary>` ("Status of an equipment request; FR-032 creates requests as Open"). Compile.
2. Setup field 5; page 50103 control in group Numbering after "Maintenance Nos.", add 'equipment request numbers' to AdditionalSearchTerms and "equipment requests" to the AboutText sentence on number series; Default Data block. Compile.
3. Table 50111, page 50133 and page 50134 together (they reference each other). List: Caption 'Equipment Requests', UsageCategory Lists, CardPageId 50134, `Editable = false`, SourceTableView sorting("No.") order(descending); columns No., Request Date, Employee No., Employee Name (page variable, same guarded full-name code as page 50104), Requested Equipment Type, Equipment Type Description, Justification, Status (StyleExpr from GetStatusStyle); Navigation action Employee (page "Employee Card", RunPageLink "No." = field("Employee No."), Image Employee) with actionref; views after actions: Open, PendingApproval, Approved, Rejected, Completed (filter on Status); AboutTitle/AboutText; AdditionalSearchTerms 'equipment requests, request equipment, equipment request process'. Card: Caption 'Equipment Request', UsageCategory None, DelayedInsert, group General `Editable = IsOpen` (IsOpen := Rec.Status = Open, set in OnAfterGetCurrRecord) with No. (OnAssistEdit as 50114), Employee No. (ShowMandatory, Promoted), Employee Name (read-only), Requested Equipment Type (ShowMandatory), Equipment Type Description, Justification (MultiLine, ShowMandatory), Request Date, Status (StyleExpr). Compile.
4. Pageext 50100: action `EQMEquipmentRequests` (Caption 'Equipment Requests', ToolTip 'View the equipment requests raised for the employee.', RunObject page 50133, RunPageLink "Employee No." = field("No."), an Image that compiles, e.g. Document) after EQMAssignedEquipment. RC 50110: Embedding action `RequestList` (Caption 'Equipment Requests', ToolTip 'Open the equipment requests.') after AssignmentList. Compile.
5. Permission sets. Build the app; commit the regenerated `.g.xlf`.
6. Test codeunit 50188 (pattern of 50183: Subtype Test, TestPermissions Disabled, AutoRollback, Library Assert, Locked test labels prefix `EQMREQ`, copies of app labels). Initialize: active category, inactive category, Active/Inactive/privacy-blocked employees, a test No. Series + line, setup record (Get or Insert) with "Request Nos." set. Build the test app.
7. Documenter: feature doc, help (raise a request, statuses and that only Open is used until FR-033, setup of Request Nos.), CHANGELOG, TODO section "FR-032 sandbox checks" (scenario 16).

## Test scenarios
1. Given setup Request Nos. = test series, when a request (active employee, active type, justification) is inserted with blank No., then No. comes from the series, "No. Series" is set, Status = Open, Request Date = WorkDate.
2. Given a past Request Date, when inserted, then the date is kept.
3. (neg) Request Date = Today + 1 on validate and on insert gives FutureDateErr; no row.
4. (neg) Blank Employee No. or blank type gives a TestField error; blank or spaces-only Justification gives JustificationRequiredErr; no row.
5. (neg) Non-existing employee gives EmployeeNotFoundErr; Inactive employee EmployeeNotActiveErr; privacy-blocked employee EmployeePrivacyBlockedErr (validate and insert).
6. (neg) Non-existing type gives CategoryNotFoundErr; inactive category CategoryInactiveErr (validate and insert).
7. Given an Open request whose employee became Inactive and whose category was deactivated afterwards, when Justification is changed and Modify(true) runs, then it succeeds; changing the employee to another Inactive employee fails.
8. (neg) Insert with Status = Pending Approval gives InsertNotOpenErr.
9. Given an Open request, Modify(true) of Justification succeeds and Delete(true) deletes it.
10. (neg) For each of Pending Approval, Approved, Rejected, Completed (set with Modify(false)): Modify(true) gives RequestNotOpenErr, Delete(true) gives DeleteNotOpenErr; the record is unchanged.
11. (neg) Rename gives RenameNotAllowedErr.
12. Enum 50110 has exactly 5 values, ordinals 0-4, names Open, Pending Approval, Approved, Rejected, Completed.
13. CalcFields "Equipment Type Description" returns the category description.
14. TestPage: new card filled and closed creates an Open request; on a Completed request the General fields are not editable; list view Open shows only Open requests; Employee Card action opens the list filtered on that employee.
15. Given setup with blank Request Nos., CreateDefaultData creates series EQREQ (REQ00001) and fills it; an existing value is kept.
16. Sandbox (manual): Reader sees requests but cannot insert; Manager raises, edits and deletes an Open request; Tell Me finds "Equipment Requests"; RC action works; a subscriber to OnAfterCheckRequestConsistency that errors blocks the save.

## Risks and open questions
- Q1, Q2: see the top. Also open, outside the issue: Q3 does Completed create the assignment (FR-004) automatically? Q4 should a request point to specific equipment, or should approval require available equipment of the type? Q5 should requests block deleting the employee (FR-001 guard)? Default for all three: not in FR-032; decide in FR-033.
- Assumed "Requested Equipment Type" = equipment category, because categories are the app's equipment types and keep requests matchable to equipment.
- Assumed Justification is mandatory Text[250], because a request without a reason cannot be approved; and Request Date defaults to WorkDate, editable while Open, not in the future (as Maintenance Date).
- Assumed no "Requested By" field, because the issue does not ask for it and SystemCreatedBy records it.
- Assumed status changes by code from Open are not validated in FR-032 (only the lock after leaving Open), because transition rules belong to FR-033 (Q1).
- Assumed IDs 50110/50111/50133/50134/50188 (next free; pages skip the 50127-50129 API reserve; 50188 was freed by FR-031).
- R1 FR-043 Application Setup does not exist in the repo; if it is built later it should absorb "Request Nos." (would be a field move on a public table).
- R2 Companies set up before FR-032 have a blank "Request Nos." (TODO item on defaults only when setup is missing); the TestField error names the field.
- R3 Trigger-less writes bypass all checks and the lock, as in every EQM table. R4 Deleting an employee leaves their requests with a dangling Employee No. (Q5). R5 Justification may contain personal data; classified CustomerContent like other free text (TODO personal-data item).
