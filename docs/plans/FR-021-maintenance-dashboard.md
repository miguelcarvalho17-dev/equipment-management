# FR-021 Maintenance Dashboard

> Status: **APPROVED by the user (defaults for Q1-Q10 accepted).** Open questions Q1-Q10 (see "Risks and open questions") each have a
> proposed default, and the plan is written with these defaults. **Q1 (what "this month" counts), Q2 (what "YTD" means:
> calendar year, Today, maintenance date) and Q3 (where the four KPIs are placed on the dashboard) change the design if
> they are answered differently.**
> Source: GitHub issue #40. Branch: `feature/FR-021-maintenance-dashboard`.
> No events report. FR-021 only reads this app's own data (table 50100 "EQM Equipment" fields 9 Status and 22 "Next
> Maintenance Date", table 50106 "EQM Maintenance History Entry" fields 4 "Maintenance Date" and 8 Cost) and shows it on
> this app's own cue part. It subscribes to no standard events and changes no standard behavior, so al-event-finder is
> not needed.
> Scope: main app only. **No new objects. No new stored field.** Two FlowFields and two FlowFilters on the temporary cue
> table 50104, one changed and one new procedure in codeunit 50107, two new tiles and one `OnOpenPage` line on cue part
> 50106, AboutText and search terms on page 50109. **No permission set change. No new event. No version bump** (app.json
> stays 29.0.0.0). **No upgrade logic.** Tests deferred (Q9 default): test codeunit 50175 is reserved, and the tester step
> is skipped.
> Workflow for FR-021: planner -> (human approves plan) -> developer -> reviewer -> build -> **tester step SKIPPED
> (Q9)** -> documenter -> appsource-validator.

## Goal
The equipment dashboard (page 50109) and the Equipment Manager Role Center (page 50110) show the four maintenance KPIs
of issue #40: Equipment in Maintenance, Planned Maintenance This Month, Overdue Maintenance and Total Maintenance Cost
YTD. Two of them already exist (FR-009, FR-020); FR-021 adds the other two as live tiles on the shared cue part 50106,
built on the FR-013, FR-019 and FR-020 fields and filters, each with a drill-down to the records behind the number.

### Requirement restated
- MD-R1 The dashboard includes maintenance-related KPIs.
- MD-R2 KPI "Equipment in Maintenance".
- MD-R3 KPI "Planned Maintenance This Month".
- MD-R4 KPI "Overdue Maintenance".
- MD-R5 KPI "Total Maintenance Cost YTD".

### What already exists and is reused
| Already present | Built in | Use in FR-021 |
|---|---|---|
| Cue table 50104 field 13 "Equipment in Maintenance" (count of table 50100 where Status = In Maintenance), tile in `cuegroup(Equipment)` of page 50106, drill-down to Equipment List. | FR-009, FR-012 | **MD-R2 is met as is.** No change. |
| Cue table 50104 field 50 "Overdue Maintenance Equipment" + FlowFilter 51, set by `SetPlannedMaintenanceCueFilters` in codeunit 50107; styled tile in `cuegroup(PlannedMaintenance)`. Same rule as `IsPlannedMaintenanceOverdue` on table 50100. | FR-020 | **MD-R4 is met as is.** No change to the field, filter, rule, style or caption. |
| Table 50100 field 22 "Next Maintenance Date" (stored, calculated from Last Maintenance Date + frequency; 0D when no plan; moves forward when Preventive maintenance is posted). | FR-019 | Input of the new "Planned Maintenance This Month" tile. |
| Cue table 50104 field 20 "Total Maintenance Cost" = sum of table 50106 Cost (posted maintenance only, all time), tile in `cuegroup(MaintenanceCosts)`, drill-down to page "EQM Maintenance History". Key `EquipmentDate` ("Equipment No.", "Maintenance Date") with `SumIndexFields = Cost` on table 50106. | FR-013, FR-011 | Same definition of cost (posted only, LCY), restricted to the year to date by a date FlowFilter. |
| Date-FlowFilter-on-cue pattern: FlowField with `field("... Filter")`, filter set by codeunit 50107 in `OnOpenPage` of page 50106 from `Today()`; 0D means today. | FR-015, FR-020 | Same pattern for both new tiles. |
| Page 50109 (dashboard, Refresh calls `RefreshCues`) and Role Center 50110 both embed page 50106. | FR-009 | New tiles appear on both without layout change. |
| Permission set "EQM - Reader" (50100): R on tabledata 50100 and 50106, X on table 50104, page 50106, codeunit 50107, pages "EQM Equipment List" and "EQM Maintenance History". Manager and Administrator include Reader. | NFR-002 | Covers everything FR-021 reads and opens. |

