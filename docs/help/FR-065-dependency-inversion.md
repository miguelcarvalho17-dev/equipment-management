# Feature checks through an interface (contributor help)

This article is for people who change this repository. It is not an end-user article. The feature doc is [FR-065](../features/FR-065-dependency-inversion.md).

## What changes for users
Nothing. The equipment features, notifications, integration events and the background jobs work as before. The user guide is [Notifications and monitoring](../user-guide/notifications-and-monitoring.md).

## Where the feature checks are asked
The interface "EQM IFeature Availability" answers one question: is an optional feature turned on. It is in `app/src/Features/`. Its default implementation is codeunit "EQM Feature Mgt.", which reads the Feature Setup table. Three business logic codeunits ask through the interface: "EQM Notification Mgt.", "EQM Integration Event Mgt." and "EQM Monitoring Job Runner". Pages still call "EQM Feature Mgt." directly.

## Before you change the feature code
- Keep the checks of each codeunit in their order. The interface answers only the feature switch. The Equipment Setup switch for API integration, and the notification gates, stay in the caller.
- Route every new feature check through the local helper `IsFeatureEnabled`, so the interface variable is assigned first.
- A new implementation of the interface must be public for its methods (AL0921). Keep it internal.
- To replace the answer in a test, call the internal procedure `SetFeatureAvailability` of the codeunit under test, with a test double such as the stub "EQM Feature Avail. Stub".

## Tests that cover it
| Test codeunit | What it checks |
|---|---|
| "EQM Feature Mgt. Tests" | The default implementation through the interface, and the injected answers for the integration events |
| "EQM Notification Tests" | An injected answer for the notifications |
| "EQM Background Process. Tests" | An injected answer for the calculation job, and that it reaches the inner job runner |

Results are in the CI log of the pull request. The tests are not run locally by the documentation step.
