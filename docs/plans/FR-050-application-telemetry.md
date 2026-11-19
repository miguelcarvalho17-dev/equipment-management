# FR-050 Application Telemetry — Plan

> Request (verbatim): FR-050 Application Telemetry
> Status: **approved**

Issue #91: The system shall generate telemetry events. Tracked: Equipment Created, Equipment Assigned, Equipment Returned, Maintenance Registered, Warranty Expired. Related: FR-018 / NFR-004 (EQM0001 to EQM0004), FR-029 Business Events (#67).

Target: AppSource

## Request
Send one custom telemetry signal (Session.LogMessage) each time one of five business moments happens: Equipment Created, Equipment Assigned, Equipment Returned, Maintenance Registered and Warranty Expired. Event IDs continue the existing sequence: **EQM0005 to EQM0009**. The signals hook into the five FR-029 business events that already exist in codeunit 50119 "EQM Business Events". No business logic changes.

### What exists today (checked by reading the source)
- No telemetry helper codeunit exists. EQM0001 to EQM0004 each call `Session.LogMessage` directly from a local procedure:
  - EQM0001: `LogGenerationTelemetry` in `app/src/Warranty/EQMWarrantyAlertMgt.Codeunit.al` (50110)
  - EQM0002: `LogOverdueCheckTelemetry` in `app/src/Maintenance/EQMMaintenanceMgt.Codeunit.al` (50108)
  - EQM0003 / EQM0004: `LogScheduled` / `LogNotScheduled` in `app/src/Monitoring/EQMMonitoringJobMgt.Codeunit.al` (50115)
- Shared conventions: labels `<Name>TelemetryTok` / `<Name>TelemetryMsg` (`Locked = true`); PascalCase `...DimTok` dimension keys; `Format(x, 0, 9)`; `Verbosity::Normal`, `DataClassification::SystemMetadata`, `TelemetryScope::All`; no customer content.
- The five moments already exist as integration events in `app/src/BusinessEvents/EQMBusinessEvents.Codeunit.al` (50119), which already filter temporary records and Insert(false). Existing subscribers following the pattern: 50121 and 50136.
- This plan adds a third subscriber codeunit, the code that builds and logs each signal, and an internal event so tests can observe the signals.
- Later phases (not planned here): FR-051 Error Logging, FR-052 Usage Analytics.

## Definition of done
- [ ] New codeunit 50140 "EQM Telemetry Mgt." (Internal) and 50141 "EQM Telemetry Subscr." (Internal) exist in `app/src/Telemetry/`.
- [ ] The five signals are logged as follows (all `Verbosity::Normal`, `DataClassification::SystemMetadata`, `TelemetryScope::All`, one call per event raise):

  | Event ID | Message | When | Dimensions |
  |---|---|---|---|
  | EQM0005 | 'Equipment created.' | Each OnEquipmentCreated | `EquipmentStatus` |
  | EQM0006 | 'Equipment assigned.' | Each OnEquipmentAssigned | none |
  | EQM0007 | 'Equipment returned.' | Each OnEquipmentReturned | `EquipmentStatus`; `AssignmentDays` only when both dates are set and Closing Date >= Assignment Date |
  | EQM0008 | 'Maintenance registered.' | Each OnMaintenanceCreated | `MaintenanceType` |
  | EQM0009 | 'Warranty expired.' | Each OnWarrantyExpired | `EquipmentStatus` |

