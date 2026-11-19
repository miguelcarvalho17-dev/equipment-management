# Large registers: speed and filters (AppSource end-user help)

Equipment Management works with large registers: 100,000 or more equipment records and 1,000,000 or more assignment records. Lists and filters respond faster. The results are the same as before.

## What you notice
- Filters on **Status**, **Category Code** and **Assigned Employee** on the Equipment List respond faster.
- The Equipment Assignments list opens faster and looks up each employee once. The **Employee Name** column shows the same names as before.
- The daily warranty job cancels alerts for deleted equipment, changed warranty dates and Lost or Disposed equipment faster. The alerts cancelled are the same as before.
- Nothing is new on the pages. You do not need a new permission to use them.

## Filter instead of searching all text
On a large register, narrow the list with filters rather than typing in the search box:
1. Choose the filter field of the list, or choose **Filter** on the page.
2. Filter on **Status**, **Category Code**, **Assigned Employee No.** or **Serial No.**
3. Choose **OK**.

Status and Category Code filters use the new indexes on the equipment table. Serial No. has no new index.

## Employee names on the Equipment Assignments list
- The **Employee Name** column is looked up once for each employee while the list is open.
- It is blank when the employee does not exist, or when you do not have permission to read employees.
- If an employee was renamed while the list was open, close the list and open it again to see the new name.

## For integrations: read only what changed
External systems can read only the records changed since their last read. Use a filter on `lastModifiedDateTime` in the Equipment API and the Assignment API:

```
$filter=lastModifiedDateTime gt 2026-11-19T00:00:00Z
```

Use the time of your last successful read. The filter is faster on large registers than reading all records.

## Tip for administrators: calculate only visible FlowFields
Business Central can calculate the FlowFields on a page only when they are shown. This saves work on pages where some columns or tiles are hidden. An administrator turns it on in **Feature Management**:
1. Search for **Feature Management** with **Tell Me**.
2. Turn on **Calculate only visible FlowFields**.

See [Enabling upcoming features ahead of time](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/feature-management) and [Calculate only visible FlowFields](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/calculate-only-visible-flowfields-feature-key).

## Release notes
Equipment Management responds faster with large numbers of equipment and assignment records. Filter on status, category, employee and serial number to narrow a large list. The Equipment Assignments list looks up each employee once. The warranty job cancels stale alerts faster, with the same result. Integrations can read only the records changed since their last read.
