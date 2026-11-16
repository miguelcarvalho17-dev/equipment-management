# Event search report: FR-034 Change Log Support

**Feature:** Support Business Central Change Log monitoring for status, assignment, warranty and category changes (traceability and compliance).
**Target:** BC 29 (Base Application 29.0.54011.57272, System 29.0.57237.0), AppSource mode  |  Symbols from app/.alpackages checked: yes  |  Base app source available: no (BASEAPP_SOURCE_PATH not set; where events are raised was NOT verified)

## Recommendation
**No event subscription is needed to make our tables and fields loggable. There is no published "register loggable table/field" event.** The standard Change Log is data-driven: `Change Log Setup` (402), `Change Log Setup (Table)` (403) and `Change Log Setup (Field)` (404) are plain tables, and any table or field can be logged by inserting rows. The recommended extension point is therefore **writing setup records from the install codeunit** (existing `EQM Install`, `OnInstallAppPerCompany`), plus an upgrade codeunit for existing tenants. This is a table-data mechanism, not an event.

Symbol facts (from SymbolReference.json of Base Application, not guessed):
- Table 402 "Change Log Setup": `Primary Key` Code[10], `Change Log Activated` Boolean.
- Table 403 "Change Log Setup (Table)": `Table No.`, `Log Insertion` / `Log Modification` / `Log Deletion` as Option ` ,Some Fields,All Fields`, `Monitor Sensitive Field`.
- Table 404 "Change Log Setup (Field)": `Table No.`, `Field No.`, `Log Insertion`, `Log Modification`, `Log Deletion` (Boolean), `Monitor Sensitive Field`, `Notify`.
- Codeunit 423 "Change Log Management" declares permissions `r` on 402/403/404 and `ri` on Change Log Entry; no `Access` restriction shown for the setup tables.

Proposed setup rows (field numbers from app/src, table 50100 "EQM Equipment"):
| Requirement | Table | Field(s) | Setting |
|---|---|---|---|
| Status changes | 50100 | 9 Status | Table 403: Log Modification = Some Fields; Table 404 row Log Modification = true |
| Assignment changes | 50100 | 10 Assigned Employee No. | same; Log Modification |
| Warranty changes | 50100 | 17 Warranty Start Date, 18 Warranty End Date, 19 Warranty Provider, 20 Warranty Reference No. | same; Log Modification |
| Category changes | 50100 | 3 Category Code | same; Log Modification |
| Category master data (optional) | 50101 | all | Log Insertion/Modification/Deletion = All Fields (decision for planner) |
| Assignment history (optional) | 50103 | Status (6) etc. | Entries are already history rows; logging is likely redundant (decision for planner) |

Logging activation: set `Change Log Setup."Change Log Activated"` to true. This is a company-wide switch affecting all tables and can be a performance and policy decision for the customer. Recommend: register our rows by default, but do NOT silently flip the global switch on install without a documented decision (planner to decide; suggest an "EQM Equipment Setup" action or a notification that prompts an admin). Confidence in this point: medium (design choice, not an API fact).

