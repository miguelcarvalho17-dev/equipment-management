# FR-009 Dashboard and KPIs

> Status: **APPROVED** by the user. Q1 = option B (own Role Center plus profile). Q2-Q8 are confirmed as the defaults.
> All questions are resolved (see the end of the plan), and the developer works from this version.
> Source: GitHub issue #15. Branch: `feature/FR-009-dashboard-kpis`.
> No events report: FR-009 only adds this app's own pages, queries, a temporary cue table, a codeunit, a Role Center and
> a profile, plus one navigation action on its own list page 50100. It subscribes to no events and changes no standard
> behavior, so al-event-finder is not needed.
> Scope: main app only. **Ten new objects (nine with IDs, plus one profile) and two changed objects. No change to any
> stored table or key, no version bump** (app.json stays 29.0.0.0, as in FR-004 to FR-008). **No upgrade logic.** **No
> automated tests** (Q6 resolved: deferred, as in FR-003 to FR-008; the scenarios are a reference only).
> Workflow for FR-009: developer -> reviewer -> build -> **tester step SKIPPED (Q6)** -> documenter ->
> appsource-validator.

## Goal
Managers get a dashboard with six KPI tiles (Total, Available, Assigned, In Maintenance, Lost and Disposed equipment)
and two charts: equipment by category and equipment by status. The dashboard is the home page of a new **Equipment
Manager** role (own Role Center and profile). For users in any other role it is also a standalone Equipment Dashboard
page, found through Tell Me and from the Equipment list. Every tile and every chart data point opens the Equipment list,
filtered to the equipment behind the number.

### Requirement restated
- D-R1 A management dashboard page.
- D-R2 KPIs: Total Equipment, Available Equipment, Assigned Equipment, Equipment in Maintenance, Lost Equipment,
  Disposed Equipment.
- D-R3 Visual indicator: Equipment by Category.
- D-R4 Visual indicator: Equipment by Status.

### Interpretation (resolved, see Q2-Q5)
- Total Equipment counts every equipment record, whatever its status, Lost and Disposed included (Q2). With the five
  standard statuses, Total = Available + Assigned + In Maintenance + Lost + Disposed. If an extension adds a status, its
  records count in Total but have no tile.
- Equipment by Category counts every equipment record per category, all statuses included. It shows only categories
  that have at least one equipment record, ordered by category code and labelled with the code (Q3).
- Equipment by Status shows one data point for every value of enum "EQM Equipment Status", in enum (ordinal) order,
  zero counts included: Available, Assigned, In Maintenance, Disposed, Lost, then any values added by extensions (Q3).
- The numbers are live counts, computed when the page opens or when the user chooses Refresh. Nothing is stored and
  nothing is cached.

## Approach and rejected alternatives
- Chosen:
  - **KPIs:** a cue table "EQM Equipment Cue" with `TableType = Temporary` and six `Count` FlowFields on table 50100,
    shown as tiles by a `CardPart` with one `cuegroup`. This is the standard BC cue pattern. Drill-down needs no code,
    because a Count FlowField opens page 50100 filtered by the FlowField's `CalcFormula`. Because the table is
    temporary, no row is stored, the page needs no insert permission, and there is no upgrade impact.
  - **Charts:** two `CardPart` pages that host the standard System Application Business Chart control add-in, filled
    through System Application codeunit "Business Chart". The data comes from two internal queries (`GROUP BY` category
    and `GROUP BY` status) through a new internal codeunit "EQM Dashboard Mgt.". The codeunit returns plain lists, so
    tests can check it without the add-in, and it also opens the filtered list on drill-down. Each chart part has its
    own Refresh action, so it works the same on the Role Center and on the standalone page.
  - **Surface (Q1 = B):**
    - A new Role Center page "EQM Equipment Manager RC" (50110) embeds the three parts and offers navigation to
      Equipment, Categories, Assignments and Setup.
    - A new profile "EQM EQUIPMENT MANAGER" (caption "Equipment Manager") uses this Role Center. Users choose it in My
      Settings, or an administrator assigns it in Profiles (Roles).
  - **Standalone page 50109 "EQM Equipment Dashboard" is kept (decided).** It holds the same three parts and is the
    target of the Equipment list's Dashboard action and of Tell Me. Users in other roles (for example Business Manager)
    get the dashboard without switching profile. It costs one small page with no logic of its own.
- Rejected: dropping page 50109 and pointing the Dashboard action at the Role Center. A Role Center page cannot be opened
  as a normal page from an action or Tell Me, so users outside the new profile would lose the dashboard.
- Rejected: page extensions that add the parts to standard role centers (Q1 option C). That is invasive for every user
  of those profiles, and not requested.
- Rejected: assigning the new profile to users or making it the default in install code. Role choice belongs to the
  customer's administrator, and AppSource apps must not change user settings on install.
- Rejected: a stored cue table (`TableType = Normal`) with the "insert the singleton on open" pattern. It writes a row
  from a page, needs `tabledata ... = RI` in EQM - Read, and adds a table to upgrade.
