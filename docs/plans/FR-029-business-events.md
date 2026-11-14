# FR-029 Business Events

> Status: **Approved**. The user approved Q1 = daily and Q2 = all (approved 2026-11-14). Source: GitHub issue #67. Branch `feature/FR-029-business-events`. No base app behavior is touched: only this app's own objects, plus the platform trigger events `OnAfterInsertEvent` on its own tables 50100 and 50105. So no events report is needed (same reasoning as FR-028).
> **Open questions (the plan uses the recommended default, so the answer can be one word):**
> - **Q1 OnWarrantyExpired detection.** Options: **daily** (recommended) or **tracked**. *Daily:* the scheduled warranty job raises the event for equipment whose warranty ended yesterday. There is no schema change, but the event is missed for any day the job does not run. *Tracked:* a new field on table 50100 remembers which end date was already raised, so the job raises each expiry exactly once and catches up on missed days. This needs a new field and an upgrade codeunit, so that equipment that has already expired does not raise a burst of events on the first run.
> - **Q2 Scope of OnEquipmentReturned.** Options: **all** (recommended) or **action**. *All:* the event is raised whenever an active assignment is closed: by the Return action, by registering maintenance, or by setting the status to Lost or Disposed. `Equipment.Status` tells subscribers why. *Action:* the event is raised only by the Return action (UnassignEmployee), so subscribers that track who holds what would miss the other two ways.

## Goal
Publish five integration events: OnEquipmentCreated, OnEquipmentAssigned, OnEquipmentReturned, OnMaintenanceCreated and OnWarrantyExpired. Partner extensions can react to these business moments without changing this app. The events only notify: they are raised after the fact and cannot change or skip the standard logic.

## Approach and rejected alternatives
- Chosen: one new public publisher codeunit "EQM Business Events". It contains only the five `[IntegrationEvent(false, false)]` publishers, declared as `internal procedure`. Subscribers anywhere can subscribe, but only this app can raise them. The call sites are: a new internal subscriber codeunit on `OnAfterInsertEvent` of Equipment and Maintenance Record (created events, so the record is already stored); codeunit 50106 at the points where assignment entries are inserted or closed (assigned/returned); and a new procedure in the warranty alert codeunit 50110, called by the daily job 50111 (warranty expired).
- Rejected: declaring the events in the objects where they are raised (tables 50100/50105, codeunits 50106/50110). The five events would be spread over four objects, and 50110 is Internal, so it cannot be subscribed to from outside the app.
- Rejected: raising "created" at the end of the table `OnInsert` triggers. The row is not stored yet at that point, so a subscriber's `Get` fails.
- Rejected: raising assigned/returned in `AssignEmployee`/`UnassignEmployee` on the table. That misses the closes made by registering maintenance and by setting Lost/Disposed (Q2), and paths such as the API.
- Rejected: `IsHandled` parameters and `[ExternalBusinessEvent]`. Overrides already exist through the OnBefore* events, and the issue asks for integration events (see Risks).

## Objects
IDs in use (checked in `app/src` and `test/src`): codeunits 50103-50118 (50123-50129 are reserved by FR-026 C10), test codeunits 50178-50183 (50150-50177 are reserved). The next free IDs are taken after the highest ID in use, as earlier plans did.
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Codeunit | 50119 | EQM Business Events | New | `Access = Public`, no other procedures. The five publishers. File `app/src/BusinessEvents/EQMBusinessEvents.Codeunit.al` |
| Codeunit | 50120 | EQM Business Event Subscr. | New | `Access = Internal`. Raises the two created events from `OnAfterInsertEvent`. File `app/src/BusinessEvents/EQMBusinessEventSubscr.Codeunit.al` |
| Codeunit | 50106 | EQM Assignment Mgt. | Modify (own) | Raises the assigned and returned events |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | Modify (own) | New internal procedure `RaiseWarrantyExpiredEvents(ReferenceDate: Date): Integer` |
| Codeunit | 50111 | EQM Warranty Alert Job | Modify (own) | Calls the new procedure after `GenerateAlerts` |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | X on 50119 and 50120 |
| Codeunit (test) | 50184 | EQM Business Events Tests | New | Scenarios 1-12. File `test/src/EQMBusinessEventsTests.Codeunit.al` |
| Codeunit (test) | 50185 | EQM Business Event Test Subscr. | New | `EventSubscriberInstance = Manual`. Counts each event and keeps the parameters of the last raise, plus a flag that tells whether the record was found in the database |

