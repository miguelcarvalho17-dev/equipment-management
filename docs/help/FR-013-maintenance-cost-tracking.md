# Maintenance costs (AppSource end-user help)

See what each piece of equipment has cost in maintenance, and compare it with what it cost to buy. Only **posted** maintenance counts, in local currency. Open maintenance records are not included until you post them.

## Before you start: permissions
Everyone with **Equipment Reader** (and Manager and Administrator) can see all cost figures and charts. Nobody can edit them; they are calculated from the maintenance history.

## On the Equipment list
- **Total Maintenance Cost** shows the posted maintenance cost of each piece of equipment. Choose the amount to open its maintenance history.
- Use the column chooser (personalization) to show **No. of Posted Maintenances**, **Average Maintenance Cost** and **Maintenance Cost %**.
- **Maintenance Cost %** is the total maintenance cost as a percentage of the purchase cost. At 100 % or more it is shown in red: maintenance has cost as much as the equipment itself, which may justify replacing it. It is blank when the equipment has no purchase cost or no posted maintenance.
- **Cost of one period:** choose **Filter totals by**, set **Date Filter** (for example 01/01/2026..12/31/2026) and the cost columns show only maintenance with a maintenance date in that period.
- To find expensive equipment, open the filter pane and filter **Total Maintenance Cost**, for example to more than 1000.

Example: Laptop A cost 1,200. Maintenance in 2025 was 500 and in 2026 it was 700. With no date filter the total is 1,200 and Maintenance Cost % is 100 in red. With the date filter set to 2025 the total is 500.

## In the Maintenance pane
On the Equipment Card and the Equipment list, the **Maintenance** pane shows **Total Maintenance Cost**, **Average Maintenance Cost** and **Maintenance Cost %** for the selected equipment. These are always for all dates; the date filter on the list does not change them.

## On the dashboard and Role Center
- **Maintenance Costs** tiles: **Total Maintenance Cost** and **Average Maintenance Cost** (cost of one posted maintenance) over all equipment. Choose a tile to open the Maintenance History.
- **Maintenance Cost by Category**: a column per equipment category. Choose a column to open the Equipment list for that category. Equipment without a category appears as **(blank)**.
- **Top 10 Equipment by Maintenance Cost**: the ten pieces of equipment with the highest cost, highest first. Choose a column to open the maintenance history of that equipment.
- The Equipment Manager Role Center also has a **Maintenance History** shortcut.
- Choose **Refresh** to update the tiles and charts.

## Good to know
- **Changed total in the Maintenance pane:** **Total Maintenance Cost** used to include open maintenance records. It now counts posted maintenance only, so it can be lower than the sum in the **Equipment Maintenance** list. The record counts in the pane still include open records.
- **Category:** the chart uses the equipment's current category. If you move equipment to another category, all its past maintenance cost moves with it.
- **Cost 0:** maintenance posted with cost 0 (for example a record cancelled by posting) counts in the number of maintenances and lowers the average.
- Only categories and equipment with a cost above 0 appear in the charts.
- Pages do not refresh by themselves; after posting maintenance, choose **Refresh** on the dashboard to update the tiles and charts.
- The percentage and amounts are in local currency.

## Release notes
Maintenance costs are now tracked. The Equipment list shows the total posted maintenance cost per equipment, with optional columns for the number of maintenances, the average cost and the cost as a percentage of the purchase cost (red at 100 % or more). Use Filter totals by > Date Filter to see the cost of a period. The dashboard and the Equipment Manager Role Center show total and average maintenance cost tiles, a chart of cost by category and a chart of the ten most expensive pieces of equipment. The total in the Maintenance pane now counts posted maintenance only.
