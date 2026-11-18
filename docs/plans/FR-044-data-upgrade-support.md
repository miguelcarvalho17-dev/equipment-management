# FR-044 Data Upgrade Support — Plan

> Request (verbatim): "FR-044 Data Upgrade Support" (GitHub issue #85)
> Status: **approved**

## Request
Give the app a reusable way to run upgrades. Each data change is its own step, guarded by an upgrade tag. The install and upgrade codeunits both run the steps. New companies get the tags through the standard Upgrade Tag event. Data must stay intact. Phase 1 adds the first real step: the FR-043 field "Default Warranty Alert Days" is set automatically on existing setup rows where it is still blank (0). That is the only field in the app whose blank value stands in for a default.
Target: AppSource

Tooling note: the AL MCP again reported "No AL projects are loaded" (the same as FR-038 to FR-043). Both `al_getnextobjectid` and `al_symbolsearch` failed. IDs come from a scan of every object declaration in `app/src` and `test/src`, plus the reservations in `docs/plans` and `docs/TODO.md`. The one standard event is confirmed on Microsoft Learn but not with the symbol tool (see Risks).

The user's request for this feature authorises upgrade and install code. Nothing else on the stop list is touched: no `app.json` change, no version bump, no new permission set.

**Resolved decision:** test codeunit ID 50177 is reused (NFR-005 releases its reservation). The user chose this option over widening `test/app.json` idRanges.

## Definition of done
- [ ] New internal codeunit 50139 "EQM Upgrade Mgt." (`app/src/Install/EQMUpgradeMgt.Codeunit.al`) contains:
  - `UpgradePerCompany()`, which runs every per-company step;
  - one tag-guarded step, `UpgradeDefaultWarrantyAlertDays()`;
  - the unguarded data procedure `InitDefaultWarrantyAlertDays()`;
  - the tag getter `GetDefaultWarrantyAlertDaysTag()`, which returns `MC-EQM-FR044-DefaultWarrantyAlertDays-20261118`;
  - a subscriber to `Codeunit::"Upgrade Tag"` `OnGetPerCompanyUpgradeTags` that registers the tag.
- [ ] `InitDefaultWarrantyAlertDays()` behaves as follows:
  - It sets "Default Warranty Alert Days" to `GetLongestIntervalDays()` (90) only when the setup row exists and the field is 0.
  - It leaves every other value and every other field alone.
  - It does nothing when no setup row exists. It never creates one.
  - It is idempotent.
- [ ] `EQM Upgrade` (50134) `OnUpgradePerCompany` calls `RegisterChangeLogSetupOnce()` as today, then `UpgradeMgt.UpgradePerCompany()`.
- [ ] `EQM Install` (50104) `OnInstallAppPerCompany` calls `UpgradeMgt.UpgradePerCompany()` as its last statement. A fresh install or a reinstall therefore runs the safe steps and sets the tags.
- [ ] Behaviour does not change. `GetWarrantyAlertDays()` already treats 0 as 90, so the stored value now matches what the code already used. The getter fallback stays.
- [ ] `EQM - Reader` (50100) has `codeunit "EQM Upgrade Mgt." = X`. Test 50162 SCENARIO 8 picks it up automatically and stays green.
- [ ] Test codeunit 50177 "EQM Upgrade Tests" contains 6 tests. They compile, and are reported as "Not verified: tests not executed locally, CI result pending".
- [ ] `app/` then `test/` compile with 0 errors and 0 warnings (CodeCop, UICop, AppSourceCop on app/).
- [ ] `app/Translations/Equipment Management.g.xlf` is regenerated. Only Locked labels are added, so there should be no new translatable unit.
- [ ] Docs:
  - `docs/features/FR-044-data-upgrade-support.md`, with a section "How to add an upgrade step" (checklist below);
  - `docs/help/FR-044-data-upgrade-support.md`;
  - `CHANGELOG.md` heading `## FR-044 Data Upgrade Support`;
  - `docs/TODO.md` section "FR-044 sandbox checks" (SB1 to SB5), plus the NFR-005 reservation note.

## Out of scope
- Bumping the `app.json` version (stop list, and a release decision). The upgrade trigger runs only when a higher version replaces an installed one. AL-Go CI artifacts get higher build numbers, so a sandbox update from one CI build to a newer one runs it.
- Default data for companies created after install (AA0235 `OnCompanyInitialize`). This is an existing gap from FR-001 and FR-034 R2.
- Registering the FR-034 change log tag for new companies. It is left unregistered on purpose (FR-034 R2) and stays that way.
- `OnCheckPreconditionsPerCompany` and `OnValidateUpgradePerCompany`, per-database steps, and `DataTransfer`. Phase 1 has no bulk table to move.
- FR-062 Breaking Change Validation (AppSourceCop baseline in `AppSourceCop.json`).
- Initializing any other field. All other `InitValue` fields (Category Active, Request Status, Assignment Status, Equipment Status, Maintenance Type, Feature Enabled) existed when their table was created, so there are no older rows with a wrong blank. Field 7 "Default Maint. Freq. (Months)" uses 0 to mean "no default" on purpose.

Later phases (one line each):
- Phase 2: an `OnCompanyInitialize` subscriber that creates default data for new companies (resolves AA0235 and FR-034 R2).
- Phase 3: precondition and validation triggers once a step moves real data, for example when a field is obsoleted.

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Codeunit | 50139 | EQM Upgrade Mgt. | New | `app/src/Install/EQMUpgradeMgt.Codeunit.al` |
| Codeunit | 50134 | EQM Upgrade | Changed (+1 call, +1 var) | `app/src/Install/EQMUpgrade.Codeunit.al` |
| Codeunit | 50104 | EQM Install | Changed (+1 call, +1 var) | `app/src/Install/EQMInstall.Codeunit.al` |
| PermissionSet | 50100 | EQM - Reader | Changed (+X on 50139) | `app/src/Permissions/EQMReader.PermissionSet.al` |
| XLIFF | – | Equipment Management.g.xlf | Regenerated | `app/Translations/Equipment Management.g.xlf` |
| Codeunit (test) | 50177 | EQM Upgrade Tests | New | `test/src/EQMUpgradeTests.Codeunit.al` |

About the IDs:
- Codeunit 50139 follows the house rule (next after the highest in use, 50138). Codeunits 50123-50129 are the API reserve.
- In app/, codeunit IDs in use are 50103-50122 and 50130-50138. In test/, IDs in use are 50161, 50162 and 50178-50199. Test IDs 50150-50177 are reserved in docs by FR-001 to FR-022 and NFR-002/003/005. 50177 was reserved by NFR-005 and never built; it is reused here.

## Events and standard symbols
| Symbol | Exact signature | Verified with al_symbolsearch |
|---|---|---|
| Codeunit 9999 "Upgrade Tag" (namespace `System.Upgrade`) | `HasUpgradeTag(Tag: Code[250]): Boolean` | No (MCP down). Already used and compiled in `app/src/ChangeLog/EQMChangeLogRegistration.Codeunit.al`; on Learn |
| Codeunit 9999 "Upgrade Tag" | `SetUpgradeTag(NewTag: Code[250])` | No (MCP down). Already used and compiled in 50133; on Learn |
| Event `OnGetPerCompanyUpgradeTags` on Codeunit "Upgrade Tag" | `[EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)] local procedure X(var PerCompanyUpgradeTags: List of [Code[250]])` | No (MCP down). On Learn only, signature taken from the Learn sample (see Risks) |
| Install/Upgrade triggers | `trigger OnInstallAppPerCompany()`, `trigger OnUpgradePerCompany()` | Already in 50104/50134; on Learn |
| In-app: codeunit 50110 | `internal procedure GetLongestIntervalDays(): Integer` (returns 90), `internal procedure GetIntervalDays(AlertInterval: Enum "EQM Warranty Alert Interval"): Integer`, `internal procedure GetWarrantyAlertDays(): Integer` | Read in source |
| In-app: table 50102 | fields 2 "Equipment Nos." Code[20], 4 "Integration Events Enabled" Boolean, 6 "Default Warranty Alert Days" Integer (InitValue 90, OnValidate 1..90), 7 "Default Maint. Freq. (Months)" Integer (0..120), PK "Primary Key" Code[10] | Read in source |
| In-app: codeunit 50133 | `internal procedure RegisterChangeLogSetupOnce()` | Read in source |

## Steps
1. **`app/src/Install/EQMUpgradeMgt.Codeunit.al`** (new). Why: the step logic goes into a normal codeunit so that Install, Upgrade and the tests can call it. AA0243 forbids running Upgrade-subtype codeunits, and this matches how 50133 is used. Exact content:
   ```al
   namespace MiguelCarvalho.EquipmentManagement;

   using System.Upgrade;

   /// <summary>
   /// Upgrade steps of the app. Each data change is one step, guarded by its own upgrade tag, so it runs once per company
   /// however often the upgrade or install is repeated. Called from "EQM Install" and "EQM Upgrade". New companies get every
   /// registered tag through OnGetPerCompanyUpgradeTags. Each step must be safe on fresh-install data, because the install runs it too.
   /// </summary>
   codeunit 50139 "EQM Upgrade Mgt."
   {
       Access = Internal;
       Permissions = tabledata "EQM Equipment Setup" = rm;

       var
           DefaultWarrantyAlertDaysTagTok: Label 'MC-EQM-FR044-DefaultWarrantyAlertDays-20261118', Locked = true;

       /// <summary>
       /// Runs every per-company upgrade step. Steps whose tag is already set are skipped.
       /// </summary>
       internal procedure UpgradePerCompany()
       begin
           UpgradeDefaultWarrantyAlertDays();
       end;

       /// <summary>
       /// Fills Default Warranty Alert Days (FR-043) on the existing setup row once per company, then sets the upgrade tag.
       /// </summary>
       internal procedure UpgradeDefaultWarrantyAlertDays()
       var
           UpgradeTag: Codeunit "Upgrade Tag";
       begin
           if UpgradeTag.HasUpgradeTag(GetDefaultWarrantyAlertDaysTag()) then
               exit;

           InitDefaultWarrantyAlertDays();
           UpgradeTag.SetUpgradeTag(GetDefaultWarrantyAlertDaysTag());
       end;

       /// <summary>
       /// Sets Default Warranty Alert Days to the longest alert interval (90) when the setup row exists and the field is blank (0).
       /// Rows created before the field existed read 0. Any other value, every other field, and a missing setup row are left alone.
       /// </summary>
       internal procedure InitDefaultWarrantyAlertDays()
       var
           EquipmentSetup: Record "EQM Equipment Setup";
           WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
       begin
           if not EquipmentSetup.Get() then
               exit;
           if EquipmentSetup."Default Warranty Alert Days" <> 0 then
               exit;

           EquipmentSetup."Default Warranty Alert Days" := WarrantyAlertMgt.GetLongestIntervalDays();
           EquipmentSetup.Modify(false);
       end;

       /// <summary>
       /// Returns the upgrade tag of the Default Warranty Alert Days step. Never change a shipped tag.
       /// </summary>
       /// <returns>The upgrade tag.</returns>
       internal procedure GetDefaultWarrantyAlertDaysTag(): Code[250]
       begin
           exit(DefaultWarrantyAlertDaysTagTok);
       end;

       [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
       local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
       begin
           PerCompanyUpgradeTags.Add(GetDefaultWarrantyAlertDaysTag());
       end;
   }
   ```
   Rules for the developer:
   - Assign the field directly. Do not call Validate (that would run the 1..90 range check) and do not run the Modify triggers (`Modify(false)`).
   - No `SetLoadFields`: the row is modified.
   - No UI, no Commit, no LockTable. The row is a single setup row, written in the upgrade's own system session or the install transaction.
   - If AppSourceCop or CodeCop complains about the Label name suffix or the `Code[250]` conversion, use `CopyStr(DefaultWarrantyAlertDaysTagTok, 1, 250)` in the getter, the same way 50133 does, and report it.
   Compile.

2. **`app/src/Install/EQMUpgrade.Codeunit.al`**: add the local var `UpgradeMgt: Codeunit "EQM Upgrade Mgt.";`, and after `ChangeLogRegistration.RegisterChangeLogSetupOnce();` add `UpgradeMgt.UpgradePerCompany();`. Why: existing tenants run the step on their next upgrade. Compile.

3. **`app/src/Install/EQMInstall.Codeunit.al`**: add the local var `UpgradeMgt: Codeunit "EQM Upgrade Mgt.";`, and add `UpgradeMgt.UpgradePerCompany();` as the last statement, after `RegisterChangeLogSetupOnce()` and therefore after `CreateDefaultData()`. Leave the existing order and comment alone. Why: a fresh install sets the tag, so the first upgrade does not run old steps. A reinstall over retained data with field 6 at 0 is also fixed, because Learn says install code runs on reinstall. Compile.

4. **`app/src/Permissions/EQMReader.PermissionSet.al`**: add `codeunit "EQM Upgrade Mgt." = X,` directly after `codeunit "EQM Default Data" = X,`. Why: the codeunit has an event subscriber that runs in normal user sessions when a company is created, so it is not install-only like 50104/50133/50134. Test 50162 SCENARIO 8 also requires X in Reader for every codeunit that is not on the exclusion list. Manager and Administrator inherit it. Do not edit test 50162. Compile `app/`, keep the regenerated `.g.xlf`, and require 0 errors and 0 warnings. If the MCP has no project, use the direct alc build as in FR-039 to FR-043, then copy the new app.app into `test/.alpackages` (gitignored).

5. **`test/src/EQMUpgradeTests.Codeunit.al`** (new), codeunit 50177 "EQM Upgrade Tests":
   - `namespace MiguelCarvalho.EquipmentManagement.Tests;`
   - usings: `MiguelCarvalho.EquipmentManagement; System.TestLibraries.Utilities; System.Upgrade;`
   - `Subtype = Test; TestPermissions = Disabled;`
   - Every test is `[Test]` `[TransactionModel(TransactionModel::AutoRollback)]` and calls `Initialize()` first. No Commit.
   - Globals: `Assert: Codeunit "Library Assert"`, `UpgradeMgt: Codeunit "EQM Upgrade Mgt."`, `WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt."`, `EquipmentNosTok: Label 'UPGNOS', Locked = true;`.
   - Helpers:
     - `Initialize()`: if `not EquipmentSetup.Get()` then `Init()` + `Insert(false)`.
     - `SetAlertDays(Value: Integer)`: Get, direct assignment, `Modify(false)`.
     - `EnsureTagSet()`: `if not UpgradeTag.HasUpgradeTag(UpgradeMgt.GetDefaultWarrantyAlertDaysTag()) then UpgradeTag.SetUpgradeTag(...)`, the same pattern as 50191.
   - Derive numbers from `WarrantyAlertMgt.GetLongestIntervalDays()` and `GetIntervalDays(...)`, never literals. Compile `test/` with 0 errors and 0 warnings.

6. **Documenter** (after review):
   - `docs/features/FR-044-data-upgrade-support.md` includes the section "How to add an upgrade step":
     1. Add a Locked Tok tag `MC-EQM-FR0NN-<What>-<yyyymmdd>` and an internal getter.
     2. Add an internal step procedure with the HasUpgradeTag guard, then the data change, then SetUpgradeTag.
     3. Add the tag in `RegisterPerCompanyUpgradeTags`.
     4. Call the step from `UpgradePerCompany()`.
     5. The step must be idempotent, set-based (ModifyAll or DataTransfer for big tables), with no UI or Commit, and safe on fresh-install data. If it is not safe there, Install must only set the tag.
     6. Never delete or rename published fields. Obsolete them (Pending, then Removed) and move their data in a step.
     7. Bump the version at release (user decision).
     8. Add positive and negative tests.
   - `docs/help/FR-044-data-upgrade-support.md`: what administrators see. Existing companies show 90 in Default Warranty Alert Days after the upgrade. Values they set themselves are kept. Nothing else changes.
   - `CHANGELOG.md` heading `## FR-044 Data Upgrade Support (version stays 29.0.0.0, no bump)`.
   - `docs/TODO.md`: add "FR-044 sandbox checks" SB1 to SB5. Change the NFR-005 heading to say test codeunit 50177 now belongs to FR-044 and a future NFR-005 test codeunit needs a new ID.

## Tests
Codeunit "EQM Upgrade Tests". There is one business rule: blank alert days become 90 exactly once, and nothing else changes.
- [SCENARIO 1] Blank alert days are initialized. [GIVEN] The setup row has Default Warranty Alert Days = 0 (`SetAlertDays(0)`). [WHEN] `UpgradeMgt.InitDefaultWarrantyAlertDays()` runs. [THEN] The field = `WarrantyAlertMgt.GetLongestIntervalDays()`.
- [SCENARIO 2] (negative) A value the user set is kept. [GIVEN] The field = `GetIntervalDays("30 Days")`. [WHEN] Init runs. [THEN] The field still equals that value.
- [SCENARIO 3] (negative) Other data is preserved. [GIVEN] The field is 0, "Equipment Nos." := `EquipmentNosTok`, "Integration Events Enabled" := not its current value, and "Default Maint. Freq. (Months)" := `Date2DMY(Today(), 1)` (1..31, inside 0..120). All are set by direct assignment followed by `Modify(false)`, and the values are stored in locals. [WHEN] Init runs. [THEN] The three fields equal the locals, and the alert days field = 90 (derived).
- [SCENARIO 4] (negative) A missing setup is not created. [GIVEN] `EquipmentSetup.DeleteAll()`. [WHEN] Init runs. [THEN] No error, and `Assert.RecordIsEmpty(EquipmentSetup)`.
- [SCENARIO 5] Idempotent. [GIVEN] The field is 0. [WHEN] Init runs twice. [THEN] The field = 90 and `EquipmentSetup.Count()` = 1.
- [SCENARIO 6] (negative) The tag stops a second run. [GIVEN] `EnsureTagSet()` (asserted with `HasUpgradeTag`) and the field is 0. [WHEN] `UpgradeMgt.UpgradeDefaultWarrantyAlertDays()` runs. [THEN] The field is still 0.

Existing tests likely affected, all expected to pass:
- 50162 SCENARIO 8 now also checks codeunit 50139 and passes because of step 4. If step 4 is missed, it fails, which is the intended safety net. The exclusion list stays 50104/50133/50134.
- 50199 is unaffected: its tests set field 6 directly, and the install already ran before them.
- 50191 is unaffected.

Manual sandbox checks (go to `docs/TODO.md`):
- SB1: Fresh install in a new sandbox. Equipment Setup shows Default Warranty Alert Days 90, and table 9999 "Upgrade Tags" (`?table=9999`) has `MC-EQM-FR044-DefaultWarrantyAlertDays-20261118` for each company.
- SB2: Upgrade path. Install a CI build from before FR-043 and open Equipment Setup. Then install an FR-044 CI build with a higher build number (upgrade). Default Warranty Alert Days is 90, and the number series and Integration Events Enabled are unchanged.
- SB3: A user value survives. Set alert days to 30 and upgrade to a newer build. It stays 30.
- SB4: Create a new company after install. The tag exists (Company Initialize calls SetAllUpgradeTags), and the setup created later shows 90.
- SB5: Uninstall with data kept, then reinstall the same version. No error, and the values are unchanged.

## Assumptions
- Assumed no prior release ("current version is the baseline"). Field 6 is still the right first step, because rows created in sandboxes before FR-043 read 0, and the step changes no behaviour (0 already meant 90).
- Assumed the user's request authorises changing Install (50104) and Upgrade (50134) and adding the upgrade-step codeunit, but not a version bump. The version stays 29.0.0.0.
- Assumed the FR-043 decision "blank/0 = 90 in the getter plus InitValue 90, over upgrade code" is extended rather than reversed. The getter fallback stays as a safety net, and the upgrade step only makes the stored value match it. That decision was taken only because upgrade code was then on the stop list.
- Assumed the FR-034 change log tag stays unregistered for new companies (FR-034 R2).
- Assumed codeunit ID 50139 (house rule: next after the highest in use, outside the API reserve 50123-50129).
- Assumed the tag format `MC-EQM-FR044-<What>-<yyyymmdd>`, following the existing FR-034 tag and the Learn convention.
- No mismatch found between `CLAUDE.md` and `app/app.json` (29.0.0.0, runtime 18.0, range 50100-50149, TranslationFile on).

## Risks
- **`OnGetPerCompanyUpgradeTags` was not checked with al_symbolsearch** (MCP down). Name and signature come from Learn. The compile is the final check. If it fails, the developer reports it and does not guess a different signature.
- **The upgrade trigger only runs on a higher version.** Version 29.0.0.0 is not bumped. SB2 relies on AL-Go CI builds having increasing build numbers, so check the artifact versions before SB2.
- **Install transaction:** Install now also writes the setup row after `CreateDefaultData()`. Existing comment: "The isolated run must come before any write in the install transaction". The new call is last, so the order rule holds. The reviewer checks this.
- **Permissions:** the install runs as the installing user. The codeunit's `Permissions = tabledata "EQM Equipment Setup" = rm` is indirect, and the installing user is expected to be SUPER or Administrator (who has RIMD). Reader getting X on 50139 gives no data access, and all its procedures are internal.
- **Tests depend on the install having run in the CI company** (setup row and tag). `Initialize()` and `EnsureTagSet()` cover both, as 50191 does.
- **The test ID range is exhausted.** The next feature with tests runs into the same problem; consider widening `test/app.json` idRanges then.
- **Data preservation:** the step only touches 0 values on one row. Negative or out-of-range values (only possible through code) are left as they are, and the getter still treats them as 90.
- **AA0235** (Info: install without an `OnCompanyInitialize` subscriber) already exists and is not introduced here. Phase 2 deals with it.
- No separate AppSource validation ran. The reviewer checks the AppSource rules: affix (`EQM` on codeunit 50139), Access = Internal, Locked tag label, no breaking change (purely additive), and the permission entry.

## DECISIONS
- FR-044 | Chose a new internal codeunit "EQM Upgrade Mgt." holding the steps, tags and tag subscriber, called from Install and Upgrade, over putting the logic in the Upgrade-subtype codeunit, because upgrade codeunits cannot be run (AA0243) and tests need to call the steps | Reversible: no (object ID becomes permanent at release)
- FR-044 | Chose to have Install run the same steps (each must be safe on fresh-install data) over only setting the tags, so a reinstall over retained data with blank values is also fixed | Reversible: yes
- FR-044 | Chose to register the tag through OnGetPerCompanyUpgradeTags, so new companies count as upgraded, and to leave the FR-034 change log tag unregistered | Reversible: yes
- FR-044 | Chose to initialize only field 6 "Default Warranty Alert Days" (0 → 90) over a generic InitValue sweep, because it is the only field whose blank stands for a default; field 7 uses 0 to mean "none" | Reversible: yes
- FR-044 | Chose to keep the GetWarrantyAlertDays 0 → 90 fallback after the upgrade step, as a safety net for rows the step cannot reach | Reversible: yes
- FR-044 | Chose X in EQM - Reader for codeunit 50139 over adding it to the test 50162 exclusion list, because its subscriber runs in normal user sessions (company creation) | Reversible: yes
- FR-044 | Chose no version bump and no precondition or validation triggers in phase 1 | Reversible: yes
- FR-044 | Chose test codeunit 50177 (reusing the NFR-005 reservation) over widening test/app.json idRanges, on the user's answer | Reversible: yes (test objects are not published)

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-upgrading-extensions#using-upgrade-tags-to-control-upgrade-code — tag pattern, `HasUpgradeTag`/`SetUpgradeTag`, the `OnGetPerCompanyUpgradeTags` signature, install must set the tags, tag naming convention, SetAllUpgradeTags called from Company Initialize
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code — install code runs on first install and on reinstall, not on upgrade
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/devenv-onupgradepercompany-codeunit-trigger — runs once per company in its own system session; an error cancels the upgrade
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/codecop-aa0243 — running an upgrade codeunit is not allowed (why the logic sits in 50139)
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/codecop-aa0235 — existing install-without-OnCompanyInitialize note (phase 2)
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-app-life-cycle#maintain-and-update-your-app — data kept on uninstall; reinstalling a newer version runs the upgrade path, the same version the reinstall path
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission — AppSource technical validation
