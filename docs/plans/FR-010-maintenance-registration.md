# FR-010 Maintenance Registration

> Status: REVISION 2. **Open questions Q1-Q10 are RESOLVED by the user** (see "Risks and open questions"). Changes
> from revision 1: maintenance cannot be registered for Lost or Disposed equipment (Q5), and the Maintenance Type
> defaults to Preventive with no blank enum value (Q8). All other defaults are confirmed unchanged.
> Source: GitHub issue #29. Branch: `feature/FR-010-maintenance-registration`.
> No events report: FR-010 adds new objects only, plus changes to this app's own objects. It subscribes to no events
> and changes no standard behavior. "Vendor" is a plain table relation to the base Vendor table. al-event-finder is not
> needed.
> Scope: main app only. **Six new objects (enum, table, three pages, codeunit), one new field on the setup table, and
> small changes to nine of the app's own objects. No version bump** (app.json stays 29.0.0.0, as in FR-004 to NFR-003).
> **No upgrade logic.** **No automated tests** (Q10 resolved: deferred, as in FR-003 to NFR-003; the scenarios are a
> reference, and test codeunit 50164 is reserved).
> Workflow for FR-010: planner -> (human approves plan) -> developer -> reviewer -> build -> **tester step SKIPPED
> (Q10)** -> documenter -> appsource-validator.

## Goal
Users can register the maintenance work that was done on a piece of equipment: when, what kind, by whom, by which
vendor, at what cost and with what description. Each record gets a number from a number series. Records belong to
existing equipment that is not Lost or Disposed, cannot be dated in the future, cannot have a negative cost and can
never be deleted, so they form a lasting maintenance history that is visible from the equipment list and card.

### Requirement restated
- M-R1 Register maintenance activities performed on equipment.
- M-R2 Data: Maintenance No., Equipment No., Maintenance Date, Maintenance Type, Vendor, Cost, Description, Performed By.
- M-R3 Maintenance Types: Preventive, Corrective, Inspection, Upgrade.
- BR-M1 Equipment must exist before maintenance can be registered.
- BR-M2 Maintenance records cannot be deleted once created.
- BR-M3 Maintenance Date cannot be in the future.
- BR-M4 Cost must be zero or greater.
- BR-M5 (user decision Q5) Maintenance cannot be registered for equipment whose status is Lost or Disposed.

### Interpretation (resolved decisions, see Q1-Q10)
- "Register" means recording work that **was performed** (past or today). Planning or scheduling future maintenance is
  a later V2 feature (README "maintenance schedules"), not part of FR-010.
- Registering maintenance does **not** change the equipment status. The status "In Maintenance" (FR-003) stays a
  manual status and is independent of maintenance records (Q4).
- Records can be corrected after creation (date, type, vendor, cost, description, performed by), with the rules
  checked again. The equipment of a saved record and its number cannot be changed (Q3).
- BR-M5 applies to **registering** (inserting) a record. Correcting an existing record stays allowed after the equipment
  became Lost or Disposed, so history from before the disposal can still be fixed (Q5). Equipment with any other status
  (Available, Assigned, In Maintenance, and statuses added by extensions) can get maintenance.
- "Vendor" is optional (internal maintenance has no vendor). "Performed By" is free text (Q1).
- "Future" means later than the real calendar date `Today()`, not the work date (Q2).
- Cost is an amount in local currency (LCY); there is no currency code (Q6).
- Maintenance Type defaults to Preventive on new records; the user changes it when needed (Q8).
- Because records cannot be deleted, equipment that has maintenance records cannot be deleted either (same rule as
  assignment history in FR-006). Otherwise records would point to equipment that no longer exists.

### What already exists and is reused
- Number series pattern of table 50100: `OnInsert` takes the next number from the setup series, `"No." OnValidate`
  calls `TestManual`, `AssistEdit()` on the card. FR-010 copies this pattern for maintenance numbers.
- `IsFinalStatus(EquipmentStatus)` on table 50100 (internal): true for Lost and Disposed. BR-M5 reuses it, so "final
  status" has one definition in the app.
- Setup table 50102 and setup page 50103 (`Numbering` FastTab); codeunit 50105 "EQM Default Data" creates the EQUIP
  series on install / first open by an Administrator. FR-010 adds a second series the same way.
- FR-006 rule "equipment with history cannot be deleted" in table 50100 `OnDelete`. FR-010 adds one more check there.
- NFR-002 roles: Reader (R), Manager (RIM), Administrator (RIMD). Nobody may delete history (Q2 of NFR-002).
- NFR-002 guard pattern: names from base tables are read only when `ReadPermission()` is true, otherwise blank.
- NFR-003 patterns: List page with `CardPageId`, `Editable = false`; Card with `DelayedInsert`; promoted groups
  `Category_Process` / `Category_Category4`; imperative action ToolTips, "Specifies ..." field ToolTips; teaching tips
  and `AdditionalSearchTerms` on searchable pages; FactBoxes as CardParts fed by internal read procedures of a Mgt.
  codeunit; Notes (visible) and Links (hidden) system parts.

### Linking maintenance into the Equipment Card (decision, Q7 resolved)
- **Through a FactBox and actions, not through a body subpage.**
  - New CardPart "EQM Maintenance FactBox" (caption 'Maintenance') in the FactBox pane of the Equipment Card and the
    Equipment List: number of maintenance records (drill-down to the filtered list), last maintenance date and type,
    total maintenance cost.
  - Equipment Card: processing action **Register Maintenance** (opens a new maintenance card with the equipment
    filled in; disabled for Lost and Disposed equipment) and navigation action **Maintenance** (the equipment's
    records). Equipment List: navigation action **Maintenance**.
- Rejected: a ListPart "Maintenance History" in the card body like the FR-008 Assignment History. The card already
  has four FastTabs and a body part; the full list is one click away; keeps FR-010 tight.

## Approach and rejected alternatives
- Chosen:
  - **New table 50105 "EQM Maintenance Record"** with a number-series key "No.", all rules in table triggers and one
    internal check procedure (same structure as table 50100), and one publisher event for partner rules.
  - **New enum 50102 "EQM Maintenance Type"** with exactly the four issue values; Preventive is value 0 and the field's
    `InitValue`, so new records default to Preventive (Q8). `Extensible = true` (no code branches on the values).
  - **New field "Maintenance Nos."** on setup table 50102, a new default series EQMAINT in codeunit 50105, shown on the
    setup page.
  - **BR-M2 as a hard rule:** `OnDelete` of table 50105 always raises an error; pages have `DeleteAllowed = false`; no
    permission set grants D on the table. No IsHandled.
  - **BR-M1** through `TableRelation` + `NotBlank` on "Equipment No." and an explicit existence check on insert and
    modify (covers code paths that assign without validating).
  - **BR-M5** checked on insert (and early, when "Equipment No." is validated on a new record) with
    `Equipment.IsFinalStatus`. Hard rule, no IsHandled (the user decided it; partners can still add stricter rules
    through the event). The card action Register Maintenance is disabled for final statuses.
  - **BR-M3** checked on field validation and on insert/modify against `Today()`.
  - **BR-M4** through `MinValue = 0` on Cost and an explicit check on insert/modify.
  - **UI:** list page (searchable), card page, CardPart FactBox for equipment pages; actions on the Equipment List,
    Equipment Card and Role Center.
  - **Internal codeunit 50108 "EQM Maintenance Mgt."** with read helpers for the FactBox and the vendor name (avoids a
    sixth copy of the guarded name lookup, NFR-003 R5).
