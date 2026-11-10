# FR-020 Overdue Maintenance Monitoring

> Status: **Approved by the user in chat (defaults for Q1-Q11 accepted).** Open questions Q1-Q11 (see "Risks and open questions") each have a proposed
> default, and the plan is written with these defaults. **Q1 (boundary day and reference date), Q2 (Lost and Disposed
> equipment are never overdue), Q3 (where the highlight is shown) and Q4 (name clash with the FR-017 "overdue
> maintenance" rule for open records) change the design if they are answered differently.**
> Source: GitHub issue #39. Branch: `feature/FR-020-overdue-maintenance-monitoring`.
> No events report. FR-020 only reads this app's own data (table 50100 "EQM Equipment", field 22 "Next Maintenance
> Date" from FR-019 and field 9 Status) and shows the result on this app's own pages and dashboard. It subscribes to no
> standard events and changes no standard behavior, so al-event-finder is not needed.
> Scope: main app only. **No new objects. No new stored field.** Two new procedures and one ToolTip change on table
> 50100, one FlowField and one FlowFilter on the temporary cue table 50104, two new procedures in codeunit 50107, and
> changes to pages 50100, 50101, 50106, 50109 and 50115. **No permission set change. No new event. No version bump**
> (app.json stays 29.0.0.0). **No upgrade logic.** Tests deferred (Q10 default): test codeunit 50174 is reserved, and
> the tester step is skipped.
> Workflow for FR-020: planner -> (human approves plan) -> developer -> reviewer -> build -> **tester step SKIPPED
> (Q10)** -> documenter -> appsource-validator.

## Goal
Users see which equipment has missed its planned maintenance: equipment is overdue when its Next Maintenance Date
(FR-019) is before today. Overdue equipment is highlighted (red) on the Equipment List, the Equipment Card and the
Maintenance FactBox, and a new dashboard and Role Center tile "Overdue Maintenance Equipment" counts it (red when at
least one, green when none) and drills down to the overdue equipment. Nothing is stored and no job has to run; the
result is calculated from the date every time it is shown.

### Requirement restated
- OM-R1 Identify equipment whose planned maintenance is overdue.
- OM-R2 Rule: overdue when Next Maintenance Date < today.
- OM-R3 KPI "Overdue Maintenance Equipment" (a count) on the dashboard.
- OM-R4 Overdue equipment is highlighted in lists and dashboards.

### Interpretation (defaults, see Q1-Q11)
With N = "Next Maintenance Date" and T = `Today()`:
- **Overdue (Q1):** N <> 0D and N < T. N = T (due today) is **not** overdue; the first overdue day is T = N + 1. This is
  exactly the issue's "less than Today". The reference date is the real date `Today()`, not the Work Date (same choice
  as FR-015 warranty status, FR-017 notifications and the FR-019 future-date check).
- **Blank Next Maintenance Date:** never overdue (no plan: no last date, or frequency 0).
- **Lost and Disposed (Q2):** never overdue. They are not counted on the tile and not highlighted (they no longer need
  maintenance). Their Next Maintenance Date is still shown, without style.
- **In Maintenance, Assigned, Available:** can be overdue. Equipment In Maintenance with an overdue date stays overdue
  until a Preventive record is posted and moves the Last/Next dates forward (FR-019 posting rule). Statuses added by
  extensions can be overdue (the rule only excludes the two final statuses).
- **Highlight (Q3):** the "Next Maintenance Date" control gets the `Unfavorable` style (red) when overdue, `Standard`
  otherwise, on: Equipment List 50100 (column), Equipment Card 50101 (Planned Maintenance group), Maintenance FactBox
  50115. The dashboard tile is `Unfavorable` when the count is greater than 0 and `Favorable` when it is 0.
- **Where the KPI shows:** new cue group "Planned Maintenance" with one tile on cue part 50106, which page 50109
  "EQM Equipment Dashboard" and Role Center 50110 already embed (no layout change on 50109 / 50110).
- **Not in scope (Q5, Q6):** no notification, no job queue check, no list view, no "Due Soon" state, no "Days Overdue"
  column, no stored overdue flag, no change to the FR-017 open-record overdue rule (14 days) or its notifications.

