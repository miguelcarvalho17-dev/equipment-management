# FR-012 Equipment Maintenance Status

## Purpose
Links maintenance records (FR-010, FR-011) to the equipment status (FR-003) and the assignment rules (FR-004, FR-005). Registering a maintenance record sets the equipment to In Maintenance. While the equipment has an open maintenance record it cannot be assigned. Posting the last open record sets the equipment back to Available.

Status: describes the code as implemented. **The build compiled with alc and the analyzers with no new warnings. Review verdict CHANGES, resolved, no blockers. No automated tests (deferred, plan decision Q9; test codeunit 50166 reserved, nothing written). Sandbox checks MS-SB0 to MS-SB10 are NOT yet run.** App version stays 29.0.0.0. No new objects, no upgrade codeunit, no permission set changes.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50100 | EQM Equipment | New `internal StartMaintenance`, `internal CompleteMaintenance`; two hard checks in `CheckStatusTransitionAllowed`; two events; three labels; Status ToolTip. |
| Table | 50105 | EQM Maintenance Record | New key `EquipmentStatus` ("Equipment No.", Status). `OnInsert` calls `Equipment.StartMaintenance` last. ToolTips of "Equipment No." and Status, table summary. |
| Codeunit | 50108 | EQM Maintenance Mgt. | New `internal HasOpenMaintenance`, `CountOpenMaintenanceRecords`, `ShowOpenMaintenanceRecords`. `PostQst` text extended. |
| Codeunit | 50109 | EQM Maintenance-Post | New local `CompleteEquipmentMaintenance`, called after the history entry and before `OnAfterPostMaintenanceRecord`. Summary text. |
| Page | 50101 | EQM Equipment Card | `CanAssign` is also false while maintenance is open. ToolTips of Assign to Employee and Register Maintenance. |
| Page | 50113 / 50114 | EQM Maintenance Records / Record Card | AboutText and Post ToolTip text only (diff checked). |
| Page | 50115 | EQM Maintenance FactBox | New field "Open Maintenance Records" (drill-down to the open records). |

## Behavior
- **Open maintenance** means the equipment has at least one record with Status = Open. This is read from table 50105, not from the equipment status.
- **Registering** (table 50105 `OnInsert`, after `CheckMaintenanceConsistency(true)`): reads the equipment with `UpdLock` and calls `StartMaintenance`:
  1. Status already In Maintenance, Lost or Disposed: nothing changes.
  2. Status Assigned: asks `StartMaintenanceAssignedQst` through `GetResponseOrDefault(..., true)` (Yes without a UI). No raises `Error('')`, which rolls back the insert without a message. Yes clears "Assigned Employee No.".
  3. Sets Status to In Maintenance, raises `OnBeforeStartMaintenance`, calls `Modify(true)`. The existing checks run; the active assignment of formerly assigned equipment is closed through `UpdateAssignmentOnSave` (FR-006).
  Registering historical work also sets In Maintenance until the record is posted.
- **Posting** (codeunit 50109): after the history entry, reads the equipment with `UpdLock` and calls `CompleteMaintenance`. It does nothing when the status is not In Maintenance, or when another open record exists. Otherwise it raises `OnBeforeCompleteMaintenance`; unless IsHandled, it validates Status to Available and calls `Modify(true)`. An error rolls back the whole posting. No `Commit`.
- **Assignment block:** in `CheckStatusTransitionAllowed`, before `OnBeforeCheckStatusTransitionAllowed`, a change to Assigned raises `MaintenanceOpenAssignErr` while an open record exists. This applies to Assign to Employee, Status validation and `Modify(true)`. `OnBeforeCheckStatusTransitionAllowed` IsHandled cannot bypass it.
- **Manual early return blocked:** a change from In Maintenance to a non-final status raises `MaintenanceOpenStatusErr` while an open record exists. Lost and Disposed stay allowed; the open record can then still be posted and the status is not changed by posting.
- **Manual In Maintenance** without records stays allowed and can be set back to Available by hand. If records are registered afterwards, posting the last one sets Available.
- **No cancel:** a record opened by mistake is ended by posting it. Records cannot be deleted (FR-010).
- **Locking (accepted decision, option B):** the confirmation for assigned equipment is asked inside `OnInsert` of table 50105, while the No. Series line and the `UpdLock` on the equipment row are held. Other users who register, save or post on that number series or equipment wait while the dialog is open. Not yet checked in a sandbox (MS-SB3, MS-SB9). If registration is declined, a number from the series may be skipped; TODO(verify) (MS-SB3).
- **Page refresh:** the Equipment Card and FactBoxes show the new status after a refresh. TODO(verify).
- **Maintenance FactBox:** "Open Maintenance Records" is set only when the total count is above 0. Choosing it opens page 50113 filtered to the equipment and Status Open.

