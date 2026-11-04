# FR-008 Equipment Card

> Status: DRAFT, awaiting user approval. Open questions Q1-Q6 are at the end. Every question has a default (in bold),
> and this plan is written against those defaults. If the user confirms them all, no revision is needed.
> Source: GitHub issue #14. Branch: `feature/FR-008-equipment-card`.
> No events report: FR-008 changes only this app's own card page (50101), adds one own ListPart page and one internal
> procedure on an own codeunit. It subscribes to no events and changes no standard behavior, so al-event-finder is not
> needed.
> Scope: main app only. **One new object (page 50105). No schema change, no version bump** (app.json stays 29.0.0.0, as
> in FR-004 to FR-007). **No upgrade logic.** **No automated tests** by default (Q5, same as FR-003 to FR-007; the
> scenarios are a reference only).
> Workflow for FR-008: planner -> (human approves plan) -> developer -> reviewer -> **tester step SKIPPED (Q5)** ->
> documenter -> appsource-validator.

## Goal
Users get one card that shows everything about a piece of equipment: its details, its current status and assignment,
the full assignment history and who created and last changed the record. FR-001 already built the card (page 50101)
with most of the General Information. FR-008 closes the gaps: assignment details from the active assignment entry, the
assignment history shown directly on the card, and complete audit information (who, not only when).

### Requirement restated
- C-R1 A dedicated Equipment Card page.
- C-R2 General Information: equipment details.
- C-R3 General Information: assignment details.
- C-R4 General Information: current status.
- C-R5 Related Information: assignment history.
- C-R6 Related Information: audit information.

### What FR-001 to FR-007 already deliver (reused, not duplicated)
Page 50101 "EQM Equipment Card" (Card, `SourceTable = "EQM Equipment"`, `CardPageId` of list 50100, target of the
Equipment action on page 50104). Groups today, in this order: General, Assignment, Purchase, Audit. Actions: Assign to
Employee, Return, Assignments (navigation to page 50104 filtered on the equipment), all promoted.

| Requirement | Already covered by | Gap closed by FR-008 |
|---|---|---|
| C-R1 | Page 50101 exists, opened from the list, from page 50104 and from lookups. | None. No second card is created (Q1). |
| C-R2 | Group General: No. (number-series assist edit), Description, Category Code, Serial No., Manufacturer, Model. Group Purchase: Purchase Date, Purchase Cost. | None. |
| C-R3 | Group Assignment: Assigned Employee No., Assigned Employee Name, Location Code. | **Assigned Since** and **Assigned By** of the current assignment, read from the active entry in table 50103. |
| C-R4 | Group Assignment: Status (two controls: new-record and saved-record variants, styled with `GetStatusStyle`). | Status is shown in the collapsed Assignment FastTab header (`Importance = Promoted`). |
| C-R5 | Only a navigation action "Assignments" that opens page 50104 in a separate window. | **New ListPart page 50105 "EQM Assignment History Part"** shown on the card as section "Assignment History", newest first, inserted between Purchase and Audit. The navigation action stays. |
| C-R6 | Group Audit (last group): Created Date (SystemCreatedAt), Last Modified Date (SystemModifiedAt), both `Importance = Additional` (hidden until "Show more"). | **Created By** and **Last Modified By** (user names resolved from SystemCreatedBy / SystemModifiedBy). Audit fields shown by default (Q4). Audit stays the last section. Assignment-level audit (Assigned By, Closed By and dates) is shown in the history part. |
| Discoverability | Nothing explains the card layout. | **Teaching tip** (`AboutTitle`/`AboutText`) on page 50101, like FR-007 did on the list (Q6). |

## Approach and rejected alternatives
- Chosen: extend this app's own card 50101 in place, add one read-only ListPart (page 50105) bound to the card through
  `SubPageLink`, and add one internal read procedure `GetActiveAssignment` on codeunit 50106 "EQM Assignment Mgt." so
  the card does not query table 50103 itself. Assignment details and audit user names are page variables filled in the
  existing `UpdateControls` procedure. No table, key or permission-model change except granting X on the new page.
- Rejected: a new, second card page. Card 50101 already exists and is the `CardPageId`; a second card would split the
  UI and the permission sets (Q1).
- Rejected: FlowFields "Assigned Since" / "Assigned By" on table 50100 (lookup to the active entry). Schema change,
  and the values are only needed on the card. The page-variable pattern is already used for the employee name.
