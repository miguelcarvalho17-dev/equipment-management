# FR-064 Feature Interfaces — Plan

> Request (verbatim): FR-064 Feature Interfaces
> Status: **approved**

## Request
Put the existing FR-017 in-app notification code behind an interface ("EQM INotification Provider") so delivery channels can be swapped or added. Phase 1 delivers the interface, a neutral notification payload, and the Business Central notification provider, and sends all six existing notification paths through it. Existing behaviour stays exactly the same. Email and Teams providers are later phases: both need business rules the issue does not give, and Teams would need HTTP (stop list).
Target: AppSource

## Definition of done
- [ ] Interface "EQM INotification Provider" has `Send(var NotificationPayload: Codeunit "EQM Notification Payload")` and `Recall(NotificationId: Guid)`.
- [ ] Enum 50114 "EQM Notification Provider" implements the interface; only value 0 "Business Central" maps to codeunit 50147 "EQM BC Notification Provider".
- [ ] Codeunit 50112 "EQM Notification Mgt." declares no `Notification` variable except in action-handler and `DisableNotification` parameters. All six send paths and `RecallNotification` go through the provider.
- [ ] No procedure signature in 50112 or 50113 changes. Gating order unchanged: GuiAllowed, Notifications feature, SystemCreatedAt, My Notifications, Warranty Alerts feature, business conditions.
- [ ] Notification IDs, messages, `EquipmentNo` data key, action captions/order, handler codeunit 50112, handler method names and LocalScope identical to today.
- [ ] Existing notification tests (50158: 8 tests; 50199 returned notification; 50161/50159 DisableNotification) pass unchanged in CI.
- [ ] Test codeunit 50171 "EQM Notification Tests" and spy 50174 compile; their 9 tests are written.
- [ ] Reader has X on 50146 and 50147 (test 50162 checks this).
- [ ] pt-PT and es-ES XLIFF complete for the 2 new enum captions (repo check 7).
- [ ] Coverage register lists 50146 and 50147; `repo_checks.py` shows no errors.
- [ ] Nothing changes in app.json; no new permission set, HTTP, or dependency.

## Out of scope
- Email provider (phase 2): needs recipient/opt-in/email-scenario rules (user decision).
- Teams provider (phase 3): a webhook needs HTTP and a secret (stop list). In-scope route: Power Automate flow on existing FR-029/FR-031 business events, no AL change.
- Public API (phase 4): public interface/payload, Extensible enum, setup field to choose providers.
- Channel gating (GuiAllowed, My Notifications) stays out of the provider until phase 4.
- No change to My Notifications registration (50113), feature gating, pages 50101/50106/50114, business events or Power Automate code.

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Codeunit | 50146 | EQM Notification Payload | New (Internal) | app/src/Notifications/EQMNotificationPayload.Codeunit.al |
| Interface | n/a | EQM INotification Provider | New (Internal) | app/src/Notifications/EQMINotificationProvider.Interface.al |
| Codeunit | 50147 | EQM BC Notification Provider | New (Internal, implements interface) | app/src/Notifications/EQMBCNotificationProvider.Codeunit.al |
| Enum | 50114 | EQM Notification Provider | New (Internal, Extensible = false, implements interface) | app/src/Notifications/EQMNotificationProvider.Enum.al |
| Codeunit | 50112 | EQM Notification Mgt. | Changed (internal refactor, no signature change) | app/src/Notifications/EQMNotificationMgt.Codeunit.al |
| PermissionSet | 50100 | EQM - Reader | Changed (+2 codeunits X) | app/src/Permissions/EQMReader.PermissionSet.al |
| XLIFF | n/a | g / pt-PT / es-ES | Changed (+2 units) | app/Translations/ |
| JSON | n/a | coverage register | Changed (+50146, +50147) | .github/coverage/coverage-register.json |
| Codeunit (test) | 50174 | EQM Notif. Provider Spy | New (SingleInstance, implements interface) | test/src/EQMNotifProviderSpy.Codeunit.al |
| Codeunit (test) | 50171 | EQM Notification Tests | New (Subtype = Test) | test/src/EQMNotificationTests.Codeunit.al |

