# FR-009 Dashboard and KPIs

## Purpose
Managers get a dashboard with six KPI tiles (Total, Available, Assigned, In Maintenance, Lost, Disposed equipment) and two charts (equipment by category, equipment by status). It is the home page of a new **Equipment Manager** role (own Role Center and profile) and also a standalone page, "Equipment Dashboard", for users in any other role. Every tile and chart data point opens the Equipment list filtered to the equipment behind the number.

Status: describes the code as implemented. **Build is clean for the FR-009 files** (alc 30.0.43, CodeCop, UICop, AppSourceCop); the remaining diagnostics are pre-existing app.json/manifest ones plus AA0215 and AW0006 on untouched files. **Review: APPROVE WITH CHANGES, changes applied, no blockers. No automated tests (deferred, plan decision Q6). Not run in a sandbox.** App version stays 29.0.0.0 (app.json unchanged). Namespace `MiguelCarvalho.EquipmentManagement`. No schema change to stored tables, no upgrade codeunit, no events published or subscribed, no events report.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50104 | EQM Equipment Cue | New, `TableType = Temporary`, internal. Key "Primary Key" (Code[10]). Six Count FlowFields on "EQM Equipment" (fields 10-15): Total Equipment (all records), Available Equipment, Assigned Equipment, Equipment in Maintenance, Lost Equipment, Disposed Equipment (each filtered on Status). Nothing is stored. |
| Query | 50100 | EQM Equipment by Category | New, internal. Count of equipment grouped by Category Code, ordered by category code ascending. |
| Query | 50101 | EQM Equipment by Status | New, internal. Count of equipment grouped by Status. |
| Codeunit | 50107 | EQM Dashboard Mgt. | New, internal. Chart data as lists and drill-down to the filtered Equipment list (see below). |
| Page | 50106 | EQM Equipment Cues | New CardPart "Equipment Activities": cuegroup "Equipment" with the six tiles, each with `DrillDownPageId = "EQM Equipment List"`. `RefreshOnActivate`. `OnOpenPage` inserts the single row into the temporary table. |
| Page | 50106 | EQM Equipment Cues | FR-020: cuegroup "Planned Maintenance" (after Warranty) with the tile "Overdue Maintenance Equipment" (table 50104 fields 50/51), styled Unfavorable above 0 and Favorable at 0, drill-down to the Equipment List. See FR-020 feature doc. |
| Page | 50107 | EQM Equipment Category Chart | New CardPart with the System Application `BusinessChart` add-in: column chart, one column per category that has equipment. Own Refresh action. |
| Page | 50108 | EQM Equipment Status Chart | New CardPart, `BusinessChart` add-in: pie chart, one segment per value of enum "EQM Equipment Status" (zero counts included, enum order). Own Refresh action. |
| Page | 50109 | EQM Equipment Dashboard | New Card, `UsageCategory = ReportsAndAnalysis` (found through Tell Me), holds the three parts. Actions Refresh (promoted 'Process') and Equipment (promoted 'Navigate'). Teaching tip (`AboutTitle`/`AboutText`). |
| Page | 50110 | EQM Equipment Manager RC | New Role Center "Equipment Manager": the three parts plus Embedding actions Equipment, Assignments (the duplicate Categories was removed in NFR-003); Sections group Setup (Equipment Setup, Equipment Categories); Creation action Equipment (new equipment card). |
| Profile | - | EQM EQUIPMENT MANAGER | New. Caption "Equipment Manager", Role Center 50110, `Enabled = true`, `Promoted = true`. |
| Page | 50100 | EQM Equipment List | Action "Dashboard" (opens page 50109) in `area(Reporting)` since NFR-003, promoted under 'Report'. |
| PermissionSet | 50100 | EQM - Reader | `X` on table 50104, queries 50100 and 50101, pages 50106-50110 and codeunit 50107. |

## Added by FR-013 (maintenance costs)
Table 50104 gets FlowFields "Total Maintenance Cost" and "Average Maintenance Cost" (cue group "Maintenance Costs" on page 50106, drill-down to page 50117). Pages 50118 "EQM Category Cost Chart" and 50119 "EQM Equipment Cost Chart" (top 10) are added to pages 50109 and 50110; the dashboard Refresh also refreshes them. Codeunit 50107 gets four procedures. Page 50110 gets the Embedding action Maintenance History. Details: docs/features/FR-013-maintenance-cost-tracking.md. The six equipment tiles and the two FR-009 charts are unchanged.

