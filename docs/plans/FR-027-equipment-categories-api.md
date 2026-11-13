# FR-027 Equipment Categories API

> Status: **approved** (Q1 = read-only, Q2 = all categories with an active field). Source: GitHub issue #65. Branch `feature/FR-027-equipment-categories-api`. No base behavior touched (own table only), so no events report is needed. Binding conventions: C1 to C10 in `docs/plans/FR-026-equipment-api.md` (FR-026 is already on `main`).

## Goal
Expose the equipment categories of table 50101 "EQM Equipment Category" (FR-002) through the custom API v1.0, so external systems can list the categories and resolve the `categoryCode` values of the `equipments` entity without database access. The entity is read-only (GET only); categories stay maintained in the UI by administrators.

## Approach and rejected alternatives
- Chosen: one read-only API page on table 50101 (C1 + C7), entity `category`/`categories` (C2), all categories returned with an `active` field; clients filter with `$filter=active eq true`. No codeunit, no table change, no bound actions.
- Rejected: read-write (POST/PATCH/DELETE): the issue only asks to retrieve; category maintenance is administrator setup, and writes would freeze rename (OnRename) and delete (OnDelete) behavior into the public contract.
- Rejected: return only active categories (fixed page filter): `equipments` can still return inactive category codes, and clients could not resolve them.
- Rejected: API query object: no `SystemId` key or single-entity GET by id, and it would break the "one API page per entity" pattern of C9.
- Rejected: equipment count or other FlowFields per category: not requested (speculative).

## Objects
IDs in use (checked `app/src`, `test/src`): pages 50100-50123 and 50130-50131, codeunits 50103-50118, tables 50100-50109; test codeunits 50178-50180 and 50183. Page 50124 and test codeunit 50181 are reserved for FR-027 by FR-026 C10 and are free.
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Page (API) | 50124 | EQM Category API | New | `categories` entity, file `app/src/API/EQMCategoryAPI.Page.al`, SourceTable "EQM Equipment Category" |
| PermissionSet | 50100 | EQM - Reader | Modify (own) | `page "EQM Category API" = X` |
| Codeunit (test) | 50181 | EQM Category API Tests | New | Automatable scenarios below, `test/src/EQMCategoryAPITests.Codeunit.al` |

## Data model and upgrade impact
- No new fields or tables, no upgrade codeunit. Page fields (API name <- table field, all read-only because the page is not editable): `id` <- SystemId, `code` <- Code, `description` <- Description, `active` <- Active, `lastModifiedDateTime` <- SystemModifiedAt. Captions = table field captions ('Id', 'Code', 'Description', 'Active', 'Last Modified Date-Time'). DataClassification unchanged (table is CustomerContent).

## Events
- Subscribed: none. Published: none (read-only page, no logic).

## Permissions
- EQM - Reader: add `page "EQM Category API" = X` directly after `page "EQM Equipment API" = X,` (C8/C9, API page ID order). Read comes from the existing `tabledata "EQM Equipment Category" = R` in Reader; Manager and Administrator inherit it. No tabledata change.

## Compatibility
- Additive only; the only change to an existing object is one permission line (no breaking risk). **At first AppSource release the page becomes a public contract:** entity names, field names and types of v1.0 are frozen. Adding writes later is possible in v1.0 only as an additive change; removing/renaming fields needs `v2.0` and Obsolete on v1.0. `Extensible = false`.

## Implementation steps
1. Create page 50124 "EQM Category API" with C1 properties (PageType API, APIPublisher 'miguelCarvalho', APIGroup 'equipment', APIVersion 'v1.0', ODataKeyFields SystemId, DelayedInsert true, Extensible false), EntityName 'category', EntitySetName 'categories', EntityCaption 'Category', EntitySetCaption 'Categories', Caption 'Category API', and C7 properties (Editable false, InsertAllowed false, ModifyAllowed false, DeleteAllowed false, DataAccessIntent ReadOnly). Add a repeater with the five fields in the Data model order. No triggers, no procedures. Compile.
2. Add the EQM - Reader line (Permissions). Build the main app and commit the regenerated `.g.xlf`.
3. Create test codeunit 50181 (Subtype Test, TestPermissions Disabled, AutoRollback per test, `Library Assert`, Locked test labels with an `EQMCAT` prefix, pattern of 50180). Implement scenarios 1-3 at table level (HTTP calls cannot authenticate in CI, see FR-026 Q3). Build the test app.
4. Documenter: `docs/features/FR-027-equipment-categories-api.md`, `docs/help/FR-027-equipment-categories-api.md` (URL `/api/miguelCarvalho/equipment/v1.0/companies({id})/categories`, fields, `$filter=active eq true`, read-only), CHANGELOG section at the top, `docs/TODO.md` section at the end with the sandbox checks (scenarios 4-8); tick the FR-026 follow-up line for FR-027.

## Test scenarios
Setup: active category EQMCAT-A (description 'Laptops'), inactive category EQMCAT-I.
1. Given the setup, when categories are read with Active = true (the `$filter=active eq true` equivalent), then EQMCAT-A is included and EQMCAT-I is not; without the filter, both are included.
2. Given EQMCAT-A, when it is read by its SystemId (GetBySystemId, the `categories({id})` equivalent), then Code, Description and Active match.
3. Given EQMCAT-A, when its Description is modified, then SystemId is unchanged and SystemModifiedAt is filled (the `id` is stable for clients).
4. Sandbox: when GET `.../categories`, then 200 with `id`, `code`, `description`, `active`, `lastModifiedDateTime` for every category (active and inactive), camelCase names.
5. Sandbox: when GET `.../categories({id})` with the SystemId of EQMCAT-A, then a single entity; with an unknown GUID, then 404.
6. Sandbox (neg): when POST, PATCH or DELETE on `categories`, then the request is rejected (record the HTTP status) and no data changes.
7. Sandbox: with an equipment whose category is EQMCAT-I, the `categoryCode` from GET `equipments` is found in GET `categories`.
8. Sandbox permissions (not SUPER): a user with only EQM - Reader gets 200 on GET; a user without any EQM set gets a permission error.

## Risks and open questions
- Q1 (design): read-only or read-write? Options: **read-only** (GET only) or full CRUD (POST/PATCH/DELETE through the table triggers; Administrator only, since only Admin has I/M/D on categories). **Recommend read-only:** the issue only asks to retrieve, and it keeps the frozen contract small.
- Q2 (business rule): which categories are returned? Options: **all, with an `active` field** or only active ones. **Recommend all:** equipment can reference inactive categories, and clients filter with `$filter=active eq true`.
- Assumed page name "EQM Category API" (fits the 30-character limit with prefix) and EntitySetCaption 'Categories' because C1 requires translatable captions. Assumed APIPublisher `miguelCarvalho` and the `/api/miguelCarvalho/equipment/v1.0/...` URL because the issue URL omits the publisher and C1 fixes it.
- Assumed DelayedInsert = true is kept although inserts are not allowed, because C1 lists it for every API page (harmless).
- V1 Unverified: the HTTP status for writes on a page with InsertAllowed/ModifyAllowed/DeleteAllowed = false (scenario 6); expected 4xx, recorded in the sandbox.
- Risk: the automated tests only cover table behavior; the API layer (scenarios 4-8) is verified manually in the sandbox, as in FR-026.
