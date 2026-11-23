# Notification providers (contributor help)

This article is for people who change this repository. It is not an end-user article. The feature doc is [FR-064](../features/FR-064-feature-interfaces.md).

## What changes for users
Nothing. The equipment notifications show, act and switch off in My Notifications as before. The user guide is [Notifications and monitoring](../user-guide/notifications-and-monitoring.md).

## Where the notifications are sent
Codeunit "EQM Notification Mgt." builds each notification as a payload and sends it through a provider. The provider contract is the interface "EQM INotification Provider" and the channels are the enum "EQM Notification Provider". Both are in `app/src/Notifications/`. Phase 1 has one provider, the Business Central notification.

## Before you change the notification code
- Keep the gating in codeunit "EQM Notification Mgt.": `GuiAllowed`, the Notifications feature, My Notifications and the business conditions. A provider must not repeat them.
- Keep the notification IDs, the messages, the data key `EquipmentNo`, and the action captions and their order. The IDs are stored in users' My Notifications settings, so changing one breaks the switches of existing users.
- Keep the handler codeunit and the handler method names. The platform calls the actions by these names.
- A provider method must be public.

## Tests that cover it
| Test codeunit | What it checks |
|---|---|
| "EQM Notification Tests" | The payload, the Business Central provider and the dispatch of the equipment notifications through the spy provider |
| "EQM Process Integration Tests" | The real Business Central notifications, as before |

Results are in the CI log of the pull request. The tests are not run locally by the documentation step.
