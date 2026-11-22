# Dashboards and role center

This article explains the Equipment Manager role center and the Equipment Dashboard: the tiles, the charts, the drill-down and how to refresh the numbers. It is for managers and for everyone who follows the equipment figures.

**In this article**
- [Open the dashboard](#open-the-dashboard)
- [The Equipment Manager role center](#the-equipment-manager-role-center)
- [Tiles](#tiles)
- [Charts](#charts)
- [Drill down](#drill-down)
- [Refresh the numbers](#refresh-the-numbers)

## Open the dashboard

- **Equipment Manager role:** choose the **Settings** icon, choose **My Settings**, choose **Equipment Manager** in the **Role** field, and save. The dashboard becomes your home page.
- **Any other role:** choose the search icon, enter **Equipment Dashboard**, and choose the related link. Or open the **Equipment** list and choose **Dashboard** under **Reports**.

Everyone with the Equipment Reader permission set or higher can open the dashboard. Choosing the role does not give edit rights.

## The Equipment Manager role center

The role center shows the tiles and the four charts. Its navigation bar has these shortcuts: **Equipment**, **Assignments**, **Equipment Requests**, **Maintenance**, **Maintenance History** and **Warranty Alerts**. The **Setup** section has **Equipment Setup**, **Equipment Features** and **Equipment Categories**. You can create new **Equipment** and a new **Maintenance Record** from the **New** menu, and open the four reports from the **Reporting** area. See [Reports](reports.md).

## Tiles

The tiles are read-only. They are calculated when the page opens, and they use today's real date, not the work date.

### Equipment

| Tile | What it shows |
|---|---|
| **Total Equipment** | The number of equipment records, whatever their status. |
| **Available Equipment** | The number of equipment records that are available for assignment. |
| **Assigned Equipment** | The number of equipment records that are assigned to an employee. |
| **Equipment in Maintenance** | The number of equipment records that are in maintenance. |
| **Lost Equipment** | The number of equipment records that are lost. |
| **Disposed Equipment** | The number of equipment records that are disposed of. |

### Operational Indicators

| Tile | What it shows |
|---|---|
| **Requests Pending Approval** | The number of equipment requests that are waiting for approval. Choose the number to see the requests. |
| **Warranties Expiring This Month** | The number of equipment records whose warranty ends from today up to and including the last day of the current month. Warranties that ended earlier this month are counted as expired warranties. Lost and disposed equipment and equipment without a warranty end date are not counted. Choose the number to see the equipment. |
| **Open Maintenance Activities** | The number of maintenance records that are registered but not yet posted. While a record is open, its equipment is in maintenance and cannot be assigned. Choose the number to see the open maintenance records. |
| **Total Assets Value** | The total purchase cost of the equipment that is not lost or disposed of, in local currency. Equipment without a purchase cost counts as zero, and depreciation is not taken into account. Choose the amount to see the equipment. |

### Warranty

| Tile | What it shows |
|---|---|
| **Active Warranties** | The number of equipment records whose warranty is still in force: the warranty end date is today or later. Warranties that expire within the next 30 days are included. Lost and disposed equipment and equipment without a warranty end date are not counted. Choose the number to see the equipment. |
| **Warranties Expiring in 90 Days** | The number of equipment records whose warranty ends within the next 90 days, today included. Warranties that end within 30 days are included. Lost and disposed equipment is not counted. Choose the number to see the equipment. |
| **Warranties Expiring in 30 Days** | The number of equipment records whose warranty ends within the next 30 days, today included. Lost and disposed equipment is not counted. |
| **Expired Warranties** | The number of equipment records whose warranty end date has passed. Lost and disposed equipment and equipment without a warranty end date are not counted. |
| **Open Warranty Alerts** | The number of warranty alerts that are open. An alert is created 90, 60 and 30 days before a warranty ends. Choose the number to see and acknowledge the alerts. |

### Planned Maintenance

This group is shown only when the Maintenance Planning feature is on.

| Tile | What it shows |
|---|---|
| **Planned Maintenance This Month** | The number of equipment records whose next maintenance date is in the current month, including dates earlier this month that are already overdue. Lost and disposed equipment is not counted. When preventive maintenance is posted, the next maintenance date moves forward and the equipment is no longer counted. Choose the number to see the equipment. |
| **Overdue Maintenance Equipment** | The number of equipment records whose next maintenance date is before today. Equipment without a next maintenance date and lost or disposed equipment are not counted. Choose the number to see the equipment. |

### Maintenance Costs

| Tile | What it shows |
|---|---|
| **Total Maintenance Cost** | The total cost of all posted maintenance, in local currency. |
| **Total Maintenance Cost YTD** | The total cost of the maintenance posted with a maintenance date from 1 January of the current year up to and including today, in local currency. Open maintenance records are not included until they are posted. Choose the amount to see the maintenance history. |
| **Average Maintenance Cost** | The average cost of one posted maintenance, in local currency. Maintenance with a cost of zero is included. |

How the tiles relate:

- **Active Warranties** includes the warranties that expire within 30 days.
- **Warranties Expiring in 90 Days** includes the equipment of **Warranties Expiring in 30 Days**.
- **Warranties Expiring This Month** and **Warranties Expiring in 30 Days** can count the same equipment. The first uses the calendar month, and the second the next 30 days.
- **Planned Maintenance This Month** includes equipment that is already overdue this month. Do not add it to **Overdue Maintenance Equipment**.
- **Open Maintenance Activities** counts records. **Equipment in Maintenance** counts equipment.
- **Total Equipment** counts all equipment. The Asset Utilization report does not count lost and disposed equipment, so its total can differ.

TODO(verify): the tile order, the tile placement, the colors of the overdue tile and the wording of the captions are not checked in a sandbox.

## Charts

| Chart | What it shows |
|---|---|
| **Equipment by Category** | A column for each category that has equipment. Equipment without a category appears as a column without a label. |
| **Equipment by Status** | A pie chart with a segment for each status. |
| **Maintenance Cost by Category** | Columns with the posted maintenance cost for each category. Only categories with a cost above 0 appear. |
| **Top 10 Equipment by Maintenance Cost** | The ten pieces of equipment with the highest posted maintenance cost, highest first. |

## Drill down

Choose a tile number to open the list behind it. Most tiles open the equipment list with only the counted equipment. **Requests Pending Approval** opens the requests, **Open Maintenance Activities** opens the open maintenance records, **Open Warranty Alerts** opens the alerts, and the cost tiles open the maintenance history.

Choose a chart column or segment to open the equipment list for that category or status. For the top 10 chart, a column opens the maintenance history of that equipment.

TODO(verify): the filters that the filter pane shows after a drill-down are not checked in a sandbox.

## Refresh the numbers

The numbers are calculated when the page opens. To update them, choose **Refresh** on the dashboard, or on a chart. A dashboard that stays open past midnight, or past the end of a month or year, keeps the old period until you reopen it.

## What to know

- A tile of a feature that is off is hidden. The Equipment Requests and Warranty Alerts shortcuts on the role center stay visible, and opening one shows an error.
- Lost and disposed equipment is left out of the warranty and planned maintenance tiles.
- **Total Assets Value** uses the purchase cost in your local currency. It does not show the value after depreciation.
- Pages do not refresh by themselves. After you post maintenance, choose **Refresh**.

## Related

- [Warranty](warranty.md)
- [Maintenance](maintenance.md)
- [Reports](reports.md)
- Feature article: [Equipment dashboard](../help/FR-009-dashboard-kpis.md)
- Feature article: [Maintenance dashboard](../help/FR-021-maintenance-dashboard.md)
- Feature article: [Warranty dashboard](../help/FR-022-warranty-dashboard.md)
- Feature article: [Operational indicators on the Equipment Role Center and dashboard](../help/FR-038-enhanced-role-center.md)
- Feature article: [Equipment list and dashboard speed](../help/NFR-001-performance.md)

---
Previous: [Warranty](warranty.md) | Next: [Reports](reports.md)
