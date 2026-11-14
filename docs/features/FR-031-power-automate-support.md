# FR-031 Power Automate Support (external business events)

## Purpose
Two business moments are published as external business events, so a flow can start from them with the trigger "When a business event occurs" of the Business Central connector in Power Automate (GitHub issue #69): equipment assigned, and warranty expiring. The flows themselves are built by the customer in Power Automate. No existing business code changes. The only subscriptions are to this app's own publisher (codeunit 50119, FR-029) and to the platform trigger event of its own table 50107, so there is no events report.

Status: merged to `main` via PR #122. App version stays 29.0.0.0 (not released).

## Verification status
- **Build:** both apps compile with 0 errors and 0 warnings. The documenter did not rerun the build; no AL line was changed (the `///` comments were already present).
- **Tests:** 3 automated smoke tests in codeunit 50187 (scenarios 1, 4 and 6 of the plan, as "runs without an error" checks). CI (AL-Go) for PR #122 showed that the platform does not call an AL subscriber for an external business event in the test runner, so the raise count and the payload (scenarios 1 and 4) cannot be asserted automatically and are sandbox-only; the negative scenarios 2, 3, 5 and 7 were removed because they passed trivially. The 3 smoke tests pass in CI (AL-Go PR build of PR #122: 122 tests in total, 0 failed, 0 skipped). Not run in a BC sandbox by a person.
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
| Codeunit (test app) | 50187 | EQM Power Automate Tests | New, 3 smoke tests. |

Test codeunit 50188 (manual subscriber) was removed: it never received the events. ID 50188 is free again.

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
Codeunit 50187 (`test/src/EQMPowerAutomateTests.Codeunit.al`, AutoRollback), 3 smoke tests that run the operations firing the subscribers of codeunit 50131 and assert only that they complete:
1. `AssignRunsSubscriberWithoutError`: AssignEmployee succeeds, equipment is Assigned.
2. `GenerateAlertsRunsSubscriberWithoutError`: GenerateAlerts creates one alert.
3. `AlertInsertWithoutRaiseDoesNotFail`: a temporary alert and an `Insert(false)` pass the subscriber guards.

Why no payload test: the first version used a manual subscriber (codeunit 50188) on the two events. In the CI run for PR #122 it saw 0 raises (2 positive tests failed, 5 negative tests passed trivially), while the same chain is proven in FR-029 (`OnEquipmentAssigned`, `OnAfterInsertEvent` of table 50107). The most likely cause is that the platform raises an external business event itself and does not invoke AL subscribers in the test runner; this was not proven in isolation. The raise count and payload (plan scenarios 1 and 4) and the negative cases (2, 3, 5, 6, 7) are therefore sandbox-only; see docs/TODO.md.

Compiled with 0 errors and 0 warnings. The 3 smoke tests pass in CI (122 tests in total, 0 failed, 0 skipped). Scenario 8 is sandbox-only (see Verification status).

## XML documentation
Present on the enum extension, codeunit 50130 and both events with all parameters, and codeunit 50131. Checked, nothing added.

## Discrepancies plan vs code
Plan V1 did not apply (the events are `internal procedure`). Plan V2 applied in effect: codeunit 50188 compiled but received no events in CI, so it was dropped and scenarios 1 and 4 are sandbox-only (the plan's V2 trigger was a compile error; the cause here is runtime).
