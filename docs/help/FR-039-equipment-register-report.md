# Equipment Register (AppSource end-user help)

The Equipment Register lists your equipment with its main data, in an Excel workbook. Use it to get an inventory of all equipment, or of a part of it, for one category, one status, one employee or one purchase period. The report only reads data; it changes nothing.

TODO(verify): this feature has not been tested in a sandbox. The request page order, the Excel headers and the message for an empty result may differ slightly from the description below.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** can run the report.
- A user who cannot read employees still runs the report. The **Assigned Employee Name** column is blank for every row.

## How to open the report
Use one of these:
- **Equipment List**: choose **Equipment Register** in the **Report** group of the action bar.
- **Equipment Manager Role Center**: choose **Equipment Register** in the **Reporting** area.
- **Tell Me**: search for "Equipment Register".

## Choose the filters
The request page has four filters, in this order:

| Filter | What it matches |
|---|---|
| **Category Code** | The equipment in the category you choose. |
| **Status** | The equipment with the status you choose. Lost and Disposed are available here too. |
| **Assigned Employee No.** | The equipment that is assigned to that employee now. |
| **Purchase Date** | The equipment bought on the date or in the date range you choose. |

Filters combine: equipment is listed only when it matches every filter you set. Leave a filter empty to ignore it. You can enter several values or a range, as in any Business Central request page.

With no filter, all equipment is listed, including lost and disposed equipment. Filter on **Status** to leave them out.

The **Assigned Employee No.** filter looks at the current assignment only. Past assignments are not shown.

## What the report shows
One row per equipment, sorted by equipment number. The columns are:
- Equipment number, description, category code and category description
- Serial number, manufacturer and model
- Status
- Assigned employee number and assigned employee name
- Location code
- Purchase date, purchase cost and warranty end date

The assigned employee name is the full name of the employee. If you cannot read employees, or the employee no longer exists, the name is blank and the report still runs.

## The output
The report opens as an Excel workbook. The first sheet holds the data, with the column headings in the first row. There is no formatting, no totals and no chart yet. To total or sort the amounts, use the Excel filter and sort tools.

## Good to know
- The report uses the current company only.
- The report does not use the filters you set on the Equipment List. Set the filters on the request page.
- If no equipment matches, the report may open with no rows, or show a message. Check the message in your environment.

## Release notes
Equipment Management now has an Equipment Register. It lists your equipment with its category, status, assigned employee, purchase and warranty data, in an Excel workbook. Filter it by category, status, employee and purchase date. Choose Equipment Register on the Equipment list or in the Equipment Manager Role Center.
