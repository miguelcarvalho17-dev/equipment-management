# FR-033 Approval Workflow

> Status: **Approved.** Decisions: Q1 own, Q2 noself, Q3 action, Q4 none, Q5 no. Source: GitHub issue #71. Branch `feature/FR-033-approval-workflow`. Builds on FR-032 (table 50111, enum 50110) and FR-004 (`AssignEmployee` on table 50100). No events report needed with the defaults below: only this app's objects change, and no standard behavior is touched. No version bump (29.0.0.0, unreleased), no upgrade code.
> **Open questions (the plan uses the recommended default, so each answer can be one word):**
> - **Q1 Approval engine.** **own** (recommended): simple approval in this app. Send for Approval, Approve and Reject actions, with sender, decider, date and comment fields on the request. **standard**: use BC Approvals Management and Workflow (Approval Entry, workflow template, user approver setup). That needs an al-event-finder run first ("Workflow Event Handling", "Workflow Response Handling", "Approvals Mgmt." publishers), and a replan of about three times this scope.
> - **Q2 Who approves.** **noself** (recommended): any user with EQM - Manager or Administrator, except the user who sent the request for approval. **any**: self-approval is also allowed (no second user is needed in small companies).
> - **Q3 Approval to assignment.** **action** (recommended): a new "Assign Equipment" action on an Approved request. It lists the Available equipment of the requested type, assigns the chosen equipment through the FR-004 logic and sets the request to Completed. Direct assignment from the Equipment Card and the API stays as it is. **strict**: every assignment also needs an approved request. This blocks the FR-004 card action and the FR-026 API `assign`, which is a breaking behavior change.
> - **Q4 Availability at approval.** **none** (recommended): approval does not check the stock. Equipment is chosen at assignment, and if none is available the user gets a message. **check**: Approve fails when no Available equipment of the type exists.
> - **Q5 Employee deletion.** **no** (recommended): not part of this issue; this stays as risk R3. **block**: extend subscriber 50103 so that an employee with Pending Approval or Approved requests cannot be deleted. FR-001-events already covers this event.

## Goal
A manager sends an Open equipment request for approval. Another manager approves or rejects it, and the decision is recorded with the user, date and comment. Only an Approved request can lead to an assignment: "Assign Equipment" assigns available equipment of the requested type to the employee and completes the request. Rejected requests are final and cannot be reopened.

## Approach and rejected alternatives
- Chosen: new public codeunit "EQM Request Approval Mgt.", which holds the state machine (Open > Pending Approval > Approved > Completed, and Pending Approval > Rejected) and two events. It adds five read-only fields to table 50111, a small comment dialog page, and actions on the request card and list. Status changes use `Modify(false)` after explicit checks, because the FR-032 OnModify lock rejects every Modify(true) on a request that is not Open.
- Rejected: BC Approvals Management/Workflow (Q1 standard). It is much larger, needs setup (approver user setup, workflow enabling), and the issue does not ask for configurable workflows.
- Rejected: an approver setup table or a User Setup extension. The EQM - Manager permission set already defines who may decide (NFR-002 roles).
- Rejected: relaxing the OnModify lock so that comments can be typed on the card. That would weaken the FR-032 rule; a dialog collects the comment instead.
- Rejected: a "Request No." field on assignment table 50103 or an event subscriber on the assignment. The request stores "Assigned Equipment No.", which is enough for traceability and leaves the FR-004 to FR-006 contracts unchanged.
- Rejected: a Reopen or withdraw transition, notifications, business events in 50119, and an RC cue. None of these is requested. FR-038 covers the pending-approval KPI.

