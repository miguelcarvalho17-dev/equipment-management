# Equipment Categories API (AppSource end-user help)

The Equipment Categories API lets other systems read your equipment categories from Business Central. Use it to look up the category behind the `categoryCode` of an equipment record. It is read-only: you maintain categories in Business Central itself.

TODO(verify): this feature has not been tested in a sandbox. Automated table-level tests exist but have not been run yet. Reading data, filtering, the address and permissions through the API are not verified.

## Before you start: permissions
- **Equipment Reader, Equipment Manager and Administrator** can read categories (GET).
- Nobody can create, change or delete categories through this API.

TODO(verify): permissions were not checked in a sandbox.

## Address
`/api/miguelCarvalho/equipment/v1.0/companies({companyId})/categories`

Use `categories({id})` for one record, where `id` is the value of the `id` field. Authentication is the same as for other Business Central APIs. TODO(verify): the address was not tested against a sandbox.

## Fields
| Field | What it is |
|---|---|
| `id` | Unique ID of the record. |
| `code` | Category code, the value used in `categoryCode` of equipment. |
| `description` | Category description. |
| `active` | Whether the category is active. Only active categories can be chosen for new equipment. |
| `lastModifiedDateTime` | When the record was last changed. |

All fields are read-only.

## What you can do
| Request | What it does |
|---|---|
| GET `categories` | Lists all categories, active and inactive. |
| GET `categories?$filter=active eq true` | Lists active categories only. |
| GET `categories({id})` | Returns one category. |

## Good to know
- Inactive categories are included in the list, because existing equipment can still use them.
- Writes (POST, PATCH, DELETE) are not supported. The exact error returned has not been verified.
- Version 1.0 is a frozen public contract once released: field names and types will not change. Breaking changes will come as a new version (v2.0).

For authentication and general API use, see the Microsoft Learn documentation for Business Central APIs.

## Release notes
Equipment Categories API: other systems can now read your equipment categories through the Business Central API (v1.0, publisher miguelCarvalho, group equipment, entity categories). The list includes the code, description and active flag of every category, so you can resolve the category of any equipment. The API is read-only. Equipment Reader, Manager and Administrator can use it.
