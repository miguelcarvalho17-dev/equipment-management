# FR-002 Equipment Categories

> Status: REVISION 2, **APPROVED** by the user (decisions Q1-Q8 below are final).
> No events report: FR-002 does not change standard BC behavior and subscribes to no standard events.
> Scope of this phase: main app only. **No upgrade logic** (nothing has been published yet). **No automated tests**
> (deferred to V5). **W1 only** (no target-language translations).
> Workflow for FR-002: planner -> developer -> reviewer -> **tester step SKIPPED (tests deferred to V5)** -> documenter -> appsource-validator.

## Goal
Administrators maintain a list of equipment categories (Code, Description, Active). Category codes are unique.
Only active categories can be chosen when equipment is created or when its category is changed. Equipment that
already uses a category keeps it after the category is made inactive.

### Requirement restated, with final decisions
- FR-001 already created table 50101 "EQM Equipment Category" (Code, Description), page 50102 "EQM Equipment Categories",
  the mandatory "Category Code" on EQM Equipment, a delete guard for categories in use, and five starter categories.
  FR-002 **extends these objects**. It does not create a second category table.
- Uniqueness: Code is the primary key, so it is unique already. Code fields are upper case, so 'laptop' and 'LAPTOP' are the same code.
- New field Active (Boolean). New categories are active by default (`InitValue = true`).
- "Inactive categories cannot be selected for new equipment records" is applied as: an inactive category can **not be
  newly set** on equipment. This covers new equipment and a category change on existing equipment (Q1).
- Existing equipment that already uses a category that later becomes inactive keeps it. It can still be edited,
  assigned, unassigned and deleted. Re-validating the same inactive code is allowed. Changing to an active category is
  allowed. Changing back to the inactive category afterwards is refused.
- Deactivating a category in use is allowed, with no confirmation and no change to equipment.
- Deleting a category in use stays blocked (FR-001 rule, active or inactive). The error now suggests deactivating instead.
- Lookups (the dropdown and the lookup page on the Equipment Card "Category Code") show active categories only.
- "List/card page": a single editable list page (existing page 50102) with a new Active column. No separate card (3 fields).
- Category maintenance becomes an **administrator** right (EQM - Admin). EQM - Edit can only read categories (Q2).

## Approach and rejected alternatives
- Chosen:
  - Add field 3 Active (Boolean, `InitValue = true`) to own table 50101. Show it on page 50102.
  - On EQM Equipment field "Category Code": filter the TableRelation to active categories
    (`where(Active = const(true))`), so every lookup and dropdown shows active ones only.
    Set `ValidateTableRelation = false`, so the platform does not raise its generic "cannot be found in the related table" error.
    The table does the check itself with two clear messages: category does not exist, and category is not active.
  - One internal check procedure `CheckCategoryAllowed(CheckIsActive)`, called from:
    - the field OnValidate, with the active check only when the value changed against xRec;
    - `CheckEquipmentConsistency` on insert (always checks active) and on modify (checks active only when the code differs from the stored record).
    So direct assignment without Validate (API, code, RapidStart) cannot set an inactive category either.
  - One new IsHandled event before the active check, in line with the FR-001 extensibility pattern (Q8).
  - No upgrade codeunit and no upgrade tag: the app has never been published, so there is no customer data to upgrade (Q3).
  - Category rename guard: renaming a category that is inactive and used by equipment is blocked (see Risks R2).
- Rejected: a "Blocked" field instead of "Active". The requirement names an Active flag, and inverted wording on the page confuses admins.
- Rejected: an upgrade codeunit with an upgrade tag to set Active = true on existing rows. Nothing is published, so there is nothing to upgrade (user decision Q3).
- Rejected: filtered TableRelation with the default `ValidateTableRelation = true`. It gives a generic platform error for inactive categories and breaks code that re-validates an existing inactive value.
- Rejected: unfiltered TableRelation plus a page OnLookup on the card (the FR-001 employee pattern). Inactive categories would still show in dropdowns and on any other page that uses the field.
- Rejected: blocking deactivation while equipment uses the category. Admins must be able to retire a category without touching every equipment record.
- Rejected: a separate category card page. Three fields fit an editable list. A card adds an object and no value.
- Rejected: a "No. of Equipment" FlowField on the category. Useful, but outside the requirement. Can be a later item.