- Rejected: showing the history in the FactBox pane (CardPart/ListPart in `area(FactBoxes)`). The history has seven
  useful columns (employee, name, dates, users, status), which do not fit the narrow FactBox pane (Q3).
- Rejected: reusing page 50104 "EQM Equipment Assignments" as the part. It is a `List` page with `UsageCategory`,
  views and navigation actions; a part must be a `ListPart`, and its Equipment columns are redundant on the card.
- Rejected: showing SystemCreatedBy / SystemModifiedBy directly. They are GUIDs and mean nothing to users.
- Rejected: turning on the BC Change Log for table 50100, or building a field-level change history. Not asked for by
  the issue, needs setup and its own permissions (Q2).
- Rejected: a shared helper for the employee full name (used now by pages 50100, 50101, 50104 and 50105). It would mean
  refactoring three existing pages; the duplication is 4 lines and is noted as a follow-up (R4).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50103, pages 50100-50104, codeunits 50103-50106,
enums 50100-50101, page extension 50100, permission sets 50100-50102, permission set extension 50103. Test app: no
objects (test codeunits 50150-50155 reserved by FR-001, 50156-50157 by FR-004, 50158 by FR-006, 50159 by FR-007,
none built).

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Page | 50105 | EQM Assignment History Part | New | Read-only ListPart of assignment entries (table 50103), embedded in the card |
| Page | 50101 | EQM Equipment Card | Modify (own) | Teaching tip; Assigned Since / Assigned By; Status promoted; history part; Created By / Last Modified By; Audit shown by default |
| Codeunit | 50106 | EQM Assignment Mgt. | Modify (own) | New internal procedure `GetActiveAssignment` |
| PermissionSet | 50100 | EQM - Read | Modify (own) | Add `page "EQM Assignment History Part" = X` |

Not changed: tables 50100-50103, pages 50100, 50102-50104, codeunits 50103-50105, enums, page extension 50100,
permission sets 50101-50102 (they include EQM - Read), permission set extension 50103, `app/app.json`, `test/`.
Next free IDs after FR-008: tables 50104, pages 50106, codeunits 50107, enums 50102, page extensions 50101,
permission sets 50104. Test app: test codeunit **50160 reserved for FR-008 "EQM Equipment Card Tests", not built now
(Q5).**

### Page 50105 "EQM Assignment History Part" (new)
File: `app/src/Assignment/EQMAssignmentHistoryPart.Page.al`, namespace `MiguelCarvalho.EquipmentManagement`,
`using Microsoft.HumanResources.Employee;`.

Page properties:
- `Caption = 'Assignment History'`
- `PageType = ListPart`
- `ApplicationArea = All`
- `SourceTable = "EQM Equipment Assignment"`
- `SourceTableView = sorting("Entry No.") order(descending);` (newest first, same as page 50104)
- `Editable = false`, `InsertAllowed = false`, `ModifyAllowed = false`, `DeleteAllowed = false`
- No `UsageCategory` (a part must not appear in search).

Layout: `area(Content)`, `repeater(History)` with these controls in this order (no ToolTip on table-field controls,
they inherit it from table 50103):
1. `"Entry No."` with `Visible = false`
2. `"Employee No."`
3. `"Employee Name"` bound to page variable `EmployeeName` (Text[100]), `Caption = 'Employee Name'`,
   `ToolTip = 'Specifies the name of the employee.'` (identical to page 50104, so the XLF stays consistent)
4. `"Assignment Date"`
5. `"Assigned By"`
6. `Status` with `StyleExpr = StatusStyle`
7. `"Closing Date"`
8. `"Closed By"`
No "Equipment No." or "Equipment Description" column: the part is always filtered on the card's equipment.

Actions: none, so no `actions` section (the card keeps its "Assignments" navigation action for the full list page).

`var`: `EmployeeName: Text[100]`, `StatusStyle: Text`, `FavorableStyleTok: Label 'Favorable', Locked = true`,
`SubordinateStyleTok: Label 'Subordinate', Locked = true`.

Trigger `OnAfterGetRecord` (same logic as page 50104):
1. `EmployeeName := ''`.
2. Local `Employee: Record Employee` (the name `Employee` is safe here: the part has no control or action called
   Employee). `SetLoadFields("First Name", "Middle Name", "Last Name")`; if `Get(Rec."Employee No.")` succeeds, set
   `EmployeeName := Employee.FullName()`. A missing employee leaves the name blank, no error.
3. `StatusStyle` = `FavorableStyleTok` when `Rec.Status = Rec.Status::Active`, otherwise `SubordinateStyleTok`.

