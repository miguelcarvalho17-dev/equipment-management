# FR-005 Equipment Unassignment

> Status: REVISION 2, **APPROVED** by the user (decisions D1-D8 under "Risks and open questions" are final).
> Source: GitHub issue #11. Branch: `feature/FR-005-equipment-unassignment`.
> No events report: FR-005 changes only this app's own objects and its existing Employee Card page extension; it
> subscribes to no standard events. al-event-finder is not needed.
> Scope of this iteration: main app only. **No automated tests** (user decision; see Test scenarios). **No version
> bump** (app.json stays 29.0.0.0, as in FR-004 D9). **No upgrade logic, no backfill.**
> Workflow for FR-005: planner -> (human approves plan) -> developer -> reviewer -> **tester step SKIPPED** ->
> documenter -> appsource-validator.

## Goal
Users can return assigned equipment: the active assignment entry is closed (never deleted), the employee is removed
from the equipment and its status becomes Available, so it can be assigned again. Returning is the only way to make
Assigned equipment Available, and it can be started from the equipment card or from the Employee Card.

### Requirement restated
- BR-U1: returning equipment removes the active employee assignment (equipment "Assigned Employee No." cleared, active
  assignment entry closed).
- BR-U2: the status is set to Available automatically.
- BR-U3: assignment history is preserved: a return closes the entry (Closing Date, Closed By) and never deletes it.
- Implicit: only equipment that is currently Assigned can be returned; afterwards it can be assigned again (FR-004
  BR-A1: only Available equipment can be assigned).

### What FR-004 already delivers (reused, not duplicated)
- Table 50100 `UnassignEmployee()` (internal) validates Status := Available and calls Modify(true). Status OnValidate
  asks `StatusChangeRemovesEmployeeQst` and clears "Assigned Employee No.". The card action "Unassign" (enabled only when
  Assigned) calls it. -> BR-U1/BR-U2 on the equipment record.
- Table 50100 OnModify calls codeunit 50106 `UpdateAssignmentOnSave`, which closes the Active entry (Status Closed,
  Closing Date = WorkDate, Closed By = user) when equipment leaves Assigned. It never deletes entries. -> BR-U1 on the
  entry, BR-U3.
- Assigning again afterwards is the FR-004 path (Available -> Assigned creates a new Active entry).

### Gaps FR-005 closes
1. `UnassignEmployee` has no guard: it validates Status := Available whatever the current status is (In Maintenance
   equipment would silently become Available; Lost/Disposed give the FR-003 final-status error, confusing for a return).
2. Wording: the issue speaks of returning; the UI says "Unassign" and the confirmation reads like a generic status change.
3. Assigned -> Available can also be done by changing Status directly on the card; the user wants the Return action to
   be the only way (D6).
4. Returning can only be started from the equipment card; the user also wants it on the Employee Card (D3).

## Approach and rejected alternatives
- Chosen:
  - **D1 Wording "Return":** card action caption "Return" and every user-facing text that says "unassign" reworded.
    Internal names stay (`UnassignEmployee`, card action control `Unassign`).
  - **Return guard, own confirmation and a "return in progress" flag in `UnassignEmployee`** (table 50100): refuse
    equipment that is not Assigned; ask one return-specific confirmation; clear the employee; set a table-level global
    flag; validate Status := Available; reset the flag; Modify(true). Returns a Boolean (false = user said No).
  - **D6 Assigned -> Available only through Return:** a hard check in table 50100 Status OnValidate refuses the change
    from Assigned to Available unless the "return in progress" flag is set. It runs **before** the FR-003 confirmation,
    so the card user gets the error at once instead of a confirmation followed by an error. Assigned -> In Maintenance /
    Lost / Disposed stay allowed directly (they close the entry as in FR-004). Scope: Status validate only (D8).
  - **D3 Employee Card: action "Return Equipment"** in the existing page extension 50100. It opens the equipment list
    (page 50100) in lookup mode filtered on that employee's Assigned equipment; the user picks one; the action re-reads
    the equipment, checks it is still assigned to that employee, and calls `UnassignEmployee`. No new objects.
  - **D4 Return date:** WorkDate, automatic (existing FR-004 behavior of `CloseActiveAssignments`). No dialog.
  - **D5 History:** a return only closes the entry (already true). FR-004 D6 (Closed entries are deleted together with
    their equipment) is kept unchanged (D7).
