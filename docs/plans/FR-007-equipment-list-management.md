# FR-007 Equipment List Management

> Status: APPROVED by the user, implemented (developer step done, awaiting review). Decisions: Q1 build the delta; Q2
> employee number filtering is enough; Q3 both navigation actions, no action on the Employee List page; Q4 do not add
> Serial No. to the DropDown field group; Q5 tests skipped for now (test codeunit not written). All five match the
> defaults used throughout this plan, so no revision was needed.
> Source: GitHub issue #13. Branch: `feature/FR-007-equipment-list-management`.
> No events report: FR-007 changes only this app's own pages (50100, 50102) and its own page extension of the
> Employee Card (50100, which adds actions only). It subscribes to no events and changes no standard behavior, so
> al-event-finder is not needed.
> Scope: main app only. **No new objects, no schema change, no version bump** (app.json stays 29.0.0.0, as in FR-004 D9,
> FR-005 and FR-006). **No upgrade logic.** **No automated tests** by default (Q5, same as FR-003 to FR-006; scenarios
> are a reference only).
> Workflow for FR-007: planner -> (human approves plan) -> developer -> reviewer -> **tester step SKIPPED (Q5)** ->
> documenter -> appsource-validator.

## Goal
Users can open one list of all equipment and narrow it down by category, status and assigned employee, and find
equipment by its number or serial number. FR-001 already built that list (page 50100). It covers every requirement
through the standard BC search box and filter pane. FR-007 adds a few small things so the features are easier to find
and use: a teaching tip that explains search and filters, the assigned employee's name, and one-click navigation to a
filtered list from a category and from an employee.

### Requirement restated
- L-R1 View all equipment in one list.
- L-R2 Filter by category.
- L-R3 Filter by status.
- L-R4 Filter by assigned employee.
- L-R5 Search by equipment number.
- L-R6 Search by serial number.

### What FR-001 to FR-006 already deliver (reused, not duplicated)
Page 50100 "EQM Equipment List" (List, `Editable = false`, `UsageCategory = Lists`, searchable as "Equipment",
`CardPageId` = card 50101; the LookupPageId/DrillDownPageId of table 50100).

| Requirement | Already covered by | Gap closed by FR-007 |
|---|---|---|
| L-R1 | The page has no `SourceTableView` and no filters on open, so it shows all equipment in every status. | None. |
| L-R2 | "Category Code" column; the filter pane can filter on any table field (lookup to categories); key `CategoryCode` exists. | **Navigation:** new action "Equipment" on page 50102 "EQM Equipment Categories" opens the list filtered on the selected category. |
| L-R3 | Status column (styled); views Available, Assigned, In Maintenance, Lost, Disposed (FR-003); filter pane on Status. | None. |
| L-R4 | "Assigned Employee No." column; filter pane with Employee lookup; key `AssignedEmployee` ("Assigned Employee No.", Status). | **Display:** new column "Assigned Employee Name" so users can recognize the employee. **Navigation:** new action "Assigned Equipment" on the Employee Card (page extension 50100) opens the list filtered on that employee. |
| L-R5 | "No." column; the list search box searches all visible columns; key PK. | None. |
| L-R6 | "Serial No." column (visible by default); same search box; key `SerialNo`. | None. |
| Discoverability | Nothing tells the user how to search and filter. | **Teaching tip** (`AboutTitle`/`AboutText`) on page 50100. |

## Approach and rejected alternatives
- Chosen: change only the UI of this app's own pages. On page 50100, add a teaching tip and an "Assigned Employee Name"
  column calculated in `OnAfterGetRecord`, using the same pattern as card 50101 and page 50104. On page 50102, add a
  Navigation action "Equipment" with `RunPageLink` on "Category Code". On page extension 50100 (Employee Card), add a
  Navigation action "Assigned Equipment" with `RunPageLink` on "Assigned Employee No.".
  Search and filtering stay with the platform's search box, filter pane and the existing views. No code reimplements them.
- Rejected: a new list page or a "filter header" page with filter fields (category, status, employee, search text) and
  code that applies them. This duplicates the platform filter pane and search box, adds code that needs tests, and
  does not work the same way in lookups and in Excel or analysis mode.
- Rejected: a FlowField "Assigned Employee Name" on table 50100. Employee has no stored full-name field (`FullName()` is
  a procedure), so a FlowField could only show one name part. It would also be a schema change. A page variable cannot
  be filtered or searched, but the employee can still be filtered by number (Q2).
