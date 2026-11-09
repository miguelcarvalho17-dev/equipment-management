# FR-017 Equipment Notifications

> Status: **Approved by the user with the default answers to Q1-Q12; the events report `docs/plans/FR-017-events.md` is
> applied.** Open questions Q1-Q12 (see "Risks and open questions") each had a
> proposed default, and the plan is written with these defaults. **Q1 (what "overdue maintenance" means), Q3 (what
> triggers the warranty notification), Q5 (who is told that equipment is back from maintenance) and Q6 (My Notifications
> integration) change the design if they are answered differently.**
> Source: GitHub issue #36. Branch: `feature/FR-017-equipment-notifications`.
> **Events: one standard hook is needed, not zero.** The design uses the platform `Notification` data type on this app's
> own pages (no standard behavior changes). To let users switch the notifications off ("Don't show again" and My
> Settings > My Notifications), the app must register its notifications with the standard **My Notifications** feature,
> which means subscribing to one standard event and calling standard procedures. No events report exists, and the names
> are not verified in the symbols (the `.app` files cannot be read without the event-search script). **Before the
> developer starts, the coordinator must run al-event-finder** for the My Notifications registration (scope below in
> "Events"); its report goes to `docs/plans/FR-017-events.md`. If no usable API is found, the fallback in Q6 applies.
> Scope: main app only. **Two new codeunits** (50112, 50113) and changes to tables 50105, pages 50101, 50106, 50114,
> codeunits 50108 and 50110, and permission set 50100. **No new table, field, page or enum. No version bump. No upgrade
> logic.** Tests deferred (Q11 default): test codeunit 50171 is reserved, and the tester step is skipped.
> Workflow for FR-017: **al-event-finder (My Notifications only)** -> planner update if the report differs -> (human
> approves plan) -> developer -> reviewer -> build -> tester step SKIPPED (Q11) -> documenter -> appsource-validator.

## Goal
Business Central notifications (the yellow bar at the top of a page) tell users about three situations while they work:
a warranty that is about to expire, maintenance that is overdue, and equipment that is back from maintenance. The
notifications appear on the Equipment Card, the Maintenance Record Card, the maintenance pages after posting and the
Equipment Manager Role Center, each with an action that opens the records to act on, and users can switch each kind
off.

### Requirement restated
- NT-R1 Use standard Business Central notifications (the `Notification` data type), not messages, emails or a new list.
- NT-R2 Scenario "Warranty expiring", for example "Warranty for Laptop LAP00045 will expire in 30 days."
- NT-R3 Scenario "Overdue maintenance".
- NT-R4 Scenario "Equipment returned from maintenance".

### What is new and what is already covered
| Already present | Built in | Use in FR-017 |
|---|---|---|
| Stored warranty alerts at 90/60/30 days, created daily by job queue codeunit 50111 or the Generate Alerts action; Open / Acknowledged / Cancelled; stale alerts cancelled. | FR-016 (table 50107, codeunit 50110, page 50120) | **The trigger of the warranty notification.** FR-017 creates no alert and changes no alert rule. A notification is shown while an Open alert exists for the current end date; acknowledging the alert (FR-016) stops it. |
| "Open Warranty Alerts" tile, Warranty Alerts list, card navigation action. | FR-016 | Still the place to work through alerts; the notification action opens the same list. |
| `CalcWarrantyStatus`, `GetWarrantyDaysRemaining`, `IsFinalStatus` on table 50100. | FR-015, FR-016, FR-003 | Days in the text and eligibility guard. No rule is duplicated. |
| Open / Posted maintenance records, Maintenance Date, `HasOpenMaintenance`, `ShowOpenMaintenanceRecords`. | FR-010, FR-012 (table 50105, codeunit 50108) | Basis of "overdue maintenance" (Q1). |
| Posting the last open record sets the equipment from In Maintenance to Available (`CompleteMaintenance`). `PostWithConfirmation` is the only UI path to posting. | FR-011, FR-012 (codeunits 50108, 50109) | The moment "returned from maintenance". |
| Role Center 50110 and dashboard 50109 both host cue part 50106. | FR-009, FR-015 | Sends the Role Center summary notifications. |

**New in FR-017:** the three notification kinds, their texts and actions, the overdue-maintenance rule (there was no
concept of "overdue" before), registration in My Notifications, and a new key on table 50105. **Not new:** any alert,
schedule, job, email or status rule.

### Interpretation (defaults, see Q1-Q12)
- **Overdue maintenance (Q1, Q2, Q9):** the app has no maintenance schedule (README: "Maintenance schedules: Planned"),
  so nothing is "due" yet. Default: a maintenance record is **overdue when it is still Open more than 14 days after its
  Maintenance Date** (days open = today - Maintenance Date; 15 or more is overdue). These records keep the equipment In
  Maintenance and blocked for assignment, so they need a user to post them.
- **Warranty expiring (Q3, Q4):** shown for equipment that has an **Open** FR-016 alert whose Warranty End Date equals
  the equipment's current end date, the equipment is not Lost or Disposed, and the end date is today or later. The days
  in the text are the actual days remaining today (not the 90/60/30 interval of the alert). Expired warranties get no
  notification.
- **Returned from maintenance (Q5):** shown to the user who posts the maintenance record, right after posting, when the
  posting changed the equipment from In Maintenance to Available. Not shown to other users.
- **Reference date:** `Today()` everywhere (FR-015 Q1, FR-016 Q9).
- **Equipment name in texts (Q8):** the equipment Description; when it is blank, the Category Code (always filled).
- **Switching off (Q6):** each of the three kinds is one entry in My Notifications (enabled by default) and every
  notification has a "Don't show again" action.

