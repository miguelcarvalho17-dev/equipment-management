# FR-017 Equipment Notifications

## Purpose
Business Central notifications (the bar at the top of a page) tell users about three situations while they work: a warranty that is about to expire, maintenance that has been open too long, and equipment that is back from maintenance. Each notification has an action that opens the records to act on, and each kind can be switched off per user in My Notifications.

Status: describes the code as implemented (uncommitted changes on branch `feature/FR-017-equipment-notifications`). Build result and review verdict are not part of the documenter input: TODO(verify). **No automated tests (deferred, plan decision Q11; test codeunit 50171 reserved, nothing written; the 40 scenarios NT1 to NT40 in docs/plans/FR-017-equipment-notifications.md are a reference only). Nothing was run in a sandbox; checks NT-SB1 to NT-SB12 are open (see "Not verified").** App version stays 29.0.0.0. No new table, field, page or enum; no upgrade codeunit; no published events; one standard event subscribed (events report below).

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Codeunit | 50112 | EQM Notification Mgt. | New, `Access = Internal`. Builds, sends and recalls notifications, action handlers, My Notifications calls. |
| Codeunit | 50113 | EQM Notification Subscribers | New, `Access = Internal`. One subscriber registering the three kinds in My Notifications. |
| Codeunit | 50108 | EQM Maintenance Mgt. | Internal procedures `GetMaintenanceOverdueDays`, `CalcDaysOpen`, `IsMaintenanceOverdue`, `SetOverdueMaintenanceFilter`, `CountOverdueMaintenance`, `FindOldestOverdueMaintenance`, `ShowOverdueMaintenanceRecords`. `PostWithConfirmation` sends the "returned" notification. |
| Codeunit | 50110 | EQM Warranty Alert Mgt. | Internal procedures `HasOpenAlert`, `CountOpenAlerts`, `ShowOpenAlerts`. Existing procedures unchanged. |
| Table | 50105 | EQM Maintenance Record | New key `StatusDate` (Status, "Maintenance Date"). |
| Page | 50101 | EQM Equipment Card | New `OnAfterGetCurrRecord`: warranty and overdue notifications. |
| Page | 50114 | EQM Maintenance Record Card | New `OnAfterGetCurrRecord`: overdue notification. |
| Page | 50106 | EQM Equipment Cues | `OnOpenPage` ends with `ShowRoleCenterNotifications`. The part is hosted on the Equipment Manager Role Center (50110) and the Equipment Dashboard (50109). |
| PermissionSet | 50100 | EQM - Reader | Execute on codeunits 50112 and 50113. |

## Behavior
Reference date is `Today()` (not the work date). Notifications are sent only when `GuiAllowed()` is true, so background sessions (job queue) send nothing and raise no error. A notification never raises an error, message or confirm.

| Kind | Where and when | Text | Actions |
|---|---|---|---|
| Warranty expiring | Equipment Card, when a saved record becomes current | "Warranty for {description or category code} {No.} will expire in {n} days." (also "tomorrow", "expires today") | Show warranty alerts; Don't show again |
| Warranty expiring (summary) | Cue part `OnOpenPage` (Role Center, dashboard) | "{n} warranty alerts are open. Review the warranties that are about to expire." (singular text for 1) | Show warranty alerts; Don't show again |
| Overdue maintenance | Equipment Card, when a saved record becomes current | "Maintenance {No.} for {name} {No.} has been open for {n} days. Post it when the work is finished." | Show open maintenance; Don't show again |
| Overdue maintenance (record) | Maintenance Record Card, when a saved open record becomes current | "Maintenance record {No.} has been open for {n} days. Post it when the work is finished." | Don't show again |
| Overdue maintenance (summary) | Cue part `OnOpenPage` | "{n} maintenance records have been open for more than 14 days. Post them when the work is finished." (singular text for 1) | Show overdue maintenance; Don't show again |
| Returned from maintenance | After posting from the Maintenance Record Card or the maintenance list | "{name} {No.} is back from maintenance and is available again." | Open equipment card; Don't show again |

