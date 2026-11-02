# FR-001 Equipment Registration

> **Implementation note (revision 3):** main app implemented; tests are deferred to a future version (the test
> codeunits, test scenarios and Step 0 test-app fixes below are NOT part of this version). Symbols were verified;
> the UNVERIFIED marks are resolved except the implicit Employee OnBeforeDeleteEvent, which needs a sandbox check.
> Changes after review are in the section "Revision 3 changes" at the end of this file.
>
> Status: REVISION 2, all design questions answered by the user. Ready for approval.
> Items marked **UNVERIFIED** depend on BC 29 symbols that are not yet downloaded
> (`app/.alpackages` is empty). They must be confirmed in step 0 below before coding them.
> Events source: `docs/plans/FR-001-events.md` (confidence notes kept in the Events section).

## Pre-development step 0 (user/environment action, blocks development)
These are environment tasks for the user. The developer agent cannot download symbols.
1. In VS Code, run **AL: Download Symbols** for `/app` and for `/test` (BC 29 sandbox) so that
   `app/.alpackages` and `test/.alpackages` contain Base Application, System Application,
   Business Foundation and, for `/test`, the Microsoft test libraries.
2. Fix `test/app.json`: remove the obsolete `"test"` property and add explicit dependencies on
   Microsoft's **"Library Assert"**, **"Any"** and **"Tests-TestLibraries"** (plus
   **"Library Variable Storage"** and **"System Application Test Library"** if the symbols show that
   `Library - Variable Storage` / `Library - Lower Permissions` live there). Take the app IDs and versions
   from the downloaded symbols. Never type them from memory.
3. Re-run the event search to remove the UNVERIFIED marks:
   `python3 .claude/skills/al-event-search/scripts/list_events.py app/.alpackages --object Employee` and
   `python3 .claude/skills/al-event-search/scripts/list_events.py app/.alpackages --keyword delete --type table`.
   Confirm: (a) the Employee fields `Status` (enum "Employee Status" with value Active) and `"Privacy Blocked"` (Boolean);
   (b) whether a published Employee delete event exists (if it does, prefer it over the implicit event and update this plan);
   (c) codeunit "Confirm Management" with `GetResponseOrDefault(Question: Text; DefaultButton: Boolean): Boolean`;
   (d) page "Employee List" (expected ID 5201); (e) codeunit "No. Series" procedures `GetNextNo`, `TestManual`,
   `AreRelated`, `LookupRelatedNoSeries`; (f) the test-library procedures listed under Test scenarios.
If any name differs, the developer stops and reports to the planner instead of guessing.

## Goal
Users can create and maintain equipment records: the master data that later features use for
assignment and maintenance. Each record has a unique, number-series-driven Equipment No., a mandatory
category, an optional unique serial number, and purchase data. Its status defaults to Available. An
active employee is required while the status is Assigned and is not allowed in any other status. The
app installs a default number series and starter categories. It also stops standard Employee records
from being deleted while equipment is assigned to them.

### Requirement restated, with the user's decisions
- Fields: No., Description, Category, Serial No., Manufacturer, Model, Purchase Date, Purchase Cost,
  Status, Assigned Employee, Location, Created Date, Last Modified Date.
- No. unique (primary key). Serial No. unique when not blank. Category mandatory. Status = Available on a new record.
- Assigned Employee allowed **only** when Status = Assigned, and **required** when Status = Assigned (insert, modify, card).
- Only employees with Status = Active and not Privacy Blocked can be assigned.
- Leaving Assigned while an employee is set asks for confirmation. Answering No cancels the status change.
- Deleting Assigned equipment asks for confirmation. Answering Yes deletes it; deletion is not blocked.
- Deleting a standard Employee that has Assigned EQM equipment is blocked.
- Location = standard `Location` table. Manufacturer and Model = free text. Created/Last Modified = `SystemCreatedAt`/`SystemModifiedAt` (UTC).
- Status values: Available, Assigned, Under Maintenance, Retired.
- On install: number series EQUIP set in EQM Equipment Setup, plus categories LAPTOP, MONITOR, PHONE, VEHICLE, TOOL. Install is idempotent.
- Affix: EQM on objects and on members added to other publishers' objects. Fields inside own tables do not get the affix.

## Approach and rejected alternatives
- Chosen:
  - New Public tables (equipment, category, setup) with the validation in field triggers, plus one
    internal consistency check called from OnInsert and OnModify.
  - An extensible status enum.
  - List, card and setup pages. The card has "Assign to Employee" and "Unassign" actions, because the
    card saves after each field and a two-step manual edit (Status first, then employee) would fail
    the "employee required" rule.
  - Confirmations go through base codeunit "Confirm Management" `GetResponseOrDefault`. With UI, it
    shows the dialog, which tests answer with a `[ConfirmHandler]`. Without UI (API, job queue), it
    returns the default without a dialog.
  - One internal subscriber codeunit on the Employee implicit `OnBeforeDeleteEvent`.
  - An install codeunit that calls a shared internal "default data" codeunit. The setup page calls
    the same codeunit, so companies created after install also get the defaults when an admin first
    opens setup.
  - Numbering uses the BC 24+ `"No. Series"` codeunit.