- Rejected: an editable list page only (no card), like Equipment Categories. Numbered records with eight fields
  follow the BC List + Card pattern (NFR-003); the card also hosts the equipment FactBoxes.
- Rejected: a journal + posting routine producing read-only ledger entries. Correct for accounting data, but far
  beyond the issue (no posting, no G/L); "cannot be deleted" is met by the delete rule and permissions.
- Rejected: AutoIncrement entry number like table 50103. The issue asks for a "Maintenance No."; users expect a
  number series they can configure (Q9).
- Rejected: setting the equipment status to In Maintenance when a record is registered. Records describe past work;
  the FR-003 status logic stays the only status path (Q4).
- Rejected: making records fully read-only after creation. The issue only forbids deletion; typos must be correctable
  (Q3).
- Rejected: applying BR-M5 also on modify. Then a record registered before the equipment was disposed could never be
  corrected; the user's rule is about registering.
- Rejected: a blank enum value with a "type required" check (revision 1). The user chose Preventive as the default
  (Q8).
- Rejected: FlowFields on table 50100 for maintenance count / cost. Schema change on a public table for values one
  FactBox needs (NFR-003 rejected the same for assignments).
- Rejected: a FlowField "Vendor Name" on table 50105. A FlowField raises a permission error for users without Vendor
  read; a guarded page variable stays blank instead (NFR-002 Q4 pattern).
- Rejected: a Cue tile / chart for maintenance on the dashboard. Not asked; candidate for a later KPI feature (Q7).
- Rejected: any standard BC event subscription (e.g. block deleting a Vendor used by maintenance). Out of scope; see R3.

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50104, pages 50100-50112, codeunits 50103-50107,
queries 50100-50101, enums 50100-50101, page extension 50100, permission sets 50100-50102, permission set extension
50103, profile "EQM EQUIPMENT MANAGER". Test app: no objects (test codeunits 50150-50163 reserved by FR-001 to
NFR-003, none built).

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50102 | EQM Maintenance Type | New | Preventive, Corrective, Inspection, Upgrade; `Extensible = true` |
| Table | 50105 | EQM Maintenance Record | New | One record per maintenance activity; rules BR-M1 to BR-M5; one publisher event |
| Page | 50113 | EQM Maintenance Records | New | List (searchable), read-only rows, `CardPageId` = 50114, views per type |
| Page | 50114 | EQM Maintenance Record Card | New | Card to register and correct a record |
| Page | 50115 | EQM Maintenance FactBox | New | CardPart on equipment pages: count, last date/type, total cost |
| Codeunit | 50108 | EQM Maintenance Mgt. | New | Internal read/show helpers, guarded vendor name |
| Table | 50102 | EQM Equipment Setup | Modify (own) | New field 3 "Maintenance Nos." |
| Page | 50103 | EQM Equipment Setup | Modify (own) | Show "Maintenance Nos."; search terms |
| Codeunit | 50105 | EQM Default Data | Modify (own) | Create series EQMAINT and fill "Maintenance Nos." when blank |
| Table | 50100 | EQM Equipment | Modify (own) | `OnDelete`: refuse delete when maintenance records exist |
| Page | 50100 | EQM Equipment List | Modify (own) | Action Maintenance; Maintenance FactBox |
| Page | 50101 | EQM Equipment Card | Modify (own) | Actions Register Maintenance and Maintenance; Maintenance FactBox |
| Page | 50110 | EQM Equipment Manager RC | Modify (own) | Embedding 'Maintenance'; Creation 'Maintenance Record' |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | R on table 50105; X on the new table, pages and codeunit |
| PermissionSet | 50101 | EQM - Manager | Modify (own) | RIM on table 50105 (no D) |

Not changed: tables 50101, 50103, 50104; pages 50102, 50104-50109, 50111, 50112; codeunits 50103, 50104, 50106,
50107; queries; enums 50100, 50101; page extension 50100; permission set 50102 (inherits Manager; still no D on
maintenance); permission set extension 50103; the profile; `app/app.json`; `test/`.
Folder: new files in `app/src/Maintenance/`: `EQMMaintenanceType.Enum.al`, `EQMMaintenanceRecord.Table.al`,
`EQMMaintenanceRecords.Page.al`, `EQMMaintenanceRecordCard.Page.al`, `EQMMaintenanceFactBox.Page.al`,
`EQMMaintenanceMgt.Codeunit.al`. Namespace `MiguelCarvalho.EquipmentManagement` like all existing files.
Next free IDs after FR-010: tables 50106, pages 50116, codeunits 50109, queries 50102, enums 50103, page extensions
50101, permission sets 50104. Test app: test codeunit **50164 reserved for FR-010 "EQM Maintenance Tests", not built
now (Q10).**

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report; do not pick a workaround on your own.
- Table "Vendor" and page "Vendor Card" are in namespace `Microsoft.Purchases.Vendor` in the BC 29 symbols; Vendor
  has fields "No." (Code[20]) and Name (Text[100]).
- Object names are at most 30 characters: "EQM Maintenance Record Card" (27), "EQM Maintenance Records" (23),
  "EQM Maintenance FactBox" (23), "EQM Maintenance Type" (20), "EQM Maintenance Record" (22), "EQM Maintenance Mgt." (20).
- An action with `RunObject = page "EQM Maintenance Record Card"`, `RunPageLink = "Equipment No." = field("No.")` and
  `RunPageMode = Create` opens a new card whose "Equipment No." is pre-filled from the link (the pattern the base
  Customer Card uses for new sales documents). Check in the sandbox (MT-SB3).
- `InitValue = Preventive` on an enum field is accepted by the compiler (enum value name as InitValue).
- Image names used below exist: `MaintenanceRegistrations`, `Maintenance`, `Vendor`, `FixedAssets`, `New`. If one does
  not compile, use `ServiceLedger` for the Maintenance list action and report the replacement.

### Enum 50102 "EQM Maintenance Type"
- `Caption = 'Maintenance Type'`; `Extensible = true`; `/// <summary>`: "Type of maintenance activity. New maintenance
  records start as Preventive."
- Values: 0 Preventive (Caption 'Preventive'), 1 Corrective (Caption 'Corrective'), 2 Inspection (Caption
  'Inspection'), 3 Upgrade (Caption 'Upgrade'). No blank value.

### Table 50105 "EQM Maintenance Record"
Object properties: `Caption = 'Maintenance Record'`; `DataClassification = CustomerContent`; `Access = Public`;
`LookupPageId` and `DrillDownPageId` = "EQM Maintenance Records"; `DataCaptionFields = "No.", Description`.
`using Microsoft.Foundation.NoSeries;` and `using Microsoft.Purchases.Vendor;`.
`/// <summary>`: "One record per maintenance activity performed on equipment. Maintenance cannot be registered for
Lost or Disposed equipment. Records can be corrected but never deleted, so equipment that has maintenance records
cannot be deleted either."

