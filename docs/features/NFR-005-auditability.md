# NFR-005 Auditability

## Purpose
Requirement: every maintenance operation leaves a permanent, read-only record of who did what and when, and maintenance data is never deleted. Status: **implemented, review APPROVE, build clean (CodeCop + UICop, 0 errors, 0 warnings). Not verified in a sandbox; automated tests deferred (plan Q3, codeunit 50177 reserved, not written).** App version stays 29.0.0.0 (not released, no upgrade code).

## What it does
| Operation | Log entry | Written by |
|---|---|---|
| Register a maintenance record | One `Registered` entry (at the end of `OnInsert`, after the equipment is set to In Maintenance) | Table 50105 `OnInsert` |
| Correct an open record | One `Changed` entry per audited field whose value differs, with old and new value | Table 50105 `OnModify` (compares the stored record with the new one) |
| Post | One `Posted` entry (after the history entry, before the equipment is completed) | Codeunit 50109 `OnRun` |

- Audited fields: Maintenance Date, Maintenance Type, Vendor No., Cost, Description, Performed By. Status, Equipment No., No. and No. Series are not compared. A `Modify` that changes none of the six writes no entry.
- Values are stored with `Format(value, 0, 9)` (XML format, plan Q4): unambiguous, not regional, less readable (for example dates as `2026-03-15`).
- Each entry stores User ID (`UserId()`) and Logged At (`CurrentDateTime()`). Old/New Value are truncated to 250 characters.
- Entries are written in the same transaction as the operation: if registering or posting fails and rolls back, no entry remains.
- Not a replacement for the base Change Log, which the app does not configure. A customer may enable it additionally.

## Objects
| Type | ID | Name | Purpose |
|---|---|---|---|
| Enum | 50107 | EQM Maintenance Log Action | Registered (0), Changed (1), Posted (2). `Extensible = false` |
| Table | 50108 | EQM Maintenance Log Entry | Append-only audit trail. `Access = Public`, `CustomerContent` |
| Codeunit | 50116 | EQM Maintenance Log Mgt. | `Access = Internal`, `Permissions = tabledata "EQM Maintenance Log Entry" = ri`. Procedures `LogRegistered`, `LogChanges`, `LogPosted` (all internal) |
| Page | 50121 | EQM Maintenance Log Entries | Read-only list, newest first, `UsageCategory = History` |
| Table | 50105 | EQM Maintenance Record | Own change: logging calls in `OnInsert`/`OnModify`, summary comment |
| Codeunit | 50109 | EQM Maintenance-Post | Own change: `LogPosted` call |
| Page | 50113, 50114 | EQM Maintenance Records / Record Card | Navigation action Log Entries (opens page 50121 filtered on the record), AboutText sentence |
| PermissionSet | 50100, 50101 | EQM - Reader / EQM - Manager | See Permissions |

## Fields of table 50108
| No. | Name | Meaning |
|---|---|---|
| 1 | Entry No. | AutoIncrement primary key. Gaps after rollbacks are possible. |
| 2 | Maintenance No. | The record the operation was performed on. Table relation without validation, so the entry survives whatever happens to the record. Secondary key. |
| 3 | Action | Registered, Changed or Posted. |
| 4 | Field No. | Field number in table 50105 that changed; 0 for Registered and Posted. |
| 5 | Field Caption | FlowField: caption looked up in the system table Field for table 50105 and Field No. Blank when Field No. is 0. |
| 6 / 7 | Old Value / New Value | XML-formatted values; blank for Registered and Posted. |
| 8 | User ID | User who performed the operation (`EndUserIdentifiableInformation`). |
| 9 | Logged At | Date and time of the operation. |

All fields are not editable. Insert is only possible through `AllowInsertFromLog` (internal), set by codeunit 50116; `OnModify`, `OnDelete` and `OnRename` always raise an error, also for Administrators.

## Setup
None. Logging cannot be switched off and needs no configuration. Users open the log with **Log Entries** on Equipment Maintenance or the Maintenance Record card, or search for "Maintenance Log Entries".

## Events
None published, none subscribed. Deliberate: an IsHandled event could let a subscriber disable the audit trail. Existing events on table 50105 and codeunit 50109 are unchanged; changes their subscribers make to the six audited fields before the stored `Modify` are logged.

## Permissions
| Permission set | Access |
|---|---|
| EQM - Reader | Read on table data 50108, execute on table 50108, page 50121, codeunit 50116 |
| EQM - Manager | Indirect insert (`i`) on table data 50108 (used by codeunit 50116) |
| EQM - Administrator | No change; inherits through the sets above. No set has delete on tables 50105, 50106 or 50108 |

## Known limitations
- Code that calls `Modify`/`Delete` with `RunTrigger = false` bypasses logging and the delete guard (only other extensions; delete additionally needs D, i.e. SUPER). Not fixable without global triggers.
- Records registered before this feature (development data) have no Registered entry.
- Changes to planned-maintenance fields on equipment (Last Maintenance Date, Maintenance Frequency) are not logged (plan Q1, default: maintenance records only).
- "Cancel" is still posting with cost 0 and a describing text (FR-012); there is no Cancelled status (plan Q2).
- Old/New Value can hold personal data such as the name in Performed By (classified CustomerContent; see the personal-data item in `docs/TODO.md`).

## Not verified
- **TODO(verify) R2:** the Field Caption FlowField reads the system table Field. Compiles clean, but not checked that non-SUPER users (Reader, Manager) see the caption. Fallback in the plan: store the caption as text at write time.
- **TODO(verify):** the text `Format(Maintenance Type, 0, 9)` produces for the enum (name or number) was not checked; Old/New Value for Maintenance Type may show differently than expected.
- **TODO(verify):** `OnModify` reads the stored record with `Get` to get the old values; behavior with two concurrent users and inside the post flow was not run.
- Plan test scenarios 1 to 11 were not run and no test code exists. Sandbox checks are listed in `docs/TODO.md` ("NFR-005 sandbox checks").

## Discrepancies plan vs code
None found. Object IDs, names, field IDs/types, triggers, audited fields, permissions and call sites match the plan. `AllowInsertFromLog` is `internal` as planned; no public procedure was added, so no new XML comments were needed (existing `///` comments on the new objects were checked).