Section order: `layout`, then `var` and triggers (AL0926).

### Codeunit 50106 "EQM Assignment Mgt." (change)
Add one procedure after `HasAssignmentHistory`:
- Signature: `internal procedure GetActiveAssignment(EquipmentNo: Code[20]; var EquipmentAssignment: Record "EQM Equipment Assignment"): Boolean`
- Behavior: on the `var` parameter call `Reset()`, `SetCurrentKey("Equipment No.", Status)`,
  `SetRange("Equipment No.", EquipmentNo)`, `SetRange(Status, Status::Active)`; return `FindLast()`. No
  `SetLoadFields` (the caller gets a complete record). When the function returns false the record is empty.
- `FindLast` because the app guarantees at most one active entry per equipment (FR-004 `CreateAssignment` closes older
  ones first); if there ever were two, the newest is the current one.
- XML doc comment: "Finds the active assignment entry of the equipment. Equipment has at most one active entry; if
  there are more, the newest is returned." Document both parameters and the return value.
- Must stay `internal`: it is not a partner API (see Compatibility).
- No new events. The existing codeunit `Permissions` property already covers reading table 50103.

### Page 50101 "EQM Equipment Card" (changes)

**Page-level properties** (add next to `Caption`; do not change the existing properties):
- `AboutTitle = 'About equipment details'`
- `AboutText = 'Here you manage one piece of equipment. The first sections show its details, its current status and who it is assigned to. Use **Assign to Employee** and **Return** to change the assignment. Further down, **Assignment History** lists every assignment, and **Audit** shows who created the record and who changed it last.'`
  (one string on one line in the source, translated through the XLF; do not split it into labels).

**Layout, order of the content area** (existing groups keep their names and relative order; the only structural change
is the new part between Purchase and Audit):
1. `group(General)` unchanged.
2. `group(Assignment)` with the changes below.
3. `group(Purchase)` unchanged.
4. **New** `part(AssignmentHistory; "EQM Assignment History Part")`:
   - `Caption = 'Assignment History'`
   - `SubPageLink = "Equipment No." = field("No.");`
   - `UpdatePropagation` not set (the part is read-only).
   - No `Visible`/`Enabled` condition: on a new, unsaved card the link filter is on a blank or not-yet-used number, so
     the part is simply empty (entries never have a blank Equipment No., `NotBlank = true`).
5. `group(Audit)`, still last, with the changes below.

**Group Assignment changes:**
- Controls `StatusNew` and `Status`: add `Importance = Promoted` to both (they are never visible at the same time).
  Keep everything else (ValuesAllowed, Visible, StyleExpr, OnValidate) unchanged.
- After `"Assigned Employee Name"` and before `"Location Code"`, add:
  - `field(AssignedSince; ActiveAssignmentDate)` with `Caption = 'Assigned Since'`, `Editable = false`,
    `ToolTip = 'Specifies the date the equipment was assigned to the current employee. It is blank when the equipment is not assigned.'`
  - `field(AssignedBy; ActiveAssignedBy)` with `Caption = 'Assigned By'`, `Editable = false`,
    `ToolTip = 'Specifies the user who assigned the equipment to the current employee. It is blank when the equipment is not assigned.'`
- `"Assigned Employee No."`, `"Assigned Employee Name"`, `"Location Code"`: unchanged.

**Group Audit changes** (four controls, in this order):
1. `CreatedDate` (SystemCreatedAt): keep caption 'Created Date', tooltip and `Editable = false`; **remove**
   `Importance = Additional` (Q4).
2. **New** `field(CreatedBy; CreatedByUserName)`, `Caption = 'Created By'`, `Editable = false`,
   `ToolTip = 'Specifies the user who created the equipment record.'`
3. `LastModifiedDate` (SystemModifiedAt): keep caption, tooltip and `Editable = false`; **remove**
   `Importance = Additional`.
4. **New** `field(LastModifiedBy; ModifiedByUserName)`, `Caption = 'Last Modified By'`, `Editable = false`,
   `ToolTip = 'Specifies the user who last changed the equipment record.'`

**Actions:** unchanged (AssignToEmployee, Unassign, Assignments and their actionrefs). Both processing actions already
call `CurrPage.Update(false)`, which also refreshes the part, so a new or closed entry shows immediately. Do not add
extra refresh code.

**`var` section:** add
- `ActiveAssignmentDate: Date;`
- `ActiveAssignedBy: Code[50];` (same length as table 50103 "Assigned By")
- `CreatedByUserName: Code[50];`
- `ModifiedByUserName: Code[50];` (same length as `User."User Name"`)