- Rejected: one view per category. Categories are master data the user creates, and views are compile-time constants.
- Rejected: new keys (for example on Status alone). Equipment volumes are small, and the existing keys already cover
  category, employee+status and serial number. Changing a key is a schema change that costs more than it gains.
- Rejected: adding "Serial No." to the DropDown field group of table 50100, so that typing in an equipment lookup also
  matches serial numbers. The issue asks for search on the list page, and the list search already covers it (Q4).
- Rejected: making page 50100 editable or adding processing actions (assign/return) to it. Not asked for. Assignment
  rules live on the card and the Employee Card.
- Rejected: an "Equipment" action on the Employee List page (new page extension). The Employee Card is enough, and a
  new page extension would add an object (Q3).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50103, pages 50100-50104, codeunits 50103-50106,
enums 50100-50101, page extension 50100, permission sets 50100-50102, permission set extension 50103. Test app: no
objects (test codeunits 50150-50155 reserved by FR-001, 50156-50157 by FR-004, 50158 by FR-006, none built).

**No new objects.**

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Page | 50100 | EQM Equipment List | Modify (own) | Teaching tip (`AboutTitle`/`AboutText`); new column "Assigned Employee Name" (page variable, filled in `OnAfterGetRecord`) |
| Page | 50102 | EQM Equipment Categories | Modify (own) | New Navigation action "Equipment" (list filtered on the category) and its promoted actionref |
| PageExtension | 50100 | EQM Employee Card | Modify (own) | New Navigation action "EQMAssignedEquipment" (list filtered on the employee) |

Not changed: tables 50100-50103, pages 50101, 50103, 50104, codeunits 50103-50106, enums, all permission sets and the
permission set extension, `app/app.json`, `test/`.
Next free IDs (unchanged by FR-007): tables 50104, pages 50105, codeunits 50107, enums 50102, page extensions 50101,
permission sets 50104. Test app: next free test codeunit 50159, **reserved for FR-007 "EQM Equipment List Tests", not
built now (Q5).**

### Page 50100 "EQM Equipment List" (changes)

**Page-level properties** (add next to `Caption`, `PageType` and the others. Do not change the existing properties):
- `AboutTitle` = 'About equipment'
- `AboutText` = 'This list shows all your equipment. Use **Search** to find equipment by its number, serial number, or
  any other column you can see. To filter by category, status, or assigned employee, open the filter pane and add a
  filter on that field. You can also choose a status view at the top of the list.'
  (One string, one line in the source. The bold markup around Search is supported by teaching tips. The string is
  translated through the XLF like captions. Do not split it into labels.)

**Repeater: new column** directly after `field("Assigned Employee No."; ...)` and before `field("Location Code"; ...)`:
- Control name `"Assigned Employee Name"`, source expression page variable `AssignedEmployeeName`.
- `Caption = 'Assigned Employee Name'`.
- `ToolTip = 'Specifies the name of the employee the equipment is assigned to.'` (identical to card 50101, so the XLF
  has one consistent text. The ToolTip is required here because a page variable has no table field to inherit it from).
- Visible by default. No `Editable` property is needed because the page is `Editable = false`.

**Existing columns:** unchanged, including order and visibility. "No.", "Category Code", "Serial No.", Status and
"Assigned Employee No." must stay visible by default, because the search box searches visible columns only (see R1).
Do not add `Visible = false` to any of them.

**`var` section:** add `AssignedEmployeeName: Text[100];` next to `StatusStyle`.

**Trigger `OnAfterGetRecord`** becomes:
1. Unchanged: `StatusStyle := Rec.GetStatusStyle();`
2. New: set `AssignedEmployeeName` to blank first, so the previous row's name is never reused.
3. New: if `Rec."Assigned Employee No."` is not blank, then on a local `Employee` record (`Record Employee`) call
   `SetLoadFields("First Name", "Middle Name", "Last Name")`. If `Get(Rec."Assigned Employee No.")` succeeds, set
   `AssignedEmployeeName := Employee.FullName()`. If the employee is missing, leave the name blank. Raise no error,
   because this is a display-only list.
- Add `using Microsoft.HumanResources.Employee;` at the top of the file (namespace already declared).
- Name the local variable `Employee`. There is no conflict on this page, since page 50104 uses `EmployeeRec` only
  because it has an action named Employee. Page 50100 has no control or action named Employee.

**Actions, views:** unchanged (Categories, Setup, Assignments and their promoted refs; the five status views).
Section order stays `layout`, `actions`, `views`, then `var` and triggers (AL0926).

