# FR-032 Equipment Request Process

## Purpose
A user can raise an equipment request for an employee: who needs equipment, which type (an equipment category), why, and when (GitHub issue #70). Requests are numbered from a number series and carry a status (Open, Pending Approval, Approved, Rejected, Completed). In this feature every request is created Open and stays Open: nothing in the app changes the status yet. The transitions (send, approve, reject, complete) belong to FR-033 Approval Workflow. An Open request can be corrected or deleted; a request in any other status is locked.

Status: implemented and merged to `main` via PR #124 (merge commit 8515f62). App version stays 29.0.0.0 (not released), no upgrade code.

## Verification status
- **Build:** app and test app compiled locally with alc 30.0 (CodeCop, UICop): 0 errors, 0 warnings. The AL-Go PR build passed. AppSourceCop reports only the known `app.json` manifest diagnostics.
- **Tests:** codeunit 50188 (`test/src/EQMEquipmentRequestTests.Codeunit.al`, 46 tests) passed in the AL-Go PR build: 168 tests in total, 0 failed, 0 skipped. The first CI run had 13 failures caused by the test structure (in the CI runner the first `asserterror` rolls back the earlier writes of the test); the tests were restructured to one `asserterror` each. No app defect was found.
- **AppSource validator:** READY TO SUBMIT FOR ENVIRONMENT TESTING for the FR-032 scope, no confirmed FAIL (report: `docs/validation/29.0.0.0-FR-032.md`). Warnings to check by hand: the request table reads Employee, which neither EQM permission set grants; number assignment as Manager is untested.
- **Not verified (manual sandbox checklist, not done):** see `docs/TODO.md`, section FR-032.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Enum | 50110 | EQM Request Status | New, `Extensible = false`. 0 Open, 1 Pending Approval, 2 Approved, 3 Rejected, 4 Completed. |
| Table | 50111 | EQM Equipment Request | New, `Access = Public`. The request, its checks and numbering. |
| Page | 50133 | EQM Equipment Requests | New list (read-only), `UsageCategory = Lists`. |
| Page | 50134 | EQM Equipment Request Card | New card, `UsageCategory = None`, `DelayedInsert`. |
| Table | 50102 | EQM Equipment Setup | New field 5 "Request Nos." (additive change on a public table). |
| Page | 50103 | EQM Equipment Setup | Control "Request Nos." in group Numbering; search terms and About text mention requests. |
| Codeunit | 50105 | EQM Default Data | Creates number series EQREQ (starts at REQ00001) when "Request Nos." is blank. |
| PageExtension | 50100 | EQM Employee Card | Action "Equipment Requests" (opens the list filtered on the employee). |
| Page | 50110 | EQM Equipment Manager RC | Embedding action "Equipment Requests". |
| PermissionSet | 50100 / 50101 | EQM - Reader / EQM - Manager | See Permissions. |
| Codeunit (test app) | 50188 | EQM Equipment Request Tests | New. |

## Data model (table 50111)
`DataClassification = CustomerContent`; DataCaptionFields "No.", "Employee No."; Lookup and DrillDown page 50133.

| No. | Field | Type | What it does |
|---|---|---|---|
| 1 | No. | Code[20] | Blank on insert: next number of the Request Nos. series. A manually typed number is allowed only if the series allows manual numbers (`TestManual`). |
| 2 | Employee No. | Code[20] | Employee the equipment is for. On validate: must exist, must not be privacy blocked, status must be Active. |
| 3 | Requested Equipment Type | Code[20] | Code of an "EQM Equipment Category". The lookup shows active categories only; on validate the category must exist and be active. |
| 4 | Justification | Text[250] | Required; blank or spaces-only is rejected. |
| 5 | Request Date | Date | Blank on insert: work date. Cannot be later than today. |
| 6 | Status | Enum 50110 | Not editable, default Open. |
| 7 | No. Series | Code[20] | Series the number came from. Not editable. |
| 8 | Equipment Type Description | Text[100] | FlowField: description of the category. Not editable. |

Keys: PK "No."; EmployeeStatus ("Employee No.", Status); StatusDate (Status, "Request Date"). Field groups DropDown and Brick: No., Employee No., Requested Equipment Type, Request Date, Status.

### Behavior
- **Insert:** takes the number if blank (error if "Request Nos." is blank in the setup), sets the request date if blank, requires Status Open (error otherwise), then runs `CheckRequestConsistency(true)`.
- **Modify:** if the stored record is not Open, error. Otherwise `CheckRequestConsistency(false)`.
- **Delete:** if the stored record is not Open, error.
- **Rename:** always an error (the number cannot be changed).
- `CheckRequestConsistency(IsNewRecord)` (internal): Employee No., Requested Equipment Type and Request Date must be filled in; Justification must not be blank; the employee and the category must exist. The "employee Active and not privacy blocked" and "category active" checks run on insert, or on modify only when the employee or the type differs from the stored record. A request therefore stays editable after its employee leaves or its category is deactivated. The request date must not be later than today. Raises `OnAfterCheckRequestConsistency` last.
- `AssistEdit()` (internal): lets the user choose a related number series for the card's No. field.
- `GetStatusStyle()` (internal): style for the Status column: Open Standard, Pending Approval Ambiguous, Approved Favorable, Rejected Unfavorable, Completed Subordinate.
- Status is not validated against transitions: code that sets a status other than Open on an existing request (for example with `Modify(false)`) is not blocked by FR-032; only the lock applies afterwards.

## Events
Published (table 50111): `OnAfterCheckRequestConsistency(EquipmentRequest: Record "EQM Equipment Request")`, `[IntegrationEvent(false, false)]`, `local procedure`.
- Raised at the end of the consistency check on insert and on modify, after all standard checks passed.
- `EquipmentRequest` is passed by value: changes are not kept. A subscriber can raise an error to reject the save. There is no `IsHandled`, so the status lock cannot be bypassed.
- Same extension point as the other EQM document tables.
No events are subscribed. No events report (only this app's objects change; the only touch outside them is an action on the Employee Card page extension).

## Setup
1. Search "Equipment Setup" and open it. In group Numbering, **Request Nos.** holds the number series for requests.
2. New installations get series EQREQ (REQ00001) and the field filled automatically.
3. Existing companies created before this feature have a blank **Request Nos.** (default data runs only on install or when the setup record is missing). Inserting a request then fails with a TestField error on "Request Nos."; an administrator must choose a number series.

## Permissions
- **EQM - Reader:** `tabledata "EQM Equipment Request"` = R; execute on table 50111 and pages 50133 and 50134. Can see requests, cannot create or change them.
- **EQM - Manager:** `tabledata "EQM Equipment Request"` = RIMD (delete because Open requests can be deleted).
- **EQM - Administrator:** no change; inherits Manager.
Decision Q2 (approved): only Manager and Administrator create and edit; Reader stays read-only.

## Compatibility
Additive; breaking-change risk low. At the first AppSource release, table 50111 (field IDs, names, types), enum 50110 values and the event signature become contracts. Making the enum extensible later (FR-033) is non-breaking; the reverse would be breaking.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and was changed in this branch; never edit by hand.

## Test status
Automated tests: `test/src/EQMEquipmentRequestTests.Codeunit.al`, codeunit 50188. The 46 tests passed in the AL-Go PR build (168 tests in total, 0 failed); the manual sandbox checklist (Reader read-only, Manager raise/edit/delete, Tell Me search, Role Center action, a subscriber blocking the save) is not yet done and is listed in `docs/TODO.md`.

## XML documentation
Already present on the enum, the table's internal procedures (`AssistEdit`, `CheckRequestConsistency`, `GetStatusStyle`), the published event and the changed `CreateDefaultData` comment. Checked, nothing added.

## Out of scope (decided)
- Q1: no status transitions and no actions to send, approve or reject (FR-033).
- Q3 to Q5 are deferred to FR-033: whether Completed creates an assignment (FR-004), whether a request points to specific equipment, and whether requests block deleting an employee.
- Deleting an employee leaves its requests with a dangling Employee No. (see Q5).
- Writes without triggers bypass the checks and the lock, as in every EQM table.
- Justification can contain personal data; it is classified CustomerContent like other free text.

## Discrepancies plan vs code
None found in `app/src/Request/`, setup, permission and navigation files. The code matches the plan, including the pages' Reader/Manager permissions and the default series.