| Field ID | Name | Type | Caption | Properties / ToolTip |
|---|---|---|---|---|
| 1 | "No." | Code[20] | No. | ToolTip 'Specifies the number of the maintenance record.' `OnValidate`: see below. |
| 2 | "Equipment No." | Code[20] | Equipment No. | `TableRelation = "EQM Equipment"."No."`; `NotBlank = true`. ToolTip 'Specifies the equipment the maintenance was performed on. The equipment must exist and cannot be lost or disposed of. You cannot change it after the record is created.' `OnValidate`: see below. |
| 3 | "Maintenance Date" | Date | Maintenance Date | ToolTip 'Specifies the date the maintenance was performed. The date cannot be later than today. If you leave it blank, the work date is used.' `OnValidate`: `CheckMaintenanceDate()`. |
| 4 | "Maintenance Type" | Enum "EQM Maintenance Type" | Maintenance Type | `InitValue = Preventive`. ToolTip 'Specifies the type of maintenance: Preventive, Corrective, Inspection or Upgrade. New records start as Preventive.' |
| 5 | "Vendor No." | Code[20] | Vendor No. | `TableRelation = Vendor."No."`. ToolTip 'Specifies the vendor that performed the maintenance. Leave it blank when the maintenance was done internally.' |
| 6 | Cost | Decimal | Cost | `AutoFormatType = 1`; `MinValue = 0`. ToolTip 'Specifies the cost of the maintenance in local currency. The cost must be zero or greater.' |
| 7 | Description | Text[100] | Description | ToolTip 'Specifies a description of the maintenance work.' |
| 8 | "Performed By" | Text[100] | Performed By | ToolTip 'Specifies the name of the person or team that performed the maintenance.' |
| 9 | "No. Series" | Code[20] | No. Series | `TableRelation = "No. Series"`; `Editable = false`. ToolTip 'Specifies the number series from which the maintenance record number was assigned.' |
| 10 | "Equipment Description" | Text[100] | Equipment Description | `FieldClass = FlowField`; `CalcFormula = lookup("EQM Equipment".Description where("No." = field("Equipment No.")))`; `Editable = false`. ToolTip 'Specifies the description of the equipment.' |

- DataClassification: table level only (CustomerContent). No field overrides it (Performed By holds names of
  technicians who are usually not users of the system; see R6).
- Keys: `PK` "No." (Clustered); `EquipmentDate` ("Equipment No.", "Maintenance Date") with `SumIndexFields = Cost`.
- Field groups: `DropDown` = "No.", "Equipment No.", "Maintenance Date", "Maintenance Type", Description;
  `Brick` = "No.", "Equipment No.", "Maintenance Date", "Maintenance Type".
- The Preventive default comes from `InitValue` (applies on `Init` and on new card records). No extra code in
  `OnInsert` is needed for it.

**Field triggers**
- `"No." OnValidate`: when "No." <> xRec."No.": get the setup (local `GetSetup`, same as table 50100),
  `NoSeries.TestManual(EquipmentSetup."Maintenance Nos.")`, `"No. Series" := ''`.
- `"Equipment No." OnValidate`, in this order:
  1. When "Equipment No." <> xRec."Equipment No." and `IsStoredRecord()`:
     Error(EquipmentCannotChangeErr, "No.", xRec."Equipment No.").
  2. When "Equipment No." <> '' (record is new, because step 1 passed): `CheckEquipmentAllowsMaintenance()` (BR-M5,
     early feedback on the card). The TableRelation already checks existence.
- `"Maintenance Date" OnValidate`: `CheckMaintenanceDate()`.

**Table triggers**
- `OnInsert`:
  1. Number series, same code shape as table 50100 `OnInsert`: when "No." = '': `GetSetup`,
     `EquipmentSetup.TestField("Maintenance Nos.")`, "No. Series" := setup series (or xRec series when `AreRelated`),
     "No." := `NoSeries.GetNextNo("No. Series")`.
  2. When "Maintenance Date" = 0D: "Maintenance Date" := `WorkDate()`.
  3. `CheckMaintenanceConsistency(true)`.
- `OnModify`: `CheckMaintenanceConsistency(false)`.
- `OnDelete`: Error(MaintenanceCannotBeDeletedErr, "No."). Always, no condition, no event (BR-M2).
- `OnRename`: Error(RenameNotAllowedErr, xRec."No."). (Rename would change the key of a history record; the platform
  cascade from renaming **equipment** updates "Equipment No." without running this trigger, see R5.)

**Procedures**
- `internal procedure AssistEdit(): Boolean` - same as table 50100 `AssistEdit`, using "Maintenance Nos.". Doc comment
  as in table 50100 with "maintenance record".
- `internal procedure CheckMaintenanceConsistency(IsNewRecord: Boolean)` - in this order:
  1. `TestField("Equipment No.")`.
  2. Local `Equipment: Record "EQM Equipment"`, `SetLoadFields("No.")`; when not `Get("Equipment No.")`:
     Error(EquipmentNotFoundErr, "Equipment No."). (BR-M1)
  3. When IsNewRecord: `CheckEquipmentAllowsMaintenance()`. (BR-M5, insert only)
  4. When not IsNewRecord: local `StoredRecord: Record "EQM Maintenance Record"`, `SetLoadFields("Equipment No.")`;
     when `Get("No.")` and StoredRecord."Equipment No." <> "Equipment No.":
     Error(EquipmentCannotChangeErr, "No.", StoredRecord."Equipment No.").
  5. `TestField("Maintenance Date")`; `CheckMaintenanceDate()`. (BR-M3)
  6. When Cost < 0: Error(NegativeCostErr, "No."). (BR-M4)
  7. `OnAfterCheckMaintenanceConsistency(Rec)`.
  Doc comment: "Validates the record before it is inserted or modified: equipment filled in and existing, equipment
  not Lost or Disposed when a new record is registered, equipment not changed on a saved record, maintenance date
  filled in and not later than today, cost zero or greater. Raises OnAfterCheckMaintenanceConsistency at the end."
- `local procedure CheckEquipmentAllowsMaintenance()`: local `Equipment: Record "EQM Equipment"`,
  `SetLoadFields(Status)`; when `Get("Equipment No.")` and `Equipment.IsFinalStatus(Equipment.Status)`:
  Error(EquipmentFinalStatusErr, "Equipment No.", Format(Equipment.Status)). When the equipment is not found, do
  nothing here (existence is reported by the TableRelation or by step 2 of the consistency check).
- `local procedure CheckMaintenanceDate()`: when "Maintenance Date" > `Today()`:
  Error(FutureDateErr, "Maintenance Date", Today()). A blank date passes here (blank is handled by `TestField`).
- `local procedure IsStoredRecord(): Boolean`: same as table 50100 (false when "No." = '', else `Get` with
  `SetLoadFields("No.")`).
- `local procedure GetSetup(var EquipmentSetup: Record "EQM Equipment Setup")`: same as table 50100.

