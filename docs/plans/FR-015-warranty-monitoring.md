# FR-015 Warranty Monitoring

> Status: Approved (user approved with all defaults for Q1-Q10, 2026-11-08). Open questions Q1-Q10 (see "Risks and open questions") each have a
> proposed default, and the plan is written with these defaults. **Q1 (reference date Today or Work Date), Q2 (what
> "Expiring Soon" and "Expired" mean on the boundary days), Q3 (status when there is no Warranty End Date) and Q5
> (Lost and Disposed equipment on the dashboard) change the design if they are answered differently.**
> Source: GitHub issue #34. Branch: `feature/FR-015-warranty-monitoring` (cut from `main` at 1c4e4b6, after the FR-014
> merge).
> No events report. FR-015 only reads this app's own data (table 50100 "EQM Equipment", fields 17 and 18 from FR-014)
> and shows a calculated value on this app's own pages. It subscribes to no standard events and changes no standard
> behavior, so al-event-finder is not needed.
> Scope: main app only. **One new object** (enum 50104 "EQM Warranty Status"). **No new stored field.** Four new
> procedures on table 50100, two new FlowFields and two new FlowFilters on the temporary cue table 50104, one new
> procedure in codeunit 50107, and changes to three pages. **No permission set change. No version bump** (app.json
> stays 29.0.0.0). **No upgrade logic.** Tests are deferred (Q10 default): test codeunit 50169 is reserved, and the
> tester step is skipped.
> Workflow for FR-015: planner -> (human approves plan) -> developer -> reviewer -> build -> **tester step SKIPPED
> (Q10)** -> documenter -> appsource-validator.

## Goal
Users see at a glance whether the warranty of each piece of equipment is still Active, is Expiring Soon (ends within
30 days) or has Expired, so they can act before coverage ends and know whether a repair is still covered. The status is
calculated automatically from the Warranty End Date (FR-014) and today's date every time it is shown; nobody sets it
and no job has to run. It appears on the Equipment Card, the Equipment List and as two dashboard tiles.

### Requirement restated
- WM-R1 Monitor warranty expiration dates of equipment.
- WM-R2 Warranty statuses: Active, Expiring Soon, Expired.
- WM-R3 Expiring Soon = the Warranty End Date is 30 days or less in the future.
- WM-R4 Expired = the Warranty End Date has passed.
- WM-R5 The status is calculated automatically (never entered by a user).

### Interpretation (defaults, see Q1-Q9)
- **Reference date (Q1):** the real date, `Today()`, not the Work Date. A warranty expires in the real world; it must
  not look Active because a user moved the work date back.
- **Boundaries (Q2)**, with D = Warranty End Date and T = today:
  - D < T: **Expired** ("has passed": the day after the end date is the first expired day).
  - T <= D <= T + 30: **Expiring Soon** (the end date itself is the last covered day, so a warranty that ends today is
    still Expiring Soon; a warranty that ends in exactly 30 days is Expiring Soon).
  - D > T + 30: **Active**.
- **No Warranty End Date (Q3):** blank status (enum value 0, caption blank). The equipment is not monitored. This also
  applies when only the Warranty Start Date is filled in, and when there is no warranty at all.
- **Warranty Start Date (Q4):** ignored by the status. A warranty whose start date is in the future is shown by its end
  date (normally Active). The issue lists only three statuses; no "Not Started" status.
- **Lost and Disposed equipment (Q5):** the card and the list still show the calculated warranty status (it is a fact
  about the warranty). The dashboard tiles **exclude** Lost and Disposed equipment, so they count only equipment that is
  still in use and needs action.
- **The 30 days (Q6):** fixed, as the issue says. Defined once in a table procedure that the status and the tiles both
  use. No setup field.
- **Where it shows (Q7):** Equipment Card (Warranty group, promoted, with a style), Equipment List (visible column with
  a style), dashboard and Role Center (new tile group "Warranty" with two tiles: Expiring Soon and Expired). No FactBox
  change, no list views, no notification, no job queue, no email.

