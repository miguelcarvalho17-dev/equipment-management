# FR-041 Maintenance Cost Analysis Report

> **Sandbox verification (2026-11-24):** verified in a Business Central sandbox by the project owner; no defects were reported. The detailed results are not recorded here, so statements below that say "not verified" or carry `TODO(verify)` predate this run.

## Purpose
A maintenance cost report for the equipment (GitHub issue #79). It shows the posted maintenance cost and the number of maintenances, with one row per category, equipment, year and month. The user can limit the rows with the request page filters on the equipment (No., Category Code) and on the posted maintenance (Maintenance Date, Maintenance Type). The report is read-only.

Status: implemented on branch `feature/FR-041-maintenance-cost-analysis`, not committed, not merged. App version stays 29.0.0.0 (unreleased, no bump, no upgrade code). No table change on stored data, no new key, no event, no published procedure, no API page, no app.json change. One new report, one new temporary buffer table, one new Excel layout, one internal procedure on codeunit 50107, one new test codeunit, one permission line pair, two new actions.

## Verification status
- **Build:** not recorded in this document. Before the pull request, confirm that `app/` and `test/` compile with 0 errors and 0 warnings and that `app/src/Reports/Layouts/EQMMaintCostAnalysis.xlsx` is present and committed.
- **Review:** APPROVED.
- **Tests: written, NOT executed.** Test codeunit 50197 "EQM Maint. Cost Analysis Tests" (12 test procedures) and the Reader and API Consumer checks in test codeunit 50162 have not been run locally. There is no command-line test runner and no sandbox run yet. Test results come from CI (AL-Go) after the branch is pushed. Nothing here claims the tests pass.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the AppSource rules.
- **Not verified:** sandbox checks S1 to S6. See `docs/TODO.md`, section "FR-041 sandbox checks".

## What the report shows
One row per category, equipment, year and month that has at least one posted maintenance entry. Rows are sorted by category code, equipment number, year and month. The columns are:

| Column | Content |
|---|---|
| CategoryCode | The current category code of the equipment |
| CategoryDescription | The description of that category |
| EquipmentNo | The equipment number |
| EquipmentDescription | The equipment description |
| CostYear | The year of the Maintenance Date |
| CostMonth | The month of the Maintenance Date (1 to 12) |
| PeriodStartDate | The first day of that month |
| NoOfMaintenances | The number of posted maintenance entries in that month |
| TotalCost | The sum of the cost of those entries |

The column names are the dataset names. The Excel layout shows the captions of the columns as the headers of the Data sheet.

The Excel data is the finest grain: equipment by year and month. Totals by category, by equipment, by month or by year are made in Excel, with the filter, sort or PivotTable tools.

## Request page filters
The request page has two filter tabs:

- **Equipment**, with the filter fields **No.** and **Category Code**.
- **Posted Maintenance**, with the filter fields **Maintenance Date** and **Maintenance Type**.

The filters use the standard filter fields of Business Central, so a filter can be a single value, a list or a range, as usual in the platform. The equipment filters and the maintenance filters combine with AND: an entry is counted only when its equipment matches the equipment filters and the entry matches the maintenance filters.

With no filter, all posted maintenance of all equipment is included.

## Rules
- **Only posted maintenance counts.** Open maintenance records are never included, in any column.
- **TotalCost** is the sum of the Cost of the posted maintenance entries in the row.
- **NoOfMaintenances** is the number of posted maintenance entries in the row. Entries with a cost of zero are counted.
- **CostYear and CostMonth** come from the Maintenance Date of each entry. **PeriodStartDate** is the first day of that month.
- **Category** is the **current** Category Code of the equipment. Maintenance history entries do not store a category. When equipment is moved to another category, its whole cost history moves with it.
- **Equipment outside the equipment filters** is not included, even when it has maintenance.
- **No data** gives no rows and no error.
- The report reads the current company only. It changes no data.

## Output
One Excel workbook. The data sheet has the nine column headers in the first row, then one row per category, equipment, year and month. The platform also writes the filters the user chose into the workbook's hidden filter sheet (to be checked in sandbox check S3). The layout has no formatting, no totals and no PivotTable yet. A designed layout with ready-made PivotTables is a later decision (phase 2).

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table (TableType Temporary, Access Internal) | 50113 | EQM Maint. Cost Buffer | New. Holds one row per category, equipment, year and month. Never stored. |
| Report | 50102 | EQM Maint. Cost Analysis | New. Caption Maintenance Cost Analysis. Excel layout only. Found with Tell Me. |
| Excel layout | – | EQMMaintCostAnalysis.xlsx | New. Generated by the compiler from the dataset and committed. |
| Codeunit | 50107 | EQM Dashboard Mgt. | One new internal procedure `BuildMaintenanceCostBuffer` and two local procedures. |
| Permission set | 50100 | EQM - Reader | Table 50113 and report 50102 (both execute). |
| Page (List) | 50100 | EQM Equipment List | New action Maintenance Cost Analysis in the Reporting area, after Asset Utilization, promoted in the Report group after Asset Utilization. |
| Page (Role Center) | 50110 | EQM Equipment Manager RC | New action Maintenance Cost Analysis in the Reporting area, after Asset Utilization. |
| Codeunit (test) | 50197 | EQM Maint. Cost Analysis Tests | New, not executed. |
| Codeunit (test) | 50162 | EQM Role Permission Tests | Reader must have execute on every report of the app (now covers this report). API Consumer must have no entry for it. Not executed. |
| XLIFF | – | Equipment Management.g.xlf | Regenerated by the build. |

The report, its layout and the dataset column names are part of the public contract from the first AppSource release. The column names are fixed once released: new columns can be added, existing ones are not renamed or removed.

## Permissions
- **EQM - Reader** has execute on the report and on the temporary buffer table, so Equipment Reader can run it. Equipment Manager and Equipment Administrator inherit it.
- **EQM - API Consumer** has no access to the report.
- The buffer is a temporary table. It needs no table data permission and stores nothing.
- The report reads equipment, categories and posted maintenance history. It does not read employees or vendors.

## Design decisions
- **One row per category, equipment, year and month.** The finest grain keeps the report pivotable. Coarser breakdowns are made in Excel.
- **Aggregation in AL, not in a query.** A query cannot take the request page views of the report, so the "+ Filter" fields would be silently ignored.
- **Posted maintenance only.** Consistent with the maintenance cost on the Equipment List, the dashboard and the cost queries.
- **Current category.** History entries store no category. Storing it at posting time would need a new stored field and an upgrade.
- **Zero-cost entries are counted.** The number of maintenances is the number of posted entries.
- **Two filter tabs.** The equipment filters and the maintenance filters are kept apart, as the issue's breakdown needs both.
- **Procedure on the existing codeunit.** It sits with the other maintenance cost helpers, and Reader already has execute on the codeunit.
- **Entry points:** the Tell Me search, the Report group of the Equipment List and the Reporting area of the Equipment Manager Role Center.
- **No cue tile or chart.** A tile or a chart on the dashboard is not part of this feature.

## Translations
New captions, ToolTips, the layout caption and summary, and the search terms are in `app/Translations/Equipment Management.g.xlf`, regenerated by the build. Never edit it by hand.

## Known limitations
- Open maintenance is not included. A record that is still open adds nothing until it is posted.
- The category is the current one. After equipment is moved to another category, all of its past cost is shown under the new category.
- The Excel output is a plain data table. It has no formatting, totals, PivotTables or charts.
- The report has one layout. There is no printable layout.
- There is no breakdown by vendor or by maintenance type as a column. A Maintenance Type filter limits the rows, but it is not a column.
- The figures are calculated when the report runs, not stored. Two runs at different times can differ.
- The request page filters are not pre-filled from the list page the report is started from.
- A Maintenance Date filter keeps the run fast on a large maintenance history. Without it, every posted entry of the selected equipment is read once.
- What the platform shows when no maintenance matches the filters is not tested automatically. It is a sandbox check (S6).

## Test status
- Tests: test codeunit 50197 has 12 test procedures, one per scenario of the plan. They cover the summing of the same equipment and month, the year and category breakdowns, the equipment and maintenance filters, open maintenance, no data, zero-cost entries, and the caller's filters being kept with no duplicate rows after a rebuild. The report tests check the XML output for the breakdown columns and for the equipment filter. Codeunit 50162 also checks that the Reader has execute on the report and that the API Consumer has none. Not executed locally (no CLI runner, no sandbox). CI result pending.
- The report tests check the output with a plain text search in the XML output. They do not parse the Excel file. The exact figures are tested through the procedure, not through the XML.
- Open sandbox checks: S1 to S6 (see `docs/TODO.md`).

## Related
- Help article: `docs/help/FR-041-maintenance-cost-analysis.md`
- Changelog: `CHANGELOG.md`, entry FR-041
- Plan: `docs/plans/FR-041-maintenance-cost-analysis.md`
- Sandbox checks: `docs/TODO.md`, section "FR-041 sandbox checks"
- Asset report with the same pattern: `docs/features/FR-040-asset-utilization-report.md`
- Maintenance cost on the Equipment List and the dashboard: `docs/features/FR-013-maintenance-cost-tracking.md`