Add `using System.Security.AccessControl;` at the top (for the `User` table).

**Procedure `UpdateControls` changes** (keep all existing lines; add at the end):
1. Clear the four new variables first, so a previous record's values are never shown.
2. If `IsSaved` and `Rec.Status = Rec.Status::Assigned`: call `AssignmentMgt.GetActiveAssignment(Rec."No.", ActiveAssignment)`
   on local variables `AssignmentMgt: Codeunit "EQM Assignment Mgt."` and
   `ActiveAssignment: Record "EQM Equipment Assignment"`; when it returns true, copy "Assignment Date" to
   `ActiveAssignmentDate` and "Assigned By" to `ActiveAssignedBy`. When it returns false, leave them blank (no error;
   this is display only).
3. `CreatedByUserName := GetUserName(Rec.SystemCreatedBy);` and
   `ModifiedByUserName := GetUserName(Rec.SystemModifiedBy);`

**New local procedure** `local procedure GetUserName(UserSecurityId: Guid): Code[50]`:
- Returns '' when `IsNullGuid(UserSecurityId)` (new records, records written by the system).
- Local `User: Record User`. Returns '' when `not User.ReadPermission()` (no permission error on the card for users
  without read access to User, see R2).
- `User.SetLoadFields("User Name")`; if `User.Get(UserSecurityId)` succeeds return `User."User Name"`, otherwise ''
  (deleted user).

Section order stays `layout`, `actions`, then `var`, triggers and procedures (AL0926).

### app.json, translations
- No app.json change. The build regenerates `app/Translations/Equipment Management.g.xlf` (new page, captions,
  tooltips, AboutTitle/AboutText). Commit the regenerated file; never edit it by hand.

## Data model and upgrade impact
- No schema change: no new tables, fields, keys, enums or field groups. One new page, page and codeunit changes only.
- DataClassification: nothing new is stored. The card now displays user names (Created By, Last Modified By, Assigned
  By); they are read from System fields / table 50103 ("Assigned By" is already `EndUserIdentifiableInformation`).
- Upgrade codeunit: not needed (nothing released, no data change).
- Performance per card record: one `Employee.Get` (existing), at most one indexed read of table 50103 on key
  `EquipmentStatus` (only when Assigned), two `User.Get` with `SetLoadFields`. The part reads the equipment's entries
  filtered on "Equipment No." and sorted by "Entry No." descending; acceptable at equipment volumes (R3).

## Events
**Standard BC events: none.** No events report required.

Subscribed: none.

Published: **no new events, no signature changes.** The new UI and `GetActiveAssignment` contain no business rules,
so no IsHandled is needed. Partners can extend page 50101 and page 50105 with page extensions. Existing events
`OnBeforeInsertAssignment` / `OnBeforeCloseAssignment` (codeunit 50106) and the table 50100 events are unchanged;
fields partners add to table 50103 through those events can be added to the history part with a page extension.

## Permissions
- **EQM - Read (50100):** add `page "EQM Assignment History Part" = X`. It already grants
  `tabledata "EQM Equipment Assignment" = R`, `tabledata "EQM Equipment" = R`, `page "EQM Equipment Card" = X` and
  `codeunit "EQM Assignment Mgt." = X`, which cover everything else in FR-008.
- EQM - Edit (50101) and EQM - Admin (50102) include EQM - Read: no change.
- Employee read access for the name columns: still from D365 BASIC, same as FR-001/FR-004/FR-007 (existing TODO item,
  not changed here).
- User table: read access is checked with `ReadPermission()`; without it the two "By" fields stay blank instead of
  raising an error. No EQM set grants User read (R2).
- Help text (documenter): "Everyone with Equipment - Read can open the equipment card and see its history and audit
  information."

## Compatibility
- AppSource mode, development phase: nothing released, no baseline, no Obsolete handling needed.
- No public API change: `GetActiveAssignment` is `internal`; no existing procedure, event, field or key changes.
- New public object: page 50105 (pages are extensible by default; that is intended).
- Page 50101: new controls (`AssignedSince`, `AssignedBy`, `CreatedBy`, `LastModifiedBy`, part `AssignmentHistory`) are
  additive. Existing groups and controls keep their names, so partner page extensions anchored on them still compile.
  Removing `Importance = Additional` and adding `Importance = Promoted` change display only. Name clashes with partner
  controls of the same names are possible but unlikely, accepted.
