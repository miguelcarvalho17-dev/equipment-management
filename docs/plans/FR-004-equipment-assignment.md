# FR-004 Equipment Assignment

> Status: REVISION 2, **APPROVED** by the user (decisions D1-D10 under "Risks and open questions" are final).
> Source: GitHub issue #9. Branch: `feature/FR-004-equipment-assignment`.
> No events report: FR-004 does not change standard BC behavior and subscribes to no standard events (see Events).
> al-event-finder is not needed. The only base-app touch is a UI action on the standard Employee Card (page extension).
> Scope of this iteration: main app only. **No automated tests** (D8: no test objects; the scenario list below is a
> reference only; the reserved test IDs stay unused). **No version bump** (D9: app.json stays 29.0.0.0). **No upgrade
> logic and no backfill** (D10).
> Workflow for FR-004: planner -> developer -> reviewer -> **tester step SKIPPED** -> documenter -> appsource-validator.

## Goal
Every time equipment is assigned to an employee, the app records an assignment entry with the equipment, the employee,
the assignment date and the user who performed it. An equipment record has at most one active assignment entry, which
is closed automatically when the equipment stops being Assigned. Only saved Available equipment can be assigned, and
assigning sets the status to Assigned through the existing FR-001/FR-003 logic in table 50100.

### Requirement restated
- Assignment information (issue): Equipment No., Employee No., Assignment Date, Assignment Performed By.
- BR-A1: equipment can be assigned only when its Status is Available. New equipment cannot be created as Assigned (D3).
- BR-A2: assigning sets Status to Assigned automatically.
- BR-A3: an employee may have several assignments (several equipment at once, and history over time).
- BR-A4: equipment has at most one active assignment at a time.

### What already exists (FR-001 / FR-003) and is reused, not duplicated
- Table 50100 "EQM Equipment" already holds the **current** assignment: Status (enum 50100) and "Assigned Employee No."
  (employee must exist, be Active and not privacy blocked; only allowed while Assigned; required while Assigned).
- `AssignEmployee(EmployeeNo)` (internal) validates Status := Assigned, validates the employee and calls Modify(true).
  `UnassignEmployee()` validates Status := Available (with confirm) and calls Modify(true). The card actions
  "Assign to Employee" / "Unassign" call them.
- FR-003 `CheckStatusTransitionAllowed(FromStatus, ToStatus)` runs on Status validate (from xRec) and on modify (from the
  stored record). It holds the hard rule "Lost/Disposed cannot become Assigned" and raises
  `OnBeforeCheckStatusTransitionAllowed` (IsHandled).
- FR-003 already refuses final statuses on new records (Status OnValidate with `IsStoredRecord`, and
  `CheckEquipmentConsistency` on insert), and the card shows a `StatusNew` control with `ValuesAllowed` on new records.
  FR-004 extends the same two checks and the same control for Assigned (D3).
- Status changes away from Assigned (Unassign, In Maintenance, Lost, Disposed) already clear the employee.
- Codeunit 50103 blocks deleting an Employee referenced by any equipment (implicit Employee `OnBeforeDeleteEvent`).

### How FR-004 maps onto this
- **Assigning** = a saved equipment record changes from Available to Assigned. This keeps one assignment path
  (table 50100). The status change itself (BR-A2) is the existing FR-001/FR-003 logic; FR-004 only tightens which
  status may become Assigned (BR-A1) and records the entry.
- **Active assignment** is modelled by a new history table "EQM Equipment Assignment" with its own status enum
  **Active / Closed**. An entry is created Active when saved equipment becomes Assigned, and set to Closed (with closing
  date and user) when equipment leaves Assigned for any reason (Unassign, In Maintenance, Lost, Disposed). Invariant:
  `Equipment.Status = Assigned` <=> exactly one Active entry for that equipment, with the same employee.
- A full "return" process (return condition, notes, return document) is **out of scope** (D5). Closing is automatic.
- The equipment field "Assigned Employee No." stays the source of truth for the current assignee (it is used by the
  list, the card, the Employee delete guard and partners). The entry table is the record of who/when/by whom.

## Approach and rejected alternatives
- Chosen:
  - **New table 50103 "EQM Equipment Assignment"** (entry table, AutoIncrement entry no.) and **enum 50101
    "EQM Assignment Status"** (Active, Closed; not extensible).
  - **New codeunit 50106 "EQM Assignment Mgt."** holds the bookkeeping (create entry, close entry, delete closed
    entries with safety checks) and two publisher events. Table 50100 calls it from OnModify and OnDelete, after its own
    checks. So every path that saves equipment with triggers (card, list, API, code, RapidStart with validation) keeps
    the entries in sync, and the FR-003 status logic stays the only place where status changes are decided.
  - **BR-A1 in the existing FR-003 transition check:** new rule "ToStatus = Assigned requires FromStatus = Available",
    placed **after** `OnBeforeCheckStatusTransitionAllowed` (partners can relax it, like the "final status" rule), and
    after the existing hard rule "Lost/Disposed cannot become Assigned" (still not relaxable).
  - **No Assigned on new records (D3), hard rule:** Status OnValidate and the insert check in
    `CheckEquipmentConsistency` refuse Status = Assigned on a record that is not yet in the database, next to the
    existing FR-003 final-status checks. The card's `StatusNew` control drops Assigned from `ValuesAllowed`. No entry is
    ever created on insert.
  - **BR-A4 as hard rules in table 50100:** (a) `AssignEmployee` refuses equipment that is already Assigned;
    (b) `CheckEquipmentConsistency` on modify refuses changing the employee while the equipment stays Assigned
    (reassignment must go through Unassign first, D1). (c) Codeunit 50106 closes any leftover Active entry before it
    creates a new one (data repair after trigger-less writes), so there is never more than one Active entry.
  - **Equipment delete with safety checks (D6):** deleting equipment is refused while it is Assigned or while it still
    has an Active entry; otherwise its Closed entries are deleted with it. There is no other way for users to delete
    entries (see "D6 interpretation" under Risks and open questions).
  - Assignment Date = `WorkDate()` and Assigned By = current user ID, filled automatically (D4). The exact timestamp is
    also available in SystemCreatedAt.
  - UI: a read-only list page "EQM Equipment Assignments" (searchable), opened filtered from the equipment card and list
    (per equipment) and from the standard Employee Card through a page extension (per employee, BR-A3, D7).
  - Card: "Assign to Employee" enabled only for saved Available equipment; "Assigned Employee No." is never editable on
    the card (new records cannot be Assigned, saved assignments cannot be changed in place). The action is the only UI
    path to assign.
