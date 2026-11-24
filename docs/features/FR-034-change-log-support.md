# FR-034 Change Log Support

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
Make changes to equipment traceable through the standard Business Central Change Log: category, status, assigned employee and the stored warranty fields of table 50100 "EQM Equipment" (GitHub issue #72). The app registers these fields in the Change Log setup on install. It does not switch the Change Log on.

Status: implemented on branch `feature/FR-034-change-log-support`, not committed, not merged. App version stays 29.0.0.0 (unreleased, no bump).

Decisions (plan approved): D1 off (the app never touches table 402 "Change Log Activated"; an administrator turns the Change Log on), D2 no (category table 50101 is not logged), D3 no (assignment table 50103 is not logged; assignment changes are logged through field 10 of 50100), D4 inputs (the stored warranty fields 17-20 are logged; "Warranty Status" is calculated from the end date and today, so it is not logged).

## Verification status
- **Tests: pass in AL-Go CI (PR #128).** Test codeunit 50191 (7 tests) passed in the AL-Go PR build. Not run in a BC sandbox.
- **Not verified:** that the Change Log actually writes entries for these rows (plan scenario 8) and the install behavior (scenario 9). See `docs/TODO.md`, section "FR-034 sandbox checks".

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Codeunit | 50133 | EQM Change Log Registration | New, `Access = Internal`. Writes the setup rows. |
| Codeunit | 50134 | EQM Upgrade | New, `Subtype = Upgrade`, `Access = Internal`. `OnUpgradePerCompany` calls the registration. |
| Codeunit | 50104 | EQM Install | Calls `RegisterChangeLogSetupOnce` after `CreateDefaultData`. |
| Codeunit (test) | 50191 | EQM Change Log Setup Tests | New, 7 tests. |

No new tables, fields, pages or permission set changes.

## What gets registered
One row in "Change Log Setup (Table)" (403) for table 50100: Log Modification = Some Fields, Log Insertion and Log Deletion blank. One row in "Change Log Setup (Field)" (404) per field, Log Modification = true:

| Field No. | Field |
|---|---|
| 3 | Category Code |
| 9 | Status |
| 10 | Assigned Employee No. |
| 17 | Warranty Start Date |
| 18 | Warranty End Date |
| 19 | Warranty Provider |
| 20 | Warranty Reference No. |

Field numbers come from `Equipment.FieldNo(...)`. Only modifications are logged; insertions and deletions are not.

## Behavior
- `RegisterEquipmentChangeLogSetup`: if a 403 row for table 50100 already exists (in any state, including blank = switched off), it does nothing. Otherwise it inserts the 403 row and the missing 404 rows (assigned directly, `Insert(true)`, no Validate).
- `RegisterChangeLogSetupOnce`: exits when the upgrade tag `MC-EQM-FR034-ChangeLogSetup-20261116` is set; otherwise registers and sets the tag. The install sets the tag, so a later upgrade does not re-add rows a customer deleted on purpose.
- The tag is not registered through `OnGetPerCompanyUpgradeTags`. Companies created after the install get the rows at the next upgrade run; until then an administrator can add them on the standard Change Log Setup page.
- The upgrade codeunit 50134 only runs at the next version bump (a release decision outside FR-034).
- Table 402 is never read or written. The rows have no effect until an administrator sets "Change Log Activated" on the Change Log Setup page (Business Central caches the setup per session; users sign in again).

Every write to fields 3, 9, 10 and 17-20 in `app/src` uses `Modify(true)` or a page or API save, so the table triggers the Change Log depends on run. Code that uses `Modify(false)` or `ModifyAll` without triggers on table 50100 would not be logged; none exists in this app.

## Events
None published, none subscribed. The standard Change Log has no "register a loggable table" event; registration is data in tables 403 and 404 (see `docs/plans/FR-034-change-log-support-events.md`).

## Permissions
- Codeunit 50133: `Permissions = tabledata "Change Log Setup (Table)" = ri, tabledata "Change Log Setup (Field)" = ri` (indirect). The installing or upgrading user supplies the base rights.
- No permission set changes. Users never run the codeunit. Change Log entries are written by the base app under its own permissions.

## Compatibility
No public API change; all new objects are internal. This partly revisits NFR-005 ("the app does not configure the Change Log"): the app now writes tenant setup rows in 403/404, but still does not activate the Change Log.

## Known limitations
- Warranty Status (calculated) is not logged; only changes to the stored warranty fields are.
- Not logged: Description, Location Code and all other fields; table 50101 and 50103; insertions and deletions.
- Change Log entries contain user IDs and old/new values; retention is the customer's Change Log policy.
- If the customer already has a 403 row for table 50100, the app adds nothing, even if fields are missing.

## Translations
The only new label (the upgrade tag) is `Locked = true`, which the AL compiler does not export to `Equipment Management.g.xlf`. No translation change is needed. The CI warning "app/Translations/*.g.xlf not updated" is expected for this feature (it is a warning only; verified: the xlf has no entry for the tag).

## Not verified (TODO(verify))
- Entries are created for the registered fields once the Change Log is on, and none for Description (plan scenario 8).
- Assigning direct values to 403 without Validate gives the intended "Some Fields" behavior (plan scenario 8).
- Install as a non-SUPER administrator: succeeds or fails with a permission error (plan scenario 9).
- Fresh install in a new sandbox: rows exist and the upgrade tag is set (plan scenario 9).

## Discrepancies plan vs code
None found. Objects, IDs, rows, tag name and the install call match the plan. The test codeunit has 7 tests (plan scenarios 1-7); scenarios 8-9 are manual.