- Rejected: base `Fixed Asset` / `Resource` tables. They mix accounting or capacity concepts with operational equipment.
- Rejected: custom Created/Modified Date fields. They duplicate the system fields and are skipped by trigger-less writes.
- Rejected: a unique secondary key on "Serial No.". It would forbid more than one blank serial number.
- Rejected: an interface or "confirm provider" abstraction for test bypass. Over-engineered: `[ConfirmHandler]` covers tests, and `GetResponseOrDefault` covers non-UI sessions.
- Rejected: opening an Employee lookup from inside the Status OnValidate trigger. UI in a validate trigger breaks API and code callers. A page action keeps UI on the page.
- Rejected: TableExtension on Employee with an OnDelete trigger. Table extensions cannot add table triggers (events report).
- Rejected: `OnAfterDeleteEvent` on Employee. It fires after base cleanup has run (events report, rank 2).
- Rejected: an `OnCompanyInitialize` subscriber for new companies. That event is not in the events report and is not verified. The setup page path covers new companies without it.

## Objects
No AL objects exist yet in `/app` or `/test`; all IDs below are free. Folders: `app/src/Equipment/`,
`app/src/Setup/`, `app/src/Employee/`, `app/src/Install/`, `app/src/Permissions/`; tests in `test/src/`.
File names: `<Name>.<ObjectType>.al` without spaces or punctuation (e.g. `EQMEquipment.Table.al`).

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50100 | EQM Equipment Status | New | Available, Assigned, Under Maintenance, Retired; `Extensible = true` |
| Table | 50100 | EQM Equipment | New | Equipment master, validation, confirms, published events |
| Table | 50101 | EQM Equipment Category | New | Category master |
| Table | 50102 | EQM Equipment Setup | New | Singleton setup (Equipment Nos.) |
| Page | 50100 | EQM Equipment List | New | Read-only list, search entry point |
| Page | 50101 | EQM Equipment Card | New | Create/maintain; Assign/Unassign actions |
| Page | 50102 | EQM Equipment Categories | New | Editable category list |
| Page | 50103 | EQM Equipment Setup | New | Setup card; ensures setup + defaults |
| Codeunit | 50103 | EQM Employee Subscribers | New | Internal; blocks Employee delete while equipment is Assigned |
| Codeunit | 50104 | EQM Install | New | `Subtype = Install`; calls default data creation per company |
| Codeunit | 50105 | EQM Default Data | New | Internal; idempotent creation of setup, EQUIP series, starter categories |
| PermissionSet | 50100 | EQM - Read | New | Read access |
| PermissionSet | 50101 | EQM - Edit | New | Maintain equipment and categories |
| PermissionSet | 50102 | EQM - Admin | New | Edit + setup |
| Codeunit (test) | 50150 | EQM Equipment Tests | New | Scenarios 1-34, 40-42 (`TestPermissions = Disabled`) |
| Codeunit (test) | 50151 | EQM Library - Equipment | New | Test data helpers |
| Codeunit (test) | 50152 | EQM Equipment Test Subscr. | New | `EventSubscriberInstance = Manual`; scenarios 55-57 |
| Codeunit (test) | 50153 | EQM Equipment Perm. Tests | New | Scenarios 52-54 (`TestPermissions = Restrictive`) |
| Codeunit (test) | 50154 | EQM Employee Integr. Tests | New | Scenarios 35-39 (Employee delete guard) |
| Codeunit (test) | 50155 | EQM Default Data Tests | New | Scenarios 43-51 (setup page, card UI, default data) |

Next free IDs after this feature: app tables/pages 50104, codeunits 50106, enums 50101, permission sets 50103; test 50156.
(Tables, pages and codeunits each have their own ID space, so table 50103 and codeunit 50103 do not collide. Only codeunit 50103 is used in this feature.)

### Enum 50100 "EQM Equipment Status" (Extensible = true, Caption 'Equipment Status')
| Ordinal | Name | Caption |
|---|---|---|
| 0 | Available | Available |
| 1 | Assigned | Assigned |
| 2 | "Under Maintenance" | Under Maintenance |
| 3 | Retired | Retired |

Ordinal 0 = Available, so new records default to Available. Values 2 and 3 have no behavior of their own
in FR-001; for the employee rules they behave like Available.

### Table 50100 "EQM Equipment"
Object properties: Caption 'Equipment'; DataClassification CustomerContent; Access = Public;
LookupPageId/DrillDownPageId "EQM Equipment List"; DataCaptionFields "No.", Description.

| Field ID | Name | Type | Caption | Properties / validation |
|---|---|---|---|---|
| 1 | "No." | Code[20] | No. | OnValidate: if "No." <> xRec."No.", get setup, `NoSeries.TestManual(Setup."Equipment Nos.")`, clear "No. Series". |
| 2 | Description | Text[100] | Description | none |
| 3 | "Category Code" | Code[20] | Category Code | `TableRelation = "EQM Equipment Category"`; `NotBlank = true` |
| 4 | "Serial No." | Code[50] | Serial No. | OnValidate: `CheckSerialNoIsUnique` |
| 5 | Manufacturer | Text[100] | Manufacturer | none |
| 6 | Model | Text[100] | Model | none |
| 7 | "Purchase Date" | Date | Purchase Date | none |
| 8 | "Purchase Cost" | Decimal | Purchase Cost | `AutoFormatType = 1` (LCY); `MinValue = 0` |
| 9 | Status | Enum "EQM Equipment Status" | Status | `InitValue = Available`. OnValidate: see "Status change" below |
| 10 | "Assigned Employee No." | Code[20] | Assigned Employee No. | `TableRelation = Employee."No."`. OnValidate: `CheckAssignedEmployeeAllowed(true)` |
| 11 | "Location Code" | Code[10] | Location Code | `TableRelation = Location.Code` |
| 12 | "No. Series" | Code[20] | No. Series | `TableRelation = "No. Series"`; `Editable = false` |