### Interpretation (defaults, see Q1-Q4)
With T = `Today()` (real date, not Work Date, as in FR-015, FR-019 and FR-020):
- **Planned Maintenance This Month (Q1):** the number of equipment records whose "Next Maintenance Date" is between the
  first and the last day of T's calendar month, both included, and whose Status is not Lost or Disposed. Dates earlier
  in the month (already overdue) are included, so such equipment is counted in this tile **and** in the overdue tile.
  Equipment with a blank Next Maintenance Date is never counted. In Maintenance, Assigned and Available equipment is
  counted. Because posting Preventive maintenance moves the Next Maintenance Date forward (FR-019), the tile shows the
  planned maintenance **still due** this month, not the maintenance already done this month.
- **Total Maintenance Cost YTD (Q2):** the sum of Cost of the posted maintenance history entries (table 50106) whose
  "Maintenance Date" is from 1 January of T's calendar year to T, both included. Open maintenance records are not
  included (same rule as the FR-013 Total Maintenance Cost tile). Amounts are in LCY. Zero-cost entries are included
  (they add nothing).
- **Placement (Q3):** least change to the existing dashboard. "Equipment in Maintenance" stays in group "Equipment".
  "Planned Maintenance This Month" is added to the existing group "Planned Maintenance", before "Overdue Maintenance
  Equipment" (issue order). "Total Maintenance Cost YTD" is added to the existing group "Maintenance Costs", between
  "Total Maintenance Cost" and "Average Maintenance Cost". The issue's "Overdue Maintenance" KPI is the existing tile
  "Overdue Maintenance Equipment" (caption kept, Q4).
- **Style:** the new tiles have no style (standard tile), Q5.
- **Not in scope:** charts by month, planned maintenance next month, maintenance cost of the previous year, fiscal-year
  periods, a separate maintenance Role Center, notifications.

## Approach and rejected alternatives
- Chosen: **two FlowFields with date FlowFilters on the temporary cue table (FR-015/FR-020 pattern).** Codeunit 50107
  sets the month range and the year-to-date range from a reference date when the cue part opens. The platform calculates
  the counts and the sum; drill-down needs no code because the FlowField filters are applied to the drill-down page.
  Nothing is stored, nothing new needs a permission, and the existing tiles for MD-R2 and MD-R4 are reused unchanged.
- Rejected: a new "Maintenance" cue group that repeats Equipment in Maintenance and moves the overdue tile. It shows one
  tile twice (or removes it from the FR-009 Equipment group) and moves an FR-020 control. Kept as alternative in Q3.
- Rejected: a separate Maintenance Dashboard page or cue part. The issue extends "the dashboard"; a second part would
  duplicate the cue table pattern and need new permissions.
- Rejected: computing the two KPIs in code (page variables + `OnDrillDown`). Loses the standard cue drill-down and
  needs extra code for what FlowFields do already.
- Rejected: reusing the "Date Filter" FlowFilter on table 50100 ("Total Maintenance Cost" per equipment) and summing per
  equipment. N reads instead of one SIFT sum.
- Rejected: counting "planned this month" from maintenance records or history. FR-019 defines the plan only through
  "Next Maintenance Date"; there is no planned-maintenance document.
- Rejected: YTD by "Posted At". "Maintenance Date" is the business date the FR-013 period filters already use
  (alternative in Q2).
- Rejected: fiscal year from "Accounting Period". The issue says YTD; calendar year matches the rest of the dashboard and
  needs no G/L setup (alternative in Q2).