- Moment: install/upgrade time; rows exist before the first equipment change.
- Data: no event data needed; field numbers come from our own tables (use `Database::"EQM Equipment"` and `Rec.FieldNo(...)`, not literals).
- Frequency: once per install/upgrade. Make the insert idempotent (check existence, never overwrite a customer's choices).
- Override: n/a.
- Permissions: the installing/admin user needs insert/modify on tabledata 402/403/404; add them to the Permissions property of the codeunit that writes them (indirect) and verify in sandbox. The runtime logging itself runs under Change Log Management's own permissions.
- Confidence: **medium-high** that this approach works (table structure verified in symbols), **low-medium** on exact runtime behavior (not verified in source or sandbox).
- Verify: (1) in a sandbox, insert the rows and change Status/Category/Employee/Warranty fields through UI and through code with `Modify(true)`, and confirm Change Log Entries appear; (2) confirm that code paths using `Modify(false)` or `RecordRef` without triggers are not logged (the Change Log depends on database triggers, see below); (3) confirm option semantics of "Some Fields" against the Change Log Setup (Table) page.

## Alternatives considered
| Candidate | Published signature (from symbols) | Why ranked lower / when to use |
|---|---|---|
| Codeunit 49 "GlobalTriggerManagement" `OnAfterGetDatabaseTableTriggerSetup` | `(TableId: Integer, var OnDatabaseInsert, var OnDatabaseModify, var OnDatabaseDelete, var OnDatabaseRename: Boolean)` | Not needed to enable logging of our tables if rows exist in 403/404 (assumed: Change Log Management enables the triggers from setup; unverified). Use only if sandbox shows our tables do not fire. Hooks a global trigger path; wrong use adds overhead to every record operation. |
| Codeunit 49 `OnAfterGetGlobalTableTriggerMask` | `(TableID: Integer, var TableTriggerMask: Integer)` | Same reason; lower-level than the setup tables. |
| Codeunit 423 "Change Log Management" `OnAfterIsAlwaysLoggedTable` | `(TableID: Integer, var AlwaysLogTable: Boolean)` | Forces a table to be always logged regardless of setup, which overrides the customer's configuration. Use only if compliance requires non-disableable logging (a stronger stance; needs product decision). Raised where: not verified. Candidate if "logging cannot be turned off" becomes a requirement. |
| Codeunit 423 `OnAfterLogModification` / `OnAfterLogInsertion` / `OnAfterLogDeletion` | `(var RecRef: RecordRef)` | Notification after an entry is logged; useful only to react to changes (for example an alert), not to enable logging. Fires for every logged table; early exit on `RecRef.Number`. |
| Codeunit 423 `OnBeforeLogModification` / `OnBeforeLogInsertion` / `OnBeforeLogDeletion` / `OnBeforeLogRename` | `(var RecRef: RecordRef)` (rename adds `var xRecRefParam: RecordRef`) | Same: reaction hooks, no registration. No IsHandled parameter, so they cannot suppress logging. |
| Codeunit 423 `OnInsertLogEntryOnBeforeInitChangeLogEntry` | `(var ChangeLogEntry: Record "Change Log Entry")` | Only if entries must be enriched; not required by FR-034. |
| Codeunit 423 `OnInsertLogEntryOnBeforeChangeLogEntryValidateChangedRecordSystemId` | `(var ChangeLogEntry, RecRef, FldRef)` | Internal-detail event; fragile. Not needed. |
| Table 405 "Change Log Entry" `OnAfterIsProtected` | `(var ChangeLogEntry, var ProtectedRecord: Boolean)` | Relevant only for protecting entries from deletion. Possible compliance add-on, not part of FR-034's stated scope. |
| Page 593 "Change Log Setup (Table) List" `OnBeforeUpdateRec` / `OnAfterGetRec`; Page 594 "Change Log Setup (Field) List" `OnBeforeUpdateRec` | UI-level hooks | Fire only on the setup pages; not suitable for default registration. |
| Own subscribers on `EQM Equipment` field `OnAfterValidateEvent` (implicit) or own log table | n/a | Duplicates the standard Change Log; FR-006 already provides assignment history. Do not reimplement. |
| Page extension or action on the Equipment Card opening the Change Log Entries filtered to the record | n/a (no event) | Good complement for traceability UX (open `Change Log Entries` filtered by `Table No.` and `Primary Key`). Page name not searched; planner to confirm. |

## Published events found (from symbols)
| Object | Event | Signature | Relevant? |
|---|---|---|---|
| Codeunit 423 "Change Log Management" | OnAfterIsAlwaysLoggedTable | TableID: Integer, var AlwaysLogTable: Boolean | Possible (forced logging) |
| Codeunit 423 | OnBeforeLogInsertion / OnAfterLogInsertion | var RecRef: RecordRef | Reaction only |
| Codeunit 423 | OnBeforeLogModification / OnAfterLogModification | var RecRef: RecordRef | Reaction only |
| Codeunit 423 | OnBeforeLogDeletion / OnAfterLogDeletion | var RecRef: RecordRef | Reaction only |
| Codeunit 423 | OnBeforeLogRename | var RecRef, var xRecRefParam: RecordRef | Reaction only |
| Codeunit 423 | OnLogModificationOnBeforeCheckSecurityFiltering / OnLogModificationOnAfterCheckSecurityFiltering | var xRecRef: RecordRef | No |
| Codeunit 423 | OnLogModificationOnBeforeRecRefLoopStart | var RecRef, var xRecRef: RecordRef | No |
| Codeunit 423 | OnInsertLogEntryOnBeforeInitChangeLogEntry | var ChangeLogEntry | No |
| Codeunit 423 | OnInsertLogEntryOnBeforeChangeLogEntryValidateChangedRecordSystemId | var ChangeLogEntry, RecRef, FldRef | No |
| Table 405 "Change Log Entry" | OnAfterIsProtected | var ChangeLogEntry, var ProtectedRecord | Optional |
| Codeunit 49 "GlobalTriggerManagement" | OnAfterGetDatabaseTableTriggerSetup | TableId, var OnDatabaseInsert/Modify/Delete/Rename | Fallback only |
| Codeunit 49 | OnAfterGetGlobalTableTriggerMask | TableID, var TableTriggerMask | Fallback only |
| Page 593 / 594 (setup lists) | OnBeforeUpdateRec, OnAfterGetRec | see above | No |

Subscriber attribute lines are available from `scripts/list_events.py` output; these use namespace `System.Diagnostics` / `System.Environment` (add `using` as needed in BC 29). Only needed if a fallback is chosen.

## Gaps and risks
- No published event for "register a table or field as loggable". Registration is by data in tables 403/404. This is the answer to "is there a suitable event": **no, none is needed**.
- Base app source is not available, so where each event is raised and how Change Log Management decides which tables fire database triggers was not verified. Recommend an Event Recorder or sandbox test.
- Change Log only captures changes that run triggers: `Modify(false)`, `ModifyAll` without trigger, or code that bypasses table triggers are not logged. Check our codeunits (for example the assignment and maintenance codeunits that set Status and Assigned Employee No.) use `Modify(true)`; this was not verified in this search.
- `Change Log Activated` is a global company switch; enabling it by default has a performance and policy impact. Needs a human decision.
- Table 403 `Log Modification` uses the options ` `, `Some Fields`, `All Fields`; with "Some Fields", rows in 404 decide the fields. Inserting rows into 404 while 403 is ` ` logs nothing (assumed, to be verified).
- AppSource: writing to base tables 402/403/404 is allowed (data, not object modification), but the app needs `tabledata` permissions for these tables; AppSourceCop may flag direct access; verify at build.
- Equipment Status and warranty-status fields: "Warranty Status" is an enum (EQMWarrantyStatus.Enum.al) but was not found as a stored table field in the field list I read (fields 17-20 are the stored warranty fields); the planner should confirm whether warranty status is calculated; calculated values are not logged.
- Existing installs: `OnInstallAppPerCompany` runs only on first install, so an upgrade codeunit is also needed (not searched).
