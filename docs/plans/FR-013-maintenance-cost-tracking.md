# FR-013 Maintenance Cost Tracking

> Status: APPROVED by the user (2026-11-07) with the defaults for Q1-Q9. Open questions Q1-Q9 (see "Risks and open
> questions") were all accepted at their proposed default, and the plan is written with these defaults. **Q1 (which costs count), Q2 (what "category"
> means) and Q3 (what "average" means) change the design if they are answered differently.**
> Source: GitHub issue #32. Branch: `feature/FR-013-maintenance-cost-tracking` (cut from `main` at 92cd835, after the
> FR-012 merge).
> No events report. FR-013 only reads this app's own data: equipment (table 50100), categories (table 50101) and the
> posted maintenance history (table 50106). It subscribes to no standard events and changes no standard behavior, so
> al-event-finder is not needed.
> Scope: main app only. **Four new objects** (two queries, two chart pages), **four new FlowField/FlowFilter fields** on
> table 50100, **two new FlowFields** on the temporary cue table 50104, and changes to eight of the app's own objects plus
> one permission set. **No stored schema change** (FlowFields and FlowFilters are not stored). **No version bump**
> (app.json stays 29.0.0.0). **No upgrade logic.** Tests are deferred (Q8 default): test codeunit 50167 is reserved,
> and the tester step is skipped.
> Workflow for FR-013: planner -> (human approves plan) -> developer -> reviewer -> build -> **tester step SKIPPED
> (Q8)** -> documenter -> appsource-validator.

## Goal
Managers see what each piece of equipment has cost in maintenance, compared with what it cost to buy, so they can spot
assets where replacement is cheaper than further repair. The app shows four KPIs: Total Maintenance Cost, Average
Maintenance Cost, Maintenance Cost by Category and Maintenance Cost by Equipment. They appear on the equipment pages,
the dashboard and the Equipment Manager Role Center, and they are calculated live from the posted maintenance history.

### Requirement restated
- C-R1 Calculate the maintenance cost per equipment.
- C-R2 KPI Total Maintenance Cost (per equipment and overall).
- C-R3 KPI Average Maintenance Cost (per equipment and overall).
- C-R4 KPI Maintenance Cost by Category.
- C-R5 KPI Maintenance Cost by Equipment.
- C-R6 (business value, from the example) Compare the maintenance cost with the purchase cost, so excessive maintenance
  is visible. The example: Laptop A, Purchase Cost 1,200; maintenance 2025 = 500 and 2026 = 700; total 1,200, which
  equals the purchase cost. The yearly split means users must be able to see the cost of one period.

### Interpretation (defaults, see Q1-Q7)
- **Which costs count (Q1):** only **posted** maintenance, read from table 50106 "EQM Maintenance History Entry". Open
  records (table 50105) are work in progress: their cost can still change, and FR-012 has users post records with cost
  0 to end maintenance that was opened by mistake. Posted entries are read-only, so the KPIs are auditable and never
  change after the fact.
- **One definition across the app:** the existing "Total Maintenance Cost" in the Maintenance FactBox (page 50115)
  today sums **all** records in table 50105, open and posted (FR-011 Q3). It is switched to the same posted-only
  definition, so the FactBox, the Equipment list and the dashboard always show the same number. This is an intentional
  behavior change (see Compatibility).
- **Category (Q2):** the **equipment category** (table 50101, field "Category Code" on the equipment), not the
  maintenance type. The equipment's **current** category is used. History entries do not store the category (R1).
- **Average (Q3):** the average cost **per posted maintenance**: total cost divided by the number of posted entries,
  zero-cost entries included (Q6). On one equipment: its own entries. On the dashboard: all entries.
- **Period (Q4):** table 50100 gets a **Date Filter** (filter on "Maintenance Date") used by the cost FlowFields. On
  the Equipment list, the user sets it through "Filter totals by", which gives the yearly view of the example. The
  Maintenance FactBox, the dashboard tiles and the charts always show all-time totals (R5).
- **Comparison with the purchase cost (Q5):** a calculated **Maintenance Cost %** = Total Maintenance Cost / Purchase
  Cost x 100, rounded to one decimal. It is shown with the `Unfavorable` style when it is 100 or more (maintenance has
  cost at least as much as the equipment). The value is blank when the equipment has no purchase cost. The 100 %
  threshold is fixed. There is no setup field.
- **Currency (Q7):** all amounts are in local currency (LCY), as the Cost and Purchase Cost fields already are.

### What already exists and is reused
| Already present | Use in FR-013 |
|---|---|
| Table 50106 "EQM Maintenance History Entry" (FR-011): one read-only entry per posted record, field 8 Cost (LCY), field 4 "Maintenance Date", key `EquipmentDate` ("Equipment No.", "Maintenance Date") with `SumIndexFields = Cost`, `DrillDownPageId` = page 50117. | **The only cost source.** The SIFT key already supports Sum, Count and Average FlowFields per equipment with a date filter. No new key is needed. |
| Table 50100 "EQM Equipment" field 8 "Purchase Cost" (LCY), field 3 "Category Code"; style labels `UnfavorableStyleTok`, `StandardStyleTok`. | Basis of Maintenance Cost %; category grouping; style reuse. No new stored data. |
| Page 50115 "EQM Maintenance FactBox" (on Equipment Card and List), field `TotalMaintenanceCost`. | Re-pointed to the new FlowField; gets Average and Maintenance Cost %. |
| Codeunit 50108 `GetTotalMaintenanceCost` (sums table 50105). | Its only caller (page 50115) moves to the FlowField. **The procedure is removed** (internal, no other caller). |
| Temporary cue table 50104 and CardPart 50106 "EQM Equipment Cues" (FR-009), shown on page 50109 and Role Center 50110. | Two new cue FlowFields in a new cue group "Maintenance Costs". |
| FR-009 chart pattern: internal query, internal codeunit 50107 "EQM Dashboard Mgt." returning lists, CardPart with the System Application `BusinessChart` add-in, Refresh action, guarded `DataPointClicked`. | Copied for the two new charts. `ShowEquipmentByCategory` is reused for drill-down. |
| Page 50117 "EQM Maintenance History" (list of posted entries). | Drill-down target for cost tiles, FlowFields and the equipment chart. |