- Rejected: a closing-reason field/enum on the entry (D2: not now).
- Rejected: return actions on the equipment list and on the assignments page (D3: card and Employee Card only).
- Rejected: Employee Card action that lists assignment **entries** (page 50104) instead of equipment. Entries can be
  outdated after trigger-less writes; the equipment record is the source of truth for the current assignee, and page
  50100 already exists and supports lookup mode.
- Rejected: a new dialog/page for choosing the equipment, or a "Return all equipment" bulk action. More objects and a
  bulk confirmation/error design that was not asked for.
- Rejected: blocking Assigned -> Available only in the card's Status control (page OnValidate). The table field's
  OnValidate runs first, so the user would answer the FR-003 confirmation and then get the error. The table-level check
  with a flag avoids that and also covers other validating paths.
- Rejected: making the D6 check part of `CheckStatusTransitionAllowed` (relaxable through
  `OnBeforeCheckStatusTransitionAllowed`). The user wants the Return action to be the only path; a partner IsHandled
  would silently reopen it.
- Rejected: also enforcing D6 in `CheckEquipmentConsistency` on modify (D8: Status-validate-only block is enough).
- Rejected: refusing to delete equipment that has assignment history (D7: keep FR-004 D6).
- Rejected: any standard BC event subscription. No standard behavior changes.

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50103, pages 50100-50104, codeunits 50103-50106,
enums 50100-50101, page extension 50100, permission sets 50100-50102, permission set extension 50103. Test app: no
objects.

