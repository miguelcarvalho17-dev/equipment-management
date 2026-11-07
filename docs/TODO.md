# TODO for next development sessions

Open items after FR-001 Equipment Registration (written 2026-11-02). Nothing from FR-001 has been compiled or tested yet.

## Verify FR-001 first
- [x] (done 2026-11-02, builds with no warnings) Run **AL: Package** on `app/` with CodeCop, UICop and AppSourceCop on. Fix every warning and error. The compiler could not run in the agent environment (alc needs .NET 10).
- [ ] Check that `app/.alpackages` still holds the BC 29 symbols (the validator reported it missing).
- [ ] Sandbox checks (also listed in `docs/features/FR-001-equipment-registration.md`):
  - [ ] Deleting an Employee from the Employee Card fires the implicit `OnBeforeDeleteEvent` guard: blocked when equipment references the employee, allowed otherwise.
  - [ ] A user with only D365 BASIC (and no EQM set) can delete an employee who has no equipment (indirect permission on EQM Equipment works).
  - [ ] (reversed by NFR-002, see SB8) Formerly: a user with only EQM - Read can open Equipment Setup in a fresh company. Now expected: EQM - Reader and EQM - Manager get the setup-missing error; EQM - Administrator creates the defaults.
  - [ ] Publish and republish into a fresh company: defaults appear once, no duplicates.
  - [ ] On a new card, the number-series button keeps the "No." until the page closes.
  - [ ] Setting Status to Assigned directly on an existing card fails on save (employee required); the Assign to Employee action is the intended path.
  - [ ] FR-005: on an Assigned card, choosing Available in Status fails at once with the "use the Return action" message and no confirmation; In Maintenance still works and closes the entry. Return (card and Employee Card > Return Equipment) closes the entry, keeps it, and the equipment can be assigned again.
  - [ ] Deleting from the non-editable Equipment List shows the confirmation.
  - [ ] FR-006: open a Closed entry on Equipment Assignments (no field editable). Rename equipment and an employee that have closed history: no error, and the entries show the new numbers (plan H12, risk R3).
  - [ ] FR-006: delete equipment with history from the card and from the list (Available, Disposed, Lost, In Maintenance): the history error appears and nothing is deleted. Assigned equipment gives the "return first" error. Never-assigned equipment is deleted.
  - [ ] FR-006: after build, `Equipment Management.g.xlf` contains the new labels and tooltip and no `ActiveAssignmentExistsErr`.
  - [ ] FR-007: code not yet compiled; run AL: Package, then check `Equipment Management.g.xlf` has the AboutTitle, AboutText, new captions and tooltips.
  - [ ] FR-007: teaching tip appears on first open of the Equipment list and `**Search**` renders bold.
  - [ ] FR-007: search box finds partial equipment and serial numbers; filter pane offers Category Code, Status, Assigned Employee No.
  - [ ] FR-007: Equipment Categories > Equipment and Employee Card > Assigned Equipment open the filtered list; Return Equipment lookup still works and shows the name column.

## NFR-002 sandbox checks (not run; automated tests deferred, Q7, test codeunit 50162 reserved)
- [ ] SB0 After publishing, EQM - READER / Equipment Reader, EQM - MANAGER / Equipment Manager and EQM - ADMINISTRATOR / Equipment Administrator exist and the old EQM - READ/EDIT/ADMIN are gone. **Assignments to the old set names must be redone** for every test user (old assignments are orphaned).
- [ ] SB1 Create three test users (not SUPER), each with D365 BASIC plus one EQM set, and a fourth with EQM - Reader only.
- [ ] SB2 Reader: list, card, history, categories, setup and dashboard open; nothing can be changed.
- [ ] SB3 Reader: Assign to Employee (pick an employee, then permission error, card unchanged) and Return (confirm, then permission error).
- [ ] SB4 Reader on list and card: New and Delete not offered or blocked; typing in a card field cannot be saved. Record what the client does.
- [ ] SB5 Manager: create, change, change status, assign, return; delete not offered or fails. Also confirm the number series is consumed for a non-SUPER Manager.
- [ ] SB6 Manager: Equipment Categories and Equipment Setup open read-only.
- [ ] SB7 Administrator: delete never-assigned equipment, maintain categories, change the setup.
- [ ] SB8 Company without setup: Reader and Manager opening Setup get the setup-missing error; the Administrator (not SUPER) creates EQUIP and the starter categories with no permission error.
- [ ] SB9 Reader without D365 BASIC: list, card, Assignments and history part open with blank employee names and no error.
- [ ] SB10 Reader on the Equipment Manager Role Center: tiles and charts work; New > Equipment fails on save with a permission error.
- [ ] SB11 D365 BASIC only: Employee Card actions Equipment Assignments / Assigned Equipment are hidden or fail (record which); deleting an employee with equipment shows the guard error.
- [ ] SB12 After the build, `Equipment Management.g.xlf` has the three new captions and the setup-missing label, and there are no CodeCop, UICop or AppSourceCop warnings.

