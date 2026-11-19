# FR-053 Large Dataset Support — Plan

> Request (verbatim): FR-053 Large Dataset Support
> Status: **approved**

Issue #94: The application shall support environments containing 100,000+ Equipment Records and 1,000,000+ Assignment Records. Requirements: optimized keys, optimized filtering, FlowField optimization, Query objects where applicable. Related: NFR-001 Performance (#22) sets the current target of 10,000 records.

Target: AppSource

## Request

Make the app hold up in companies with 100,000+ equipment records and 1,000,000+ assignment records, changing as little as possible. Phase 1 has four parts:
- add three secondary keys (two on Equipment, one on Equipment Assignment);
- cache employee names on the 1M-row Equipment Assignments list;
- replace the N+1 read loop in the warranty job's stale-alert cancellation (deferred to FR-053 by NFR-001) with one new Query;
- extend the existing performance test codeunit.

## Audit

- **Table 50103 "EQM Equipment Assignment"** (1M rows). Keys: PK "Entry No." (clustered), EquipmentStatus ("Equipment No.", Status), EmployeeStatus ("Employee No.", Status).
  - Readers filtering by equipment or employee already have an index: `EQM Assignment Mgt.` (50106), FactBoxes 50111 and 50138, part 50105, page 50104 opened from the Employee card.
  - Page 50104 is unfiltered and sorted by "Entry No." descending, so it reads the clustered index backward. Fine. Active entries sit near the tail. No Status key is added.
  - **Gap 1:** page 50104 `OnAfterGetRecord` runs `Employee.Get` per row (N+1). Fixed with a cache.
  - **Gap 2:** API page 50125 exposes `lastModifiedDateTime = SystemModifiedAt`; delta reads have no index. Fixed with a key.
- **Table 50100 "EQM Equipment"** (100k rows). NFR-001 already added Status, ("Warranty End Date", Status), ("Next Maintenance Date", Status).
  - **Gap 3:** filters on "Category Code" + Status have no covering index (`EQM Request Approval Mgt.`.`AssignEquipmentWithLookup`, `EQM Dashboard Mgt.`.`CalcAssetUtilization`). Fixed with a key.
  - **Gap 4:** API page 50123 delta reads on `SystemModifiedAt` have no index. Fixed with a key.
- **FlowFields:** each is already backed by an index or SIFT key. No change. The NFR-001 decision against SIFT on low-cardinality Status holds at this size.
- **Queries:** dashboard charts already use Queries 50100-50103.
  - **Gap 5:** `EQM Warranty Alert Mgt.`.`CancelStaleAlerts` runs `Equipment.Get` per open alert inside the `LockTable()` transaction of `GenerateAlerts`. Fixed with Query 50104.

## Definition of done

- [ ] Table 50100 has secondary keys `CategoryStatus` ("Category Code", Status) and `SystemModified` (SystemModifiedAt). Table 50103 has secondary key `SystemModified` (SystemModifiedAt). Nothing existing on either table changes.
- [ ] New query 50104 "EQM Open Warranty Alerts" (Internal) returns open alerts left-joined to their equipment.
- [ ] `CancelStaleAlerts` reads all open alerts in one query. It cancels exactly the same alerts as before (equipment deleted, warranty end date changed, equipment Lost/Disposed) and re-checks the alert is still Open after `Get`.
- [ ] Page 50104 shows the same Employee Name as before; each employee is read at most once per page session.
- [ ] Query 50104 has X in "EQM - Reader". Not added to "EQM - API Consumer".
- [ ] Caption 'Open Warranty Alerts' is in the `.g.xlf`, `pt-PT` and `es-ES` (translated). repo_checks check 7 passes.
- [ ] `app/` compiles with CodeCop, UICop, AppSourceCop with no new warnings. `test/` compiles.
- [ ] Test codeunit 50159 has the new scenarios L1-L2, D1, K1, C1-C2, S1-S5.
- [ ] CI shows 50159 and regression codeunits passing. Until a push: "Not verified: tests not executed locally, CI result pending".
- [ ] Docs exist: this plan, `docs/features/FR-053-large-dataset-support.md`, `docs/help/FR-053-large-dataset-support.md`, CHANGELOG `## FR-053 Large Dataset Support`.

