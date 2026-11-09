# Automatic daily monitoring (AppSource end-user help)

Equipment Management checks your equipment every day without anyone starting it. Two job queue entries do the work: one creates warranty alerts, the other checks for overdue maintenance. The app creates them for you.

## Before you start: permissions
- **Administrator** can create the entries again with **Schedule Monitoring Jobs**.
- **Equipment Reader** and **Equipment Manager** can see the status of the two jobs on Equipment Setup, but cannot create entries. The status is blank if you cannot read job queue entries.
- Changing the time or restarting a job is done on the standard **Job Queue Entries** page and needs the matching job queue permissions.

## What runs
| Job | What it does |
|---|---|
| Warranty Alert Job | Creates warranty alerts at 90, 60 and 30 days before a warranty ends (see Warranty alerts). |
| Overdue Maintenance Job | Counts maintenance records that are still open more than 14 days after their Maintenance Date. It changes no data and sends no notification; the result is only recorded in telemetry. |

Both run once a day at 06:00 and try up to 3 times if they fail. The first run may be the next 06:00 rather than right away.

## When the jobs are created
- When the app is installed in a company.
- When an Administrator opens **Equipment Setup** in a company that has no setup yet.
- When an Administrator chooses **Schedule Monitoring Jobs**.

If a job already exists in the company, it is left as it is, whatever its status. This includes entries you created yourself.

## Check the status
1. Open **Equipment Setup**.
2. Under **Background Monitoring**, read **Warranty Alert Job** and **Overdue Maintenance Job**. They show the job status, for example Ready or Error, or **Not scheduled** when no entry exists.

## Create missing jobs
1. Open **Equipment Setup** as an Administrator.
2. Choose **Schedule Monitoring Jobs**.
3. A message tells you how many jobs were created and how many already existed. Existing jobs are not changed.

Use this if a status shows **Not scheduled**. This can happen in a company that was skipped when the app was installed in several companies at once. If the action fails, you may not be allowed to schedule tasks in this environment; ask your administrator.

## Change the time or restart a job
1. On **Equipment Setup**, choose **Monitoring Job Queue Entries**.
2. Open the entry to see when it ran, change the time, or restart it.

A job in **Error** is not restarted automatically by the app. Restart it from this list after fixing the cause.

## Good to know
- Notifications are still shown only when a user opens a page; the jobs send none.
- The jobs run as the user who created them. If that user is disabled or loses permissions, the jobs fail.
- Removing the app does not delete the job queue entries; delete them on the Job Queue Entries page.
- The **Generate Alerts** action on Warranty Alerts still works as an extra manual run.
- The time of day uses the server's time zone and may differ from yours.

## Release notes
Automated background processing: the app now creates two daily job queue entries by itself, one that creates warranty alerts and one that checks overdue maintenance. Equipment Setup shows the status of both jobs, and the new action Schedule Monitoring Jobs creates missing entries without changing existing ones.
