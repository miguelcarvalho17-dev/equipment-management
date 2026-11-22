# Notifications and monitoring

This article explains the in-app notifications, the daily monitoring jobs, the equipment error log and the retention policies for old entries. The first part is for all users. The rest is for administrators.

**In this article**
- [Notifications](#notifications)
- [Switch notifications off](#switch-notifications-off)
- [The daily jobs](#the-daily-jobs)
- [Check the job status](#check-the-job-status)
- [Schedule missing jobs](#schedule-missing-jobs)
- [Change the time or restart a job](#change-the-time-or-restart-a-job)
- [The equipment error log](#the-equipment-error-log)
- [Retention policies](#retention-policies)

## Notifications

Equipment Management shows a notification at the top of a page when something needs your attention. Each notification has an action that opens the records to act on. Notifications appear only when you open the page. Nobody gets an email, and the daily jobs send none.

| Notification | When you see it |
|---|---|
| Warranty is about to end | You open an equipment card, the warranty end date is today or later, the equipment is not lost or disposed, and an open warranty alert exists for that date. Choose **Show warranty alerts**. When you acknowledge the alert, the notification no longer appears. |
| Maintenance is overdue | A maintenance record is still Open 15 or more days after its maintenance date. You see it on the equipment card, on the maintenance record card, and as a summary on the role center and the dashboard. Choose **Show open maintenance** or **Show overdue maintenance**. |
| Equipment is back from maintenance | You post the last open maintenance record of equipment that is In Maintenance, and the equipment becomes Available. Choose **Open equipment card**. Only the user who posted sees it. |

The role center and the dashboard also show a summary of open warranty alerts. The dates are counted from today's real date, not the work date. Notifications do not appear on new, unsaved records. Overdue planned maintenance is not a notification. It is a red date. See [Maintenance](maintenance.md).

## Switch notifications off

- Choose **Don't show again** on a notification to switch that kind off for you.
- Or open **My Notifications** from your user settings, and switch each of **Equipment warranty is expiring**, **Equipment maintenance is overdue** and **Equipment returned from maintenance** on or off.

This affects only your own user. An administrator can turn off all equipment notifications for the company with **Enable Notifications** on **Equipment Setup**.

## The daily jobs

The app checks your equipment every day, without anyone starting it. It uses the standard job queue, in the category EQM.

| Job | Time | What it does |
|---|---|---|
| **Warranty Alert Job** | 06:00 | Creates warranty alerts 90, 60 and 30 days before a warranty ends. |
| **Overdue Maintenance Job** | 06:00 | Counts maintenance records that are open more than 14 days after the maintenance date. It changes no data and sends no notification. |
| **Maintenance Calculation Job** | 05:00 | Corrects the stored next maintenance date. It runs only when the Maintenance Planning feature is on. It does not change lost or disposed equipment. |

The two 06:00 jobs retry up to 3 times when they fail. The times use the server's time zone and may differ from yours. TODO(verify): the retention setup and the job user rules are not checked in a sandbox.

The jobs are created:

- when the app is installed in a company,
- when an administrator opens **Equipment Setup** in a company that has no setup, and
- when an administrator chooses **Schedule Monitoring Jobs**.

An existing job is left as it is, whatever its status. The jobs run as the user who created them. If that user is disabled or loses permissions, the jobs fail. The Maintenance Calculation Job needs a user who can read and change equipment. A user with only the Equipment Reader permission set cannot change the next maintenance date, and the job stops with an error.

## Check the job status

1. Open **Equipment Setup**.
2. Under **Background Monitoring**, read **Warranty Alert Job**, **Overdue Maintenance Job** and **Maintenance Calculation Job**.

They show the job status, for example Ready or Error, or **Not scheduled** when no entry exists. The status is blank when you cannot read job queue entries. Nothing alerts you when a job stops, so check the status from time to time.

## Schedule missing jobs

1. Open **Equipment Setup** as an administrator.
2. Choose **Schedule Monitoring Jobs**.
3. A message tells you how many jobs were created and how many already existed.

Existing jobs are not changed. If the action fails, you may not be allowed to schedule tasks in this environment. Ask your administrator.

## Change the time or restart a job

1. On **Equipment Setup**, choose **Monitoring Job Queue Entries**.
2. Open the entry to see when it ran, change the time, or restart it.

A job in **Error** is not restarted by the app. Fix the cause, and restart it from this list. This needs the matching job queue permissions. See [Use job queues to schedule tasks](https://learn.microsoft.com/dynamics365/business-central/admin-job-queues-schedule-tasks).

## The equipment error log

The equipment error log lists the errors that stopped the daily jobs and the scheduling of those jobs.

1. Open **Equipment Setup**, and choose **Error Log**. Or choose the search icon, enter **Equipment Error Log**, and choose the related link.
2. Select an entry, and choose **Show Details** to read the full message and the call stack.

| Field | What it tells you |
|---|---|
| **Logged At** | The date and time of the error. |
| **Operation** | The process that failed: Warranty Alert Job, Overdue Maintenance Job, Maintenance Calculation Job or Schedule Monitoring Jobs. |
| **Error Message** | The error text. |
| **User ID** | The user who ran the process. |
| **Object ID**, **Error Code**, **Error Call Stack** | Technical details to give to support. |

Only users with the Equipment Administrator permission set can read and delete entries. No user can change an entry. The log is per company. The error message can contain data from the records that the job processed, so check it before you share it. The log does not list successful runs or errors of pages, actions, reports and API calls. Entries stay until you delete them, or a retention policy deletes them.

## Retention policies

The app can delete old entries from three tables with the standard Business Central retention policies. Nothing is deleted until you create a policy and turn it on. Deleted entries are not archived.

| Table | What is kept |
|---|---|
| Equipment error log | Nothing is protected. Any entry can be deleted after its period. |
| Warranty alerts | Open alerts are kept. Acknowledged and cancelled alerts can be deleted after at least one year. |
| Integration event entries | Unprocessed entries are kept. Processed entries can be deleted after at least three months. |

The app never adds the audit trail, the maintenance log, the maintenance history, notes or assignments to a policy.

1. Choose the search icon, enter **Retention Policies**, and choose the related link.
2. Choose **New**.
3. In **Table ID**, choose the table.
4. In **Retention Period**, choose how long to keep the entries.
5. Turn the policy on. All policies share one job queue entry, which runs every day at 02:00 by default.
6. Open the **Retention Policy Log** to check the runs.

To define policies you need the SUPER permission set or the standard **Retention Policy Setup** permission set. The retention job must run as a user that can read and delete the three tables, for example a SUPER user. The Equipment Administrator permission set cannot delete warranty alerts directly, so a retention job that runs as that user fails on the warranty alert table. See [Define retention policies](https://learn.microsoft.com/dynamics365/business-central/admin-data-retention-policies).

## What to know

- Removing the app does not delete the job queue entries. Delete them on the **Job Queue Entries** page.
- A company that the install skipped, for example when the app is installed in several companies at once, can show **Not scheduled**.
- A turned-off Warranty Alerts feature stops the warranty notifications and new alerts.
- Deleting entries cannot be undone.

## Related

- [Warranty](warranty.md)
- [Maintenance](maintenance.md)
- [Setup and configuration](setup-and-configuration.md)
- Feature article: [Equipment notifications](../help/FR-017-equipment-notifications.md)
- Feature article: [Automatic daily monitoring](../help/FR-018-automated-background-processing.md)
- Feature article: [Automatic monitoring](../help/NFR-004-automation.md)
- Feature article: [Equipment error log](../help/FR-051-error-logging.md)
- Feature article: [Background processing and retention policies](../help/FR-054-background-processing-optimization.md)
- Learn: [Use job queues to schedule tasks](https://learn.microsoft.com/dynamics365/business-central/admin-job-queues-schedule-tasks)
- Learn: [Define retention policies](https://learn.microsoft.com/dynamics365/business-central/admin-data-retention-policies)

---
Previous: [Reports](reports.md) | Next: [Audit and change tracking](audit-and-change-tracking.md)
