# FR-034 Change Log Support

> Status: **Approved.** The user approved D1 off, D2 no, D3 no, D4 inputs (stored warranty fields 17-20). Source: GitHub issue #72. Branch `feature/FR-034-change-log-support`. Events report: `docs/plans/FR-034-change-log-support-events.md`. No version bump in this feature (29.0.0.0, unreleased).
> **Open decisions (the plan uses the recommended default, so each answer can be one word):**
> - **D1 Activation of "Change Log Activated".** **off** (recommended): the app only adds its setup rows to tables 403/404. Table 402 is never read or written. An administrator turns the Change Log on in the standard Change Log Setup page, and the help explains how. The rows have no effect until then. **on**: install and upgrade also set 402 "Change Log Activated" = true. This is a company-wide switch: every table the customer has already set up starts logging too, with a performance and policy impact. It also adds `rim` on 402 and conflicts with the NFR-005 decision that the app does not take over the tenant's audit configuration.
> - **D2 Category table 50101.** **no** (recommended): "category changes" in the issue means changing an equipment's category, which is field 3 on 50100. The category master data stays out of scope. **yes**: also add a 403 row for 50101 with Log Insertion/Modification/Deletion = All Fields.
> - **D3 Assignment table 50103.** **no** (recommended): every row in 50103 is already a history entry with dates and user (FR-006), and assignment changes are logged through 50100 field 10. Logging 50103 too would record the same event twice. **yes**: add a 403 row for 50103 with Modification = All Fields.
> - **D4 Warranty status.** **inputs** (recommended): log the stored warranty fields 17-20. "Warranty Status" is calculated from the End Date and today (`CalcWarrantyStatus`) and is not stored, so the status changing over time is never a database change and cannot be logged. Help states this. **stored**: add a stored status field that a job updates. This is out of scope and would need a new plan.

## Goal
Make the equipment changes that the issue lists traceable through the standard Business Central Change Log: status, assigned employee, category and the warranty fields of table 50100. The app registers these fields in the Change Log setup when it is installed or upgraded. It never overwrites a customer's own Change Log configuration, and it leaves the company-wide on/off switch to the administrator (D1).

## Approach and rejected alternatives
- Chosen: a new internal codeunit "EQM Change Log Registration". It inserts one row into "Change Log Setup (Table)" (403) for table 50100 with Log Modification = "Some Fields", and one "Change Log Setup (Field)" (404) row per tracked field with Log Modification = true. Install codeunit 50104 and a new upgrade codeunit both call it. An upgrade tag makes it run once per company. The events report confirms there is no "register loggable table" event: registration is data in 403/404.
- Rejected: `OnAfterIsAlwaysLoggedTable` (codeunit 423). It forces logging that the customer cannot turn off and overrides their setup.
- Rejected: GlobalTriggerManagement (codeunit 49) subscribers. Low-level and global overhead, and the setup rows already cover the need (fallback only, see Risks).
- Rejected: our own field-change log table or OnAfterValidate subscribers. That would duplicate the standard Change Log, and NFR-005/FR-006 already cover the domain history.
- Rejected: Log Insertion/Deletion and an Equipment Card action that opens Change Log Entries. The issue asks for changes only, and the standard Change Log Entries page can filter by table.

## Objects
IDs in use (checked `app/src`, `test/src`): codeunits 50103-50122 and 50130-50132 (50123-50129 reserved by FR-026, and 50100-50102 left unused per the FR-029 convention), test codeunits 50178-50190. Folder `app/src/ChangeLog/`.
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Codeunit | 50133 | EQM Change Log Registration | New | `EQMChangeLogRegistration.Codeunit.al`; `Access = Internal`; idempotent inserts into 403/404 plus the upgrade-tag guard |
| Codeunit | 50134 | EQM Upgrade | New | `app/src/Install/EQMUpgrade.Codeunit.al`; `Subtype = Upgrade`, `Access = Internal`, `OnUpgradePerCompany` |
| Codeunit | 50104 | EQM Install | Modify (own) | Calls 50133 after `CreateDefaultData` |
| Codeunit (test) | 50191 | EQM Change Log Setup Tests | New | `test/src/EQMChangeLogSetupTests.Codeunit.al` |

## Data model and upgrade impact
- No new tables or fields. Only data is written to base tables 403 and 404 (allowed in AppSource: data, not object modification). Table 402 is untouched (D1 = off).
- 403 row: Table No. = `Database::"EQM Equipment"`, Log Modification = "Some Fields", Log Insertion and Log Deletion = blank, Monitor Sensitive Field = false.
- 404 rows (Log Modification = true, all other flags false), with field numbers from `Equipment.FieldNo(...)` and no literals: 3 "Category Code", 9 Status, 10 "Assigned Employee No.", 17 "Warranty Start Date", 18 "Warranty End Date", 19 "Warranty Provider", 20 "Warranty Reference No.".
- Customer-choice rule: if a 403 row for 50100 already exists (in any state, including blank, meaning switched off), insert nothing for that table. A 404 row is inserted only when it is missing.
- Upgrade tag `MC-EQM-FR034-ChangeLogSetup-20261116` (Locked label). The install sets it after registering, so a later upgrade does not re-add rows that the customer deleted on purpose. The upgrade codeunit takes effect only at the next version bump, which is a release decision outside FR-034.
- Modify(true) audit (grep of `app/src`): every write to 50100 fields 3, 9, 10 and 17-20 goes through `Modify(true)` (AssignEmployee, UnassignEmployee, StartMaintenance, CompleteMaintenance, UpdateLastMaintenanceFromPosting) or through page and API saves. There is no `Modify(false)`/`ModifyAll` on 50100. The only `Modify(false)` calls are on 50111 (FR-033) and 50107, which are out of scope. No code change is needed.