- Rejected: an assignment journal/document as the entry point (user creates an assignment line, which then updates the
  equipment). Two ways to make equipment Assigned would exist and the FR-003 status logic would have to be duplicated
  or guarded with flags.
- Rejected: bookkeeping only inside `AssignEmployee`/`UnassignEmployee`. Status changes on the card (to In Maintenance,
  Lost, Disposed) and API writes would bypass the entries.
- Rejected: adding "Assignment Date"/"Assigned By" fields to table 50100 only. It cannot show an employee's history
  (BR-A3) and loses data on every reassignment.
- Rejected: an "Active" Boolean instead of a status enum on the entry. An enum reads better in filters and views and can
  be made extensible later without a breaking change (the reverse would be breaking).
- Rejected: automatic reassignment (close the old entry, open a new one) when the employee changes on Assigned
  equipment. The issue says only Available equipment can be assigned (D1).
- Rejected: allowing new equipment to be created as Assigned and creating the entry on insert (D3). The user wants
  assignment to happen only on saved Available equipment.
- Rejected: making BR-A1 a hard (non-relaxable) rule. FR-003 lets partners relax transition rules through the event;
  BR-A1 follows the same pattern. Only "Lost/Disposed cannot be assigned", "no Assigned on new records" and BR-A4 stay hard.
- Rejected: a dialog page for the user to enter the assignment date (D4). Adds an object; WorkDate covers backdating.
- Rejected: deleting all entries (Active included) with the equipment, or keeping orphan entries after deleting
  equipment (D6). The first loses the record of a current assignment; the second leaves entries for equipment that no
  longer exists.
- Rejected: letting users delete entries on the assignments page (D6). Entries are an audit trail.
- Rejected: any standard BC event subscription. Nothing in standard behavior changes (see Events).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50102, pages 50100-50103, codeunits 50103-50105,
enum 50100, permission sets 50100-50102, permission set extension 50103; no page extensions. Test app: no objects
(FR-001 reserved test codeunits 50150-50155, never built).

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50101 | EQM Assignment Status | New | Active, Closed (`Extensible = false`) |
| Table | 50103 | EQM Equipment Assignment | New | One entry per assignment: equipment, employee, date, user, status, closing data |
| Page | 50104 | EQM Equipment Assignments | New | Read-only list of assignment entries, views Active/Closed |
| Codeunit | 50106 | EQM Assignment Mgt. | New | Create/close entries on equipment modify; delete Closed entries with safety checks on equipment delete; publishes 2 events |
| PageExtension | 50100 | EQM Employee Card | Extend "Employee Card" (5200) | Action "Equipment Assignments" filtered on the employee |
| Table | 50100 | EQM Equipment | Modify (own) | BR-A1 in transition check, no Assigned on new records, BR-A4 checks, delete refused while Assigned, calls to codeunit 50106, tooltip/doc updates |
| Page | 50101 | EQM Equipment Card | Modify (own) | StatusNew without Assigned; employee field read-only; Assign enabled only when Available; Assignments action |
| Page | 50100 | EQM Equipment List | Modify (own) | Assignments action |
| PermissionSet | 50100 | EQM - Read | Modify | Read on the new table; X on new table, page, codeunit |
| PermissionSet | 50101 | EQM - Edit | Modify | Indirect insert/modify/delete on the new table |

No test objects in this iteration (D8). Test codeunit IDs 50156 "EQM Assignment Tests" and 50157 "EQM Assignment Test
Subscr." are reserved for when the user writes the tests; they stay unused now.
Not changed: tables 50101/50102, pages 50102/50103, codeunits 50103/50104/50105, enum 50100, permission set 50102
(EQM - Admin inherits Edit), permission set extension 50103, `app/app.json` (D9), `test/`.
Folder: new files go in `app/src/Assignment/` (`EQMAssignmentStatus.Enum.al`, `EQMEquipmentAssignment.Table.al`,
`EQMEquipmentAssignments.Page.al`, `EQMAssignmentMgt.Codeunit.al`); the page extension goes in
`app/src/Employee/EQMEmployeeCard.PageExt.al`. Namespace `MiguelCarvalho.EquipmentManagement` like all existing files.
Next free IDs after FR-004: tables 50104, pages 50105, codeunits 50107, enums 50102, page extensions 50101,
permission sets 50104; test codeunits 50156 (50156/50157 reserved for FR-004 tests).

### Enum 50101 "EQM Assignment Status"
- Caption 'Equipment Assignment Status'; `Extensible = false`; `/// <summary>`: "Status of an equipment assignment
  entry. Active means the equipment is currently assigned to the employee; Closed means the assignment has ended."
- Values: 0 Active (Caption 'Active'), 1 Closed (Caption 'Closed').

### Table 50103 "EQM Equipment Assignment"
Object properties: Caption 'Equipment Assignment'; DataClassification CustomerContent; Access = Public;
LookupPageId and DrillDownPageId "EQM Equipment Assignments"; DataCaptionFields "Equipment No.", "Employee No.".
`/// <summary>`: "One entry per assignment of equipment to an employee. Entries are created and closed by the app when
equipment is assigned and unassigned; users cannot edit them. Closed entries are deleted together with their equipment."

