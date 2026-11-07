# FR-013 Maintenance Cost Tracking

## Purpose
Managers see what each piece of equipment has cost in maintenance, next to what it cost to buy. Four KPIs are calculated live from the posted maintenance history (table 50106): Total Maintenance Cost, Average Maintenance Cost, Maintenance Cost by Category and Maintenance Cost by Equipment. They appear on the Equipment list, the Maintenance FactBox, the dashboard and the Equipment Manager Role Center. A Maintenance Cost % column compares the cost with the purchase cost and is highlighted at 100 % or more.

Status: describes the code as implemented. **Build: source has 0 errors and 0 warnings with CodeCop, UICop and AppSourceCop; the only diagnostics are app.json manifest/AppSource items (privacyStatement, EULA, help, logo, url, contextSensitiveHelpUrl, App Insights, demo ID range, affix configuration), none from FR-013. Review: APPROVE WITH CHANGES, no blockers. No automated tests (deferred, plan decision Q8; test codeunit 50167 reserved, nothing written). Nothing was run in a sandbox; checks CS-SB1 to CS-SB10 are NOT verified.** App version stays 29.0.0.0 (app.json unchanged). No stored schema change, no upgrade codeunit, no events published or subscribed, no events report.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Query | 50102 | EQM Maint. Cost by Category | New, internal. Sum of history `Cost` per equipment `Category Code` (inner join Equipment to history), only sums above 0, ordered by cost descending then category code. |
| Query | 50103 | EQM Maint. Cost by Equipment | New, internal. Sum of history `Cost` per `Equipment No.`, only sums above 0, ordered by cost descending then equipment number. |
| Page | 50118 | EQM Category Cost Chart | New CardPart, `BusinessChart` column chart "Maintenance Cost by Category". Blank category shown as '(blank)'. Click a column: Equipment list filtered on that category. Refresh action. |
| Page | 50119 | EQM Equipment Cost Chart | New CardPart, `BusinessChart` column chart "Top 10 Equipment by Maintenance Cost". Click a column: Maintenance History filtered on that equipment. Refresh action. |
| Table | 50100 | EQM Equipment | New field 13 "Date Filter" (FlowFilter), 14 "Total Maintenance Cost" (Sum), 15 "No. of Posted Maintenances" (Count), 16 "Average Maintenance Cost" (Average); internal `GetMaintenanceCostPercentage`, `GetMaintenanceCostStyle`. |
| Table | 50104 | EQM Equipment Cue | New FlowFields 20 "Total Maintenance Cost" (Sum, all entries) and 21 "Average Maintenance Cost" (Average, all entries). |
| Codeunit | 50107 | EQM Dashboard Mgt. | New internal `GetMaintenanceCostByCategory`, `GetTopMaintenanceCostByEquipment`, `GetTopEquipmentLimit`, `ShowMaintenanceHistory`; summary on the codeunit. |
| Codeunit | 50108 | EQM Maintenance Mgt. | **`GetTotalMaintenanceCost(EquipmentNo)` removed** (its only caller was page 50115). |
| Page | 50100 | EQM Equipment List | Columns Total Maintenance Cost (visible), No. of Posted Maintenances, Average Maintenance Cost, Maintenance Cost % (hidden by default); AboutText. |
| Page | 50106 | EQM Equipment Cues | New cue group "Maintenance Costs" with two tiles. |
| Page | 50109 | EQM Equipment Dashboard | Two new chart parts; Refresh covers them; AboutText, Refresh ToolTip and search terms updated. |
| Page | 50110 | EQM Equipment Manager RC | Same two chart parts; new Embedding action "Maintenance History". |
| Page | 50115 | EQM Maintenance FactBox | Total re-pointed to the FlowField (posted only); Average Maintenance Cost and Maintenance Cost % added. |
| PermissionSet | 50100 | EQM - Reader | `X` on the two queries and the two chart pages. |