### What already exists and is reused
| Already present | Use in FR-015 |
|---|---|
| Table 50100 fields 17 "Warranty Start Date" and 18 "Warranty End Date" (FR-014, stored Date, optional). | Field 18 is the only input of the status. No change to the fields or their rule. |
| FR-012/FR-013 pattern "table procedure returns a value, a second table procedure returns the page style" (`GetStatusStyle`, `GetMaintenanceCostPercentage` + `GetMaintenanceCostStyle`); locked style labels `FavorableStyleTok`, `AmbiguousStyleTok`, `UnfavorableStyleTok`, `StandardStyleTok` on table 50100. | Same pattern for `GetWarrantyStatus` + `GetWarrantyStatusStyle`, reusing the existing style labels. |
| FR-013 Maintenance Cost % on the Equipment List and FactBox: calculated in `OnAfterGetRecord` into a page variable with `StyleExpr`. | Same technique for the Warranty Status column and card field. |
| Temporary cue table 50104 "EQM Equipment Cue" and CardPart 50106 "EQM Equipment Cues" (FR-009/FR-013), shown on page 50109 "EQM Equipment Dashboard" and Role Center 50110; `OnOpenPage` creates the single record; `RefreshCues`; `RefreshOnActivate = true`. | Two new count FlowFields with two FlowFilters set in `OnOpenPage`. Pages 50109 and 50110 need no layout change (they embed page 50106). |
| Codeunit 50107 "EQM Dashboard Mgt." (internal dashboard helpers). | New procedure that sets the warranty FlowFilters on the cue record. |
| Enum 50103 "EQM Maintenance Status" (`Extensible = false`, XML summary). | Shape of the new enum. |
| Permission sets 50100-50102: R/RIM on tabledata 50100, X on table 50104 and pages 50100, 50101, 50106, 50109, 50110 and codeunit 50107. | Already cover everything FR-015 reads and runs. Enums need no permission. |

## Approach and rejected alternatives
- Chosen: **calculate on read**. A new non-extensible enum "EQM Warranty Status" (blank, Active, Expiring Soon,
  Expired). Table 50100 gets internal procedures that calculate the status from "Warranty End Date" and a reference
  date, return the 30-day constant and return the page style. Pages call them in their record triggers and show the
  result in a page variable. The dashboard counts use FlowFields on the cue table with date FlowFilters that the cue
  page sets from the same reference date and the same 30-day constant, so tiles and the per-record status always agree.
  No stored data, no writes, no background job.
- Rejected: a **stored** "Warranty Status" field on table 50100 updated by a daily job queue entry. The status changes
  when the date changes, without any write to the record, so a stored value is stale between job runs, needs a job
  queue setup, a codeunit, write permissions for the job user and an upgrade/backfill, and every update runs the
  equipment consistency checks and `OnModify` logic. The issue only asks for automatic calculation.
- Rejected: a **FlowField** for the status. A CalcFormula cannot compare with today's date or return an enum by date
  range.
- Rejected: following FR-012 literally (status set by events at save time). FR-012's status changes on a business
  event (maintenance registered/posted); warranty status changes with the passing of time, when no event fires. Only
  the FR-012 presentation pattern (procedure + style, status-filtered tiles) is reused.
- Rejected: a new codeunit "EQM Warranty Mgt." for the calculation. The input is one field of the equipment record and
  table 50100 already owns the comparable helpers (`GetStatusStyle`, `GetMaintenanceCostPercentage`); a new object adds
  nothing.
- Rejected: list **views** "Warranty Expiring Soon" / "Warranty Expired". A view filter would need a date relative to
  today, and the per-row status is not a field that can be filtered. The tiles drill down to the filtered list instead
  (Q7 follow-up).
- Rejected: an **integration event** to change the calculated status (for example other day counts). The tiles count
  with FlowFilters and would not follow a subscriber, so the card and the dashboard would disagree (Q8).
- Rejected: a setup field for the 30 days. The issue fixes the value; it can be added later without a breaking change
  because the constant sits behind one procedure (Q6).