## NFR-003 sandbox checks (not run; automated tests deferred, Q1, test codeunit 50163 reserved)
- [ ] UX-SB1 AL: Package on `app/` gives no errors or warnings (reported done by the user); `Equipment Management.g.xlf` contains the new captions, ToolTips, teaching tips and search terms.
- [ ] UX-SB2 Equipment List action bar: Equipment menu (Assignments), Report menu (Dashboard); Related shows Equipment > Assignments and Setup > Categories / Equipment Setup; Reports shows Dashboard. Ctrl+F7 opens the row's assignments. Record how promoted groups render; every action within two clicks.
- [ ] UX-SB3 Equipment Card: Process (Assign to Employee, Return), Equipment (Assignments), Ctrl+F7. Collapsed General shows Description and Category Code; collapsed Assignment shows Status and employee name.
- [ ] UX-SB4 List FactBox follows the selected row; on the card it updates after Assign to Employee and Return.
- [ ] UX-SB5 Add a note on a card: visible in the list FactBox for that row. Links hidden by default, can be shown through personalization.
- [ ] UX-SB6 Employee Card: Related > Equipment > Equipment Assignments (History icon) / Assigned Equipment; Assigned Equipment FactBox at the top of the pane, lists only current equipment; No. opens the card.
- [ ] UX-SB7 Tell Me: Equipment Assignments under History; "devices", "equipment types", "equipment number series", "equipment loans" find the right pages. Teaching tips appear on first open of Categories and Assignments.
- [ ] UX-SB8 Role Center: Embedding shows Equipment and Assignments only; Setup section keeps Equipment Setup and Equipment Categories.
- [ ] UX-SB9 **R1:** user with D365 BASIC only: Employee Card opens without error and without the Assigned Equipment FactBox. If the FactBox is visible and errors, report; fallback (needs approval) is to remove the part and keep the actions.
- [ ] UX-SB10 Reader without D365 BASIC: list and card FactBox open with blank employee details, no error.
- [ ] UX-SB11 Reader: list and card still read-only; Notes can be added (record result).
- [ ] UX-SB12 Return Equipment lookup from the Employee Card (list in lookup mode) still works with the FactBox pane.

## FR-011 sandbox checks (not run; automated tests deferred, Q8, test codeunit 50165 reserved)
- [ ] HS-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings (CodeCop and UICop reported clean; AppSourceCop not confirmed). `Equipment Management.g.xlf` contains the new captions, ToolTips, labels and AboutTexts.
- [ ] HS-SB2 Equipment Card shows the Maintenance History FastTab after Assignment History, newest first, posted entries only. Related > Equipment > Maintenance History opens page 50117 filtered.
- [ ] HS-SB3 Post from the maintenance card with F9 and with the action. After confirming, the record is read-only and an entry appears in page 50117. Return to the Equipment Card and record whether the part needs a refresh (R6).
- [ ] HS-SB4 Post from the list on the current row. The Open and Posted views work. History Entry opens the right entry.
- [ ] HS-SB5 A non-SUPER Manager can post (indirect insert works, no permission error). A non-SUPER Reader gets a permission error.
- [ ] HS-SB6 Pages 50116 and 50117 offer no New, Edit or Delete for any role, including Administrator.
- [ ] HS-SB7 Tell Me finds "Maintenance History" (also "posted maintenance", "maintenance costs") under History. Teaching tips show the new text.
- [ ] HS-SB8 Existing development records show as Open after publishing and can be posted.
- [ ] HS-SB9 **R2:** rename equipment that has history entries as a non-SUPER Manager and as an Administrator. Record whether the entries follow the new number and whether a permission error on table 50106 appears. If it fails, follow-up needs approval: block rename when maintenance exists, or remove the TableRelation on "Equipment No.".
- [ ] HS-SB10 Rename a vendor used in posted maintenance as a non-EQM user: no error, and the entries keep the old vendor number and name.
- [ ] HS-SB11 Posting user without Vendor read: posting works and Vendor Name on the entry is blank (R4).
- [ ] HS-SB12 An error during posting (for example a future date set by data) leaves no entry and the record stays Open.
- [ ] FR-011 follow-ups: update the personal-data classification item to include "Posted By", "Performed By" and "Vendor Name" (R5). Tests need `internalsVisibleTo` for the test app in app.json (H8).