ID choice: `al_getnextobjectid` reported no AL project loaded, so IDs come from a source scan (codeunits in use 50103–50122, 50130–50145, 50149; enums 50100–50113; 50123–50129 API reserve). 50171 and 50174 are earlier reservations never built; the test range has no unreserved IDs left.

## Events and standard symbols
Only platform `Notification` members already used in 50112 (Id, Message, Scope, SetData, AddAction, Send, Recall), `NotificationScope::LocalScope`, enum `implements` with `Implementation =` (runtime 5.0+), interface `Access = Internal` (runtime 4.0+). Not verified with `al_symbolsearch` (no project loaded); confirmed on Microsoft Learn. No new base-app event or procedure.

## Steps
All new app files start with `namespace MiguelCarvalho.EquipmentManagement;`, with `/// <summary>` on the object and every non-local procedure.

1. **EQMNotificationPayload.Codeunit.al (50146).** `Access = Internal`, not SingleInstance. Globals: `NotificationId: Guid; MessageText: Text; DataValues: Dictionary of [Text, Text]; ActionCaptions: List of [Text]; ActionCodeunitIds: List of [Integer]; ActionMethodNames: List of [Text]`. Internal procedures: `SetNotificationId`, `GetNotificationId`, `SetMessage`, `GetMessage`, `SetData(DataKey, DataValue)` (`DataValues.Set`), `GetDataKeys(): List of [Text]`, `GetData(DataKey): Text` ('' when missing, via `DataValues.Get` Boolean), `AddAction(ActionCaption, HandlerCodeunitId, HandlerMethodName)`, `GetActionCount`, `GetAction(ActionIndex; var ActionCaption; var HandlerCodeunitId; var HandlerMethodName)`. No labels.
2. **EQMINotificationProvider.Interface.al.** `interface "EQM INotification Provider"`, `Access = Internal`. `procedure Send(var NotificationPayload: Codeunit "EQM Notification Payload");` `procedure Recall(NotificationId: Guid);` Recall does nothing when the channel cannot recall.
3. **EQMBCNotificationProvider.Codeunit.al (50147).** `implements "EQM INotification Provider"`, `Access = Internal`. `Send`: build local `Notification` with Id, `Scope := LocalScope`, Message; `foreach` data key → `SetData`; loop actions → `AddAction`; `Notification.Send()`. `Recall`: `Notification.Id := NotificationId; Notification.Recall();`. No gating here; caller does it as today.
4. **EQMNotificationProvider.Enum.al (50114).** `implements "EQM INotification Provider"`, `Caption = 'Equipment Notification Provider'; Extensible = false; Access = Internal;` `value(0; "Business Central") { Caption = 'Business Central notification'; Implementation = "EQM INotification Provider" = "EQM BC Notification Provider"; }`. No DefaultImplementation/UnknownValueImplementation in phase 1.
5. **EQMNotificationMgt.Codeunit.al (changed, only these edits).**
   - a) Globals `NotificationProvider: Interface "EQM INotification Provider"; IsProviderSet: Boolean;`
   - b) `internal procedure SetProvider(NewProvider: Interface "EQM INotification Provider")` (test seam) and `local procedure EnsureProvider()` (default: enum value "Business Central" assigned via a local enum variable).
   - c) `local procedure SendThroughProvider(var NotificationPayload: Codeunit "EQM Notification Payload")` → `EnsureProvider(); NotificationProvider.Send(NotificationPayload);`
   - d) `RecallNotification` body → `EnsureProvider(); NotificationProvider.Recall(NotificationId);`
   - e) In the six send paths (`SendEquipmentWarrantyNotification`, `SendEquipmentOverdueNotification`, `ShowMaintenanceRecordNotification`, `SendOpenWarrantyAlertsNotification`, `SendOverdueMaintenanceSummaryNotification`, `SendReturnedFromMaintenanceNotification`) replace local `Notification` with `NotificationPayload`: `Id :=` → `SetNotificationId`, `Message :=` → `SetMessage` (same branches), `SetData` → `NotificationPayload.SetData`, `AddAction` unchanged args and order, delete `Scope` line, `Send()` → `SendThroughProvider`. Every `exit` guard stays. Data only where it is set today (two equipment paths and the returned path).
   - f) Action handlers, `GetNotificationEquipmentNo`, labels, usings, object summary kept; add one summary sentence about the provider.
