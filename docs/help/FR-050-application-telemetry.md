# Application telemetry (administrator help)

This article is for the environment administrator. It is not an end-user article. The signals are described in detail in `docs/features/FR-050-application-telemetry.md`.

The app sends a usage signal when equipment is created, assigned or returned, when maintenance is registered and when a warranty expires. The app also sends signals for the warranty alert job and the overdue maintenance check. The signals contain no customer data: no equipment, employee, maintenance or user numbers.

Telemetry is sent only when the environment is set up to send it. Until then, nothing is sent.

## Turn on telemetry for an online environment
You need an Azure Application Insights resource and its connection string first. Then:

1. Open the Business Central admin center and select **Environments**. Select the environment.
2. In the **Telemetry** field, select **Define**, or **Modify** if telemetry is already set up.
3. In the **Logging telemetry** pane, turn on **Enable telemetry**. Enter the **Azure Application Insights Connection String**.
4. Select **Save**. The environment restarts. Plan this for a time when no users are active.

To turn telemetry off, turn off **Enable telemetry** and select **Save**. The restart happens again.

Microsoft describes the steps in [Turn environment telemetry on or off](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/telemetry-enable-application-insights).

## Turn on telemetry for an on-premises environment
- **Single-tenant server:** set the Application Insights connection string on the server instance, then restart the Business Central Server instance.
- **Multitenant server:** set the connection string when you mount the tenant.
- **Diagnostic trace level:** the signals of this app have the level Normal, except EQM0004, which is a warning. If the server's Diagnostic Trace Level is Warning, the Normal signals are not sent. Set the level to Normal or Verbose.

See [Turn environment telemetry on or off](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/telemetry-enable-application-insights) for the commands.

## If no signals arrive
Check these points first:
1. The connection string is the one of the Application Insights resource you expect.
2. Telemetry is turned on in the environment you are looking at.
3. The environment or server was restarted after the change.
4. On-premises only: the trace level (see above), and that no firewall blocks the connection to Application Insights.

## What each signal means
| Signal | Message | What it tells you |
|---|---|---|
| EQM0001 | Warranty alerts generated. | One run of the warranty alert job or a manual run. Shows how many alerts were created and cancelled. |
| EQM0002 | Overdue maintenance checked. | One overdue check. Shows how many maintenance records are overdue and how many days. |
| EQM0003 | Monitoring job queue entries ensured. | The monitoring jobs were checked. Shows how many entries were created and how many already existed, and where the check came from (`Install`, `SetupCreated` or `Action`). |
| EQM0004 | Monitoring job queue entries could not be created. | The jobs could not be created (warning). The **Reason** tells you why: `WriteTransaction` (run the Schedule Monitoring Jobs action in that company), `CannotCreateTask` (check that the job queue can run tasks) or `Error` (the **ErrorCode** shows the error). |
| EQM0005 | Equipment created. | One new equipment record was saved. **EquipmentStatus** is its starting status. |
| EQM0006 | Equipment assigned. | One equipment was assigned to an employee. No other details. |
| EQM0007 | Equipment returned. | One assignment was closed. **EquipmentStatus** shows why: `Available` (returned), `In Maintenance` (maintenance was registered), `Lost` or `Disposed`, or `Assigned` (the equipment was assigned again). **AssignmentDays** is the number of days assigned, when both dates are known. |
| EQM0008 | Maintenance registered. | One new maintenance record was saved. **MaintenanceType** shows its type. Posting the record sends no signal. |
| EQM0009 | Warranty expired. | The warranty of one equipment ended the day before. The daily job sends it, once for each equipment. |

Read the signals with the sample queries in `docs/features/FR-050-application-telemetry.md`.

## Things to know
- **Counts can be a little high.** A signal is sent when the action runs, before the save is complete. If the save fails after that, the signal stays. Use the app's history and audit trail for exact figures.
- **A zero for EQM0009 does not prove that no warranty expired.** The signal comes from the daily job only. A day when the job did not run is missed.
- **Telemetry is not an audit trail.** Use the equipment audit trail in the app for changes.
- **There is no switch in the app for these signals.** To stop them, turn telemetry off for the environment (see above).

## Related
- Feature doc: `docs/features/FR-050-application-telemetry.md`
- Changelog: `CHANGELOG.md`, entry FR-050
- Microsoft Learn: [Monitoring and analyzing telemetry](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/telemetry-overview), [Telemetry event IDs in Application Insights](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/telemetry-event-ids)
