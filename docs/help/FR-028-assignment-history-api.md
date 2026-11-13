# Assignment History API (AppSource end-user help)

The Assignment History API lets other systems, such as reporting and analytics platforms, read the assignment history of your equipment from Business Central: which equipment was assigned to which employee, from when, and until when. It is read-only. Assignments are still created and closed in Business Central when you assign and return equipment.

TODO(verify): this feature has not been tested in a sandbox. Automated table-level tests are written and compile, but have not been run yet. Reading data, filtering, the address and permissions through the API are not verified.

## Before you start: permissions
- **Equipment Reader, Equipment Manager and Administrator** can read assignments (GET).
- Nobody can create, change or delete assignments through this API.

TODO(verify): permissions were not checked in a sandbox.

## Address
`/api/miguelCarvalho/equipment/v1.0/companies({companyId})/assignments`

Use `assignments({id})` for one record, where `id` is the value of the `id` field. Authentication is the same as for other Business Central APIs. TODO(verify): the address was not tested against a sandbox.

## Fields
| Field | What it is |
|---|---|
| `id` | Unique ID of the record. |
| `entryNumber` | Running number of the history entry. Sort by it for chronological order. |
| `equipmentNumber` | Number of the equipment. Matches `equipmentNumber` in the equipment API. |
| `employeeNumber` | Number of the employee who had the equipment. |
| `assignmentDate` | Date the equipment was assigned. |
| `status` | `Active` for the current assignment, `Closed` once the equipment was returned. |
| `closingDate` | Date the equipment was returned. Empty while the assignment is active. |
| `lastModifiedDateTime` | When the record was last changed. |

All fields are read-only. The names of the Business Central users who made or closed the assignment are not included, because they are personal data.

## What you can do
| Request | What it does |
|---|---|
| GET `assignments` | Lists all assignments, active and closed. |
| GET `assignments?$filter=status eq 'Closed'` | Lists closed assignments only. |
| GET `assignments?$filter=equipmentNumber eq 'X'` | Lists the history of one piece of equipment. |
| GET `assignments?$filter=employeeNumber eq 'X'` | Lists the assignments of one employee. |
| GET `assignments?$filter=lastModifiedDateTime gt <date-time>` | Lists records changed since a point in time, for incremental sync. |
| GET `assignments({id})` | Returns one assignment. |

## Good to know
- The list includes the current (active) assignment of each piece of equipment as well as past ones.
- Employees and equipment appear as numbers only. To get equipment details, look up `equipmentNumber` in the equipment API.
- A just-closed assignment can appear in the API with a short delay.
- Writes (POST, PATCH, DELETE) are not supported. The exact error returned has not been verified.
- Version 1.0 is a frozen public contract once released: field names and types will not change. Breaking changes will come as a new version (v2.0).

For authentication and general API use, see the Microsoft Learn documentation for Business Central APIs.

## Release notes
Assignment History API: other systems can now read the assignment history of your equipment through the Business Central API (v1.0, publisher miguelCarvalho, group equipment, entity assignments). Each entry shows the equipment, the employee, the assignment date, the status and the closing date, for both current and past assignments. The API is read-only and does not include user names. Equipment Reader, Manager and Administrator can use it.