- Rejected: page variables computed in code and shown in the cuegroup. Every tile would need its own `OnDrillDown`
  code, and the standard cue drill-down would be lost.
- Rejected: one cue tile per category for D-R3. Categories are user data, but cues are fixed fields.
- Rejected: a ListPart with count columns. It is not a visual indicator.
- Rejected: Power BI embedded reports. They need a Power BI licence, a workspace and published reports.
- Rejected: the base app generic chart framework ("Chart Definition" / "Generic Chart Setup"). It is tenant-configured
  and legacy.
- Rejected: base app table "Business Chart Buffer". Codeunit "Business Chart" replaces it for new code.
- Rejected: per-status `Count()` calls for the charts. That is N round trips; a query is one `GROUP BY`.
- Rejected: a headline part on the Role Center. Not requested, and it would need its own logic and messages.
- Rejected: a new index on table 50100 `Status`. Equipment volumes are small, and it would be a schema change for no
  measurable gain (R4).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50103, pages 50100-50105, codeunits 50103-50106, enums
50100-50101, page extension 50100, permission sets 50100-50102, permission set extension 50103, no queries, no
profiles. Test app: no objects (test codeunits 50150-50160 reserved by FR-001 to FR-008, none built).

Folder for all new files: `app/src/Dashboard/`. Namespace: `MiguelCarvalho.EquipmentManagement`.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50104 | EQM Equipment Cue | New | Temporary cue table: six Count FlowFields on table 50100 |
| Query | 50100 | EQM Equipment by Category | New | Count of equipment grouped by Category Code (internal) |
| Query | 50101 | EQM Equipment by Status | New | Count of equipment grouped by Status (internal) |
| Codeunit | 50107 | EQM Dashboard Mgt. | New | Chart data as lists; drill-down to the filtered Equipment list (internal) |
| Page | 50106 | EQM Equipment Cues | New | CardPart with the six KPI tiles |
| Page | 50107 | EQM Equipment Category Chart | New | CardPart, Business Chart add-in, column chart by category, own Refresh action |
| Page | 50108 | EQM Equipment Status Chart | New | CardPart, Business Chart add-in, pie chart by status, own Refresh action |
| Page | 50109 | EQM Equipment Dashboard | New | Standalone dashboard (Tell Me + Equipment list action) holding the three parts |
| Page | 50110 | EQM Equipment Manager RC | New | Role Center: the three parts plus navigation to the equipment pages |
| Profile | (no ID) | EQM EQUIPMENT MANAGER | New | Role "Equipment Manager" with Role Center 50110 |
| Page | 50100 | EQM Equipment List | Modify (own) | New navigation action "Dashboard" (opens 50109) plus its promoted actionref |
| PermissionSet | 50100 | EQM - Read | Modify (own) | Grant X on the nine new objects with IDs (profiles need no permission) |

Not changed: tables 50100-50103, pages 50101-50105, codeunits 50103-50106, enums, page extension 50100, permission sets
50101-50102 (they include EQM - Read), permission set extension 50103, `app/app.json`, `test/`.
Next free IDs after FR-009: tables 50105, pages 50111, codeunits 50108, queries 50102, enums 50102, page extensions
50101, permission sets 50104. Test app: test codeunit **50161 reserved for FR-009 "EQM Dashboard Tests", not built now
(Q6).**

### Platform names to verify in the symbols before coding (not design choices)
The System Application symbols (29.0) must be checked with Go to Definition, because the planner could only partly
confirm them from the symbol cache:
- Codeunit **"Business Chart"** (namespace `System.Visualization`) with procedures `Initialize`, `AddMeasure`,
  `SetXDimension`, `AddDataRowWithXDimension`, `SetValue`, `Update`, and enums **"Business Chart Type"** (values
  `Column`, `Pie`) and **"Business Chart Data Type"** (values `Integer`, `String`).
- Control add-in **`BusinessChart`** (System Application). The symbol cache also shows the legacy
  `Microsoft.Dynamics.Nav.Client.BusinessChart`. Use `BusinessChart`, the one that codeunit "Business Chart" `Update`
  accepts. Never use an add-in or procedure marked `Obsolete`: the analyzer warning would be a defect.
- The `DataPointClicked(Point: JsonObject)` event of the add-in, and the key **`XValueString`** in `Point` (the label of
  the clicked X value).
- Profile object properties `Caption`, `ProfileDescription`, `RoleCenter`, `Enabled`, `Promoted` (runtime 18).
- `Image = BarChart` for the Dashboard action. If that value does not exist, use `Image = AnalysisView`.
If any of these differ, adapt to the real names with the same behavior and report the difference in the developer
report. Do not fall back to table "Business Chart Buffer".

### Table 50104 "EQM Equipment Cue" (new)
File `EQMEquipmentCue.Table.al`.
- `Caption = 'Equipment Cue'`, `TableType = Temporary`, `DataClassification = CustomerContent` (table level only),
  `Access = Internal`. No `LookupPageId`/`DrillDownPageId`.
