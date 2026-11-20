# Usage Analytics (AppSource end-user help)

The Usage Analytics report shows how your equipment register is used over a period. It gives four views in one Excel workbook: the most assigned categories, the maintenance trends, the growth of the equipment register and the number of active users. The report only reads data; it changes nothing.

TODO(verify): this feature has not been tested in a sandbox. The request page, the Excel headers and the message for an empty period may differ slightly from the description below.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** can run the report.
- The report reads assignments, maintenance, equipment and the audit trail. A custom role needs read permission on these. Without it, the report stops with a permission error.

## How to open the report
Use one of these:
- **Equipment List**: choose **Usage Analytics** in the **Reporting** area. It is also in the **Report** group.
- **Equipment Manager Role Center**: choose **Usage Analytics** in the **Reporting** area.
- **Tell Me**: search for "Usage Analytics".

## Choose the period
The request page has two fields:

| Field | What it means |
|---|---|
| **Starting Date** | The first day of the period. |
| **Ending Date** | The last day of the period. |

By default the period is the last 12 calendar months. The ending date is the work date. The starting date is the first day of the month 11 months earlier.

The period must follow these rules:
- Both dates must be filled in.
- The starting date must be on or before the ending date.
- The period can be at most 120 months.

If a rule is broken, the report stops with a message that says what to change. No workbook is created.

## What the workbook shows
The workbook has four sheets. Each sheet has its own column headers.

### Most Assigned Categories
One row for each category that has assignments in the period, with the most assigned category first.

| Column | What it shows |
|---|---|
| **Rank** | The position of the category in the list. 1 is the most assigned. |
| **Category Code** | The category code. Blank for the row "Without category". |
| **Category Description** | The description of the category. |
| **No. of Assignments** | The number of assignments in the period. Active and closed assignments are both counted. |
| **Share of Assignments %** | The share of all assignments in the period. |

The category is the category the equipment is in now. If you move equipment to another category, its past assignments count under the new category.

The row **Without category** holds two kinds of assignments: those of equipment that has no category, and those of equipment that has been deleted.

### Maintenance Trends
One row for each month in the period, including months with no maintenance.

| Column | What it shows |
|---|---|
| **Period Start Date** and **Period End Date** | The first and last day of the month. The first and last month are cut to the period. |
| **No. of Maintenances** | The number of posted maintenance records in the month. |
| **Maintenance Cost** | The total cost of those records. |

Only posted maintenance is counted, by its maintenance date. Open maintenance is not counted. Post a record to see it here.

### Equipment Growth
One row for each month in the period.

| Column | What it shows |
|---|---|
| **Period Start Date** and **Period End Date** | As above. |
| **New Equipment** | The equipment records created in the month. |
| **Total Equipment** | The equipment records created up to the end of the month. |

All statuses are counted, including Lost and Disposed. Equipment that has been deleted is not in the register, so it is not counted.

### Active Users
One row for each month in the period.

| Column | What it shows |
|---|---|
| **Period Start Date** and **Period End Date** | As above. |
| **Active Users** | The number of different users in the month. |

A user counts when the user changed equipment data or posted maintenance in the month. A user who was active in two months is counted in both months. The report shows only the number of users. It does not show user names or user IDs.

## Good to know
- The report uses the current company only.
- The report does not use the filters you set on the Equipment List. The period is set on the request page.
- The figures are calculated when you run the report. Run it again to see changes.
- Results depend on the time zone of the session that runs the report. A session in another time zone, for example a job queue session, can give different months. This is not yet checked in a sandbox.
- A large register can take a while to calculate. Use a shorter period for a quick result.

## Release notes
Equipment Management now has a Usage Analytics report. It shows, for a period of up to 120 months, the most assigned equipment categories, the posted maintenance per month, the growth of the equipment register per month and the number of active users per month. Choose Usage Analytics on the Equipment List or in the Equipment Manager Role Center. The report does not show user names. Open maintenance is not included.