## Approach and rejected alternatives
- Chosen:
  - **Per equipment (C-R1, C-R2, C-R3, C-R5):** three FlowFields on table 50100 over table 50106: "Total Maintenance
    Cost" (Sum), "No. of Posted Maintenances" (Count) and "Average Maintenance Cost" (Average), all filtered by "Equipment
    No." and by a new FlowFilter "Date Filter" on "Maintenance Date". They use the existing SIFT key, need no code, and
    drill down to page 50117 on their own. A table procedure calculates Maintenance Cost % (C-R6).
  - **Equipment List** gets the cost columns, so "Filter totals by: Date Filter" gives the cost per period, and the
    filter pane can filter on the cost (for example Total Maintenance Cost > 1000).
  - **Maintenance FactBox** shows the posted total, the average and the percentage for the selected equipment.
  - **Overall KPIs (C-R2, C-R3):** two FlowFields on the temporary cue table: "Total Maintenance Cost" (Sum of all
    entries) and "Average Maintenance Cost" (Average of all entries), shown as tiles in a new cue group.
  - **By category (C-R4) and ranking by equipment (C-R5):** two internal queries (Sum of Cost grouped by equipment
    category, and grouped by equipment, sorted by cost descending and limited to the top 10) and two chart CardParts on
    the dashboard and the Role Center. Charts show the ranking, which a list cannot, because FlowField columns cannot be
    sorted.
- Rejected: summing open records too (table 50105). Their cost is not final, and cost-0 "cancel" postings (FR-012 Q4)
  would still be counted while open. Kept as the alternative in Q1.
- Rejected: a stored "Total Maintenance Cost" field on table 50100 that posting updates. It duplicates data that can
  disagree, needs an upgrade/backfill and a write in codeunit 50109. FlowFields over the SIFT key are exact and free.
- Rejected: a new "Maintenance Cost Analysis" page with a temporary buffer table filled from a query (sortable list).
  It adds a table and a page, and its data is a snapshot. The Equipment list with FlowFields plus the top-10 chart
  covers the issue. It can be added later if users need a sortable full ranking (Q9).
- Rejected: Power BI or Excel reports. They need a licence and setup, and are not requested.
- Rejected: storing the category on table 50106 (snapshot). It changes a read-only posted table and needs an upgrade;
  the issue does not ask for historical categories (R1).
- Rejected: a setup field for the "excessive" threshold. No requirement asks for it, so it would be invented data
  (Q5).
- Rejected: an event or IsHandled on the calculations. They are read-only reporting with no business rule a partner
  must override. Partners can add their own FlowFields through table extensions.

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50106, pages 50100-50117, codeunits 50103-50109,
queries 50100-50101, enums 50100-50103, page extension 50100, permission sets 50100-50102, permission set extension
50103, profile "EQM EQUIPMENT MANAGER". Test app: no objects; test codeunits 50150-50166 are reserved by FR-001 to
FR-012, none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Query | 50102 | EQM Maint. Cost by Category | New | Sum of posted maintenance cost grouped by equipment category (internal) |
| Query | 50103 | EQM Maint. Cost by Equipment | New | Sum of posted maintenance cost grouped by equipment, cost descending (internal) |
| Page | 50118 | EQM Category Cost Chart | New | CardPart, BusinessChart column chart: maintenance cost by category |
| Page | 50119 | EQM Equipment Cost Chart | New | CardPart, BusinessChart column chart: top 10 equipment by maintenance cost |
| Table | 50100 | EQM Equipment | Modify (own) | Fields 13 "Date Filter", 14 "Total Maintenance Cost", 15 "No. of Posted Maintenances", 16 "Average Maintenance Cost"; procedures `GetMaintenanceCostPercentage`, `GetMaintenanceCostStyle` |
| Table | 50104 | EQM Equipment Cue | Modify (own) | Fields 20 "Total Maintenance Cost", 21 "Average Maintenance Cost" |
| Codeunit | 50107 | EQM Dashboard Mgt. | Modify (own) | `GetMaintenanceCostByCategory`, `GetTopMaintenanceCostByEquipment`, `GetTopEquipmentLimit`, `ShowMaintenanceHistory` |
| Codeunit | 50108 | EQM Maintenance Mgt. | Modify (own) | Remove `GetTotalMaintenanceCost` (no caller left) |
| Page | 50100 | EQM Equipment List | Modify (own) | Four cost columns; Maintenance Cost % with style; AboutText |
| Page | 50106 | EQM Equipment Cues | Modify (own) | New cue group "Maintenance Costs" with two tiles |
| Page | 50109 | EQM Equipment Dashboard | Modify (own) | Two new chart parts; Refresh covers them; AboutText; search terms |
| Page | 50110 | EQM Equipment Manager RC | Modify (own) | Two new chart parts; Embedding action Maintenance History |
| Page | 50115 | EQM Maintenance FactBox | Modify (own) | Total re-pointed to the posted FlowField; Average and Maintenance Cost % added |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | X on the two queries and two pages |

