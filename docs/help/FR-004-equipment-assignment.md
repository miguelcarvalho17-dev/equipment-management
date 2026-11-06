# Assign equipment to employees (AppSource end-user help)

Every time you assign equipment to an employee, the app records an assignment: the equipment, the employee, the
date and who assigned it. When the equipment stops being assigned, the assignment is closed automatically.

## Before you start: permissions
- **Equipment Manager** to assign and return equipment.
- **Equipment Reader** to view the assignment list.

## Assign equipment
1. Open the equipment card of saved equipment with the status **Available**.
2. Choose **Assign to Employee** and select an active employee.
3. The status becomes **Assigned**, and an assignment is recorded with your work date and your user name.

Notes:
- Only **Available** equipment can be assigned. Equipment in maintenance, lost or disposed cannot be assigned. Equipment with an open maintenance record cannot be assigned either; Assign to Employee is then unavailable.
- New equipment cannot start as Assigned. Create it first, then assign it. On a new card, **Status** offers only Available and In Maintenance.
- **Assigned Employee No.** on the card cannot be typed in; use **Assign to Employee**.
- To give assigned equipment to another employee, choose **Return** first, then assign it again.

## End an assignment
Choose **Return** on the card. The assignment is closed with today's work date and your user name. It is also closed
when the status changes from Assigned to In Maintenance, Lost or Disposed.

## View assignments
- On the equipment card or list: **Assignments** shows the history of the equipment.
- On the employee card: **Related > Equipment > Equipment Assignments** shows the equipment assigned to that employee, now and before.
- The list has the views **Active** and **Closed**. Entries cannot be edited or deleted, and closed entries can never be changed.

| Field | Meaning |
|---|---|
| Assignment Date / Assigned By | Work date and user at the time of assignment. |
| Status | Active while assigned, Closed afterwards. |
| Closing Date / Closed By | Work date and user when the assignment ended. |

## Deleting equipment
- Equipment that is Assigned cannot be deleted. Return it first.
- Equipment that has been assigned at least once has assignment history and cannot be deleted, even after it is returned. Set its status to **Disposed** instead.
- Only equipment that was never assigned can be deleted.
- Assignments are never deleted. Closed assignments cannot be changed. See the FR-006 help.

## Existing data
Equipment that was already assigned before this version has no assignment record until it is returned and assigned again.