### Page 50102 "EQM Equipment Categories" (changes)
Add an `actions` section after `layout` (the page has none today):
- `area(Navigation)`: action `Equipment`
  - `Caption = 'Equipment'`
  - `ToolTip = 'View the equipment in the selected category.'`
  - `Image = FixedAssets` (same image as the Equipment action on page 50104)
  - `RunObject = page "EQM Equipment List"`
  - `RunPageLink = "Category Code" = field("Code")`
- `area(Promoted)`: `actionref(Equipment_Promoted; Equipment)`.
- No trigger code. `ApplicationArea` is inherited from the page level (`All`).
- Effect: the list opens with a fixed filter on the category, and the status views still work inside it. A category with
  no equipment opens an empty list, which is not an error.

### Page extension 50100 "EQM Employee Card" (changes)
In the existing `addlast(Navigation)` block, add a second action **after** `EQMEquipmentAssignments`:
- Action name `EQMAssignedEquipment` (affix prefix, like the existing actions in this extension)
- `ApplicationArea = All` (required here: page extensions do not inherit it from our page, so keep the existing pattern
  of this file)
- `Caption = 'Assigned Equipment'`
- `ToolTip = 'View the equipment that is currently assigned to the employee.'`
- `Image = FixedAssets`
- `RunObject = page "EQM Equipment List"`
- `RunPageLink = "Assigned Employee No." = field("No.")`
- No trigger code and no promoted actionref (the existing actions in this extension are not promoted either).
- Effect: only equipment with Status Assigned has an employee (table rules from FR-003/FR-004), so the list shows the
  employee's current equipment. Past equipment is in "Equipment Assignments" (history, page 50104).
- `ReturnAssignedEquipment` and the Return Equipment action: unchanged.

### app.json, translations
- No app.json change. The build regenerates `app/Translations/Equipment Management.g.xlf` with the new AboutTitle,
  AboutText, captions and tooltips. Commit the regenerated file and never edit it by hand. Note that the working tree
  already shows an uncommitted change to this file from before FR-007. The developer should check with the user whether
  it belongs to this branch before committing.

## Data model and upgrade impact
- No schema change: no new tables, fields, keys, enums or field groups. Page and page extension changes only.
- DataClassification: nothing new. The employee name is displayed, not stored.
- Upgrade codeunit: not needed (nothing released, no data change).
- Performance: one `Employee.Get` with `SetLoadFields` per displayed row that has an assigned employee. This is
  acceptable for equipment volumes, and FR-004 page 50104 uses the same pattern (R2).

## Events
**Standard BC events: none.** No events report required.

Subscribed: none.

Published: **no new events, no signature changes.** The new UI has no business logic, so it needs no IsHandled.
Partners can extend page 50100, page 50102 and the Employee Card with their own page extensions.

## Permissions
- No permission set changes.
- EQM - Read (50100) already grants `page "EQM Equipment List" = X`, `page "EQM Equipment Categories" = X`,
  `tabledata "EQM Equipment" = R` and `tabledata "EQM Equipment Category" = Ri`. All new actions open page 50100, which
  only reads.
- Reading Employee for the name column: users of the list need read access to Employee. D365 BASIC (which every user
  has with EQM - Read in practice) grants it, the same as for card 50101 and page 50104. No EQM set grants Employee.
  This is the existing FR-001/FR-004 assumption and is not changed here (R3).
- A user who sees the Employee Card but has no EQM permission set gets a permission error when choosing "Assigned
  Equipment". This is the same as the existing "Equipment Assignments" action, and acceptable.
- Help text (documenter): "Everyone with Equipment - Read can open the equipment list, search it and filter it."

## Compatibility
- AppSource mode, development phase: nothing has been released, so there is no baseline and no Obsolete handling.
- No public API changes: no procedures, events, fields or keys change. New page controls and actions are additive, so
  existing partner page extensions anchored on existing controls or actions keep compiling. New control/action names
  (`"Assigned Employee Name"` on page 50100, `Equipment` on page 50102, `EQMAssignedEquipment` on page extension 50100)
  could clash only with a partner extension that adds a control of the same name. That risk is low and accepted.
- Page 50100 is also the lookup page for table 50100 and the selection page for Return Equipment on the Employee Card.
  The new column and teaching tip show there too. No behavior changes: `LookupMode`, `SetTableView` and `GetRecord` work
  as before.
