# FR-021 Maintenance Dashboard

## Purpose
The equipment dashboard (page 50109) and the Equipment Manager Role Center (page 50110) show the four maintenance KPIs of GitHub issue #40: Equipment in Maintenance, Planned Maintenance This Month, Overdue Maintenance and Total Maintenance Cost YTD. Two already existed (FR-009, FR-020). FR-021 adds Planned Maintenance This Month and Total Maintenance Cost YTD as tiles on the shared cue part 50106, each with a drill-down. Nothing is stored; the tiles are FlowFields on a temporary cue table.

Status: describes the code as implemented (uncommitted changes on branch `feature/FR-021-maintenance-dashboard`). Review verdict: APPROVE WITH COMMENTS, no blockers. **Build: clean, CodeCop and UICop 0 errors and 0 warnings.** **Tests: automated tests are deferred to a later version (Q9); test codeunit 50175 "EQM Maintenance Dashboard Tests" is reserved.** Sandbox checks V2, V3 and MD-SB1 to MD-SB8 are still open. App version stays 29.0.0.0. No new objects, no stored field, no upgrade codeunit, no new event, no standard events subscribed (no events report), no permission set change.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50104 | EQM Equipment Cue | Field 22 "Total Maintenance Cost YTD" (FlowField, sum), field 23 "Maint. Cost YTD Filter" (FlowFilter), field 52 "Planned Maintenance This Month" (FlowField, count), field 53 "Planned Maint. Month Filter" (FlowFilter) |
| Codeunit | 50107 | EQM Dashboard Mgt. | `SetPlannedMaintenanceCueFilters` also sets the month filter; new internal `SetMaintenanceCostCueFilters`; three locked date formula labels |
| Page | 50106 | EQM Equipment Cues | Tile "Planned Maintenance This Month" (group Planned Maintenance, before Overdue), tile "Total Maintenance Cost YTD" (group Maintenance Costs, between Total and Average); `OnOpenPage` calls `SetMaintenanceCostCueFilters` |
| Page | 50109 | EQM Equipment Dashboard | AboutText and AdditionalSearchTerms only |
| Codeunit (test app) | 50175 | EQM Maintenance Dashboard Tests | Reserved, not built (tests deferred) |

Page 50110 (Role Center) is unchanged; it shows the tiles through page 50106. Reused unchanged: "Equipment in Maintenance" (field 13, group Equipment) and "Overdue Maintenance Equipment" (field 50, group Planned Maintenance).

## Behavior
With T = `Today()` (real date, not Work Date):
- **Equipment in Maintenance:** equipment with Status In Maintenance (FR-009, unchanged).
- **Planned Maintenance This Month:** count of equipment whose Next Maintenance Date is from the first to the last day of T's month, both included, and whose Status is not Lost and not Disposed. `SetPlannedMaintenanceCueFilters` sets filter 53 with `CalcDate('<-CM>', ...)` and `CalcDate('<CM>', ...)`. Blank dates are never counted. Available, Assigned and In Maintenance equipment is counted.
  - Dates earlier in the month (already overdue) are counted, so the same equipment can be in this tile and in Overdue Maintenance Equipment. Do not add the two.
  - Posting Preventive maintenance moves Next Maintenance Date forward (FR-019), so the equipment leaves the tile. The tile shows maintenance still due, not maintenance done.
- **Overdue Maintenance:** the FR-020 tile "Overdue Maintenance Equipment", caption kept. Its filter rule is unchanged.
- **Total Maintenance Cost YTD:** sum of Cost of table 50106 "EQM Maintenance History Entry" with Maintenance Date from 1 January of T's year (`CalcDate('<-CY>', ...)`) to T, both included. Posted maintenance only (history entries), all equipment, local currency. Filtered by Maintenance Date, not Posted At. Zero-cost entries add nothing. Same cost definition as the all-time tile "Total Maintenance Cost".
- **Filters:** page 50106 `OnOpenPage` calls both filter procedures with `Today()`. 0D as reference date means today. The procedures only set filters; no write, no `Commit`.
- **Drill-down:** the month tile opens "EQM Equipment List", the YTD tile opens "EQM Maintenance History" (`DrillDownPageId`). TODO(verify) V3: that the date range is applied to the opened list.
- **Not in scope:** charts by month, next month's plan, previous-year cost, fiscal-year periods, notifications, a separate Role Center.

## Setup
No setup. The tiles fill from existing equipment (plan fields, FR-019) and posted maintenance (FR-010, FR-013).

## Extending (events)
None published, none subscribed (plan decision Q8). The definition of "planned" follows the stored Next Maintenance Date, which can be changed through the FR-019 event `OnBeforeCalcNextMaintenanceDate`. Partners can add tiles by extending page 50106. `SetMaintenanceCostCueFilters` and `SetPlannedMaintenanceCueFilters` are `internal`.

## Permissions
No permission set changes. EQM - Reader already has R on tabledata 50100 and 50106 and execute on table 50104, pages 50106, 50109, 50110, "EQM Equipment List", "EQM Maintenance History" and codeunit 50107; Manager and Administrator include Reader rights.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See the four maintenance tiles, drill down | yes | yes | yes |
| Change the numbers (post maintenance, change the plan) | no | yes | yes |

From code reading and the plan, not a sandbox run (MD-SB7).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand. Checked: the four new field captions and ToolTips are present and the locked labels `<-CM>`, `<CM>`, `<-CY>` are not.

## Upgrade and compatibility
Nothing stored, so no upgrade code and no schema change; table 50104 is temporary. Two controls are added inside existing groups of page 50106; none is renamed, moved or removed. FR-009, FR-013, FR-019 and FR-020 tiles, rules and captions are unchanged.

## Known limitations
- A cue page left open past midnight, or past the end of a month or year, keeps the old filters until reopened (Refresh does not reset them).
- `Today()` uses the session time zone.
- Maintenance done in December but posted in January counts in the previous year (Maintenance Date rule).
- Both new tiles scan without a dedicated index.
- Long captions may wrap on a tile.

## Test status
- Build: clean (CodeCop and UICop, 0 errors, 0 warnings).
- No test objects; test codeunit 50175 "EQM Maintenance Dashboard Tests" is reserved. Scenarios MD1 to MD25 in docs/plans/FR-021-maintenance-dashboard.md are a reference only. Automated tests are deferred to a later version.
- Open sandbox checks: V2 (sum FlowField respects the filter without an explicit `CalcFields`; fallback in the plan), V3 (drill-down filter on a sum FlowField) and MD-SB1 to MD-SB8 (see docs/TODO.md).

## Discrepancies plan vs code
- Doc comment of `SetMaintenanceCostCueFilters`: the parameter text said "tiles" and was changed to "tile" to match the plan (comment only).
- README row, docs/TODO.md section and cross-references in the FR-009, FR-013, FR-019 and FR-020 docs, listed in the plan, are done only for README and docs/TODO.md; the cross-references are not written.
