# FR-003 Equipment Status Management

## Purpose
Give every equipment record one current lifecycle status (Available, Assigned, In Maintenance, Lost, Disposed) and
enforce the rules for changing it. Lost and Disposed are final statuses. The rules live in table 50100, so they apply to
pages, code and APIs alike. The list and card show the status in color, and the list offers per-status views.

Status of this document: describes the code as implemented. **Nothing has been compiled and there are no automated tests**
for FR-003 (tests are written later by the user).

## Objects
No new objects. Changed objects (namespace `MiguelCarvalho.EquipmentManagement`):

| Type | ID | Name | Change |
|---|---|---|---|
| Enum | 50100 | EQM Equipment Status | Value 2 renamed "Under Maintenance" -> "In Maintenance", value 3 renamed Retired -> Disposed, new value 4 Lost. Ordinals unchanged. Still extensible. |
| Table | 50100 | EQM Equipment | Status validation and transition rules, final-status rules, new-record rule, confirmations, one event replaced, one event added, internal helpers. |
| Page | 50100 | EQM Equipment List | Status color; five optional views. |
| Page | 50101 | EQM Equipment Card | Status color; separate Status control for new records; Assign to Employee disabled for Lost/Disposed. |

## Setup
None. No setup fields, no default data, no permission set changes.

## Behavior
Statuses: Available (0), Assigned (1), In Maintenance (2), Disposed (3), Lost (4). The Status dropdown follows ordinal order, so Disposed is listed before Lost.

Rules (table 50100):

| Rule | Behavior | Skippable by a partner |
|---|---|---|
| Lost/Disposed cannot be assigned | Status cannot change from Lost or Disposed to Assigned; `AssignEmployee` raises an error for Lost/Disposed. | No |
| Employee only when Assigned | "Assigned Employee No." may only be filled when Status = Assigned (all statuses). The employee must exist. | No |
| Lost/Disposed are final | Once saved as Lost or Disposed, the status cannot change to any other value, including Lost <-> Disposed. Other fields stay editable; delete is unchanged. | Yes, via `OnBeforeCheckStatusTransitionAllowed` |
| New equipment | A new (not yet stored) record cannot have Lost or Disposed. Checked on Status validate and on insert. | No |
| Confirmation | Changing to Lost or Disposed asks one question and clears the assigned employee (the question names the employee when one is set). No answers cancels the change. | n/a |

- Other transitions among Available, Assigned and In Maintenance are allowed. In Maintenance equipment can be assigned directly.
- Moving from Assigned to Available or In Maintenance keeps the FR-001 behavior (confirm, then the employee is cleared).
- Checks run on Status validate (previous value from the record's `xRec`) and again on insert/modify in `CheckEquipmentConsistency`, comparing against the stored record. Direct field assignment followed by `Modify(true)` is therefore also checked.
- Without UI (API, job queue) the confirmations answer Yes (`GetResponseOrDefault` default).
- Not enforced when triggers are skipped (`Modify(false)`, `Insert(false)`, `ModifyAll`, RapidStart without validation).
- Existing data: records stored as 2 now read In Maintenance, records stored as 3 (formerly Retired) read Disposed and are final. No upgrade codeunit.

Equipment List (page 50100): Status is colored; views Available, Assigned, In Maintenance, Lost, Disposed. No default filter, so the default view shows all equipment.

Equipment Card (page 50101): on a new record a Status control offering only Available, Assigned and In Maintenance is shown; on a saved record the normal Status control is shown. **Assign to Employee** is enabled for saved records that are not Lost or Disposed.

Status colors (`GetStatusStyle`): Available = Favorable, Assigned = Standard, In Maintenance = Ambiguous, Lost = Unfavorable, Disposed = Subordinate; statuses added by extensions = Standard.

## Extending (events)
Published from table "EQM Equipment" as `[IntegrationEvent(false, false)]`, declared `local`. The record is passed by value.

| Event | Raised | Parameters | What you can do |
|---|---|---|---|
| `OnBeforeCheckStatusTransitionAllowed` (new) | When the status changes, after the hard rule "Lost/Disposed cannot become Assigned" passed. Raised on Status validate and again on insert/modify when the stored status differs, so up to twice per change. Not raised on insert. | `Equipment`; `FromStatus` (previous value on validate, stored value on modify); `ToStatus`; `IsHandled` (var) | `IsHandled = true` skips the rule "Lost and Disposed are final" (the only way to leave a final status). It cannot allow Lost/Disposed equipment to become Assigned. Leave `IsHandled` false and raise an error to block a transition (for example for your own enum value). |
| `OnBeforeCheckEmployeeIsEligible` (replaces `OnBeforeCheckAssignedEmployeeAllowed`) | When an employee is filled in, Status = Assigned, the employee exists, and the employee is new or changed. | `Equipment`; `IsHandled` (var) | `IsHandled = true` skips only the "employee is Active" and "not privacy blocked" checks. Employee only when Assigned, employee must exist and Assigned requires an employee are not skippable. |

Unchanged: `OnBeforeCheckSerialNoIsUnique`, `OnBeforeCheckCategoryIsActive`, `OnAfterCheckEquipmentConsistency`.
Subscribed: none.

Internal (not API): `IsFinalStatus(Status)` (true for Lost/Disposed), `GetStatusStyle()`, `AssignEmployee`, `CheckEquipmentConsistency`.

## Permissions
No change. Changing status needs `tabledata "EQM Equipment"` modify, which EQM - Edit (and Admin by inclusion) has. EQM - Read users see colors and views but cannot change status.

## Upgrade and compatibility
- No upgrade codeunit (ordinals kept). Nothing is released, so the following breaking changes were made without obsoleting: enum value renames and removal of `OnBeforeCheckAssignedEmployeeAllowed`. After a release these would be breaking.
- Additive: enum value Lost, event `OnBeforeCheckStatusTransitionAllowed`.
- Behavior change: an employee is now allowed only when Status = Assigned, with no partner override.
- Existing records with an employee on a non-Assigned status (possible only after trigger-less writes) raise an error on the next modify until the employee is cleared.
- `app.json` version is unchanged (29.0.0.0). The build regenerates `app/Translations/Equipment Management.g.xlf`; not verified.

## Known limitations / verification pending
- **Not compiled, not tested.** Compiler and analyzer results (including use of `ValuesAllowed` and the twin Status controls on the card) are unknown.
- TODO(verify): the page views and status colors in the client; that the new-record Status control hides Lost/Disposed.
- TODO(verify): the generated `.g.xlf` has no stale entries for Under Maintenance/Retired.
- No undo for Lost/Disposed in the standard app.
- Test scenarios are in `docs/plans/FR-003-equipment-status-management.md` (reference list). FR-001 test specs that mention Retired, Under Maintenance or the removed event need updating when written.

## Plan discrepancies
- None found. Code matches plan revision 2.