- Rejected: a new key on table 50100 "Next Maintenance Date" or on table 50106 "Maintenance Date". Schema change for
  small volumes (R4).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50107, pages 50100-50120, codeunits 50103-50115, queries
50100-50103, enums 50100-50106, page extension 50100, permission sets 50100-50102, permission set extension 50103,
profile "EQM EQUIPMENT MANAGER". Fields in use on table 50104: 1, 10-15, 20-21, 30-32, 40-41, 50-51 (22-29 free).
Test app: no objects (folder `test/` has no `.al` files); test codeunits 50150-50174 are reserved by FR-001 to FR-020,
none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50104 | EQM Equipment Cue | Modify (own) | FlowField 22 "Total Maintenance Cost YTD", FlowFilter 23 "Maint. Cost YTD Filter", FlowField 52 "Planned Maintenance This Month", FlowFilter 53 "Planned Maint. Month Filter" |
| Codeunit | 50107 | EQM Dashboard Mgt. | Modify (own) | `SetPlannedMaintenanceCueFilters` also sets the month filter; new `SetMaintenanceCostCueFilters`; three locked date formula labels |
| Page | 50106 | EQM Equipment Cues | Modify (own) | Two new tiles; `OnOpenPage` calls `SetMaintenanceCostCueFilters` |
| Page | 50109 | EQM Equipment Dashboard | Modify (own) | AboutText and AdditionalSearchTerms only |

Not changed: tables 50100-50103, 50105-50107; pages 50100-50105, 50107, 50108, 50110 (Role Center shows the tiles
through page 50106), 50111-50120; codeunits 50103-50106, 50108-50115; queries; enums; page extension 50100; permission
sets 50100-50102; permission set extension 50103; the profile; `app/app.json`; `test/`. **No new files.**

Next free IDs after FR-021 (unchanged): tables 50108, pages 50121, codeunits 50116, queries 50104, enums 50107, page
extensions 50101, permission sets 50104; next free field on table 50104: 24 (in the 20s block) and 54. Test app: **test
codeunit 50175 reserved for FR-021 "EQM Maintenance Dashboard Tests"**, not built now (Q9).

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report, except where a fallback is written here.
- V1 `CalcDate` accepts a Text/Label date formula in angle brackets: `'<-CM>'` returns the first day of the month,
  `'<CM>'` the last day, `'<-CY>'` 1 January of the year of the reference date. (Angle brackets make the formula
  language independent.) Fallback: build the dates with `DMY2Date(1, Date2DMY(ReferenceDate, 2), Date2DMY(ReferenceDate,
  3))`, `DMY2Date(1, 1, Date2DMY(ReferenceDate, 3))` and `CalcDate('<CM>', ...)`.
- V2 A Decimal `sum` FlowField on the temporary cue table with `"Maintenance Date" = field("Maint. Cost YTD Filter")` is
  calculated by the cue part without an explicit `CalcFields` (same as fields 20, 21 and the warranty count tiles), and
  respects the FlowFilter set in `OnOpenPage`. Fallback if the sandbox shows the all-time amount: add
  `Rec.CalcFields("Total Maintenance Cost YTD", "Planned Maintenance This Month")` to the existing `OnAfterGetRecord`.
- V3 Drill-down on the YTD tile (`DrillDownPageId = "EQM Maintenance History"`) opens the history with the
  "Maintenance Date" range applied (same mechanism as FR-015/FR-020 count tiles, here on a sum FlowField).
- V4 The CalcFormula `count("EQM Equipment" where("Next Maintenance Date" = field("Planned Maint. Month Filter"), Status =
  filter(<> Lost & <> Disposed)))` compiles (same syntax as field 50).

### Table 50104 "EQM Equipment Cue" (change)
New fields. They inherit `DataClassification = CustomerContent` from the table; set nothing else on them than listed.
Place fields 22 and 23 directly after field 21, and fields 52 and 53 directly after field 51.

