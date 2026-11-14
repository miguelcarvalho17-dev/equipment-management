# FR-030 Event Subscribers (integration event outbox)

## Purpose
A new Integration module subscribes to the five FR-029 business events and writes one outbox entry per event, in the same transaction as the business operation (GitHub issue #68). External systems read pending entries through an API and mark them processed. No existing business code changes. No standard BC event is used, so there is no events report.

Status: implemented on branch `feature/FR-030-event-subscribers`. App version stays 29.0.0.0 (not released).

## Verification status
- **Build:** app compiles clean with CodeCop and UICop. AppSourceCop reports only the manifest diagnostics that were already known. The documenter did not rerun the build; no AL line was changed (the `///` comments were already present).
- **Tests:** 14 tests in codeunit 50186 all pass in AL-Go CI (PR #120: 119 tests in total, 0 failed, 0 skipped). They were not run in a BC sandbox by a person.
- **Not verified (sandbox only):**
  - Scenario 12: API GET with `$filter=processed eq false`; POST `markProcessed` sets `processed`; Reader can GET but `markProcessed` is denied; a scheduled warranty job run writes Warranty Expired entries.
  - Plan item V1: a bound action on an API page with `ModifyAllowed = false` that modifies the record through a codeunit. Fallback if it fails: `ModifyAllowed = true` with every field `Editable = false`.
- TODO(verify): permissions per role in a sandbox.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Enum | 50109 | EQM Integration Event Type | New, `Extensible = false`. 0 Equipment Created, 1 Equipment Assigned, 2 Equipment Returned, 3 Maintenance Created, 4 Warranty Expired. `app/src/Integration/EQMIntegrationEventType.Enum.al` |
| Table | 50110 | EQM Integration Event Entry | New, `Access = Public`. The outbox. |
| Codeunit | 50121 | EQM Integration Event Subscr. | New, `Access = Internal`. Five subscribers to codeunit 50119. |
| Codeunit | 50122 | EQM Integration Event Mgt. | New, `Access = Internal`. `IsEnabled`, `RecordEvent`, `MarkProcessed`. |
| Page | 50132 | EQM Integration Event Entries | New list, read-only, `DeleteAllowed = true`, `UsageCategory = None`. Newest first. |
| Page (API) | 50126 | EQM Integration Event API | New. v1.0, publisher `miguelCarvalho`, group `equipment`, entity `integrationEvent` / `integrationEvents`. |
| Table | 50102 | EQM Equipment Setup | Field 4 "Integration Events Enabled" (Boolean, default off). |
| Page | 50103 | EQM Equipment Setup | Group "Integration" with the field; action "Integration Event Entries". |
| PermissionSet | 50100-50102 | EQM - Reader / Manager / Administrator | See Permissions. |
| Codeunit (test app) | 50186 | EQM Integration Event Tests | New, 14 tests. |

## Setup
Equipment Setup > Integration > **Integration Events Enabled**. Off by default; no entry is written while it is off. No upgrade code is needed.

## Data model (table 50110)
All fields `Editable = false`.

| # | Field | Type | Meaning |
|---|---|---|---|
| 1 | Entry No. | Integer, AutoIncrement | Primary key. |
| 2 | Event Type | Enum 50109 | The business event. |
| 3 | Equipment No. | Code[20] | Equipment the event is about. Table relation without validation. |
| 4 | Equipment Status | Enum "EQM Equipment Status" | Status at event time. |
| 5 | Assignment Entry No. | Integer | Assignment entry for assigned and returned events; 0 otherwise. |
| 6 | Maintenance No. | Code[20] | Set for Maintenance Created; blank otherwise. |
| 7 | Processed | Boolean | Set by `MarkProcessed`. |
| 8 | Processed At | DateTime | When it was marked processed. |

Keys: PK ("Entry No.", clustered); "Processed, Entry No.". Creation time is `SystemCreatedAt`. No user ID or employee number is stored (no personal data).
Field groups: **DropDown** (Entry No., Event Type, Equipment No., Processed) and **Brick** (Event Type, Equipment No., Processed). These are extra to the plan; they feed lookups and drill-downs of the table.

Guards in the table triggers (one error label each):
- `OnInsert` errors unless `AllowInsertFromMgt` was called on that record variable.
- `OnModify` errors unless `AllowModifyFromMgt` was called.
- `OnDelete` errors when the entry is not Processed.
- `OnRename` always errors.

## Subscribers (codeunit 50121)
Each subscribes to the same-named publisher of codeunit 50119 "EQM Business Events", exits when `IsEnabled()` is false, then calls `RecordEvent`. No UI, no `Commit`, no change to the passed records. An error while writing an entry stops the business operation (same transaction).

| Publisher | Entry written |
|---|---|
| `OnEquipmentCreated` | Equipment Created; number and status from the parameter. |
| `OnEquipmentAssigned` | Equipment Assigned; status and assignment "Entry No." from the parameters. |
| `OnEquipmentReturned` | Equipment Returned; same as assigned (status tells the reason: Available, In Maintenance, Lost, Disposed, Assigned). |
| `OnMaintenanceCreated` | Maintenance Created; equipment number and maintenance "No." from the record. Status is read from the stored equipment (`SetLoadFields`, `Get`); Available when the equipment is not found. |
| `OnWarrantyExpired` | Warranty Expired; number and status from the parameter. |

One maintenance registration on assigned equipment writes Equipment Returned first and Maintenance Created after it (higher Entry No.).

## Codeunit 50122 (internal)
- `IsEnabled(): Boolean`: true when the setup exists and the switch is on.
- `RecordEvent(EventType; EquipmentNo; EquipmentStatus; AssignmentEntryNo; MaintenanceNo)`: inserts one entry with `Insert(true)`.
- `MarkProcessed(var Entry)`: does nothing if already Processed (idempotent); otherwise sets Processed and Processed At and modifies.

## API (page 50126)
`/api/miguelCarvalho/equipment/v1.0/companies({companyId})/integrationEvents`

Fields (all read-only): `id` (SystemId), `entryNumber`, `eventType`, `equipmentNumber`, `equipmentStatus`, `assignmentEntryNumber`, `maintenanceNumber`, `processed`, `processedDateTime`, `createdDateTime`, `lastModifiedDateTime`. `InsertAllowed`, `ModifyAllowed`, `DeleteAllowed` are false; not extensible. No `DataAccessIntent = ReadOnly`, because the action writes.

Bound action `markProcessed` (`[ServiceEnabled]`): calls `MarkProcessed`, returns result code Updated. Address: `.../integrationEvents({id})/Microsoft.NAV.markProcessed`. TODO(verify): the exact address and behavior (see V1).

Polling pattern: GET `integrationEvents?$filter=processed eq false&$orderby=entryNumber`, handle each entry, then POST `markProcessed`. The action is idempotent, so clients can retry.

## Events
Published: none. Subscribed: the five events of codeunit 50119 (see FR-029).

## Permissions
- **EQM - Reader:** tabledata "EQM Integration Event Entry" = R; execute on table 50110, pages 50132 and 50126, codeunits 50121 and 50122. Manager and Administrator inherit it.
- **EQM - Manager:** tabledata = i (its assign, create and maintenance actions raise the events).
- **EQM - Administrator:** tabledata = mD (`markProcessed`; delete processed entries on page 50132).
- Codeunit 50122 carries `Permissions = tabledata "EQM Integration Event Entry" = rim`.
- The warranty job runs as its scheduling user, who gets insert through Manager. Not checked in a sandbox.

## Retention
No retention job. An Administrator deletes processed entries manually on page 50132; pending entries cannot be deleted. The table grows if no consumer runs; this is why the switch is off by default.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build. Never edit by hand.

## Compatibility
Additive. Adds field 4 to public table 50102 and changes page 50103 (additive); codeunit 50119 and its call sites are untouched. **Contract at the first AppSource release:** table 50110 field IDs and names, enum 50109 values, API v1.0 entity `integrationEvent` / `integrationEvents`, its fields and the `markProcessed` action. Later changes need Obsolete handling or API v2.0.

## Test status
Codeunit 50186 (`test/src/EQMIntegrationEventTests.Codeunit.al`, AutoRollback): created, assigned, returned, maintenance (Returned then Maintenance Created), warranty expired, disabled setting, Insert(false) and temporary record, cancelled return, `MarkProcessed` (and second call), rejected direct insert, modify and rename, delete of pending (rejected) and processed (allowed) entries. all 14 pass in AL-Go CI (PR #120).

## XML documentation
Present on the enum, the table and its internal procedures, codeunits 50121 and 50122 and their procedures, and `markProcessed` on page 50126.

## Discrepancies plan vs code
- Table 50110 has two field groups (DropDown, Brick) that the plan does not list.
- Plan: test codeunit covers scenarios 1-11 as written; the code has 14 tests (more granular). Scenario 12 is sandbox-only.
- Page 50132 columns and API page captions were not compared line by line to the plan. TODO(verify).