### What already exists and is reused
| Already present | Built in | Use in FR-020 |
|---|---|---|
| Table 50100 field 22 "Next Maintenance Date" (stored Date, `Editable = false`, calculated; 0D when no plan); field 9 Status; `IsFinalStatus`; locked style labels `UnfavorableStyleTok`, `StandardStyleTok`, `FavorableStyleTok`. | FR-019, FR-003, FR-012 | The only inputs of the rule; style labels reused, no new label on the table. |
| FR-015 pattern: table procedure calculates on a reference date (`CalcWarrantyStatus(ReferenceDate)`, 0D = today), second procedure returns the style; tiles use a count FlowField on cue table 50104 with a date FlowFilter set by codeunit 50107 in the cue page's `OnOpenPage`, CalcFormula excludes Lost and Disposed. | FR-015 | Same pattern: `IsPlannedMaintenanceOverdue` + `GetNextMaintenanceDateStyle`; FlowField 50 + FlowFilter 51; `SetPlannedMaintenanceCueFilters`. |
| Cue part 50106 (`RefreshOnActivate = true`, `RefreshCues` = `CurrPage.Update(false)`, `OnOpenPage` creates the record and sets filters), dashboard 50109 Refresh action, Role Center 50110. | FR-009, FR-015, FR-016 | New cue group and tile; Refresh and RC work without change. |
| Equipment List 50100 column "Next Maintenance Date" (visible), card group `PlannedMaintenance`, FactBox 50115 control "Next Maintenance Date". | FR-019 | Add `StyleExpr` to the existing controls. |
| Permission sets 50100-50102: Reader has R on tabledata 50100, X on table 50104, pages 50100, 50101, 50106, 50109, 50110, 50115 and codeunit 50107. | NFR-002 | Already cover everything FR-020 reads and runs. |
| FR-017 "overdue maintenance" = an **open maintenance record** more than 14 days after its date (codeunit 50108 `IsMaintenanceOverdue`, notification "Equipment maintenance is overdue"). | FR-017 | **Not changed.** Different concept; naming kept apart (Q4). |

## Approach and rejected alternatives
- Chosen: **calculate on read, FR-015 pattern.** Two internal procedures on table 50100 decide "overdue" and return the
  style; pages call them in their record triggers and put the style on the existing Next Maintenance Date controls. The
  KPI is a count FlowField on the temporary cue table with a date FlowFilter "not blank and before today" and a Status
  filter excluding Lost and Disposed, so the tile and the per-record highlight always agree. No stored data, no writes,
  no job.
- Rejected: a stored Boolean "Maintenance Overdue" on table 50100 updated by a daily job (FR-018 job codeunit). Stale
  between runs, needs write permission for the job user, every update runs `OnModify` / consistency checks and raises
  `OnAfterCheckEquipmentConsistency`. Time passing is not an event.
- Rejected: a FlowField for "overdue" on table 50100. A CalcFormula cannot compare a field of the same record with
  today.
- Rejected: a new enum "Planned Maintenance Status" (Not Planned / Planned / Overdue). The issue asks only for overdue;
  a public enum becomes permanent API (follow-up with "Due Soon", Q5).
- Rejected: a separate visible column "Maintenance Overdue" (Boolean page variable) on the list. A page variable cannot be
  filtered or sorted, and the red date already marks the row. The tile drill-down gives the filtered list.
- Rejected: list view "Overdue Maintenance". View filters cannot express "before today" reliably; the tile drill-down
  covers it (same decision as FR-015).
- Rejected: a new codeunit "EQM Planned Maintenance Mgt.". Table 50100 already owns the comparable helpers
  (`CalcWarrantyStatus`, `GetWarrantyStatusStyle`, `CalcNextMaintenanceDate`).
- Rejected: an integration event to change the overdue rule (e.g. a grace period). The tile counts through a FlowFilter
  and would not follow a subscriber, so tile and highlight would disagree (Q7).