## FR-012 sandbox checks (not run; automated tests deferred, Q9, test codeunit 50166 reserved)
- [ ] MS-SB0 After publishing, list equipment with open maintenance records from FR-010/FR-011 testing; post them or accept that they cannot be assigned until posted.
- [ ] MS-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` contains the new and changed texts.
- [ ] MS-SB2 Register maintenance for Available equipment from the Equipment Card: status becomes In Maintenance, Assign to Employee is disabled, the FactBox shows 1 open record.
- [ ] MS-SB3 Register maintenance for assigned equipment: one confirm; No cancels without a message and creates no record; Yes returns the equipment and closes the assignment. Note whether a series number was skipped after No. While the confirm is open, check that a second session registering on the same series or posting for the same equipment waits (accepted, option B).
- [ ] MS-SB4 Two open records: post one (still In Maintenance), post the other (Available). Check the post confirm text.
- [ ] MS-SB5 Status = Available by hand while a record is open: error. Disposed while open: allowed; then post the record, the status stays Disposed.
- [ ] MS-SB6 A non-SUPER Manager does all of the above without permission errors.
- [ ] MS-SB7 Reader: Register fails with a permission error; nothing changes.
- [ ] MS-SB8 Equipment List view In Maintenance and the dashboard tile include the equipment while maintenance is open.
- [ ] MS-SB9 Two sessions: register a record for E in session A and post the last other open record of E in session B; record whether B waits and the final status is In Maintenance. Also record how long B waits while A's confirm for assigned equipment is open.
- [ ] MS-SB10 Teaching tips of pages 50113 and 50114 show the new texts.

## FR-013 sandbox checks (not run; automated tests deferred, Q8, test codeunit 50167 reserved)
- [ ] CS-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings (source reported clean; manifest items remain); `.g.xlf` contains the new texts.
- [ ] CS-SB2 Equipment List: Total Maintenance Cost column visible; the hidden columns can be shown; "Filter totals by: Date Filter" changes the totals; filter pane on Total Maintenance Cost > 1000 works.
- [ ] CS-SB3 Equipment Card and List FactBox: Total, Average and Maintenance Cost % shown; 100 % or more is shown in the Unfavorable style; drill-down on Total opens the history.
- [ ] CS-SB4 Dashboard and Role Center: the Maintenance Costs tile group renders amounts readably (record the format), the two new charts show bars, clicking a category bar opens the Equipment list filtered on that category, clicking an equipment bar opens its maintenance history; Refresh updates all charts.
- [ ] CS-SB5 With no posted maintenance, the new charts are empty and no error appears.
- [ ] CS-SB6 Post a record and come back to the Role Center: the tiles update (RefreshOnActivate); the charts update after Refresh.
- [ ] CS-SB7 Non-SUPER Reader sees all of the above with no permission error.
- [ ] CS-SB8 Reproduce the issue example (Laptop A): 500 last year, 700 this year, purchase cost 1,200: Total 1,200 and 100 % in red.
- [ ] CS-SB9 Teaching tips of pages 50100 and 50109 show the new texts; Tell Me finds the dashboard with "maintenance cost".
- [ ] CS-SB10 Role Center Embedding shows Maintenance History and it opens page 50117.

## FR-014 sandbox checks (not run; automated tests deferred, Q8, test codeunit 50168 reserved)
- [ ] WS-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` contains the new captions, ToolTips, the error label with its comment, the group caption and the new card AboutText.
- [ ] WS-SB2 Publish over the existing development data: no schema sync error; existing equipment opens with blank warranty fields.
- [ ] WS-SB3 Equipment Card: the Warranty section appears after Purchase; when collapsed it shows Warranty End Date and Warranty Provider.
- [ ] WS-SB4 Enter an end date earlier than or equal to the start date: the error appears on the field, the text is readable and the dates are in the regional format.
- [ ] WS-SB5 Move an existing warranty to a later period: end date first, then start date: no error. Start date first, to a date after the old end date: error (R2); record whether the message is clear enough.
- [ ] WS-SB6 Equipment List: the four columns can be shown through personalization; filtering on Warranty End Date works.
- [ ] WS-SB7 Non-SUPER Reader sees the warranty fields and cannot change them; non-SUPER Manager can.
- [ ] WS-SB8 Teaching tip of the Equipment Card shows the new text.

## Open design and fix items
- [x] FR-007 known limitation (Employee read): addressed in code by NFR-002 (name blank without Employee read, `ReadPermission()` guard). Not verified in a sandbox (SB9).
- [ ] **New companies:** default data and number series are created only in `OnInstallAppPerCompany`. In a company created later the setup record is missing, and equipment creation fails on `TestField("Equipment Nos.")`. Create the defaults on company initialization (subscribe to the company-initialize event) or give the user path working permissions. NFR-002: the Administrator path now has indirect No. Series rights (ri), but defaults are still created only on install or when an Administrator opens Setup. Readers and Managers get the setup-missing error. Not verified (SB8).
- [x] **Setup permissions (Read too permissive):** addressed in code by NFR-002 (EQM - Reader has R only). Not verified in a sandbox (SB2, SB8).
- [ ] Decide whether "Assigned Employee No." should carry a personal-data classification.
- [ ] Setup defaults are created only when the setup record is missing. If the record exists but "Equipment Nos." is blank, nothing happens. Fix or document.
- [ ] Document attachments on equipment (needs al-event-finder first; NFR-003 Q9).
- [ ] Shared internal helper for the guarded employee full name, now repeated in five pages (NFR-003 R5).

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