**No new objects.** All changes are to existing objects of this app.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50100 | EQM Equipment | Modify (own) | Return guard, return confirmation, return flag, hard check "Assigned -> Available only through Return", label/tooltip wording |
| Page | 50101 | EQM Equipment Card | Modify (own) | Action `Unassign`: caption "Return", tooltip |
| PageExtension | 50100 | EQM Employee Card (extends "Employee Card") | Modify (own) | New action "Return Equipment" (pick one of the employee's assigned equipment and return it) |
| Codeunit | 50106 | EQM Assignment Mgt. | Modify (own) | Label text only (`ActiveAssignmentExistsErr` wording) |
| Table | 50103 | EQM Equipment Assignment | Modify (own) | Text only (Status tooltip, table summary wording) |

Not changed: tables 50101/50102, pages 50100/50102/50103/50104, codeunits 50103/50104/50105, enums 50100/50101,
permission sets 50100-50102, permission set extension 50103, `app/app.json`, `test/`.
Next free IDs (unchanged by FR-005): tables 50104, pages 50105, codeunits 50107, enums 50102, page extensions 50101,
permission sets 50104; test codeunits 50156 (50156/50157 still reserved for FR-004 tests).

### Table 50100 "EQM Equipment" (changes)

**New global variable** (table `var` section): `ReturnInProgress: Boolean`. Only `UnassignEmployee` sets it.

**Field 9 Status: OnValidate** (one new step; all existing steps unchanged and in the same order)
- New step directly **after** the existing `if (Status = Status::Assigned) and IsNew then Error(NewEquipmentAssignedErr, ...)`
  and **before** `if Status <> xRec.Status then CheckStatusTransitionAllowed(...)`:
  if (xRec.Status = Status::Assigned) and (Status = Status::Available) and not ReturnInProgress:
  Error(UseReturnActionErr, "No."). Hard rule (D6), no event.
- Because it runs before the confirmations, the user gets no confirmation dialog before this error.

**Field 9 Status: ToolTip** becomes:
'Specifies the lifecycle status of the equipment: Available, Assigned, In Maintenance, Lost or Disposed. Only saved, available equipment can be assigned; use the Assign to Employee action. Assigned equipment becomes available only through the Return action. Lost and Disposed are final statuses: the equipment cannot be assigned or change status again. New equipment cannot start as Assigned, Lost or Disposed.'

**Field 10 "Assigned Employee No.": ToolTip** becomes:
'Specifies the employee the equipment is assigned to. To assign available equipment, use the Assign to Employee action. To change the employee, return the equipment first.'

**Procedure `UnassignEmployee()` (internal) becomes `UnassignEmployee(): Boolean`**
Steps, in this order:
1. If Status <> Status::Assigned: Error(NotAssignedErr, "No.", Format(Status)). Hard rule, no event.
2. If not `ConfirmManagement.GetResponseOrDefault(StrSubstNo(ReturnEquipmentQst, "No.", "Assigned Employee No.",
   Format(Status::Available)), true)`: exit(false). Nothing has been changed yet, so no error is needed. Without a UI
   session the answer defaults to Yes, like the other confirmations in this table.
3. "Assigned Employee No." := '' (plain assignment, no Validate; with a blank employee Status OnValidate does not ask
   `StatusChangeRemovesEmployeeQst` a second time).
4. ReturnInProgress := true.
5. Validate(Status, Status::Available) (passes the new D6 check because of the flag; runs the FR-003 transition check
   and raises `OnBeforeCheckStatusTransitionAllowed` as before).
6. ReturnInProgress := false.
7. Modify(true) (OnModify -> `CheckEquipmentConsistency(false)` -> codeunit 50106 `UpdateAssignmentOnSave` closes the
   Active entry with Closing Date = WorkDate and Closed By = user; nothing is deleted).
8. exit(true).
- If step 5 raises an error the transaction rolls back and the record instance is discarded by the caller's error, so
  the flag does not need a separate reset path. The developer must still keep step 6 directly after step 5 (not after
  Modify), so the flag is never set while OnModify or partner subscribers run.
- New local variable `ConfirmManagement: Codeunit "Confirm Management"` (`System.Utilities`, already in `using`).
- Doc comment replaces the current one: "Returns assigned equipment: removes the assigned employee, sets the status to
  Available, saves the record with triggers and closes the active assignment entry. The entry is kept as history. The
  user is asked to confirm first; without a UI session the answer defaults to Yes. This is the only way to change
  Assigned equipment to Available. Raises an error when the equipment is not Assigned." Returns: "True when the
  equipment was returned; false when the user cancelled."
- Callers: card action `Unassign` and the new Employee Card action. Both ignore the result.

**`CheckEquipmentConsistency`**: unchanged (D8). Update nothing else in the table: triggers, `AssignEmployee`,
`CheckStatusTransitionAllowed`, events stay as they are.

**Labels (table 50100)**
- New `NotAssignedErr`: 'You cannot return equipment %1 because it is not assigned. Its status is %2.' Comment: '%1 = equipment number, %2 = status caption'.
- New `ReturnEquipmentQst`: 'Do you want to return equipment %1 from employee %2? The status changes to %3 and the assignment is closed.' Comment: '%1 = equipment number, %2 = employee number, %3 = Available status caption'.
- New `UseReturnActionErr`: 'To make assigned equipment %1 available, use the Return action on the equipment card or the Return Equipment action on the employee card.' Comment: '%1 = equipment number'.
- `EmployeeNotFoundErr` text becomes: 'Employee %1 assigned to equipment %2 no longer exists. Use the Return action, then assign another employee.' Comment unchanged.
- `AlreadyAssignedErr` text becomes: 'Equipment %1 is already assigned to employee %2. Return the equipment first, and then assign it again.' Comment unchanged.
- `DeleteAssignedErr` text becomes: 'You cannot delete equipment %1 because it is assigned to employee %2. Return the equipment first.' Comment unchanged.
- `StatusChangeRemovesEmployeeQst`: unchanged (still used for Assigned -> In Maintenance on the card).

### Page 50101 "EQM Equipment Card" (changes)
- Action `Unassign` (control name and actionref `Unassign_Promoted` unchanged): Caption 'Return'; ToolTip 'Returns the
  equipment from the assigned employee. The status changes to Available and the assignment is closed with the work date
  and your user name. The assignment stays in the history.'; Image unchanged (`Undo`). Enabled = IsAssigned
  (unchanged). OnAction unchanged (`Rec.UnassignEmployee()` then `CurrPage.Update(false)`).
- Status control (saved records): no page change. Choosing Available on an Assigned card now fails at once with
  `UseReturnActionErr` (table check, D6). Choosing In Maintenance / Lost / Disposed works as before.

### PageExtension 50100 "EQM Employee Card" (changes)
- New action `EQMReturnEquipment` in the **Processing** area of "Employee Card": `addlast(Processing)`. Caption 'Return
  Equipment'; ToolTip 'Returns equipment assigned to this employee. Choose the equipment in the list. Its status changes
  to Available and the assignment is closed.'; ApplicationArea All; Image `Undo` (same as the card). No promoted
  actionref (same reason as FR-004: no dependency on base action group names). Always enabled (computing whether the
  employee has equipment would cost a query per record).
  - **Verify** in the BC 29 symbols that `addlast(Processing)` is accepted on "Employee Card". If not, use
    `addlast(Navigation)` next to the existing action and report it in the developer report. Do not guess other anchors.
- OnAction calls a new local procedure `ReturnAssignedEquipment()` in the page extension:
  1. Filter an EQM Equipment record: SetCurrentKey("Assigned Employee No.", Status) (existing key `AssignedEmployee`);
     "Assigned Employee No." = Rec."No."; Status = Assigned.
  2. If `IsEmpty()`: Message(NoAssignedEquipmentMsg, Rec."No.") and exit.
  3. Open page "EQM Equipment List" with `SetTableView(Equipment)` and `LookupMode(true)`; if RunModal() <>
     Action::LookupOK, exit. (Same pattern as `SelectActiveEmployee` on the equipment card.) The list shows the filtered
     rows even when only one exists; the user always confirms which equipment.
  4. `GetRecord(Equipment)`, then re-read it with `Equipment.Get(Equipment."No.")` (full record, it is modified).
  5. If Equipment.Status <> Assigned or Equipment."Assigned Employee No." <> Rec."No.":
     Error(EquipmentNoLongerAssignedErr, Equipment."No.", Rec."No.") (another user changed it meanwhile).
  6. `Equipment.UnassignEmployee()` (asks the return confirmation, closes the entry). Ignore the result.
- Labels (page extension):
  - `NoAssignedEquipmentMsg`: 'No equipment is assigned to employee %1.' Comment: '%1 = employee number'.
  - `EquipmentNoLongerAssignedErr`: 'Equipment %1 is no longer assigned to employee %2.' Comment: '%1 = equipment number, %2 = employee number'.
- `UnassignEmployee` is `internal` in table 50100; the page extension is in the same app, so the call is allowed.
- The existing action `EQMEquipmentAssignments` is unchanged.

### Codeunit 50106 "EQM Assignment Mgt." (text only)
- `ActiveAssignmentExistsErr` text becomes: 'You cannot delete equipment %1 because it has an active assignment. Assign the equipment and then return it to close the assignment, and then delete the equipment.' Comment unchanged.
- No code change: `CloseActiveAssignments` already closes (never deletes) the entry with WorkDate and the current user.
  `DeleteAssignments` unchanged (D7).
- Doc comment of `UpdateAssignmentOnSave` may say "returned" instead of "stops being Assigned" only if the developer
  edits nearby text anyway; optional.

### Table 50103 "EQM Equipment Assignment" (text only)
- Field 6 Status ToolTip becomes: 'Specifies whether the assignment is active or closed. Equipment has at most one active assignment. The assignment is closed when the equipment is returned or its status changes from Assigned to another status. Closed assignments are kept as history.'
- Table `/// <summary>`: replace "when equipment is assigned and unassigned" with "when equipment is assigned and
  returned".

### app.json, translations
- No app.json change. The build regenerates `app/Translations/Equipment Management.g.xlf`; commit it, never edit it by
  hand.

## Data model and upgrade impact
- No schema change: no new tables, fields, enums or keys. Only a table global variable, procedures and labels.
- DataClassification: nothing new.
- Upgrade codeunit: not needed.
- Existing data: unaffected. Equipment that is Assigned keeps its Active entry; returning it closes that entry.
  Equipment Assigned before FR-004 without an entry (FR-004 R3) can be returned; nothing is closed and no error is raised.

## Events
**Standard BC events: none.** No events report required. The Employee Card change is a UI action in our existing page
extension, not an event subscription.

Subscribed: none.

Published: **no new events, no signature changes.**
- `OnBeforeCheckStatusTransitionAllowed` (table 50100) is raised on the Assigned -> Available transition of a return,
  as before. It cannot skip the new D6 check (that check runs outside the transition rules, before them).
- `OnBeforeCloseAssignment` (codeunit 50106) is raised on every return, as before. Note for the documenter: on a return
  the Equipment parameter already has a blank "Assigned Employee No."; partners should use the entry's "Employee No.".
  No doc-comment change is required in code.
- No IsHandled on the return guard, the confirmation or the D6 check: the user wants Return to be the only path, and
  the guard protects the FR-004 invariant.

## Permissions
- No permission set changes.
  - Returning modifies EQM Equipment with the user's own rights (EQM - Edit: RIMD) and closes the entry through codeunit
    50106 (EQM - Edit: indirect `m`). Same rights as the FR-004 Unassign.
  - Employee Card action: reading EQM Equipment and opening page 50100 needs EQM - Read; returning needs EQM - Edit.
    A user with only D365 BASIC (indirect read on EQM Equipment via extension 50103) gets a permission error when using
    the action. Acceptable: the action is meant for equipment managers.
- Help text (documenter): "Returning equipment needs Equipment - Edit."

## Compatibility
- AppSource mode, development phase: nothing released, no baseline; no Obsolete handling needed.
- No new public surface: no new objects, fields, enums or events.
- Behavior changes (would be breaking after a release, allowed now):
  - Assigned -> Available through Validate(Status) is refused unless it comes from `UnassignEmployee` (D6). This affects
    the card's Status control and any code or (future) API page that validates Status.
  - `UnassignEmployee` (internal) refuses equipment that is not Assigned and returns a Boolean; cancelling no longer
    raises a silent error but exits with false. Internal, no `internalsVisibleTo`, so no external caller.
  - The return confirmation text changes from the generic status-change question to `ReturnEquipmentQst`.
  - UI wording "Unassign" becomes "Return". Action control name `Unassign` is kept, so page extensions anchored on it
    keep working.
- Base app: only our existing page extension on "Employee Card" gets one more action.
- Doc references to update (documenter, not developer):
  - `docs/help/FR-004-equipment-assignment.md`, `docs/features/FR-004-equipment-assignment.md`: "Unassign" becomes
    "Return"; Employee Card Return Equipment action; Available only through Return.
  - `docs/help/FR-001-equipment-registration.md`, `docs/help/FR-003-equipment-status-management.md` and the FR-001/FR-003
    feature docs: "Unassign" wording; Assigned -> Available no longer possible through the Status field.
  - `docs/TODO.md` sandbox check "Setting Status to Assigned directly ..." is unaffected; add a sandbox check for D6.
  - New `docs/features/FR-005-equipment-unassignment.md`, `docs/help/FR-005-equipment-unassignment.md`, CHANGELOG
    section `## FR-005 Equipment Unassignment (version stays 29.0.0.0, no bump)` at the top, release-notes paragraph.
  - Historical plans are not edited.

## Test scenarios
**Deferred by user decision: no automated tests and no test-app work in this iteration.** No test codeunits, no
`test/app.json` change, no test IDs reserved for FR-005. The tester step is skipped. The developer and reviewer check
the behavior by reading the code against this plan; the manual sandbox checks below are for the user.

Manual sandbox checks (not automated):
- Return from the equipment card: one confirmation; Yes -> Available, employee blank, entry Closed with Closing Date =
  work date and Closed By = user, entry still present; No -> nothing changes.
- Return action is disabled on the card for equipment that is not Assigned.
- On an Assigned card, choosing Available in the Status field fails at once with the "use the Return action" message
  and no confirmation; choosing In Maintenance still works and closes the entry.
- Employee Card > Return Equipment: with no assigned equipment shows the message; with assigned equipment shows only
  that employee's Assigned equipment; picking one and confirming returns it.
- Returned equipment can be assigned again; the old entry stays Closed and a new Active entry is created.
- `.g.xlf` regenerated with the new and reworded texts.

## Risks and open questions
Decisions (approved by the user):
- **D1 (Q1):** users see "Return"; internal names (`UnassignEmployee`, action `Unassign`) stay.
- **D2 (Q2):** no closing reason now. No enum, no field, no column.
- **D3 (Q3):** return from the equipment card and the Employee Card only. No actions on the equipment list or the
  assignments page.
- **D4 (Q4):** return date = WorkDate, automatic.
- **D5 (Q5):** returning only closes the entry, never deletes it ("we want to keep assignment history").
- **D6 (Q6):** Assigned -> Available only through the Return action; a direct status change is blocked.
- **D7 (O1):** FR-004 D6 is kept: equipment that is not Assigned can still be deleted, and its Closed entries are
  deleted with it. `DeleteAssignments` is unchanged.
- **D8 (O2):** the D6 block sits in Status OnValidate only. It covers the card and any code or future API page that
  validates Status. Code that assigns Status directly and calls Modify(true) is not blocked and still closes the entry
  normally. `CheckEquipmentConsistency` is unchanged.

Still open: none.

Risks:
- R1 Trigger-less writes (Modify(false), ModifyAll, RapidStart without validation) still bypass the return logic and
  the entry bookkeeping, as in FR-001..FR-004. Direct Status assignment plus Modify(true) also bypasses the D6 block (D8).
- R2 The `ReturnInProgress` flag is per record instance. It works because `UnassignEmployee` validates on its own
  instance; it must never be exposed or set elsewhere.
- R3 `addlast(Processing)` on "Employee Card" is unverified against the BC 29 symbols; fallback is Navigation (see
  page extension section).
- R4 Users without EQM - Read/Edit see the Employee Card action and get a permission error when they use it.
- R5 No automated tests: regressions in FR-003/FR-004 status and assignment behavior are caught only by review and
  manual sandbox checks.
