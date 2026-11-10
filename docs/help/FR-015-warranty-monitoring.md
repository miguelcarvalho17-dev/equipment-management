# Warranty monitoring (AppSource end-user help)

See at a glance whether the warranty of your equipment is active, ends soon or has ended, so you can act before coverage ends and know whether a repair is still covered. You do not enter the status; it is calculated from the **Warranty End Date** and today's date.

## Before you start: permissions
**Equipment Reader**, **Equipment Manager** and **Administrator** can see the warranty status and the warranty tiles. To change it, change the **Warranty End Date**, which needs **Equipment Manager** or **Administrator**.

## What the statuses mean
| Warranty Status | When |
|---|---|
| Active | The warranty ends more than 30 days from today. |
| Expiring Soon | The warranty ends today or within the next 30 days. |
| Expired | The warranty end date is before today. |
| (blank) | No **Warranty End Date** is filled in. The equipment is not monitored. |

- The status uses today's real date, not the work date.
- The last day of the warranty is the end date, so a warranty that ends today is still Expiring Soon and is Expired from tomorrow.
- The **Warranty Start Date** does not change the status.

## On the Equipment Card
**Warranty Status** is shown in the **Warranty** section, after **Warranty End Date**, in green (Active), yellow (Expiring Soon) or red (Expired). It cannot be edited. When you change the **Warranty End Date**, the status updates at once.

## On the Equipment list
The **Warranty Status** column is shown by default with the same colors. You cannot filter or sort on it, and it is not included when you export the list to Excel. To find equipment by warranty, filter on **Warranty End Date** (show the column with personalization) or use the dashboard tiles.

## On the dashboard and the Role Center
The **Warranty** group has these tiles from this feature (see the warranty dashboard help, FR-022, for all warranty tiles):
- **Warranties Expiring in 30 Days** (called Warranty Expiring Soon before FR-022): equipment whose warranty ends within the next 30 days, today included.
- **Expired Warranties** (called Warranty Expired before FR-022): equipment whose warranty end date has passed.

Choose a tile to open the Equipment list with those items. The tiles do not count lost and disposed equipment or equipment without an end date. The card and list still show the status for lost and disposed equipment. If you keep the dashboard open past midnight, reopen it to update the tiles.

## Release notes
The Equipment Card and Equipment list now show a Warranty Status: Active, Expiring Soon (the warranty ends within 30 days) or Expired. It is calculated automatically from the Warranty End Date and is blank when no end date is filled in. The dashboard and the Equipment Manager Role Center have two new tiles, Warranties Expiring in 30 Days and Expired Warranties (first named Warranty Expiring Soon and Warranty Expired), which open the matching equipment. The tiles do not count lost and disposed equipment.