## Data model and upgrade impact
- No new tables or fields and no upgrade codeunit (with Q1 = daily). `app.json` does not change. If Q1 = tracked, this section must be replanned: new field 25 on table 50100 (CustomerContent) plus an upgrade codeunit with an upgrade tag.

## Events
- Subscribed (in 50120): Table "EQM Equipment" `OnAfterInsertEvent`, and Table "EQM Maintenance Record" `OnAfterInsertEvent`. Guard order: exit if `Rec.IsTemporary()`, exit if not `RunTrigger`, then raise. Make no DB calls.
- Published (in 50119). No `IsHandled` (they only notify) and no `var` (records are passed by value). Each publisher gets XML docs that state when it is raised, the state of the record, and "no UI, no Commit":
  1. `OnEquipmentCreated(Equipment: Record "EQM Equipment")`. Raised after a non-temporary `Insert(true)`; the record is stored.
  2. `OnEquipmentAssigned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")`. Raised in 50106 `CreateAssignment`, right after `EquipmentAssignment.Insert(true)`. The entry is stored. `Equipment` has the new values (Assigned, employee), but its database row is written only after the event. The doc must say: do not Modify the equipment in the subscriber.
  3. `OnEquipmentReturned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")`. Raised in 50106 `CloseActiveAssignments`, right after each `EquipmentAssignment.Modify(true)`. The entry is Closed. `Equipment.Status` shows the reason (Available, In Maintenance, Lost or Disposed). The same "do not Modify" note applies.
  4. `OnMaintenanceCreated(MaintenanceRecord: Record "EQM Maintenance Record")`. Raised after a non-temporary `Insert(true)`. The record is stored, and the equipment is already In Maintenance.
  5. `OnWarrantyExpired(Equipment: Record "EQM Equipment")`. Raised by the daily warranty job, in the job queue session, for equipment whose Warranty End Date = reference date - 1 (the first day CalcWarrantyStatus returns Expired) and whose status is not final.

## Permissions
- EQM - Reader: append `codeunit "EQM Business Events" = X` and `codeunit "EQM Business Event Subscr." = X` after `codeunit "EQM Monitoring Job Mgt." = X` (move the `;` to the last line). Manager and Administrator inherit them. No tabledata changes.

## Compatibility
- Additive only. **Contract at the first AppSource release:** the codeunit name and ID, the five event names, and their parameter lists, types and order are frozen. Changing them later needs a new event plus `Obsolete` on the old one. The "raised when" rules are documented behavior too.
- **Breaking-change risk (low), flagged:** steps 3-5 change codeunit 50106 (Access = Public, but only local procedures change) and codeunits 50110/50111 (internal and job). No signature changes. The existing events OnBeforeInsertAssignment and OnBeforeCloseAssignment stay unchanged.

## Implementation steps
1. Create codeunit 50119 with the five publishers (signatures and docs as in Events, empty bodies). Compile.
2. Create codeunit 50120 with the two subscribers and the guards from Events. Each one calls the matching publisher. Compile.
3. In 50106: declare a local `BusinessEvents: Codeunit "EQM Business Events"` in `CreateAssignment` and in `CloseActiveAssignments`, and raise OnEquipmentAssigned / OnEquipmentReturned right after the Insert / Modify (inside the loop). Compile.
4. In 50110: add `RaiseWarrantyExpiredEvents(ReferenceDate: Date): Integer`. Treat 0D as Today(). Filter Equipment on `"Warranty End Date" = ReferenceDate - 1` (no SetLoadFields, because the full record goes to subscribers). Skip final statuses, raise OnWarrantyExpired for each remaining equipment, and return the count. Add XML docs. Compile.
5. In 50111 `OnRun`: after `GenerateAlerts`, call `Commit()` with a comment stating the reason (a failing partner subscriber must not roll back the alerts), then call `RaiseWarrantyExpiredEvents(Today())`. Manual alert generation does not raise the event. Compile.
6. Add the Permissions lines. Build the main app, and commit the `.g.xlf` if it changes.
7. Create test codeunit 50185 (manual subscribers that record count, last No./Entry No./Status, and whether `Get` found the record) and test codeunit 50184. Follow the 50180/50182 patterns: Subtype Test, TestPermissions Disabled, AutoRollback, `Library Assert`, a ConfirmHandler, Locked labels with prefix `EQMBEV`, an Initialize that sets up the Equipment Nos. and Maintenance Nos. series, and BindSubscription in each test. Build the test app.
8. Documenter: write `docs/features/FR-029-business-events.md` and `docs/help/FR-029-business-events.md` (help for developers: event list, signatures, when each event is raised, a subscriber example in text). Add a CHANGELOG section at the top and a `docs/TODO.md` section with sandbox scenario 13.