- Doc references to update (documenter, not developer):
  - New `docs/features/FR-007-equipment-list-management.md` and `docs/help/FR-007-equipment-list-management.md`. They
    explain how to find the list (search "Equipment"), search by number or serial number (search box, visible columns
    only), filter by category / status / assigned employee (filter pane; status views), see the assigned employee name,
    open equipment of a category (Equipment Categories > Equipment), and open an employee's current equipment
    (Employee Card > Assigned Equipment). They also note that the name column cannot be used to filter: filter on
    Assigned Employee No. instead.
  - `docs/help/FR-001-equipment-registration.md` (list section) and `docs/help/FR-002-equipment-categories.md` (new
    Equipment action): short cross-references to FR-007.
  - CHANGELOG: add a section `## FR-007 Equipment List Management (version stays 29.0.0.0, no bump)` at the top, plus a
    release-notes paragraph.
  - `docs/TODO.md`: add the manual sandbox checks listed under Test scenarios.
  - Historical plans are not edited.

## Test scenarios
**No automated tests in this iteration by default (Q5). No test codeunits, no `test/app.json` change. ID 50159 is
reserved and stays unused, and the tester step is skipped.** The list is a reference for the user, who writes the
tests later. The developer and reviewer use it to check behavior by reading the code. When the tests are built, they
go into test codeunit 50159 "EQM Equipment List Tests" and use `TestPage "EQM Equipment List"`.

Note for test authors: the list search box cannot be driven from a TestPage. Search scenarios are covered with
`TestPage.Filter.SetFilter` on the field (the same filtering the search applies to that column) plus a manual sandbox
check of the search box.

Test data, unless stated: categories C1 and C2 (active). Equipment E1 (C1, serial S-100, Available), E2 (C1, serial
S-200, assigned to active employee P1 through `AssignEmployee`), E3 (C2, serial S-300, In Maintenance), E4 (C2, serial
blank, Disposed, set through validate with a `[ConfirmHandler]` answering Yes). Employee P2 is active with no equipment.

View all (L-R1)
- L1 Given E1-E4, when page EQM Equipment List is opened with no filter, then all four records are shown, including the
  Disposed E4.
- L2 Given no equipment in the company, when the list is opened, then it opens empty without error.

Filter by category (L-R2)
- L3 Given E1-E4, when the list is filtered on Category Code = C1, then exactly E1 and E2 are shown.
- L4 Given category C3 with no equipment, when the list is filtered on Category Code = C3, then no record is shown.
- L5 Given E1-E4, when page EQM Equipment Categories is opened, C1 is selected and the action Equipment is invoked
  (TestPage `Trap` on the list), then the list shows only E1 and E2, and its Category Code filter is C1.
- L6 Given category C3 with no equipment, when the Equipment action is invoked on C3, then the list opens empty without
  error.

Filter by status (L-R3)
- L7 Given E1-E4, when the list is filtered on Status = Assigned, then only E2 is shown. Repeat for Available (E1), In
  Maintenance (E3) and Disposed (E4).
- L8 Given E1-E4, when the list is filtered on Status = Lost, then no record is shown.
- L9 Given E1-E4, when the list is filtered on Category Code = C1 and Status = Available together, then only E1 is shown.

Filter by assigned employee (L-R4)
- L10 Given E1-E4, when the list is filtered on Assigned Employee No. = P1, then only E2 is shown, and its Assigned
  Employee Name equals P1's `FullName()`.
- L11 Given E1-E4, when the list is filtered on Assigned Employee No. = P2, then no record is shown.
- L12 Given E1-E4, when the Employee Card of P1 is opened and the action Assigned Equipment is invoked (TestPage `Trap`
  on the list), then the list shows only E2.
- L13 Given E2 returned (`UnassignEmployee`, confirm Yes), when Assigned Equipment is invoked on P1's Employee Card, then
  the list is empty. E2 shows Status Available and a blank Assigned Employee No. when the list is opened without filter.
- L14 Given E1-E4, when the list is filtered on Assigned Employee No. = '' (blank), then E1, E3 and E4 are shown.

Assigned Employee Name column
- L15 Given E1-E4, when the list is opened, then the Assigned Employee Name is P1's full name on E2 and blank on E1, E3
  and E4.
- L16 Given E2 assigned to P1 followed by E1 (no employee) when sorted by No., when the list is opened and moved from
  E2 to E1, then E1's name is blank (the previous row's name is not reused).
- L17 Given equipment whose Assigned Employee No. points to an employee that no longer exists (created with trigger-less
  writes in the test), when the list is opened, then the name is blank and no error is raised.

