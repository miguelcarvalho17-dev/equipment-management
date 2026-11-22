# Endpoints

> Applies to Equipment Management 29.0.0.0 (not released). Facts are taken from the repository on branch feature/FR-060-developer-documentation; nothing is verified in a Business Central sandbox.

This page lists the four API pages with their properties, fields and bound actions, copied from `app/src/API`. Every request sample is marked TODO(verify): no call was made against a Business Central environment. The user view of the same API is in [Using the API](../user-guide/using-the-api.md).

**In this article**
- [Common properties](#common-properties)
- [Equipment API (page 50123)](#equipment-api-page-50123)
- [Category API (page 50124)](#category-api-page-50124)
- [Assignment API (page 50125)](#assignment-api-page-50125)
- [Integration Event API (page 50126)](#integration-event-api-page-50126)
- [Open checks](#open-checks)
- [Related](#related)

## Common properties

All four pages: `PageType = API`, `APIPublisher = 'miguelCarvalho'`, `APIGroup = 'equipment'`, `APIVersion = 'v1.0'`, `ODataKeyFields = SystemId`, `DelayedInsert = true`, `Extensible = false`. They call `FeatureMgt.CheckEnabled("EQM Feature"::"API Integration")` in `OnOpenPage`. Route: `/api/miguelCarvalho/equipment/v1.0/companies({companyId})/<entitySet>`; see the [API overview](README.md#route). A property that the source does not set is shown as "not set" and keeps the platform default.

## Equipment API (page 50123)

Source: `app/src/API/EQMEquipmentAPI.Page.al`. Source table: `EQM Equipment` (50100).

| Property | Value |
|---|---|
| EntityName / EntitySetName | `equipment` / `equipments` |
| EntityCaption / EntitySetCaption | `Equipment` / `Equipment` |
| InsertAllowed, ModifyAllowed, DeleteAllowed | not set (allowed) |
| Editable, DataAccessIntent | not set |

Operations: GET, POST, PATCH, DELETE, and the bound actions below. Writes use the table triggers, so the rules of the UI apply ([FR-026](../features/FR-026-equipment-api.md)): POST creates equipment with the number series number and status Available; status `Assigned`, `Disposed` or `Lost` on POST is rejected; a PATCH of status to `Assigned` fails, and API clients use `assign`; DELETE is rejected for assigned equipment, equipment with assignment history or with maintenance records.

| JSON name | Source field | Type | Editable | Notes |
|---|---|---|---|---|
| `id` | SystemId | Guid | No | Key. |
| `number` | "No." | Code[20] | Yes | On POST an explicit number is accepted only when the number series is manual. |
| `description` | Description | Text[100] | Yes | |
| `categoryCode` | "Category Code" | Code[20] | Yes | Must be an existing, active category. |
| `serialNumber` | "Serial No." | Code[50] | Yes | Must be unique. |
| `manufacturer` | Manufacturer | Text[100] | Yes | |
| `model` | Model | Text[100] | Yes | |
| `purchaseDate` | "Purchase Date" | Date | Yes | |
| `purchaseCost` | "Purchase Cost" | Decimal | Yes | |
| `status` | Status | Enum `EQM Equipment Status` | Yes | Enum value name; spaces as `_x0020_` (unverified). Table rules apply. |
| `assignedEmployeeNumber` | "Assigned Employee No." | Code[20] | No | Set only by `assign`. |
| `locationCode` | "Location Code" | Code[10] | Yes | |
| `warrantyStartDate` | "Warranty Start Date" | Date | Yes | |
| `warrantyEndDate` | "Warranty End Date" | Date | Yes | Must be after the start date. |
| `warrantyProvider` | "Warranty Provider" | Text[100] | Yes | |
| `warrantyReferenceNumber` | "Warranty Reference No." | Text[50] | Yes | |
| `lastMaintenanceDate` | "Last Maintenance Date" | Date | Yes | Must not be in the future (table rule). |
| `nextMaintenanceDate` | "Next Maintenance Date" | Date | No | |
| `maintenanceFrequencyMonths` | "Maintenance Frequency (Months)" | Integer | Yes | |
| `lastModifiedDateTime` | SystemModifiedAt | DateTime | No | |

Not exposed: No. Series, Date Filter, the FlowFields and the Picture.

**Bound actions** (`[ServiceEnabled]`, signatures copied from the source):

```al
procedure assign(var ActionContext: WebServiceActionContext; employeeNumber: Code[20])
procedure returnEquipment(var ActionContext: WebServiceActionContext)
```

| Action | Effect |
|---|---|
| `assign` | Calls `Rec.AssignEmployee(employeeNumber)`: status Assigned, employee set, active assignment entry. Errors: inactive employee, final status, already assigned, open maintenance. |
| `returnEquipment` | Calls `Rec.UnassignEmployee()`: status Available, entry closed. Error if the equipment is not assigned. |

Both set the result code `Updated` and return the entity key. Samples, TODO(verify) (not executed):

```text
POST .../equipments({id})/Microsoft.NAV.assign
Content-Type: application/json

{"employeeNumber": "<employee no.>"}

POST .../equipments({id})/Microsoft.NAV.returnEquipment
```

## Category API (page 50124)

Source: `app/src/API/EQMCategoryAPI.Page.al`. Source table: `EQM Equipment Category` (50101).

| Property | Value |
|---|---|
| EntityName / EntitySetName | `category` / `categories` |
| EntityCaption / EntitySetCaption | `Category` / `Categories` |
| Editable | `false` |
| InsertAllowed, ModifyAllowed, DeleteAllowed | `false`, `false`, `false` |
| DataAccessIntent | `ReadOnly` |

Operations: GET only.

| JSON name | Source field | Type | Editable | Notes |
|---|---|---|---|---|
| `id` | SystemId | Guid | No | Key. |
| `code` | Code | Code[20] | No | |
| `description` | Description | Text[100] | No | |
| `active` | Active | Boolean | No | Inactive categories are included. |
| `lastModifiedDateTime` | SystemModifiedAt | DateTime | No | |

## Assignment API (page 50125)

Source: `app/src/API/EQMAssignmentAPI.Page.al`. Source table: `EQM Equipment Assignment` (50103).

| Property | Value |
|---|---|
| EntityName / EntitySetName | `assignment` / `assignments` |
| EntityCaption / EntitySetCaption | `Assignment` / `Assignments` |
| Editable | `false` |
| InsertAllowed, ModifyAllowed, DeleteAllowed | `false`, `false`, `false` |
| DataAccessIntent | `ReadOnly` |

Operations: GET only (the assignment history).

| JSON name | Source field | Type | Editable | Notes |
|---|---|---|---|---|
| `id` | SystemId | Guid | No | Key. |
| `entryNumber` | "Entry No." | Integer | No | |
| `equipmentNumber` | "Equipment No." | Code[20] | No | |
| `employeeNumber` | "Employee No." | Code[20] | No | |
| `assignmentDate` | "Assignment Date" | Date | No | |
| `status` | Status | Enum `EQM Assignment Status` | No | |
| `closingDate` | "Closing Date" | Date | No | |
| `lastModifiedDateTime` | SystemModifiedAt | DateTime | No | |

## Integration Event API (page 50126)

Source: `app/src/API/EQMIntegrationEventAPI.Page.al`. Source table: `EQM Integration Event Entry` (50110), the outbox of [FR-030](../features/FR-030-event-subscribers.md). The outbox is only written when "Integration Events Enabled" is on in Equipment Setup.

| Property | Value |
|---|---|
| EntityName / EntitySetName | `integrationEvent` / `integrationEvents` |
| EntityCaption / EntitySetCaption | `Integration Event` / `Integration Events` |
| Editable | `false` |
| InsertAllowed, ModifyAllowed, DeleteAllowed | `false`, `false`, `false` |
| DataAccessIntent | not set (the bound action writes) |

Operations: GET, and the bound action `markProcessed`.

| JSON name | Source field | Type | Editable | Notes |
|---|---|---|---|---|
| `id` | SystemId | Guid | No | Key. |
| `entryNumber` | "Entry No." | Integer | No | |
| `eventType` | "Event Type" | Enum `EQM Integration Event Type` | No | Equipment Created, Equipment Assigned, Equipment Returned, Maintenance Created, Warranty Expired. |
| `equipmentNumber` | "Equipment No." | Code[20] | No | |
| `equipmentStatus` | "Equipment Status" | Enum `EQM Equipment Status` | No | Status at event time. |
| `assignmentEntryNumber` | "Assignment Entry No." | Integer | No | 0 when not applicable. |
| `maintenanceNumber` | "Maintenance No." | Code[20] | No | Blank when not applicable. |
| `processed` | Processed | Boolean | No | |
| `processedDateTime` | "Processed At" | DateTime | No | |
| `createdDateTime` | SystemCreatedAt | DateTime | No | |
| `lastModifiedDateTime` | SystemModifiedAt | DateTime | No | |

**Bound action** (signature copied from the source):

```al
procedure markProcessed(var ActionContext: WebServiceActionContext)
```

`markProcessed` calls `MarkProcessed` of codeunit 50122, sets Processed and the processed time, and does nothing if the entry is already processed, so a client can retry. Sample and polling pattern, TODO(verify) (not executed):

```text
GET  .../integrationEvents?$filter=processed eq false&$orderby=entryNumber
POST .../integrationEvents({id})/Microsoft.NAV.markProcessed
```

TODO(verify): a bound action on an API page with `ModifyAllowed = false` that changes the record through a codeunit (FR-030 check V1). The fallback would be `ModifyAllowed = true` with every field `Editable = false`.

## Open checks

Not verified in a sandbox. The authoritative lists are in [`docs/TODO.md`](../TODO.md), sections FR-026, FR-027 and FR-028:

- GET list, GET by id, unknown id (404) and the OData filter on enums.
- Enum encoding: the status value for In Maintenance as `In_x0020_Maintenance`.
- PATCH of a read-only field (`assignedEmployeeNumber`): error or ignored.
- `employeeNumber` as `Code[20]` parameter of the bound action `assign`.
- Rejected writes on the read-only pages: record the HTTP status for POST, PATCH and DELETE.
- Filters `employeeNumber eq` and `lastModifiedDateTime gt` on assignments.
- ETag and `If-Match` on PATCH and DELETE.
- Permissions per role (not SUPER).

## Related

- [API overview](README.md), [Events](events.md)
- [Using the API](../user-guide/using-the-api.md)
- Feature docs: [FR-026](../features/FR-026-equipment-api.md), [FR-027](../features/FR-027-equipment-categories-api.md), [FR-028](../features/FR-028-assignment-history-api.md), [FR-030](../features/FR-030-event-subscribers.md)
- Microsoft Learn: [API page type](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-api-pagetype), [Developing a custom API](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-develop-custom-api)
