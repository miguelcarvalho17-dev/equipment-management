# FR-008 Equipment Card

## Purpose
Users get one card with everything about a piece of equipment: details, current status, current assignment, the full assignment history and who created and last changed the record. Page 50101 "EQM Equipment Card" (FR-001) already existed. FR-008 adds the assignment details of the active entry, the assignment history as a section on the card, and "who" audit fields.

Status: describes the code as implemented. **Not compiled and not run in a sandbox. No automated tests (deferred by the user, plan decision Q5).** App version stays 29.0.0.0 (app.json unchanged). Namespace `MiguelCarvalho.EquipmentManagement`. No schema change, no upgrade codeunit, no events.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Page | 50105 | EQM Assignment History Part | New. ListPart on table "EQM Equipment Assignment", read-only (no insert, modify, delete), sorted by "Entry No." descending (newest first). Columns: Employee No., Employee Name (looked up, display only), Assignment Date, Assigned By, Status, Closing Date, Closed By. "Entry No." is hidden. Status is green (Favorable) when Active, otherwise Subordinate. |
| Page | 50101 | EQM Equipment Card | Teaching tip (`AboutTitle`/`AboutText`). New fields Assigned Since, Assigned By (assignment group), Created By, Last Modified By (Audit group). New part `AssignmentHistory` linked on "Equipment No." = "No.". NFR-003 adds the Assignment Details FactBox (page 50111), Notes and Links, and Ctrl+F7 on Assignments (group 'Equipment'). Status fields `Importance = Promoted`. Created Date and Last Modified Date no longer `Importance = Additional`. `using System.Security.AccessControl;` added. |
| Page | 50101 | EQM Equipment Card | FR-019: new group `PlannedMaintenance` (Last Maintenance Date, Maintenance Frequency (Months), Next Maintenance Date) after Warranty; `AboutText` mentions planned maintenance. See docs/features/FR-019-planned-maintenance.md. |
| Codeunit | 50106 | EQM Assignment Mgt. | New internal procedure `GetActiveAssignment`. |
| PermissionSet | 50100 | EQM - Reader | `page "EQM Assignment History Part" = X` added. |

## Behavior
- **Assigned Since / Assigned By:** shown from the active assignment entry (Assignment Date, Assigned By). Filled only for a saved record with status Assigned; otherwise blank.
- **`GetActiveAssignment(EquipmentNo, var EquipmentAssignment): Boolean`** (internal, so no public XML-doc requirement; a `///` comment is present): resets the record, filters on equipment and Status = Active using key ("Equipment No.", Status), returns `FindLast()`. Equipment should have at most one active entry; if there are more, the newest is returned.
- **Created By / Last Modified By:** resolved in `UpdateControls` from `SystemCreatedBy` / `SystemModifiedBy` through local `GetUserName` (reads table User, `User Name`). Blank when the GUID is null, when the user has no read permission on table User, or when the user no longer exists. No error is raised.
- **Assignment History part:** shows all entries of the equipment, active and closed. Employee Name is blank if the employee record no longer exists.
- **Audit group** is the last section and its dates are visible without "Show more".
- **Teaching tip:** one translated string pair. `AboutText` uses `**bold**` markup. TODO(verify): renders as bold in a sandbox.

## FR-011 update (maintenance history)
The card also has part `MaintenanceHistory` (page 50116) after Assignment History, linked on "Equipment No." = "No.", and action `ShowMaintenanceHistory` (Equipment group, promoted under Navigate, enabled when the record is saved) that opens page 50117 filtered on the equipment. The `AboutText` was extended. The part shows posted entries only. Details: docs/features/FR-011-maintenance-history.md. Not run in a sandbox (HS-SB2).

## Extending (events)
No events published or subscribed, no signature changes. `GetActiveAssignment` is internal and not callable from other apps. Partners can extend the card with page extensions; new control names (`AssignedSince`, `AssignedBy`, `CreatedBy`, `LastModifiedBy`, `AssignmentHistory`) could clash with same-named partner controls.

## Permissions
EQM - Reader now includes `page "EQM Assignment History Part" = X`; it already had `tabledata "EQM Equipment Assignment" = R` and `codeunit "EQM Assignment Mgt." = X`. EQM - Manager and Administrator include it by inclusion. Since NFR-002 the Assigned Employee Name is blank without Employee read permission.

**Known limitations:**
- **Created By and Last Modified By show blank without read access to the User table.** No EQM set grants it. This is deliberate: the page checks `User.ReadPermission()` and shows blank rather than failing.
- Employee Name in the history part and on the card reads table Employee, which comes from D365 BASIC (same assumption as FR-007).

## Translations
`app/Translations/Equipment Management.g.xlf` **still needs to be regenerated with AL: Package**. Never edit it by hand. It does not yet contain the FR-008 teaching tip, captions or tooltips. TODO(verify) after the build.

## Upgrade and compatibility
Additive page controls, one new page, one internal procedure. No schema or API change. No Obsolete handling.

## Test status
No test objects; test codeunit ID 50160 is reserved and unused. The scenarios in docs/plans/FR-008-equipment-card.md are a reference only. **The code has not been compiled or run in a sandbox.**

TODO(verify) in a sandbox:
- Card of Assigned equipment shows Assigned Since and Assigned By; they are blank after Return.
- History part lists all entries newest first and is read-only.
- Created By / Last Modified By show names for a user with User table read access and blank without it.
- Teaching tip bold markup.

## Discrepancies plan vs code
None found in the files read. The plan was not copied here; it is a design record.
