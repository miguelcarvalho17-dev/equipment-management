# Register and assign equipment (AppSource end-user help)

Use equipment records to keep track of devices and tools and who has them.

## Before you start: permissions
- Assign one EQM permission set: **Equipment Reader** (view), **Equipment Manager** (create and change equipment, assign and return) or **Equipment Administrator** (also delete equipment and change setup and categories). See the roles help article.
- Users also need the standard **D365 BASIC** permission set. The Equipment sets do not give access to employees, locations or number series.

## Set up numbering
1. Choose the search icon, enter **Equipment Setup**, and open the page.
2. In **Equipment Nos.**, choose the number series for new equipment. The first time the page is opened in a company, the series EQUIP is filled in for you.
Until a series is set, you cannot create equipment with an automatic number.

## Categories
1. Search for **Equipment Categories** and open the page.
2. Enter a **Code** and **Description** on a new line. Starter categories (Laptop, Monitor, Phone, Vehicle, Tool) are already there.
A category that is used by equipment cannot be deleted.

## Create equipment
1. Search for **Equipment** and open the list, then choose **New**.
2. The **No.** is filled in automatically. To use a different series, choose the AssistEdit button on **No.** before you enter anything else.
3. Fill in **Category Code** (required). Add **Description**, **Serial No.**, **Manufacturer**, **Model**, **Location Code**, **Purchase Date** and **Purchase Cost** as needed.
The equipment is saved when the category is filled in; closing the card without a category shows an error and nothing is saved.
**Serial No.** can be used by one equipment record only. **Status** starts as Available.

## Assign equipment to an employee
1. Open the equipment card.
2. Choose **Assign to Employee** and select an employee. Only active employees who are not blocked for privacy reasons are listed.
Status becomes Assigned and the employee's name is shown. You can use the same action to give the equipment to someone else.
The **Assigned Employee No.** field is editable only while the status is Assigned, and must be filled in then.

## Return equipment
1. Open the equipment card and choose **Return**. Assigned equipment becomes Available only through Return.
2. Confirm the question. The employee is removed and the status becomes Available.
If you change **Status** from Assigned to Available or In Maintenance while an employee is set, you get the same question. Choose No to keep the status and the employee.
If you change it to Lost or Disposed, you get a different question, because those statuses are final; see the equipment status help.

## Delete equipment
Select the equipment and delete it. You can delete equipment only if it was never assigned to an employee. Equipment that is assigned, or that has assignment history, is refused with a message. To stop using equipment that has history, set its status to **Disposed**. See the assignment history help.
Where no screen is shown (for example automated integrations), these questions are answered Yes automatically.

## Employees with equipment
You cannot delete an employee while equipment is assigned to that employee. Return the equipment first.
Deleting through methods that skip triggers, such as some data migration tools, bypasses this check.
If an assigned employee no longer exists, use **Return** and assign someone else.

## Related
- Equipment List, Equipment Card, Equipment Categories, Equipment Setup
- Searching and filtering the list: see docs/help/FR-007-equipment-list-management.md
- Employees