All fields: `DataClassification = CustomerContent`, `Caption` set, no affix (own table).
Created Date / Last Modified Date = `SystemCreatedAt` / `SystemModifiedAt`.

Keys: PK "No." (Clustered); "Serial No."; "Category Code"; "Assigned Employee No.", Status (non-unique; used by the Employee delete guard).
Field groups: DropDown = "No.", Description, "Category Code", Status. Brick = "No.", Description, Status.

Triggers:
- **OnInsert**:
  1. If "No." is blank: get setup (blank if missing; do not create it here), `TestField("Equipment Nos.")`,
     "No. Series" := setup "Equipment Nos." (or xRec."No. Series" when filled and `NoSeries.AreRelated`), then
     "No." := `NoSeries.GetNextNo("No. Series")`.
  2. `CheckEquipmentConsistency(true)`. The flag means "validate the employee as new".
- **OnModify**: `CheckEquipmentConsistency(false)`.
- **OnDelete**: if Status = Assigned and "Assigned Employee No." <> '': if not
  `ConfirmManagement.GetResponseOrDefault(StrSubstNo(DeleteAssignedQst, "No.", "Assigned Employee No."), true)`, then `Error('')`.
  This cancels the delete silently. Without UI, the default true lets the delete proceed.
- **OnRename**: nothing.

Status change (Status OnValidate):
- If the new Status <> Assigned and "Assigned Employee No." <> '' (the employee is still set from before):
  call `ConfirmManagement.GetResponseOrDefault(StrSubstNo(StatusChangeRemovesEmployeeQst, "Assigned Employee No.", "No."), true)`.
  - Yes (or no UI): set "Assigned Employee No." := '' by plain assignment.
  - No: `Error('')`. The validate is cancelled, the page reverts the field and the record is unchanged.
- If the new Status = Assigned: no action. The consistency check on save requires the employee.
- No confirm is shown when no employee is set.

Internal procedures:
- `AssistEdit(): Boolean`: get setup, `TestField("Equipment Nos.")`. If `NoSeries.LookupRelatedNoSeries(Setup."Equipment Nos.", xRec."No. Series", "No. Series")`
  returns true, set "No." := `NoSeries.GetNextNo("No. Series")` and return true.
- `AssignEmployee(EmployeeNo: Code[20])`: used by the card action. `Validate(Status, Status::Assigned)`; `Validate("Assigned Employee No.", EmployeeNo)`; `Modify(true)`.
- `UnassignEmployee()`: used by the card action. `Validate(Status, Status::Available)` (which asks the confirm); `Modify(true)`.
- `CheckEquipmentConsistency(IsNewRecord: Boolean)`:
  1. `TestField("Category Code")`.
  2. `CheckSerialNoIsUnique`.
  3. Decide whether the employee changed. When IsNewRecord is true, it changed. Otherwise read the stored record
     into a second variable (`SetLoadFields("Assigned Employee No.")`, `Get("No.")`) and compare.
     Call `CheckAssignedEmployeeAllowed(EmployeeChanged)`.
  4. If Status = Assigned and "Assigned Employee No." = '': Error(AssignedEmployeeRequiredErr, FieldCaption("Assigned Employee No."), "No.", Format(Status)).
     This check is not overridable.
  5. Raise `OnAfterCheckEquipmentConsistency(Rec)`.
- `CheckSerialNoIsUnique`:
  1. Raise `OnBeforeCheckSerialNoIsUnique(Rec, IsHandled)`; exit if IsHandled.
  2. Exit if "Serial No." is blank.
  3. On a second record: SetLoadFields("No."), SetCurrentKey("Serial No."), filter "Serial No." = Rec."Serial No." and "No." <> Rec."No.".
  4. If FindFirst, Error(SerialNoAlreadyUsedErr, "Serial No.", other "No.").
- `CheckAssignedEmployeeAllowed(CheckEmployeeIsActive: Boolean)`:
  1. Raise `OnBeforeCheckAssignedEmployeeAllowed(Rec, IsHandled)`; exit if IsHandled.
  2. Exit if "Assigned Employee No." = ''.
  3. If Status <> Status::Assigned: Error(EmployeeOnlyWhenAssignedErr, FieldCaption("Assigned Employee No."), Format(Status::Assigned)).
  4. If CheckEmployeeIsActive and `Employee.Get("Assigned Employee No.")` (use SetLoadFields(Status, "Privacy Blocked")):
     - If `Employee."Privacy Blocked"`: Error(EmployeePrivacyBlockedErr, "Assigned Employee No.").
     - If `Employee.Status <> Employee.Status::Active`: Error(EmployeeNotActiveErr, "Assigned Employee No.", Format(Employee.Status)).
     - **UNVERIFIED** field and enum names; see step 0.
  Why the activity check runs only when the employee changes: equipment already assigned to an employee
  who later becomes inactive can still be edited and unassigned.

