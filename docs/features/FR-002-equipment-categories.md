# FR-002 Equipment Categories

## Purpose
Administrators maintain the list of equipment categories (Code, Description, Active). Only active categories can be
newly set on equipment. Equipment that already uses a category keeps it after the category is made inactive.
FR-002 extends the FR-001 category objects; it adds no new objects.

Status of this document: describes the code as implemented. Not compiled and no automated tests (see "Known limitations").

## Objects
All objects are in namespace `MiguelCarvalho.EquipmentManagement`. All are changed existing objects.

| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50101 | EQM Equipment Category | New field 3 Active; new OnRename guard; new delete error text. |
| Table | 50100 | EQM Equipment | "Category Code" relation filtered to active categories, own existence and active checks, new event. |
| Page | 50102 | EQM Equipment Categories | New Active column. |
| Codeunit | 50105 | EQM Default Data | Adds TABLET and PRINTER; PHONE description is now "Mobile Phone". |
| PermissionSet | 50101 / 50102 | EQM - Manager / EQM - Administrator (were Edit / Admin) | Category maintenance moved from Manager to Administrator. |
| app.json | n/a | app/app.json | Version 29.1.0.0; feature `TranslationFile` added. |

## Setup
1. Open **Equipment Categories** and add or change categories. A new category is active.
2. To retire a category, clear **Active**. Equipment keeps the category; nobody can newly select it.
3. Users who maintain categories need **EQM - Administrator** (`Equipment Administrator`).
- New companies get seven starter categories: LAPTOP, MONITOR, PHONE ("Mobile Phone"), TABLET, PRINTER, VEHICLE, TOOL.
  Companies that already ran the default data do not get TABLET and PRINTER, and existing categories are never changed. Add them by hand if wanted.
- Development sandboxes: when the Active column is synced onto existing category rows they get Active = false (`InitValue` applies to new rows only).
  Reinstall the app data, or tick Active on each existing category on the Equipment Categories page. There is no upgrade code.

## Behavior
Category (table 50101):
- **Code** is the primary key, so it is unique. Codes are upper case, so `laptop` and `LAPTOP` are the same code.
- **Active** (Boolean, default true): whether the category can be newly set on equipment.
- **Delete** is refused while any equipment uses the category (active or inactive). The error suggests clearing Active instead.
- **Rename** (OnRename) is refused when the category is inactive (before or after the rename) and equipment uses it. Select Active, rename, then clear Active again.
  Reason: it is not verified that the platform updates equipment through a relation filtered to active categories when an inactive category is renamed. Active categories cascade normally.
- Deactivating a category in use is allowed, with no confirmation and no change to equipment.

Equipment "Category Code" (table 50100):
- The table relation is `where(Active = const(true))`, so the dropdown and lookup list active categories only.
  `ValidateTableRelation = false`: the platform's generic "cannot be found" error is not raised; the table checks itself.
- `CheckCategoryAllowed(CheckIsActive)` (local) runs on validate and in `CheckEquipmentConsistency` (insert and modify with triggers):
  - Blank code: no check here (NotBlank and `TestField` handle it).
  - Code does not exist: error "Equipment category %1 does not exist...". Always checked.
  - Code exists but is inactive: error "You cannot select equipment category %1 because it is not active...". Checked only for a new record or when the code differs from the stored one (on validate: differs from xRec).
- Consequences: new equipment and a category change cannot use an inactive category. Existing equipment with an inactive category can still be edited, assigned, unassigned, retired and deleted; re-validating the same code is allowed; changing to an active category is allowed; changing back to the inactive one is refused.
- In `CheckEquipmentConsistency` the category check now runs before the serial number check.

## Extending (events)
Published from table "EQM Equipment" as `[IntegrationEvent(false, false)]`, declared `local`, record passed by value.
| Event | Raised | Parameters | What you can do |
|---|---|---|---|
| `OnBeforeCheckCategoryIsActive` | Before the "category must be active" check, only when that check would run (new record or changed category) | `Equipment`; `IsHandled` (var) | Set `IsHandled = true` to allow an inactive category. The "category must exist" and blank checks still run. |

Subscribed: none new. Partner checks on save remain possible with the FR-001 event `OnAfterCheckEquipmentConsistency`.

## Permissions
| Set | Categories |
|---|---|
| EQM - Reader | Read (R). |
| EQM - Manager | Read only, through EQM - Reader. |
| EQM - Administrator | Includes Manager; full RIMD on categories and setup. The page is read-only for users without write permission (NFR-002). |

## Upgrade and compatibility
No upgrade codeunit, upgrade tag or install change: the app has not been published. If 29.0.0.0 data must ever be kept, existing categories become inactive after the sync and an admin must tick Active (otherwise new equipment cannot be created).
Behavior changes against FR-001 (see CHANGELOG):
- FR-001 scenario 9 (non-existing category): the error is now our own `CategoryNotFoundErr`, not the platform table-relation error.
- FR-001 scenario 53 (Manager maintains categories): no longer true; maintenance is EQM - Administrator only.
Once published, field 50101.3 and the event signature become contracts. `CheckCategoryAllowed` is local, not API.

## Known limitations / verification pending
- **Not compiled.** .NET 10 is missing locally, so no build ran. The generated translation file `app/Translations/Equipment Management.g.xlf` (feature `TranslationFile`) does not exist yet; generate it with the first build and commit it. Never edit it by hand.
- **No automated tests.** Deferred to V5. The scenario list (C1-C12, E1-E13, D1-D3, U1-U5, P1-P3, V1-V2) is in `docs/plans/FR-002-equipment-categories.md`. FR-001 scenarios 9 and 53 are not covered by any test until then.
- TODO(verify) in a sandbox: partial or lower-case input in **Category Code**. With `ValidateTableRelation = false` the platform may no longer match partial input (for example `lap` to LAPTOP) or auto-complete lower-case input. Lower-case exact codes should still match because Code fields are upper case. If matching is lost, note it here and in the help article.
- TODO(verify) in a sandbox: renaming an active category in use updates equipment (cascade through the filtered relation).
- Writes without triggers (`Insert(false)`, `Modify(false)`, RapidStart without validation) can store a non-existing or inactive category.
- Open items outside FR-002: `docs/TODO.md` (marketplace properties, registered ID range, supportedLocales). W1 only; no target-language translations.

## Plan discrepancies
- Plan: OnRename exits when `xRec.Active` is true, and the search uses `SetLoadFields("No.")`. Code: exits only when `xRec.Active` and `Active` are both true (so deactivating and renaming together is also blocked), and sets no `SetLoadFields`.