## Objects
IDs in use (checked `app/src`, `test/src`): tables 50100-50111, enums 50100-50110, pages 50100-50126 and 50130-50134 (50127-50129 API reserve), codeunits 50103-50122 and 50130-50131 (50123-50129 reserved by FR-026 C10), test codeunits 50178-50188. Folder `app/src/Request/`.
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Codeunit | 50132 | EQM Request Approval Mgt. | New | `EQMRequestApprovalMgt.Codeunit.al`; `Access = Public`, internal procedures, transitions, checks, UI wrappers, 2 events |
| Page | 50135 | EQM Request Decision | New | `EQMRequestDecision.Page.al`; StandardDialog with an instruction text and a multi-line comment |
| Table | 50111 | EQM Equipment Request | Modify (own) | Fields 9-13, doc comment and Status ToolTip. **Published table: additive** |
| Enum | 50110 | EQM Request Status | Modify (own) | Only the summary text changes; the values and `Extensible = false` stay |
| Page | 50134 / 50133 | Request Card / Requests | Modify (own) | Approval group (card) and actions (both pages) |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | X on 50132 and 50135 |
| Codeunit (test) | 50189 | EQM Request Approval Tests | New | `test/src/EQMRequestApprovalTests.Codeunit.al` |

## Data model and upgrade impact
- Table 50111 gets new fields 9-13. All are `Editable = false`, have a Caption and ToolTip, and are set only by codeunit 50132. 9 "Sent for Approval By" Code[50]. 10 "Decided By" Code[50]. Fields 9 and 10 use `DataClassification = EndUserIdentifiableInformation`, TableRelation User."User Name", `ValidateTableRelation = false` (as 50103 "Assigned By"). 11 "Decision Date" Date (WorkDate, as the assignment dates). 12 "Decision Comment" Text[250] (CustomerContent, inherited). 13 "Assigned Equipment No." Code[20], TableRelation "EQM Equipment"."No.".
- Status ToolTip becomes: '...New requests are Open. Send an open request for approval; another manager approves or rejects it. Approved requests are completed by assigning equipment. Rejected and completed requests are final. Only open requests can be changed or deleted.' Update the table doc comment to match. Existing rows get blank fields. No upgrade codeunit (unreleased).

## Events
- Subscribed: none.
- Published in 50132 (`[IntegrationEvent(false, false)]`, local, XML docs):
  - `OnBeforeCheckApproverAllowed(EquipmentRequest: Record "EQM Equipment Request"; var IsHandled: Boolean)`. IsHandled skips only the self-approval check (for Q2 = any per tenant, or for a custom approver rule; raise an error to deny). Partners cannot bypass the status rules.
  - `OnAfterRequestStatusChanged(EquipmentRequest: Record "EQM Equipment Request"; PreviousStatus: Enum "EQM Request Status")`. Raised after each successful transition Modify. Notify only: no IsHandled, no UI, no Commit.

## Permissions
- EQM - Reader: `codeunit "EQM Request Approval Mgt." = X` after the Power Automate codeunits, and `page "EQM Request Decision" = X` after the request pages. Manager already has RIMD on requests, RIM on equipment and Rim on assignments; Administrator inherits these. A Reader who runs an action gets the platform permission error. That is acceptable, because the Reader is read-only (NFR-002).

## Compatibility
- Additive. **Breaking-change risk: low, flagged.** Step 1 adds fields to published table 50111 and changes its Status ToolTip. Steps 3-4 change published pages 50133 and 50134 (new controls and actions only). Enum 50110 stays unchanged. At the first release the names and IDs of codeunit 50132 and its two event signatures, and fields 9-13, become contracts. Equipment, assignment and API objects are not changed (Q3 = action).

