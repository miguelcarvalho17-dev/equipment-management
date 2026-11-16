# FR-036 Permission Sets

> Status: **Approved (D1 full, D2 no).** Source: GitHub issue #74. Branch `feature/FR-036-permission-sets`. No events report: no standard behavior is touched. No version bump (29.0.0.0, unreleased). No upgrade code. No change to existing permission sets or other objects.
> **Open decisions (the plan uses the recommended default, so each answer can be one word):**
> - **D1 API Consumer scope.** **full** (recommended): everything API v1.0 exposes (GET on all four entities; POST/PATCH equipment; `assign`, `returnEquipment`, `markProcessed`), because FR-026 targets sync/CMDB/mobile writers and FR-030 polling needs `markProcessed`. **read**: GET only. The set then has only `R` on 50100, 50101, 50103, 50110 and X on the 4 API pages and those 4 tables, with no codeunits. Scenarios 2 and S1 change to "writes denied".
> - **D2 DELETE equipment through the API.** **no** (recommended): API Consumer gets RIM on equipment, because NFR-002 Q1 limits deletion to Administrators. **yes**: RIMD (then scenario S2 expects success).

## Goal
Ship the four roles from the issue as assignable AL permission sets. Equipment Reader, Equipment Manager and Equipment Administrator already exist (NFR-002, extended by FR-010 to FR-035). An audit shows they match the issue and cover every object. This feature adds **Equipment API Consumer**: data access through the four API pages only, with no UI pages and no queries. Automated structural tests protect all four sets.

## Approach and rejected alternatives
- Chosen: one new permission set object 50104 "EQM - API Consumer" (18 chars, Role ID limit 20), `Assignable = true`, **no** `IncludedPermissionSets`, least privilege per table (matrix below). Sets 50100-50102 and the D365 BASIC extension 50103 stay unchanged. Audit on this branch: Reader has X on all 13 tables, 4 queries, 34 pages and 24 codeunits. The only objects without X are 50104 EQM Install, 50133 EQM Change Log Registration and 50134 EQM Upgrade, which run only during install or upgrade. Manager = Reader + equipment/assignment/maintenance/warranty/notes/requests/attachments writes. Administrator = Manager + delete, categories, setup, job queue and integration cleanup.
- Rejected: including "EQM - Reader" in API Consumer. It brings X on every UI page and query, which contradicts "API access only".
- Rejected: a shared non-assignable "objects" set included by Reader and API Consumer. It refactors Reader to share about 10 codeunit lines, and NFR-002 rejected this already.
- Rejected: `permissionsetextension` on D365 AUTOMATION/BASIC (grants every user of those sets), entitlements (only for transact offers), `.permissionset.xml` (deprecated, AppSource requires AL objects), and code checks such as ClientType = Api (NFR-002: permissions are the only enforcement).

## Objects
IDs in use (checked `app/src`, `test/src`): permission sets 50100-50102, permission set extension 50103, test codeunits 50178-50193. 50162 is reserved by NFR-002 for "EQM Role Permission Tests" and is not built.
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| PermissionSet | 50104 | EQM - API Consumer | New | `app/src/Permissions/EQMAPIConsumer.PermissionSet.al`; Caption 'Equipment API Consumer' |
| Codeunit (test) | 50162 | EQM Role Permission Tests | New | `test/src/EQMRolePermissionTests.Codeunit.al`; structural checks of all four sets |

## Data model and upgrade impact
- No table, field or DataClassification change. No upgrade codeunit: the new set is metadata, and nothing is released.

## Events
- Subscribed: none. Published: none. Partners extend roles with `permissionsetextension` or `IncludedPermissionSets`.

## Permissions
Effective rights after inclusion (lowercase = indirect, "-" = none). Base tables Employee, Location, No. Series and User come from the documented prerequisite **D365 BASIC** for all four roles.
| Table | Reader | Manager | Administrator | API Consumer (new) |
|---|---|---|---|---|
| 50100 EQM Equipment | R | RIM | RIMD | RIM (D2) |
| 50101 Category, 50102 Setup | R | R | RIMD | R |
| 50103 Equipment Assignment | R | Rim | Rim | Rim |
| 50105 Maintenance Record | R | RIM | RIM | R (read by `HasOpenMaintenance` on assign/status checks) |
| 50110 Integration Event Entry | R | Ri | RimD | Rim (`markProcessed` via 50122) |
| 50112 Equipment Audit Entry | R | Ri | Ri | ri (written by 50135 on POST/PATCH/assign/return) |
| 50106, 50107, 50108, 50109, 50111, Document Attachment | R | as today | as today | - |
| No. Series / Line, Job Queue Entry | - | - | ri / rim | - |
API Consumer object X, grouped by type: tables 50100, 50101, 50102, 50103, 50105, 50110, 50112. Pages 50123 "EQM Equipment API", 50124 "EQM Category API", 50125 "EQM Assignment API", 50126 "EQM Integration Event API". Codeunits for the write path: 50106 Assignment Mgt., 50108 Maintenance Mgt., 50119 Business Events, 50120 Business Event Subscr., 50121 Integration Event Subscr., 50122 Integration Event Mgt., 50130 Power Automate Events, 50131 Power Automate Subscr., 50135 Audit Trail Mgt., 50136 Audit Trail Subscr. No UI page, no query, no X on 50103/50105 codeunits.

