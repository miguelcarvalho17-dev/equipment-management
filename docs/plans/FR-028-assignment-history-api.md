# FR-028 Assignment History API

> Status: **approved** (Q1 resolved: exclude `assignedBy`/`closedBy`). Source: GitHub issue #66. Branch `feature/FR-028-assignment-history-api`. No base behavior touched (own table only), so no events report is needed. Binding conventions: C1 to C10 in `docs/plans/FR-026-equipment-api.md` (FR-026 and FR-027 are already on `main`). C7 already settles that this entity is read-only.

## Goal
Expose the assignment history of table 50103 "EQM Equipment Assignment" (FR-004/FR-005/FR-006) through the custom API v1.0, so reporting and analytics platforms can read equipment movements (who had which equipment, from when to when) without database access. The entity is read-only (GET only). It returns all entries, both active and closed. Entries are still created and closed only by the app.

## Approach and rejected alternatives
- Chosen: one read-only API page on table 50103 (C1 + C7), entity `assignment`/`assignments` (C2), with flattened code fields (C4) and the status enum (C5). No codeunit, no table change, no bound actions.
- Rejected: writes (POST/PATCH/DELETE): entries are app-managed history (the table blocks changes to closed entries). Assign/return already exist as bound actions on `equipments` (FR-026). C7 also fixes this entity as read-only.
- Rejected: an `assignments` part nested under `equipments`: C4 rules out navigation parts in v1.0, and it would change the frozen FR-026 page.
- Rejected: API query object (for example, with a join to the equipment description): it has no `SystemId` key or single-entity GET by id, and it breaks the "one API page per entity" rule in C9.
- Rejected: exposing the FlowField "Equipment Description" or employee names: C4 keeps relationships as codes. Clients join on `equipmentNumber` with `equipments`. Employee data is not in the EQM sets.

## Objects
IDs in use (checked `app/src`, `test/src`): pages 50100-50124 and 50130-50131, codeunits 50103-50118, tables 50100-50109; test codeunits 50178-50181 and 50183. Page 50125 and test codeunit 50182 are reserved for FR-028 by FR-026 C10, and they are free.
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Page (API) | 50125 | EQM Assignment API | New | `assignments` entity, file `app/src/API/EQMAssignmentAPI.Page.al`, SourceTable "EQM Equipment Assignment" |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | `page "EQM Assignment API" = X` |
| Codeunit (test) | 50182 | EQM Assignment API Tests | New | Automatable scenarios below, `test/src/EQMAssignmentAPITests.Codeunit.al` |

## Data model and upgrade impact
- No new fields or tables, and no upgrade codeunit. Page fields, in this order (API name <- table field; all are read-only because the page is not editable): `id` <- SystemId, `entryNumber` <- "Entry No.", `equipmentNumber` <- "Equipment No.", `employeeNumber` <- "Employee No.", `assignmentDate` <- "Assignment Date", `status` <- Status (enum: `Active`/`Closed`), `closingDate` <- "Closing Date", `lastModifiedDateTime` <- SystemModifiedAt. Q1 resolved to exclude, so these are NOT added (would otherwise be `assignedBy` <- "Assigned By" after `assignmentDate`, and `closedBy` <- "Closed By" after `closingDate`). Captions are the table field captions ('Id', 'Entry No.', 'Equipment No.', 'Employee No.', 'Assignment Date', 'Status', 'Closing Date', 'Last Modified Date-Time'). DataClassification is unchanged: the table is CustomerContent, and the two user fields are EndUserIdentifiableInformation.

## Events
- Subscribed: none. Published: none (read-only page, no logic).

## Permissions
- EQM - Reader: add `page "EQM Assignment API" = X` directly after `page "EQM Category API" = X,` (C8/C9, API page ID order). Read access comes from the existing `tabledata "EQM Equipment Assignment" = R` in Reader. Manager and Administrator inherit it. No tabledata change.

## Compatibility
- Additive only. The only change to an existing object is one permission line, so there is no breaking risk. **At first AppSource release the page becomes a public contract:** v1.0 entity names, field names and types are frozen. Adding fields later is additive. Removing or renaming fields needs `v2.0` plus Obsolete on v1.0. `Extensible = false`.