## Implementation steps
1. Table 50111: add fields 9-13, the new Status ToolTip and the doc comment. Enum 50110: change the summary to "Status of an equipment request. Open, then Pending Approval, then Approved or Rejected; Approved requests become Completed when equipment is assigned. Rejected and Completed are final." Compile.
2. Page 50135: PageType StandardDialog, Caption 'Equipment Request Decision', no source table, ApplicationArea All, UsageCategory None. Fields: Instruction (read-only, ShowCaption false) and Comment (Text[250], MultiLine, ToolTip 'Specifies a comment on the decision.'). Procedures `SetInstruction(Text)` and `GetComment(): Text[250]`. Compile.
3. Codeunit 50132, with `Access = Public` and every procedure `internal`, each with a `/// summary`. Every transition starts with the same check: if Status = Rejected, Error(RequestRejectedErr). Then it checks the expected from-status, sets the fields, runs `Modify(false)` and raises OnAfterRequestStatusChanged.
   - `SendForApproval(var EquipmentRequest)`: requires Open (else NotOpenErr). Runs `CheckRequestConsistency(true)`, so that the employee and type are still active. Sets "Sent for Approval By" := UserId and Status := Pending Approval.
   - `Approve(var EquipmentRequest; Comment: Text[250])`: requires Pending Approval (else NotPendingErr) and runs the local CheckApproverAllowed (raises the event; if not handled and UserId = "Sent for Approval By", Error(SelfApprovalErr)). Sets "Decided By", "Decision Date" := WorkDate, "Decision Comment" and Status := Approved.
   - `Reject(var EquipmentRequest; Comment: Text[250])`: requires Pending Approval. If the trimmed Comment is blank, Error(RejectionCommentRequiredErr). Sets the same decision fields and Status := Rejected.
   - `AssignEquipment(var EquipmentRequest; EquipmentNo: Code[20])`: requires Approved (else NotApprovedErr). Gets the equipment (EquipmentNotFoundErr). If its "Category Code" <> "Requested Equipment Type", Error(EquipmentTypeMismatchErr). Calls `Equipment.AssignEmployee(EquipmentRequest."Employee No.")`, which keeps the FR-004 checks for availability, maintenance and employee. Then sets "Assigned Equipment No." and Status := Completed. Everything runs in one transaction.
   - UI wrappers `ApproveWithDialog`, `RejectWithDialog` (page 50135 RunModal; exit on anything but OK) and `AssignEquipmentWithLookup` (as pageext 50100 ReturnAssignedEquipment: "EQM Equipment List" in LookupMode, filtered on Category Code = type and Status = Available; if IsEmpty, Message(NoAvailableEquipmentMsg) and exit; re-Get the equipment after the lookup).
   - Labels, one sentence each with a Comment: RequestRejectedErr 'Equipment request %1 was rejected. A rejected request cannot be reopened; raise a new request instead.'; NotOpenErr 'You can only send equipment request %1 for approval when its status is Open. The current status is %2.'; NotPendingErr 'You can only approve or reject equipment request %1 when its status is Pending Approval. The current status is %2.'; SelfApprovalErr 'You cannot approve equipment request %1 because you sent it for approval. Another manager must approve it.'; RejectionCommentRequiredErr 'You must enter a comment to reject equipment request %1.'; NotApprovedErr 'You cannot assign equipment for request %1 because its status is %2. The request must be approved first.'; EquipmentNotFoundErr 'Equipment %1 does not exist.'; EquipmentTypeMismatchErr 'You cannot assign equipment %1 for request %2 because its category %3 is not the requested equipment type %4.'; NoAvailableEquipmentMsg 'There is no available equipment of type %1.'; ApproveInstructionTxt 'Enter an optional comment for the approval.'; RejectInstructionTxt 'Enter the reason for the rejection.'. Compile.
4. Card 50134: add a group Approval after General with fields 9-13 (Decision Comment MultiLine). Add Processing actions SendForApproval (Image SendApprovalRequest), Approve (Image Approve), Reject (Image Reject) and AssignEquipment (Image Allocate), with Enabled = Status Open / Pending / Pending / Approved (page booleans set in UpdateControls). Each action calls 50132, then runs `CurrPage.Update(false)`. Add a Promoted group Category_Process with actionrefs. List 50133: the same four actions on the current record, plus columns "Decided By" and "Decision Date" (Visible = false) and "Assigned Equipment No.". Update the AboutText of both pages to mention approval. Compile.
5. Permissions. Build the app and commit the regenerated `.g.xlf`.
6. Test codeunit 50189 follows the 50188 pattern: Subtype Test, TestPermissions Disabled, AutoRollback, Library Assert, Locked labels with prefix `EQMAPR`, and copies of the app labels. Initialize as in 50188, plus Available equipment of the requested category and of another category. To simulate a different sender, set "Sent for Approval By" := 'EQMAPR-OTHER' with Modify(false). Use a ConfirmHandler for AssignEmployee where needed, and ModalPageHandlers for page 50135 and the lookup. Build the test app.
7. Documenter: feature doc, help (approval process, the self-approval rule, assigning equipment from a request, the final statuses), CHANGELOG, and a TODO section "FR-033 sandbox checks" (scenario 17).

