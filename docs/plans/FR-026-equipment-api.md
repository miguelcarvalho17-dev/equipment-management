# FR-026 Equipment API

> Status: **APPROVED** (user approved the plan with the recommended answers to Q1 to Q3). Source: GitHub issue #64. Branch `feature/FR-026-equipment-api`. No base behavior touched (own tables only), so no events report is needed. This plan also fixes the API conventions that FR-027 (#65) and FR-028 (#66) must follow.

## Goal
Expose equipment through a custom Business Central API v1.0 (GET, POST, PATCH, DELETE), including category, status and the current employee assignment, for inventory sync, CMDB, mobile and self-service clients. Every write goes through the existing table triggers and procedures, so the business rules from FR-001 to FR-024 apply exactly as in the UI.

## Approach and rejected alternatives
- Chosen: one API page on table 50100. Status is editable (table OnValidate rules apply). Assigning and returning use two bound actions that call the existing `AssignEmployee` / `UnassignEmployee`. No new codeunit, no table change.
- Rejected: PATCH of `assignedEmployeeNumber` + `status`: the result depends on the order fields are validated in (employee before status fails `EmployeeOnlyWhenAssignedErr`), and it bypasses the Assign/Return procedures.
- Rejected: nested sub-entities (category, assignments as parts) in v1.0: deep insert/expand adds contract surface; codes plus top-level entities in FR-027/FR-028 are enough.
- Rejected: API query objects: read-only, but the issue needs writes.
- **API conventions (binding for FR-026, FR-027, FR-028):**
  C1 `PageType = API`, `APIPublisher = 'miguelCarvalho'`, `APIGroup = 'equipment'`, `APIVersion = 'v1.0'`, `DelayedInsert = true`, `ODataKeyFields = SystemId`, `Extensible = false`, `EntityCaption`/`EntitySetCaption` set (translatable). URL: `/api/miguelCarvalho/equipment/v1.0/companies({id})/<entitySet>`.
  C2 Entities: `equipment`/`equipments` (FR-026), `category`/`categories` (FR-027), `assignment`/`assignments` (FR-028).
  C3 Fields: camelCase. Key field `id` = SystemId (read-only); `lastModifiedDateTime` = SystemModifiedAt (read-only). "No." -> `number`, "...No." -> `...Number`, Code fields keep `...Code`. Each control has a `Caption`; no ToolTip or ApplicationArea (unless the analyzers ask for them).
  C4 Relationships: flattened code fields only (`categoryCode`, `assignedEmployeeNumber`, `equipmentNumber`, `employeeNumber`); no navigation parts or `...Id` foreign keys in v1.0.
  C5 Enums are exposed as enum-typed fields (the value name; spaces become `_x0020_`, e.g. `In_x0020_Maintenance`). Extension values appear automatically. No mapping to text.
  C6 Writes: no `OnInsertRecord`/`OnModifyRecord`/`OnDeleteRecord` overrides and no direct assignment that skips validation. The platform does Validate + Insert/Modify/Delete(true), and table errors are returned unchanged. Confirms default to Yes (no GUI). Fields that only the app may set are `Editable = false`. Workflow operations are bound actions (`[ServiceEnabled]`, `WebServiceActionContext` with result code Updated) that call existing table/codeunit procedures.
  C7 Read-only entities (FR-028): `Editable = false`, `InsertAllowed`/`ModifyAllowed`/`DeleteAllowed = false`, `DataAccessIntent = ReadOnly`.
  C8 Permissions: each API page gets `= X` in "EQM - Reader" only. Write rights come from the existing tabledata lines (Manager RIM on equipment, Administrator RIMD on equipment and categories). Do not add tabledata unless an entity needs a right that no set grants yet.
  C9 Files: one page per feature in `app/src/API/`. Shared files: `EQMReader.PermissionSet.al` (one line appended after `page "EQM Warranty Alerts" = X,`, in API page ID order), `CHANGELOG.md` (own section at the top), `docs/TODO.md` (own section at the end), `test/app.json` (FR-026 only). Merge order is 026, 027, 028. Each later branch merges `main` before its PR and resolves the adjacent-line conflicts.
  C10 IDs: pages 50123 (FR-026), 50124 (FR-027), 50125 (FR-028); 50126-50129 and codeunits 50123-50129 are spare API reserve. Test codeunits 50180/50181/50182 (see Q1).

## Objects
IDs in use (checked `app/src`, `test/src`): pages 50100-50122, codeunits 50103-50118, tables 50100-50108, enums 50100-50108; test codeunits 50178, 50179. Test 50150-50177 are reserved by earlier plans (see Q1).
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Page (API) | 50123 | EQM Equipment API | New | `equipments` entity, file `app/src/API/EQMEquipmentAPI.Page.al`, SourceTable "EQM Equipment" |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | `page "EQM Equipment API" = X` |
| Codeunit (test) | 50180 | EQM Equipment API Tests | New | Scenarios below, `test/src/EQMEquipmentAPITests.Codeunit.al` |

## Data model and upgrade impact
- No new fields or tables, no upgrade codeunit. Page fields (API name <- table field, RO = Editable false): `id` <- SystemId RO, `number` <- "No.", `description`, `categoryCode`, `serialNumber`, `manufacturer`, `model`, `purchaseDate`, `purchaseCost`, `status`, `assignedEmployeeNumber` RO, `locationCode`, `warrantyStartDate`, `warrantyEndDate`, `warrantyProvider`, `warrantyReferenceNumber`, `lastMaintenanceDate`, `nextMaintenanceDate` RO, `maintenanceFrequencyMonths` <- "Maintenance Frequency (Months)", `lastModifiedDateTime` <- SystemModifiedAt RO. Not exposed: No. Series, Date Filter, FlowFields, Picture.
- Bound actions: `assign(employeeNumber: Code[20])` -> `Rec.AssignEmployee`; `returnEquipment()` -> `Rec.UnassignEmployee`.

