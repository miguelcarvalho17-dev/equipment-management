# FR-065 Dependency Inversion

## Purpose
The business logic codeunits asked "EQM Feature Mgt." directly whether an optional feature was turned on. A test could change the answer only by writing rows in the Feature Setup table. FR-065 puts the question behind an internal interface, "EQM IFeature Availability", with one method, `IsEnabled`. Three codeunits now ask through the interface: "EQM Notification Mgt.", "EQM Integration Event Mgt." and "EQM Monitoring Job Runner". Their default answer is still "EQM Feature Mgt.", so the behaviour does not change. Tests can inject another answer. This is the first phase of the work in issue #106 and supports the mockable unit tests of FR-045.

Plan: `docs/plans/FR-065-dependency-inversion.md` (approved).

## Status
- Branch `feature/FR-065-dependency-inversion`. Files not committed at the time of writing.
- Phase 1 only: feature activation. The telemetry sink, the error log writer and the notification preference and query seams are later phases (see [Later phases](#later-phases)).
- No change to `app.json`; version stays 29.0.0.0. No table, field, page, enum, event, permission set, translation or upgrade change. No new codeunit or enum in the app. No HTTP call, secret or dependency.

## Objects
| Type | ID | Name | Access | Role |
|---|---|---|---|---|
| Interface | n/a | EQM IFeature Availability | Internal | Answers whether a feature is turned on: `IsEnabled`. New. |
| Codeunit | 50138 | EQM Feature Mgt. | Internal | Default implementation of the interface. `IsEnabled` is now a public procedure of the codeunit. Its parameters and body are unchanged. Changed. |
| Codeunit | 50112 | EQM Notification Mgt. | Internal | Asks through the interface for each gate. Internal `SetFeatureAvailability`. Changed internally; no existing signature changed. |
| Codeunit | 50122 | EQM Integration Event Mgt. | Internal | Asks through the interface for the API Integration feature. Internal `SetFeatureAvailability`. Changed internally. |
| Codeunit | 50143 | EQM Monitoring Job Runner | Internal | Asks through the interface for the Warranty Alerts and Maintenance Planning features. Internal `SetFeatureAvailability`; `RunJob` passes an injected answer to the inner job runner. Changed internally. |
| Codeunit (test) | 50170 | EQM Feature Avail. Stub | Internal | Test double of the interface. Answers from memory and records which features were asked. Single instance. New. |
| Codeunit (test) | 50198 | EQM Feature Mgt. Tests | Test | Five new tests (F1, F2, I1, I2, I3). Initialize resets the stub. Changed. |
| Codeunit (test) | 50171 | EQM Notification Tests | Test | Two new tests (N1, N2). Changed. |
| Codeunit (test) | 50172 | EQM Background Process. Tests | Test | Two new tests (R1, R2). Changed. |

## Interface contract
```al
interface "EQM IFeature Availability"
{
    procedure IsEnabled(Feature: Enum "EQM Feature"): Boolean;
}
```

Rules for an implementation:
- **IsEnabled** returns true when the feature is turned on. It has the same meaning as `"EQM Feature Mgt.".IsEnabled`.
- **The interface answers only the feature switch.** The caller keeps its other checks and runs them in the same order. For example, codeunit 50122 still checks the Equipment Setup switch for API integration before it asks the interface.
- **Read only.** An implementation does not write data.
- **The interface is internal.** No public API, no enum and no setup field choose an implementation in this phase.

## How the seam is wired
- Each of the three codeunits keeps a global interface variable. The first time it needs an answer, it assigns "EQM Feature Mgt." to the variable. Every check goes through the same helper, so the variable is always assigned.
- The internal procedure `SetFeatureAvailability` replaces the answer. The test app reaches it through `internalsVisibleTo`.
- The job codeunit "EQM Monitoring Job Runner" runs its jobs in an inner job runner instance. When an answer was injected, `RunJob` passes it to that inner instance. When nothing was injected, the inner instance uses its default, as before.
- Pages and page extensions keep calling "EQM Feature Mgt." directly. The procedures `CheckEnabled`, `SetFeatureEnabled`, `InitializeFeatures` and `GetFeatureDescription` are not on the interface.

## Tests
All new tests use `AutoRollback` and call `Initialize()` first. The stub 50170 has four methods: `IsEnabled`, `Reset`, `Disable` (turns a feature off for the test) and `CountAsked` (how often a feature was asked).

| Test codeunit | Test | What it checks |
|---|---|---|
| 50198 | F1 FeatureMgtThroughInterfaceIsEnabledWithoutSetupRow | The default implementation through the interface is on for every feature when no setup rows exist. |
| 50198 | F2 FeatureMgtThroughInterfaceIsDisabledWhenTurnedOff | The default implementation through the interface is off for a feature that was turned off. |
| 50198 | I1 InjectedFeatureAvailabilityTurnsIntegrationEventsOff | An injected `false` turns the integration events off, even when the database says on. |
| 50198 | I2 InjectedFeatureAvailabilityTurnsIntegrationEventsOn | An injected `true` turns the integration events on, even when the database says off. The table is not read. |
| 50198 | I3 InjectedFeatureAvailabilityStillNeedsTheSetupSwitch | With the Equipment Setup switch off, an injected `true` does not turn the integration events on. |
| 50171 | N1 InjectedFeatureAvailabilityStopsNotifications | An injected `false` for Notifications sends no notification. |
| 50171 | N2 InjectedFeatureAvailabilityAllowsNotifications | An injected `true` lets the warranty notification through. |
| 50172 | R1 InjectedFeatureAvailabilityStopsCalculationJob | An injected `false` for Maintenance Planning stops the calculation job. |
| 50172 | R2 InjectedFeatureAvailabilityRunsCalculationJob | An injected `true` runs the calculation job, which proves the answer reached the inner job runner. |

The Warranty Alert job is not used in the job tests, because it calls `Commit()`, which is not allowed under `AutoRollback`.

## Verification status
- **AL build:** not part of this documentation step. Check the build log of the pull request and the `al_getdiagnostics` result.
- **Tests:** not executed locally. CI result pending. The nine new tests are F1, F2, I1, I2, I3 in 50198, N1 and N2 in 50171, and R1 and R2 in 50172. The regression guards are 50171 (all tests), 50158, 50198 (tests 1 to 20), 50172 (BP6 and BP7), 50186, 50154, 50155, 50162 and 50199.
- **Repository checks:** `repo_checks.py` not run by al-docs. Checks 1 (object IDs) and 5 (coverage register) are the ones this change affects. The coverage register has three declared traces for `SetFeatureAvailability` in 50112, 50122 and 50143.
- **AppSource validation:** no separate AppSource validation ran. The reviewer checked the affix, the captions, that no public surface changed, and that the interface is internal.
- **Symbols:** the plan records the platform members as confirmed on Microsoft Learn. The own-app members were read from the source.
- **Sandbox:** nothing is checked in a Business Central sandbox. The features and notifications are expected to behave as before; this is not yet seen in a session.

## Open items
- **Test stub against an internal interface.** The plan lists as a risk that the test app may not implement an internal interface through `internalsVisibleTo`. FR-064 used the same pattern. The CI build result settles this for FR-065.
- **Interface visibility.** The interface stays internal. Making it public is a public API decision and is not part of this phase.

## Later phases
- **Phase 2, telemetry sink.** One logger for the six `Session.LogMessage` calls. Moving the calls into another object changes the `alObjectId`, `alObjectName` and `alObjectType` dimensions of the EQM signals. The user decides whether to accept that change.
- **Phase 3, error log writer.** An interface for the Equipment Error Log writes in 50143 and 50115.
- **Phase 4, notification and query seams.** The My Notifications check and the maintenance and warranty queries in 50112.

The pattern follows [FR-064](FR-064-feature-interfaces.md), which put notification delivery behind an interface.

## Related
[Help](../help/FR-065-dependency-inversion.md), [FR-064](FR-064-feature-interfaces.md), [FR-017](FR-017-equipment-notifications.md), [Extension structure](../architecture/extension-structure.md), [Testing strategy](../architecture/testing-strategy.md), [Access modifiers in AL](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-using-access-modifiers), [Interfaces in AL](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al)
