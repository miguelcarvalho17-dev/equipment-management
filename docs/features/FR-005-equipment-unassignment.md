# FR-005 Equipment Unassignment (Return)

## Purpose
Users return assigned equipment. The employee is removed from the equipment, the status becomes Available and the active
assignment entry is closed (never deleted). Returning is the only way to change Assigned equipment to Available. It can be
started from the equipment card or from the Employee Card. User-facing wording is "Return"; internal names
(`UnassignEmployee`, card action control `Unassign`) are unchanged.

Status of this document: describes the code as implemented. **No automated tests (deferred by user request). The return
flow and the new Employee Card action have not been run in a sandbox.** The app version stays 29.0.0.0; app.json was not
changed.

## Objects
No new objects. Namespace `MiguelCarvalho.EquipmentManagement`.

| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50100 | EQM Equipment | `UnassignEmployee` guard, confirmation and flag; Status check; wording. |
| Page | 50101 | EQM Equipment Card | Action `Unassign`: caption "Return", new tooltip. |
| PageExtension | 50100 | EQM Employee Card | New action `EQMReturnEquipment` ("Return Equipment") in Processing. |
| Codeunit | 50106 | EQM Assignment Mgt. | Error text only. |
| Table | 50103 | EQM Equipment Assignment | Tooltip and summary text only. |

## Behavior
- **`UnassignEmployee(): Boolean`** (internal, table 50100):
  1. Raises `NotAssignedErr` if Status is not Assigned.
  2. Asks one confirmation (`ReturnEquipmentQst`). No: exits with `false`, nothing changed. Without a UI session the answer defaults to Yes.
  3. Clears "Assigned Employee No.", sets the private flag `ReturnInProgress`, validates Status := Available, resets the flag.
  4. `Modify(true)`. OnModify runs `UpdateAssignmentOnSave` (codeunit 50106), which closes the Active entry with Closing Date = `WorkDate()` and Closed By = `UserId()`. The entry is kept as history.
  5. Returns `true`.
- **Assigned -> Available only through Return:** Status OnValidate raises `UseReturnActionErr` when the stored status is Assigned, the new status is Available and `ReturnInProgress` is false. It runs before the transition check and the confirmations, so no dialog precedes the error. Hard rule, no event, not relaxable through `OnBeforeCheckStatusTransitionAllowed`.
  - Assigned -> In Maintenance / Lost / Disposed stay allowed and close the entry as in FR-004.
  - Code that assigns Status directly and calls `Modify(true)` is not blocked by this check; the check lives in Status OnValidate only.
- **Equipment card:** action "Return" (enabled only when Assigned) calls `UnassignEmployee`, then refreshes the page.
- **Employee Card:** action "Return Equipment" (`addlast(Processing)`, always enabled) runs `ReturnAssignedEquipment`:
  1. Filters EQM Equipment on the employee and Status = Assigned. If none: message `NoAssignedEquipmentMsg`, stop.
  2. Opens page "EQM Equipment List" in lookup mode on that filter; Cancel stops.
  3. Re-reads the chosen record; if it is no longer Assigned to this employee, raises `EquipmentNoLongerAssignedErr`.
  4. Calls `UnassignEmployee` (confirmation, return). The result is ignored.
- Reworded texts ("Unassign" -> "Return"): `EmployeeNotFoundErr`, `AlreadyAssignedErr`, `DeleteAssignedErr` (table 50100), `ActiveAssignmentExistsErr` (codeunit 50106, removed again in FR-006), tooltips of Status and "Assigned Employee No." (table 50100) and of Status (table 50103).
- Not enforced when triggers are skipped (`Modify(false)`, `ModifyAll`, RapidStart without validation).
- Equipment Assigned before FR-004 has no entry; it can be returned and nothing is closed, no error.
- Delete rule changed by FR-006: Closed entries are no longer deleted with their equipment; equipment with assignment history cannot be deleted (see `FR-006-assignment-history-tracking.md`). This replaces the earlier "Closed entries are deleted together with their equipment" rule.

## Extending (events)
No new events, no signature changes, no standard events subscribed.
- `OnBeforeCheckStatusTransitionAllowed` (table 50100) is still raised on the Assigned -> Available transition of a return; it cannot skip the Return-only check.
- `OnBeforeCloseAssignment` (codeunit 50106) is raised on every return. On a return the `Equipment` parameter already has a blank "Assigned Employee No."; use the entry's "Employee No." instead.

## Permissions
No permission set changes. Returning needs EQM - Edit (modify equipment; the entry is closed indirectly through codeunit 50106). The Employee Card action also needs EQM - Read to open the equipment list. A user with only indirect read on EQM Equipment (D365 BASIC) gets a permission error when using it; the action is shown to all users.

## Upgrade and compatibility
- No schema change, no upgrade codeunit, no new public surface. Existing data unaffected.
- Behavior changes (nothing released yet): Assigned -> Available through Validate(Status) is refused; `UnassignEmployee` refuses non-Assigned equipment and returns a Boolean; confirmation text changed.
- Translations: `app/Translations/Equipment Management.g.xlf` regenerated by the build.

## Test status
No test objects were written. Manual sandbox checks (not yet run) are listed in docs/plans/FR-005-equipment-unassignment.md.

## Discrepancies plan vs code
None found. `addlast(Processing)` on "Employee Card" is used as planned and compiles against the BC 29 symbols (confirmed by the reviewer from the symbols; the build ran clean).
