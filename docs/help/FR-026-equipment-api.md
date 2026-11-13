# Equipment API (AppSource end-user help)

The Equipment API lets other systems (inventory sync, CMDB, mobile apps, self-service tools) read and maintain your equipment in Business Central without opening the Equipment Card. The same rules apply as in the app: for example, equipment needs an active category, serial numbers must be unique, and equipment with history cannot be deleted.

TODO(verify): this feature has not been tested in a sandbox. The automated tests cover the business rules at table level only; they compile in CI but have not been run there yet. Reading data, filtering, URL and field names, ETag and permissions through the API are not covered by automated tests.

## Before you start: permissions
- **Equipment Reader**: can only read equipment (GET). Cannot create, change or delete.
- **Equipment Manager**: can read, create, change, assign and return equipment. Cannot delete (the same as in the app).
- **Administrator**: can do everything, including delete.

TODO(verify): permissions were not checked in a sandbox.

## Address
`/api/miguelCarvalho/equipment/v1.0/companies({companyId})/equipments`

Use `equipments({id})` for one record, where `id` is the value of the `id` field. Authentication is the same as for other Business Central APIs. TODO(verify): the address was not tested against a sandbox.

## Fields
| Field | What it is |
|---|---|
| `id` | Unique ID of the record. Read-only. |
| `number` | Equipment No. Assigned from the number series when you create equipment. |
| `description`, `manufacturer`, `model`, `serialNumber` | Equipment details. The serial number must be unique. |
| `categoryCode` | Code of an active equipment category. Required. |
| `status` | Available, Assigned, In Maintenance, Lost or Disposed (see below). |
| `assignedEmployeeNumber` | Employee the equipment is assigned to. Read-only: use the assign action. |
| `locationCode` | Location. |
| `purchaseDate`, `purchaseCost` | Purchase information. |
| `warrantyStartDate`, `warrantyEndDate`, `warrantyProvider`, `warrantyReferenceNumber` | Warranty information. The end date must be later than the start date. |
| `lastMaintenanceDate`, `maintenanceFrequencyMonths` | Maintenance information. |
| `nextMaintenanceDate` | Calculated. Read-only. |
| `lastModifiedDateTime` | When the record was last changed. Read-only. |

Status values with spaces are written with `_x0020_`, for example `In_x0020_Maintenance`. TODO(verify): this encoding was not tested in a sandbox.

## What you can do
| Request | What it does |
|---|---|
| GET `equipments` | Lists equipment. You can filter, for example by `status`. |
| POST `equipments` | Creates equipment. It starts as Available. Send at least `description` and `categoryCode`. |
| PATCH `equipments({id})` | Changes fields of the equipment. |
| DELETE `equipments({id})` | Deletes equipment that was never assigned and has no maintenance records. |
| POST `equipments({id})/Microsoft.NAV.assign` with `{"employeeNumber": "EMP1"}` | Assigns the equipment to an active employee. |
| POST `equipments({id})/Microsoft.NAV.returnEquipment` | Returns the equipment from its employee. It becomes Available. |

## Assign and return
- To assign equipment, always use the **assign** action. Changing `status` to `Assigned` with PATCH fails, and its error message mentions the Assign to Employee action on the Equipment Card. API clients do not have that card: use the assign action instead.
- To return equipment, use the **returnEquipment** action. Changing an assigned equipment to `Available` with PATCH fails.
- You cannot create equipment with status Assigned, Lost or Disposed. Create it first, then change the status.

## Good to know
- **Final statuses apply without a confirmation.** Setting `status` to `Lost` or `Disposed` through the API takes effect at once, removes the assigned employee and closes the assignment. A final status cannot be changed again.
- You can only set your own equipment number when the number series is set to manual numbering.
- Errors are returned with the same text as in Business Central.
- Version 1.0 is a frozen public contract once released: field names, types and actions will not change. Breaking changes will come as a new version (v2.0).

For authentication and general API use, see the Microsoft Learn documentation for Business Central APIs.

## Release notes
Equipment API: other systems can now read and maintain equipment through a new Business Central API (v1.0, publisher miguelCarvalho, group equipment). You can list, create, change and delete equipment, and assign or return it with the assign and returnEquipment actions. The same business rules as in the app apply. Equipment Reader can only read; Equipment Manager can change but not delete.