Not changed: tables 50101-50103, 50105, 50106; pages 50101-50105, 50107, 50108, 50111-50114, 50116, 50117; codeunits
50103-50106, 50109; queries 50100-50101; enums; page extension 50100; permission sets 50101-50102; permission set
extension 50103; the profile; `app/app.json`; `test/`.
New files, folder `app/src/Dashboard/`, namespace `MiguelCarvalho.EquipmentManagement`:
- `EQMMaintCostByCategory.Query.al`
- `EQMMaintCostByEquipment.Query.al`
- `EQMCategoryCostChart.Page.al`
- `EQMEquipmentCostChart.Page.al`

Next free IDs after FR-013: tables 50107, pages 50120, codeunits 50110, queries 50104, enums 50104, page extensions
50101, permission sets 50104. Test app: test codeunit **50167 reserved for FR-013 "EQM Maintenance Cost Tests"**, not
built now (Q8).

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report. Use a named fallback only where one is given, and report that you used it.
- Object names are at most 30 characters: "EQM Maint. Cost by Category" (27), "EQM Maint. Cost by Equipment" (28),
  "EQM Category Cost Chart" (23), "EQM Equipment Cost Chart" (24). Field names: "No. of Posted Maintenances" (26),
  "Average Maintenance Cost" (24), "Total Maintenance Cost" (22).
- `CalcFormula = average(...)` is valid for a Decimal FlowField and returns 0 when no row matches.
- Enum "Business Chart Data Type" has a value `Decimal` (namespace `System.Visualization`), accepted by `AddMeasure`
  and by `SetValue` with a Decimal value. Fallback: none; report.
- A query `column` with `Method = Sum` accepts `ColumnFilter = <Column> = filter(>0)` (applied after grouping,
  HAVING). Fallback: drop the ColumnFilter and skip rows with cost 0 in the codeunit loop instead (same result).
- A query `OrderBy` can reference the Sum column (`descending(TotalCost)`) together with a second column.
- The query runtime method `TopNumberOfRows(Integer)` can be called before `Open()`. Fallback: stop reading after N
  rows in the codeunit loop (same result).
- A cue control bound to a Decimal FlowField with `AutoFormatType = 1` renders as a tile, and drill-down opens the page
  given in `DrillDownPageId` filtered by the CalcFormula.
- On a list page, a FlowFilter field of the source table appears under "Filter totals by", and `Rec.CalcFields` in
  `OnAfterGetRecord` uses that filter.

### Table 50100 "EQM Equipment" (change)
New fields, after field 12 "No. Series" (all inherit `DataClassification = CustomerContent` from the table; do not set
it on the fields):

| ID | Name | Type | Class | Definition | Caption | ToolTip |
|---|---|---|---|---|---|---|
| 13 | "Date Filter" | Date | FlowFilter | `FieldClass = FlowFilter` | Date Filter | 'Specifies a date filter for the maintenance cost fields. Only maintenance with a maintenance date within the filter is included.' |
| 14 | "Total Maintenance Cost" | Decimal | FlowField | `sum("EQM Maintenance History Entry".Cost where("Equipment No." = field("No."), "Maintenance Date" = field("Date Filter")))` | Total Maintenance Cost | 'Specifies the total cost of the posted maintenance of the equipment, in local currency. Open maintenance records are included when they are posted. Use the date filter to see the cost of a period. Choose the amount to see the maintenance history.' |
| 15 | "No. of Posted Maintenances" | Integer | FlowField | `count("EQM Maintenance History Entry" where("Equipment No." = field("No."), "Maintenance Date" = field("Date Filter")))` | No. of Posted Maintenances | 'Specifies how many maintenance records of the equipment have been posted. Use the date filter to count the maintenance of a period. Choose the number to see the maintenance history.' |
| 16 | "Average Maintenance Cost" | Decimal | FlowField | `average("EQM Maintenance History Entry".Cost where("Equipment No." = field("No."), "Maintenance Date" = field("Date Filter")))` | Average Maintenance Cost | 'Specifies the average cost of one posted maintenance of the equipment, in local currency. Maintenance with a cost of zero is included. Use the date filter to see the average of a period.' |

- Fields 14 and 16: `AutoFormatType = 1`. Fields 14-16: `Editable = false`.
- No change to keys, field groups, triggers, events or existing procedures. No new labels.
- New procedure `internal procedure GetMaintenanceCostPercentage(): Decimal`, in this order:
  1. When "Purchase Cost" = 0: exit(0).
  2. `CalcFields("Total Maintenance Cost")` (uses the "Date Filter" currently set on the record).
  3. exit(Round("Total Maintenance Cost" / "Purchase Cost" * 100, 0.1)).
  Doc comment: "Returns the total posted maintenance cost as a percentage of the purchase cost, rounded to one decimal.
  Uses the date filter set on the record. Returns 0 when the equipment has no purchase cost."
- New procedure `internal procedure GetMaintenanceCostStyle(MaintenanceCostPercentage: Decimal): Text`: when
  MaintenanceCostPercentage >= 100 exit(`UnfavorableStyleTok`), else exit(`StandardStyleTok`) (both labels exist).
  Doc comment: "Returns the page style for the maintenance cost percentage. Unfavorable when maintenance has cost at
  least as much as the purchase cost."
- Place both procedures after `GetStatusStyle`, before `GetSetup`.

### Table 50104 "EQM Equipment Cue" (change)
New fields after field 15 (FlowFields, `Editable = false`, `AutoFormatType = 1`):

