# FR-030 Event Subscribers

> Status: **Approved** by the user. Source: GitHub issue #68. Branch `feature/FR-030-event-subscribers`. Only this app's own publishers (codeunit 50119, FR-029) are subscribed; no standard BC event is needed, so no events report is needed.
> **Decisions:** Q1 **outbox** (build only the external-sync gap; notifications stay with FR-017/FR-031, audit with NFR-005/FR-035), Q2 **setup** (Boolean on Equipment Setup, off by default), Q3 **api** (API entity `integrationEvents` with bound action `markProcessed`, API page 50126).

## Goal
Demonstrate event-driven, loosely coupled design: a new Integration module subscribes to the five FR-029 business events and writes one outbox entry per event, in the same transaction as the business operation. External systems read pending entries through an API and mark them processed. No existing business code changes.

## Approach and rejected alternatives
- Chosen: transactional outbox. Thin internal subscriber codeunit on the five events of 50119 -> internal mgt. codeunit -> append-only table 50110. An entry exists only when the operation commits (rollback removes it), which is what the FR-029 docs ask for ("do not make non-transactional calls; queue them instead").
- Rejected: HTTP call to an external system in the subscriber: runs inside the caller's transaction, not rolled back, blocks the user, fails in tests.
- Rejected: an interface + extensible enum "dispatcher": speculative; no second implementation exists. Can be added later on top of the outbox.
- Rejected: notification and audit subscribers now (Q1): duplicate FR-017/NFR-005/table 50103 and pre-empt FR-031/FR-035.
- Rejected: standard events (e.g. Job Queue, Change Log): not needed; our own publishers carry all data.

## Objects
IDs in use (checked `app/src`, `test/src`): tables 50100-50109, enums 50100-50108, codeunits 50103-50120 (50123-50129 reserved API), pages 50100-50125 and 50130-50131 (50126-50129 reserved API), test codeunits 50178-50185 (50150-50177 reserved).
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50109 | EQM Integration Event Type | New | 0 Equipment Created, 1 Equipment Assigned, 2 Equipment Returned, 3 Maintenance Created, 4 Warranty Expired; `Extensible = false`. `app/src/Integration/EQMIntegrationEventType.Enum.al` |
| Table | 50110 | EQM Integration Event Entry | New | The outbox. `EQMIntegrationEventEntry.Table.al` |
| Codeunit | 50122 | EQM Integration Event Mgt. | New | `Access = Internal`, `Permissions = tabledata "EQM Integration Event Entry" = rim`. Writes and marks entries |
| Codeunit | 50121 | EQM Integration Event Subscr. | New | `Access = Internal`. Five subscribers to 50119 |
| Page | 50132 | EQM Integration Event Entries | New | Read-only list, opened from Equipment Setup |
| Page (API) | 50126 | EQM Integration Event API | New | Q3. `app/src/API/EQMIntegrationEventAPI.Page.al` |
| Table / Page | 50102 / 50103 | EQM Equipment Setup | Modify (own) | Q2. Field 4 + group "Integration" + navigation action |
| PermissionSet | 50100-50102 | EQM - Reader / Manager / Administrator | Modify (own) | See Permissions |
| Codeunit (test) | 50186 | EQM Integration Event Tests | New | Scenarios 1-11. `test/src/EQMIntegrationEventTests.Codeunit.al` |

## Data model and upgrade impact
- Table 50110 (Caption 'Integration Event Entry', `DataClassification = CustomerContent` at table level, `Access = Public`, Lookup/DrillDown page 50132). Fields, all `Editable = false`, each with Caption + ToolTip: 1 "Entry No." Integer AutoIncrement (PK, clustered); 2 "Event Type" Enum 50109; 3 "Equipment No." Code[20] (TableRelation 50100, `ValidateTableRelation = false`); 4 "Equipment Status" Enum 50100 (status at event time); 5 "Assignment Entry No." Integer (0 when not an assignment event; TableRelation 50103, no validation); 6 "Maintenance No." Code[20] (blank unless Maintenance Created; TableRelation 50105, no validation); 7 "Processed" Boolean; 8 "Processed At" DateTime. Key 2: Processed, "Entry No.". Creation time = SystemCreatedAt. No user ID and no employee number (no personal data; consumers read the assignment via the FR-028 API).
- Triggers: `OnInsert` errors unless the internal insert flag is set (then reset); `OnModify` errors unless the internal modify flag is set (then reset); `OnDelete` errors when not Processed; `OnRename` errors. Internal procedures `AllowInsertFromMgt`, `AllowModifyFromMgt` (pattern of table 50108). One label per error.
- Table 50102 field 4 "Integration Events Enabled" Boolean, Caption 'Integration Events Enabled', ToolTip explains the outbox and that entries are written only when on. Default false: **no upgrade codeunit**. App version stays 29.0.0.0 (not released).

