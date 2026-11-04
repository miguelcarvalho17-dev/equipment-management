# FR-004 Equipment Assignment

## Purpose
Record every assignment of equipment to an employee as an assignment entry (equipment, employee, assignment date,
user who assigned it) and close the entry automatically when the equipment stops being Assigned. Equipment has at most
one active entry. The status and employee on table 50100 stay the source of truth for the current assignment; the
entries are the history.

Status of this document: describes the code as implemented. **The code has not been compiled (.NET 10 missing locally)
and there are no automated tests (decision D8).** The app version stays 29.0.0.0 (D9); app.json was not changed.
Permission behavior for the Employee delete guard still needs a sandbox check (see the comment in codeunit 50103).

## Objects
Namespace `MiguelCarvalho.EquipmentManagement`.

| Type | ID | Name | Purpose |
|---|---|---|---|
| Table | 50103 | EQM Equipment Assignment | One entry per assignment. |
| Enum | 50101 | EQM Assignment Status | Active, Closed. Not extensible. |
| Codeunit | 50106 | EQM Assignment Mgt. | Creates and closes entries; since FR-006 it also answers whether equipment has history. Two events. |
| Page | 50104 | EQM Equipment Assignments | Read-only list, views Active and Closed. |
| PageExtension | 50100 | EQM Employee Card | Navigation action "Equipment Assignments" (entries of the employee). |
| Table | 50100 | EQM Equipment | Changed: assignment rules, create/close hooks, delete rules. |
| Page | 50101 | EQM Equipment Card | Changed: Assigned Employee No. read-only, new Status control without Assigned, Assignments action. |
| Page | 50100 | EQM Equipment List | New action "Assignments". |
| Permission sets | 50100, 50101 | EQM - Read, EQM - Edit | Changed (see Permissions). |

### Table 50103 fields
| No. | Field | Notes |
|---|---|---|
| 1 | Entry No. | Auto-increment, primary key. |
| 2 | Equipment No. | Relation to EQM Equipment. |
| 3 | Employee No. | Relation to Employee. |
| 4 | Assignment Date | Work date of the user who assigned. |
| 5 | Assigned By | User ID of the user who assigned (EndUserIdentifiableInformation). |
| 6 | Status | Active or Closed. |
| 7 | Closing Date | Work date of the user who closed. Blank while Active. |
| 8 | Closed By | User ID of the user who closed. Blank while Active. |
| 9 | Equipment Description | FlowField (lookup), not editable. |

Keys: PK (Entry No.), (Equipment No., Status), (Employee No., Status).

## Behavior
Rules are in table 50100, so they apply to pages, code and APIs alike (with triggers running).

- **Assign:** only saved equipment with status Available can be assigned (`AssignEmployee`, called by the card action
  "Assign to Employee"). It sets Status = Assigned and the employee, and on modify codeunit 50106 inserts an Active entry
  (Assignment Date = `WorkDate()`, Assigned By = `UserId()`).
- **Close:** when stored status is Assigned and the new status is not, all Active entries of the equipment get
  Status Closed, Closing Date = `WorkDate()`, Closed By = `UserId()`. This covers Return (FR-005; formerly Unassign), In Maintenance, Lost and Disposed.
- **Hook:** `UpdateAssignmentOnSave` runs in table 50100 `OnModify`, after `CheckEquipmentConsistency`, and compares the
  stored status with the new one. Creating an entry first closes any leftover Active entry of the same equipment.
- **Employee card:** Navigation > Equipment Assignments shows that employee's entries (several allowed).

### Behavior changes
- **In Maintenance -> Assigned is refused.** Only Available can become Assigned (reverses the FR-003 rule that allowed it).
  Partners can relax it through `OnBeforeCheckStatusTransitionAllowed` (`IsHandled`); Lost/Disposed still cannot become Assigned.
- **No reassignment in one step.** Assigned equipment cannot be given to another employee: `AssignEmployee` and the modify
  check raise "already assigned"; return first. `AssignEmployee` previously reassigned.
- **New equipment cannot be Assigned.** Refused on Status validate and on insert (hard, no event). The card's Status
  control for new records now offers only Available and In Maintenance.
- **Picking Assigned in the card's Status dropdown is refused.** On saved equipment the card raises "To assign equipment, use the Assign to Employee action." as soon as Assigned is chosen, and the status reverts. This avoids a dead end where the employee field is read-only and the action is disabled.
- **Assigned Employee No. on the card is read-only.** The employee is set only through Assign to Employee. The card action is enabled only for saved Available equipment.
- **Deleting equipment (D6, superseded by FR-006 D2):** replaces the FR-001 confirmation.
  - Refused while status is Assigned.
  - Since FR-006: refused when the equipment has any assignment entry, Active or Closed (`DeleteHistoryExistsErr`). Entries are no longer deleted with the equipment; `DeleteAssignments` and `ActiveAssignmentExistsErr` were removed. Only equipment that was never assigned can be deleted.
  - Entries cannot be deleted any other way: the list page has `DeleteAllowed = false` and no EQM permission set grants delete.
  - Since FR-006 a Closed entry cannot be modified or renamed (see `FR-006-assignment-history-tracking.md`).
- Not enforced when triggers are skipped (`Modify(false)`, `Insert(false)`, `Delete(false)`, `ModifyAll`, `DeleteAll`, RapidStart
  without validation). A leftover state is repaired by assign + return.
- No backfill (D10): equipment already Assigned before this feature has no entry until it is returned and assigned again.
- Each equipment save adds one primary-key read of the stored record.

## Extending (events)
Published from codeunit 50106 as `[IntegrationEvent(false, false)]`, declared `local`.

| Event | Raised | Parameters | What you can do |
|---|---|---|---|
| `OnBeforeInsertAssignment` | Before a new Active entry is inserted. | `EquipmentAssignment` (var), `Equipment` (by value) | Set your own fields on the entry. Do not change standard fields. |
| `OnBeforeCloseAssignment` | Before an Active entry is closed (Status, Closing Date, Closed By already set). | `EquipmentAssignment` (var), `Equipment` (by value) | Set your own fields; the equipment status shows why it closes. |

Changed doc for existing event `OnBeforeCheckStatusTransitionAllowed`: `IsHandled` now also skips "only Available can become Assigned".
Subscribed: `Database::Employee` `OnBeforeDeleteEvent` in codeunit 50103 (from FR-001; unchanged here).

Internal (not API): `UpdateAssignmentOnSave`, `HasAssignmentHistory` (FR-006; replaces `DeleteAssignments`), `AssignEmployee`, `UnassignEmployee`.

## Permissions
- EQM - Read: read on table 50103, execute on table 50103, page 50104 and codeunit 50106.
- EQM - Edit: indirect rights `Rim` on table 50103 (read, plus indirect insert/modify; the indirect delete right was removed in FR-006), used only through codeunit 50106. Users cannot edit entries directly.
- EQM - Admin: no change (inherits Edit).
- Page extension action on the Employee Card uses `ApplicationArea = All`.

## Upgrade and compatibility
- New table and enum only; no upgrade codeunit, no schema changes to existing tables.
- Existing records: see "No backfill" above.
- Version stays 29.0.0.0 (D9). The changelog lists FR-002 as 29.1.0.0 while app.json says 29.0.0.0; settle before first release.
- Translations: `.g.xlf` not edited; new captions appear after the next build.

## Test status
No test objects were written (D8). Scenarios are listed in docs/plans/FR-004-equipment-assignment.md for later.