| ID | Name | Type / class | Caption | ToolTip | CalcFormula / other |
|---|---|---|---|---|---|
| 22 | "Total Maintenance Cost YTD" | Decimal, FlowField, `Editable = false`, `AutoFormatType = 1` | Total Maintenance Cost YTD | 'Specifies the total cost of the maintenance posted with a maintenance date from 1 January of the current year up to and including today, in local currency. Open maintenance records are not included until they are posted. Choose the amount to see the maintenance history.' | sum("EQM Maintenance History Entry".Cost where("Maintenance Date" = field("Maint. Cost YTD Filter"))) |
| 23 | "Maint. Cost YTD Filter" | Date, FlowFilter | Maintenance Cost YTD Filter | 'Specifies the maintenance dates that count for the year-to-date maintenance cost. It is set automatically.' | none |
| 52 | "Planned Maintenance This Month" | Integer, FlowField, `Editable = false` | Planned Maintenance This Month | 'Specifies the number of equipment records whose next maintenance date is in the current month, including dates earlier this month that are already overdue. Lost and disposed equipment is not counted. When preventive maintenance is posted, the next maintenance date moves forward and the equipment is no longer counted. Choose the number to see the equipment.' | count("EQM Equipment" where("Next Maintenance Date" = field("Planned Maint. Month Filter"), Status = filter(<> Lost & <> Disposed))) |
| 53 | "Planned Maint. Month Filter" | Date, FlowFilter | Planned Maintenance Month Filter | 'Specifies the next maintenance dates that count as planned this month. It is set automatically.' | none |

Name lengths (limit 30): "Total Maintenance Cost YTD" 26, "Maint. Cost YTD Filter" 22, "Planned Maintenance This
Month" 30, "Planned Maint. Month Filter" 27.

### Codeunit 50107 "EQM Dashboard Mgt." (change)
- Add to the existing `var` section three locked labels (they must not be translated):
  `StartOfMonthFormulaTok: Label '<-CM>', Locked = true;`, `EndOfMonthFormulaTok: Label '<CM>', Locked = true;`,
  `StartOfYearFormulaTok: Label '<-CY>', Locked = true;`.
- **Change** `internal procedure SetPlannedMaintenanceCueFilters(var EquipmentCue: Record "EQM Equipment Cue";
  ReferenceDate: Date)` (signature unchanged). After the existing `SetFilter("Overdue Maintenance Filter", ...)` line add:
  `EquipmentCue.SetRange("Planned Maint. Month Filter", CalcDate(StartOfMonthFormulaTok, ReferenceDate),
  CalcDate(EndOfMonthFormulaTok, ReferenceDate))` (V1). The 0D -> `Today()` step stays first.
  New doc summary: "Sets the date filters of the planned maintenance tiles from a reference date. Overdue: a next
  maintenance date that is filled in and before the reference date, the same rule as IsPlannedMaintenanceOverdue on the
  equipment. Planned this month: a next maintenance date from the first to the last day of the reference date's month.
  0D means today." Param docs unchanged except ReferenceDate: "The date the tiles are calculated on."
- **New** `internal procedure SetMaintenanceCostCueFilters(var EquipmentCue: Record "EQM Equipment Cue"; ReferenceDate:
  Date)`, placed directly after `SetPlannedMaintenanceCueFilters`:
  1. When ReferenceDate = 0D: ReferenceDate := `Today()`.
  2. `EquipmentCue.SetRange("Maint. Cost YTD Filter", CalcDate(StartOfYearFormulaTok, ReferenceDate), ReferenceDate)`.
  Doc: summary "Sets the date filter of the year-to-date maintenance cost tile: maintenance dates from 1 January of the
  reference date's year up to and including the reference date. 0D means today." Params: EquipmentCue "The cue record to
  set the filter on."; ReferenceDate "The date the tile is calculated on."
- No other change. No new event, no `Commit`, no database write.

### Page 50106 "EQM Equipment Cues" (change)
- `cuegroup(PlannedMaintenance)`: add, **before** the existing "Overdue Maintenance Equipment" control,
  `field("Planned Maintenance This Month"; Rec."Planned Maintenance This Month")` with
  `DrillDownPageId = "EQM Equipment List"`. No Caption, ToolTip, ApplicationArea or StyleExpr on the control.
