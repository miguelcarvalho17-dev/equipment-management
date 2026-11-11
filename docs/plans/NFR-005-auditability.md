# NFR-005 Auditability

> Status: **APPROVED** by the user. Q1-Q3 defaults, Q4 changed to `Format(value, 0, 9)` (XML format).
> Source: GitHub issue #45. Branch: `feature/NFR-005-auditability`.
> No events report: only this app's own objects change (tables 50105, new 50108). No standard BC behavior is hooked. al-event-finder is not needed.
> Scope: main app. 1 new table, 1 new enum, 1 new codeunit, 1 new page; table 50105, codeunit 50109, pages 50113/50114 and permission sets 50100/50101 changed. **No version bump** (29.0.0.0, not released). **No upgrade code.** Tests deferred by default (Q3, test codeunit 50177 reserved).

## Goal
Every maintenance operation (register, correct, post) leaves a permanent, read-only record of who did what and when, including the old and new value of each corrected field. Maintenance data stays non-deletable for every role.

### Requirement restated and current state (audit of this branch)
| Req | Today | Gap |
|---|---|---|
| AU-R1 Maintenance records are never physically deleted | Met: table 50105 `OnDelete`/`OnRename` raise errors; pages 50113/50114 `DeleteAllowed = false`; no permission set has D on 50105 or 50106; table 50106 is immutable; equipment with maintenance cannot be deleted (table 50100 `OnDelete`). | None in code. Only code with RunTrigger = false and D permission (SUPER) could bypass (R1). |
| AU-R2 Posting is traceable | Met: history entry 50106 stores Posted By / Posted At and a snapshot of the record. | None. |
| AU-R3 Registration is traceable | Partly: only platform fields SystemCreatedBy/At (GUID, not shown). | Nothing visible to users. |
| AU-R4 Corrections of open records are traceable | **Not met**: an open record can be changed any number of times; only the last SystemModifiedBy/At survives; old values are lost. | Main gap. |
| AU-R5 Cancel | Settled in FR-012 Q4: no cancel, a record opened by mistake is posted with cost 0 and a describing text. Not reopened. | Covered by AU-R2 + AU-R4. |

## Approach and rejected alternatives
- Chosen: **own append-only "Maintenance Log Entry" table** written from the maintenance record's triggers (Registered, Changed per field with old/new value) and from posting (Posted), through one internal codeunit with indirect insert rights. Same immutability pattern as table 50106 (insert only through an internal allow-flag; modify/delete/rename raise errors). Read-only list page opened from the maintenance list and card.
- Rejected: base **Change Log** (enable Change Log Setup for table 50105 by code). It changes the customer's audit configuration silently, admins can switch it off or delete entries (Delete Change Log Entries), and AppSource apps should not own tenant setup. Customers may still enable it themselves (help note).
- Rejected: **version copies of the whole record** per modify. More storage, harder to read than field-level old/new values.
- Rejected: **a Cancelled status / soft delete**. FR-012 Q4 is settled; it would change enum 50103, posting, KPIs and history.
- Rejected: **telemetry as the audit trail**. Telemetry must not carry customer content and is not visible to the customer's auditors in BC.
- Rejected: publishing IsHandled events around logging. A subscriber could switch off the audit trail.

## Objects
IDs in use (checked in `app/src`): tables 50100-50107, pages 50100-50120, codeunits 50103-50115, enums 50100-50106, queries 50100-50103, page ext 50100, permission sets 50100-50102, permission set ext 50103. Test app: no objects; codeunits 50150-50176 reserved by earlier plans.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50107 | EQM Maintenance Log Action | New | Values 0 Registered, 1 Changed, 2 Posted; `Extensible = false` |
| Table | 50108 | EQM Maintenance Log Entry | New | Append-only audit trail |
| Codeunit | 50116 | EQM Maintenance Log Mgt. | New | `Access = Internal`; `Permissions = tabledata "EQM Maintenance Log Entry" = ri`; writes entries |
| Page | 50121 | EQM Maintenance Log Entries | New | Read-only list |
| Table | 50105 | EQM Maintenance Record | Modify (own) | Log in `OnInsert` and `OnModify` |
| Codeunit | 50109 | EQM Maintenance-Post | Modify (own) | Log Posted after the history entry |
| Page | 50113, 50114 | EQM Maintenance Records / Record Card | Modify (own) | Navigation action "Log Entries" |
| PermissionSet | 50100, 50101 | EQM - Reader / EQM - Manager | Modify (own) | Read/X and indirect insert |
Test (reserved, Q3): codeunit 50177 "EQM Maintenance Audit Tests".