| ID | Name | Type | Definition | Caption | ToolTip |
|---|---|---|---|---|---|
| 20 | "Total Maintenance Cost" | Decimal | `sum("EQM Maintenance History Entry".Cost)` | Total Maintenance Cost | 'Specifies the total cost of all posted maintenance, in local currency.' |
| 21 | "Average Maintenance Cost" | Decimal | `average("EQM Maintenance History Entry".Cost)` | Average Maintenance Cost | 'Specifies the average cost of one posted maintenance, in local currency. Maintenance with a cost of zero is included.' |

### Query 50102 "EQM Maint. Cost by Category" (new)
File `EQMMaintCostByCategory.Query.al`.
- `Caption = 'Maintenance Cost by Category'`, `QueryType = Normal`, `Access = Internal`, `DataAccessIntent = ReadOnly`.
  No `QueryCategory`.
- `dataitem(Equipment; "EQM Equipment")` with `column(CategoryCode; "Category Code")`, and nested
  `dataitem(HistoryEntry; "EQM Maintenance History Entry")` with `DataItemLink = "Equipment No." = Equipment."No."`,
  `SqlJoinType = InnerJoin`, and `column(TotalCost; Cost)` with `Method = Sum` and `ColumnFilter = TotalCost = filter(>0)`.
- `OrderBy = descending(TotalCost), ascending(CategoryCode)`.

### Query 50103 "EQM Maint. Cost by Equipment" (new)
File `EQMMaintCostByEquipment.Query.al`.
- `Caption = 'Maintenance Cost by Equipment'`, `QueryType = Normal`, `Access = Internal`, `DataAccessIntent = ReadOnly`.
- `dataitem(HistoryEntry; "EQM Maintenance History Entry")` with `column(EquipmentNo; "Equipment No.")` and
  `column(TotalCost; Cost)` with `Method = Sum` and `ColumnFilter = TotalCost = filter(>0)`.
- `OrderBy = descending(TotalCost), ascending(EquipmentNo)`. No `TopNumberOfRows` property (set at runtime).

### Codeunit 50107 "EQM Dashboard Mgt." (change)
Add, each with an XML doc comment, after the existing procedures:
1. `internal procedure GetMaintenanceCostByCategory(var CategoryCodes: List of [Code[20]]; var MaintenanceCosts: List of [Decimal])`
   - Clear both lists. Open query 50102, add `CategoryCode` and `TotalCost` of every row in row order, close.
   - Doc: "Returns the posted maintenance cost per equipment category, highest cost first. Categories without posted
     maintenance cost are not returned. The current category of each equipment is used."
2. `internal procedure GetTopMaintenanceCostByEquipment(NumberOfEquipment: Integer; var EquipmentNos: List of [Code[20]]; var MaintenanceCosts: List of [Decimal])`
   - Clear both lists. When NumberOfEquipment <= 0: exit. `TopNumberOfRows(NumberOfEquipment)` on query 50103, open,
     add `EquipmentNo` and `TotalCost` of every row, close.
   - Doc: "Returns the equipment with the highest posted maintenance cost, highest first, at most NumberOfEquipment
     entries. Equipment without posted maintenance cost is not returned."
3. `internal procedure GetTopEquipmentLimit(): Integer` - exit(10). Doc: "Returns how many equipment records the
   maintenance cost chart shows."
4. `internal procedure ShowMaintenanceHistory(EquipmentNo: Code[20])` - local `MaintenanceHistoryEntry: Record "EQM
   Maintenance History Entry"`, `SetRange("Equipment No.", EquipmentNo)`, `Page.Run(Page::"EQM Maintenance History",
   MaintenanceHistoryEntry)`. Doc: "Opens the posted maintenance history filtered to one piece of equipment."
- Add a `/// <summary>` to the codeunit (it has none today): "Data and drill-down helpers for the equipment dashboard
  tiles and charts."

### Codeunit 50108 "EQM Maintenance Mgt." (change)
- Remove `GetTotalMaintenanceCost` and its doc comment. Before removing, search the whole `app/` and `test/` for the
  name; the only caller today is page 50115. If another caller exists, stop and report.

### Page 50118 "EQM Category Cost Chart" (new)
File `EQMCategoryCostChart.Page.al`. Same structure as page 50107 "EQM Equipment Category Chart" (usercontrol
`Chart; BusinessChart` with `AddInReady`, `Refresh` and `DataPointClicked` triggers; `Refresh` action; `RefreshChart`
internal procedure; `using System.Integration;` and `using System.Visualization;`), with these differences:
- `Caption = 'Maintenance Cost by Category'`, `PageType = CardPart`, `ApplicationArea = All`.
- `var`: `BusinessChart`, `DashboardMgt`, `CategoryCodes: List of [Code[20]]`, `CategoryLabels: List of [Text]`,
  `MaintenanceCosts: List of [Decimal]`, `IsChartReady: Boolean`,
  `MaintenanceCostMeasureLbl: Label 'Maintenance Cost'`, `CategoryDimensionLbl: Label 'Category'`,
  `BlankCategoryLbl: Label '(blank)', Comment = 'Shown in the chart for equipment without a category'`.
- `UpdateChart()`: exit when not ready; `DashboardMgt.GetMaintenanceCostByCategory(CategoryCodes, MaintenanceCosts)`;
  `Initialize()`; `AddMeasure(MaintenanceCostMeasureLbl, 1, Data Type Decimal, Chart Type Column)`;
  `SetXDimension(CategoryDimensionLbl, Data Type String)`; clear `CategoryLabels`; for each index: the label is
  `BlankCategoryLbl` when the code is blank, otherwise `Format(code)`; add it to `CategoryLabels`,
  `AddDataRowWithXDimension(label)`, `SetValue(MaintenanceCostMeasureLbl, index - 1, cost)`; `Update(CurrPage.Chart)`.