- `cuegroup(MaintenanceCosts)`: add, **between** "Total Maintenance Cost" and "Average Maintenance Cost",
  `field("Total Maintenance Cost YTD"; Rec."Total Maintenance Cost YTD")` with
  `DrillDownPageId = "EQM Maintenance History"`. No other properties.
- `OnOpenPage`: directly after `DashboardMgt.SetPlannedMaintenanceCueFilters(Rec, Today());` add
  `DashboardMgt.SetMaintenanceCostCueFilters(Rec, Today());` (before the notifications call).
- `OnAfterGetRecord`, `RefreshCues`, the other groups and tiles: unchanged (fallback in V2 only if needed).
- Group order stays: Equipment, Warranty, Planned Maintenance, Maintenance Costs.

### Page 50109 "EQM Equipment Dashboard" (change)
- AboutText becomes (one line in the source): 'The tiles count your equipment by status, show how many warranties are expiring within 30 days or have expired, how many warranty alerts are open, how many pieces of equipment have planned maintenance due this month or overdue, and show the total cost of posted maintenance, this year''s cost so far and the average cost. **Total Equipment** includes lost and disposed equipment; the warranty and planned maintenance tiles do not. **Overdue Maintenance Equipment** turns red when at least one piece of equipment has a next maintenance date before today. The charts show how your equipment is spread over categories and statuses, which categories cost the most in maintenance, and the ten pieces of equipment with the highest maintenance cost. Choose a tile or a chart segment to see the details. Choose **Refresh** to update the numbers.'
- AdditionalSearchTerms becomes: 'equipment kpi, equipment overview, equipment chart, maintenance cost, maintenance kpi, warranty expiration, expiring warranties, warranty alerts, overdue maintenance, maintenance due, maintenance dashboard, maintenance this month, maintenance cost ytd'
- Nothing else changes.