## Data model and upgrade impact
- Table 50108 (Caption 'Maintenance Log Entry', `DataClassification = CustomerContent` at table level, `Access = Public` like 50105/50106, LookupPageId/DrillDownPageId = page 50121). Fields, all `Editable = false`, each with Caption + ToolTip: 1 "Entry No." Integer AutoIncrement (PK, clustered); 2 "Maintenance No." Code[20], TableRelation 50105 with `ValidateTableRelation = false`; 3 "Action" Enum 50107; 4 "Field No." Integer (0 for Registered/Posted); 5 "Field Caption" Text[80] FlowField = lookup of `Field."Field Caption"` where TableNo = const(50105) and "No." = field("Field No."); 6 "Old Value" Text[250]; 7 "New Value" Text[250]; 8 "User ID" Code[50] `DataClassification = EndUserIdentifiableInformation`; 9 "Logged At" DateTime. Secondary key on "Maintenance No.". No "Equipment No." (avoids the equipment-rename cascade issue of HS-SB9).
- Triggers on 50108: `OnInsert` errors unless the internal allow-flag is set (then resets it, TestField "Maintenance No."); `OnModify`, `OnDelete`, `OnRename` raise one label each (wording as table 50106). Internal procedure `AllowInsertFromLog`.
- Codeunit 50116: internal procedures `LogRegistered(MaintenanceRecord)`, `LogChanges(OldRecord, NewRecord)`, `LogPosted(MaintenanceRecord)`. `LogChanges` compares exactly fields 3 Maintenance Date, 4 Maintenance Type, 5 Vendor No., 6 Cost, 7 Description, 8 Performed By, and writes one Changed entry per field that differs, with `Format(value, 0, 9)` (XML format, Q4 decided). Status, Equipment No., No., No. Series are not compared (Equipment No. and No. cannot change; Status is covered by Posted). User ID = `UserId()` (CopyStr to 50), Logged At = `CurrentDateTime()`.
- No upgrade codeunit: nothing is released. Existing development records have no Registered entry (accepted, documented).

## Events
Subscribed: none. Published: none (see rejected alternatives). Existing events on 50105/50109 unchanged; changes made by their subscribers to the six audited fields are logged, which is intended.

## Permissions
- EQM - Reader: `tabledata "EQM Maintenance Log Entry" = R`; X on table 50108, page 50121, codeunit 50116.
- EQM - Manager: `tabledata "EQM Maintenance Log Entry" = i` (indirect only, used by codeunit 50116).
- EQM - Administrator: no change (log immutable for everyone, as history in NFR-002 Q2). No set gets D on 50105, 50106 or 50108.

## Compatibility
- New public table 50108 and its enum become a contract after first release (field IDs, names). Table 50105 and codeunit 50109 are Public: only trigger bodies change, no signature or event change. No breaking-change risk now; app not released.

