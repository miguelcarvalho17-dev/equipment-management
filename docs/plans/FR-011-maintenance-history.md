# FR-011 Equipment Maintenance History

> Status: REVISION 2. **Q1 is RESOLVED by the user.** User's words: "I want you create a historical maintenance
> table where you save it when you change status for Posted. Should be read only and shouldn't be able to delete
> records. All others question follow default answer." Q2 to Q8 take the revision 1 defaults. **Q2 was adjusted**,
> because the history now lives in its own table (see "Risks and open questions").
> Changes from revision 1:
> - new read-only table 50106 "EQM Maintenance History Entry", filled by posting;
> - new history list page 50117;
> - the Equipment Card history part (50116) reads from the history table;
> - table 50105 gets only the Status field. "Posted By" and "Posted At" move to the history entry.
>
> Source: GitHub issue #30, milestone V2. Branch: `feature/FR-011-maintenance-history` (cut from `main` after the
> FR-010 merge, commit 6c95efb).
> No events report. FR-011 changes only this app's own objects and subscribes to no standard events, so
> al-event-finder is not needed.
> Scope: main app only. There are **five new objects** (enum, table, codeunit, two pages), **one new field** on
> table 50105, and changes to six of the app's own objects plus two permission sets. **No version bump**
> (app.json stays 29.0.0.0) and **no upgrade logic.** Tests are deferred (Q8 default): test codeunit 50165 is
> reserved, and the tester step is skipped.
> Workflow for FR-011: planner -> (human approves plan) -> developer -> reviewer -> build -> **tester step SKIPPED
> (Q8)** -> documenter -> appsource-validator.

## Goal
Each piece of equipment has a complete maintenance history that users can see directly on the Equipment Card. The
history shows the date, type, vendor, cost and description of every posted maintenance. A maintenance record can be
corrected while it is Open. When the user posts it, the record is frozen and a copy is written to a separate
maintenance history table. Nobody can change or delete those history entries. This gives full traceability of what
was done to the equipment and what it cost.

### Requirement restated
- H-R1 Keep the complete maintenance history of each piece of equipment.
- H-R2 The history shows Maintenance Date, Maintenance Type, Vendor, Cost and Description.
- BR-H1 History entries are read-only once posted: no insert from outside posting, no modify, no rename, no delete.
  This holds for every role, including Administrator.
- BR-H2 The maintenance history can be opened directly from the Equipment Card.
- BR-H3 (user decision Q1) When a maintenance record is posted (Status Open -> Posted), it is saved into a new
  historical maintenance table.

### What FR-010 already built (reused, not duplicated)
| Already present (FR-010, merged in 6c95efb) | Use in FR-011 |
|---|---|
| Table 50105 "EQM Maintenance Record": all five issue fields plus "Equipment No.", "Vendor No.", "Performed By"; key `EquipmentDate`; delete and rename always refused; `CheckMaintenanceConsistency` + event `OnAfterCheckMaintenanceConsistency`. | **Source of the history entry.** It gets a Status field. Its rules are reused unchanged and run again at posting. |
| Equipment cannot be deleted while it has maintenance records (table 50100 `OnDelete` -> `HasMaintenanceRecords`). | Also protects history entries. Every history entry has a source record that is kept (see below), so no extra check is needed on table 50100. |
| Pages 50113 "EQM Maintenance Records" (list) and 50114 "EQM Maintenance Record Card". | Extended: Status, Post action, Open/Posted views, link to the history entry. |
| Page 50115 "EQM Maintenance FactBox" (count, last date/type, total cost of maintenance records). | Unchanged (Q3 default: it counts open and posted records). |
| Equipment Card actions **Register Maintenance** and **Maintenance**. | Kept. FR-011 adds **Maintenance History** next to them. |
| Codeunit 50108 "EQM Maintenance Mgt." (internal helpers, guarded `GetVendorName`). | Reused at posting (vendor name snapshot). Adds `PostWithConfirmation`. |
| Ledger-style pattern of table 50103 "EQM Equipment Assignment" (AutoIncrement "Entry No.", `ValidateTableRelation = false`, user ID fields as EndUserIdentifiableInformation, codeunit 50106 with `Permissions` + indirect rights in the Manager set). | Copied for table 50106 and codeunit 50109. |
| Page 50105 "EQM Assignment History Part" (read-only ListPart in the Equipment Card body). | Copied for page 50116. |

### What FR-011 adds
1. **Status Open/Posted on table 50105** and a **Post** action on the maintenance card and list. Open records behave
   exactly as in FR-010. A posted record is frozen.
2. **New table 50106 "EQM Maintenance History Entry"**. Posting creates exactly one entry per maintenance record. The
   entry holds a snapshot of the five issue fields plus equipment, vendor number and name, performed by, posted by,
   posted at and the source maintenance number. It is read-only for everybody.
3. **New list page 50117 "EQM Maintenance History"** (searchable under History) and **new ListPart 50116 "EQM
   Maintenance History Part"** in the Equipment Card body. Both read the history table.

### Decision: what happens to the source record after posting
**The source record in table 50105 is kept, frozen with Status = Posted. It is not removed.** Reasons:
- FR-010 BR-M2 says maintenance records are never deleted. `OnDelete` of 50105 always errors, and no role has D.
  Removing the record at posting would need a delete exception in 50105, which breaks that rule and its tests
  (FR-010 M15, M40, M41).
- The equipment delete guard (table 50100), the Maintenance FactBox and the maintenance list all read table 50105.
  If the source were kept, they would keep working unchanged. If it were removed, all three would have to be
  changed to read two tables.
- The number series and the "Maintenance No." the user saw stay valid. The history entry points back to it
  ("Maintenance No."), so the user can go from the entry to the record and back.
- Cost: one duplicated row per posted record. This is accepted, because the history entry is the immutable audit
  copy and the source is frozen by its Status.
- The frozen source is enforced in 50105 `OnModify` (stored Status = Posted -> error). The history entry is
  enforced in 50106 itself. Both stay read-only.

### Interpretation (defaults Q2-Q8)
- New records always start as Open and cannot be inserted as Posted. Posting runs only through codeunit 50109.
- A posted record never returns to Open, and there is no reversal (Q5). A wrong posted record stays. The user
  registers a new record to describe the correction.
- **Q2 (adjusted):** the Equipment Card history part and the history list show **posted entries only**. They read
  the history table, which holds only posted maintenance. Open records stay visible in the maintenance list (view
  Open), through the Maintenance action, and in the FactBox.
