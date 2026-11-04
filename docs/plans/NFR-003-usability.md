# NFR-003 Usability

> Status: **APPROVED by the user with the defaults for Q1-Q12.** The plan is written with the defaults for Q1-Q12, and each question
> says what changes if the user picks the other answer.
> Source: GitHub issue #24. Branch: `feature/NFR-003-usability`.
> No events report: NFR-003 changes only this app's own pages and its own page extension on the Employee Card. It adds
> FactBoxes and reorganizes actions. It subscribes to no events, publishes none, and changes no standard behavior.
> al-event-finder is not needed. (Document attachments would need it; they are out of scope, Q9.)
> Scope: main app only. **Two new pages (FactBoxes), nine own pages and the Employee Card page extension changed, three
> internal procedures added to codeunit 50106, two X entries added to EQM - Reader. No table, field or key change. No
> version bump** (app.json stays 29.0.0.0). **No upgrade logic.** **No automated tests by default** (Q1: deferred, as in
> FR-003 to NFR-002; the scenarios are a reference, and test codeunit 50163 is reserved).
> Workflow for NFR-003: developer -> reviewer -> build -> **tester step SKIPPED (Q1)** -> documenter ->
> appsource-validator.

## Goal
Every page of the app follows the standard Business Central page pattern for its type, with consistent captions,
ToolTips and Tell Me search entries. Actions are grouped by purpose (process, navigate, report, setup) in the action
bar the same way the base app groups them. The equipment list and card, and the Employee Card, get FactBoxes that show
the assignment context (who has the equipment, since when, how often it was assigned), plus the standard Links and
Notes parts.

### Requirement restated
- U-R1 All pages follow standard BC design patterns (page type, layout, properties, Tell Me).
- U-R2 Actions are discoverable and grouped logically.
- U-R3 FactBoxes provide relevant contextual information.

### Interpretation (defaults, see Q2-Q12)
- No new business functionality. Nothing a user can do changes, except: open information from the new FactBoxes
  (drill-downs to existing pages), add notes and links to equipment (standard system parts), and use Ctrl+F7.
- NFR-002 behavior stays: pages are read-only for Readers where they are today; nothing assumes Employee read (names
  and employee details are blank without it, never an error); custom actions are not hidden per role.
- Nothing is released (confirmed by the user on 2026-11-04 for NFR-002), so moving or removing actions on own pages
  needs no Obsolete cycle.

## Approach and rejected alternatives
- Chosen:
  - **Audit every page** against the BC pattern for its type (table below) and fix only real deviations. Pages that
    already follow the pattern are recorded as "no change" with the reason.
  - **One promotion convention for the whole app**, taken from the base app: promoted actions sit in named groups in
    `area(Promoted)`, never directly under it. `Category_Process` (caption 'Process') holds processing actions,
    `Category_Report` (caption 'Report') holds report/analysis actions, and `Category_Category4` holds record
    navigation (caption = the entity name on entity pages: 'Equipment'; caption 'Navigate' on other pages). Setup
    navigation is grouped under Related > Setup and is not promoted. Legacy `Promoted`/`PromotedCategory` properties
    are not used (runtime 18 uses `actionref`).
  - **One ToolTip style:** field ToolTips start with "Specifies" (already true everywhere); action ToolTips use the
    imperative ("Open ...", "View ...", "Assign ..."), as in the Microsoft ToolTip guidelines. Today most action
    ToolTips are third person ("Opens ...", "Assigns ...").
  - **New CardPart page 50111 "EQM Equipment FactBox"** (caption 'Assignment Details') on the Equipment List and the
    Equipment Card: status, current employee (number with drill-down to the Employee Card, name, job title, company
    e-mail), assigned since/by, number of assignments (drill-down to the history) and the date the last assignment was
    closed. All employee data is guarded with `ReadPermission()` (NFR-002 pattern).
  - **New ListPart page 50112 "EQM Assigned Equipment FactBox"** (caption 'Assigned Equipment') on the Employee Card,
    listing the equipment currently assigned to the employee, with drill-down to the Equipment Card. The part is shown
    only to users who can read equipment.
  - **Standard system parts Links and Notes** on the Equipment List and Card (Links hidden by default, Notes visible,
    as on the base Customer and Item pages).
  - **Three internal read procedures** in codeunit 50106 "EQM Assignment Mgt." so the FactBox does not query table
    50103 itself (FR-008 pattern).
  - **Tell Me:** `UsageCategory = History` for Equipment Assignments (it is history, like ledger entries), and
    `AdditionalSearchTerms` on the four searchable main pages.
  - **Teaching tips** (`AboutTitle`/`AboutText`) on the two searchable list pages that lack one (Categories,
    Assignments).
- Rejected: base app "Employee Picture" or other Employee-sourced FactBoxes on equipment pages. Their source table is
  Employee, so they fail for users without Employee read (NFR-002 Q4), and they show only a picture.
- Rejected: showing the assignment history in the FactBox pane. FR-008 Q3 already decided the history is a body part
  (seven columns do not fit the narrow pane). The FactBox shows a count and a drill-down instead.
- Rejected: FlowFields on table 50100 for "No. of Assignments" / "Last Assignment Closed". Schema change on a public
  table for values only one FactBox needs; page variables filled through codeunit 50106 do the same.
- Rejected: Document Attachments FactBox ("Doc. Attachment List Factbox") on equipment. A custom table needs
  subscribers to base Document Attachment events to resolve the record. That is new functionality and needs
  al-event-finder (Q9, follow-up).
