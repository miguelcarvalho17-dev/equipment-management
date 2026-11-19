# Equipment list and dashboard speed (AppSource end-user help)

The equipment list and the dashboard are built for large numbers of equipment records, up to about 10,000. Filtering by status and opening a status view are faster. The Assigned Employee Name is looked up once for each employee, not once for each row.

## What you notice
- Opening the **Equipment List** and its status views (Available, Assigned, In Maintenance, Lost, Disposed) is faster on a large register.
- The dashboard tiles that count equipment by status, warranty or maintenance date are faster to calculate.
- The figures on the dashboard and in the lists are the same as before.
- Nothing is new on the pages. You do not need a new permission.

## Employee names on the Equipment List
- The **Assigned Employee Name** column shows the full name of the employee who has the equipment. It is blank when no employee is assigned, when the employee does not exist, or when you do not have permission to read employees.
- The name is looked up when you open the list and kept for the time the list is open. If an employee's name changes while the list is open, the list still shows the old name. Close the list and open it again to see the new name.

## Tip for administrators: calculate only visible FlowFields
Business Central can calculate the FlowFields on a page only when they are shown. This saves work on pages where some columns or tiles are hidden. An administrator turns it on in **Feature Management**:
1. Search for **Feature Management** with **Tell Me**.
2. Turn on **Calculate only visible FlowFields**.

See [Enabling upcoming features ahead of time](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/feature-management) and [Calculate only visible FlowFields](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/calculate-only-visible-flowfields-feature-key).

## Release notes
The equipment list and its status views open faster on a large register. The dashboard tiles respond faster. Employee names on the list are looked up once for each employee. If an employee was renamed while the list was open, close and reopen the list to see the new name.
