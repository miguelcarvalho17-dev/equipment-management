# FR-031 Power Automate Support (external business events)

## Purpose
Two business moments are published as external business events, so a flow can start from them with the trigger "When a business event occurs" of the Business Central connector in Power Automate (GitHub issue #69): equipment assigned, and warranty expiring. The flows themselves are built by the customer in Power Automate. No existing business code changes. The only subscriptions are to this app's own publisher (codeunit 50119, FR-029) and to the platform trigger event of its own table 50107, so there is no events report.

Status: implemented on branch `feature/FR-031-power-automate-support`. App version stays 29.0.0.0 (not released).

## Verification status
- **Build:** both apps compile with 0 errors and 0 warnings. The documenter did not rerun the build; no AL line was changed (the `///` comments were already present).
- **Tests:** 7 automated scenarios in codeunit 50187 (scenarios 1-7 of the plan). CI (AL-Go) run for PR #122 is pending: they are not yet confirmed passing. Not run in a BC sandbox by a person.
- **Not verified (Power Automate / sandbox only), plan scenario 8:**
  - Both events appear in Power Automate under the category Equipment Management, with the display names and descriptions.
  - An assignment posts a Teams message; the warranty alert job sends an email.
  - Delivery happens only after commit and its delay; a rolled-back assignment sends nothing.
  - The exact BC permission set a flow owner needs to subscribe; that a Reader user can create the flow.
  - How Guid and Date parameters render in a flow.
  - Whether the attribute strings (display name, description) are translatable.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| EnumExtension | 50100 | EQM Event Category | Extends the platform enum `EventCategory` with value 50100 "EQM Equipment Management" (caption 'Equipment Management'). `app/src/PowerAutomate/EQMEventCategory.EnumExt.al` |
| Codeunit | 50130 | EQM Power Automate Events | New, `Access = Public`. The two external business events (empty bodies). |
| Codeunit | 50131 | EQM Power Automate Subscr. | New, `Access = Internal`. Two subscribers that raise the events. |
| PermissionSet | 50100 | EQM - Reader | Execute on codeunits 50130 and 50131. |
| Codeunit (test app) | 50187 | EQM Power Automate Tests | New, 7 tests. |
| Codeunit (test app) | 50188 | EQM Power Automate Test Subscr | New, `EventSubscriberInstance = Manual`; counts each event and keeps the last payload. |

No tables, fields or upgrade code. No setup switch: the platform sends nothing while no flow subscribes.

## Events (codeunit 50130)
Both are `[ExternalBusinessEvent]`, version '1.0', category `EventCategory::"EQM Equipment Management"`, `internal procedure`, simple types only, no `IsHandled`. The platform queues the event and delivers it after the transaction commits; a rolled-back operation delivers nothing.

### equipmentAssigned
Display name 'Equipment assigned'. Description 'Occurs when equipment is assigned to an employee.' `[RequiredPermissions]` TableData "EQM Equipment Assignment" R. Procedure `EquipmentAssigned`.

| Parameter | Type | Meaning |
|---|---|---|
| EquipmentId | Guid | SystemId of the equipment. |
| EquipmentNo | Code[20] | Equipment number. |
| EquipmentDescription | Text[100] | Equipment description. |
| EmployeeNo | Code[20] | Employee the equipment is assigned to. No name is sent (personal data). |
| AssignmentId | Guid | SystemId of the assignment entry. |
| AssignmentDate | Date | Assignment date. |

### warrantyExpiring
Display name 'Warranty expiring'. Description 'Occurs when a warranty alert is created, 90, 60 or 30 days before the warranty end date.' `[RequiredPermissions]` TableData "EQM Warranty Alert" R. Procedure `WarrantyExpiring`.

| Parameter | Type | Meaning |
|---|---|---|
| EquipmentId | Guid | SystemId of the equipment. |
| EquipmentNo | Code[20] | Equipment number. |
| EquipmentDescription | Text[100] | Equipment description. |
| WarrantyProvider | Text[100] | Warranty provider. |
| WarrantyEndDate | Date | Warranty end date. |
| DaysRemaining | Integer | Warranty end date minus the alert date. |
| AlertIntervalDays | Integer | 90, 60 or 30, from `GetIntervalDays` of codeunit 50110 for the alert's interval. |

## Subscribers (codeunit 50131)
No UI, no `Commit`, no `Modify`; they run in the caller's transaction.
- `RaiseEquipmentAssigned`: subscribes to `OnEquipmentAssigned` of codeunit 50119. Uses the event parameters only (the equipment row is not written yet at that point, see FR-029).
- `RaiseWarrantyExpiring`: subscribes to `OnAfterInsertEvent` of table 50107 "EQM Warranty Alert". Exits for a temporary record and when `RunTrigger` is false. Loads the equipment (`SetLoadFields(Description, "Warranty Provider")`); exits if it is not found. Because it hooks the alert insert, it fires for alerts created by the daily job and by the manual Generate Alerts action alike, once per alert (an alert is created only once).

## Permissions
- **EQM - Reader:** execute on codeunits 50130 and 50131. Manager and Administrator inherit it. No tabledata change.
- The flow owner also needs Business Central's own permission to subscribe to external business events. TODO(verify): which permission set, in a sandbox.

## Compatibility
Additive; only permission set 50100 changes. **Contract at the first AppSource release:** codeunit 50130 name and ID, the two event names, their parameter names, types and order, category value 50100 and version '1.0'. A later change needs a new event version ('2.0') or a new event, plus `Obsolete` on the old one. Codeunits 50119, 50110 and table 50107 are untouched.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build; never edit by hand. TODO(verify): whether the attribute strings are translated.

## Test status
Codeunit 50187 (`test/src/EQMPowerAutomateTests.Codeunit.al`, AutoRollback), with 50188 counting events:
1. `EquipmentAssignedRaisedOnAssign`: raised once with the equipment and assignment values.
2. `EquipmentAssignedNotRaisedWhenAssignFails`: not raised when assigning fails.
3. `EquipmentAssignedNotRaisedOnUnassign`.
4. `WarrantyExpiringRaisedWhenAlertCreated`: payload incl. DaysRemaining 20, AlertIntervalDays 30.
5. `WarrantyExpiringNotRaisedAgainForSameAlert`.
6. `WarrantyExpiringNotRaisedForTemporaryOrWithoutTriggers`.
7. `WarrantyExpiringNotRaisedOutsideWindowOrForDisposed`.

Compiled with 0 errors and 0 warnings. CI for PR #122 is pending; not yet confirmed passing. Scenario 8 is sandbox-only (see Verification status).

## XML documentation
Present on the enum extension, codeunit 50130 and both events with all parameters, and codeunit 50131. Checked, nothing added.

## Discrepancies plan vs code
None found. Plan scenario 8 and the V1/V2 fallbacks did not apply: the events are `internal procedure` and codeunit 50188 subscribes in the code as planned. TODO(verify): the build result for V1/V2 is taken from the "0 errors" statement, not rerun.
