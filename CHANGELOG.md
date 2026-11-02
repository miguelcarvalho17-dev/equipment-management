# Changelog
Newest first. Grouped by Added / Changed / Fixed / Obsolete.

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
