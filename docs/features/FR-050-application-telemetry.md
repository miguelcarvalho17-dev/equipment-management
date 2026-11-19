# FR-050 Application Telemetry

## Purpose
Sends a usage signal to the environment's Application Insights when equipment is created, assigned or returned, when maintenance is registered and when a warranty expires (issue #91). The signals show how the application is used. They are not a record of the business data, and they change no business logic.

The app has nine telemetry event IDs in total. EQM0001 to EQM0004 were added earlier (FR-016 and FR-018). FR-050 adds EQM0005 to EQM0009.

Status: implemented on branch `feature/FR-050-application-telemetry`, not committed, not merged. Plan: `docs/plans/FR-050-application-telemetry.md` (status approved). Target: AppSource.

## Signal catalog
All signals use `Verbosity::Normal` (except EQM0004, which is a warning), `DataClassification::SystemMetadata` and `TelemetryScope::All`. Each signal is sent once per event.

| ID | Message | When it is sent | Dimensions | Verbosity |
|---|---|---|---|---|
| EQM0001 | Warranty alerts generated. | Each run of warranty alert generation, from the daily warranty job or a manual run. | AlertsCreated, AlertsCancelled, ReferenceDate, Trigger (`JobQueue` or `Manual`) | Normal |
| EQM0002 | Overdue maintenance checked. | Each overdue maintenance check, from the daily job or a manual check. | OverdueCount, OverdueDays, ReferenceDate, Trigger (`JobQueue` or `Manual`) | Normal |
| EQM0003 | Monitoring job queue entries ensured. | When the monitoring job queue entries are checked or created. | Created, Existing, Trigger (`Install`, `SetupCreated` or `Action`) | Normal |
| EQM0004 | Monitoring job queue entries could not be created. | When the monitoring job queue entries cannot be created. | Trigger, Reason (`WriteTransaction`, `CannotCreateTask` or `Error`), ErrorCode (for `Error` only) | Warning |
| EQM0005 | Equipment created. | Each new equipment record that is saved. Not when the insert fails. | EquipmentStatus | Normal |
| EQM0006 | Equipment assigned. | Each successful assignment of equipment to an employee. Not when the assignment fails. | none | Normal |
| EQM0007 | Equipment returned. | Each time an active assignment closes: the Return action, registering maintenance, setting the status to Lost or Disposed, or a new assignment. Not when the return is cancelled. | EquipmentStatus, AssignmentDays (only when both dates are set and the closing date is not before the assignment date) | Normal |
| EQM0008 | Maintenance registered. | Each new maintenance record that is saved. Posting is not signalled. Changes to an open record are not signalled. | MaintenanceType | Normal |
| EQM0009 | Warranty expired. | Once for each equipment whose warranty ended the day before, when the daily warranty job runs. Manual alert generation does not send it. | EquipmentStatus | Normal |

Dimension values:
- **EquipmentStatus**: the AL name of the status, for example `Available`, `Assigned`, `In Maintenance`, `Disposed` or `Lost`. The name does not depend on the user's language. If a value has no name, the number is sent.
- **MaintenanceType**: the AL name of the type: `Preventive`, `Corrective`, `Inspection` or `Upgrade`.
- **AssignmentDays**: whole days from the assignment date to the closing date, for example `0` or `14`.

Volume: a bulk creation of equipment sends one EQM0005 for each record. No limit is set in this phase.

