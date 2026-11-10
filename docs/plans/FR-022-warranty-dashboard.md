# FR-022 Warranty Dashboard

> Status: **APPROVED** by the user with the default answers to Q1-Q11. Open questions Q1-Q11 (see "Risks and open questions") each have a
> proposed default, and the plan is written with these defaults. **Q1 (what "Active Warranties" counts) and Q2 (whether
> the 90-day and 30-day tiles overlap) change the design if they are answered differently.**
> Source: GitHub issue #41. Branch: `feature/FR-022-warranty-dashboard`.
> No events report. FR-022 only reads this app's own data (table 50100 "EQM Equipment" fields 9 Status and 18
> "Warranty End Date") and shows it on this app's own cue part. It subscribes to no standard events and changes no
> standard behavior, so al-event-finder is not needed.
> Scope: main app only. **No new objects. No new stored field.** Two FlowFields and two FlowFilters on the temporary cue
> table 50104, two caption changes on existing cue fields, one changed procedure in codeunit 50107, two new tiles on cue
> part 50106, AboutText and search terms on page 50109. **No permission set change. No new event. No version bump**
> (app.json stays 29.0.0.0). **No upgrade logic.** Tests deferred (Q9 default): test codeunit 50176 is reserved, and the
> tester step is skipped.
> Workflow for FR-022: planner -> (human approves plan) -> developer -> reviewer -> build -> **tester step SKIPPED
> (Q9)** -> documenter -> appsource-validator.

## Goal
The equipment dashboard (page 50109) and the Equipment Manager Role Center (page 50110) show the four warranty KPIs of
issue #41: Active Warranties, Warranties Expiring in 90 Days, Warranties Expiring in 30 Days and Expired Warranties. Two
of them already exist (FR-015 tiles "Warranty Expiring Soon" and "Warranty Expired"); FR-022 adds the other two as live
tiles in the existing Warranty group of the shared cue part 50106, built on the same date-FlowFilter pattern, each with a
drill-down to the equipment behind the number.

### Requirement restated
- WD-R1 The dashboard includes warranty-related KPIs.
- WD-R2 KPI "Active Warranties".
- WD-R3 KPI "Warranties Expiring in 90 Days".
- WD-R4 KPI "Warranties Expiring in 30 Days".
- WD-R5 KPI "Expired Warranties".

### What already exists and is reused
| Already present | Built in | Use in FR-022 |
|---|---|---|
| Table 50100 field 18 "Warranty End Date" (stored, optional). `CalcWarrantyStatus(ReferenceDate)`: blank when no end date; Expired when end < ref; Expiring Soon when ref <= end <= ref + 30; otherwise Active. Start date ignored. `GetWarrantyExpiringSoonDays()` = 30. | FR-014, FR-015 | Only input of all four tiles. No change. |
| Cue table 50104 field 30 "Warranty Expiring Soon" (count where end date in ref..ref+30, Status not Lost/Disposed) + FlowFilter 40, tile in `cuegroup(Warranty)` of page 50106, drill-down to Equipment List. | FR-015 | **WD-R4 is met by this tile.** Only its caption changes (Q3). |
| Cue table 50104 field 31 "Warranty Expired" (count where end date filled in and < ref, Status not Lost/Disposed) + FlowFilter 41, tile in `cuegroup(Warranty)`. | FR-015 | **WD-R5 is met by this tile.** Only its caption changes (Q3). |
| Cue table 50104 field 32 "Open Warranty Alerts", last tile of `cuegroup(Warranty)`. | FR-016 | Unchanged, stays last in the group. |
| Codeunit 50107 `SetWarrantyCueFilters(var EquipmentCue; ReferenceDate)`, called in `OnOpenPage` of page 50106 with `Today()`; 0D means today. | FR-015 | Extended to also set the two new FlowFilters. Signature unchanged. |
| Codeunit 50110 "EQM Warranty Alert Mgt." `GetIntervalDays(Enum "EQM Warranty Alert Interval")`; value "90 Days" returns 90. The FR-016 alert generator looks at end dates ref..ref+90 for equipment that is not Lost/Disposed. | FR-016 | Single source of the "90 days" number, so the 90-day tile and the 90-day alert window always agree. |
| Page 50109 (dashboard, Refresh calls `RefreshCues`) and Role Center 50110 both embed page 50106. | FR-009 | New tiles appear on both without layout change. |
| Permission set "EQM - Reader" (50100): R on tabledata 50100, X on table 50104, page 50106, page "EQM Equipment List", codeunits 50107 and 50110. Manager and Administrator include Reader. | NFR-002 | Covers everything FR-022 reads and opens. |

