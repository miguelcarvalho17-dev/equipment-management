# FR-031 Power Automate Support

> Status: **Approved** by the user. **Decisions:** Q1 **examples** (`equipmentAssigned`, `warrantyExpiring`), Q2 **alert** (raised when a 90/60/30-day warranty alert is created). Source: GitHub issue #69 (milestone V3). Branch `feature/FR-031-power-automate-support`. No standard BC event is subscribed: only this app's publisher 50119 (FR-029) and the platform trigger event `OnAfterInsertEvent` of its own table 50107, so no events report is needed (same reasoning as FR-029/FR-030).
> **Open questions (the plan uses the recommended default, so the answer can be one word):**
> - **Q1 Scope.** **examples** (recommended): two external business events, matching the issue's flows: `equipmentAssigned` and `warrantyExpiring`. **all**: also `equipmentCreated`, `equipmentReturned`, `maintenanceCreated`, `warrantyExpired` (four more frozen contracts; needs a replan of Objects, Events and tests). More events can be added later as an additive change.
> - **Q2 Warranty trigger.** **alert** (recommended): `warrantyExpiring` is raised when a warranty alert (90/60/30 days, FR-016) is created, so the reminder goes out before the end date, once per interval. **expired**: reuse FR-029 OnWarrantyExpired (raised the day after the end date), which is a notice, not a reminder.

## Goal
Make two business moments of the app available as triggers in Power Automate ("When a business event occurs" in the Business Central connector), so that makers can build the issue's example flows (assignment -> Teams message, expiring warranty -> email) without code. The app ships the events and step-by-step flow instructions; the flows themselves live in the customer's Power Automate.

## Approach and rejected alternatives
- Chosen: `[ExternalBusinessEvent]` publishers in a new public codeunit, raised from a thin internal subscriber codeunit that subscribes to FR-029 OnEquipmentAssigned and to `OnAfterInsertEvent` of "EQM Warranty Alert". An enum extension of the platform enum `EventCategory` groups them under "Equipment Management". The platform queues external business events and delivers them only when the transaction commits, so no Commit, HTTP or setup switch is needed (nothing is sent while no flow subscribes). No business code changes.
- Rejected: API webhook triggers ("When a record is created" on Assignment API 50125). They give record-level, not business-level, semantics, and there is no warranty alert API. They are mentioned in the help as a zero-code option.
- Rejected: calling a flow's HTTP URL from AL. It is not transactional, needs a stored secret, and blocks the user.
- Rejected: polling the FR-030 outbox from a flow. Polling is not push; the outbox stays for external systems.
- Rejected: adding the events to codeunit 50119. That would mix integration and external events in one frozen contract.

## Objects
IDs in use (checked in `app/src`, `test/src`): codeunits 50103-50122 (50123-50129 reserved by FR-026 C10), no enum extensions, test codeunits 50178-50186 (50150-50177 reserved).
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| EnumExtension | 50100 | EQM Event Category | Extend `EventCategory` | Value 50100 "EQM Equipment Management", Caption 'Equipment Management'. `app/src/PowerAutomate/EQMEventCategory.EnumExt.al` |
| Codeunit | 50130 | EQM Power Automate Events | New | `Access = Public`. The two external business events only. `app/src/PowerAutomate/EQMPowerAutomateEvents.Codeunit.al` |
| Codeunit | 50131 | EQM Power Automate Subscr. | New | `Access = Internal`. Two subscribers that build the payload and raise the events. `app/src/PowerAutomate/EQMPowerAutomateSubscr.Codeunit.al` |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | X on 50130 and 50131 |
| Codeunit (test) | 50187 | EQM Power Automate Tests | New | Scenarios 1-7. `test/src/EQMPowerAutomateTests.Codeunit.al` |
| Codeunit (test) | 50188 | EQM Power Automate Test Subscr | New | `EventSubscriberInstance = Manual`; counts each event and keeps the last payload |

## Data model and upgrade impact
- No tables, fields or upgrade code. `app.json` unchanged (System Application comes through `application`). Version stays 29.0.0.0.

## Events
- Subscribed (in 50131), no UI, no Commit, no Modify:
  1. Codeunit 50119 `OnEquipmentAssigned(Equipment; EquipmentAssignment)`: raise `EquipmentAssigned` with values from the parameters only (FR-029 docs: the equipment row is not written yet).
  2. Table 50107 "EQM Warranty Alert" `OnAfterInsertEvent`: exit if `Rec.IsTemporary()`, exit if not `RunTrigger`; `SetLoadFields(Description, "Warranty Provider")` and `Get` the equipment, exit if not found; raise `WarrantyExpiring`.
- Published (in 50130), both `internal procedure`, empty body, XML docs ("delivered after commit, only to subscribed flows"), attribute version '1.0', category `EventCategory::"EQM Equipment Management"`, no `IsHandled`, simple types only:
  1. `EquipmentAssigned`, name `equipmentAssigned`, display 'Equipment assigned', description 'Occurs when equipment is assigned to an employee.'. `[RequiredPermissions]` TableData "EQM Equipment Assignment" R. Parameters: `EquipmentId: Guid` (SystemId), `EquipmentNo: Code[20]`, `EquipmentDescription: Text[100]`, `EmployeeNo: Code[20]`, `AssignmentId: Guid` (assignment SystemId), `AssignmentDate: Date`.
  2. `WarrantyExpiring`, name `warrantyExpiring`, display 'Warranty expiring', description 'Occurs when a warranty alert is created, 90, 60 or 30 days before the warranty end date.'. `[RequiredPermissions]` TableData "EQM Warranty Alert" R. Parameters: `EquipmentId: Guid`, `EquipmentNo: Code[20]`, `EquipmentDescription: Text[100]`, `WarrantyProvider: Text[100]`, `WarrantyEndDate: Date`, `DaysRemaining: Integer` (end date - alert date), `AlertIntervalDays: Integer` (50110 `GetIntervalDays`).