Search by equipment number and serial number (L-R5, L-R6)
- L18 Given E1-E4, when the list is filtered on No. = E3's number, then only E3 is shown.
- L19 Given E1-E4, when the list is filtered on Serial No. = S-200, then only E2 is shown.
- L20 Given E1-E4, when the list is filtered on Serial No. = `*-1*` (wildcard, as the search box matches parts of a
  value), then only E1 is shown.
- L21 Given E1-E4, when the list is filtered on Serial No. = S-999, then no record is shown.
- L22 Given E1-E4, when `FindFirstField("Serial No.", 'S-300')` is called on the list TestPage, then it returns true and
  the current row is E3.

Regression
- L23 Given E1-E4, when the view Available (separately: Assigned, In Maintenance, Lost, Disposed) is selected, then the
  list shows the same records as the matching Status filter in L7 and L8.
- L24 Given employee P1 with E2 assigned, when Return Equipment is invoked on P1's Employee Card and the lookup
  (`[ModalPageHandler]` on EQM Equipment List) selects E2 with confirm Yes, then E2 is returned as in FR-005. The new
  column does not break the lookup.
- L25 (`TestPermissions = Restrictive`) Given a user with EQM - Read and D365 BASIC, when the list is opened, filtered on
  each of Category Code, Status and Assigned Employee No., and the Equipment action on the categories page is invoked,
  then no permission error is raised and the name column is filled in.

Manual sandbox checks (for the user):
- Type part of an equipment number and part of a serial number into the list search box; the matching rows are shown.
- The teaching tip appears the first time the list opens.
- The filter pane offers Category Code, Status and Assigned Employee No. with lookups.
- Equipment Categories > Equipment and Employee Card > Assigned Equipment open the filtered list.
- The Return Equipment lookup from the Employee Card still works and shows the name column.
- After the build, `Equipment Management.g.xlf` contains the AboutTitle, AboutText, new captions and tooltips.

## Risks and open questions
Questions Q1-Q5 were ANSWERED by the user: all confirmed the default in bold (Q1 build the delta, Q2 yes, Q3 both
actions and none on Employee List, Q4 no, Q5 defer/skip tests). Original wording kept below for reference.
- **Q1 Scope:** the existing FR-001 list already meets L-R1 to L-R6 through the standard search box and filter pane.
  Is the delta in this plan (teaching tip, name column, two navigation actions) the right scope? Or should FR-007 be
  closed as "already delivered, documentation only"? **Default: build the delta.**
- **Q2 Filtering by employee name:** the name column is display-only and cannot be filtered or searched. Users filter by
  employee number, and the filter pane lookup shows employee names. Is that enough? **Default: yes.** Filtering by name
  would need a stored, maintained name field on table 50100 (schema change, plus sync when an employee is renamed),
  and is not planned.
- **Q3 Navigation actions:** add "Equipment" on Equipment Categories and "Assigned Equipment" on the Employee Card?
  **Default: both, and no action on the Employee List page.**
- **Q4 Serial number in lookups:** add "Serial No." to the DropDown field group of table 50100, so that typing in an
  equipment lookup field (for example on the assignments filter) also matches serial numbers? **Default: no**, because
  this is outside the list page asked for in the issue.
- **Q5 Tests:** build test codeunit 50159 now, or defer like FR-003 to FR-006? **Default: defer.** The test app is still
  not set up (see `docs/TODO.md`), and the scenarios L1-L25 are kept as the reference.

Risks:
- R1 The list search box searches visible columns only. If a user hides "Serial No." or "No." through personalization,
  search by that value stops working for that user. This is platform behavior, mitigated by keeping both columns
  visible by default. The help article should mention it.
- R2 The name column reads Employee once per displayed row with an assigned employee. The cost is negligible at
  equipment volumes. If volumes ever grow large, move to a stored name field (see Q2).
- R3 The name column needs read access to Employee, which comes from D365 BASIC and not from an EQM set. A user with
  only EQM - Read would get a permission error when the list loads a row with an assigned employee. This is the
  existing assumption on card 50101 and page 50104, and it is not changed here. If wanted, add
  `tabledata Employee = R` to EQM - Read in a separate fix.
- R4 Filtering on Assigned Employee No. shows only current assignments, because the field is cleared on return. To see
  who had the equipment in the past, use Equipment Assignments (FR-006). The help article should make this clear.
- R5 No automated tests (Q5): regressions in the list and lookup are caught only by review and the manual sandbox
  checks.