Labels (in the table; each a full sentence with a Comment):
- SerialNoAlreadyUsedErr: 'Serial No. %1 is already used by equipment %2.' (%1 = serial number, %2 = equipment number)
- EmployeeOnlyWhenAssignedErr: 'You can only fill in %1 when the status is %2.' (%1 = Assigned Employee No. field caption, %2 = Assigned status caption)
- AssignedEmployeeRequiredErr: 'You must fill in %1 for equipment %2 because its status is %3. On the equipment card, use the Assign to Employee action.' (%1 = field caption, %2 = equipment number, %3 = status caption)
- EmployeeNotActiveErr: 'You cannot assign equipment to employee %1 because the employee status is %2.' (%1 = employee number, %2 = employee status)
- EmployeePrivacyBlockedErr: 'You cannot assign equipment to employee %1 because the employee is blocked for privacy reasons.' (%1 = employee number)
- StatusChangeRemovesEmployeeQst: 'Changing the status removes the assigned employee %1 from equipment %2. Do you want to continue?' (%1 = employee number, %2 = equipment number)
- DeleteAssignedQst: 'Equipment %1 is assigned to employee %2. Do you want to delete it anyway?' (%1 = equipment number, %2 = employee number)

### Table 50101 "EQM Equipment Category"
- Caption 'Equipment Category'; CustomerContent; Access = Public; LookupPageId/DrillDownPageId "EQM Equipment Categories".
- Fields: 1 Code Code[20] (NotBlank); 2 Description Text[100]. PK Code. DropDown = Code, Description.
- OnDelete: if any equipment uses the code (key "Category Code", `IsEmpty`), Error(CategoryInUseErr, Code).
  Label: 'You cannot delete category %1 because it is used by one or more equipment records.' (%1 = category code)

### Table 50102 "EQM Equipment Setup"
- Caption 'Equipment Setup'; CustomerContent; Access = Public.
- Fields: 1 "Primary Key" Code[10]; 2 "Equipment Nos." Code[20] TableRelation "No. Series". PK "Primary Key".

### Codeunit 50105 "EQM Default Data" (Access = Internal)
`Permissions = tabledata "EQM Equipment Setup" = rim, tabledata "EQM Equipment Category" = ri, tabledata "No. Series" = ri, tabledata "No. Series Line" = ri`
(indirect permissions, so a user with only EQM - Read who opens setup does not get a permission error).

Procedures:
- `EnsureSetupExists(): Boolean`: if the setup record does not exist, insert it and return true. Otherwise return false.
- `CreateDefaultData()`: idempotent; never overwrites or deletes existing data.
  1. `EnsureSetupExists`.
  2. If setup "Equipment Nos." is blank:
     - If No. Series 'EQUIP' does not exist, create it: Description = label 'Equipment', Default Nos. = true, Manual Nos. = true.
     - If the series has no No. Series Line, create one: Line No. 10000, Starting No. 'EQ00001', no Ending No.,
       Increment-by No. 1, Starting Date blank.
     - Set setup "Equipment Nos." := 'EQUIP' and Modify.
     If 'EQUIP' already exists, it is reused unchanged.
  3. For each starter category (LAPTOP 'Laptop', MONITOR 'Monitor', PHONE 'Phone', VEHICLE 'Vehicle', TOOL 'Tool'):
     insert only if the code does not exist. Existing descriptions are never changed.
- Labels: the codes 'EQUIP', 'EQ00001' and the category codes are `Locked = true` labels. The descriptions are
  translatable labels with `MaxLength` set to the target field length.

### Codeunit 50104 "EQM Install" (Subtype = Install)
`OnInstallAppPerCompany`: call `EQM Default Data`.CreateDefaultData(). No `OnInstallAppPerDatabase` logic.
Do not use `OnBeforeCompanyOpen` or `OnAfterCompanyOpen` (AppSource rule).

### Codeunit 50103 "EQM Employee Subscribers" (Access = Internal)
`Permissions = tabledata "EQM Equipment" = r`.
- Subscriber to table Employee, implicit `OnBeforeDeleteEvent` (**UNVERIFIED**, confidence medium per events
  report). Parameters: var Rec: Record Employee; RunTrigger: Boolean.
  1. Exit if not RunTrigger. Exit if Rec.IsTemporary().
  2. On EQM Equipment: SetLoadFields("No."), SetCurrentKey("Assigned Employee No.", Status), filter
     "Assigned Employee No." = Rec."No." and Status = Assigned.
  3. If not IsEmpty, Error(EmployeeHasAssignedEquipmentErr, Rec."No.").
- Label: 'You cannot delete employee %1 because one or more equipment records are assigned to the employee.' (%1 = employee number)
- No business logic beyond this check. The subscriber holds the whole guard because the check is a single
  filtered `IsEmpty`. Tests go through the real `Employee.Delete(true)`.

### Page 50100 "EQM Equipment List"
- PageType List; Caption 'Equipment'; CardPageId "EQM Equipment Card"; Editable = false; UsageCategory = Lists.
- Columns: "No.", Description, "Category Code", "Serial No.", Manufacturer, Model, Status, "Assigned Employee No.",
  "Location Code"; "Purchase Date" and "Purchase Cost" with Visible = false.
- Actions: Categories (page 50102) and Setup (page 50103), with actionrefs in the Promoted area.
- Deleting from the list goes through the table OnDelete confirm.