6. **EQMReader.PermissionSet.al.** After `codeunit "EQM Notification Subscribers" = X,` add `codeunit "EQM Notification Payload" = X,` and `codeunit "EQM BC Notification Provider" = X,`. Not API Consumer.
7. **Build and translations.** `al_build` on app/ (regenerates `.g.xlf`; if no project loaded use the alc fallback from DECISIONS FR-051/055). Then `python3 .github/scripts/xlf_sync.py sync`; translations: 'Equipment Notification Provider' pt-PT 'Fornecedor de notificações de equipamento', es-ES 'Proveedor de notificaciones de equipo'; 'Business Central notification' pt-PT 'Notificação do Business Central', es-ES 'Notificación de Business Central'. Then `xlf_sync.py check`.
8. **coverage-register.json.** Add 50146 and 50147 to `scope.businessLogic.codeunits` after 50145.
9. **test/src/EQMNotifProviderSpy.Codeunit.al (50174).** `implements "EQM INotification Provider"`, `SingleInstance = true`, `Access = Internal`. Copies payload contents into globals on `Send`; records ids on `Recall`. Readers: `Reset`, `CountSent(Id)`, `SentCount`, `RecallCount`, `GetLastMessage`, `GetLastData(DataKey)`, `GetLastActionCount`, `GetLastAction(...)`.
10. **test/src/EQMNotificationTests.Codeunit.al (50171).** Mirror 50158 header/helpers (`Initialize`, `NextId`, `CreateCategory`, `CreateEquipment`, `CreateEquipmentWithWarrantyAlert`), Locked Tok labels, handler globals, `SendNotificationHandler` and `RecallNotificationHandler`. In T6–T9 `NotificationMgt` is a local variable so `SetProvider` cannot leak.
11. **Compile test/ and run checks.** Compile test/ against fresh app symbols; run `python3 .github/scripts/repo_checks.py --base origin/main`. Report "Not verified: tests not executed locally, CI result pending".
12. **Docs (al-docs).** This plan file, `docs/features/FR-064-feature-interfaces.md`, `docs/help/FR-064-feature-interfaces.md` (no user-visible change), CHANGELOG `## FR-064`, update object counts in `docs/architecture/extension-structure.md`.

## Tests
Codeunit 50171, all `[TransactionModel(TransactionModel::AutoRollback)]`.
- **T1 BusinessCentralProviderSendsThePayload** (SendNotificationHandler): payload with id, message, data key/value, one action → `Provider.Send`; handler sees same Id, Message, data.
- **T2 BusinessCentralProviderSendsNoDataWhenPayloadHasNone** (negative): HasData false.
- **T3 BusinessCentralProviderRecallsById** (RecallNotificationHandler): handler sees the Guid.
- **T4 PayloadKeepsActionsInOrder**: two actions returned in insertion order.
- **T5 NewPayloadIsEmpty** (negative): null Id, empty message, 0 actions, 0 keys, GetData('') for unknown key.
- **T6 EquipmentNotificationsAreDispatchedThroughTheProvider**: spy gets exactly 1 Send for warranty notification Id; message contains equipment No.; data `EquipmentNo`; 2 actions, first `ShowWarrantyAlerts`; RecallCount = 2; no real notification sent.
- **T7 FeatureOffDispatchesNothing** (negative): Notifications feature off → SentCount 0, RecallCount 2.
- **T8 ReturnedNotificationKeepsTheActionContract**: 1 Send, data EquipmentNo, actions `OpenEquipmentCard` then `DisableNotification`.
- **T9 NoReturnedNotificationWhenNotFromMaintenance** (negative): SentCount 0.

