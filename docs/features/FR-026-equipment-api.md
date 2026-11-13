# FR-026 Equipment API

## Purpose
Custom Business Central API v1.0 for equipment (GET, POST, PATCH, DELETE, plus two bound actions), including category, status and the current employee assignment, for inventory sync, CMDB, mobile and self-service clients (GitHub issue #64). Every write goes through the existing table triggers and procedures of table 50100, so the rules of FR-001 to FR-024 apply as in the UI. This feature also fixes the API conventions C1 to C10 that FR-027 (#65) and FR-028 (#66) must follow.

Status: implemented on branch `feature/FR-026-equipment-api`, uncommitted at the time of writing. App version stays 29.0.0.0. No new table, field, upgrade code or event.

## Verification status
- **Build (app):** compiles with CodeCop, UICop and AppSourceCop with no diagnostics from the new page. The only compiler output is the known AppSource manifest gaps of the demo app (missing privacyStatement, EULA, help, logo, url, contextSensitiveHelpUrl; ID range 50100-50149 not valid for AppSource; AppSourceCop mandatory affix configuration; InternalsVisibleTo and Application Insights warnings). The documenter did not re-run the build; only existing `///` comments were checked and no AL line was changed.
- **CI (commit 9dc8102):** the main app compiles with only the known AppSource manifest warnings; the test app compiled after the `GetFromWebService` call was fixed.
- **Tests:** 35 table-level tests in codeunit 50180 (`test/src/EQMEquipmentAPITests.Codeunit.al`). All 35 pass in AL-Go CI (PR #111, merge commit 0f9718f). The earlier 25 HTTP tests (Library - Graph Mgt) failed in CI with HTTP 401 and were replaced (see Test status).
- **Not covered by automated tests, verified manually in the sandbox (not done yet):** GET list and the OData enum filter (plan scenarios 1, 2a/2b); PATCH of a read-only field at page level (scenario 11); URL and field naming; ETag / If-Match; permissions (scenario 17).
- **Other unverified API behavior:** enum encoding (`In_x0020_Maintenance`); Code[20] as bound action parameter; assumed API publisher `miguelCarvalho`.
- **Permissions** (plan scenario 17) are manual sandbox checks and have **not** been done.
- Open items are in `docs/TODO.md`, section FR-026.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Page (API) | 50123 | EQM Equipment API | New, `app/src/API/EQMEquipmentAPI.Page.al`, SourceTable "EQM Equipment" |
| PermissionSet | 50100 | EQM - Reader | `page "EQM Equipment API" = X` |
| Codeunit (test app) | 50180 | EQM Equipment API Tests | New, 35 table-level tests, all passing in CI |

## Endpoint
`/api/miguelCarvalho/equipment/v1.0/companies({companyId})/equipments` and `.../equipments({id})`, where `{id}` is the `id` (SystemId) field. `APIPublisher = 'miguelCarvalho'` is an assumption of the plan (the platform needs a publisher segment). TODO(verify): base URL in a sandbox.

## Fields
RO = read-only (`Editable = false`).

| API field | Table field | Notes |
|---|---|---|
| `id` | SystemId | RO. Key (`ODataKeyFields = SystemId`). |
| `number` | "No." | Editable (rename, as on the card). On POST an explicit number is only accepted when the number series is manual (`NoSeries.TestManual`); otherwise the series assigns it. |
| `description` | Description | |
| `categoryCode` | "Category Code" | Must be an existing, active category. |
| `serialNumber` | "Serial No." | Must be unique. |
| `manufacturer`, `model` | Manufacturer, Model | |
| `purchaseDate`, `purchaseCost` | Purchase Date, Purchase Cost | |
| `status` | Status | Enum, see Behavior. |
| `assignedEmployeeNumber` | "Assigned Employee No." | RO. Set only by the `assign` action. |
| `locationCode` | "Location Code" | |
| `warrantyStartDate`, `warrantyEndDate`, `warrantyProvider`, `warrantyReferenceNumber` | Warranty fields | End date must be after start date. |
| `lastMaintenanceDate` | "Last Maintenance Date" | Editable, must not be in the future (table rule). |
| `nextMaintenanceDate` | "Next Maintenance Date" | RO. |
| `maintenanceFrequencyMonths` | "Maintenance Frequency (Months)" | |
| `lastModifiedDateTime` | SystemModifiedAt | RO. |

Not exposed: No. Series, Date Filter, FlowFields, Picture.

## Behavior
- **Writes use table logic.** The page has no `OnInsertRecord`, `OnModifyRecord` or `OnDeleteRecord`; the platform validates fields and runs insert, modify and delete with triggers. Table errors are returned unchanged.
- **POST** creates equipment with the series number and status Available. Status `Assigned`, `Disposed` or `Lost` on POST is rejected (NewEquipment...Err). An empty or inactive category is rejected.
- **PATCH status:** the table rules apply. To `Disposed` or `Lost` there is no GUI, so the confirmations default to Yes and the status changes **without a confirmation** (plan Q2, accepted). Final statuses cannot be changed again (StatusIsFinalErr). Moving to `Lost` or `Disposed` clears the assigned employee and closes the active assignment entry (as the UI after Yes).
- **PATCH status to `Assigned`** fails (AssignedEmployeeRequiredErr). The error text says to use the Assign to Employee action on the equipment card, which an API client does not have: **API clients use the `assign` action.** PATCH of assigned equipment to `Available` fails with UseReturnActionErr (use `returnEquipment`).
- **Enum encoding (unverified):** `status` is exposed as an enum, values by name, spaces as `_x0020_`, for example `In_x0020_Maintenance`. Extension values appear automatically.
- **PATCH of a read-only field** (`assignedEmployeeNumber`): the result (error or ignored) is unverified.
- **Bound actions** (`[ServiceEnabled]`, result code Updated, entity key SystemId):

| Action | Call | Effect |
|---|---|---|
| `assign` | `POST .../equipments({id})/Microsoft.NAV.assign` with `{"employeeNumber": "EMP1"}` | `Rec.AssignEmployee`: status Assigned, employee set, Active assignment entry. Errors: inactive employee, final status, already assigned, open maintenance. |
| `returnEquipment` | `POST .../equipments({id})/Microsoft.NAV.returnEquipment` | `Rec.UnassignEmployee`: status Available, entry Closed. Error NotAssignedErr if not assigned. |

  Code[20] as the `employeeNumber` parameter type is unverified.
- **DELETE** follows the table: rejected for assigned equipment, equipment with assignment history or with maintenance records; otherwise the equipment and its attachments are deleted.
- **Concurrency:** standard OData ETag / If-Match on PATCH and DELETE. TODO(verify).
- **Not available:** nested parts, `...Id` foreign keys, category description, employee name (conventions C4, employee read is not in the EQM permission sets).

## API conventions (binding for FR-026, FR-027, FR-028)
| # | Convention |
|---|---|
| C1 | `PageType = API`, `APIPublisher = 'miguelCarvalho'`, `APIGroup = 'equipment'`, `APIVersion = 'v1.0'`, `DelayedInsert = true`, `ODataKeyFields = SystemId`, `Extensible = false`, translatable `EntityCaption` / `EntitySetCaption`. URL `/api/miguelCarvalho/equipment/v1.0/companies({id})/<entitySet>`. |
| C2 | Entities: `equipment`/`equipments` (FR-026), `category`/`categories` (FR-027), `assignment`/`assignments` (FR-028). |
| C3 | Fields in camelCase. `id` = SystemId (RO), `lastModifiedDateTime` = SystemModifiedAt (RO). "No." becomes `number`, "...No." becomes `...Number`, Code fields keep `...Code`. Every control has a `Caption`; no ToolTip or ApplicationArea (unless the analyzers ask). |
| C4 | Relationships as flattened code fields only (`categoryCode`, `assignedEmployeeNumber`, `equipmentNumber`, `employeeNumber`). No navigation parts, no `...Id` foreign keys in v1.0. |
| C5 | Enums exposed as enum-typed fields (value name, spaces as `_x0020_`). No mapping to text. |
| C6 | No `OnInsertRecord` / `OnModifyRecord` / `OnDeleteRecord` overrides and no assignment that skips validation. Fields only the app may set are `Editable = false`. Workflow operations are `[ServiceEnabled]` bound actions that set `WebServiceActionContext` (result code Updated) and call existing table or codeunit procedures. Confirms default to Yes (no GUI). |
| C7 | Read-only entities (FR-028): `Editable = false`, `InsertAllowed`, `ModifyAllowed`, `DeleteAllowed = false`, `DataAccessIntent = ReadOnly`. |
| C8 | Each API page gets `= X` in "EQM - Reader" only. Write rights come from the existing tabledata lines. Add tabledata only if an entity needs a right no set grants. |
| C9 | One page per feature in `app/src/API/`. Shared files: `EQMReader.PermissionSet.al` (one line after `page "EQM Warranty Alerts" = X,`, in API page ID order), `CHANGELOG.md` (own section at the top), `docs/TODO.md` (own section at the end), `test/app.json` (FR-026 only). Merge order 026, 027, 028; each later branch merges `main` first. |
| C10 | IDs: pages 50123 (FR-026), 50124 (FR-027), 50125 (FR-028); 50126-50129 and codeunits 50123-50129 are API reserve. Test codeunits 50180, 50181, 50182. |

Implementation check: the page follows C1 to C6 (verified in the code). The page sets no ToolTip or ApplicationArea.

## Setup
No setup. API clients authenticate as for any Business Central API (OAuth, see Microsoft Learn "Authenticating with Business Central"); the user needs the permissions below. TODO(verify): end-to-end call in a sandbox.

## Extending (events)
Published: none. Subscribed: none. The table raises its own events on every API write. The page is `Extensible = false`: partners cannot add fields to the contract.

## Permissions
| Function | Reader | Manager | Administrator |
|---|---|---|---|
| GET equipments | yes (`page "EQM Equipment API" = X`) | yes | yes |
| POST, PATCH, `assign`, `returnEquipment` | no | yes (existing RIM on equipment) | yes |
| DELETE | no | no (no D, same as the UI) | yes |

Expected from the code and the existing permission sets; **not checked in a sandbox** (scenario 17).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit by hand.

## Compatibility
Additive: one new page and one permission line. **At first AppSource release v1.0 is a frozen public contract:** entity names, field names, types and actions must not change. A breaking change needs a new page with `APIVersion = 'v2.0'`; v1.0 is then marked Obsolete.

## Test status
35 AutoRollback tests in codeunit 50180 (`TestPermissions = Disabled`), all 35 passing in AL-Go CI (PR #111, merge commit 0f9718f). They call the same table triggers (`Validate`, `Insert(true)`, `Modify(true)`, `Delete(true)`) and the `AssignEmployee` / `UnassignEmployee` procedures that the API page uses, in the field order of a request. No HTTP, no Tests-TestLibraries dependency: `test/app.json` depends on the main app and Library Assert only.

Why: the first version used 25 HTTP tests through Library - Graph Mgt. They failed in CI with HTTP 401, because the AL-Go container uses UserPassword authentication and the library sends no credentials. The plan's Q3 fallback (table-level tests plus sandbox checks) was applied.

Covered (plan scenarios 3 to 16): POST (series number and status Available, status Assigned/Disposed/Lost rejected also when set without Validate, inactive/unknown/empty category, used serial number), PATCH (description, own serial number kept, warranty end before/equal/after start, Disposed with and without confirmation, Disposed to Available rejected, Lost clears the employee and closes the entry, Assigned to Available rejected, status Assigned without employee rejected, employee on non-assigned equipment rejected), `AssignEmployee` (success, inactive employee, Lost, already assigned), `UnassignEmployee` (success, declined, not assigned), DELETE (plain, with history, assigned) and explicit number with a non-manual and a manual series.

Not covered by automated tests, manual sandbox checks (not done): scenarios 1 and 2a/2b (GET, OData enum filter), scenario 11 at page level (the page marks `id`, `assignedEmployeeNumber`, `nextMaintenanceDate` and `lastModifiedDateTime` as not editable; only the table rule behind it is tested), URL and field naming, ETag / If-Match, scenario 17 (permissions).

## Discrepancies plan vs code
- Plan scenario 10 names PATCH status `Available` on assigned equipment; the test file adds scenario 10b (PATCH status `Assigned`), which the plan did not list. The code behaves as described in Behavior.
- Plan step 4 and Q3 (HTTP tests with Tests-TestLibraries) were not kept: the tests are table-level (Q3 fallback applied). The plan scenarios 1, 2 and 17 and the page-level part of 11 are manual checks, not automated.
- Otherwise the page matches the plan (objects, fields, actions, permission line).