### Page 50101 "EQM Equipment Card"
PageType Card; Caption 'Equipment Card'; **DelayedInsert = true**.
- General: "No." (OnAssistEdit: if Rec.AssistEdit() then CurrPage.Update()), Description, "Category Code" (ShowMandatory), "Serial No.", Manufacturer, Model.
- Assignment:
  - Status.
  - "Assigned Employee No.": Editable and ShowMandatory both bound to a page Boolean `IsAssigned` (Status = Assigned).
    It is recalculated in OnAfterGetRecord and in the page-level OnValidate of Status.
  - Read-only page control "Assigned Employee Name": Text[100], from `Employee.FullName()`, computed in
    OnAfterGetRecord and after the employee field is validated.
  - "Location Code".
- Purchase: "Purchase Date", "Purchase Cost".
- Audit (read-only, Importance Additional): SystemCreatedAt (Caption 'Created Date'), SystemModifiedAt (Caption 'Last Modified Date').
- Actions (Processing area, with actionrefs in Promoted):
  - **Assign to Employee**: Enabled when the record exists in the database.
    1. Filter an Employee record on Status = Active and "Privacy Blocked" = false (**UNVERIFIED** names).
    2. Run page "Employee List" (**UNVERIFIED** name/ID) with `LookupMode = true`.
    3. On LookupOK, call `Rec.AssignEmployee(Employee."No.")`, then CurrPage.Update(false).
    It also works to reassign equipment that is already Assigned.
  - **Unassign**: Enabled when IsAssigned. Calls `Rec.UnassignEmployee()`, then CurrPage.Update(false).
- All controls and actions: ApplicationArea All, ToolTip starting "Specifies ..." or a verb for actions.

### Page 50102 "EQM Equipment Categories"
List; editable; DelayedInsert = true; UsageCategory = Administration; columns Code, Description.

### Page 50103 "EQM Equipment Setup"
- Card; UsageCategory = Administration; InsertAllowed = false; DeleteAllowed = false.
- OnOpenPage: if `EQM Default Data`.EnsureSetupExists() returned true (the setup was missing), call `CreateDefaultData()`.
  Then Rec.Get().
- Group Numbering: "Equipment Nos.".

## Data model and upgrade impact
- First version: three new tables and one enum. **No upgrade codeunit.** An **install codeunit** creates defaults per company.
- DataClassification: CustomerContent on every field. "Assigned Employee No." stores only a reference; personal data stays in Employee.
- Purchase Cost is in LCY.
- Default data (EQUIP series, five categories) is customer data after install; the app never overwrites it.
  Uninstalling does not remove it, which is standard.
- Employee and Location rename: cascades through the TableRelation (platform behavior).
- Location delete: not guarded. Location Code may dangle, the same as base app behavior for location references.

## Events
Subscribed (source: `docs/plans/FR-001-events.md`):
- Table **Employee**, implicit **`OnBeforeDeleteEvent`**, in codeunit 50103. Purpose: block deleting an Employee
  with Assigned equipment.
  - Confidence: **medium, UNVERIFIED** in symbols. Implicit trigger events are a documented platform mechanism.
  - If step 0 finds a published Employee delete event, switch to it (the events report ranks it first).
  - Limitation: deletes with RunTrigger = false bypass the guard. This is accepted and documented in help.
  - Rank-2 fallback: `OnAfterDeleteEvent`.
Not needed: an event for the inactive-employee check. We own the validation (events report, high confidence).

Published (all `[IntegrationEvent(false, false)]`, `local` in the Public table "EQM Equipment"; record passed by value):
1. `OnBeforeCheckSerialNoIsUnique(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)`, with IsHandled. Partners can replace the serial uniqueness rule.
2. `OnBeforeCheckAssignedEmployeeAllowed(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)`, with IsHandled.
   Partners can replace the "employee only when Assigned" and "employee must be active / not privacy blocked" checks.
   It does not skip the "employee required when Assigned" check.
3. `OnAfterCheckEquipmentConsistency(Equipment: Record "EQM Equipment")`, no IsHandled. Partners can add their own checks on insert/modify.

## Permissions
- `EQM - Read` (50100, Assignable, Caption 'Equipment - Read'):
  - tabledata EQM Equipment, EQM Equipment Category, EQM Equipment Setup = R.
  - X on tables 50100-50102, pages 50100-50103 and codeunits 50103 and 50105.
- `EQM - Edit` (50101, Assignable, Caption 'Equipment - Edit'):
  - IncludedPermissionSets = EQM - Read.
  - tabledata EQM Equipment = RIMD, EQM Equipment Category = RIMD.
- `EQM - Admin` (50102, Assignable, Caption 'Equipment - Admin'):
  - IncludedPermissionSets = EQM - Edit.
  - tabledata EQM Equipment Setup = RIMD.
- Indirect permissions declared on codeunits:
  - 50103: tabledata "EQM Equipment" = r. A user who deletes employees without EQM permissions still gets our check, not a permission error.
  - 50105: as listed above.
- Base data (Employee read, Location read, No. Series / No. Series Line for consuming numbers) is not granted by EQM sets.
  Users also need the standard basic set (e.g. D365 BASIC). Document this in the help article. Verify the exact standard
  set name in BC 29 (step 0).

