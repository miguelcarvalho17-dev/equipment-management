# FR-019 Planned Maintenance

> Status: **Approved by the user with the proposed defaults for Q1-Q12.** Open questions Q1-Q12 (see "Risks and open questions") each have a proposed
> default, and the plan is written with these defaults. **Q1 (Next Maintenance Date is calculated and read-only), Q2
> (posting maintenance updates Last Maintenance Date automatically) and Q3 (only Preventive maintenance resets the
> schedule) change the design if they are answered differently.**
> Source: GitHub issue #38. Branch: `feature/FR-019-planned-maintenance`.
> No events report. FR-019 only adds fields to this app's own table 50100 "EQM Equipment", changes this app's own
> pages and this app's own posting codeunit 50109. It subscribes to no standard events and changes no standard
> behavior, so al-event-finder is not needed.
> Scope: main app only. **No new objects.** Three new **stored** fields on table 50100, two new integration events,
> changes to codeunit 50109 and pages 50100, 50101 and 50115. **No permission set change. No version bump** (app.json
> stays 29.0.0.0). **No upgrade logic.** Tests deferred (Q11 default): test codeunit 50173 is reserved, and the tester
> step is skipped.
> Workflow for FR-019: planner -> (human approves plan) -> developer -> reviewer -> build -> **tester step SKIPPED
> (Q11)** -> documenter -> appsource-validator.

## Goal
Users can plan recurring maintenance per piece of equipment: they enter how often it must be maintained (in months)
and when it was last maintained, and the system calculates when the next maintenance is due. When a preventive
maintenance record is posted, the last maintenance date moves forward automatically, so the schedule keeps itself up
to date. Example from the issue: last maintenance **1 January 2026** with a frequency of **6 months** gives a next
maintenance date of **1 July 2026** (the issue writes the dates as DD/MM/YYYY: 01/01/2026 and 01/07/2026).

### Requirement restated
- PM-R1 Three fields on equipment: Last Maintenance Date, Next Maintenance Date, Maintenance Frequency (Months).
- PM-R2 Next Maintenance Date = Last Maintenance Date + Maintenance Frequency (Months).
- PM-R3 (implied by "scheduling") The schedule follows the real maintenance work recorded in the app.

### Interpretation (defaults, see Q1-Q12)
- **Next Maintenance Date (Q1):** calculated, stored (so it can be filtered and sorted), not editable by users. It is
  recalculated whenever Last Maintenance Date or Maintenance Frequency (Months) is validated, and on every
  `Insert(true)` / `Modify(true)`. It is blank when Last Maintenance Date is blank or the frequency is 0.
- **Month arithmetic:** the platform `CalcDate` with a month formula (`<nM>`). A last date at the end of a long month
  gives the last day of the shorter target month (31 August 2026 + 6 months = 28 February 2027). See V1.
- **Maintenance Frequency (Months) (Q4):** whole months, 0 to 120. 0 (shown blank) means "no planned maintenance".
- **Last Maintenance Date (Q6):** entered by the user (for example for work done before the app was used) or set by
  posting. It cannot be later than today (same rule as the Maintenance Date of a maintenance record). It may be moved
  backwards by hand. It is not compared with the Purchase Date or with the maintenance history.
- **Posting (Q2, Q3):** when a maintenance record of type **Preventive** is posted, the equipment's Last Maintenance
  Date becomes the record's Maintenance Date, but only if that date is later than the current Last Maintenance Date
  (or the current one is blank). The date never moves backwards through posting. Corrective, Inspection and Upgrade
  records do not change the schedule (partners can change this through a new event). Registering (not posting) a
  record changes nothing.
- **No base date without Last Maintenance Date (Q5):** the Purchase Date is not used as a fallback.
- **Lost and Disposed equipment (Q12):** no new rule; the fields stay editable and posting still updates them.
- **Not in scope (Q7):** no "due"/"overdue" status, style, view, dashboard tile, notification, alert or job for planned
  maintenance. The FR-017 overdue rule (open record more than 14 days old) and the FR-018 jobs are unchanged.

