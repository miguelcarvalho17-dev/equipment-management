# Maintenance Cost Analysis (AppSource end-user help)

The Maintenance Cost Analysis report shows what your equipment has cost in maintenance. It gives the posted maintenance cost and the number of maintenances for each category, equipment, year and month. The report only reads data; it changes nothing.

TODO(verify): this feature has not been tested in a sandbox. The request page layout, the Excel headers and the message for an empty result may differ slightly from the description below.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** can run the report.

## How to open the report
Use one of these:
- **Equipment List**: choose **Maintenance Cost Analysis** in the **Report** group of the action bar.
- **Equipment Manager Role Center**: choose **Maintenance Cost Analysis** in the **Reporting** area.
- **Tell Me**: search for "Maintenance Cost Analysis".

## Choose the filters
The request page has two tabs.

**Equipment** has two filters:

| Filter | What it matches |
|---|---|
| **No.** | The equipment with the number you choose. |
| **Category Code** | The equipment in the category you choose. |

**Posted Maintenance** has two filters:

| Filter | What it matches |
|---|---|
| **Maintenance Date** | The maintenance done on the date or in the date range you choose. |
| **Maintenance Type** | The maintenance of the type you choose, for example Preventive or Corrective. |

The filters on the two tabs combine. A maintenance entry is included only when its equipment matches the Equipment filters and the entry matches the Posted Maintenance filters. Leave a filter empty to ignore it. You can enter several values or a range, as in any Business Central request page.

With no filter, all posted maintenance of all equipment is included.

Tip: set a **Maintenance Date** range when you have a long maintenance history. The report then runs faster.

## Only posted maintenance counts
The report counts posted maintenance only. Maintenance records that are still open are not included. Post a record to see its cost in the report.

## What the report shows
One row for each category, equipment, year and month that has at least one posted maintenance. The rows are sorted by category, equipment, year and month. The columns are:

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

The category is the category the equipment is in now. If you move equipment to another category, all of its maintenance cost, including past months, is shown under the new category.

## Totals by category, year or month
The report gives one row per equipment and month. To get totals, use Excel:
- To total by category, year or month, sort or filter the Data sheet, or create a PivotTable with CategoryCode, CostYear or CostMonth as rows and TotalCost as values.
- To total the whole report, select the TotalCost column. Excel shows the sum in the status bar.

## The output
The report opens as an Excel workbook. The first sheet holds the data: one row for each category, equipment, year and month, under the column headings. There is no formatting, no totals and no chart yet.

If no posted maintenance matches the filters, the workbook may have no rows, or the platform may show a message. Check what your environment shows.

## Good to know
- The report uses the current company only.
- The report does not use the filters you set on the Equipment List. Set the filters on the request page.
- The figures are calculated when you run the report. Run it again to see changes.

## Release notes
Equipment Management now has a Maintenance Cost Analysis report. It shows the posted maintenance cost and the number of maintenances for each category, equipment, year and month, in an Excel workbook that you can total and pivot. Filter it by equipment, category, maintenance date and maintenance type before you run it. Open maintenance is not included. Choose Maintenance Cost Analysis on the Equipment list or in the Equipment Manager Role Center.