- [ ] Dimension values never depend on the user's language: enum dimensions use the AL value name (`Names()`), numbers use `Format(x, 0, 9)`.
- [ ] No dimension value contains an equipment number, employee number, maintenance number, description, user ID or other record content.
- [ ] Nothing new is logged for temporary records, Insert(false), a failing insert or assignment, a cancelled return, or alert generation (each has a test).
- [ ] The telemetry code cannot raise an error, show UI or call Commit. An enum ordinal with no name falls back to the ordinal number.
- [ ] Reader (50100) and API Consumer (50104) have `X` on codeunits 50140 and 50141. Manager and Administrator inherit from Reader.
- [ ] Test 50162 `ApiConsumerExecuteMatchesMatrix` asserts the two new codeunits; codeunit count changes from 11 to 13.
- [ ] Test codeunits 50151 "EQM Telemetry Tests" and 50152 "EQM Telemetry Test Subscr" exist and compile, covering the scenarios below.
- [ ] `.github/coverage/coverage-register.json` lists 50140 and 50141 in `scope.businessLogic.codeunits` and has traces for the new subscribers and the procedures reached only through events.
- [ ] app/ and test/ compile with 0 errors and 0 warnings (CodeCop, UICop, AppSourceCop). Test results are "Not verified: CI result pending" until CI runs.
- [ ] Docs step: `docs/features/FR-050-application-telemetry.md` (catalog EQM0001 to EQM0009 and a sample KQL query), `docs/help/FR-050-application-telemetry.md`, `## FR-050` in `CHANGELOG.md`.

## Out of scope
- Changing EQM0001 to EQM0004 or moving them into the new codeunit.
- `applicationInsightsConnectionString` in app.json (stop list). `TelemetryScope::All` already reaches the environment's Application Insights.
- System Application "Feature Telemetry" codeunit.
- A FR-042 feature switch for telemetry.
- Telemetry for other moments: maintenance posting, requests/approvals, API calls, errors (FR-051), usage analytics (FR-052).
- Changing the business events, their raise points or doc comments.

## Objects
IDs come from a source scan (`al_getnextobjectid` reported no projects loaded). App codeunits in use are 50103-50122 and 50130-50139; 50100-50102 stay unused by convention; 50123-50129 are the API reserve.

| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Codeunit | 50140 | EQM Telemetry Mgt. | New | `app/src/Telemetry/EQMTelemetryMgt.Codeunit.al` |
| Codeunit | 50141 | EQM Telemetry Subscr. | New | `app/src/Telemetry/EQMTelemetrySubscr.Codeunit.al` |
| PermissionSet | 50100 | EQM - Reader | Changed (2 lines) | `app/src/Permissions/EQMReader.PermissionSet.al` |
| PermissionSet | 50104 | EQM - API Consumer | Changed (2 lines) | `app/src/Permissions/EQMAPIConsumer.PermissionSet.al` |
| Codeunit (test) | 50151 | EQM Telemetry Tests | New | `test/src/EQMTelemetryTests.Codeunit.al` |
| Codeunit (test) | 50152 | EQM Telemetry Test Subscr | New | `test/src/EQMTelemetryTestSubscr.Codeunit.al` |
| Codeunit (test) | 50162 | EQM Role Permission Tests | Changed (one test) | `test/src/EQMRolePermissionTests.Codeunit.al` |
| JSON | — | coverage register | Changed | `.github/coverage/coverage-register.json` |

## Events and standard symbols
`al_symbolsearch` was unavailable (no projects loaded). All publishers are this app's own objects, checked by reading the source. Platform methods checked on Microsoft Learn. No base-app event is used.