## Setup
No new setup. Existing development data: open maintenance records registered before FR-012 did not change the status. After publishing, such equipment cannot be assigned until those records are posted (MS-SB0).

## Extending (events)
Both are on table 50100, `[IntegrationEvent(false, false)]`, `local` (subscribable only from inside this app; same open point as FR-010 and FR-011: TODO(verify) whether public publishers are wanted for partners).

| Event | Raised | Parameters and what a subscriber may do |
|---|---|---|
| `OnBeforeStartMaintenance(var Equipment; MaintenanceRecord)` | When registering changes the status to In Maintenance, after Status and employee are set, before the save. Not raised when the status is already In Maintenance, Lost or Disposed. | `Equipment`: Status In Maintenance, employee blank; fill fields added by an extension, do not change standard fields. `MaintenanceRecord`: by value. Raise an error to stop the registration. No IsHandled. |
| `OnBeforeCompleteMaintenance(var Equipment; MaintenanceRecord; var IsHandled)` | When the last open record of equipment that is In Maintenance is posted, before the status changes. | `IsHandled = true` keeps the equipment In Maintenance; the user can set Available by hand later. It cannot make equipment assignable while maintenance is open. |

Still raised in the new flows: `OnAfterCheckEquipmentConsistency` (every equipment `Modify(true)`), `OnBeforeCheckStatusTransitionAllowed` (after the new hard checks), `OnBeforeCloseAssignment` (codeunit 50106), `OnAfterCheckMaintenanceConsistency`, and the three events of codeunit 50109. `OnAfterPostMaintenanceRecord` now sees the updated equipment status. A subscriber that raises an error in `OnAfterCheckEquipmentConsistency` or `OnBeforeStartMaintenance` also blocks registering and posting.

## Permissions
No permission set changes.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| Register maintenance (sets In Maintenance) | no | yes | yes |
| Post maintenance (may set Available) | no | yes | yes |
| Assign equipment with open maintenance | no | no (error) | no (error) |
| In Maintenance to Available by hand while a record is open | no | no (error) | no (error) |
| In Maintenance to Lost or Disposed while a record is open | no | yes | yes |

Manager uses its existing rights: modify on table 50100 and the indirect rights for closing the assignment. A user who can insert maintenance records but not modify equipment gets a permission error when registering. From code reading, not a sandbox run (MS-SB6, MS-SB7).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand.

## Upgrade and compatibility
New key on table 50105 only. No upgrade codeunit, no Obsolete handling (nothing released). Intentional behavior changes:
- FR-010: registering now changes the equipment status (the earlier "does not change the status" no longer holds).
- FR-011: posting can set the equipment to Available.
- FR-003: the status cannot leave In Maintenance for a non-final status while a record is open.
- FR-004: Assign to Employee is refused with an open record, also when an extension allows the transition.
- Registering for assigned equipment returns it from the employee after confirmation.

Trigger-less writes (`Insert(false)`, `Modify(false)`, RapidStart) skip the status change; the assignment block still holds because it reads open records.

## Test status
No test objects; test codeunit 50166 reserved. Sandbox checks MS-SB0 to MS-SB10 in docs/plans/FR-012-equipment-maintenance-status.md are open: existing open records, build and translations, register for Available and for assigned equipment, two open records, manual status changes, non-SUPER Manager, Reader, list view and tile, two-session locking, teaching tips.

## Discrepancies plan vs code
None found in the changed objects (procedures, events, labels and checks match the plan; page texts checked against the diff).
