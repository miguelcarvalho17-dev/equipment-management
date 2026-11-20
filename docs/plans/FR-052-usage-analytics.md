# FR-052 Usage Analytics — Plan

> Request (verbatim): FR-052 Usage Analytics
> Status: **approved**
> Target: AppSource

## Request
FR-052 (issue #93): collect operational statistics for four metrics: Most Assigned Categories, Maintenance Trends, Equipment Growth and Active Users. Phase 1 calculates them when needed from data the app already records (assignments, posted maintenance, equipment, audit trail). They are delivered as one new Excel report, "Usage Analytics", with one data sheet per metric for a date period. Nothing new is stored and no existing behaviour changes.

Tooling note: `al_getnextobjectid` and `al_symbolsearch` returned "No AL projects are loaded". IDs come from a source scan of `app/` and `test/`, as in FR-050/051/066. The developer runs `al_getnextobjectid` first if the MCP has the project loaded and reports any difference. No base-app object, event or field is used.

Reused patterns:
- Report with temporary buffer and compiler-generated Excel layout: `app/src/Reports/EQMMaintCostAnalysis.Report.al` (50102), `EQMMaintCostBuffer.Table.al` (50113).
- Join/Count query: `app/src/Dashboard/EQMMaintCostByCategory.Query.al` (50102), `app/src/Warranty/EQMOpenWarrantyAlerts.Query.al` (50104).
- ErrorInfo label pattern: `CheckValueInRange` in `EQMEquipmentSetup.Table.al`.
- Entry points: Reporting area and `Category_Report` in `EQMEquipmentList.Page.al`; Reporting area in `EQMEquipmentManagerRC.Page.al`.
- Tests: `test/src/EQMMaintCostAnalysisTests.Codeunit.al` (50197); permission matrix `EQMRolePermissionTests.Codeunit.al` (50162).

Later phases (not planned here):
- Phase 2: in-app Usage Analytics page with charts, breakdown by maintenance type, list of active users by user ID (needs privacy review).
- Phase 3: daily telemetry snapshot signal EQM0011 with counts only, or a snapshot table filled by a job queue entry.

## Definition of done
- [ ] New objects: table 50116 "EQM Usage Analytics Buffer" (Temporary), query 50105 "EQM Assignments by Category", codeunit 50144 "EQM Usage Analytics Mgt.", report 50103 "EQM Usage Analytics" (caption **Usage Analytics**, Tell Me / ReportsAndAnalysis), compiler-generated layout `app/src/Reports/Layouts/EQMUsageAnalytics.xlsx`, committed.
- [ ] Request page has **Starting Date** and **Ending Date**. Defaults: first day of the month 11 months before the work date, and the work date (12 calendar months).
- [ ] The report fails with an actionable error and no output when: either date is blank; starting date is after ending date; period covers more than 120 calendar months.
- [ ] Four data sheets (`ExcelLayoutMultipleDataSheets = true`): MostAssignedCategories, MaintenanceTrends, EquipmentGrowth, ActiveUsers.
- [ ] **Most Assigned Categories**: one row per category with at least one assignment entry (any status) with Assignment Date in the period, using the equipment's current category. Columns: Rank, Category Code, Category Description, No. of Assignments, Share % (rounded 0.01). Sorted by count descending, then code ascending. Assignments of equipment without category or no longer existing form one row with blank code and description "Without category".
- [ ] **Maintenance Trends**: one row per calendar month in the period (including zero months). Columns: Period Start, Period End (first and last month cut to the period), No. of Maintenances, Maintenance Cost. Posted maintenance only (history entries by Maintenance Date); open records are not counted.
- [ ] **Equipment Growth**: one row per month. New Equipment = SystemCreatedAt inside the month part; Total Equipment = SystemCreatedAt up to the end of that month part. All statuses count.
- [ ] **Active Users**: one row per month. Distinct non-blank user IDs among audit entries ("User ID", by "Logged At") and posted maintenance ("Posted By", by "Posted At"). No user ID in the output.
- [ ] The report writes nothing to the database, holds no locks, does not Commit.
- [ ] Entry points: "Usage Analytics" action in Reporting area of page 50100 (promoted in `Category_Report`) and in Reporting area of Role Center 50110.
- [ ] EQM - Reader has `X` on the four new objects (Manager/Administrator inherit). API Consumer has no entry for the report or query.
- [ ] All new captions, ToolTips and labels in `.g.xlf`, `pt-PT.xlf`, `es-ES.xlf`; `python3 .github/scripts/xlf_sync.py check` passes.
- [ ] Test codeunit 50169 "EQM Usage Analytics Tests" (17 tests) compiles. Test 50162 gets one new assert.
- [ ] `.github/coverage/coverage-register.json` lists 50144 in `scope.businessLogic.codeunits`; `repo_checks.py` reports no integrity errors.
- [ ] app/ and test/ compile with 0 errors and 0 warnings. Tests reported as "Not verified: tests not executed locally, CI result pending".
- [ ] Docs: `docs/features/FR-052-usage-analytics.md`, `docs/help/FR-052-usage-analytics.md`, `## FR-052` in `CHANGELOG.md`, section "FR-052 sandbox checks" UA-SB1..UA-SB6 in `docs/TODO.md`.

## Out of scope
- New stored tables, snapshot jobs, job queue entries, install/upgrade code (stop list).
- New telemetry signals (EQM0010 earmarked by FR-051 phase 3); no change to EQM0001-EQM0009.
- New keys on published tables 50103 / 50112 (FR-053 left them out deliberately).
- Feature switch (FR-042), Role Center cues, charts, a new page.
- Showing user IDs, employee numbers or equipment numbers.
- Requests and approvals as Active Users source.
- `app.json`, `test/app.json`, new permission sets, analyzer rulesets.
- Changes to "EQM Dashboard Mgt." (50107) or existing reports.

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Table | 50116 | EQM Usage Analytics Buffer | New | `app/src/UsageAnalytics/EQMUsageAnalyticsBuffer.Table.al` |
| Query | 50105 | EQM Assignments by Category | New | `app/src/UsageAnalytics/EQMAssignmentsByCategory.Query.al` |
| Codeunit | 50144 | EQM Usage Analytics Mgt. | New | `app/src/UsageAnalytics/EQMUsageAnalyticsMgt.Codeunit.al` |
| Report | 50103 | EQM Usage Analytics | New | `app/src/Reports/EQMUsageAnalytics.Report.al` |
| Excel layout | — | EQMUsageAnalytics.xlsx | New (compiler-generated) | `app/src/Reports/Layouts/EQMUsageAnalytics.xlsx` |
| Page | 50100 | EQM Equipment List | Changed (1 action, 1 actionref) | `app/src/Equipment/EQMEquipmentList.Page.al` |
| Page | 50110 | EQM Equipment Manager RC | Changed (1 action) | `app/src/Dashboard/EQMEquipmentManagerRC.Page.al` |
| PermissionSet | 50100 | EQM - Reader | Changed (4 lines) | `app/src/Permissions/EQMReader.PermissionSet.al` |
| XLIFF | — | g / pt-PT / es-ES | Changed | `app/Translations/*.xlf` |
| Codeunit (test) | 50169 | EQM Usage Analytics Tests | New | `test/src/EQMUsageAnalyticsTests.Codeunit.al` |
| Codeunit (test) | 50162 | EQM Role Permission Tests | Changed (1 line) | `test/src/EQMRolePermissionTests.Codeunit.al` |
| JSON | — | coverage register | Changed | `.github/coverage/coverage-register.json` |

Test ID 50169 was reserved for FR-015 "EQM Warranty Status Tests", which is superseded: 50168 "EQM Warranty Tests" (FR-045) already covers it.

## Events and standard symbols
No base-app event, table or procedure is used; no event published or subscribed. Own objects checked by reading source (MCP had no project loaded): tables 50100, 50101, 50103, 50105, 50106, 50112. Platform: `ExcelLayoutMultipleDataSheets` (runtime 12.0+), `Query.SetRange` on filter element, `Report.SaveAs` verified on Microsoft Learn.

## Steps
1. **Table 50116 "EQM Usage Analytics Buffer"**: `TableType = Temporary`, `Access = Internal`, `DataClassification = CustomerContent`. Fields: 1 "Line No." Integer; 2 "Period Start Date" Date; 3 "Period End Date" Date; 4 "Category Code" Code[20]; 5 "Category Description" Text[100]; 6 Rank Integer; 7 "No. of Assignments" Integer; 8 "Assignment Share %" Decimal (caption 'Share of Assignments %', `DecimalPlaces = 0 : 2`); 9 "No. of Maintenances" Integer; 10 "Maintenance Cost" Decimal (`AutoFormatType = 1`); 11 "New Equipment" Integer; 12 "Total Equipment" Integer; 13 "Active Users" Integer. Key `PK("Line No.")` clustered. Captions only, like 50113.
2. **Query 50105 "EQM Assignments by Category"**: `QueryType = Normal`, `Access = Internal`, `DataAccessIntent = ReadOnly`, `OrderBy = descending(NoOfAssignments), ascending(CategoryCode)`. Data item `Assignment` ("EQM Equipment Assignment") with `filter(AssignmentDateFilter; "Assignment Date")`; child `Equipment` ("EQM Equipment") with `DataItemLink = "No." = Assignment."Equipment No."`, `SqlJoinType = LeftOuterJoin`, `column(CategoryCode; "Category Code")`, `column(NoOfAssignments) { Method = Count; }`. Fallback: if the compiler rejects Count in the child, move it to the Assignment data item and report.
3. **Codeunit 50144 "EQM Usage Analytics Mgt."** (`Access = Internal`, reads only, never writes/locks/commits).
   - Locked tokens `<-CM>`, `<CM>`, `<-CM-11M>`. Labels: PeriodMissingErr ('Enter both a starting date and an ending date for the usage analytics.'), PeriodReversedErr ('The starting date %1 is after the ending date %2. Enter a starting date that is on or before the ending date.'), PeriodTooLongErr ('The period from %1 to %2 covers %3 months. Choose a period of at most %4 months.'), WithoutCategoryLbl ('Without category'). Errors raised as ErrorInfo.
   - Internal procedures: `GetMaxPeriodMonths()` (120); `GetDefaultPeriod(ReferenceDate; var StartingDate; var EndingDate)` (0D → WorkDate); `CheckPeriod(StartingDate; EndingDate)`; `BuildMostAssignedCategories`, `BuildMaintenanceTrends`, `BuildEquipmentGrowth`, `BuildActiveUsers` (each: CheckPeriod, clear buffer, fill).
   - Most Assigned Categories: read the query with `SetRange(AssignmentDateFilter, Start, End)`; rank = running index; description from category (SetLoadFields) or "Without category" when code blank; share = Round(count*100/Total, 0.01).
   - Maintenance Trends: per month row, history entries filtered on "Maintenance Date" → Count and CalcSums(Cost).
   - Equipment Growth: per month row, SystemCreatedAt ranges (new in month part; total up to month end).
   - Active Users: one filtered FindSet (SetLoadFields) on audit entries ("Logged At") and history ("Posted At"); de-duplicate with `Dictionary of [Text, Boolean]` keyed by month|user; count per month.
   - Local: `InitMonthRows` (rows cut to the period, guard against year-9999 overflow), `GetMonthKey`, `CountMonths`, `AddActiveUser`, `GetCategoryDescription`.
   - No Insert/Modify/Delete on non-temporary records, no Commit, no UI.
4. **Report 50103 "EQM Usage Analytics"**: caption 'Usage Analytics', `UsageCategory = ReportsAndAnalysis`, `AdditionalSearchTerms`, `DefaultRenderingLayout = UsageAnalyticsExcel`, `ExcelLayoutMultipleDataSheets = true`. Four root data items on the buffer (`sorting("Line No.")`), each `OnPreDataItem` calls its Build procedure; columns with `IncludeCaption = true` and unique names (CategoryRank, CategoryCode, CategoryDescription, NoOfAssignments, AssignmentSharePct; TrendPeriodStart, TrendPeriodEnd, NoOfMaintenances, MaintenanceCost; GrowthPeriodStart, GrowthPeriodEnd, NewEquipment, TotalEquipment; UsersPeriodStart, UsersPeriodEnd, ActiveUsers). Request page (`SaveValues = false`): Starting Date, Ending Date with ToolTips. `OnInitReport` applies defaults when both dates are 0D; `OnPreReport` calls CheckPeriod. `internal procedure SetPeriod(...)` as test seam. Excel layout with Summary text.
5. **Compile app/** with `al_build` (regenerates `.g.xlf`; per DECISIONS FR-056) and `generateReportLayout` on, or alc `/generatereportlayout+` as in FR-039. Confirm the xlsx has four Data_ sheets. Do not hand-edit it. Fix every warning.
6. **EQMEquipmentList.Page.al**: action `UsageAnalytics` in `area(Reporting)` after `MaintenanceCostAnalysis` (Image = Report, RunObject report 50103, ToolTip), plus `actionref(UsageAnalytics_Promoted; UsageAnalytics)` in `Category_Report`.
7. **EQMEquipmentManagerRC.Page.al**: same action in `area(Reporting)`.
8. **EQMReader.PermissionSet.al**: add `X` for table "EQM Usage Analytics Buffer", query "EQM Assignments by Category", report "EQM Usage Analytics", codeunit "EQM Usage Analytics Mgt.". No tabledata line (temporary table).
9. **Compile app/** again: 0 errors, 0 warnings.
10. **Translations**: `xlf_sync.py sync`, fill pt-PT and es-ES using FR-055 glossary and existing terms, then `xlf_sync.py check` (0 pending, 0 empty). Key terms: Usage Analytics → Análise de utilização / Análisis de uso; Rank → Posição / Posición; Active Users → Utilizadores ativos / Usuarios activos; Without category → Sem categoria / Sin categoría; Starting/Ending Date → Data inicial/final / Fecha inicial/final; and so on. Translate ToolTips, layout Summary and the three error labels in full.
11. **Test codeunit 50169 "EQM Usage Analytics Tests"** (`Subtype = Test`, AutoRollback on every test, helpers copied from 50197, `Insert(false)` for assignments and audit entries, delta checks for month-based metrics, at most one `asserterror` per test, last action).
12. **EQMRolePermissionTests.Codeunit.al**: add `AssertNoEntry(ApiConsumerRoleTok, 3, Report::"EQM Usage Analytics");` in `ApiConsumerHasNoUIPageQueryOrUICodeunit`.
13. **Compile test/**: 0 errors, 0 warnings.
14. **Coverage register**: add `50144` to `scope.businessLogic.codeunits` (ascending). Run `repo_checks.py`.
15. **Docs**: feature doc, help article, `## FR-052` in CHANGELOG, `docs/TODO.md` section UA-SB1..UA-SB6, and one sentence in `docs/features/FR-015-warranty-monitoring.md` (line ~71) saying the 50169 reservation was reused by FR-052 and FR-015 scenarios are covered by 50168.

## Tests
Codeunit 50169:
- U1 `DefaultPeriodIsTwelveMonthsUpToReferenceDate`: GetDefaultPeriod gives End = R, Start = `CalcDate('<-CM-11M>', R)`; trends has 12 rows.
- U2 (negative) `StartingDateAfterEndingDateIsRejected`.
- U3 (negative) `BlankDateIsRejected`.
- U4 (negative, boundary) `PeriodOfMoreThan120MonthsIsRejected` (121 months).
- U5 (boundary) `PeriodOf120MonthsIsAccepted` (120 rows, first starts S, last ends E).
- U6 `CategoriesAreRankedByAssignmentsInPeriod` (counts, rank, share, description).
- U7 (negative) `AssignmentsOutsidePeriodAreNotCounted`.
- U8 `AssignmentOfUnknownEquipmentCountsWithoutCategory`.
- U9 `MonthlyCountAndCostOfPostedMaintenance`.
- U10 (negative) `OpenMaintenanceAndEntriesOutsidePeriodAreNotCounted`.
- U11 (boundary) `FirstAndLastMonthAreCutToPeriod`.
- U12 `NewEquipmentCountsInCreationMonthAndInTotal`.
- U13 (negative) `EquipmentCreatedAfterPeriodIsNotCounted`.
- U14 `DistinctUsersArePerMonth`.
- U15 (negative) `BlankUserAndActivityOutsidePeriodAreNotCounted`.
- U16 `ReportContainsAllFourMetrics` (SaveAs XML).
- U17 (negative) `ReportWithReversedPeriodFails`.

Codeunit 50162: the one new assert (step 12). 50162 `ReaderHasExecuteOnEveryObjectOfTheApp` passes only after step 8. Tests are not executed locally; CI result pending.

Sandbox checks (not run): UA-SB1 run as Reader-only user, four Data_ sheets, values match demo data (FR-066); UA-SB2 error cases on request page; UA-SB3 defaults; UA-SB4 pt-PT/es-ES captions; UA-SB5 run time with FR-053 volumes; UA-SB6 month boundaries in a far-from-UTC time zone.

## Assumptions
- "Collect operational statistics" means calculating them on demand from data the app already records; a snapshot store would need a job and install code (stop list).
- Most Assigned Categories counts assignment entries by Assignment Date, every status, by the equipment's current category (consistent with FR-041 and query 50102).
- Maintenance Trends = posted maintenance count and cost per calendar month; open records excluded.
- Equipment Growth uses SystemCreatedAt, not Purchase Date; Total Equipment counts all statuses.
- Active Users = distinct audit "User ID" + history "Posted By" per month; requests/approvals not counted (phase 2); counts only, no user IDs (EUII, FR-051 decision).
- Maximum period 120 months; default last 12 calendar months to the work date.
- Month boundaries use the user's local time; data is per company.

## DECISIONS
- FR-052 Usage Analytics | Chose calculating the metrics from existing data on demand, over a snapshot table filled by a job queue entry, because every metric already has a dated source and a job needs install/upgrade registration (stop list) | Reversible: yes
- FR-052 Usage Analytics | Chose one Excel report with four root data items and `ExcelLayoutMultipleDataSheets = true`, over a page with four parts or four reports, because it follows the FR-039/040/041 pattern | Reversible: no (dataset columns are a contract once released)
- FR-052 Usage Analytics | Chose a new internal codeunit "EQM Usage Analytics Mgt." over more procedures on "EQM Dashboard Mgt.", for one responsibility per codeunit | Reversible: yes
- FR-052 Usage Analytics | Chose a grouped query (LeftOuterJoin, Count) for Most Assigned Categories over an AL loop, because assignments reach 1M rows (FR-053) | Reversible: yes
- FR-052 Usage Analytics | Chose per-month Count/CalcSums for trends and growth, and one filtered FindSet with Dictionary de-duplication for active users, over query Year/Month methods, because query date methods group in UTC while the report uses local month boundaries | Reversible: yes
- FR-052 Usage Analytics | Chose SystemCreatedAt for Equipment Growth over Purchase Date | Reversible: yes
- FR-052 Usage Analytics | Chose Active Users = distinct audit "User ID" + history "Posted By" per month, counts only, over listing user IDs | Reversible: yes
- FR-052 Usage Analytics | Chose current category, all assignment statuses, and a "Without category" row | Reversible: yes
- FR-052 Usage Analytics | Chose a request period (default last 12 months, maximum 120, actionable ErrorInfo errors) over request filter fields | Reversible: yes
- FR-052 Usage Analytics | Chose entry points Tell Me, Equipment List Reporting area (promoted) and Role Center Reporting area, as FR-039-041 | Reversible: no (published actions can only be obsoleted)
- FR-052 Usage Analytics | Chose no new keys on published tables 50103/50112, accepting a filtered scan on an on-demand report, consistent with FR-053 | Reversible: yes
- FR-052 Usage Analytics | IDs: table 50116, query 50105, report 50103, codeunit 50144, test codeunit 50169 (FR-015 reservation, superseded by 50168), from a source scan because the AL MCP had no project loaded | Reversible: yes

## Risks
- Compiler-generated layout may produce a single Data sheet; then also set `ExcelLayoutMultipleDataSheets = true` on the layout (runtime 15+), regenerate and report. Never hand-craft the xlsx.
- No date index on assignments and audit trail (FR-053 left them out): a 12-month run on 1M rows may take seconds. Reviewer confirms SetLoadFields on both FindSet loops and no Get inside them. UA-SB5 measures it.
- `Report.SaveAs` with `SetPeriod`: OnInitReport only applies defaults when both dates are 0D. If CI shows the request page resetting them, pass parameters XML in `RunReport` and report back.
- SystemCreatedAt / Logged At / Posted At are stored in UTC; DT2Date and CreateDateTime both use the session's time zone (Microsoft Learn, "About dates in Business Central"), so bucketing and the period filter agree. Results depend on the time zone of the session that runs the report, for example a job queue session (documented, UA-SB6).
- A custom role without read on the audit trail gets a platform permission error (documented in help).
- Privacy: no column may expose "User ID" or "Posted By" values (reviewer check).
- Reusing test ID 50169; fallback is adding U1-U17 to existing 50161 "EQM Dashboard Tests".
- Symbols not verified with `al_symbolsearch` (only own objects used); the reviewer recompiles. No separate AppSource validation ran.

## References
- Microsoft Learn: ExcelLayoutMultipleDataSheets property; Excel report layouts (developer and user docs); ReportInstance.SaveAs; QueryInstance.SetRange; query filters; DateTime data type (UTC storage).