## Test scenarios
1. Given an Open valid request, when SendForApproval runs, then Status = Pending Approval and "Sent for Approval By" = UserId.
2. (neg) Given an Open request whose employee became Inactive, when SendForApproval runs, then EmployeeNotActiveErr is raised and Status stays Open.
3. (neg) Given a Pending, Approved, Rejected or Completed request, when SendForApproval runs, then NotOpenErr is raised (Rejected: RequestRejectedErr).
4. Given a Pending request sent by another user, when Approve runs with comment C, then Status = Approved, "Decided By" = UserId, "Decision Date" = WorkDate and "Decision Comment" = C. A blank comment is also accepted.
5. (neg) Given a Pending request sent by the current user, when Approve runs, then SelfApprovalErr is raised and Status stays Pending.
6. Given scenario 5 with a bound manual subscriber that sets IsHandled on OnBeforeCheckApproverAllowed, when Approve runs, then it succeeds.
7. Given a Pending request, when Reject runs with a comment, then Status = Rejected and the decision fields are filled. The sender may reject their own request.
8. (neg) When Reject runs with a blank or spaces-only comment, then RejectionCommentRequiredErr is raised and Status stays Pending.
9. (neg) Given an Open, Approved, Rejected or Completed request, when Approve or Reject runs, then NotPendingErr is raised (Rejected: RequestRejectedErr).
10. (neg) Given a Rejected request, when SendForApproval, Approve, Reject or AssignEquipment runs, or Modify(true) or Delete(true) runs, then each fails and the record is unchanged (cannot be reopened).
11. Given an Approved request and Available equipment EQ of the requested type, when AssignEquipment(EQ) runs, then EQ is Assigned to the employee, an active assignment entry exists, the request is Completed and "Assigned Equipment No." = EQ.
12. (neg) Given an Open or Pending request, when AssignEquipment runs, then NotApprovedErr is raised and EQ stays Available with no new assignment entry.
13. (neg) Given an Approved request, when AssignEquipment runs with equipment of another category, then EquipmentTypeMismatchErr is raised. With already-assigned equipment, AlreadyAssignedErr (FR-004) is raised. In both cases the request stays Approved.
14. (neg) Given an Approved request whose employee became Inactive, when AssignEquipment runs, then the FR-004 employee error is raised and the request stays Approved (one transaction).
15. Given a bound subscriber, when a request goes Open > Pending > Approved > Completed, then OnAfterRequestStatusChanged is raised 3 times with the correct PreviousStatus. When an action fails, it is not raised.
16. TestPage: on an Open card only Send for Approval is enabled. On a Pending card, Approve and Reject are enabled; Reject with dialog comment X makes the request Rejected with Comment X. On a Completed card no action is enabled. AssignEquipmentWithLookup with no available equipment shows NoAvailableEquipmentMsg.
17. Sandbox (manual): manager A sends a request and cannot approve it; manager B approves it; A assigns equipment from the request; a Reader sees the requests but the actions fail; the Rejected view shows rejected requests.

## Risks and open questions
- Q1-Q5: see the top. Rejected is final (the issue rule, no question). Completed is final too.
- Assumed there is no withdraw (Pending back to Open), because the issue does not ask for one. The sender can reject their own request instead. Self-approval is blocked only for Approve.
- Assumed a rejection needs a comment and an approval does not, because a rejected requester needs the reason.
- Assumed transitions use `Modify(false)`, because the FR-032 OnModify lock rejects Modify(true) once a request is no longer Open. As a result, table OnModify subscribers are not raised for transitions; OnAfterRequestStatusChanged is the documented hook instead.
- Assumed SendForApproval re-checks that the employee and type are active (`CheckRequestConsistency(true)`), so that inactive data is not sent for approval.
- R1 Q2 = noself needs two users to complete the process. A single-user sandbox cannot approve without a subscriber (documented in the help).
- R2 Equipment assigned directly from the Equipment Card still needs no request (Q3 = action). The rule "approved before assignment" applies to the request path only.
- R3 (Q5) Deleting an employee leaves Pending or Approved requests with a dangling Employee No.; AssignEquipment then fails with the FR-004 employee-not-found error.
- R4 Fields 9 and 10 hold user names (EUII), and the Decision Comment may contain personal data (CustomerContent, TODO personal-data item).
- R5 Trigger-less writes bypass the state machine, as in every EQM table.
