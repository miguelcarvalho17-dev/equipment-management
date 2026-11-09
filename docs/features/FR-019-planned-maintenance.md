# FR-019 Planned Maintenance

## Purpose
Users plan recurring maintenance per piece of equipment: they enter how often it must be maintained (in months) and when it was last maintained, and the app calculates the next maintenance date. Posting a Preventive maintenance record moves the last maintenance date forward automatically. Example: last maintenance 1 January 2026 and frequency 6 months give a next maintenance date of 1 July 2026.

Status: describes the code as implemented (uncommitted changes on branch `feature/FR-019-planned-maintenance`, GitHub issue #38). The code compiles with CodeCop and UICop with no diagnostics. AppSourceCop shows only the 8 project-level app.json/config errors that already exist on `main`; none comes from FR-019. **No automated tests (deferred, plan decision Q11; test codeunit 50173 reserved, nothing written). Nothing is verified in a sandbox (no BC sandbox available); the platform checks V1 to V4 and sandbox checks PM-SB1 to PM-SB9 are open.** App version stays 29.0.0.0. No new objects, no upgrade codeunit, no standard events subscribed, no events report, no permission set change.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50100 | EQM Equipment | Fields 21 to 23; procedures `CalcNextMaintenanceDate`, `UpdateLastMaintenanceFromPosting` (internal), `UpdateNextMaintenanceDate`, `CheckLastMaintenanceDate` (local); two published events; trigger calls |
| Codeunit | 50109 | EQM Maintenance-Post | `CompleteEquipmentMaintenance` also calls `Equipment.UpdateLastMaintenanceFromPosting` |
| Page | 50101 | EQM Equipment Card | New group Planned Maintenance (after Warranty); AboutText |
| Page | 50100 | EQM Equipment List | Three columns (only Next Maintenance Date visible); AboutText |
| Page | 50115 | EQM Maintenance FactBox | Two captions renamed, new control Next Maintenance Date |

### New fields on table 50100
| ID | Name | Type | Meaning |
|---|---|---|---|
| 21 | Last Maintenance Date | Date | Date the equipment was last maintained. Entered by the user or set by posting. Cannot be later than today. Validation checks the date, then recalculates field 22. |
| 22 | Next Maintenance Date | Date | `Editable = false`. Stored (can be filtered and sorted). Last Maintenance Date plus Maintenance Frequency (Months). Blank when either is missing. |
| 23 | Maintenance Frequency (Months) | Integer | `MinValue = 0`, `MaxValue = 120`, `BlankZero = true`. Whole months; 0 (shown blank) means no planned maintenance. Validation recalculates field 22. |

The fields inherit `DataClassification = CustomerContent` from the table. No key, no TableRelation. Existing rows get blank dates and 0.

## Behavior
**Calculation.** `CalcNextMaintenanceDate()` raises `OnBeforeCalcNextMaintenanceDate`; if a subscriber sets IsHandled, its date is returned. Otherwise it returns 0D when Last Maintenance Date is blank or the frequency is 0 or less, and else `CalcDate('<nM>', "Last Maintenance Date")` with n the frequency. The Purchase Date is not used as a fallback. `UpdateNextMaintenanceDate` stores the result in field 22. It runs on validation of fields 21 and 23, at the start of `OnInsert` (before `CheckEquipmentConsistency(true)`) and as the first statement of `OnModify`, so direct assignment followed by `Insert(true)`/`Modify(true)` also yields the right Next date. `Insert(false)` and `Modify(false)` skip it.

**Month end.** The platform month arithmetic is expected to clamp to the last day of a shorter month (31 August 2026 + 6 months = 28 February 2027). TODO(verify) V1 / PM-SB4: not run.

**Future date rule.** `CheckLastMaintenanceDate` raises 'The last maintenance date %1 is in the future. Enter a date that is not later than today (%2).' when Last Maintenance Date is later than `Today()`. It runs on validation of field 21 and in `CheckEquipmentConsistency` (after `CheckWarrantyDates`). No event. Moving the date backwards by hand is allowed; it is not compared with the Purchase Date or with maintenance history.

**Posting.** `CompleteEquipmentMaintenance` in codeunit 50109 gets the equipment with `UpdLock`, calls `UpdateLastMaintenanceFromPosting(MaintenanceRecord)` and then the existing `CompleteMaintenance`. The schedule is therefore updated even when `CompleteMaintenance` exits early (other open records, or status not In Maintenance). `UpdateLastMaintenanceFromPosting`:
1. `UpdateSchedule` is true when the record's Maintenance Type is Preventive.
2. Raises `OnBeforeUpdateLastMaintenanceFromPosting`; exits when `UpdateSchedule` is false.
3. Exits when the record's Maintenance Date is blank, or when Last Maintenance Date is filled and the record's date is not later than it (the date never moves backwards through posting).
4. `Validate("Last Maintenance Date", record date)` and `Modify(true)`.

Corrective, Inspection and Upgrade records do not change the dates unless a subscriber sets `UpdateSchedule`. Registering a record changes nothing; only posting does. No `Confirm`, `Message` or `Commit`. Lost and Disposed equipment have no special rule: the fields stay editable and posting still updates them.

### Pages
- **Equipment Card (50101):** group Planned Maintenance with Last Maintenance Date, Maintenance Frequency (Months) (Promoted) and Next Maintenance Date (Promoted, read-only).
- **Equipment List (50100):** Next Maintenance Date visible; Last Maintenance Date and Maintenance Frequency (Months) hidden by default (shown through personalization). No due or overdue status, style, view, tile, notification or job exists for planned maintenance.
- **Maintenance FactBox (50115):** the calculated controls were renamed from 'Last Maintenance Date' / 'Last Maintenance Type' to 'Latest Record Date' / 'Latest Record Type' (most recent record of any type, open or posted) to avoid a clash with the new stored field. New control Next Maintenance Date (stored field, so it shows even for equipment without maintenance records).

## Setup
No setup. Enter the frequency (and a last maintenance date if work was done before) on the Equipment Card.

## Extending (events)
Both are `[IntegrationEvent(false, false)]`, `local` procedures on table 50100.

| Event | Raised | Parameters | Subscriber may |
|---|---|---|---|
| `OnBeforeCalcNextMaintenanceDate(Equipment, var NextMaintenanceDate, var IsHandled)` | On every calculation: validation of fields 21 and 23, insert and modify, also when the inputs are blank. | Equipment: record being calculated, by value (changes are not kept). NextMaintenanceDate: date used when IsHandled is set. IsHandled. | Set NextMaintenanceDate and IsHandled = true to replace the standard calculation (for example move to a working day). |
| `OnBeforeUpdateLastMaintenanceFromPosting(Equipment, MaintenanceRecord, var UpdateSchedule)` | When a maintenance record is posted, before the date is moved. | Equipment and MaintenanceRecord by value. UpdateSchedule: true by default only for Preventive. | Set true so other types (for example Inspection) update the schedule, or false to stop Preventive. The forward-only rule still applies afterwards. |

`OnAfterCheckEquipmentConsistency` (existing) still lets partners add rules. `OnAfterPostMaintenanceRecord` (codeunit 50109, existing) now sees equipment whose planned maintenance dates are already updated. No standard events are subscribed.

## Permissions
No permission set changes. Existing sets cover the fields: 50100 EQM - Reader (R on table 50100), 50101 EQM - Manager (RIM), 50102 EQM - Administrator (includes Manager).

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See the fields (card, list, FactBox) | yes | yes | yes |
| Enter or change Last Maintenance Date and frequency | no | yes | yes |
| Post maintenance (updates the dates) | no | yes | yes |

From code reading, not a sandbox run (PM-SB9).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand. The locked label `MonthsDateFormulaTok` does not appear in the file (checked by search). TODO(verify) the full set of new texts in PM-SB1.

## Upgrade and compatibility
Three new stored fields, no upgrade codeunit (nothing released), no backfill from posted history. Public surface that becomes permanent at release: fields 21 to 23 on public table 50100 (names, types, the 0 to 120 range) and the two event signatures. Posting a Preventive record with a later date now makes one extra `Modify(true)` on the equipment, which raises `OnAfterCheckEquipmentConsistency` once more. Existing records have blank dates, so the new future-date check cannot fail them.

## Known limitations
- Next Maintenance Date is stored: if a subscriber or rule changes later, existing records are only recalculated when modified.
- `Insert(false)`, `Modify(false)` or direct assignment without a save skip the calculation and the future-date check.
- No index on Next Maintenance Date; filtering scans the equipment table.
- A date filter `..D` also includes blank dates, a range `D1..D2` does not (V5, not verified).
- `Today()` is the session date.
- One schedule per equipment; no due/overdue status, alerts, or creation of maintenance records from the plan.

## Test status
No test objects; test codeunit 50173 "EQM Planned Maintenance Tests" is reserved. Scenarios PM1 to PM35 in docs/plans/FR-019-planned-maintenance.md are a reference only. **Sandbox checks PM-SB1 to PM-SB9 are not run.**

TODO(verify) in a sandbox: schema sync over existing data (V4, PM-SB2); issue example and regional date format (PM-SB3); month-end result (V1, PM-SB4); future-date error text (PM-SB5); posting Preventive versus Corrective (PM-SB6); list filtering and personalization (PM-SB7); FactBox (PM-SB8); Reader/Manager permissions and teaching tips (PM-SB9); that the 30-character field name "Maintenance Frequency (Months)" and the MinValue/MaxValue errors behave as expected (V2, V3; the compiler accepted the name).

## Discrepancies plan vs code
- None in behavior. The plan's wording on the doc updates to FR-007, FR-008, FR-010, FR-011, README.md and docs/TODO.md was not part of this step; see the report.
