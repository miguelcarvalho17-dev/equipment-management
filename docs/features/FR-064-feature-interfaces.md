# FR-064 Feature Interfaces

## Purpose
The equipment notifications of FR-017 were sent directly from the notification codeunit. FR-064 puts them behind an internal interface, "EQM INotification Provider", so that a delivery channel can be added or swapped without changing the notification rules. Phase 1, this change, delivers the interface, a channel-neutral payload and the Business Central provider. All six notification paths send through the provider. Behaviour does not change.

Plan: `docs/plans/FR-064-feature-interfaces.md` (approved).

## Status
- Branch `feature/FR-064-feature-interfaces`. Files not committed at the time of writing.
- Phase 1 only. The email and Teams providers and the public API are later phases (see [Later phases](#later-phases)).
- No change to `app.json`; version stays 29.0.0.0. No table, field, page, event or upgrade code. No HTTP call, secret or dependency.

## Objects
| Type | ID | Name | Access | Role |
|---|---|---|---|---|
| Codeunit | 50146 | EQM Notification Payload | Internal | Channel-neutral content of one notification: ID, message, data and ordered actions. New. |
| Interface | n/a | EQM INotification Provider | Internal | The delivery contract: `Send` and `Recall`. New. |
| Codeunit | 50147 | EQM BC Notification Provider | Internal | Delivers the payload as a Business Central notification. Implements the interface. New. |
| Enum | 50114 | EQM Notification Provider | Internal, `Extensible = false` | The channels. Value 0 "Business Central" maps to the Business Central provider. New. |
| Codeunit | 50112 | EQM Notification Mgt. | Internal | Builds the payloads, keeps the gating, and sends and recalls through the provider. Changed internally; no procedure signature changed. |
| Permission set | 50100 | EQM - Reader | - | Execute on 50146 and 50147. Operator, Manager and Administrator inherit it. API Consumer gets nothing. |
| Codeunit (test) | 50171 | EQM Notification Tests | Test | Nine tests of the provider, the payload and the dispatch. New. |
| Codeunit (test) | 50174 | EQM Notif. Provider Spy | Internal | Test double of the provider. Records what is sent and recalled. New. |

## Interface contract
```al
interface "EQM INotification Provider"
{
    procedure Send(var NotificationPayload: Codeunit "EQM Notification Payload");
    procedure Recall(NotificationId: Guid);
}
```

Rules for a provider:
- **Send** receives a complete notification and delivers its message, data and actions on the provider's channel. Send does not decide whether a notification is sent.
- **Recall** removes a notification delivered earlier, by ID. A channel that cannot recall does nothing. The caller recalls IDs before it evaluates a page, so Recall can be called for an ID that was never sent.
- **Gating stays in the caller.** Before it calls Send, "EQM Notification Mgt." checks, in this order: `GuiAllowed`, the Notifications feature, `SystemCreatedAt` of the record, My Notifications, the Warranty Alerts feature where it applies, and the business conditions. A provider does not repeat these checks.
- **The payload is read only through its getters.** A provider does not change the payload.

### Payload
The payload has no Scope. The Business Central provider sets `LocalScope`, because that is the only scope used today.

| Methods | Purpose |
|---|---|
| `SetNotificationId`, `GetNotificationId` | The ID of the notification. Each kind keeps its ID: warranty, overdue maintenance and returned from maintenance. |
| `SetMessage`, `GetMessage` | The message text. |
| `SetData(DataKey, DataValue)`, `GetDataKeys`, `GetData` | Data values. Setting a key again replaces its value. `GetData` returns blank for a key that is not set. Today only `EquipmentNo` is set, on the warranty, overdue (equipment card) and returned notifications. |
| `AddAction(Caption, HandlerCodeunitId, HandlerMethodName)`, `GetActionCount`, `GetAction(Index, ...)` | The actions, in the order they were added. Index starts at 1. |

### Action handlers
The handlers stay in codeunit 50112 with their names: `ShowWarrantyAlerts`, `ShowOpenMaintenance`, `ShowOverdueMaintenance`, `OpenEquipmentCard` and `DisableNotification`. The payload carries the handler codeunit ID and the method name. The Business Central provider passes them to the platform `Notification.AddAction`, which calls the handler when the user clicks the action.

### Paths through the provider
| Path | Procedure in 50112 | Notification |
|---|---|---|
| Warranty expiring, equipment card | `SendEquipmentWarrantyNotification` | Warranty |
| Overdue maintenance, equipment card | `SendEquipmentOverdueNotification` | Overdue maintenance |
| Overdue maintenance, maintenance record card | `ShowMaintenanceRecordNotification` | Overdue maintenance |
| Warranty summary, Role Center and dashboard | `SendOpenWarrantyAlertsNotification` | Warranty |
| Overdue summary, Role Center and dashboard | `SendOverdueMaintenanceSummaryNotification` | Overdue maintenance |
| Returned from maintenance | `SendReturnedFromMaintenanceNotification` | Returned |
| Recall of the card notifications | `RecallNotification` | Warranty, overdue, returned |

The texts, IDs, actions and their order are the same as in [FR-017](FR-017-equipment-notifications.md).

### Provider selection in phase 1
Phase 1 has no setup field. `EnsureProvider` in codeunit 50112 sets the "Business Central" value of the enum the first time a notification is sent or recalled. Tests replace the provider with the internal procedure `SetProvider`. The test app reaches it through `internalsVisibleTo`.

## How to add a provider (phase 1)
Until phase 4 adds a choice in setup, a new provider is selected in code. Steps:

1. **Create the provider codeunit.** It is `Access = Internal` and declares `implements "EQM INotification Provider"`. Its `Send` reads the payload through the getters and delivers it. Its `Recall` removes the notification by ID, or does nothing when the channel cannot recall. Do not repeat the gating from the caller.
2. **Declare `Send` and `Recall` as public procedures.** Microsoft Learn requires an implementing method to be public: AL0920 is the warning and AL0921 the error that replaces it.
3. **Add a value to the enum** `EQM Notification Provider` with `Implementation = "EQM INotification Provider" = "<your codeunit>"`. Use a value number that is not used yet. Do not reuse a removed value number.
4. **Select the provider** in `EnsureProvider` in codeunit 50112. Phase 1 sends each notification to one provider only.
5. **Grant execute** on the new codeunit in the permission set `EQM - Reader`, as for 50146 and 50147. Do not grant it to API Consumer.
6. **Add the captions** to the translation files: run `al_build` on `app/`, then `python3 .github/scripts/xlf_sync.py sync`, and translate the new units into pt-PT and es-ES.
7. **Register the codeunit** in `.github/coverage/coverage-register.json` under `scope.businessLogic.codeunits`.
8. **Test the provider.** Follow test codeunit 50171: call `Send` and `Recall` on the provider directly, as tests T1 to T5 do. Use the spy (50174) in dispatch tests, so no real notification is shown. Keep the real notification tests in 50158 as the regression guard.
9. **Run the repository checks** (`repo_checks.py`) and wait for the CI result.

## Verification status
- **AL build:** the compile result is not part of this documentation step. Check the build log of the pull request and the `al_getdiagnostics` result.
- **Tests:** not executed locally. CI result pending. The new tests are the nine in test codeunit 50171. The regression guards are 50158, 50199, 50161, 50159, 50162 and 50153.
- **Repository checks:** `repo_checks.py` not run by al-docs. Checks 1 (object IDs), 5 (coverage register) and 7 (language files) are the ones this change affects.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the affix, the captions, that no public surface changed, and the schema check (additions only).
- **Symbols:** `al_symbolsearch` was not used for the new calls (no AL project was loaded when the plan was written). The platform members are confirmed on Microsoft Learn.
- **Sandbox:** nothing is checked in a Business Central sandbox. The notifications are expected to look and behave as before; this is not yet seen in a session.

## Open items
- **Test spy against an internal interface.** The plan lists as a risk that the test app may not implement an internal interface through `internalsVisibleTo`. The CI build result settles this.
- **Phase 1 has one provider per send.** There is no fan-out to several channels.

## Later phases
- **Phase 2, email provider.** Built on the System Application email module. It needs decisions from the user first: who receives the email, which notifications send an email, and the opt-in rules. See [extending email](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extending-email). Stop list: user decision.
- **Phase 3, Teams.** A Power Automate flow on the business events of [FR-029](FR-029-business-events.md) and [FR-031](FR-031-power-automate-support.md). This phase is documentation and a flow template only. An AL webhook provider needs HTTP and a secret, which are on the stop list.
- **Phase 4, public API.** A public interface and payload, an extensible enum with `DefaultImplementation` and `UnknownValueImplementation`, a provider choice in setup, and channel gating moved into the provider. A public contract cannot be removed after release. New interface methods can get a default body, because runtime 18.0 supports default interface methods ([interfaces in AL](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al)).

## Related
[Help](../help/FR-064-feature-interfaces.md), [FR-017](FR-017-equipment-notifications.md), [FR-029](FR-029-business-events.md), [FR-031](FR-031-power-automate-support.md), [Extension structure](../architecture/extension-structure.md), [Testing strategy](../architecture/testing-strategy.md), [Notifications and monitoring (user guide)](../user-guide/notifications-and-monitoring.md)