- `DataPointClicked`: same guards as page 50107; look the label up in `CategoryLabels`; on a match call the existing
  `DashboardMgt.ShowEquipmentByCategory(CategoryCodes.Get(index))` (the Equipment list then shows the cost column).
- Refresh action: `Caption = 'Refresh'`, `ToolTip = 'Update the chart with the current maintenance costs.'`,
  `Image = Refresh`.

### Page 50119 "EQM Equipment Cost Chart" (new)
File `EQMEquipmentCostChart.Page.al`. Same structure as page 50118, with these differences:
- `Caption = 'Top 10 Equipment by Maintenance Cost'`.
- `var`: `EquipmentNos: List of [Code[20]]`, `EquipmentLabels: List of [Text]`, `MaintenanceCosts: List of [Decimal]`,
  `MaintenanceCostMeasureLbl: Label 'Maintenance Cost'`, `EquipmentDimensionLbl: Label 'Equipment'`. No blank label
  (equipment numbers are never blank).
- `UpdateChart()`: `DashboardMgt.GetTopMaintenanceCostByEquipment(DashboardMgt.GetTopEquipmentLimit(), EquipmentNos,
  MaintenanceCosts)`; X label = `Format(EquipmentNo)`; Column chart, Decimal measure.
- `DataPointClicked`: look the label up in `EquipmentLabels`; on a match call
  `DashboardMgt.ShowMaintenanceHistory(EquipmentNos.Get(index))`.
- Refresh action: same Caption, ToolTip and Image as page 50118.

### Page 50106 "EQM Equipment Cues" (change)
- After `cuegroup(Equipment)`, add `cuegroup(MaintenanceCosts)` with `Caption = 'Maintenance Costs'` and two controls
  (control name = field name, no ToolTip on the controls): "Total Maintenance Cost", "Average Maintenance Cost", each with
  `DrillDownPageId = "EQM Maintenance History"`.
- Nothing else changes (`RefreshCues` already updates every tile).

### Page 50109 "EQM Equipment Dashboard" (change)
- `area(Content)`: after `part(StatusChart ...)` add `part(CategoryCostChart; "EQM Category Cost Chart")` and
  `part(EquipmentCostChart; "EQM Equipment Cost Chart")`.
- Action `Refresh` `OnAction`: also call `CurrPage.CategoryCostChart.Page.RefreshChart()` and
  `CurrPage.EquipmentCostChart.Page.RefreshChart()`. ToolTip becomes: 'Update the tiles and charts with the current equipment and maintenance data.'
- `AboutText` becomes: 'The tiles count your equipment by status and show the total and average cost of posted maintenance. **Total Equipment** includes lost and disposed equipment. The charts show how your equipment is spread over categories and statuses, which categories cost the most in maintenance, and the ten pieces of equipment with the highest maintenance cost. Choose a tile or a chart segment to see the details. Choose **Refresh** to update the numbers.'
- `AdditionalSearchTerms` becomes: 'equipment kpi, equipment overview, equipment chart, maintenance cost, maintenance kpi'.

### Page 50110 "EQM Equipment Manager RC" (change)
- `area(RoleCenter)`: after `part(StatusChart ...)` add the same two parts as on page 50109.
- `area(Embedding)`: after `MaintenanceList`, add `action(MaintenanceHistoryList)`: `Caption = 'Maintenance History'`,
  `ToolTip = 'Open the posted maintenance history of all equipment, with costs.'`,
  `RunObject = page "EQM Maintenance History"`.

### Page 50100 "EQM Equipment List" (change)
- Repeater, after `"Purchase Cost"`, add in this order:
  - `"Total Maintenance Cost"` (visible);
  - `"No. of Posted Maintenances"` (`Visible = false`);
  - `"Average Maintenance Cost"` (`Visible = false`);
  - `field(MaintenanceCostPct; MaintenanceCostPct)`: `Caption = 'Maintenance Cost %'`, `DecimalPlaces = 0 : 1`,
    `BlankZero = true`, `StyleExpr = MaintenanceCostStyle`, `Visible = false`,
    `ToolTip = 'Specifies the total posted maintenance cost as a percentage of the purchase cost. A value of 100 or more means that maintenance has cost as much as the equipment itself, which may justify replacing it. It is blank when the equipment has no purchase cost or no posted maintenance.'`
- `var`: add `MaintenanceCostPct: Decimal`, `MaintenanceCostStyle: Text`.
- `OnAfterGetRecord`: add `MaintenanceCostPct := Rec.GetMaintenanceCostPercentage();` and
  `MaintenanceCostStyle := Rec.GetMaintenanceCostStyle(MaintenanceCostPct);`.
- `AboutText` becomes: 'This list shows all your equipment. Use **Search** to find equipment by its number, serial number, or any other column you can see. To filter by category, status, or assigned employee, open the filter pane and add a filter on that field. You can also choose a status view at the top of the list. **Total Maintenance Cost** shows the cost of posted maintenance; to see the cost of one period, set **Date Filter** under **Filter totals by**.'
- Nothing else changes.

### Page 50115 "EQM Maintenance FactBox" (change)
- Field `TotalMaintenanceCost`: keep the control name, bind it to `Rec."Total Maintenance Cost"` instead of the page
  variable, and remove its `Caption`, `AutoFormatType` and `ToolTip` (inherited from the table field). Drill-down to
  page 50117 is automatic (FlowField).