- Rejected: notifications, emails or a job that warns about expiring warranties. Not requested (Q7 follow-up).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50106, pages 50100-50119, codeunits 50103-50109,
queries 50100-50103, enums 50100-50103, page extension 50100, permission sets 50100-50102, permission set extension
50103, profile "EQM EQUIPMENT MANAGER". Fields in use on table 50100: 1-20. Fields in use on table 50104: 1, 10-15,
20-21. Test app: no objects; test codeunits 50150-50168 are reserved by FR-001 to FR-014, none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50104 | EQM Warranty Status | New | Values 0 " " (blank), 1 Active, 2 "Expiring Soon", 3 Expired. `Extensible = false` |
| Table | 50100 | EQM Equipment | Modify (own) | Procedures `GetWarrantyStatus`, `CalcWarrantyStatus`, `GetWarrantyExpiringSoonDays`, `GetWarrantyStatusStyle`; ToolTip of field 18 |
| Table | 50104 | EQM Equipment Cue | Modify (own) | FlowFields 30 "Warranty Expiring Soon", 31 "Warranty Expired"; FlowFilters 40 "Warranty Expiring Filter", 41 "Warranty Expired Filter" |
| Codeunit | 50107 | EQM Dashboard Mgt. | Modify (own) | Procedure `SetWarrantyCueFilters` |
| Page | 50106 | EQM Equipment Cues | Modify (own) | New cue group "Warranty" with two tiles; `OnOpenPage` sets the warranty filters |
| Page | 50101 | EQM Equipment Card | Modify (own) | Field "Warranty Status" in group Warranty with style; recalculated when the end date is changed |
| Page | 50100 | EQM Equipment List | Modify (own) | Visible column "Warranty Status" with style; AboutText |
| Page | 50109 | EQM Equipment Dashboard | Modify (own) | AboutText and search terms only |

Not changed: tables 50101-50103, 50105, 50106; pages 50102-50105, 50107, 50108, 50110-50119 (Role Center 50110 shows
the new tiles through page 50106 without a change); codeunits 50103-50106, 50108, 50109; queries; enums 50100-50103;
page extension 50100; permission sets 50100-50102; permission set extension 50103; the profile; `app/app.json`;
`test/`.
New file: `app/src/Equipment/EQMWarrantyStatus.Enum.al`. Namespace `MiguelCarvalho.EquipmentManagement`, like all
existing files.

Next free IDs after FR-015: tables 50107, pages 50120, codeunits 50110, queries 50104, **enums 50105**, page
extensions 50101, permission sets 50104; next free field on table 50100: 21; on table 50104: 32 (FlowFields) / 42
(filters). Test app: test codeunit **50169 reserved for FR-015 "EQM Warranty Status Tests"**, not built now (Q10).

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report, except where a fallback is written here.
- An enum value named `" "` with `Caption = ' '` (as in the base app) compiles with no CodeCop, UICop or AppSourceCop
  warning.
- A CalcFormula filter `Status = filter(<>Lost&<>Disposed)` on an enum field is accepted. **Fallback if it is
  refused:** `Status = filter(Available|Assigned|"In Maintenance")` (then statuses added by extensions are excluded;
  note it in the help).
- A Date FlowFilter set with `SetFilter` to the expression "not blank and before today" (placeholders: `'<>%1&<%2'`
  with 0D and the reference date) is applied by a count FlowField with `"Warranty End Date" = field(<FlowFilter>)`,
  and records with a blank end date are not counted.
- Drilling down on a cue FlowField (`DrillDownPageId = "EQM Equipment List"`) opens the list with the CalcFormula
  filters applied, including the FlowFilter values and the Status filter.
- `Rec.SetRange`/`SetFilter` on FlowFilter fields of the temporary cue record in `OnOpenPage`, after `Rec.Get()` or
  `Rec.Insert()`, is kept by the cue page for every later `CalcFields` and `CurrPage.Update(false)`.
- `ReferenceDate + Integer` on a Date gives the date that many days later (no `CalcDate` needed).

### Enum 50104 "EQM Warranty Status" (new)
File `app/src/Equipment/EQMWarrantyStatus.Enum.al`. `Caption = 'Warranty Status'`, `Extensible = false`, no
`Access` property (default public, like the other enums). `/// <summary>`: "Calculated warranty status of equipment,
based on the Warranty End Date and today's date. Blank when no end date is filled in. Never stored."

| Ordinal | Name | Caption |
|---|---|---|
| 0 | `" "` | `' '` (blank) |
| 1 | Active | Active |
| 2 | "Expiring Soon" | Expiring Soon |
| 3 | Expired | Expired |

### Table 50100 "EQM Equipment" (change)
No new field, key or trigger. No change to existing procedures or events.

**ToolTip of field 18 "Warranty End Date"** becomes:
'Specifies the date the warranty of the equipment ends. When both warranty dates are filled in, the end date must be later than the start date. The warranty status is calculated from this date: Expiring Soon from 30 days before the end date, and Expired after it. Leave it blank when the equipment has no warranty or the end date is not known.'

**New internal procedures**, placed directly after `GetMaintenanceCostStyle` and before `GetSetup`, each with an XML
doc comment:
1. `internal procedure GetWarrantyExpiringSoonDays(): Integer` - returns 30.
   Doc: "Returns how many days before the warranty end date the warranty status becomes Expiring Soon."
