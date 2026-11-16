# FR-035 Equipment Audit Trail

## Purpose
One chronological, read-only lifecycle timeline per piece of equipment (GitHub issue #73): Created, Updated, Assigned, Returned, Sent to Maintenance, Disposed. Each entry records who, when, the status after the event, and the assignment entry or maintenance record behind it. The trail is always on; it has no setup and cannot be switched off.

Status: implemented on branch `feature/FR-035-equipment-audit-trail`, not committed, not merged. App version stays 29.0.0.0 (unreleased, no bump, no upgrade code).

Decisions (approved): D1 save, D2 updated, D3 keep (see Behavior).

## Verification status
- **Build:** the app compiles clean with CodeCop and UICop.
- **Tests: written, compile, NOT executed.** Test codeunit 50192 "EQM Audit Trail Tests" (21 test procedures in the file, see Discrepancies) has not been run: no BC sandbox was available and it has not run in CI yet.
- **Not verified:** sandbox scenarios 14 (rename cascade, Manager permission) and 15 (permissions) in `docs/plans/FR-035-equipment-audit-trail.md`. See `docs/TODO.md`, section "FR-035 sandbox checks".

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Enum | 50111 | EQM Audit Event Type | New, not extensible. 0 Created, 1 Updated, 2 Assigned, 3 Returned, 4 Sent to Maintenance, 5 Disposed |
| Table | 50112 | EQM Equipment Audit Entry | New, `Access = Public`, append-only |
| Codeunit | 50135 | EQM Audit Trail Mgt. | New, `Access = Internal`. Writes the entries |
| Codeunit | 50136 | EQM Audit Trail Subscr. | New, `Access = Internal`. Subscribes to the business events |
| Page | 50136 | EQM Equipment Audit Trail | New, read-only list |
| Table | 50100 | EQM Equipment | `OnModify` calls the audit trail; `StartMaintenance` hands over the maintenance number (new global `MaintenanceNoInProgress`) |
| Page | 50101 | EQM Equipment Card | New action "Audit Trail" (enabled once the record is saved), promoted; About text extended |
| PermissionSet | 50100, 50101 | EQM - Reader, EQM - Manager | See Permissions |
| Codeunit (test) | 50192 | EQM Audit Trail Tests | New |
| Codeunit (test) | 50193 | EQM Audit Trail Test Subscr | New, test helper (`test/src/EQMAuditTrailTestSubscr.Codeunit.al`) |

## Table 50112 "EQM Equipment Audit Entry"
All fields are not editable.
| No. | Field | Meaning |
|---|---|---|
| 1 | Entry No. | Auto-increment primary key |
| 2 | Equipment No. | Equipment the event happened to (table relation without validation, so entries survive deletion) |
| 3 | Event Type | Enum 50111 |
| 4 | Status After | Equipment status after the event (the status in the record being saved) |
| 5 | Employee No. | Assigned and Returned only; blank otherwise |
| 6 | Assignment Entry No. | Entry of table 50103 behind Assigned and Returned; 0 otherwise |
| 7 | Maintenance No. | Maintenance record that sent the equipment to maintenance; blank for a manual status change and for other events |
| 8 | User ID | `UserId()`; classified EndUserIdentifiableInformation |
| 9 | Logged At | `CurrentDateTime()` |

Keys: primary "Entry No."; secondary "Equipment No.", "Entry No.". Insert is allowed only after the internal `AllowInsertFromAuditTrail()` and requires an Equipment No.; Modify, Delete and Rename each raise an error. Table-level data classification is CustomerContent.

## Behavior
Entries are written in the transaction of the operation, so a rolled back operation leaves no entry. Temporary records are skipped.

| Event | Written when | Source |
|---|---|---|
| Created | Equipment is inserted with triggers | Subscriber to `OnEquipmentCreated` of codeunit 50119 |
| Assigned | Equipment is assigned; Employee No. and Assignment Entry No. filled | Subscriber to `OnEquipmentAssigned` |
| Returned | Equipment is returned; Employee No. and Assignment Entry No. filled; Status After shows why (Available, In Maintenance, Disposed, Lost) | Subscriber to `OnEquipmentReturned` |
| Sent to Maintenance | Status changes to In Maintenance | `OnModify` of table 50100 |
| Disposed | Status changes to Disposed | `OnModify` of table 50100 |
| Updated | See below | `OnModify` of table 50100 |

The subscribed business events are internal integration events of the app's own codeunit 50119; they are raised whether or not the integration is enabled.

Within one save, entries are written in this order: Sent to Maintenance, Disposed, Updated. Returned is written by the return itself, so it comes before Sent to Maintenance or Disposed when assigned equipment changes status.

**Updated (D1 = save, D2 = updated):**
- At most one Updated entry per save (`Modify`). It holds no field names and no values; the old and new values are in the standard Change Log (FR-034).
- An Updated entry is written when the stored record differs from the saved record in one of: Description, Category Code, Serial No., Manufacturer, Model, Purchase Date, Purchase Cost, Location Code, Warranty Start Date, Warranty End Date, Warranty Provider, Warranty Reference No., Last Maintenance Date, Maintenance Frequency (Months).
- Not compared: Status and Assigned Employee No. (covered by the lifecycle events), calculated fields, FlowFields, Picture.
- D2: a status change from a status other than Assigned to a status other than Assigned, In Maintenance or Disposed also writes Updated, with the new status in Status After. This covers a change to Lost and In Maintenance back to Available after posting.
- The Equipment Card saves each edited field separately, so editing five fields on the card gives five Updated entries. A single `Modify` that changes five fields (for example from code or an API) gives one.
- Posting a maintenance record can add two Updated entries (status back to Available, then Last Maintenance Date), because they are two separate saves.

**D3 = keep:** deleting equipment is unchanged (allowed only without assignments, maintenance records or notes). Its audit entries stay in the log and no Deleted event is written. A reused equipment number shows the old entries.

**Limits:**
- Equipment created before this feature has no Created entry (no backfill).
- Code that saves equipment with `Modify(false)` or inserts without triggers bypasses the trail (none exists in this app).
- Rename of equipment: whether entries follow the new number for non-SUPER users is TODO(verify) (scenario 14).

## Setup
None. The page is reached from the Equipment Card action **Audit Trail** (filtered to the equipment) or by searching "Equipment Audit Trail" (Tell Me, category History; also found by "equipment history", "equipment lifecycle", "equipment audit"). Newest entry first.

## Events
None published. Subscribed: the three business events above. No events report was needed because only the app's own objects are hooked.

## Permissions
- **EQM - Reader:** `tabledata "EQM Equipment Audit Entry"` = R; execute on table 50112, page 50136 and codeunits 50135 and 50136.
- **EQM - Manager:** `tabledata "EQM Equipment Audit Entry"` = i (indirect insert, used by codeunit 50135). Administrator inherits; no set gets modify or delete on the table.
- Codeunit 50135 declares `Permissions = tabledata "EQM Equipment Audit Entry" = ri, tabledata "EQM Equipment" = r`.

## Compatibility
Table 50100 is public: only the `OnModify` body, the internal `StartMaintenance` body and a new global variable changed; no signature or event changed. At the first AppSource release, table 50112 (field IDs, names, types) and the values of enum 50111 become a contract.

## Relation to other history
| Where | What |
|---|---|
| Audit Trail (this feature) | Lifecycle timeline, no values |
| Equipment Assignments (FR-006) | Every assignment with dates |
| Maintenance Log (NFR-005) | Every maintenance operation with old and new values |
| Change Log (FR-034) | Field values, only when an administrator switches it on |

## Translations
New captions, tooltips and labels are in `app/Translations/Equipment Management.g.xlf` (regenerated by the build).

## Not verified (TODO(verify))
- All 21 tests in codeunit 50192: not executed.
- Rename of equipment with audit entries as a non-SUPER Manager (scenario 14).
- Reader opens the page read-only; Manager can use card actions without permission errors (scenarios 14, 15).
- Entries are written with integration events off; deleting equipment without history leaves its entries (scenario 15).

## Discrepancies plan vs code
- Extra tests beyond the plan list: `InsertWithoutTriggersWritesNoEntry` and `InsertWithoutEquipmentNoIsRejected`.
- Test count: the file has 21 test procedures; the handover said 22. TODO(verify) the count after the first run.
- The plan stated the Updated field list by number (2, 3, 4, ... 23); the code compares the fields by name as listed above (Status and Assigned Employee No. excluded; D2 handles status).