## Out of scope

- `OptimizeForTextSearch` on Description/Manufacturer/Model/"Serial No." (phase 2: changes search semantics).
- Prefetching alerts in `GenerateAlerts` (phase 2).
- A Status or "Assignment Date" key on table 50103; employee-name cache on part 50105 and request pages.
- `BuildMaintenanceCostBuffer` (standing decision FR-041), SIFT, columnstore, BCPT (phase 3).
- Obsoleting the prefix-redundant `CategoryCode` key (still used by `SetCurrentKey` in table 50101).
- Tables 50106, 50110, 50112; app.json; upgrade code; edits to existing tests beyond adding to 50159.

## Objects

| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Table | 50100 | EQM Equipment | Changed (2 keys) | app/src/Equipment/EQMEquipment.Table.al |
| Table | 50103 | EQM Equipment Assignment | Changed (1 key) | app/src/Assignment/EQMEquipmentAssignment.Table.al |
| Query | 50104 | EQM Open Warranty Alerts | New | app/src/Warranty/EQMOpenWarrantyAlerts.Query.al |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | Changed (local CancelStaleAlerts / IsAlertStale) | app/src/Warranty/EQMWarrantyAlertMgt.Codeunit.al |
| Page | 50104 | EQM Equipment Assignments | Changed (employee-name cache) | app/src/Assignment/EQMEquipmentAssignments.Page.al |
| PermissionSet | 50100 | EQM - Reader | Changed (query X) | app/src/Permissions/EQMReader.PermissionSet.al |
| XLIFF | — | g / pt-PT / es-ES | Changed (1 unit) | app/Translations/ |
| Codeunit (test) | 50159 | EQM Performance Tests | Changed (tests added) | test/src/EQMPerformanceTests.Codeunit.al |
| Docs | — | plan / feature / help / changelog | New / Changed | docs/, CHANGELOG.md |

ID basis: the AL MCP had no project loaded; a source scan shows queries 50100-50103 used, so 50104 is next free in 50100..50149. The reviewer should confirm with `al_getnextobjectid`.

## Events and standard symbols

No events subscribed or published. Standard symbols (Employee name fields, `ReadPermission`, `SetLoadFields`, `SystemModifiedAt` in a key, `Sleep`, Library Assert, TestPage methods) are confirmed only by existing compiled usage in the repo and Microsoft Learn, not `al_symbolsearch`. Query joins/filters, RecordRef/KeyRef methods were checked on Learn.

## Steps

1. **EQMEquipment.Table.al**: after `key(NextMaintenanceDate; ...)` add:
   ```
   key(CategoryStatus; "Category Code", Status) { }
   key(SystemModified; SystemModifiedAt) { }
   ```
   No SumIndexFields, IncludedFields, Unique or Clustered. Compile `app/`.
2. **EQMEquipmentAssignment.Table.al**: after `key(EmployeeStatus; ...)` add `key(SystemModified; SystemModifiedAt) { }`. Compile.
3. **EQMOpenWarrantyAlerts.Query.al** (new, `namespace MiguelCarvalho.EquipmentManagement;`):
   ```
   query 50104 "EQM Open Warranty Alerts"
   {
       Caption = 'Open Warranty Alerts';
       QueryType = Normal;
       Access = Internal;
       // Read inside the write transaction of GenerateAlerts (after LockTable), so never from a read-only replica
       DataAccessIntent = ReadWrite;

       elements
       {
           dataitem(WarrantyAlert; "EQM Warranty Alert")
           {
               DataItemTableFilter = Status = const(Open);
               column(EntryNo; "Entry No.") { }
               column(AlertWarrantyEndDate; "Warranty End Date") { }
               dataitem(Equipment; "EQM Equipment")
               {
                   DataItemLink = "No." = WarrantyAlert."Equipment No.";
                   SqlJoinType = LeftOuterJoin;
                   column(EquipmentNo; "No.") { }
                   column(EquipmentWarrantyEndDate; "Warranty End Date") { }
                   column(EquipmentStatus; Status) { }
               }
           }
       }
   }
   ```
   Add an XML `/// <summary>`: "Open warranty alerts with the current warranty end date and status of their equipment. EquipmentNo is blank when the equipment no longer exists. Used to cancel stale alerts in one read." Compile.