## Compatibility
- AppSource, first release: no existing public API, so no breaking-change risk now.
- **Standard behavior change:** deleting an Employee is now refused while equipment is Assigned to them. This is an
  accepted AppSource pattern (an error from a subscriber), with a clear message. List it in the release notes and the help.
- After the first release, these become contracts and need Obsolete handling to change:
  - table 50100 field names, IDs and types; tables 50101 and 50102;
  - enum 50100 values (can be added, never removed or renumbered);
  - the three event signatures;
  - page IDs and names;
  - permission set names.
- Internal and not API: `AssistEdit`, `AssignEmployee`, `UnassignEmployee`, `CheckEquipmentConsistency`, `CheckSerialNoIsUnique`,
  `CheckAssignedEmployeeAllowed`, and codeunits 50103 and 50105. Tests go through Validate / Insert(true) / Modify(true) /
  Delete(true) / TestPage, so **no internalsVisibleTo** is needed.
- Uses only public BC 29 objects: the "No. Series" and "Confirm Management" codeunits, the Employee and Location tables,
  and the "Employee List" page (all UNVERIFIED until step 0).

## Test scenarios
General:
- Each test codeunit's Initialize uses `EQM Library - Equipment` (50151) to set EQM Equipment Setup."Equipment Nos." to a
  fresh number series (Default Nos. = true, Manual Nos. = true). This runs regardless of the defaults created on install.
- Libraries: `Library - Utility` (CreateNoSeries, CreateNoSeriesLine, GenerateRandomCode), `Library - Human Resource`
  (CreateEmployee, expected to create Active employees), `Library - Warehouse` (CreateLocation), `Library - Random`,
  `Library - Variable Storage`, `Library Assert`, `Library - Lower Permissions`. All UNVERIFIED (step 0).
- Assertions:
  - TestField errors: `Assert.ExpectedTestFieldError`.
  - Platform errors: `Assert.ExpectedErrorCode`.
  - Own errors: the label text with StrSubstNo.
- Confirms are answered by `[ConfirmHandler]` functions:
  - The reply comes from Library - Variable Storage.
  - The handler also stores the question text, which the test checks against the label.
  - A test that expects **no** confirm attaches no handler. An unexpected confirm then fails the test.
- A test that expects a cancelled action (No reply) uses `asserterror`. It then re-reads the record from the database and
  asserts it is unchanged.

Numbering and identity (50150)
1. Given setup with an Equipment Nos. series, when equipment is inserted with blank No. (Insert(true)), then No. is the next number and "No. Series" = setup series.
2. Given setup with blank Equipment Nos., when equipment with blank No. is inserted, then a TestField error on "Equipment Nos." is raised.
3. Given the setup series with Manual Nos. = false, when a manual No. is validated, then an error is raised.
4. Given Manual Nos. = true, when a manual No. is validated and the record inserted, then it is saved with that No. and blank "No. Series".
5. Given existing equipment No. X, when another equipment with No. X is inserted, then the insert fails (record exists).

Status default (50150)
6. Given a new record (Init) with a category, when it is inserted without setting Status, then Status = Available.

Category (50150)
7. Given blank Category Code, when Insert(true) is called, then a TestField error on "Category Code" is raised and no record exists.
8. Given existing equipment, when Category Code is validated to blank, then an error is raised (NotBlank).
9. Given a non-existing category code, when it is validated, then a table relation error is raised.
10. Given an existing category, when it is validated, then the value is kept.
11. Given a category used by equipment, when the category is deleted with Delete(true), then CategoryInUseErr is raised.
12. Given an unused category, when it is deleted with Delete(true), then it no longer exists.

