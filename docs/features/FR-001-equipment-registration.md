# FR-001 Equipment Registration

## Purpose
Maintain equipment master data (number, category, serial number, purchase data, status) and assign equipment
to employees. Later features (maintenance) build on these records. The app also blocks deleting a standard
Employee while equipment references that employee.

Status of this document: describes the code as implemented. Nothing has been compiled yet and there are no
automated tests (see "Known limitations / verification pending").

## Objects
All objects are in the AL namespace `MiguelCarvalho.EquipmentManagement`. Partner extensions must add `using MiguelCarvalho.EquipmentManagement;` to reference them (for example when subscribing to the published events).

| Type | ID | Name | Role |
|---|---|---|---|
| Enum | 50100 | EQM Equipment Status | Available, Assigned, Under Maintenance, Retired. Extensible. |
| Table | 50100 | EQM Equipment | Equipment master, validation, confirmations, published events. Access = Public. |
| Table | 50101 | EQM Equipment Category | Category master. Cannot be deleted while used. Access = Public. |
| Table | 50102 | EQM Equipment Setup | Singleton setup (Equipment Nos.). Access = Public. |
| Page | 50100 | EQM Equipment List | Read-only list; links to Categories and Setup. |
| Page | 50101 | EQM Equipment Card | Create and maintain; Assign to Employee / Unassign actions. |
| Page | 50102 | EQM Equipment Categories | Editable category list. |
| Page | 50103 | EQM Equipment Setup | Setup card; creates defaults when the setup record is missing. |
| Codeunit | 50103 | EQM Employee Subscribers | Internal. Blocks Employee delete while equipment references the employee. |
| Codeunit | 50104 | EQM Install | Install; calls default data creation per company. |
| Codeunit | 50105 | EQM Default Data | Internal. Idempotent creation of setup, series EQUIP and starter categories. |
| PermissionSet | 50100 / 50101 / 50102 | EQM - Read / Edit / Admin | See Permissions. |
| PermissionSetExtension | 50103 | EQM D365 BASIC | Extends standard set "D365 BASIC" with indirect read on equipment. |

## Setup
1. Open **Equipment Setup**. If no setup record exists in the company, it is created and the defaults are added
   (number series `EQUIP` starting at `EQ00001`, categories LAPTOP, MONITOR, PHONE, VEHICLE, TOOL).
2. **Equipment Nos.** selects the number series used for new equipment. Change it to use another series.
- On install, the same default data is created in every company. Existing series, setup values and categories are never overwritten.
- Series `EQUIP` is created with Default Nos. and Manual Nos. enabled.
- Equipment cannot be created with a blank number until Equipment Nos. is set (TestField error).

## Behavior
Equipment (table 50100):
- **No.**: taken from the Equipment Nos. series on insert when blank. A manually typed number needs Manual Nos. on the series; the number is then saved with a blank "No. Series".
- **Category Code**: mandatory (checked on insert and modify); must exist in categories.
- **Serial No.**: optional. If filled, it must be unique across equipment. Several records may have a blank serial number.
- **Status**: defaults to Available.
- **Assigned Employee No.**: may only be filled when Status = Assigned, and must be filled when Status = Assigned.
  - When the employee is entered or changed (validate, or a different employee on modify), the employee must exist, have Status Active and not be Privacy Blocked.
  - An employee already assigned who later becomes inactive does not block editing the equipment; unassigning is always possible.
  - If the assigned employee record no longer exists, every validate/insert/modify raises "Employee ... no longer exists" until the equipment is unassigned.
- **Status change away from Assigned** while an employee is set: asks for confirmation; Yes clears the employee, No cancels the change.
- **Delete** of equipment that is Assigned to an employee: asks for confirmation; No cancels the delete. Other equipment is deleted without a question.
- Confirmations use codeunit "Confirm Management" `GetResponseOrDefault` with default Yes: in sessions without UI (API, job queue) no dialog appears and the answer is Yes.
- Created Date / Last Modified Date are the system fields SystemCreatedAt / SystemModifiedAt (shown on the card, Additional importance).

Equipment Card (page 50101): DelayedInsert is on, so a new record is saved only when the mandatory category is filled in. The "Assigned Employee No." field is editable only while Status = Assigned; its lookup lists only Active, not privacy-blocked employees (the table relation itself is not filtered). **Assign to Employee** (enabled for saved records) opens Employee List filtered the same way and assigns the choice, also for equipment that is already assigned. **Unassign** (enabled when Status = Assigned) clears the employee and sets Available. The "No." AssistEdit works only while No. is blank.