### Interpretation (defaults, see Q1-Q7)
With T = `Today()` (real date, not Work Date, as in FR-015, FR-016, FR-020, FR-021) and D = Warranty End Date. All four
tiles count **equipment records** (one warranty per equipment), exclude equipment with Status Lost or Disposed (FR-015
Q5), and ignore the Warranty Start Date (FR-015 Q4). Equipment without a Warranty End Date is never counted.
- **Active Warranties (Q1):** D >= T. The warranty is still in force today. This **includes** warranties that expire
  within 30 days (status "Expiring Soon" on the card and list). So Active Warranties + Expired Warranties = all
  monitored equipment that is still in use.
- **Warranties Expiring in 90 Days (Q2):** T <= D <= T + 90, both ends included. Includes the warranties of the 30-day
  tile (cumulative windows, like the FR-016 alert window).
- **Warranties Expiring in 30 Days:** existing tile field 30, T <= D <= T + 30 (= warranty status Expiring Soon).
- **Expired Warranties:** existing tile field 31, D filled in and D < T (= warranty status Expired).
- Resulting invariants (used in tests): Active >= Expiring 90 >= Expiring 30; Active + Expired = count of equipment not
  Lost/Disposed with an end date.
- **Placement (Q4):** all four in the existing group "Warranty", in issue order, followed by the existing "Open Warranty
  Alerts": Active Warranties, Warranties Expiring in 90 Days, Warranties Expiring in 30 Days, Expired Warranties, Open
  Warranty Alerts. The two existing tiles do not move relative to each other.
- **Captions (Q3):** the existing tiles get the issue's KPI names as captions: field 30 "Warranties Expiring in 30 Days"
  (was "Warranty Expiring Soon"), field 31 "Expired Warranties" (was "Warranty Expired"). Field **names** stay
  unchanged.
- **Style (Q5):** no style on any warranty tile (unchanged from FR-015).
- **Not in scope:** a warranty chart, warranties expiring in 60 days, "no warranty" tile, warranty value or cost
  amounts, a separate warranty Role Center, notifications.

## Approach and rejected alternatives
- Chosen: **two count FlowFields with date FlowFilters on the temporary cue table (FR-015/FR-020/FR-021 pattern)**,
  filters set by the existing `SetWarrantyCueFilters` from the same reference date. The platform counts; drill-down
  needs no code because the FlowField filters are applied to the Equipment List. Nothing stored, no new permission, the
  existing tiles for WD-R4 and WD-R5 are reused (caption only).
- Rejected: a new cue group "Warranty KPIs" separate from "Warranty". Shows the 30-day and expired tiles twice or moves
  FR-015 controls; the existing group already is the warranty area (alternative in Q4).
- Rejected: a separate Warranty Dashboard page or cue part. The issue extends "the dashboard"; a second part duplicates
  the cue pattern and needs new permission entries.
- Rejected: counting in code (loop over equipment with `CalcWarrantyStatus` into page variables + `OnDrillDown`). Loses
  the standard cue drill-down, N record reads per open, more code for what FlowFields already do.
- Rejected: counting "Active" with the enum meaning (D > T + 30) as default. The issue's KPIs are cumulative windows
  (90 contains 30), so "Active" reads as "in force"; kept as alternative in Q1.
- Rejected: a hard-coded 90 in codeunit 50107 or a new setup field. The app already defines "90 days" once, as the
  FR-016 alert interval; reusing it keeps the tile and the alert window consistent (Q8).
