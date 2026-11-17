# Equipment Summary, Equipment Statistics and Attachment Summary (AppSource end-user help)

The Equipment Card shows three more FactBoxes on the right side, directly after the picture: **Equipment Summary**, **Equipment Statistics** and **Attachment Summary**. They are read-only. Change the equipment on the card itself.

TODO(verify): this feature has not been tested in a sandbox. Names and layout may differ slightly from the steps below.

## Equipment Summary
- **Status**: the current status of the equipment, in the same colors as on the card.
- **Assigned Employee No.**: the employee the equipment is assigned to. Choose the number to open the employee card. Nothing happens when the equipment is not assigned or you cannot see employees.
- **Assigned Employee Name**: the full name of that employee. It is blank when the equipment is not assigned.
- **Warranty Status**: one of these values:
  - **Active**: the warranty ends more than 30 days from today.
  - **Expiring Soon**: the warranty ends within 30 days.
  - **Expired**: the warranty end date has passed.
  - Blank: no warranty end date is filled in.

## Equipment Statistics
- **Assignment Count**: how many times the equipment has been assigned, including the current assignment. Choose the number to see the assignments of this equipment.
- **Maintenance Count**: how many maintenance records of this equipment have been posted. Choose the number to see the maintenance history.
- **Total Maintenance Cost**: the total cost of the posted maintenance records. Choose the amount to see the maintenance history.

Open maintenance records are not counted until they are posted. To see open records, use the Maintenance FactBox.

## Attachment Summary
- **Document Count**: the number of files attached to the equipment that are not images, such as PDF, Word or Excel files.
- **Image Count**: the number of files attached to the equipment that are images, such as JPG or PNG files. The equipment picture is not counted. It is shown in the Picture FactBox.

Images and documents are counted as recognized by Business Central. A file that Business Central does not recognize as an image is counted as a document.

Choose either number to open the attachments of the equipment. The numbers update when you close the attachments page.

## Good to know
- The numbers show only the equipment on the card. Other equipment and other records are not counted.
- On a new card that you have not saved yet, the numbers show 0 and the fields are blank.
- If you cannot see attachments, the attachment numbers show 0.
- The statistics are for all time. They do not follow a date filter.

## Release notes
Equipment Summary, Equipment Statistics and Attachment Summary are three new FactBoxes on the Equipment Card. Equipment Summary shows the status, the assigned employee and the warranty status. Equipment Statistics shows how often the equipment was assigned, how many maintenance records were posted and their total cost. Attachment Summary counts the attached documents and images. Choose a number to open the matching list.