- Q3: the FactBox is unchanged. It counts and sums all maintenance records, open and posted.
- Q4: posting is allowed for records of Lost or Disposed equipment. Posting freezes work that already exists; it
  does not register new work.
- Q6: one record is posted at a time, from the card or from the list.
- Q7: no "Register and Post".
- Q8: automated tests deferred.

## Approach and rejected alternatives
- Chosen:
  - **Enum 50103 "EQM Maintenance Status"** (Open, Posted; `Extensible = false`, because code branches on the
    values) and field 11 Status on table 50105. `OnModify` refuses changes when the **stored** record is Posted.
    `OnInsert` refuses Status <> Open.
  - **Table 50106 "EQM Maintenance History Entry"**: ledger-style, AutoIncrement "Entry No.", all fields
    `Editable = false`. `OnInsert` errors unless the insert was enabled by an internal procedure that only codeunit
    50109 calls. `OnModify`, `OnDelete` and `OnRename` always error. No IsHandled.
  - **Permissions as a second lock:** no role gets direct I, M or D on table 50106. Manager gets indirect `i` only.
    Codeunit 50109 has `Permissions = tabledata "EQM Maintenance History Entry" = i`. Readers and Managers get R.
  - **Codeunit 50109 "EQM Maintenance-Post"** (`Access = Public`, `TableNo` 50105) does three things in one
    transaction:
    - sets the source to Posted (with `Modify(true)`, which reruns the FR-010 checks);
    - inserts the history entry;
    - raises three events.
  - **Pages:** the Equipment Card gets ListPart 50116 and a navigation action to the new list page 50117. The
    maintenance list and card get Status, a Post action and a link to the history entry.
- Rejected: deleting the source record after posting. It breaks FR-010 BR-M2 and needs changes to every page and
  check that reads 50105 (see "Decision" above).
- Rejected: Status on the record only, without a history table (revision 1). The user asked for a separate
  historical table (Q1).
- Rejected: a TableRelation on "Vendor No." in table 50106. A vendor rename in the base app would cascade into the
  history entries without running triggers. That would change frozen data, and it needs rights on 50106 that
  purchasing users do not have. The vendor number and **name** are stored as a snapshot instead.
- Rejected: copying with `TransferFields`. The field numbers of 50105 and 50106 differ by design, so the copy uses
  explicit field assignments.
- Rejected: an IsHandled event on posting or on the history-table locks. BR-H1 must not be bypassed by extensions.
- Rejected: a Reopen/Unpost action, even for Administrators. It contradicts "read-only once posted" (Q5).
- Rejected: posting logic in codeunit 50108. It is `Access = Internal`, so partners could not subscribe to the
  posting events.
- Rejected: Status, Posted By and Posted At all on 50105 (revision 1). The history entry now holds who posted and
  when. Keeping both would duplicate data that could disagree.

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50105, pages 50100-50115, codeunits 50103-50108,
queries 50100-50101, enums 50100-50102, page extension 50100, permission sets 50100-50102, permission set extension
50103, profile "EQM EQUIPMENT MANAGER". Test app: no objects. Test codeunits 50150-50164 are reserved by FR-001 to
FR-010, and none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50103 | EQM Maintenance Status | New | Open, Posted; `Extensible = false` |
| Table | 50106 | EQM Maintenance History Entry | New | Read-only snapshot of each posted maintenance record |
| Codeunit | 50109 | EQM Maintenance-Post | New | `Access = Public`, `TableNo` 50105; posts one record, writes the history entry; three publisher events |
| Page | 50116 | EQM Maintenance History Part | New | ListPart in the Equipment Card body, source table 50106 |
| Page | 50117 | EQM Maintenance History | New | Read-only list of all history entries, `UsageCategory = History` |
| Table | 50105 | EQM Maintenance Record | Modify (own) | Field 11 Status; insert and modify rules; `GetStatusStyle` |
| Codeunit | 50108 | EQM Maintenance Mgt. | Modify (own) | New `PostWithConfirmation` |
| Page | 50113 | EQM Maintenance Records | Modify (own) | Status column, Post, History Entry action, views Open/Posted, AboutText |
| Page | 50114 | EQM Maintenance Record Card | Modify (own) | Status, read-only when Posted, Post, History Entry action, AboutText |
| Page | 50101 | EQM Equipment Card | Modify (own) | Maintenance History part and action, AboutText |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | R on table 50106; X on the new table, pages and codeunit |
| PermissionSet | 50101 | EQM - Manager | Modify (own) | Indirect `i` on table 50106 only |

Not changed: tables 50100-50104; pages 50100, 50102-50112, 50115; codeunits 50103-50107; queries; enums
50100-50102; page extension 50100; permission set 50102 (inherits Manager; no direct rights on 50106);
permission set extension 50103; the profile; `app/app.json`; `test/`.
Folder: new files in `app/src/Maintenance/`:
- `EQMMaintenanceStatus.Enum.al`
- `EQMMaintenanceHistoryEntry.Table.al`
- `EQMMaintenancePost.Codeunit.al`
- `EQMMaintenanceHistoryPart.Page.al`
- `EQMMaintenanceHistory.Page.al`

Namespace `MiguelCarvalho.EquipmentManagement`, like all existing files.
Next free IDs after FR-011: tables 50107, pages 50118, codeunits 50110, queries 50102, enums 50104, page extensions
50101, permission sets 50104. Test app: test codeunit **50165 reserved for FR-011 "EQM Maintenance History Tests"**.

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report. Use a named fallback only where one is given, and report that you used it.
- Object names are at most 30 characters: "EQM Maintenance History Entry" (29), "EQM Maintenance History Part" (28),
  "EQM Maintenance History" (23), "EQM Maintenance-Post" (20), "EQM Maintenance Status" (22).
- A table key accepts `Unique = true` (key `MaintenanceNo` on 50106). Fallback: drop `Unique`. The duplicate check
  in codeunit 50109 step 2 still prevents a second entry.
- A page `group` accepts `Editable = <Boolean variable>`.
- `Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord)` passes the record by reference (`TableNo`), so
  the caller sees Status = Posted afterwards.
- A global variable of a table, set by a procedure called on a record variable, is still set when `Insert(true)` is
  called on that same variable and is readable in `OnInsert` (used for the insert lock on 50106).
- Image names `PostDocument`, `View`, `History`, `LedgerEntries` exist. Fallbacks: `Post` for PostDocument, `Card` for
  View, `History` for LedgerEntries.
