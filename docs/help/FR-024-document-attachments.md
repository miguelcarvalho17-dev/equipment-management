# Equipment attachments (AppSource end-user help)

You can attach any number of files to a piece of equipment, for example the purchase invoice, a maintenance report, a warranty certificate, a user manual or a delivery note. The files are listed in the **Attachments** FactBox on the **Equipment Card**.

## Before you start: permissions
- **Equipment Reader**: can see the attached files and open them. Cannot add, change or delete files.
- **Equipment Manager** and **Administrator**: can also add files, set their category and delete them.

TODO(verify): permissions were not checked in a sandbox.

## What you can do
| Where | What it does |
|---|---|
| **Attachments** FactBox | Lists the files attached to the equipment. |
| **Attachments** action on the card | Opens the list of attached files, where you add files, set the **Category** and delete files. Available once the equipment is saved. |

## Attach a file
1. Open the equipment and save it first. On a new, unsaved equipment the **Attachments** action is disabled.
2. Choose **Attachments**.
3. In the list that opens, add a file (use the attach or upload action of the page).
4. Set the **Category** of the file: Purchase Invoice, Maintenance Report, Warranty Certificate, User Manual, Delivery Note or Other.
5. Close the list. The FactBox shows the files.

TODO(verify): the exact names of the upload actions on the standard attachment page were not checked in a sandbox.

## Good to know
- The **Category** column appears only for equipment attachments. New files start with **Other**.
- Equipment with any status, including Lost and Disposed, can have attachments.
- If you rename the equipment number, the attachments follow the equipment.
- If you delete equipment, its attachments are deleted with it. Equipment that is assigned, has assignment history or has maintenance records cannot be deleted, and then the attachments stay.
- The **Attachments** FactBox is on the Equipment Card only, not on the Equipment List.

For the standard attachment functions, see the Microsoft Learn documentation for attaching documents to records in Business Central.

## Release notes
Equipment attachments: you can now attach files such as invoices, maintenance reports, warranty certificates, user manuals and delivery notes to a piece of equipment. The files appear in the Attachments FactBox on the Equipment Card. Choose Attachments to add files and set a category for each one. Attachments follow the equipment when you rename it and are deleted when you delete it.
