# FR-065 Dependency Inversion — Plan

> Request (verbatim): FR-065 Dependency Inversion
> Status: **approved**

GitHub issue #106: "Business logic shall depend on interfaces rather than implementations. Business Value: Facilitates testing and future extensibility. Depends on: FR-064 Feature Interfaces. Supports FR-045 (mockable logic in unit tests)."

## Request
Make business logic depend on interfaces instead of concrete codeunits, so unit tests can replace a dependency (FR-045) and later implementations can be added. FR-064 did this for notification delivery. Phase 1 inverts the most widely shared concrete dependency of the business-logic codeunits, feature activation ("EQM Feature Mgt."), behind a new internal interface. No behaviour changes.
Target: AppSource

### Survey
| # | Dependency | Used by | Decision |
|---|---|---|---|
| S1 | `"EQM Feature Mgt.".IsEnabled` | 50112 (6 calls), 50122 (1), 50143 (2) | **Phase 1**: pure read, no side effects |
| S2 | `Session.LogMessage` (telemetry) | 50108, 50110, 50115, 50140 | Phase 2, needs user decision: moving the call into one sink changes alObjectId/alObjectName/alObjectType dimensions of EQM signals |
| S3 | `"EQM Error Log Mgt."` | 50143, 50115 | Phase 3 |
| S4 | `My Notifications`, maintenance/warranty queries in 50112 | 50112 | Phase 4 |
| S5 | `"EQM Business Events"` | 50106, 50110 | Not planned: publish/subscribe already inverts |
| S6 | Clock and user | several | Not planned |
| S7 | Pages calling FeatureMgt | 12 pages | Not planned: UI layer |

## Definition of done
- [ ] New interface "EQM IFeature Availability" (`Access = Internal`) with exactly one method `procedure IsEnabled(Feature: Enum "EQM Feature"): Boolean;`.
- [ ] Codeunit 50138 "EQM Feature Mgt." declares `implements "EQM IFeature Availability"`. `IsEnabled` is a plain (public) `procedure`, parameter list and body unchanged. No other procedure of 50138 changes.
- [ ] Codeunits 50112, 50122, 50143 no longer call `FeatureMgt.IsEnabled` directly; each calls a local `IsFeatureEnabled` helper that goes through an `Interface "EQM IFeature Availability"` variable (default "EQM Feature Mgt.").
- [ ] Each of 50112, 50122, 50143 has `internal procedure SetFeatureAvailability(NewFeatureAvailability: Interface "EQM IFeature Availability")`.
- [ ] 50143 `RunJob` passes an injected implementation on to the inner `JobRunner` instance; when nothing was injected, it does not.
- [ ] No other signature, guard order, exit, label, telemetry, permission or data access changes in 50112, 50122, 50143.
- [ ] Test stub 50170 "EQM Feature Avail. Stub" and the 9 new tests compile. Tests run only in CI.
- [ ] Existing tests pass unchanged: 50171 (9), 50158, 50198 (scenarios 1-20), 50172, 50186, 50154, 50155, 50162, 50199.
- [ ] Coverage register has 3 trace entries for `SetFeatureAvailability`; `python3 .github/scripts/repo_checks.py --base origin/main` reports no errors.
- [ ] No change to app.json, permission sets or XLIFF content. No new app codeunit, table, page or enum.