- Style names `Ambiguous` and `Favorable` are valid `StyleExpr` values.

### Enum 50103 "EQM Maintenance Status" (new)
- `Caption = 'Maintenance Status'`; `Extensible = false`. `/// <summary>`: "Status of a maintenance record. Open
  records can be corrected. Posting a record freezes it and writes it to the maintenance history."
- Values: 0 Open (Caption 'Open'), 1 Posted (Caption 'Posted').

### Table 50106 "EQM Maintenance History Entry" (new)
Object properties: `Caption = 'Maintenance History Entry'`; `DataClassification = CustomerContent`;
`Access = Public`; `LookupPageId` and `DrillDownPageId` = "EQM Maintenance History";
`DataCaptionFields = "Maintenance No.", Description`.
`/// <summary>`: "Read-only maintenance history. One entry is written when a maintenance record is posted. Entries
cannot be created except by posting, and they can never be changed, renamed or deleted."

All fields have `Editable = false`.

| Field ID | Name | Type | Caption | Properties / ToolTip |
|---|---|---|---|---|
| 1 | "Entry No." | Integer | Entry No. | `AutoIncrement = true`. ToolTip 'Specifies the number of the maintenance history entry.' |
| 2 | "Maintenance No." | Code[20] | Maintenance No. | `TableRelation = "EQM Maintenance Record"."No."`; `ValidateTableRelation = false`. ToolTip 'Specifies the number of the maintenance record that was posted to create this entry.' |
| 3 | "Equipment No." | Code[20] | Equipment No. | `TableRelation = "EQM Equipment"."No."`; `ValidateTableRelation = false`. ToolTip 'Specifies the equipment the maintenance was performed on.' |
| 4 | "Maintenance Date" | Date | Maintenance Date | ToolTip 'Specifies the date the maintenance was performed.' |
| 5 | "Maintenance Type" | Enum "EQM Maintenance Type" | Maintenance Type | ToolTip 'Specifies the type of maintenance: Preventive, Corrective, Inspection or Upgrade.' |
| 6 | "Vendor No." | Code[20] | Vendor No. | **No TableRelation** (snapshot, see Approach). ToolTip 'Specifies the number of the vendor that performed the maintenance, as it was when the maintenance was posted.' |
| 7 | "Vendor Name" | Text[100] | Vendor Name | ToolTip 'Specifies the name of the vendor as it was when the maintenance was posted.' |
| 8 | Cost | Decimal | Cost | `AutoFormatType = 1`. ToolTip 'Specifies the cost of the maintenance in local currency.' |
| 9 | Description | Text[100] | Description | ToolTip 'Specifies a description of the maintenance work.' |
| 10 | "Performed By" | Text[100] | Performed By | ToolTip 'Specifies the name of the person or team that performed the maintenance.' |
| 11 | "Posted By" | Code[50] | Posted By | `DataClassification = EndUserIdentifiableInformation`. ToolTip 'Specifies the user who posted the maintenance.' |
| 12 | "Posted At" | DateTime | Posted At | ToolTip 'Specifies the date and time when the maintenance was posted.' |
| 13 | "Equipment Description" | Text[100] | Equipment Description | `FieldClass = FlowField`; `CalcFormula = lookup("EQM Equipment".Description where("No." = field("Equipment No.")))`. ToolTip 'Specifies the description of the equipment.' |

- Keys:
  - `PK` "Entry No." (Clustered);
  - `EquipmentDate` ("Equipment No.", "Maintenance Date") with `SumIndexFields = Cost`;
  - `MaintenanceNo` ("Maintenance No.") with `Unique = true`.
- Field groups:
  - `DropDown` = "Entry No.", "Equipment No.", "Maintenance Date", "Maintenance Type", Description;
  - `Brick` = "Equipment No.", "Maintenance Date", "Maintenance Type", Cost.
- Global variable `InsertFromPostingAllowed: Boolean`.

**Triggers**
- `OnInsert`:
  1. When not InsertFromPostingAllowed: Error(InsertNotAllowedErr).
  2. `TestField("Maintenance No.")`; `TestField("Equipment No.")`.
- `OnModify`: Error(ModifyNotAllowedErr, "Entry No."). Always.
- `OnDelete`: Error(DeleteNotAllowedErr, "Entry No."). Always.
- `OnRename`: Error(RenameNotAllowedErr, xRec."Entry No."). Always.

**Procedures**
- `internal procedure AllowInsertFromPosting()`: sets `InsertFromPostingAllowed := true`. Doc comment: "Enables the
  next insert on this record variable. Only the maintenance posting codeunit calls it."

**Labels**
- `InsertNotAllowedErr`: 'You cannot create maintenance history entries directly. Entries are created when you post a maintenance record.'
- `ModifyNotAllowedErr`: 'You cannot change maintenance history entry %1. The maintenance history is read-only.' Comment: '%1 = entry number'.
- `DeleteNotAllowedErr`: 'You cannot delete maintenance history entry %1. The maintenance history is kept permanently.' Comment: '%1 = entry number'.
- `RenameNotAllowedErr`: 'You cannot change the number of maintenance history entry %1.' Comment: '%1 = entry number'.

No events on this table. Partners use `OnBeforeInsertMaintenanceHistoryEntry` in codeunit 50109 to fill their own
fields.

### Table 50105 "EQM Maintenance Record" (change)
- New field `field(11; Status; Enum "EQM Maintenance Status")`: `Caption = 'Status'`; `Editable = false`.
  ToolTip 'Specifies whether the maintenance record is open or posted. You can correct an open record. Posting copies it to the maintenance history, and after that the record cannot be changed.'
- Update the table `/// <summary>`: "One record per maintenance activity performed on equipment. Maintenance cannot be
  registered for Lost or Disposed equipment. Open records can be corrected. Posting freezes the record and writes a
  maintenance history entry. Records are never deleted, so equipment that has maintenance records cannot be deleted
  either."
- `OnInsert`: add this check after the number-series block and the default date, before
  `CheckMaintenanceConsistency(true)`: when Status <> Status::Open: Error(InsertPostedErr, "No.").
- `OnModify`: call new local `CheckNotPosted()` **before** `CheckMaintenanceConsistency(false)`.
- `OnDelete`, `OnRename`, `CheckMaintenanceConsistency` and its event: unchanged.
- `local procedure CheckNotPosted()`:
  - Local `StoredRecord: Record "EQM Maintenance Record"`; `SetLoadFields(Status)`.
  - When `StoredRecord.Get("No.")` and StoredRecord.Status = Posted: Error(PostedRecordCannotBeChangedErr, "No.").
  - Use the stored record, never xRec. xRec is not reliable on `Modify` from code.
  - This allows the single Open-to-Posted modify done by codeunit 50109.