- Fields (no `ToolTip` on field 1; the others get the tooltip shown):
  | ID | Name | Type | Caption | Definition | ToolTip |
  |---|---|---|---|---|---|
  | 1 | Primary Key | Code[10] | Primary Key | normal field | none (not shown) |
  | 10 | Total Equipment | Integer | Total Equipment | FlowField `Count("EQM Equipment")` | Specifies the number of equipment records, whatever their status. |
  | 11 | Available Equipment | Integer | Available Equipment | FlowField `Count("EQM Equipment" where(Status = const(Available)))` | Specifies the number of equipment records that are available for assignment. |
  | 12 | Assigned Equipment | Integer | Assigned Equipment | FlowField, `Status = const(Assigned)` | Specifies the number of equipment records that are assigned to an employee. |
  | 13 | Equipment in Maintenance | Integer | Equipment in Maintenance | FlowField, `Status = const("In Maintenance")` | Specifies the number of equipment records that are in maintenance. |
  | 14 | Lost Equipment | Integer | Lost Equipment | FlowField, `Status = const(Lost)` | Specifies the number of equipment records that are lost. |
  | 15 | Disposed Equipment | Integer | Disposed Equipment | FlowField, `Status = const(Disposed)` | Specifies the number of equipment records that are disposed of. |
- All FlowFields: `FieldClass = FlowField`, `Editable = false`.
- Key `PK` on "Primary Key", clustered.
- No triggers, no procedures, no events.

### Query 50100 "EQM Equipment by Category" (new)
File `EQMEquipmentByCategory.Query.al`.
- `Caption = 'Equipment by Category'`, `QueryType = Normal`, `Access = Internal`, `DataAccessIntent = ReadOnly`.
  No `QueryCategory`.
- `dataitem(Equipment; "EQM Equipment")` with `column(CategoryCode; "Category Code")` and
  `column(NoOfEquipment)` with `Method = Count`.
- `OrderBy = ascending(CategoryCode)`.

### Query 50101 "EQM Equipment by Status" (new)
File `EQMEquipmentByStatus.Query.al`.
- `Caption = 'Equipment by Status'`, `QueryType = Normal`, `Access = Internal`, `DataAccessIntent = ReadOnly`, no
  `QueryCategory`.
- `dataitem(Equipment; "EQM Equipment")` with `column(Status; Status)` and `column(NoOfEquipment)` with
  `Method = Count`. No `OrderBy` (the codeunit sets the order).

### Codeunit 50107 "EQM Dashboard Mgt." (new)
File `EQMDashboardMgt.Codeunit.al`. `Access = Internal`. No `Permissions` property. Every procedure has an XML doc
comment.

1. `internal procedure GetEquipmentCountByCategory(var CategoryCodes: List of [Code[20]]; var EquipmentCounts: List of [Integer])`
   - Clear both lists. Open query 50100, add `CategoryCode` and `NoOfEquipment` of every row to the lists in row order
     (category code ascending), then close the query.
   - Result: one entry per category that has at least one equipment record. Both lists have the same length and are
     empty when there is no equipment.
2. `internal procedure GetEquipmentCountByStatus(var StatusOrdinals: List of [Integer]; var EquipmentCounts: List of [Integer])`
   - Clear both lists. Read query 50101 into a local `Dictionary of [Integer, Integer]` (key `Status.AsInteger()`, value
     `NoOfEquipment`), then close the query.
   - For each ordinal in `Enum::"EQM Equipment Status".Ordinals()`, in that order: add the ordinal to `StatusOrdinals`,
     and add the dictionary value (or 0 when the key is missing) to `EquipmentCounts`.
3. `internal procedure GetStatusCaption(StatusOrdinal: Integer): Text`
   - Returns `Format(Enum::"EQM Equipment Status".FromInteger(StatusOrdinal))`.
4. `internal procedure ShowEquipmentByCategory(CategoryCode: Code[20])`
   - Local `Equipment: Record "EQM Equipment"`, `SetRange("Category Code", CategoryCode)`, then
     `Page.Run(Page::"EQM Equipment List", Equipment)`.
5. `internal procedure ShowEquipmentByStatus(StatusOrdinal: Integer)`
   - Same pattern, with `SetRange(Status, Enum::"EQM Equipment Status".FromInteger(StatusOrdinal))`.
No events, no UI other than `Page.Run`, no `Commit`.

### Page 50106 "EQM Equipment Cues" (new)
File `EQMEquipmentCues.Page.al`.
- `Caption = 'Equipment Activities'`, `PageType = CardPart`, `ApplicationArea = All`,
  `SourceTable = "EQM Equipment Cue"`, `RefreshOnActivate = true`, `Editable = false`. No `UsageCategory`.
- Layout: `area(Content)`, `cuegroup(Equipment)` with `Caption = 'Equipment'` and six controls in this order (control
  name = field name, no ToolTip on the controls because they inherit it): "Total Equipment", "Available Equipment",
  "Assigned Equipment", "Equipment in Maintenance", "Lost Equipment", "Disposed Equipment". Each control has
  `DrillDownPageId = "EQM Equipment List"`.
