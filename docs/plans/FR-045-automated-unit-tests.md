# FR-045 Automated Unit Tests — Plan

> Request (verbatim): "FR-045 Automated Unit Tests. Check if some of them are already implemented or not"
> Status: **approved**

Target: AppSource

## Request
FR-045 (issue #86) asks for automated unit tests in five areas: Equipment Creation, Assignment Logic, Status Changes, Maintenance Processing and Warranty Calculation. It includes the example "Create Equipment, Assign Employee, Verify Status = Assigned". This plan first lists which existing tests already cover each area. It then plans only the missing tests, in the existing test app. Nothing in `app/` changes.

Tooling note: the AL MCP reported "No AL projects are loaded". Both `al_getnextobjectid` and `al_symbolsearch` failed, the same as in FR-038 to FR-044. The IDs below come from a scan of every `codeunit NNNNN` declaration in `test/src`, plus the reservations in `docs/plans` and `docs/TODO.md`. Symbols were checked against the app source and against existing test code that already compiles.

The note in the issue is out of date. The test app is built: `test/app.json` depends on the main app and on Library Assert, and has range 50150..50199. It contains 25 codeunits, and AL-Go CI runs them. No change to the test app setup is needed.

## Coverage inventory (existing [Test] procedures, by area)

| Area | Production logic | Already covered (file: tests) | Partially covered | Gaps (planned below) |
|---|---|---|---|---|
| Equipment Creation | table 50100 `OnInsert`, `CheckEquipmentConsistency`, `CheckCategoryAllowed`, `CheckSerialNoIsUnique`, `CheckWarrantyDates`, `CheckLastMaintenanceDate`, `CalcNextMaintenanceDate`, `OnDelete` | `EQMEquipmentAPITests` (50180): InsertGivesSeriesNumberAndAvailableStatus, InsertWith{Assigned,Disposed}StatusIsRejected, InsertWith{Lost,Assigned}StatusSetWithoutValidateIsRejected, InsertWith{Inactive,Unknown}Category*, InsertWithoutCategoryIsRejected, InsertWithUsedSerialNumber* (2), PatchKeepsOwnSerialNumber, InsertWithExplicitNumber* (2), DeleteRemovesEquipmentWithoutHistory. `EQMApplicationSetupTests` (50199): default maintenance frequency (5 tests). 50192, 50184, 50186: side effects of creation. 50 Note/DocAttachment/Picture tests: delete/rename side rules | Warranty date rule is tested only on the Validate path (PatchWarrantyEnd* in 50180), not on Insert | Missing "Equipment Nos." in setup; warranty dates checked on Insert; future Last Maintenance Date rejected; Next Maintenance Date calculated on insert; blank without frequency |
| Assignment Logic | table 50100 `AssignEmployee`, `UnassignEmployee`, `CheckAssignedEmployeeAllowed`, reassignment guard; codeunit 50106 "EQM Assignment Mgt." | 50180: AssignActionAssignsEquipmentToEmployee, AssignActionRejects{InactiveEmployee,LostEquipment,AlreadyAssignedEquipment}, ReturnAction* (3), PatchStatusAssignedWithoutEmployeeIsRejected, EmployeeCannotBeSetOnAvailableEquipment, DeleteIsRejectedFor{AssignmentHistory,AssignedEquipment}. `EQMAssignmentAPITests` (50182): 7 tests. 50192/50184/50186: assign/return side effects. 50194: AssignmentCountIncludesActiveAndClosedOfThisEquipmentOnly. 50189: AssignEquipment* (6) | Issue example: the assign test checks status, employee and one Active entry, but not Assignment Date or Assigned By, and equipment is not created in the same test. Return tests do not check Closing Date or Closed By. Reassign after return only as a count | Privacy-blocked employee; unknown employee; open maintenance blocks assign; direct change of employee on assigned equipment; the issue example end to end; history after return and reassign |
| Status Changes | table 50100 `Status.OnValidate`, `CheckStatusTransitionAllowed`, `IsFinalStatus` | 50180: PatchStatusDisposedIsApplied, PatchStatusDisposedDeclinedKeepsStatus, PatchDisposedEquipmentToAvailableIsRejected, PatchStatusLostClearsEmployeeAndClosesAssignment, PatchAssignedEquipmentToAvailableIsRejected. 50192: 3 tests. 50184: EquipmentReturnedRaisedWhenSetToLost. 50196: counts per status | Final status tested only for Disposed | Lost is final; open maintenance blocks leaving In Maintenance; In Maintenance back to Available without open records; manual In Maintenance on assigned equipment (Yes and No); disposal with open maintenance, and status after posting |
| Maintenance Processing | table 50105 "EQM Maintenance Record"; codeunit 50109 "EQM Maintenance-Post"; table 50100 `StartMaintenance`, `CompleteMaintenance`, `UpdateLastMaintenanceFromPosting`; codeunit 50108 | Side effects only: 50192 (4 tests), 50184 (2), 50186 (1), 50194, 50197, 50161 (cost and count reads) | Status In Maintenance / Available and record Posted appear only as side asserts | Almost every rule of 50105 and 50109 (see M1–M17) |
| Warranty Calculation | table 50100 `CalcWarrantyStatus`, `GetWarrantyDaysRemaining`, `GetWarrantyExpiringSoonDays`; codeunit 50110 "EQM Warranty Alert Mgt." | 50194: Summary warranty (4, via FactBox page, random dates). 50180: PatchWarrantyEnd* (3). 50161: 5 warranty-window tests. 50199: alert-days tests. 50184, 50187, 50186: events and alert run | Exact status boundaries and a 0D reference date are not tested on the procedure | `GetWarrantyDaysRemaining`; `FindDueInterval` boundaries; alert idempotency; Disposed and expired equipment skipped; stale alert cancelled on end-date change; Acknowledge positive and error |

Outside the five areas and not planned: NFR-005 maintenance log, FR-020 overdue maintenance, FR-018 jobs, FR-017 notifications (later phases).

## Definition of done
- [ ] Five new test codeunits in `test/src/`, with the IDs, names and tests below (52 [Test] procedures).
- [ ] The issue example is one test: create equipment, assign an employee, verify status Assigned, employee, one Active entry, Assignment Date = WorkDate(), Assigned By = UserId (A1).
- [ ] No test duplicates an existing one; overlapping tests add assertions the existing ones do not make ("extends").
- [ ] Every business rule has a positive and a negative test; negative tests assert the specific error text.
- [ ] Each test uses `[TransactionModel(TransactionModel::AutoRollback)]`, `TestPermissions = Disabled`, `[SCENARIO]/[GIVEN]/[WHEN]/[THEN]` comments, at most one `asserterror` as the last action.
- [ ] Data from Locked `Tok` labels with a prefix plus Counter, and `Random()`. No literal business numbers: thresholds come from app getters.
- [ ] No file under `app/` changes. Neither `app.json` changes.
- [ ] `test/` compiles with 0 errors and 0 warnings; `app/` still compiles.
- [ ] Reports say: "Not verified: tests not executed locally, CI result pending."
- [ ] Docs updated as in Step 7.

## Out of scope
- Any change in `app/`, including fixing behaviour found by a test (the developer reports it).
- Changes to `test/app.json`, analyzers or rulesets.
- Changes to the existing 25 test codeunits.
- Tests for NFR-005, FR-020, FR-018, FR-017, and TestPage UI tests.
- A shared test library codeunit.

## Objects
| Type | ID | Name | File |
|---|---|---|---|
| Codeunit (Test) | 50150 | EQM Equipment Creation Tests | `test/src/EQMEquipmentCreationTests.Codeunit.al` |
| Codeunit (Test) | 50156 | EQM Assignment Tests | `test/src/EQMAssignmentTests.Codeunit.al` |
| Codeunit (Test) | 50157 | EQM Status Change Tests | `test/src/EQMStatusChangeTests.Codeunit.al` |
| Codeunit (Test) | 50164 | EQM Maintenance Tests | `test/src/EQMMaintenanceTests.Codeunit.al` |
| Codeunit (Test) | 50168 | EQM Warranty Tests | `test/src/EQMWarrantyTests.Codeunit.al` |

ID basis: the scan shows 50161, 50162 and 50177–50199 in use. Free IDs are 50150–50160 and 50163–50176, all reserved in docs for deferred tests of earlier features. The chosen IDs reuse the reservation of the matching feature: 50150 (FR-001), 50156/50157 (FR-004/FR-005), 50164 (FR-010), 50168 (FR-014). No permission set entries, captions or translations are needed.

## Events and standard symbols
Library Assert (AreEqual, AreNotEqual, IsTrue, IsFalse, ExpectedError, ExpectedErrorCode, RecordCount, RecordIsEmpty) is used as in existing compiled tests. App symbols used (read from source): table 50100 `AssignEmployee(EmployeeNo)`, `UnassignEmployee(): Boolean`, `CalcWarrantyStatus(ReferenceDate)`, `GetWarrantyDaysRemaining(ReferenceDate)`, `GetWarrantyExpiringSoonDays()`, `CalcNextMaintenanceDate()`; codeunit 50108 `HasOpenMaintenance(EquipmentNo)`; codeunit 50109 run via `Codeunit.Run`; codeunit 50110 `GetIntervalDays`, `GetLongestIntervalDays`, `FindDueInterval`, `GenerateAlerts`, `AcknowledgeAlerts`. No events are subscribed or published.

## Steps
Conventions for every new codeunit (copy from `EQMEquipmentAPITests` and `EQMApplicationSetupTests`): namespace `MiguelCarvalho.EquipmentManagement.Tests`; `Subtype = Test; TestPermissions = Disabled;`; summary naming FR-045; global `Assert`, `Counter`, Locked Tok labels with prefix (`EQMCRT`, `EQMASG`, `EQMSTS`, `EQMMNT`, `EQMWTY`); local helpers `Initialize`, `NextId`, `CreateEquipment`, `InitMaintenance`, `FilterAssignments`, and a `[ConfirmHandler]` where confirms happen. `[HandlerFunctions('ConfirmHandler')]` only on tests where a confirm really happens (Lost/Disposed, leaving Assigned with an employee, maintenance on assigned equipment, UnassignEmployee). Error texts are copied as labels with the same Comment; date-dependent texts use Locked fragments.

1. `EQMEquipmentCreationTests` (50150): tests C1–C5.
2. `EQMAssignmentTests` (50156): tests A1–A7; employees E1, E2 active and E3 privacy blocked.
3. `EQMStatusChangeTests` (50157): tests S1–S7.
4. `EQMMaintenanceTests` (50164): tests M1–M17; post with `Codeunit.Run(Codeunit::"EQM Maintenance-Post", ...)`, never `PostWithConfirmation`.
5. `EQMWarrantyTests` (50168): tests W1–W16; Initialize sets "Default Warranty Alert Days" to the longest interval and clears feature setup.
6. Compile `test/` (and `app/` first). If the MCP has no project loaded, use the alc compiler directly as in earlier FRs. Fix every warning.
7. Docs: this plan; `docs/features/FR-045-automated-unit-tests.md`; `docs/help/FR-045-automated-unit-tests.md`; `CHANGELOG.md` section `## FR-045 Automated Unit Tests`; rewrite "Tests (deferred by decision)" in `docs/TODO.md` and add an FR-045 section; update feature docs naming now-used reserved IDs (FR-010, FR-014, others by grep); run `repo_checks.py`.

## Tests (all AutoRollback)

**50150 Equipment Creation**
- C1 No "Equipment Nos." in setup and blank "No." → Insert(true) errors with the field caption (negative).
- C2 Warranty end not after start, set directly → Insert rejected with "must be later than the warranty start date" (negative).
- C3 Future Last Maintenance Date → Insert rejected "is in the future" (negative).
- C4 New equipment gets Next Maintenance Date = last date + frequency (positive).
- C5 Without frequency, Next Maintenance Date stays blank (negative).

**50156 Assignment**
- A1 Issue example: create equipment, assign E1, verify Status Assigned, employee, one Active entry, Assignment Date = WorkDate(), Assigned By = UserId, Closing Date blank (positive; extends 50180).
- A2 Privacy-blocked employee cannot be assigned (negative).
- A3 Unknown employee cannot be assigned (negative).
- A4 Equipment with open maintenance cannot be assigned (negative).
- A5 Return closes the entry with Closing Date and Closed By (positive; extends 50180).
- A6 Reassign after return keeps history: one Closed (E1), one Active (E2) (positive).
- A7 Employee of assigned equipment cannot be changed directly (negative).

**50157 Status Change**
- S1 Open maintenance blocks In Maintenance → Available (negative).
- S2 Without open maintenance, In Maintenance → Available works (positive).
- S3 Manual In Maintenance on assigned equipment removes employee and closes assignment (positive, confirm Yes).
- S4 Declining that confirmation stops the change (negative, confirm No).
- S5 Lost is final (negative).
- S6 Open maintenance does not block disposal (positive).
- S7 Posting the last open record of disposed equipment keeps it Disposed (negative).

**50164 Maintenance**
- M1 Registering sets equipment In Maintenance, record Open (positive).
- M2 Lost equipment cannot get maintenance (negative).
- M3 Unknown equipment rejected (negative).
- M4 Future maintenance date rejected (negative).
- M5 Negative cost rejected (negative).
- M6 Registering on assigned equipment returns it (positive, confirm Yes).
- M7 Declining that confirmation registers nothing (negative).
- M8 Posting writes the history entry (equipment, cost, type, Posted By) and makes equipment Available (positive).
- M9 Posting one of two open records keeps equipment In Maintenance (negative).
- M10 A posted record cannot be posted again (negative).
- M11 A posted record is read-only (negative).
- M12 A maintenance record cannot be deleted (negative).
- M13 Equipment of a saved record cannot change (negative).
- M14 Preventive posting moves Last and Next maintenance dates (positive).
- M15 Corrective posting does not move planned dates (negative).
- M16 An older preventive date does not move the last date back (negative).
- M17 Equipment with maintenance records cannot be deleted (negative).

**50168 Warranty** (R = Today() + Random(365); Window = GetWarrantyExpiringSoonDays())
- W1 End = R → Expiring Soon. W2 End = R + Window → Expiring Soon. W3 End = R + Window + 1 → Active. W4 End = R − 1 → Expired.
- W5 Reference 0D means today.
- W6 Days remaining = N. W7 After end date = −N. W8 No end date = 0.
- W9 Due interval is the most urgent one (30/60/90). W10 No interval due outside the range.
- W11 Second alert run creates no duplicate. W12 Disposed equipment gets no alert. W13 Expired warranty gets no alert.
- W14 Changing end date cancels the open alert and creates a new one.
- W15 Acknowledge records status, user and time. W16 Acknowledge with nothing open is rejected.

Existing tests likely affected: none. CI run time grows by about 52 tests.

## Assumptions
- The five areas map to the logic in the inventory; FR-019 planned-date updates on posting count as Maintenance Processing; FR-020 overdue monitoring does not.
- Built-in `Random()`, Locked Tok labels and Counter count as "no hardcoded data". Adding Library Random would change `test/app.json` (stop list).
- A fresh CI company may lack Equipment Setup; Initialize gets or inserts it, and all records use test-prefixed explicit numbers.
- Assigning an unknown employee fails with the platform table-relation error or EmployeeNotFoundErr; A3 asserts the employee number, which both contain.
- `Assert.ExpectedError` is a contains check, as existing tests rely on.

## DECISIONS
- FR-045 test IDs | Reuse reserved but never-built IDs 50150, 50156, 50157, 50164, 50168 over widening `test/app.json` idRanges (stop list). MCP ID tool was unavailable, so IDs come from a source scan | Reversible: yes
- FR-045 structure | One new test codeunit per area (5) over adding to existing codeunits such as 50180 | Reversible: yes
- FR-045 helpers | Local helpers per codeunit (existing convention) over a shared library codeunit | Reversible: yes
- FR-045 scope | NFR-005, FR-020, FR-018, FR-017 out of phase 1 | Reversible: yes
- FR-045 issue example | Dedicated end-to-end test A1 over relying on 50180 | Reversible: yes

## Risks
- The MCP could not verify symbols or allocate IDs; symbols were read from source. The reviewer rechecks IDs against `test/src`.
- Unused-handler failures: every `[HandlerFunctions('ConfirmHandler')]` test must really raise a confirm.
- Date-format sensitivity: Locked English fragments, as in 50180.
- WorkDate in CI may differ from Today(); A1, A5, A6 assert against WorkDate().
- `GenerateAlerts` scans all open alerts; assertions filter on the test's own equipment, except CreatedCount in W11.
- CI result unknown until push. A failing test may reveal an app defect; changing `app/` is outside this plan.
- Later phases: 2 NFR-005 log tests; 3 FR-020/FR-021 monitoring tests; 4 TestPage tests for card actions.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-test-codeunits-and-test-methods
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-handlerfunctions-attribute
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-confirmhandler-attribute
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-application

## Deviations and review notes (recorded at Step 7)
- Reviewer APPROVED. Tests: 52 in 5 codeunits (50150: 5, 50156: 7, 50157: 7, 50164: 17, 50168: 16). Written and compiled with alc, because the AL MCP had no project loaded. NOT executed locally. CI result pending.
- M2 and W12 set Lost or Disposed with a direct Status assignment and `Modify(false)`.
- M13 uses direct assignment with `Modify(true)`.
- W1 to W4 use `Today()` as the reference date.
- W1 to W8 use in-memory equipment records.
- Open MINOR: W1 to W4 reference date (`Today()`, while A1, A5 and A6 use WorkDate()).
- Open MINOR: Employee First Name literals in 3 test files.
- Open MINOR: A3 cannot distinguish the two error sources (table relation error and EmployeeNotFoundErr). It asserts the employee number only.
- Pre-existing, not part of FR-045: 5 AA0073 warnings in `test/src/EQMDashboardTests.Codeunit.al`. Follow-up chore.
- No separate AppSource validation ran. `app/` and `app.json` are unchanged.