| Symbol | Exact signature | How verified |
|---|---|---|
| Codeunit 50119 "EQM Business Events" | `[IntegrationEvent(false, false)] internal procedure OnEquipmentCreated(Equipment: Record "EQM Equipment")` | Source, line 17-20 |
| same | `OnEquipmentAssigned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")` | Source, line 30-33 |
| same | `OnEquipmentReturned(Equipment: Record "EQM Equipment"; EquipmentAssignment: Record "EQM Equipment Assignment")` | Source, line 47-50 |
| same | `OnMaintenanceCreated(MaintenanceRecord: Record "EQM Maintenance Record")` | Source, line 57-60 |
| same | `OnWarrantyExpired(Equipment: Record "EQM Equipment")` | Source, line 68-71 |
| Table "EQM Equipment" field 9 | `Status; Enum "EQM Equipment Status"` (Extensible; Available, Assigned, In Maintenance, Disposed, Lost) | Source |
| Table "EQM Maintenance Record" field 4 | `"Maintenance Type"; Enum "EQM Maintenance Type"` (Extensible; Preventive, Corrective, Inspection, Upgrade) | Source |
| Table "EQM Equipment Assignment" | `"Assignment Date"`, `"Closing Date"` (Date) | Source |
| Session.LogMessage | `Session.LogMessage(EventId: Text, Message: Text, Verbosity, DataClassification, TelemetryScope, CustomDimensions: Dictionary of [Text, Text])` | Learn (runtime 5.4+) |
| Enum instance methods | `Names(): List of [Text]`, `Ordinals(): List of [Integer]`, `AsInteger(): Integer` | Learn (runtime 4.0+) |
| InternalEvent attribute | `[InternalEvent(IncludeSender: Boolean [, Isolated: Boolean])]`; subscribable by `internalsVisibleTo` modules | Learn |

## Steps
1. **`app/src/Telemetry/EQMTelemetryMgt.Codeunit.al` — create codeunit 50140 "EQM Telemetry Mgt."** Only place that builds and logs the five signals.
   - Header: `namespace MiguelCarvalho.EquipmentManagement;`, `Access = Internal;`, XML summary "Logs the usage telemetry signals EQM0005 to EQM0009. Signals carry no customer content."
   - Global labels (all `Locked = true`): `EquipmentCreatedTelemetryTok` 'EQM0005' / `...Msg` 'Equipment created.'; `EquipmentAssignedTelemetryTok` 'EQM0006' / 'Equipment assigned.'; `EquipmentReturnedTelemetryTok` 'EQM0007' / 'Equipment returned.'; `MaintenanceRegisteredTelemetryTok` 'EQM0008' / 'Maintenance registered.'; `WarrantyExpiredTelemetryTok` 'EQM0009' / 'Warranty expired.'; `EquipmentStatusDimTok` 'EquipmentStatus'; `MaintenanceTypeDimTok` 'MaintenanceType'; `AssignmentDaysDimTok` 'AssignmentDays'.
   - Internal procedures (XML doc comment each; each declares local `Dimensions: Dictionary of [Text, Text]`):
     - `LogEquipmentCreated(Equipment: Record "EQM Equipment")` — adds `EquipmentStatusDimTok` = `GetEquipmentStatusName(Equipment.Status)`, then `LogUsage(...)`.
     - `LogEquipmentAssigned()` — no parameters; `LogUsage` with empty dictionary.
     - `LogEquipmentReturned(Equipment; EquipmentAssignment: Record "EQM Equipment Assignment")` — adds `EquipmentStatusDimTok`; adds `AssignmentDaysDimTok` = `Format(Closing Date - Assignment Date, 0, 9)` only when `(Assignment Date <> 0D) and (Closing Date <> 0D) and (Closing Date >= Assignment Date)`; then `LogUsage`.
     - `LogMaintenanceRegistered(MaintenanceRecord)` — adds `MaintenanceTypeDimTok` = `GetMaintenanceTypeName(...)`, then `LogUsage`.
     - `LogWarrantyExpired(Equipment)` — adds `EquipmentStatusDimTok`, then `LogUsage`.
   - Local procedures:
     - `LogUsage(EventId: Text; Message: Text; Dimensions: Dictionary of [Text, Text])`: `Session.LogMessage(EventId, Message, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);` then `OnAfterLogUsageTelemetry(EventId, Dimensions);`
     - `GetEquipmentStatusName(Status: Enum "EQM Equipment Status"): Text`: `Index := Status.Ordinals().IndexOf(Status.AsInteger()); if Index = 0 then exit(Format(Status.AsInteger(), 0, 9)); exit(Status.Names().Get(Index));`
     - `GetMaintenanceTypeName(MaintenanceType: Enum "EQM Maintenance Type"): Text` — same shape.
   - Internal event: `[InternalEvent(false)] internal procedure OnAfterLogUsageTelemetry(EventId: Text; Dimensions: Dictionary of [Text, Text])`, empty body. Doc: "Raised after each usage signal is logged. Internal: used by the test app to observe the signals."
   - Rules: no table access (no `Permissions` property); no Error, UI or Commit; no `Format(enum)` without a format argument (captions are translated).
