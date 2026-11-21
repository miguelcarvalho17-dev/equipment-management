# FR-057 Permission Review

## Purpose
Review of the app's permission sets for least privilege (GitHub issue #98, relates to NFR-002 and FR-036). The review adds one role, **Equipment Operator** (`EQM - Operator`), for day-to-day work on existing equipment. It sits between Reader and Manager. The existing sets are not narrowed in this phase: two findings (F1 and F2 below) would remove or change rights, and that needs user approval.

Status: implemented on branch `feature/FR-057-permission-review`, not committed, not merged. App version stays 29.0.0.0 (no bump, no upgrade code). No table, field, page, codeunit, event or existing permission set changed.

Decision (approved by the user): a new permission set `EQM - Operator` that includes Reader, instead of making Manager include Operator. Manager and Administrator keep their hierarchy. The other decisions are in the plan, section DECISIONS (`docs/plans/FR-057-permission-review.md`).

## Verification status
- **Build:** the reviewer returned APPROVED. The build result is in the pull request.
- **Tests: written and compiled, NOT executed locally.** Seven test procedures (scenarios 12 to 15) were added to test codeunit 50162 "EQM Role Permission Tests". CI result pending.
- **Not verified:** sandbox checks OP-SB1 to OP-SB8 (see `docs/TODO.md`, section "FR-057 sandbox checks").
- No separate AppSource validation ran.

## Objects
| Type | ID | Name | Change | File |
|---|---|---|---|---|
| PermissionSet | 50105 | EQM - Operator | New, caption "Equipment Operator", `Assignable = true`, `IncludedPermissionSets = "EQM - Reader"` | `app/src/Permissions/EQMOperator.PermissionSet.al` |
| Codeunit (test) | 50162 | EQM Role Permission Tests | Changed, 7 test procedures added | `test/src/EQMRolePermissionTests.Codeunit.al` |
| Translations | - | Equipment Management.g.xlf, pt-PT, es-ES | One unit added (the Operator caption) | `app/Translations/` |

Unchanged: permission sets 50100 (Reader), 50101 (Manager), 50102 (Administrator), 50104 (API Consumer, see FR-036) and the D365 BASIC extension 50103.

## Roles
| Role ID | Caption | Includes | For |
|---|---|---|---|
| EQM - Reader | Equipment Reader | none | View everything in the app, change nothing |
| EQM - Operator | Equipment Operator | Reader | Day-to-day work on existing equipment: assign and return, register and post maintenance, notes, warranty alerts (acknowledge and generate) |
| EQM - Manager | Equipment Manager | Reader | Daily work: create and change equipment, requests, attachments and everything the Operator does. Does not include Operator; test T6 proves Manager covers every Operator right |
| EQM - Administrator | Equipment Administrator | Manager | Setup, categories, deleting equipment, integration event cleanup, job queue, error log, demo data |
| EQM - API Consumer | Equipment API Consumer | none | Service-to-service access through API v1.0 (Microsoft Entra application), no UI (FR-036) |

All roles need the base-app prerequisite **D365 BASIC**, as in FR-036.