4. **EQMWarrantyAlertMgt.Codeunit.al**: replace `CancelStaleAlerts` and `IsAlertStale`; keep both local and the call site unchanged.
   ```
   local procedure CancelStaleAlerts(): Integer
   var
       WarrantyAlertToCancel: Record "EQM Warranty Alert";
       OpenWarrantyAlerts: Query "EQM Open Warranty Alerts";
       StaleEntryNos: List of [Integer];
       EntryNo: Integer;
       CancelledCount: Integer;
   begin
       // One read of the open alerts joined to their equipment, instead of one equipment read per alert (FR-053)
       OpenWarrantyAlerts.Open();
       while OpenWarrantyAlerts.Read() do
           if IsAlertStale(OpenWarrantyAlerts.EquipmentNo, OpenWarrantyAlerts.AlertWarrantyEndDate, OpenWarrantyAlerts.EquipmentWarrantyEndDate, OpenWarrantyAlerts.EquipmentStatus) then
               StaleEntryNos.Add(OpenWarrantyAlerts.EntryNo);
       OpenWarrantyAlerts.Close();

       foreach EntryNo in StaleEntryNos do
           if WarrantyAlertToCancel.Get(EntryNo) then
               // Re-checked after the read: another session may have acknowledged the alert in between
               if WarrantyAlertToCancel.Status = WarrantyAlertToCancel.Status::Open then begin
                   WarrantyAlertToCancel.Status := WarrantyAlertToCancel.Status::Cancelled;
                   WarrantyAlertToCancel."Cancelled At" := CurrentDateTime();
                   WarrantyAlertToCancel.Modify(false);
                   CancelledCount += 1;
               end;
       exit(CancelledCount);
   end;

   local procedure IsAlertStale(EquipmentNo: Code[20]; AlertWarrantyEndDate: Date; EquipmentWarrantyEndDate: Date; EquipmentStatus: Enum "EQM Equipment Status"): Boolean
   var
       Equipment: Record "EQM Equipment";
   begin
       // A blank number means the outer join found no equipment: it was deleted
       if EquipmentNo = '' then
           exit(true);
       if EquipmentWarrantyEndDate <> AlertWarrantyEndDate then
           exit(true);
       exit(Equipment.IsFinalStatus(EquipmentStatus));
   end;
   ```
   Stale IDs are collected before any Modify. Old locals must be removed (AA0137). No new `Error(` calls. Compile.
5. **EQMEquipmentAssignments.Page.al**: copy the NFR-001 cache from page 50100. Add `EmployeeNames: Dictionary of [Code[20], Text]` and `CanReadEmployees: Boolean`; `OnOpenPage` sets `CanReadEmployees := Employee.ReadPermission()`; `OnAfterGetRecord` calls `GetEmployeeName(Rec."Employee No.")` (body identical to `GetAssignedEmployeeName` in EQMEquipmentList.Page.al:322-336, using `MaxStrLen(EmployeeName)`; missing employee cached as blank). Keep the StatusStyle block. No control/caption/ToolTip/view changes. Compile.
6. **EQMReader.PermissionSet.al**: add `query "EQM Open Warranty Alerts" = X,`. Not in "EQM - API Consumer" (test 50162 forbids queries there). Compile.
7. **Translations**: `al_build` on `app/` (al_compile does not regenerate `.g.xlf`), then `python3 .github/scripts/xlf_sync.py sync`. Targets: `Alertas de garantia abertos` (pt-PT), `Alertas de garantía abiertas` (es-ES), state translated. Run `xlf_sync.py check`.
8. **EQMPerformanceTests.Codeunit.al**: add tests L1, L2, D1, K1, C1, C2, S1-S5 at the end of the test section; leave existing tests and helpers unchanged. Each new test has `[Test]` and `[TransactionModel(TransactionModel::AutoRollback)]`.
   - New labels: `CategoryTwoCodeTok` ('PERFCAT2', Locked), `AssignmentsTooSlowMsg`, `UtilizationTooSlowMsg`, `AlertJobTooSlowMsg` (pattern: '... took %1 ms; the budget is %2 ms.', with Comment), `KeyMissingMsg`.
   - New helpers: `GetAssignmentDatasetSize()` (20000), `GetAlertDatasetSize()` (1000, even), `EnsureCategoryCode`, `InsertEquipmentInCategory`, `InsertAssignment` (direct `Insert(false)`; table has no insert trigger), `InsertAlert`, `GetFarWarrantyEndDate()` (Today()+200+Random(100)), `HasActiveKey(TableNo, FieldNos)` via RecordRef/KeyRef.
   - Compile `test/` after `app/`. If the AL MCP still has no project, compile with the extension's alc as in FR-041 to FR-055 and copy new app symbols into `test/.alpackages` (gitignored).
