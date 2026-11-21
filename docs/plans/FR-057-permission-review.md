# FR-057 Permission Review — Plan

> Request (verbatim): "FR-057 Permission Review" (GitHub issue #98)
> Status: **approved** (user chose Option A: add the new permission set "EQM - Operator")

## Request
Review the app's permission sets for least privilege, and add the missing role "Equipment Operator" to the existing Reader, Manager, Administrator and API Consumer roles (GitHub issue #98, relates to NFR-002 and FR-036).
Target: AppSource

## Definition of done
- [ ] `app/src/Permissions/EQMOperator.PermissionSet.al` exists: permissionset 50105 "EQM - Operator", Caption 'Equipment Operator', `Assignable = true`, `IncludedPermissionSets = "EQM - Reader"`, exactly the 9 tabledata lines of Step 1.
- [ ] Sets 50100, 50101, 50102, 50104 and extension 50103 are byte-identical to `main`.
- [ ] The Operator's effective rights equal the matrix in Step 1 (asserted by test T2).
- [ ] The Operator has no Insert on equipment and no Delete on any table. It has no write rights on Category, Setup, Feature Setup, Equipment Request or Document Attachment, and no entry on Error Log, Demo Data Entry or Job Queue Entry (T3-T5).
- [ ] Manager's effective rights are equal to or stronger than the Operator's on every Operator entry (T6).
- [ ] `app/` builds with 0 errors and 0 warnings (CodeCop, UICop, AppSourceCop). `test/` builds with 0 errors and 0 warnings.
- [ ] `Equipment Management.g.xlf` has the new caption. The pt-PT and es-ES files translate it. `python3 .github/scripts/xlf_sync.py check` and `repo_checks.py` pass.
- [ ] Docs: feature doc with the audit table, help article, CHANGELOG heading `## FR-057 ...`, TODO sandbox checks OP-SB1 to OP-SB8, and a plan header line `> Status:`.
- [ ] Tests compile. Report "Not verified: tests not executed locally, CI result pending".

## Out of scope
- No removal or narrowing of any right in the existing sets. Audit findings F1 and F2 are recorded for phase 2 and need user approval (stop list).
- No change to the Manager hierarchy: Manager keeps including Reader and does not include Operator.
- No code changes in pages, tables or codeunits, for example making equipment master fields read-only for the Operator.
- No enforcement tests with "Library - Lower Permissions", because they need a test-app dependency and app.json is on the stop list.
- No change to app.json, the profile or the Role Center.

Later phases:
- Phase 2: narrow the direct `Document Attachment` rights (Reader R, Manager RIMD apply to attachments of every BC table). Needs a sandbox check of what D365 BASIC already grants, plus user approval for removing rights.
- Phase 3: Operator UX. Equipment master fields read-only when the user has no Insert on equipment (code change on the card).
- Phase 4: permission enforcement tests with Library - Lower Permissions (needs a test-app dependency).

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| PermissionSet | 50105 | EQM - Operator | New | app/src/Permissions/EQMOperator.PermissionSet.al |
| Codeunit (test) | 50162 | EQM Role Permission Tests | Changed (7 tests added) | test/src/EQMRolePermissionTests.Codeunit.al |
| XLIFF | – | Equipment Management.g.xlf / .pt-PT.xlf / .es-ES.xlf | Changed (1 unit) | app/Translations/ |

ID 50105 comes from a source scan: permission sets 50100-50102 and 50104 plus permission set extension 50103 are used, and no other `permissionset 50105` exists. `al_getnextobjectid` failed ("No AL projects are loaded"). The reviewer should confirm the ID is unique (repo_checks.py check 1 does this). No new test codeunit: test IDs are scarce, and FR-066 already chose to extend 50162.

## Events and standard symbols
No events are subscribed or published.
| Symbol | Exact signature | Verified with al_symbolsearch |
|---|---|---|
| Table "Expanded Permission" (System.Security.AccessControl), fields "Role ID", "Object Type", "Object ID", "Read/Insert/Modify/Delete/Execute Permission" | used as in 50162 `FilterPermissions`/`RightsText` | No. MCP has no project loaded. Already compiled in test/src/EQMRolePermissionTests.Codeunit.al |
| Table "Metadata Permission Set" (Role ID, Assignable), "Metadata Permission Set Rel." (Role ID, Related Role ID, Type::Include) | as in `AssertAssignableWithInclude` | No (same reason). Already compiled in 50162 |
| Table "Document Attachment" (Microsoft.Foundation.Attachment) | `Database::"Document Attachment"` | No (same reason). Already compiled in 50162 and app sets |
| Table "Job Queue Entry" (System.Threading) | `Database::"Job Queue Entry"` | No (same reason). Already compiled in 50162 |
| Permission set "D365 BASIC" (prerequisite, not referenced in new code) | – | Contents not verifiable; see Risks |

## Steps
1. `app/src/Permissions/EQMOperator.PermissionSet.al` (new). Create it with exactly this content (tabledata lines alphabetical by table name, as in the other sets; no X lines, because all X comes from Reader):
```al
namespace MiguelCarvalho.EquipmentManagement;

permissionset 50105 "EQM - Operator"
{
    Caption = 'Equipment Operator';
    Assignable = true;
    IncludedPermissionSets = "EQM - Reader";

    Permissions =
        tabledata "EQM Equipment" = RM,
        tabledata "EQM Equipment Assignment" = Rim,
        tabledata "EQM Equipment Audit Entry" = i,
        tabledata "EQM Equipment Note" = RI,
        tabledata "EQM Integration Event Entry" = i,
        tabledata "EQM Maintenance History Entry" = i,
        tabledata "EQM Maintenance Log Entry" = i,
        tabledata "EQM Maintenance Record" = RIM,
        tabledata "EQM Warranty Alert" = RIM;
}
```
   Why each line, from tracing the code paths:
   - Equipment M: AssignEmployee, Return, maintenance registration and posting all Modify table 50100 directly (codeunit 50106 has only `r` on equipment).
   - Assignment im: written only through codeunit 50106, whose Permissions property is `rim`.
   - Audit i: written by 50135 (`ri`).
   - Integration i: written by 50122 on events.
   - History i: written by 50109 (`ri`).
   - Log i: written by 50116 (`ri`).
   - Maintenance Record IM: register and post (`Rec.Modify(true)` in 50109).
   - Note I: the notes part allows insert, and the table forbids delete.
   - Warranty Alert IM: page 50120 enables Acknowledge and Generate through `Rec.WritePermission()`, so the Operator gets the same combination as the Manager (see DECISIONS).

   Effective matrix (Read, Insert, Modify, Delete, Execute; Y = direct, I = indirect, - = none):

   | Table | Operator |
   |---|---|
   | 50100 Equipment | Y-Y-- |
   | 50101 Category | Y---- |
   | 50102 Setup | Y---- |
   | 50103 Assignment | YII-- |
   | 50105 Maintenance Record | YYY-- |
   | 50106 Maint. History Entry | YI--- |
   | 50107 Warranty Alert | YYY-- |
   | 50108 Maint. Log Entry | YI--- |
   | 50109 Equipment Note | YY--- |
   | 50110 Integration Event Entry | YI--- |
   | 50111 Equipment Request | Y---- |
   | 50112 Audit Entry | YI--- |
   | 50114 Feature Setup | Y---- |
   | 50115 Error Log Entry | ----- |
   | 50149 Demo Data Entry | ----- |
   | Document Attachment | Y---- |

   Object X: identical to Reader, through the include.
2. `app/Translations/*.xlf`. Build `app/` so `Equipment Management.g.xlf` is regenerated. al_build regenerates it, al_compile does not (DECISIONS FR-056). If the MCP has no project, use alc as in earlier features. Then run `python3 .github/scripts/xlf_sync.py sync`, and set the new unit (source 'Equipment Operator', note "PermissionSet EQM - Operator - Property Caption") through `export`/`import`: pt-PT 'Operador de equipamento', es-ES 'Operador de equipo'. Then run `xlf_sync.py check` (must exit 0). Never hand-edit `.g.xlf`.
3. `test/src/EQMRolePermissionTests.Codeunit.al`. Additions only; do not touch existing procedures:
   - New label `OperatorRoleTok: Label 'EQM - OPERATOR', Locked = true;`
   - New label `NotAtLeastManagerErr: Label 'Manager should have equal or stronger rights than Operator on object type %1, ID %2 (Operator %3, Manager %4).', Comment = '%1 = object type number, %2 = object ID, %3 = rights of Operator, %4 = rights of Manager';`
   - New label `OperatorMissingErr: Label 'Operator should have Execute on object type %1, ID %2 like Reader.', Comment = '%1 = object type number, %2 = object ID';`
   - Tests T1-T7 below, using the existing helpers (`AssertAssignableWithInclude`, `AssertTableDataRights`, `AssertNoWriteRights`, `AssertNoDelete`, `AssertNoEntry`, `RightsOf`, `RightsText`, `Strength`, `FilterPermissions`).
   - Update the codeunit's summary comment to mention FR-057 Operator scenarios 12-15.
   - Build `test/` with 0 warnings.
4. Docs (documenter):
   - `docs/features/FR-057-permission-review.md`: the five-role table, the full matrix (FR-036 matrix plus an Operator column), the audit table below and the drift rule. A new tabledata write path must be added to Manager and, when it is operational, to Operator.
   - `docs/help/FR-057-permission-review.md`: which role for whom, the Operator limits (see Risks), D365 BASIC prerequisite.
   - `CHANGELOG.md`: `## FR-057 Permission Review` (Added: EQM - Operator; Changed: none; no version bump).
   - `docs/TODO.md`: OP-SB1 to OP-SB8.

   Audit result for the feature doc (review on this branch, no change in phase 1):
   - Reader: R on 13 EQM tables plus Document Attachment, X on every object except 50104, 50133 and 50134. Least privilege OK; X on codeunits grants no data.
   - Manager: matches its role. Request D is limited to Open requests by the OnDelete guard. Direct `I` on Warranty Alert is needed for the manual Generate action.
     - **F1:** direct RIMD on the standard Document Attachment table covers attachments of every BC record, not only equipment (phase 2, approval needed).
   - Administrator: OK. Indirect `d` only for Demo Data (FR-066), Error Log RD (FR-051), No. Series and Job Queue indirect only.
   - API Consumer: unchanged from FR-036, no UI pages.
   - D365 BASIC extension 50103: indirect `r` only, own table only (Learn best practice).
   - **F2 (observation):** Reader R on Audit Entry and Integration Event Entry exposes User IDs to every Reader. Keep for now, because NFR-002 defined Reader as "view all". Narrowing it is phase 2 and needs approval.

## Tests
All in codeunit 50162 (structural, `TestPermissions = Disabled`, nothing written). Existing tests are expected to be unaffected: `ExistingRolesKeepTheirHierarchy`, `ReaderHasExecuteOnEveryObjectOfTheApp` and all API Consumer tests.
- T1 [SCENARIO 12] Operator is assignable and includes only Reader. `AssertAssignableWithInclude(OperatorRoleTok, ReaderRoleTok)`: the set exists, is assignable, and has exactly one Include relation, to EQM - READER.
- T2 [SCENARIO 13] Operator's effective tabledata equals the matrix: `AssertTableDataRights` for each of the 16 rows (Document Attachment through `Database::"Document Attachment"`).
- T3 [SCENARIO 13, negative] Operator cannot create or delete equipment, and deletes nothing. For the Operator's Expanded Permission rows of type 0 (all IDs), `CopyStr(RightsText(..), 4, 1) = '-'` for every row, Checked > 0 (NothingCheckedErr), and `CopyStr(RightsOf(OperatorRoleTok, 0, Database::"EQM Equipment"), 2, 1) = '-'`.
- T4 [SCENARIO 13, negative] `AssertNoWriteRights` on "EQM Equipment Category", "EQM Equipment Setup", "EQM Feature Setup", "EQM Equipment Request" and "Document Attachment": Insert, Modify and Delete are '---'.
- T5 [SCENARIO 13, negative] `AssertTableDataRights(OperatorRoleTok, Database::"EQM Error Log Entry", '-----')`, the same for "EQM Demo Data Entry", and `AssertNoEntry(OperatorRoleTok, 0, Database::"Job Queue Entry")`.
- T6 [SCENARIO 14] Manager covers everything the Operator can do: for every Operator Expanded Permission row, positions 1-5 satisfy `Strength(Manager) >= Strength(Operator)` (NotAtLeastManagerErr), Checked > 0. Copy the pattern of `AdministratorCoversEverythingApiConsumerCan`; do not refactor that test.
- T7 [SCENARIO 15] Operator can execute every object Reader can: for Reader rows with object types 1, 3, 5, 8, 9 and Execute = Yes, the Operator has position 5 = 'Y' (OperatorMissingErr), Checked > 0.

Manual sandbox checks for `docs/TODO.md`:
- OP-SB1: a non-SUPER user with D365 BASIC + EQM - Operator can assign and return from the card and the Employee Card, register maintenance (number series consumed), post maintenance, add a note, acknowledge alerts, generate alerts, without a permission error.
- OP-SB2: New equipment fails on save with a permission error.
- OP-SB3: Delete equipment fails with a permission error.
- OP-SB4: Categories and Setup open read-only.
- OP-SB5: Approve or reject a request, and creating a request, fail with a permission error.
- OP-SB6: attachment upload fails, and the picture cannot be edited (WritePermission).
- OP-SB7: the Error Log action is hidden on Setup.
- OP-SB8: the Warranty Alerts page has Acknowledge and Generate enabled.

## Assumptions
- "Operator" means day-to-day work on existing equipment (assignments, maintenance, notes, warranty follow-up), not master data, approvals or configuration, because the issue lists it between Reader and Manager.
- The "review" changes nothing in the existing sets in phase 1, because removing rights is on the stop list. Findings F1 and F2 are documented instead.
- D365 BASIC stays the prerequisite for every role (Employee, No. Series, User), as decided in NFR-002 and FR-036.
- No Commit or partial-write risk: the Operator's failing paths (New, Delete, request decisions) error at the first write and roll back.
- Role ID "EQM - Operator" (14 characters, within the Code[20] limit), caption 'Equipment Operator' like the other captions.

## DECISIONS
- FR-057 | Chose a new set "EQM - Operator" that includes Reader, over making Manager include Operator, so the Manager and Administrator hierarchy and test `ExistingRolesKeepTheirHierarchy` stay unchanged; Manager ⊇ Operator is asserted by T6 instead | Reversible: yes until first release (Role ID becomes a contract)
- FR-057 | Chose direct M on equipment for the Operator over indirect `m` through code, because assign, return and maintenance modify table 50100 from table and page code. Accepted limitation: the Operator can edit card fields and rename equipment (phase 3) | Reversible: yes
- FR-057 | Chose RIM on Warranty Alert (same as Manager) over M only, because page 50120 enables Acknowledge and Generate through `Rec.WritePermission()`; Generate is an idempotent operational action | Reversible: yes
- FR-057 | Chose no write rights on Equipment Request for the Operator over RIM, because approval is a plain Modify and permissions cannot separate requesting from approving | Reversible: yes
- FR-057 | Chose Document Attachment R only (inherited) for the Operator over RI, because direct rights on that standard table apply to attachments of every BC record (audit F1) | Reversible: yes
- FR-057 | Chose to document audit findings F1 and F2 for phase 2 over removing rights now, because removal is on the stop list | Reversible: yes
- FR-057 | Chose to add the Operator tests to existing 50162 over a new test codeunit (scarce test IDs; same as FR-066) | Reversible: yes
- FR-057 | Chose permission set ID 50105 from a source scan, because the AL MCP had no project loaded | Reversible: yes
- FR-057 | Chose translations 'Operador de equipamento' (pt-PT) and 'Operador de equipo' (es-ES), consistent with the existing role captions | Reversible: yes
- FR-057 | User approved a new permission set (stop-list item) via Option A | Reversible: n/a

## Risks
- `Record.WritePermission()` with partial rights: Learn says only that "a write permission consists of Insert, Delete, and Modify permissions". The Picture page (50122) gates editing on it, so the Operator (M only on equipment) probably cannot edit pictures. Accepted, because the picture is master data. Reviewer: OP-SB6 and OP-SB8.
- The Operator can rename equipment (Modify right). If the equipment has attachments, `OnRename` renames Document Attachment rows, and the Operator gets a permission error that rolls back (no data damage). Documented in help, phase 3.
- The Operator can set the status to Lost or Disposed through the card (M on equipment). Follows NFR-002. Documented as a known limit.
- D365 BASIC contents (Document Attachment, No. Series consumption for maintenance numbers) cannot be verified from symbols. Sandbox OP-SB1 covers number series; F1 needs a sandbox check before phase 2.
- Drift: a future feature that adds an operational write path must add the matching tabledata line to Operator as well as Manager. T6 only guarantees Manager ⊇ Operator, not completeness. The feature doc records this rule.
- Symbols were not verified with al_symbolsearch (no project loaded). All standard symbols used are already compiled in 50162 and the app's sets, so compile risk is low. The developer should load the projects (al_addproject) or use alc as in FR-051 to FR-054.
- After the first AppSource release, the Role ID "EQM - OPERATOR" is stored on users and security groups and cannot be renamed.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-composing
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-permissions-on-database-objects
- https://learn.microsoft.com/dynamics365/business-central/ui-define-granular-permissions
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-writepermission-method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-ext-object
