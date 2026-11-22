# Equipment register

This article explains how to create equipment, use the equipment card, change the status and find equipment in the list. It is for everyone who works with the register.

**In this article**
- [Create equipment](#create-equipment)
- [The equipment card](#the-equipment-card)
- [Change the status](#change-the-status)
- [Find and filter equipment](#find-and-filter-equipment)
- [Picture](#picture)
- [Notes](#notes)
- [Attachments](#attachments)
- [FactBoxes on the card](#factboxes-on-the-card)
- [Delete equipment](#delete-equipment)

## Create equipment

Creating equipment needs the Equipment Manager or Equipment Administrator permission set.

1. Choose the search icon, enter **Equipment**, and choose the related link.
2. Choose **New**. The **No.** is filled in from the number series.
3. To use another number series, choose the AssistEdit button on **No.** before you enter anything else.
4. In **Category Code**, choose a category. The category is required, and only active categories are offered.
5. Fill in **Description**, **Serial No.**, **Manufacturer**, **Model**, **Location Code**, **Purchase Date** and **Purchase Cost** as needed.

The equipment is saved when the category is filled in. New equipment starts as Available or In Maintenance. A serial number can be used by one equipment record only.

## The equipment card

The card shows everything about one piece of equipment. To open it, select the equipment in the list.

### General

| Field | Description |
|---|---|
| **No.** | The number of the equipment. |
| **Description** | A description of the equipment. |
| **Category Code** | The category of the equipment. Only active categories can be selected. |
| **Serial No.** | The serial number of the equipment. A serial number can be used by one equipment record only. |
| **Manufacturer** | The manufacturer of the equipment. |
| **Model** | The model of the equipment. |

### Assignment

| Field | Description |
|---|---|
| **Status** | The lifecycle status of the equipment: Available, Assigned, In Maintenance, Lost or Disposed. Only saved, available equipment without open maintenance can be assigned; use the Assign to Employee action. Assigned equipment becomes available only through the Return action. Registering maintenance sets the status to In Maintenance, and posting the last open maintenance record sets it back to Available. Lost and Disposed are final statuses: the equipment cannot be assigned or change status again. New equipment cannot start as Assigned, Lost or Disposed. |
| **Assigned Employee No.** | The employee the equipment is assigned to. To assign available equipment, use the Assign to Employee action. To change the employee, return the equipment first. |
| **Assigned Employee Name** | The name of the employee the equipment is assigned to. |
| **Assigned Since** | The date the equipment was assigned to the current employee. It is blank when the equipment is not assigned. |
| **Assigned By** | The user who assigned the equipment to the current employee. It is blank when the equipment is not assigned. |
| **Location Code** | The location where the equipment is kept. |

### Purchase

| Field | Description |
|---|---|
| **Purchase Date** | The date the equipment was purchased. |
| **Purchase Cost** | The purchase cost of the equipment. |

### Warranty

| Field | Description |
|---|---|
| **Warranty Start Date** | The date the warranty of the equipment starts. Leave it blank when the equipment has no warranty or the start date is not known. |
| **Warranty End Date** | The date the warranty of the equipment ends. When both warranty dates are filled in, the end date must be later than the start date. The warranty status is calculated from this date: Expiring Soon from 30 days before the end date, and Expired after it. Leave it blank when the equipment has no warranty or the end date is not known. |
| **Warranty Status** | Whether the warranty is Active, Expiring Soon (it ends within 30 days) or Expired (the end date has passed). It is calculated from the warranty end date and today's date, and is blank when no warranty end date is filled in. |
| **Warranty Provider** | The company that provides the warranty, for example the manufacturer, the vendor or a service company. |
| **Warranty Reference No.** | The reference of the warranty, such as the contract, certificate or registration number from the warranty provider. |

### Planned Maintenance

This FastTab is shown only when the Maintenance Planning feature is on.

| Field | Description |
|---|---|
| **Last Maintenance Date** | The date the equipment was last maintained according to its maintenance plan. Posting a preventive maintenance record with a later date updates it automatically. The date cannot be later than today. The next maintenance date is calculated from this date and the maintenance frequency. |
| **Maintenance Frequency (Months)** | How often the equipment must be maintained, in months, for example 6 for every six months. Leave it blank when the equipment has no planned maintenance. The next maintenance date is calculated from the last maintenance date and this frequency. |
| **Next Maintenance Date** | When the next planned maintenance of the equipment is due. It is calculated as the last maintenance date plus the maintenance frequency in months, and is blank when either is missing. When the date is before today, the maintenance is overdue and the date is highlighted, unless the equipment is lost or disposed. |

### Assignment History, Maintenance History and Equipment Notes

These three sections list the assignments of the equipment, its posted maintenance and its notes, newest first. You cannot edit the assignment history or the maintenance history here. The current assignment is shown in green.

### Audit

| Field | Description |
|---|---|
| **Created Date** | When the equipment record was created. |
| **Created By** | The user who created the equipment record. |
| **Last Modified Date** | When the equipment record was last modified. |
| **Last Modified By** | The user who last changed the equipment record. |

Created By and Last Modified By are blank for users who cannot read the list of users.

### Actions on the card

| Action | Description |
|---|---|
| **Assign to Employee** | Assign available equipment to an active employee that you select. The assignment is recorded with the work date and your user name. Not available while the equipment has open maintenance. |
| **Return** | Return the equipment from the assigned employee. The status changes to Available and the assignment is closed with the work date and your user name. The assignment stays in the history. |
| **Register Maintenance** | Register maintenance for the equipment. The equipment status changes to In Maintenance, and the equipment cannot be assigned until the maintenance record is posted. Not available for lost or disposed equipment. |
| **Assignments** | View the assignment history of the equipment. Shortcut: Ctrl+F7. |
| **Audit Trail** | View the lifecycle timeline of the equipment: when it was created, changed, assigned, returned, sent to maintenance or disposed. |
| **Maintenance** | View the maintenance records of the equipment. |
| **Maintenance History** | View the posted maintenance history of the equipment. |
| **Equipment Notes** | View all notes recorded for the equipment. |
| **Attachments** | Add a file, such as an invoice, manual or warranty certificate, to the equipment, or view and categorize the attached files. |
| **Warranty Alerts** | View the warranty alerts of the equipment. An alert is created 90, 60 and 30 days before the warranty ends. Shown when the Warranty Alerts feature is on. |

The navigation actions are available once the equipment is saved.

## Change the status

Every piece of equipment has one status.

| Status | Meaning |
|---|---|
| Available | In stock, not assigned to anyone. |
| Assigned | Assigned to an employee. |
| In Maintenance | Being serviced. It cannot be assigned. It is set when you register maintenance. |
| Disposed | Permanently removed from use. |
| Lost | Permanently lost. |

1. Open the equipment card.
2. Choose a new value in **Status**.

The rules:

- To assign equipment, use **Assign to Employee**. To make assigned equipment available, use **Return**.
- Equipment with an open maintenance record cannot be set to Available or Assigned. Post the record, and the status changes to Available by itself.
- Disposed and Lost are final. When you choose one of them, you are asked to confirm. If an employee is assigned, the question names the employee, and the employee is removed from the equipment.
- Once saved as Disposed or Lost, the status cannot be changed again, and the equipment cannot be assigned. You can still edit the other fields.
- New equipment cannot start as Assigned, Lost or Disposed. Create the equipment first, and then change it.

## Find and filter equipment

1. Choose the search icon, enter **Equipment**, and choose the related link.
2. To search, choose **Search** and type part of the equipment number or serial number. The search uses the columns that you can see.
3. To filter, open the filter pane and add a filter on **Category Code**, **Status** or **Assigned Employee No.** You can combine filters.
4. To see one status, choose a view at the top of the list: Available, Assigned, In Maintenance, Lost or Disposed.

The list can also show the total maintenance cost, the number of posted maintenances, the average cost and the cost as a percentage of the purchase cost. Some columns are hidden by default. Show them through personalization.

To open the equipment of one category, select the category on **Equipment Categories** and choose **Equipment**.

You cannot filter or search on the assigned employee name. Filter on **Assigned Employee No.** instead.

## Picture

Each piece of equipment can have one picture, shown in the **Picture** FactBox. The FactBox is shown when the Equipment Images feature is on.

1. Open the equipment and save it first.
2. In the **Picture** FactBox, choose **Import**, or **Take** if your device has a camera.
3. If the equipment already has a picture, confirm that it is replaced.
4. Select the file. Supported files are JPG, JPEG, PNG, GIF, BMP, TIF and TIFF.

Choose **Export** to download the picture, and **Delete** to remove it. TODO(verify): that Export works for an Equipment Reader, and the FactBox layout, the tile view and the Take action on a mobile device, are not checked in a sandbox.

## Notes

Notes are short, dated comments on a piece of equipment. Each note shows when it was written, who wrote it and the text.

1. Open the equipment and save it first.
2. In **Equipment Notes**, go to the empty line at the end of the list and type the text in **Comment**. The maximum is 250 characters.
3. Move to another line or field to save the note.

Notes cannot be changed or deleted. To correct a note, add a new one. TODO(verify): where the empty line appears and when the note is saved are not checked in a sandbox.

The standard **Notes** FactBox is separate. It is a free notepad that can be edited and deleted.

## Attachments

You can attach any number of files, such as a purchase invoice, a maintenance report, a warranty certificate, a user manual or a delivery note.

1. Open the equipment and save it first.
2. Choose **Attachments**.
3. In the list that opens, add a file.
4. Set the **Category** of the file: Purchase Invoice, Maintenance Report, Warranty Certificate, User Manual, Delivery Note or Other. New files start with Other.
5. Close the list. The **Attachments** FactBox shows the files.

TODO(verify): the names of the upload actions on the standard attachment page are not checked in a sandbox. For the standard functions, see the Business Central documentation on attaching documents to records.

## FactBoxes on the card

| FactBox | What it shows |
|---|---|
| **Picture** | The picture of the equipment, with the actions to take, import, export and delete it. |
| **Equipment Summary** | The status, the assigned employee and the warranty status. |
| **Equipment Statistics** | How many times the equipment was assigned, how many maintenance records were posted, and their total cost. |
| **Attachment Summary** | The number of attached documents and the number of attached images. The equipment picture is not counted. |
| **Attachments** | The files attached to the equipment. |
| **Assignment Details** | The employee, since when, and how often the equipment was assigned. |
| **Maintenance** | The number of maintenance records, the number of open records, the latest record, the next maintenance date and the cost. |

The numbers in the Equipment Statistics and Attachment Summary FactBoxes open the matching list when you choose them.

## Delete equipment

Deleting equipment needs the Equipment Administrator permission set. You can delete equipment only when it:

- is not assigned,
- was never assigned, so it has no assignment history,
- has no maintenance records, and
- has no notes.

For all other equipment, set the status to **Disposed**. Attachments are deleted with the equipment. A category that equipment uses cannot be deleted.

## What to know

- Equipment can have one picture only.
- Employee names in the list need the D365 BASIC permission set. Without it, the name column is blank.
- Pages do not refresh by themselves. Refresh the card to see a new status.
- Tools that skip checks, such as some data migration tools, bypass these rules.

## Related

- [Assignments](assignments.md)
- [Maintenance](maintenance.md)
- [Warranty](warranty.md)
- Feature article: [Register and assign equipment](../help/FR-001-equipment-registration.md)
- Feature article: [Manage equipment categories](../help/FR-002-equipment-categories.md)
- Feature article: [Manage equipment status](../help/FR-003-equipment-status-management.md)
- Feature article: [Find and filter equipment](../help/FR-007-equipment-list-management.md)
- Feature article: [Equipment card](../help/FR-008-equipment-card.md)
- Feature article: [Equipment pictures](../help/FR-023-equipment-images.md)
- Feature article: [Equipment attachments](../help/FR-024-document-attachments.md)
- Feature article: [Equipment notes](../help/FR-025-equipment-notes.md)
- Feature article: [Equipment Summary, Equipment Statistics and Attachment Summary](../help/FR-037-factboxes.md)
- Feature article: [Find actions and see assignment details](../help/NFR-003-usability.md)
- Feature article: [Large registers: speed and filters](../help/FR-053-large-dataset-support.md)

---
Previous: [Setup and configuration](setup-and-configuration.md) | Next: [Assignments](assignments.md)