Rules:
- **Warranty.** Shown when the warranty end date is filled, the equipment is not Lost or Disposed, days remaining (`GetWarrantyDaysRemaining`) are 0 or more, and an **Open** warranty alert (FR-016) exists for the equipment and its current Warranty End Date. The days in the text are the actual days remaining, not the 90/60/30 interval. Acknowledging or cancelling the alert stops the notification. The summary counts all Open alerts (`CountOpenAlerts`).
- **Overdue.** A record is overdue when Status is Open, Maintenance Date is filled and `Today() - "Maintenance Date"` is greater than 14 (`GetMaintenanceOverdueDays`, fixed). 15 days or more is overdue, 14 is not. Posted records are never overdue. The equipment status is not checked, so open maintenance of Lost or Disposed equipment counts. On the Equipment Card the oldest overdue record of the equipment is named.
- **Returned.** `PostWithConfirmation` reads the equipment status after the confirmation and before posting, runs the posting, then calls `SendReturnedFromMaintenanceNotification`. It is shown only when the status was In Maintenance before and is Available after. It is not shown when other open records keep the equipment In Maintenance, when the user answers No, when posting fails, or when codeunit 50109 is run directly. Only users who can post see it.
- **Name in texts.** The equipment Description; the Category Code when the Description is blank.
- **Notification IDs.** One per kind, shared by the card and summary variants, so only one notification of a kind is on a page at a time. Cards recall the previous record's notifications before sending new ones.
- **When the cards re-evaluate.** The Equipment Card only when the record number changes; the Maintenance Record Card when the number or status changes (so the overdue notification is recalled after posting). Field validation does not resend. New, unsaved records (`SystemCreatedAt = 0DT`) get none.
- **Action handlers** `ShowWarrantyAlerts`, `ShowOpenMaintenance`, `ShowOverdueMaintenance`, `OpenEquipmentCard`, `DisableNotification` are global procedures (parameter `Notification: Notification`) of codeunit 50112. They open: Warranty Alerts (50120) filtered to Status Open (and the equipment, when the notification carries one); Equipment Maintenance (50113) filtered to Open records of the equipment; the same list filtered to overdue records; the Equipment Card.

## My Notifications (switching off)
Codeunit 50113 subscribes to page "My Notifications" (1518) `OnInitializingNotificationWithDefaultState` and calls `RegisterDefaultNotifications`, which calls `InsertDefault` on table "My Notifications" for three entries, enabled by default:
| Name | Notification ID (locked, permanent after release) |
|---|---|
| Equipment warranty is expiring | 6F3B9C2E-8A41-4D7B-9E15-2C7A0B5D3F01 |
| Equipment maintenance is overdue | A82D4F6B-1C93-4E58-B7A0-5D9E3C1F7A02 |
| Equipment returned from maintenance | D14E7A9C-3B65-4F2D-8C1E-9A6F0B2D5E03 |

`IsNotificationEnabled` returns `MyNotifications.IsEnabled(Id)` before every send. `DisableNotification` calls `Disable(Id)`; when that returns false (no row yet) it registers the defaults and disables again.

## Extending (events)
Published: none. Subscribed (standard): page "My Notifications" `OnInitializingNotificationWithDefaultState` (codeunit 50113). Everything else runs in this app's own page triggers and internal codeunits. Partners can still react to alerts and posting through the existing events (FR-012 `OnAfterPostMaintenanceRecord`, `OnBeforeCompleteMaintenance`); a subscriber that keeps the equipment In Maintenance suppresses the "returned" notification.

### Events report (docs/plans/FR-017-events.md, condensed)
Searched BC 29 Base Application 29.0.54011.57272 symbols (names and signatures read from SymbolReference.json; no base app source).
- **Recommended and used:** Page 1518 "My Notifications", `OnInitializingNotificationWithDefaultState()`, local IntegrationEvent, no parameters. Confidence medium-high.
- **Standard procedures on Table 1518 "My Notifications"** (namespace `System.Environment.Configuration`): `InsertDefault(NotificationId: Guid; NotificationName: Text[128]; DescriptionText: Text; DefaultState: Boolean)`, `IsEnabled(NotificationId: Guid): Boolean`, `Disable(NotificationId: Guid): Boolean`. Others (`SetStatus`, `IsEnabledForRecord`, per-record filter variants) are not used.
- **Fallback event:** `OnAfterInitializingNotificationWithDefaultState()` on the same page. Not used.
- **Not used:** table events `OnStateChanged`, `OnAfterIsNotificationEnabled` (OnPrem scope).
- **Gaps the report could not verify:** when the page raises the event; that `InsertDefault` keeps an existing user choice; what `IsEnabled` returns when the user has no row yet (the code relies on "enabled by default"); the permissions a normal user needs on the table (report says InherentPermissions `riX`).
- **Verdict:** a suitable event and public API exist; no plan fallback (Q6) applied.