## Out of scope
- Telemetry sink (S2), error-log writer (S3), notification preference and query seams (S4), clock/user seams (S6).
- Pages and page extensions keep calling "EQM Feature Mgt." directly. `CheckEnabled`, `SetFeatureEnabled`, `InitializeFeatures`, `GetFeatureDescription` are not on the interface.
- No public API: interface stays Internal, no enum or setup field to choose an implementation.
- Job codeunits 50111, 50114, 50145 and all subscribers are unchanged.

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Interface | n/a | EQM IFeature Availability | New (Internal) | app/src/Features/EQMIFeatureAvailability.Interface.al |
| Codeunit | 50138 | EQM Feature Mgt. | Changed (`implements`, `IsEnabled` made public) | app/src/Features/EQMFeatureMgt.Codeunit.al |
| Codeunit | 50112 | EQM Notification Mgt. | Changed (internal refactor + setter) | app/src/Notifications/EQMNotificationMgt.Codeunit.al |
| Codeunit | 50122 | EQM Integration Event Mgt. | Changed (internal refactor + setter) | app/src/Integration/EQMIntegrationEventMgt.Codeunit.al |
| Codeunit | 50143 | EQM Monitoring Job Runner | Changed (internal refactor + setter) | app/src/ErrorLog/EQMMonitoringJobRunner.Codeunit.al |
| Codeunit (test) | 50170 | EQM Feature Avail. Stub | New (SingleInstance, implements interface) | test/src/EQMFeatureAvailStub.Codeunit.al |
| Codeunit (test) | 50198 | EQM Feature Mgt. Tests | Changed (+5 tests, Initialize resets stub) | test/src/EQMFeatureMgtTests.Codeunit.al |
| Codeunit (test) | 50171 | EQM Notification Tests | Changed (+2 tests) | test/src/EQMNotificationTests.Codeunit.al |
| Codeunit (test) | 50172 | EQM Background Process. Tests | Changed (+2 tests) | test/src/EQMBackgroundProcessTests.Codeunit.al |
| JSON | n/a | coverage register | Changed (+3 traces) | .github/coverage/coverage-register.json |
| Docs | n/a | extension structure | Changed (counts, interface row) | docs/architecture/extension-structure.md |

IDs: `al_getnextobjectid` had no project loaded; IDs come from a source scan. 50170 is the unbuilt FR-016 reservation (superseded by 50168).

## Events and standard symbols
No new base-app event or procedure. Own-app symbols read from source (al_symbolsearch unavailable): `"EQM Feature Mgt".IsEnabled(Feature: Enum "EQM Feature"): Boolean`; enum "EQM Feature" 50112; enum "EQM Error Operation" 50113. Platform: codeunit variable assignable to interface variable (Learn, Interfaces in AL); AL0921 requires the implementing method to be public.

## Steps
All new app files start with `namespace MiguelCarvalho.EquipmentManagement;`. Every object and non-local procedure gets a `/// <summary>`.

1. **EQMIFeatureAvailability.Interface.al (new).** Shape of `EQMINotificationProvider.Interface.al`. `interface "EQM IFeature Availability"`, `Access = Internal;`. Summary: "Tells whether an optional equipment feature is turned on. Business logic asks through this interface so tests and later sources can replace the answer." One method `procedure IsEnabled(Feature: Enum "EQM Feature"): Boolean;` with `<param>`/`<returns>`. No default body.
2. **EQMFeatureMgt.Codeunit.al.** Header `codeunit 50138 "EQM Feature Mgt." implements "EQM IFeature Availability"`. Change `internal procedure IsEnabled` to `procedure IsEnabled` (only the keyword; body and doc stay). Add to the object summary: "It is the default implementation of "EQM IFeature Availability"."
3. **EQMNotificationMgt.Codeunit.al.** Only these edits:
   - a) Keep `FeatureMgt: Codeunit "EQM Feature Mgt.";`. Add `FeatureAvailability: Interface "EQM IFeature Availability";` and `IsFeatureAvailabilitySet: Boolean;` after `IsProviderSet`.
   - b) After `SetProvider`: `internal procedure SetFeatureAvailability(NewFeatureAvailability: Interface "EQM IFeature Availability")` → `FeatureAvailability := NewFeatureAvailability; IsFeatureAvailabilitySet := true;`. Summary: "Replaces the source that tells whether a feature is turned on. Used by tests."
   - c) After `EnsureProvider`: `local procedure EnsureFeatureAvailability()` → `if IsFeatureAvailabilitySet then exit; FeatureAvailability := FeatureMgt; IsFeatureAvailabilitySet := true;`.
   - d) `local procedure IsFeatureEnabled(Feature: Enum "EQM Feature"): Boolean` → `EnsureFeatureAvailability(); exit(FeatureAvailability.IsEnabled(Feature));`.
   - e) Replace all 6 `FeatureMgt.IsEnabled(` (lines 94, 110, 166, 188, 202, 252) with `IsFeatureEnabled(`. Arguments, `not`, order, `exit` identical.
   - f) Add summary sentence: "Whether a feature is turned on is asked through "EQM IFeature Availability"."