## Events
- Subscribed (in 50121), all `[IntegrationEvent]` publishers of codeunit 50119 "EQM Business Events"; subscriber parameter names must match the publishers exactly. Each one exits when `IntegrationEventMgt.IsEnabled()` is false, then calls `RecordEvent(EventType, EquipmentNo, EquipmentStatus, AssignmentEntryNo, MaintenanceNo)`. No UI, no Commit, no Modify of the passed records.
  1. OnEquipmentCreated(Equipment): Equipment Created, Equipment."No.", Equipment.Status.
  2. OnEquipmentAssigned(Equipment; EquipmentAssignment): Equipment Assigned, values from the parameters (not the DB, per FR-029 docs), "Entry No." of the assignment.
  3. OnEquipmentReturned(Equipment; EquipmentAssignment): Equipment Returned, same as 2.
  4. OnMaintenanceCreated(MaintenanceRecord): Maintenance Created, "Equipment No." and "No." of the record; status read from the stored equipment (`SetLoadFields(Status)`, `Get`; Available when not found).
  5. OnWarrantyExpired(Equipment): Warranty Expired, Equipment."No.", Equipment.Status.
- Published: none. 50119 is unchanged.

## Permissions
- EQM - Reader: `tabledata "EQM Integration Event Entry" = R`; X on table 50110, page 50132, page 50126, codeunits 50121 and 50122.
- EQM - Manager: `tabledata "EQM Integration Event Entry" = i` (its assign/create/maintenance actions raise the events).
- EQM - Administrator: `tabledata "EQM Integration Event Entry" = mD` (markProcessed through 50122; delete processed entries on page 50132). The warranty job runs as its scheduling (admin) user, who has `i` through Manager.

## Compatibility
- Additive only. **Contract at first AppSource release:** table 50110 (Public) field IDs/names, enum 50109 values, API v1.0 entity `integrationEvent`/`integrationEvents`, its fields and the `markProcessed` action. Later changes need Obsolete handling or API v2.0.
- **Breaking-change risk (low), flagged:** step 3 adds field 4 to public table 50102 and changes page 50103 (additive). 50119 and all FR-029 call sites are untouched.

## Implementation steps
1. Enum 50109. Compile.
2. Table 50110 and page 50132 together (they reference each other). Page: List, `Editable/InsertAllowed/ModifyAllowed = false`, `DeleteAllowed = true`, `UsageCategory = None` (opened from setup), sorted Entry No. descending; columns Entry No., Event Type, Equipment No., Equipment Status, Assignment Entry No., Maintenance No., SystemCreatedAt (Caption 'Created At'), Processed, Processed At; AboutTitle/AboutText. Compile.
3. Table 50102 field 4; page 50103: group `Integration` (Caption 'Integration') with the field, and Navigation action `IntegrationEventEntries` (Caption 'Integration Event Entries', Image Log, RunObject page 50132). Compile.
4. Codeunit 50122: `IsEnabled(): Boolean` (Get setup with SetLoadFields; false when no setup), `RecordEvent(...)` (Init, set fields, AllowInsertFromMgt, Insert(true)), `MarkProcessed(var IntegrationEventEntry)` (no-op when already Processed; else Processed true, Processed At CurrentDateTime, AllowModifyFromMgt, Modify(true)). XML docs. Compile.
5. Codeunit 50121 with the five subscribers (Events section). Compile.
6. Page 50126 per FR-026 C1/C3/C5/C6/C9: EntityName `integrationEvent`, EntitySetName `integrationEvents`, Caption 'Integration Event API'. Fields `id` (SystemId), `entryNumber`, `eventType`, `equipmentNumber`, `equipmentStatus`, `assignmentEntryNumber`, `maintenanceNumber`, `processed`, `processedDateTime`, `createdDateTime` (SystemCreatedAt), `lastModifiedDateTime`; all read-only; `InsertAllowed/ModifyAllowed/DeleteAllowed = false`; no `DataAccessIntent = ReadOnly` (the action writes). Bound action `markProcessed` -> 50122 MarkProcessed, ActionContext result code Updated. Compile.
7. Permission lines (API page line after `page "EQM Assignment API" = X,`, C9). Build; commit the `.g.xlf`.
8. Test codeunit 50186 (pattern of 50184: Subtype Test, TestPermissions Disabled, AutoRollback, Library Assert, ConfirmHandler, Locked labels prefix `EQMIEV`, Initialize sets number series and `Integration Events Enabled` = true; count entries filtered on Equipment No.). Build the test app.
9. Documenter: feature doc, help (setup, API URL, polling pattern: GET `processed eq false` ordered by entryNumber, then markProcessed), CHANGELOG, TODO sandbox section (scenario 12).

