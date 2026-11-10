# Warranty dashboard (AppSource end-user help)

The equipment dashboard and the Equipment Manager Role Center show four warranty numbers. Choose a number to see the equipment behind it.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** can see the tiles and open the equipment behind them.
- Changing the numbers (changing a warranty end date or the equipment status) needs **Equipment Manager** or **Administrator**.

## The warranty tiles
The **Warranty** group shows these tiles, in this order:

| Tile | What it counts |
|---|---|
| **Active Warranties** | Equipment whose warranty end date is today or later. |
| **Warranties Expiring in 90 Days** | Equipment whose warranty ends from today up to 90 days from today. |
| **Warranties Expiring in 30 Days** | Equipment whose warranty ends from today up to 30 days from today. |
| **Expired Warranties** | Equipment whose warranty end date is before today. |
| **Open Warranty Alerts** | Warranty alerts that are still open (see the warranty alerts help). |

TODO(verify): tile order and caption wrapping were not checked in a sandbox.

## How the tiles relate
- **Active Warranties** includes the warranties that expire within 30 days. On the Equipment list these can show the Warranty Status **Expiring Soon**; that is expected.
- **Warranties Expiring in 90 Days** includes the equipment of **Warranties Expiring in 30 Days**.
- Do not add the tiles together. Active Warranties plus Expired Warranties is all equipment with a warranty end date, except lost and disposed equipment.
- The 90 days are the same as the 90 Days warranty alert, so the tile matches the alerts you get.

## What is not counted
- Lost and disposed equipment.
- Equipment without a **Warranty End Date**.
- The **Warranty Start Date** is ignored: a warranty that has not started yet is counted by its end date.

## Open the equipment behind a tile
Choose the number. The **Equipment** list opens with the counted equipment. TODO(verify): which filters the filter pane shows.

## Good to know
- Today means the real calendar date, not your work date.
- Choose **Refresh** on the dashboard to update the numbers. A dashboard left open past midnight keeps the old date until you reopen it.
- The tiles are read-only; you cannot edit the numbers.
- Tiles earlier called **Warranty Expiring Soon** and **Warranty Expired** are now **Warranties Expiring in 30 Days** and **Expired Warranties**. They count as before.

## Release notes
Warranty dashboard: the equipment dashboard and the Role Center now show four warranty numbers: Active Warranties, Warranties Expiring in 90 Days, Warranties Expiring in 30 Days and Expired Warranties. Choose a number to see the equipment behind it. The two existing warranty tiles were renamed to match and count as before. Lost and disposed equipment and equipment without a warranty end date are not counted.
