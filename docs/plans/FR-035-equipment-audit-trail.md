# FR-035 Equipment Audit Trail

> Status: **Draft, awaiting approval.** Source: GitHub issue #73. Branch `feature/FR-035-equipment-audit-trail`. No events report: only this app's own objects are hooked (business events of codeunit 50119, table 50100 triggers). No version bump (29.0.0.0, unreleased). No upgrade code.
> **Open decisions (the plan uses the recommended default, so each answer can be one word):**
> - **D1 "Updated" detail.** **save** (recommended): one Updated entry per save that changed at least one tracked field, with no field names or values. Field-level old/new values stay in the standard Change Log (FR-034 rejected an own field-change log). **fields**: one Updated entry per changed field, with Field No. and a Field Caption FlowField, still without values.
> - **D2 Status changes the issue does not name** (Available/In Maintenance to Lost, In Maintenance to Available after posting, extension statuses). **updated** (recommended): logged as Updated; "Status After" shows the new status. **own**: add enum values Lost and Maintenance Completed.
> - **D3 Deleting equipment.** **keep** (recommended): deletion stays allowed as today (only equipment without assignments, maintenance or notes); its audit entries stay as orphans and no Deleted event is logged. **block**: equipment with audit entries cannot be deleted, which makes all equipment undeletable (behavior change).

## Goal
Keep one chronological, read-only lifecycle timeline per equipment with the issue's six events: Created, Updated, Assigned, Returned, Sent to Maintenance, Disposed. Each entry says who, when, the status after the event, and links to the assignment entry or maintenance record behind it. Users open it from the Equipment Card.

## Approach and rejected alternatives
- Chosen: new append-only table "EQM Equipment Audit Entry" (same immutability pattern as 50108), written by one internal codeunit. Created/Assigned/Returned come from subscribers to the existing business events of codeunit 50119 (no change to their publishers). Sent to Maintenance, Disposed and Updated come from one call at the end of table 50100 `OnModify`. Read-only list page, navigation action on the card. Detail stays where it already is: assignment table 50103 (FR-006), maintenance log 50108 (NFR-005), standard Change Log (FR-034); the audit entry only references them.
- Rejected: a virtual timeline (temporary table) built from 50103, 50105 and Change Log Entries. Disposal and status changes exist only in the Change Log, which is off by default (FR-034 D1) and deletable by admins, so the history would not be complete.
- Rejected: reusing "EQM Integration Event Entry" (50110). It is an outbox: written only when integration is enabled, and processed entries are deleted.
- Rejected: own field-level old/new log. Settled against in FR-034 (duplicates the Change Log).
- Rejected: telemetry as the trail and publishing new events (NFR-005 reasoning: telemetry must not carry customer content; an IsHandled could switch the audit off).

## Objects
IDs in use (checked `app/src`, `test/src`): tables 50100-50111, pages 50100-50126 and 50130-50135 (50127-50129 reserved for APIs), codeunits 50103-50122 and 50130-50134, enums 50100-50110, test codeunits 50178-50191. Folder `app/src/AuditTrail/`.
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50111 | EQM Audit Event Type | New | 0 Created, 1 Updated, 2 Assigned, 3 Returned, 4 "Sent to Maintenance", 5 Disposed; `Extensible = false` |
| Table | 50112 | EQM Equipment Audit Entry | New | Append-only timeline |
| Codeunit | 50135 | EQM Audit Trail Mgt. | New | `Access = Internal`; `Permissions = tabledata "EQM Equipment Audit Entry" = ri, tabledata "EQM Equipment" = r` |
| Codeunit | 50136 | EQM Audit Trail Subscr. | New | `Access = Internal`; subscribes OnEquipmentCreated/Assigned/Returned of 50119 |
| Page | 50136 | EQM Equipment Audit Trail | New | Read-only list |
| Table | 50100 | EQM Equipment | Modify (own, Public) | `OnModify` call + Maintenance No. hand-over in `StartMaintenance` |
| Page | 50101 | EQM Equipment Card | Modify (own) | Navigation action "Audit Trail" |
| PermissionSet | 50100, 50101 | EQM - Reader / EQM - Manager | Modify (own) | See Permissions |
| Codeunit (test) | 50192 | EQM Audit Trail Tests | New | `test/src/EQMAuditTrailTests.Codeunit.al` |