4. **EQMIntegrationEventMgt.Codeunit.al.** a) Add global var section after `Permissions`: `FeatureMgt: Codeunit "EQM Feature Mgt."; FeatureAvailability: Interface "EQM IFeature Availability"; IsFeatureAvailabilitySet: Boolean;`. b) In `IsEnabled()` delete local `FeatureMgt`; replace the `FeatureMgt.IsEnabled("EQM Feature"::"API Integration")` call with `IsFeatureEnabled(...)`; rest unchanged. c) Add the same three procedures as step 3 at the end.
5. **EQMMonitoringJobRunner.Codeunit.al.** a) Global var (after `JobCodeunitId`): same three variables. b) `RunWarrantyAlertJob`: delete local `FeatureMgt`, use `IsFeatureEnabled("EQM Feature"::"Warranty Alerts")`; `Commit()` and `RaiseWarrantyExpiredEvents` stay. c) `RunMaintenanceCalculationJob`: same with "Maintenance Planning". d) `RunJob`: directly after `JobRunner.SetJob(JobCodeunitIdToRun);` add `if IsFeatureAvailabilitySet then JobRunner.SetFeatureAvailability(FeatureAvailability);`. e) Add `SetFeatureAvailability` (internal; summary also says it is passed on to the job that RunJob starts), `EnsureFeatureAvailability`, `IsFeatureEnabled`.
6. **Build app/.** `al_compile` then `al_getdiagnostics`; if no project loaded, use the alc fallback recorded in DECISIONS (FR-051/055/064). Expect 0 errors, 0 new warnings. Run `python3 .github/scripts/xlf_sync.py check`; expect no change. Report any new trans-unit.
7. **EQMFeatureAvailStub.Codeunit.al (new, test, 50170).** Namespace `MiguelCarvalho.EquipmentManagement.Tests`, `using MiguelCarvalho.EquipmentManagement;` as in 50174. `codeunit 50170 "EQM Feature Avail. Stub" implements "EQM IFeature Availability"`, `SingleInstance = true; Access = Internal;`. Globals `DisabledFeatures: List of [Integer]; AskedFeatures: List of [Integer];`. `procedure IsEnabled(Feature)` (plain): `AskedFeatures.Add(Feature.AsInteger()); exit(not DisabledFeatures.Contains(Feature.AsInteger()));`. Internal: `Reset()`, `Disable(Feature)` (add if missing), `CountAsked(Feature): Integer`. Summary: "FR-065 test double: answers feature checks from memory instead of the Feature Setup table. Single instance, so the copy handed to the code under test shares its state with the test."
8. **EQMFeatureMgtTests.Codeunit.al.** Global `FeatureAvailabilityStub`; `Initialize()` adds `FeatureAvailabilityStub.Reset();` after `FeatureSetup.DeleteAll();`. Add F1, F2, I1, I2, I3 after `IntegrationEventsAreWrittenWhenApiIntegrationIsOn`. Reuse `EnsureEquipmentSetup`.
9. **EQMNotificationTests.Codeunit.al.** Global stub; `Initialize()` adds `FeatureAvailabilityStub.Reset();` after `ProviderSpy.Reset();`. Add N1, N2 before the handlers. Reuse `CreateEquipmentWithWarrantyAlert` and the `ProviderSpy` pattern from T6/T7. `NotificationMgt` is a **local** variable in each test.
10. **EQMBackgroundProcessTests.Codeunit.al.** Global stub; `Initialize()` resets it. Add R1, R2 after `MaintCalcJobCorrectsStaleDate`. Reuse `CreateEquipmentWithPlan` and `MakeStale`. `JobRunner` local in each test.
11. **Compile test/** against fresh app symbols (refresh gitignored `test/.alpackages` app copy as in earlier runs). Expect 0 errors, 0 warnings.
12. **coverage-register.json.** Append 3 entries to `"traces"` in the shape of the 50140 entries; note: "Same name on 50112, 50122 and 50143; declared trace."
    | type | id | member | test |
    |---|---|---|---|
    | codeunit | 50112 | SetFeatureAvailability | 50171, InjectedFeatureAvailabilityStopsNotifications |
    | codeunit | 50122 | SetFeatureAvailability | 50198, InjectedFeatureAvailabilityTurnsIntegrationEventsOff |
    | codeunit | 50143 | SetFeatureAvailability | 50172, InjectedFeatureAvailabilityStopsCalculationJob |
    Scope lists unchanged. Run `python3 .github/scripts/repo_checks.py --base origin/main`; expect no errors.
13. **Docs (al-docs).** `docs/plans/FR-065-dependency-inversion.md` (this file), `docs/features/FR-065-dependency-inversion.md`, `docs/help/FR-065-dependency-inversion.md` (no user-visible change), `CHANGELOG.md` heading `## FR-065`, `docs/architecture/extension-structure.md` (line 77 counts become 134 objects and 2 interfaces plus a sentence on FR-065; add a row after line 208: `| Interface | n/a | EQM IFeature Availability | Internal | app/src/Features/EQMIFeatureAvailability.Interface.al |`; add feature doc link on line 302). Report: "Not verified: tests not executed locally, CI result pending"; no separate AppSource validation ran.

## Tests
All new tests use `[TransactionModel(TransactionModel::AutoRollback)]`, call `Initialize()` first, use no hardcoded business data.

Codeunit 50198:
- **F1 FeatureMgtThroughInterfaceIsEnabledWithoutSetupRow**: no Feature Setup rows; local interface var := `FeatureMgt`; `IsEnabled` for every ordinal of `Enum::"EQM Feature"` returns true.
- **F2 FeatureMgtThroughInterfaceIsDisabledWhenTurnedOff** (negative): `FeatureMgt.SetFeatureEnabled("Warranty Alerts", false)`; "Warranty Alerts" false, Notifications true.
- **I1 InjectedFeatureAvailabilityTurnsIntegrationEventsOff** (negative): `EnsureEquipmentSetup(true)`, no setup rows (database says on); stub `Disable("API Integration")`, `IntegrationEventMgt.SetFeatureAvailability(Stub)`; `IsEnabled()` false and `Stub.CountAsked("API Integration") = 1`.
- **I2 InjectedFeatureAvailabilityTurnsIntegrationEventsOn**: `EnsureEquipmentSetup(true)` and `SetFeatureEnabled("API Integration", false)` (database says off); stub with nothing disabled injected; `IsEnabled()` true (proves the table is not read).
- **I3 InjectedFeatureAvailabilityStillNeedsTheSetupSwitch** (negative, boundary): `EnsureEquipmentSetup(false)`; stub injected; `IsEnabled()` false.

Codeunit 50171:
- **N1 InjectedFeatureAvailabilityStopsNotifications** (negative): spy provider set; `RegisterDefaultNotifications`; no feature rows; stub `Disable(Notifications)` injected via `SetFeatureAvailability`; equipment X with warranty alert; `ShowEquipmentNotifications(X)`: `ProviderSpy.SentCount() = 0`, `ProviderSpy.RecallCount() = 2`, `Stub.CountAsked(Notifications) = 1`.
- **N2 InjectedFeatureAvailabilityAllowsNotifications**: spy provider; `FeatureMgt.SetFeatureEnabled(Notifications, false)` (local `FeatureMgt`); stub with nothing disabled injected; X has warranty alert; `ShowEquipmentNotifications(X)`: `ProviderSpy.CountSent(GetWarrantyNotificationId()) = 1`, `Stub.CountAsked(Notifications) = 1`, `Stub.CountAsked("Warranty Alerts") = 1`.

Codeunit 50172:
- **R1 InjectedFeatureAvailabilityStopsCalculationJob** (negative): no feature rows; E from `CreateEquipmentWithPlan(E, Today() - 1 - Random(365))` then `MakeStale(E)`, remember stale date; stub `Disable("Maintenance Planning")`, local `JobRunner.SetFeatureAvailability(Stub)`; `JobRunner.RunJob(Codeunit::"EQM Maintenance Calc. Job", "EQM Error Operation"::"Maintenance Calculation Job")`; E's "Next Maintenance Date" still equals stale date and `Stub.CountAsked("Maintenance Planning") = 1`.
- **R2 InjectedFeatureAvailabilityRunsCalculationJob**: `SetFeatureEnabled("Maintenance Planning", false)`; E has plan, expected date remembered, made stale; stub with nothing disabled injected; same RunJob; date equals expected date (proves the injection reached the inner runner instance).
- Do **not** use the Warranty Alert job in these tests: its `Commit()` is not allowed under AutoRollback.

Existing tests that must pass unchanged: 50171 (all 9, especially T7), 50158, 50198 (1-20, especially 19/20), 50172 (BP6, BP7), 50186, 50154, 50155, 50162, 50199.

## Assumptions
- Default implementation is "EQM Feature Mgt." itself, not an adapter codeunit (no new ID, permission entries or XLIFF).
- Holding the default in a **global** `FeatureMgt` codeunit variable is safe; "EQM Feature Mgt." has no state.
- The stub is `SingleInstance`, following the FR-064 spy (50174).
- `GuiAllowed()` is true in the test runner, as FR-064 already assumes for 50171.
- The `.g.xlf` gets no new units.
- Making `IsEnabled` public on an `Access = Internal` codeunit is not a "public signature change" on the stop list (Learn: Access property).

## DECISIONS
- FR-065 scope | Chose feature activation as phase 1 over the telemetry sink, because moving Session.LogMessage into another object changes alObjectId/alObjectName/alObjectType of EQM0001-EQM0012 | Reversible: yes
- FR-065 consumers | Chose only business-logic codeunits 50112, 50122, 50143 over also the 12 pages (UI layer) | Reversible: yes
- FR-065 default implementation | Chose "EQM Feature Mgt." implementing the interface directly (IsEnabled internal → public on an internal codeunit) over a new adapter codeunit | Reversible: yes
- FR-065 interface surface | Chose a single method IsEnabled, Access = Internal, no enum or selector, over also putting CheckEnabled on the interface or making it public | Reversible: yes
- FR-065 test seam | Chose an internal SetFeatureAvailability per consumer plus a SingleInstance stub, consistent with FR-064 SetProvider, over an InternalEvent seam | Reversible: yes
- FR-065 runner propagation | Chose to pass an injected implementation from RunJob to the inner JobRunner only when one was set | Reversible: yes
- FR-065 IDs | Chose test codeunit 50170 (superseded FR-016 reservation) for the stub and added the 9 tests to existing 50171, 50172, 50198, because free test IDs are scarce; IDs from a source scan | Reversible: yes
- FR-065 coverage | Chose declared traces for the three SetFeatureAvailability procedures (ambiguous name) over three different procedure names | Reversible: yes

## Risks
- Interface lifetime: `EnsureFeatureAvailability` must assign from the global `FeatureMgt`, not a local; every `IsFeatureEnabled` goes through `EnsureFeatureAvailability` so the interface variable is never unassigned.
- Behaviour drift in 50112: the 6 replaced calls keep the same feature value, `not` and guard order (GuiAllowed, Notifications, SystemCreatedAt, My Notifications, Warranty Alerts, business conditions).
- The runner's Commit: no test may inject into the warranty path under AutoRollback.
- Friend module implementing an internal interface: FR-064 confirmed it works; if the compiler rejects the stub, stop and report, do not make the interface public.
- AL0918 (interface runtime ID collision): if it appears, rename the method, not the object.
- al_symbolsearch/al_getnextobjectid unavailable: run repo check 1 for duplicate IDs and confirm 50170 is unused in `test/src`.
- Coverage enforcement is off (`"enforce": false`); traces keep the report accurate anyway.
- No data written by the refactor; default path behaves exactly as before, including fail-open when the user cannot read Feature Setup.
- No separate AppSource validation runs.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/diagnostics/diagnostic-al921
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/diagnostics/diagnostic-al920
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/diagnostics/diagnostic-al616
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-access-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-using-access-modifiers
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-instrument-application-for-telemetry-app-insights

## Later phases
- **Phase 2:** "EQM ITelemetry Logger" for the 6 `Session.LogMessage` sites in 50108, 50110, 50115, 50140. Needs the user's decision: accept that alObjectId/alObjectName/alObjectType change to the sink codeunit, or have each consumer implement the interface itself so dimensions stay the same.
- **Phase 3:** "EQM IError Logger" for 50143 and 50115.
- **Phase 4:** notification-preference seam (My Notifications) and maintenance/warranty query seams in 50112.
