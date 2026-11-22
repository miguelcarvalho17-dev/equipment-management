# Reports

This article explains the four reports of Equipment Management: Equipment Register, Asset Utilization, Maintenance Cost Analysis and Usage Analytics. It is for managers and analysts.

**In this article**
- [Run a report](#run-a-report)
- [Equipment Register](#equipment-register)
- [Asset Utilization](#asset-utilization)
- [Maintenance Cost Analysis](#maintenance-cost-analysis)
- [Usage Analytics](#usage-analytics)

## Run a report

All four reports open as an Excel workbook. They only read data and change nothing. Everyone with the Equipment Reader permission set or higher can run them. Choose the report in one of these ways:

- On the **Equipment** list, choose the report in the **Report** group of the action bar.
- In the Equipment Manager role center, choose the report in the **Reporting** area.
- Choose the search icon, and enter the name of the report.

Set the filters on the request page. The reports do not use the filters that you set on the equipment list. Each report uses the current company only, and calculates its figures when you run it. Run it again to see changes.

TODO(verify): the request pages, the Excel headers and the result for an empty filter are not checked in a sandbox for any of the reports.

## Equipment Register

The Equipment Register lists your equipment with its main data. Use it for an inventory of all equipment, or of a part of it.

### Filters

| Filter | What it matches |
|---|---|
| **Category Code** | The equipment in the category you choose. |
| **Status** | The equipment with the status you choose. Lost and Disposed are available here too. |
| **Assigned Employee No.** | The equipment that is assigned to that employee now. Past assignments are not shown. |
| **Purchase Date** | The equipment bought on the date or in the date range you choose. |

Filters combine. Leave a filter empty to ignore it. With no filter, all equipment is listed, including lost and disposed equipment. Filter on **Status** to leave them out.

### What the report shows

One row for each piece of equipment, sorted by equipment number. The columns are the equipment number, description, category code and category description, serial number, manufacturer, model, status, assigned employee number and name, location code, purchase date, purchase cost and warranty end date. The first sheet of the workbook holds the data. There is no formatting, no totals and no chart.

### Example reading

To count your laptops that are in use, filter **Category Code** on the laptop category and **Status** on Assigned. Count the rows in Excel.

If you cannot read employees, the name column is blank for every row, and the report still runs.

## Asset Utilization

Asset Utilization shows how much of your equipment is assigned.

### Filters

| Filter | What it matches |
|---|---|
| **Category Code** | The equipment in the category you choose. |
| **Location Code** | The equipment at the location you choose. |

To filter on other fields, such as status, choose **+ Filter**.

### Figures

| Figure | What it counts |
|---|---|
| **TotalEquipment** | All equipment except lost and disposed equipment. |
| **AssignedEquipment** | Equipment with the status Assigned. |
| **AvailableEquipment** | Equipment with the status Available. |
| **InMaintenanceEquipment** | Equipment with the status In Maintenance. |
| **UtilizationPct** | The percentage of total equipment that is assigned, rounded to two decimals. |

The percentage is assigned equipment divided by total equipment, times 100. If no equipment counts in the total, the percentage is 0, and the report shows no error. Lost and disposed equipment is never counted, so a filter on one of those statuses gives 0 in every figure. The first sheet holds one row with the five figures.

### Example reading

With 40 pieces of equipment, of which 30 are assigned, the utilization is 75. A low percentage with many available items can mean that you hold more equipment than you use.

## Maintenance Cost Analysis

Maintenance Cost Analysis shows the posted maintenance cost and the number of maintenances for each category, equipment, year and month. Only posted maintenance counts.

### Filters

On the **Equipment** tab:

| Filter | What it matches |
|---|---|
| **No.** | The equipment with the number you choose. |
| **Category Code** | The equipment in the category you choose. |

On the **Posted Maintenance** tab:

| Filter | What it matches |
|---|---|
| **Maintenance Date** | The maintenance done on the date or in the date range you choose. |
| **Maintenance Type** | The maintenance of the type you choose, for example Preventive or Corrective. |

The filters on the two tabs combine. Set a **Maintenance Date** range when you have a long maintenance history, so that the report runs faster.

### Columns

| Column | What it shows |
|---|---|
| **CategoryCode** | The category of the equipment. |
| **CategoryDescription** | The description of that category. |
| **EquipmentNo** | The equipment number. |
| **EquipmentDescription** | The description of the equipment. |
| **CostYear** | The year of the maintenance date. |
| **CostMonth** | The month of the maintenance date, from 1 to 12. |
| **PeriodStartDate** | The first day of that month. |
| **NoOfMaintenances** | The number of posted maintenance entries in that month. Entries with a cost of zero are counted. |
| **TotalCost** | The total cost of those entries. |

The report has one row for each category, equipment, year and month with at least one posted maintenance. The category is the category the equipment is in now. If you move equipment to another category, all its cost moves with it.

### Example reading

To total the cost by category, create a PivotTable in Excel with **CategoryCode** as rows and **TotalCost** as values. To total the whole report, select the **TotalCost** column. Excel shows the sum in the status bar.

## Usage Analytics

Usage Analytics shows how the register is used over a period. The workbook has four sheets.

### Period

| Field | What it means |
|---|---|
| **Starting Date** | The first day of the period. |
| **Ending Date** | The last day of the period. |

By default the period is the last 12 calendar months. The ending date is the work date. Both dates must be filled in, the starting date must be on or before the ending date, and the period can be at most 120 months. If a rule is broken, the report stops with a message and creates no workbook.

### Sheets

| Sheet | What it shows |
|---|---|
| **Most Assigned Categories** | One row for each category with assignments in the period, with the most assigned category first: rank, category, number of assignments and share of assignments. Active and closed assignments are both counted. The row Without category holds the assignments of equipment that has no category or has been deleted. |
| **Maintenance Trends** | One row for each month, including months without maintenance: the number of posted maintenance records and their cost, by maintenance date. |
| **Equipment Growth** | One row for each month: the equipment records created in the month, and the total created up to the end of the month. All statuses are counted. |
| **Active Users** | One row for each month: the number of different users who changed equipment data or posted maintenance. It shows no user names. |

### Example reading

If the number of new equipment records rises while the number of assignments stays flat, the register grows faster than it is used.

The report reads assignments, maintenance, equipment and the audit trail. A custom role needs read permission on them, or the report stops with a permission error. The months depend on the time zone of the session that runs the report. TODO(verify): not checked in a sandbox. A large register can take a while to calculate. Use a shorter period for a quick result.

## What to know

- The column headings in the Excel reports are English in every language.
- Employee names are blank for users who cannot read employees.
- The category is the current category of the equipment, not the category at the time of the event.

## Related

- [Dashboards and role center](dashboards-and-role-center.md)
- [Maintenance](maintenance.md)
- Feature article: [Equipment Register](../help/FR-039-equipment-register-report.md)
- Feature article: [Asset Utilization](../help/FR-040-asset-utilization-report.md)
- Feature article: [Maintenance Cost Analysis](../help/FR-041-maintenance-cost-analysis.md)
- Feature article: [Usage Analytics](../help/FR-052-usage-analytics.md)

---
Previous: [Dashboards and role center](dashboards-and-role-center.md) | Next: [Notifications and monitoring](notifications-and-monitoring.md)