- After it add `field(AverageMaintenanceCost; Rec."Average Maintenance Cost")` and
  `field(MaintenanceCostPct; MaintenanceCostPct)` with the same Caption, DecimalPlaces, BlankZero, StyleExpr and
  ToolTip as on page 50100 (variable `MaintenanceCostStyle`).
- `var`: remove `TotalMaintenanceCost`; add `MaintenanceCostPct: Decimal`, `MaintenanceCostStyle: Text`.
- `ClearFactBox`: remove the `TotalMaintenanceCost` line; set `MaintenanceCostPct := 0` and `MaintenanceCostStyle := ''`.
- `UpdateFactBox`: replace the last line (`TotalMaintenanceCost := MaintenanceMgt.GetTotalMaintenanceCost(...)`) with
  `MaintenanceCostPct := Rec.GetMaintenanceCostPercentage();` and
  `MaintenanceCostStyle := Rec.GetMaintenanceCostStyle(MaintenanceCostPct);`. Everything before it (including the
  early exit when there are no maintenance records) stays as it is; equipment without records has no posted cost, so
  the cleared 0 is correct.
- `SubPageLink` is unchanged (no "Date Filter" link), so the FactBox always shows all-time values (R5).

### Permission sets
- `EQM - Reader` (50100): add `query "EQM Maint. Cost by Category" = X`, `query "EQM Maint. Cost by Equipment" = X`,
  `page "EQM Category Cost Chart" = X`, `page "EQM Equipment Cost Chart" = X`. No `tabledata` change: Reader already has
  R on tables 50100, 50101 and 50106.