- Doc references to update (documenter, not developer):
  - New `docs/features/FR-008-equipment-card.md` and `docs/help/FR-008-equipment-card.md`: sections of the card,
    Assigned Since / Assigned By, the Assignment History section (newest first, read-only, full list through
    Assignments), the Audit section (who/when created and last changed; blank "By" when the user was deleted, the
    record was written by the system, or you cannot read users).
  - `docs/help/FR-001-equipment-registration.md` (card section) and `docs/help/FR-006-assignment-history-tracking.md`
    (history on the card): short cross-references to FR-008.
  - CHANGELOG: section `## FR-008 Equipment Card (version stays 29.0.0.0, no bump)` at the top, plus a release-notes
    paragraph.
  - `docs/TODO.md`: add the manual sandbox checks listed under Test scenarios.
  - Historical plans are not edited.

## Test scenarios
**No automated tests in this iteration by default (Q5). No test codeunits, no `test/app.json` change. ID 50160 is
reserved and stays unused, and the tester step is skipped.** The list is the reference for the user, who writes the
tests later in test codeunit 50160 "EQM Equipment Card Tests" using `TestPage "EQM Equipment Card"` (the part is
reached through `EquipmentCard.AssignmentHistory`). The developer and reviewer use it to check behavior by reading the
code.

Test data, unless stated: active category C1; active employees P1 and P2. Equipment E1 (C1, Available, never
assigned). Equipment E2 (C1) assigned to P1 through `AssignEmployee` on work date D1, returned (`UnassignEmployee`,
`[ConfirmHandler]` Yes) on D2, then assigned to P2 on D3: two entries, entry 1 Closed (P1), entry 2 Active (P2).
Equipment E3 (C1) with one entry for P1, then status set to In Maintenance through validate + Modify(true) (confirm
Yes): one Closed entry, no employee.

General Information (C-R2 to C-R4)
- C1 Given E1, when the card is opened, then No., Description, Category Code, Serial No., Manufacturer, Model, Purchase
  Date, Purchase Cost, Status (Available) and Location Code show the stored values.
- C2 Given E2, when the card is opened, then Status = Assigned, Assigned Employee No. = P2, Assigned Employee Name = P2's
  `FullName()`, Assigned Since = D3 and Assigned By = the current user ID.
- C3 Given E1 (never assigned), when the card is opened, then Assigned Since and Assigned By are blank and no error is
  raised.
- C4 Given E3 (In Maintenance, history exists), when the card is opened, then Assigned Since and Assigned By are blank
  (the closed entry is not shown as current).
- C5 Given the card of E2 and then navigating to E1 (`Next`/`GoToRecord`), then E1's Assigned Since, Assigned By and
  Assigned Employee Name are blank (values from E2 are not reused).
- C6 Given E1 open on the card, when Assign to Employee is invoked and P1 is selected (`[ModalPageHandler]` on Employee
  List), then Assigned Since = work date and Assigned By = current user, without closing the card.
- C7 Given E2 open on the card, when Return is invoked (confirm Yes), then Status = Available and Assigned Since and
  Assigned By are blank.
- C8 Given an Assigned equipment whose active entry is missing (entry deleted in the test with `Delete(false)`), when
  the card is opened, then Assigned Since and Assigned By are blank and no error is raised.

Assignment history part (C-R5)
- C9 Given E2, when the card is opened, then the part shows exactly two rows: first row entry 2 (P2, Active, Assignment
  Date D3, Closing Date blank), second row entry 1 (P1, Closed, Assignment Date D1, Closing Date D2, Closed By current
  user).
- C10 Given E1, when the card is opened, then the part is empty and no error is raised.
- C11 Given E1 and E2, when the card of E1 is opened, then no entry of E2 is shown (link filter on Equipment No.).
- C12 Given E1 open on the card, when Assign to Employee is invoked for P1, then the part shows one Active row for P1
  without reopening the card.
- C13 Given E2 open on the card, when Return is invoked (confirm Yes), then the first row of the part is entry 2 with
  Status Closed and Closing Date = work date.
- C14 Given E2, when the part is shown, then the Employee Name of each row equals the employee's `FullName()`; given an
  entry whose employee no longer exists (removed with trigger-less writes in the test), the name is blank and no error
  is raised.
- C15 Given E2, when the user tries to edit, insert or delete a row in the part, then it is not possible (TestPage
  controls are not editable; new and delete are not allowed).
- C16 Given a new card (`OpenNew`) before the record is saved, then the part is empty and no error is raised.
- C17 Given E2, when the Assignments action is invoked (TestPage `Trap` on page 50104), then page 50104 opens filtered on
  E2 (regression).

