# FR-029 Business Events

## Purpose
Five integration events let partner extensions react to business moments (equipment created, assigned, returned, maintenance created, warranty expired) without changing this app (GitHub issue #67). The events only notify: they are raised after the fact and cannot change or skip the standard logic. There is no `IsHandled` and no `var` parameter.

Status: implemented on branch `feature/FR-029-business-events`. App version stays 29.0.0.0. No new table, field or upgrade code. No base app behavior is touched, so there is no events report (platform trigger events on the app's own tables only).

## Verification status
- **Build:** TODO(verify): the documenter did not run the build; only `///` comments were reviewed, no AL line was changed. Build result as reported by the caller.
- **Tests:** 12 automated scenarios pass in AL-Go CI (105 tests in total, 0 failed).
- **Not verified:** scenario 13 (manual sandbox check): a scheduled warranty job run succeeds, creates the alerts as before, raises OnWarrantyExpired, and the `Commit()` in the job behaves as intended. It cannot be covered by AutoRollback tests.
- TODO(verify): permissions per role in a sandbox.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Codeunit | 50119 | EQM Business Events | New, `Access = Public`, the five publishers only. `app/src/BusinessEvents/EQMBusinessEvents.Codeunit.al` |
| Codeunit | 50120 | EQM Business Event Subscr. | New, `Access = Internal`. Raises the two created events from `OnAfterInsertEvent`. `app/src/BusinessEvents/EQMBusinessEventSubscr.Codeunit.al` |
| Codeunit | 50106 | EQM Assignment Mgt. | Raises assigned and returned in `CreateAssignment` and `CloseActiveAssignments` (local procedures) |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | New internal procedure `RaiseWarrantyExpiredEvents(ReferenceDate: Date): Integer` |
| Codeunit | 50111 | EQM Warranty Alert Job | `OnRun` calls `GenerateAlerts`, then `Commit()`, then `RaiseWarrantyExpiredEvents(Today())` |
| PermissionSet | 50100 | EQM - Reader | `codeunit "EQM Business Events" = X`, `codeunit "EQM Business Event Subscr." = X` |
| Codeunit (test app) | 50184 | EQM Business Events Tests | New, scenarios 1 to 12 |
| Codeunit (test app) | 50185 | EQM Business Event Test Subscr. | New, manual subscriber that records raises |

## Events
Published in codeunit 50119. All are `[IntegrationEvent(false, false)]` and declared `internal procedure`: **partners can subscribe but cannot raise them**. Records are passed by value.

| Event | Parameters | Raised |
|---|---|---|
| `OnEquipmentCreated` | `Equipment: Record "EQM Equipment"` | After a non-temporary `Insert(true)`. The record is stored. Not raised for `Insert(false)` (data migration) or temporary records. |
| `OnEquipmentAssigned` | `Equipment`, `EquipmentAssignment: Record "EQM Equipment Assignment"` | In `CreateAssignment`, right after the Active entry is inserted. |
| `OnEquipmentReturned` | `Equipment`, `EquipmentAssignment` | In `CloseActiveAssignments`, right after each entry is modified to Closed. |
| `OnMaintenanceCreated` | `MaintenanceRecord: Record "EQM Maintenance Record"` | After a non-temporary `Insert(true)`. The record is stored and the equipment is already In Maintenance. Not raised on modify or post. |
| `OnWarrantyExpired` | `Equipment` | By the daily warranty job, for equipment whose Warranty End Date is the reference date minus 1 and whose status is not final. |

Subscribed (codeunit 50120): `OnAfterInsertEvent` of "EQM Equipment" and "EQM Maintenance Record". Guards: exit if `Rec.IsTemporary()`, exit if not `RunTrigger`. No database calls.

### Transaction behavior (assigned and returned)
- Both are raised while the equipment is being saved: the assignment entry is written, the equipment row is not yet. The operation can still fail and be rolled back. Subscribers must read the equipment from the parameter, not from the database, must not `Modify` it, and must queue non-transactional calls (HTTP, telemetry).
- Returned is raised for every way an active entry is closed: the Return action, registering maintenance (Status In Maintenance; raised inside the Maintenance Record insert, before that record is stored), setting the status to Lost or Disposed, and a new assignment that closes a leftover Active entry (Status Assigned). `Equipment.Status` tells the reason.
- Created and maintenance-created events run after the insert, inside the caller's transaction. An error in a subscriber stops the operation that raised the event.

### OnWarrantyExpired delivery
- Raised once per day by job codeunit 50111 for equipment with Warranty End Date = `Today() - 1`, the first day the warranty status is Expired. Manual alert generation does not raise it.
- The job calls `Commit()` after `GenerateAlerts` so that a failing subscriber cannot roll back the alerts.
- A day the job does not run is lost; there is no catch-up. Running the job again the same day, or a job queue entry with Maximum No. of Attempts > 1 after a failure, raises the event again for the same equipment.
- An error in a subscriber stops the remaining equipment (no event for them) and puts the job queue entry in Error. The alerts are already saved.
- Equipment is read without `SetLoadFields`, so subscribers get the full record. `RaiseWarrantyExpiredEvents` treats `0D` as today and returns the number of events raised.
- Possible later chore: a key on Warranty End Date, to avoid a table scan in the job (not done).

## Permissions
EQM - Reader has execute on codeunits 50119 and 50120; Manager and Administrator inherit it. No tabledata changes. Expected from the permission sets; not checked in a sandbox.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build. Never edit by hand.

## Compatibility
Additive. **Contract at the first AppSource release:** the codeunit name and ID, the five event names, and their parameter lists, types and order are frozen. A change needs a new event plus `Obsolete` on the old one. The "raised when" rules above are documented behavior. Existing events `OnBeforeInsertAssignment` and `OnBeforeCloseAssignment` in 50106 are unchanged.

## Test status
Codeunit 50184 (`test/src/EQMBusinessEventsTests.Codeunit.al`, AutoRollback) with manual subscriber 50185 covers plan scenarios 1 to 12: created (Insert(true), Insert(false), temporary, failed insert), assigned (and not raised when assign fails), returned (Return action, maintenance, Lost, declined confirm, unrelated modify), maintenance-created (not raised on modify or post), and warranty-expired (only W1 raised, count 1; not raised by `GenerateAlerts`). All pass in AL-Go CI; 105 tests in total, 0 failed. Scenario 13 is manual and not done.

## XML documentation
Present on all five publishers in codeunit 50119 and on `RaiseWarrantyExpiredEvents` in 50110.

## Discrepancies plan vs code
- None found in the objects, signatures and call sites. TODO(verify): the plan step to add a `docs/TODO.md` section for scenario 13 was not part of this task.