## Privacy statement
- The signals carry no customer content. No equipment number, description, serial number, employee number, category code, maintenance number, maintenance description, or user ID is sent.
- The dimensions are enum value names, maintenance type names, day counts, counts and dates, and trigger names (`JobQueue`, `Manual`, `Install`, `SetupCreated`, `Action`).
- The signals go only to the Application Insights resource that the environment administrator sets up. The app sets no connection string in `app.json`, so no signal goes to a publisher account.
- The data classification is `SystemMetadata`. Business Central sends only signals with a system or organization classification to Application Insights. See [Creating custom telemetry events](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-instrument-application-for-telemetry-app-insights#conditions-on-when-events-are-sent).

## Counts can be slightly high
A signal is sent when the event is raised, which is inside the save transaction. The save can still fail after the signal is sent. The transaction is then rolled back, but the telemetry is not. The signal stays, and no record is saved.

This affects every signal raised during a save:
- EQM0006 and EQM0007 are raised before the equipment row is written.
- EQM0005 and EQM0008 are raised after the insert, before the commit.

So the counts can be a little higher than the number of records that were saved. Telemetry shows usage trends. For exact numbers, use the business data: the assignment history, the maintenance history and the equipment audit trail (FR-035).

## Sample KQL
Business Central sends the event ID with an `AL` prefix and the dimension names with an `al` prefix (see [Telemetry event IDs in Application Insights](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/telemetry-event-ids)). Signals from this app are `ALEQM0001` to `ALEQM0009`.

All signals of this app per day:

```kql
traces
| where timestamp > ago(30d)
| where customDimensions.eventId startswith "ALEQM"
| summarize Count = count() by EventId = tostring(customDimensions.eventId), Day = bin(timestamp, 1d)
| order by Day desc, EventId asc
```

Returns per equipment status, with the average number of days assigned:

```kql
traces
| where timestamp > ago(30d)
| where customDimensions.eventId == "ALEQM0007"
| summarize Returns = count(), AverageDays = avg(todouble(customDimensions.alAssignmentDays)) by EquipmentStatus = tostring(customDimensions.alEquipmentStatus)
| order by Returns desc
```

The KQL has not been run against a workspace yet (see Verification status).

## Permissions
- The permission set EQM - Reader grants execute on the two telemetry codeunits. EQM - API Consumer grants the same. EQM - Manager and EQM - Administrator inherit it from Reader.
- No new permission set. No user needs more than the existing EQM permission sets to produce the signals.

## Not changed (decided)
- EQM0001 to EQM0004 keep their own codeunits. They are not moved.
- No feature switch (FR-042). Turning signals on or off is done by the environment administrator (see the help article).
- No telemetry for maintenance posting, requests, approvals, API calls, errors (FR-051) or usage analytics (FR-052).
- The five business events (FR-029) are unchanged. They are the source of the signals. The FR-029 help article advises partners not to send telemetry from event subscribers and to queue it instead. FR-050 sends the signal inside the transaction on purpose (see "Counts can be slightly high").

## Verification status
- **Tests**: test codeunits "EQM Telemetry Tests" and "EQM Telemetry Test Subscr" cover the scenarios in the plan (positive and negative cases, and the privacy check). Written; not executed locally. Not verified: tests not executed locally, CI result pending.
- **Telemetry delivery**: not testable locally or in CI. Not verified until a sandbox check (see `docs/TODO.md`, section "FR-050 checks").
- **KQL**: not run against a workspace. The `al` and `ALEQM` prefixes come from Microsoft Learn, not from a sandbox.
- **Review**: APPROVED by al-reviewer.
- **repo_checks.py**: not run by al-docs. The main agent runs it after this change.
- **AppSource validation**: no separate AppSource validation ran. The reviewer checked the change against the plan and the AppSource rules.

## Open items
- Sandbox check: with environment telemetry on, each action once, and the query in `docs/TODO.md` shows one row per action with the dimensions above.
- Decision for the user: the FR-029 help article and the doc comment on the business events advise against telemetry in event subscribers. FR-050 does the opposite (see DECISIONS in the plan). Accept as is, or add a one-line clarification to those docs.

## Related
- Help article: `docs/help/FR-050-application-telemetry.md`
- Changelog: `CHANGELOG.md`, entry FR-050
- Plan: `docs/plans/FR-050-application-telemetry.md`
- Earlier signals: `docs/features/FR-016-warranty-alerts.md` (EQM0001), `docs/features/FR-018-automated-background-processing.md` (EQM0002 to EQM0004)
- Business events: `docs/features/FR-029-business-events.md`
- Microsoft Learn: [Monitoring and analyzing telemetry](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/telemetry-overview), [Telemetry event IDs in Application Insights](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/telemetry-event-ids), [Creating custom telemetry events for Application Insights](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-instrument-application-for-telemetry-app-insights), [Session.LogMessage method](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-logmessage-string-string-verbosity-dataclassification-telemetryscope-dictionary%5btext,text%5d-method)
