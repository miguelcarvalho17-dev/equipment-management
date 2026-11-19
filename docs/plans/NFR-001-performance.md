# NFR-001 Performance — Plan

> Request (verbatim): NFR-001 Performance
> Status: **approved**

Issue #22: The system shall remain responsive with large datasets. The Equipment list must open in less than 3 seconds for datasets up to 10,000 records. Dashboard calculations should be optimized using FlowFields or Queries. FR-053 (#94, 100k+ records) is out of scope.

## Request
Make sure the Equipment list and the dashboard stay responsive with 10,000 equipment records, using only small additive changes. The audit below shows that the dashboard already uses FlowFields and Queries, but the filters behind them (and behind the list views and drill-downs) have no supporting index on table 50100. The list page also reads the Employee table once for every row it shows. Phase 1 adds three secondary keys to table 50100, caches the employee names on the list page, and adds a 10,000-record test codeunit.
Target: AppSource

### Audit (what exists today, verified by reading the source)
- **Equipment list, page 50100** (`app/src/Equipment/EQMEquipmentList.Page.al`). Editable list on table 50100, sorted by the PK. The platform reads rows in batches and loads only the fields on the page, so the work per row is bounded by the visible rows, not by the 10,000 records. Work per row in `OnAfterGetRecord`:
  - `Employee.Get` for every assigned row (lines 316-321). This is N+1 on the visible rows, and the same employee is read again for each of their equipment. **Fixed in phase 1 (cache).**
  - `Rec.GetMaintenanceCostPercentage()` runs `CalcFields("Total Maintenance Cost")` when Purchase Cost <> 0. This is a SIFT lookup on History key `EquipmentDate` (SumIndexFields Cost, already exists), so it is cheap. Left as is (see Out of scope).
  - Views Available/Assigned/In Maintenance/Lost/Disposed filter on `Status`. Table 50100 has **no key on Status**, so every view and every status drill-down is a clustered scan. **Fixed (key).**
  - FlowFields 14/15/16 (cost, count, average) are backed by SIFT key `EquipmentDate` on table 50106. OK.
- **Dashboard** (page 50109 → cue part 50106 on temporary table 50104, plus 4 chart parts):
  - Every tile is already a FlowField (count/sum/average). The charts already use Queries 50100-50103 through `EQM Dashboard Mgt.` (50107). **The issue's "FlowFields or Queries" requirement is already met; no AL loop calculates a dashboard figure.**
  - The filters behind the FlowFields have no index on table 50100: `Status` (fields 10-16, 30-35, 50, 52), `"Warranty End Date"` + Status (30, 31, 33, 34, 35), `"Next Maintenance Date"` + Status (50, 52). `Total Assets Value` (16) sums `"Purchase Cost"` with a Status filter. Query 50101 groups by Status. **Fixed (keys).**
  - Tiles on other tables are already indexed: Maintenance Record `StatusDate` (Status, Maintenance Date), Warranty Alert `Status`, Equipment Request `StatusDate`, History `EquipmentDate` SIFT (Cost).
  - Page 50106 `OnAfterGetRecord` runs `CalcFields("Overdue Maintenance Equipment")` once per page open. Negligible; left as is.
- **Other readers that also benefit** (code unchanged): `EQM Warranty Alert Mgt.` (50110) `GenerateAlerts` and `RaiseWarrantyExpiredEvents` (range on Warranty End Date), `EQM Dashboard Mgt.`.`CalcAssetUtilization` (Count per Status, report 50101), `EQM Dashboard Mgt.`.`ShowEquipmentByStatus`, `EQM Request Approval Mgt.` line 154 (SetRange Status Available).

