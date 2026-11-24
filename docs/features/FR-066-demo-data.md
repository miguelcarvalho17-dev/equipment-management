# FR-066 Demo Data

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
Gives a new company sample data to look at. An administrator runs **Create Demo Data** on the Equipment Setup page. The action adds about 8 employees, 15 equipment records, assignments and maintenance records. **Delete Demo Data** removes what the demo created and keeps everything a user created or changed in a way that matters.

Status: implemented on branch `feature/FR-066-demo-data`, not committed, not merged. Plan: `docs/plans/FR-066-demo-data.md` (status approved). Target: AppSource. Review: APPROVED by al-reviewer.

No demo data is created on install or upgrade. The actions are user-triggered only (user decision).

## Objects
| Object | Name | Change |
|---|---|---|
| Table 50149 | EQM Demo Data Entry | New. Tracking table: one row per record the demo created (table ID, number, SystemId, created at, created by). Internal, no page |
| Codeunit 50149 | EQM Demo Data Mgt. | New. All create and delete logic, the confirmations and the notifications. Internal |
| Page 50103 | EQM Equipment Setup | Two actions in the Processing area: Create Demo Data, Delete Demo Data. Both are enabled only with `CanManage` |
| Permission set EQM - Reader | | Execute on codeunit 50149 and on table 50149 |
| Permission set EQM - Administrator | | Indirect rights used by codeunit 50149 (see below) |
| Translations | pt-PT, es-ES | New captions, ToolTips, messages, errors and the maintenance descriptions |

No event is published or subscribed. No `app.json` change.

## Permission design
The demo code reaches the tables through the **Permissions** property of codeunit 50149. The rights are indirect. Users never get direct rights on these tables from this feature.

- **EQM - Administrator** gets indirect `d` on the six tables that only the demo delete path needs: equipment assignment, equipment audit entry, maintenance record, maintenance history entry, maintenance log entry and warranty alert. It also gets indirect `rimd` on the demo tracking table 50149. The Integration Event Entry right already existed.
- **EQM - Manager** gets nothing new.
- **EQM - Reader** gets execute on codeunit 50149 and on table 50149. This is needed by the existing reader test that checks every object of the app.
- **Standard Employee table:** no rights are added. The code checks `WritePermission()` on Employee for the user who runs the action. The user needs Employee edit rights. A user who has EQM - Administrator but no Employee edit rights gets an error, and nothing is written.
- **Setup check:** the code checks `WritePermission()` on the Equipment Setup table. If the check fails, the action raises an actionable error and nothing is written.

Deletion of the demo records uses `Delete(false)` and `DeleteAll(false)`. This skips the OnDelete triggers that forbid deletion of audit, history and log rows. This is intended. The delete path runs only after the code confirms that the record is demo data and that no user data depends on it.

## What Create makes
On an empty company with the seven default categories, Create makes:

| Record | Count | Details |
|---|---|---|
| Employees | 8 | Numbers `EQMDEMO-E01` to `EQMDEMO-E08`. Last name "Demo". Active |
| Equipment | 15 | Numbers `EQMDEMO-001` to `EQMDEMO-015`. Serial numbers `EQMDEMO-SN-001` to `-015`. Final statuses: Assigned 7, Available 3, In Maintenance 3, Lost 1, Disposed 1 |
| Assignment entries | 13 | 7 active and 6 closed. The closed entries give the equipment a history |
| Maintenance records | 12 | Numbers `EQMDEMO-M01` to `EQMDEMO-M12`. 9 posted (9 history entries) and 3 open. Of the open records, 2 are overdue (open more than 14 days) |
| Tracking rows | 35 | One row for each employee, equipment and maintenance record |

The demo also covers these cases:
- Warranties that are expired, expiring soon, inside the 90-day alert window, active, and blank.
- One equipment record whose planned maintenance is overdue.
- Equipment in each of the seven default categories.

All dates are relative to today. Warranty status and overdue checks use today's date.

### Naming
Demo records use the prefix `EQMDEMO-`. Names, products, providers and number patterns are fixed text. Maintenance descriptions and "Performed By" are translated and follow the session language. Equipment and employee texts are not translated.

### Create through app logic
Create uses the app's own business logic, so the records behave like records entered by a user:
- Equipment is inserted with the normal insert logic and the audit entry for "Created".
- Maintenance records are inserted, then posted with the existing posting codeunit. Posting creates the history and log entries.
- Active assignments use the existing assign procedure.
- Lost and Disposed are set on the record directly, because validating the status raises a confirmation.
- Closed assignment entries are inserted directly to create history with past dates. These rows have no Assigned or Returned audit entries.

### Skipping and rerunning
- Create never changes or deletes a record that it did not create.
- A second Create adds only the missing records. It does not change records that already exist. In a company where the demo already exists, nothing is added.
- An item is skipped when:
  - its number is already used by a record that the demo did not create,
  - its category is missing or inactive, or
  - for equipment, its serial number is already used. The equipment is then created with a blank serial number.