### app.json, translations
- **app.json: no change.** Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf` (four field captions and ToolTips, AboutText,
  search terms). The three locked date formula labels must not appear as translatable units. Commit the file; never edit
  it by hand.

## Data model and upgrade impact
- **No stored schema change.** Table 50104 is `TableType = Temporary`; its new FlowFields and FlowFilters create no
  columns. Tables 50100 and 50106 and their keys are unchanged.
- DataClassification: new cue fields inherit `CustomerContent` from the table. They hold counts and amounts only and
  are never stored. No personal data.
- Performance per open or Refresh: one more `COUNT` on table 50100 (filtered on "Next Maintenance Date" and Status, no
  index, as the FR-020 tile) and one more `SUM` on table 50106 filtered on "Maintenance Date" only. The SIFT key
  `EquipmentDate` has "Maintenance Date" as second field, so the sum uses the SIFT view grouped over all equipment
  (R4).
- Upgrade codeunit: **not needed.** Nothing stored, nothing released, version unchanged. Existing data is shown at once.

## Events
**Standard BC events: none.** No events report is required. Subscribed: none.

Published: **none** (Q8). The KPIs are read-only FlowField calculations; a subscriber could not change a FlowFilter-based
count consistently. Partners can add their own tiles by extending page 50106 (a page extension on a cue part is
additive). The definition of "planned" is already extensible through the FR-019 event `OnBeforeCalcNextMaintenanceDate`;
the tile follows the stored date. No existing event is raised by the new code (it only sets filters; no `Modify`).

## Permissions
**No permission set changes.**
- "EQM - Reader" already has R on tabledata "EQM Equipment" and "EQM Maintenance History Entry", X on table "EQM
  Equipment Cue" (temporary, no tabledata entry needed), pages "EQM Equipment Cues", "EQM Equipment Dashboard", "EQM
  Equipment Manager RC", "EQM Equipment List", "EQM Maintenance History", and codeunit "EQM Dashboard Mgt.". Manager and
  Administrator include Reader rights (NFR-002).

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See the four maintenance tiles on dashboard and Role Center | yes | yes | yes |
| Drill down from Planned Maintenance This Month / Total Maintenance Cost YTD | yes | yes | yes |
| Change the numbers (register/post maintenance, change the plan) | no | yes | yes |

## Compatibility
- AppSource mode, development phase: nothing is released, no baseline, no Obsolete handling needed.
- No new public surface. Table 50104 and codeunit 50107 are `Access = Internal`; the changed procedure keeps its
  signature; the new procedure is `internal`.
- Page 50106 (public, extensible): two controls are added inside existing groups; no control, group or action is
  renamed, moved or removed, so existing page extensions that anchor on controls stay valid. Once released, the new
  control names become anchors for partners.
- No behavior change: FR-009, FR-013, FR-019 and FR-020 tiles, rules, styles and captions are unchanged.
  `SetPlannedMaintenanceCueFilters` keeps the overdue filter exactly as before and only adds a second filter.
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-021-maintenance-dashboard.md` and `docs/help/FR-021-maintenance-dashboard.md`: the four KPIs
    and where they are (group per tile), the month and YTD rules with boundary days, today not the work date,
    posted-only cost, maintenance date not posting date, why a tile can count the same equipment as the overdue tile,
    why equipment leaves "this month" after Preventive posting, drill-downs, Refresh, roles.
  - `docs/help/FR-009-dashboard-kpis.md`, `docs/help/FR-013-maintenance-cost-tracking.md`,
    `docs/help/FR-019-planned-maintenance.md`, `docs/help/FR-020-overdue-maintenance-monitoring.md` and the matching
    `docs/features/` files: one cross-reference each to the new tiles.
  - `README.md`: new row "Maintenance dashboard KPIs (FR-021)" with "Built, not yet verified in a Business Central
    sandbox".
  - `CHANGELOG.md`: new top section `## FR-021 Maintenance Dashboard (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-021 sandbox checks (not run; automated tests deferred, Q9, test codeunit 50175 reserved)"
    with MD-SB1 to MD-SB8.

## Test scenarios
**No automated tests in this iteration** (Q9 default, as in FR-003 to FR-020). Test codeunit 50175 "EQM Maintenance
Dashboard Tests" is reserved and the tester step is skipped. The list is the reference for the developer, the reviewer
and the tests written later (needs the test-app fix in `docs/TODO.md` and `internalsVisibleTo`, because codeunit 50107
and table 50104 are internal).

Test data, unless stated: all equipment, maintenance records and history entries deleted first; active category LAPTOP;
equipment saved with `Insert(true)`, Status Available. R = 15 June 2026 (a fixed past reference date; Today() is later).
For a given Next Maintenance Date D, set "Next Maintenance Date" directly and save with `Modify(false)` (only the read
rule is tested), unless the scenario posts maintenance. History entries are created only by registering and posting
maintenance records through codeunit "EQM Maintenance-Post" (`[ConfirmHandler]` Yes, `[MessageHandler]` where needed).
Cue filters are set with `SetPlannedMaintenanceCueFilters(Cue, R)` / `SetMaintenanceCostCueFilters(Cue, R)` on a
temporary cue record that was inserted, then `CalcFields`.

Equipment in Maintenance (MD-R2, regression)
- MD1 Given E1 Available, E2 with one open maintenance record (In Maintenance), E3 Lost, when the cue is calculated,
  then "Equipment in Maintenance" = 1; after E2's record is posted, it is 0.

Planned Maintenance This Month (MD-R3)
- MD2 Given E1 Next = 1 June 2026, E2 Next = 30 June 2026, E3 Next = 31 May 2026, E4 Next = 1 July 2026, E5 Next = 0D,
  then "Planned Maintenance This Month" = 2 (E1, E2): both month boundaries are included, neighbours and blank are not.
- MD3 Given E6 Next = 10 June 2026 (before R), then E6 is counted in "Planned Maintenance This Month" **and** in
  "Overdue Maintenance Equipment" (Q1).
- MD4 Given E7 Lost and E8 Disposed, both with Next = 20 June 2026, then neither is counted.
- MD5 Given E9 Assigned and E10 In Maintenance, both with Next = 20 June 2026, then both are counted.
- MD6 Given R = 10 February 2028 (leap year) and Next = 29 February 2028, then counted; with R = 10 February 2027 and
  Next = 1 March 2027, then not counted (end of month computed correctly).
- MD7 Given R = 31 December 2026, then the filter range is 1 December 2026..31 December 2026 (check with
  `GetRangeMin`/`GetRangeMax` on "Planned Maint. Month Filter").
- MD8 Given the filters set with ReferenceDate 0D, then the month filter equals the one set with `Today()`.
- MD9 Given E11 with Last Maintenance Date = Today - 6 months, frequency 6 (Next in the current month) and counted on a
  cue with `Today()`, when a Preventive record dated today is registered and posted, then Next moves 6 months forward and
  the tile goes down by 1. With a Corrective record instead, the tile does not change.
- MD10 (no data) Given no equipment with a Next Maintenance Date, then the tile is 0 and no error is raised.

Overdue Maintenance (MD-R4, regression with FR-020)
- MD11 Given the data of FR-020 OM12, when `SetPlannedMaintenanceCueFilters(Cue, R)` runs, then "Overdue Maintenance
  Equipment" is still 2 and the "Overdue Maintenance Filter" text is unchanged from before FR-021.

Total Maintenance Cost YTD (MD-R5)
- MD12 Given posted entries for E1 dated 31 Dec 2025 cost 500, 1 Jan 2026 cost 100, 10 Mar 2026 cost 0, 15 Jun 2026
  cost 200, and 20 Jun 2026 cost 50, when the cost filter is set with R = 15 June 2026, then "Total Maintenance Cost YTD"
  = 300 (1 January and R included; previous year and after R excluded) and "Total Maintenance Cost" = 850.
- MD13 Given entries on two different equipment records in the year, then both are summed (no per-equipment filter).
- MD14 (negative) Given an open (not posted) record dated 1 May 2026 with cost 1,000, then it is not included; after it
  is posted, the YTD amount grows by 1,000.
- MD15 Given R = 1 January 2026, then only entries dated 1 January 2026 count.
- MD16 Given no history entries, then the tile is 0 and no error is raised.
- MD17 Given filters set with ReferenceDate 0D, then the range is 1 January of the current year..Today().
- MD18 For any data: "Total Maintenance Cost YTD" <= "Total Maintenance Cost" (costs are never negative).

Cue part and dashboard (MD-R1, TestPage)
- MD19 Given the data of MD2 and MD12 (cue calculated on Today(), so dates are shifted relative to Today), when page
  50106 opens, then group Planned Maintenance shows "Planned Maintenance This Month" then "Overdue Maintenance
  Equipment", and group Maintenance Costs shows "Total Maintenance Cost", "Total Maintenance Cost YTD", "Average
  Maintenance Cost", with the expected values.
- MD20 Given page 50106, when "Planned Maintenance This Month" is drilled down (`Trap` on page "EQM Equipment List"),
  then the list shows only the counted equipment (current month, not Lost or Disposed).
- MD21 Given page 50106, when "Total Maintenance Cost YTD" is drilled down (`Trap` on page "EQM Maintenance History"),
  then the list shows only entries from 1 January to today.
- MD22 Given page 50109 open, when a maintenance record is posted in the test and Refresh is invoked, then the YTD tile
  shows the new amount without reopening.
- MD23 (negative) Given the tiles, when the user tries to edit a tile value, then it is not possible; opening the page
  writes no data (no stored cue row, equipment and history SystemModifiedAt unchanged).

Permissions (`TestPermissions = Restrictive`, with D365 BASIC)
- MD24 Given a user with EQM - Reader only, when page 50109 opens and both new tiles are drilled down, then no
  permission error is raised.
- MD25 (negative) Given a user without any EQM permission set, when page 50109 opens, then a permission error is
  raised (unchanged from FR-009 N6).

### Manual sandbox checks (for the user)
- MD-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` has the new captions, ToolTips,
  AboutText and search terms, and not the locked date formula labels.