## Definition of done
- [ ] Table 50100 "EQM Equipment" has three new secondary keys: `Status` (with IncludedFields "Purchase Cost"), `WarrantyEndDate` ("Warranty End Date", Status) and `NextMaintenanceDate` ("Next Maintenance Date", Status). No existing key, field, property or procedure is changed.
- [ ] Page 50100 shows the same Assigned Employee Name as before: full name when the employee exists, blank when there is no employee, the employee does not exist, or the user has no read permission on Employee. Each employee is read at most once per page session.
- [ ] No new captions, labels, ToolTips, permissions, app objects, upgrade code or app.json changes.
- [ ] `app/` compiles with CodeCop, UICop and AppSourceCop and no new warnings. `test/` compiles.
- [ ] New test codeunit 50159 "EQM Performance Tests" compiles, with the scenarios below, including the 10,000-record dataset tests and the 3-second budget assertions.
- [ ] CI (AL-Go `Pull Request Build`) shows 50159 passing. Until a push: "Not verified: tests not executed locally, CI result pending".
- [ ] Docs: `docs/features/NFR-001-performance.md`, `docs/help/NFR-001-performance.md` and a CHANGELOG section `## NFR-001 Performance (version stays 29.0.0.0, no bump)` exist (repo_checks requires them on `feature/NFR-001-*`).

## Out of scope
- FR-053 (100k+ records), Performance Toolkit (BCPT) app, telemetry. BCPT would be a new app and would need `.AL-Go` settings changes.
- `GetMaintenanceCostPercentage` CalcFields per row on the list. Passing the page-calculated value instead would show a wrong % when a user hides "Total Maintenance Cost" while the "Calculate only visible FlowFields" feature is on. The SIFT lookup is already cheap.
- The `Equipment.Get` per open alert in `CancelStaleAlerts` (a job, not a UI path), and FactBox per-record counts (one record at a time, already indexed).
- SIFT (SumIndexFields) on the new keys (see DECISIONS).
- Any change to the cue page, the queries, the charts or `EQM Dashboard Mgt.`.
- Changes to existing tests.

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Table | 50100 | EQM Equipment | Changed (3 keys added) | app/src/Equipment/EQMEquipment.Table.al |
| Page | 50100 | EQM Equipment List | Changed (employee-name cache) | app/src/Equipment/EQMEquipmentList.Page.al |
| Codeunit (test) | 50159 | EQM Performance Tests | New | test/src/EQMPerformanceTests.Codeunit.al |
| Doc | — | Feature doc / help / changelog | New / Changed | docs/features/NFR-001-performance.md, docs/help/NFR-001-performance.md, CHANGELOG.md |

There are no new app objects, so there are no permission-set entries. There is no new text, so there are no XLIFF entries. Test-app ID 50159 is the unbuilt FR-007 reservation "EQM Equipment List Tests" (FR-007 plan line 84, feature doc line 50). It is not used by any object in `test/src`. Free test IDs found by a source scan: 50151-50155, 50159, 50160, 50163, 50165-50167, 50169-50176 (all are unbuilt reservations of earlier plans).

## Events and standard symbols
| Symbol | Exact signature | Verified with al_symbolsearch |
|---|---|---|
| Table Employee (`Microsoft.HumanResources.Employee`) | fields "No.", "First Name", "Middle Name", "Last Name" | **No.** MCP returned "No projects are loaded". The fields are already used in the same file (EQMEquipmentList.Page.al:318), which compiles today |
| Employee.FullName | `procedure FullName(): Text[100]` (return length per existing usage; assign with CopyStr) | **No.** Already used at EQMEquipmentList.Page.al:320 |
| Record.ReadPermission / SetLoadFields / Get | platform methods | **No.** Already used at EQMEquipmentList.Page.al:317-319 |
| Codeunit "Library Assert" (`System.TestLibraries.Utilities`) | `AreEqual(Expected: Variant; Actual: Variant; Msg: Text)`, `IsTrue(Condition: Boolean; Msg: Text)` | **No.** Used in 28 test codeunits, e.g. test/src/EQMDashboardTests.Codeunit.al |
| TestPage methods | `OpenView()`, `First(): Boolean`, `Next(): Boolean`, `GoToRecord(Rec)`, `Filter.SetFilter(Field, Text)`, control `.Value`, `.AsInteger()`, `.AsDecimal()`, `Close()` | **No.** Used in test/src/EQMEquipmentRequestTests.Codeunit.al:868-873, EQMDashboardTests.Codeunit.al:286-292, EQMFeatureMgtTests.Codeunit.al:247-248 |
| App: `EQM Notification Mgt.`.`DisableNotification(Notification)`, `GetWarrantyNotificationId(): Guid`, `GetOverdueMaintenanceNotificationId(): Guid` | as in app/src/Notifications/EQMNotificationMgt.Codeunit.al:48-66, 318 | Read in source |
| App: `EQM Dashboard Mgt.`.`SetWarrantyCueFilters(var EquipmentCue; ReferenceDate: Date)`, `SetPlannedMaintenanceCueFilters(...)`, `GetEquipmentCountByStatus(var StatusOrdinals: List of [Integer]; var EquipmentCounts: List of [Integer])` | as in app/src/Dashboard/EQMDashboardMgt.Codeunit.al:42, 109, 135 | Read in source |