- Rejected: a new key on table 50100 "Warranty End Date". Schema change for small volumes (FR-014 R4, FR-015 R5); an
  additive key later stays AppSource-safe.
- Rejected: an integration event to change the counts. FlowFilter-based counts cannot follow a subscriber (FR-015 Q8).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50107, pages 50100-50120, codeunits 50103-50115, queries
50100-50103, enums 50100-50106, page extension 50100, permission sets 50100-50102, permission set extension 50103,
profile "EQM EQUIPMENT MANAGER". Fields in use on table 50104: 1, 10-15, 20-23, 30-32, 40-41, 50-53 (33-39 and 42-49
free). Test app: no objects (folder `test/` has no `.al` files); test codeunits 50150-50175 are reserved by FR-001 to
FR-021, none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50104 | EQM Equipment Cue | Modify (own) | FlowField 33 "Active Warranties", FlowField 34 "Warranties Expiring 90 Days", FlowFilter 42 "Active Warranty Filter", FlowFilter 43 "Warranty 90 Days Filter"; captions of fields 30 and 31 |
| Codeunit | 50107 | EQM Dashboard Mgt. | Modify (own) | `SetWarrantyCueFilters` also sets the two new filters (signature unchanged) |
| Page | 50106 | EQM Equipment Cues | Modify (own) | Two new tiles at the start of `cuegroup(Warranty)` |
| Page | 50109 | EQM Equipment Dashboard | Modify (own) | AboutText and AdditionalSearchTerms only |

Not changed: tables 50100-50103, 50105-50107; pages 50100-50105, 50107, 50108, 50110 (Role Center shows the tiles
through page 50106), 50111-50120; codeunits 50103-50106, 50108-50115 (50110 is only called, not changed); queries;
enums; page extension 50100; permission sets 50100-50102; permission set extension 50103; the profile; `app/app.json`;
`test/`. **No new files.**

Next free IDs after FR-022 (unchanged): tables 50108, pages 50121, codeunits 50116, queries 50104, enums 50107, page
extensions 50101, permission sets 50104; next free field on table 50104: 35 (counts in the 30s block) and 44 (filters in
the 40s block). Test app: **test codeunit 50176 reserved for FR-022 "EQM Warranty Dashboard Tests"**, not built now
(Q9).

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report, except where a fallback is written here.
- V1 A Date FlowFilter set with `SetFilter(<filter>, '>=%1', ReferenceDate)` is applied by a count FlowField with
  `"Warranty End Date" = field(<filter>)`, and records with a blank end date (0D) are **not** counted (0D is earlier
  than any real date). Fallback: `SetFilter(<filter>, '<>%1&>=%2', 0D, ReferenceDate)` (same style as the expired
  filter).
- V2 `WarrantyAlertMgt.GetIntervalDays("EQM Warranty Alert Interval"::"90 Days")` is callable from codeunit 50107 (both
  internal in the same app) and returns 90.
- V3 The CalcFormula `count("EQM Equipment" where("Warranty End Date" = field("Active Warranty Filter"), Status =
  filter(<> Lost & <> Disposed)))` compiles (same syntax as fields 30 and 31).
- V4 The new count tiles are calculated by the cue part without explicit `CalcFields` (as fields 30 and 31 are).
  Fallback if a tile shows 0 in the sandbox while equipment qualifies: add `"Active Warranties"` and `"Warranties
  Expiring 90 Days"` to the existing `Rec.CalcFields(...)` call in `OnAfterGetRecord` of page 50106.
- V5 Drill-down from the new tiles (`DrillDownPageId = "EQM Equipment List"`) opens the list with the end-date filter
  and the Status filter applied (same mechanism as FR-015).

### Table 50104 "EQM Equipment Cue" (change)
New fields. They inherit `DataClassification = CustomerContent` from the table; set nothing else on them than listed.
Place fields 33 and 34 directly after field 32, and fields 42 and 43 directly after field 41.

