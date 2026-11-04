# Changelog
Newest first. Grouped by Added / Changed / Fixed / Obsolete.

## FR-006 Assignment History Tracking (version stays 29.0.0.0, no bump)
### Added
- Closed assignment entries can no longer be modified or renamed (error `ClosedEntryCannotBeChangedErr`, raised by the table triggers).
- Internal procedure `HasAssignmentHistory` in codeunit "EQM Assignment Mgt.".
### Changed
- Equipment with any assignment entry (active or closed) cannot be deleted; the message tells the user to set the status to Disposed. Closed entries are no longer deleted with their equipment. Supersedes the FR-004 and FR-005 delete rule.
- EQM - Edit has `Rim` (no delete) on assignments; the codeunit permission `d` was removed.
- Tooltip of the Status field on assignments extended. Field names are unchanged: Start Date = Assignment Date, End Date = Closing Date.
### Fixed
- None.
### Obsolete
- Removed internal `DeleteAssignments` and the label `ActiveAssignmentExistsErr`.

Release notes: Assignment history is now protected. Every assignment is kept with its start date (Assignment Date), end date (Closing Date) and the user who assigned it. Closed assignments cannot be changed, and equipment that has ever been assigned cannot be deleted; set it to Disposed instead.

Note: no automated tests (deferred, D4) and not run in a sandbox; see docs/features/FR-006-assignment-history-tracking.md. No new objects, events or schema changes. Trigger-less writes (`Modify(false)`, `Delete(false)`) bypass both rules.

