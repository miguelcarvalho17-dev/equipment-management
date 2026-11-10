# FR-022 Warranty Dashboard

## Purpose
The equipment dashboard (page 50109) and the Equipment Manager Role Center (page 50110) show the four warranty KPIs of GitHub issue #41: Active Warranties, Warranties Expiring in 90 Days, Warranties Expiring in 30 Days and Expired Warranties. Two already existed as FR-015 tiles; FR-022 renames their captions and adds Active Warranties and Warranties Expiring in 90 Days as tiles on the shared cue part 50106, each with a drill-down. Nothing is stored; the tiles are FlowFields on a temporary cue table.

Status: describes the code as implemented (uncommitted changes on branch `feature/FR-022-warranty-dashboard`). Review verdict: APPROVE. **Build: clean, CodeCop and UICop, no diagnostics.** **Tests: automated tests are deferred (Q9); test codeunit 50176 "EQM Warranty Dashboard Tests" is reserved, not built.** Sandbox checks V1, V4, V5 and WD-SB1 to WD-SB8 are not run. App version stays 29.0.0.0. No new objects, no stored field, no upgrade codeunit, no new event, no standard events subscribed (no events report), no permission set change.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50104 | EQM Equipment Cue | Field 33 "Active Warranties" (FlowField, count), field 34 "Warranties Expiring 90 Days" (FlowField, count), field 42 "Active Warranty Filter" and field 43 "Warranty 90 Days Filter" (FlowFilters, Date). Captions of fields 30 and 31 changed |
| Codeunit | 50107 | EQM Dashboard Mgt. | `SetWarrantyCueFilters` also sets filters 42 and 43 (signature unchanged); new local variables for codeunit 50110 and the 90 days |
| Page | 50106 | EQM Equipment Cues | Tiles "Active Warranties" and "Warranties Expiring 90 Days" at the start of `cuegroup(Warranty)`, both `DrillDownPageId = "EQM Equipment List"` |
| Page | 50109 | EQM Equipment Dashboard | AboutText and AdditionalSearchTerms only |
| Codeunit (test app) | 50176 | EQM Warranty Dashboard Tests | Reserved, not built (tests deferred) |

Page 50110 (Role Center) is unchanged; it shows the tiles through page 50106. Reused: codeunit 50110 "EQM Warranty Alert Mgt." `GetIntervalDays` (called only for the 90) and table 50100 `GetWarrantyExpiringSoonDays` (30).

## Behavior
With T = `Today()` (real date, not Work Date) and D = Warranty End Date. All tiles count equipment records, exclude Status Lost and Disposed, ignore the Warranty Start Date and never count a blank end date.

| Tile (caption) | Field | Counts | Drill-down |
|---|---|---|---|
| Active Warranties | 33 | D >= T | Equipment List |
| Warranties Expiring in 90 Days | 34 | T <= D <= T + 90 | Equipment List |
| Warranties Expiring in 30 Days | 30 (existing, FR-015) | T <= D <= T + 30 | Equipment List |
| Expired Warranties | 31 (existing, FR-015) | D filled in and D < T | Equipment List |

- **Order in group Warranty:** Active Warranties, Warranties Expiring in 90 Days, Warranties Expiring in 30 Days, Expired Warranties, Open Warranty Alerts (FR-016).
- **Cumulative windows:** Active includes the warranties that expire within 30 days, and the 90-day tile includes the 30-day tile. Do not add the tiles. Active + Expired = equipment not Lost or Disposed with an end date. Equipment counted as Active can show Warranty Status "Expiring Soon" on the card and list (that status is the 30-day window).
- **Filters:** page 50106 `OnOpenPage` calls `SetWarrantyCueFilters` with `Today()`; 0D means today. Filter 42 is `'>=%1'` with the reference date; filter 43 is `SetRange` from the reference date to the reference date plus the 90. The procedure only sets filters; no write, no `Commit`.
- **The 90 days:** read from `GetIntervalDays(Enum::"EQM Warranty Alert Interval"::"90 Days")`, the FR-016 alert window, so the tile and the alerts use one definition. Changing or removing that enum value changes or breaks the tile.
- **Captions:** field 30 is captioned "Warranties Expiring in 30 Days" (was "Warranty Expiring Soon"), field 31 "Expired Warranties" (was "Warranty Expired"). Field names, IDs, formulas and ToolTips are unchanged.
- **Tiles without calculate call:** the new tiles are not added to the `CalcFields` call of page 50106. TODO(verify) V4: that they calculate without it (fallback in the plan).
- **Drill-down:** TODO(verify) V5: that the end-date and Status filters are applied to the opened Equipment List.
- **Not in scope:** warranty chart, 60-day tile, "no warranty" tile, warranty value, tile styles, notifications, a separate Role Center.

## Setup
No setup. The tiles fill from the Warranty End Date of existing equipment (FR-014).

## Extending (events)
None published, none subscribed (plan decision Q11). A subscriber could not change a FlowFilter-based count consistently with the warranty status. Partners can add tiles by extending page 50106. `SetWarrantyCueFilters` is `internal`.

## Permissions
No permission set changes. EQM - Reader already has R on tabledata 50100 and execute on table 50104, pages 50106, 50109, 50110, "EQM Equipment List" and codeunits 50107 and 50110; Manager and Administrator include Reader rights.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See the four warranty tiles, drill down | yes | yes | yes |
| Change the numbers (end date, status) | no | yes | yes |

From the plan and code reading, not a sandbox run (WD-SB7).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand. TODO(verify) WD-SB1: that the four new captions and ToolTips, the two changed captions, AboutText and search terms are in the file as intended.

## Upgrade and compatibility
Nothing stored, so no upgrade code and no schema change; table 50104 is temporary. Two controls are added inside the existing Warranty group of page 50106, before existing controls; none is renamed, moved or removed. The caption change on fields 30 and 31 is text only; the counting of FR-015 and the alerts of FR-016 are unchanged. Translations of the old captions in other languages, if added later, would be stale.

## Known limitations
- A cue page left open past midnight keeps the old filters until reopened (Refresh does not reset them).
- `Today()` uses the session time zone.
- A warranty that has not started yet counts as active (start date ignored).
- Four unindexed counts on table 50100 per open or Refresh.
- Long captions may wrap on a tile.

## Test status
- Build: clean (CodeCop and UICop).
- No test objects; test codeunit 50176 is reserved. Scenarios WD1 to WD23 in docs/plans/FR-022-warranty-dashboard.md are a reference only.
- Open sandbox checks: V1, V4, V5 and WD-SB1 to WD-SB8 (see docs/TODO.md).

## Discrepancies plan vs code
- None found in behavior. The doc comment of `SetWarrantyCueFilters` also says the 90 days come from the 90 Days alert interval (the plan's risk R6 asked for this note).
- Plan listed cross-references for FR-009, FR-015 and FR-016 docs; FR-009 and FR-016 did not mention the old captions, so only a cross-reference was added there.
