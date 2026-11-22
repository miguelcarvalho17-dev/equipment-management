# API overview

> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-060-developer-documentation; nothing is verified in a Business Central sandbox.

Equipment Management has four REST API pages (v1.0), a set of AL events for partner extensions, two external business events for Power Automate and an integration event outbox that external systems poll through the API. None of the API calls was tested against a running Business Central environment. This page is the entry point; the detail is in [endpoints](endpoints.md) and [events](events.md).

**In this article**
- [Surfaces](#surfaces)
- [Route](#route)
- [Authentication and permissions](#authentication-and-permissions)
- [Feature switch](#feature-switch)
- [Conventions and versioning](#conventions-and-versioning)
- [Tests](#tests)
- [Related](#related)

## Surfaces

| Surface | For | Where |
|---|---|---|
| REST API pages (v1.0) | External systems: inventory sync, CMDB, mobile, self-service | [endpoints](endpoints.md) |
| AL events (business events and process hooks) | Partner extensions written in AL | [events](events.md) |
| External business events | Power Automate flows ("When a business event occurs") | [events](events.md#external-business-events-power-automate) |
| Integration event outbox | External systems that poll for what happened | table 50110, API page 50126, [FR-030](../features/FR-030-event-subscribers.md) |

## Route

The API pages set `APIPublisher = 'miguelCarvalho'`, `APIGroup = 'equipment'` and `APIVersion = 'v1.0'`. The route of an entity is:

```text
/api/miguelCarvalho/equipment/v1.0/companies({companyId})/<entitySet>
```

The full URL follows the Business Central pattern (see [API endpoint structure](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/webservices/api-endpoint-structure)):

```text
https://api.businesscentral.dynamics.com/v2.0/{environment name}/api/miguelCarvalho/equipment/v1.0/companies({companyId})/equipments
```

Entity sets: `equipments`, `categories`, `assignments`, `integrationEvents`. The key of every entity is `id` (`SystemId`).

The root `README.md` shows the route `/api/equipment/v1.0/...`. That is wrong (the publisher segment is missing). It is recorded in [`docs/TODO.md`](../TODO.md) ("FR-060 checks") and not changed here. TODO(verify): the base URL in a sandbox (the publisher `miguelCarvalho` is an assumption of the FR-026 plan).

## Authentication and permissions

- API clients authenticate as for any Business Central API: a Microsoft Entra application with OAuth ([Authenticating with Business Central](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/webservices/authenticate-web-services-using-oauth)).
- The user or application needs the permission set **EQM - API Consumer** (data access through the four API pages only, no UI pages) and the base-app prerequisite **D365 BASIC** ([FR-036](../features/FR-036-permission-sets.md)). **EQM - Reader** also holds `page ... = X` for the four API pages.
- Delete on equipment is not part of API Consumer (decision D2 in FR-036); Administrator has it.
- TODO(verify): the sandbox checks S1 to S4 of FR-036 (an Entra application with API Consumer plus D365 BASIC can use the APIs; delete fails; no UI page access; `GET /companies` works) are not done (`docs/TODO.md`, "FR-036 Permission Sets").

## Feature switch

Every API page checks the feature **API Integration** (enum 50112 value `API Integration`, switched on the Equipment Features page) when it opens. From `OnOpenPage` of each API page:

```al
FeatureMgt.CheckEnabled("EQM Feature"::"API Integration");
```

When the feature is off, the API returns an error. When no setup row exists for the feature, or the caller cannot read the setup, the feature counts as on (`IsEnabled` in codeunit 50138 fails open, because feature activation is not a security boundary).

## Conventions and versioning

The conventions C1 to C10 of [FR-026](../features/FR-026-equipment-api.md) apply to every API page. In short:

- `PageType = API`, the route properties above, `DelayedInsert = true`, `ODataKeyFields = SystemId`, `Extensible = false`, translatable `EntityCaption` and `EntitySetCaption` (C1, C2).
- JSON names are camelCase. `id` is `SystemId` and `lastModifiedDateTime` is `SystemModifiedAt`, both read-only. "No." becomes `number`, "...No." becomes `...Number` (C3).
- Relations are flat code fields only, with no navigation parts and no `...Id` foreign keys in v1.0 (C4). Enums are exposed as enum fields: the value name, with spaces encoded as `_x0020_` (C5, unverified).
- No `OnInsertRecord`, `OnModifyRecord` or `OnDeleteRecord` override; writes use the table triggers, so the UI rules apply. Workflow operations are `[ServiceEnabled]` bound actions. Confirmations default to Yes because there is no UI (C6).
- Read-only entities set `Editable`, `InsertAllowed`, `ModifyAllowed` and `DeleteAllowed` to false and `DataAccessIntent = ReadOnly` (C7), with the exception noted for page 50126 in [endpoints](endpoints.md).
- Each API page has `= X` in the permission sets (C8); one page per feature in `app/src/API/` (C9); page IDs 50123 to 50126 (C10).
- **Versioning.** v1.0 becomes a frozen public contract at the first AppSource release: entity names, field names, types and actions do not change. A breaking change needs a new page with `APIVersion = 'v2.0'`, and v1.0 is then marked obsolete.

## Tests

Three test codeunits cover the API at table level: 50180 (equipment, 35 tests), 50181 (categories, 6) and 50182 (assignments, 7). They call the table triggers and procedures that the pages use; they do not call the pages, because HTTP tests failed with HTTP 401 in CI. All 48 passed in AL-Go CI when they were added (PR #111 for 50180, PR #115 for 50181, PR #117 for 50182), and they are part of CI/CD run 44925652127 (569 tests passed).

Procedure reach of the API pages (FR-047) is 0.0% (0/7), measured with `python3 .github/scripts/coverage_check.py` on 2026-11-22. See [testing strategy](../architecture/testing-strategy.md#coverage-targets). The manual sandbox checks (GET, filters, rejected writes, ETag, permissions) are open in `docs/TODO.md`.

## Related

- [Endpoints](endpoints.md), [Events](events.md)
- User view of the API: [Using the API](../user-guide/using-the-api.md)
- Feature docs: [FR-026](../features/FR-026-equipment-api.md), [FR-027](../features/FR-027-equipment-categories-api.md), [FR-028](../features/FR-028-assignment-history-api.md), [FR-030](../features/FR-030-event-subscribers.md), [FR-036](../features/FR-036-permission-sets.md)
- Microsoft Learn: [Developing a custom API](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-develop-custom-api), [API page type](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-api-pagetype), [API endpoint structure](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/webservices/api-endpoint-structure)
