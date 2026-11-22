# Assignments

This article explains how to assign equipment to an employee, return it and review the assignment history. It is for Equipment Operators, Managers and Administrators. Equipment Readers can view the history.

**In this article**
- [Assign equipment to an employee](#assign-equipment-to-an-employee)
- [Return equipment](#return-equipment)
- [View the assignment history](#view-the-assignment-history)
- [Equipment on the employee card](#equipment-on-the-employee-card)
- [Delete rules](#delete-rules)

## Assign equipment to an employee

1. Open the card of saved equipment with the status **Available**.
2. Choose **Assign to Employee**.
3. Select an active employee. Employees who are blocked for privacy reasons are not listed.

The status becomes **Assigned**, and an assignment is recorded with your work date and your user name.

- Only available equipment can be assigned. Equipment in maintenance, lost or disposed cannot be assigned.
- Equipment with an open maintenance record cannot be assigned. **Assign to Employee** is then not available.
- **Assigned Employee No.** cannot be typed in. Use **Assign to Employee**.
- To give assigned equipment to another employee, return it first, and then assign it again.

## Return equipment

Return equipment when an employee gives it back. The status becomes **Available**, the employee is cleared and the assignment is closed. The assignment stays in the history.

### Return from the equipment card

1. Open the card of equipment with the status **Assigned**.
2. Choose **Return**.
3. Confirm the question.

If you choose **No**, nothing changes.

### Return from the employee card

1. Open the employee card and choose **Return Equipment**.
2. If the employee has no assigned equipment, a message tells you so.
3. Otherwise a list shows the equipment assigned to the employee. Select one and choose **OK**.
4. Confirm the question.

If someone else returned the equipment in the meantime, a message tells you that it is no longer assigned to the employee.

An assignment is also closed when the status changes from Assigned to In Maintenance, Lost or Disposed, and when you register maintenance for assigned equipment. In the second case, you confirm first.

## View the assignment history

The history keeps every assignment: the equipment, the employee, the dates and the user. Open it in one of these ways:

- On the equipment card or the equipment list, choose **Equipment**, and then **Assignments**. Or press Ctrl+F7.
- On the employee card, choose **Related**, then **Equipment**, then **Equipment Assignments**.
- Choose the search icon, enter **Equipment Assignments**, and choose the related link.

Use the views **Active** and **Closed** to filter.

| Field | Meaning |
|---|---|
| Equipment No. and Employee No. | The equipment and the employee. |
| Assignment Date | The work date when the equipment was assigned. |
| Closing Date | The work date when the equipment was returned or left the Assigned status. Blank while active. |
| Assigned By | The user who assigned the equipment. |
| Status | Active while assigned, Closed afterwards. |

Reassigning equipment gives two entries: the old one, which is Closed, and a new one, which is Active.

## Equipment on the employee card

The employee card has an **Equipment** group under **Related** with three actions.

| Action | Description |
|---|---|
| **Equipment Assignments** | View the equipment assignment history of the employee. |
| **Assigned Equipment** | View the equipment that is currently assigned to the employee. |
| **Equipment Requests** | View the equipment requests raised for the employee. Hidden when the Approval Workflows feature is off. |

The **Assigned Equipment** FactBox on the employee card lists the equipment that is currently assigned. Choose a number to open the equipment card. The FactBox is shown only to users who can read equipment.

## Delete rules

- Equipment that is assigned cannot be deleted. Return it first.
- Equipment that has been assigned at least once has assignment history and cannot be deleted, even after it is returned. Set its status to **Disposed** instead.
- You cannot delete an employee while equipment is assigned to the employee. Return the equipment first.

## What to know

- Closed assignments are never changed or deleted, not even by an administrator.
- If you change the number of equipment or of an employee, the history shows the new number.
- The history keeps employee numbers and user names. It cannot be removed from within the app.
- If an assigned employee no longer exists, use **Return**, and assign the equipment to someone else.
- Equipment that was assigned before the history existed has no assignment record until it is returned and assigned again.
- Employee names need the D365 BASIC permission set. Without it, the name columns are blank.

## Related

- [Equipment register](equipment-register.md)
- [Equipment requests](equipment-requests.md)
- Feature article: [Assign equipment to employees](../help/FR-004-equipment-assignment.md)
- Feature article: [Return equipment](../help/FR-005-equipment-unassignment.md)
- Feature article: [Assignment history](../help/FR-006-assignment-history-tracking.md)
- Feature article: [Find actions and see assignment details](../help/NFR-003-usability.md)
- Feature article: [Register and assign equipment](../help/FR-001-equipment-registration.md)

---
Previous: [Equipment register](equipment-register.md) | Next: [Equipment requests](equipment-requests.md)