9. **Docs** (al-docs): plan, feature doc (audit, keys, query, cache, CI dataset sizes, manual sandbox check at 100k/1M, write-overhead note), help article (filter on Status/Category/Assigned Employee/Serial No. instead of free text; admins can enable "Calculate only visible FlowFields"; API consumers use `$filter=lastModifiedDateTime gt …`), CHANGELOG `## FR-053 Large Dataset Support`.

## Tests

All in codeunit 50159; each builds its own data or baselines.

- **L1** List opens within budget on a large history and shows the employee name on every row. GIVEN employee E and `GetAssignmentDatasetSize()` closed entries. WHEN timed `OpenView; First;` + up to 50 `Next()` reading "Employee Name". THEN elapsed < `GetResponseBudgetMs()`, every name = `E.FullName()`.
- **L2** (negative) Blank name for a missing employee, real name still shown after it. GIVEN entry A1 for a missing employee number and A2 for E. WHEN OpenView, `GoToRecord(A1)`, `GoToRecord(A2)`. THEN A1 name = '', A2 name = `E.FullName()`.
- **D1** Delta filter on SystemModifiedAt returns only entries changed after the boundary. GIVEN batch A (Random(20)+5), boundary = max SystemModifiedAt of A, `Sleep(100)`, batch B (Random(20)+5). WHEN filter `SystemModifiedAt > boundary` on the entry range. THEN count = size of B; with `<=` count = size of A.
- **K1** The FR-053 keys exist and are active: Equipment ("Category Code", Status), Equipment (SystemModifiedAt), Assignment (SystemModifiedAt).
- **C1** Asset utilization counts for one category are correct and within budget. GIVEN `GetDatasetSize()` equipment in PERFCAT2, status cycling by `Index mod 5`, expected counts in a Dictionary. WHEN timed `CalcAssetUtilization` with category filter. THEN counts match, elapsed < budget.
- **C2** (negative) Other category not counted. GIVEN Random(10)+5 Available in PERFCAT2 and Random(10)+5 Assigned in PERFCAT. WHEN filtered on PERFCAT2. THEN Assigned = 0, Total = Available = PERFCAT2 count.
- **S1** Open alert of deleted equipment is cancelled (Status = Cancelled, "Cancelled At" <> 0DT).
- **S2** Open alert of Lost equipment is cancelled.
- **S3** (negative) Open alert matching its equipment stays Open; `HasOpenAlert(No., D)` true.
- **S4** (negative) Acknowledged alert of deleted equipment is untouched ("Cancelled At" = 0DT).
- **S5** Stale cancellation correct and within budget on `GetAlertDatasetSize()` alerts: even indexes stale (alert date = equipment date + 1), odd valid. THEN stale Cancelled, valid Open, CancelledCount >= half, elapsed < budget.

No UI dialogs on these paths, so no handlers.

Existing tests to re-run (no change expected): 50168 (W14 and other GenerateAlerts tests), 50199, 50187, 50151, 50184, 50158, 50162, 50182, 50180, 50196, 50189, 50194, 50156, 50159 P1-P8, 50153.