- MD-SB2 Dashboard and Role Center: "Planned Maintenance This Month" before "Overdue Maintenance Equipment"; "Total
  Maintenance Cost YTD" between "Total Maintenance Cost" and "Average Maintenance Cost"; amount formatted as currency (V2).
- MD-SB3 Equipment with Next Maintenance Date on the 1st and the last day of this month are counted; last day of the
  previous month and first day of the next month are not.
- MD-SB4 Drill-down from both new tiles opens the filtered list; record which filters the filter pane shows (V3).
- MD-SB5 Post a Preventive record for equipment due this month: after Refresh, the month tile goes down and the YTD
  amount goes up by the cost.
- MD-SB6 Change the work date to last year: tiles do not change (Q2, Today not Work Date).
- MD-SB7 Non-SUPER Reader sees the tiles and can drill down.
- MD-SB8 Tell Me finds the dashboard with "maintenance dashboard"; the teaching tip shows the new text.

## Risks and open questions
Open questions (each has the default used in this plan; answer to change it):
- **Q1 What "Planned Maintenance This Month" counts.** Default: equipment (not maintenance records) whose Next
  Maintenance Date is from the 1st to the last day of the current month, Lost/Disposed excluded; overdue dates earlier
  this month are included (double counted with the overdue tile); equipment drops out once Preventive maintenance is
  posted. Alternatives: (a) only from today to the end of the month (no overlap with overdue); (b) also count the
  Preventive maintenance already posted this month ("planned and done"). **Changes the design** (filter range, MD2-MD3,
  MD9; (b) needs another FlowField on table 50106).