## Compatibility
- Additive only. **After first AppSource release the name "EQM - API Consumer" becomes a contract** (stored as Role ID on users, Entra apps and security groups). The caption can still change. Removing rights later is a behavior change that needs release notes.
- Existing sets 50100-50102 are not touched, so there is no breaking-change risk for them in this feature.

## Implementation steps
1. Create permission set 50104 in `app/src/Permissions/EQMAPIConsumer.PermissionSet.al`: namespace `MiguelCarvalho.EquipmentManagement`, Caption 'Equipment API Consumer', `Assignable = true`, no includes. Add tabledata lines in table ID order, then X lines (tables, pages, codeunits), exactly as in Permissions. Build the app and commit the regenerated `.g.xlf` (one new caption).
2. Test codeunit 50162. Follow the pattern of 50192: Subtype Test, `TestPermissions = Disabled`, Library Assert, Locked labels prefix `EQMRPS`. Read the platform table "Expanded Permission" (System.Security.AccessControl; filter "Role ID" in uppercase, e.g. 'EQM - API CONSUMER') for effective rights. Read "Aggregate Permission Set" or "Metadata Permission Set" for Assignable/Name. Read "AllObjWithCaption"/"Page Metadata" for object lists. Verify the table and field names in symbols first. If they cannot be read, stop and report. Build both apps.
3. Documenter: `docs/features/FR-036-permission-sets.md` (matrix, audit), `docs/help/FR-036-permission-sets.md` (which role for whom; assign API Consumer + D365 BASIC to a Microsoft Entra application card for service-to-service; it opens no UI pages), CHANGELOG, `docs/TODO.md` sandbox checks S1-S4, and the README row status.

## Test scenarios
Automated (50162, structural):
1. API Consumer exists, Assignable = true, includes no other set. The other three sets are unchanged (Reader standalone, Manager includes Reader, Administrator includes Manager, all Assignable).
2. API Consumer effective tabledata equals the matrix column exactly: e.g. equipment Read/Insert/Modify = Yes and Delete = none; Integration Event Entry Read = Yes, Insert/Modify = Indirect, Delete = none.
3. (neg) API Consumer has no tabledata entry for 50106, 50107, 50108, 50109, 50111, Document Attachment or Job Queue Entry, and no I/M/D on 50101, 50102 or 50105.
4. (neg) API Consumer has no X on any page in 50100-50149 whose PageType is not API, and no X on any query.
5. Every page with PageType API in 50100-50149 has X in API Consumer and in Reader. This guards the API IDs 50127-50129 reserved for later features.
6. For every API Consumer entry, Administrator's effective right is equal or stronger (Yes > Indirect > none), so admins can do everything the integration can.
7. (neg) Reader has no Insert/Modify/Delete (direct or indirect) on any EQM table. Manager has no Delete on 50100, 50101, 50102.
8. Every table, page, query and codeunit in 50100-50149 except codeunits 50104, 50133, 50134 has X in Reader (NFR-002 ST3).
Manual sandbox (permission mocking is unreliable per FR-023/FR-026):
- S1 An Entra app with API Consumer + D365 BASIC can GET equipments/categories/assignments/integrationEvents, POST equipment with a blank number, PATCH it, `assign`/`returnEquipment`, and `markProcessed`, with no permission error. Audit and assignment entries are written.
- S2 (neg) DELETE equipment fails with a permission error (D2), and PATCH on categories is rejected.
- S3 (neg) A user with only API Consumer + D365 BASIC who opens Equipment List or Card in the web client gets a permission error.
- S4 GET `/companies` (standard API) works for that app. If not, record the extra set needed in TODO.

## Risks and open questions
- D1, D2: see the top.
- Assumed Caption 'Equipment API Consumer' rather than 'API Consumer', because the tenant's permission set list mixes all apps and the other three captions start with "Equipment".
- Assumed no change to Reader/Manager/Administrator, because the audit shows they already meet the issue. Reopening Manager rights (e.g. deleting maintenance records) is out of scope.
- Assumed D365 BASIC as the API Consumer prerequisite (Employee read for `assign`, No. Series for POST, Location validation), as for all roles since NFR-002. Direct Employee `R` was rejected there for personal data.
- R1 Enforcement of page X for UI access is platform behavior and unverified (S3). R2 Number-series consumption for non-SUPER users is still unverified (NFR-002 R3).
- R3 Drift: a future feature that adds a codeunit on the equipment write path must add X to API Consumer as well as Reader. Scenario 5 guards API pages only. The documenter records this rule in the feature doc.
- R4 The names of the "Expanded Permission" and "Metadata Permission Set" tables and fields are unverified for BC 29 (step 2).