**Event** (see Events): `OnAfterCheckMaintenanceConsistency`.

**Labels** (table 50105):
- `MaintenanceCannotBeDeletedErr`: 'You cannot delete maintenance record %1. Maintenance records are kept as the maintenance history of the equipment.' Comment: '%1 = maintenance record number'.
- `EquipmentNotFoundErr`: 'Equipment %1 does not exist. Register the equipment before you register maintenance for it.' Comment: '%1 = equipment number'.
- `EquipmentFinalStatusErr`: 'You cannot register maintenance for equipment %1 because its status is %2.' Comment: '%1 = equipment number, %2 = status caption (Lost or Disposed)'.
- `EquipmentCannotChangeErr`: 'You cannot change the equipment of maintenance record %1. The record belongs to equipment %2.' Comment: '%1 = maintenance record number, %2 = equipment number'.
- `FutureDateErr`: 'The maintenance date %1 is in the future. Enter a date that is not later than today (%2).' Comment: '%1 = maintenance date, %2 = today''s date'.
- `NegativeCostErr`: 'The cost of maintenance record %1 must be zero or greater.' Comment: '%1 = maintenance record number'.
- `RenameNotAllowedErr`: 'You cannot change the number of maintenance record %1.' Comment: '%1 = maintenance record number'.

### Codeunit 50108 "EQM Maintenance Mgt."
`Access = Internal`. No `Permissions` property (every role has direct R on table 50105; Vendor read comes from
D365 BASIC and is guarded). `using Microsoft.Purchases.Vendor;`. `/// <summary>`: "Read helpers for maintenance
records shown on equipment pages." All procedures `internal`, each with an XML doc comment. Use key `EquipmentDate`
with `SetCurrentKey("Equipment No.", "Maintenance Date")`.
1. `HasMaintenanceRecords(EquipmentNo: Code[20]): Boolean` - filter "Equipment No.", return `not IsEmpty()`.
2. `CountMaintenanceRecords(EquipmentNo: Code[20]): Integer` - filter, return `Count()`.
3. `GetLastMaintenanceRecord(EquipmentNo: Code[20]; var MaintenanceRecord: Record "EQM Maintenance Record"): Boolean` -
   `Reset`, `SetCurrentKey`, filter, return `FindLast()` (latest date; on equal dates the highest "No." because the
   primary key is the last part of every secondary key).
4. `GetTotalMaintenanceCost(EquipmentNo: Code[20]): Decimal` - filter, `CalcSums(Cost)`, return Cost.
5. `ShowMaintenanceRecords(EquipmentNo: Code[20])` - `Page.Run(Page::"EQM Maintenance Records", MaintenanceRecord)`
   with the record filtered on "Equipment No." (same shape as `ShowAssignments` in codeunit 50106).
6. `GetVendorName(VendorNo: Code[20]): Text[100]` - returns '' when VendorNo = '' or when `Vendor.ReadPermission()`
   is false; otherwise `SetLoadFields(Name)`, returns Name when `Get` succeeds, else ''.

### Page 50113 "EQM Maintenance Records" (new)
Properties: `Caption = 'Equipment Maintenance'`; `PageType = List`; `ApplicationArea = All`; `UsageCategory = Lists`;
`AdditionalSearchTerms = 'equipment maintenance, maintenance history, repairs, inspections, equipment service'`;
`SourceTable = "EQM Maintenance Record"`; `CardPageId = "EQM Maintenance Record Card"`; `Editable = false`;
`DeleteAllowed = false`; `SourceTableView = sorting("No.") order(descending)` (newest number first).
`AboutTitle = 'About equipment maintenance'`;
`AboutText = 'This list shows the maintenance work done on your equipment: when, what type, by whom and at what cost. Choose **New** to register maintenance. Maintenance records cannot be deleted, so they stay in the history of the equipment. Choose a view at the top to see one maintenance type.'`

Layout: `repeater(MaintenanceRecords)` with, in this order: "No.", "Maintenance Date", "Equipment No.",
"Equipment Description", "Maintenance Type", Description, "Vendor No.", `VendorName` (page variable Text[100],
`Caption = 'Vendor Name'`, `ToolTip = 'Specifies the name of the vendor that performed the maintenance.'`),
"Performed By", Cost. No ToolTips on table fields (inherited).
`area(FactBoxes)`: `part(EquipmentFactBox; "EQM Equipment FactBox")` with `SubPageLink = "No." = field("Equipment No.")`;
`systempart(Links; Links)` with `Visible = false`; `systempart(Notes; Notes)`.

Actions:
- `area(Navigation)`: action `Equipment` (`Caption = 'Equipment'`, `ToolTip = 'Open the equipment card.'`,
  `Image = FixedAssets`, `RunObject = page "EQM Equipment Card"`, `RunPageLink = "No." = field("Equipment No.")`);
  action `Vendor` (`Caption = 'Vendor'`, `ToolTip = 'Open the vendor card.'`, `Image = Vendor`,
  `RunObject = page "Vendor Card"`, `RunPageLink = "No." = field("Vendor No.")`).
- `area(Promoted)`: `group(Category_Category4)`, `Caption = 'Navigate'`, with `Equipment_Promoted` and
  `Vendor_Promoted`.

Views (after `actions`, AL0926): `Preventive`, `Corrective`, `Inspection`, `Upgrade`, each with the type caption and
`Filters = where("Maintenance Type" = const(<value>))`.
`var`: `VendorName: Text[100]`. Trigger `OnAfterGetRecord`: `VendorName := MaintenanceMgt.GetVendorName(Rec."Vendor No.")`
(local `MaintenanceMgt: Codeunit "EQM Maintenance Mgt."`).

### Page 50114 "EQM Maintenance Record Card" (new)
Properties: `Caption = 'Maintenance Record'`; `PageType = Card`; `ApplicationArea = All`; `UsageCategory = None`;
`SourceTable = "EQM Maintenance Record"`; `DelayedInsert = true`; `DeleteAllowed = false`.
`AboutTitle = 'About maintenance records'`;
`AboutText = 'Register maintenance that was done on equipment. Choose the equipment, the date and the type of maintenance, and add the vendor, the cost and who did the work. You cannot register maintenance for lost or disposed equipment. You can correct a record later, but you cannot delete it or move it to other equipment.'`

Layout `area(Content)`:
- `group(General)`, `Caption = 'General'`:
  - "No." with `OnAssistEdit`: when `Rec.AssistEdit()` then `CurrPage.Update(false)` (as on the equipment card).
  - "Equipment No." with `Importance = Promoted`, `ShowMandatory = true`, `Editable = IsNewRecord`. No page trigger on
    this control.
  - "Equipment Description".
  - "Maintenance Date" with `Importance = Promoted`.
  - "Maintenance Type" with `Importance = Promoted` (no `ShowMandatory`; it always has a value).
  - Description with `Importance = Promoted`.
- `group(Execution)`, `Caption = 'Vendor and Cost'`:
  - "Vendor No." (page trigger `OnValidate`: `VendorName := MaintenanceMgt.GetVendorName(Rec."Vendor No.")`);
    `VendorName` (page variable, same Caption/ToolTip as on the list, `Editable = false`); "Performed By"; Cost.
