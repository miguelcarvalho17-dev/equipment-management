# FR-033 Approval Workflow

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
A manager sends an Open equipment request (FR-032) for approval. Another manager approves or rejects it, and the decision is recorded with user, date and comment. An Approved request can be completed with the action "Assign Equipment", which assigns available equipment of the requested type to the employee (FR-004 logic) and sets the request to Completed. Rejected and Completed requests are final (GitHub issue #71).

Status: implemented on branch `feature/FR-033-approval-workflow`, not committed, not merged. App version stays 29.0.0.0 (unreleased), no upgrade code.

Decisions (plan approved): Q1 own (simple approval in this app, not BC Approvals Management or Workflow), Q2 noself (the sender cannot approve), Q3 action (assignment from the request is an extra action; direct assignment from the Equipment Card and the API is unchanged), Q4 none (approval does not check stock), Q5 no (employee deletion is not blocked).

## Verification status
- **Tests: pass in AL-Go CI (PR #126).** Test codeunit 50189 (41 tests) and helper 50190 ran in the AL-Go PR build: 209 test functions in total, 0 failures. Not run in a BC sandbox. The first CI run had 10 failing tests in 50189 because they read the database after an `asserterror` (the runner rolls back the test transaction); they were split to one case per procedure.
- **Build:** app and test app compile with 0 errors and 0 warnings (CodeCop, UICop; alc 30.0 locally) and the AL-Go PR build was green. AppSourceCop reports only the known app.json manifest diagnostics.
- **AppSource validator:** READY TO SUBMIT FOR ENVIRONMENT TESTING for the FR-033 scope (source only); see `docs/validation/29.0.0.0-FR-033.md`.
- **Not verified:** everything in `docs/TODO.md`, section "FR-033 sandbox checks".

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Codeunit | 50132 | EQM Request Approval Mgt. | New, `Access = Public`. State machine, checks, UI wrappers, 2 events. Procedures are `internal`. |
| Page | 50135 | EQM Request Decision | New, StandardDialog, `UsageCategory = None`. Instruction text and a multi-line comment. |
| Table | 50111 | EQM Equipment Request | Fields 9-13 added; Status ToolTip, table summary and `OnAfterCheckRequestConsistency` summary updated. |
| Enum | 50110 | EQM Request Status | Summary only. Values and `Extensible = false` unchanged. |
| Page | 50134 | EQM Equipment Request Card | Group Approval (fields 9-13), actions Send for Approval, Approve, Reject, Assign Equipment (Process group, promoted). |
| Page | 50133 | EQM Equipment Requests | Same four actions; columns "Decided By" and "Decision Date" (hidden by default) and "Assigned Equipment No.". |
| PermissionSet | 50100 | EQM - Reader | Execute on codeunit 50132 and page 50135. |
| Codeunit (test) | 50189 / 50190 | EQM Request Approval Tests / EQM Request Appr. Test Subscr | New. |

## Data model (new fields on table 50111)
All fields are not editable and are set only by codeunit 50132.

| No. | Field | Type | What it does |
|---|---|---|---|
| 9 | Sent for Approval By | Code[50] | User who sent the request for approval (`UserId`). EndUserIdentifiableInformation; TableRelation User."User Name", `ValidateTableRelation = false`. |
| 10 | Decided By | Code[50] | User who approved or rejected. Same classification and relation. |
| 11 | Decision Date | Date | Work date of the decision. |
| 12 | Decision Comment | Text[250] | Comment of the decision. Required for a rejection, optional for an approval. |
| 13 | Assigned Equipment No. | Code[20] | Equipment assigned when the request was completed. TableRelation "EQM Equipment"."No.". |

Existing rows get blank values.

## Behavior (codeunit 50132)
State machine: Open > Pending Approval > Approved > Completed, and Pending Approval > Rejected. Every procedure first raises an error if the request is Rejected, then checks the expected status. Each transition saves with `Modify(false)` (the FR-032 OnModify lock rejects every Modify(true) on a request that is not Open), so table OnModify subscribers are not raised for transitions; use `OnAfterRequestStatusChanged` instead.

| Procedure | Requires | What it does |
|---|---|---|
| `SendForApproval(var Request)` | Open | Runs `CheckRequestConsistency(true)` (employee and type must still be active), sets "Sent for Approval By" = current user, Status = Pending Approval. |
| `Approve(var Request; Comment)` | Pending Approval | Runs the approver check (see Events), sets "Decided By", "Decision Date" (work date), "Decision Comment", Status = Approved. A blank comment is accepted. |
| `Reject(var Request; Comment)` | Pending Approval | Comment must not be blank or only whitespace. Sets the decision fields, Status = Rejected. The sender may reject their own request. |
| `AssignEquipment(var Request; EquipmentNo)` | Approved | Equipment must exist and its "Category Code" must equal "Requested Equipment Type". Calls `Equipment.AssignEmployee` (FR-004 checks: availability, maintenance, employee). Sets "Assigned Equipment No." and Status = Completed, in one transaction. |
| `ApproveWithDialog`, `RejectWithDialog` | as above | Open page 50135 with an instruction text; do nothing if the user does not choose OK. |
| `AssignEquipmentWithLookup` | Approved | Opens "EQM Equipment List" in lookup mode filtered on the requested category and status Available. If none exists: message and exit. Cancel: exit. |

Page actions on the card are enabled by status (Send: Open; Approve and Reject: Pending Approval; Assign Equipment: Approved). On the list the four actions have no status-based enabling; the codeunit raises the status error instead.

Error messages: Rejected request ("cannot be reopened; raise a new request instead"); not Open; not Pending Approval; self-approval; missing rejection comment; not Approved; equipment not found; equipment category differs from the requested type. All are labels with a Comment in codeunit 50132.

## Events
Published in codeunit 50132, both `[IntegrationEvent(false, false)]`, `local procedure`:
- `OnBeforeCheckApproverAllowed(EquipmentRequest: Record "EQM Equipment Request"; var IsHandled: Boolean)`. Raised in Approve before the self-approval check. Set `IsHandled` to skip only that check (for example to allow self-approval in a small company); raise an error to deny. The status rules cannot be bypassed. The record is passed by value.
- `OnAfterRequestStatusChanged(EquipmentRequest: Record "EQM Equipment Request"; PreviousStatus: Enum "EQM Request Status")`. Raised after every successful transition is saved (Send, Approve, Reject, Assign Equipment). Notification only: no `IsHandled`, do not show UI or commit. Not raised when a transition fails.

Also, `OnAfterCheckRequestConsistency` (table 50111, FR-032) is raised when a request is sent for approval.
No events are subscribed. No events report (only this app's objects change).

## Permissions
- EQM - Reader: execute on codeunit 50132 and page 50135. Reader has read access to requests only, so a Reader who runs an action gets the platform permission error.
- EQM - Manager: already has RIMD on requests, RIM on equipment and Rim on assignments, which the transitions need. Administrator inherits.
- Who may approve is decided by the permission sets: there is no separate approver setup.

## Compatibility
Additive; breaking-change risk low. Published table 50111 and pages 50133 and 50134 get new fields and controls only; enum 50110 is unchanged. Equipment, assignment and API objects are unchanged. At the first AppSource release, codeunit 50132 (name, ID), its two event signatures and fields 9-13 become contracts.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build (changed in this branch); never edit by hand.

## Test status
Test codeunit 50189 (`test/src/EQMRequestApprovalTests.Codeunit.al`, 41 tests) and helper codeunit 50190 (`test/src/EQMRequestApprTestSubscr.Codeunit.al`, manual subscriber with counters). **The tests pass in AL-Go CI (PR #126; not run in a BC sandbox).** Because an `asserterror` rolls back the test transaction in the runner, each failing case is its own test and asserts only the error text; the "state unchanged after the error" checks (request still Open or Pending, equipment still Available, no assignment entry) are therefore not covered by any test. They cover plan scenarios 1-16: sending (including inactive employee, wrong status), approval (decision fields, blank comment, self-approval, subscriber handling), rejection (own request, required comment), wrong-status errors, final Rejected status, assignment (success, before approval, wrong category, already assigned, inactive employee), event counts, card action enablement, dialog and lookup behavior. Scenario 17 is manual only.

## XML documentation
Already present on all procedures and both events of codeunit 50132, on the page 50135 procedures, and on the table and enum summaries. Checked, nothing added.

## Out of scope (decided)
- Q1: no BC Approvals Management or Workflow, no approver setup, no notifications, no withdraw or reopen.
- Q3: direct assignment from the Equipment Card and the API still needs no request.
- Q4: approving does not check stock; equipment is chosen at assignment.
- Q5: deleting an employee leaves Pending Approval or Approved requests with a dangling Employee No.; Assign Equipment then fails with the FR-004 employee error.
- Writes without triggers bypass the state machine, as in every EQM table.
- Fields 9 and 10 hold user names and the decision comment can contain personal data. TODO(verify): personal-data handling.

## Discrepancies plan vs code
None found in `app/src/Request/`, the permission set or the pages. Test count: the plan lists 16 automated scenarios; the test codeunit has 41 tests (multi-case scenarios were split to one test per case after the first CI run).