### Where each notification appears
| ID | Kind | Page and moment | Text (label) | Actions |
|---|---|---|---|---|
| N-A1 | Warranty expiring | Equipment Card 50101, when a saved record becomes current | `WarrantyExpiresInDaysMsg` / `WarrantyExpiresTomorrowMsg` / `WarrantyExpiresTodayMsg` | Show warranty alerts; Don't show again |
| N-A2 | Warranty expiring | Cue part 50106 `OnOpenPage` (Role Center and dashboard) | `OpenWarrantyAlertsMsg` / `OneOpenWarrantyAlertMsg` | Show warranty alerts; Don't show again |
| N-B1 | Overdue maintenance | Equipment Card 50101, when a saved record becomes current | `EquipmentMaintenanceOverdueMsg` | Show open maintenance; Don't show again |
| N-B2 | Overdue maintenance | Maintenance Record Card 50114, when a saved open record becomes current | `MaintenanceRecordOverdueMsg` | Don't show again |
| N-B3 | Overdue maintenance | Cue part 50106 `OnOpenPage` | `OverdueMaintenanceSummaryMsg` / `OneOverdueMaintenanceMsg` | Show overdue maintenance; Don't show again |
| N-C1 | Returned from maintenance | After Post on Maintenance Record Card 50114 or list 50113 | `ReturnedFromMaintenanceMsg` | Open equipment card; Don't show again |

Three notification IDs (one per kind) are used: N-A1/N-A2 share the warranty ID, N-B1/N-B2/N-B3 share the overdue ID,
N-C1 has its own. Two notifications with the same ID are never sent on the same page.

## Approach and rejected alternatives
- Chosen: **an internal codeunit "EQM Notification Mgt." that builds, sends and recalls `Notification` objects, called
  from triggers of this app's own pages and from `PostWithConfirmation`; small read helpers added to the existing
  warranty alert and maintenance codeunits; registration in the standard My Notifications through one thin subscriber
  codeunit.** Notifications are a UI feature of the current session, so they are raised where the user works, from data
  that already exists.
- Rejected: **sending notifications from the job queue (codeunit 50111) or another background job.** Notifications
  belong to the user's client session and page; a background session has no client to show them to, and there is no
  push to other users. The job keeps creating alerts; the pages turn them into notifications.
- Rejected: **a new "EQM Notification Entry" table (inbox per user).** It duplicates FR-016 alerts and the standard
  notification framework, needs read/unread state per user and a retention rule. Not requested.
- Rejected: **raising N-C1 in a subscriber to our own `OnAfterPostMaintenanceRecord` or in codeunit 50109.** No UI in
  posting code or posting event subscribers (al-extensibility); 50109 is also run without UI. `PostWithConfirmation`
  is the UI path and already shows a Confirm.
- Rejected: **warranty notification from the FR-015 status (Expiring Soon, 30 days)** without FR-016 alerts. It would
  ignore acknowledgement and the 90/60 intervals and duplicate FR-016 (Q3 alternative).
- Rejected: **new maintenance schedule fields (Next Maintenance Date, interval) to define "overdue".** That is the
  separate planned "Maintenance schedules" capability and a data model change; this feature would grow into two (Q1).
- Rejected: **a setup field for the 14-day threshold.** Same reasoning as FR-016 Q5: a procedure returns the value, so a
  setup field can be added later without a breaking change (Q2).
- Rejected: **published events (for example `OnBeforeSendNotification` with IsHandled).** New permanent public API for
  no stated need; partners can already react to alerts and posting through existing events (Q10).
- Rejected: **a notification on the Equipment List or Employee Card.** Lists show many records; the Role Center summary
  covers the overview (Q7).
- Rejected: **a Role Center summary of equipment returned from maintenance by other users.** No stored "returned" state
  exists, and the list of affected equipment cannot be opened with a simple filter (Q5).
- Rejected: **a new "Overdue Maintenance" tile.** Not requested; the summary notification and its action cover it
  (follow-up in Q7).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50107, pages 50100-50120, codeunits 50103-50111,
queries 50100-50103, enums 50100-50106, page extension 50100, permission sets 50100-50102, permission set extension
50103. Test app: no objects; test codeunits 50150-50170 are reserved by FR-001 to FR-016, none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Codeunit | 50112 | EQM Notification Mgt. | New | Internal: notification IDs, conditions, texts, send/recall, action handlers, My Notifications calls |
| Codeunit | 50113 | EQM Notification Subscribers | New | Internal: one subscriber that registers the three notifications in My Notifications (only if al-event-finder confirms the API, Q6) |
| Codeunit | 50108 | EQM Maintenance Mgt. | Modify (own) | Overdue rule helpers; `PostWithConfirmation` sends N-C1 |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | Modify (own) | Read helpers: open alert exists, count open alerts, show open alerts |
| Table | 50105 | EQM Maintenance Record | Modify (own) | New key `StatusDate` (Status, "Maintenance Date") |
| Page | 50101 | EQM Equipment Card | Modify (own) | `OnAfterGetCurrRecord`: N-A1, N-B1 |
| Page | 50114 | EQM Maintenance Record Card | Modify (own) | `OnAfterGetCurrRecord`: N-B2 |
| Page | 50106 | EQM Equipment Cues | Modify (own) | `OnOpenPage`: N-A2, N-B3 |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | X on codeunits 50112, 50113 |

Not changed: tables 50100-50104, 50106, 50107; pages 50100, 50102-50105, 50107-50113, 50115-50120 (page 50113 is
covered through `PostWithConfirmation`); codeunits 50103-50107, 50109, 50111; queries; enums; page extension 50100;
permission sets 50101, 50102; permission set extension 50103; the profile; `app/app.json`; `test/`.