`area(FactBoxes)`: `part(EquipmentFactBox; "EQM Equipment FactBox")` and `part(MaintenanceFactBox; "EQM Maintenance
FactBox")`, both with `SubPageLink = "No." = field("Equipment No.")`; `systempart(Links; Links)` with `Visible = false`;
`systempart(Notes; Notes)`.

Actions: `area(Navigation)` with the same `Equipment` and `Vendor` actions as page 50113; `area(Promoted)`
`group(Category_Category4)`, `Caption = 'Navigate'` with both actionrefs.

`var`: `VendorName: Text[100]`, `IsNewRecord: Boolean`, `MaintenanceMgt: Codeunit "EQM Maintenance Mgt."`.
Triggers `OnAfterGetRecord` and `OnNewRecord`: call local `UpdateControls()`:
`IsNewRecord := Rec.SystemCreatedAt = 0DT;` `VendorName := MaintenanceMgt.GetVendorName(Rec."Vendor No.");`
Section order: `layout`, `actions`, then `var`, triggers, procedures (AL0926).

### Page 50115 "EQM Maintenance FactBox" (new)
Properties: `Caption = 'Maintenance'`; `PageType = CardPart`; `ApplicationArea = All`; `SourceTable = "EQM Equipment"`;
`Editable = false`. No `UsageCategory`.
Layout `area(Content)` (no groups needed):
- `NoOfMaintenanceRecords` (Integer), `Caption = 'No. of Maintenance Records'`,
  `ToolTip = 'Specifies how many maintenance records the equipment has. Choose the number to see them.'`;
  `OnDrillDown`: `MaintenanceMgt.ShowMaintenanceRecords(Rec."No.")`.
- `LastMaintenanceDate` (Date), `Caption = 'Last Maintenance Date'`,
  `ToolTip = 'Specifies the date of the most recent maintenance of the equipment. It is blank when no maintenance has been registered.'`
- `LastMaintenanceType` (**Text**, not the enum: the enum has no blank value, so a Text stays empty when there are no
  records), `Caption = 'Last Maintenance Type'`,
  `ToolTip = 'Specifies the type of the most recent maintenance of the equipment. It is blank when no maintenance has been registered.'`
- `TotalMaintenanceCost` (Decimal), `Caption = 'Total Maintenance Cost'`, `AutoFormatType = 1`,
  `ToolTip = 'Specifies the total cost of all maintenance registered for the equipment, in local currency.'`
Triggers, same pattern as page 50111: `OnFindRecord` clears the variables and returns `Rec.Find(Which)`;
`OnAfterGetRecord` clears, then when Rec."No." <> '': count; when count > 0, `GetLastMaintenanceRecord` (date, and
type as `Format(MaintenanceRecord."Maintenance Type")`) and `GetTotalMaintenanceCost`. Clearing sets the text to ''.

### Table 50102 "EQM Equipment Setup" (change)
- New field `field(3; "Maintenance Nos."; Code[20])`: `Caption = 'Maintenance Nos.'`,
  `ToolTip = 'Specifies the number series used to assign numbers to new maintenance records.'`,
  `TableRelation = "No. Series"`.

### Page 50103 "EQM Equipment Setup" (change)
- Group `Numbering`: add field "Maintenance Nos." after "Equipment Nos.".
- `AdditionalSearchTerms = 'equipment numbers, equipment number series, maintenance number series'`.
- `OnOpenPage` unchanged (see Data model for existing companies).

### Codeunit 50105 "EQM Default Data" (change)
- New labels: `MaintenanceSeriesCodeTok: Label 'EQMAINT', Locked = true;`
  `MaintenanceSeriesStartTok: Label 'MNT00001', Locked = true;`
  `MaintenanceSeriesDescriptionTxt: Label 'Equipment Maintenance', MaxLength = 100;`
- Replace `EnsureEquipmentNoSeries()` with `local procedure EnsureNoSeries(SeriesCodeTxt: Text; StartingNoTxt: Text;
  SeriesDescription: Text)` holding the same body (CopyStr to the field lengths; series with "Default Nos." and
  "Manual Nos." true; one line 10000 with increment 1 when the series has no lines). Behavior for EQUIP is unchanged.
- `CreateDefaultData`: after `EquipmentSetup.Get()`, handle both series and do **one** `Modify` at the end only if
  something changed: when "Equipment Nos." = '' ensure EQUIP and set it; when "Maintenance Nos." = '' ensure EQMAINT
  and set it. Categories as today.
- Update the `/// <summary>` of `CreateDefaultData` (mention EQMAINT) and keep the header permission comment (no
  permission change: the `Permissions` property already covers setup `rim` and No. Series `ri`).

### Table 50100 "EQM Equipment" (change)
- `OnDelete`: after the existing history check, add: local `MaintenanceMgt: Codeunit "EQM Maintenance Mgt."`; when
  `MaintenanceMgt.HasMaintenanceRecords("No.")`: Error(DeleteMaintenanceExistsErr, "No.", Format(Status::Disposed)).
- New label `DeleteMaintenanceExistsErr`: 'You cannot delete equipment %1 because it has maintenance records. To stop using the equipment, set its status to %2 instead.' Comment: '%1 = equipment number, %2 = Disposed status caption'.
- Nothing else changes (`IsFinalStatus` is already `internal` and is reused as is).

### Page 50100 "EQM Equipment List" (change)
- `group(EquipmentGroup)` in `area(Navigation)`: add after `Assignments` an action `Maintenance`: `Caption =
  'Maintenance'`, `ToolTip = 'View the maintenance records of the selected equipment.'`, `Image =
  MaintenanceRegistrations`, `RunObject = page "EQM Maintenance Records"`, `RunPageLink = "Equipment No." =
  field("No.")`.
- `area(Promoted)`, `group(Category_Category4)`: add `actionref(Maintenance_Promoted; Maintenance)` after
  `Assignments_Promoted`.
- `area(FactBoxes)`: add `part(MaintenanceFactBox; "EQM Maintenance FactBox")` with `SubPageLink = "No." =
  field("No.")` directly after `EquipmentFactBox`.

### Page 50101 "EQM Equipment Card" (change)
- New global `CanRegisterMaintenance: Boolean`. In `UpdateControls`, next to `CanAssign`:
  `CanRegisterMaintenance := IsSaved and not Rec.IsFinalStatus(Rec.Status);`
- `area(Processing)`: add after `Unassign` an action `RegisterMaintenance`: `Caption = 'Register Maintenance'`,
  `ToolTip = 'Register maintenance that was performed on the equipment. Not available for lost or disposed equipment.'`,
  `Image = Maintenance`, `Enabled = CanRegisterMaintenance`, `RunObject = page "EQM Maintenance Record Card"`,
  `RunPageLink = "Equipment No." = field("No.")`, `RunPageMode = Create`.
- `group(EquipmentGroup)` in `area(Navigation)`: add after `Assignments` an action `Maintenance` with the list
  properties above, ToolTip `'View the maintenance records of the equipment.'`, plus `Enabled = IsSaved` (history of
  Lost/Disposed equipment stays viewable).