- Skipped items are counted and shown in the result notification.
- Create runs in one transaction. If it fails, nothing is kept.

## Delete rules
Delete works on the tracking rows, not on the numbers. A demo record that a user renamed or edited is still found and removed. A renamed record is found by its SystemId.

### Equipment is kept when a user added data to it
Delete keeps a demo equipment record, and its tracking row, when any of these exist:
- a picture,
- a note,
- a document attachment,
- an equipment request that points to it,
- a maintenance record that the demo did not create, or
- an assignment entry for an employee that the demo did not create.

Kept equipment keeps its history and tracking row.

### Employee is kept when something still refers to it
Delete keeps a demo employee when any of these exist:
- equipment assigned to the employee,
- any assignment entry for the employee,
- an equipment request for the employee, or
- a document attachment on the employee.

### Order
Delete removes, for each demo equipment that it can delete:
1. maintenance log entries of its maintenance records,
2. maintenance history entries,
3. maintenance records,
4. assignment entries,
5. audit entries,
6. warranty alerts,
7. integration event entries,
8. the equipment record,
9. the tracking rows of the equipment and its maintenance records.

Then it removes the demo employees that are not kept, and their tracking rows. Tracking rows whose record no longer exists are removed without an error.

### Result
The result notification shows the equipment and employees deleted, and the equipment and employees kept.

## Side effects that cannot be undone
The demo uses the normal app logic, so the same side effects happen as for user actions. Delete does not reverse them.

- **Power Automate:** the "Equipment Assigned" external events fire for each active assignment that Create makes (7 in the default set). Flows that listen to these events run.
- **Warranty alerts:** the daily job creates warranty alerts for the demo equipment after Create. Delete removes them, but only when it deletes the equipment.
- **Change Log:** if the Change Log is set up (FR-034), changes made by Create and Delete are logged, as for user changes.
- **Telemetry:** signals EQM0005 to EQM0009 may be sent for the demo actions (equipment created, assigned, returned, maintenance registered, warranty expired), as for any user action. See FR-050.
- **Business events:** the business events published by the app fire during Create. Subscribers receive them.

The demo does not suppress these, because that would change existing subscribers (plan decision).

## Out of scope
- No demo data on install or upgrade.
- No equipment requests, notes, attachments, pictures, warranty alerts or job queue entries in the demo set.
- No locations, vendors or dimensions on demo records.
- No "demo company only" guard (phase 3).
- No configurable size (phase 4, may reuse FR-053).

## Not verified / follow-ups
- **Tests:** the test codeunit 50176 "EQM Demo Data Tests" and the new tests in codeunit 50162 are written and compiled. The tests were not executed. CI result pending (`Pull Request Build`).
- **Employee behaviour:** `Employee.Insert(true)` with an explicit number and `Employee.Delete(true)` run the standard triggers. These were not verified against symbols or a sandbox. A sandbox check is needed as a user with EQM - Administrator and Employee edit rights.
- **Permission-denied path:** the error for a user without the rights is not covered by a test. The test app has no lower-permission library, and adding one changes `test/app.json`, which is on the stop list. A sandbox check is needed: as EQM - Manager only (actions disabled), and as EQM - Administrator without Employee write rights (actionable error).
- **Picture rule:** the rule that keeps equipment with a picture is not tested.
- **Rename cascade (D14):** the test for a renamed demo equipment relies on the platform updating the "Equipment No." of closed assignment entries on rename, without the OnModify or OnRename code of the app. If CI fails, use equipment without history in the test. Do not change app code for it.
- **Employee fields:** the Employee field names are confirmed only by compiled use in this repo. They were not checked with `al_symbolsearch` (no symbols in the worktree at the time).
- **Test ID reuse:** test codeunit 50176 was reserved by FR-022 and never built. Check that the FR-053 branch does not use the same ID before merging.
- **Record Links (minor m1, open):** Delete does not check Record Links on demo equipment. A link added by a user does not keep the equipment. Decide whether it should.
- **Unindexed scans (minor m2, open, FR-053 follow-up):** the Delete path scans the integration event entries by "Equipment No.". That field has no key, so each equipment is a filtered scan. Up to 15 scans per run. Add a key in the FR-053 work.
- **Branch update before commit:** the branch is behind `origin/main`. FR-053 is merged. Update the branch to `origin/main` and rebuild the translation files with `al_build` and `xlf_sync.py` before committing.
- **Translations:** pt-PT and es-ES are complete for the new units, but the translations have not been checked by a native speaker.
- **No separate AppSource validation ran.** The reviewer checked the change against the plan and the AppSource rules.

## Related
- Help article: `docs/help/FR-066-demo-data.md`
- Changelog: `CHANGELOG.md`, entry FR-066
- Plan: `docs/plans/FR-066-demo-data.md`
- Telemetry: `docs/features/FR-050-application-telemetry.md`
- Microsoft Learn: [Record.WritePermission](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-writepermission-method), [Record.DeleteAll](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-deleteall-method), [Permissions property](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-permissions-property)