- Rejected: extending the FR-017 notifications / FR-018 job with planned-maintenance overdue. Not requested (Q6).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50107, pages 50100-50120, codeunits 50103-50115,
queries 50100-50103, enums 50100-50106, page extension 50100, permission sets 50100-50102, permission set extension
50103, profile "EQM EQUIPMENT MANAGER". Fields in use on table 50100: 1-23. Fields in use on table 50104: 1, 10-15,
20-21, 30-32, 40-41. Test app: no objects; test codeunits 50150-50173 are reserved by FR-001 to FR-019, none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50100 | EQM Equipment | Modify (own) | Procedures `IsPlannedMaintenanceOverdue`, `GetNextMaintenanceDateStyle`; ToolTip of field 22 |
| Table | 50104 | EQM Equipment Cue | Modify (own) | FlowField 50 "Overdue Maintenance Equipment", FlowFilter 51 "Overdue Maintenance Filter" |
| Codeunit | 50107 | EQM Dashboard Mgt. | Modify (own) | Procedures `SetPlannedMaintenanceCueFilters`, `GetOverdueMaintenanceCueStyle`; two locked style labels |
| Page | 50106 | EQM Equipment Cues | Modify (own) | New cue group "Planned Maintenance" with the styled tile; `OnOpenPage` sets the filter; new `OnAfterGetRecord` |
| Page | 50100 | EQM Equipment List | Modify (own) | `StyleExpr` on "Next Maintenance Date"; AboutText |
| Page | 50101 | EQM Equipment Card | Modify (own) | `StyleExpr` on "Next Maintenance Date"; recalculated on validate of the plan fields |
| Page | 50115 | EQM Maintenance FactBox | Modify (own) | `StyleExpr` on "Next Maintenance Date" |
| Page | 50109 | EQM Equipment Dashboard | Modify (own) | AboutText and AdditionalSearchTerms only |

Not changed: tables 50101-50103, 50105-50107; pages 50102-50105, 50107, 50108, 50110 (Role Center shows the tile
through page 50106), 50111-50114, 50116-50120; codeunits 50103-50106, 50108-50115 (FR-017 overdue rule, notifications
and FR-018 jobs unchanged); queries; enums; page extension 50100; permission sets 50100-50102; permission set extension
50103; the profile; `app/app.json`; `test/`. **No new files.**

Next free IDs after FR-020 (unchanged): tables 50108, pages 50121, codeunits 50116, queries 50104, enums 50107, page
extensions 50101, permission sets 50104; next free field on table 50100: 24; on table 50104: 52. Test app: **test
codeunit 50174 reserved for FR-020 "EQM Overdue Maintenance Tests"**, not built now (Q10).

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report, except where a fallback is written here.
- V1 A cuegroup field with `StyleExpr` set to a page variable holding 'Favorable' / 'Unfavorable' colors the tile.
- V2 In the cue page's `OnAfterGetRecord`, an explicit `Rec.CalcFields("Overdue Maintenance Equipment")` returns the
  value with the FlowFilter set in `OnOpenPage` applied (the FlowFilter is set on `Rec` before the first read). After
  `RefreshCues` (`CurrPage.Update(false)`) `OnAfterGetRecord` runs again and the style follows the new count.
- V3 The CalcFormula `count("EQM Equipment" where("Next Maintenance Date" = field("Overdue Maintenance Filter"), Status =
  filter(<> Lost & <> Disposed)))` compiles (the same Status filter syntax is already used by fields 30 and 31).
- V4 `SetFilter` on the Date FlowFilter with `'<>%1&<%2'`, 0D and the reference date counts only non-blank dates before
  the reference date (same expression already used for "Warranty Expired Filter").
- V5 Drilling down on the tile (`DrillDownPageId = "EQM Equipment List"`) opens the list with the date and Status
  filters applied (same behavior as the warranty tiles, WM-SB4).
- V6 `StyleExpr` on a control bound to a table field that is `Editable = false` (field 22) on a Card page shows the
  style.

### Table 50100 "EQM Equipment" (change)
No new field, key, trigger, label or event. No change to existing procedures.

**ToolTip of field 22 "Next Maintenance Date"** becomes:
'Specifies when the next planned maintenance of the equipment is due. It is calculated as the last maintenance date plus the maintenance frequency in months, and is blank when either is missing. When the date is before today, the maintenance is overdue and the date is highlighted, unless the equipment is lost or disposed.'

**New internal procedures**, placed directly after `UpdateLastMaintenanceFromPosting` and before `IsStoredRecord`, each
with a `/// <summary>`:
1. `internal procedure IsPlannedMaintenanceOverdue(ReferenceDate: Date): Boolean` - in this order:
   1. When ReferenceDate = 0D: ReferenceDate := `Today()`.
   2. When "Next Maintenance Date" = 0D: exit(false).
   3. When `IsFinalStatus(Status)`: exit(false).
   4. exit("Next Maintenance Date" < ReferenceDate).
   Doc: summary "Returns whether the planned maintenance of the equipment is overdue on a given date: the next
   maintenance date is filled in and before the reference date, and the equipment is not lost or disposed. Reads only;
   the record is not changed." Param ReferenceDate: "The date to check on. 0D means today." Returns: "True when the
   planned maintenance is overdue."