New files (namespace `MiguelCarvalho.EquipmentManagement`), in a new feature folder `app/src/Notifications/`:
`EQMNotificationMgt.Codeunit.al`, `EQMNotificationSubscribers.Codeunit.al`.

Next free IDs after FR-017: tables 50108, pages 50121, codeunits 50114, queries 50104, enums 50107, page extensions
50101, permission sets 50104. Test app: **test codeunit 50171 reserved for FR-017 "EQM Notification Tests"**, not
built now (Q11).

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report, except where a fallback is written here.
- `Notification` data type members: `Id`, `Message`, `Scope` (`NotificationScope::LocalScope`), `SetData`, `GetData`,
  `HasData`, `AddAction(Caption, CodeunitId, MethodName)`, `Send()`, `Recall()`. Recall works on a new variable that
  only has the same `Id` set.
- A notification action handler is a global procedure (no `local`, no `internal` keyword) with one parameter
  `Notification: Notification`, in a codeunit with `Access = Internal`, and the client can call it.
  **Fallback:** set codeunit 50112 to `Access = Public`. All its other procedures are declared `internal`, so only the
  five handlers become public; record this in the Compatibility section of the feature doc.
- A `Guid` return value can be assigned from a locked `Label` holding the GUID text (implicit Text-to-Guid conversion)
  without a CodeCop warning. **Fallback:** `Evaluate` the label into a local Guid.
- A notification sent from `OnOpenPage` of a `CardPart` hosted on a `RoleCenter` page (and on the Card page 50109) is
  shown on the host page.
- `GuiAllowed()` returns false in job queue and test sessions without UI (used as a guard before every `Send`).
- My Notifications API: **taken from `docs/plans/FR-017-events.md` only** (see Events). Do not code from memory.

### Codeunit 50112 "EQM Notification Mgt." (new)
`Access = Internal` (see fallback). XML summary: "Shows Business Central notifications about expiring warranties,
overdue maintenance and equipment that is back from maintenance, and handles their actions." All procedures `internal`
unless stated `local` or "handler", each with an XML doc comment. No `Commit`, no `Message`, no `Confirm`, no `Error`
(a notification must never block the page).

Labels (all on this codeunit):

| Name | Text | Comment / Locked |
|---|---|---|
| `WarrantyNotificationIdTok` | `6F3B9C2E-8A41-4D7B-9E15-2C7A0B5D3F01` | Locked |
| `OverdueMaintNotificationIdTok` | `A82D4F6B-1C93-4E58-B7A0-5D9E3C1F7A02` | Locked |
| `ReturnedNotificationIdTok` | `D14E7A9C-3B65-4F2D-8C1E-9A6F0B2D5E03` | Locked |
| `EquipmentNoDataTok` | `EquipmentNo` | Locked (data key) |
| `WarrantyExpiresInDaysMsg` | `Warranty for %1 %2 will expire in %3 days.` | `%1 = equipment description, or the category code when the description is blank, %2 = equipment number, %3 = number of days until the warranty end date` |
| `WarrantyExpiresTomorrowMsg` | `Warranty for %1 %2 will expire tomorrow.` | `%1 = equipment description, or the category code when the description is blank, %2 = equipment number` |
| `WarrantyExpiresTodayMsg` | `Warranty for %1 %2 expires today.` | same as above |
| `OpenWarrantyAlertsMsg` | `%1 warranty alerts are open. Review the warranties that are about to expire.` | `%1 = number of open warranty alerts` |
| `OneOpenWarrantyAlertMsg` | `1 warranty alert is open. Review the warranty that is about to expire.` | no placeholder |
| `EquipmentMaintenanceOverdueMsg` | `Maintenance %1 for %2 %3 has been open for %4 days. Post it when the work is finished.` | `%1 = maintenance record number, %2 = equipment description, or the category code when the description is blank, %3 = equipment number, %4 = number of days since the maintenance date` |
| `MaintenanceRecordOverdueMsg` | `Maintenance record %1 has been open for %2 days. Post it when the work is finished.` | `%1 = maintenance record number, %2 = number of days since the maintenance date` |
| `OverdueMaintenanceSummaryMsg` | `%1 maintenance records have been open for more than %2 days. Post them when the work is finished.` | `%1 = number of overdue maintenance records, %2 = number of days after which maintenance is overdue` |
| `OneOverdueMaintenanceMsg` | `1 maintenance record has been open for more than %1 days. Post it when the work is finished.` | `%1 = number of days after which maintenance is overdue` |
| `ReturnedFromMaintenanceMsg` | `%1 %2 is back from maintenance and is available again.` | `%1 = equipment description, or the category code when the description is blank, %2 = equipment number` |
| `ShowWarrantyAlertsActionLbl` | `Show warranty alerts` | |
| `ShowOpenMaintenanceActionLbl` | `Show open maintenance` | |
| `ShowOverdueMaintenanceActionLbl` | `Show overdue maintenance` | |
| `OpenEquipmentCardActionLbl` | `Open equipment card` | |
| `DontShowAgainActionLbl` | `Don''t show again` | |
| `WarrantyNotificationNameTxt` | `Equipment warranty is expiring` | (My Notifications name) |
| `WarrantyNotificationDescTxt` | `Show a notification when the warranty of equipment will expire soon and its warranty alert is still open.` | |
| `OverdueNotificationNameTxt` | `Equipment maintenance is overdue` | |
| `OverdueNotificationDescTxt` | `Show a notification when a maintenance record has been open for more than 14 days without being posted.` | |
| `ReturnedNotificationNameTxt` | `Equipment returned from maintenance` | |
| `ReturnedNotificationDescTxt` | `Show a notification when posting maintenance makes the equipment available again.` | |