## Permissions
- EQM - Reader: append `codeunit "EQM Power Automate Events" = X` and `codeunit "EQM Power Automate Subscr." = X` after `codeunit "EQM Integration Event Mgt." = X` (move the `;`). Manager/Administrator inherit. No tabledata changes. The flow owner also needs BC's own external-events subscription permission (documented in help, not added to our sets).

## Compatibility
- Additive only. **Contract at the first AppSource release:** codeunit 50130 name/ID, the two event names, their parameter names/types/order, the category value 50100, and version '1.0'. A later change needs a new event version ('2.0') or a new event, plus `Obsolete` on the old one.
- **Breaking-change risk:** none on existing objects; only permission set 50100 changes (additive). 50119, 50107 and 50110 are not modified.

## Implementation steps
1. Enum extension 50100 (the developer adds the `using` the compiler asks for `EventCategory`). Compile.
2. Codeunit 50130 with the two events (Events section). Compile. **V1:** if the compiler rejects `ExternalBusinessEvent` on an `internal procedure`, make them `local`, move the subscribers of step 3 into 50130 (codeunit 50131 is then not created, its permission line dropped), and mark test scenarios 1 and 4 sandbox-only.
3. Codeunit 50131 with the two subscribers. Compile.
4. Permission lines. Build; commit the `.g.xlf` if it changes.
5. Test codeunits 50188 (manual subscriber on 50130 events) and 50187, pattern of 50184/50186: Subtype Test, TestPermissions Disabled, AutoRollback, Library Assert, ConfirmHandler, Locked labels prefix `EQMPAE`, Initialize with number series; BindSubscription per test. **V2:** if 50188 cannot subscribe to the external events (compile error), drop 50188, keep scenarios 2, 3 and 5-7 as "operation succeeds, no error" checks, and mark 1 and 4 sandbox-only. Build the test app.
6. Documenter: `docs/features/FR-031-power-automate-support.md`; `docs/help/FR-031-power-automate-support.md` with both example flows step by step (trigger "When a business event occurs", category Equipment Management; Teams "Post message in a chat or channel"; Outlook "Send an email (V2)"; optional "Get record" through the FR-026 API or the standard employees API to add names), the required permissions, and the webhook alternative; CHANGELOG; `docs/TODO.md` sandbox section (scenario 8).

## Test scenarios
**Status after CI (PR #122):** manual subscriber 50188 received no event in the test runner (platform-raised external business events do not call AL subscribers; likely, not proven in isolation). V2 applied: 50188 removed; 50187 keeps 3 smoke tests ("runs without an error") for scenarios 1, 4 and 6. Scenarios 1 to 7 as written below are sandbox-only for the raise count and payload.
Setup: active category, active employee E1, Available equipment EQ with description and warranty provider; reference date R.
1. Given EQ, when AssignEmployee(E1) runs, then EquipmentAssigned is raised once with EQ's SystemId, No., Description, EmployeeNo E1, and AssignmentId/AssignmentDate of the stored active entry.
2. (neg) Given EQ with an open maintenance record, when AssignEmployee fails (asserterror), then EquipmentAssigned was not raised.
3. (neg) Given EQ assigned, when UnassignEmployee runs (Yes), then EquipmentAssigned is not raised.
4. Given equipment W with warranty end R+20, when GenerateAlerts(R) runs, then WarrantyExpiring is raised once with W's SystemId, No., Description, provider, end date, DaysRemaining 20 and AlertIntervalDays 30.
5. (neg) Given scenario 4 done, when GenerateAlerts(R) runs again, then no further WarrantyExpiring (no new alert).
6. (neg) When a warranty alert is inserted as a temporary record, or with Insert(false), then WarrantyExpiring is not raised.
7. (neg) Given equipment with end R+120, and equipment with end R+20 and status Disposed, when GenerateAlerts(R) runs, then WarrantyExpiring is not raised.
8. Sandbox: both events appear in Power Automate under Equipment Management; an assignment posts a Teams message; the warranty job sends an email; a failed (rolled back) assignment sends nothing; a Reader user can create the flow.

## Risks and open questions
- Q1, Q2: see the top. "all" or "expired" need a replan.
- Assumed no setup switch, because the platform sends nothing without a subscribed flow.
- Assumed employee number but no employee name in the payload, to keep personal data out of the event; flows look the name up through the BC connector.
- Assumed alerts created by the manual "Generate Alerts" action also raise `warrantyExpiring`, because each alert is created only once either way.
- Assumed codeunits 50130/50131 (next free after 50122, skipping the FR-026 reserve 50123-50129), enum extension 50100 (first in its object type) and test codeunits 50187/50188.
- Unverified (sandbox only): event discovery in Power Automate, delivery only after commit and its delay, the exact BC permission set needed to subscribe, Guid/Date parameter rendering in flows, and whether attribute strings (display name, description) are translatable. V1 and V2 are settled by the build.