| Field ID | Name | Type | Caption | Properties |
|---|---|---|---|---|
| 1 | "Entry No." | Integer | Entry No. | `AutoIncrement = true`. ToolTip 'Specifies the number of the assignment entry.' |
| 2 | "Equipment No." | Code[20] | Equipment No. | `TableRelation = "EQM Equipment"."No."`; `NotBlank = true`. ToolTip 'Specifies the equipment that was assigned.' |
| 3 | "Employee No." | Code[20] | Employee No. | `TableRelation = Employee."No."`; `NotBlank = true`. ToolTip 'Specifies the employee the equipment was assigned to.' |
| 4 | "Assignment Date" | Date | Assignment Date | ToolTip 'Specifies the date the equipment was assigned. It is the work date of the user who assigned it.' |
| 5 | "Assigned By" | Code[50] | Assigned By | `TableRelation = User."User Name"`; `ValidateTableRelation = false`; `DataClassification = EndUserIdentifiableInformation`. ToolTip 'Specifies the user who assigned the equipment.' |
| 6 | Status | Enum "EQM Assignment Status" | Status | `InitValue = Active`. ToolTip 'Specifies whether the assignment is active or closed. Equipment has at most one active assignment. The assignment is closed when the equipment is unassigned or its status changes from Assigned to another status.' |
| 7 | "Closing Date" | Date | Closing Date | ToolTip 'Specifies the date the assignment was closed. It is the work date of the user who closed it.' |
| 8 | "Closed By" | Code[50] | Closed By | Same relation and DataClassification as field 5. ToolTip 'Specifies the user who closed the assignment.' |
| 9 | "Equipment Description" | Text[100] | Equipment Description | `FieldClass = FlowField`; `CalcFormula = lookup("EQM Equipment".Description where("No." = field("Equipment No.")))`; `Editable = false`. ToolTip 'Specifies the description of the equipment.' |

- DataClassification: set at table level (CustomerContent); only fields 5 and 8 override it.
- `User` is table "User" in namespace `System.Security.AccessControl`; `Employee` in `Microsoft.HumanResources.Employee`.
  Add `using` lines. **Verify the User namespace in the BC 29 symbols**; if it differs, stop and report.
- Keys: PK "Entry No." (Clustered); key `EquipmentStatus` ("Equipment No.", Status); key `EmployeeStatus`
  ("Employee No.", Status).
- Field groups: DropDown = "Entry No.", "Equipment No.", "Employee No.", "Assignment Date", Status.
- No table triggers, no procedures, no events in the table. Write protection comes from permissions (users get only
  indirect insert/modify/delete; see Permissions) and from the read-only page.
- Renaming equipment or an employee updates fields 2/3 through the TableRelation (platform behavior).

### Codeunit 50106 "EQM Assignment Mgt."
- `Access = Public` (required so other apps can subscribe to its events); all procedures except the event publishers
  are `internal` or `local`.
- `Permissions = tabledata "EQM Equipment Assignment" = rimd, tabledata "EQM Equipment" = r`.
- `/// <summary>` on the codeunit: "Keeps the equipment assignment entries in sync with the equipment status."

**`internal procedure UpdateAssignmentOnSave(Equipment: Record "EQM Equipment")`**
Called only by table 50100 OnModify after `CheckEquipmentConsistency(false)`, so the record already passed all checks.
Not called on insert: new equipment cannot be Assigned (D3), so there is never an entry to create on insert.
1. WasAssigned := false. Read a second EQM Equipment record with `SetLoadFields(Status)` and `Get(Equipment."No.")`;
   if found, WasAssigned := stored Status = Assigned.
2. IsAssigned := Equipment.Status = Assigned.
3. If not WasAssigned and IsAssigned: call `CreateAssignment(Equipment)`.
4. If WasAssigned and not IsAssigned: call `CloseActiveAssignments(Equipment)`.
5. Otherwise do nothing (no status change in or out of Assigned; employee changes while Assigned are already refused
   by table 50100).
- Doc comment: "Creates an active assignment entry when saved equipment becomes Assigned, and closes it when the
  equipment stops being Assigned. Call it from the equipment modify trigger, after the consistency check."

**`local procedure CreateAssignment(Equipment: Record "EQM Equipment")`**
1. `CloseActiveAssignments(Equipment)` (repairs leftovers so BR-A4 holds; normally finds nothing).
2. Init a new EQM Equipment Assignment: "Equipment No." := Equipment."No."; "Employee No." := Equipment."Assigned
   Employee No."; "Assignment Date" := `WorkDate()`; "Assigned By" := current user ID (`UserId()` copied with
   `CopyStr` to the field length, to avoid the implicit-truncation warning); Status := Active.
3. Raise `OnBeforeInsertAssignment(EquipmentAssignment, Equipment)`.
4. Insert(true).

**`local procedure CloseActiveAssignments(Equipment: Record "EQM Equipment")`**
1. Filter EQM Equipment Assignment: SetCurrentKey("Equipment No.", Status); "Equipment No." = Equipment."No.";
   Status = Active. If `FindSet()`: for each entry, set Status := Closed, "Closing Date" := `WorkDate()`,
   "Closed By" := current user ID (CopyStr), raise `OnBeforeCloseAssignment(EquipmentAssignment, Equipment)`,
   then Modify(true).
   Modifying a field that is part of the filter (Status) inside the loop: iterate on one record variable and modify a
   second variable obtained with `Get("Entry No.")`. It must not skip or revisit entries. (Normally at most one entry matches.)
2. No error when nothing is found (equipment that was Assigned before FR-004 existed, see R3).

**`internal procedure DeleteAssignments(EquipmentNo: Code[20])`** (D6, safety checks)
Called from table 50100 OnDelete, after the table's own "equipment is Assigned" check.
1. Safety check: filter entries on "Equipment No." = EquipmentNo and Status = Active (key EquipmentStatus). If not
   `IsEmpty()`: Error(ActiveAssignmentExistsErr, EquipmentNo). This catches leftovers from trigger-less writes on
   equipment that is no longer Assigned.
2. Change the Status filter to Closed and `DeleteAll(false)` (the table has no triggers).
- Doc comment: "Deletes the closed assignment entries of the equipment. Raises an error when the equipment still has an
  active assignment entry."

**Labels** (codeunit 50106):
- `ActiveAssignmentExistsErr`: 'You cannot delete equipment %1 because it has an active assignment. Assign the equipment and then unassign it to close the assignment, and then delete the equipment.' Comment: '%1 = equipment number'.
  (Assigning closes the leftover entry and creates a new one; unassigning closes that one; see A13.)