The GUIDs above are fixed for this app; use them exactly and never change them after release (they are stored in users'
My Notifications settings).

Procedures:
1. `GetWarrantyNotificationId(): Guid`, `GetOverdueMaintenanceNotificationId(): Guid`,
   `GetReturnedFromMaintenanceNotificationId(): Guid` - return the three locked GUIDs.
2. `ShowEquipmentNotifications(Equipment: Record "EQM Equipment")` - (N-A1, N-B1) in this order: recall the warranty and
   overdue notifications (`RecallNotification(Id)` for both); exit when `not GuiAllowed()` or
   `Equipment.SystemCreatedAt = 0DT` (unsaved); call `SendEquipmentWarrantyNotification(Equipment, Today())` and
   `SendEquipmentOverdueNotification(Equipment, Today())`. Doc: "Shows the warranty and overdue maintenance
   notifications for one piece of equipment and removes those of the previous record."
3. `local SendEquipmentWarrantyNotification(Equipment; ReferenceDate: Date)` - exit unless all are true:
   `IsNotificationEnabled(GetWarrantyNotificationId())`; `Equipment."Warranty End Date" <> 0D`;
   `not Equipment.IsFinalStatus(Equipment.Status)`; DaysRemaining := `Equipment.GetWarrantyDaysRemaining(ReferenceDate)`
   >= 0; `WarrantyAlertMgt.HasOpenAlert(Equipment."No.", Equipment."Warranty End Date")`. Message: DaysRemaining = 0 ->
   `WarrantyExpiresTodayMsg`; = 1 -> `WarrantyExpiresTomorrowMsg`; otherwise `WarrantyExpiresInDaysMsg` with
   DaysRemaining. Id = warranty ID, Scope LocalScope, `SetData(EquipmentNoDataTok, Equipment."No.")`, actions
   `ShowWarrantyAlertsActionLbl` -> handler `ShowWarrantyAlerts`, `DontShowAgainActionLbl` -> handler
   `DisableNotification`; Send.
4. `local SendEquipmentOverdueNotification(Equipment; ReferenceDate: Date)` - exit unless the overdue ID is enabled and
   `MaintenanceMgt.FindOldestOverdueMaintenance(Equipment."No.", ReferenceDate, MaintenanceRecord)`. Message
   `EquipmentMaintenanceOverdueMsg` (record No., equipment name, equipment No.,
   `MaintenanceMgt.CalcDaysOpen(MaintenanceRecord, ReferenceDate)`). SetData equipment No.; actions
   `ShowOpenMaintenanceActionLbl` -> `ShowOpenMaintenance`, Don't show again -> `DisableNotification`; Send. Equipment
   status is not checked (open maintenance of Lost/Disposed equipment still needs posting, Q12).
5. `ShowMaintenanceRecordNotification(MaintenanceRecord: Record "EQM Maintenance Record")` - (N-B2) recall the overdue
   ID; exit when `not GuiAllowed()`, `MaintenanceRecord.SystemCreatedAt = 0DT`, the overdue ID is disabled, or
   `not MaintenanceMgt.IsMaintenanceOverdue(MaintenanceRecord, Today())`. Message `MaintenanceRecordOverdueMsg`; only the
   Don't show again action (Post is on the page); Send.
6. `ShowRoleCenterNotifications()` - (N-A2, N-B3) exit when `not GuiAllowed()`. Warranty: when enabled and
   Count := `WarrantyAlertMgt.CountOpenAlerts()` > 0: message `OneOpenWarrantyAlertMsg` when Count = 1, else
   `OpenWarrantyAlertsMsg`; no SetData; actions Show warranty alerts, Don't show again; Send. Overdue: when enabled and
   Count := `MaintenanceMgt.CountOverdueMaintenance(Today())` > 0: `OneOverdueMaintenanceMsg` /
   `OverdueMaintenanceSummaryMsg` (with `MaintenanceMgt.GetMaintenanceOverdueDays()`); actions
   `ShowOverdueMaintenanceActionLbl` -> `ShowOverdueMaintenance`, Don't show again; Send.
7. `SendReturnedFromMaintenanceNotification(EquipmentNo: Code[20]; StatusBeforePosting: Enum "EQM Equipment Status")` -
   (N-C1) exit when `not GuiAllowed()`, the returned ID is disabled, StatusBeforePosting <> "In Maintenance", or the
   equipment cannot be read (`SetLoadFields(Description, "Category Code", Status)`, `Get`), or its Status <> Available.
   Message `ReturnedFromMaintenanceMsg`; SetData equipment No.; actions `OpenEquipmentCardActionLbl` ->
   `OpenEquipmentCard`, Don't show again; Send.
8. Handlers (global procedures, parameter `Notification: Notification`, doc comment each):
   - `ShowWarrantyAlerts` - EquipmentNo := data when `HasData(EquipmentNoDataTok)`, else blank;
     `WarrantyAlertMgt.ShowOpenAlerts(EquipmentNo)`.
   - `ShowOpenMaintenance` - `MaintenanceMgt.ShowOpenMaintenanceRecords(<data equipment No.>)` (existing procedure).
   - `ShowOverdueMaintenance` - `MaintenanceMgt.ShowOverdueMaintenanceRecords(Today())`.
   - `OpenEquipmentCard` - Equipment `Get(<data>)`; when found, `Page.Run(Page::"EQM Equipment Card", Equipment)`;
     nothing when not found.
   - `DisableNotification` - disables `Notification.Id` for the current user in My Notifications (procedure name from
     the events report). Fallback when Q6 is not available: this handler and every Don't show again action are not
     built.