## Test scenarios
Setup: active category, active employee E1, and Available equipment EQ (inserted with `Insert(true)` before the subscriber is bound, unless the scenario says otherwise).
1. Given the bound subscriber, when new equipment is inserted with Insert(true), then OnEquipmentCreated is raised once with its No., and the record is found in the database.
2. (neg) Given the bound subscriber, when equipment is inserted with Insert(false), and when a temporary equipment record is inserted with Insert(true), then OnEquipmentCreated is not raised.
3. (neg) Given equipment without a category, when Insert(true) fails (asserterror), then OnEquipmentCreated was not raised.
4. Given EQ, when AssignEmployee(E1) runs, then OnEquipmentAssigned is raised once, with Equipment.Status Assigned and employee E1, and the entry is the stored Active entry of EQ.
5. Given EQ assigned to E1, when UnassignEmployee runs (confirm Yes), then OnEquipmentReturned is raised once, with Equipment.Status Available and the entry Closed. OnEquipmentAssigned is not raised.
6. Given EQ assigned to E1, when a maintenance record is inserted for EQ, then OnEquipmentReturned is raised once with Status In Maintenance, and OnMaintenanceCreated is raised once with the record's No., found in the database.
7. Given EQ assigned to E1, when its status is validated to Lost and the record is modified (confirm Yes), then OnEquipmentReturned is raised once with Status Lost.
8. (neg) Given EQ assigned, when UnassignEmployee is answered No, then no event is raised. When the Description of the assigned EQ is changed and modified, then no event is raised.
9. (neg) Given EQ with an open maintenance record, when AssignEmployee fails (asserterror), then OnEquipmentAssigned was not raised.
10. (neg) Given an open maintenance record, when it is modified and then posted, then OnMaintenanceCreated is not raised again (count stays 0 after binding).
11. Given reference date R and equipment W1 (end R-1), W2 (end R), W3 (end R-2), W4 (end R-1, Disposed) and W5 (no end date), when RaiseWarrantyExpiredEvents(R) runs, then the event is raised only for W1 and the procedure returns 1.
12. (neg) Given W1 (end R-1), when GenerateAlerts(R, false, ...) runs, then OnWarrantyExpired is not raised.
13. Sandbox: a scheduled warranty job run succeeds, creates the alerts as before, and raises OnWarrantyExpired (checked with a small test extension or the debugger).

## Risks and open questions
- Q1 and Q2: see the top of this plan. The plan follows the recommended defaults.
- Assumed `[IntegrationEvent]` rather than `[ExternalBusinessEvent]` (Power Automate) because the issue names IntegrationEvent explicitly. External business events can be added later as an additive change.
- Assumed the created events skip `Insert(false)`, because that path bypasses the numbering and validation (it is used for data migration).
- Assumed final-status equipment raises no OnWarrantyExpired, to match the warranty alerts (FR-016).
- Assumed codeunit IDs 50119/50120 (the next IDs after the highest in use) rather than the unused 50100-50102, because earlier plans always took the next free ID after the highest.
- Risk: subscribers run inside the caller's transaction. An error in a partner subscriber stops the assign, return, insert or maintenance registration. This is the standard behavior of integration events and is documented in the XML docs.
- Risk (Q1 = daily): a missed job day means a missed event, and running the job codeunit twice on the same day raises the event twice. Both are documented in the help.
- Unverified: step 5 (Commit in the job) cannot be covered by AutoRollback tests. It is covered by sandbox scenario 13.
