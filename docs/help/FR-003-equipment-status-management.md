# Manage equipment status (AppSource end-user help)

Every piece of equipment has one status that shows where it stands.

## Before you start: permissions
Changing the status needs the **Equipment Manager** permission set (or Equipment Administrator). With **Equipment Reader** you can see the status and use the list views, but not change it.

## Statuses
| Status | Meaning |
|---|---|
| Available | In stock, not assigned to anyone. |
| Assigned | Assigned to an employee. |
| In Maintenance | Being serviced. It cannot be assigned. It is set automatically when you register maintenance (see the maintenance help). |
| Disposed | Permanently removed from use. |
| Lost | Permanently lost. |

In the **Status** list, Disposed appears before Lost. In the list and on the card, the status is shown in color.

## Change the status
1. Open the equipment card.
2. Choose a new value in **Status**.
Changing between Available, Assigned and In Maintenance is allowed, except that Assigned equipment becomes Available only through **Return**, and In Maintenance equipment cannot be set to Available (or Assigned) while it has an open maintenance record: post the record and the status changes to Available by itself. Lost and Disposed are still allowed. To assign equipment, use **Assign to Employee** (see the registration help).

## Lost and Disposed are permanent
- When you change the status to Lost or Disposed, you are asked to confirm. If an employee is assigned, the question names the employee, and the employee is removed from the equipment. Choose No to cancel.
- Once saved as Lost or Disposed, the status cannot be changed again, not even from Lost to Disposed. In the standard app there is no way to undo it.
- Lost and Disposed equipment cannot be assigned, and **Assign to Employee** is not available for it.
- You can still edit the other fields, and you can delete the equipment.
- New equipment cannot start as Lost or Disposed. On a new card, **Status** offers only Available, Assigned and In Maintenance. Create the equipment first, then change its status.

## Other things to know
- An employee can be on the equipment only while the status is Assigned. To keep an employee, leave the status as Assigned; to change the status to In Maintenance, Lost or Disposed, accept the question that removes the employee. To make assigned equipment Available, use **Return** (see the Return equipment help).
- Equipment with an open maintenance record cannot be assigned, whatever its status.
- Where no screen is shown (for example automated integrations), the confirmation is answered Yes automatically.
- Tools that skip checks, such as some data migration tools, bypass these rules.

## Filter the list by status
1. Open **Equipment**.
2. Choose a view: **Available**, **Assigned**, **In Maintenance**, **Lost** or **Disposed**. The default view shows all equipment.

## Related
- Equipment List, Equipment Card
- Register and assign equipment