2. `internal procedure GetNextMaintenanceDateStyle(): Text` - when `IsPlannedMaintenanceOverdue(Today())`: exit
   `UnfavorableStyleTok`; else exit `StandardStyleTok`. Reuse the existing locked labels; add no new label.
   Doc: summary "Returns the page style name used to show the next maintenance date: Unfavorable when the planned
   maintenance is overdue today, otherwise Standard." Returns: "The style name."

### Table 50104 "EQM Equipment Cue" (change)
New fields after field 41 (inherit `DataClassification = CustomerContent` from the table; set nothing on the fields):

| ID | Name | Type / class | Caption | ToolTip | CalcFormula / other |
|---|---|---|---|---|---|
| 50 | "Overdue Maintenance Equipment" | Integer, FlowField, `Editable = false` | Overdue Maintenance Equipment | 'Specifies the number of equipment records whose next maintenance date is before today. Equipment without a next maintenance date and lost or disposed equipment are not counted. Choose the number to see the equipment.' | count("EQM Equipment" where("Next Maintenance Date" = field("Overdue Maintenance Filter"), Status = filter(<> Lost & <> Disposed))) |
| 51 | "Overdue Maintenance Filter" | Date, FlowFilter | Overdue Maintenance Filter | 'Specifies the next maintenance dates that count as overdue. It is set automatically.' | none |

Field name length: "Overdue Maintenance Equipment" is 29 characters, "Overdue Maintenance Filter" 26 (limit 30).

### Codeunit 50107 "EQM Dashboard Mgt." (change)
- New `var` section at the top of the codeunit (it has none today) with two locked labels:
  `FavorableStyleTok: Label 'Favorable', Locked = true;` and `UnfavorableStyleTok: Label 'Unfavorable', Locked = true;`.
- New internal procedures, placed after `SetWarrantyCueFilters`:
  1. `internal procedure SetPlannedMaintenanceCueFilters(var EquipmentCue: Record "EQM Equipment Cue"; ReferenceDate: Date)`:
     1. When ReferenceDate = 0D: ReferenceDate := `Today()`.
     2. `EquipmentCue.SetFilter("Overdue Maintenance Filter", '<>%1&<%2', 0D, ReferenceDate)`.
     Doc: summary "Sets the date filter of the overdue maintenance tile so that it counts the same equipment as
     IsPlannedMaintenanceOverdue on the equipment: a next maintenance date that is filled in and before the reference
     date. 0D means today." Params: EquipmentCue "The cue record to set the filter on."; ReferenceDate "The date the
     tile is calculated on."
  2. `internal procedure GetOverdueMaintenanceCueStyle(OverdueCount: Integer): Text` - when OverdueCount > 0: exit
     `UnfavorableStyleTok`; else exit `FavorableStyleTok`.
     Doc: summary "Returns the style of the overdue maintenance tile: Unfavorable when at least one equipment is
     overdue, Favorable when none is." Param OverdueCount "The value of the tile." Returns "The style name."

### Page 50106 "EQM Equipment Cues" (change)
- New `cuegroup(PlannedMaintenance)` with `Caption = 'Planned Maintenance'`, placed **after** `cuegroup(Warranty)` and
  before `cuegroup(MaintenanceCosts)`, with one control (no Caption, ToolTip or ApplicationArea on it):
  `field("Overdue Maintenance Equipment"; Rec."Overdue Maintenance Equipment")` with
  `DrillDownPageId = "EQM Equipment List"` and `StyleExpr = OverdueMaintenanceStyle`.
- New page `var` section (before the triggers): `OverdueMaintenanceStyle: Text;`.
- `OnOpenPage`: directly after the existing `DashboardMgt.SetWarrantyCueFilters(Rec, Today());` add
  `DashboardMgt.SetPlannedMaintenanceCueFilters(Rec, Today());` (before the notifications call).
- New `trigger OnAfterGetRecord()` (local `DashboardMgt: Codeunit "EQM Dashboard Mgt."`):
  `Rec.CalcFields("Overdue Maintenance Equipment");` then
  `OverdueMaintenanceStyle := DashboardMgt.GetOverdueMaintenanceCueStyle(Rec."Overdue Maintenance Equipment");` (V2).
- `RefreshCues` unchanged.