2. `internal procedure CalcWarrantyStatus(ReferenceDate: Date): Enum "EQM Warranty Status"` - in this order:
   1. When ReferenceDate = 0D: ReferenceDate := `Today()`.
   2. When "Warranty End Date" = 0D: return `" "`.
   3. When "Warranty End Date" < ReferenceDate: return Expired.
   4. When "Warranty End Date" <= ReferenceDate + `GetWarrantyExpiringSoonDays()`: return "Expiring Soon".
   5. Otherwise: return Active.
   Doc: "Calculates the warranty status on a given date from the Warranty End Date. Blank when no end date is filled
   in; Expired when the end date is before the reference date; Expiring Soon when the end date is on the reference
   date or at most the number of days from GetWarrantyExpiringSoonDays later; otherwise Active. The Warranty Start Date
   is not used." Param ReferenceDate: "The date to calculate the status on. 0D means today." Returns: "The warranty
   status."
3. `internal procedure GetWarrantyStatus(): Enum "EQM Warranty Status"` - returns `CalcWarrantyStatus(Today())`.
   Doc: "Returns the warranty status of the equipment today. See CalcWarrantyStatus."
4. `internal procedure GetWarrantyStatusStyle(WarrantyStatus: Enum "EQM Warranty Status"): Text` - case:
   Active -> `FavorableStyleTok`; "Expiring Soon" -> `AmbiguousStyleTok`; Expired -> `UnfavorableStyleTok`;
   else (blank) -> `StandardStyleTok`. Use the existing locked labels; add no new style label.
   Doc: "Returns the page style name used to show a warranty status." Param: "The status from GetWarrantyStatus."
   Returns: "The style name."

No new labels on the table (the enum captions are the user text).

### Table 50104 "EQM Equipment Cue" (change)
New fields after field 21 (inherit `DataClassification = CustomerContent` from the table; set nothing on the fields):

| ID | Name | Type / class | Caption | ToolTip | CalcFormula / other |
|---|---|---|---|---|---|
| 30 | "Warranty Expiring Soon" | Integer, FlowField, `Editable = false` | Warranty Expiring Soon | 'Specifies the number of equipment records whose warranty ends within the next 30 days, today included. Lost and disposed equipment is not counted.' | count("EQM Equipment" where("Warranty End Date" = field("Warranty Expiring Filter"), Status = filter(<>Lost&<>Disposed))) |
| 31 | "Warranty Expired" | Integer, FlowField, `Editable = false` | Warranty Expired | 'Specifies the number of equipment records whose warranty end date has passed. Lost and disposed equipment and equipment without a warranty end date are not counted.' | count("EQM Equipment" where("Warranty End Date" = field("Warranty Expired Filter"), Status = filter(<>Lost&<>Disposed))) |
| 40 | "Warranty Expiring Filter" | Date, FlowFilter | Warranty Expiring Filter | 'Specifies the warranty end dates that count as expiring soon. It is set automatically.' | none |
| 41 | "Warranty Expired Filter" | Date, FlowFilter | Warranty Expired Filter | 'Specifies the warranty end dates that count as expired. It is set automatically.' | none |

(Fallback for the Status filter: see "Platform names and behaviors to verify".)

### Codeunit 50107 "EQM Dashboard Mgt." (change)
New internal procedure, placed after `ShowEquipmentByStatus`:
`internal procedure SetWarrantyCueFilters(var EquipmentCue: Record "EQM Equipment Cue"; ReferenceDate: Date)`:
1. When ReferenceDate = 0D: ReferenceDate := `Today()`.
2. Local `Equipment: Record "EQM Equipment"`; ExpiringSoonDays := `Equipment.GetWarrantyExpiringSoonDays()`.
3. `EquipmentCue.SetRange("Warranty Expiring Filter", ReferenceDate, ReferenceDate + ExpiringSoonDays)`.
4. `EquipmentCue.SetFilter("Warranty Expired Filter", '<>%1&<%2', 0D, ReferenceDate)`.
Doc: "Sets the date filters of the warranty tiles so that they count the same equipment as the warranty status:
expiring soon from the reference date to the end of the expiring period, expired before the reference date. 0D means
today." Params: EquipmentCue "The cue record to set the filters on."; ReferenceDate "The date the tiles are calculated
on."