## Behavior
- **What counts:** posted maintenance only (table 50106). Open records (table 50105) are never included. Posted entries are read-only, so the figures change only when something is posted.
- **Currency:** local currency (LCY), as the existing Cost and Purchase Cost fields.
- **Per equipment (table 50100):** the three FlowFields filter table 50106 on "Equipment No." and on "Maintenance Date" = "Date Filter". They use the existing key `EquipmentDate` (SumIndexFields = Cost). Drill-down on the amount or count opens the Maintenance History list (FlowField drill-down). Average includes zero-cost entries (FR-012 cancel postings) and is 0 when there are no entries.
- **Date Filter (period):** FlowFilter on "Maintenance Date". On the Equipment list it is set through "Filter totals by". The Maintenance FactBox, the dashboard tiles and the charts ignore it and always show all-time values. While a date filter is set the list and the FactBox can therefore show different totals for the same equipment.
- **Maintenance Cost %:** `GetMaintenanceCostPercentage` returns 0 when "Purchase Cost" = 0; otherwise it calls `CalcFields("Total Maintenance Cost")` (uses the record's Date Filter) and returns `Round(Total / Purchase Cost * 100, 0.1)`. Pages show it with `BlankZero`, so it is blank for no purchase cost or no posted maintenance. `GetMaintenanceCostStyle` returns `Unfavorable` for 100 or more, else `Standard`. The 100 % threshold is fixed, with no setup field.
- **Overall tiles (table 50104):** Total = sum of all history entries, Average = average cost per entry (total / number of entries). Drill-down opens page 50117 (all entries). Refreshed by the existing `RefreshCues`.
- **Cost by category:** query 50102 uses the **current** category of each equipment, not the category at posting time. Moving equipment to another category moves its whole cost history. Only categories with a sum above 0 are returned. Equipment without a category is returned with a blank code, shown as '(blank)'.
- **Top 10 by equipment:** `GetTopMaintenanceCostByEquipment(NumberOfEquipment, ...)` clears both lists, exits when NumberOfEquipment is 0 or less, otherwise sets `TopNumberOfRows` and reads the query. The chart uses `GetTopEquipmentLimit` (10). Equal totals sort by ascending equipment number. Equipment without posted cost above 0 is not returned.
- **Chart drill-down:** same pattern as FR-009: `DataPointClicked` reads `XValueString`, looks the label up in a list kept while building the chart and exits silently on a null, non-value or unknown label. Category chart calls `ShowEquipmentByCategory`; equipment chart calls `ShowMaintenanceHistory`.
- **Refresh:** the dashboard Refresh action also calls `RefreshChart` on both new parts. The Role Center has no Refresh action of its own (as in FR-009).

### Codeunit 50107 "EQM Dashboard Mgt." (internal; `///` comments present)
- `GetMaintenanceCostByCategory(var CategoryCodes: List of [Code[20]]; var MaintenanceCosts: List of [Decimal])`
- `GetTopMaintenanceCostByEquipment(NumberOfEquipment: Integer; var EquipmentNos: List of [Code[20]]; var MaintenanceCosts: List of [Decimal])`
- `GetTopEquipmentLimit(): Integer`
- `ShowMaintenanceHistory(EquipmentNo: Code[20])`: runs page 50117 filtered to the equipment.

## Setup
No setup. No new fields in Equipment Setup. To use the period view, set "Date Filter" under "Filter totals by" on the Equipment list. To see the yearly split of the example (Laptop A: 500 + 700 against a purchase cost of 1,200), post maintenance with maintenance dates in two years and filter by year.

## Extending (events)
None published, none subscribed. The feature is read-only reporting with no rule to override. Partners can add their own FlowFields with table extensions. Queries, codeunit procedures and table procedures are internal.

## Permissions
`EQM - Reader` gets `X` on queries 50102, 50103 and pages 50118, 50119. Reader already has R on tables 50100, 50101 and 50106. Manager and Administrator inherit Reader. The charts need the System Application `BusinessChart` objects, granted by D365 BASIC (as in FR-009).

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See cost columns, FactBox costs, Maintenance Cost % | yes | yes | yes |
| See cost tiles and charts on dashboard and Role Center | yes | yes | yes |
| Drill down to the maintenance history | yes | yes | yes |
| Change a cost value | no (FlowFields) | no | no |

From code reading, not a sandbox run.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand.

## Upgrade and compatibility
Additive for stored data: FlowFields and a FlowFilter are not stored, so no SQL column, key or upgrade codeunit. Nothing is released, so no Obsolete handling. Public surface that becomes a contract at release: fields 13-16 on table 50100 and pages 50118, 50119.

Intentional changes to earlier features:
- **Maintenance FactBox total (FR-011, FR-010):** "Total Maintenance Cost" used to sum all records in table 50105, open and posted. It now shows **posted maintenance only**, the same figure as the Equipment list and the dashboard. The control name `TotalMaintenanceCost` is kept. The record counts in the FactBox ("No. of Maintenance Records", "Open Maintenance Records") still include open records. FR-011 scenario H36 ("FactBox total includes both") no longer holds for the total. Users who compare it with the Maintenance Records list see a lower number.
- **Removed procedure (FR-010):** `GetTotalMaintenanceCost(EquipmentNo)` is gone from codeunit 50108 (internal, no other caller).

## Test status
No test objects; test codeunit 50167 "EQM Maintenance Cost Tests" is reserved (plan Q8). Scenarios C1 to C32 in docs/plans/FR-013-maintenance-cost-tracking.md are a reference only. Sandbox checks CS-SB1 to CS-SB10 are listed in docs/TODO.md and are **not verified**.

TODO(verify) in a sandbox:
- Average FlowField returns 0 with no rows; ColumnFilter `filter(> 0)` on the Sum columns; `TopNumberOfRows` before `Open()`; Decimal chart data type renders.
- Decimal cue tiles render readably and drill down to page 50117.
- "Filter totals by: Date Filter" changes the Equipment list totals; filter pane on Total Maintenance Cost works.
- The FactBox does not receive the list's Date Filter (all-time values, plan risk R5).
- Rename of equipment keeps the FlowFields correct (depends on the FR-011 rename cascade, HS-SB9).

## Discrepancies plan vs code
- ToolTip of table 50100 field 14 "Total Maintenance Cost": the plan text said open records "are included when they are posted"; the code says "Open maintenance records are not included until they are posted". Documented the code (same meaning, clearer).
- No other differences found in the changed objects (procedures, queries, fields, pages and permissions match the plan).