### Page 50100 "EQM Equipment List" (change)
- Existing control `field("Next Maintenance Date"; ...)`: add `StyleExpr = NextMaintenanceStyle;` (nothing else).
- New page variable `NextMaintenanceStyle: Text;` (after `WarrantyStatusStyle`).
- `OnAfterGetRecord`: after the two warranty lines add `NextMaintenanceStyle := Rec.GetNextMaintenanceDateStyle();`.
- AboutText: replace the sentence '**Next Maintenance Date** shows when planned maintenance is due; to find equipment that is due in a period, filter on it with a date range.' with '**Next Maintenance Date** shows when planned maintenance is due and is highlighted when the maintenance is overdue; to find equipment that is due in a period, filter on it with a date range, or choose the **Overdue Maintenance Equipment** tile on the dashboard.' Everything else in the AboutText stays.
- Views, actions, FactBoxes unchanged.

### Page 50101 "EQM Equipment Card" (change)
- Existing control `field("Next Maintenance Date"; ...)` in `group(PlannedMaintenance)`: add
  `StyleExpr = NextMaintenanceStyle;` (keep `Importance = Promoted`).
- Existing controls `"Last Maintenance Date"` and `"Maintenance Frequency (Months)"`: add `trigger OnValidate()` that
  calls `UpdateNextMaintenanceStyle();` (the table already recalculated the date; this refreshes the style at once).
- New page variable `NextMaintenanceStyle: Text;` (after `WarrantyStatusStyle`).
- New local procedure `UpdateNextMaintenanceStyle()`, placed after `UpdateWarrantyStatus`:
  `NextMaintenanceStyle := Rec.GetNextMaintenanceDateStyle();`.
- `UpdateControls()`: call `UpdateNextMaintenanceStyle();` as the last line, after `UpdateWarrantyStatus();` (runs on
  `OnAfterGetRecord`, `OnNewRecord` and the Status `OnValidate`, so setting Disposed removes the highlight at once).
- AboutText, actions, notifications: unchanged.

### Page 50115 "EQM Maintenance FactBox" (change)
- Existing control `field("Next Maintenance Date"; Rec."Next Maintenance Date")`: add
  `StyleExpr = NextMaintenanceStyle;`.
- New page variable `NextMaintenanceStyle: Text;`.
- `ClearFactBox()`: add `NextMaintenanceStyle := '';`.
- `OnAfterGetRecord`: between `ClearFactBox();` and `UpdateFactBox();` add
  `NextMaintenanceStyle := Rec.GetNextMaintenanceDateStyle();` (must be before `UpdateFactBox`, whose early `exit`
  for equipment without maintenance records would otherwise skip it).

### Page 50109 "EQM Equipment Dashboard" (change)
- AboutText becomes: 'The tiles count your equipment by status, show how many warranties are expiring within 30 days or have expired, how many warranty alerts are open, how many pieces of equipment are overdue for planned maintenance, and show the total and average cost of posted maintenance. **Total Equipment** includes lost and disposed equipment; the warranty and overdue maintenance tiles do not. **Overdue Maintenance Equipment** turns red when at least one piece of equipment has a next maintenance date before today. The charts show how your equipment is spread over categories and statuses, which categories cost the most in maintenance, and the ten pieces of equipment with the highest maintenance cost. Choose a tile or a chart segment to see the details. Choose **Refresh** to update the numbers.'
- AdditionalSearchTerms becomes: 'equipment kpi, equipment overview, equipment chart, maintenance cost, maintenance kpi, warranty expiration, expiring warranties, warranty alerts, overdue maintenance, maintenance due'
- Nothing else changes.