| ID | Name | Type / class | Caption | ToolTip | CalcFormula / other |
|---|---|---|---|---|---|
| 33 | "Active Warranties" | Integer, FlowField, `Editable = false` | Active Warranties | 'Specifies the number of equipment records whose warranty is still in force: the warranty end date is today or later. Warranties that expire within the next 30 days are included. Lost and disposed equipment and equipment without a warranty end date are not counted. Choose the number to see the equipment.' | count("EQM Equipment" where("Warranty End Date" = field("Active Warranty Filter"), Status = filter(<> Lost & <> Disposed))) |
| 34 | "Warranties Expiring 90 Days" | Integer, FlowField, `Editable = false` | Warranties Expiring in 90 Days | 'Specifies the number of equipment records whose warranty ends within the next 90 days, today included. Warranties that end within 30 days are included. Lost and disposed equipment is not counted. Choose the number to see the equipment.' | count("EQM Equipment" where("Warranty End Date" = field("Warranty 90 Days Filter"), Status = filter(<> Lost & <> Disposed))) |
| 42 | "Active Warranty Filter" | Date, FlowFilter | Active Warranty Filter | 'Specifies the warranty end dates that count as active. It is set automatically.' | none |
| 43 | "Warranty 90 Days Filter" | Date, FlowFilter | Warranty 90 Days Filter | 'Specifies the warranty end dates that count as expiring within 90 days. It is set automatically.' | none |

Name lengths (limit 30): "Active Warranties" 17, "Warranties Expiring 90 Days" 27, "Active Warranty Filter" 22,
"Warranty 90 Days Filter" 23.

**Caption changes on existing fields (names, IDs, CalcFormulas and ToolTips unchanged):**
- Field 30 "Warranty Expiring Soon": `Caption = 'Warranties Expiring in 30 Days'`.
- Field 31 "Warranty Expired": `Caption = 'Expired Warranties'`.

### Codeunit 50107 "EQM Dashboard Mgt." (change)
- **Change** `internal procedure SetWarrantyCueFilters(var EquipmentCue: Record "EQM Equipment Cue"; ReferenceDate:
  Date)` (signature unchanged). Steps, in this order:
  1. When ReferenceDate = 0D: ReferenceDate := `Today()` (existing).
  2. ExpiringSoonDays := `Equipment.GetWarrantyExpiringSoonDays()` (existing).
  3. New: ExpiringWithin90Days := `WarrantyAlertMgt.GetIntervalDays("EQM Warranty Alert Interval"::"90 Days")`. New
     locals: `WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt."`, `ExpiringWithin90Days: Integer`.
  4. Existing `SetRange("Warranty Expiring Filter", ...)` and `SetFilter("Warranty Expired Filter", ...)` lines
     unchanged.
  5. New: `EquipmentCue.SetFilter("Active Warranty Filter", '>=%1', ReferenceDate)` (V1 fallback if needed).
  6. New: `EquipmentCue.SetRange("Warranty 90 Days Filter", ReferenceDate, ReferenceDate + ExpiringWithin90Days)`.
  New doc summary: "Sets the date filters of the warranty tiles so that they count the same equipment as the warranty
  status: active from the reference date on, expiring within 90 days and within the expiring period from the reference
  date, expired before the reference date. 0D means today." Param docs unchanged.
- The filter string `'>=%1'` is a format string with a placeholder, not user text, same as the existing `'<>%1&<%2'`
  literal (no label needed; follow whatever the existing line does).
- No other change. No new procedure, no new event, no `Commit`, no database write.

### Page 50106 "EQM Equipment Cues" (change)
- `cuegroup(Warranty)`: add, **before** the existing "Warranty Expiring Soon" control, in this order:
  - `field("Active Warranties"; Rec."Active Warranties")` with `DrillDownPageId = "EQM Equipment List"`.
  - `field("Warranties Expiring 90 Days"; Rec."Warranties Expiring 90 Days")` with
    `DrillDownPageId = "EQM Equipment List"`.
  No Caption, ToolTip, ApplicationArea or StyleExpr on the controls (inherited from table and page).
- Resulting group order: Active Warranties, Warranties Expiring in 90 Days, Warranties Expiring in 30 Days, Expired
  Warranties, Open Warranty Alerts.