## Data model and upgrade impact
- Table 50112: Caption 'Equipment Audit Entry', `DataClassification = CustomerContent` at table level, `Access = Public`, Lookup/DrillDownPageId = 50136. All fields `Editable = false`, Caption + ToolTip on each: 1 "Entry No." Integer AutoIncrement (PK, clustered); 2 "Equipment No." Code[20], TableRelation 50100, `ValidateTableRelation = false`; 3 "Event Type" Enum 50111; 4 "Status After" Enum "EQM Equipment Status"; 5 "Employee No." Code[20], TableRelation Employee, `ValidateTableRelation = false` (Assigned/Returned only); 6 "Assignment Entry No." Integer, TableRelation 50103, `ValidateTableRelation = false` (0 otherwise); 7 "Maintenance No." Code[20], TableRelation 50105, `ValidateTableRelation = false` (blank otherwise); 8 "User ID" Code[50] `DataClassification = EndUserIdentifiableInformation`; 9 "Logged At" DateTime. Secondary key ("Equipment No.", "Entry No."). Triggers and labels as 50108: insert only after internal `AllowInsertFromAuditTrail()`, then TestField "Equipment No."; Modify/Delete/Rename raise one error each.
- Updated compares the stored record with Rec on fields 2, 3, 4, 5, 6, 7, 8, 11, 17, 18, 19, 20, 21, 23 (via `FieldNo`). Excluded: 1, 12, 22 (calculated), 24 Picture, FlowFields, and 9/10 (lifecycle events; D2 rule below).
- No upgrade codeunit: nothing is released. Equipment created before this feature has no Created entry (accepted, documented).

## Events
- Subscribed (codeunit 50136, all `internal` IntegrationEvents of own codeunit 50119, raised regardless of the integration setup): `OnEquipmentCreated` -> Created (Status After = Equipment.Status); `OnEquipmentAssigned` -> Assigned (employee + assignment entry no.); `OnEquipmentReturned` -> Returned (Status After = Equipment.Status, so Disposed/Lost/In Maintenance show why). Each skips temporary records.
- Hook in own code (table 50100 `OnModify`, after `AssignmentMgt.UpdateAssignmentOnSave(Rec)`, skipped when `Rec.IsTemporary()`): `AuditTrailMgt.LogEquipmentChanges(Rec, MaintenanceNoInProgress)`. It reads the stored record and logs, in this order: Sent to Maintenance when the status changes to In Maintenance (Maintenance No. = global var, blank for a manual change); Disposed when it changes to Disposed; at most one Updated when a tracked field differs or (D2 = updated) the status changed from a non-Assigned status to one other than Assigned, In Maintenance or Disposed.
- `StartMaintenance`: set global `MaintenanceNoInProgress := MaintenanceRecord."No."` before `Modify(true)` and clear it after (same pattern as `ReturnInProgress`).
- Published: none (see rejected alternatives).

## Permissions
- EQM - Reader: `tabledata "EQM Equipment Audit Entry" = R`; X on table 50112, page 50136, codeunits 50135 and 50136 (keep object-type grouping).
- EQM - Manager: `tabledata "EQM Equipment Audit Entry" = i` (indirect, used by 50135). Administrator: no change; no set gets M or D on 50112.

## Compatibility
- **Breaking-change risk: low, flagged.** Table 50100 is Public: only the `OnModify` body, internal `StartMaintenance` body and a new global var change; no signature or event change. Page 50101 gets an additive action. After the first AppSource release, table 50112 (field IDs/names/types) and enum 50111 values become a contract; making 50111 extensible later is non-breaking.

