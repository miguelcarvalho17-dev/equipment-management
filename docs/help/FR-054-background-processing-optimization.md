# Background processing and retention policies (administrator help)

This article is for the environment administrator. The design is described in `docs/features/FR-054-background-processing-optimization.md`.

TODO(verify): the retention setup and the job user rules below are not tested in a sandbox yet. The checks are in `docs/TODO.md`, section "FR-054 sandbox checks".

## Daily jobs
The app runs three daily job queue entries in category EQM:

| Job | Time | What it does |
|---|---|---|
| Warranty Alert Job | 06:00 | Creates warranty alerts. |
| Overdue Maintenance Job | 06:00 | Counts maintenance records that are still open too long. Changes no data. |
| Maintenance Calculation Job | 05:00 | Corrects the stored next maintenance date of the equipment. Runs only when Maintenance Planning is on. |

The Maintenance Calculation Job corrects only dates that are out of date. It does not send notifications and does not change equipment that is Lost or Disposed. If it fails, the error is written to the Equipment Error Log with the operation Maintenance Calculation Job.

## Create the missing job
1. Open **Equipment Setup** as an Administrator.
2. Choose **Schedule Monitoring Jobs**. The message shows how many jobs were created. Existing jobs are not changed, so the two 06:00 jobs stay as they are.
3. Under **Background Monitoring**, check **Maintenance Calculation Job**. It is shown only when Maintenance Planning is on.

## Delete old log entries with retention policies
The app can delete old entries from three tables automatically. This uses the standard Business Central retention policies. Deleted entries are not archived.

Nothing is deleted until you create a policy and turn it on.

| Table | What the locked filter keeps |
|---|---|
| EQM Error Log Entry (Equipment Error Log) | No filter. Any entry can be deleted after its period. |
| EQM Warranty Alert | Open alerts are kept. Only alerts that are acknowledged or cancelled can be deleted, after one year at least. |
| EQM Integration Event Entry | Unprocessed entries are kept. Only processed entries can be deleted, after three months at least. |

The app never adds audit trail, maintenance log, maintenance history, notes or assignment entries to a policy.

### Before you start: who can define and run policies
- To define policies, you need **SUPER**, or the standard **Retention Policy Setup** permission set. The app does not give it to any role.
- The retention job deletes data, so it must run as a user that can read and delete the three tables. Use a SUPER user, or a user with delete permission on all three tables.
- **EQM - Administrator** can delete the error log and the integration event entries, but it has no direct delete permission on warranty alerts. A retention job that runs as a non-SUPER EQM - Administrator fails on the warranty alert table.
- Check the **User ID** of the retention job queue entry on the **Job Queue Entries** page.

### Set up a policy for each table
1. Use Tell Me (or the search) to open **Retention Policies**.
2. Choose **New**.
3. In **Table ID**, choose the table: **EQM Error Log Entry**, **EQM Warranty Alert** or **EQM Integration Event Entry**.
4. In **Retention Period**, choose how long to keep the entries. For the error log, you can leave the filter empty and choose **Apply to all records**.
5. For warranty alerts and integration event entries, keep the locked filter line. Each line has its own period, and the longest period of the matching records applies, so a shorter period cannot remove the locked filter's period.
6. Turn the policy on. All policies share one job queue entry, which runs every day at 02:00 by default. Choose **Apply Manually** to run a policy at once.
7. Open the **Retention Policy Log** to check the runs and any errors.

Learn: [Define retention policies](https://learn.microsoft.com/dynamics365/business-central/admin-data-retention-policies).

### What to know
- Deleting cannot be undone. Make a copy of the data first if you need it later.
- The locked filter lines cannot be removed. Turning on **Apply to all records** does not remove them.
- If a table is not offered when you create a policy, the app has not registered it in this company yet. The registration runs at the next install or upgrade. Companies created after the install may need the next upgrade.
- If the allowed table list is refreshed, the three tables may need the next upgrade to come back (not verified).

## Maintenance calculation: a job user without permission
The Maintenance Calculation Job runs as the user of its job queue entry. That user must be able to read and change equipment. A user with only **EQM - Reader** cannot change the next maintenance date. The job then stops at the first stale record, the job queue entry shows **Error**, and the Equipment Error Log shows the failure with the operation Maintenance Calculation Job.

To fix it, give the job user permission to change equipment, or run the job as SUPER. Then restart the entry from **Monitoring Job Queue Entries**.

## Good to know
- Restarting a job in **Error** is still done by hand from **Monitoring Job Queue Entries**.
- The times use the server's time zone and may differ from yours.
- The Equipment Error Log is described in the help article `docs/help/FR-051-error-logging.md`.

## Release notes
Equipment Management now has a third daily job that corrects the planned maintenance dates every morning at 05:00. Administrators can also delete old entries automatically with retention policies for the equipment error log, closed warranty alerts and processed integration event entries. Nothing is deleted until a policy is created and turned on.