- **Q2 What "YTD" means.** Default: calendar year, 1 January to `Today()`, by history "Maintenance Date", posted only.
  Alternatives: Work Date instead of Today; fiscal year from the Accounting Period table; "Posted At" instead of
  Maintenance Date; open records included. **Changes the design** (filter procedure, ToolTip, MD12-MD17).
- **Q3 Placement.** Default: new tiles added to the existing groups; Equipment in Maintenance and Overdue stay where
  they are. Alternative: one new cue group "Maintenance" with exactly the four issue KPIs in issue order (Equipment in
  Maintenance shown a second time or removed from group Equipment; Overdue moved; group "Planned Maintenance" removed).
  **Changes the design** (page 50106 layout, MD19).
- **Q4 Caption of the overdue KPI.** Default: keep "Overdue Maintenance Equipment" (FR-020). Alternative: rename the
  caption to "Overdue Maintenance" as in the issue (caption only; the field name stays).
- **Q5 Tile styles.** Default: no style for the two new tiles. Alternative: "Planned Maintenance This Month" Ambiguous
  (yellow) when > 0.
- **Q6 Caption length.** "Planned Maintenance This Month" and "Total Maintenance Cost YTD" are long for a tile and may
  wrap. Alternative captions: "Maintenance Due This Month", "Maintenance Cost YTD".
- **Q7 Follow-ups not built.** Next month's planned maintenance, cost of the previous year, a monthly cost chart,
  open (unposted) maintenance cost tile.
- **Q8 No integration event.** Default: none (see Events).
- **Q9 Automated tests.** Default: deferred, as in FR-003 to FR-020; test codeunit 50175 reserved, tester step skipped;
  MD-SB1 to MD-SB8 are the verification.
- **Q10 Help location.** Default: a separate FR-021 help article plus cross-references. Alternative: only extend the
  FR-009 dashboard help.

Risks:
- R1 A cue page left open past midnight (or past the end of a month or year) keeps the old filters until it is reopened;
  Refresh does not reset them (same as FR-015 R3 and FR-020 R3). Accepted.
- R2 `Today()` uses the session time zone; around midnight on the last day of a month or year two users can see
  different numbers. Accepted.
- R3 The month tile and the overdue tile can count the same equipment (Q1 default). The ToolTip and help must say so,
  or users will add them up.
- R4 Both new tiles scan without a dedicated index (table 50100 on "Next Maintenance Date"; table 50106 on "Maintenance
  Date" as second key field). Acceptable for equipment volumes; an additive key later is AppSource-safe.
- R5 Maintenance done late in December but posted in January counts in the previous year (maintenance date rule, Q2).
- R6 V2: if the platform does not apply the FlowFilter for a sum FlowField on a temporary cue record, the YTD tile
  shows the all-time amount; the fallback `CalcFields` in `OnAfterGetRecord` fixes it.
- R7 No automated tests (Q9): regressions are caught only by review and sandbox checks.
