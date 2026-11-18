# FR-044 Data Upgrade Support

## Purpose
The app gets a reusable way to run data upgrades. Each data change is one step. Each step is guarded by its own upgrade tag, so it runs once per company, however often the upgrade or the install is repeated. Phase 1 adds the first real step: the FR-043 field "Default Warranty Alert Days" is set on existing setup rows where it is still blank (0).

Status: implemented on branch `feature/FR-044-data-upgrade-support`, not committed, not merged. App version stays 29.0.0.0 (unreleased, no bump, no app.json change). One new internal codeunit, one new test codeunit, one changed permission set entry, and changes to the install and upgrade codeunits.

## Verification status
- **Build:** not recorded in this document. Before the pull request, confirm that `app/` and `test/` compile with 0 errors and 0 warnings.
- **Review:** APPROVED. One MINOR finding: no test covers the positive tag path or the tag subscriber. Sandbox checks SB1 and SB4 cover them (see `docs/TODO.md`).
- **Tests: written, NOT executed.** Test codeunit 50177 "EQM Upgrade Tests" (6 tests) has not been run locally. There is no command-line test runner and no sandbox here. CI result pending. Nothing here claims the tests pass.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the AppSource rules (affix on the new codeunit, `Access = Internal`, locked tag label, no breaking change: the change is additive).
- **Not verified:** sandbox checks SB1 to SB5. See `docs/TODO.md`, section "FR-044 sandbox checks".

## What changes for existing data
- An existing equipment setup with Default Warranty Alert Days = 0 gets 90 once per company. 90 is the value the app already used for a blank field (FR-043), so the behaviour does not change.
- Any other value is kept. A user who set 30 keeps 30.
- No other field is changed. The number series, Integration Events Enabled and Default Maintenance Frequency (Months) are left alone.
- A company without a setup row gets no row. The step never creates one.
- The step runs again only when its tag is missing. Running the upgrade twice changes nothing the second time.

## How the steps run
- **Upgrade** (`EQM Upgrade`, OnUpgradePerCompany): registers the change log setup once (FR-034), then runs every upgrade step. Existing companies run the steps on their next upgrade to a higher version.
- **Install** (`EQM Install`, OnInstallAppPerCompany): creates the default data and registers the change log setup, then runs every upgrade step as its last statement. A fresh install and a reinstall therefore set the tags. A reinstall over retained data is also fixed.
- **New companies:** every registered tag is set through the standard Upgrade Tag event `OnGetPerCompanyUpgradeTags`, so a company created after install does not run old steps.
- The upgrade and install code run in their own sessions and must not show UI. Install code runs in the install transaction, so the install keeps its existing order: the isolated monitoring job run comes first.

## Upgrade tags
| Tag | Step | Purpose |
|---|---|---|
| `MC-EQM-FR044-DefaultWarrantyAlertDays-20261118` | Default Warranty Alert Days | Sets the blank value to 90 once per company |

Never change a shipped tag. Changing it runs the step again in every company.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Codeunit | 50139 | EQM Upgrade Mgt. | New. Internal. Holds the steps, the tags and the tag subscriber. |
| Codeunit | 50134 | EQM Upgrade | Changed. Calls `UpgradePerCompany()` after the change log registration. |
| Codeunit | 50104 | EQM Install | Changed. Calls `UpgradePerCompany()` as its last statement. |
| Permission set | 50100 | EQM - Reader | Changed. Execute on codeunit 50139. |
| Codeunit (test) | 50177 | EQM Upgrade Tests | New, not executed. 6 tests. |

No event is published. No base application object is changed. No table or field changes. The translation file gets no new translatable text, because the tag label is locked.

## Permissions
- **EQM - Reader:** execute on codeunit 50139. The codeunit has an event subscriber that runs in normal user sessions when a company is created, so it is not install-only. Its procedures are internal, so no user can call them from the UI. The codeunit itself has no data access for Reader.
- **EQM - Manager and EQM - Administrator:** inherit the Reader entry.
- The step writes the setup row with `Permissions = tabledata "EQM Equipment Setup" = rm`. The installing user is expected to be SUPER or an Administrator.

## Design decisions
- **The steps sit in a normal internal codeunit.** Upgrade-subtype codeunits cannot be run from code (CodeCop AA0243). Install, Upgrade and the tests all call the same internal procedures.
- **Install runs the same steps as the upgrade.** Each step must therefore be safe on fresh-install data. A reinstall over retained data with blank values is also fixed. If a future step is not safe on fresh-install data, Install should only set its tag.
- **Only Default Warranty Alert Days is initialized.** It is the only field whose blank value stands in for a default. Default Maintenance Frequency (Months) uses 0 to mean "no default", so 0 is not changed. The other initial values existed when their table was created, so there are no older rows with a wrong blank.
- **The getter fallback stays.** The FR-043 getter still treats 0 as 90. The upgrade step makes the stored value match what the code already used. Rows that the step cannot reach keep working.
- **The change log tag stays unregistered for new companies.** This is the FR-034 decision (R2). It is left unchanged here.
- **No version bump.** The upgrade code runs only when a higher version replaces an installed one. Releasing a new version is a user decision.

## How to add an upgrade step
Follow these steps in `app/src/Install/EQMUpgradeMgt.Codeunit.al`.

1. Add a Locked label tag `MC-EQM-FR0NN-<What>-<yyyymmdd>` and an internal getter that returns it. Never change a shipped tag.
2. Add an internal step procedure with the `HasUpgradeTag` guard first, then the data change, then `SetUpgradeTag`. Follow `UpgradeDefaultWarrantyAlertDays()` as the pattern.
3. Add the tag to `RegisterPerCompanyUpgradeTags` (the `OnGetPerCompanyUpgradeTags` subscriber), so new companies count as upgraded.
4. Call the step from `UpgradePerCompany()`.
5. The step must be idempotent, set-based (ModifyAll, or DataTransfer for big tables), with no UI and no Commit, and safe on fresh-install data. If it is not safe there, Install must only set the tag.
6. Never delete or rename published fields. Obsolete them first (Pending, then Removed) and move their data in a step.
7. Bump the version at release. This is a user decision.
8. Add positive and negative tests in the test app, the same way as "EQM Upgrade Tests".

## Known limitations
- **Companies created after install** get the default data only from the install code path (AA0235, an existing gap from FR-001). Phase 2 deals with it.
- **No precondition or validation triggers yet.** Phase 3 adds them once a step moves real data, for example when a field is obsoleted.
- **Per-database steps and DataTransfer** are not used. Phase 1 has no bulk table to move.

## Test status
- **Codeunit 50177 "EQM Upgrade Tests" (6 tests):** blank alert days are initialized, a user value is kept, other setup data is preserved, a missing setup is not created, the step is idempotent, and the tag stops a second run.
- Written; not executed locally. CI result pending.
- Gap from the review (MINOR): no test for the positive tag path and the tag subscriber. Sandbox checks SB1 and SB4 cover them.
- Sandbox checks SB1 to SB5 are open (`docs/TODO.md`, section "FR-044 sandbox checks").

## Related
- Help article: `docs/help/FR-044-data-upgrade-support.md`
- Changelog: `CHANGELOG.md`, entry FR-044
- Plan: `docs/plans/FR-044-data-upgrade-support.md`
- Sandbox checks: `docs/TODO.md`, section "FR-044 sandbox checks"
- Application setup: `docs/features/FR-043-application-setup.md`
- Change log support: `docs/features/FR-034-change-log-support.md`
- Upgrade tags on Microsoft Learn: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-upgrading-extensions#using-upgrade-tags-to-control-upgrade-code
