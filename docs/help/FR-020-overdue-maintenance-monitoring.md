# Overdue maintenance monitoring (AppSource end-user help)

See at a glance which equipment has missed its planned maintenance. The next maintenance date turns red, and a tile on the dashboard counts the overdue equipment.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** can see the red date and the tile, and open the equipment behind the tile.
- Clearing an overdue status (changing the plan or posting maintenance) needs **Equipment Manager** or **Administrator**.

## When is equipment overdue?
Equipment is overdue when its **Next Maintenance Date** is before today. See Planned Maintenance for how that date is calculated.
- Due today is not overdue. Equipment becomes overdue the day after its next maintenance date.
- Today means the real calendar date, not your work date.
- Equipment without a next maintenance date is never overdue.
- Lost and disposed equipment is never overdue: it is not highlighted and not counted.
- Equipment that is assigned or in maintenance can be overdue.

## Where you see it
- **Equipment** list, **Equipment Card** (section Planned Maintenance) and the **Maintenance FactBox**: the **Next Maintenance Date** is shown in red when the maintenance is overdue. On the card, the date changes colour as soon as you change the last maintenance date, the frequency or the status.
- **Equipment Dashboard** and the Role Center: the tile **Overdue Maintenance Equipment**, in the group **Planned Maintenance**, shows how many pieces of equipment are overdue. It is red when at least one is overdue and green when none is. Choose **Refresh** on the dashboard to update it. TODO(verify): colours and placement not checked in a sandbox.
- Choose the tile number to open the **Equipment** list with only the overdue equipment. TODO(verify): which filters the filter pane shows.

## Clear an overdue status
- Post a **Preventive** maintenance record with a date later than the last maintenance date. The last and next dates move forward (see Planned Maintenance).
- Or change **Last Maintenance Date** or **Maintenance Frequency (Months)** on the Equipment Card so the next date is today or later. A frequency of 0 clears the plan.
- Setting the equipment to **Disposed** or **Lost** also removes the highlight.

Being overdue does not block anything: you can still assign, return and maintain the equipment.

## Good to know
- To find overdue equipment, use the tile. A list filter on Next Maintenance Date with only an upper limit can also show equipment without a date and lost or disposed equipment.
- This is not the same as the notification **Equipment maintenance is overdue**, which refers to a maintenance record that has been open for more than 14 days.
- The app sends no notification for overdue planned maintenance.
- A dashboard left open past midnight keeps the previous day's count until you reopen it.

## Release notes
Overdue Maintenance Monitoring: equipment whose next maintenance date is before today is now highlighted. The next maintenance date is shown in red on the Equipment list, the Equipment Card and the Maintenance FactBox, and a new tile, Overdue Maintenance Equipment, on the dashboard and Role Center counts the overdue equipment and opens the list of it. Lost and disposed equipment and equipment without a next maintenance date are not counted.