- `area(Promoted)`: `Category_Process` gets `actionref(RegisterMaintenance_Promoted; RegisterMaintenance)` after
  `Unassign_Promoted`; `Category_Category4` gets `actionref(Maintenance_Promoted; Maintenance)` after
  `Assignments_Promoted`.
- `area(FactBoxes)`: add `part(MaintenanceFactBox; "EQM Maintenance FactBox")` with `SubPageLink = "No." =
  field("No.")` directly after `EquipmentFactBox`.
- `AboutText` unchanged. Layout groups and other triggers and procedures unchanged.

### Page 50110 "EQM Equipment Manager RC" (change)
- `area(Embedding)`: add after `AssignmentList` an action `MaintenanceList`: `Caption = 'Maintenance'`,
  `ToolTip = 'Open the maintenance records of all equipment.'`, `RunObject = page "EQM Maintenance Records"`.
- `area(Creation)`: add after `NewEquipment` an action `NewMaintenanceRecord`: `Caption = 'Maintenance Record'`,
  `ToolTip = 'Register maintenance that was performed on equipment.'`, `Image = New`,
  `RunObject = page "EQM Maintenance Record Card"`, `RunPageMode = Create`.

### app.json, translations
- **app.json: no change.** The version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf` (new objects, captions, ToolTips, labels,
  teaching tips, search terms). Commit it; never edit it by hand.

## Data model and upgrade impact
- New table 50105 (10 fields, one FlowField, two keys, SumIndexFields Cost on `EquipmentDate`), new enum 50102 (four
  values, no blank), new field 3 on table 50102. No change to tables 50100, 50101, 50103, 50104.
- DataClassification: CustomerContent at table level for 50105 and for the new setup field (inherited from table
  50102). "Performed By" is free text that can contain a person's name (R6).
- Upgrade codeunit: **not needed** (nothing released; confirmed 2026-11-04 for NFR-002). The first release will
  install the field and series through `OnInstallAppPerCompany`.
- **Existing development companies:** the setup record exists, so `CreateDefaultData` is not called by the setup page
  and "Maintenance Nos." stays blank. Registering maintenance then fails with the standard `TestField` error on
  "Maintenance Nos.". Sandbox step MT-SB0: an Administrator opens Equipment Setup and selects a number series (or the
  app is reinstalled with data cleared, which runs the install code). Same limitation as the TODO item "Setup defaults
  are created only when the setup record is missing"; not solved here (Q9).
- Volume: one record per maintenance activity; never deleted. The `EquipmentDate` key keeps the FactBox reads and the
  per-equipment list cheap.

## Events
**Standard BC events: none.** No events report required.

Subscribed: none.

Published (table 50105, `[IntegrationEvent(false, false)]`, `local`):
- `OnAfterCheckMaintenanceConsistency(MaintenanceRecord: Record "EQM Maintenance Record")`, **no IsHandled**.
  - Raised at the end of `CheckMaintenanceConsistency`, on insert and modify, after all standard checks passed. Lets
    partners add their own rules (e.g. vendor required for Corrective) by raising an error. Same shape as
    `OnAfterCheckEquipmentConsistency` on table 50100.
  - Doc comment: "Raised at the end of the consistency check on insert and modify, after all standard checks passed."
    Parameter: "The record being saved (passed by value; changes are not kept). Raise an error to reject the save."
- No IsHandled events: BR-M1 to BR-M5 are business rules decided by the issue and the user and are not overridable.
  No event on delete (delete is always refused).
- Partners can also use the implicit table events of 50105 and extend pages 50113-50115 and the enum.

## Permissions
- **EQM - Reader (50100):** add `tabledata "EQM Maintenance Record" = R`, `table "EQM Maintenance Record" = X`,
  `page "EQM Maintenance Records" = X`, `page "EQM Maintenance Record Card" = X`, `page "EQM Maintenance FactBox" = X`,
  `codeunit "EQM Maintenance Mgt." = X`. (Enums need no entry.)
- **EQM - Manager (50101):** add `tabledata "EQM Maintenance Record" = RIM` (register and correct; **no D**).
- **EQM - Administrator (50102):** no change. It inherits RIM from Manager and gets **no D** on maintenance (BR-M2:
  nobody deletes records; same as assignment history, NFR-002 Q2). Setup field covered by its existing RIMD on setup.
- Permission set extension 50103: no change.
- Vendor read (name column, Vendor lookup) and No. Series consumption come from **D365 BASIC**, the documented
  prerequisite (NFR-002). Without Vendor read the Vendor Name is blank, no error. Consuming the EQMAINT series for a
  non-SUPER Manager is the same unverified point as NFR-002 R3 (MT-SB5).

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| View maintenance list, card, FactBox | yes | yes | yes |
| Register maintenance (card, Register Maintenance, RC New), not for Lost/Disposed equipment | no (permission error at save) | yes | yes |
| Correct a record (also for Lost/Disposed equipment) | no | yes | yes |
| Delete a record | no | no | no |
| Set "Maintenance Nos." in setup | no | no | yes |

## Compatibility
- AppSource mode, development phase: nothing released, no baseline, no Obsolete handling needed.
- New public surface that becomes a contract after the first release: table 50105 (fields, keys, `InitValue` of
  "Maintenance Type"), enum 50102 values (extensible; values cannot be removed or renumbered later; Preventive is
  ordinal 0), event `OnAfterCheckMaintenanceConsistency`, pages 50113-50115 and their control/action names, setup
  field 3.
- Codeunit 50108 is `Access = Internal`; `AssistEdit` and `CheckMaintenanceConsistency` on table 50105 are `internal`.
  The table calls the internal `IsFinalStatus` of table 50100 (same app, allowed).
- Behavior change on existing objects: equipment with maintenance records can no longer be deleted (new error), for
  every role including Administrator. Equipment without history or maintenance is deleted as before.
- Equipment Card, List and Role Center: actions and parts are added; no existing action, group or control is renamed.
- Doc references to update (documenter, not developer). Historical plans in `docs/plans/` are **not** edited:
  - New `docs/features/FR-010-maintenance-registration.md` and `docs/help/FR-010-maintenance-registration.md`: how to
    register (Equipment Card > Register Maintenance, Equipment Maintenance list > New, Role Center), the four types and
    the Preventive default, the rules (equipment must exist and not be Lost or Disposed, no future date, cost >= 0, no
    delete, equipment cannot be changed), correcting a record (also after disposal), the Maintenance FactBox, setup of
    "Maintenance Nos.", roles, D365 BASIC for vendor names.
  - `docs/help/FR-003-equipment-status-management.md`: Lost and Disposed equipment cannot get new maintenance records.
  - `docs/help/FR-001-equipment-registration.md` and `docs/help/FR-006-assignment-history-tracking.md` (delete rules):
    equipment with maintenance records cannot be deleted either.
  - `docs/help/NFR-002-role-based-access.md` and `docs/features/NFR-002-role-based-access.md`: add maintenance to the
    matrices.
  - `docs/help/NFR-003-usability.md`: the new FactBox and the Maintenance actions.
  - `CHANGELOG.md`: new top section `## FR-010 Maintenance Registration (version stays 29.0.0.0, no bump)` with Added /
    Changed / Fixed / Obsolete and a release-notes paragraph.
  - `docs/TODO.md`: section "FR-010 sandbox checks" with MT-SB0 to MT-SB11.