- `OnOpenPage`, `OnAfterGetRecord`, `RefreshCues`, the other groups and tiles: unchanged (V4 fallback only if needed).
- Group order stays: Equipment, Warranty, Planned Maintenance, Maintenance Costs.

### Page 50109 "EQM Equipment Dashboard" (change)
- AboutText becomes (one line in the source): 'The tiles count your equipment by status, show how many warranties are active, expire within 90 or 30 days or have expired, how many warranty alerts are open, how many pieces of equipment have planned maintenance due this month or overdue, and show the total cost of posted maintenance, this year''s cost so far and the average cost. **Total Equipment** includes lost and disposed equipment; the warranty and planned maintenance tiles do not. **Active Warranties** includes the warranties that expire soon, and **Warranties Expiring in 90 Days** includes those that expire within 30 days. **Overdue Maintenance Equipment** turns red when at least one piece of equipment has a next maintenance date before today. The charts show how your equipment is spread over categories and statuses, which categories cost the most in maintenance, and the ten pieces of equipment with the highest maintenance cost. Choose a tile or a chart segment to see the details. Choose **Refresh** to update the numbers.'
- AdditionalSearchTerms becomes: 'equipment kpi, equipment overview, equipment chart, maintenance cost, maintenance kpi, warranty expiration, expiring warranties, warranty alerts, overdue maintenance, maintenance due, maintenance dashboard, maintenance this month, maintenance cost ytd, warranty dashboard, warranty kpi, active warranties, expired warranties'
- Nothing else changes.