2. **`app/src/Telemetry/EQMTelemetrySubscr.Codeunit.al` — create codeunit 50141 "EQM Telemetry Subscr."** `Access = Internal;` Summary: "Logs a usage telemetry signal for each business event. Runs in the caller's transaction: no UI, no Commit." Five subscribers, each `[EventSubscriber(ObjectType::Codeunit, Codeunit::"EQM Business Events", <EventName>, '', false, false)]`, each body declaring `TelemetryMgt: Codeunit "EQM Telemetry Mgt.";` and making one call:
   - `EmitEquipmentCreated(Equipment)` ← OnEquipmentCreated → `LogEquipmentCreated(Equipment)`
   - `EmitEquipmentAssigned(Equipment; EquipmentAssignment)` ← OnEquipmentAssigned → `LogEquipmentAssigned()`
   - `EmitEquipmentReturned(Equipment; EquipmentAssignment)` ← OnEquipmentReturned → `LogEquipmentReturned(Equipment, EquipmentAssignment)`
   - `EmitMaintenanceRegistered(MaintenanceRecord)` ← OnMaintenanceCreated → `LogMaintenanceRegistered(MaintenanceRecord)`
   - `EmitWarrantyExpired(Equipment)` ← OnWarrantyExpired → `LogWarrantyExpired(Equipment)`
   - No IsTemporary check (publishers already skip temporary records and Insert(false)).
