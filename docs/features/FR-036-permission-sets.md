# FR-036 Permission Sets

## Purpose
Four assignable roles for the app (GitHub issue #74): Equipment Reader, Equipment Manager, Equipment Administrator and the new **Equipment API Consumer**. The first three already existed (NFR-002, extended by FR-010 to FR-035) and were audited, not changed. This feature adds the API Consumer set (data access through the four API pages only, no UI pages, no queries) and automated structural tests for all four sets.

Status: implemented on branch `feature/FR-036-permission-sets`, not committed, not merged. App version stays 29.0.0.0 (unreleased, no bump, no upgrade code). No table, field, event or existing permission set changed.

Decisions (approved): D1 full (API Consumer gets everything API v1.0 exposes, including writes), D2 no (no DELETE on equipment through the API).

## Verification status
- **Build:** app and test app compile with 0 errors and 0 warnings on CodeCop and UICop.
- **Review:** APPROVE, no blockers.
- **Tests: written, compile, NOT executed.** Test codeunit 50162 "EQM Role Permission Tests" (14 test procedures) has not been run: no BC sandbox was available. Nothing here claims the tests pass.
- **Not verified:** sandbox scenarios S1 to S4 (permission enforcement). See `docs/TODO.md`, section "FR-036 Permission Sets".

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| PermissionSet | 50104 | EQM - API Consumer | New, `app/src/Permissions/EQMAPIConsumer.PermissionSet.al`. Caption "Equipment API Consumer", `Assignable = true`, no `IncludedPermissionSets` |
| Codeunit (test) | 50162 | EQM Role Permission Tests | New, `test/src/EQMRolePermissionTests.Codeunit.al` |
| PermissionSet | 50100, 50101, 50102 | EQM - Reader, Manager, Administrator | Unchanged |
| PermissionSetExtension | 50103 | D365 BASIC | Unchanged |

## Roles
| Role ID | Caption | Includes | For |
|---|---|---|---|
| EQM - Reader | Equipment Reader | none | View everything in the app, change nothing |
| EQM - Manager | Equipment Manager | Reader | Daily work: equipment, assignments, maintenance, warranty alerts, notes, requests, attachments |
| EQM - Administrator | Equipment Administrator | Manager | Setup, categories, deleting equipment, integration event cleanup, job queue |
| EQM - API Consumer | Equipment API Consumer | none | Service-to-service access through API v1.0 (Microsoft Entra application), no UI |

All four need the base-app prerequisite **D365 BASIC** (Employee, Location, No. Series and User reads come from it; the app's extension 50103 adds what the app needs to that set's users). Direct Employee read was rejected in NFR-002 for personal data.

## Permission matrix (effective rights, table data)
Capital = direct, lowercase = indirect (only through the app's own code), "-" = none.
| Table | Reader | Manager | Administrator | API Consumer |
|---|---|---|---|---|
| 50100 EQM Equipment | R | RIM | RIMD | RIM |
| 50101 EQM Equipment Category | R | R | RIMD | R |
| 50102 EQM Equipment Setup | R | R | RIMD | R |
| 50103 EQM Equipment Assignment | R | Rim | Rim | Rim |
| 50105 EQM Maintenance Record | R | RIM | RIM | R |
| 50110 EQM Integration Event Entry | R | Ri | Rim + D | Rim |
| 50112 EQM Equipment Audit Entry | R | Ri | Ri | ri |
| 50106, 50107, 50108, 50109, 50111 and Document Attachment | R | as in the Manager file | as Manager | - |
| No. Series, No. Series Line, Job Queue Entry | - | - | ri, ri, rim | - |

Notes:
- The "Rim + D" for Integration Event Entry comes from Manager `i` plus Administrator `mD` on top of Reader `R`.
- Why API Consumer has what it has: equipment RIM for POST and PATCH (no D by D2; deletion stays with Administrators per NFR-002); assignment Rim and integration event Rim through the `assign`, `returnEquipment` and `markProcessed` actions; Maintenance Record `R` because assign and status checks read open maintenance; Audit Entry `ri` because the audit codeunit 50135 writes entries on POST, PATCH, assign and return.
- Manager, Administrator and Reader lines for tables 50106 to 50111 are in the existing files and were not re-derived here.

### API Consumer execute rights (X)
- Tables: 50100, 50101, 50102, 50103, 50105, 50110, 50112.
- Pages: 50123 "EQM Equipment API", 50124 "EQM Category API", 50125 "EQM Assignment API", 50126 "EQM Integration Event API". No UI page, no query.
- Codeunits (write path): 50106 Assignment Mgt., 50108 Maintenance Mgt., 50119 Business Events, 50120 Business Event Subscr., 50121 Integration Event Subscr., 50122 Integration Event Mgt., 50130 Power Automate Events, 50131 Power Automate Subscr., 50135 Audit Trail Mgt., 50136 Audit Trail Subscr.

## Audit of the existing sets
Done on this branch against the code and the plan; no change needed.
- Reader has X on all tables, queries, pages and codeunits of the app. The only objects without X are codeunits 50104 EQM Install, 50133 EQM Change Log Registration and 50134 EQM Upgrade, which run only during install or upgrade.
- Reader has no Insert, Modify or Delete. Manager = Reader + writes on equipment, assignments, maintenance, warranty alerts, notes, requests and attachments, and no Delete on equipment, categories or setup. Administrator = Manager + delete, categories, setup, integration event cleanup, No. Series and Job Queue rights.
- All three are `Assignable = true`; Manager includes Reader, Administrator includes Manager.
- Rights listed in the plan matrix match the permission set files, except the ordering note under Discrepancies.

## Tests (codeunit 50162, compile only)
14 test procedures, structural: they read "Expanded Permission", "Metadata Permission Set", "Metadata Permission Set Rel.", "Page Metadata" and "AllObjWithCaption" and write nothing. They cover plan scenarios 1 to 8: set existence, assignable and includes; API Consumer rights equal to the matrix; no access to other data, no write on categories, setup, maintenance, no delete; no UI page, query or non-API page; every API page in 50100-50149 present in Reader and API Consumer; Administrator at least as strong as API Consumer; Reader read-only; Manager without delete on equipment, categories and setup; Reader X on every object except the three install and upgrade codeunits.
They do not test enforcement (see sandbox checks).

## Rule for later features (drift)
A feature that adds a codeunit on the equipment write path (called by an API action) must add X to **EQM - API Consumer** as well as Reader. A new API page must be added to both sets; test `EveryApiPageIsInReaderAndApiConsumer` covers API pages in 50100-50149 only, not codeunits. API page IDs 50127 to 50129 are reserved for later features.

## Setup
No app setup. For service-to-service use, see the help article: create a Microsoft Entra application card in Business Central and assign **EQM - API Consumer** and **D365 BASIC**.

## Events
None published or subscribed. Partners extend roles with a `permissionsetextension` or `IncludedPermissionSets` of their own.

## Compatibility
Additive only. After the first AppSource release, the Role ID "EQM - API Consumer" is stored on users, Entra applications and security groups and becomes a contract; the caption can still change. Removing rights later is a behavior change that needs release notes.

## Translations
One new caption ("Equipment API Consumer") in `app/Translations/Equipment Management.g.xlf`, regenerated by the build.

## Not verified (TODO(verify))
- Test codeunit 50162: not executed.
- S1 An Entra application with API Consumer + D365 BASIC can GET all four entities, POST and PATCH equipment, run `assign`, `returnEquipment`, `markProcessed` without a permission error.
- S2 DELETE equipment and PATCH on categories are refused.
- S3 A user with only API Consumer + D365 BASIC gets a permission error opening Equipment List or Card (page X enforcement is platform behavior).
- S4 GET `/companies` (standard API) works for that application; if not, the extra set needed is unknown.
- Number series use for POST with a blank number by non-SUPER users (NFR-002 R3).

## Discrepancies plan vs code
- The plan says tabledata lines in API Consumer follow table ID order. The file lists them alphabetically by table name, like the existing Reader set. The existing convention won; review marked this optional and minor. Rights are not affected.
- Test count: the plan lists 8 scenarios; the codeunit has 14 test procedures (scenarios split into several procedures).
