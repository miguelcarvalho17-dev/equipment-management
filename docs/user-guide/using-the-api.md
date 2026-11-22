# Using the API

This article explains the Business Central APIs that Equipment Management provides, and how an external system gets access to them. It is for integrators.

TODO(verify): none of the APIs is tested in a sandbox. The automated tests cover the business rules only. Reading data, filtering, the addresses, the field names, the encoding of status values, the ETag handling and the permissions through the API are not verified.

**In this article**
- [What the APIs expose](#what-the-apis-expose)
- [Address](#address)
- [Equipment](#equipment)
- [Categories](#categories)
- [Assignments](#assignments)
- [Integration events](#integration-events)
- [Get access](#get-access)

## What the APIs expose

| API | Entity set | What you can do |
|---|---|---|
| Equipment | `equipments` | Read, create, change and delete equipment, and assign and return it. |
| Categories | `categories` | Read the equipment categories. |
| Assignments | `assignments` | Read the assignment history. |
| Integration events | `integrationEvents` | Read the integration event entries, and mark them as processed. |

The same business rules apply as in the app. For example, equipment needs an active category, serial numbers must be unique, and equipment with history cannot be deleted. Errors are returned with the same text as in Business Central.

The APIs work only when the API Integration feature is on. When it is off, the APIs return an error. See [Setup and configuration](setup-and-configuration.md).

## Address

The APIs use this pattern:

`/api/miguelCarvalho/equipment/v1.0/companies({companyId})/<entity set>`

Use `<entity set>({id})` for one record, where `id` is the value of the `id` field. The authentication is the same as for other Business Central APIs. The version is 1.0, and it is a frozen public contract once released: field names, types and actions will not change. Breaking changes will come as a new version.

## Equipment

Address: `.../equipments`

| Field | What it is |
|---|---|
| `id` | The unique ID of the record. Read-only. |
| `number` | The equipment number. Assigned from the number series when you create equipment. |
| `description`, `manufacturer`, `model`, `serialNumber` | Equipment details. The serial number must be unique. |
| `categoryCode` | The code of an active equipment category. Required. |
| `status` | Available, Assigned, In Maintenance, Lost or Disposed. |
| `assignedEmployeeNumber` | The employee the equipment is assigned to. Read-only. Use the assign action. |
| `locationCode` | The location. |
| `purchaseDate`, `purchaseCost` | Purchase information. |
| `warrantyStartDate`, `warrantyEndDate`, `warrantyProvider`, `warrantyReferenceNumber` | Warranty information. The end date must be later than the start date. |
| `lastMaintenanceDate`, `maintenanceFrequencyMonths` | Maintenance information. |
| `nextMaintenanceDate` | Calculated. Read-only. |
| `lastModifiedDateTime` | When the record was last changed. Read-only. |

Status values with spaces are written with `_x0020_`, for example `In_x0020_Maintenance`.

| Request | What it does |
|---|---|
| GET `equipments` | Lists equipment. You can filter, for example by `status`. |
| POST `equipments` | Creates equipment. It starts as Available. Send at least `description` and `categoryCode`. |
| PATCH `equipments({id})` | Changes fields of the equipment. |
| DELETE `equipments({id})` | Deletes equipment that was never assigned and has no maintenance records. |
| POST `equipments({id})/Microsoft.NAV.assign` | Assigns the equipment to an active employee. Send `{"employeeNumber": "EMP1"}`. |
| POST `equipments({id})/Microsoft.NAV.returnEquipment` | Returns the equipment from its employee. It becomes Available. |

To assign equipment, always use the `assign` action. Changing `status` to `Assigned` with PATCH fails. To return equipment, use the `returnEquipment` action. Changing assigned equipment to `Available` with PATCH fails. You cannot create equipment with the status Assigned, Lost or Disposed.

Setting `status` to `Lost` or `Disposed` takes effect at once, without a confirmation. It removes the assigned employee and closes the assignment, and a final status cannot be changed again. You can set your own equipment number only when the number series is set to manual numbering.

## Categories

Address: `.../categories`

| Field | What it is |
|---|---|
| `id` | The unique ID of the record. |
| `code` | The category code, the value used in `categoryCode` of equipment. |
| `description` | The category description. |
| `active` | Whether the category is active. |
| `lastModifiedDateTime` | When the record was last changed. |

All fields are read-only. GET `categories` lists all categories, active and inactive. GET `categories?$filter=active eq true` lists the active ones. Writes are not supported. The exact error that a write returns is not verified.

## Assignments

Address: `.../assignments`

| Field | What it is |
|---|---|
| `id` | The unique ID of the record. |
| `entryNumber` | The running number of the history entry. Sort by it for chronological order. |
| `equipmentNumber` | The number of the equipment. Matches `number` in the equipment API. |
| `employeeNumber` | The number of the employee who had the equipment. |
| `assignmentDate` | The date the equipment was assigned. |
| `status` | `Active` for the current assignment, `Closed` once the equipment was returned. |
| `closingDate` | The date the equipment was returned. Empty while active. |
| `lastModifiedDateTime` | When the record was last changed. |

All fields are read-only. The names of the users who made or closed the assignment are not included, because they are personal data.

| Request | What it does |
|---|---|
| GET `assignments` | Lists all assignments, active and closed. |
| GET `assignments?$filter=status eq 'Closed'` | Lists closed assignments. |
| GET `assignments?$filter=equipmentNumber eq 'X'` | Lists the history of one piece of equipment. |
| GET `assignments?$filter=employeeNumber eq 'X'` | Lists the assignments of one employee. |
| GET `assignments?$filter=lastModifiedDateTime gt <date-time>` | Lists records changed since a point in time, for incremental sync. |

A just-closed assignment can appear in the API with a short delay. Writes are not supported.

## Integration events

Address: `.../integrationEvents`

All fields are read-only: `id`, `entryNumber`, `eventType`, `equipmentNumber`, `equipmentStatus`, `assignmentEntryNumber`, `maintenanceNumber`, `processed`, `processedDateTime`, `createdDateTime` and `lastModifiedDateTime`. The entries contain no user names and no employee numbers. To see the employee of an assignment, read the assignment through the assignments API, and filter on `entryNumber` equal to the `assignmentEntryNumber` of the entry.

Recommended routine:

1. GET `integrationEvents?$filter=processed eq false&$orderby=entryNumber`.
2. Handle each entry.
3. For each handled entry, POST `integrationEvents({id})/Microsoft.NAV.markProcessed`.

Calling `markProcessed` again on a processed entry changes nothing, so it is safe to retry. The entries are written only when **Integration Events Enabled** is on. See [Integration with other apps](integration.md).

## Get access

A person who calls the API needs the permission set that fits the job: Equipment Reader to read, and Equipment Manager to also create, change, assign and return. Equipment Administrator also deletes equipment.

For a system that calls the API without a signed-in person, use the Equipment API Consumer permission set:

1. Register the application in Microsoft Entra, and note its application (client) ID.
2. In Business Central, choose the search icon, enter **Microsoft Entra Applications**, and create a card for that ID. Enable it.
3. In the permission sets of the card, add **Equipment API Consumer** and **D365 BASIC**.

The integration can read equipment, categories, assignments and integration events. It can create and change equipment, assign and return equipment, and mark integration events as processed. It cannot delete equipment, change categories or setup, or open any page. TODO(verify): the names of the Microsoft Entra pages and the steps are not checked in a sandbox, and that the permission set refuses to open the equipment pages is not verified.

For reading incrementally on a large register, filter on `lastModifiedDateTime` in the equipment API and the assignment API.

See [Using service-to-service (S2S) authentication](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/automation-apis-using-s2s-authentication) and [Assign permissions to users and groups](https://learn.microsoft.com/dynamics365/business-central/ui-define-granular-permissions).

## What to know

- Equipment API Consumer is for an external system, not for a person.
- If you read many records, use the `lastModifiedDateTime` filter instead of reading everything.

## Related

- [Integration with other apps](integration.md)
- [Security and permissions](security-and-permissions.md)
- Feature article: [Equipment API](../help/FR-026-equipment-api.md)
- Feature article: [Equipment Categories API](../help/FR-027-equipment-categories-api.md)
- Feature article: [Assignment History API](../help/FR-028-assignment-history-api.md)
- Feature article: [Integration Events](../help/FR-030-event-subscribers.md)
- Feature article: [Choosing a Permission Set for Equipment Management](../help/FR-036-permission-sets.md)
- Feature article: [Large registers: speed and filters](../help/FR-053-large-dataset-support.md)
- Learn: [Using service-to-service (S2S) authentication](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/automation-apis-using-s2s-authentication)

---
Previous: [Integration with other apps](integration.md) | Next: [Pages and UI reference](pages-and-ui-reference.md)