### What already exists and is reused
| Already present | Built in | Use in FR-019 |
|---|---|---|
| Table 50100 "EQM Equipment" (public, `DataClassification = CustomerContent` at table level), fields 1-20; `CheckEquipmentConsistency(IsNewRecord)` called from `OnInsert` / `OnModify`; pattern "local check procedure + `OnBefore...` IsHandled event" (`CheckWarrantyDates`). | FR-001, FR-014 | Three new fields 21-23; new date check follows the `CheckWarrantyDates` pattern. |
| Maintenance Record table 50105: `"Maintenance Type"` enum 50102 (Preventive, Corrective, Inspection, Upgrade), `"Maintenance Date"` (never later than today, never blank after insert). | FR-010 | The posting rule reads both. |
| Codeunit 50109 "EQM Maintenance-Post", local `CompleteEquipmentMaintenance` (gets the equipment with `UpdLock`, calls `Equipment.CompleteMaintenance`). | FR-011, FR-012 | Also updates the planned maintenance dates, in the same locked equipment record. |
| Page 50101 card group `Warranty`; page 50100 hidden warranty columns; page 50115 Maintenance FactBox with a calculated control captioned "Last Maintenance Date". | FR-008, FR-014, FR-010 | New card group, new list columns, FactBox caption clash resolved (Q8). |
| Permission sets 50100 (R on table 50100), 50101 (RIM), 50102 (includes 50101). | NFR-002 | Already cover the new fields. Posting already needs M on equipment (status change). |

## Approach and rejected alternatives
- Chosen: **three stored fields on our own table 50100; Next Maintenance Date calculated in one internal procedure,
  called from field validation and from the insert/modify triggers; the posting codeunit moves Last Maintenance Date
  forward for Preventive records; small page changes. No new objects.**
