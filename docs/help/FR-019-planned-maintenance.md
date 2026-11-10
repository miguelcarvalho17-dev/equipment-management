# Planned maintenance (AppSource end-user help)

Plan recurring maintenance for each piece of equipment. Enter how often it must be maintained and when it was last maintained, and the app calculates when the next maintenance is due.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** can see the planned maintenance fields.
- Entering or changing **Last Maintenance Date** and **Maintenance Frequency (Months)** needs **Equipment Manager** or **Administrator**. A Reader cannot change them.
- Posting maintenance, which can update the dates, needs **Equipment Manager** or **Administrator**.

## Set up the plan
1. Open the **Equipment Card**. Planned maintenance has its own section, **Planned Maintenance**, after Warranty.
2. In **Maintenance Frequency (Months)**, enter how many months pass between maintenance, for example 6 for every six months. You can enter 0 to 120. Leave it blank if the equipment has no planned maintenance.
3. In **Last Maintenance Date**, enter the date the equipment was last maintained. It cannot be later than today.

**Next Maintenance Date** is calculated and cannot be edited. It is the last maintenance date plus the frequency. For example, last maintenance 1 January 2026 with a frequency of 6 months gives a next maintenance date of 1 July 2026. It is blank when either field is blank. The Purchase Date is not used when the last maintenance date is blank.

If the last date falls at the end of a longer month, the next date is expected to be the last day of the shorter month (31 August 2026 plus 6 months is 28 February 2027). TODO(verify): not checked in a sandbox.

If you enter a last maintenance date in the future, you get an error that shows both dates; enter today's date or an earlier one. You may change the date to an earlier one by hand.

## Posting maintenance updates the plan
When you post a maintenance record of type **Preventive**, **Last Maintenance Date** becomes the record's Maintenance Date and the next date is recalculated, but only if the record's date is later than the current last maintenance date (or the last date is blank). The date never moves backwards through posting.

- Corrective, Inspection and Upgrade records do not change the plan.
- Registering a record without posting it changes nothing.
- This also applies to lost and disposed equipment.

## Find equipment that is due
On the **Equipment** list, **Next Maintenance Date** is shown. Set a filter on it with a date range, for example 1 July 2026 to 31 July 2026, to see the equipment due in that month. A filter with only an upper limit may also list equipment without a plan, because blank dates are included. TODO(verify): not checked in a sandbox.

**Last Maintenance Date** and **Maintenance Frequency (Months)** are hidden in the list; show them through personalization.

The Maintenance FactBox shows **Next Maintenance Date**. Its two other date and type fields are now called **Latest Record Date** and **Latest Record Type**: they show the most recent maintenance record of any type, open or posted, and are not the same as the planned last maintenance date.

Equipment whose next maintenance date is before today is shown in red and counted on a dashboard tile; see Overdue maintenance monitoring. The app sends no alert for planned maintenance.

## Release notes
Planned Maintenance: on the Equipment Card you can now enter a maintenance frequency in months and the date of the last maintenance, and the app calculates the next maintenance date. Posting a Preventive maintenance record moves the last maintenance date forward automatically. The Equipment list shows the next maintenance date, so you can filter for equipment that is due in a period. In the Maintenance FactBox, the fields for the most recent record are renamed Latest Record Date and Latest Record Type, and the next maintenance date is added.