**Events:** see Events section (two publishers, both `[IntegrationEvent(false, false)]`, `local`).

### Table 50100 "EQM Equipment" (changes)

**Field 9 Status: ToolTip** becomes:
'Specifies the lifecycle status of the equipment: Available, Assigned, In Maintenance, Lost or Disposed. Only saved, available equipment can be assigned; use the Assign to Employee action. Lost and Disposed are final statuses: the equipment cannot be assigned or change status again. New equipment cannot start as Assigned, Lost or Disposed.'

**Field 9 Status: OnValidate** (one new step; all FR-003 steps unchanged and in the same order):
- New step directly after FR-003 step 1 (the final-status check for new records): if Status = Status::Assigned and not
  `IsStoredRecord()`: Error(NewEquipmentAssignedErr, Format(Status)). (D3)

**Field 10 "Assigned Employee No.": ToolTip** becomes:
'Specifies the employee the equipment is assigned to. To assign available equipment, use the Assign to Employee action. To change the employee, unassign the equipment first.'

**Procedure `CheckStatusTransitionAllowed(FromStatus, ToStatus)` (local, changed)**
New order:
1. Exit if FromStatus = ToStatus. (unchanged)
2. Hard: if ToStatus = Assigned and `IsFinalStatus(FromStatus)`: Error(CannotAssignFinalStatusErr, ...). (unchanged)
3. Raise `OnBeforeCheckStatusTransitionAllowed(Rec, FromStatus, ToStatus, IsHandled)`; exit if IsHandled. (unchanged)
4. If `IsFinalStatus(FromStatus)`: Error(StatusIsFinalErr, ...). (unchanged)
5. **New (BR-A1):** if ToStatus = Assigned and FromStatus <> Available:
   Error(NotAvailableForAssignmentErr, "No.", Format(FromStatus), Format(Status::Available)).
- Effect: Available -> Assigned allowed; In Maintenance (and any partner enum value) -> Assigned refused unless a
  subscriber sets IsHandled (D2); Lost/Disposed -> Assigned always refused. All other FR-003 transitions unchanged.
- Runs on Status validate (from xRec) and on modify (from the stored status), so direct field assignment plus
  Modify(true) is covered too. Not run on insert; new records are covered by the separate hard D3 check.

**Procedure `AssignEmployee(EmployeeNo)` (internal, changed)**
New steps:
1. Existing: if `IsFinalStatus(Status)`: Error(CannotAssignFinalStatusErr, "No.", Format(Status)).
2. **New (BR-A4, hard):** if Status = Assigned: Error(AlreadyAssignedErr, "No.", "Assigned Employee No.").
3. Existing: Validate(Status, Status::Assigned) (runs the transition check, which raises NotAvailableForAssignmentErr
   for In Maintenance and stays relaxable through the event; on an unsaved record the D3 check raises
   NewEquipmentAssignedErr); Validate("Assigned Employee No.", EmployeeNo); Modify(true).
   Modify(true) runs OnModify, which creates the assignment entry (see below).
- Doc comment replaces "Can also be used to reassign equipment that is already assigned." with:
  "Only saved, Available equipment can be assigned. An active assignment entry with the work date and the current user
  is created. Raises an error when the equipment is already assigned, or when the status is not Available (Lost and
  Disposed always; other statuses unless an extension allows the transition)."

**Procedure `UnassignEmployee()`:** code unchanged. Doc comment adds: "The active assignment entry is closed."

**Procedure `CheckEquipmentConsistency(IsNewRecord)` (changed)**
- New step directly after the existing `if IsNewRecord and IsFinalStatus(Status) then Error(NewEquipmentFinalStatusErr, ...)`:
  if IsNewRecord and (Status = Status::Assigned): Error(NewEquipmentAssignedErr, Format(Status)). Hard rule (D3), no event.
- The stored read stays `StoredEquipment.SetLoadFields("Assigned Employee No.", "Category Code", Status)`.
- New local Boolean `IsReassignment` (false by default) and Code[20] `StoredEmployeeNo`. Inside the existing
  `if StoredEquipment.Get("No.")` block, add: StoredEmployeeNo := StoredEquipment."Assigned Employee No.";
  IsReassignment := (StoredEquipment.Status = Status::Assigned) and (Status = Status::Assigned) and
  (StoredEmployeeNo <> '') and ("Assigned Employee No." <> '') and (StoredEmployeeNo <> "Assigned Employee No.").
- New step **directly after** the existing `if StatusChanged then CheckStatusTransitionAllowed(StoredStatus, Status)`:
  if IsReassignment: Error(AlreadyAssignedErr, "No.", StoredEmployeeNo). Hard rule (BR-A4), no event.
- All other steps unchanged and in the same order. Update the `/// <summary>`: add "new equipment cannot be Assigned"
  and "the employee of assigned equipment cannot be changed (unassign first)".

**Triggers (changed)**
- OnInsert: **no change** (no entry on insert; the D3 check inside `CheckEquipmentConsistency(true)` refuses Assigned).
- OnModify: after `CheckEquipmentConsistency(false)`, add a call to codeunit "EQM Assignment Mgt."
  `UpdateAssignmentOnSave(Rec)`.
- OnDelete (D6), replaces the FR-001 confirm:
  1. If Status = Status::Assigned: Error(DeleteAssignedErr, "No.", "Assigned Employee No."). No confirm any more.
  2. Call codeunit "EQM Assignment Mgt." `DeleteAssignments("No.")` (refuses a leftover Active entry, deletes Closed entries).
  - Remove the label `DeleteAssignedQst` and the local `ConfirmManagement` variable of OnDelete (they become unused;
    unused variables are analyzer warnings).
- Trigger-less writes (Insert(false), Modify(false), Delete(false), ModifyAll, DeleteAll) do not create, close or delete
  entries and skip all checks above (R2).