### Page 50106 "EQM Equipment Cues" (change)
- New `cuegroup(Warranty)` with `Caption = 'Warranty'`, placed **after** `cuegroup(Equipment)` and before
  `cuegroup(MaintenanceCosts)`, with, in this order (no ToolTip, Caption or ApplicationArea on the controls):
  - `field("Warranty Expiring Soon"; Rec."Warranty Expiring Soon")` with `DrillDownPageId = "EQM Equipment List"`
  - `field("Warranty Expired"; Rec."Warranty Expired")` with `DrillDownPageId = "EQM Equipment List"`
- `OnOpenPage`: after the existing `Get`/`Init`/`Insert` block, add a call to
  `DashboardMgt.SetWarrantyCueFilters(Rec, Today())` (local `DashboardMgt: Codeunit "EQM Dashboard Mgt."`).
- `RefreshCues` unchanged. No styles on the tiles (Q7 follow-up).

### Page 50101 "EQM Equipment Card" (change)
- In `group(Warranty)`, directly after `"Warranty End Date"` and before `"Warranty Provider"`, add
  `field(WarrantyStatus; WarrantyStatus)` with `Caption = 'Warranty Status'`, `Editable = false`,
  `Importance = Promoted`, `StyleExpr = WarrantyStatusStyle`,
  `ToolTip = 'Specifies whether the warranty is Active, Expiring Soon (it ends within 30 days) or Expired (the end date has passed). It is calculated from the warranty end date and today''s date, and is blank when no warranty end date is filled in.'`
- New page variables: `WarrantyStatus: Enum "EQM Warranty Status"`, `WarrantyStatusStyle: Text`.
- New local procedure `UpdateWarrantyStatus()`: WarrantyStatus := `Rec.GetWarrantyStatus()`;
  WarrantyStatusStyle := `Rec.GetWarrantyStatusStyle(WarrantyStatus)`.
- Call `UpdateWarrantyStatus()` as the last line of `UpdateControls()` (runs on `OnAfterGetRecord` and
  `OnNewRecord`).
- On the existing control `"Warranty End Date"` add `trigger OnValidate()` that calls `UpdateWarrantyStatus()`, so the
  status changes as soon as the user changes the date.
- AboutText: unchanged (it already mentions warranty information).

### Page 50100 "EQM Equipment List" (change)
- Repeater: directly after `field("Purchase Cost"; ...)` and before `field("Warranty Start Date"; ...)`, add
  `field(WarrantyStatus; WarrantyStatus)` with `Caption = 'Warranty Status'`, `StyleExpr = WarrantyStatusStyle`,
  **visible** (no `Visible` property), and the same ToolTip text as on the card. (Because the purchase and warranty
  columns before and after it are hidden, it appears after Location Code.)
- New page variables `WarrantyStatus: Enum "EQM Warranty Status"`, `WarrantyStatusStyle: Text`; in `OnAfterGetRecord`
  after the maintenance cost lines: WarrantyStatus := `Rec.GetWarrantyStatus()`;
  WarrantyStatusStyle := `Rec.GetWarrantyStatusStyle(WarrantyStatus)`.
- AboutText becomes: 'This list shows all your equipment. Use **Search** to find equipment by its number, serial number, or any other column you can see. To filter by category, status, or assigned employee, open the filter pane and add a filter on that field. You can also choose a status view at the top of the list. **Warranty Status** shows whether the warranty is active, expiring soon or expired; to find equipment by warranty, filter on **Warranty End Date** or choose a warranty tile on the dashboard. **Total Maintenance Cost** shows the cost of posted maintenance; to see the cost of one period, set **Date Filter** under **Filter totals by**.'
- Views, actions, FactBoxes unchanged.

### Page 50109 "EQM Equipment Dashboard" (change)
- AboutText becomes: 'The tiles count your equipment by status, show how many warranties are expiring within 30 days or have expired, and show the total and average cost of posted maintenance. **Total Equipment** includes lost and disposed equipment; the warranty tiles do not. The charts show how your equipment is spread over categories and statuses, which categories cost the most in maintenance, and the ten pieces of equipment with the highest maintenance cost. Choose a tile or a chart segment to see the details. Choose **Refresh** to update the numbers.'
- AdditionalSearchTerms becomes: 'equipment kpi, equipment overview, equipment chart, maintenance cost, maintenance kpi, warranty expiration, expiring warranties'
- Nothing else changes.

