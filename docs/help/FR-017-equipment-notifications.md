# Equipment notifications (AppSource end-user help)

Equipment Management shows a notification at the top of a page when something needs your attention: a warranty is about to end, maintenance has been open for too long, or equipment is back from maintenance. Each notification has an action that opens the records to act on.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** see the warranty and maintenance notifications and can use their actions.
- The notification that equipment is back from maintenance appears after you post maintenance, so only **Equipment Manager** and **Administrator** see it.
- Every user can switch notifications off for themselves.

## Warranty is about to end
You see "Warranty for <equipment> <number> will expire in <n> days." (or "tomorrow", "expires today") when you open an **Equipment Card** and:
- the equipment has a **Warranty End Date** that is today or later,
- the equipment is not lost or disposed of, and
- an open warranty alert exists for that end date (see Warranty alerts).

The days shown are the days left today. Choose **Show warranty alerts** to open the open alerts of the equipment. When you acknowledge the alert, the notification no longer appears. Expired warranties are not notified.

The Equipment Manager Role Center and the Equipment Dashboard show a summary, for example "2 warranty alerts are open. Review the warranties that are about to expire." Choose **Show warranty alerts** to open all open alerts.

Alerts only exist after the daily job has run or a manager has chosen **Generate Alerts**. Without alerts, no warranty notification appears.

## Maintenance is overdue
A maintenance record is overdue when it is still **Open** more than 14 days after its **Maintenance Date** (15 days or more). Posted records are never overdue.

- On the **Equipment Card**: "Maintenance <number> for <equipment> <number> has been open for <n> days. Post it when the work is finished." If there are several, the oldest is named. Choose **Show open maintenance** to open the open records of the equipment.
- On the **Maintenance Record Card** of an overdue open record: "Maintenance record <number> has been open for <n> days. Post it when the work is finished." The notice disappears after you post the record.
- On the Role Center and the dashboard: "<n> maintenance records have been open for more than 14 days. Post them when the work is finished." Choose **Show overdue maintenance** to open the overdue records.

To resolve it, post the record when the work is finished. Open maintenance keeps the equipment In Maintenance and blocks assignment.

## Equipment is back from maintenance
When you post the last open maintenance record of equipment that is In Maintenance, the equipment becomes Available and you see "<equipment> <number> is back from maintenance and is available again." Choose **Open equipment card** to open it. You do not see it when other open maintenance records keep the equipment In Maintenance, or when you answer No to the post question. Other users do not see it.

## Switch notifications off
- Choose **Don't show again** on a notification to switch that kind off for you.
- Or open **My Notifications** from your user settings and switch each of **Equipment warranty is expiring**, **Equipment maintenance is overdue** and **Equipment returned from maintenance** on or off.

This only affects your own user. Switching a kind off hides it on all pages (card, Role Center and dashboard).

## Good to know
- Notifications appear only when you open the page; nobody is notified by email or in the background.
- Dates are counted from today's real date, not the work date.
- Notifications do not appear on new, unsaved records.

## Release notes
Equipment notifications: the app now shows a notification when a warranty is about to end (while its warranty alert is open), when a maintenance record has been open for more than 14 days without being posted, and when posting maintenance makes equipment available again. Each notification has an action that opens the matching records, and you can switch each kind off with Don't show again or in My Notifications.