## Test scenarios
**No automated tests in this iteration (Q10 resolved: deferred, as in FR-003 to NFR-003). No test codeunits, no
`test/app.json` change. ID 50164 is reserved, and the tester step is skipped.** The list is the reference for the
user, who writes the tests later in test codeunit 50164 "EQM Maintenance Tests" (it can bind its own manual
subscriber for M29/M30). The developer and reviewer use it to check behavior by reading the code.

Test data, unless stated: setup with "Maintenance Nos." = a fresh series (e.g. TMNT, starting TMNT0001, manual nos.
allowed); category C1; equipment E1 (Available), E2 (Disposed), E3 (never used for maintenance), E4 (Lost), E5 (In
Maintenance), E6 (assigned to an active employee); vendor V1 (Name 'Fix Ltd.'). "Register" means: Init a record, set
"Equipment No.", Cost etc. with `Validate`, then `Insert(true)`. Assert dates against `Today()` / `WorkDate()`. After
an expected error, assert that nothing was inserted, modified or deleted.

Registration and numbering (M-R1, M-R2, M-R3)
- M1 Given E1, when a record is registered with type Corrective, date Today, vendor V1, cost 100, description and
  performed by, then it is saved with "No." from the series, "No. Series" = the series and all values stored.
- M2 Given "Maintenance Date" left blank, when the record is inserted, then "Maintenance Date" = `WorkDate()` (with
  WorkDate <= Today).
- M3 Given a manual number 'MANUAL1' and a series with "Manual Nos." = true, when the record is inserted, then "No." =
  'MANUAL1' and "No. Series" is blank.
- M4 Given "Maintenance Nos." blank in setup and "No." blank, when a record is inserted, then the `TestField` error on
  "Maintenance Nos." is raised.
- M5 Given each type Preventive, Corrective, Inspection, Upgrade, when a record is registered, then it is saved with
  that type.
- M6 Given a new record after `Init()` (type not set), when it is registered, then it is saved with "Maintenance Type"
  = Preventive (Q8). Same on a new card (TestPage `OpenNew`): the type field shows Preventive before anything is entered.
- M7 Given no vendor, when a record is registered, then it is saved with "Vendor No." blank.
- M8 (negative) Given "Vendor No." validated to a non-existing vendor, then the table relation error is raised.

Equipment must exist (BR-M1)
- M9 (negative) Given "Equipment No." validated to 'NOPE' (no equipment), then the table relation error is raised.
- M10 (negative) Given "Equipment No." := 'NOPE' set by direct assignment (no Validate), when `Insert(true)` is
  called, then `EquipmentNotFoundErr` ('NOPE') is raised.
- M11 (negative) Given "Equipment No." blank, when `Insert(true)` is called, then the TestField error on Equipment No.
  is raised.
- M13 (negative) Given a saved record for E1, when "Equipment No." is validated to E3, then `EquipmentCannotChangeErr`
  (record no., E1) is raised.
- M14 (negative) Given a saved record for E1, when "Equipment No." := E3 by direct assignment and `Modify(true)`, then
  `EquipmentCannotChangeErr` is raised and the stored record still has E1.

Lost and Disposed equipment (BR-M5, Q5)
- M12 (negative) Given E2 (Disposed), when "Equipment No." is validated to E2 on a new record, then
  `EquipmentFinalStatusErr` (E2, Disposed caption) is raised.
- M12b (negative) Given E4 (Lost), when "Equipment No." is validated to E4 on a new record, then
  `EquipmentFinalStatusErr` (E4, Lost caption) is raised.
- M12c (negative) Given "Equipment No." := E2 by direct assignment (no Validate), when `Insert(true)` is called, then
  `EquipmentFinalStatusErr` is raised and no record exists. Same for E4.
- M12d Given E5 (In Maintenance) and E6 (Assigned), when a record is registered for each, then both are saved (only
  Lost and Disposed are refused).
- M12e Given a record registered for E1 while Available, and E1 then set to Disposed (validate + `Modify(true)`, confirm
  Yes), when the record's Description and Cost are changed with `Modify(true)`, then the change is saved (BR-M5 applies
  to registering only).
- M12f Given registering for E2 is refused, then registering maintenance does not change the status of E2 or of any
  equipment in the other scenarios (status before = status after).
- M12g Given the Equipment Card on E2 (Disposed) and on E4 (Lost), then Register Maintenance is disabled and the
  Maintenance navigation action is enabled; on E1, E5 and E6 Register Maintenance is enabled.

No delete (BR-M2)
- M15 (negative) Given a saved record and a user with D on the table (SUPER in the test), when `Delete(true)` is
  called, then `MaintenanceCannotBeDeletedErr` (record no.) is raised and the record still exists.
- M16 (negative) Given a saved record, when `Rename` is called with a new number, then `RenameNotAllowedErr` is raised.
- M17 (negative) Given E3 with one maintenance record and no assignment history, when E3 is deleted with
  `Delete(true)`, then `DeleteMaintenanceExistsErr` (E3, Disposed caption) is raised and E3 and the record still exist.
- M18 Given equipment with no maintenance records and no assignment history, when it is deleted, then it is deleted
  (regression).
- M19 Given the list page 50113 and the card 50114 (TestPage), then delete is not available on either.

Date not in the future (BR-M3)
- M20 Given "Maintenance Date" validated to `Today()`, then no error; given `Today() - 30`, then no error.
- M21 (negative) Given "Maintenance Date" validated to `Today() + 1`, then `FutureDateErr` (date, Today) is raised.
- M22 (negative) Given "Maintenance Date" := `Today() + 1` by direct assignment, when `Insert(true)`, then
  `FutureDateErr` is raised and no record exists.
- M23 (negative) Given WorkDate = `Today() + 5` and the date left blank, when `Insert(true)`, then `FutureDateErr` is
  raised (default work date is still checked).
- M24 Given a saved record dated Today - 10, when Description is changed and `Modify(true)` is called, then it is
  saved (the old date stays valid).

Cost (BR-M4)
- M25 Given Cost validated to 0, then saved; given 1234.56, then saved.
- M26 (negative) Given Cost validated to -1, then the platform MinValue error is raised.
- M27 (negative) Given Cost := -1 by direct assignment, when `Insert(true)` (and separately `Modify(true)` on a saved
  record), then `NegativeCostErr` is raised.

Correction (Q3)
- M28 Given a saved record, when date (past), type, vendor, cost, description and performed by are changed with
  `Modify(true)`, then all changes are stored.

Events
- M29 Given a manual subscriber to `OnAfterCheckMaintenanceConsistency` that raises an error when Type = Corrective
  and "Vendor No." is blank, when such a record is inserted, then the subscriber's error is raised; for Preventive it
  is saved.
- M30 Given a subscriber that records calls, when a record is inserted and then modified, then the event was raised
  twice; when a standard check fails (e.g. future date, or Disposed equipment), it is not raised.