## Objects
Existing IDs in use (checked in `app/src`): tables 50100-50102, pages 50100-50103, codeunits 50103-50105, enum 50100,
permission sets 50100-50102, permission set extension 50103. FR-002 creates **no new objects**; it only modifies existing ones.
Files stay where they are (`app/src/Equipment/`, `app/src/Setup/`, `app/src/Permissions/`). No `/test` changes.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50101 | EQM Equipment Category | Modify (own) | Add Active; OnRename guard; delete error text updated |
| Table | 50100 | EQM Equipment | Modify (own) | Category Code relation filtered to Active; existence and active checks; new event |
| Page | 50102 | EQM Equipment Categories | Modify (own) | Add Active column |
| Codeunit | 50105 | EQM Default Data | Modify (own) | Add starter categories TABLET and PRINTER; PHONE description 'Mobile Phone' (Q4) |
| PermissionSet | 50101 | EQM - Edit | Modify | Remove category RIMD (keeps R via EQM - Read) |
| PermissionSet | 50102 | EQM - Admin | Modify | Add category RIMD |
| app.json | n/a | app/app.json | Modify | Add `TranslationFile` feature; version 29.1.0.0 (Q5) |

Not changed: codeunit 50104 "EQM Install", pages 50100/50101/50103, codeunit 50103, permission set 50100, permission set extension 50103, `test/` folder.

Next free IDs after this feature (unchanged by FR-002): app tables 50103, pages 50104, codeunits 50106, enums 50101,
permission sets 50104 (50103 is used by the permission set extension). Test range: FR-002 uses none (FR-001 reserved 50150-50155, not built).

### Table 50101 "EQM Equipment Category" (changes)
- New field 3 Active, Boolean, Caption 'Active', `InitValue = true`.
  ToolTip: 'Specifies whether the category can be selected for equipment. Equipment that already uses an inactive category keeps it.'
  No DataClassification on the field (inherits CustomerContent from the table).
- No new keys. Field groups unchanged (DropDown = Code, Description; the dropdown is filtered to active ones anyway).
- OnDelete: unchanged logic. Change the label text of `CategoryInUseErr` to:
  'You cannot delete category %1 because it is used by one or more equipment records. To stop using the category, clear the Active check box instead.'
  Comment: '%1 = category code'.
- New OnRename trigger:
  1. If xRec.Active is true, exit.
  2. On a separate EQM Equipment record: SetLoadFields("No."), SetCurrentKey("Category Code"), SetRange("Category Code", xRec.Code).
  3. If not IsEmpty: Error(CategoryRenameInactiveErr, xRec.Code).
  New label `CategoryRenameInactiveErr`: 'You cannot rename category %1 because it is not active and is used by equipment. Select the Active check box, rename the category, and then clear the check box again.'
  Comment: '%1 = category code'.
- Table access stays Public. Add a `/// <summary>` doc comment on the OnRename guard explaining why it exists (R2).

### Table 50100 "EQM Equipment" (changes)
Field 3 "Category Code":
- TableRelation becomes `"EQM Equipment Category" where(Active = const(true))`.
- Add `ValidateTableRelation = false`. Keep `NotBlank = true`.
- ToolTip becomes: 'Specifies the category of the equipment. Only active categories can be selected.'
- New OnValidate trigger: call `CheckCategoryAllowed("Category Code" <> xRec."Category Code")`.

New local procedure `CheckCategoryAllowed(CheckIsActive: Boolean)`:
1. Exit if "Category Code" is blank. (NotBlank and the existing `TestField` in `CheckEquipmentConsistency` handle blanks.)
2. Read EQM Equipment Category with `SetLoadFields(Active)` and `Get("Category Code")`.
   If not found: Error(CategoryNotFoundErr, "Category Code").