### app.json, translations
- **app.json: no change.** Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf` (two cue captions and ToolTips, the cue group
  caption, the changed ToolTip of field 22, two AboutTexts, search terms). The new locked style labels in codeunit
  50107 must not appear as translatable units. Commit it; never edit by hand.

## Data model and upgrade impact
- No stored schema change. "Overdue" is never stored. Table 50104 is `TableType = Temporary`; its new FlowField and
  FlowFilter create no columns.
- No new key. The tile count scans table 50100 filtered on "Next Maintenance Date" and Status (no index, accepted in
  FR-019 R4 for equipment volumes).
- DataClassification: cue fields inherit `CustomerContent` from the table. No personal data.
- Upgrade codeunit: **not needed.** Nothing is stored or released; version stays 29.0.0.0. Existing equipment is
  highlighted at once when its Next Maintenance Date is already in the past.

## Events
**Standard BC events: none.** No events report is required. Subscribed: none.

Published: **none** (Q7). The rule is a read-only calculation; a subscriber that changed it would make the highlight
and the tile disagree (the tile counts through a FlowFilter). Partners can change the date itself through the existing
FR-019 event `OnBeforeCalcNextMaintenanceDate`, and both highlight and tile follow the stored date. No existing event is
raised by the new code (it reads only; no `Modify`).

## Permissions
**No permission set changes.**
- EQM - Reader already has R on tabledata "EQM Equipment", X on table "EQM Equipment Cue", pages 50100, 50101, 50106,
  50109, 50110, 50115 and codeunit 50107. Manager and Administrator include Reader rights (NFR-002). The temporary cue
  table needs no tabledata entry.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See the highlight on list, card and FactBox | yes | yes | yes |
| See and drill down on the Overdue Maintenance Equipment tile | yes | yes | yes |
| Clear "overdue" by changing Last Maintenance Date / frequency or posting Preventive maintenance | no | yes | yes |

## Compatibility
- AppSource mode, development phase: nothing is released, no baseline, no Obsolete handling needed.
- No new public surface: table 50104 and codeunit 50107 are internal; the two new table 50100 procedures are
  `internal`, so the rule can change later without a breaking change (Q1, Q2, Q7).
- No behavior change in existing rules: no new check on insert, modify, assign, maintenance or posting; the FR-017
  open-record overdue rule, its notifications and the FR-018 jobs are unchanged. No control, group, tile or action is
  renamed, moved or removed; one cue group is inserted between two existing groups.
- Terminology (Q4): after FR-020 the app has two "overdue" concepts: equipment whose planned maintenance is overdue
  (FR-020, Next Maintenance Date) and maintenance records open longer than 14 days (FR-017). User texts keep them apart:
  FR-020 texts say "equipment ... next maintenance date", FR-017 texts say "maintenance record ... open". The FR-017
  My Notifications name "Equipment maintenance is overdue" is ambiguous but unchanged (Q4).
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-020-overdue-maintenance-monitoring.md` and `docs/help/FR-020-overdue-maintenance-monitoring.md`:
    the rule with boundary days (due today is not overdue), today not the work date, blank date and Lost/Disposed never
    overdue, where the highlight shows, the tile and its colors and drill-down, how to clear "overdue" (post a
    Preventive record or change the plan), the difference from the FR-017 open-record overdue notification, roles.
  - `docs/help/FR-019-planned-maintenance.md` / `docs/features/FR-019-planned-maintenance.md`: point to the overdue
    highlight and tile.
  - `docs/help/FR-007-equipment-list-management.md`, `docs/help/FR-008-equipment-card.md`,
    `docs/help/FR-009-dashboard-kpis.md`, `docs/help/FR-010-maintenance-registration.md` (FactBox) and the matching
    `docs/features/` files: highlight and new tile.
  - `docs/help/FR-017-equipment-notifications.md`: one sentence that its "overdue" means open records, not the planned
    maintenance date.
  - `README.md`: add or update the overdue maintenance row (built, not verified).
  - `CHANGELOG.md`: new top section `## FR-020 Overdue Maintenance Monitoring (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-020 sandbox checks" with OM-SB1 to OM-SB9.

## Test scenarios
**No automated tests in this iteration** (Q10 default, as in FR-003 to FR-019). Test codeunit 50174 "EQM Overdue
Maintenance Tests" is reserved and the tester step is skipped. The list is the reference for the developer, the
reviewer and the tests written later (needs the test-app fix in `docs/TODO.md` and `internalsVisibleTo`).

Test data, unless stated: active category LAPTOP; equipment saved with `Insert(true)`, Status Available. T = `Today()`.
R = a fixed reference date (e.g. 15 June 2026). To get a given Next Maintenance Date D, set Last Maintenance Date =
D - 1 month (not in the future) and frequency 1, or set "Next Maintenance Date" directly in the test record and save
with `Modify(false)` when only the read rule is tested.

Rule (OM-R1, OM-R2), `IsPlannedMaintenanceOverdue(R)`
- OM1 Given Next = R - 1, then true (first overdue day).
- OM2 Given Next = R, then false (due today is not overdue, Q1).
- OM3 Given Next = R + 1, then false.
- OM4 Given Next = R - 400, then true.
- OM5 Given Next = 0D (no plan), then false.
- OM6 Given Next = R - 10 and Status Lost, then false; the same with Disposed (Q2).
- OM7 Given Next = R - 10 and Status In Maintenance, then true; the same with Assigned.
- OM8 Given Next = T - 1, when `IsPlannedMaintenanceOverdue(0D)` runs, then it equals `IsPlannedMaintenanceOverdue(Today())` = true.
- OM9 (negative, read only) Given equipment E with Next = R - 5, when the procedure runs, then E is not modified
  (SystemModifiedAt unchanged) and no table 50100 event is raised.

Style
- OM10 `GetNextMaintenanceDateStyle` returns 'Unfavorable' for Next = T - 1 (Available), 'Standard' for Next = T,
  T + 30, 0D, and for Next = T - 1 with Status Disposed.
- OM11 `GetOverdueMaintenanceCueStyle` returns 'Favorable' for 0 and 'Unfavorable' for 1 and 25.

Tile (cue table, `SetPlannedMaintenanceCueFilters(Cue, R)` then `CalcFields`) (OM-R3)
- OM12 Given E1 Next = R - 1, E2 Next = R, E3 Next = R + 30, E4 Next = 0D, E5 Next = R - 100, then "Overdue Maintenance
  Equipment" = 2 (E1, E5).
- OM13 Given E6 Lost with Next = R - 5 and E7 Disposed with Next = R - 5, then neither is counted.
- OM14 Given E8 Assigned with Next = R - 3 and E9 In Maintenance with Next = R - 3, then both are counted.
- OM15 Given no equipment with a Next Maintenance Date, then the tile is 0 and no error is raised.
- OM16 (consistency) For every equipment of OM12-OM14: it is counted exactly when `IsPlannedMaintenanceOverdue(R)` is
  true.
- OM17 Given the cue filters set with `SetPlannedMaintenanceCueFilters(Cue, 0D)`, then the count equals the one with
  `Today()`.

Changes clear or create "overdue" (regression with FR-019)
- OM18 Given E with Last = T - 7 months and frequency 6 (Next = T - 1 month, overdue), when a Preventive record dated T
  is registered and posted, then Next = T + 6 months and E is no longer overdue; the tile goes down by 1.
- OM19 Given E overdue as in OM18, when a Corrective record is posted, then E stays overdue (FR-019 rule).
- OM20 Given E overdue, when the frequency is set to 0, then Next = 0D and E is not overdue.
- OM21 Given E with Next = T + 5 (not overdue), when the frequency is lowered so that Next becomes T - 1, then E is
  overdue.
- OM22 Given E overdue and Available, when it is set to Disposed (confirm Yes), then it is no longer overdue and leaves
  the tile.
- OM23 (negative) Given E overdue, when it is assigned and returned, then both succeed (overdue blocks nothing) and E
  stays overdue.

Pages (TestPage) (OM-R4)
- OM24 Equipment List with E1 (Next = T - 1) and E3 (Next = T + 30): the Next Maintenance Date column of E1 has style
  Unfavorable, E3 Standard (check via the style or the procedure if the TestPage cannot read styles).
- OM25 Equipment Card on E3: Next shown Standard; when the user changes Maintenance Frequency (Months) so that Next
  becomes T - 1, the style becomes Unfavorable without reopening the page; when the user sets Status Disposed, the style
  returns to Standard.
- OM26 New Equipment Card (create mode): Next blank, style Standard, no error.
- OM27 Maintenance FactBox on equipment E1 without maintenance records: Next shown with style Unfavorable (style set
  before the early exit).
- OM28 Equipment Cues: the Planned Maintenance group is between Warranty and Maintenance Costs and shows the tile with
  the value of OM12; drill-down opens the Equipment List with only E1 and E5 (non-blank Next before T, not Lost or
  Disposed).
- OM29 Equipment Dashboard Refresh after posting a Preventive record for an overdue equipment: the tile value goes down
  and, when it reaches 0, the style becomes Favorable.

Permissions (`TestPermissions = Restrictive`, with D365 BASIC)
- OM30 Reader: list, card, FactBox, dashboard and Role Center show the highlight and the tile with no permission error;
  drill-down works.
- OM31 Manager: changing the plan fields on the card updates the highlight with no permission error.

### Manual sandbox checks (for the user)
- OM-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` has the new texts and not the
  locked style labels (V3).
