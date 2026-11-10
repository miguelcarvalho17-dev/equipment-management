# Maintenance dashboard (AppSource end-user help)

The equipment dashboard and the Equipment Manager Role Center show four maintenance numbers. Choose a number to see the records behind it.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** can see the tiles and open the records behind them.
- Changing the numbers (posting maintenance, changing a maintenance plan) needs **Equipment Manager** or **Administrator**.

## The four tiles
| Tile | Group | What it counts |
|---|---|---|
| **Equipment in Maintenance** | Equipment | Equipment with the status In Maintenance. |
| **Planned Maintenance This Month** | Planned Maintenance | Equipment whose next maintenance date is in the current month. |
| **Overdue Maintenance Equipment** | Planned Maintenance | Equipment whose next maintenance date is before today. |
| **Total Maintenance Cost YTD** | Maintenance Costs | Cost of posted maintenance from 1 January of this year up to today. |

TODO(verify): tile order and caption wrapping were not checked in a sandbox.

### Planned Maintenance This Month
- Counts equipment with a next maintenance date from the first to the last day of the current month, both days included.
- Equipment without a next maintenance date, and lost or disposed equipment, are not counted.
- Equipment whose date is earlier this month is counted here and also in **Overdue Maintenance Equipment**. Do not add the two tiles together.
- When you post a **Preventive** maintenance record, the next maintenance date moves forward and the equipment is no longer counted. The tile shows maintenance that is still due, not maintenance already done.
- Choose the number to open the **Equipment** list with the counted equipment. TODO(verify): which filters the filter pane shows.

### Total Maintenance Cost YTD
- Adds up the cost of posted maintenance with a maintenance date from 1 January of the current year up to and including today, in local currency.
- Maintenance records that are not yet posted are not included. Maintenance posted in January but dated in December counts in the previous year.
- Choose the amount to open the **Maintenance History** with these entries. TODO(verify): that the date range is applied to the list.
- **Total Maintenance Cost** next to it still shows the cost of all posted maintenance.

## Good to know
- Today means the real calendar date, not your work date.
- Choose **Refresh** on the dashboard to update the numbers. A dashboard left open past midnight, or past the end of a month or year, keeps the old period until you reopen it.
- The tiles are read-only; you cannot edit the numbers.

## Release notes
Maintenance Dashboard: the equipment dashboard and the Role Center have two new tiles. Planned Maintenance This Month counts the equipment whose next maintenance date falls in the current month, and Total Maintenance Cost YTD shows the cost of posted maintenance from 1 January to today. Both open the records behind the number. Together with Equipment in Maintenance and Overdue Maintenance Equipment they give the four maintenance KPIs on one page.