3. Exit if not CheckIsActive.
4. Raise `OnBeforeCheckCategoryIsActive(Rec, IsHandled)`; exit if IsHandled.
5. If not Category.Active: Error(CategoryInactiveErr, "Category Code").

Changes to `CheckEquipmentConsistency(IsNewRecord)`:
- Step 1 stays `TestField("Category Code")`.
- The stored-record read for the modify case moves before the category check and becomes
  `StoredEquipment.SetLoadFields("Assigned Employee No.", "Category Code")`.
  - New Boolean `CategoryChanged`, true by default.
  - When not IsNewRecord and the stored record is found: `CategoryChanged := StoredEquipment."Category Code" <> "Category Code"`.
  - `EmployeeChanged` is computed from the same read as today.
- New step after the TestField: `CheckCategoryAllowed(CategoryChanged)`. On insert CategoryChanged is true, so the active check always runs.
- The rest (serial no., employee checks, required employee, `OnAfterCheckEquipmentConsistency`) is unchanged and in the same order.
- Update its `/// <summary>` to mention "category exists, and is active when it is new or changed".

New labels in table 50100 (full sentences, with Comment):
- `CategoryNotFoundErr`: 'Equipment category %1 does not exist. Choose a category from the Equipment Categories page.' Comment: '%1 = category code'.
- `CategoryInactiveErr`: 'You cannot select equipment category %1 because it is not active. Choose an active category, or ask an administrator to activate it.' Comment: '%1 = category code'.

New published event (see Events): `OnBeforeCheckCategoryIsActive`, with a `/// <summary>` doc comment in the FR-001 style.

### Page 50102 "EQM Equipment Categories" (changes)
- Add the column Active after Description in the repeater (no control properties; ToolTip comes from the table).
- Everything else is unchanged: List, editable, DelayedInsert, UsageCategory = Administration, ApplicationArea = All at page level.
- No default filter. Admins see active and inactive categories.

### Page 50101 "EQM Equipment Card" and page 50100 "EQM Equipment List"
- No code changes. The card lookup on "Category Code" follows the filtered TableRelation automatically.
- Equipment that uses an inactive category shows the code normally.

### Codeunit 50105 "EQM Default Data" (changes, Q4)
- Add two starter categories, using the same `InsertCategoryIfMissing` path:
  - TABLET 'Tablet';
  - PRINTER 'Printer'.
  New Locked code labels `TabletCodeTok` 'TABLET' and `PrinterCodeTok` 'PRINTER'. New translatable description labels
  `TabletDescriptionTxt` 'Tablet' and `PrinterDescriptionTxt` 'Printer', with `MaxLength = 100`.
- Change the text of `PhoneDescriptionTxt` from 'Phone' to 'Mobile Phone'. The code stays PHONE.
- Insert order: LAPTOP, MONITOR, PHONE, TABLET, PRINTER, VEHICLE, TOOL.
- New categories are active through `InitValue` (Init is already called). Do not set Active explicitly.
  Never change Active or the description of an existing category (the "if missing" rule applies, so this is for new companies only).
- Update the `CreateDefaultData` doc comment to list the seven codes.

### app/app.json (changes)
- `features`: add `"TranslationFile"` next to `"NoImplicitWith"`. The build then generates `app/Translations/Equipment Management.g.xlf`.
  Commit the generated `.g.xlf`. Never edit it by hand.
  - Recommendation (Q7): keep it even for W1-only. It costs nothing, AppSource technical validation expects the
    generated source xlf for apps with user-facing labels, and it is the base for any later target language. No target-language `.xlf` files.
- `version`: raise from 29.0.0.0 to **29.1.0.0** (Q5, final).
- Do not touch `supportedLocales` or other properties in FR-002 (W1 only; marketplace properties stay a TODO item).
- Developer self-check after build: the `.g.xlf` is generated and contains the new labels, the Active caption and the tooltips; no analyzer warnings.

