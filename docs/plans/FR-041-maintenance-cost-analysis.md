# FR-041 Maintenance Cost Analysis — Plan

> Request (verbatim): "FR-041 Maintenance Cost Analysis. The system shall provide maintenance cost reporting. Breakdown: Equipment, Category, Month, Year" (GitHub issue #79)
> Status: **approved**

## Request
Add a Maintenance Cost Analysis report. It shows posted maintenance cost and the number of maintenances, with one row per category, equipment, year and month. The rows cover the equipment and maintenance that match the user's request-page filters. It follows the FR-039/FR-040 report pattern: a compiler-generated Excel layout, Tell Me, the Report group on the Equipment List, the Reporting area of the Role Center, Reader permission and tests based on SaveAs.
Target: AppSource

Tooling note: the AL MCP server returned "No AL projects are loaded" for `al_getnextobjectid`, and `al_symbolsearch` is unavailable for the same reason (same as FR-038 to FR-040). IDs come from a scan of every object declaration in `app/src` and `test/src`, plus the reservations in `docs/plans/*` (codeunits 50123-50129 are API reserve, test codeunits 50150-50177 are reserved):
- **Report 50102.** 50100 and 50101 are in use.
- **Table 50113.** 50100-50112 are in use.
- **Test codeunit 50197.** 50178-50196 are in use. After this, only 50198-50199 are free.
- No new codeunit (see DECISIONS).

No base-application symbol is used. Platform methods (Date2DMY, DMY2Date, CopyFilters, CurrReport.Break, Report.SaveAs, Dictionary) were confirmed on Learn. The compile is the final check.

## Definition of done
- [ ] New report 50102 "EQM Maint. Cost Analysis" (caption **Maintenance Cost Analysis**). It is found in Tell Me (UsageCategory ReportsAndAnalysis, ApplicationArea All).
- [ ] The request page has exactly two filter tabs:
  - **Equipment**, with the filter fields No. and Category Code.
  - **Posted Maintenance**, with the filter fields Maintenance Date and Maintenance Type.
  - No tab for the buffer data item. With no filters, all posted maintenance of all equipment is included.
- [ ] The output has one dataset row per (Category Code, Equipment No., Year, Month) that has at least one posted maintenance. Columns in this order: CategoryCode, CategoryDescription, EquipmentNo, EquipmentDescription, CostYear, CostMonth, PeriodStartDate, NoOfMaintenances, TotalCost.
- [ ] Rules:
  - Only maintenance history entries (posted maintenance) count. Open maintenance records never count.
  - TotalCost = sum of Cost. NoOfMaintenances = number of entries, zero-cost entries included.
  - CostYear and CostMonth come from "Maintenance Date". PeriodStartDate = the first day of that month.
  - The category is the equipment's **current** "Category Code" (same as query 50102).
  - Equipment filters and maintenance filters combine with AND.
- [ ] Rows are sorted by Category Code, Equipment No., Year, Month.
- [ ] No data gives no rows and no error.
- [ ] The default and only layout is an Excel layout, `app/src/Reports/Layouts/EQMMaintCostAnalysis.xlsx`. The compiler generates it and it is committed.
- [ ] Action **Maintenance Cost Analysis** on page 50100 "EQM Equipment List": in area(Reporting) after AssetUtilization, and promoted in group Category_Report after AssetUtilization_Promoted. The same action on Role Center 50110, in area(Reporting) after AssetUtilization.
- [ ] Permission set 50100 "EQM - Reader" gets `table "EQM Maint. Cost Buffer" = X` and `report "EQM Maint. Cost Analysis" = X`. Manager and Administrator inherit them. API Consumer gets nothing.
- [ ] The build regenerates `app/Translations/Equipment Management.g.xlf` with the new captions, ToolTips, layout caption/summary, RequestFilterHeading and AdditionalSearchTerms.
- [ ] `app/` then `test/` compile with zero errors and zero warnings (CodeCop, UICop and AppSourceCop on app).
- [ ] New test codeunit 50197 and the change to 50162 compile. Report them as "Not verified: tests not executed locally, CI result pending".

## Out of scope
- Open (unposted) maintenance, cost per vendor or per maintenance type as a breakdown column, budget or forecast, and comparison between periods.
- Category at posting time (history entries store no category; it would need a new stored field and an upgrade, which are on the stop list).
- A formatted Excel layout with ready-made PivotTables (Cost by Category, Cost by Month, Cost by Year) and a printable Word layout. These are phase 2.
- A Role Center tile or a chart. Changes to tables 50100, 50105, 50106, to queries 50102/50103 or to the existing charts.
- Any `app.json` change, new permission set, event, upgrade or API change.

Later phases:
- Phase 2: an Excel layout with pivot sheets "Cost by Category", "Cost by Equipment", "Cost by Month", "Cost by Year", and an About sheet.
- Phase 3: an entry point on the Maintenance History page, if requested.

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Table (TableType Temporary) | 50113 | EQM Maint. Cost Buffer | New | `app/src/Reports/EQMMaintCostBuffer.Table.al` |
| Report | 50102 | EQM Maint. Cost Analysis | New | `app/src/Reports/EQMMaintCostAnalysis.Report.al` |
| Excel layout | – | EQMMaintCostAnalysis.xlsx | New (generated by compiler) | `app/src/Reports/Layouts/EQMMaintCostAnalysis.xlsx` |
| Codeunit | 50107 | EQM Dashboard Mgt. | Changed (+1 internal, +2 local procedures) | `app/src/Dashboard/EQMDashboardMgt.Codeunit.al` |
| PermissionSet | 50100 | EQM - Reader | Changed (+2 lines) | `app/src/Permissions/EQMReader.PermissionSet.al` |
| Page (List) | 50100 | EQM Equipment List | Changed (1 action, 1 actionref) | `app/src/Equipment/EQMEquipmentList.Page.al` |
| Page (RoleCenter) | 50110 | EQM Equipment Manager RC | Changed (1 action) | `app/src/Dashboard/EQMEquipmentManagerRC.Page.al` |
| XLIFF | – | Equipment Management.g.xlf | Regenerated by build | `app/Translations/Equipment Management.g.xlf` |
| Codeunit (test) | 50197 | EQM Maint. Cost Analysis Tests | New | `test/src/EQMMaintCostAnalysisTests.Codeunit.al` |
| Codeunit (test) | 50162 | EQM Role Permission Tests | Changed (1 line) | `test/src/EQMRolePermissionTests.Codeunit.al` |

## Events and standard symbols
No event is published or subscribed to.

| Symbol | Exact signature / usage | Verified |
|---|---|---|
| Table 50106 "EQM Maintenance History Entry": 1 "Entry No." Integer AutoIncrement; 2 "Maintenance No." Code[20] (unique key MaintenanceNo); 3 "Equipment No." Code[20]; 4 "Maintenance Date" Date; 5 "Maintenance Type" Enum "EQM Maintenance Type"; 8 Cost Decimal. OnInsert errors unless AllowInsertFromPosting | Data item and source of cost | MCP down. Read in `app/src/Maintenance/EQMMaintenanceHistoryEntry.Table.al` |
| Table 50100 "EQM Equipment": 1 "No." Code[20], 2 Description Text[100], 3 "Category Code" Code[20] | Data item and request filters | Read in source |
| Table 50101 "EQM Equipment Category": 1 Code Code[20], 2 Description Text[100] | Category description | Read in source |
| Table 50105 "EQM Maintenance Record" (Status Open/Posted) | Test only (open records are not counted) | Read in source |
| Codeunit 50107 "EQM Dashboard Mgt." (Access = Internal; Reader has X) | Host of the new procedure | Read in source |
| `Record.CopyFilters(var FromRecord)` | Copy the request filters to local records | Learn (used in FR-040) |
| `System.Date2DMY(Date: Date, Value: Integer): Integer` (2 = month, 3 = year) | Year and month | Learn |
| `System.DMY2Date(Day: Integer [, Month: Integer] [, Year: Integer]): Date` | Period start date | Learn |
| `CurrReport.Break()` in OnPreDataItem | Filter-only data items | Learn (used in FR-040) |
| `TableType = Temporary` | Buffer table; no schema sync; no tabledata permission needed | Learn; same as table 50104 |
| `RequestFilterHeading` (report data item) | Tab caption "Posted Maintenance" | Learn |
| `Report.SaveAs(Number, Parameters, ReportFormat::Xml, var OutStream, RecordRef)` | Test only | Learn; compiles in 50195/50196 |
| Codeunit "Library Assert", Codeunit "Temp Blob" | Test only | Already used in the test app |

## Steps
1. **`app/src/Reports/EQMMaintCostBuffer.Table.al`** (new):
   ```al
   namespace MiguelCarvalho.EquipmentManagement;

   /// <summary>
   /// In-memory buffer for the maintenance cost analysis report: posted maintenance cost per category, equipment, year and month.
   /// </summary>
   table 50113 "EQM Maint. Cost Buffer"
   {
       Caption = 'Maintenance Cost Buffer';
       DataClassification = CustomerContent;
       TableType = Temporary;
       Access = Internal;

       fields
       {
           field(1; "Category Code"; Code[20]) { Caption = 'Category Code'; }
           field(2; "Equipment No."; Code[20]) { Caption = 'Equipment No.'; }
           field(3; "Cost Year"; Integer) { Caption = 'Year'; }
           field(4; "Cost Month"; Integer) { Caption = 'Month'; }
           field(5; "Period Start Date"; Date) { Caption = 'Period Start Date'; }
           field(6; "Category Description"; Text[100]) { Caption = 'Category Description'; }
           field(7; "Equipment Description"; Text[100]) { Caption = 'Equipment Description'; }
           field(8; "No. of Maintenances"; Integer) { Caption = 'No. of Maintenances'; }
           field(9; "Total Cost"; Decimal) { Caption = 'Total Cost'; AutoFormatType = 1; }
       }
       keys
       {
           key(PK; "Category Code", "Equipment No.", "Cost Year", "Cost Month") { Clustered = true; }
       }
   }
   ```
   - Write every field and key block on several lines, in house style.
   - No ToolTips: the table is on no page. Same as the non-page fields of 50104.
   - Why the primary key starts with the category: it gives the report its sort order with no extra key. Each equipment has exactly one current category, so the key stays unique per equipment, year and month.

2. **`app/src/Dashboard/EQMDashboardMgt.Codeunit.al`**: add at the end, with `/// <summary>`, `<param>` and `<returns>` comments in house style:
   ```al
   /// <summary>
   /// Fills the maintenance cost buffer with the posted maintenance cost per category, equipment, year and month.
   /// Only maintenance history entries (posted maintenance) are included. Equipment is taken within the filters of the
   /// given equipment record, and entries within the filters of the given history entry record. The filters of both
   /// records are not changed. The current category of the equipment is used. The buffer is emptied first.
   /// </summary>
   internal procedure BuildMaintenanceCostBuffer(var Equipment: Record "EQM Equipment"; var MaintenanceHistoryEntry: Record "EQM Maintenance History Entry"; var TempMaintCostBuffer: Record "EQM Maint. Cost Buffer" temporary)
   var
       FilteredEquipment: Record "EQM Equipment";
       FilteredHistoryEntry: Record "EQM Maintenance History Entry";
       EquipmentCategories: Dictionary of [Code[20], Code[20]];
       EquipmentDescriptions: Dictionary of [Code[20], Text];
       CategoryDescriptions: Dictionary of [Code[20], Text];
       CategoryCode: Code[20];
   begin
       TempMaintCostBuffer.Reset();
       TempMaintCostBuffer.DeleteAll();

       FilteredEquipment.CopyFilters(Equipment);
       FilteredEquipment.SetLoadFields("No.", Description, "Category Code");
       if not FilteredEquipment.FindSet() then
           exit;
       repeat
           EquipmentCategories.Add(FilteredEquipment."No.", FilteredEquipment."Category Code");
           EquipmentDescriptions.Add(FilteredEquipment."No.", FilteredEquipment.Description);
       until FilteredEquipment.Next() = 0;

       FilteredHistoryEntry.CopyFilters(MaintenanceHistoryEntry);
       FilteredHistoryEntry.SetLoadFields("Equipment No.", "Maintenance Date", Cost);
       if not FilteredHistoryEntry.FindSet() then
           exit;
       repeat
           // Entries of equipment outside the equipment filters are skipped
           if EquipmentCategories.Get(FilteredHistoryEntry."Equipment No.", CategoryCode) then
               AddToMaintCostBuffer(TempMaintCostBuffer, CategoryCode, FilteredHistoryEntry."Equipment No.", FilteredHistoryEntry."Maintenance Date", FilteredHistoryEntry.Cost, EquipmentDescriptions.Get(FilteredHistoryEntry."Equipment No."), CategoryDescriptions);
       until FilteredHistoryEntry.Next() = 0;
   end;

   local procedure AddToMaintCostBuffer(var TempMaintCostBuffer: Record "EQM Maint. Cost Buffer" temporary; CategoryCode: Code[20]; EquipmentNo: Code[20]; MaintenanceDate: Date; Cost: Decimal; EquipmentDescription: Text; CategoryDescriptions: Dictionary of [Code[20], Text])
   var
       CostYear: Integer;
       CostMonth: Integer;
   begin
       // Posting always sets a maintenance date; a blank date is grouped under year 0, month 0 instead of raising an error
       if MaintenanceDate <> 0D then begin
           CostYear := Date2DMY(MaintenanceDate, 3);
           CostMonth := Date2DMY(MaintenanceDate, 2);
       end;

       if TempMaintCostBuffer.Get(CategoryCode, EquipmentNo, CostYear, CostMonth) then begin
           TempMaintCostBuffer."Total Cost" += Cost;
           TempMaintCostBuffer."No. of Maintenances" += 1;
           TempMaintCostBuffer.Modify();
           exit;
       end;

       TempMaintCostBuffer.Init();
       TempMaintCostBuffer."Category Code" := CategoryCode;
       TempMaintCostBuffer."Equipment No." := EquipmentNo;
       TempMaintCostBuffer."Cost Year" := CostYear;
       TempMaintCostBuffer."Cost Month" := CostMonth;
       if CostYear <> 0 then
           TempMaintCostBuffer."Period Start Date" := DMY2Date(1, CostMonth, CostYear);
       TempMaintCostBuffer."Category Description" := CopyStr(GetCategoryDescription(CategoryCode, CategoryDescriptions), 1, MaxStrLen(TempMaintCostBuffer."Category Description"));
       TempMaintCostBuffer."Equipment Description" := CopyStr(EquipmentDescription, 1, MaxStrLen(TempMaintCostBuffer."Equipment Description"));
       TempMaintCostBuffer."Total Cost" := Cost;
       TempMaintCostBuffer."No. of Maintenances" := 1;
       TempMaintCostBuffer.Insert();
   end;

   local procedure GetCategoryDescription(CategoryCode: Code[20]; CategoryDescriptions: Dictionary of [Code[20], Text]): Text
   var
       EquipmentCategory: Record "EQM Equipment Category";
       Value: Text;
   begin
       if CategoryCode = '' then
           exit('');
       if CategoryDescriptions.Get(CategoryCode, Value) then
           exit(Value);
       EquipmentCategory.SetLoadFields(Description);
       if EquipmentCategory.Get(CategoryCode) then
           Value := EquipmentCategory.Description;
       CategoryDescriptions.Add(CategoryCode, Value);
       exit(Value);
   end;
   ```
   - Add `<param>` lines for each parameter of the internal procedure, as in CalcAssetUtilization.
   - Why: the codeunit already holds the maintenance-cost dashboard helpers, and Reader already has X on it.
   - The work is two filtered FindSet loops: no Get per history entry, one Get per category (cached), no lock, no Commit.
   - Local records are used, so the caller's filters never change. Dictionaries are reference types, so the category cache is shared across calls within one build.

3. **`app/src/Reports/EQMMaintCostAnalysis.Report.al`** (new):
   ```al
   namespace MiguelCarvalho.EquipmentManagement;

   report 50102 "EQM Maint. Cost Analysis"
   {
       Caption = 'Maintenance Cost Analysis';
       ApplicationArea = All;
       UsageCategory = ReportsAndAnalysis;
       AdditionalSearchTerms = 'maintenance cost report, maintenance spend, repair cost per equipment, maintenance cost by month';
       DefaultRenderingLayout = MaintCostAnalysisExcel;

       dataset
       {
           dataitem(Equipment; "EQM Equipment")
           {
               DataItemTableView = sorting("No.");
               RequestFilterFields = "No.", "Category Code";

               trigger OnPreDataItem()
               begin
                   // Carries the equipment filters of the request page only
                   CurrReport.Break();
               end;
           }
           dataitem(HistoryEntry; "EQM Maintenance History Entry")
           {
               DataItemTableView = sorting("Entry No.");
               RequestFilterFields = "Maintenance Date", "Maintenance Type";
               RequestFilterHeading = 'Posted Maintenance';

               trigger OnPreDataItem()
               begin
                   // Carries the maintenance filters of the request page only
                   CurrReport.Break();
               end;
           }
           dataitem(CostLine; "EQM Maint. Cost Buffer")
           {
               DataItemTableView = sorting("Category Code", "Equipment No.", "Cost Year", "Cost Month");

               column(CategoryCode; "Category Code") { IncludeCaption = true; }
               column(CategoryDescription; "Category Description") { IncludeCaption = true; }
               column(EquipmentNo; "Equipment No.") { IncludeCaption = true; }
               column(EquipmentDescription; "Equipment Description") { IncludeCaption = true; }
               column(CostYear; "Cost Year") { IncludeCaption = true; }
               column(CostMonth; "Cost Month") { IncludeCaption = true; }
               column(PeriodStartDate; "Period Start Date") { IncludeCaption = true; }
               column(NoOfMaintenances; "No. of Maintenances") { IncludeCaption = true; }
               column(TotalCost; "Total Cost") { IncludeCaption = true; }

               trigger OnPreDataItem()
               begin
                   DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, CostLine);
               end;
           }
       }

       rendering
       {
           layout(MaintCostAnalysisExcel)
           {
               Type = Excel;
               LayoutFile = './src/Reports/Layouts/EQMMaintCostAnalysis.xlsx';
               Caption = 'Maintenance Cost Analysis (Excel)';
               Summary = 'Shows the posted maintenance cost and the number of maintenances per category, equipment, year and month for the equipment and maintenance that match your filters, in an Excel workbook that you can total and pivot. Open maintenance records are not included.';
           }
       }

       var
           DashboardMgt: Codeunit "EQM Dashboard Mgt.";
   }
   ```
   - Write the column blocks on several lines, as in `EQMEquipmentRegister.Report.al`.
   - No labels, no UI, no Commit, no DataAccessIntent (same as FR-039).
   - Why: the first two data items only carry the request-page filters. They also fill the hidden ReportFilterValues sheet in Excel. The buffer data item has a fixed sort and no RequestFilterFields, so it gets no request-page tab. It is filled in its own OnPreDataItem and then iterated by the report.

4. **Build `app/`** (`al_compile` + `al_getdiagnostics`; if the MCP still has no project, use the direct alc build with `/generatereportlayout+` as in FR-039/FR-040).
   - Confirm that `app/src/Reports/Layouts/EQMMaintCostAnalysis.xlsx` exists. Do not edit it.
   - On AL0709, rebuild with layout generation on. Never hand-create the binary.
   - Fix every warning.

5. **`app/src/Permissions/EQMReader.PermissionSet.al`**:
   - Add `table "EQM Maint. Cost Buffer" = X,` directly after `table "EQM Warranty Alert" = X,`.
   - Add `report "EQM Maint. Cost Analysis" = X,` directly after `report "EQM Asset Utilization" = X,`.
   - No tabledata line: the table is temporary.
   - Why: test 50162 SCENARIO 8 requires Execute on every table and report in 50100-50149.

6. **`app/src/Equipment/EQMEquipmentList.Page.al`**:
   - In `area(Reporting)`, after `action(AssetUtilization)`, add:
     ```al
     action(MaintenanceCostAnalysis)
     {
         Caption = 'Maintenance Cost Analysis';
         ToolTip = 'Print the maintenance cost analysis: posted maintenance cost and number of maintenances per category, equipment, year and month. Open maintenance is not included. You can filter by equipment, category, maintenance date and maintenance type.';
         Image = Report;
         RunObject = report "EQM Maint. Cost Analysis";
     }
     ```
   - In `group(Category_Report)`, after `actionref(AssetUtilization_Promoted; AssetUtilization)`, add `actionref(MaintenanceCostAnalysis_Promoted; MaintenanceCostAnalysis)` with multi-line braces.
   - Change nothing else.

7. **`app/src/Dashboard/EQMEquipmentManagerRC.Page.al`**: in `area(Reporting)`, after `action(AssetUtilization)`, add the same `action(MaintenanceCostAnalysis)` as step 6 (same Caption, ToolTip, Image, RunObject). Change nothing else.

8. **Build `app/`** again with zero errors and zero warnings, and keep the regenerated `.g.xlf`. New trans-units are expected for:
   - the table caption and 9 field captions
   - the report caption and AdditionalSearchTerms
   - RequestFilterHeading
   - the layout caption and summary
   - 2 action captions and 2 ToolTips

9. **`test/src/EQMMaintCostAnalysisTests.Codeunit.al`**: new codeunit 50197 "EQM Maint. Cost Analysis Tests".
   - Header: `namespace MiguelCarvalho.EquipmentManagement.Tests;` and the usings `MiguelCarvalho.EquipmentManagement; System.TestLibraries.Utilities; System.Utilities;`. Set `Subtype = Test; TestPermissions = Disabled;`.
   - Every test has `[Test]` and `[TransactionModel(TransactionModel::AutoRollback)]`. No UI handlers.
   - Globals:
     - `Assert: Codeunit "Library Assert"`, `DashboardMgt: Codeunit "EQM Dashboard Mgt."`, `Counter: Integer`.
     - Locked Tok labels: `EquipmentNoTok 'MCEQ%1X'`, `CategoryCodeTok 'MCCAT%1'`, `CategoryDescriptionTok 'Maintenance cost category %1'`, `EquipmentDescriptionTok 'Maintenance cost test equipment'`, `MaintenanceNoTok 'MCMNT%1'`, `MaintenanceRecordNoTok 'MCMR%1'`, `CounterFormatTok '<Integer,4><Filler Character,0>'`, `TotalCostColumnTok 'TotalCost'`, `CostMonthColumnTok 'CostMonth'`.
   - Local helpers, shaped like 50196 and `EQMEquipmentFactBoxTests.Codeunit.al`:
     - `NextId(): Text`.
     - `CreateCategory(): Code[20]` (Active true, `Insert(false)`).
     - `CreateEquipment(CategoryCode): Code[20]`: Init, No. from the Tok, Description = EquipmentDescriptionTok, category, `Insert(true)`; returns the No.
     - `InsertHistoryEntry(EquipmentNo: Code[20]; MaintenanceDate: Date; Cost: Decimal; MaintenanceType: Enum "EQM Maintenance Type")`: Init, "Maintenance No." from MaintenanceNoTok + NextId, fields, `Insert(false)`. Comment: "Inserted directly, without triggers, to avoid dependency on the posting flow".
     - `InsertOpenMaintenanceRecord(EquipmentNo; MaintenanceDate; Cost)`: as in the FactBox tests, `Insert(false)`, Status Open.
     - `RandomCost(): Decimal` = `Random(100000) / 100`.
     - `PastYear(): Integer` = `Date2DMY(WorkDate(), 3) - 1`.
     - `RunReport(var Equipment): Text`: same as 50196 `RunReport`, but with `Report::"EQM Maint. Cost Analysis"`.
   - Every test filters a fresh Equipment record on its own test category, so demo data never counts.
   - Dates are built with DMY2Date from `PastYear()`, `Random(28)` for the day and `Random(6)` for month M, with the second month M + 6. No literal dates or amounts.
   - Implement the scenarios under Tests, one behaviour per test.

10. **`test/src/EQMRolePermissionTests.Codeunit.al`**: in `ApiConsumerHasNoUIPageQueryOrUICodeunit`, after `AssertNoEntry(ApiConsumerRoleTok, 3, Report::"EQM Asset Utilization");`, add `AssertNoEntry(ApiConsumerRoleTok, 3, Report::"EQM Maint. Cost Analysis");`. Nothing else changes.

11. **Build `test/`** with zero errors and zero warnings. Report the tests as not executed (CI pending).

12. **Documenter** (after review):
    - Write `docs/features/FR-041-maintenance-cost-analysis.md` and `docs/help/FR-041-maintenance-cost-analysis.md`.
    - The help covers:
      - how to open the report and the two filter tabs
      - the columns
      - that only posted maintenance counts
      - that the current category is used
      - how to pivot by category or year in Excel
      - that a Maintenance Date filter keeps large histories fast
    - Add a `CHANGELOG.md` section with the heading `## FR-041 Maintenance Cost Analysis (version stays 29.0.0.0, no bump)`.
    - Add a `docs/TODO.md` section "FR-041 sandbox checks" with S1-S6 below. No events report.

## Tests
New codeunit 50197. C1 and C2 are fresh categories, E1 and E2 are fresh equipment, Y = PastYear(), and X1, X2, X3 are RandomCost().

**Buffer (BuildMaintenanceCostBuffer)**
- [SCENARIO 1] Entries of the same equipment and month are summed; another month gets its own row.
  - [GIVEN] E1 in C1 with entries X1 and X2 in (Y, M), and X3 in (Y, M+6).
  - [WHEN] Build runs with Equipment filtered on C1 and HistoryEntry unfiltered.
  - [THEN] Buffer Count = 2.
  - [THEN] Get(C1, E1, Y, M): Total = X1+X2, No. of Maintenances = 2, Period Start Date = DMY2Date(1, M, Y), Category Description = StrSubstNo(CategoryDescriptionTok, C1), Equipment Description = EquipmentDescriptionTok.
  - [THEN] Get(C1, E1, Y, M+6): Total = X3, count 1.
- [SCENARIO 2] Year breakdown: the same month in two years gives two rows.
  - [GIVEN] E1 in C1 with X1 in (Y-1, M) and X2 in (Y, M).
  - [WHEN] Build on C1.
  - [THEN] Count = 2. Get(C1, E1, Y-1, M) Total = X1. Get(C1, E1, Y, M) Total = X2.
- [SCENARIO 3] Category breakdown.
  - [GIVEN] E1 in C1 with X1, and E2 in C2 with X2, same (Y, M).
  - [WHEN] Build with Category Code filter `C1|C2`.
  - [THEN] SetRange("Category Code", C1) + CalcSums("Total Cost") = X1, and the same for C2 = X2.
- [SCENARIO 4] (negative) Equipment outside the equipment filter is not included.
  - [GIVEN] E1 in C1 with X1, and E2 in C2 with X2.
  - [WHEN] Build with filter C1.
  - [THEN] SetRange("Equipment No.", E2) is empty, and Count = 1.
- [SCENARIO 5] (negative) Maintenance Date filter excludes entries outside the range.
  - [GIVEN] E1 in C1 with X1 in (Y, M) and X2 in (Y, M+6).
  - [WHEN] Build with HistoryEntry.SetRange("Maintenance Date", DMY2Date(1, M, Y), CalcDate('<CM>', DMY2Date(1, M, Y))).
  - [THEN] Count = 1, and Get(C1, E1, Y, M) Total = X1.
- [SCENARIO 6] (negative) Maintenance Type filter.
  - [GIVEN] E1 in C1 with a Preventive X1 and a Corrective X2 in (Y, M).
  - [WHEN] Build with HistoryEntry filtered on Corrective.
  - [THEN] Total = X2, count 1.
- [SCENARIO 7] (negative) Open maintenance records are not included.
  - [GIVEN] E1 in C1 with only an open maintenance record (cost X1).
  - [WHEN] Build on C1.
  - [THEN] The buffer is empty.
- [SCENARIO 8] (failure path) No posted maintenance gives an empty buffer and no error.
  - [GIVEN] E1 in C1 with no entries, and an empty category C2.
  - [WHEN] Build on C1, then on C2.
  - [THEN] The buffer is empty both times.
- [SCENARIO 9] Zero-cost entries are counted.
  - [GIVEN] E1 in C1 with one entry of cost 0 and one of X1 in (Y, M).
  - [WHEN] Build on C1.
  - [THEN] Total = X1, count = 2.
- [SCENARIO 10] Caller filters are kept and a rebuild does not duplicate.
  - [GIVEN] E1 in C1 with X1. Equipment is filtered on C1 and HistoryEntry on Maintenance Type; store both `GetFilters()`.
  - [WHEN] Build runs twice on the same buffer.
  - [THEN] Count = 1 and Total = X1.
  - [THEN] Both GetFilters() are unchanged, and FilterGroup() on both is 0.

**Report (SaveAs XML)**
- [SCENARIO 11] The report emits the breakdown columns for matching equipment.
  - [GIVEN] E1 in C1 with X1.
  - [WHEN] SaveAs XML with Equipment filtered on C1.
  - [THEN] The output is not empty and contains TotalCostColumnTok, CostMonthColumnTok and E1.
- [SCENARIO 12] (negative) The report leaves out equipment of other categories.
  - [GIVEN] E1 in C1 with X1, and E2 in C2 with X2.
  - [WHEN] SaveAs XML with filter C1.
  - [THEN] The output contains E1 and does not contain E2.

**Permissions (50162)**
- [SCENARIO 8 existing] Reader has Execute on every table and report in the range. It now also covers table 50113 and report 50102, and it fails if step 5 is missed.
- [SCENARIO 4 extended] (negative) API Consumer has no entry for report 50102.

Existing tests likely affected:
- 50162 (changed on purpose; SCENARIO 8 picks up the new objects automatically).
- No other test calls the touched procedures, actions or permission lines. 50195 and 50196 are unaffected.

Manual sandbox checks (go to `docs/TODO.md`):
- S1: Tell Me "Maintenance Cost Analysis" shows exactly two tabs: Equipment (No., Category Code) and Posted Maintenance (Maintenance Date, Maintenance Type).
- S2: With no filter, the sum of TotalCost in Excel equals the dashboard total maintenance cost.
- S3: The Excel Data sheet has one row per category/equipment/year/month, and a PivotTable by CategoryCode/CostYear works.
- S4: A user with only EQM - Reader can run it.
- S5: The action works from the Equipment list Report group and from the Role Center.
- S6: Find out what the user sees when no maintenance matches (an empty workbook or the platform "report is empty" message), and record it in the help.

## Assumptions
- Assumed "maintenance cost" = **posted** maintenance (history entries), because FR-013, FR-037 (DECISIONS), queries 50102/50103 and the cue all use posted cost. Open records can still change.
- Assumed **current category** of the equipment, because history entries store no category and query 50102 already works this way (FR-013 doc). Storing the category at posting would need a schema change and an upgrade (stop list).
- Assumed "breakdown Equipment, Category, Month, Year" = one row at the finest grain (equipment × year × month), with category, year and month as columns. Excel totals and pivots give the coarser breakdowns (by category, by year). Learn positions Excel layouts exactly for this.
- Assumed zero-cost entries count in NoOfMaintenances, consistent with "No. of Posted Maintenances" (field 15 on table 50100).
- Assumed history entries whose equipment no longer exists are left out. Equipment with maintenance cannot be deleted, so this is not expected to happen.
- Assumed no default date filter: the user sets Maintenance Date if needed.
- No mismatch found between `CLAUDE.md` and `app/app.json`.

## DECISIONS
- FR-041 | Chose an aggregated dataset (one row per category, equipment, year, month) filled into a TableType=Temporary buffer table over one row per history entry, because the issue asks for a breakdown and it stays pivotable in Excel | Reversible: no (dataset columns are a contract once released; can only be added)
- FR-041 | Chose to aggregate in AL (filtered FindSet + Dictionary + temporary buffer) over a query with Year/Month date methods, because a query cannot take the report's request-page views, so "+ Filter" fields would be silently ignored | Reversible: yes
- FR-041 | Chose the procedure on "EQM Dashboard Mgt." over a new codeunit, same reasoning as FR-040 (it already holds the maintenance-cost helpers, and Reader has X) | Reversible: yes
- FR-041 | Chose posted maintenance (history entries) only, and the equipment's current category, consistent with FR-013/FR-037 and query 50102 | Reversible: yes
- FR-041 | Chose request filters Equipment: No., Category Code and Posted Maintenance: Maintenance Date, Maintenance Type | Reversible: yes
- FR-041 | Chose zero-cost entries counted in No. of Maintenances | Reversible: yes
- FR-041 | Chose a single compiler-generated Excel layout and the FR-039/040 entry points (Tell Me, Equipment List Report group, Role Center Reporting area) | Reversible: no (published actions cannot be removed, AS0031; they can be obsoleted)
- FR-041 | Chose report 50102, table 50113 and test codeunit 50197 (MCP ID tool unavailable, IDs from a source scan) | Reversible: yes

## Risks
- **MCP unavailable.** The compile is the check. The reviewer greps that `report 50102`, `table 50113` and `codeunit 50197` are declared nowhere else.
- **Test ID range almost exhausted.** After 50197, only 50198-50199 are free. Extending it is an `app.json` change (stop list).
- **Filling the data item record in its own OnPreDataItem.** The procedure calls Reset() on the CostLine record. The data item's sort equals the primary key, so nothing is lost. The reviewer checks that rows come out sorted and non-duplicated (S3). If the platform does not iterate the rows, do not work around it silently: report it.
- **Internal table as report data item.** Same module, so it is allowed, and table 50104 is internal too. If the compiler objects, stop and report; do not make the table Public on your own.
- **AA0073** (temporary variable name prefix): the parameter is named `TempMaintCostBuffer`. The data item `CostLine` is not a `temporary` declaration and should not trigger it. If it does, report it; do not rename the data item without asking (the dataset contract starts at release).
- **Layout generation.** If the xlsx is missing, AL0709 fails the build. Commit the file.
- **Performance.** One scan of the history entries within the maintenance filters, plus one scan of the equipment. No new key. On a very large history with an equipment filter only, every history entry is still read once. The help recommends a Maintenance Date filter. Read-only, no locks, no Commit, current company only.
- **Empty dataset.** What the platform does with an Excel report with no rows is checked in sandbox S6. The tests cover the empty case at procedure level only.
- **XML shape** (scenarios 11 and 12). Exact figures are tested through the procedure, not through the XML.
- **Dataset is a contract.** Never rename or remove the 9 columns once released.
- **Category moves.** Moving equipment to another category moves its whole cost history. Documented in the help.
- No separate AppSource validation ran; the reviewer checks the AppSource rules.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables — TableType Temporary, buffers for aggregated report data, no permissions needed on temporary tables
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-tabletype-property — TableType = Temporary (runtime 6.0+), no schema sync
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-request-pages-for-reports — no RequestFilterFields + DataItemTableView sort means no FastTab; RequestFilterHeading
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-dataitemtableview-property — sort and filter behaviour of DataItemTableView
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-howto-excel-report-layout — Excel layouts for analytical reports, pivot tables, generateReportLayout, ReportFilterValues
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-date2dmy-method — Date2DMY(Date, 2|3)
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-dmy2date-method — DMY2Date(Day, Month, Year)
- Pattern: `docs/plans/FR-040-asset-utilization-report.md`, `docs/plans/FR-039-equipment-register-report.md`