- `internal procedure GetStatusStyle(): Text`: `case` on Status. Open -> `AmbiguousStyleTok`, Posted ->
  `FavorableStyleTok`, `else` -> `StandardStyleTok`. Doc comment: "Returns the style name used to show the status
  on pages."
- New labels:
  - `PostedRecordCannotBeChangedErr`: 'You cannot change maintenance record %1 because it is posted. Posted maintenance is part of the maintenance history and is read-only.' Comment: '%1 = maintenance record number'.
  - `InsertPostedErr`: 'Maintenance record %1 must be registered as open. Register the record first, and then post it.' Comment: '%1 = maintenance record number'.
  - `AmbiguousStyleTok: Label 'Ambiguous', Locked = true;` `FavorableStyleTok: Label 'Favorable', Locked = true;`
    `StandardStyleTok: Label 'Standard', Locked = true;`

### Codeunit 50109 "EQM Maintenance-Post" (new)
- `Access = Public`; `TableNo = "EQM Maintenance Record"`;
  `Permissions = tabledata "EQM Maintenance History Entry" = i;`.
- There is no permission for table 50105. Posting needs the user's own M on 50105, so Readers fail before anything
  is written.
- `/// <summary>`: "Posts a maintenance record: freezes it and writes a read-only maintenance history entry. Run it
  with Codeunit.Run on the record. It shows no dialogs."

`OnRun` (Rec = the maintenance record), in this order:
1. Local `StoredRecord: Record "EQM Maintenance Record"`; `StoredRecord.ReadIsolation := IsolationLevel::UpdLock`;
   `SetLoadFields(Status)`. When not `StoredRecord.Get(Rec."No.")`: Error(RecordNotSavedErr, Rec."No.").
   When StoredRecord.Status = Posted: Error(AlreadyPostedErr, Rec."No.").
2. Local `MaintenanceHistoryEntry: Record "EQM Maintenance History Entry"`; `SetCurrentKey("Maintenance No.")`;
   `SetRange("Maintenance No.", Rec."No.")`. When `not IsEmpty()`: Error(AlreadyPostedErr, Rec."No.").
3. `OnBeforePostMaintenanceRecord(Rec)`.
4. `Rec.Status := Rec.Status::Posted`; `Rec.Modify(true)`. This runs `CheckNotPosted`, which passes because the
   stored record is Open. It also runs `CheckMaintenanceConsistency(false)`: equipment exists and is unchanged, the
   date is not later than today, and the cost is >= 0. The equipment status is not checked (Q4).
5. Call local `InsertHistoryEntry(Rec, MaintenanceHistoryEntry)`:
   1. `MaintenanceHistoryEntry.Init()`.
   2. Copy by assignment: "Maintenance No." := Rec."No."; "Equipment No."; "Maintenance Date"; "Maintenance Type";
      "Vendor No."; Cost; Description; "Performed By".
   3. "Vendor Name" := `MaintenanceMgt.GetVendorName(Rec."Vendor No.")` (codeunit 50108; blank without Vendor
      read, R4).
   4. "Posted By" := `CopyStr(UserId(), 1, MaxStrLen(...))`; "Posted At" := `CurrentDateTime()`.
   5. `OnBeforeInsertMaintenanceHistoryEntry(MaintenanceHistoryEntry, Rec)`.
   6. `MaintenanceHistoryEntry.AllowInsertFromPosting()`; `MaintenanceHistoryEntry.Insert(true)`.
6. `OnAfterPostMaintenanceRecord(Rec, MaintenanceHistoryEntry)`.

There is no `Commit`. An error at any step rolls back both the status change and the entry.

Labels:
- `RecordNotSavedErr`: 'You cannot post maintenance record %1 because it has not been saved.' Comment: '%1 = maintenance record number'.
- `AlreadyPostedErr`: 'Maintenance record %1 is already posted.' Comment: '%1 = maintenance record number'.

### Codeunit 50108 "EQM Maintenance Mgt." (change)
- Add `internal procedure PostWithConfirmation(var MaintenanceRecord: Record "EQM Maintenance Record"): Boolean`:
  1. When `not Confirm(PostQst, true, MaintenanceRecord."No.")`: exit(false).
  2. `Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord)`. Do not use the return value, so errors
     reach the user.
  3. exit(true).
- Doc comment: "Asks the user to confirm, then posts the maintenance record. Returns false when the user cancels."
- Label `PostQst`: 'Do you want to post maintenance record %1? It is copied to the maintenance history, and after that you cannot change it.' Comment: '%1 = maintenance record number'.
- Add `internal procedure ShowHistoryEntries(EquipmentNo: Code[20])`: runs page 50117 with a record filtered on
  "Equipment No.", the same shape as `ShowMaintenanceRecords`.
- Update the codeunit `/// <summary>`: "Read helpers for maintenance records shown on equipment pages, and the
  confirmation before posting."

### Page 50116 "EQM Maintenance History Part" (new)
- Properties: `Caption = 'Maintenance History'`; `PageType = ListPart`; `ApplicationArea = All`;
  `SourceTable = "EQM Maintenance History Entry"`.
- `SourceTableView = sorting("Equipment No.", "Maintenance Date") order(descending)`: newest date first, and on equal
  dates the highest "Entry No." first.
- `Editable = false`; `InsertAllowed = false`; `ModifyAllowed = false`; `DeleteAllowed = false`. No `UsageCategory`.
- Layout: `repeater(History)`, in this order:
  - "Entry No." (`Visible = false`);
  - "Maintenance Date";
  - "Maintenance Type";
  - "Vendor No.";
  - "Vendor Name";
  - Cost;
  - Description;
  - "Performed By" (`Visible = false`);
  - "Maintenance No." (`Visible = false`);
  - "Posted By" (`Visible = false`);
  - "Posted At" (`Visible = false`).

  All values are stored fields, so the page needs no variables or triggers.
- Actions, `area(Processing)`: action `ShowMaintenanceRecord`: `Caption = 'Show Maintenance Record'`,
  `ToolTip = 'Open the posted maintenance record that this history entry was created from.'`, `Image = View`,
  `RunObject = page "EQM Maintenance Record Card"`, `RunPageLink = "No." = field("Maintenance No.")`.

