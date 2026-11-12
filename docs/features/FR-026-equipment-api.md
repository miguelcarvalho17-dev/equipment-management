# FR-026 Equipment API

## Purpose
Custom Business Central API v1.0 for equipment (GET, POST, PATCH, DELETE, plus two bound actions), including category, status and the current employee assignment, for inventory sync, CMDB, mobile and self-service clients (GitHub issue #64). Every write goes through the existing table triggers and procedures of table 50100, so the rules of FR-001 to FR-024 apply as in the UI. This feature also fixes the API conventions C1 to C10 that FR-027 (#65) and FR-028 (#66) must follow.

Status: implemented on branch `feature/FR-026-equipment-api`, uncommitted at the time of writing. App version stays 29.0.0.0. No new table, field, upgrade code or event.

## Verification status
- **Build (app):** compiles with CodeCop, UICop and AppSourceCop with no diagnostics from the new page. The only compiler output is the known AppSource manifest gaps of the demo app (missing privacyStatement, EULA, help, logo, url, contextSensitiveHelpUrl; ID range 50100-50149 not valid for AppSource; AppSourceCop mandatory affix configuration; InternalsVisibleTo and Application Insights warnings). The documenter did not re-run the build; only existing `///` comments were checked and no AL line was changed.
- **Tests:** 25 tests in codeunit 50180 (`test/src/EQMEquipmentAPITests.Codeunit.al`) are written but **NOT compiled and NOT run** (no Library Assert / Tests-TestLibraries symbols, no sandbox). The Tests-TestLibraries app ID in `test/app.json` is **unverified**.
- **Unverified API behavior:** enum encoding (`In_x0020_Maintenance`); PATCH of a read-only field (plan scenario 11: fails or is ignored); Code[20] as bound action parameter; Library - Graph Mgt procedure signatures and base URL used by the tests.
- **Permissions** (plan scenario 17) are manual sandbox checks and have **not** been done.
- Open items are in `docs/TODO.md`, section FR-026.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Page (API) | 50123 | EQM Equipment API | New, `app/src/API/EQMEquipmentAPI.Page.al`, SourceTable "EQM Equipment" |
| PermissionSet | 50100 | EQM - Reader | `page "EQM Equipment API" = X` |
| Codeunit (test app) | 50180 | EQM Equipment API Tests | New, 25 tests, not compiled, not run |

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
25 tests in codeunit 50180 (`TestPermissions = Disabled`), **not compiled, not run**. They call the API through Library - Graph Mgt web service helpers and cover plan scenarios 1 to 16: GET (list, single, enum filter), POST (series number, status Assigned/Disposed rejected, inactive and empty category, used serial), PATCH (description, warranty dates, Disposed, Lost clears the employee, Assigned to Available rejected, status Assigned rejected, assignedEmployeeNumber does not assign), `assign` (success, inactive employee, Lost, already assigned), `returnEquipment` (success, not assigned), DELETE (plain, with history, assigned) and explicit number with a non-manual series. Fallback if HTTP tests cannot run in CI: table-level calls plus sandbox checks (plan Q3).

## Discrepancies plan vs code
- Plan scenario 10 names PATCH status `Available` on assigned equipment; the test file adds scenario 10b (PATCH status `Assigned`), which the plan did not list. The code behaves as described in Behavior.
- Otherwise the page matches the plan (objects, fields, actions, permission line).
