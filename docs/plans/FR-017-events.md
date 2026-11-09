# Event search report: FR-017 Equipment Notifications, My Notifications registration

**Feature:** Register three notification kinds in standard My Notifications (user can switch each off)
**Target:** BC 29 (Base Application 29.0.54011.57272, symbols in app/.alpackages read: yes)  |  Base app source available: no (BASEAPP_SOURCE_PATH not set)
Search terms: notification, my notification, default state, enabled, disable, don't show again.
Note: `.alpackages` at repo root is empty; symbols are in `app/.alpackages`. The script was run on `app/.alpackages`.
Procedure signatures below were read directly from SymbolReference.json of the Base Application (the script lists events only).

## Recommendation
**Subscribe to** `OnInitializingNotificationWithDefaultState` on **Page** 1518 "My Notifications" (publisher is a local IntegrationEvent on the page).
```al
[EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
local procedure OnInitializingNotificationWithDefaultState()
```
Inside, call on **Table** 1518 "My Notifications" (namespace `System.Environment.Configuration`; add `using`):
```al
procedure InsertDefault(NotificationId: Guid; NotificationName: Text[128]; DescriptionText: Text; DefaultState: Boolean)
```
once per kind (three calls, DefaultState = true), with the same three Guids the notification codeunit 50112 uses as `Notification.Id`.
- Use `Page::"My Notifications"` explicitly: a table and a page share the name "My Notifications".
- Moment: subscriber has no parameters and the record is not passed in; use a local `MyNotifications: Record "My Notifications"` variable and call InsertDefault on it.
- Frequency: runs when the user opens the My Notifications page (the page procedure `InitializeNotificationsWithDefaultState` is the public wrapper; it also has `OnAfterInitializingNotificationWithDefaultState`). Cheap; three calls.
- Confidence: **medium-high**. Names, parameters and publisher type are verified in symbols. NOT verified (no source): where/when the page raises the event and that InsertDefault skips existing rows (from memory it inserts only if the Guid is not yet there, so repeated opens do not reset a user's choice). Verify in a sandbox.

## Standard procedures to call (Table 1518 "My Notifications", all public, from symbols)
| Procedure | Signature | Use |
|---|---|---|
| InsertDefault | (NotificationId: Guid; NotificationName: Text[128]; DescriptionText: Text; DefaultState: Boolean) | Registration in the subscriber |
| IsEnabled | (NotificationId: Guid): Boolean | Check before sending a notification |
| Disable | (NotificationId: Guid): Boolean | Handler of the "Don't show again" action |
| SetStatus | (NotificationId: Guid; Enable: Boolean): Boolean | Alternative to Disable/enable |
| IsEnabledForRecord | (NotificationId: Guid; Record: Variant): Boolean | Only for filtered notifications; not needed |
| InsertDefaultWithTableNum / ...AndFilter | (..., TableNum: Integer[, Filters: Text]) | Per-record filter variants; not needed |
Also on the table: IntegrationEvents `OnStateChanged(NotificationId: Guid; NewEnabledState: Boolean)` and `OnAfterIsNotificationEnabled(NotificationId: Guid; var IsNotificationEnabled: Boolean; Record: Variant)` (scope OnPrem only; do not use).
The table has InherentPermissions `riX`, so users can read and insert; `Disable`/`SetStatus` modify the user's own row (permission set 50100 should still be checked by the developer; not verified).

## Alternatives considered
| Candidate | Why ranked lower |
|---|---|
| Page 1518 `OnAfterInitializingNotificationWithDefaultState()` | Same moment, fires after base registrations; no benefit, and it is meant for work that depends on the standard defaults. Valid fallback. |
| Calling `InsertDefault` lazily on first send (no event) | Entry would not appear in My Notifications until a notification was shown; also bypasses the standard registration pattern. |
| Own enable flag in an EQM setup/user table | Duplicates the standard feature; rejected by plan (no new table). |

## Published events found (from symbols)
| Object | Event | Signature | Relevant? |
|---|---|---|---|
| Page 1518 "My Notifications" | OnInitializingNotificationWithDefaultState | () | Yes, recommended |
| Page 1518 "My Notifications" | OnAfterInitializingNotificationWithDefaultState | () | Fallback |
| Table 1518 "My Notifications" | OnStateChanged | NotificationId: Guid, NewEnabledState: Boolean | No (only if we must react to toggling) |
| Table 1518 "My Notifications" | OnAfterIsNotificationEnabled | NotificationId: Guid, var IsNotificationEnabled: Boolean, Record: Variant | No (OnPrem scope) |

## Gaps and risks
- Behavior of IsEnabled when the user never opened My Notifications (no row yet) is not verified in symbols. From memory it returns true (default enabled); confirm in the sandbox, since the plan relies on "enabled by default". If it returned false, call InsertDefault before IsEnabled as a guard.
- Event raise point unverified (no source). Run Event Recorder or test in a sandbox: open Settings > My Notifications and confirm the three entries appear, toggling works, and "Don't show again" (Disable) flips the entry.
- AppSource: this is the documented standard pattern, public API, low break risk.
- Verdict: a suitable event and API exist; no fallback (plan Q6) needed unless sandbox verification fails.