### Page 50117 "EQM Maintenance History" (new)
Properties:
- `Caption = 'Maintenance History'`; `PageType = List`; `ApplicationArea = All`; `UsageCategory = History`.
- `AdditionalSearchTerms = 'posted maintenance, maintenance history entries, maintenance costs, equipment service history'`.
- `SourceTable = "EQM Maintenance History Entry"`; `SourceTableView = sorting("Entry No.") order(descending)`.
- `Editable = false`; `InsertAllowed = false`; `ModifyAllowed = false`; `DeleteAllowed = false`.
- `AboutTitle = 'About the maintenance history'`.
- `AboutText = 'This list shows every maintenance that was posted, with its date, type, vendor and cost. An entry is created when you post a maintenance record. Entries cannot be changed or deleted, so the history stays complete. Choose a view at the top to see one maintenance type.'`

Layout: `repeater(Entries)`, in this order:
- "Entry No." (`Visible = false`);
- "Maintenance Date";
- "Equipment No.";
- "Equipment Description";
- "Maintenance Type";
- Description;
- "Vendor No.";
- "Vendor Name";
- "Performed By";
- Cost;
- "Maintenance No.";
- "Posted By";
- "Posted At".

`area(FactBoxes)`: `part(EquipmentFactBox; "EQM Equipment FactBox")` with
`SubPageLink = "No." = field("Equipment No.")`; `systempart(Links; Links)` with `Visible = false`;
`systempart(Notes; Notes)`.

Actions:
- `area(Navigation)`:
  - action `Equipment` (same as on page 50113);
  - action `MaintenanceRecord`: `Caption = 'Maintenance Record'`, `ToolTip = 'Open the posted maintenance record
    that this entry was created from.'`, `Image = View`, `RunObject = page "EQM Maintenance Record Card"`,
    `RunPageLink = "No." = field("Maintenance No.")`.
- `area(Promoted)`: `group(Category_Category4)`, `Caption = 'Navigate'`, with both actionrefs.

Views (after `actions`): `Preventive`, `Corrective`, `Inspection`, `Upgrade`, the same as on page 50113.

### Page 50101 "EQM Equipment Card" (change)
- `area(Content)`: add `part(MaintenanceHistory; "EQM Maintenance History Part")`, `Caption = 'Maintenance History'`,
  `SubPageLink = "Equipment No." = field("No.")`. Place it directly after `part(AssignmentHistory ...)` and before
  `group(Audit)`.
- `group(EquipmentGroup)` in `area(Navigation)`: add after `Maintenance` an action `MaintenanceHistory`:
  - `Caption = 'Maintenance History'`;
  - `ToolTip = 'View the posted maintenance history of the equipment.'`;
  - `Image = LedgerEntries`; `Enabled = IsSaved`;
  - `RunObject = page "EQM Maintenance History"`; `RunPageLink = "Equipment No." = field("No.")`.

  Add `actionref(MaintenanceHistory_Promoted; MaintenanceHistory)` in `Category_Category4` after
  `Maintenance_Promoted`.
- `AboutText` becomes: 'Here you manage one piece of equipment. The first sections show its details, its current status and who it is assigned to. Use **Assign to Employee** and **Return** to change the assignment, and **Register Maintenance** to record maintenance work. Further down, **Assignment History** lists every assignment, **Maintenance History** lists every posted maintenance, and **Audit** shows who created the record and who changed it last.'
- Nothing else changes.

### Page 50114 "EQM Maintenance Record Card" (change)
- `group(General)` and `group(Execution)`: add `Editable = IsOpen`. Add field Status at the end of General, with
  `Importance = Promoted` and `StyleExpr = StatusStyle`.
- New `area(Processing)`: action `Post`:
  - `Caption = 'Post'`;
  - `ToolTip = 'Post the maintenance record. It is copied to the maintenance history, and after that it cannot be changed or deleted.'`;
  - `Image = PostDocument`; `ShortCutKey = 'F9'`; `Enabled = CanPost`;
  - `OnAction`: `CurrPage.SaveRecord()`, then when `MaintenanceMgt.PostWithConfirmation(Rec)`:
    `CurrPage.Update(false)`.
- `area(Navigation)`: add action `HistoryEntry`:
  - `Caption = 'History Entry'`;
  - `ToolTip = 'View the maintenance history entry that was created when the record was posted.'`;
  - `Image = LedgerEntries`; `Enabled = not IsOpen`;
  - `RunObject = page "EQM Maintenance History"`; `RunPageLink = "Maintenance No." = field("No.")`.
- `area(Promoted)`: new `group(Category_Process)`, `Caption = 'Process'`, with `actionref(Post_Promoted; Post)`,
  placed **before** `Category_Category4`. Add `actionref(HistoryEntry_Promoted; HistoryEntry)` to
  `Category_Category4`.
- `AboutText` becomes: 'Register maintenance that was done on equipment. Choose the equipment, the date and the type of maintenance, and add the vendor, the cost and who did the work. You cannot register maintenance for lost or disposed equipment. You can correct the record until you choose **Post**. Posting copies it to the maintenance history, and after that it cannot be changed. Maintenance records can never be deleted.'
- `var`: add `IsOpen: Boolean`, `CanPost: Boolean`, `StatusStyle: Text`.
- `UpdateControls()`:
  - add `IsOpen := Rec.Status = Rec.Status::Open;`
  - add `CanPost := (not IsNewRecord) and IsOpen;`
  - add `StatusStyle := Rec.GetStatusStyle();`
  - keep the existing lines.

### Page 50113 "EQM Maintenance Records" (change)
- Repeater: add Status after Cost, with `StyleExpr = StatusStyle`.
- New `area(Processing)`: action `Post` with the same Caption, ToolTip, Image and ShortCutKey as on the card, and
  `Enabled = CanPost`. `OnAction`: when `MaintenanceMgt.PostWithConfirmation(Rec)`: `CurrPage.Update(false)`. It
  posts the current row only (Q6).
- `area(Navigation)`: add action `HistoryEntry`, the same as on the card, with `Enabled = CanShowHistoryEntry`.
- `area(Promoted)`: new `group(Category_Process)`, `Caption = 'Process'`, with `Post_Promoted`, placed before
  `Category_Category4`. Add `HistoryEntry_Promoted` to `Category_Category4`.
- Views: after `Upgrade`, add:
  - `view(OpenRecords)` (`Caption = 'Open'`, `Filters = where(Status = const(Open))`);
  - `view(PostedRecords)` (`Caption = 'Posted'`, `Filters = where(Status = const(Posted))`).
