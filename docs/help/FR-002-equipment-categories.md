# Manage equipment categories (AppSource end-user help)

Categories group your equipment (for example Laptop or Printer). You can retire a category without touching the equipment that uses it.

## Before you start: permissions
Maintaining categories needs the **Equipment Administrator** permission set. Users with **Equipment Manager** or **Equipment Reader** can see categories and choose one on equipment, but cannot add, change or delete them; the page opens read-only for them.

## Add a category
1. Search for **Equipment Categories** and open the page.
2. On a new line, enter a **Code** and a **Description**. **Active** is selected for you.
Codes must be unique. Codes are upper case, so `laptop` and `LAPTOP` are the same code.
New companies start with: Laptop, Monitor, Mobile Phone, Tablet, Printer, Vehicle and Tool.

## Retire a category
1. On **Equipment Categories**, clear **Active** for the category.
Equipment that already uses it keeps it and can still be edited, assigned and deleted. The category no longer appears in the **Category Code** lookup, and nobody can newly choose it.
To bring it back, select **Active** again.

## Choose a category on equipment
On the equipment card, **Category Code** lists active categories only. If you type an inactive code you get an error; choose an active category or ask an administrator to activate it. If you type a code that does not exist, you are told to choose one from the Equipment Categories page.
If a category was retired after you chose it, you can still save other changes to the equipment. Once you change to another category, you cannot change back to the retired one.

## Delete or rename a category
- A category that equipment uses cannot be deleted. Clear **Active** instead.
- A retired category that equipment uses cannot be renamed. Select **Active**, rename the category, then clear **Active** again.

## Related
- Equipment Categories, Equipment Card
- To see the equipment of a category, select it and choose **Equipment**: see docs/help/FR-007-equipment-list-management.md
