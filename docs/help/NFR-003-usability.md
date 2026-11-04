# Find actions and see assignment details (AppSource end-user help)

The equipment pages now group their actions the same way as other Business Central pages and show who has the equipment in a side pane.

## Before you start: permissions
Everyone with **Equipment Reader**, **Equipment Manager** or **Equipment Administrator** can see the details. Employee details (name, job title, email) need the standard **D365 BASIC** permission set; without it they are blank.

## Where the actions are
**Equipment list**
- **Equipment > Assignments**: assignment history of the selected equipment. Shortcut: **Ctrl+F7**.
- **Related > Setup > Categories** and **Equipment Setup**.
- **Reports > Dashboard**: the equipment dashboard.

**Equipment card**
- **Process**: **Assign to Employee** and **Return**.
- **Equipment > Assignments**: assignment history. Shortcut: **Ctrl+F7**. Available once the card is saved.
- The collapsed **General** FastTab shows Description and Category Code; the collapsed **Assignment** FastTab shows Status and the employee name.

**Employee card**
- **Related > Equipment > Equipment Assignments** (history) and **Assigned Equipment** (current equipment).
- **Return Equipment** stays under the process actions.

## Assignment Details FactBox
On the equipment list and card, the **Assignment Details** pane shows, for the selected equipment:
- **Status**, **Assigned Employee No.** (choose it to open the employee card), **Employee Name**, **Job Title** and **Company Email**.
- **Assigned Since** and **Assigned By**: when and by whom the current assignment was made. Blank when the equipment is not assigned.
- **No. of Assignments**: how many times the equipment was assigned, including now. Choose the number to open the history.
- **Last Assignment Closed**: date the most recent assignment ended. Blank when none has ended.

If the pane is hidden, choose the FactBox icon in the page header.

## Assigned Equipment FactBox on the employee card
The **Assigned Equipment** pane lists the equipment currently assigned to the employee. Choose a number to open the equipment card. It is shown only to users who can read equipment.

## Notes and Links
The equipment list and card have **Notes** in the FactBox pane: add a note to any equipment. **Links** is hidden by default; turn it on through **Personalize**. Notes are stored by Business Central and can contain personal data you type, so do not enter more than needed.

## Search words
In Tell Me, **Equipment Assignments** is listed under History. You can also find pages with: **devices**, **tools**, **hardware**, **company equipment** (Equipment); **equipment types** (Equipment Categories); **equipment number series** (Equipment Setup); **equipment loans**, **issued equipment** (Equipment Assignments). Equipment Categories and Equipment Assignments show a short tip the first time you open them.

## Release notes
Equipment actions are now grouped like other Business Central pages: Assignments under Equipment (Ctrl+F7), Categories and Setup under Related, Dashboard under Reports. New FactBoxes show who has the equipment, since when and how often it was assigned, and the equipment assigned to an employee on the Employee Card. Equipment pages also have Notes and Links. The Equipment Manager home page no longer lists Categories twice.