No events are subscribed or published.

## Steps
1. **app/src/Equipment/EQMEquipment.Table.al**: in `keys`, after `key(AssignedEmployee; "Assigned Employee No.", Status) { }` (line 266-268), add exactly:
   ```
   key(Status; Status)
   {
       IncludedFields = "Purchase Cost";
   }
   key(WarrantyEndDate; "Warranty End Date", Status)
   {
   }
   key(NextMaintenanceDate; "Next Maintenance Date", Status)
   {
   }
   ```
   Why: these back the Status views and status drill-downs, cue FlowFields 10-16/30-35/50/52, query 50101 and the warranty job ranges. The key name `Status` equal to a field name has a precedent that compiles: `key(Status; Status, "Warranty End Date")` in app/src/Warranty/EQMWarrantyAlert.Table.al:102. Do not add SumIndexFields, MaintainSiftIndex, Unique or Clustered. Do not touch the existing keys (AS0009/AS0010/AS0038). IncludedFields needs runtime 8.0 and the app is on runtime 18.0. Compile `app/`.
2. **app/src/Equipment/EQMEquipmentList.Page.al**: replace the employee lookup with a page-session cache.
   - In `var` add `EmployeeNames: Dictionary of [Code[20], Text];` and `CanReadEmployees: Boolean;`.
   - In `OnOpenPage` add a local `Employee: Record Employee;` and the line `CanReadEmployees := Employee.ReadPermission();` after the two existing lines.
   - In `OnAfterGetRecord` remove the local `Employee` variable and replace lines 316-321 (`AssignedEmployeeName := '';` … `end;`) with `AssignedEmployeeName := GetAssignedEmployeeName(Rec."Assigned Employee No.");`.
   - Add the local procedure:
     ```
     local procedure GetAssignedEmployeeName(EmployeeNo: Code[20]): Text[100]
     var
         Employee: Record Employee;
         EmployeeName: Text;
     begin
         if (EmployeeNo = '') or not CanReadEmployees then
             exit('');
         if EmployeeNames.Get(EmployeeNo, EmployeeName) then
             exit(CopyStr(EmployeeName, 1, MaxStrLen(AssignedEmployeeName)));
         Employee.SetLoadFields("First Name", "Middle Name", "Last Name");
         if Employee.Get(EmployeeNo) then
             EmployeeName := Employee.FullName();
         EmployeeNames.Add(EmployeeNo, EmployeeName);
         exit(CopyStr(EmployeeName, 1, MaxStrLen(AssignedEmployeeName)));
     end;
     ```
   Why: one Employee read per distinct employee instead of one per visible row. A missing employee is cached as blank, which keeps today's behaviour. Keep the `using Microsoft.HumanResources.Employee;`. Do not change any control, caption, ToolTip or `AboutText`. Compile `app/`.