## Test scenarios
Setup: integration enabled, active category, active employee E1, Available equipment EQ inserted with Insert(true) (its Created entry is counted in 1 only).
1. Given enabled, when new equipment is inserted with Insert(true), then one entry Equipment Created exists with its No., Status Available, Processed false.
2. Given EQ, when AssignEmployee(E1) runs, then one Equipment Assigned entry with Status Assigned and Assignment Entry No. = the active entry.
3. Given EQ assigned, when UnassignEmployee runs (Yes), then one Equipment Returned entry with Status Available and the closed entry's No.
4. Given EQ assigned, when a maintenance record M is inserted, then an Equipment Returned entry (Status In Maintenance) and, with a higher Entry No., a Maintenance Created entry with Maintenance No. M and Status In Maintenance.
5. Given W1 (warranty end R-1), when RaiseWarrantyExpiredEvents(R) runs, then one Warranty Expired entry for W1.
6. (neg) Given integration disabled, when equipment is created and assigned, then no entries are written.
7. (neg) Given enabled, when equipment is inserted with Insert(false) or as a temporary record, then no entry.
8. (neg) Given EQ assigned, when UnassignEmployee is answered No, then no Returned entry.
9. Given a pending entry, when MarkProcessed runs, then Processed is true and Processed At is filled; when it runs again, Processed At is unchanged.
10. (neg) When an entry is inserted directly, or a stored entry is modified directly, or renamed, then the matching error is raised.
11. (neg) Given a pending entry, when it is deleted, then an error; given a processed entry, when deleted, then it is gone.
12. Sandbox: API GET with `$filter=processed eq false`, POST `.../integrationEvents({id})/Microsoft.NAV.markProcessed` sets processed; Reader GET works and markProcessed is denied; a scheduled warranty job run writes Warranty Expired entries.

## Risks and open questions
- Q1-Q3: see the top. The plan follows the recommended defaults; "all" (Q1), "always" (Q2) or "none" (Q3) remove or add objects and need a replan.
- Assumed no standard BC event is needed, because the five FR-029 publishers carry all required data.
- Assumed codeunits 50121/50122, page 50132 and test codeunit 50186 (next free after the highest in use), and API page 50126 because 50126-50129 are the FR-026 C10 API reserve.
- Assumed no retention job: processed entries are deleted manually by an Administrator; pending entries cannot be deleted. Risk: the table grows if no consumer runs (mitigated by Q2 off by default).
- Assumed `markProcessed` is idempotent (second call is a no-op) because API clients retry.
- Risk: any error writing an entry stops the business operation (same transaction). Insert of a guarded table with AutoIncrement is the only work, so this is low.
- Unverified (V1): a bound action on an API page with `ModifyAllowed = false` that modifies through a codeunit; fallback `ModifyAllowed = true` with every field `Editable = false`. HTTP checks are sandbox-only (FR-026 Q3: API HTTP tests fail in CI).
