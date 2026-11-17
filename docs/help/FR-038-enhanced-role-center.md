# Operational indicators on the Equipment Role Center and dashboard (AppSource end-user help)

The Equipment Manager Role Center and the equipment dashboard show four more numbers in a new group, **Operational Indicators**. Choose a number to see the records behind it. The tiles are read-only; change the records themselves.

TODO(verify): this feature has not been tested in a sandbox. Tile order and caption wrapping may differ slightly from the description below.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** can see the tiles and open the records behind them.

## The Operational Indicators tiles
The group sits after the **Equipment** group and before the **Warranty** group. The tiles are in this order:

| Tile | What it counts |
|---|---|
| **Requests Pending Approval** | Equipment requests that were sent for approval and are waiting for a decision. Requests that are still open, not yet sent, are not counted. |
| **Warranties Expiring This Month** | Equipment whose warranty ends from today up to and including the last day of the current month. |
| **Open Maintenance Activities** | Maintenance records that are registered but not yet posted. |
| **Total Assets Value** | The total purchase cost of the equipment that is not lost or disposed of, in your local currency. |

Choose a number to open the matching list:
- **Requests Pending Approval** opens the equipment requests, filtered to the pending ones.
- **Warranties Expiring This Month** and **Total Assets Value** open the equipment list, with the same filter as the tile.
- **Open Maintenance Activities** opens the maintenance records, filtered to the open ones.

## What is not counted
- **Requests Pending Approval**: requests that are still open (not yet sent for approval), approved, rejected or completed.
- **Warranties Expiring This Month**: lost and disposed equipment, equipment without a warranty end date, and warranties that ended before today. A warranty that ended earlier this month is shown in **Expired Warranties**.
- **Total Assets Value**: lost and disposed equipment, and equipment without a purchase cost (it counts as zero). Depreciation is not taken into account.
- **Open Maintenance Activities**: posted maintenance records.

## How the tiles relate
- **Warranties Expiring This Month** and **Warranties Expiring in 30 Days** can count the same equipment. The month tile uses the calendar month; the 30-day tile counts the next 30 days from today.
- **Open Maintenance Activities** counts records, not equipment. A piece of equipment with two open records is counted twice. The **Equipment in Maintenance** tile counts equipment.

## Good to know
- Today means the real calendar date, not your work date.
- Choose **Refresh** on the dashboard to update the numbers. A dashboard that stays open past the end of the month keeps the old window until you reopen it.
- **Total Assets Value** shows the purchase cost in your local currency. It does not convert other currencies and does not show the current value after depreciation.

## Release notes
The Equipment Manager Role Center and the equipment dashboard show four new numbers in the Operational Indicators group: Requests Pending Approval, Warranties Expiring This Month, Open Maintenance Activities and Total Assets Value. Choose a number to see the records behind it.