## Permission matrix (table data and execute)
Capital letter = direct, lowercase = indirect (only through the app's own code), "-" = none. Letters are the ones declared in each permission set file. Reader's `R` is included in Operator, Manager and Administrator through the include.

| Table | Reader | Operator | Manager | Administrator |
|---|---|---|---|---|
| 50100 EQM Equipment | R | RM | RIM | RIMD |
| 50101 EQM Equipment Category | R | R | R | RIMD |
| 50102 EQM Equipment Setup | R | R | R | RIMD |
| 50103 EQM Equipment Assignment | R | Rim | Rim | Rimd |
| 50105 EQM Maintenance Record | R | RIM | RIM | RIMd |
| 50106 EQM Maintenance History Entry | R | i | i | id |
| 50107 EQM Warranty Alert | R | RIM | RIM | RIMd |
| 50108 EQM Maintenance Log Entry | R | i | i | id |
| 50109 EQM Equipment Note | R | RI | RI | RI |
| 50110 EQM Integration Event Entry | R | i | i | imD (Manager `i`, Administrator `mD`) |
| 50111 EQM Equipment Request | R | R | RIMD | RIMD |
| 50112 EQM Equipment Audit Entry | R | i | i | id |
| 50114 EQM Feature Setup | R | R | R | RIMD |
| 50115 EQM Error Log Entry | - | - | - | RD |
| 50149 EQM Demo Data Entry | - | - | - | rimd |
| Document Attachment (standard) | R | R | RIMD | RIMD |
| No. Series, No. Series Line (standard) | - | - | - | ri |
| Job Queue Entry (standard) | - | - | - | rim |

Execute (X): Reader has X on every object of the app (tables, queries, reports, pages, codeunits) except the install, change log registration and upgrade codeunits 50104, 50133 and 50134. Operator, Manager and Administrator include Reader, so they have the same Execute rights. Execute grants no data by itself.

API Consumer is unchanged. Its matrix is in `docs/features/FR-036-permission-sets.md`.

### Effective rights of Operator (checked by test T2)
Read, Insert, Modify, Delete, Execute. Y = direct, I = indirect, - = none.

| Table | Operator |
|---|---|
| 50100 Equipment | Y-Y-- |
| 50101 Category | Y---- |
| 50102 Setup | Y---- |
| 50103 Assignment | YII-- |
| 50105 Maintenance Record | YYY-- |
| 50106 Maintenance History Entry | YI--- |
| 50107 Warranty Alert | YYY-- |
| 50108 Maintenance Log Entry | YI--- |
| 50109 Equipment Note | YY--- |
| 50110 Integration Event Entry | YI--- |
| 50111 Equipment Request | Y---- |
| 50112 Audit Entry | YI--- |
| 50114 Feature Setup | Y---- |
| 50115 Error Log Entry | ----- |
| 50149 Demo Data Entry | ----- |
| Document Attachment | Y---- |

What the Operator cannot do: create equipment, delete anything, change categories, setup or feature setup, create or decide requests, change attachments, read the error log, read demo data, or delete job queue entries.

## Audit of the existing sets
Done on this branch against the permission set files and the code paths. No change in phase 1.
- **Reader:** R on 13 EQM tables plus Document Attachment. X on every object except 50104, 50133 and 50134. Least privilege OK. X on codeunits grants no data.
- **Operator (new):** R plus the writes listed in the matrix. Each write is traced to the code path that needs it (equipment: assign, return and maintenance modify table 50100 directly; assignments: written only through the assignment codeunit; audit, integration, history and log: written by their codeunits with indirect insert; maintenance record: registering and posting; warranty alert: Acknowledge and Generate in the page; note: the notes part inserts). Known limit: Operator can edit equipment fields, including Status and the name (phase 3).
- **Manager:** matches its role. Request Delete is limited to Open requests by the OnDelete guard. Direct `I` on Warranty Alert is needed for the manual Generate action. Finding F1 applies.
- **Administrator:** OK. Indirect `d` only for Demo Data (FR-066), Error Log RD (FR-051), No. Series and Job Queue (indirect only).
- **API Consumer:** unchanged from FR-036. No UI pages.
- **D365 BASIC extension 50103:** indirect `r` only, on its own table only (Microsoft Learn best practice).
- **F1 (phase 2, approval needed):** Direct RIMD on the standard Document Attachment table (Manager and Administrator) and direct R (Reader, Operator) apply to attachments of every Business Central record, not only equipment. Narrowing needs a sandbox check of what D365 BASIC already grants, plus user approval for removing rights.
- **F2 (phase 2, observation):** Reader R on Audit Entry and Integration Event Entry exposes user IDs to every Reader, and to Operator, Manager and Administrator. Kept for now, because NFR-002 defined Reader as "view all". Narrowing needs approval.

## Tests
All in codeunit 50162 "EQM Role Permission Tests" (`TestPermissions = Disabled`, structural: reads permission metadata, writes nothing).
| Procedure | Scenario | Checks |
|---|---|---|
| OperatorIsAssignableAndIncludesOnlyReader | 12 | Exists, assignable, one include relation, to EQM - Reader |
| OperatorTableDataMatchesMatrix | 13 | Effective tabledata equals the matrix for all 16 tables and Document Attachment |
| OperatorCannotCreateEquipmentOrDeleteAnything | 13 (negative) | No Insert on equipment; no Delete on any table |
| OperatorCannotWriteMasterDataSetupOrRequests | 13 (negative) | No Insert, Modify or Delete on Category, Setup, Feature Setup, Request and Document Attachment |
| OperatorHasNoAccessToErrorLogDemoDataOrJobQueue | 13 (negative) | No entry on Error Log, Demo Data Entry and Job Queue Entry |
| ManagerCoversEverythingOperatorCan | 14 | For every Operator entry, Manager's rights are equal or stronger |
| OperatorCanExecuteEverythingReaderCan | 15 | Operator has Execute wherever Reader has it |

The existing tests are expected to be unaffected: `ExistingRolesKeepTheirHierarchy`, `ReaderHasExecuteOnEveryObjectOfTheApp` and the API Consumer tests.

Not tested: enforcement (what a user actually gets in a session). That needs "Library - Lower Permissions" and a test-app dependency, which is out of scope (see the sandbox checks).

## Rule for later features (drift)
- A feature that adds a write path on a table, directly or through code, adds the matching `tabledata` line to **EQM - Manager**.
- When that write is part of day-to-day work on existing equipment, it is also added to **EQM - Operator**.
- T6 guarantees Manager covers Operator. It does not check that the list is complete. Review the new write path against this rule.
- A new API page is added to Reader and API Consumer (FR-036).

## Setup
No app setup. Assign roles to users in Business Central (Users, User Permission Sets). Steps for end users: `docs/help/FR-057-permission-review.md`.

## Events
None published or subscribed.

## Compatibility
Additive only. The existing four sets are unchanged. After the first AppSource release, the Role ID "EQM - Operator" is stored on users and security groups and becomes a contract; the caption can still change. Removing rights later (F1, F2) is a behaviour change that needs release notes.

## Translations
One new caption, "Equipment Operator", in `app/Translations/Equipment Management.g.xlf` (regenerated by the build). Portuguese (Portugal): "Operador de equipamento". Spanish (Spain): "Operador de equipo". Not reviewed by a native speaker.

## Out of scope and later phases
- **Phase 2:** narrow the direct Document Attachment rights (F1) and the Reader rights on audit and integration entries (F2). Needs a sandbox check and user approval.
- **Phase 3:** Operator UX. Equipment master fields read-only when the user has no Insert on equipment (code change on the card). Rename with attachments and status changes are the known limits.
- **Phase 4:** permission enforcement tests with "Library - Lower Permissions" (needs a test-app dependency).

## Not verified (TODO(verify))
- Test codeunit 50162, seven new procedures: not executed locally. CI result pending.
- OP-SB1 to OP-SB8 in `docs/TODO.md`: enforcement in a sandbox, including number series consumption for maintenance and the picture edit path (`Record.WritePermission()`).
- The D365 BASIC contents (Document Attachment, number series) are not verifiable from symbols.