UI and helpers
- M31 Given the Equipment Card on E1, when Register Maintenance is invoked (TestPage `Trap` on the maintenance card),
  then a new card opens with "Equipment No." = E1 and type Preventive; after closing, a record for E1 exists.
- M32 Given a new Equipment Card (not saved), then Register Maintenance and Maintenance are disabled.
- M33 Given E1 with records dated D1 (Corrective, cost 50) and D2 > D1 (Inspection, cost 20), when the card or list
  shows E1, then the Maintenance FactBox shows No. of Maintenance Records 2, Last Maintenance Date D2, Last Maintenance
  Type 'Inspection', Total Maintenance Cost 70.
- M34 Given E3 with no records, then the FactBox shows 0, blank date, **blank** type (not 'Preventive'), 0 cost and no
  error.
- M35 Given E1, when No. of Maintenance Records is drilled down, then page 50113 opens filtered on E1.
- M36 Given a saved maintenance card, then "Equipment No." is not editable; on a new card it is editable.
- M37 Given a record with vendor V1, when list and card are opened, then Vendor Name = 'Fix Ltd.'; for a user
  without Vendor read, Vendor Name is blank and no error is raised.
- M38 Given the list, when the views Preventive / Corrective / Inspection / Upgrade are selected, then only that type
  is shown.

Permissions (`TestPermissions = Restrictive`, with D365 BASIC)
- M39 Reader: can open pages 50113-50115 and read records; `Insert(true)` and `Modify(true)` raise a permission error.
- M40 Manager: can insert and modify. `Delete(true)` fails and the record still exists. Accept either the platform
  permission error (no D granted) or `MaintenanceCannotBeDeletedErr`, and note which one the platform raises.
- M41 Administrator: same delete result as M40 (no D granted); can change "Maintenance Nos." in setup.

### Manual sandbox checks (for the user)
- MT-SB0 In an existing dev company, open Equipment Setup as Administrator and set Maintenance Nos. (or reinstall
  with data cleared and confirm EQMAINT is created and filled in a fresh company).
- MT-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` contains the new captions,
  ToolTips, labels, teaching tips and search terms.
- MT-SB2 Tell Me finds "Equipment Maintenance" (also by "repairs", "inspections"); teaching tips appear on first open.
- MT-SB3 Equipment Card > Register Maintenance opens a new card with the equipment filled in and type Preventive;
  saving creates the record and the Maintenance FactBox updates when returning to the equipment card.
- MT-SB4 Delete is not offered on the list or card; equipment with maintenance cannot be deleted from the list or card.
- MT-SB5 Non-SUPER Manager registers maintenance: the EQMAINT series is consumed without a permission error.
- MT-SB6 Reader: list and card read-only; Register Maintenance fails at save with a permission error.
- MT-SB7 Future date on the card gives `FutureDateErr`; negative cost gives the MinValue error.
- MT-SB8 Role Center: Maintenance in the navigation bar, Maintenance Record under New.
- MT-SB9 Rename equipment that has maintenance records: no error, and the records show the new equipment number (R5).
- MT-SB10 Vendor Name shows on list and card; Vendor action opens the vendor card.
- MT-SB11 Disposed and Lost equipment: Register Maintenance is disabled on the card; choosing such equipment on a new
  maintenance card (Role Center > New > Maintenance Record) gives `EquipmentFinalStatusErr`; an existing record of
  equipment disposed later can still be corrected.

## Risks and open questions
Resolved decisions (answered by the user, 2026-11-05):
- **Q1 Performed By: RESOLVED.** Free text, Text[100]. No relation to Employee or User.
- **Q2 "Future" reference date: RESOLVED (default kept).** `Today()`, the real calendar date.
- **Q3 Editing after creation: RESOLVED.** Editable, except Equipment No. and Maintenance No.
- **Q4 Equipment status: RESOLVED (default kept).** Registering maintenance does not change the equipment status.
- **Q5 Lost / Disposed equipment: RESOLVED, changed from revision 1.** Registering maintenance is **refused** for
  Lost and Disposed equipment (`EquipmentFinalStatusErr`, BR-M5). No status change. Applies to inserting records;
  corrections of existing records stay allowed.
- **Q6 Currency: RESOLVED (default kept).** Cost is in local currency, no currency code.
- **Q7 Scope of UI: RESOLVED (default kept).** Maintenance FactBox on equipment list and card, Register Maintenance
  and Maintenance actions, Role Center entries; no body subpage on the card; no dashboard tile.
- **Q8 Maintenance Type default: RESOLVED, changed from revision 1.** The type defaults to **Preventive**
  (`InitValue = Preventive`); the blank enum value is removed and no "type required" check exists. (The coordinator's
  message called this "Q7"; in this plan it is Q8.)
- **Q9 Number series for existing companies: RESOLVED (default kept).** Install creates EQMAINT; existing dev
  companies set it by hand (MT-SB0).
- **Q10 Tests: RESOLVED (default kept).** Deferred; test codeunit 50164 reserved, tester step skipped, MT-SB0 to
  MT-SB11 are the verification. Building them later needs the test-app fix in `docs/TODO.md` first (dependencies on
  Library Assert / Tests-TestLibraries, remove the old `test` property); vendor creation needs `Library - Purchase`.

Still open: none.

Risks:
- R1 Trigger-less writes (`Insert(false)`, `Modify(false)`, `Delete(false)`, `DeleteAll`, RapidStart without
  validation) bypass BR-M1 to BR-M5, as for every other rule in the app. In particular `Delete(false)` by code with D
  permission would remove a record; no EQM set grants D, so only SUPER-type users could do it. Document in help.
- R2 BR-M3 uses `Today()`; around midnight or with server/client time zones, "today" is the server's date. Accepted.
- R3 Deleting a Vendor used by maintenance records is not blocked (no subscription to base events); the records keep
  the vendor number and show a blank name. A guard would need al-event-finder (follow-up if wanted).
- R4 Equipment deleted by trigger-less code could leave records whose equipment no longer exists; the FlowField
  description is then blank. Accepted (same as R1).
- R5 Renaming equipment updates "Equipment No." on maintenance records through the table relation without running
  table 50105 triggers, so `EquipmentCannotChangeErr` does not fire. This is the wanted behavior; UNVERIFIED in the
  sandbox (MT-SB9), same open point as FR-006 R3.
- R6 "Performed By" can contain names of people (staff or external technicians). Classified CustomerContent like
  other business data; joins the open TODO item on personal-data classification.
- R7 Platform names and behaviors listed under "Platform names" (Vendor namespace, image names, `InitValue` on an enum
  field, RunPageMode Create pre-filling the link field) are not verified at planning time.
- R8 No automated tests (Q10): regressions are caught only by review and the sandbox checks.
- R9 Preventive as the default type means a user who forgets to change it records Corrective work as Preventive.
  Accepted by the user (Q8); the type is shown promoted on the card.
- R10 BR-M5 is checked when the record is inserted. Equipment that becomes Lost or Disposed while a new maintenance
  card is open (another user) is still refused at insert; a record inserted just before the status change stays valid.
  Accepted.