## Data model and upgrade impact
- New field: table 50101 field 3 Active (Boolean, CustomerContent inherited from the table, InitValue true). No other schema change.
- "Category Code" on table 50100: the TableRelation filter and `ValidateTableRelation` change. Type, length and ID are unchanged, so there is no schema change.
- **Upgrade codeunit needed: no** (Q3). The app has never been published. No upgrade codeunit, no upgrade tag, no install codeunit change.
- Development sandboxes: when the new column is synced onto existing data, existing category rows get Active = false
  (InitValue applies to new records only). Developers either reinstall/recreate the app data, or tick Active on the existing
  categories by hand on page 50102. This is a dev-only step, not shipped logic (see R7).
- Existing equipment is not changed.
- Category rename: cascades to equipment through the TableRelation (platform). Inactive categories that are used cannot be renamed (R2).
- Uninstall keeps the data (standard).

## Events
Subscribed:
- None. FR-002 does not touch standard behavior.

Published (in the Public table "EQM Equipment", `[IntegrationEvent(false, false)]`, `local`, record passed by value):
- `OnBeforeCheckCategoryIsActive(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)`, **with IsHandled** (Q8: keep).
  - Raised only when the active check would run: a new record, or a changed category.
  - Setting IsHandled skips **only** the "category must be active" check. The "category must exist" check and the blank check still run.
  - Use case: partners that allow inactive categories in a special flow (e.g. data migration).
  - Doc comment: "Raised before the check that a new or changed category is active." Param Equipment: "The record being checked (passed by value; changes are not kept)." Param IsHandled: "Set to true to allow an inactive category. The category must still exist."
- Additional partner checks on save are already possible through the FR-001 event `OnAfterCheckEquipmentConsistency`. No new "after" event.

## Permissions
- `EQM - Read` (50100): no change. It keeps `tabledata "EQM Equipment Category" = Ri`. The lowercase i is needed for the default data codeunit (indirect).
- `EQM - Edit` (50101): **remove** `tabledata "EQM Equipment Category" = RIMD`. Edit users still read categories through EQM - Read.
- `EQM - Admin` (50102): **add** `tabledata "EQM Equipment Category" = RIMD`.
- No new objects, so no new permission entries otherwise.
- The EQM D365 BASIC extension (50103): no change.
- Help text (documenter): "Maintaining categories needs the Equipment - Admin permission set."

## Compatibility
- AppSource mode, but nothing has been published (validator verdict NOT READY), so there is no released baseline.
  Per user decision Q8 there is no breaking-change or permanence concern during development; no Obsolete handling is needed.
- Changes are additive for AppSourceCop anyway: new field on a Public table, new event.
- Behavior changes to list in the changelog:
  - Inactive categories can no longer be set on equipment.
  - For a non-existing category code, the error changes from the platform table-relation error to `CategoryNotFoundErr` (FR-001 scenario 9 changes; see deferred E4).
  - Category maintenance moves from EQM - Edit to EQM - Admin (FR-001 scenario 53 changes; see deferred P2/P3).
  - Renaming an inactive category in use is blocked.
  - New companies get TABLET and PRINTER, and PHONE is described as 'Mobile Phone'.
- Internal, not API: `CheckCategoryAllowed`. No internalsVisibleTo.
- Once the app is first published, field 50101.3 Active and the event signature become contracts (note for the future only).

## Test scenarios
**Deferred to V5 (user decision Q6). No test codeunits, no `test/app.json` change, no test-app IDs in FR-002. The tester step is skipped.**
Scenario list kept for V5 (one line each; the V5 planner expands them to full Given/When/Then):
- Category master: C1 new category defaults Active = true; C2 duplicate code refused; C3 lower-case duplicate refused (upper-case codes);
  C4 blank code refused; C5 deactivating a used category succeeds, equipment unchanged, no confirm; C6 reactivation works;
  C7/C8 delete of a used category (active / inactive) refused with new `CategoryInUseErr` text; C9 delete of an unused inactive category works;
  C10 rename of an active used category cascades to equipment; C11 rename of an inactive used category refused (`CategoryRenameInactiveErr`);
  C12 rename of an unused inactive category works and stays inactive.
