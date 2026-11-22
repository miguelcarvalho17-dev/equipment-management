# Events

> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-060-developer-documentation; nothing is verified in a Business Central sandbox.

Partner extensions can react to Equipment Management through AL events. This page lists every published event with its signature copied from `app/src`: five business events, nineteen process hooks and two external business events for Power Automate. Once the app is released these signatures never change.

**In this article**
- [Event types used](#event-types-used)
- [Business events for partners](#business-events-for-partners)
- [Process hooks (IsHandled and validation events)](#process-hooks-ishandled-and-validation-events)
- [External business events (Power Automate)](#external-business-events-power-automate)
- [Contract rules](#contract-rules)
- [Example subscriber](#example-subscriber)
- [Related](#related)

## Event types used

| Type | Attribute | Use here |
|---|---|---|
| Integration event | `[IntegrationEvent(false, false)]` | All AL events below: the business events and the process hooks. The sender and global variables are not exposed. |
| External business event | `[ExternalBusinessEvent(...)]` | Two events for Power Automate. Delivered by the platform after the transaction commits. |
| Internal event | `[InternalEvent(false)]` | Two events for the test app only (`OnBeforeRunMonitoringJob` in codeunit 50143 and `OnAfterLogUsageTelemetry` in codeunit 50140). Not public API; they are not listed below. |

A publisher that is a `local procedure` can still be subscribed to from other objects and apps ([Publishing events](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-publishing-events)). Subscribers are not run unless the event is raised.

## Business events for partners

Codeunit 50119 `EQM Business Events`, `Access = Public`. The events only notify: they are raised after the fact and cannot change or skip the standard logic. There is no `IsHandled` and there are no `var` parameters. The publishers are `internal procedure`: **partners can subscribe but cannot raise them**. TODO(verify): FR-029 states that a partner extension can subscribe to an `internal` integration event publisher; no second app has confirmed it (the test app uses `internalsVisibleTo`).

Source: `app/src/BusinessEvents/EQMBusinessEvents.Codeunit.al`. Details: [FR-029](../features/FR-029-business-events.md).

| Event | Signature | Raised when | Transaction notes |
|---|---|---|---|
| `OnEquipmentCreated` | `internal procedure OnEquipmentCreated(Equipment: Record "EQM Equipment")` | After new equipment is inserted with `Insert(true)`. Not for temporary records or `Insert(false)`. | The record is stored. In the caller's transaction. |
| `OnEquipmentAssigned` | `internal procedure OnEquipmentAssigned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")` | Right after the active assignment entry is inserted. | The assignment entry is written, the equipment row is not yet; the operation can still roll back. Read the equipment from the parameter, do not `Modify` it, queue non-transactional calls. |
| `OnEquipmentReturned` | `internal procedure OnEquipmentReturned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")` | Whenever an active assignment is closed: return action, registering maintenance, status Lost or Disposed, or a new assignment closing a leftover entry. `Equipment.Status` shows the reason. | Same as assigned. On the maintenance path it is raised inside the Maintenance Record insert, before that record is stored. |
| `OnMaintenanceCreated` | `internal procedure OnMaintenanceCreated(MaintenanceRecord: Record "EQM Maintenance Record")` | After a maintenance record is inserted with `Insert(true)`. Not for temporary records or `Insert(false)`. | The record is stored and the equipment is already In Maintenance. |
| `OnWarrantyExpired` | `internal procedure OnWarrantyExpired(Equipment: Record "EQM Equipment")` | By the daily warranty job, for equipment whose warranty ended yesterday and whose status is not final. Not by manual alert generation. | Job queue session; the job commits the alerts first. A day the job does not run is missed. The event can be raised again if the job runs again the same day. |

Records are passed by value. An error in a subscriber stops the operation that raised the event, except for `OnWarrantyExpired`, where it stops the remaining equipment and puts the job queue entry in error (the alerts are already saved).

## Process hooks (IsHandled and validation events)

Every other `[IntegrationEvent(false, false)]` publisher in `app/src`. The publishers are `local procedure` declarations inside public objects (tables 50100, 50105 and 50111, codeunits 50106, 50109 and 50132). A hook with `var IsHandled` lets a subscriber replace or skip the standard check; set it only in a deliberate extension. The feature doc column links the document that introduced the event.

| Publisher object | Event | Signature | IsHandled | Feature doc |
|---|---|---|---|---|
| EQM Equipment 50100 | `OnBeforeCheckCategoryIsActive` | `local procedure OnBeforeCheckCategoryIsActive(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)` | Yes | [FR-002](../features/FR-002-equipment-categories.md) |
| EQM Equipment 50100 | `OnBeforeCheckSerialNoIsUnique` | `local procedure OnBeforeCheckSerialNoIsUnique(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)` | Yes | [FR-001](../features/FR-001-equipment-registration.md) |
| EQM Equipment 50100 | `OnBeforeCheckEmployeeIsEligible` | `local procedure OnBeforeCheckEmployeeIsEligible(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)` | Yes | [FR-003](../features/FR-003-equipment-status-management.md) |
| EQM Equipment 50100 | `OnBeforeCheckStatusTransitionAllowed` | `local procedure OnBeforeCheckStatusTransitionAllowed(Equipment: Record "EQM Equipment"; FromStatus: Enum "EQM Equipment Status"; ToStatus: Enum "EQM Equipment Status"; var IsHandled: Boolean)` | Yes | [FR-003](../features/FR-003-equipment-status-management.md) |
| EQM Equipment 50100 | `OnBeforeCheckWarrantyDates` | `local procedure OnBeforeCheckWarrantyDates(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)` | Yes | [FR-014](../features/FR-014-warranty-information.md) |
| EQM Equipment 50100 | `OnBeforeCalcNextMaintenanceDate` | `local procedure OnBeforeCalcNextMaintenanceDate(Equipment: Record "EQM Equipment"; var NextMaintenanceDate: Date; var IsHandled: Boolean)` | Yes | [FR-019](../features/FR-019-planned-maintenance.md) |
| EQM Equipment 50100 | `OnBeforeUpdateLastMaintenanceFromPosting` | `local procedure OnBeforeUpdateLastMaintenanceFromPosting(Equipment: Record "EQM Equipment"; MaintenanceRecord: Record "EQM Maintenance Record"; var UpdateSchedule: Boolean)` | No (`UpdateSchedule`) | [FR-019](../features/FR-019-planned-maintenance.md) |
| EQM Equipment 50100 | `OnAfterCheckEquipmentConsistency` | `local procedure OnAfterCheckEquipmentConsistency(Equipment: Record "EQM Equipment")` | No | [FR-001](../features/FR-001-equipment-registration.md) |
| EQM Equipment 50100 | `OnBeforeStartMaintenance` | `local procedure OnBeforeStartMaintenance(var Equipment: Record "EQM Equipment"; MaintenanceRecord: Record "EQM Maintenance Record")` | No | [FR-012](../features/FR-012-equipment-maintenance-status.md) |
| EQM Equipment 50100 | `OnBeforeCompleteMaintenance` | `local procedure OnBeforeCompleteMaintenance(var Equipment: Record "EQM Equipment"; MaintenanceRecord: Record "EQM Maintenance Record"; var IsHandled: Boolean)` | Yes | [FR-012](../features/FR-012-equipment-maintenance-status.md) |
| EQM Maintenance Record 50105 | `OnAfterCheckMaintenanceConsistency` | `local procedure OnAfterCheckMaintenanceConsistency(MaintenanceRecord: Record "EQM Maintenance Record")` | No | [FR-010](../features/FR-010-maintenance-registration.md) |
| EQM Maintenance-Post 50109 | `OnBeforePostMaintenanceRecord` | `local procedure OnBeforePostMaintenanceRecord(var MaintenanceRecord: Record "EQM Maintenance Record")` | No | [FR-011](../features/FR-011-maintenance-history.md) |
| EQM Maintenance-Post 50109 | `OnBeforeInsertMaintenanceHistoryEntry` | `local procedure OnBeforeInsertMaintenanceHistoryEntry(var MaintenanceHistoryEntry: Record "EQM Maintenance History Entry"; MaintenanceRecord: Record "EQM Maintenance Record")` | No | [FR-011](../features/FR-011-maintenance-history.md) |
| EQM Maintenance-Post 50109 | `OnAfterPostMaintenanceRecord` | `local procedure OnAfterPostMaintenanceRecord(MaintenanceRecord: Record "EQM Maintenance Record"; MaintenanceHistoryEntry: Record "EQM Maintenance History Entry")` | No | [FR-011](../features/FR-011-maintenance-history.md) |
| EQM Assignment Mgt. 50106 | `OnBeforeInsertAssignment` | `local procedure OnBeforeInsertAssignment(var EquipmentAssignment: Record "EQM Equipment Assignment"; Equipment: Record "EQM Equipment")` | No | [FR-004](../features/FR-004-equipment-assignment.md) |
| EQM Assignment Mgt. 50106 | `OnBeforeCloseAssignment` | `local procedure OnBeforeCloseAssignment(var EquipmentAssignment: Record "EQM Equipment Assignment"; Equipment: Record "EQM Equipment")` | No | [FR-005](../features/FR-005-equipment-unassignment.md) |
| EQM Equipment Request 50111 | `OnAfterCheckRequestConsistency` | `local procedure OnAfterCheckRequestConsistency(EquipmentRequest: Record "EQM Equipment Request")` | No | [FR-032](../features/FR-032-equipment-request-process.md) |
| EQM Request Approval Mgt. 50132 | `OnBeforeCheckApproverAllowed` | `local procedure OnBeforeCheckApproverAllowed(EquipmentRequest: Record "EQM Equipment Request"; var IsHandled: Boolean)` | Yes | [FR-033](../features/FR-033-approval-workflow.md) |
| EQM Request Approval Mgt. 50132 | `OnAfterRequestStatusChanged` | `local procedure OnAfterRequestStatusChanged(EquipmentRequest: Record "EQM Equipment Request"; PreviousStatus: Enum "EQM Request Status")` | No | [FR-033](../features/FR-033-approval-workflow.md) |

When each hook is raised, in short:

- **Equipment checks.** The `OnBeforeCheck...` hooks run before the standard rule. `OnBeforeCheckStatusTransitionAllowed` runs after the hard rule that Lost and Disposed cannot become Assigned; `IsHandled` skips the "only Available can become Assigned" rule, but not the Return-only rule (FR-004, FR-005). `OnAfterCheckEquipmentConsistency` runs at the end of the insert and modify check; raise an error to reject the save.
- **Maintenance.** `OnBeforeStartMaintenance` runs when registering moves the equipment to In Maintenance, before the save. `OnBeforeCompleteMaintenance` runs when the last open record is posted; `IsHandled` keeps the status. `OnBeforePostMaintenanceRecord` runs before the status changes, `OnBeforeInsertMaintenanceHistoryEntry` just before the history insert and `OnAfterPostMaintenanceRecord` after the status change and the insert. Subscribers must not commit.
- **Assignment.** `OnBeforeInsertAssignment` and `OnBeforeCloseAssignment` let a subscriber set its own fields. Do not change standard fields. On a return, the `Equipment` parameter already has a blank "Assigned Employee No."; use the entry's "Employee No.".
- **Requests.** `OnBeforeCheckApproverAllowed` runs in `Approve` before the self-approval check; `IsHandled` skips only that check. `OnAfterRequestStatusChanged` runs after every saved transition (send, approve, reject, assign equipment).

Not verified: the hooks were not exercised by a partner extension in a sandbox.

## External business events (Power Automate)

Codeunit 50130 `EQM Power Automate Events`, `Access = Public`. The platform delivers these events after the transaction commits, and only to flows that subscribe to them. Names, parameters and version are a frozen contract. The enum extension 50100 `EQM Event Category` (value `EQM Equipment Management`, caption "Equipment Management") groups them in Power Automate. They are raised by codeunit 50131 `EQM Power Automate Subscr.`. Source: `app/src/PowerAutomate`. Details: [FR-031](../features/FR-031-power-automate-support.md).

| Event name | Display name | Signature | `RequiredPermissions` | Raised when |
|---|---|---|---|---|
| `equipmentAssigned` | Equipment assigned | `internal procedure EquipmentAssigned(EquipmentId: Guid; EquipmentNo: Code[20]; EquipmentDescription: Text[100]; EmployeeNo: Code[20]; AssignmentId: Guid; AssignmentDate: Date)` | `TableData` "EQM Equipment Assignment", `R` | Equipment is assigned to an employee. |
| `warrantyExpiring` | Warranty expiring | `internal procedure WarrantyExpiring(EquipmentId: Guid; EquipmentNo: Code[20]; EquipmentDescription: Text[100]; WarrantyProvider: Text[100]; WarrantyEndDate: Date; DaysRemaining: Integer; AlertIntervalDays: Integer)` | `TableData` "EQM Warranty Alert", `R` | A warranty alert is created, 90, 60 or 30 days before the warranty end date. |

Attribute text from the source, both with category `EventCategory::"EQM Equipment Management"` and version `'1.0'`:

```al
[ExternalBusinessEvent('equipmentAssigned', 'Equipment assigned', 'Occurs when equipment is assigned to an employee.', EventCategory::"EQM Equipment Management", '1.0')]
[ExternalBusinessEvent('warrantyExpiring', 'Warranty expiring', 'Occurs when a warranty alert is created, 90, 60 or 30 days before the warranty end date.', EventCategory::"EQM Equipment Management", '1.0')]
```

Not verified: the payload and the raise count of both events (the test runner does not call an AL subscriber for an external business event; see `docs/TODO.md`, "FR-031 Power Automate Support").

## Contract rules

- Signatures never change once released. To change one, add a new event and mark the old one obsolete (`ObsoleteState = Pending`, `ObsoleteReason`, `ObsoleteTag`). AppSourceCop checks this against the baseline once a release exists (AS0019, AS0020, AS0025).
- Publishers are `[IntegrationEvent(false, false)]`. A new event is public API from the day it is released.
- Subscribers must not `Commit`. Table-event subscribers must exit on `Rec.IsTemporary()`. Subscribers must not show UI without a `GuiAllowed()` check. Subscribers run in the caller's transaction, and an error stops the operation.
- The business events carry `Insert(true)` rules: they are not raised for `Insert(false)` (data migration) or for temporary records.

## Example subscriber

A partner extension (placeholder affix `ABC`) that reacts to an assignment. Markdown only: the code is not compiled in this repository, and no second app has been used to check it. TODO(verify).

```al
namespace ABC.Partner;

using MiguelCarvalho.EquipmentManagement;

codeunit 50300 "ABC Equipment Subscribers"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", OnEquipmentAssigned, '', false, false)]
    local procedure ABCOnEquipmentAssigned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")
    begin
        if Equipment.IsTemporary() then
            exit;

        // Read from the parameters, not from the database: the equipment row is not saved yet.
        // No Commit, no UI, no Modify of the equipment. Queue any call to an outside system.
    end;
}
```

## Related

- [API overview](README.md), [Endpoints](endpoints.md)
- Feature docs: [FR-029](../features/FR-029-business-events.md), [FR-030](../features/FR-030-event-subscribers.md), [FR-031](../features/FR-031-power-automate-support.md), and the docs linked in the tables above
- [Architecture overview](../architecture/README.md#extension-points-into-standard-business-central)
- Microsoft Learn: [Events in AL](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al), [Event types](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-event-types), [Publishing events](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-publishing-events), [Business events](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/business-events-overview)