Category (table 50101): deleting a category used by any equipment raises an error.

Employee delete guard (codeunit 50103): subscribes to the implicit `OnBeforeDeleteEvent` of table Employee. It exits when RunTrigger is false or the record is temporary; otherwise any equipment record referencing the employee blocks the delete with an error. Deletes with RunTrigger = false (some migration or configuration paths) bypass the guard.

## Extending (events)
Published from table "EQM Equipment" as `[IntegrationEvent(false, false)]`, declared `local` (subscribable). Records are passed by value, so subscribers cannot change them.
| Event | Raised | Parameters | What you can do |
|---|---|---|---|
| `OnBeforeCheckSerialNoIsUnique` | Before the serial number uniqueness check (on validating Serial No. and on insert/modify) | `Equipment`; `IsHandled` (var) | Set `IsHandled = true` to replace the uniqueness rule. |
| `OnBeforeCheckAssignedEmployeeAllowed` | Before the assigned employee checks (on validating Assigned Employee No. and on insert/modify) | `Equipment`; `IsHandled` (var) | Set `IsHandled = true` to skip: "only when Assigned", employee exists, Active, not privacy blocked. The "Assigned requires an employee" rule is not skipped. |
| `OnAfterCheckEquipmentConsistency` | At the end of the insert/modify check, after all standard checks passed | `Equipment` | Add checks; raise an error to reject the save. |

Subscribed: table Employee, implicit `OnBeforeDeleteEvent` (see above).

## Permissions
| Set | Allows |
|---|---|
| EQM - Read (`Equipment - Read`) | Read equipment (R), categories (R, indirect insert) and setup (R, indirect insert and modify); execute the app's tables, pages and the two internal codeunits. |
| EQM - Edit (`Equipment - Edit`) | Includes Read; full RIMD on equipment and categories. |
| EQM - Admin (`Equipment - Admin`) | Includes Edit; full RIMD on setup. |
| D365 BASIC (extension 50103) | Adds indirect read (`r`) on equipment so the Employee delete guard works for any user who can delete employees. |

- Users also need a standard base set (D365 BASIC) for Employee, Location and No. Series access; the EQM sets do not grant base data.
- Codeunits 50103 and 50105 declare `Permissions` (indirect only). They take effect only when the user holds the matching lowercase rights.

## Upgrade and compatibility
First version: new objects only, no upgrade codeunit. Standard behavior change: deleting an Employee with equipment assigned is now refused.
After release, field IDs/names of tables 50100-50102, enum values, the three event signatures, page IDs and permission set names are contracts.
`AssistEdit`, `AssignEmployee`, `UnassignEmployee`, `CheckEquipmentConsistency` and the codeunits 50103 and 50105 are `internal`, not API.
Uninstalling does not remove the default data.

## Known limitations / verification pending
- **Not compiled.** `alc` needs .NET 10, which was unavailable; no build has run, so compiler and analyzer warnings are unknown.
- **No automated tests.** Deferred to a future version. Scenarios 1-57 in `docs/plans/FR-001-equipment-registration.md` are the specification for them.
- **Manual sandbox checks still open:**
  1. The implicit Employee `OnBeforeDeleteEvent` subscriber fires when an Employee is deleted from the Employee Card with equipment assigned (guard error expected). No published Employee delete event was confirmed.
  2. Indirect permissions: a user with only D365 BASIC (no EQM set) deletes an Employee with equipment (expect the guard error, not a permission error) and one without equipment (expect success).
  3. A user with only EQM - Read opens Equipment Setup in a fresh company: expect no permission error and defaults created.
  4. Publish into a fresh company: defaults exist; republish: no duplicates.
- Deletes with RunTrigger = false bypass the Employee guard (accepted).
- Location delete is not guarded; Location Code may dangle.
- TODO(verify): setting Status to Assigned directly on the card for an existing record is expected to fail on save (employee required); the intended path is the Assign to Employee action. Not exercised in a client.
- TODO(verify): Delete from the (non-editable) Equipment List is expected to show the confirmation for assigned equipment.
- app.json is not AppSource-ready (outside FR-001): empty privacyStatement, EULA, help, url, logo; no translation file; demo ID range.

## Plan discrepancies
- Plan lists `CheckSerialNoIsUnique` and `CheckAssignedEmployeeAllowed` as internal; in code they are `local`.
- Employee-not-found rule and delete guard filtering on the employee only (not Status) are plan revision 3 items; both match the code.