Regression guards (must pass unchanged): 50158, 50199 (~390–415), 50161, 50159, 50162, 50153 and repo check 7.

## Assumptions
- Existing tests assume `GuiAllowed()` is true in the runner.
- Internal enum still gets captions (AppSource) and the repo's other internal enums have them; "Business Central" is a product name.
- No `this` or Interface return types; `EnsureProvider` assigns via a local enum variable.
- Scope is always LocalScope today, so the provider sets it and the payload does not carry it.

## DECISIONS
- FR-064 scope | Phase 1 = interface + payload + Business Central provider, no behaviour change, over also building Email and Teams now (stop-list: business rules, HTTP/secret) | Reversible: yes
- FR-064 Teams | Power Automate flow on existing FR-029/FR-031 business events as the in-scope Teams route (phase 3, docs only) over an AL webhook provider | Reversible: yes
- FR-064 API surface | `Access = Internal` for interface, payload, provider, enum; `Extensible = false`. Public AppSource contracts are permanent; shape them after two real implementations. Runtime 18 default interface methods make the later step non-breaking | Reversible: yes (internal→public non-breaking, reverse not)
- FR-064 contract | Payload codeunit (id, message, data, ordered actions) over primitive parameters or the platform Notification type | Reversible: yes
- FR-064 gating | GuiAllowed, feature, My Notifications and business conditions stay in "EQM Notification Mgt." | Reversible: yes
- FR-064 action handlers | Stay on codeunit 50112; payload carries handler codeunit ID and method | Reversible: yes
- FR-064 test seam | Internal `SetProvider(Interface)` on 50112 plus SingleInstance spy in test app, over an InternalEvent seam | Reversible: yes
- FR-064 naming | Interface "EQM INotification Provider", enum "EQM Notification Provider" | Reversible: yes until made public
- FR-064 permissions | X on 50146/50147 in EQM - Reader only (inherited by Operator, Manager, Administrator), not API Consumer | Reversible: yes
- FR-064 IDs | Enum 50114, codeunits 50146/50147, tests 50171/50174 (unbuilt reservations), from a source scan because the AL MCP had no project loaded | Reversible: yes

## Risks
- **Internal interface from the test app.** Not confirmed that `internalsVisibleTo` lets a friend module implement an internal interface. Mitigation: if the compiler rejects the spy or `SetProvider` calls, make nothing public; drop spy and T6–T9, keep T1–T5 and 50158 as dispatch regression, report as a deviation.
- **Codeunit value semantics** with interface assignment: spy is SingleInstance, payload parameter is `var`.
- **Behaviour drift.** Reviewer diffs each of the six paths: guards, `exit`s, messages, `StrSubstNo` args, action order and methods, `SetData` only where it was.
- **Unassigned interface variable.** Reviewer checks `SendThroughProvider` and `RecallNotification` both call `EnsureProvider`.
- **No `al_symbolsearch`/`al_getnextobjectid`.** Reviewer runs `repo_checks.py` check 1 (duplicate IDs).
- **Translations.** Check 7 fails without step 7; use `al_build`, not `al_compile`.
- No separate AppSource validation runs; reviewer checks affix, captions, no public surface change, schema check sees only additions.
- No data written: no locking or multi-company impact.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-access-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-implementation-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0067
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/notification/notification-data-type
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/notification/notification-addaction-string-integer-string-method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-notifications-developing
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extending-email
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/powerplatform/power-automate-overview
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/business-events-overview

## Later phases
- Phase 2: Email provider via System Application Email module (needs recipient, which-notifications and opt-in rules from the user).
- Phase 3: Teams via Power Automate flows on FR-029/FR-031 business events (docs/flow template only).
- Phase 4: public interface and payload, Extensible enum with DefaultImplementation/UnknownValueImplementation, provider selection in setup, channel gating moved into provider; new interface methods get default bodies.