## Events
- Subscribed: none. Published: none (the table already raises its events on every API write).

## Permissions
- EQM - Reader: `page "EQM Equipment API" = X` (C8/C9). Effect: Reader can only GET. Manager can POST/PATCH/assign/return, but DELETE fails (no D, same as the UI). Administrator can do everything.

## Compatibility
- Additive only: no change to existing objects except one permission line. **At first AppSource release the page becomes a public contract:** entity names, field names, types and actions of v1.0 are frozen. Breaking changes need a new page with `APIVersion = 'v2.0'`, and v1.0 is then marked Obsolete. `Extensible = false` keeps partners from adding fields to the contract.

## Implementation steps
1. Create page 50123 with the C1 properties, `EntityName = 'equipment'`, `EntitySetName = 'equipments'`, EntityCaption 'Equipment', EntitySetCaption 'Equipment', Caption 'Equipment API'. Add the repeater with the fields in the Data model order, captions = table field captions. Compile.
2. Add the `assign` and `returnEquipment` bound actions (C6). Each one sets the ActionContext (page 50123, entity key SystemId, ResultCode Updated). Compile.
3. Update the EQM - Reader line (C9). Build the main app and commit the regenerated `.g.xlf`.
4. In `test/app.json`, add the dependency "Tests-TestLibraries" (Microsoft, 29.0.0.0, id from the symbols; it holds "Library - Graph Mgt"). Create test codeunit 50180 (TestPermissions Disabled, pattern of 50179). Calls go through the web service helpers of Library - Graph Mgt (Q3).
5. Documenter: feature doc, help (URL, fields, enum encoding, actions, ETag/If-Match), CHANGELOG, TODO: close housekeeping item "confirmations default to Yes ... API", add sandbox checks.

## Test scenarios
Setup: active category LAPTOP, inactive OLD, active employee EMP1, inactive EMP2, saved equipment E (LT001, Available).
1. Given E, when GET equipments, then E is returned with id = SystemId, number LT001, categoryCode LAPTOP, status `Available`.
2. Given E, when GET equipments({id}), then a single entity is returned; when the filter is `status eq 'In_x0020_Maintenance'` on In Maintenance equipment, it is returned.
3. Given the setup, when POST {description, categoryCode LAPTOP}, then 201 and a record with a series number and status Available.
4. (neg) When POST with status `Assigned` (or `Disposed`), then an error and no record.
5. (neg) When POST with categoryCode OLD, then CategoryInactiveErr and no record; when POST with an empty category, then an error.
6. (neg) Given E with serial S1, when POST another with S1, then SerialNoAlreadyUsedErr.
7. Given E, when PATCH description, then it is saved; (neg) when PATCH warrantyEndDate before warrantyStartDate, then WarrantyEndDateErr and no change.
8. Given E, when PATCH status `Disposed`, then Disposed with no confirm; (neg) a further PATCH to `Available` gives StatusIsFinalErr.
9. Given E assigned to EMP1, when PATCH status `Lost`, then the employee is cleared and the active assignment entry is Closed.
10. (neg) Given E assigned, when PATCH status `Available`, then UseReturnActionErr.
11. (neg) Given E, when PATCH assignedEmployeeNumber, then the request fails or is ignored, and the employee stays blank (record which).
12. Given E, when POST equipments({id})/Microsoft.NAV.assign {employeeNumber EMP1}, then status Assigned, employee EMP1, one Active assignment entry.
13. (neg) assign with EMP2 gives EmployeeNotActiveErr; assign on Lost equipment gives CannotAssignFinalStatusErr; assign on assigned equipment gives AlreadyAssignedErr.
14. Given E assigned, when returnEquipment, then Available and the entry is Closed; (neg) returnEquipment on Available gives NotAssignedErr.
15. Given never-assigned E, when DELETE, then it is gone; (neg) with history: DeleteHistoryExistsErr, still exists; assigned: DeleteAssignedErr.
16. (neg) When POST with an explicit number while the series is not manual, then the TestManual error.
17. Sandbox (not automated, permissions mock unreliable per FR-023): Reader GET ok / PATCH denied; Manager DELETE denied; Admin all.

## Risks and open questions
- Q1 (IDs): the requested test IDs 50150-50159 are free in code but **reserved** by FR-001/004/006/007 plans and docs/TODO.md. Recommend 50180-50182 (first unreserved). Alternative: reuse 50150-50152 and update the old reservations. **Decided: use 50180-50182.**
- Q2 (business rule): without a GUI, the final-status and remove-employee confirms default to Yes, so PATCH `Lost`/`Disposed` acts immediately (TODO housekeeping item). Recommend accepting this (an explicit API call means intent). Alternative: block final statuses via the API. **Decided: accept.**
- Q3 (tests): HTTP tests need the API endpoint in the CI container and the Tests-TestLibraries dependency. If this is not possible, fall back to direct table calls for the rules and do the API checks in the sandbox. TestPage on an API page is unverified. **Decided: try the real API tests, with the table-level fallback.**
- Assumed APIPublisher `miguelCarvalho` because the issue URL omits the publisher segment and the platform requires one. Assumed `number` stays editable (rename, as on the card) because the card allows it. Assumed no category description/employee name fields because C4 keeps relationships as codes and Employee read is not in the EQM sets.
- V1 Unverified: enum `_x0020_` encoding, read-only field behavior on PATCH (scenario 11), and Code[20] as a bound action parameter (fallback: Text, then CopyStr).