3. **test/src/EQMPerformanceTests.Codeunit.al** (new): `codeunit 50159 "EQM Performance Tests"`, namespace `MiguelCarvalho.EquipmentManagement.Tests`, `using MiguelCarvalho.EquipmentManagement; using Microsoft.HumanResources.Employee; using System.TestLibraries.Utilities;`, `Subtype = Test; TestPermissions = Disabled;`. Every test has `[Test]` and `[TransactionModel(TransactionModel::AutoRollback)]`.
   - Globals: `Assert: Codeunit "Library Assert"`, `Counter: Integer`, Locked Tok labels `CategoryCodeTok 'PERFCAT'`, `EquipmentNoTok 'PERF%1'`, `EmployeeNoTok 'PERFEMP%1'`, and Locked labels for first/last name (`'Perf'`, `'Tester%1'`). Message labels with Comment for each placeholder, e.g. `ListTooSlowMsg: Label 'The equipment list took %1 ms; the budget is %2 ms.', Comment = '%1 = elapsed ms, %2 = budget ms'`. These are test assertion texts and do not go in the app XLIFF.
   - Helpers (local, following the FR-045 "local helpers per codeunit" decision):
     - `GetDatasetSize(): Integer` returns 10000, with the comment "NFR-001 dataset size".
     - `GetResponseBudgetMs(): Integer` returns 3000, with the comment "NFR-001: list must open in less than 3 seconds".
     - `EnsureCategory()`: Init/Insert-or-Modify of category `CategoryCodeTok`, Active = true, as in EQMDashboardTests:344-348.
     - `CreateEmployee(var Employee)`: No. from `EmployeeNoTok` + Counter, names from labels with Counter, `Insert(false)` (pattern EQMEquipmentFactBoxTests:402-409).
     - `InsertEquipment(NewStatus; EmployeeNo; PurchaseCost; WarrantyEndDate; NextMaintenanceDate)`: Counter += 1, Init, "No." := CopyStr(StrSubstNo(EquipmentNoTok, Counter)…), Description, "Category Code", Status, "Assigned Employee No." (only when NewStatus = Assigned), cost and dates set directly, then `Insert(false)`. The comment explains that triggers are bypassed on purpose to build volume fast, as the existing tests do with Modify(false).
     - `CreateDataset(NoOfRecords; EmployeeNo; var CountByStatus: Dictionary of [Integer, Integer]; var NonFinalPurchaseCost: Decimal)`: loop 1..NoOfRecords. The status cycles through Available, Assigned, In Maintenance, Lost, Disposed by `Index mod 5`. PurchaseCost := Random(100000) / 100. WarrantyEndDate := Today() - 200 + Random(400). NextMaintenanceDate := Today() - 100 + Random(200). The loop accumulates the per-status counts and the purchase cost of the non-final statuses. Nothing is hardcoded.
     - `GetCue(var EquipmentCue)`: Init, Insert, then `DashboardMgt.SetWarrantyCueFilters(EquipmentCue, Today())` and `SetPlannedMaintenanceCueFilters(EquipmentCue, Today())` (pattern EQMDashboardTests:295-302).
     - `DisableRoleCenterNotifications()`: copied from EQMDashboardTests:397-407.
     - `ElapsedMs(StartTime: DateTime): Integer` returns `CurrentDateTime() - StartTime` as an integer.
   - Tests: as listed under Tests (P1-P8). Compile `test/`. If the AL MCP still has no project loaded, compile with the extension's alc as in FR-041 to FR-046 (DECISIONS lines 63, 75, 87, 96, 108), `app/` first. Copy the new app symbols into `test/.alpackages` (gitignored).
4. **Docs (docs agent)**: `docs/features/NFR-001-performance.md` (audit, keys, cache, test results or "CI pending"). `docs/help/NFR-001-performance.md` (no UI change; tip: an admin can switch on **Calculate only visible FlowFields** in Feature Management, a platform feature from v26, link below). CHANGELOG section `## NFR-001 Performance (version stays 29.0.0.0, no bump)`.

## Tests
All in codeunit 50159. Every test captures baselines first, so existing data never matters.