### app.json, translations
- **app.json: no change.** Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf` (four new field captions and ToolTips, two
  changed captions, AboutText, search terms). Commit the file; never edit it by hand.

## Data model and upgrade impact
- **No stored schema change.** Table 50104 is `TableType = Temporary`; its new FlowFields and FlowFilters create no
  columns. Table 50100 and its keys are unchanged.
- DataClassification: new cue fields inherit `CustomerContent` from the table. They hold counts only and are never
  stored. No personal data.
- Performance per open or Refresh: two more `COUNT`s on table 50100 filtered on "Warranty End Date" and Status (no
  index, same as fields 30 and 31). Acceptable for equipment volumes (R4).
- Upgrade codeunit: **not needed.** Nothing stored, nothing released, version unchanged. Existing data is shown at once.

## Events
**Standard BC events: none.** No events report is required. Subscribed: none.

Published: **none** (Q11). The KPIs are read-only FlowField counts; a subscriber could not change a FlowFilter-based
count consistently with the per-record warranty status (FR-015 Q8). Partners can add their own tiles by extending page
50106 (additive page extension). No existing event is raised by the new code (it only sets filters; no `Modify`).

## Permissions
**No permission set changes.**
- "EQM - Reader" already has R on tabledata "EQM Equipment", X on table "EQM Equipment Cue" (temporary, no tabledata
  entry needed), pages "EQM Equipment Cues", "EQM Equipment Dashboard", "EQM Equipment Manager RC", "EQM Equipment
  List", and codeunits "EQM Dashboard Mgt." and "EQM Warranty Alert Mgt." (the latter is only called for a constant; it
  reads no data in `GetIntervalDays`). Manager and Administrator include Reader rights (NFR-002).

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See the four warranty tiles on dashboard and Role Center | yes | yes | yes |
| Drill down from Active Warranties / Warranties Expiring in 90 Days | yes | yes | yes |
| Change the numbers (change Warranty End Date or equipment status) | no | yes | yes |

## Compatibility
- AppSource mode, development phase: nothing is released, no baseline, no Obsolete handling needed.
- No new public surface. Table 50104 and codeunits 50107 and 50110 are `Access = Internal`; the changed procedure keeps
  its signature.
- Page 50106 (public, extensible): two controls are added inside an existing group, before existing controls; no
  control, group or action is renamed, moved or removed, so page extensions that anchor on controls stay valid. Once
  released, the new control names become anchors for partners.
- Caption changes on fields 30 and 31 are text only (field names and IDs unchanged): no compile impact on extensions,
  but translations of the old captions in other languages become stale (none exist yet besides the generated `.g.xlf`).
- No behavior change: FR-015 tiles count exactly as before (filters 40 and 41 unchanged); FR-016 alerts are unchanged.
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-022-warranty-dashboard.md` and `docs/help/FR-022-warranty-dashboard.md`: the four KPIs and
    their order in the Warranty group, the date rules with boundary days, today not the work date, cumulative windows
    (Active includes Expiring Soon; 90 includes 30) and why the card/list "Warranty Status" column can say "Expiring
    Soon" for equipment counted as active, Lost/Disposed and blank end dates excluded, start date ignored, the 90 days
    match the 90-day warranty alert, drill-downs, Refresh, roles.
  - `docs/help/FR-015-warranty-monitoring.md`, `docs/features/FR-015-warranty-monitoring.md`,
    `docs/help/FR-009-dashboard-kpis.md`, `docs/features/FR-009-dashboard-kpis.md`: the renamed tile captions ("Warranty
    Expiring Soon" -> "Warranties Expiring in 30 Days", "Warranty Expired" -> "Expired Warranties") and a
    cross-reference to FR-022. `docs/help/FR-016-warranty-alerts.md` and its feature doc: one cross-reference to the
    90-day tile.
  - `README.md`: new row "Warranty dashboard KPIs (FR-022)" with "Built, not yet verified in a Business Central
    sandbox".
  - `CHANGELOG.md`: new top section `## FR-022 Warranty Dashboard (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-022 sandbox checks (not run; automated tests deferred, Q9, test codeunit 50176
    reserved)" with WD-SB1 to WD-SB8.

## Test scenarios
**No automated tests in this iteration** (Q9 default, as in FR-003 to FR-021). Test codeunit 50176 "EQM Warranty
Dashboard Tests" is reserved and the tester step is skipped. The list is the reference for the developer, the reviewer
and the tests written later (needs the test-app fix in `docs/TODO.md` and `internalsVisibleTo`, because codeunit 50107
and table 50104 are internal).

Test data, unless stated: all equipment and warranty alerts deleted first; active category LAPTOP; equipment saved with
`Insert(true)`, Status Available, no Warranty Start Date. R = 15 June 2026 (a fixed reference date). The end date is set
with `Validate("Warranty End Date", ...)` and saved with `Modify(true)`. Cue filters are set with
`SetWarrantyCueFilters(Cue, R)` on a temporary cue record that was inserted, then `CalcFields` on the four warranty
fields. Page tests use dates relative to `Today()` (T).

Active Warranties (WD-R2) and Warranties Expiring in 90 Days (WD-R3)
- WD1 Given E1 End = R - 1, E2 End = R, E3 End = R + 30, E4 End = R + 31, E5 End = R + 90, E6 End = R + 91, E7 End =
  R + 400, E8 no end date, when the cue is calculated, then "Active Warranties" = 6 (E2-E7), "Warranties Expiring 90
  Days" = 4 (E2-E5), "Warranty Expiring Soon" = 2 (E2, E3) and "Warranty Expired" = 1 (E1); E8 is in no tile.
- WD2 (negative) Given E9 with only Warranty Start Date = R - 100 (no end date), then E9 is in no tile.
- WD3 Given E10 End = R + 60 and Start = R + 10 (warranty not started yet), then E10 is counted in "Active Warranties"
  and "Warranties Expiring 90 Days" (start date ignored, Q7).
- WD4 (negative) Given E11 Lost with End = R + 10 and E12 Disposed with End = R + 200, then neither is counted in any of
  the four tiles.
- WD5 Given E13 Assigned with End = R + 45 and E14 In Maintenance with End = R + 5, then E13 is counted in Active and 90
  days; E14 in Active, 90 days and 30 days.
- WD6 Given no equipment with a warranty end date, then all four tiles are 0 and no error is raised.

Filters and reference date
- WD7 Given filters set with R, then `GetRangeMin`/`GetRangeMax` of "Warranty 90 Days Filter" are R and R + 90, and
  `GetFilter("Active Warranty Filter")` selects R and later only (check with the V1 form actually used).
- WD8 Given filters set with ReferenceDate 0D, then the four filters equal those set with `Today()`.
- WD9 (regression) Given filters set with R, then "Warranty Expiring Filter" is still R..R + 30 and "Warranty Expired
  Filter" text is unchanged from before FR-022.
- WD10 Given R = 1 December 2026 and E15 End = 1 March 2027 (R + 90 across a year end), then E15 is counted in 90
  days; E16 End = 2 March 2027 is not.

Consistency
- WD11 For the data of WD1 + WD3 + WD5: "Active Warranties" >= "Warranties Expiring 90 Days" >= "Warranty Expiring
  Soon", and "Active Warranties" + "Warranty Expired" = number of equipment not Lost/Disposed with an end date.
- WD12 For every equipment of WD1-WD5 that is not Lost or Disposed: counted in "Active Warranties" exactly when
  `CalcWarrantyStatus(R)` is Active or Expiring Soon; in "Warranty Expiring Soon" exactly when it is Expiring Soon; in
  "Warranty Expired" exactly when it is Expired.
- WD13 For the data of WD1, when `GenerateAlerts(R, false, ...)` (codeunit 50110) runs, then every equipment counted in
  "Warranties Expiring 90 Days" has an open alert, and no equipment outside it gets one (90-day window agrees with
  FR-016).

Changes over time (negative / update)
- WD14 Given E17 End = R + 10 counted in Active, when its end date is cleared and saved, then after recalculation E17 is
  in no tile.
- WD15 Given E18 End = R + 120 (Active, not in 90 days), when the status is set to Disposed, then Active goes down by 1.
- WD16 (negative) Given E19 counted in Active, when only its Warranty Start Date is changed, then no tile changes.

Cue part and dashboard (WD-R1, TestPage)
- WD17 Given equipment with ends T - 1, T, T + 45, T + 120, when page 50106 opens, then group Warranty shows, in this
  order, "Active Warranties" = 3, "Warranties Expiring in 90 Days" = 2, "Warranties Expiring in 30 Days" = 1, "Expired
  Warranties" = 1, "Open Warranty Alerts", with these captions.
- WD18 Given page 50106, when "Active Warranties" is drilled down (`Trap` on page "EQM Equipment List"), then the list
  shows only equipment with an end date from T on, not Lost or Disposed.
- WD19 Given page 50106, when "Warranties Expiring in 90 Days" is drilled down, then the list shows only equipment with
  end dates T..T + 90, not Lost or Disposed.
- WD20 Given page 50109 open, when a new equipment with End = T + 50 is inserted in the test and Refresh is invoked, then
  Active and 90 days go up by 1 without reopening.
- WD21 (negative) Given the tiles, when the user tries to edit a tile value, then it is not possible; opening the page
  writes no data (no stored cue row; equipment SystemModifiedAt unchanged).

Permissions (`TestPermissions = Restrictive`, with D365 BASIC)
- WD22 Given a user with EQM - Reader only, when page 50109 opens and both new tiles are drilled down, then no
  permission error is raised.
- WD23 (negative) Given a user without any EQM permission set, when page 50109 opens, then a permission error is raised
  (unchanged from FR-009).

### Manual sandbox checks (for the user)
- WD-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` has the new captions and ToolTips,
  the two changed captions, the new AboutText and search terms.
- WD-SB2 Dashboard and Role Center: group Warranty shows Active Warranties, Warranties Expiring in 90 Days, Warranties
  Expiring in 30 Days, Expired Warranties, Open Warranty Alerts, in that order; captions are readable on a tile (Q6).
- WD-SB3 Boundary days with real data: end date today is in Active, 90 and 30; today + 90 is in Active and 90; today +
  91 only in Active; today - 1 only in Expired.
- WD-SB4 Drill-down from both new tiles opens the filtered Equipment List; record which filters the filter pane shows
  (V5). Rows in the Active drill-down may show Warranty Status "Expiring Soon" (expected, Q1).
- WD-SB5 Dispose equipment with an active warranty: after Refresh, Active (and 90/30 if applicable) goes down.
- WD-SB6 Change the work date to last year: tiles do not change (Today not Work Date).
- WD-SB7 Non-SUPER Reader sees the tiles and can drill down.
- WD-SB8 Tell Me finds the dashboard with "warranty dashboard"; the teaching tip shows the new text. If the V1 or V4
  fallback was needed, record it.

## Risks and open questions
Open questions (each has the default used in this plan; answer to change it):
- **Q1 What "Active Warranties" counts.** Default: warranties still in force (end date today or later), **including**
  those Expiring Soon. Alternative: only equipment whose warranty status is "Active" on the card (end date after today +
  30), so Active, Expiring in 30 Days and Expired partition the monitored equipment. **Changes the design** (filter
  expression becomes "after R + 30", ToolTip, AboutText, WD1, WD5, WD11, WD12, WD17).
- **Q2 Overlap of the 90-day and 30-day tiles.** Default: cumulative (90 includes 30, as the FR-016 alert window).
  Alternative: the 90-day tile counts only 31 to 90 days ahead (no overlap). **Changes the design** (filter range,
  caption/ToolTip wording, WD1, WD5, WD11, WD13).
- **Q3 Captions of the existing tiles.** Default: rename captions of fields 30 and 31 to "Warranties Expiring in 30
  Days" and "Expired Warranties" (issue names; field names unchanged). Alternative: keep "Warranty Expiring Soon" and
  "Warranty Expired" (no help updates for the rename).
- **Q4 Placement.** Default: all in the existing Warranty group in issue order, Open Warranty Alerts last. Alternative:
  new group "Warranty KPIs" with the four tiles, leaving Open Warranty Alerts alone in "Warranty".
- **Q5 Tile styles.** Default: none (as FR-015). Alternative: Expired Warranties Unfavorable when > 0 and Warranties
  Expiring in 30 Days Ambiguous when > 0 (needs page variables and a style procedure in codeunit 50107, like FR-020).
- **Q6 Caption length.** "Warranties Expiring in 90 Days" / "... 30 Days" are long for a tile and may wrap. Alternative
  captions: "Expiring in 90 Days", "Expiring in 30 Days" (the group caption already says Warranty).
- **Q7 Lost/Disposed, blank end date, start date.** Default: same as FR-015 (Lost/Disposed and blank end date excluded;
  start date ignored, so a warranty that has not started yet counts as active). Alternative: Active requires Start Date
  <= today when filled in (needs a second FlowFilter on field 17 and a blank-start rule).
- **Q8 Source of the 90 days.** Default: the FR-016 "90 Days" alert interval via `GetIntervalDays`, so tile and alerts
  agree. Alternative: an independent constant (tile would not follow a future change of the alert interval) or a
  setup field.
- **Q9 Automated tests.** Default: deferred, as in FR-003 to FR-021; test codeunit 50176 reserved, tester step skipped;
  WD-SB1 to WD-SB8 are the verification.
- **Q10 Help location.** Default: a separate FR-022 help article plus cross-references. Alternative: only extend the
  FR-015 and FR-009 help.
- **Q11 No integration event.** Default: none (see Events).

Risks:
- R1 With the Q1 default, the Active drill-down list shows rows whose Warranty Status column says "Expiring Soon".
  ToolTip, AboutText and help must explain that Active means "in force", or users will think the tile is wrong.
- R2 A cue page left open past midnight keeps the old filters until it is reopened; Refresh does not reset them (FR-015
  R3). Accepted.
- R3 `Today()` uses the session time zone; around midnight two users can see different numbers. Accepted.
- R4 Two more unindexed counts on table 50100 per open/Refresh (four warranty counts in total). Acceptable for equipment
  volumes; an additive key on "Warranty End Date" later is AppSource-safe.
- R5 The caption rename (Q3) makes existing FR-009/FR-015 help screenshots and text outdated until the documenter
  updates them.
- R6 Coupling to the FR-016 interval enum (Q8): if the "90 Days" value is ever changed or removed, the tile changes or
  fails to compile; that is intended (one definition) but must be noted in the codeunit doc comment.
- R7 No automated tests (Q9): regressions are caught only by review and sandbox checks.
