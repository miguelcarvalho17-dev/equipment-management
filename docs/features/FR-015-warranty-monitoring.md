# FR-015 Warranty Monitoring

## Purpose
Users see at a glance whether the warranty of each piece of equipment is Active, Expiring Soon or Expired, so they can act before coverage ends and know whether a repair is still covered. The status is calculated from the Warranty End Date (FR-014) and today's date every time it is shown. Nobody sets it and no job runs. It appears on the Equipment Card, on the Equipment List and as two dashboard tiles.

Status: describes the code as implemented (uncommitted changes on branch `feature/FR-015-warranty-monitoring`). Review verdict: APPROVE WITH COMMENTS (no blockers). The app compiles with no AL errors or warnings from the compiler, CodeCop and UICop; only the existing app.json / AppSourceCop-configuration diagnostics AS0051, AS0052, AS0054, AS0084 and AS0092 remain. **No automated tests (deferred, plan decision Q10; test codeunit 50169 reserved, nothing written). Sandbox checks WM-SB1 to WM-SB10 have NOT been run.** App version stays 29.0.0.0. No stored field, no permission set change, no upgrade codeunit, no standard events subscribed, no published events, no events report.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Enum | 50104 | EQM Warranty Status | New. Values 0 " " (blank), 1 Active, 2 "Expiring Soon", 3 Expired. `Extensible = false`. File `EQMWarrantyStatus.Enum.al`. |
| Table | 50100 | EQM Equipment | New internal procedures `GetWarrantyExpiringSoonDays`, `CalcWarrantyStatus`, `GetWarrantyStatus`, `GetWarrantyStatusStyle`. ToolTip of field 18 "Warranty End Date" now explains the status. No new field. |
| Table | 50104 | EQM Equipment Cue (temporary) | FlowFields 30 "Warranty Expiring Soon" and 31 "Warranty Expired"; FlowFilters 40 "Warranty Expiring Filter" and 41 "Warranty Expired Filter". |
| Codeunit | 50107 | EQM Dashboard Mgt. | New internal procedure `SetWarrantyCueFilters(var EquipmentCue; ReferenceDate)`. |
| Page | 50106 | EQM Equipment Cues | New cue group `Warranty` (between Equipment and Maintenance Costs) with two tiles that drill down to the Equipment List. `OnOpenPage` calls `SetWarrantyCueFilters(Rec, Today())`. |
| Page | 50101 | EQM Equipment Card | Field `WarrantyStatus` after Warranty End Date (not editable, Promoted, styled). `OnValidate` of Warranty End Date and `UpdateControls` call the local `UpdateWarrantyStatus`. |
| Page | 50100 | EQM Equipment List | Visible column `WarrantyStatus` (styled), calculated in `OnAfterGetRecord`. AboutText updated. |
| Page | 50109 | EQM Equipment Dashboard | AboutText and search terms ("warranty expiration", "expiring warranties") only. |

## Behavior
Reference date D = Warranty End Date, T = today (`Today()`, not the work date).

| Condition | Status |
|---|---|
| D blank | blank (not monitored) |
| D < T | Expired (first expired day is the day after the end date) |
| T <= D <= T + 30 | Expiring Soon (an end date of today and of today + 30 both count) |
| D > T + 30 | Active |

- **Input:** only "Warranty End Date". The Warranty Start Date is ignored; a warranty that has not started yet is shown by its end date. Only a start date filled in gives a blank status.
- **The 30 days:** fixed in `GetWarrantyExpiringSoonDays` (returns 30), used by both the status and the tiles. There is no setup field. **The text "30 days" is also written into the ToolTips of field 18, the card and list Warranty Status fields, the "Warranty Expiring Soon" cue ToolTip, and the AboutText of the Equipment Dashboard. If the value is made configurable, update these texts as well.**
- **Calculation:** `CalcWarrantyStatus(ReferenceDate)` (0D = today); `GetWarrantyStatus()` calls it with `Today()`. Both are read-only: no `Modify`, no event.
- **Style:** `GetWarrantyStatusStyle` returns Favorable (Active), Ambiguous (Expiring Soon), Unfavorable (Expired), Standard (blank), using the existing style labels.
- **Card:** recalculated on `OnAfterGetRecord`, `OnNewRecord` (via `UpdateControls`) and when Warranty End Date is changed on the page. Changing the Warranty Start Date does not change it.
- **List:** visible by default, calculated per row. Because the columns around it are hidden, it appears after Location Code.
- **Tiles:** "Warranty Expiring Soon" counts equipment with an end date from T to T + 30; "Warranty Expired" counts equipment with a non-blank end date before T. Both exclude Status Lost and Disposed (`Status = filter(<> Lost & <> Disposed)`). The card and list still show the status for Lost and Disposed equipment. Filters are set once in `OnOpenPage`.
- **Informational only:** the status blocks nothing (assign, return, maintenance and posting are unchanged).

## Setup
No setup. No new fields in Equipment Setup.

## Extending (events)
None published, by design (plan Q8): a subscriber that changed the status would make the card and the tiles disagree, because the tiles count through FlowFilters. No standard events are subscribed. The new procedures are `internal`, so there is no public API to keep stable; the enum is public but not extensible.

## Permissions
No change to permission sets. EQM - Reader already has R on table 50100, X on table 50104, pages 50100, 50101, 50106, 50109, 50110 and codeunit 50107. Enums need no permission.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See Warranty Status on card and list | yes | yes | yes |
| See and drill down on the warranty tiles | yes | yes | yes |
| Change the status directly | no (calculated) | no (calculated) | no (calculated) |
| Change the Warranty End Date (changes the status) | no | yes | yes |

From code reading, not a sandbox run (WM-SB9).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand.

## Upgrade and compatibility
Nothing is stored, so there is no schema change and no upgrade codeunit. Existing equipment shows its status at once (blank without an end date). Nothing is released, so no Obsolete handling. Public surface that becomes permanent at release: enum 50104 and its ordinals.

## Known limitations
- **No filter, sort or export on Warranty Status.** It is a page variable, not a field: it cannot be filtered, sorted or searched on the list and is not in Excel exports or analysis mode. Use the tile drill-down or filter on Warranty End Date.
- The status uses the session's date (`Today()`); around midnight, users in different time zones can see a different status for one day.
- A dashboard left open past midnight keeps the previous day's tile filters until it is reopened; Refresh does not reset them.
- The tile counts scan the equipment table without an index on Warranty End Date.
- No notification, email, job, tile styles or list views for warranties.

## Test status
No test objects; test codeunit 50169 "EQM Warranty Status Tests" is reserved. Scenarios WS1 to WS29 in docs/plans/FR-015-warranty-monitoring.md are a reference only. Sandbox checks WM-SB1 to WM-SB10 are **not run**.

TODO(verify) in a sandbox:
- Tile drill-down opens the Equipment List with the date and Status filters applied (WM-SB4); the `Status = filter(<> Lost & <> Disposed)` formula is counted correctly (the compiler accepts it; the fallback was not needed to compile, WM-SB8).
- Boundary days with real data and the work-date independence (WM-SB5, WM-SB6).
- Colors, column position, collapsed Warranty group, teaching tips, Tell Me search (WM-SB2, SB3, SB10).
- Non-SUPER Reader and Manager permissions (WM-SB9).

## Discrepancies plan vs code
- None found in the changed objects. Enum, procedures, cue fields, tiles, page fields, ToolTips and AboutTexts match the plan. The plan's updates to the FR-014, FR-007, FR-008 and FR-009 feature and help documents and to docs/TODO.md were not made in this step; TODO.