Serial number (50150)
13. Given equipment A with Serial No. S, when equipment B validates S, then SerialNoAlreadyUsedErr is raised (S, A's No.).
14. Given A with Serial No. S, when A re-validates S, then no error.
15. Given A and B with blank Serial No., when both are inserted, then both are saved.
16. Given A with Serial No. 'ABC', when B validates 'abc', then SerialNoAlreadyUsedErr is raised.
17. Given A with Serial No. S, when B gets S by direct assignment and Insert(true) is called, then SerialNoAlreadyUsedErr is raised.

Assigned employee: allowed / required / active (50150)
18. Given Status Available, when an active employee is validated into Assigned Employee No., then EmployeeOnlyWhenAssignedErr is raised.
19. Given Status Under Maintenance (and, separately, Retired), when an employee is validated, then EmployeeOnlyWhenAssignedErr is raised.
20. Given Status Assigned (validated), when an active employee is validated and Modify(true) is called, then the record is saved with the employee.
21. Given Status Assigned, when a non-existing employee no. is validated, then a table relation error is raised.
22. Given an employee with Status Inactive, when validated on Assigned equipment, then EmployeeNotActiveErr is raised.
23. Given an employee with Status Terminated, when validated on Assigned equipment, then EmployeeNotActiveErr is raised.
24. Given an Active employee with Privacy Blocked = true, when validated on Assigned equipment, then EmployeePrivacyBlockedErr is raised.
25. Given new equipment with Status Assigned and blank employee, when Insert(true) is called, then AssignedEmployeeRequiredErr is raised.
26. Given saved Assigned equipment with an employee, when the employee is set to blank and Modify(true) is called, then AssignedEmployeeRequiredErr is raised.
27. Given saved Available equipment, when Assigned Employee No. is set by direct assignment and Modify(true) is called, then EmployeeOnlyWhenAssignedErr is raised.
28. Given equipment assigned to employee E, and E is later set to Inactive, when Description is changed and Modify(true) is called, then the record is saved (the activity check runs only when the employee changes).
29. Given equipment assigned to inactive employee E (as in 28), when the employee is set to a different inactive employee by direct assignment and Modify(true) is called, then EmployeeNotActiveErr is raised.

Status change confirm (50150)
30. Given equipment Assigned to E, when Status is validated to Available and the ConfirmHandler answers Yes, then Status = Available and Assigned Employee No. is blank. The confirm question equals StatusChangeRemovesEmployeeQst with E and the equipment No.
31. Given equipment Assigned to E, when Status is validated to Available and the ConfirmHandler answers No, then an error is raised (asserterror). After re-reading, Status = Assigned and the employee is still E.
32. Given Available equipment (no employee), when Status is validated to Retired, then no confirm is shown (no handler) and Status = Retired.

Delete confirm (50150)
33. Given equipment Assigned to E, when Delete(true) is called and the ConfirmHandler answers Yes, then the record no longer exists. The question equals DeleteAssignedQst.
34. Given equipment Assigned to E, when Delete(true) is called and the ConfirmHandler answers No, then the record still exists.
    Extra case for 34: given Available equipment, when Delete(true) is called, then no confirm is shown and the record is deleted. Implement as a separate test.

Employee delete guard (50154)
35. Given equipment Assigned to employee E, when E.Delete(true) is called, then EmployeeHasAssignedEquipmentErr is raised with E's No., and E still exists.
36. Given equipment that was Assigned to E and then unassigned (confirm Yes), when E.Delete(true) is called, then E is deleted.
37. Given employee E with no equipment, when E.Delete(true) is called, then E is deleted.
38. Given equipment Assigned to E, when E.Delete(false) is called, then E is deleted (documented limitation: no trigger, no guard).
39. Given a temporary Employee record with the No. of E (E has Assigned equipment), when the temporary record's Delete(true) is called, then no error is raised.

Other fields (50150)
40. Given a non-existing Location code, when Location Code is validated, then a table relation error is raised; with an existing Location, the value is kept.
41. Given equipment, when Purchase Cost is validated to a negative value, then an error is raised; 0 and a positive value are accepted.
42. Given newly inserted equipment, then SystemCreatedAt and SystemModifiedAt are not 0DT; after a later Modify(true), SystemModifiedAt >= its previous value and SystemCreatedAt is unchanged.

Setup page, card UI and default data (50155)
Default data is tested through the setup page path, which uses the same `CreateDefaultData` as the install codeunit.
To start from a clean state, a test deletes the setup record, the categories LAPTOP/MONITOR/PHONE/VEHICLE/TOOL and
No. Series 'EQUIP' with its lines; the test rollback restores them.
43. Given no setup record, no 'EQUIP' series and no starter categories, when page EQM Equipment Setup is opened, then:
    the setup exists with "Equipment Nos." = 'EQUIP'; series 'EQUIP' exists with Default Nos. = true and Manual Nos. = true;
    it has one line starting at 'EQ00001'; and the five categories exist with descriptions Laptop, Monitor, Phone, Vehicle, Tool.
44. Given the state after 43, when `CreateDefaultData` runs again (close the page, delete only the setup record, open the page again), then there is still exactly one 'EQUIP' series line, exactly five starter categories, and no error.
45. Given category LAPTOP already exists with description 'Notebooks', when defaults are created, then its description is still 'Notebooks'.
46. Given an existing setup record with "Equipment Nos." = another series X, when the setup page is opened, then "Equipment Nos." is still X and no categories are created (defaults run only when the setup was missing).
47. Given No. Series 'EQUIP' already exists with its own line, and no setup record, when defaults are created, then the setup uses 'EQUIP' and the existing line is unchanged (no second line).
48. Given the Equipment Card on Available equipment, then "Assigned Employee No." is not editable and Unassign is disabled. When Status is set to Assigned on the page, the field becomes editable.
49. Given the card opened with OpenNew, when category and description are filled and the page is closed, then exactly one new equipment exists with a number from the series and Status Available.
50. Given Available equipment on the card, when Assign to Employee is invoked and a `[ModalPageHandler]` for the Employee List selects active employee E, then the record is saved with Status Assigned and employee E.
    The handler also checks that an inactive employee and a privacy-blocked employee cannot be found in the lookup (GoToKey returns false).
51. Given equipment Assigned to E on the card, when Unassign is invoked and the ConfirmHandler answers Yes, then the record is saved with Status Available and a blank employee.

Permissions (50153, `TestPermissions = Restrictive`)
52. Given a user with EQM - Read (plus the standard basic set), when equipment is read, then it succeeds; when equipment is inserted, then a permission error is raised.
53. Given a user with EQM - Edit (plus the standard basic set), when equipment and a category are created, then it succeeds; when the setup record is modified, then a permission error is raised; with EQM - Admin, it succeeds.
54. Given equipment Assigned to E, and a user with only the standard set that can delete employees (no EQM set), when E.Delete(true) is called, then EmployeeHasAssignedEquipmentErr is raised (not a permission error), which proves the indirect permission on codeunit 50103.

Published events (50152 bound with BindSubscription in the test)
55. Given an OnBeforeCheckSerialNoIsUnique subscriber that sets IsHandled := true, when B validates a Serial No. used by A, then no error is raised.
56. Given an OnBeforeCheckAssignedEmployeeAllowed subscriber that sets IsHandled := true, when an inactive employee is validated on Available equipment, then no error is raised.
57. Given an OnAfterCheckEquipmentConsistency subscriber that raises a known error, when equipment is inserted with Insert(true), then that error is raised.

Not automatable: the install codeunit trigger itself (`OnInstallAppPerCompany`). Verify manually once in a sandbox:
after publishing into a fresh company, the setup has EQUIP and the five categories exist. Republishing or reinstalling
creates no duplicates. Tests 43-47 cover the logic it calls.

## Risks and open questions
Open questions: **none**. All ten earlier questions were answered by the user and are reflected above.

Risks:
- **UNVERIFIED names until step 0:**
  - Employee `Status` enum ("Employee Status", value Active) and `"Privacy Blocked"`;
  - the implicit Employee `OnBeforeDeleteEvent`;
  - page "Employee List";
  - codeunit "Confirm Management".`GetResponseOrDefault`;
  - the "No. Series" codeunit procedures;
  - the test-library procedures, including `Assert.ExpectedTestFieldError`;
  - the standard basic permission set name.
  If any differs, the developer stops and reports back. No guessing.
- **Test environment** (step 0, user action): symbols are missing and test/app.json lacks the Microsoft test-library dependencies. Nothing compiles until this is fixed.
- The Employee delete guard does not apply to trigger-less deletes (RunTrigger = false), e.g. some configuration-package or migration paths. Document this in help.
- Confirm in non-UI sessions (API, job queue) uses the default Yes. A status change away from Assigned clears the employee, and deleting Assigned equipment proceeds without asking. This is intended, so integrations are not blocked. Document it.
- Rule conflict, by design: an inactive employee can stay assigned (28), but cannot be newly assigned (29). Unassigning always works.
- AppSource readiness of app.json (outside FR-001; for appsource-validator):
  - no "TranslationFile" feature (XLF required);
  - no `supportedLocales`;
  - empty `privacyStatement`, `EULA`, `help`, `url` and `logo`;
  - 50100-50149 is a demo range, not a registered AppSource range.
- DelayedInsert on the card: closing a new card without a category shows the error and the record is not saved. Mention this in help.

## Revision 3 changes (post-review, implemented)
- **Rule: employee that no longer exists.** If "Assigned Employee No." is filled and the Employee record does not
  exist, insert/modify and validate raise EmployeeNotFoundErr ('Employee %1 assigned to equipment %2 no longer exists.
  Use the Unassign action, then assign another employee.'). The equipment cannot be edited until it is unassigned.
- **Employee delete guard:** filters on the employee only (any equipment referencing the employee blocks the delete,
  regardless of Status). The key ("Assigned Employee No.", Status) still supports the lookup.
- **AssistEdit** is only allowed when "No." is blank; the card calls `CurrPage.Update(false)` after it.
- **Card lookup:** the "Assigned Employee No." field has an OnLookup showing active, not privacy-blocked employees only
  (the table relation itself stays unfiltered). Assign to Employee uses the same selection.
- **Permissions (indirect only):**
  - New `permissionsetextension` 50103 "EQM D365 BASIC" extends standard set "D365 BASIC" (ID 207, namespace
    System.Security.AccessControl; verified in BC 29 symbols) with only `tabledata "EQM Equipment" = r` (lowercase,
    indirect). It exposes no data directly and works only inside objects whose Permissions property lists the table
    (codeunit 50103).
  - `EQM - Read`: tabledata "EQM Equipment" = R, "EQM Equipment Category" = Ri, "EQM Equipment Setup" = Rim (plus X on objects).
    `EQM - Edit` includes Read and adds RIMD on equipment and categories; `EQM - Admin` includes Edit and adds RIMD on setup.
    So Edit and Admin contain everything Read has.
  - The Permissions property on codeunits 50103 and 50105 grants indirect permissions only; it works when the user's sets
    contain the matching lowercase rights (D365 BASIC extension and EQM sets).
- **Verified names (BC 29):** Employee.Status enum "Employee Status" (Active, Inactive, Terminated), "Privacy Blocked",
  page "Employee List" (5201), codeunit "Confirm Management" (27) GetResponseOrDefault, codeunit "No. Series" (310)
  GetNextNo/TestManual/AreRelated/LookupRelatedNoSeries, standard set "D365 BASIC". Base objects are in namespaces; our
  files add `using` lines.
- **Manual sandbox checks (replace automated tests for now):**
  1. A user with no EQM permission set (only D365 BASIC) deletes an Employee with Assigned equipment: expect the guard
     error, not a permission error. Same user deletes an Employee without equipment: expect success.
  2. A user with only EQM - Read opens Equipment Setup in a fresh company (no setup record): expect no permission error and
     defaults (EQUIP series, five categories) created.
  3. Publish into a fresh company; verify defaults; republish and verify no duplicates.
  4. Delete an Employee from the Employee Card with Assigned equipment: verify the implicit OnBeforeDeleteEvent subscriber fires.
- **Tests: deferred to a future version.** Scenarios 1-57 remain as the specification for that work.