**New labels** (table 50100):
- `NotAvailableForAssignmentErr`: 'You cannot assign equipment %1 because its status is %2. Only equipment with the status %3 can be assigned.' Comment: '%1 = equipment number, %2 = current status caption, %3 = Available status caption'.
- `AlreadyAssignedErr`: 'Equipment %1 is already assigned to employee %2. Unassign the equipment first, and then assign it again.' Comment: '%1 = equipment number, %2 = employee number'.
- `NewEquipmentAssignedErr`: 'You cannot create equipment with the status %1. Create the equipment first, and then use the Assign to Employee action.' Comment: '%1 = status caption'.
- `DeleteAssignedErr`: 'You cannot delete equipment %1 because it is assigned to employee %2. Unassign the equipment first.' Comment: '%1 = equipment number, %2 = employee number'.
Removed label: `DeleteAssignedQst`.

**Event doc comment change (no signature change):** `OnBeforeCheckStatusTransitionAllowed`, parameter IsHandled becomes:
"Set to true to skip the standard transition rules: Lost and Disposed being final, and only Available equipment being
assignable. Lost and disposed equipment still cannot be assigned."

### Page 50104 "EQM Equipment Assignments"
- PageType List; Caption 'Equipment Assignments'; ApplicationArea All (page level); UsageCategory Lists;
  SourceTable "EQM Equipment Assignment"; `Editable = false`; `InsertAllowed = false`; `ModifyAllowed = false`;
  `DeleteAllowed = false`; `SourceTableView = sorting("Entry No.") order(descending)` (newest first).
- Repeater columns: "Entry No.", "Equipment No.", "Equipment Description", "Employee No.", Employee Name (page
  control), "Assignment Date", "Assigned By", Status, "Closing Date", "Closed By". "Entry No." with `Visible = false`.
- Employee Name: page variable `EmployeeName: Text[100]`, Caption 'Employee Name', ToolTip
  'Specifies the name of the employee.'. Set in OnAfterGetRecord: clear it; if Employee.Get("Employee No.") (with
  `SetLoadFields("First Name", "Middle Name", "Last Name")`) then EmployeeName := Employee.FullName(). Same approach
  as the card's "Assigned Employee Name".
- Status column: `StyleExpr` = page variable `StatusStyle`, set in OnAfterGetRecord: 'Favorable' for Active,
  'Subordinate' for Closed (Locked labels with suffix `Tok`, like FR-003).