3. **`EQMReader.PermissionSet.al`** — after `codeunit "EQM Request Approval Mgt." = X` (move its `;` down) add `codeunit "EQM Telemetry Mgt." = X,` and `codeunit "EQM Telemetry Subscr." = X;`.
4. **`EQMAPIConsumer.PermissionSet.al`** — after `codeunit "EQM Audit Trail Subscr." = X` add the same two lines (keep the final `;`).
5. **Compile app/** with `al_compile` then `al_getdiagnostics`. If the MCP has no project loaded, use the alc compiler as in FR-038 to FR-046 on a scratchpad copy. Expect no new translation units (all labels Locked); if `app/Translations/Equipment Management.g.xlf` is regenerated with changes, keep them. Fix every warning.
6. **`test/src/EQMTelemetryTestSubscr.Codeunit.al` — test codeunit 50152 "EQM Telemetry Test Subscr".** `namespace MiguelCarvalho.EquipmentManagement.Tests;`, `using MiguelCarvalho.EquipmentManagement;`, `EventSubscriberInstance = Manual;`. State: `EventIds: List of [Text]`, `DimensionValues: Dictionary of [Text, Text]` (key EventId + '|' + DimKey, last wins via `Set`), `AllValues: List of [Text]`. One subscriber `CaptureUsageTelemetry(EventId; Dimensions)` on `Codeunit::"EQM Telemetry Mgt."`, `OnAfterLogUsageTelemetry`. Getters: `CountOf(EventId)`, `GetDimension(EventId; DimKey)` ('' when missing), `HasDimension`, `AnyValueContains(Fragment)`, `TotalCount()`. State lives in the instance so it survives `asserterror` rollback (as in 50185).
7. **`test/src/EQMTelemetryTests.Codeunit.al` — test codeunit 50151 "EQM Telemetry Tests".** `Subtype = Test; TestPermissions = Disabled;` each test `[TransactionModel(TransactionModel::AutoRollback)]`. Copy local helpers from `test/src/EQMBusinessEventsTests.Codeunit.al` (`Initialize`, `InitEquipment`, `CreateEquipment`, `CreateEquipmentWithWarranty`, `InitMaintenance`, `ConfirmYesHandler` / `ConfirmNoHandler`). Own Locked Tok labels prefixed `EQMTEL-` (CategoryTok 'EQMTEL-CAT', EmployeeTok 'EQMTEL-E1', EquipmentNoTok 'EQMTEL-EQ', NewEquipmentNoTok 'EQMTEL-NEW', MaintenanceNoTok 'EQMTEL-M1', WarrantyNoTok 'EQMTEL-W%1'). Locked labels for expected IDs and dimension keys; do not reference the app's private labels. Bind `Subscriber` with `BindSubscription` after GIVEN setup. At most one `asserterror` per test, last action.
8. **`EQMRolePermissionTests.Codeunit.al` — `ApiConsumerExecuteMatchesMatrix`:** add `AssertExecute(ApiConsumerRoleTok, 5, Codeunit::"EQM Telemetry Mgt.");` and `... "EQM Telemetry Subscr."`; change count `11` to `13`; update `[SCENARIO 2]` comment "11 codeunits" to "13 codeunits".
9. **Compile test/** with the app symbol refreshed in `test/.alpackages` (gitignored). 0 errors, 0 warnings.
10. **`.github/coverage/coverage-register.json`:** append `50140, 50141` to `scope.businessLogic.codeunits` (ascending). Append traces in the existing shape `{ "type": "codeunit", "id": ..., "member": ..., "tests": [{ "codeunit": 50151, "test": "<name>" }], "note": ... }`:
    - 50141 (note "Subscriber: a test whose WHEN raises the subscribed event."): EmitEquipmentCreated → EquipmentCreatedLogsEQM0005; EmitEquipmentAssigned → EquipmentAssignedLogsEQM0006; EmitEquipmentReturned → EquipmentReturnedLogsEQM0007; EmitMaintenanceRegistered → MaintenanceOnAssignedLogsEQM0007AndEQM0008; EmitWarrantyExpired → WarrantyExpiredLogsEQM0009.
    - 50140 (note "Reached only through the business event subscriber."): same tests for `LogEquipmentCreated`, `LogEquipmentAssigned`, `LogEquipmentReturned`, `LogMaintenanceRegistered`, `LogWarrantyExpired`; `OnAfterLogUsageTelemetry` → EquipmentCreatedLogsEQM0005.
    - Run `python3 .github/scripts/repo_checks.py` locally; no integrity errors.
11. **Docs step (documenter):** feature doc with event catalog EQM0001 to EQM0009 (ID, message, when, dimensions, verbosity), KQL sample `traces | where customDimensions.eventId startswith "ALEQM"`, privacy statement; help article on turning on environment telemetry; CHANGELOG `## FR-050`.

## Tests
Codeunit 50151 "EQM Telemetry Tests", observed through 50152:
- [SCENARIO 1] `EquipmentCreatedLogsEQM0005` — bound subscriber; new equipment Insert(true); CountOf('EQM0005') = 1, EquipmentStatus = 'Available', TotalCount = 1.
- [SCENARIO 2] (neg) `NoCreatedSignalForInsertFalseOrTemporary` — Insert(false) on a real record and Insert(true) on a temporary record; TotalCount = 0.
- [SCENARIO 3] (neg) `NoCreatedSignalWhenInsertFails` — blank category; `asserterror Equipment.Insert(true)`; CountOf('EQM0005') = 0.
- [SCENARIO 4] `EquipmentAssignedLogsEQM0006` — available EQ; `Equipment.AssignEmployee(EmployeeTok)`; CountOf('EQM0006') = 1, CountOf('EQM0007') = 0, HasDimension('EQM0006','EquipmentStatus') = false.
- [SCENARIO 5] (neg) `NoAssignedSignalWhenAssignFails` — EQ with open maintenance record; `asserterror AssignEmployee`; CountOf('EQM0006') = 0.
- [SCENARIO 6] `EquipmentReturnedLogsEQM0007` (ConfirmYesHandler) — EQ assigned to E1; `UnassignEmployee()`; CountOf('EQM0007') = 1, EquipmentStatus = 'Available', AssignmentDays = '0'.
- [SCENARIO 7] `MaintenanceOnAssignedLogsEQM0007AndEQM0008` (ConfirmYesHandler) — EQ assigned, maintenance record Corrective Insert(true); EQM0007 = 1 with EquipmentStatus 'In Maintenance'; EQM0008 = 1 with MaintenanceType 'Corrective'.
- [SCENARIO 8] (neg) `NoSignalWhenReturnCancelledOrDescriptionChanged` (ConfirmNoHandler) — return answered No, then description changed with Modify(true); TotalCount = 0.
- [SCENARIO 9] (neg) `NoMaintenanceSignalOnModifyOrPost` — open maintenance record modified, then `Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord)`; CountOf('EQM0008') = 0.
- [SCENARIO 10] `WarrantyExpiredLogsEQM0009` — W1 (end Today-1), W2 (end Today); `WarrantyAlertMgt.RaiseWarrantyExpiredEvents(Today())`; CountOf('EQM0009') = 1, EquipmentStatus = 'Available'.
- [SCENARIO 11] (neg) `NoWarrantyExpiredSignalFromAlertGeneration` — W1 (end Today-1); `GenerateAlerts(Today(), false, CreatedCount, CancelledCount)`; CountOf('EQM0009') = 0.
- [SCENARIO 12] (neg, privacy) `SignalsCarryNoCustomerContent` (ConfirmYesHandler) — create equipment, assign to E1, insert maintenance M1; TotalCount = 4 (EQM0005..EQM0008); AnyValueContains false for EquipmentNoTok, EmployeeTok, MaintenanceNoTok, equipment description, maintenance description and `UserId()`.

Existing tests affected: 50162 `ApiConsumerExecuteMatchesMatrix` (11 to 13, step 8); 50162 `ReaderHasExecuteOnEveryObjectOfTheApp` passes only after step 3. Not affected: 50184/50185, 50186, 50192, NFR-001 50159.

Sandbox (manual, for `docs/TODO.md`): with environment telemetry on, run each action once and check `traces | where customDimensions.eventId in ("ALEQM0005","ALEQM0006","ALEQM0007","ALEQM0008","ALEQM0009")` shows one row per action with `alEquipmentStatus`, `alMaintenanceType`, `alAssignmentDays` as described.

## Assumptions
- "Maintenance Registered" = OnMaintenanceCreated (record inserted with Insert(true)). Posting is a separate moment, not tracked.
- "Warranty Expired" = OnWarrantyExpired, raised only by the daily job for the day after the end date. Manual alert generation does not raise it; a day the job does not run is missed.
- "Equipment Returned" covers every close of an active assignment (Return action, registering maintenance, Lost or Disposed, reassignment). `EquipmentStatus` shows the reason.
- Equipment, employee, maintenance and category codes are customer content and stay out of telemetry (NFR-005, FR-016 Q11, FR-018). Enum value names and day counts are system metadata.
- No feature switch; routing is controlled by the environment administrator.
- `Verbosity::Normal` for all five, matching EQM0001 to EQM0003.

## DECISIONS
- FR-050 Application Telemetry | Chose to subscribe to the five existing FR-029 business events in codeunit 50119, over new subscribers on table triggers or calls inside AssignmentMgt, MaintenanceRecord or WarrantyAlertMgt, because the events already mark exactly these moments and filter out temporary records and Insert(false) | Reversible: yes
- FR-050 Application Telemetry | Chose to log Assigned/Returned from the in-transaction business events, accepting that a rolled-back save can still leave a signal, over queueing until after commit, because AL has no after-commit hook and telemetry is a usage indicator, not a record. This deliberately departs from the 50119 doc advice to partners | Reversible: yes
- FR-050 Application Telemetry | Chose raw Session.LogMessage with IDs EQM0005-EQM0009, over the System Application "Feature Telemetry" codeunit, so numbering and shape stay consistent with EQM0001-EQM0004 | Reversible: no (event IDs are a monitoring contract once released)
- FR-050 Application Telemetry | Chose a new internal "EQM Telemetry Mgt." (50140) + "EQM Telemetry Subscr." (50141), over adding subscribers to 50121 or refactoring EQM0001-0004 into the new codeunit, for one responsibility per codeunit and no change to shipped code | Reversible: yes
- FR-050 Application Telemetry | Chose dimensions EquipmentStatus (enum name), MaintenanceType (enum name) and AssignmentDays (integer), and no record numbers, over the equipment no. or category code, because telemetry must not carry customer content | Reversible: no (dimension names are a query contract once released; values can only be added)
- FR-050 Application Telemetry | Chose a language-independent enum name via Names()/Ordinals() with an ordinal fallback, over Format(enum) (translated caption) or the bare ordinal | Reversible: yes
- FR-050 Application Telemetry | Chose an [InternalEvent] OnAfterLogUsageTelemetry on 50140 so the test app can observe the signals, over testing only dimension-builder procedures, because LogMessage cannot be intercepted and internal events are visible to internalsVisibleTo modules only | Reversible: yes
- FR-050 Application Telemetry | Chose TelemetryScope::All, over ExtensionPublisher, because the app has no publisher connection string (app.json is on the stop list) and administrators read the environment resource | Reversible: yes
- FR-050 Application Telemetry | Chose app codeunits 50140/50141 (house rule: next after the highest in use, outside the API reserve 50123-50129) and test codeunits 50151/50152 (unbuilt FR-001 reservations, whose scenarios live in 50150), over widening test/app.json. IDs from a source scan because the AL MCP had no project loaded | Reversible: yes
- FR-050 Application Telemetry | Chose X for both codeunits in Reader and API Consumer (Manager and Administrator inherit), following FR-036/FR-044 | Reversible: yes

## Risks
- **Rollback gives false signals.** Assigned/Returned are raised inside the equipment OnModify before the row is written, Created and Maintenance inside OnAfterInsert before commit. A later failure in the same transaction leaves a signal for something that did not persist. Accepted (see DECISIONS). Reviewer: confirm the docs say numbers can be slightly high.
- **The 50119 doc comment says the opposite** (tells partners not to send telemetry from OnEquipmentAssigned/Returned). Left unchanged. Reviewer: accept per DECISIONS or ask for a one-line doc clarification.
- **Volume.** Bulk creation logs one EQM0005 per record. No mitigation in phase 1.
- **Dictionary as an event parameter.** If the compiler rejects `Dictionary of [Text, Text]` as an InternalEvent parameter (not expected), the developer stops and reports back. Fallback: `EventId: Text` plus dimensions serialized as `Key=Value;` text.
- **Subscriber must never error** (runs inside the equipment and maintenance save). Reviewer: no `Get`, `TestField`, `Error`, `List.Get` without the IndexOf guard, no Commit or UI in 50140/50141.
- **Symbols not verified with al_symbolsearch.** Reviewer recompiles to confirm event names.
- **AppSourceCop baseline.** Only new objects and permission entries; no breaking change expected. No separate AppSource validation ran.
- **Coverage register integrity.** Trace test names must match test procedures in 50151 exactly.
- **Telemetry delivery is not testable locally or in CI.** Only the sandbox check proves signals reach Application Insights.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-instrument-application-for-telemetry-app-insights
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/telemetry-event-ids
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/attributes/devenv-internalevent-attribute
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/analyzers/appsourcecop-as0019
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-data-type
