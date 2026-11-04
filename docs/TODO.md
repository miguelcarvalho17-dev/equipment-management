# TODO for next development sessions

Open items after FR-001 Equipment Registration (written 2026-11-02). Nothing from FR-001 has been compiled or tested yet.

## Verify FR-001 first
- [x] (done 2026-11-02, builds with no warnings) Run **AL: Package** on `app/` with CodeCop, UICop and AppSourceCop on. Fix every warning and error. The compiler could not run in the agent environment (alc needs .NET 10).
- [ ] Check that `app/.alpackages` still holds the BC 29 symbols (the validator reported it missing).
- [ ] Sandbox checks (also listed in `docs/features/FR-001-equipment-registration.md`):
  - [ ] Deleting an Employee from the Employee Card fires the implicit `OnBeforeDeleteEvent` guard: blocked when equipment references the employee, allowed otherwise.
  - [ ] A user with only D365 BASIC (and no EQM set) can delete an employee who has no equipment (indirect permission on EQM Equipment works).
  - [ ] A user with only EQM - Read can open Equipment Setup in a fresh company.
  - [ ] Publish and republish into a fresh company: defaults appear once, no duplicates.
  - [ ] On a new card, the number-series button keeps the "No." until the page closes.
  - [ ] Setting Status to Assigned directly on an existing card fails on save (employee required); the Assign to Employee action is the intended path.
  - [ ] FR-005: on an Assigned card, choosing Available in Status fails at once with the "use the Return action" message and no confirmation; In Maintenance still works and closes the entry. Return (card and Employee Card > Return Equipment) closes the entry, keeps it, and the equipment can be assigned again.
  - [ ] Deleting from the non-editable Equipment List shows the confirmation.
  - [ ] FR-006: open a Closed entry on Equipment Assignments (no field editable). Rename equipment and an employee that have closed history: no error, and the entries show the new numbers (plan H12, risk R3).
  - [ ] FR-006: delete equipment with history from the card and from the list (Available, Disposed, Lost, In Maintenance): the history error appears and nothing is deleted. Assigned equipment gives the "return first" error. Never-assigned equipment is deleted.
  - [ ] FR-006: after build, `Equipment Management.g.xlf` contains the new labels and tooltip and no `ActiveAssignmentExistsErr`.

## Open design and fix items
- [ ] **New companies:** default data and number series are created only in `OnInstallAppPerCompany`. In a company created later the setup record is missing, and equipment creation fails on `TestField("Equipment Nos.")`. Create the defaults on company initialization (subscribe to the company-initialize event) or give the user path working permissions. A non-SUPER user opening Setup needs No. Series insert rights, which no EQM set grants.
- [ ] **Setup permissions:** EQM - Read has indirect insert/modify (`Rim`) on EQM Equipment Setup. The validator finds this too permissive for a read set. Consider restricting modify to EQM - Admin.
- [ ] Decide whether "Assigned Employee No." should carry a personal-data classification.
- [ ] Setup defaults are created only when the setup record is missing. If the record exists but "Equipment Nos." is blank, nothing happens. Fix or document.

## AppSource FAILs (validator verdict: NOT READY)
- [ ] **Translations:** add `TranslationFile` to `features` in `app/app.json`, build to generate `Translations/Equipment Management.g.xlf`, and add an xlf per supported language.
- [ ] **Marketplace properties in `app/app.json`:** set `privacyStatement`, `EULA`, `help`, `url` and `logo` (needs real URLs and a logo file; publish `docs/help/FR-001-equipment-registration.md` somewhere linkable).
- [ ] `supportedLocales` and `applicationInsightsConnectionString` are missing.
- [ ] Review `resourceExposurePolicy` (debugging, source download and source in symbols are all `true`).
- [ ] The `description` in `app.json` mentions assigning to resources, which is not implemented. Reword it.
- [ ] Register the publisher affix `EQM` and a real object ID range with Microsoft. 50100-50149 is a demo range and blocks a real submission.
- [ ] Re-read Microsoft's current "Technical validation checklist - Business Central" (the skill copy is dated 2026-02-26).
- [ ] Run Run-AlValidation (Windows with Docker) or AL-Go for GitHub CI. Neither runs on macOS.
- [ ] Digital signature and the match with the Partner Center offer (release steps).
- [ ] Every release after 29.0.0.0 needs an upgrade codeunit.

## Tests (deferred by decision)
- [ ] Build the test app in `test/`: `test/app.json` needs the old `test` property removed and dependencies on Library Assert, Any and Tests-TestLibraries added (IDs from the symbols). Its dependency version on the main app should match the app's version.
- [ ] Implement the 57 scenarios in `docs/plans/FR-001-equipment-registration.md` (test codeunits 50150-50155). Answer the confirm dialogs with a `[ConfirmHandler]`.

## Housekeeping
- [ ] Nothing is committed yet. The repo has no commits.
- [ ] Without a UI session (API, job queue) both confirmations default to Yes. Revisit this if the tables are ever exposed through an API.
- [ ] Deleting an Employee with `RunTrigger = false` bypasses the delete guard. This is documented in the help.