## Implementation steps
1. Create page 50125 "EQM Assignment API" with the C1 properties (PageType API, APIPublisher 'miguelCarvalho', APIGroup 'equipment', APIVersion 'v1.0', ODataKeyFields SystemId, DelayedInsert true, Extensible false), EntityName 'assignment', EntitySetName 'assignments', EntityCaption 'Assignment', EntitySetCaption 'Assignments', Caption 'Assignment API', and the C7 properties (Editable false, InsertAllowed false, ModifyAllowed false, DeleteAllowed false, DataAccessIntent ReadOnly). Add a repeater with the fields in the Data model order. No triggers, no procedures, no SourceTableView (default key Entry No.). Same layout as page 50124. Compile.
2. Add the EQM - Reader line (see Permissions). Build the main app and commit the regenerated `.g.xlf`.
3. Create test codeunit 50182, following the pattern of 50181 (Subtype Test, TestPermissions Disabled, AutoRollback per test, `Library Assert`, Locked test labels with prefix `EQMASG`). Build the history in Initialize through `AssignEmployee`/`UnassignEmployee` on table 50100 (internalsVisibleTo already set), not through direct inserts. Implement scenarios 1-5 at table level (HTTP calls cannot authenticate in CI, see FR-026 Q3). Build the test app.
4. Documenter: write `docs/features/FR-028-assignment-history-api.md` and `docs/help/FR-028-assignment-history-api.md`. The help covers the URL `/api/miguelCarvalho/equipment/v1.0/companies({id})/assignments`, the fields, the filter examples `status eq 'Closed'`, `equipmentNumber eq 'X'` and `lastModifiedDateTime gt <dt>` for incremental sync, and the fact that the entity is read-only. Add a CHANGELOG section at the top and a `docs/TODO.md` section at the end with the sandbox checks (scenarios 6-11). Tick the FR-026 follow-up line for FR-028.

## Test scenarios
Setup: active category EQMASG-CAT, active employee EQMASG-E1, equipment E. E is assigned to E1 and returned (entry A1 Closed), then assigned again (entry A2 Active).
1. Given the setup, when the entries are read for E's number (the `$filter=equipmentNumber eq` equivalent), then exactly 2 are returned: A1 has Status Closed with Closing Date filled, and A2 has Status Active with Closing Date blank. Both have Employee No. E1 and Assignment Date filled.
2. Given the setup, when the entries are read with Status = Closed (the `status eq 'Closed'` equivalent), then only A1 is returned. With Status = Active, only A2 is returned.
3. Given A1, when it is read by its SystemId (GetBySystemId, the `assignments({id})` equivalent), then Entry No., Equipment No., Employee No. and Status match. (neg) When the read uses an unknown GUID, then no record is found.
4. Given A2, when E is returned (UnassignEmployee), then A2 keeps its SystemId, Status becomes Closed, and SystemModifiedAt is not earlier than before (incremental sync with `lastModifiedDateTime` picks up the change).
5. (neg) Given closed A1, when its Employee No. is modified with Modify(true), then the closed-entry error is raised and the entry is unchanged (history stays immutable).
6. Sandbox: when GET `.../assignments`, then 200 with the Data model fields (camelCase) for active and closed entries, and `status` values `Active`/`Closed`.
7. Sandbox: when GET `.../assignments({id})` with A1's SystemId, then a single entity is returned. With an unknown GUID, then 404.
8. Sandbox: when GET with `$filter=employeeNumber eq 'EQMASG-E1'` and with `$filter=lastModifiedDateTime gt <time before step 4>`, then only the matching entries are returned.
9. Sandbox (neg): when POST, PATCH or DELETE is sent on `assignments`, then the request is rejected (record the HTTP status) and no data changes.
10. Sandbox: `equipmentNumber` from `assignments` is found in GET `equipments`, and for A2 it matches that equipment's `assignedEmployeeNumber`.
11. Sandbox permissions (not SUPER): a user with only EQM - Reader gets 200 on GET. A user without any EQM set gets a permission error.

## Risks and open questions
- Q1 (privacy/design) **RESOLVED: exclude** (user decision): should the API expose `assignedBy`/`closedBy` (BC user names, EndUserIdentifiableInformation)? Options: **exclude** or include. **Decision: exclude** (recommended option): the issue asks for equipment movements (equipment, employee, dates, status), and user names add personal data to an external analytics feed. They can be added later in v1.0 as an additive change, but removing them later would be breaking.
- Assumed all entries (active and closed) are returned because "history" includes the current assignment, and clients filter on `status`.
- Assumed `entryNumber` is exposed because it is the stable natural key shown in the UI and gives a chronological sort (`$orderby=entryNumber`).
- Assumed no equipment description field because C4 keeps relationships as codes, and FR-026 exposes no FlowFields.
- Assumed APIPublisher `miguelCarvalho` and the URL `/api/miguelCarvalho/equipment/v1.0/...` because the issue URL omits the publisher and C1 fixes it.
- Risk: DataAccessIntent ReadOnly reads from a replica, so a just-closed entry can appear with a short delay. This is acceptable for analytics.
- V1 Unverified: the HTTP status for writes on a non-editable API page (scenario 9). Expected 4xx, to be recorded in the sandbox. The automated tests cover only table behavior; the API layer (scenarios 6-11) is checked manually, as in FR-026/FR-027.