## Permissions
| Permission set | Change |
|---|---|
| 50100 EQM - Reader | `codeunit "EQM Notification Mgt." = X`, `codeunit "EQM Notification Subscribers" = X`. |
| 50101 / 50102 | No change. |
| 50103 D365 BASIC (extension) | No change. No standard tabledata for My Notifications was added. |

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See warranty and overdue notifications, use their Show actions | yes | yes | yes |
| See "returned from maintenance" | no (cannot post) | yes | yes |
| Don't show again / My Notifications | yes | yes | yes |

From code reading, not a sandbox run: TODO(verify) NT-SB8, NT-SB9.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build (105 added lines in the diff). Never edit it by hand. TODO(verify) that the locked labels (GUIDs, data key) are not translation units (NT-SB1).

## Upgrade and compatibility
No stored field or upgrade code; one new secondary key on table 50105 (nothing released). Permanent after release: the three notification GUIDs (stored in users' My Notifications settings). Codeunits 50112 and 50113 are `Access = Internal`; the five handler procedures are global inside the internal codeunit, so they are not partner API. If the sandbox shows the client cannot call them, the plan fallback is `Access = Public` on 50112, which would make the five handlers public API (list them in the release then). No existing rule, field, action or tile changed; FR-016 generation and FR-012 posting are unchanged apart from the notification after posting.

## Known limitations
- Notifications appear only when a user opens the page; there is no push to users who do not.
- Warranty notifications need FR-016 alerts (job queue entry or Generate Alerts) and stop once the alert is acknowledged. Expired warranties get none.
- "Overdue" here means an open record 14 days after the Maintenance Date (not the FR-020 planned-maintenance overdue, Next Maintenance Date before today); there is no maintenance schedule and no setup field.
- `Today()` can differ from the user's date by a day in other time zones.
- Up to two notifications show each time the Role Center or dashboard opens. A user can switch them off in My Notifications.
- No notification on the Equipment List or Employee Card; no "Overdue Maintenance" tile (FR-020 later added an Overdue Maintenance Equipment tile for planned maintenance, a different concept: Next Maintenance Date before today, not open records).
- No automated tests.

## Not verified
Nothing was run in a Business Central sandbox. Open, all TODO(verify):
- The My Notifications registration: that the event fires when the page opens, that the three entries appear and that toggling works (NT-SB6).
- That `IsEnabled` returns true for a user without a row (the "enabled by default" assumption).
- That the action handlers work in codeunit 50112 with `Access = Internal`; otherwise switch to `Access = Public` (NT-SB3).
- Permissions: Reader plus D365 BASIC on My Notifications (read, register, disable) without permission error (NT-SB8).
- Notifications sent from the cue part appear at the top of the Role Center and the Equipment Dashboard, and how two look together (NT-SB5).
- Texts for days remaining 30, 1, 0 and 75; overdue at 14 versus 15 days; posting from card and list (NT-SB2, SB4, SB9); Next/Previous on the card (SB10); the warranty job still runs without error (SB11).
- Build result and review verdict were not part of this step.
- Tests deferred: codeunit 50171 "EQM Notification Tests" is reserved; scenarios NT1 to NT40 in the plan are the specification.

## Discrepancies plan vs code
- `SetOverdueMaintenanceFilter` and `FindOldestOverdueMaintenance` filter Maintenance Date with `<>0D&..(Today - 15)`; the plan wrote `..(Today - 15)`. The code excludes blank dates, matching `IsMaintenanceOverdue`.
- `DisableNotification` has an extra step not in the plan: when `Disable` returns false it registers the defaults and disables again.
- `ShowEquipmentNotifications` recalls the two notifications before the `GuiAllowed()` check (plan order matches).
- Not done in this step: the plan's one-paragraph updates to the FR-016, FR-012 and FR-010 help and feature documents, and the docs/TODO.md section NT-SB1 to NT-SB12. TODO.