- Rejected: promoting the equipment actions on the standard Employee Card. It adds a promoted group to a page used by
  every HR user; the new FactBox and the Related > Equipment group are enough (Q4).
- Rejected: legacy `Promoted = true` / `PromotedCategory` / `PromotedActionCategories`. Replaced by `actionref` in
  runtime 10+; mixing both is flagged by the compiler.
- Rejected: leaving `actionref` directly under `area(Promoted)` (today's state). It works, but every page then shows its
  own unsorted top-level buttons; the base app always groups. Grouping gives the same order on every page.
- Rejected: a FactBox on Equipment Assignments (page 50104), Categories, Setup, the parts, the dashboard or the Role
  Center. See the audit table: rows already show equipment and employee, the setup pages have one to three fields, and
  parts/Role Centers have no FactBox pane (Q8).
- Rejected: profile customizations (page customizations in the profile) instead of code. They apply only to that
  profile, not to users on other roles.
- Rejected: a shared helper for the employee full name. It would touch four existing pages; the FactBox adds one more
  copy of the guarded four-line lookup. Noted as risk R5, as in FR-008 R4.

### Audit (on this branch)
Legend: OK = follows the pattern, no change. FIX = changed by this plan (details per page below).

| Page | Type today vs pattern | Search / caption / ToolTips | Fields / importance | Actions | FactBoxes | Verdict |
|---|---|---|---|---|---|---|
| 50100 EQM Equipment List | List, `Editable = false`, `CardPageId` = card: OK (base list pattern) | Lists, caption 'Equipment', teaching tip: OK. No `AdditionalSearchTerms` | Columns OK, Purchase fields hidden by default: OK | Four Navigation actions all promoted flat; Setup and Categories promoted on a list (base lists keep setup under Related); Dashboard is analysis but sits in Navigation; ToolTips third person | **None** (base lists have entity FactBox + Links + Notes) | FIX |
| 50101 EQM Equipment Card | Card, `DelayedInsert`, `UsageCategory = None`: OK | Teaching tip OK | Status Promoted; Description, Category Code and employee name not Promoted, so the collapsed FastTabs say little | Assign/Return/Assignments promoted flat; no keyboard shortcut for the history (base: Ctrl+F7 for entries); ToolTips third person | **None** | FIX |
| 50102 EQM Equipment Categories | List, Administration, editable list, read-only without write permission (NFR-002): OK | No teaching tip, no search terms | OK (3 fields) | One action promoted flat | None; OK for a three-field setup list | FIX (actions, tip, search) |
| 50103 EQM Equipment Setup | Card, Administration, Insert/Delete not allowed, singleton: OK (base setup pattern) | No search terms | 'Numbering' FastTab: OK (base name) | None: OK | None: OK | FIX (search terms only) |
| 50104 EQM Equipment Assignments | List, read-only, descending, views Active/Closed: OK | **`UsageCategory = Lists`, should be History**; no teaching tip; no search terms | OK | Two navigation actions promoted flat; ToolTips third person | None; OK (rows already show equipment and employee) | FIX |
| 50105 EQM Assignment History Part | ListPart, read-only, no UsageCategory: OK | OK | OK | None: OK (card has the Assignments action) | n/a | OK, no change |
| 50106 EQM Equipment Cues | CardPart with cuegroup, `RefreshOnActivate`: OK (base Activities pattern) | Caption 'Equipment Activities': OK | OK | None: OK | n/a | OK, no change |
| 50107 EQM Equipment Category Chart | CardPart with BusinessChart: OK | OK | n/a | Refresh in Processing: OK; ToolTip third person | n/a | FIX (ToolTip only) |
| 50108 EQM Equipment Status Chart | same as 50107 | OK | n/a | same | n/a | FIX (ToolTip only) |
| 50109 EQM Equipment Dashboard | Card hosting parts, ReportsAndAnalysis, search terms, teaching tip: OK | OK | n/a | Refresh + Equipment promoted flat; ToolTips third person | n/a (parts are the content) | FIX (actions) |
| 50110 EQM Equipment Manager RC | RoleCenter with Embedding / Sections / Creation: OK | No UsageCategory: OK | n/a | **Categories appears twice** (Embedding and Setup section); ToolTips third person | n/a (Role Centers have no FactBox pane) | FIX |
| PageExt 50100 EQM Employee Card | Extension with `addlast`: OK | OK | n/a | Two navigation actions loose at the end of Related, not grouped; **Equipment Assignments uses Image Employee** (should be History); ToolTips third person | **None**: no view of the employee's equipment | FIX |

Other findings, no change:
- `ApplicationArea = All` is set at page level on every page and on every control of the page extension: OK.
- Every page field inherits its ToolTip from the table, and every page variable field has its own Caption and ToolTip:
  OK.
- The profile "EQM EQUIPMENT MANAGER" caption equals the permission set caption 'Equipment Manager' (NFR-002 Q6, kept).
- All images used exist in the base image set (FixedAssets, History, Category, Setup, BarChart, Employee, Undo,
  Refresh, New).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50104, pages 50100-50110, codeunits 50103-50107,
queries 50100-50101, enums 50100-50101, page extension 50100, permission sets 50100-50102, permission set extension
50103, profile "EQM EQUIPMENT MANAGER". Test app: no objects (test codeunits 50150-50162 reserved by FR-001 to NFR-002,
none built).

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Page | 50111 | EQM Equipment FactBox | New | CardPart 'Assignment Details' on the Equipment List and Card |
| Page | 50112 | EQM Assigned Equipment FactBox | New | ListPart 'Assigned Equipment' on the Employee Card |
| Codeunit | 50106 | EQM Assignment Mgt. | Modify (own) | Three internal read/show procedures for the FactBox |
| Page | 50100 | EQM Equipment List | Modify (own) | Action groups, Reporting area, Ctrl+F7, FactBoxes, search terms, ToolTips |
| Page | 50101 | EQM Equipment Card | Modify (own) | Action groups, Ctrl+F7, field importance, FactBoxes, ToolTips |
| Page | 50102 | EQM Equipment Categories | Modify (own) | Promoted group, teaching tip, search terms |
| Page | 50103 | EQM Equipment Setup | Modify (own) | Search terms |
| Page | 50104 | EQM Equipment Assignments | Modify (own) | UsageCategory History, promoted group, teaching tip, search terms, ToolTips |
| Page | 50107 | EQM Equipment Category Chart | Modify (own) | ToolTip wording |
| Page | 50108 | EQM Equipment Status Chart | Modify (own) | ToolTip wording |
| Page | 50109 | EQM Equipment Dashboard | Modify (own) | Promoted groups, ToolTips |
| Page | 50110 | EQM Equipment Manager RC | Modify (own) | Remove duplicate Categories from Embedding, ToolTips |
| PageExtension | 50100 | EQM Employee Card | Modify (own) | Action group, image, ToolTips, FactBox |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | X on pages 50111 and 50112 |

Not changed: tables, queries, enums, codeunits 50103-50105 and 50107, pages 50105 and 50106, permission sets 50101 and
50102 (they include EQM - Reader), permission set extension 50103, the profile, `app/app.json`, `test/`.
Next free IDs after NFR-003: tables 50105, pages 50113, codeunits 50108, queries 50102, enums 50102, page extensions
50101, permission sets 50104. Test app: test codeunit **50163 reserved for NFR-003 "EQM Usability Tests", not built now
(Q1).**

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report; do not pick a workaround on your own.
- Object names are at most 30 characters: "EQM Equipment FactBox" (21), "EQM Assigned Equipment FactBox" (30).
- Base page "Employee Card" has an `area(FactBoxes)` that a page extension can target with `addfirst(FactBoxes)`
  (check the symbols in `.alpackages`).
- Employee table fields "Job Title" and "Company E-Mail" exist with these names in BC 29.
- A page extension can declare a global Boolean, set it in its own `OnOpenPage` trigger, and use it as the `Visible`
  expression of a part it adds.
- `ShortCutKey = 'Ctrl+F7'` is valid syntax on a page action in runtime 18.
- `area(Reporting)` accepts an action with `RunObject = page ...`.
- `systempart(Links; Links)` and `systempart(Notes; Notes)` inside `area(FactBoxes)`.
- `Record.ReadPermission()` on table "EQM Equipment" returns **false** for a user who has only the indirect `r` from
  permission set extension 50103 (D365 BASIC). This decides whether the Employee Card part is hidden for HR users
  without an EQM set. It cannot be checked at compile time: sandbox check UX-SB9 (risk R1).

### Codeunit 50106 "EQM Assignment Mgt." (three new internal procedures)
All `internal`, each with an XML doc comment. No change to existing procedures or events. Use the existing key
`EquipmentStatus` ("Equipment No.", Status) with `SetCurrentKey`.
1. `CountAssignments(EquipmentNo: Code[20]): Integer` - number of assignment entries (active and closed) of the
   equipment. Filter on "Equipment No." and return `Count()`.
2. `GetLastClosedAssignment(EquipmentNo: Code[20]; var EquipmentAssignment: Record "EQM Equipment Assignment"): Boolean`
   - same shape as the existing `GetActiveAssignment`: `Reset`, filter "Equipment No." and Status = Closed, return
   `FindLast()` (highest Entry No. in the key = most recent).
3. `ShowAssignments(EquipmentNo: Code[20])` - opens page "EQM Equipment Assignments" with a record filtered on
   "Equipment No." (same pattern as `ShowEquipmentByCategory` in codeunit 50107).
The codeunit's `Permissions` property is unchanged (it already has indirect r on assignments; Readers have direct R).

### Page 50111 "EQM Equipment FactBox" (new)
File: `app/src/Equipment/EQMEquipmentFactBox.Page.al`, namespace `MiguelCarvalho.EquipmentManagement`,
`using Microsoft.HumanResources.Employee;`.

Page properties: `Caption = 'Assignment Details'`, `PageType = CardPart`, `ApplicationArea = All`,
`SourceTable = "EQM Equipment"`, `Editable = false`. No `UsageCategory`.

Layout, `area(Content)`, in this order:
- Field "No." (`Rec."No."`). Table ToolTip.
- Field Status (`Rec.Status`) with `StyleExpr` = a Text variable set from `Rec.GetStatusStyle()`.
- `group(CurrentAssignment)`, `Caption = 'Current Assignment'`:
  - Field "Assigned Employee No." (`Rec."Assigned Employee No."`). `OnDrillDown`: when the number is not blank **and**
    Employee `ReadPermission()` is true **and** the Employee `Get` succeeds, run page "Employee Card" on that record;
    otherwise do nothing (no message).
  - Field `EmployeeName` (Text[100]), `Caption = 'Employee Name'`,
    `ToolTip = 'Specifies the name of the employee the equipment is assigned to.'`
  - Field `EmployeeJobTitle` (Text[30]), `Caption = 'Job Title'`,
    `ToolTip = 'Specifies the job title of the employee the equipment is assigned to.'`
  - Field `EmployeeEmail` (Text[80]), `Caption = 'Company Email'`, `ExtendedDatatype = EMail`,
    `ToolTip = 'Specifies the company email address of the employee the equipment is assigned to.'`
  - Field `AssignedSince` (Date), `Caption = 'Assigned Since'`,
    `ToolTip = 'Specifies the date the equipment was assigned to the current employee. It is blank when the equipment is not assigned.'`
  - Field `AssignedBy` (Code[50]), `Caption = 'Assigned By'`,
    `ToolTip = 'Specifies the user who assigned the equipment to the current employee. It is blank when the equipment is not assigned.'`
- `group(History)`, `Caption = 'History'`:
  - Field `NoOfAssignments` (Integer), `Caption = 'No. of Assignments'`,
    `ToolTip = 'Specifies how many times the equipment has been assigned, including the current assignment. Choose the number to see the assignment history.'`
    `OnDrillDown`: call `AssignmentMgt.ShowAssignments(Rec."No.")`.
  - Field `LastClosedDate` (Date), `Caption = 'Last Assignment Closed'`,
    `ToolTip = 'Specifies the date the most recent closed assignment of the equipment ended, because the equipment was returned or its status changed. It is blank when no assignment has been closed.'`

Trigger `OnAfterGetRecord` (one local procedure `UpdateFactBox` is fine):
1. Clear all variables (blank text, 0D, 0).
2. Status style from `Rec.GetStatusStyle()`.
3. When "Assigned Employee No." is not blank and Employee `ReadPermission()`: `SetLoadFields("First Name",
   "Middle Name", "Last Name", "Job Title", "Company E-Mail")`, `Get`; if found, name = `FullName()`, job title and
   e-mail from the record.
4. When Status = Assigned and `AssignmentMgt.GetActiveAssignment` finds an entry: AssignedSince = "Assignment Date",
   AssignedBy = "Assigned By".
5. When "No." is not blank: NoOfAssignments = `CountAssignments`; when `GetLastClosedAssignment` finds an entry,
   LastClosedDate = "Closing Date".
No actions. No `var` section labels needed (no messages).
Section order: `layout`, then `var`, then triggers and procedures (AL0926).

### Page 50112 "EQM Assigned Equipment FactBox" (new)
File: `app/src/Employee/EQMAssignedEquipmentFactBox.Page.al`, same namespace. No `using` needed.

Page properties: `Caption = 'Assigned Equipment'`, `PageType = ListPart`, `ApplicationArea = All`,
`SourceTable = "EQM Equipment"`, `SourceTableView = sorting("Assigned Employee No.", Status) where(Status =
const(Assigned))`, `Editable = false`, `InsertAllowed = false`, `ModifyAllowed = false`, `DeleteAllowed = false`.

Layout: `repeater(Equipment)` with
- "No." with `OnDrillDown`: run page "EQM Equipment Card" on `Rec`.
- Description.
- "Serial No." with `Visible = false` (available through personalization).
No actions. The employee filter comes from the `SubPageLink` on the Employee Card.

### Page 50100 "EQM Equipment List" (change)
- Add `AdditionalSearchTerms = 'devices, tools, hardware, company equipment';`
- Actions, replace the whole `actions` section with:
  - `area(Navigation)`:
    - `group(EquipmentGroup)`, `Caption = 'Equipment'`, `Image = FixedAssets`, containing the existing action
      `Assignments` (unchanged name, caption and image), with `ShortCutKey = 'Ctrl+F7'` and
      `ToolTip = 'View the assignment history of the selected equipment.'`
    - `group(SetupGroup)`, `Caption = 'Setup'`, `Image = Setup`, containing the existing actions `Categories`
      (`ToolTip = 'Open the list of equipment categories.'`) and `Setup` (**caption changes to 'Equipment Setup'**,
      `ToolTip = 'Open the equipment setup.'`).
  - `area(Reporting)`: the existing action `Dashboard` moved here (name, caption, image, RunObject unchanged),
    `ToolTip = 'Open the equipment dashboard with key figures and charts.'`
  - `area(Promoted)`:
    - `group(Category_Category4)`, `Caption = 'Equipment'`: `actionref(Assignments_Promoted; Assignments)`.
    - `group(Category_Report)`, `Caption = 'Report'`: `actionref(Dashboard_Promoted; Dashboard)`.
    - `Categories_Promoted` and `Setup_Promoted` are **removed** (setup stays under Related > Setup, Q5).
- Layout, add after `area(Content)`:
  - `area(FactBoxes)`:
    - `part(EquipmentFactBox; "EQM Equipment FactBox")`, `SubPageLink = "No." = field("No.")`.
    - `systempart(Links; Links)`, `Visible = false`.
    - `systempart(Notes; Notes)`.
- `views` and the trigger are unchanged. Keep the section order `layout`, `actions`, `views`, `var`, triggers.

### Page 50101 "EQM Equipment Card" (change)
- Field importance (General and Assignment groups only):
  - `Description`: `Importance = Promoted`.
  - `"Category Code"`: `Importance = Promoted`.
  - `"Assigned Employee Name"`: `Importance = Promoted` (the collapsed Assignment FastTab then shows status and who).
  - All other fields unchanged (no `Additional`: the card has few fields; FR-008 decided the audit fields stay visible).
- Actions:
  - `area(Processing)`: actions `AssignToEmployee` and `Unassign` unchanged except the ToolTips:
    - AssignToEmployee: `'Assign available equipment to an active employee that you select. The assignment is recorded with the work date and your user name.'`
    - Unassign: `'Return the equipment from the assigned employee. The status changes to Available and the assignment is closed with the work date and your user name. The assignment stays in the history.'`
  - `area(Navigation)`: put the existing `Assignments` action into `group(EquipmentGroup)`, `Caption = 'Equipment'`,
    `Image = FixedAssets`. Add `ShortCutKey = 'Ctrl+F7'`. `ToolTip = 'View the assignment history of the
    equipment.'` (already imperative, keep). `Enabled = IsSaved` stays.
  - `area(Promoted)`:
    - `group(Category_Process)`, `Caption = 'Process'`: `AssignToEmployee_Promoted`, `Unassign_Promoted`.
    - `group(Category_Category4)`, `Caption = 'Equipment'`: `Assignments_Promoted`.
- Layout, add after `area(Content)`:
  - `area(FactBoxes)`:
    - `part(EquipmentFactBox; "EQM Equipment FactBox")`, `SubPageLink = "No." = field("No.")` (Q3).
    - `systempart(Links; Links)`, `Visible = false`.
    - `systempart(Notes; Notes)`.
- The part `AssignmentHistory` in the body, the teaching tip, the triggers and procedures are unchanged.
- The FactBox does not refresh by itself after Assign/Return: the existing `CurrPage.Update(false)` in both actions
  re-reads the record, which also updates linked parts. Verify in the sandbox (UX-SB4); if it does not refresh, report
  it, do not add code on your own.

### Page 50102 "EQM Equipment Categories" (change)
- Add `AdditionalSearchTerms = 'equipment types, equipment groups';`
- Add `AboutTitle = 'About equipment categories';` and
  `AboutText = 'Categories group your equipment, for example laptops or phones. Every piece of equipment needs an active category. To stop using a category, clear **Active** instead of deleting it. Choose **Equipment** to see the equipment in a category.';`
- `area(Promoted)`: put `Equipment_Promoted` into `group(Category_Category4)`, `Caption = 'Navigate'`.
- Action `Equipment` ToolTip stays ('View the equipment in the selected category.', already imperative).
- `OnOpenPage` (NFR-002) unchanged.

### Page 50103 "EQM Equipment Setup" (change)
- Add `AdditionalSearchTerms = 'equipment numbers, equipment number series';` Nothing else.

### Page 50104 "EQM Equipment Assignments" (change)
- `UsageCategory = History` (was Lists).
- Add `AdditionalSearchTerms = 'equipment history, equipment loans, issued equipment';`
- Add `AboutTitle = 'About equipment assignments';` and
  `AboutText = 'This list shows every assignment of equipment to an employee, newest first. Active assignments show who has the equipment now. Closed assignments are kept as history and cannot be changed. Choose a view at the top to see only active or closed assignments, and choose **Equipment** or **Employee** to open the related card.';`
- Action ToolTips: Equipment `'Open the equipment card.'`, Employee `'Open the employee card.'`
- `area(Promoted)`: put `Equipment_Promoted` and `Employee_Promoted` into `group(Category_Category4)`,
  `Caption = 'Navigate'`.
- Everything else unchanged (read-only flags, views, trigger, NFR-002 guard).

### Pages 50107 and 50108 (charts, change)
- Action `Refresh`: `ToolTip = 'Update the chart with the current equipment data.'` Nothing else.

### Page 50109 "EQM Equipment Dashboard" (change)
- Action ToolTips: Refresh `'Update the tiles and charts with the current equipment data.'`, Equipment
  `'Open the list of all equipment.'`
- `area(Promoted)`: `group(Category_Process)`, `Caption = 'Process'` with `Refresh_Promoted`;
  `group(Category_Category4)`, `Caption = 'Navigate'` with `Equipment_Promoted`.

### Page 50110 "EQM Equipment Manager RC" (change)
- `area(Embedding)`: **remove the action `CategoryList`** (Categories stays in the Setup section as
  `EquipmentCategories`, Q6).
- ToolTips: EquipmentList `'Open the list of all equipment.'`, AssignmentList `'Open the assignment history of all
  equipment.'`, EquipmentSetup `'Open the equipment setup.'`, EquipmentCategories `'Open the list of equipment
  categories.'`, NewEquipment `'Create a new equipment record.'`
- Parts, Sections and Creation otherwise unchanged.

### Page extension 50100 "EQM Employee Card" (change)
- Actions:
  - `addlast(Navigation)`: wrap the two existing actions in `group(EQMEquipment)`, `Caption = 'Equipment'`,
    `Image = FixedAssets`. Action names unchanged.
    - EQMEquipmentAssignments: **`Image = History`** (was Employee), `ToolTip = 'View the equipment assignment history
      of the employee.'` No shortcut key (Ctrl+F7 is the base shortcut for the employee's own entries).
    - EQMAssignedEquipment: `ToolTip = 'View the equipment that is currently assigned to the employee.'` (unchanged,
      already imperative).
  - `addlast(Processing)`: EQMReturnEquipment stays where it is, `ToolTip = 'Return equipment that is assigned to this employee. Choose the equipment in the list. Its status changes to Available and the assignment is closed.'`
  - No promotion (Q4).
- Layout: new `layout` section with `addfirst(FactBoxes)`:
  - `part(EQMAssignedEquipmentFactBox; "EQM Assigned Equipment FactBox")`, `ApplicationArea = All`,
    `SubPageLink = "Assigned Employee No." = field("No.")`, `Visible = EQMShowEquipmentFactBox`.
- New global variable `EQMShowEquipmentFactBox: Boolean`. New trigger `OnOpenPage`: set it to the result of
  `ReadPermission()` on a local "EQM Equipment" record.
- Existing variables and `ReturnAssignedEquipment` unchanged. Section order: `layout`, `actions`, `var`, triggers,
  procedures.

### Permission set 50100 "EQM - Reader" (change)
Add `page "EQM Equipment FactBox" = X` and `page "EQM Assigned Equipment FactBox" = X` to the object list. No table data
change: the FactBoxes read "EQM Equipment" and "EQM Equipment Assignment" (R for every role) and Employee (D365 BASIC,
guarded).

### app.json, translations
- **app.json: no change.** The version stays 29.0.0.0.
- **Translations:** the build regenerates `app/Translations/Equipment Management.g.xlf` (new and changed captions,
  ToolTips, AboutTitle/AboutText, AdditionalSearchTerms). Commit the regenerated file. Never edit it by hand.

## Data model and upgrade impact
- **No schema change.** No table, field or key changes. No DataClassification changes.
- Notes and links are stored by the platform in the system table "Record Link" against the equipment record. No app
  data, no upgrade code. Notes can contain personal data that users type; the platform owns that table (mention in the
  help).
- The FactBox shows employee job title and company e-mail (Q2). They are read at display time, not stored.
- Upgrade codeunit: not needed (nothing released, nothing stored).

## Events
**Standard BC events: none.** No events report required.

Subscribed: none new. Published: **none.** The new procedures in codeunit 50106 are internal display helpers, not
business moments. Partners extend the FactBoxes with page extensions (both pages are public objects). No IsHandled.

## Permissions
- EQM - Reader: X on pages 50111 and 50112 (Manager and Administrator inherit). No table data change.
- Behavior per role (unchanged from NFR-002 except the new read-only views):

| Element | Reader | Manager | Administrator | No EQM set (D365 BASIC only) |
|---|---|---|---|---|
| Equipment FactBox on list and card | view | view | view | n/a (no access to the pages) |
| Employee details in the FactBox | shown with D365 BASIC; blank without Employee read | same | same | n/a |
| Assigned Equipment FactBox on Employee Card | view | view | view | hidden (UNVERIFIED, R1) |
| Notes and Links on equipment | can add and edit notes and links (platform: needs read on the record, not modify) | same | same | n/a |
| Moved or regrouped actions | same rights as before | same | same | Employee Card actions as before (SB11 of NFR-002) |

- Notes for Readers: in the base app, a user who can read a record can add notes to it. That is standard behavior and
  not a write to equipment data; it is accepted (Q7).

## Compatibility
- AppSource mode, development phase: nothing is released and there is no baseline, so removing promoted actionrefs,
  the Role Center action `CategoryList`, and changing the Setup action caption need no Obsolete handling.
- **After the first release these become contracts:** page IDs 50111/50112, their control names, and every action and
  group name on the app's pages (partners use them in `addafter`/`addlast` and `actionref`). Moving actions into groups
  now keeps all action names, so nothing that exists today is renamed.
- Codeunit 50106 is `Access = Public`, but the three new procedures are `internal`: no public API change.
- `UsageCategory` and `AdditionalSearchTerms` changes are not breaking.
- Doc references to update (documenter, not developer). Historical plans in `docs/plans/` are **not** edited:
  - New `docs/features/NFR-003-usability.md`: requirement, the audit table, the promotion and ToolTip conventions, the
    two FactBoxes, the list of changed pages, open sandbox checks.
  - New `docs/help/NFR-003-usability.md` (end-user help): where actions are now (Equipment list: **Equipment >
    Assignments** in the action bar, **Related > Setup > Categories / Equipment Setup**, **Reports > Dashboard**;
    Employee Card: **Related > Equipment**); Ctrl+F7 opens the assignment history from the equipment list and card;
    what the Assignment Details FactBox shows and that employee details need D365 BASIC; the Assigned Equipment
    FactBox on the Employee Card; Notes and Links; new search words.
  - `docs/help/FR-006`: "Employee card: choose **Navigate > Equipment Assignments**" becomes **Related > Equipment >
    Equipment Assignments**; mention Ctrl+F7. `docs/help/FR-007`: same for **Assigned Equipment**, and add the
    Assignment Details FactBox. `docs/help/FR-009`: "the Dashboard action on the Equipment list" becomes **Reports >
    Dashboard**; the Role Center shortcut list loses the first **Categories** (it stays under Setup).
  - `docs/help/FR-001` line "You can use the same action to give the equipment to someone else." contradicts FR-004
    (return first). Correct it to "To give the equipment to someone else, return it first." (doc fix found in the
    audit).
  - `docs/features/FR-001`, `FR-007`, `FR-008`, `FR-009`: update the action and FactBox descriptions where they
    describe current behavior. No history narrative.
  - `CHANGELOG.md`: new top section `## NFR-003 Usability (version stays 29.0.0.0, no bump)`:
    - Added: pages 50111 and 50112 (FactBoxes), Notes and Links on the equipment list and card, Ctrl+F7 for
      Assignments, teaching tips on Equipment Categories and Equipment Assignments, search terms, three internal
      procedures in codeunit 50106, X permissions in EQM - Reader.
    - Changed: action grouping on all pages, Dashboard moved to Reports on the list, Setup and Categories no longer
      promoted on the list, Setup action caption 'Equipment Setup', Equipment Assignments in Tell Me under History,
      card field importance, action ToolTips in the imperative, Employee Card action group and image, Role Center
      without the duplicate Categories.
    - Fixed: FR-001 help sentence about reassigning.
    - Obsolete: none.
    - A release-notes paragraph.
  - `docs/TODO.md`: add a section "NFR-003 sandbox checks" with UX-SB1 to UX-SB12; add the follow-up "Document
    attachments on equipment (needs al-event-finder)" under open design items (Q9); add "shared employee name helper"
    (R5).

## Test scenarios
**No automated tests in this iteration (Q1 default: deferred, as in FR-003 to NFR-002). No test codeunits, no
`test/app.json` change. ID 50163 is reserved, and the tester step is skipped.** The list is the reference for the
user, who writes the tests later in test codeunit 50163 "EQM Usability Tests" (TestPage based).
- Test data: setup with a fresh number series, category C1, active employees P1 (First/Last Name, Job Title 'Driver',
  Company E-Mail 'p1@example.com') and P2 (no equipment), equipment E1 (never assigned), E2 (assigned to P1 through
  `AssignEmployee` on work date D), E3 (assigned to P1 and returned on work date D2: Available, one Closed entry).
- `[PageHandler]` for pages that drill-downs open; `[ConfirmHandler]` answers Yes for Return.

FactBox on the Equipment List and Card (page 50111)
- F1 Given E2, when the Equipment List TestPage is positioned on E2, then the FactBox shows No. E2, Status Assigned,
  Assigned Employee No. P1, Employee Name = P1 full name, Job Title 'Driver', Company Email 'p1@example.com', Assigned
  Since D, Assigned By = the test user, No. of Assignments 1, Last Assignment Closed blank.
- F2 Given E3, when the list is positioned on E3, then Status Available, all Current Assignment fields blank, No. of
  Assignments 1, Last Assignment Closed D2.
- F3 Given E1, when the list is positioned on E1, then all Current Assignment fields blank, No. of Assignments 0, Last
  Assignment Closed blank.
- F4 Given E3, when No. of Assignments is drilled down, then page 50104 opens filtered on Equipment No. E3 with one
  row (page handler).
- F5 Given E2, when Assigned Employee No. is drilled down, then the Employee Card opens on P1 (page handler).
- F6 Given E1 (no employee), when Assigned Employee No. is drilled down, then nothing opens and no error is raised.
- F7 Given the Equipment Card on E2, when it opens, then the FactBox shows the same values as F1.
- F8 Given a new Equipment Card (not saved), when it opens, then the FactBox is empty and no error is raised.
- F9 Given the card on E1, when Assign to Employee (P2) is invoked, then the FactBox shows P2 and No. of Assignments 1
  (refresh after the action; UNVERIFIED in TestPage, else manual UX-SB4).
- F10 (negative) Given a user with EQM - Reader only (no D365 BASIC), when the list is positioned on E2, then no error
  is raised; Employee Name, Job Title and Company Email are blank; Assigned Employee No., Assigned Since and No. of
  Assignments are shown; drilling down Assigned Employee No. opens nothing.

FactBox on the Employee Card (page 50112)
- EC1 Given P1 with E2 assigned and E3 returned, when the Employee Card opens on P1, then the Assigned Equipment FactBox
  lists E2 only.
- EC2 Given P2, when the Employee Card opens on P2, then the FactBox is empty and no error is raised.
- EC3 Given P1, when No. of E2 is drilled down in the FactBox, then the Equipment Card opens on E2 (page handler).
- EC4 Given E2 is returned, when the Employee Card of P1 is opened again, then the FactBox is empty.
- EC5 (negative) Given a user with D365 BASIC only (no EQM set), when the Employee Card opens on P1, then no error is
  raised and the FactBox is not visible (UNVERIFIED, R1; manual UX-SB9).

Actions (regression: names unchanged after regrouping)
- A1 Given the Equipment List, when actions Assignments, Categories, Setup and Dashboard are invoked on E3, then pages
  50104 (filtered on E3), 50102, 50103 and 50109 open.
- A2 Given the Equipment Card on E1 (Available), then AssignToEmployee is enabled and Unassign is disabled; on E2 the
  reverse (FR-008 behavior unchanged).
- A3 Given a new Equipment Card, then Assignments is disabled (Enabled = IsSaved unchanged).
- A4 Given the Employee Card on P1, when EQMEquipmentAssignments and EQMAssignedEquipment are invoked, then page 50104
  filtered on P1 and page 50100 filtered on P1 open; EQMReturnEquipment still returns E2 (handlers).
- A5 Given Equipment Assignments, Categories and the Dashboard, when their actions are invoked, then the same pages open
  as before (Equipment, Employee, Equipment, Refresh without error).

Structure (code review; no runtime test)
- S1 No page has an `actionref` directly under `area(Promoted)`; every promoted group is one of Category_Process
  'Process', Category_Report 'Report', Category_Category4 (entity name or 'Navigate').
- S2 Every action ToolTip starts with an imperative verb; every field ToolTip starts with "Specifies".
- S3 Page 50104 has `UsageCategory = History`; pages 50100, 50102, 50103, 50104 have `AdditionalSearchTerms`; pages
  50111 and 50112 have no `UsageCategory`.
- S4 The Role Center has exactly one action that opens page 50102.
- S5 EQM - Reader has X on pages 50111 and 50112.

### Manual sandbox checks (for the user; these replace the automated tests for now)
- UX-SB1 Build: AL: Package on `app/` with CodeCop, UICop and AppSourceCop gives no errors and no warnings.
  `Equipment Management.g.xlf` contains the new captions, ToolTips, teaching tips and search terms.
- UX-SB2 Equipment List action bar: an **Equipment** menu with Assignments, a **Report** menu with Dashboard; Related
  shows Equipment > Assignments and Setup > Categories / Equipment Setup; Reports shows Dashboard. Ctrl+F7 on a row
  opens its assignments. Record exactly how the Process/Report/Category groups render (top level or menu); every
  action must be reachable in at most two clicks.
- UX-SB3 Equipment Card action bar: **Process** with Assign to Employee and Return, **Equipment** with Assignments.
  Ctrl+F7 works. Collapsed General FastTab shows Description and Category Code; collapsed Assignment FastTab shows
  Status and the employee name.
- UX-SB4 FactBox on the list follows the selected row; on the card it updates after Assign to Employee and Return.
- UX-SB5 Notes: add a note on a card, it is visible from the list FactBox pane for that row. Links hidden by default and
  can be shown through personalization.
- UX-SB6 Employee Card: Related > Equipment > Equipment Assignments (History icon) / Assigned Equipment; the Assigned
  Equipment FactBox is at the top of the FactBox pane and lists only currently assigned equipment; No. opens the
  equipment card.
- UX-SB7 Tell Me: "Equipment Assignments" is listed under History; searching "devices", "equipment types",
  "equipment number series" and "equipment loans" finds the matching pages. Teaching tips appear on first open of
  Equipment Categories and Equipment Assignments.
- UX-SB8 Role Center: Embedding shows Equipment and Assignments only; Setup section still has Equipment Setup and
  Equipment Categories.
- UX-SB9 User with D365 BASIC only: Employee Card opens without error and without the Assigned Equipment FactBox. If
  the FactBox is visible and shows an error, or the card fails, apply the fallback in R1 and report.
- UX-SB10 Reader without D365 BASIC: list and card FactBox open with blank employee details, no error.
- UX-SB11 Reader: list and card still read-only (NFR-002 SB2/SB4 unchanged); Notes can be added (Q7, record result).
- UX-SB12 Return Equipment lookup from the Employee Card (page 50100 in lookup mode) still works with the FactBox pane.

## Risks and open questions
Open questions (defaults applied in this plan):
- **Q1 Tests.** **Default: deferred** (test codeunit 50163 reserved, tester step skipped, UX-SB1 to UX-SB12 are the
  verification), as decided for FR-003 to NFR-002. If the user wants them now, the test-app fix in `docs/TODO.md`
  comes first.
- **Q2 Employee details in the FactBox.** **Default: name, job title and company e-mail** (work data, useful to contact
  the holder). Alternative: name only; then remove EmployeeJobTitle and EmployeeEmail and adjust F1.
- **Q3 FactBox on the Equipment Card as well as the list?** **Default: yes, the same page 50111.** Status, employee
  and assigned since/by repeat the Assignment FastTab, but job title, e-mail, count and last closed date are new, and
  base cards also repeat details in FactBoxes. Alternative: list only (remove the part on the card, F7-F9).
- **Q4 Promote the equipment actions on the Employee Card?** **Default: no** (standard page used by all HR users; the
  FactBox and Related > Equipment suffice). Alternative: a promoted group 'Equipment' with Assigned Equipment and
  Return Equipment (needs a verified group name in a page extension).
- **Q5 Setup and Categories no longer promoted on the Equipment List.** **Default: yes** (base lists keep setup under
  Related; both pages are in Tell Me and on the Role Center). Alternative: keep them in a promoted group 'Setup'.
- **Q6 Remove the duplicate Categories from the Role Center Embedding.** **Default: yes.** Alternative: keep it in
  Embedding and drop it from the Setup section instead.
- **Q7 Notes and Links on equipment.** **Default: yes, both** (Links hidden by default). Readers can add notes, which is
  standard platform behavior. Alternative: Notes only, or none.
- **Q8 FactBox on Equipment Assignments (page 50104).** **Default: no.** Alternative: reuse page 50111 with
  `SubPageLink = "No." = field("Equipment No.")` to show the current state of the equipment of the selected entry.
- **Q9 Document attachments on equipment.** **Default: out of scope** (new functionality; needs base Document
  Attachment events, so al-event-finder first). Added to TODO as a follow-up.
- **Q10 ToolTip style.** **Default: imperative for actions** (Microsoft guideline). Alternative: keep the third-person
  wording; then only the image and grouping fixes remain for ToolTips.
- **Q11 Search terms and teaching tip texts.** **Default: the texts in this plan.** The user may change wording; the
  developer must not.
- **Q12 Assignments in Tell Me under History.** **Default: yes.** Alternative: keep Lists.

Risks:
- R1 Whether `ReadPermission()` is false for a user with only the indirect read from permission set extension 50103 is
  UNVERIFIED. If it returns true, an HR user without an EQM set could see the Employee Card FactBox fail. Fallback
  (needs user approval, not a developer choice): remove the part from the Employee Card and keep only the actions.
- R2 How promoted groups render (menu vs. top level, order) is client behavior and is checked in UX-SB2/SB3, not
  coded. If Process actions end up one click deeper than today and the user dislikes it, the alternative is
  `actionref`s for Assign/Return at top level of `area(Promoted)` on the card only.
- R3 The Employee Card `area(FactBoxes)` name and the Employee fields "Job Title"/"Company E-Mail" come from the base app
  symbols and are not verified here (see "Platform names").
- R4 The FactBox runs four small reads per selected row (employee, active entry, count, last closed). Equipment volumes
  are small; acceptable. No loop.
- R5 The guarded employee name lookup now exists in five pages. A shared internal helper is a follow-up (TODO).
- R6 Notes typed by users can contain personal data in the system table "Record Link"; that is platform-managed and
  covered by the customer's data handling. Mention in the help.
- R7 No automated tests (Q1), so UI regressions are caught only by review and the sandbox checks.