9. `IsNotificationEnabled(NotificationId: Guid): Boolean` - asks My Notifications for the current user (procedure from
   the events report). Fallback: always true.
10. `RegisterDefaultNotifications()` - registers the three IDs in My Notifications with the Name/Desc labels above,
    enabled by default (procedure from the events report). Called only by codeunit 50113.
11. `local RecallNotification(NotificationId: Guid)` - new Notification variable, set Id, `Recall()`.
12. `local GetEquipmentName(Equipment): Text` - Description, or Category Code when Description is blank.
13. `local SetEquipmentData` / building helpers as needed; keep each send procedure short.

### Codeunit 50113 "EQM Notification Subscribers" (new, conditional on the events report)
`Access = Internal`. XML summary: "Registers the equipment notifications in My Notifications so that users can switch
them off." One event subscriber to the standard My Notifications registration event (exact publisher, event name and
signature from `docs/plans/FR-017-events.md`). Body: one call to `NotificationMgt.RegisterDefaultNotifications()`.
No other logic. If the events report finds no usable event, this codeunit is not created and ID 50113 stays free.

### Codeunit 50108 "EQM Maintenance Mgt." (change)
New internal procedures, placed after `ShowOpenMaintenanceRecords`, each with a doc comment:
1. `GetMaintenanceOverdueDays(): Integer` - returns 14. Doc: "Returns after how many days an open maintenance record is
   overdue."
2. `CalcDaysOpen(MaintenanceRecord: Record "EQM Maintenance Record"; ReferenceDate: Date): Integer` - 0D -> `Today()`;
   returns ReferenceDate - "Maintenance Date" (0 when the date is blank).
3. `IsMaintenanceOverdue(MaintenanceRecord; ReferenceDate: Date): Boolean` - true when Status = Open, "Maintenance
   Date" <> 0D and `CalcDaysOpen(...)` > `GetMaintenanceOverdueDays()`.
4. `SetOverdueMaintenanceFilter(var MaintenanceRecord; ReferenceDate: Date)` - 0D -> `Today()`;
   `SetCurrentKey(Status, "Maintenance Date")`; `SetRange(Status, Open)`; `SetFilter("Maintenance Date", '..%1',
   ReferenceDate - GetMaintenanceOverdueDays() - 1)`. Must select exactly the records for which `IsMaintenanceOverdue`
   is true.
5. `CountOverdueMaintenance(ReferenceDate: Date): Integer` - filter from 4, `Count()`.
6. `FindOldestOverdueMaintenance(EquipmentNo: Code[20]; ReferenceDate: Date; var MaintenanceRecord): Boolean` -
   `Reset()`; `SetCurrentKey("Equipment No.", "Maintenance Date")`; SetRange equipment, Status Open, same date filter as
   4; `FindFirst()` (oldest date first).
7. `ShowOverdueMaintenanceRecords(ReferenceDate: Date)` - filter from 4, `Page.Run(Page::"EQM Maintenance Records",
   MaintenanceRecord)`.

Change `PostWithConfirmation`: after the Confirm returns true and **before** `Codeunit.Run`, read the equipment status
(`SetLoadFields(Status)`, `Get(MaintenanceRecord."Equipment No.")`; when not found keep the enum default). After
`Codeunit.Run`, call `NotificationMgt.SendReturnedFromMaintenanceNotification(MaintenanceRecord."Equipment No.",
StatusBefore)`. Return value and Confirm text unchanged. Update the XML doc: "...and shows a notification when the
equipment is back from maintenance."

### Codeunit 50110 "EQM Warranty Alert Mgt." (change)
New internal procedures after `AcknowledgeAlerts`, no change to existing ones:
1. `HasOpenAlert(EquipmentNo: Code[20]; WarrantyEndDate: Date): Boolean` - key `Equipment`; SetRange "Equipment No.",
   "Warranty End Date", Status = Open; `exit(not IsEmpty())`.
2. `CountOpenAlerts(): Integer` - key `Status`; SetRange Status = Open; `Count()`.
3. `ShowOpenAlerts(EquipmentNo: Code[20])` - SetRange Status = Open; when EquipmentNo <> '' SetRange "Equipment No.";
   `Page.Run(Page::"EQM Warranty Alerts", WarrantyAlert)`.

### Table 50105 "EQM Maintenance Record" (change)
Add `key(StatusDate; Status, "Maintenance Date") { }` after key `EquipmentStatus`. Nothing else.

### Page 50101 "EQM Equipment Card" (change)
- New page variables: `NotificationMgt: Codeunit "EQM Notification Mgt."`, `NotifiedEquipmentNo: Code[20]`,
  `NotificationsChecked: Boolean`.
- New trigger `OnAfterGetCurrRecord` (after `OnNewRecord`): when `not NotificationsChecked` or Rec."No." <>
  NotifiedEquipmentNo: set NotifiedEquipmentNo := Rec."No.", NotificationsChecked := true, call
  `NotificationMgt.ShowEquipmentNotifications(Rec)`. (Re-evaluated only when the record changes, not after every field
  validation.)
- No layout, action or AboutText change.

### Page 50114 "EQM Maintenance Record Card" (change)
- New page variables: `NotificationMgt`, `NotifiedMaintenanceNo: Code[20]`, `NotifiedStatus: Enum "EQM Maintenance
  Status"`, `NotificationsChecked: Boolean`.
- New trigger `OnAfterGetCurrRecord`: when `not NotificationsChecked`, Rec."No." <> NotifiedMaintenanceNo or Rec.Status
  <> NotifiedStatus: store both, set the flag, call `NotificationMgt.ShowMaintenanceRecordNotification(Rec)` (this also
  recalls N-B2 after the record is posted).
