# FR-051 Error Logging

## Purpose
Records the errors that stop the app's unattended processes (issue #92). An entry gives the time, the user, the process, the object, the error message, the error code and the call stack. Administrators read the entries on the Equipment Error Log page.

Phase 1 covers the two daily monitoring jobs (the warranty alert job and the overdue maintenance job) and the scheduling of those jobs. Errors of interactive actions, API calls, reports and page triggers are not logged yet (see "Not logged in phase 1").

The app's business logic is unchanged. The job bodies are moved into a runner that logs a failure and raises the same error text again.

Status: implemented on branch `feature/FR-051-error-logging`, not committed, not merged. Plan: `docs/plans/FR-051-error-logging.md` (status approved). Target: AppSource.

## What is logged
| Operation | When an entry is written |
|---|---|
| Warranty Alert Job | The daily warranty alert job stops with an error. |
| Overdue Maintenance Job | The daily overdue maintenance job stops with an error. |
| Maintenance Calculation Job | The daily maintenance calculation job (FR-054, 05:00) stops with an error. |
| Schedule Monitoring Jobs | Creating the daily job queue entries stops with an error. This happens in the Schedule Monitoring Jobs action, during install, and when the setup is created. |

Not logged:
- A successful run of a job, and a successful scheduling.
- Scheduling that cannot start because a write transaction is open or the task scheduler cannot create tasks. These send telemetry EQM0004 only, see `docs/features/FR-050-application-telemetry.md`.

## Entry fields
| Field | Content |
|---|---|
| Logged At | The date and time of the error. |
| User ID | The user who ran the process that failed. For a job queue entry, the user that the job runs as. |
| Operation | The process that failed (see the table above). |
| Object ID | The ID of the codeunit that ran the process. Used for support. |
| Error Message | The error text. Longer text is cut to 2,048 characters. |
| Error Code | The classification of the error that the platform returned. Used for support. |
| Error Call Stack | The AL call stack at the moment of the error. Longer text is cut to 2,048 characters. |

A text that is longer than its field is cut and never causes an error. An entry with an empty error message is not written.

## How a failed job is logged
1. The job runs in its own isolated run. When it fails, the job's database changes are rolled back.
2. The error is written to the log in its own transaction. The entry survives the rollback. For how AL logs an error from a rolled-back transaction, see [AL error handling](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling#error-handling-strategies).
3. The job raises the same error text again. The job queue entry ends in state Error with that message, as before.

The job queue entry keeps the same message. It does not keep the original call stack. The call stack is in the Equipment Error Log entry.

If the log entry cannot be written, the original error is still raised unchanged. Nothing else is affected.

## Who can read the log
- EQM - Administrator can read and delete entries.
- EQM - Manager, EQM - Reader and EQM - API Consumer cannot read entries. EQM - Reader can run the new objects, but opening the page gives a permission error.
- No user can insert an entry directly or change one. Entries are written only by the monitoring jobs and the scheduling. The write uses a permission that is part of the app (inherent permission), so a job that runs as a user with only EQM - Reader still writes its entry.
- The Equipment Setup page shows the action Error Log (Navigation) only to users who can read the log.

## Privacy
- The error message can contain data from the records that were processed, for example a number or a field value. The table is classified as customer content. Only administrators can read it.
- User ID is end-user identifiable information (personal data). Entries stay until they are deleted.
- Error Code, Error Call Stack and Object ID are classified as system metadata.

## Retention
- Entries stay until an administrator deletes them, or until a standard retention policy deletes them. Retention policies for this table were added by FR-054 (`docs/features/FR-054-background-processing-optimization.md`); the table has no filter and uses the field Logged At. The app creates no policy by itself.
- The log is per company.

## Not logged in phase 1
- Errors of interactive user actions, API calls, reports and page triggers. Phase 2.
- Errors of a job that starts while a write transaction is already open. The job runs as before: not isolated and not logged. The error is raised unchanged.
- Telemetry for a logged error. Phase 3. EQM0004 is unchanged.

## Not changed (decided)
- No change to the business logic of the jobs or to the telemetry signals EQM0001 to EQM0004.
- No new permission set. EQM - Administrator gets read and delete on the log. EQM - Reader gets execute on the new objects.
- No Role Center action or cue (later phase).

## Verification status
- **Tests**: test codeunits "EQM Error Log Tests" (scenarios E1 to E8), "EQM Error Log Isolation Tests" (scenarios I1 to I3) and the helper "EQM Error Log Test Subscr", plus two new tests in "EQM Role Permission Tests". Written and compiled; not executed locally. Not verified: tests not executed locally, CI result pending.
- **Scheduling failure path**: no automated test covers the case where scheduling fails with reason Error. It is checked only in the sandbox (ER-SB2 in `docs/TODO.md`).
- **Job queue start**: the logging depends on the Job Queue starting the job codeunit outside a write transaction. Not verified in a sandbox until ER-SB1 is run.
- **Sandbox**: not run. See `docs/TODO.md`, section "FR-051 sandbox checks".
- **Review**: APPROVED by al-reviewer. Two MINORs are open (see "Open items").
- **repo_checks.py**: not run by al-docs. The main agent runs it after this change.
- **AppSource validation**: no separate AppSource validation ran. The reviewer checked the change against the plan and the AppSource rules.

## Open items
- Sandbox checks ER-SB1 to ER-SB5 in `docs/TODO.md`.
- Reviewer MINOR, not fixed: the wording of the XML summary of `LogError` (`app/src/ErrorLog/EQMErrorLogMgt.Codeunit.al`).
- Reviewer MINOR, not fixed: no unit test for the scheduling case where a write transaction is open (no entry is expected).

## Related
- Help article: `docs/help/FR-051-error-logging.md`
- Changelog: `CHANGELOG.md`, entry FR-051
- Plan: `docs/plans/FR-051-error-logging.md`
- Monitoring jobs and their telemetry: `docs/features/FR-050-application-telemetry.md` (EQM0003, EQM0004), `docs/features/FR-018-automated-background-processing.md`
- Microsoft Learn: [Use job queues to schedule tasks](https://learn.microsoft.com/dynamics365/business-central/admin-job-queues-schedule-tasks), [AL error handling](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling)
