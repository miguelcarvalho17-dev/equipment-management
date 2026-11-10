# FR-020 Overdue Maintenance Monitoring

## Purpose
Users see which equipment has missed its planned maintenance. Equipment is overdue when its Next Maintenance Date (FR-019) is before today. The date is shown in red on the Equipment List, the Equipment Card and the Maintenance FactBox, and a dashboard / Role Center tile "Overdue Maintenance Equipment" counts the overdue equipment and drills down to it. Nothing is stored and no job runs; the result is calculated from the date every time it is shown.

Status: describes the code as implemented (uncommitted changes on branch `feature/FR-020-overdue-maintenance-monitoring`, GitHub issue #39). The build compiled with CodeCop and UICop clean. **No automated tests (deferred, plan decision Q10; test codeunit 50174 reserved, nothing written). Sandbox checks OM-SB1 to OM-SB9 are not run.** App version stays 29.0.0.0. No new objects, no new stored field, no upgrade codeunit, no new event, no standard events subscribed (no events report), no permission set change.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50100 | EQM Equipment | Internal procedures `IsPlannedMaintenanceOverdue`, `GetNextMaintenanceDateStyle`; ToolTip of field 22 |
| Table | 50104 | EQM Equipment Cue | Field 50 "Overdue Maintenance Equipment" (FlowField), field 51 "Overdue Maintenance Filter" (FlowFilter) |
| Codeunit | 50107 | EQM Dashboard Mgt. | Internal procedures `SetPlannedMaintenanceCueFilters`, `GetOverdueMaintenanceCueStyle`; two locked style labels |
| Page | 50106 | EQM Equipment Cues | Cue group Planned Maintenance (after Warranty, before Maintenance Costs) with the tile; `OnOpenPage` sets the filter; new `OnAfterGetRecord` |
| Page | 50100 | EQM Equipment List | `StyleExpr` on Next Maintenance Date; AboutText |
| Page | 50101 | EQM Equipment Card | `StyleExpr` on Next Maintenance Date; style refreshed on validate of Last Maintenance Date and Maintenance Frequency (Months) and in `UpdateControls` |
| Page | 50115 | EQM Maintenance FactBox | `StyleExpr` on Next Maintenance Date (set before `UpdateFactBox`, which can exit early) |
| Page | 50109 | EQM Equipment Dashboard | AboutText and AdditionalSearchTerms only |

Page 50110 (Role Center) is unchanged; it shows the tile through page 50106.

## Behavior
With N = Next Maintenance Date and T = `Today()`:
- **Overdue:** N is filled in and N < T, and the status is not Lost or Disposed (`IsFinalStatus`). Due today (N = T) is not overdue; the first overdue day is N + 1.
- **Reference date:** the real date `Today()`, not the Work Date.
- **Blank N:** never overdue.
- **Lost and Disposed:** never overdue, not highlighted, not counted. Their date is still shown, unstyled.
- **Available, Assigned, In Maintenance** (and statuses added by extensions): can be overdue. Overdue clears when a Preventive record is posted (FR-019) or the plan fields change so N is not before today.
- **Highlight:** `GetNextMaintenanceDateStyle` returns `Unfavorable` (red) when overdue, otherwise `Standard`. Used on the list (`OnAfterGetRecord`), the card (`UpdateControls`, plus validate of the two plan fields, so a change shows at once) and the FactBox.
- **Tile:** FlowField 50 counts `EQM Equipment` where Next Maintenance Date = filter 51 and Status is not Lost and not Disposed. `SetPlannedMaintenanceCueFilters` sets filter 51 to `<>0D&<reference date>` (0D = today); page 50106 calls it in `OnOpenPage`. `GetOverdueMaintenanceCueStyle` returns `Unfavorable` for a count above 0, `Favorable` for 0; page 50106 sets the style in `OnAfterGetRecord` after an explicit `CalcFields`. The tile drills down to the Equipment List (`DrillDownPageId`).
- Tile and highlight use the same rule; the procedures read only and do not modify the record.
- Not in scope: notification, job queue check, "Due Soon", "Days Overdue" column, stored overdue flag, list view. The FR-017 "overdue" (open maintenance record more than 14 days after its date, codeunit 50108) is a different concept and is unchanged.

## Setup
No setup. Overdue equipment shows once equipment has a Next Maintenance Date in the past (set the plan on the Equipment Card, FR-019).

## Extending (events)
None published, none subscribed. The rule is intentionally closed (a subscriber would make the tile, which counts through a FlowFilter, disagree with the highlight). The date itself can be changed through the FR-019 event `OnBeforeCalcNextMaintenanceDate`; highlight and tile follow the stored date. The two table procedures and the two codeunit procedures are `internal`.

## Permissions
No permission set changes. EQM - Reader already has R on tabledata 50100 and execute on pages 50100, 50101, 50106, 50109, 50110, 50115, table 50104 and codeunit 50107; Manager and Administrator include Reader rights.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See the highlight and the tile, drill down | yes | yes | yes |
| Clear "overdue" (change plan fields, post Preventive maintenance) | no | yes | yes |

From code reading and the plan, not a sandbox run (OM-SB9).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand. TODO(verify) in OM-SB1: that the new texts are present and the locked labels `FavorableStyleTok` / `UnfavorableStyleTok` are not.

## Upgrade and compatibility
Nothing stored, so no upgrade code and no schema change; table 50104 is temporary. Existing equipment with a past Next Maintenance Date is highlighted at once. One cue group is inserted between two existing groups; no control is renamed, moved or removed.

## Known limitations
- The highlight is a style, not a field: users cannot filter on "overdue" in the list. A filter `..yesterday` on Next Maintenance Date can also return blank dates and Lost/Disposed equipment; use the tile drill-down.
- `Today()` uses the session time zone.
- A cue page left open past midnight keeps the old filter until reopened (Refresh does not reset it).
- No index on Next Maintenance Date; the tile scans the equipment table.
- Next Maintenance Date is stored (FR-019): the overdue result follows the stored date.
- Two "overdue" concepts exist (this one and FR-017 open records); the FR-017 notification name "Equipment maintenance is overdue" is unchanged.

## Test status
No test objects; test codeunit 50174 "EQM Overdue Maintenance Tests" is reserved. Scenarios OM1 to OM31 in docs/plans/FR-020-overdue-maintenance-monitoring.md are a reference only. **Sandbox checks OM-SB1 to OM-SB9 are not run.**

TODO(verify) in a sandbox: platform checks V1 to V6 (tile style, `CalcFields` in `OnAfterGetRecord`, CalcFormula and filter syntax, drill-down filters, style on a non-editable card field); highlight on list, card and FactBox (OM-SB2); tile placement and colors (OM-SB3); drill-down filters (OM-SB4); clearing by posting and by disposing (OM-SB5, OM-SB6); Work Date independence (OM-SB7); card refresh on frequency change (OM-SB8); Reader view, teaching tips and Tell Me (OM-SB9).

## Discrepancies plan vs code
- None in behavior. The plan also lists doc updates to FR-007, FR-008, FR-009, FR-010, FR-017 docs, README.md and docs/TODO.md; they were not part of this step (see the report). FR-019 feature and help docs were updated with a pointer.