- **P1** [SCENARIO] The Equipment list opens within the 3-second budget with 10,000 records. [GIVEN] Category, employee E, and the dataset of GetDatasetSize() records (CreateDataset). [WHEN] StartTime := CurrentDateTime(); `EquipmentList.OpenView(); EquipmentList.First();` then up to 50 `Next()` calls, reading `"Assigned Employee Name".Value` and `Status.Value` on each row (forces OnAfterGetRecord). [THEN] `Assert.IsTrue(ElapsedMs(StartTime) < GetResponseBudgetMs(), StrSubstNo(ListTooSlowMsg, …))`.
- **P2** [SCENARIO] A status view on 10,000 records opens within budget and shows only that status. [GIVEN] The same dataset. [WHEN] Timed: `OpenView(); Filter.SetFilter(Status, Format(Equipment.Status::"In Maintenance")); First();`. [THEN] Elapsed < budget, and the first row's Status value equals Format("In Maintenance").
- **P3** [SCENARIO] Dashboard tiles are correct on 10,000 records. [GIVEN] Baselines of cue fields Total Equipment, Available Equipment, Assigned Equipment, Equipment in Maintenance, Lost Equipment, Disposed Equipment and Total Assets Value (CalcFields on GetCue), then the dataset. [WHEN] CalcFields of the same fields on a fresh cue. [THEN] Each equals baseline + CountByStatus[ordinal] (Total = baseline + dataset size). Total Assets Value = baseline + NonFinalPurchaseCost.
- **P4** [SCENARIO] The dashboard cue page opens within budget on 10,000 records. [GIVEN] DisableRoleCenterNotifications() and the dataset. [WHEN] Timed: `CuesPage.OpenView()` then read `"Total Equipment".AsInteger()`, `"Total Assets Value".AsDecimal()`, `"Warranty Expiring Soon".AsInteger()`, `"Overdue Maintenance Equipment".AsInteger()`. [THEN] Elapsed < budget, and "Total Equipment" = baseline + dataset size.
- **P5** [SCENARIO] The status chart query returns the right counts on 10,000 records. [GIVEN] Baseline from `DashboardMgt.GetEquipmentCountByStatus`, then the dataset. [WHEN] It is called again. [THEN] For each ordinal in the list, count = baseline + CountByStatus (0 when absent).
- **P6** (negative) [SCENARIO] Lost and disposed equipment is not counted in Total Assets Value, the warranty tiles or the overdue tile, even with indexed filters. [GIVEN] Baselines of Total Assets Value, Warranty Expiring Soon, Active Warranties, Overdue Maintenance Equipment, Lost Equipment and Disposed Equipment. Then N := Random(5) Lost and N Disposed equipment with PurchaseCost > 0, Warranty End Date = Today() + 1 and Next Maintenance Date = Today() - 1. [WHEN] The cue is calculated. [THEN] The first four are unchanged. Lost and Disposed each = baseline + N (positive anchor).
- **P7** [SCENARIO] The list shows the employee's full name on every row of the same employee (cache hit). [GIVEN] Employee E and two equipment records assigned to E. [WHEN] The list is opened and `GoToRecord` is called on each. [THEN] Both rows show `E.FullName()` in "Assigned Employee Name".
- **P8** (negative) [SCENARIO] The list shows a blank name when there is no employee or the employee does not exist. [GIVEN] One Available equipment without employee, and one Assigned equipment whose "Assigned Employee No." is a code with no Employee record (`StrSubstNo(EmployeeNoTok, Counter)` not inserted). [WHEN] The list is opened on each. [THEN] "Assigned Employee Name" is blank on both.

There are no UI dialogs in these paths, so no handlers are needed. P4 relies on DisableRoleCenterNotifications, as in EQMDashboardTests.
Existing tests to re-run (no change expected): 50198 EQM Feature Mgt. Tests (scenarios 11/11b open page 50100 and 12 opens 50106), 50178 EQM Equipment Picture Tests (list page), 50189 EQM Request Approval Tests (lookup on page 50100), 50161 EQM Dashboard Tests, 50196 EQM Asset Utilization Tests, 50168 EQM Warranty Tests (key-backed filters), 50162 EQM Role Permission Tests (no new app objects, so no change).

## Assumptions
- The 3-second target means the server-side page open time measured through TestPage. Web-client rendering cannot be measured in the test app or locally. The CI result is the evidence, and a sandbox check with 10,000 records stays a manual item.
- 10,000 records with `Insert(false)` stand for the dataset. Triggers are bypassed only to build volume; existing tests already set fields with Modify(false).
- No SIFT is needed at 10,000 rows. A covering nonclustered index makes COUNT/SUM a narrow index scan or seek, which is cheap at this size. SIFT is a FR-053 (100k+) question.
- A stale employee name is acceptable until the page is reopened. The list is read-only and names change rarely.
- The dashboard requirement is already satisfied (FlowFields and Queries exist since FR-009/FR-021/FR-022/FR-038). Phase 1 only adds index support.