## Behavior
- **Counts are live**, computed when the page opens, on activation of the cue part, or when the user chooses Refresh. Nothing is cached or stored.
- **Total Equipment** counts every record, Lost and Disposed included. With the five standard statuses, Total = Available + Assigned + In Maintenance + Lost + Disposed. A status added by an extension counts in Total but has no tile.
- **Tile drill-down** is the standard Count FlowField drill-down: it opens the Equipment list filtered by the FlowField's `CalcFormula`.
- **Category chart:** only categories with at least one equipment record, labelled with the category code, ordered by code. Counts include all statuses. With no equipment the chart is empty and no error is raised.
- **Status chart:** all enum values in ordinal order (Available, Assigned, In Maintenance, Disposed, Lost, then extension values), zero counts included.
- **Chart drill-down:** `DataPointClicked` reads the key `XValueString` of the clicked point, looks the label up in a list kept while the chart was built, and calls `ShowEquipmentByCategory` / `ShowEquipmentByStatus`. An unknown label, a missing key, or a null/non-value token exits silently.
- **Refresh:** each chart part has a Refresh action and a `Refresh` trigger on the add-in (rebuilds only when the add-in is ready). The dashboard page's Refresh calls `RefreshCues` and `RefreshChart` on the three parts. The Role Center has no Refresh action of its own.

### Codeunit 50107 "EQM Dashboard Mgt." (internal, so not callable from other apps; `///` comments present)
- `GetEquipmentCountByCategory(var CategoryCodes: List of [Code[20]]; var EquipmentCounts: List of [Integer])`
- `GetEquipmentCountByStatus(var StatusOrdinals: List of [Integer]; var EquipmentCounts: List of [Integer])`
- `GetStatusCaption(StatusOrdinal: Integer): Text`
- `ShowEquipmentByCategory(CategoryCode: Code[20])` and `ShowEquipmentByStatus(StatusOrdinal: Integer)`: `Page.Run` on the Equipment list with a filter.
- Internal procedures `RefreshCues` (page 50106) and `RefreshChart` (pages 50107, 50108) also carry `///` comments.

## Setup
1. Users open **My Settings** and choose **Equipment Manager** in the **Role** field, or an administrator assigns it in **Profiles (Roles)**. The profile is not assigned to anyone and is not made default by the app.
2. Users in other roles open **Equipment Dashboard** through Tell Me, or **Dashboard** on the Equipment list.
3. Give users the permission set **Equipment Reader** (EQM - Reader) at least; Manager and Administrator include it.

## Extending (events)
No events published or subscribed. All new codeunit procedures are internal. Partners can extend the pages with page extensions; the new control names (`Cues`, `CategoryChart`, `StatusChart`, `Chart`, `Refresh`) could clash with same-named partner controls.

## Permissions
EQM - Reader now grants `X` on the new table, queries, pages and codeunit (a profile needs no permission). EQM - Manager includes EQM - Reader and EQM - Administrator includes EQM - Manager (`IncludedPermissionSets`), so both get the new objects. No insert permission is needed for the cue table because it is temporary.

**Known limitations:**
- **Blank Category Code:** equipment without a category appears in the category chart as a column with an empty label (review edge case). It still counts in Total and the status chart. Clicking it is silently ignored if the label does not match; TODO(verify) behavior in a sandbox.
- Charts need the Business Chart control add-in; TODO(verify) availability and whether the D365 BASIC requirement applies to the chart (as in FR-007/FR-008 for Employee).
- Equipment added through an extension status has no tile.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand.

## Upgrade and compatibility
Additive: new objects and one action on page 50100. No stored table or key change, no upgrade logic, no Obsolete handling. Depends on System Application codeunit "Business Chart" (`System.Visualization`) and add-in `BusinessChart` (`System.Integration`).

## Test status
No test objects; test codeunit ID 50161 is reserved and unused (plan Q6). The scenarios in docs/plans/FR-009-dashboard-kpis.md are a reference only.

TODO(verify) in a sandbox (all open):
- `XValueString` is the payload key of `DataPointClicked`, so chart drill-down works.
- Count FlowFields calculate on the temporary cue table and tile drill-down opens the filtered list.
- Both charts render (column and pie), including the empty state and Refresh.
- Role Center and profile (plan scenarios RC1-RC8): profile appears in My Settings, Role Center loads, navigation actions work.
- D365 BASIC requirement for the charts.

## Discrepancies plan vs code
- The category chart page has an extra `CategoryLabels: List of [Text]` filled while building the chart; `DataPointClicked` looks the clicked label up there (the plan used `CategoryCodes.IndexOf`, a type mismatch).
- Both chart pages have a `Refresh` trigger on the add-in and a null/non-value guard in `DataPointClicked` (added in review).
- The add-in is in namespace `System.Integration`, so the chart pages use both `System.Integration` and `System.Visualization`.