- Equipment and category: E1 new equipment with active category saves; E2 validate inactive category on new equipment refused;
  E3 direct assignment of inactive category + Insert(true) refused; E4 validate non-existing code gives `CategoryNotFoundErr` (replaces FR-001 scenario 9);
  E5 same via direct assignment + Insert(true); E6 editing other fields of equipment whose category became inactive saves;
  E7/E8 changing to an inactive category refused (validate / direct assignment + Modify(true)), record unchanged;
  E9 re-validating the same inactive code is allowed; E10 changing to an active category works; E11 changing back to the inactive one is refused;
  E12 setting Status Retired on equipment with an inactive category saves;
  E13 given equipment E whose category was made inactive and an active employee, when E is assigned to that employee (Status Assigned, employee validated, Modify(true)), then E is saved with no category error.
- Default data: D1 new company gets the seven starter categories, all active, PHONE = 'Mobile Phone'; D2 an existing PHONE ('Phone', inactive) is not changed;
  D3 running defaults again creates no duplicates and no error.
- UI: U1 new category on page 50102 is active, Active column visible and editable; U2 card lookup shows active categories only;
  U3 setting an inactive category on the card is refused; U4 editing a card whose category is inactive saves;
  U5 Assign to Employee on a card whose category is inactive succeeds.
- Permissions: P1 EQM - Read can read but not insert/modify categories; P2 EQM - Edit can create equipment but not insert/modify categories (replaces FR-001 scenario 53);
  P3 EQM - Admin can insert, deactivate and delete categories.
- Published event: V1 subscriber setting IsHandled allows an inactive category; V2 with IsHandled, a non-existing code is still refused.

## Risks and open questions
Final decisions (approved by the user):
- Q1: the active check applies to new equipment and to a category change on existing equipment.
- Q2: category create/edit/delete is EQM - Admin only.
- Q3: no upgrade logic (no upgrade codeunit, no upgrade tag, no install change). Active is a Boolean with InitValue = true.
- Q4: add TABLET and PRINTER; PHONE described as 'Mobile Phone'; new companies only.
- Q5: version 29.1.0.0.
- Q6: no tests in this phase; deferred to V5. Tester step skipped.
- Q7: W1 only. Keep the `TranslationFile` feature (generated source xlf), no target languages, no supportedLocales work.
- Q8: keep `OnBeforeCheckCategoryIsActive`; no permanence concern during development.

Open questions: none.

Risks:
- R2 Rename cascade through a **filtered** TableRelation: it is not verified whether the platform updates equipment when an *inactive* category (outside the relation filter) is renamed. The OnRename guard blocks that case, so the result is always consistent. It can be removed later if a sandbox check shows the cascade works. Active categories are inside the filter and cascade normally.
- R3 `ValidateTableRelation = false` means the existence check is ours. It runs on validate and on insert/modify with triggers. Writes without triggers (`Insert(false)`, `Modify(false)`, RapidStart without validation) can store a non-existing or inactive code. This is the same limitation as all trigger-based checks in FR-001. Document it.
- R4 Companies that already ran default data do not get TABLET and PRINTER (by design). Admins add them by hand if they want them.
- R5 Code that re-validates "Category Code" with a value different from xRec on existing equipment with an inactive category (for example, after manually editing xRec) is refused. This is the intended rule.
- R6 AppSource readiness items in `docs/TODO.md` (marketplace properties, registered ID range and affix, supportedLocales) are still open and outside FR-002.
- R7 No upgrade logic: if a build of this app is ever installed on top of 29.0.0.0 data that must be kept, existing categories become inactive and no new equipment can be created until an admin ticks Active. Acceptable only because nothing is published; if 29.0.0.0 is ever released before FR-002, this plan must be revised to add upgrade logic.
- R8 No automated tests in this phase: regressions in FR-001 behavior (scenarios 9 and 53 change) are not caught automatically until V5. The reviewer checks these paths by reading the code.
- Documenter: update `docs/features/` and `docs/help/` for categories (Active flag, Admin permission, rename and delete rules) and create `CHANGELOG.md` if it is missing. Note that tests are deferred to V5.