### app.json, translations
- **app.json: no change.** Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf` (enum caption and value captions, cue field
  captions and ToolTips, cue group caption, page field captions and ToolTips, changed ToolTip of field 18, two
  AboutTexts, search terms). Commit it; never edit it by hand.

## Data model and upgrade impact
- No stored schema change. The status is never stored. Table 50104 is `TableType = Temporary`; its new FlowFields and
  FlowFilters create no columns.
- No new key. The two tile counts scan table 50100 filtered on "Warranty End Date" and Status (no index on the end
  date, accepted in FR-014 R4 for equipment volumes).
- DataClassification: cue fields inherit `CustomerContent` from the table. No personal data.
- Upgrade codeunit: **not needed.** Nothing is stored; nothing is released; version stays 29.0.0.0. Existing equipment
  shows its status at once (blank when it has no end date).

## Events
**Standard BC events: none.** No events report is required. Subscribed: none.

Published: **none** (Q8). The status is a read-only calculation; a subscriber that changed it would make the card and
the tiles disagree (tiles count through FlowFilters). Existing events are unchanged and none of them is raised by the
new code (the new procedures read only; no `Modify`).

## Permissions
**No permission set changes.**
- Enum 50104 needs no permission entry.
- EQM - Reader already has R on tabledata "EQM Equipment", X on table "EQM Equipment Cue", pages 50100, 50101, 50106,
  50109, 50110 and codeunit 50107. Manager and Administrator include Reader rights (NFR-002).
- The new code reads only table 50100 (fields the user can already read) and writes only the temporary cue record.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See Warranty Status on card and list | yes | yes | yes |
| See and drill down on the warranty tiles | yes | yes | yes |
| Change the status directly | no (calculated) | no (calculated) | no (calculated) |
| Change the Warranty End Date (changes the status) | no | yes | yes |

## Compatibility
- AppSource mode, development phase: nothing is released, there is no baseline, and no Obsolete handling is needed.
- New public surface after the first release: enum 50104 (public, `Extensible = false`; its values and ordinals become
  permanent). Table 50104 is internal. The four table procedures and the codeunit procedure are `internal`, so the
  30-day rule can change later without a breaking change (Q6, Q9).
- No behavior change in existing rules: no new check on insert, modify, assign, maintenance or posting; no existing
  control, action, group or tile is renamed, moved or removed. The new tile group is inserted between two existing
  groups; the new list column is visible by default (existing personalizations keep their own column set).
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-015-warranty-monitoring.md` and `docs/help/FR-015-warranty-monitoring.md`: the three
    statuses and blank, the exact boundary days (Q2), today's date not the work date (Q1), start date ignored (Q4),
    where it shows, the tiles exclude Lost and Disposed (Q5), how to find equipment by warranty (tile drill-down or
    filter on Warranty End Date; the status column cannot be filtered or sorted, R1), roles.
  - `docs/help/FR-014-warranty-information.md` and `docs/features/FR-014-warranty-information.md`: point to the
    calculated status.
  - `docs/help/FR-008-equipment-card.md`, `docs/help/FR-007-equipment-list-management.md`,
    `docs/help/FR-009-dashboard-kpis.md` (and the matching `docs/features/` files): new field, column and tiles.
  - `CHANGELOG.md`: new top section `## FR-015 Warranty Monitoring (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-015 sandbox checks" with WM-SB1 to WM-SB10.

## Test scenarios
**No automated tests in this iteration** (Q10 default, as in FR-003 to FR-014). Test codeunit 50169 "EQM Warranty
Status Tests" is reserved, and the tester step is skipped. The list is the reference for the developer and reviewer and
for the tests written later (needs the test-app fix in `docs/TODO.md` and `internalsVisibleTo` for the internal
procedures).

Test data, unless stated: active category LAPTOP; equipment saved with `Insert(true)`, Status Available. R = a fixed
reference date (for example 15 June 2026). Calculation tests call `CalcWarrantyStatus(R)`; page and tile tests use
dates relative to `Today()` (T).

Calculation (WM-R2 to WM-R5)
- WS1 Given equipment with no Warranty End Date and no Start Date, when `CalcWarrantyStatus(R)` runs, then it returns
  blank.
- WS2 Given only Warranty Start Date = R - 100 (no end date), then blank (Q3).
- WS3 Given End = R + 31, then Active.
- WS4 Given End = R + 30, then Expiring Soon (upper boundary, Q2).
- WS5 Given End = R + 1, then Expiring Soon.
- WS6 Given End = R, then Expiring Soon (last covered day, Q2).
- WS7 Given End = R - 1, then Expired (first expired day, Q2).
- WS8 Given End = R - 400, then Expired.
- WS9 Given End = R + 365 and Start = R + 10 (warranty not started yet), then Active (start date ignored, Q4).
- WS10 Given End = R + 10, when `CalcWarrantyStatus(0D)` runs, then the result equals `CalcWarrantyStatus(Today())`.
- WS11 Given End = T + 5, then `GetWarrantyStatus()` returns Expiring Soon; given End = T - 1, Expired.
- WS12 `GetWarrantyExpiringSoonDays()` returns 30.
- WS13 Given equipment with Status Disposed and End = R - 1, then `CalcWarrantyStatus(R)` still returns Expired (Q5,
  card and list show the fact).
- WS14 (negative) Given equipment E with End = R + 10, when `CalcWarrantyStatus(R)` runs, then E is not modified
  (SystemModifiedAt unchanged) and no event of table 50100 is raised.

Style
- WS15 `GetWarrantyStatusStyle` returns 'Favorable' for Active, 'Ambiguous' for Expiring Soon, 'Unfavorable' for
  Expired and 'Standard' for blank.

Tiles (cue table, with `SetWarrantyCueFilters(Cue, R)` then `CalcFields`)
- WS16 Given equipment E1 End = R + 31, E2 End = R + 30, E3 End = R, E4 End = R - 1, E5 no end date, then
  "Warranty Expiring Soon" = 2 (E2, E3) and "Warranty Expired" = 1 (E4); E1 and E5 are in neither.
- WS17 Given E6 Disposed with End = R - 1 and E7 Lost with End = R + 5, then neither is counted in either tile (Q5).
- WS18 Given E8 Assigned with End = R + 5 and E9 In Maintenance with End = R - 3, then E8 is counted as Expiring Soon
  and E9 as Expired.
- WS19 Given no equipment with a warranty end date, then both tiles are 0 and no error is raised.
- WS20 For every equipment of WS16-WS18 that is not Lost or Disposed: it is counted in "Warranty Expiring Soon" exactly
  when `CalcWarrantyStatus(R)` = Expiring Soon, and in "Warranty Expired" exactly when it = Expired (tiles and status
  agree).

Pages (TestPage)
- WS21 Given the Equipment Card on equipment with End = T + 60, then Warranty Status shows Active and is not editable;
  when the user sets Warranty End Date to T + 10 on the page, then Warranty Status shows Expiring Soon at once; when the
  user clears the end date, it shows blank.
- WS22 Given a new Equipment Card (create mode), then Warranty Status is blank.
- WS23 Given the Equipment List with equipment of WS16, then the Warranty Status column is visible and each row shows
  the status of WS16 calculated on T (with the dates built from T).
- WS24 Given the Equipment Cues page, when the "Warranty Expired" tile is drilled down, then the Equipment List opens
  with only the equipment whose end date is before T, not blank, and whose status is not Lost or Disposed; the same for
  "Warranty Expiring Soon" with end dates T..T + 30.
- WS25 (negative) Given the Warranty Start Date is changed on the card, then the Warranty Status does not change.

Regression
- WS26 Given equipment with End = T - 1 (Expired), when it is assigned, returned, sent to maintenance and posted, then
  all succeed (the status is informational and blocks nothing).
- WS27 Given equipment with an invalid warranty pair (End <= Start) entered on the card, then the FR-014 error is still
  raised and the warranty status is not changed.

Permissions (`TestPermissions = Restrictive`, with D365 BASIC)
- WS28 Reader: card, list and dashboard show the warranty status and the tiles with no permission error.
- WS29 Manager: changing the Warranty End Date on the card updates the status with no permission error.

### Manual sandbox checks (for the user)
- WM-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings (check the blank enum value); `.g.xlf`
  contains the new texts.
- WM-SB2 Equipment Card: Warranty Status appears after Warranty End Date, in green / yellow / red, and is shown when the
  Warranty group is collapsed. Changing the end date updates it at once.
- WM-SB3 Equipment List: Warranty Status column visible after Location Code with the same styles; equipment without an
  end date shows blank.
- WM-SB4 Dashboard and Role Center: a "Warranty" tile group with Warranty Expiring Soon and Warranty Expired between the
  Equipment and Maintenance Costs groups. Drill-down opens the filtered Equipment List; record which filters are shown
  in the filter pane.
- WM-SB5 Boundary days with real data: end date = today and today + 30 are Expiring Soon; today - 1 is Expired; today
  + 31 is Active.
- WM-SB6 Change the work date to a year earlier: the status and the tiles do not change (Q1).
- WM-SB7 Dispose equipment with an expired warranty: the card still shows Expired; the Expired tile goes down by one.
- WM-SB8 If the CalcFormula fallback (`Available|Assigned|"In Maintenance"`) was needed, record it.
- WM-SB9 Non-SUPER Reader sees status and tiles; non-SUPER Manager can change the end date.
- WM-SB10 Teaching tips of the Equipment List and the Dashboard show the new texts; Tell Me finds the dashboard with
  "expiring warranties".

## Risks and open questions
Open questions (each has the default used in this plan; answer to change it):
- **Q1 Reference date.** Default: `Today()` (real date). Alternative: `WorkDate()` (standard BC cues use it; lets users
  look at the status "as of" another date, but a user with an old work date sees expired warranties as Active).
  **Changes the design if answered differently** (every `Today()` call in the plan, WS10/WS11, WM-SB6).
- **Q2 Boundary days.** Default: end date = today is Expiring Soon (still covered); expired from the day after the end
  date; Expiring Soon covers today .. today + 30 (31 calendar days including today). Alternatives: Expired on the end
  date itself ("end date reached"), or Expiring Soon only up to today + 29. **Changes WS4, WS6, WS7 and the filters.**
- **Q3 No Warranty End Date.** Default: blank status, not monitored, not in any tile. Alternative: a fourth value
  "No Warranty" shown as text (and possibly a tile). **Changes the enum (permanent after release).**
- **Q4 Warranty Start Date.** Default: ignored. Alternative: a "Not Started" status when the start date is after today
  (adds an enum value and a branch).
- **Q5 Lost and Disposed equipment.** Default: status shown on card and list, excluded from the tiles. Alternative:
  counted in the tiles too (simpler CalcFormula), or blank status for final statuses. **Changes the CalcFormulas and
  WS13, WS17.**
- **Q6 The 30 days.** Default: fixed in `GetWarrantyExpiringSoonDays`. Alternative: a setup field "Warranty Expiring
  Days" on table 50102 (default 30, `MinValue = 0`), read by the procedure; adds a field, a setup page control and an
  install default.
- **Q7 Display and follow-ups.** Default: card field, visible list column, two tiles (Expiring Soon, Expired), no tile
  styles. Not built: an "Active warranties" tile, tile styles (for example Unfavorable when Expired > 0), FactBox
  fields, list views, a notification on the card or the Role Center, a job that emails about expiring warranties, a
  warning when maintenance is registered for equipment under warranty.
- **Q8 No integration event.** Default: none (keeps card and tiles consistent). Alternative: `OnAfterCalcWarrantyStatus`
  (partners could change the per-record status, but the tiles would not follow).
- **Q9 Access of the procedures.** Default: `internal` (no public API to keep stable). Alternative: make
  `GetWarrantyStatus` / `CalcWarrantyStatus` public so partners can read the status in their own code; then the
  signature and the boundary rules become permanent.
- **Q10 Automated tests.** Default: deferred, as in FR-003 to FR-014; test codeunit 50169 reserved, tester step skipped,
  WM-SB1 to WM-SB10 are the verification.

Risks:
- R1 The status is a page variable, not a field: users cannot filter, sort or search the list on it, and it does not
  appear in Excel exports of the list or in analysis mode. Mitigation: tiles with drill-down and the Warranty End Date
  filter. A stored or FlowField-backed status is not possible without a job (see Approach).
- R2 `Today()` uses the date of the session's time zone; around midnight, two users in different time zones can see a
  different status for one day. Accepted.
- R3 A cue page left open past midnight keeps yesterday's filters until it is reopened (Refresh does not reset them).
  Accepted; the Role Center reopens the part on navigation.
- R4 The CalcFormula Status filter syntax is unverified; the fallback excludes statuses added by extensions from the
  tiles (WM-SB8).
- R5 The tile counts scan table 50100 without an index on Warranty End Date (FR-014 R4). Acceptable for equipment
  volumes.
- R6 Enum 50104 values become permanent at the first release; settle Q3 and Q4 now.
- R7 No automated tests (Q10): regressions are caught only by review and the sandbox checks.
