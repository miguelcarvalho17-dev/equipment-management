# Business Events (AppSource help for developers)

Equipment Management publishes five events so that your own extension can react when equipment is created, assigned or returned, when maintenance is created, and when a warranty expires. The events only notify: they cannot change or skip what Equipment Management does.

TODO(verify): scenario 13 has not been checked in a sandbox (a scheduled warranty job run that raises OnWarrantyExpired). The other 12 scenarios pass as automated tests.

## Before you start
- You need an extension that depends on Equipment Management. Subscribe with `[EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", 'EventName', '', false, false)]`.
- The publishers are internal: you can subscribe, but you cannot raise these events from your own code.
- Equipment Reader, Manager and Administrator can run the code that raises them. TODO(verify): permissions were not checked in a sandbox.

## The events
All parameters are passed by value.

| Event | Parameters | When it is raised |
|---|---|---|
| `OnEquipmentCreated` | `Equipment` | After new equipment is saved. Not raised for data migration inserts or temporary records. |
| `OnEquipmentAssigned` | `Equipment`, `EquipmentAssignment` | When equipment is assigned to an employee. The assignment entry is Active. |
| `OnEquipmentReturned` | `Equipment`, `EquipmentAssignment` | Whenever an active assignment is closed. The entry is Closed. |
| `OnMaintenanceCreated` | `MaintenanceRecord` | After a maintenance record is saved. The equipment is already In Maintenance. Not raised again when the record is changed or posted. |
| `OnWarrantyExpired` | `Equipment` | By the daily warranty job, the day after the Warranty End Date, for equipment that is not Lost or Disposed. |

### Returned: reasons
An assignment is closed, and `OnEquipmentReturned` is raised, when:
- the Return action is used (Equipment.Status Available);
- a maintenance record is registered (In Maintenance);
- the status is set to Lost or Disposed (Lost, Disposed);
- the equipment is assigned again while a leftover Active entry still exists (Assigned). The leftover entry is closed first.

Read `Equipment.Status` to tell which one applies.

## Important: Assigned and Returned run inside a transaction
`OnEquipmentAssigned` and `OnEquipmentReturned` are raised while the equipment is being saved. The assignment entry is written, but the equipment record is not yet, and the whole operation can still fail and be rolled back (on the maintenance path the maintenance record is not stored yet either). So:
- Read the equipment from the event parameter, not from the database.
- Do not `Modify` the equipment in your subscriber.
- Do not make calls that cannot be rolled back, such as HTTP requests or telemetry. Queue them instead (for example, a job queue entry) so they run after the transaction.
- Do not show UI and do not call `Commit`.
- An error in your subscriber stops the operation and the user cannot assign, return or register maintenance. The same applies to the created events.

## OnWarrantyExpired: delivery guarantees
- It is raised by the daily warranty job, for equipment whose Warranty End Date was yesterday. Manual alert generation does not raise it.
- A day the job does not run is lost. The event is not raised later for that equipment.
- If the job runs again the same day, or the job queue entry has Maximum No. of Attempts greater than 1 and retries, the event is raised again for the same equipment. Make your subscriber safe to run twice.
- If your subscriber raises an error, the remaining equipment gets no event that day and the job queue entry goes to Error. The warranty alerts are saved anyway.

## Example
Subscribe to `OnWarrantyExpired` in your extension, read `Equipment."No."` and `Equipment.Description` from the parameter, and queue a notification to your own system. Do not send it directly from the subscriber.

## Good to know
- The event names, parameter lists and the rules above are a frozen public contract from the first AppSource release. Changes will come as new events, with the old ones marked obsolete.
- Further reading: Microsoft Learn, "Events in AL" (subscribing to events).

## Release notes
Business events: partner extensions can now subscribe to five new events in Equipment Management: equipment created, assigned and returned, maintenance created, and warranty expired. The events notify only and cannot change standard behavior. Assigned and returned run inside the save transaction, and the warranty event is raised once a day by the warranty job. The events can be subscribed to but not raised from other extensions.