## Implementation steps
1. Enum 50107 (`app/src/Maintenance/EQMMaintenanceLogAction.Enum.al`).
2. Table 50108 with triggers and labels (`EQMMaintenanceLogEntry.Table.al`).
3. Page 50121 (`EQMMaintenanceLogEntries.Page.al`): List, `Editable/InsertAllowed/ModifyAllowed/DeleteAllowed = false`, `UsageCategory = History`, sorted Entry No. descending, columns Entry No. (hidden), Logged At, Maintenance No., Action, Field Caption, Old Value, New Value, User ID; AboutTitle/AboutText; AdditionalSearchTerms 'maintenance audit, maintenance changes, maintenance log'.
4. Codeunit 50116 (`EQMMaintenanceLogMgt.Codeunit.al`).
5. Permission sets 50100 and 50101 (step 2-4 objects). Compile.
6. Table 50105: at the end of `OnInsert` (after StartMaintenance) call `LogRegistered(Rec)`; in `OnModify`, after the existing checks, read the stored record (full fields) and call `LogChanges(StoredRecord, Rec)`. Update the table summary comment.
7. Codeunit 50109: after `InsertHistoryEntry`, before `CompleteEquipmentMaintenance`, call `LogPosted(Rec)`.
8. Pages 50113/50114: Navigation action `LogEntries` (Caption 'Log Entries', Image ChangeLog, RunObject page 50121, RunPageLink "Maintenance No." = field("No.")), actionref in the Navigate group; append one sentence about the log to AboutText.
9. Build; commit regenerated `.g.xlf`.

## Test scenarios
Setup: equipment E (Available), Manager user unless stated. Codeunit 50177 (deferred, Q3).
1. Given E, when a record M is registered, then exactly one Registered entry for M exists with User ID = current user and Logged At filled.
2. Given open M, when Cost changes 100 -> 150 and Description changes, then two Changed entries exist with correct Field No., Old/New values; unchanged fields produce none.
3. Given open M, when Modify(true) is called with no field changed, then no entry is added.
4. Given open M, when it is posted, then one Posted entry exists, and no Changed entry for Status.
5. Given posted M, when a field change is attempted, then PostedRecordCannotBeChangedErr and no new log entry.
6. Given M, when M is deleted (Delete(true)) or renamed, then the existing errors are raised and the log is unchanged.
7. Given a log entry, when Insert/Modify/Delete/Rename is called directly, then the respective error is raised (also for Administrator, also with permission).
8. Given registration cancelled at the assigned-equipment confirm (No), then no record and no log entry exist.
9. Given a Reader, when page 50121 opens, then entries are visible and not editable; a Reader cannot create log entries (permission error).
10. Given Manager, Administrator: no set has D on 50105/50106/50108 (code review).
11. Given an error during posting, then neither history nor Posted log entry exists and M stays Open.

## Risks and open questions
- **Q1 (default: maintenance records only).** Are manual changes to planned-maintenance fields on equipment (Last Maintenance Date, Maintenance Frequency) also "maintenance operations" to log? If yes: extend codeunit 50116 and table 50100 `OnModify` (phase 2).
- **Q2 (default: keep FR-012 "post with cost 0" as cancel).** Alternative: a Cancelled status (new feature).
- **Q3 (default: tests deferred, codeunit 50177 reserved, sandbox checks instead).** For an audit NFR the user may want scenarios 1-11 built now (needs the test-app fix in `docs/TODO.md`).
- **Q4 (DECIDED: `Format(value, 0, 9)`, XML format, unambiguous but less readable).** Regional `Format(value)` rejected.
- R1 Code with `RunTrigger = false` (Modify/Delete) bypasses logging and the delete guard; only possible from other extensions' code and, for delete, only with D (SUPER). Documented, not fixable without global triggers.
- R2 Verify: FlowField lookup on system table `Field` compiles under AppSourceCop and is readable by non-SUPER users (as base Change Log Entry). Fallback: store "Field Caption" as Text[80] at write time.
- R3 "Old/New Value" may hold names ("Performed By"); classified CustomerContent, consistent with source fields (TODO personal-data item, FR-011 R5).
- Assumed Access = Public on table 50108 because 50105/50106 are Public and partners may need to report on the audit trail.
- Assumed no telemetry because the audit lives in data and telemetry must not carry customer content.
- Assumed AutoIncrement gaps after rollbacks are acceptable (same as table 50106).
- Docs (documenter): feature doc, help (how to open Log Entries, that Change Log is optional), CHANGELOG (version stays 29.0.0.0), TODO "NFR-005 sandbox checks".