- OM-SB2 Equipment with Next Maintenance Date yesterday: red on the list, card and Maintenance FactBox; today and
  tomorrow: not red.
- OM-SB3 Dashboard and Role Center: tile "Overdue Maintenance Equipment" in a "Planned Maintenance" group between
  Warranty and Maintenance Costs; red when > 0, green when 0 (V1, V2).
- OM-SB4 Drill-down from the tile opens the filtered Equipment List; record which filters the filter pane shows (V5).
- OM-SB5 Post a Preventive record for an overdue equipment: highlight disappears; Refresh lowers the tile.
- OM-SB6 Dispose an overdue equipment: no highlight, tile goes down by one.
- OM-SB7 Change the work date to a year earlier: highlight and tile do not change (Q1).
- OM-SB8 Card: changing the frequency so the date moves into the past turns it red at once (V6).
- OM-SB9 Non-SUPER Reader sees highlight and tile; teaching tips of the list and dashboard show the new texts; Tell Me
  finds the dashboard with "overdue maintenance".

## Risks and open questions
Open questions (each has the default used in this plan; answer to change it):
- **Q1 Boundary and reference date.** Default: overdue when Next < `Today()`; due today is not overdue; real date, not
  Work Date. Alternatives: overdue on the due date itself (Next <= today), or `WorkDate()`. **Changes the design**
  (procedure, filter expression, OM1-OM2, OM-SB7).