## FR-005 Equipment Unassignment (version stays 29.0.0.0, no bump)
### Added
- FR-005 Equipment Unassignment: equipment can be returned from the equipment card (action Return) and from the Employee Card (action Return Equipment, pick the employee's assigned equipment). A return clears the employee, sets the status to Available and closes the assignment entry, which is kept as history.
### Changed
- The card action "Unassign" is now "Return"; related messages and tooltips reworded. Internal names are unchanged.
- Assigned equipment can become Available only through Return; choosing Available in the Status field is refused with a message.
- `UnassignEmployee` (internal) refuses equipment that is not Assigned, asks a return-specific confirmation and returns a Boolean.
### Fixed
- None.
### Obsolete
- None.

Note: no automated tests (deferred by user request); the return flow and the Employee Card action are not run-tested in a sandbox. No new events or objects. See docs/features/FR-005-equipment-unassignment.md.

## FR-004 Equipment Assignment (version stays 29.0.0.0, no bump)
### Added
- FR-004 Equipment Assignment: every assignment is recorded (equipment, employee, assignment date, assigned by) and closed automatically when the equipment stops being Assigned. Assignments list with views Active and Closed; actions on the equipment card, equipment list and Employee Card.
- Table "EQM Equipment Assignment", enum "EQM Assignment Status", codeunit "EQM Assignment Mgt.", page "EQM Equipment Assignments", page extension "EQM Employee Card".
- Events `OnBeforeInsertAssignment` and `OnBeforeCloseAssignment` in codeunit "EQM Assignment Mgt.".
### Changed
- Only Available equipment can be assigned: In Maintenance to Assigned is now refused (partners can relax it with `OnBeforeCheckStatusTransitionAllowed`).
- Assigned equipment cannot be reassigned in one step; unassign first.
- New equipment cannot be created as Assigned; the Status control on a new card offers Available and In Maintenance.
- Assigned Employee No. on the equipment card is read-only; use Assign to Employee.
- Deleting equipment: refused while Assigned (replaces the confirmation) or with an active assignment; closed assignments are deleted with the equipment.
- EQM - Read gets read on assignments; EQM - Edit gets indirect rights only.
### Fixed
- None.
### Obsolete
- None.

Note: not compiled (.NET 10 missing locally) and no automated tests (decision D8); see docs/features/FR-004-equipment-assignment.md. Equipment already Assigned before FR-004 has no assignment entry (no backfill).

## FR-003 Equipment Status Management
### Added
- FR-003 Equipment Status Management: statuses Available, Assigned, In Maintenance, Lost and Disposed. Lost and Disposed are final: they cannot be assigned, cannot be changed to another status, and cannot be set on new equipment. Changing to Lost or Disposed asks for confirmation and removes the assigned employee.
- Status colors on the equipment list and card; list views for each status.
- Event `OnBeforeCheckStatusTransitionAllowed` in table "EQM Equipment".
### Changed
- Enum "EQM Equipment Status": value "Under Maintenance" renamed to "In Maintenance", Retired renamed to Disposed (ordinals unchanged, so stored Retired records are now Disposed and final), new value Lost.
- An employee is now allowed only when the status is Assigned; this can no longer be skipped by an extension.
- Event `OnBeforeCheckAssignedEmployeeAllowed` replaced by `OnBeforeCheckEmployeeIsEligible`, which only skips the "employee is Active / not privacy blocked" checks.
- Assign to Employee is disabled for Lost and Disposed equipment.
### Fixed
- None.
### Obsolete
- None.

## 29.1.0.0 - 2026-11-02
### Added
- FR-002 Equipment Categories: **Active** flag on equipment categories (default Yes). Only active categories can be newly set on equipment; equipment that already uses a category keeps it.
- Starter categories TABLET and PRINTER for new companies.
- Event `OnBeforeCheckCategoryIsActive` in table "EQM Equipment".
- Feature `TranslationFile` in app.json (source file `Equipment Management.g.xlf` is generated by the first build).
### Changed
- A non-existing category code on equipment now raises the app's own error instead of the platform table-relation error (FR-001 scenario 9).
- Category maintenance (create, edit, delete) moved from EQM - Edit to EQM - Admin (FR-001 scenario 53). EQM - Edit can still read categories.
- Deleting a category in use is still refused; the message now suggests clearing Active.
- Renaming an inactive category that equipment uses is refused.
- Starter category PHONE is now described as "Mobile Phone" (new companies only).
- Development sandboxes: existing category rows get Active = false after the schema sync; reinstall or tick Active.
### Fixed
- None.
### Obsolete
- None.

Note: not yet compiled or tested (tests deferred to V5; .NET 10 missing locally); see docs/features/FR-002-equipment-categories.md.

## 29.0.0.0 - 2026-11-02
### Added
- FR-001 Equipment Registration: equipment master data with number series, categories, serial number, purchase data, status and employee assignment; list, card, categories and setup pages.
- Default data on install: number series EQUIP and categories LAPTOP, MONITOR, PHONE, VEHICLE, TOOL.
- Permission sets EQM - Read, EQM - Edit, EQM - Admin; permission set extension for D365 BASIC (indirect read on equipment).
- Events `OnBeforeCheckSerialNoIsUnique`, `OnBeforeCheckAssignedEmployeeAllowed` and `OnAfterCheckEquipmentConsistency` in table "EQM Equipment".
### Changed
- Deleting an Employee is refused while equipment is assigned to that employee.
### Fixed
- None.
### Obsolete
- None.

Note: not yet compiled or tested; see docs/features/FR-001-equipment-registration.md.

---

# Release notes text (AppSource)

**Equipment registration.** You can now keep a register of your equipment. Each item gets a number, a
category, an optional serial number and purchase details, and you can assign it to an active employee and
unassign it again. Starter categories are included. Note that an employee who still has equipment
assigned can no longer be deleted until the equipment is unassigned.

**Equipment categories.** Administrators can now mark an equipment category as inactive. Inactive categories
can no longer be chosen for new equipment or when changing an equipment category, while equipment that already
uses them keeps them. Maintaining categories now requires the Equipment - Admin permission set. New companies also
get the Tablet and Printer categories.

**Equipment status management.** Equipment now has the statuses Available, Assigned, In Maintenance, Lost and Disposed, shown in color, with a view for each status on the equipment list. Lost and Disposed are final: you confirm the change, the employee is removed, and the status cannot be changed again. New equipment cannot start as Lost or Disposed. "Under Maintenance" is now called In Maintenance and "Retired" is now called Disposed.

**Equipment assignment.** Every assignment of equipment to an employee is now recorded with the date and the user, and closed automatically when the equipment is unassigned or its status changes. You can view the history per equipment and per employee. Only available equipment can be assigned: equipment in maintenance must first be set to Available, assigned equipment must be unassigned before it goes to someone else, and new equipment cannot start as Assigned. Equipment that is assigned cannot be deleted.