## Implementation steps
1. Enum 50111 (`EQMAuditEventType.Enum.al`). Compile.
2. Table 50112 (`EQMEquipmentAuditEntry.Table.al`) with triggers, labels and `AllowInsertFromAuditTrail`. Compile.
3. Codeunit 50135 (`EQMAuditTrailMgt.Codeunit.al`), internal procedures with `/// summary`: `LogCreated(Equipment)`, `LogAssignment(EventType, Equipment, EquipmentAssignment)`, `LogEquipmentChanges(Equipment, MaintenanceNo)`, local `InsertEntry(...)` (User ID = `UserId()` CopyStr 50, Logged At = `CurrentDateTime()`), local `HasTrackedFieldChanged(Stored, New)`. Compile.
4. Codeunit 50136 (`EQMAuditTrailSubscr.Codeunit.al`): three subscribers calling 50135. Compile.
5. Page 50136 (`EQMEquipmentAuditTrail.Page.al`): List, `Editable/InsertAllowed/ModifyAllowed/DeleteAllowed = false`, `UsageCategory = History`, `SourceTableView` sorted Entry No. descending; columns Logged At, Equipment No., Event Type, Status After, Employee No., Maintenance No., Assignment Entry No., User ID; AboutTitle/AboutText; AdditionalSearchTerms 'equipment history, equipment lifecycle, equipment audit'.
6. Permission sets 50100/50101. Compile.
7. Table 50100: `OnModify` call and `StartMaintenance` hand-over (Events section). Update the table/procedure summaries. Compile.
8. Page 50101: action `AuditTrail` (Caption 'Audit Trail', Image History, `Enabled = IsSaved`, RunObject page 50136, RunPageLink "Equipment No." = field("No.")) in group EquipmentGroup, actionref in Category_Category4; append one sentence about **Audit Trail** to AboutText. Build; commit the regenerated `.g.xlf`.
9. Test codeunit 50192 (pattern of 50191: Subtype Test, TestPermissions Disabled, AutoRollback, Library Assert, Locked labels prefix `EQMAUD`, confirm handlers where the scenario raises a Confirm). Build both apps.
10. Documenter: feature doc, help (relation to Assignment History, Maintenance Log and Change Log; no values on Updated), CHANGELOG, TODO "FR-035 sandbox checks" (scenarios 14-15).

## Test scenarios
Setup: category C, active employee E, equipment X (Available), all created in the test.
1. When X is inserted with Insert(true), then exactly one Created entry for X exists, Status After = Available, User ID = current user, Logged At filled.
2. Given X, when AssignEmployee(E), then one Assigned entry with Employee No. = E, Assignment Entry No. = the active 50103 entry, Status After = Assigned, and no Updated entry.
3. Given X assigned, when UnassignEmployee, then one Returned entry with Employee No. = E, Status After = Available, and no Updated entry.
4. Given X Available, when a maintenance record M is inserted, then one Sent to Maintenance entry with Maintenance No. = M."No.".
5. Given X assigned, when maintenance M is registered (confirm Yes), then Returned (Status After = In Maintenance) is logged before Sent to Maintenance.
6. Given X Available, when Status is validated to In Maintenance manually and saved, then one Sent to Maintenance entry with blank Maintenance No.
7. Given X assigned, when Status is set to Disposed (confirm Yes) and saved, then Returned then Disposed are logged, Status After = Disposed for both.
8. Given X, when Description and Purchase Cost change in one Modify(true), then exactly one Updated entry.
9. (neg) Given X, when Modify(true) runs with no change, or only Picture changes, then no entry is added.
10. (D2) Given X Available, when Status is set to Lost, then one Updated entry with Status After = Lost; given X In Maintenance with M posted, then an Updated entry with Status After = Available exists.
11. (neg) Given a temporary X, when inserted and modified, then no entry is added.
12. (neg) Given an entry, when Insert without the allow flag, Modify, Delete or Rename is called, then the respective error is raised.
13. (neg) Given an error after the hook in the same transaction (e.g. assignment to a blocked employee), then no entry remains.
14. Sandbox (manual): as a Manager (not SUPER), run the card actions and check the Audit Trail page; as a Reader, the page opens read-only. Rename X and record whether entries follow the new number (as HS-SB9).
15. Sandbox (manual): with integration events off, entries are still written; deleting equipment without history leaves its entries (D3).

## Risks and open questions
- D1-D3: see the top.
- Assumed a navigation action and no FactBox, because the card already has four FactBoxes and the issue asks for history, not a summary.
- Assumed one Sent to Maintenance per status change, not per maintenance record, because the maintenance log (50108) already lists every record.
- Assumed posting can add two Updated entries (status back to Available, then Last Maintenance Date), because they are two separate saves; accepted as accurate.
- Assumed no telemetry and no Retention Policy registration, because the trail is customer data (NFR-005) and retention was not requested. User ID is EUII; Employee No. is CustomerContent as in 50103.
- R1 Code with Modify(false) or RunTrigger = false on 50100 bypasses the hook (none exists today, FR-034 audit). R2 Rename cascade into 50112 is unverified for non-SUPER users (scenario 14; fallback needs approval). R3 A reused number after deletion shows the old orphan entries (D3).