- **Q2 Lost and Disposed.** Default: never overdue, not counted, not highlighted. Alternative: highlighted on list and
  card (fact about the date) but excluded from the tile, as FR-015 does for warranty (then highlight and tile differ).
  **Changes the design** (procedure step 3, OM6, OM13, OM22).
- **Q3 Where the highlight shows.** Default: red Next Maintenance Date on Equipment List, Equipment Card and Maintenance
  FactBox; styled tile on dashboard and Role Center. Alternatives: also a visible "Maintenance Overdue" yes/no column, or
  style the whole row (No. / Description) on the list. **Changes the design.**
- **Q4 Name clash with FR-017 "overdue maintenance".** Default: keep both concepts, keep FR-017 unchanged, keep texts
  distinct (FR-020: "equipment / next maintenance date"; FR-017: "maintenance record / open"). Alternatives: rename the
  FR-017 notification name to "Maintenance record is open too long" (existing My Notifications rows keep the old name),
  or add the planned-maintenance overdue case to the FR-017 notifications. **Changes the design if the FR-017 texts or
  notifications change.**
- **Q5 Follow-ups not built.** "Due Soon" state (e.g. next 30 days) and tile, "Days Overdue" column, list view,
  Equipment FactBox field, creating maintenance records from overdue equipment.
- **Q6 Notifications and job.** Default: none. Alternative: a Role Center / card notification "N pieces of equipment
  are overdue for planned maintenance" (FR-017 pattern, new notification ID) and a telemetry count in the FR-018 daily
  job.
- **Q7 No integration event.** Default: none (keeps tile and highlight consistent; the date itself is already
  extensible through `OnBeforeCalcNextMaintenanceDate`).
- **Q8 Tile colors.** Default: Unfavorable (red) when > 0, Favorable (green) when 0. Alternative: no style when 0
  (standard BC tiles), or Ambiguous for small counts.
- **Q9 Tile name and group.** Default: caption "Overdue Maintenance Equipment" (the issue's KPI name) in a new group
  "Planned Maintenance". Alternative: shorter caption "Maintenance Overdue", or put it in the "Equipment" group.
- **Q10 Automated tests.** Default: deferred, as in FR-003 to FR-019; test codeunit 50174 reserved, tester step skipped;
  OM-SB1 to OM-SB9 are the verification.
- **Q11 Access of the procedures.** Default: `internal`. Alternative: public `IsPlannedMaintenanceOverdue` for partners
  (then the rule becomes permanent API).

Risks:
- R1 The highlight is a style on a page variable: users cannot filter on "overdue" directly. Mitigation: tile
  drill-down. A list filter `..<yesterday>` on Next Maintenance Date also returns equipment with a blank date (FR-019
  V5) and Lost/Disposed equipment; the help must say so.
- R2 `Today()` uses the session time zone; around midnight two users can see a different result for one day. Accepted.
- R3 A cue page left open past midnight keeps yesterday's FlowFilter until reopened (Refresh does not reset it). Same as
  FR-015 R3; accepted.
- R4 Next Maintenance Date is stored (FR-019 R2): a calculation change from a subscriber installed later does not update
  existing records until they are modified, so the overdue result follows the stored date. Accepted.
- R5 Two "overdue" concepts in one app can confuse users (Q4). Mitigation: distinct texts and the help article.
- R6 Tile count scans table 50100 without an index on Next Maintenance Date. Acceptable for equipment volumes.
- R7 No automated tests (Q10): regressions are caught only by review and sandbox checks.