### app.json, translations
- **app.json: no change.** Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf` (new field captions and ToolTips, cue fields,
  query and page captions, chart labels including `BlankCategoryLbl` with its comment, changed AboutTexts and
  AdditionalSearchTerms). Commit it; never edit it by hand. No inline `CaptionML`.

## Data model and upgrade impact
- Table 50100: one FlowFilter and three FlowFields (fields 13-16). They are not stored, so no SQL column is added.
- Table 50104: two FlowFields; the table is temporary (no SQL table).
- No new key. Table 50106 key `EquipmentDate` with `SumIndexFields = Cost` already serves Sum, Count and Average per
  equipment and date range. The overall cue sums read the same SIFT index.
- DataClassification: inherited `CustomerContent` from the tables; nothing set on the new fields.
- Upgrade codeunit: **not needed.** Nothing stored changes, nothing is released, and the version stays 29.0.0.0.
- Existing data: KPIs include all history entries already posted in development (FR-011/FR-012). Open records are not
  counted until they are posted.
- Volume: the Equipment list calculates up to four FlowField values per visible row (one SIFT read each); the dashboard
  runs two extra cue sums and two grouped queries on open and Refresh.

## Events
**Standard BC events: none.** No events report is required. Subscribed: none.
Published: **none.** The feature is read-only reporting with no business rule to override, so no IsHandled is needed.
Partners can add their own FlowFields with table extensions and extend the pages. The queries, the codeunit procedures
and the table procedures are internal. Existing events (FR-011 posting events, FR-012 status events) are unchanged.

## Permissions
- **EQM - Reader:** X on the two new queries and two new pages. Readers see all cost KPIs (they can already see Cost
  and Purchase Cost today).
- **EQM - Manager / EQM - Administrator:** inherit Reader; nothing to add.
- Charts need the System Application BusinessChart objects, granted by D365 BASIC (as in FR-009 R3).

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See cost columns, FactBox costs and Maintenance Cost % | yes | yes | yes |
| See cost tiles and cost charts on the dashboard and Role Center | yes | yes | yes |
| Drill down to the maintenance history | yes | yes | yes |
| Change any cost value | no (FlowFields are read-only) | no | no |

## Compatibility
- AppSource mode, development phase: nothing is released, there is no baseline, and no Obsolete handling is needed.
- New public surface that becomes a contract after the first release: fields 13-16 on table 50100 (public table) and
  pages 50118-50119. Queries 50102-50103, the new codeunit 50107 procedures, and the table 50100 procedures are
  internal. Cue table 50104 is `Access = Internal`.
- Removing `GetTotalMaintenanceCost` from codeunit 50108 is safe: the codeunit is `Access = Internal`.
- **Behavior change (intentional):** the Maintenance FactBox "Total Maintenance Cost" changes from "all records, open
  and posted" (FR-011 Q3) to "posted maintenance only". The control name `TotalMaintenanceCost` is kept, so
  personalizations still apply. FR-011 scenario H36 ("FactBox total includes both") no longer holds for the total; the
  record count still includes both.
- No control, action or group is renamed or removed.
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-013-maintenance-cost-tracking.md` and `docs/help/FR-013-maintenance-cost-tracking.md`: what
    counts (posted only, LCY), the four KPIs and where they appear, the Date Filter for periods, Maintenance Cost % and
    the 100 % highlight, the current category rule, the top-10 chart, drill-downs, roles.
  - `docs/features|help/FR-009-dashboard-kpis.md`: new tiles and charts.
  - `docs/features|help/FR-011-maintenance-history.md`: the FactBox total now counts posted maintenance only.
  - `docs/help/FR-007-equipment-list-management.md`: new cost columns and the Date Filter.
  - `CHANGELOG.md`: new top section `## FR-013 Maintenance Cost Tracking (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-013 sandbox checks" with CS-SB1 to CS-SB10.

## Test scenarios
**No automated tests in this iteration** (Q8 default, as in FR-003 to FR-012). Test codeunit 50167 "EQM Maintenance
Cost Tests" is reserved, and the tester step is skipped. The list is the reference for the developer and reviewer and
for the tests the user writes later (needs the test-app fix in `docs/TODO.md` first).

Test data, unless stated:
- `PrevYearDate` = 1 January of the year before `Today()`; `CurrYearDate` = 1 January of the year of `Today()` (both
  are not in the future, as FR-010 requires).
- Categories LAPTOP and PHONE (active). History entries are created by registering a record (Init, Validate,
  `Insert(true)`) and posting it with `Codeunit.Run(Codeunit::"EQM Maintenance-Post", Record)`.
- Equipment:
  - EA "Laptop A": LAPTOP, Purchase Cost 1,200. Posted maintenance: 500 on PrevYearDate and 700 on CurrYearDate.
  - EB: LAPTOP, Purchase Cost 1,000. Posted: 100 on CurrYearDate. Plus one **open** record with cost 400.
  - EC: PHONE, Purchase Cost 0. Posted: 300 and 0 on CurrYearDate.
  - ED: PHONE, Purchase Cost 800. No maintenance.
- Totals: all posted entries = 500 + 700 + 100 + 300 + 0 = 1,600 over 5 entries.

Per equipment (C-R1, C-R2, C-R3, C-R6)
- C1 Given EA, when its FlowFields are calculated without a date filter, then Total Maintenance Cost = 1,200, No. of
  Posted Maintenances = 2, Average Maintenance Cost = 600, `GetMaintenanceCostPercentage` = 100 and
  `GetMaintenanceCostStyle(100)` = 'Unfavorable' (the issue example).
- C2 Given EA with "Date Filter" = PrevYearDate..(31 December of that year), then Total = 500, count = 1, average = 500,
  percentage = 41.7. With the current year: Total = 700, percentage = 58.3.
- C3 (negative) Given EB with one posted (100) and one open (400) record, then Total = 100 and count = 1 (open records
  are not counted, Q1); percentage = 10 and the style is 'Standard'.
- C4 Given EB, when the open record is posted, then Total = 500 and count = 2.
- C5 (negative) Given EC with Purchase Cost 0, then Total = 300, count = 2, average = 150 (the zero-cost entry counts,
  Q6), and `GetMaintenanceCostPercentage` = 0 with no division error.
- C6 (negative) Given ED without maintenance, then Total = 0, count = 0, average = 0, percentage = 0, no error.
- C7 Given the percentage values 99.9, 100 and 250, then `GetMaintenanceCostStyle` returns 'Standard', 'Unfavorable'
  and 'Unfavorable'.
- C8 Given an open record of EB whose Cost is changed from 400 to 450 (`Modify(true)`), then Total for EB is
  unchanged (100).
- C9 Given EA renamed to EA2, then the FlowFields of EA2 still return 1,200 (history entries follow the rename; see
  FR-011 R2).

Overall KPIs (C-R2, C-R3)
- C10 Given the test data, when page 50106 (TestPage) is opened, then Total Maintenance Cost = 1,600 and Average
  Maintenance Cost = 320.
- C11 (negative) Given no history entries, then both tiles show 0 and no error is raised.
- C12 Given the Total Maintenance Cost tile, when it is drilled down (`Trap` on page 50117), then the history list shows
  all five entries; the Average tile opens the same list.
- C13 Given page 50106 open, when another record is posted with cost 100 and `RefreshCues` runs, then Total = 1,700
  and Average = 283.33.

By category (C-R4)
- C14 Given the test data, when `GetMaintenanceCostByCategory` is called, then CategoryCodes = [LAPTOP, PHONE] and
  MaintenanceCosts = [1,300, 300] (EB's open record not included; highest first).
- C15 (negative) Given no history entries, then both lists are empty and no error is raised; given filled lists from an
  earlier call, they are cleared, not appended.
- C16 (negative) Given test data where EC has only its zero-cost posted entry (no 300 entry), then PHONE is not
  returned (only categories with a cost above 0 appear).
- C17 Given EC moved from PHONE to LAPTOP after its maintenance was posted, then LAPTOP = 1,600 and PHONE is not returned
  (the current category is used, R1).
- C18 Given equipment with a blank "Category Code" (set with `Modify(false)`) and a posted entry of 50, then a row with
  code '' and cost 50 is returned, and the chart label is '(blank)'.

By equipment (C-R5)
- C19 Given the test data, when `GetTopMaintenanceCostByEquipment(10, ...)` is called, then EquipmentNos = [EA, EC, EB]
  and MaintenanceCosts = [1,200, 300, 100]; ED is not returned.
- C20 Given 12 equipment records each with a different posted cost, when it is called with 10, then exactly the 10
  highest are returned, highest first.
- C21 Given two equipment records with the same total cost, then they are returned in ascending equipment number order.
- C22 (negative) Given NumberOfEquipment = 0, then both lists are empty and no error is raised.
- C23 Given `ShowMaintenanceHistory(EA)` (`Trap` on page 50117), then the page shows exactly the two EA entries.

Pages
- C24 Given the Equipment List (TestPage) on EA, then Total Maintenance Cost = 1,200 and Maintenance Cost % = 100 with
  style 'Unfavorable'; on EC the percentage is blank; drilling down on Total opens page 50117 filtered on EA.
- C25 Given the Equipment List with "Date Filter" set to the previous year, then EA shows Total 500 and percentage 41.7.
- C26 Given the Maintenance FactBox on EB, then No. of Maintenance Records = 2 (open and posted, unchanged), Open
  Maintenance Records = 1, Total Maintenance Cost = 100 (posted only), Average = 100, percentage = 10.
- C27 Given the FactBox on ED, then all cost fields are 0 or blank and no error is raised.
- C28 Given page 50109 (TestPage), when Refresh is invoked, then no error is raised (the charts themselves are checked
  manually, CS-SB4).
- C29 Given any page with the new fields, then none of the cost fields is editable.

Permissions (`TestPermissions = Restrictive`, with D365 BASIC)
- C30 Reader: the Equipment List, the FactBox and page 50106 show the cost values; `GetMaintenanceCostByCategory` and
  `GetTopMaintenanceCostByEquipment` run without a permission error.
- C31 (negative) A user with D365 BASIC but no EQM set: opening page 50109 raises a permission error (unchanged FR-009
  N6).

Regression
- C32 Given FR-009 data, then the six equipment tiles and the two FR-009 charts still return the same values (K1, G1,
  S1 of FR-009).

### Manual sandbox checks (for the user)
- CS-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` contains the new texts.
- CS-SB2 Equipment List: Total Maintenance Cost column visible; the hidden columns can be shown; "Filter totals by:
  Date Filter" changes the totals; filter pane on Total Maintenance Cost > 1000 works.