## Assumptions

- CI cannot hold 100k/1M rows; tests prove correctness and budget on CI-sized samples (20k assignments, 10k equipment, 1k alerts). Full volume is a manual sandbox check.
- The 3,000 ms NFR-001 budget also applies to these paths.
- API delta extraction via `lastModifiedDateTime` is a real usage path at 1M rows.
- Active assignments cluster near the tail of the Entry No. order, so no Status key is needed.
- A blank equipment number in the query result means deleted equipment ("No." is the PK).
- The query sees uncommitted rows of the same transaction (as existing test P5 relies on).

## Decisions

- Keys `SystemModified` (SystemModifiedAt) on 50100 and 50103: API delta reads would otherwise scan all 1M assignments. Reversible: no (published keys can only be obsoleted).
- Key ("Category Code", Status) on 50100 rather than relying on CategoryCode with a residual Status filter. CategoryCode stays (published, used by SetCurrentKey in 50101). Reversible: no.
- No Status or "Assignment Date" key on 50103: views read the clustered index backward; each extra index costs on every write. Reversible: yes.
- No SIFT/columnstore for FlowFields at 100k; confirms NFR-001. Reversible: yes.
- New internal Query 50104 for CancelStaleAlerts rather than a Dictionary cache of all equipment or keeping the N+1. Reversible: no (can be obsoleted).
- Collect stale entry numbers first, modify after `Close`, re-check Status = Open. Reversible: yes.
- Employee-name cache on page 50104 only. Reversible: yes.
- Tests added to existing codeunit 50159: remaining free test IDs are reserved and widening test/app.json is on the stop list (FR-056 precedent). Reversible: yes.
- CI-sized datasets with the 3,000 ms budget, not full volumes. Reversible: yes.
- `OptimizeForTextSearch` deferred to phase 2 (user-visible behaviour change). Reversible: yes.
- Query ID 50104 from a source scan (AL MCP had no project loaded). Reversible: yes.

## Risks

- **AL MCP unavailable:** standard symbols confirmed only by existing compiled usage and Learn; the reviewer should confirm with a real build.
- **Key on a system field:** Learn says allowed. If the compiler rejects it, stop and re-plan; do not drop the key silently.
- **Upgrade/schema sync:** new indexes build at upgrade (~1M rows on 50103, 100k on 50100). Additive, no upgrade code, no data change, but may lengthen the upgrade window. Reviewer checks AppSourceCop baseline for no AS0009/AS0010/AS0038.
- **Write overhead:** table 50100 gets one more index updated on status change, and SystemModified on every modify. Feature doc should mention it.
- **Concurrency:** an alert acknowledged between query read and cancel is handled by the Status re-check.
- **Flaky timing tests (L1, C1, S5):** re-run once; if failing twice, report and do not raise the budget.
- **D1 timestamp resolution (~3 ms):** `Sleep(100)` separates batches; raise to 500 if flaky and record it.
- **CI duration:** if too slow, drop `GetAssignmentDatasetSize` to 10,000 and record it.
- **repo_checks:** check 7 needs the pt-PT/es-ES targets; feature doc, help article and CHANGELOG `## FR-053` must exist on the branch.
- **CodeCop AA0228/AA0137:** remove the old `IsAlertStale` signature and unused locals.

## References

- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-table-keys
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields#data-audit-fields
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extract-data
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/performance/performance-developer#efficient-data-access
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-query-links-joins#leftouterjoin
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-query-filters
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-read-isolation
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/keyref/keyref-data-type
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-keyindex-method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/calculate-only-visible-flowfields-feature-key
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-table-field-text-search

## Later phases

- Phase 2: `OptimizeForTextSearch` on Description/Manufacturer/Model/"Serial No." (needs the user's yes), and prefetching existing alerts in `GenerateAlerts`.
- Phase 3: a BCPT scenario app at full 100k/1M volume (new app, needs the user's yes), and a review of obsoleting the `CategoryCode` key.

No separate AppSource validation ran.
