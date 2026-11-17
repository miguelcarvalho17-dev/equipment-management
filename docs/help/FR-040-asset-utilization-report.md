# Asset Utilization (AppSource end-user help)

The Asset Utilization report shows how much of your equipment is assigned. It gives the number of total, assigned, available and in-maintenance equipment, and the utilization percentage: assigned equipment divided by total equipment, times 100. The report only reads data; it changes nothing.

TODO(verify): this feature has not been tested in a sandbox. The request page layout, the Excel headers and the result for an empty filter may differ slightly from the description below.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** can run the report.

## How to open the report
Use one of these:
- **Equipment List**: choose **Asset Utilization** in the **Report** group of the action bar.
- **Equipment Manager Role Center**: choose **Asset Utilization** in the **Reporting** area.
- **Tell Me**: search for "Asset Utilization".

## Choose the filters
The request page has one tab, **Equipment**, with two filters:

| Filter | What it matches |
|---|---|
| **Category Code** | The equipment in the category you choose. |
| **Location Code** | The equipment at the location you choose. |

Filters combine: equipment is counted only when it matches every filter you set. Leave a filter empty to ignore it. You can enter several values or a range, as in any Business Central request page.

With no filter, all equipment is counted. To filter on other fields, such as status, choose **+ Filter**.

## The five figures
| Figure | What it counts |
|---|---|
| **TotalEquipment** | All equipment except lost and disposed equipment. |
| **AssignedEquipment** | Equipment with the status Assigned. |
| **AvailableEquipment** | Equipment with the status Available. |
| **InMaintenanceEquipment** | Equipment with the status In Maintenance. |
| **UtilizationPct** | The percentage of total equipment that is assigned. |

The utilization percentage is calculated as:

**Assigned equipment / Total equipment * 100**

It is rounded to two decimals. If there is no equipment that counts in the total, the percentage is 0. The report does not show an error in that case.

## Lost and disposed equipment
Lost and disposed equipment is never counted, in any figure. These statuses are final: the equipment cannot be assigned again, so it does not count as available capacity. A filter on the status Lost or Disposed therefore gives 0 in every figure.

## Why the total differs from the dashboard
The **Total Equipment** tile on the equipment dashboard and the Role Center counts all equipment, including lost and disposed equipment. The **TotalEquipment** figure in this report does not. The two numbers differ when you have lost or disposed equipment.

## The output
The report opens as an Excel workbook. The first sheet holds the data: one row with the five figures, under the column headings. There is no formatting, no totals and no chart yet.

## Good to know
- The report uses the current company only.
- The report does not use the filters you set on the Equipment List. Set the filters on the request page.
- The figures are calculated when you run the report. Run it again to see changes.

## Release notes
Equipment Management now has an Asset Utilization report. It shows your total, assigned, available and in-maintenance equipment, and the utilization percentage. Lost and disposed equipment is not counted. Filter it by category and location before you run it. Choose Asset Utilization on the Equipment list or in the Equipment Manager Role Center.