- CS-SB3 Equipment Card and List FactBox: Total, Average and Maintenance Cost % shown; 100 % or more is shown in the
  Unfavorable style; drill-down on Total opens the history.
- CS-SB4 Dashboard and Role Center: the Maintenance Costs tile group renders amounts readably (record the format), the
  two new charts show bars, clicking a category bar opens the Equipment list filtered on that category, clicking an
  equipment bar opens its maintenance history; Refresh updates all charts.
- CS-SB5 With no posted maintenance, the new charts are empty and no error appears.
- CS-SB6 Post a record and come back to the Role Center: the tiles update (RefreshOnActivate); the charts update after
  Refresh.
- CS-SB7 Non-SUPER Reader sees all of the above with no permission error.
- CS-SB8 Reproduce the issue example (Laptop A): 500 last year, 700 this year, purchase cost 1,200: Total 1,200 and
  100 % in red.
- CS-SB9 Teaching tips of pages 50100 and 50109 show the new texts; Tell Me finds the dashboard with "maintenance cost".
- CS-SB10 Role Center Embedding shows Maintenance History and it opens page 50117.

## Risks and open questions
Open questions (each has the default used in this plan; answer to change it):
- **Q1 Which costs count.** Default: posted maintenance only (table 50106), and the FactBox total is switched to the
  same rule. Alternative: open and posted records (table 50105). Then the FlowFields and queries read table 50105
  instead (it has the same SIFT key), and the FactBox stays as it is. **Changes the design if answered differently.**
- **Q2 What "Maintenance Cost by Category" means.** Default: the equipment category. Alternative: the maintenance type
  (Preventive, Corrective, Inspection, Upgrade), or both. Both would add one query and one chart (or a cue per type).
  **Changes the design if answered differently.**
- **Q3 What "Average Maintenance Cost" means.** Default: the average per posted maintenance. Alternative: the average
  per equipment (total cost / number of equipment with maintenance, or / all equipment). Then the overall tile becomes
  calculated in code instead of a FlowField. **Changes the design if answered differently.**
- **Q4 Periods.** Default: Date Filter on the Equipment list ("Filter totals by"); FactBox, dashboard and charts are
  all-time. Alternative: dashboard tiles for this year / last year, or a period selector on the dashboard.
- **Q5 "Excessive" threshold.** Default: Maintenance Cost % with the Unfavorable style at 100 % or more, fixed.
  Alternative: a threshold field in Equipment Setup.
- **Q6 Zero-cost postings** (FR-012 "cancel by posting with cost 0"). Default: they count in the number of
  maintenances and lower the average. Alternative: exclude Cost = 0 from the count and the average (filter
  `Cost = filter(<>0)` in the Count and Average FlowFields only).
- **Q7 Currency.** Default: LCY only, as the existing Cost and Purchase Cost fields. No action.
- **Q8 Automated tests.** Default: deferred, as in FR-003 to FR-012; test codeunit 50167 reserved, tester step
  skipped, CS-SB1 to CS-SB10 are the verification.
- **Q9 Full sortable ranking.** Default: not built; the top-10 chart shows the ranking and the Equipment list allows
  filtering by cost. Alternative: a "Maintenance Cost Analysis" list page on a temporary buffer table (one new table,
  one new page).

Risks:
- R1 The category KPI uses each equipment's **current** category. Moving equipment to another category moves its whole
  maintenance cost history with it (C17). Accepted; snapshotting the category would change read-only table 50106.
- R2 FlowField columns cannot be sorted on the Equipment list. Ranking is only in the top-10 chart (Q9).
- R3 Platform behaviors listed under "Platform names and behaviors to verify" (Average FlowField, Decimal chart data
  type, ColumnFilter on Sum columns, TopNumberOfRows, decimal cue rendering) are not verified at planning time.
- R4 The chart queries use `DataAccessIntent = ReadOnly`, while the cue FlowFields read the primary database; right
  after posting, tiles and charts may briefly disagree (same as FR-009 R10).
- R5 The Equipment list respects the Date Filter, but the FactBox always shows all-time values. Users may see two
  different totals for the same equipment while a date filter is set. Documented in the help; linking "Date Filter"
  in `SubPageLink` is a possible follow-up.
- R6 The FactBox total no longer matches "all maintenance records"; users who compared it with the Maintenance Records
  list (which shows open records too) see a lower number. Documented as a behavior change.
- R7 Zero-cost "cancel" postings lower the average (Q6).
- R8 Equipment rename cascades into table 50106 (FR-011 R2, unverified); the FlowFields follow the rename only if that
  cascade works.
- R9 No automated tests (Q8): regressions are caught only by review and the sandbox checks.