## Events
- Subscribed: none. Published: none (no extensibility is requested; the codeunit is internal).

## Permissions
- Codeunit 50133 `Permissions = tabledata "Change Log Setup (Table)" = ri, tabledata "Change Log Setup (Field)" = ri` (indirect). The installing or upgrading user (normally SUPER) supplies the base rights.
- No permission set changes. Users never run 50133 (it runs only from install/upgrade, like 50104, which is not in EQM - Reader either). Change Log Entries are written by codeunit 423 under its own permissions, and users read them through standard permission sets.

## Compatibility
- No public API change. 50133/50134 are internal, and 50104 is internal (an own object). **Breaking-change risk: none.** Policy risk: the app writes tenant setup data in 403/404. This partly revisits NFR-005 ("the app does not configure the Change Log"). The rows have no effect until an administrator activates the Change Log, and the documenter must update the NFR-005 feature doc and help.

## Implementation steps
1. Codeunit 50133 (namespace `MiguelCarvalho.EquipmentManagement`, add a `using` for the Change Log namespace as the compiler requires). Internal procedures with `/// summary`: `RegisterChangeLogSetupOnce()` (exit if `UpgradeTag.HasUpgradeTag(tag)`, otherwise `RegisterEquipmentChangeLogSetup()` then `SetUpgradeTag`), `RegisterEquipmentChangeLogSetup()` (the rule in Data model: assign fields directly, no Validate, `Insert(true)`), `GetChangeLogUpgradeTag(): Code[250]`, and local `InsertFieldSetupIfMissing(FieldNo: Integer)`. No user-facing text. Compile.
2. Install 50104: after `DefaultData.CreateDefaultData()`, call `ChangeLogRegistration.RegisterChangeLogSetupOnce()`. Keep the existing order comment. Compile.
3. Codeunit 50134 "EQM Upgrade": `OnUpgradePerCompany` calls `RegisterChangeLogSetupOnce()`. Compile.
4. Test codeunit 50191 follows the 50188 pattern: Subtype Test, TestPermissions Disabled, AutoRollback, Library Assert, and Locked labels with prefix `EQMCLG`. Initialize deletes the 403/404 rows for 50100, 50101 and 50103. Scenarios 1-5 and 7 call `RegisterEquipmentChangeLogSetup()` directly, because the install has already set the upgrade tag in the test company. Build both apps.
5. Documenter: feature doc and help (how to activate the Change Log, where to see entries, that warranty status is calculated and not logged, and that only changes are logged). Update the NFR-005 feature doc line 17 and help line 28. Add CHANGELOG and a TODO "FR-034 sandbox checks" (scenarios 8-9).

## Test scenarios
1. Given no 403/404 rows for 50100, when RegisterEquipmentChangeLogSetup runs, then one 403 row exists with Log Modification = Some Fields and Log Insertion/Deletion blank, and exactly 7 404 rows exist (fields 3, 9, 10, 17, 18, 19, 20), each with Log Modification = true and Log Insertion/Deletion = false.
2. Given scenario 1 done, when it runs again, then the row counts and values are unchanged (idempotent).
3. (neg) Given a customer 403 row for 50100 with Log Modification = All Fields, when it runs, then that row is unchanged and no 404 rows are added.
4. (neg) Given a customer 403 row for 50100 with Log Modification blank (switched off), when it runs, then nothing changes.
5. (neg) Given "Change Log Activated" = false (and, separately, = true), when it runs, then the 402 value is unchanged (D1 = off).
6. (neg) Given the upgrade tag is set (by the install, asserted with HasUpgradeTag) and the 403/404 rows for 50100 were deleted, when RegisterChangeLogSetupOnce runs, then no rows are inserted (deliberate deletion respected).
7. (neg) After registration, no 404 rows exist for 50100 fields 2 Description or 11 "Location Code", and no 403 rows exist for 50101 or 50103 (D2/D3 = no).
8. Sandbox (manual): with the Change Log activated and after signing in again (the setup is cached per session), assign, return, change category, change status to Lost, and edit the warranty dates and provider. Then Change Log Entries show one entry per changed field with old and new values. Editing Description logs nothing.
9. Sandbox (manual): with the Change Log off, the same actions create no entries. On a fresh install in a new sandbox, the 403/404 rows exist and the upgrade tag is set. An install as a non-SUPER admin either succeeds or fails with a clear permission error (record the result).

## Risks and open questions
- D1-D4: see the top.
- Assumed the upgrade tag (System codeunit "Upgrade Tag", `HasUpgradeTag`/`SetUpgradeTag`) instead of no tag, so that a customer's deletion is respected. The developer confirms these procedure names in the symbols. If they are missing, stop and ask; do not guess.
- Assumed direct assignment plus `Insert(true)` on 403/404 (no Validate), because Validate on 403 Log Modification may open dialogs or delete field rows (not verified, base source unavailable). Verify in the sandbox.
- Assumed "Some Fields" plus 404 rows is the standard semantics (events report: medium confidence). Scenario 8 verifies it.
- Assumed Change Log Entry creation is verified manually only (scenario 8), because the Change Log setup is cached per session and an in-session automated test would be flaky.
- R1 Install fails if the installing user has no rights on 403/404. This is unlikely for an admin; scenario 9 checks it.
- R2 Companies created after install get no rows until the next upgrade. The customer can add them in the standard page (documented).
- R3 If the sandbox shows that our table does not fire the Change Log, the fallback is codeunit 49 `OnAfterGetDatabaseTableTriggerSetup` (events report). That needs a replan.
- R4 Change Log entries contain user IDs and old/new values (EUII handling is the customer's Change Log retention policy).