Audit information (C-R6)
- C18 Given E1 created by the current user, when the card is opened, then Created Date = E1.SystemCreatedAt, Created By =
  the current user name, Last Modified Date = E1.SystemModifiedAt and Last Modified By = the current user name.
- C19 Given E1, when Description is changed on the card and the card is moved to another record and back, then Last
  Modified Date is updated and Last Modified By = the current user name.
- C20 Given a new card (`OpenNew`) before the record is saved, then Created Date, Created By, Last Modified Date and Last
  Modified By are blank and no error is raised.
- C21 Given an equipment record whose SystemCreatedBy refers to a user that does not exist in table User (not testable
  without system-field writes: manual check or skip), then Created By is blank and no error is raised.
- C22 (`TestPermissions = Restrictive`) Given a user with EQM - Read and D365 BASIC only, when the card of E2 is opened,
  then no permission error is raised, the part shows both entries, and Created By shows either the user name or blank
  depending on User read access (no error either way).
- C23 Given the card, when Show less is chosen (manual), then the Audit fields are still visible because they are no
  longer `Importance = Additional`.

Regression
- C24 Given the card of a new record, when Status is set to In Maintenance and the record is saved, then the record is
  created as in FR-003 (ValuesAllowed unchanged).
- C25 Given E2 on the card, when Status is set to Available, then the "use the Return action" error from FR-005 appears
  (OnValidate unchanged).
- C26 Given the Equipment action on page 50104 for a row of E2, when it is invoked, then card 50101 opens on E2 with the
  part filled.

Manual sandbox checks (for the user):
- The card shows the sections in order General, Assignment, Purchase, Assignment History, Audit; the Assignment FastTab
  header shows the Status when collapsed.
- The teaching tip appears the first time the card opens and the bold words render bold.
- Assign and Return refresh Assigned Since / Assigned By and the history part at once.
- Changing the Status of an Assigned card to In Maintenance or Lost refreshes the history (entry closed) after save.
- Created By / Last Modified By show user names (not GUIDs); a user without User read access sees them blank.
- After the build, `Equipment Management.g.xlf` contains the new page, captions, tooltips, AboutTitle and AboutText.

## Risks and open questions
Open questions (the plan follows the bold default):
- **Q1 Scope:** card 50101 already exists (FR-001) and covers most of C-R1 to C-R4. Build the delta in this plan, or close
  FR-008 as "already delivered, documentation only"? **Default: build the delta** (history on the card and full audit
  are real gaps).
- **Q2 What "audit information" covers:** **Default: record-level audit of the equipment (created at/by, last modified
  at/by) on the card, plus assignment-level audit (assigned/closed dates and users) in the history part.** Not
  included: a field-by-field change history (BC Change Log or own log table). Confirm, or ask for the change log as a
  separate feature.
- **Q3 Where the history is shown:** **Default: a ListPart section in the card body.** Alternative: a FactBox in the
  right pane (narrower, fewer columns visible).
- **Q4 Audit visibility:** **Default: show the Audit fields by default** (remove `Importance = Additional`), since the
  issue asks the card to display them. Alternative: keep them under "Show more".
- **Q5 Tests:** build test codeunit 50160 now, or defer like FR-003 to FR-007? **Default: defer.** The test app is still
  not set up (see `docs/TODO.md`); scenarios C1-C26 are kept as the reference.
- **Q6 Teaching tip on the card:** **Default: yes**, for consistency with the FR-007 list.

Risks:
- R1 "Assigned Since / Assigned By" come from the active entry. If the data were inconsistent (Assigned equipment
  without an active entry, possible only through trigger-less writes), the fields are blank rather than wrong. No repair
  logic is planned.
- R2 Resolving Created By / Last Modified By needs read access to the system table User. If a user lacks it, the fields
  stay blank (guarded by `ReadPermission()`), which could look like missing data. Help should explain it. Records
  written by the system or by deleted users also show blank.
- R3 The part reads all entries of the equipment. Volumes per equipment are small; no paging or limit is planned.
- R4 The "employee full name" code now exists on four pages (50100, 50101, 50104, 50105). Follow-up candidate: one
  internal helper (for example on codeunit 50106 or a small new codeunit). Not done here to keep FR-008 focused.
- R5 Employee name columns still need Employee read access from D365 BASIC (existing TODO item, unchanged).
- R6 No automated tests (Q5): regressions on the card are caught only by review and the manual sandbox checks.