- Rejected: Next Maintenance Date as a page variable calculated on read (like Warranty Status). The issue lists it as a
  field, and a stored date can be filtered and sorted on the list ("which equipment is due before the end of the
  month") and reused by later due/alert features.
- Rejected: Next Maintenance Date editable with recalculation as a default only. Two sources of truth; a manual value is
  silently overwritten whenever the frequency or last date changes (Q1 alternative).
- Rejected: a separate maintenance plan table (several plans per equipment, for example "service every 6 months,
  inspection every 12"). The issue asks for one set of fields per equipment; new table, page, permissions and delete
  handling without a requirement. Possible later.
- Rejected: frequency as a `DateFormula` field (any period, e.g. `<2W>`). The issue specifies months; an integer is
  simpler to enter and to report on.
- Rejected: a FlowField for Last Maintenance Date (max Maintenance Date of posted Preventive history entries). A
  FlowField cannot feed a stored, filterable Next date, and users could not enter maintenance done before the app was
  used.
- Rejected: updating the schedule in a subscriber to our own `OnAfterPostMaintenanceRecord`. It would need a second
  equipment read and lock; `CompleteEquipmentMaintenance` already holds the locked equipment record.
- Rejected: due status, overdue style, view, tile, notification or job queue alerts for planned maintenance. Not asked;
  follow-ups (Q7).
- Rejected: a table extension. Table 50100 is our own table.

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50107, pages 50100-50120, codeunits 50103-50115,
queries 50100-50103, enums 50100-50106, page extension 50100, permission sets 50100-50102, permission set extension
50103, profile "EQM EQUIPMENT MANAGER". Fields in use on table 50100: 1-20. Test app: no objects; test codeunits
50150-50172 are reserved by FR-001 to FR-018, none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50100 | EQM Equipment | Modify (own) | Fields 21-23; calculation and check procedures; two new integration events; trigger calls |
| Codeunit | 50109 | EQM Maintenance-Post | Modify (own) | `CompleteEquipmentMaintenance` also updates the planned maintenance dates |
| Page | 50101 | EQM Equipment Card | Modify (own) | New group `PlannedMaintenance`; AboutText |
| Page | 50100 | EQM Equipment List | Modify (own) | Three columns (one visible); AboutText |
| Page | 50115 | EQM Maintenance FactBox | Modify (own) | Captions of two existing controls changed; new control "Next Maintenance Date" |

Not changed: tables 50101-50107; all other pages; codeunits 50103-50108, 50110-50115; queries; enums (50102 is only
read); page extension 50100; permission sets 50100-50102; permission set extension 50103; the profile; `app/app.json`;
`test/`. **No new files.**

Next free IDs after FR-019 (unchanged): tables 50108, pages 50121, codeunits 50116, queries 50104, enums 50107, page
extensions 50101, permission sets 50104; next free field on table 50100: **24**. Test app: **test codeunit 50173
reserved for FR-019 "EQM Planned Maintenance Tests"**, not built now (Q11).

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report, except where a fallback is written here.
- V1 `CalcDate` with a text formula `<6M>` on 1 January 2026 returns 1 July 2026, and on 31 August 2026 returns
  28 February 2027 (end-of-month clamp). Verify in the sandbox (PM-SB4); if it behaves differently, record it in the
  help, no code change.
- V2 Field name length is at most 30 characters: "Maintenance Frequency (Months)" is exactly 30, "Last Maintenance
  Date" 21, "Next Maintenance Date" 21. **Fallback** if the compiler rejects it: field name "Maint. Frequency (Months)"
  (Caption stays 'Maintenance Frequency (Months)'); use the fallback name everywhere this plan names the field.
- V3 `MinValue = 0` / `MaxValue = 120` on an Integer field raise the platform's own error on `Validate` (no label
  needed), and `BlankZero = true` on the table field is inherited by page controls.
- V4 Adding stored fields to table 50100 syncs without a destructive change in the development sandbox (PM-SB2).
- V5 A date filter of the form `..D` also includes blank dates (0D); a range with a start date (`D1..D2`) excludes them.
  Used only for help text and PM32.

### Table 50100 "EQM Equipment" (change)
New fields, after field 20 "Warranty Reference No.". Normal stored fields; they inherit `DataClassification =
CustomerContent` from the table (do not set it on the fields). No `TableRelation`, no `NotBlank`, no `InitValue`.

| ID | Name | Type | Caption | Properties | ToolTip | Trigger |
|---|---|---|---|---|---|---|
| 21 | "Last Maintenance Date" | Date | Last Maintenance Date | - | 'Specifies the date the equipment was last maintained according to its maintenance plan. Posting a preventive maintenance record with a later date updates it automatically. The date cannot be later than today. The next maintenance date is calculated from this date and the maintenance frequency.' | `OnValidate`: `CheckLastMaintenanceDate()`, then `UpdateNextMaintenanceDate()` |
| 22 | "Next Maintenance Date" | Date | Next Maintenance Date | `Editable = false` | 'Specifies when the next planned maintenance of the equipment is due. It is calculated as the last maintenance date plus the maintenance frequency in months, and is blank when either is missing.' | none |
| 23 | "Maintenance Frequency (Months)" | Integer | Maintenance Frequency (Months) | `MinValue = 0`, `MaxValue = 120`, `BlankZero = true` | 'Specifies how often the equipment must be maintained, in months, for example 6 for every six months. Leave it blank when the equipment has no planned maintenance. The next maintenance date is calculated from the last maintenance date and this frequency.' | `OnValidate`: `UpdateNextMaintenanceDate()` |

Order of field declarations in the file: 21, 22, 23. Keys and field groups do not change (R4).

New labels in the `var` section, after `WarrantyEndDateErr`:
- `LastMaintenanceDateFutureErr: Label 'The last maintenance date %1 is in the future. Enter a date that is not later than today (%2).', Comment = '%1 = last maintenance date, %2 = today''s date';`
- `MonthsDateFormulaTok: Label '<%1M>', Locked = true;` (date formula text for `CalcDate`; `%1` is the number of
  months formatted with `Format(<frequency>, 0, 9)`).

New procedures, placed after `CheckWarrantyDates` and before `IsStoredRecord`, each with a `/// <summary>`:
1. `internal procedure CalcNextMaintenanceDate(): Date`
   Summary: "Calculates the next planned maintenance date from the last maintenance date and the maintenance frequency
   in months. Returns 0D when the last maintenance date is blank or the frequency is 0." Steps:
   1. Local `NextMaintenanceDate: Date` (0D) and `IsHandled: Boolean`.
   2. Raise `OnBeforeCalcNextMaintenanceDate(Rec, NextMaintenanceDate, IsHandled)`; when IsHandled:
      exit(NextMaintenanceDate).
   3. When "Last Maintenance Date" = 0D or "Maintenance Frequency (Months)" <= 0: exit(0D).
   4. exit(`CalcDate` of `StrSubstNo(MonthsDateFormulaTok, Format("Maintenance Frequency (Months)", 0, 9))` applied to
      "Last Maintenance Date").
2. `local procedure UpdateNextMaintenanceDate()`
   Summary: "Sets the next maintenance date from CalcNextMaintenanceDate." Body: assign
   `CalcNextMaintenanceDate()` to "Next Maintenance Date" directly (the field has no trigger).
3. `local procedure CheckLastMaintenanceDate()`
   Summary: "Checks that the last maintenance date is not later than today." When "Last Maintenance Date" > `Today()`:
   `Error(LastMaintenanceDateFutureErr, "Last Maintenance Date", Today())`. No event (Q10).
4. `internal procedure UpdateLastMaintenanceFromPosting(MaintenanceRecord: Record "EQM Maintenance Record")`
   Summary: "Moves the last maintenance date forward to the date of a posted maintenance record and recalculates the
   next maintenance date, then saves the equipment with triggers. By default only Preventive maintenance updates the
   dates, and only when its date is later than the current last maintenance date. Called by the posting codeunit."
   Steps, in this order:
   1. Local `UpdateSchedule: Boolean` := MaintenanceRecord."Maintenance Type" = Preventive.
   2. Raise `OnBeforeUpdateLastMaintenanceFromPosting(Rec, MaintenanceRecord, UpdateSchedule)`.
   3. When not UpdateSchedule: exit.
   4. When MaintenanceRecord."Maintenance Date" = 0D: exit.
   5. When ("Last Maintenance Date" <> 0D) and (MaintenanceRecord."Maintenance Date" <= "Last Maintenance Date"): exit.
   6. `Validate("Last Maintenance Date", MaintenanceRecord."Maintenance Date")`, then `Modify(true)`.
   No `Confirm`, `Message` or `Commit` (runs inside posting, also without UI).

Trigger changes:
- `OnInsert`: add the call `UpdateNextMaintenanceDate();` directly before the existing `CheckEquipmentConsistency(true);`.
- `OnModify`: add the call `UpdateNextMaintenanceDate();` as the first statement, before
  `CheckEquipmentConsistency(false);`. (Keeps the stored Next date right when code assigns the two input fields
  without `Validate`.)
- `CheckEquipmentConsistency`: add the call `CheckLastMaintenanceDate();` directly after `CheckWarrantyDates();`. Update
  its `/// <summary>`: after "warranty end date later than the warranty start date when both are filled in," insert
  "last maintenance date not later than today,". Nothing else changes.
- `OnDelete`, existing events and existing procedures: no change.

New integration events, placed after `OnBeforeCheckWarrantyDates` and before `OnAfterCheckEquipmentConsistency` (see
Events for signatures and doc comments).

### Codeunit 50109 "EQM Maintenance-Post" (change)
- Local procedure `CompleteEquipmentMaintenance(MaintenanceRecord)`: inside the existing `if Equipment.Get(...) then`,
  replace the single call with a `begin ... end` block that calls, in this order:
  1. `Equipment.UpdateLastMaintenanceFromPosting(MaintenanceRecord);`
  2. `Equipment.CompleteMaintenance(MaintenanceRecord);` (existing call, unchanged).
  Order matters: the schedule is updated even when `CompleteMaintenance` exits early (other open records, or status not
  In Maintenance). The same `Equipment` variable is used for both, so the second `Modify` works on the record the first
  one saved.
- Update the codeunit `/// <summary>`: after "writes a read-only maintenance history entry", insert ", moves the
  equipment's last maintenance date forward for preventive maintenance". Update the `OnAfterPostMaintenanceRecord`
  summary sentence to: "The equipment status and planned maintenance dates have already been updated."
- No other change (no new event, no new permission: the poster already needs Modify on equipment).

### Page 50101 "EQM Equipment Card" (change)
- `area(Content)`: directly after `group(Warranty)` and before `part(AssignmentHistory ...)`, add
  `group(PlannedMaintenance)` with `Caption = 'Planned Maintenance'` and these controls in this order (control name =
  field name; Caption, ToolTip and ApplicationArea inherited):
  - `"Last Maintenance Date"`
  - `"Maintenance Frequency (Months)"` with `Importance = Promoted`
  - `"Next Maintenance Date"` with `Importance = Promoted`
- No triggers on the controls (the table recalculates; the page shows the same record).
- `AboutText` becomes: 'Here you manage one piece of equipment. The first sections show its details, its current status and who it is assigned to, its purchase and warranty information, and its planned maintenance. Use **Assign to Employee** and **Return** to change the assignment, and **Register Maintenance** to record maintenance work. Further down, **Assignment History** lists every assignment, **Maintenance History** lists every posted maintenance, and **Audit** shows who created the record and who changed it last.'

### Page 50100 "EQM Equipment List" (change)
- Repeater, directly after `field("Warranty Reference No."; ...)` and before `field("Total Maintenance Cost"; ...)`, add
  in this order:
  - `"Next Maintenance Date"` (visible, nothing else)
  - `"Last Maintenance Date"` with `Visible = false`
  - `"Maintenance Frequency (Months)"` with `Visible = false`
- `AboutText`: insert after the warranty sentence (before "**Total Maintenance Cost** shows ..."): '**Next Maintenance Date** shows when planned maintenance is due; to find equipment that is due in a period, filter on it with a date range.'
- Views, actions, triggers: no change.

### Page 50115 "EQM Maintenance FactBox" (change, Q8)
The existing calculated control captioned "Last Maintenance Date" (latest record of any type, open or posted) would
carry the same caption as the new stored field with a different meaning. Control names stay; only captions and
ToolTips change:
- `field(LastMaintenanceDate; ...)`: `Caption = 'Latest Record Date'`; ToolTip 'Specifies the date of the most recent maintenance record of the equipment, of any type, open or posted. It is blank when no maintenance has been registered.'
- `field(LastMaintenanceType; ...)`: `Caption = 'Latest Record Type'`; ToolTip 'Specifies the type of the most recent maintenance record of the equipment. It is blank when no maintenance has been registered.'
- New control `field("Next Maintenance Date"; Rec."Next Maintenance Date")` directly after `LastMaintenanceType` and
  before `TotalMaintenanceCost`, nothing else (inherits caption and ToolTip). It is a stored field, so it is shown even
  when the early `exit` in `UpdateFactBox` skips the calculated values.

### app.json, translations
- **app.json: no change.** Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf` (three captions and ToolTips, the error label with
  its comment, the group caption, two AboutTexts, two FactBox captions and ToolTips). The locked label
  `MonthsDateFormulaTok` must not appear as a translatable unit. Commit it; never edit by hand. No inline `CaptionML`.

## Data model and upgrade impact
- Table 50100: three new **stored** fields (21 Date, 22 Date, 23 Integer). Existing rows get 0D / 0D / 0: no planned
  maintenance, which is valid.
- No new key. Filtering on Next Maintenance Date scans table 50100; acceptable for equipment volumes (R4).
- DataClassification: inherited `CustomerContent`; not personal data.
- Upgrade codeunit: **not needed.** Nothing is released, version stays 29.0.0.0. No backfill of Last Maintenance Date
  from posted history (Q9): existing development data keeps blank dates.
- Rename of equipment: the fields are on the equipment record and move with it.
- Posting writes to the equipment record one extra time (only for Preventive records with a later date), under the
  `UpdLock` the posting codeunit already takes.

## Events
**Standard BC events: none.** No events report is required. Subscribed: none.

Published: **two new integration events** on table 50100 (Q10), both `[IntegrationEvent(false, false)]`, `local`:
1. `OnBeforeCalcNextMaintenanceDate(Equipment: Record "EQM Equipment"; var NextMaintenanceDate: Date; var IsHandled: Boolean)`
   - IsHandled: **yes.** A subscriber sets NextMaintenanceDate and IsHandled = true to replace the standard calculation
     (for example to move the date to a working day, or to use a base calendar). Raised on every recalculation, also
     when the inputs are blank.
   - Doc: summary "Raised before the next maintenance date is calculated from the last maintenance date and the
     maintenance frequency, on validation of either field and on insert and modify."; Equipment "The record being
     calculated (passed by value; changes are not kept)."; NextMaintenanceDate "The date to use when IsHandled is
     set."; IsHandled "Set to true to use NextMaintenanceDate instead of the standard calculation."
2. `OnBeforeUpdateLastMaintenanceFromPosting(Equipment: Record "EQM Equipment"; MaintenanceRecord: Record "EQM Maintenance Record"; var UpdateSchedule: Boolean)`
   - No IsHandled: the `var UpdateSchedule` flag is the override (true by default only for Preventive). Setting it to
     true lets, for example, Inspection records reset the schedule; false stops a Preventive record from doing so. The
     "only forward" rule still applies afterwards.
   - Doc: summary "Raised when a maintenance record is posted, before the equipment's last maintenance date is moved
     forward."; Equipment "The equipment (passed by value; changes are not kept)."; MaintenanceRecord "The posted
     record (passed by value)."; UpdateSchedule "True when the record updates the planned maintenance dates. By
     default true only for Preventive maintenance. The date still moves only forward."

Existing events unchanged. Partners can still add rules through `OnAfterCheckEquipmentConsistency`.

## Permissions
No permission set changes.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See the planned maintenance fields (card, list, FactBox) | yes | yes | yes |
| Enter or change Last Maintenance Date and frequency | no (no M on table 50100) | yes | yes |
| Post maintenance (updates the dates) | no (existing) | yes | yes |

## Compatibility
- AppSource mode, development phase: nothing released, no baseline, no Obsolete handling needed.
- New permanent public surface after the first release: fields 21-23 on public table 50100 (names, types, the 0-120
  range) and the two event signatures. Settle Q1, Q4 and Q10 before release.
- Behavior change in public codeunit 50109: posting a Preventive record now also modifies the equipment's planned
  maintenance fields (one extra `Modify(true)` on equipment, which raises `OnAfterCheckEquipmentConsistency` once more).
  Partners subscribing to `OnAfterPostMaintenanceRecord` see the updated equipment. Not a breaking change.
- `CheckEquipmentConsistency` now also rejects a future Last Maintenance Date. Existing records have 0D, so no existing
  record or code path (assign, return, status change, maintenance start/complete) can fail on it.
- UI: FactBox captions renamed (no control renamed or removed), new card group between existing ones, one new visible
  list column. Personalizations stay valid.
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-019-planned-maintenance.md` and `docs/help/FR-019-planned-maintenance.md`: the three fields,
    the calculation with the issue example, month-end behavior, the 0-120 range, the future-date rule, the posting rule
    (Preventive only, forward only), how to find due equipment on the list (date range filter; an "up to" filter also
    shows equipment without a plan, V5), roles, the two events.
  - `docs/help/FR-008-equipment-card.md` / `docs/features/FR-008-equipment-card.md`: new Planned Maintenance section.
  - `docs/help/FR-007-equipment-list-management.md`: new columns.
  - `docs/help/FR-010-maintenance-registration.md` / `docs/features/FR-010-maintenance-registration.md`: FactBox
    captions "Latest Record Date" / "Latest Record Type" and the new Next Maintenance Date.
  - `docs/help/FR-011-maintenance-history.md` (posting section): posting a Preventive record updates the schedule.
  - `README.md`: "Maintenance schedules" row from Planned to built (not verified).
  - `CHANGELOG.md`: new top section `## FR-019 Planned Maintenance (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-019 sandbox checks" with PM-SB1 to PM-SB9.

## Test scenarios
**No automated tests in this iteration** (Q11 default, as in FR-003 to FR-018). Test codeunit 50173 "EQM Planned
Maintenance Tests" is reserved and the tester step is skipped. The list is the reference for the developer, the
reviewer and the tests written later (needs the test-app fix in `docs/TODO.md`).

Test data, unless stated: active category LAPTOP; equipment E1 (LAPTOP, Available, saved with `Insert(true)`, planned
maintenance fields blank/0). T = `Today()`. Dates are written as day month year; scenarios with fixed 2026 dates assume
T is on or after them (otherwise shift all dates into the past by the same amount).

Calculation (PM-R1, PM-R2)
- PM1 (issue example) Given E1, when "Last Maintenance Date" is validated with 1 January 2026 and "Maintenance
  Frequency (Months)" with 6, then "Next Maintenance Date" = 1 July 2026.
- PM2 Given E1, when the last date is validated first and the frequency second (and the reverse order on a second
  record), then both give the same Next date.
- PM3 Given E1 with last 1 January 2026 and frequency 6, when the frequency is validated with 12, then Next = 1 January
  2027.
- PM4 (month end) Given last 31 August 2026 and frequency 6, then Next = 28 February 2027 (V1).
- PM5 Given last 15 March 2026 and frequency 120, then Next = 15 March 2036.
- PM6 Given last 1 January 2026, frequency 6, when the frequency is validated with 0, then Next = 0D.
- PM7 Given last 1 January 2026, frequency 6, when "Last Maintenance Date" is validated with 0D, then Next = 0D.
- PM8 Given E1 with a Purchase Date, when only the frequency 6 is set (no last date), then Next = 0D (Q5).
- PM9 Given E1, when the two input fields are assigned directly (no `Validate`) as 1 January 2026 / 6 and `Modify(true)`
  runs, then the stored Next = 1 July 2026. The same with `Insert(true)` on a new record.
- PM10 `CalcNextMaintenanceDate` on a record in memory (not saved) returns the same value the stored field has after
  save.

Validation (negative)
- PM11 Given E1, when "Last Maintenance Date" is validated with T + 1, then `LastMaintenanceDateFutureErr` is raised with
  both dates in the text and the stored record is unchanged.
- PM12 Given E1, when "Last Maintenance Date" = T is validated, then no error.
- PM13 Given E1, when the last date is assigned directly as T + 1 and `Modify(true)` runs, then the error is raised and
  the stored record is unchanged; with `Insert(true)` on a new record, no record is inserted.
- PM14 Given E1, when the frequency is validated with -1, then the platform MinValue error is raised; with 121, the
  MaxValue error is raised; 0 and 120 are accepted.
- PM15 Given the Equipment Card on E1, then "Next Maintenance Date" is not editable.
- PM16 Given E1 with last date 1 June 2026, when it is changed by hand to 1 January 2026 (backwards), then no error and
  Next is recalculated.

Posting (PM-R3, Q2, Q3)
- PM17 Given E1 with last 1 January 2026, frequency 6, when a Preventive maintenance record dated 1 March 2026 is
  registered and posted, then Last = 1 March 2026, Next = 1 September 2026, and the equipment is Available (existing
  behavior).
- PM18 Given E1 with blank last date and frequency 6, when a Preventive record dated D is posted, then Last = D and
  Next = D + 6 months.
- PM19 Given E1 with blank last date and frequency 0, when a Preventive record is posted, then Last = its date and
  Next = 0D.
- PM20 (negative, type) Given E1 with last 1 January 2026, when a Corrective (and in separate runs an Inspection and an
  Upgrade) record dated 1 March 2026 is posted, then Last and Next do not change.
- PM21 (negative, backwards) Given E1 with last 1 June 2026, when a Preventive record dated 1 March 2026 is posted, then
  Last stays 1 June 2026. The same when the record's date equals the last date (no extra modify).
- PM22 (negative, registration only) Given E1, when a Preventive record is registered but not posted, then Last and Next
  do not change.
- PM23 Given E1 with two open Preventive records dated 1 March and 1 April 2026, when the 1 April record is posted
  first, then Last = 1 April and the equipment stays In Maintenance; when the 1 March record is posted next, then Last
  stays 1 April and the equipment becomes Available.
- PM24 Given E1 set to Disposed while a Preventive record is open, when the record is posted, then Last is updated, no
  error is raised and the status stays Disposed (Q12).
- PM25 Given posting fails after the schedule update (a test subscriber to `OnAfterPostMaintenanceRecord` raises an
  error), then the equipment's Last and Next are unchanged (transaction rolled back).

Events
- PM26 Given a manual-binding subscriber to `OnBeforeCalcNextMaintenanceDate` that sets NextMaintenanceDate = 31
  December 2030 and IsHandled = true, when the frequency is validated, then Next = 31 December 2030; after unbinding,
  the standard value returns on the next validation.
- PM27 Given a subscriber to `OnBeforeUpdateLastMaintenanceFromPosting` that sets UpdateSchedule = true for Inspection,
  when an Inspection record with a later date is posted, then Last is updated; a subscriber setting it to false stops a
  Preventive record from updating Last.

Regression
- PM28 Given E1 with a schedule, when it is assigned and returned, then both succeed and the three fields are
  unchanged.
- PM29 Given E1 with a schedule, when it is renamed to E1-NEW, then E1-NEW has the same three values.
- PM30 Given E1 with a valid warranty and a schedule, then the warranty rule (FR-014) and the FR-017 overdue rule behave
  as before.

Pages (TestPage)
- PM31 Equipment Card (Manager): group Planned Maintenance shows Last Maintenance Date, Maintenance Frequency (Months),
  Next Maintenance Date in this order; the first two are editable; entering 1 January 2026 and 6 shows 1 July 2026
  without reopening the page.
- PM32 Equipment List: Next Maintenance Date is visible; Last and frequency exist but are hidden; a filter on Next
  Maintenance Date `1 July 2026..31 July 2026` shows only equipment due in that range and no equipment with a blank
  Next date (V5).
- PM33 Maintenance FactBox: captions "Latest Record Date" and "Latest Record Type"; Next Maintenance Date is shown, also
  for equipment without maintenance records.

Permissions (`TestPermissions = Restrictive`, with D365 BASIC)
- PM34 Reader: sees the fields; changing the frequency and saving raises a permission error.
- PM35 Manager: enters and changes the fields; posting a Preventive record updates them without a permission error.

### Manual sandbox checks (for the user)
- PM-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` has the new texts and not the
  locked date formula token (V2, V3).
- PM-SB2 Publish over existing development data: no schema sync error; existing equipment shows blank fields (V4).
- PM-SB3 Reproduce the issue example on the card: 1 January 2026 + 6 months = 1 July 2026, in the regional date format.
- PM-SB4 Month end: 31 August 2026 + 6 = 28 February 2027 (V1); record the result.
- PM-SB5 A future last date gives the error with readable dates.
- PM-SB6 Register and post a Preventive record: Last and Next update; a Corrective record does not change them.
- PM-SB7 Equipment List: Next Maintenance Date column; date range filter (and an "up to" filter, to record V5);
  hidden columns via personalization.
- PM-SB8 Maintenance FactBox shows the new captions and Next Maintenance Date.
- PM-SB9 Non-SUPER Reader cannot change the fields; non-SUPER Manager can and can post. Teaching tips of the card and
  list show the new texts.

## Risks and open questions
Open questions (each has the default used in this plan; answer to change it):
- **Q1 Next Maintenance Date: calculated or editable.** Default: calculated, stored, `Editable = false`, recalculated on
  every change and save. Alternative: editable with the calculation as a proposal (a manual override is overwritten when
  the inputs change, or needs an extra "manual" flag). **Changes the design.**
- **Q2 Posting updates Last Maintenance Date.** Default: yes, automatically, forward only. Alternative: fields are
  maintained by hand only (the codeunit 50109 change and the second event drop out). **Changes the design.**
- **Q3 Which maintenance types reset the schedule.** Default: Preventive only; partners change it through
  `OnBeforeUpdateLastMaintenanceFromPosting`. Alternatives: Preventive and Inspection; all types. **Changes the design**
  (rule in `UpdateLastMaintenanceFromPosting`, PM20).
- **Q4 Frequency unit and range.** Default: whole months, 0-120, 0 = no plan. Alternative: another range or a
  DateFormula.
- **Q5 Base date when Last Maintenance Date is blank.** Default: none (Next blank). Alternative: Purchase Date as
  fallback.
- **Q6 Last Maintenance Date rules.** Default: not in the future; manual backwards change allowed; no comparison with
  Purchase Date or history.
- **Q7 Scope.** Default: fields, calculation and the posting update only. Follow-ups: "Maintenance Due/Overdue" status
  with style, list view, dashboard tile, FR-017 notification and FR-018 job check based on Next Maintenance Date,
  creating maintenance records from the plan.
- **Q8 FactBox caption clash.** Default: rename the two FactBox captions to "Latest Record Date/Type" and add Next
  Maintenance Date. Alternatives: remove the calculated FactBox controls, or leave the clash.
- **Q9 Backfill from history.** Default: none (nothing released).
- **Q10 Events.** Default: the two events above. Alternatives: none, or only the calculation event. Permanent after
  release.
- **Q11 Automated tests.** Default: deferred; test codeunit 50173 reserved; tester step skipped; PM-SB1 to PM-SB9 are
  the verification.
- **Q12 Lost and Disposed equipment.** Default: no special rule; fields editable, posting still updates.

Risks:
- R1 `Modify(false)`, `Insert(false)` or direct assignment without save bypass the recalculation and the future-date
  check, as for every other consistency rule of table 50100. Accepted.
- R2 Next Maintenance Date is stored: a change in the calculation (an event subscriber installed later, or a rule
  change) does not update existing records until they are modified. Accepted; a later version could add a recalculation
  action or an upgrade step.
- R3 Two `Modify(true)` calls on equipment during posting raise `OnAfterCheckEquipmentConsistency` twice; a partner
  subscriber that is not idempotent could misbehave. Low.
- R4 No index on Next Maintenance Date; filters scan table 50100. Acceptable for equipment volumes.
- R5 Fields 21-23 and the two events become permanent API at the first release (settle Q1, Q4, Q10).
- R6 No automated tests (Q11): regressions are caught only by review and sandbox checks.
- R7 Time zone: `Today()` in the future-date check is the session date, same as the maintenance record rule.