- `AboutText` becomes: 'This list shows the maintenance work done on your equipment: when, what type, by whom and at what cost. Choose **New** to register maintenance and **Post** when a record is final. Posting copies the record to the maintenance history and locks it. No record can be deleted. Choose a view at the top to see one maintenance type, or only open or posted records.'
- `var`: add `StatusStyle: Text`, `CanPost: Boolean`, `CanShowHistoryEntry: Boolean`, and a global
  `MaintenanceMgt: Codeunit "EQM Maintenance Mgt."` that replaces the local one in `OnAfterGetRecord`.
- `OnAfterGetRecord`: add `StatusStyle := Rec.GetStatusStyle()`.
- New trigger `OnAfterGetCurrRecord`:
  - `CanPost := (Rec."No." <> '') and (Rec.Status = Rec.Status::Open);`
  - `CanShowHistoryEntry := Rec.Status = Rec.Status::Posted`.

### Permission sets
- `EQM - Reader` (50100): add
  - `tabledata "EQM Maintenance History Entry" = R`;
  - `table "EQM Maintenance History Entry" = X`;
  - `page "EQM Maintenance History Part" = X`;
  - `page "EQM Maintenance History" = X`;
  - `codeunit "EQM Maintenance-Post" = X`.
- `EQM - Manager` (50101): add `tabledata "EQM Maintenance History Entry" = i` (lowercase: indirect insert only,
  effective inside codeunit 50109).