- No `actions` section (`RefreshOnActivate` and the host pages' refresh cover it).
- Trigger `OnOpenPage`: `Rec.Reset()`; if `not Rec.Get()` then `Rec.Init()` and `Rec.Insert()`. The insert goes into
  the temporary table, so it needs no permission and stores nothing.
- `internal procedure RefreshCues()`: `CurrPage.Update(false)`.
- Section order: `layout`, then triggers and procedures (AL0926).

### Page 50107 "EQM Equipment Category Chart" (new)
File `EQMEquipmentCategoryChart.Page.al`, `using System.Visualization;` (adjust to the verified namespace).
- `Caption = 'Equipment by Category'`, `PageType = CardPart`, `ApplicationArea = All`, no `SourceTable`, no
  `UsageCategory`.
- Layout: `area(Content)`, `usercontrol(Chart; BusinessChart)` with:
  - `trigger AddInReady()`: `IsChartReady := true;` then `UpdateChart()`.
  - `trigger DataPointClicked(Point: JsonObject)`: read the text of key `XValueString` from `Point`. When the key is
    missing, or `CategoryCodes.IndexOf(the label)` returns 0, exit without error. Otherwise call
    `DashboardMgt.ShowEquipmentByCategory(CategoryCodes.Get(index))`.
- Actions: `area(Processing)`, `action(Refresh)` with `Caption = 'Refresh'`,
  `ToolTip = 'Updates the chart with the current equipment data.'`, `Image = Refresh`. `OnAction` calls `UpdateChart()`.
  No promoted area (part actions show in the part menu).
- `var`: `BusinessChart: Codeunit "Business Chart"`, `DashboardMgt: Codeunit "EQM Dashboard Mgt."`,
  `CategoryCodes: List of [Code[20]]`, `EquipmentCounts: List of [Integer]`, `IsChartReady: Boolean`,
  `EquipmentMeasureLbl: Label 'Equipment'`, `CategoryDimensionLbl: Label 'Category'`.
- `local procedure UpdateChart()`:
  1. Exit when `not IsChartReady`.
  2. `DashboardMgt.GetEquipmentCountByCategory(CategoryCodes, EquipmentCounts)`.
  3. `BusinessChart.Initialize()`, then `AddMeasure(EquipmentMeasureLbl, 1, Data Type Integer, Chart Type Column)` (the
     second argument is the measure value/identifier that the verified signature asks for), then
     `SetXDimension(CategoryDimensionLbl, Data Type String)`.
  4. For i = 1..Count: `AddDataRowWithXDimension(Format(CategoryCodes.Get(i)))`, then
     `SetValue(EquipmentMeasureLbl, i - 1, EquipmentCounts.Get(i))` (the X index starts at 0).
  5. `BusinessChart.Update(CurrPage.Chart)`.
  With no equipment the chart is updated with no rows (an empty chart), and no error is raised.
- `internal procedure RefreshChart()`: calls `UpdateChart()`.
- Section order: `layout`, `actions`, then `var`, triggers and procedures (AL0926).

### Page 50108 "EQM Equipment Status Chart" (new)
File `EQMEquipmentStatusChart.Page.al`. Same structure as page 50107, including the Refresh action, with these
differences:
- `Caption = 'Equipment by Status'`.
- Lists: `StatusOrdinals: List of [Integer]`, `EquipmentCounts: List of [Integer]`, and also
  `StatusCaptions: List of [Text]` (filled while the chart is built, used for drill-down).
- Labels: `EquipmentMeasureLbl: Label 'Equipment'`, `StatusDimensionLbl: Label 'Status'`.
- `UpdateChart()`: calls `DashboardMgt.GetEquipmentCountByStatus`, then uses Chart Type **Pie** and, for each row, the X
  label `DashboardMgt.GetStatusCaption(StatusOrdinals.Get(i))`, which is also added to `StatusCaptions`. Clear
  `StatusCaptions` first.
- `DataPointClicked`: look up the `XValueString` label in `StatusCaptions`, and on a match call
  `DashboardMgt.ShowEquipmentByStatus(StatusOrdinals.Get(index))`. Otherwise exit without error.

### Page 50109 "EQM Equipment Dashboard" (new, kept alongside the Role Center)
File `EQMEquipmentDashboard.Page.al`.
- `Caption = 'Equipment Dashboard'`, `PageType = Card`, `ApplicationArea = All`, `UsageCategory = ReportsAndAnalysis`,
  `AdditionalSearchTerms = 'equipment kpi, equipment overview, equipment chart'`, `Editable = false`, no `SourceTable`.
- `AboutTitle = 'About the equipment dashboard'`
- `AboutText = 'The tiles count your equipment by status. **Total Equipment** includes lost and disposed equipment. The charts show how your equipment is spread over categories and statuses. Choose a tile or a chart segment to open the matching equipment. Choose **Refresh** to update the numbers.'`
  (one string on one line in the source).
- Layout, `area(Content)`, in this order: `part(Cues; "EQM Equipment Cues")`,
  `part(CategoryChart; "EQM Equipment Category Chart")`, `part(StatusChart; "EQM Equipment Status Chart")`. No
  `SubPageLink`, no captions on the parts.
- Actions:
  - `area(Processing)`, `action(Refresh)`: `Caption = 'Refresh'`,
    `ToolTip = 'Updates the tiles and charts with the current equipment data.'`, `Image = Refresh`. `OnAction` calls
    `CurrPage.Cues.Page.RefreshCues()`, `CurrPage.CategoryChart.Page.RefreshChart()` and
    `CurrPage.StatusChart.Page.RefreshChart()`.
  - `area(Navigation)`, `action(Equipment)`: `Caption = 'Equipment'`, `ToolTip = 'Opens the list of all equipment.'`,
    `Image = FixedAssets`, `RunObject = page "EQM Equipment List"`.
  - `area(Promoted)`: `actionref(Refresh_Promoted; Refresh)` and `actionref(Equipment_Promoted; Equipment)`.
- No `var`, no triggers.

### Page 50110 "EQM Equipment Manager RC" (new)
File `EQMEquipmentManagerRC.Page.al`.
- `Caption = 'Equipment Manager'`, `PageType = RoleCenter`, `ApplicationArea = All`. No `UsageCategory`, no
  `SourceTable`, no AboutTitle/AboutText (the parts are explained by the dashboard help).
- Layout: `area(RoleCenter)` with, in this order: `part(Cues; "EQM Equipment Cues")`,
  `part(CategoryChart; "EQM Equipment Category Chart")`, `part(StatusChart; "EQM Equipment Status Chart")`.
- Actions (all with `Caption` and `ToolTip` as given; the RC has no `area(Promoted)`):
  - `area(Embedding)` (top navigation lists):
    - `action(EquipmentList)`: `Caption = 'Equipment'`, `ToolTip = 'Opens the list of all equipment.'`,
      `RunObject = page "EQM Equipment List"`.
    - `action(AssignmentList)`: `Caption = 'Assignments'`,
      `ToolTip = 'Opens the assignment history of all equipment.'`, `RunObject = page "EQM Equipment Assignments"`.
    - `action(CategoryList)`: `Caption = 'Categories'`, `ToolTip = 'Opens the list of equipment categories.'`,
      `RunObject = page "EQM Equipment Categories"`.
  - `area(Sections)`, `group(Setup)` with `Caption = 'Setup'`:
    - `action(EquipmentSetup)`: `Caption = 'Equipment Setup'`, `ToolTip = 'Opens the equipment setup.'`,
      `RunObject = page "EQM Equipment Setup"`.
    - `action(EquipmentCategories)`: `Caption = 'Equipment Categories'`,
      `ToolTip = 'Opens the list of equipment categories.'`, `RunObject = page "EQM Equipment Categories"`.
  - `area(Creation)`:
    - `action(NewEquipment)`: `Caption = 'Equipment'`, `ToolTip = 'Creates a new equipment record.'`,
      `Image = New`, `RunObject = page "EQM Equipment Card"`, `RunPageMode = Create`.
- No `var`, no triggers, no procedures. Refresh on the RC: the cue part refreshes on activation
  (`RefreshOnActivate`), and each chart part has its own Refresh action.

### Profile "EQM EQUIPMENT MANAGER" (new)
File `EQMEquipmentManager.Profile.al`.
- `Caption = 'Equipment Manager'`
- `ProfileDescription = 'Manages equipment, categories and assignments, with key figures and charts.'`
- `RoleCenter = "EQM Equipment Manager RC"`
- `Enabled = true`, `Promoted = true` (listed in the role choice of My Settings).
- No `Customizations`. The profile is not assigned to anyone and not set as default by install code. The administrator
  or the user chooses it (documented in the help).

### Page 50100 "EQM Equipment List" (change)
- In `area(Navigation)`, after action `Assignments`, add `action(Dashboard)`: `Caption = 'Dashboard'`,
  `ToolTip = 'Opens the equipment dashboard with key figures and charts.'`, `Image = BarChart` (see the verification
  list), `RunObject = page "EQM Equipment Dashboard"`.
- In `area(Promoted)`, after `Assignments_Promoted`, add `actionref(Dashboard_Promoted; Dashboard)`.
- Nothing else changes.

### app.json, translations, CHANGELOG
- **app.json: no change.** Profiles and role centers need no manifest entry, and the version stays 29.0.0.0 (no
  release yet). The existing `TranslationFile` feature covers the new texts.
- **Translations:** the build regenerates `app/Translations/Equipment Management.g.xlf` with all new captions,
  tooltips, labels (`EquipmentMeasureLbl`, `CategoryDimensionLbl`, `StatusDimensionLbl`), AboutTitle/AboutText,
  AdditionalSearchTerms, and the profile `Caption` and `ProfileDescription`. Commit the regenerated file and never edit
  it by hand. No inline `CaptionML`.
- **CHANGELOG (documenter):** section `## FR-009 Dashboard and KPIs (version stays 29.0.0.0, no bump)` at the top. It
  lists the new Equipment Manager role (profile + Role Center), the Equipment Dashboard page, the six KPI tiles, the two
  charts with drill-down, and the Dashboard action on the Equipment list, plus a release-notes paragraph. It also says
  that the role must be chosen in My Settings or assigned by an administrator.

## Data model and upgrade impact
- **No stored schema change.** Table 50104 is `TableType = Temporary`, so it creates no SQL table and holds no data.
  Tables 50100-50103, their fields and their keys are unchanged.
- DataClassification: table 50104 is `CustomerContent` at table level. Its fields hold only counts and are never
  stored.
- Profile: the new profile adds a role definition (metadata), not tenant data. Uninstalling the app removes it, and
  users who had chosen it fall back to the default role (platform behavior).
- Upgrade codeunit: not needed (nothing released, nothing stored).
- Performance per open or Refresh: six `COUNT` FlowFields, one `GROUP BY` query per chart, all read-only. The Role
  Center runs the same queries each time it opens (R4).

## Events
**Standard BC events: none.** No events report required.

Subscribed: none. (The `AddInReady` and `DataPointClicked` triggers belong to the control add-in, not to event
subscribers.)

Published: **none.** No business rule a partner would need to override, so no IsHandled is needed. Partners can extend
pages 50106-50110 with page extensions (for example to add parts or actions to the Role Center), and can build their own
profile on top of the Role Center. The cue table, the queries and the codeunit are `Internal`.

## Permissions
- **EQM - Read (50100):** add
  - `table "EQM Equipment Cue" = X` (no `tabledata` entry, because the table is temporary),
  - `query "EQM Equipment by Category" = X`, `query "EQM Equipment by Status" = X`,
  - `codeunit "EQM Dashboard Mgt." = X`,
  - `page "EQM Equipment Cues" = X`, `page "EQM Equipment Category Chart" = X`, `page "EQM Equipment Status Chart" = X`,
    `page "EQM Equipment Dashboard" = X`, `page "EQM Equipment Manager RC" = X`.
  The existing `tabledata "EQM Equipment" = R` covers the FlowFields, the queries and the drill-down.
- Profile: profiles are not permission objects. Any user can choose the role, and what they can open on it still
  depends on their EQM set. The "New Equipment" action needs EQM - Edit (insert), which EQM - Edit already grants. A
  Read-only user gets the platform's permission error when inserting, the same as from the list today.
- EQM - Edit (50101) and EQM - Admin (50102) include EQM - Read: no change.
- System Application codeunit "Business Chart" and the BusinessChart add-in come with the platform basic permission
  sets (D365 BASIC). No EQM set grants them (R3).
- Help text (documenter): "Everyone with Equipment - Read can open the equipment dashboard and use the Equipment Manager
  role. Creating equipment from the role needs Equipment - Edit."

## Compatibility
- AppSource mode, development phase: nothing is released, there is no baseline, and no Obsolete handling is needed.
- No public API change. The new table, queries and codeunit are `Access = Internal`. The page procedures
  `RefreshCues`/`RefreshChart` are `internal`. No existing procedure, event, field or key changes.
- New public objects: pages 50106-50110 and the profile. Once released, the profile name "EQM EQUIPMENT MANAGER" and the
  Role Center page are a contract: partners and tenant customizations reference them, so they must not be renamed or
  removed without an Obsolete cycle.
- Page 50100: the new action `Dashboard` and the actionref `Dashboard_Promoted` are additive.
- The status enum is `Extensible = true`. A partner status shows as its own pie segment, is counted in Total Equipment,
  and has no tile.
- Doc references to update (documenter, not developer):
  - New `docs/features/FR-009-dashboard-kpis.md` and `docs/help/FR-009-dashboard-kpis.md`. They cover:
    - How to choose the Equipment Manager role (My Settings > Role, or Profiles (Roles) for an administrator).
    - What the Role Center contains.
    - Where else the dashboard is (Tell Me, Equipment list > Dashboard).
    - What each tile counts (Total includes Lost and Disposed).
    - What each chart shows, drill-down, and Refresh (dashboard page: one Refresh; Role Center: Refresh in each chart's
      menu).
  - `docs/help/FR-007-equipment-list-management.md`: short cross-reference to the new Dashboard action.
  - CHANGELOG: as described under "app.json, translations, CHANGELOG".
  - `docs/TODO.md`: add the manual sandbox checks listed under Test scenarios.
  - Historical plans are not edited.

## Test scenarios
**No automated tests in this iteration (Q6 resolved: deferred). No test codeunits, no `test/app.json` change. ID 50161
is reserved and stays unused, and the tester step is skipped.** The list is the reference for the user, who writes the
tests later in test codeunit 50161 "EQM Dashboard Tests". Cues are tested with `TestPage "EQM Equipment Cues"`. Chart
data is tested through codeunit 50107, not through the add-in. Role Center and profile checks are manual.

Test data, unless stated: every equipment record is deleted first (`DeleteAll(false)` on tables 50100 and 50103 in the
test). Categories C1 and C2 are active, C3 is active with no equipment. Employee P1 is active. Equipment: E1, E2 (C1,
Available); E3 (C1, assigned to P1 through `AssignEmployee`); E4 (C2, In Maintenance); E5 (C2, Lost); E6 (C2,
Disposed). Final statuses are set through validate + `Modify(true)` with a `[ConfirmHandler]` answering Yes.

KPI tiles (D-R2)
- K1 Given the test data, when page 50106 is opened, then Total Equipment = 6, Available Equipment = 2, Assigned
  Equipment = 1, Equipment in Maintenance = 1, Lost Equipment = 1, Disposed Equipment = 1.
- K2 Given no equipment, when page 50106 is opened, then all six tiles show 0 and no error is raised.
- K3 Given the test data, when page 50106 is opened twice in a row, then the values are identical, and nothing is
  stored for table 50104 (temporary; code review).
- K4 Given page 50106 open and E1 then assigned to P1 in the test, when `RefreshCues` runs (or the page is reopened),
  then Available Equipment = 1 and Assigned Equipment = 2.
- K5 Given the test data, when the Available Equipment tile is drilled down (TestPage `Trap` on page 50100), then the
  list shows exactly E1 and E2. Repeat for each status tile with its matching records, and for Total Equipment (all
  six).
- K6 Given the tiles, when the user tries to edit a tile value, then it is not possible.

Equipment by Category (D-R3)
- G1 Given the test data, when `GetEquipmentCountByCategory` is called, then CategoryCodes = [C1, C2] and
  EquipmentCounts = [3, 3] (Lost and Disposed included, C3 not listed).
- G2 Given no equipment, when it is called, then both lists are empty and no error is raised.
- G3 Given both lists filled by an earlier call, when it is called again after all equipment is deleted, then both
  lists are empty (cleared, not appended).
- G4 Given the test data, when `ShowEquipmentByCategory(C2)` is called (`Trap` on page 50100), then the list shows
  E4, E5 and E6 only.
- G5 Given an inactive category C1 that equipment still uses, when the function is called, then C1 is still counted.

Equipment by Status (D-R4)
- S1 Given the test data, when `GetEquipmentCountByStatus` is called, then StatusOrdinals = [0, 1, 2, 3, 4] and
  EquipmentCounts = [2, 1, 1, 1, 1].
- S2 Given only E1 and E2 (Available), when it is called, then EquipmentCounts = [2, 0, 0, 0, 0].
- S3 Given no equipment, when it is called, then five entries with count 0 are returned and no error is raised.
- S4 Given ordinal 2, when `GetStatusCaption` is called, then it returns the caption of "In Maintenance".
- S5 Given the test data, when `ShowEquipmentByStatus(4)` is called (`Trap` on page 50100), then the list shows E5
  only.
- S6 Given the test data, then the sum of EquipmentCounts from S1 equals Total Equipment from K1.

Dashboard page and navigation (D-R1)
- N1 Given a user, when "Equipment Dashboard" is searched in Tell Me, then page 50109 is found (manual).
- N2 Given page 50100 open, when the Dashboard action is invoked (`Trap` on page 50109), then the dashboard opens.
- N3 Given page 50109 open, when the Equipment action is invoked, then page 50100 opens unfiltered.
- N4 Given page 50109 open, when Refresh is invoked, then no error is raised, and the cue values reflect data changed
  since opening (as in K4).
- N5 (`TestPermissions = Restrictive`) Given a user with EQM - Read and D365 BASIC only, when page 50109 is opened and
  Refresh is invoked, then no permission error is raised and the tiles show the counts.
- N6 Given a user without any EQM permission set, when page 50109 is opened, then a permission error is raised.

Role Center and profile (D-R1, Q1 = B; manual in the sandbox)
- RC1 Given a user with EQM - Read, when they choose the role "Equipment Manager" in My Settings, then the Role Center
  opens with the tiles, the category chart and the status chart, in that order.
- RC2 Given the Role Center, when Equipment, Assignments or Categories in the top navigation are chosen, then pages
  50100, 50104 and 50102 open.
- RC3 Given the Role Center, when Setup > Equipment Setup and Setup > Equipment Categories are chosen, then pages 50103
  and 50102 open.
- RC4 Given a user with EQM - Edit on the Role Center, when New > Equipment is chosen, then the Equipment Card opens in
  create mode, and a record can be saved.
- RC5 Given a user with EQM - Read only, when New > Equipment is chosen and a record is entered, then a permission error
  appears on save (no data is written).
- RC6 Given the Role Center, when a tile or a chart point is clicked, then the filtered Equipment list opens (same as
  K5, G4, S5).
- RC7 Given the Role Center, when an equipment status is changed and the user comes back to the Role Center, then the
  tiles are updated (RefreshOnActivate), and each chart's Refresh action updates its chart.
- RC8 Given Profiles (Roles), when the administrator looks up "EQM EQUIPMENT MANAGER", then it shows the caption
  "Equipment Manager", the description, and Role Center 50110. It is assigned to nobody by default.

Regression
- R-1 Given page 50100, then the existing actions Categories, Setup and Assignments and the five status views still
  work (FR-007).

Manual sandbox checks (for the user):
- The dashboard page and the Role Center both show six tiles, then a column chart by category, then a pie chart by
  status.
- Clicking a column, a pie segment or a tile opens the Equipment list with the matching filter.
- Refresh on the dashboard page updates tiles and charts. On the Role Center, the chart menus offer Refresh.
- With no equipment, the charts are empty and no error appears.
- The teaching tip appears the first time the dashboard page opens, and the bold words render bold.
- The Dashboard action is promoted on the Equipment list.
- RC1-RC8 above.
- After the build, `Equipment Management.g.xlf` contains the new captions, tooltips, labels, AboutTitle, AboutText,
  AdditionalSearchTerms, and the profile caption and description.
- No CodeCop, UICop or AppSourceCop warning about obsolete chart objects.

## Risks and open questions
Resolved questions (decided by the user on approval):
- **Q1 Where the dashboard lives: RESOLVED, option B.** Own Role Center 50110 "EQM Equipment Manager RC" and profile "EQM
  EQUIPMENT MANAGER" embed the three parts. The standalone page 50109 is **kept** as the Tell Me and Equipment list
  target for users in other roles. Option C (extending standard role centers) is not done.
- **Q2 Total Equipment: RESOLVED.** All records, Lost and Disposed included.
- **Q3 Chart content: RESOLVED.**
  - The category chart counts all statuses, shows only categories with equipment, and labels them with the code.
  - The status chart lists every status, zeros included, in enum order (Available, Assigned, In Maintenance, Disposed,
    Lost).
- **Q4 Chart types: RESOLVED.** Column chart for categories, pie chart for status.
- **Q5 Drill-down: RESOLVED.** Yes, from tiles and chart points to the filtered Equipment list.
- **Q6 Tests: RESOLVED.** Deferred. Test codeunit 50161 is reserved and the tester step is skipped.
- **Q7 Teaching tip: RESOLVED.** Yes, on the dashboard page 50109 (not on the Role Center).
- **Q8 Cue styling: RESOLVED.** None. Standard tile style.

No open questions remain.

Risks:
- R1 The temporary cue table relies on the platform calculating Count FlowFields for a temporary source record. If the
  sandbox check shows zeros, call `Rec.CalcFields` on the six fields in `OnAfterGetRecord` of page 50106. No other
  design change is needed.
- R2 The Business Chart API names and the profile properties could only be partly confirmed from the local symbol cache
  (see "Platform names to verify"). Drill-down depends on the `XValueString` key of the `DataPointClicked` payload. If
  the key differs, drill-down silently does nothing (guarded), so it must be checked in the sandbox.
- R3 Chart rendering needs the System Application chart objects, which the platform basic permission sets grant. A user
  without D365 BASIC may see the tiles but no chart. The help should say that D365 BASIC is expected.
- R4 Table 50100 has no index on Status, so the FlowFields and the status query scan the table. This is fine at
  equipment volumes. A later additive key (Status, "Category Code") is AppSource-safe. Users of the role run these
  counts every time the Role Center opens.
- R5 The status chart maps captions back to statuses for drill-down. A partner status with a duplicate caption would
  match the first one. This is accepted.
- R6 The charts are a snapshot taken when they load. They change only on Refresh or reopen (only the cue part has
  `RefreshOnActivate`).
- R7 The profile is not assigned automatically, so users will not see the Role Center until someone chooses the role.
  The help and CHANGELOG must say how to choose it.
- R8 After release, the profile name and the Role Center page become a contract (see Compatibility).
- R10 The chart queries use `DataAccessIntent = ReadOnly`, while the cue FlowFields read the primary database. After a change, tiles and charts may briefly disagree. `DataAccessIntent` is kept as is.
- R9 No automated tests (Q6), so regressions are caught only by review and the manual sandbox checks.

## Implementation notes (developer, after review)
- Deviation: the category chart page has an extra `CategoryLabels: List of [Text]`, filled while the chart is built, and `DataPointClicked` looks the clicked label up there. Reason: `IndexOf` with a Text argument against `List of [Code[20]]` is a type mismatch, and the label list avoids uppercase, trim and overflow conversions on client text.
- Added (review): both chart pages have a `Refresh` trigger on the BusinessChart usercontrol (`if IsChartReady then UpdateChart();`).
- Added (review): in both `DataPointClicked` handlers, after `Point.Get('XValueString', ...)`, the handler exits when the token is not a value or is null, before `AsText()`.
- The BusinessChart add-in is in namespace `System.Integration`, so the chart pages use `using System.Integration;` and `using System.Visualization;`.
