# Equipment error log (administrator help)

This article is for the environment administrator. The design of the log is described in `docs/features/FR-051-error-logging.md`.

The equipment error log lists the errors that stopped the daily monitoring jobs of the app and the scheduling of those jobs. Each entry tells you when the error happened, which process failed, the error message and the user.

## Open the error log
- Open **Equipment Setup**, and then choose **Navigation** > **Error Log**.
- Or use Tell Me and search for **Equipment Error Log**.

The action on Equipment Setup is shown only to users who can read the log, in practice the users with EQM - Administrator. If you open the page without read permission, Business Central shows a permission error.

## What an entry shows
| Field | What it tells you |
|---|---|
| Logged At | The date and time of the error. |
| Operation | The process that failed: **Warranty Alert Job**, **Overdue Maintenance Job** or **Schedule Monitoring Jobs**. |
| Error Message | The error text. |
| User ID | The user who ran the process. For a job queue entry, this is the user that the job runs as. |
| Object ID | The ID of the codeunit that ran the process. Give it to support. |
| Error Code | The classification of the error. Give it to support. |
| Error Call Stack | The AL call stack at the moment of the error. Give it to support. |

Select an entry and choose **Show Details** to read the full error message and the call stack.

## Find the call stack of a failed job
When a monitoring job fails, the job queue entry ends in the state **Error** and shows the same error message as before. The job queue entry does not keep the original call stack. To find where the error came from, open the **Equipment Error Log** and look at the entry's call stack. Use the Operation and the Logged At value to find the entry.

For how to find and restart a job queue entry, see [Use job queues to schedule tasks](https://learn.microsoft.com/dynamics365/business-central/admin-job-queues-schedule-tasks).

## Privacy
- The error message can contain data from the records that the job or the scheduling processed. Check the message before you copy or share it.
- The User ID is personal data.
- Only EQM - Administrator can read and delete entries. No user can change an entry.
- Entries stay in the log until you delete them. Delete them when you no longer need them, for example when a person asks for their data to be removed.

## What is not logged
- Successful runs of the jobs.
- Errors of pages, actions, reports and API calls. They are not logged in this version.
- Errors of a job that starts while a write transaction is already open. The job fails as before, and no entry is written.
- Scheduling that cannot start because a transaction is open or the job queue cannot create tasks. No entry is written. The telemetry signal EQM0004 shows the reason, see `docs/help/FR-050-application-telemetry.md`.
- If the log entry itself cannot be written, the job still fails with its original error. No other error is shown.

## Delete entries
- Open the Equipment Error Log, select the entries to remove, and delete them.
- The log has no automatic cleanup. Entries stay until someone deletes them.

## Things to know
- The log is per company. Entries in one company are not shown in another company.
- The log is not an audit trail. Use the equipment audit trail for changes to equipment and assignments.

## Related
- Feature doc: `docs/features/FR-051-error-logging.md`
- Changelog: `CHANGELOG.md`, entry FR-051
- Microsoft Learn: [Use job queues to schedule tasks](https://learn.microsoft.com/dynamics365/business-central/admin-job-queues-schedule-tasks)