### app.json, translations
- **app.json: no change.** The version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf`. Commit it, and never edit it by hand.

## Data model and upgrade impact
- New table 50106 (13 fields, one FlowField, three keys, SumIndexFields Cost). New enum 50103. New field 11 Status on
  table 50105 (ordinal 0 = Open).
- DataClassification: CustomerContent at table level for 50106. "Posted By" is EndUserIdentifiableInformation.
  Status inherits CustomerContent from 50105. "Performed By" and "Vendor Name" are free-text names (R5).
- Existing records (development and sandbox only, because FR-010 is not released) get Status = Open and no history
  entry. They can be posted like any new record. No data change is needed.
- Upgrade codeunit: **not needed.** Nothing is released, and the version stays 29.0.0.0.
- Volume: at most one history entry per maintenance record. The entries are never deleted. The Equipment Card part
  reads one equipment through the `EquipmentDate` key. The duplicate check uses the `MaintenanceNo` key.

## Events
**Standard BC events: none.** No events report is required. Subscribed: none.

Published (codeunit 50109, `[IntegrationEvent(false, false)]`, `local`, with XML doc comments; same shape as codeunit
50106). None has IsHandled.
- `OnBeforePostMaintenanceRecord(var MaintenanceRecord: Record "EQM Maintenance Record")`.
  - Raised after the checks that the record is saved, Open and not yet in the history, and before the status
    changes.
  - Raise an error to stop posting, for example when a vendor is required for Corrective. You can fill fields your
    extension added. Do not change the standard fields.
- `OnBeforeInsertMaintenanceHistoryEntry(var MaintenanceHistoryEntry: Record "EQM Maintenance History Entry"; MaintenanceRecord: Record "EQM Maintenance Record")`.
  - Raised after all standard fields of the entry are filled, just before the insert.
  - Partners fill the fields their extensions added to 50106. Do not change the standard fields.
- `OnAfterPostMaintenanceRecord(MaintenanceRecord: Record "EQM Maintenance Record"; MaintenanceHistoryEntry: Record "EQM Maintenance History Entry")`.
  - Both parameters are passed by value.
  - Raised after the status change and the insert. Use it for follow-up work. Subscribers must not commit.
- The existing `OnAfterCheckMaintenanceConsistency` (table 50105) is unchanged. It is also raised during posting
  with Status = Posted.
- There is no IsHandled anywhere: BR-H1 and the posting rules cannot be bypassed.

## Permissions
- **EQM - Reader:** R on 50106 and X on the new objects. Readers can see the history part and list. Posting fails
  with a permission error on 50105 (no M) before anything is written.
- **EQM - Manager:** `i` on 50106 (indirect). Managers post through codeunit 50109 only. They cannot insert, modify
  or delete history entries directly (no I/M/D), and the table triggers refuse it anyway.
- **EQM - Administrator:** no change. It inherits Manager, so it also has **no** direct I/M/D on 50106 and cannot
  change posted maintenance.
- Permission set extension 50103: no change.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See Maintenance History (card part, list) | yes | yes | yes |
| Register and correct an open record | no | yes | yes |
| Post a record (creates the history entry) | no (permission error) | yes | yes |
| Change a posted record | no | no (business error) | no (business error) |
| Insert, change, rename or delete a history entry directly | no | no | no |

## Compatibility
- AppSource mode, development phase: nothing is released, there is no baseline, and no Obsolete handling is needed.
- New public surface that becomes a contract after the first release:
  - table 50106 (fields, keys, Unique key);
  - enum 50103 (not extensible; can become extensible later, but not the reverse);
  - field 11 on table 50105;
  - codeunit 50109 (`OnRun`) and its three events;
  - pages 50116 and 50117;
  - the new actions and views on pages 50101, 50113 and 50114.
- `AllowInsertFromPosting` (50106), `GetStatusStyle` (50105), `PostWithConfirmation` and `ShowHistoryEntries` (50108)
  are `internal`.
- **Behavior change to FR-010:**
  - A maintenance record can be corrected only while it is Open. After posting, `Modify` raises
    `PostedRecordCannotBeChangedErr` for every role.
  - A record cannot be inserted as Posted.
  - FR-010 scenarios M24, M28 and M12e still hold for Open records.
- Equipment Card: a new part and a new action. No existing control, action or group is renamed or moved.
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-011-maintenance-history.md` and `docs/help/FR-011-maintenance-history.md`: posting, the
    history table, what is locked, no reversal, the Equipment Card part, the history list, roles.
  - `docs/features|help/FR-010-maintenance-registration.md`: corrections only until posted.
  - `docs/features|help/FR-008-equipment-card.md`: Maintenance History section and action.
  - `docs/features|help/NFR-002-role-based-access.md`: matrices.
  - `CHANGELOG.md`: new top section `## FR-011 Equipment Maintenance History (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-011 sandbox checks" with HS-SB1 to HS-SB12.

## Test scenarios
**No automated tests in this iteration** (Q8 default, as in FR-010). Test codeunit 50165 "EQM Maintenance History
Tests" is reserved, and the tester step is skipped. The list is the reference for the developer and reviewer and for
the tests the user writes later. Writing them needs the test-app fix in `docs/TODO.md` first.

Test data, unless stated:
- setup with "Maintenance Nos." = a fresh series;
- equipment E1 (Available), E2 (Available, later Disposed), E3 (no maintenance);
- vendor V1 (Name 'Fix Ltd.').

"Register" means Init, Validate, then `Insert(true)`. "Post" means
`Codeunit.Run(Codeunit::"EQM Maintenance-Post", Record)`. After an expected error, assert that the stored record is
unchanged and that no history entry was added.

Status and posting (BR-H3)
- H1 Given a record registered for E1, then Status = Open, and no history entry exists for its "No.".
- H2 Given an Open saved record for E1 with vendor V1, when it is posted, then:
  - Status = Posted;
  - exactly one history entry exists, with "Maintenance No." = record no.;
  - the entry has the same Equipment No., Maintenance Date, Maintenance Type, Vendor No., Cost, Description and
    Performed By as the record, and Vendor Name = 'Fix Ltd.';
  - "Posted By" = `UserId()`;
  - "Posted At" lies between the times taken just before and just after the call.
- H3 Given two records posted one after the other, then their entries have increasing "Entry No.".
- H4 (negative) Given a new record with Status := Posted by direct assignment, when `Insert(true)` is called, then
  `InsertPostedErr` is raised, no record exists and no entry exists.
- H5 (negative) Given a posted record, when each editable field (date, type, vendor, cost, description, performed by)
  is changed in turn and `Modify(true)` is called, then `PostedRecordCannotBeChangedErr` is raised every time. Both
  the record and its history entry are unchanged.
- H6 (negative) Given a posted record, when Status := Open and `Modify(true)` is called, then
  `PostedRecordCannotBeChangedErr` is raised.
- H7 (negative) Given a posted record, when it is posted again, then `AlreadyPostedErr` is raised and there is still
  exactly one entry.
- H8 (negative) Given an Open record that already has a history entry (entry inserted by test code with
  `AllowInsertFromPosting`), when the record is posted, then `AlreadyPostedErr` is raised and its Status stays Open.
- H9 (negative) Given a record initialized with "No." 'NOTSAVED' and never inserted, when it is posted, then
  `RecordNotSavedErr` is raised.
- H10 (negative) Given an Open record whose Cost was set to -1 with `Modify(false)`, when it is posted, then
  `NegativeCostErr` is raised, Status stays Open and no entry exists (rollback). Do the same with a future date and
  expect `FutureDateErr`.
- H11 Given an Open record for E2, and E2 then set to Disposed, when the record is posted, then it is posted and the
  entry is created (Q4).
- H12 Given an Open record, when Description and Cost are changed with `Modify(true)`, then the changes are saved
  (FR-010 regression).
- H13 Given a posted record, then posting did not change the equipment status.
- H14 Given a posted record, when V1 is renamed or its name is changed afterwards, then the history entry still shows
  the old "Vendor No." and "Vendor Name" (snapshot).

History table is read-only (BR-H1)
- H15 (negative) Given a user with all rights (SUPER), when a history entry is inserted with `Insert(true)` without
  `AllowInsertFromPosting`, then `InsertNotAllowedErr` is raised and no entry exists.
- H16 (negative) Given a history entry and SUPER, when Cost is changed and `Modify(true)` is called, then
  `ModifyNotAllowedErr` is raised and the entry is unchanged.
- H17 (negative) Given a history entry and SUPER, when `Delete(true)` is called, then `DeleteNotAllowedErr` is raised
  and the entry still exists.
- H18 (negative) Given a history entry and SUPER, when `Rename` is called, then `RenameNotAllowedErr` is raised.
- H19 Given a posted record (source), when `Delete(true)` is called, then `MaintenanceCannotBeDeletedErr` is raised.
  When E1 (which has posted maintenance) is deleted, then `DeleteMaintenanceExistsErr` is raised (regression).
- H20 Given pages 50116 and 50117 (TestPage), then New, Edit and Delete are not available and no field is editable.

Events
- H21 Given a manual subscriber to `OnBeforePostMaintenanceRecord` that raises an error when Type = Corrective and
  "Vendor No." is blank, when such a record is posted, then the error is raised, Status stays Open and no entry
  exists. A Preventive record without a vendor is posted.
- H22 Given subscribers that count calls:
  - on a successful post, OnBefore, OnBeforeInsert and OnAfter each run once, in that order;
  - on `AlreadyPostedErr`, none of them runs;
  - on a consistency failure (H10), only OnBefore runs.
- H23 Given a subscriber to `OnAfterPostMaintenanceRecord`, then it receives the record with Status = Posted and the
  entry with "Entry No." > 0 and the same "Maintenance No.".
- H24 Given a subscriber to `OnAfterCheckMaintenanceConsistency`, when a record is posted, then it is raised once
  with Status = Posted.

Equipment Card and pages (BR-H2, H-R2)
- H25 Given E1 with three records dated D1 < D2 < D3, where D1 and D3 are posted and D2 is Open, plus one posted
  record for E3, when the Equipment Card of E1 is opened, then:
  - the Maintenance History part shows exactly two rows, D3 then D1;
  - each row shows Maintenance Date, Maintenance Type, Vendor No., Vendor Name, Cost and Description;
  - the Open D2 record and the E3 record are not shown (Q2 adjusted).
- H26 Given two posted E1 entries on the same date, then the higher "Entry No." is shown first.
- H27 Given E3 without posted maintenance, and a new unsaved Equipment Card, then the part is empty and no error is
  raised.
- H28 Given a row in the part, when Show Maintenance Record is invoked, then the maintenance card opens on the source
  record, read-only, with Post disabled.
- H29 Given the Equipment Card of E1, when Maintenance History is invoked, then page 50117 opens filtered on E1. On a
  new unsaved card, the action is disabled.
- H30 Given a saved Open record on the maintenance card, then Post is enabled and History Entry is disabled. When Post
  is invoked and the confirm is answered Yes, then Status = Posted, the General and Vendor and Cost groups are
  read-only, Post is disabled, and History Entry opens page 50117 showing just that entry.
- H31 (negative) Given the same, when the confirm is answered No, then nothing changes and no entry exists.
- H32 Given a new unsaved maintenance card, then Post is disabled.
- H33 Given the maintenance list, when Post is invoked on an Open row (Yes), then only that row is posted. On a Posted
  row, Post is disabled and History Entry is enabled.
- H34 Given the list, when the views Open and Posted are selected, then only those statuses are shown. On page 50117,
  the type views filter by type.
- H35 Given a record edited on the card but not yet saved, when Post is invoked, then the edit is saved first and
  appears in the history entry.
- H36 Given E1 with Open and Posted records, then the Maintenance FactBox count and total include both (Q3
  regression).
- H37 Given Open and Posted rows, then the Status style is Ambiguous and Favorable.

Permissions (`TestPermissions = Restrictive`, with D365 BASIC)
- H38 Reader: can open the Equipment Card part, page 50117 and the maintenance pages. Posting raises a permission
  error, Status stays Open and no entry exists. A direct insert into 50106 raises a permission error.
- H39 Manager:
  - can post (the entry is created through the indirect `i`);
  - a direct `Insert`, `Modify` or `Delete` on 50106 fails. Accept either the platform permission error or the
    table error, and note which one the platform raises;
  - changing a posted record raises `PostedRecordCannotBeChangedErr`.
- H40 Administrator: same as Manager, with no bypass.

### Manual sandbox checks (for the user)
- HS-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings. `.g.xlf` contains the new captions,
  ToolTips, labels and AboutTexts.
- HS-SB2 The Equipment Card shows the Maintenance History FastTab after Assignment History, newest first, with posted
  entries only. Related > Equipment > Maintenance History opens page 50117 filtered.
- HS-SB3 Post from the maintenance card with F9 and with the action. After confirming, the record is read-only, an
  entry appears in page 50117, and returning to the Equipment Card shows it in the part (record whether a refresh
  is needed; R6).
- HS-SB4 Post from the list on the current row. The Open and Posted views work. History Entry opens the right entry.
- HS-SB5 A **non-SUPER Manager** can post: the indirect `i` works and there is no permission error. A non-SUPER
  Reader gets a permission error.
- HS-SB6 Pages 50116 and 50117 offer no New, Edit or Delete for any role, including Administrator.
- HS-SB7 Tell Me finds "Maintenance History" (also with "posted maintenance" and "maintenance costs") under History.
  The teaching tips show the new text.
- HS-SB8 Existing development records show as Open after publishing and can be posted.
- HS-SB9 **Rename equipment that has history entries as a non-SUPER Manager and as an Administrator.** Record whether
  the entries follow the new number and whether a permission error on 50106 appears (R2).
- HS-SB10 Rename a vendor used in posted maintenance as a non-EQM user: no error, and the entries keep the old vendor
  number and name.
- HS-SB11 A posting user without Vendor read: posting works and the entry's Vendor Name is blank (R4).
- HS-SB12 An error during posting (for example, a future date set by data) leaves no entry and the record stays Open.

## Risks and open questions
Resolved decisions:
- **Q1 What "posted" means: RESOLVED (user, revision 2).** Open/Posted status on 50105 and a Post action. Posting
  copies the record into the new read-only table 50106, which nobody can change or delete. The source record is kept,
  frozen (see "Decision").
- **Q2 What the history part shows: RESOLVED, adjusted from the default.** The default was "all records with a status
  column". It is now **posted entries only**, because the part reads the history table, which by the user's decision
  holds only posted maintenance. Open records stay visible in the maintenance list and the FactBox.
- **Q3 FactBox totals: RESOLVED (default).** Unchanged: it covers all maintenance records.
- **Q4 Posting for Lost or Disposed equipment: RESOLVED (default).** Allowed.
- **Q5 Correcting posted maintenance: RESOLVED (default).** Impossible. There is no reopen or reversal, and the user
  registers a new record instead.
- **Q6 Batch posting: RESOLVED (default).** One record at a time.
- **Q7 Register and Post: RESOLVED (default).** Not added.
- **Q8 Automated tests: RESOLVED (default).** Deferred. Test codeunit 50165 is reserved, and the tester step is
  skipped.

Still open: none blocking.

Risks:
- R1 Writes that skip triggers (`Insert(false)`, `Modify(false)`, `ModifyAll`, `DeleteAll`) by code running with
  direct rights (SUPER or another app's elevated permissions) can still bypass the table locks. EQM roles have no
  direct I/M/D on 50106, so EQM users cannot. Document this in the help.
- R2 Renaming equipment cascades the new number into "Equipment No." of 50106 (TableRelation) without running
  triggers. This is wanted, because the history follows the equipment. But it is **unverified** whether the platform
  needs direct M on 50106 for the renaming user. If it does, the rename fails with a permission error for Manager and
  Administrator (HS-SB9). The follow-up options need user approval:
  - block equipment rename when maintenance exists;
  - or remove the TableRelation and keep the snapshot number.
- R3 Vendor deletion or rename does not touch the history (snapshot, no TableRelation). As before, it can still
  cascade into table 50105 (FR-010 R3).
- R4 The Vendor Name snapshot is blank when the posting user has no Vendor read (no D365 BASIC). It cannot be fixed
  later, because the entry is read-only.
- R5 "Posted By" (user ID), "Performed By" and "Vendor Name" can hold personal names. They join the open TODO item on
  personal-data classification.
- R6 The Equipment Card parts may not refresh after posting from another page (HS-SB3). This is accepted. The data is
  correct, and a refresh shows it.
- R7 Posting locks the source record with `UpdLock`. If two users post the same record at the same time, the second
  gets `AlreadyPostedErr` or the platform's "changed by another user" error. Accepted.
- R8 The platform behaviors listed under "Platform names" (Unique key, group Editable expression, table global kept
  through Insert, image and style names) are not verified at planning time.
- R9 There are no automated tests (Q8), so regressions are caught only by review and the sandbox checks.

## Implementation notes
- Equipment Card (50101): the navigation action is named `ShowMaintenanceHistory` (actionref `ShowMaintenanceHistory_Promoted`), not `MaintenanceHistory`, because the part already uses the control name `MaintenanceHistory`. The caption is unchanged ("Maintenance History").
- Codeunit 50108: `ShowHistoryEntries` was dropped. Nothing calls it, because the pages use `RunObject` with `RunPageLink`.
- Codeunit 50109 `Permissions` is `tabledata "EQM Maintenance History Entry" = ri` (read needed for the duplicate check). The `InsertFromPostingAllowed` lock on table 50106 is one-shot: `OnInsert` resets it after the check.
- Test H8 (insert an entry with `AllowInsertFromPosting`) calls an `internal` procedure from the test app. The main app needs an `internalsVisibleTo` entry for the test app in app.json before that test can compile. app.json is not changed in FR-011.