## Decisions
- Three plain secondary keys on table 50100 (Status with IncludedFields "Purchase Cost"; "Warranty End Date", Status; "Next Maintenance Date", Status) over SIFT keys, because a SIFT indexed view on the low-cardinality Status (5 buckets) makes every equipment insert or status change contend on the same view rows, and plain covering indexes are enough at 10,000 rows. Reversible: no (published keys can only be obsoleted).
- Page-session Dictionary cache for Assigned Employee Name over a new FlowField on table 50100, consistent with FR-037/FR-039 (do not widen the published table), and because FullName cannot be a FlowField. Reversible: yes.
- Leave GetMaintenanceCostPercentage's per-row CalcFields over reusing the page-calculated FlowField value, because the value is not calculated when the column is hidden and "Calculate only visible FlowFields" is on. Reversible: yes.
- No new dashboard Query or FlowField, because the audit found no AL loop in any dashboard figure; only index support was missing. Reversible: yes.
- Test codeunit ID 50159 (unbuilt FR-007 reservation) over widening test/app.json (stop list); the ID came from a source scan because the AL MCP had no project loaded. Reversible: yes.
- In-test timing assertions at the 3,000 ms requirement over a Performance Toolkit (BCPT) app, because BCPT would need a new app and AL-Go settings changes; BCPT is phase 2. Reversible: yes.

## Risks
- **AL MCP unavailable**: `al_symbolsearch` and `al_getnextobjectid` both returned "No projects are loaded". The standard symbols are confirmed only by existing compiled usage in this repo, and the test ID by a source scan. The reviewer should confirm the build, and should confirm with `al_getnextobjectid` if the MCP gets a project loaded.
- **Timing tests can be flaky in CI** (cold container, shared agent). P1, P2 and P4 are separate methods so a failure is isolated. If one fails, re-run once. If it fails again, report it and do not raise the budget silently: that would mean NFR-001 is not met, or that BCPT is needed (phase 2).
- **CI duration**: P1-P5 each insert 10,000 rows under AutoRollback, about 50k inserts in total, which may add a few minutes to the PR build. If it is too slow, merge P3 and P5 and record the change.
- **Schema sync**: adding keys creates three indexes on existing tenants at upgrade. This is additive, needs no upgrade code and does not change data. AppSourceCop allows additive keys (AS0133 is hidden by default). The reviewer should confirm that the AppSourceCop baseline check shows no AS0009/AS0010/AS0038/AS0042.
- **Write cost**: three more nonclustered indexes on table 50100 make each insert or modify slightly slower. Negligible for master data.
- **CodeCop AA0232 (Info)** may be reported on cue field 16 "Total Assets Value" (a sum FlowField without SIFT). It is Info severity, not a warning, and the choice is deliberate. The developer must not switch to SumIndexFields without a re-plan.
- **Cache staleness**: an employee renamed while the list is open keeps the old name until the list is reopened. Mention in the help article.
- **repo_checks**: `.g.xlf` will not change because there is no new text, so repo_checks raises a translation warning (warning only). Feature doc, help and CHANGELOG `## NFR-001` must exist on this branch, or repo_checks fails.
- **Key name `Status`** equals a field name. A precedent in table 50107 compiles. If the compiler objects anyway, rename the new key to `StatusKey` (the key is new, so the rename is safe before release).

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-flowfields#when-are-flowfields-calculated
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/calculate-only-visible-flowfields-feature-key
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-sift-performance
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-sift-and-sql-server
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-includedfields-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-table-keys
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0133
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0010
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/codecop-aa0232

## Later phases
- Phase 2: Performance Toolkit (BCPT) scenarios for list open and dashboard refresh (needs a new app, so it needs the user's yes).
- Phase 3 (FR-053): SIFT or columnstore evaluation for 100k+ records, and `CancelStaleAlerts` N+1 in the warranty job.

No separate AppSource validation ran.