- Actions (Navigation area, with actionrefs in Promoted): `Equipment` (Caption 'Equipment', ToolTip 'Opens the
  equipment card.', RunObject page "EQM Equipment Card", RunPageLink "No." = field("Equipment No."), Image of the
  developer's choice that compiles, e.g. `FixedAssets`); `Employee` (Caption 'Employee', ToolTip 'Opens the employee
  card.', RunObject page "Employee Card", RunPageLink "No." = field("Employee No."), Image `Employee`).
- Views (after `actions`, AL0926): `Active` Caption 'Active', Filters `where(Status = const(Active))`; `Closed`
  Caption 'Closed', Filters `where(Status = const(Closed))`. No default filter.

### Page 50101 "EQM Equipment Card" (changes)
- Control `StatusNew`: `ValuesAllowed = Available, "In Maintenance"` (Assigned removed, D3). Everything else unchanged.
- Field "Assigned Employee No.": `Editable = false` (was IsAssigned). Remove `ShowMandatory` and the control's
  OnLookup and OnValidate triggers (the field can no longer be edited on the card). `SelectActiveEmployee` stays; the
  Assign to Employee action still uses it.
- `UpdateControls()`: CanAssign becomes `IsSaved and (Rec.Status = Rec.Status::Available)`. Other lines unchanged.
- Action AssignToEmployee: ToolTip becomes 'Assigns available equipment to an active employee that you select. The
  assignment is recorded with the work date and your user name.' Enabled = CanAssign (unchanged binding).
- Action Unassign: ToolTip becomes 'Removes the assigned employee, sets the status to Available and closes the
  assignment.'
- New `area(Navigation)` with action `Assignments`: Caption 'Assignments'; ToolTip 'View the assignment history of the
  equipment.'; RunObject page "EQM Equipment Assignments"; RunPageLink "Equipment No." = field("No."); Image
  of the developer's choice that compiles (e.g. `History`); Enabled = IsSaved. Add an actionref in area(Promoted).
- Note: on a saved card the full Status control still lists Assigned; choosing it without an employee fails on save
  with the FR-001 AssignedEmployeeRequiredErr (unchanged behavior). The action is the intended path.

### Page 50100 "EQM Equipment List" (changes)
- In area(Navigation), add action `Assignments` with the same properties as on the card (no Enabled binding), and an
  actionref in area(Promoted).

### PageExtension 50100 "EQM Employee Card" extends "Employee Card" (D7)
- `addlast(Navigation)` action `EQMEquipmentAssignments`: Caption 'Equipment Assignments'; ToolTip 'View the equipment
  assignments of the employee.'; ApplicationArea All; RunObject page "EQM Equipment Assignments"; RunPageLink
  "Employee No." = field("No."); Image `Employee` or another that compiles. No promoted actionref (avoids depending on
  base action group names).
- **Verify** in the BC 29 symbols that page "Employee Card" exists with ID 5200 in `Microsoft.HumanResources.Employee`
  and that `addlast(Navigation)` is accepted. If not, stop and report.

### app.json, translations
- No app.json change (D9, version stays 29.0.0.0). The build regenerates `app/Translations/Equipment Management.g.xlf`;
  commit it, never edit it by hand.

## Data model and upgrade impact
- New table 50103 (9 fields) and enum 50101. Table 50100 gets no new fields.
- DataClassification: CustomerContent at table level; "Assigned By" and "Closed By" are
  EndUserIdentifiableInformation. "Employee No." stays CustomerContent, consistent with "Assigned Employee No." on
  table 50100 (the open TODO item about personal-data classification covers both).
- Upgrade codeunit: **not needed.** Nothing is released (development phase, as in FR-002/FR-003). **No backfill** (D10)
  of entries for equipment that was already Assigned before FR-004 (R3): such equipment has no Active entry;
  unassigning it finds nothing to close and raises no error; the next assignment creates an entry normally.
- Existing development data with equipment saved as Assigned is not affected by D3 (the rule applies to inserts only).
- Volume: one entry per assignment; entries are deleted only together with their equipment, and only when Closed (D6).

## Events
**Standard BC events: none needed.** FR-004 only changes this app's own objects. The status change, the employee
checks and the entry bookkeeping all run in table 50100 triggers and codeunit 50106. The Employee delete guard
(implicit Employee `OnBeforeDeleteEvent`, FR-001) is reused unchanged: it keeps blocking deletion of an employee that
is the current assignee on any equipment; closed history entries do not block (R5). The Employee Card page extension
adds a UI action only, no event. No events report is required.

Subscribed: none.

Published (codeunit 50106, Public codeunit, `[IntegrationEvent(false, false)]`, `local`):
- `OnBeforeInsertAssignment(var EquipmentAssignment: Record "EQM Equipment Assignment"; Equipment: Record "EQM Equipment")`, **no IsHandled**.
  - Raised just before a new Active entry is inserted. Lets partners fill fields they added to table 50103 through a
    table extension. Skipping the insert is not allowed (it would break BR-A4/invariant).
  - Doc comment: "Raised before a new active assignment entry is inserted." EquipmentAssignment: "The new entry. You
    can set fields that your extension added; do not change the standard fields." Equipment: "The equipment being
    assigned (passed by value)."
- `OnBeforeCloseAssignment(var EquipmentAssignment: Record "EQM Equipment Assignment"; Equipment: Record "EQM Equipment")`, **no IsHandled**.
  - Raised for each Active entry just before it is modified to Closed (including leftover entries closed before a new
    assignment). Equipment.Status tells why it closes (Available, In Maintenance, Lost, Disposed, or Assigned when a
    leftover is repaired).
  - Doc comment: "Raised before an active assignment entry is closed." EquipmentAssignment: "The entry being closed,
    with Status, Closing Date and Closed By already set. You can set fields that your extension added." Equipment:
    "The equipment (passed by value); its status shows why the assignment closes."
- No event on deleting entries (D6 safety checks are not overridable).

Existing events in table 50100: signatures unchanged. `OnBeforeCheckStatusTransitionAllowed` now also lets partners
skip BR-A1 (doc comment updated, see Table 50100). It does not let partners skip the D3 rule (new records are checked
outside the transition check). `OnBeforeCheckEmployeeIsEligible`, `OnBeforeCheckSerialNoIsUnique`,
`OnBeforeCheckCategoryIsActive`, `OnAfterCheckEquipmentConsistency` unchanged.

## Permissions
- `EQM - Read` (50100): add `tabledata "EQM Equipment Assignment" = R`, `table "EQM Equipment Assignment" = X`,
  `page "EQM Equipment Assignments" = X`, `codeunit "EQM Assignment Mgt." = X`.
- `EQM - Edit` (50101): add `tabledata "EQM Equipment Assignment" = Rimd` (direct read, **indirect** insert, modify,
  delete). Users can create/close entries only through codeunit 50106 when they assign, unassign or change status, and
  can delete (Closed) entries only by deleting equipment; they cannot edit or delete entries directly.
- `EQM - Admin` (50102): no change (inherits Edit). Entries stay read-only for admins too (audit trail, D6).
- Permission set extension 50103 "EQM D365 BASIC": no change (the Employee delete guard reads only table 50100).
- Page extensions and enums need no permission entries.
- Help text (documenter): "Assigning needs Equipment - Edit. Everyone with Equipment - Read can see assignments."

## Compatibility
- AppSource mode, development phase: nothing released, no baseline. Additive objects: enum 50101, table 50103, page
  50104, codeunit 50106, page extension 50100, two new events. After the first release they become contracts
  (table fields, enum values, event signatures, page/permission set names).
- Behavior changes (would be breaking after a release; allowed now because nothing is released):
  - In Maintenance equipment can no longer be assigned directly (reverses FR-003 decision Q5; D2). Partners can allow
    it again through `OnBeforeCheckStatusTransitionAllowed`.
  - New equipment can no longer be created as Assigned (D3): the card's new-record Status control offers only
    Available and In Maintenance, and the table refuses it on validate and on insert (supersedes FR-001 scenario 25's
    premise and FR-003 S21/U1).
  - Assigned equipment can no longer be reassigned to another employee in one step: Assign to Employee is disabled for
    Assigned equipment, `AssignEmployee` raises AlreadyAssignedErr, and changing the employee on modify raises it too
    (D1). The card no longer lets the user edit the employee field.
  - Deleting Assigned equipment is now refused (was: confirm, then delete; FR-001 scenarios 33/34). Deleting other
    equipment deletes its Closed entries; a leftover Active entry blocks the delete (D6).
- Base app: only a page extension on "Employee Card" (adds one action). No base object changed; no event subscription.
- Internal, not API: `UpdateAssignmentOnSave`, `DeleteAssignments`, `CreateAssignment`, `CloseActiveAssignments`,
  `AssignEmployee`, `UnassignEmployee`, `CheckEquipmentConsistency`. No `internalsVisibleTo`.
- Doc references to update (documenter, not developer):
  - `docs/features/FR-001-equipment-registration.md` and `docs/help/FR-001-equipment-registration.md`: "Assign to
    Employee" no longer reassigns; employee field read-only on the card; new equipment cannot be Assigned; deleting
    Assigned equipment is refused (no confirm).
  - `docs/features/FR-003-equipment-status-management.md` and `docs/help/FR-003-equipment-status-management.md`:
    In Maintenance equipment can no longer be assigned directly (Q5 superseded); new-record status values; event doc of
    `OnBeforeCheckStatusTransitionAllowed`.
  - New `docs/features/FR-004-equipment-assignment.md`, `docs/help/FR-004-equipment-assignment.md`, CHANGELOG section
    `## FR-004 Equipment Assignment` at the top (same pattern as FR-003), release notes paragraph.
  - Historical plans are not edited. Superseded specs are listed in R6.

## Test scenarios
**No automated tests in this iteration (D8). No test codeunits, no `test/app.json` change; IDs 50156/50157 stay
reserved and unused. The tester step is skipped.** The list below is a reference for the user, who writes the tests
later. The developer and reviewer use it to check behavior by reading the code.

Conventions for whoever implements them later: "assign" means calling `AssignEmployee` (or the card action) on saved
equipment with an Active, not privacy-blocked employee unless stated otherwise. Confirms are answered by a
`[ConfirmHandler]` that records the question; a test that expects no confirm has no handler. After an expected error,
re-read equipment and entries and assert both are unchanged. "Active entry" means an EQM Equipment Assignment with
Status Active for that equipment. Assert user IDs against `UserId()` and dates against `WorkDate()`.

Assigning (BR-A1, BR-A2, entry data)
- A1 Given saved Available equipment E and employee P, when E is assigned to P, then E.Status = Assigned, E."Assigned Employee No." = P, and exactly one entry exists for E with Status Active, Employee No. P, Assignment Date = WorkDate, Assigned By = current user, Closing Date blank, Closed By blank.
- A2 Given WorkDate set to a date D different from Today, when saved Available equipment is assigned, then the entry's Assignment Date = D.
- A3 Given saved Available equipment, when Status is validated to Assigned, an active employee is validated and Modify(true) is called (no AssignEmployee), then an Active entry is created for that employee.
- A4 Given a new, not inserted equipment record, when Status is validated to Assigned, then NewEquipmentAssignedErr (Assigned) is raised.
- A4b Given a new record with Status := Assigned and an active employee set by direct assignment, when Insert(true) is called, then NewEquipmentAssignedErr is raised, no equipment record exists and no entry exists.
- A4c Given a new record (Status Available), when Insert(true) is called, then the equipment is saved and no entry exists.
- A5 Given In Maintenance equipment, when it is assigned, then NotAvailableForAssignmentErr (equipment no., In Maintenance, Available) is raised, Status stays In Maintenance and no entry exists.
- A6 Given In Maintenance equipment, when Status := Assigned and an employee are set by direct assignment and Modify(true) is called, then NotAvailableForAssignmentErr is raised and no entry exists.
- A7 Given Lost (and, separately, Disposed) equipment, when it is assigned, then CannotAssignFinalStatusErr is raised and no entry exists (FR-003 rule unchanged).
- A8 Given saved Available equipment, when it is assigned to an Inactive (separately: privacy-blocked, non-existing) employee, then the FR-001 employee error is raised and no entry exists.

One active assignment (BR-A4)
- A9 Given equipment assigned to P1, when `AssignEmployee(P2)` is called, then AlreadyAssignedErr (equipment no., P1) is raised; the equipment still has P1 and there is still exactly one Active entry (P1).
- A10 Given equipment assigned to P1, when "Assigned Employee No." := P2 by direct assignment and Modify(true) is called, then AlreadyAssignedErr (equipment no., P1) is raised.
- A11 Given equipment assigned to P1, when `AssignEmployee(P1)` is called again, then AlreadyAssignedErr is raised and no second entry exists.
- A12 Given equipment assigned to P1, when Description is changed and Modify(true) is called, then no entry is created or closed.
- A13 Given saved Available equipment E and a leftover Active entry for E (inserted directly by the test), when E is assigned to P, then the leftover entry is Closed (Closing Date = WorkDate, Closed By = current user) and exactly one Active entry exists, for P.

Closing (automatic, D5)
- A14 Given equipment assigned to P, when `UnassignEmployee` is called (confirm Yes), then Status = Available, the employee is blank, the entry is Closed with Closing Date = WorkDate and Closed By = current user, and no Active entry exists.
- A15 Same as A14 with confirm No: equipment still Assigned to P, the entry still Active.
- A16 Given equipment assigned to P, when Status is validated to In Maintenance (confirm Yes) and Modify(true) is called, then the entry is Closed.
- A17 Given equipment assigned to P, when Status is validated to Lost (separately: Disposed) with confirm Yes and Modify(true) is called, then the entry is Closed.
- A18 Given equipment that is Assigned but has no entry (created with trigger-less writes, simulating pre-FR-004 data), when it is unassigned, then no error is raised and no entry exists.
- A19 Given equipment assigned to P, unassigned, then assigned to P2, then the equipment has two entries: P Closed and P2 Active, newest Entry No. for P2.

Multiple assignments per employee (BR-A3)
- A20 Given saved Available equipment E1 and E2 and employee P, when both are assigned to P, then two Active entries exist for P (one per equipment) and both equipment show P.
- A21 Given P has an Active entry for E1 and a Closed entry for E2, when entries are filtered on Employee No. = P and Status = Active, then only E1 is found.

Delete (D6) and rename
- A22 Given Available equipment with two Closed entries, when Delete(true) is called, then the equipment and both entries are deleted, and no confirm is shown.
- A23 Given equipment assigned to P (one Active entry), when Delete(true) is called, then DeleteAssignedErr (equipment no., P) is raised, no confirm is shown, and the equipment and its entry still exist.
- A23b Given Available equipment with a leftover Active entry (inserted directly by the test) and one Closed entry, when Delete(true) is called, then ActiveAssignmentExistsErr (equipment no.) is raised and the equipment and both entries still exist.
- A23c Given Available equipment without entries, when Delete(true) is called, then it is deleted.
- A24 Given equipment with entries, when the equipment is renamed (Rename), then its entries carry the new equipment number.
- A25 Given employee P with only Closed entries and no equipment referencing P, when P.Delete(true) is called, then P is deleted (entries remain with Employee No. P).
- A26 Given equipment currently assigned to P, when P.Delete(true) is called, then the FR-001 EmployeeHasAssignedEquipmentErr is raised (guard unchanged).

Card and pages (UI, TestPage)
- A27 Given saved Available equipment, when the card is opened, then Assign to Employee is enabled and the Assigned Employee No. field is not editable.
- A28 Given Assigned equipment, when the card is opened, then Assign to Employee is disabled, Unassign is enabled and the Assigned Employee No. field is not editable.
- A29 Given In Maintenance (separately Lost, Disposed) equipment, when the card is opened, then Assign to Employee is disabled.
- A30 Given a new card (OpenNew), then the Status control offers only Available and In Maintenance (setting Assigned via the visible control fails), the Assigned Employee No. field is not editable, and Assign to Employee is disabled.
- A31 Given equipment with entries, when the Assignments action on the card is invoked, then page EQM Equipment Assignments opens filtered on that equipment and shows only its entries, newest first; the page does not allow insert, modify or delete.
- A32 Given employee P with entries for two equipment, when the Equipment Assignments action on the Employee Card is invoked, then the list shows only P's entries.
- A33 Given an Active and a Closed entry, when the assignments page is opened, then Employee Name shows the employee's full name and the views Active and Closed filter correctly.

Events and permissions
- A34 Given a subscriber to `OnBeforeCheckStatusTransitionAllowed` that sets IsHandled when FromStatus = In Maintenance and ToStatus = Assigned, when In Maintenance equipment is assigned, then it is saved as Assigned and an Active entry exists.
- A35 Given the same subscriber setting IsHandled for every transition, when Lost equipment is assigned, then CannotAssignFinalStatusErr is still raised; when Assigned equipment is assigned to another employee, AlreadyAssignedErr is still raised; when a new record is validated to Assigned, NewEquipmentAssignedErr is still raised.
- A36 Given a subscriber to `OnBeforeInsertAssignment` that records the call, when equipment is assigned, then it was raised once with Status Active, the correct equipment and employee; given a subscriber to `OnBeforeCloseAssignment`, when the equipment is unassigned, then it was raised once with Status Closed already set.
- A37 Permissions (`TestPermissions = Restrictive`): a user with EQM - Edit (plus D365 BASIC) can assign, unassign and delete Available equipment with Closed entries (entries are created, closed and deleted) but gets a permission error when inserting, modifying or deleting an EQM Equipment Assignment record directly; a user with EQM - Read can read entries and open page 50104, and gets a permission error when assigning.

Manual checks (sandbox): Employee Card shows the Equipment Assignments action; search finds "Equipment Assignments";
the new-card Status dropdown has no Assigned; `.g.xlf` regenerated with the new captions and tooltips and without
`DeleteAssignedQst`.

## Risks and open questions
Resolved decisions (approved by the user):
- **D1 Reassignment:** refused. Equipment that is Assigned cannot be assigned to another employee in one step; unassign
  first (AlreadyAssignedErr in `AssignEmployee` and on modify).
- **D2 In Maintenance -> Assigned:** refused (BR-A1), reversing FR-003 Q5. Partners can relax it through
  `OnBeforeCheckStatusTransitionAllowed`.
- **D3 New equipment as Assigned:** forbidden. The card's `StatusNew` control offers only Available and In Maintenance;
  the table refuses Assigned on unsaved records in Status OnValidate and in the insert check of
  `CheckEquipmentConsistency` (hard, no event). No entry is ever created on insert.
- **D4 Assignment Date:** filled automatically with WorkDate(), not editable; Assigned By = current user ID.
- **D5 Active assignment model:** entry Status Active/Closed, closed automatically (with Closing Date and Closed By)
  whenever equipment leaves Assigned (Unassign, In Maintenance, Lost, Disposed). No return process in this feature.
- **D6 Deleting assignment entries "with safety checks"**, interpreted conservatively (recorded here as the agreed
  interpretation):
  - Entries are deleted **only** as part of deleting their equipment with Delete(true).
  - Deleting equipment is **refused** while its Status is Assigned (DeleteAssignedErr; replaces the FR-001 confirm) and
    while it still has any Active entry (ActiveAssignmentExistsErr, for leftovers after trigger-less writes).
  - When the delete is allowed, all **Closed** entries of that equipment are deleted with it.
  - Users cannot delete entries any other way: the assignments page has `DeleteAllowed = false`, and no EQM permission
    set (including Admin) grants direct delete on the table (EQM - Edit has indirect `d` only, used by codeunit 50106).
  - No partner event to skip these checks.
- **D7 Employee Card action:** included (page extension 50100 on "Employee Card").
- **D8 Tests:** skipped for now. No test objects; IDs 50156/50157 stay reserved and unused; tester step skipped.
- **D9 Version:** stays 29.0.0.0 (no bump). Note for later: CHANGELOG lists FR-002 as 29.1.0.0 while `app/app.json`
  says 29.0.0.0; the version line should be settled before the first release.
- **D10 No backfill:** equipment that was Assigned before FR-004 gets no entry (development data only).

Still open: none.

Risks:
- R1 BR-A1 is relaxable by partners (same IsHandled as the final-status rule). A subscriber that sets IsHandled broadly
  to undo Lost/Disposed also allows In Maintenance -> Assigned. Documented in the event doc comment.
- R2 Trigger-less writes (Insert/Modify/Delete(false), ModifyAll, DeleteAll, RapidStart without validation) bypass the
  entries and all checks, like every FR-001..FR-003 rule. A13 shows the repair on the next assignment; a leftover Active
  entry blocks equipment delete until it is repaired (assign + unassign). Document in help.
- R3 Pre-FR-004 Assigned equipment has no Active entry until it is unassigned and assigned again (D10).
- R4 OnModify of every equipment save now does one extra primary-key read (SetLoadFields(Status)) in codeunit 50106.
  Negligible.
- R5 Closed entries keep the employee number after the employee is deleted (no TableRelation enforcement on delete).
  Acceptable for history; mention in help and privacy notes. Entries also store user names (EndUserIdentifiableInformation).
- R6 Superseded earlier specs: FR-003 S27 and Q5 (assign In Maintenance directly), FR-003 S21 and U1 (new equipment as
  Assigned), FR-001 scenarios 33/34 (delete Assigned equipment with confirm), FR-001 "Assign to Employee also
  reassigns" and scenarios 48/50 (employee field editable on Assigned). The user's later tests must follow this plan.
- R7 Unverified until the developer checks symbols: table User namespace (`System.Security.AccessControl`), page
  "Employee Card" (5200) and `addlast(Navigation)` on it, Image names. If any differs, stop and report; do not guess.
- R8 AutoIncrement entry numbers can have gaps (rolled-back transactions). Entry No. is only an identifier; accepted.
- R9 No automated tests (D8): regressions in FR-001/FR-003 assignment behavior are caught only by review and manual
  sandbox checks.
