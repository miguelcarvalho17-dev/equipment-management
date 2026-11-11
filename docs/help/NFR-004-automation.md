# Automatic monitoring (AppSource end-user help)

Equipment Management checks warranties and overdue maintenance every day without anyone starting it. It uses the standard Business Central job queue. The details are in the help article for automated background processing.

## Where to see the jobs
1. Open **Equipment Setup**.
2. Under **Background Monitoring**, read **Warranty Alert Job** and **Overdue Maintenance Job**. They show the job status, or **Not scheduled** when no entry exists.
3. Choose **Monitoring Job Queue Entries** to open the two entries on the standard Job Queue Entries page.

## If a job is On Hold or in Error
The app does not restart or change an existing job, and nothing alerts you when a job stops. Check the status from time to time.
1. On **Equipment Setup**, choose **Monitoring Job Queue Entries**.
2. Open the entry, fix the cause (for example the user who owns the job was disabled), and restart it. This needs the matching job queue permissions.

## If a job is Not scheduled
As an Administrator, choose **Schedule Monitoring Jobs** on **Equipment Setup**. Missing jobs are created; existing jobs are not changed.

## Release notes
Automation: the daily monitoring of warranties and overdue maintenance runs through Business Central job queue entries that the app creates by itself. This version adds documentation only; there is no change in behavior.