- Post action unchanged (N-C1 comes from `PostWithConfirmation`).

### Page 50106 "EQM Equipment Cues" (change)
At the end of `OnOpenPage`, after `SetWarrantyCueFilters`: local `NotificationMgt`; `ShowRoleCenterNotifications()`.

### app.json, translations
- **app.json: no change.** Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf`; commit it. Locked labels (GUIDs, data key) must
  not appear as translatable units.

## Data model and upgrade impact
- No new table or field. One new secondary key on table 50105 (schema change accepted before release; no data change).
- DataClassification: nothing new. Notification data holds only the equipment number (not stored by the app).
- My Notifications rows (standard table) are created per user by the platform/base app when the user opens My
  Notifications or chooses Don't show again; they hold only the GUID and the enabled state.
- Upgrade codeunit: **not needed** (nothing released, version unchanged).
- Volume and cost: card pages run at most two filtered `IsEmpty`/`FindFirst` reads per record change; the cue part runs
  two counts per open (keys `Status` on 50107 and the new `StatusDate` on 50105).

## Events
**Standard events: one subscription, to be verified by al-event-finder before development.**
- Purpose: register the three notifications in My Notifications so users can switch them off, and support "Don't show
  again" and the enabled check.
- What al-event-finder must report (`docs/plans/FR-017-events.md`): the standard object and event raised when My
  Notifications builds its list of notifications with default state; the standard procedures to register a
  notification with a default state, to check whether a notification is enabled for the current user, and to disable
  it; their namespaces (`using` lines) and parameter types; and the permissions a normal user needs on the underlying
  table. Search hints only, **not verified, do not code from these:** table and page "My Notifications", an
  `OnInitializingNotificationWithDefaultState` event, procedures like `InsertDefault`, `IsEnabled`, `Disable`.
- If the report finds no usable API: Q6 fallback (no codeunit 50113, no Don't show again, `IsNotificationEnabled`
  always true). The rest of the plan is unaffected.
- No other standard event is needed: everything else runs in this app's own page triggers and internal codeunits.

Published: **none** (Q10). Existing events are unchanged. FR-017 raises no new event; the existing
`OnAfterPostMaintenanceRecord` and `OnBeforeCompleteMaintenance` still fire as before (N-C1 respects an
`OnBeforeCompleteMaintenance` subscriber that keeps the equipment In Maintenance: no notification then).

## Permissions
| Permission set | Change |
|---|---|
| 50100 EQM - Reader | Add `codeunit "EQM Notification Mgt." = X`, `codeunit "EQM Notification Subscribers" = X` (the second only if the codeunit is built), in the codeunit block after `"EQM Warranty Alert Job"`. |
| 50101 EQM - Manager | No change (includes Reader). |
| 50102 EQM - Administrator | No change. |
| 50103 EQM D365 BASIC (ext) | No change, unless the events report says a normal user lacks permissions on the My Notifications table; then stop and report (do not add standard tabledata to our sets without a decision). |

All reads (equipment, warranty alerts, maintenance records) are already R in Reader. Notifications add no write.
N-C1 appears only to users who can post (Manager), because only they reach `PostWithConfirmation`.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See N-A1, N-A2, N-B1, N-B2, N-B3 | yes | yes | yes |
| Use their Show actions | yes | yes | yes |
| See N-C1 | no (cannot post) | yes | yes |
| Don't show again / My Notifications | yes | yes | yes |

## Compatibility
- AppSource mode, development phase: nothing is released, no Obsolete handling needed.
- New permanent identifiers after the first release: the three notification GUIDs (stored in users' settings). No new
  public object, procedure or event unless the handler fallback makes codeunit 50112 Public (then the five handlers
  become public API; list them in the feature doc).
- Behavior changes: notifications appear on four pages; `PostWithConfirmation` shows a notification after posting.
  No existing rule, field, action, tile or text changes. FR-016 alert generation and FR-012 posting are unchanged.
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-017-equipment-notifications.md` and `docs/help/FR-017-equipment-notifications.md`: the three
    kinds, where they appear, the 14-day overdue rule, that warranty notifications need FR-016 alerts (job queue or
    Generate Alerts) and stop when the alert is acknowledged, how to switch them off.
  - `docs/help/FR-016-warranty-alerts.md`, `docs/help/FR-012-equipment-maintenance-status.md`,
    `docs/help/FR-010-maintenance-registration.md` (and the matching `docs/features/` files): one paragraph each.
  - `README.md` V2 progress: "Automated notifications" -> built, not verified.
  - `CHANGELOG.md`: new top section `## FR-017 Equipment Notifications (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-017 sandbox checks" with NT-SB1 to NT-SB12.

## Test scenarios
**No automated tests in this iteration** (Q11 default, as in FR-003 to FR-016). Test codeunit 50171 "EQM Notification
Tests" is reserved, and the tester step is skipped. The list is the reference for the developer, the reviewer and the
tests written later. Automated tests would use TestPage, `[SendNotificationHandler]` (capture `Notification.Message`,
`Notification.Id` and the data), `[RecallNotificationHandler]` and `[ConfirmHandler]` for posting.

Test data, unless stated: active category LAPTOP; equipment E saved with `Insert(true)`, Description "Laptop", No.
LAP00045, Status Available. T = `Today()`. Warranty alerts created with `GenerateAlerts(T, false, ...)` (FR-016).
"Overdue days" = 14.

Warranty expiring (N-A1, N-A2)
- NT1 Given E with Warranty End Date T + 30 and an Open alert, when the Equipment Card opens on E, then one
  notification with the warranty ID and the text "Warranty for Laptop LAP00045 will expire in 30 days." and the actions
  "Show warranty alerts" and "Don't show again".
- NT2 Given end date T + 1 -> text "...will expire tomorrow."; end date T -> "...expires today." (alert Open).
- NT3 Given end date T + 75 and an Open 90-day alert, then the text says 75 days (actual days, not the interval).
- NT4 (negative) Given end date T + 30 and no alert (generation not run), then no warranty notification.
- NT5 (negative) Given the alert Acknowledged, then no warranty notification.
- NT6 (negative) Given an Open alert for end date T + 30 and the equipment's end date changed to T + 40 (alert not yet
  cancelled), then no warranty notification.
- NT7 (negative) Given an Open alert whose end date is T - 1 (expired, still Open per FR-016 WA17), then no warranty
  notification.
- NT8 (negative) Given an Open alert and E set to Disposed, then no warranty notification.
- NT9 Given Description blank, then the text uses the category code: "Warranty for LAPTOP LAP00045 will expire in 30
  days."
- NT10 Choosing "Show warranty alerts" from N-A1 opens page 50120 filtered to E and Status Open.
- NT11 Given 2 Open alerts, 1 Acknowledged and 1 Cancelled, when the Role Center (or dashboard) opens, then N-A2 says
  "2 warranty alerts are open. Review the warranties that are about to expire."; with exactly 1 Open alert the text is
  "1 warranty alert is open. Review the warranty that is about to expire."; with 0, no N-A2.
- NT12 Choosing "Show warranty alerts" from N-A2 opens page 50120 filtered to Status Open, all equipment.

Overdue maintenance (N-B1, N-B2, N-B3)
- NT13 `GetMaintenanceOverdueDays` = 14. `IsMaintenanceOverdue`: Open record dated T - 15 -> true; T - 14 -> false;
  Posted record dated T - 30 -> false. `CalcDaysOpen` for T - 20 = 20.
- NT14 `SetOverdueMaintenanceFilter` selects exactly the records where `IsMaintenanceOverdue` is true (Open dated T - 15,
  T - 40 in; Open T - 14, T; Posted T - 40 out).
- NT15 Given E with an Open record MR001 dated T - 20, when the Equipment Card opens on E, then N-B1 "Maintenance MR001
  for Laptop LAP00045 has been open for 20 days. Post it when the work is finished." with "Show open maintenance".
- NT16 Given two overdue Open records on E (T - 30 = MR001, T - 20 = MR002), then N-B1 names MR001 with 30 days.
- NT17 (negative) Given the only Open record dated T - 14, then no N-B1.
- NT18 Given both an overdue record and an Open warranty alert on E, then the card shows both notifications (two IDs).
- NT19 "Show open maintenance" opens page 50113 filtered to E and Status Open.
- NT20 Given MR001 Open dated T - 20, when the Maintenance Record Card opens on it, then N-B2 "Maintenance record MR001
  has been open for 20 days. Post it when the work is finished." with only "Don't show again".
- NT21 When MR001 is posted from that card, then N-B2 is recalled; opening a posted record shows no N-B2; a new unsaved
  record shows no N-B2.
- NT22 Given 3 overdue and 2 not overdue Open records, when the Role Center opens, then N-B3 "3 maintenance records have
  been open for more than 14 days. Post them when the work is finished."; with 1 overdue, "1 maintenance record has been
  open for more than 14 days. Post it when the work is finished."; with 0, no N-B3.
- NT23 "Show overdue maintenance" opens page 50113 with Status Open and Maintenance Date ..T - 15, showing exactly the 3.
- NT24 Given an overdue Open record on Lost equipment, then it counts in N-B3 and shows N-B1 on its card (Q12).

Returned from maintenance (N-C1)
- NT25 Given E In Maintenance with one Open record, when the user posts it from the Maintenance Record Card and confirms,
  then E is Available and N-C1 "Laptop LAP00045 is back from maintenance and is available again." with "Open equipment
  card"; the action opens the Equipment Card on E.
- NT26 Same as NT25 from the Equipment Maintenance list (page 50113).
- NT27 (negative) Given two Open records on E, when one is posted, then E stays In Maintenance and no N-C1.
- NT28 (negative) When the user answers No to the post question, then nothing is posted and no N-C1.
- NT29 (negative) Given a subscriber to `OnBeforeCompleteMaintenance` that sets IsHandled, when the last record is
  posted, then E stays In Maintenance and no N-C1.
- NT30 (negative) Given E set to Lost while its maintenance is Open, when the record is posted, then E stays Lost and no
  N-C1.
- NT31 (negative) When codeunit 50109 is run directly (no `PostWithConfirmation`), then no notification and no error.

Switching off (only if the events report confirms the API, Q6)
- NT32 My Notifications lists "Equipment warranty is expiring", "Equipment maintenance is overdue" and "Equipment
  returned from maintenance" with their descriptions, all enabled by default.
- NT33 Choosing "Don't show again" on N-A1 disables the warranty kind: N-A1 and N-A2 no longer appear; N-B1 still
  appears. Re-enabling in My Notifications shows them again.
- NT34 Disabling one user's warranty kind does not affect another user.

General
- NT35 (negative) Validating a field on the Equipment Card (for example Location Code) does not send the notifications
  again (`SendNotificationHandler` called once per record).
- NT36 Moving from E1 (with notifications) to E2 (none) on the card recalls both notifications of E1.
- NT37 (negative) New, unsaved equipment card: no notification.
- NT38 (negative) Without a UI session (`GuiAllowed()` false, for example the warranty job), no notification is sent and
  no error is raised; FR-016 job WA26 still passes.
- NT39 Reader (`TestPermissions = Restrictive`, D365 BASIC + EQM - Reader): N-A1, N-A2, N-B1, N-B2, N-B3 appear and
  their Show actions open the pages without permission errors; Don't show again works.
- NT40 Regression: FR-016 alert generation, acknowledgement and tile counts are unchanged; FR-012 posting (status,
  history entry, Confirm text) is unchanged apart from N-C1.

### Manual sandbox checks (for the user)
- NT-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings (check the GUID labels and the handler
  procedures); `.g.xlf` contains the new texts and no locked labels.
- NT-SB2 Equipment with end date today + 30, Generate Alerts, open the card: the text matches the issue example; try
  + 1, today, + 75.
- NT-SB3 Choose each notification action once; record that the handlers run with `Access = Internal` (else apply the
  fallback and record it).
- NT-SB4 Open maintenance dated 20 days ago: notifications on the Equipment Card and the Maintenance Record Card; post it:
  N-B2 disappears, N-C1 appears.
- NT-SB5 Role Center as Equipment Manager profile: N-A2 and N-B3 appear at the top of the Role Center (sent from the cue
  part); also on the Equipment Dashboard page. Record the order and how they look together.
- NT-SB6 My Settings > My Notifications: the three entries appear; switch one off and back on.
- NT-SB7 Don't show again on each kind; reopen the pages.
- NT-SB8 Non-SUPER Reader: notifications and Show actions work; no permission error on My Notifications.
- NT-SB9 Non-SUPER Manager: post from list and card; N-C1 appears.
- NT-SB10 Navigate through several equipment records on the card with Next/Previous: notifications follow the record.
- NT-SB11 Run the warranty job queue entry: no error from notification code in the background session.
- NT-SB12 Teaching tips and help article texts read correctly in the client.

## Risks and open questions
Open questions (each has the default used in this plan; answer to change it):
- **Q1 Meaning of "overdue maintenance".** Default: an Open maintenance record not posted more than 14 days after its
  Maintenance Date. Alternative: maintenance that is due according to a schedule (Next Maintenance Date or an interval per
  equipment or category); that needs the planned "Maintenance schedules" feature first (new fields, upgrade-free but a
  data model change) and replaces N-B1 to N-B3. **Changes the design.**
- **Q2 Overdue threshold.** Default: 14 days, fixed by `GetMaintenanceOverdueDays`. Alternative: a field "Maintenance
  Overdue Days" on Equipment Setup (table 50102 field 4, page 50103).
- **Q3 Warranty trigger.** Default: an Open FR-016 alert for the current end date (needs the job queue or Generate
  Alerts; acknowledging stops it). Alternative: the FR-015 status Expiring Soon (30 days, no job needed, cannot be
  acknowledged). **Changes N-A1/N-A2 and NT1-NT12.**
- **Q4 Expired warranties.** Default: no notification when the end date has passed, even if the alert is still Open.
  Alternative: "Warranty for %1 %2 expired %3 days ago." until the alert is acknowledged.
- **Q5 Audience of "returned from maintenance".** Default: only the user who posts, right after posting. Alternative: a
  Role Center summary of equipment returned in the last N days (needs a rule and a way to list that equipment).
  **Changes N-C1 and adds objects.**
- **Q6 My Notifications.** Default: register the three kinds, Don't show again on every notification, after
  al-event-finder confirms the API. Fallback/alternative: no registration, no Don't show again (notifications cannot be
  switched off). **Changes codeunit 50113 and NT32-NT34.**
- **Q7 Where shown.** Default: Equipment Card, Maintenance Record Card, after posting, cue part (Role Center and
  dashboard). Not built: Equipment List, Employee Card, an "Overdue Maintenance" tile.
- **Q8 Equipment name in texts.** Default: Description, else Category Code. Alternative: the category's Description
  ("Laptop" as in the issue example), one extra read per notification.
- **Q9 Overdue date basis.** Default: Maintenance Date (visible and filterable). Alternative: the date the record was
  registered (SystemCreatedAt).
- **Q10 Extensibility.** Default: no published event. Alternative: `OnBeforeSendEquipmentNotification(var Notification;
  var IsHandled)` on a public codeunit (permanent API).
- **Q11 Automated tests.** Default: deferred as in FR-003 to FR-016; test codeunit 50171 reserved; NT-SB1 to NT-SB12 are
  the verification.
- **Q12 Overdue on Lost/Disposed equipment.** Default: included (the open record still needs posting). Alternative:
  exclude, like warranty alerts.

Risks:
- R1 Notifications are shown only when a user opens the pages; there is no push to users who do not open the Role
  Center or the cards. Accepted (platform design); the tiles and lists remain.
- R2 Warranty notifications depend on FR-016 alerts: if the job queue entry is not set up, no warranty notification
  appears until a Manager uses Generate Alerts (FR-016 R1).
- R3 The My Notifications API names are unverified; the developer must not start codeunit 50113 or the enabled/disable
  calls before the events report exists.
- R4 Action handlers in an `Access = Internal` codeunit may not be callable; the fallback makes five handlers public API.
- R5 Up to two notifications on the Role Center every time it opens; users who find this noisy can switch them off (Q6).
  Without Q6, they cannot.
- R6 `Today()` is used for days remaining and overdue; users in other time zones may see a day's difference (FR-016 R2).
- R7 N-C1 compares the status read before posting with the status after; a subscriber that changes the status in other
  ways could suppress or allow it unexpectedly. Accepted.
- R8 The three GUIDs become permanent at the first release.
- R9 No automated tests (Q11): regressions are caught only by review and the sandbox checks.
