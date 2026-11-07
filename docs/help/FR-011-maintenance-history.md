# Maintenance history (AppSource end-user help)

Post a maintenance record when it is final. Posting locks the record and adds it to the maintenance history of the equipment, a permanent list that nobody can change or delete.

## Before you start: permissions
- **Equipment Reader** can view the maintenance history.
- **Equipment Manager** (and Administrator) can post maintenance records.
- Existing maintenance records start as **Open**, so you can post them.

## Post a maintenance record
1. Open the record from **Equipment Maintenance**, or open the list.
2. Check the details. You can still correct an **Open** record.
3. Choose **Post** (or press F9) and confirm. On the card, your changes are saved first.

After posting:
- **Status** shows **Posted** and the record can no longer be changed. Nobody can delete it.
- A history entry is created with the date, type, vendor, cost, description, who did the work, who posted it and when.
- The vendor number and name are saved as they were when you posted. A later vendor change does not alter the history.

Good to know:
- There is no way to undo posting. If a posted record is wrong, register a new maintenance record that describes the correction.
- Posting works for equipment that is **Lost** or **Disposed**. Posting does not change the status of Lost or Disposed equipment. For equipment that is **In Maintenance**, posting the last open maintenance record sets it to **Available**.
- If posting fails, for example because the date is later than today, nothing is posted and the record stays **Open**.
- On the list, **Post** works on the selected row only.

## See the history
- **Equipment Card:** the **Maintenance History** section lists the posted maintenance of that equipment, newest date first. Open records are not shown there. Choose **Show Maintenance Record** to open the record behind a row.
- **Maintenance History** list: search for **Maintenance History**, or choose **Maintenance History** in the Equipment Card (Related). It shows every posted maintenance. Use the views at the top (Preventive, Corrective, Inspection, Upgrade) to show one type. Choose **Equipment** or **Maintenance Record** to open those cards.
- **Equipment Maintenance** list: the new **Status** column shows Open or Posted. Use the views **Open** and **Posted** to filter. On a posted row, choose **History Entry** to see its entry.
- The **Maintenance** FactBox counts both open and posted records. Its **Total Maintenance Cost** counts posted maintenance only (changed in the maintenance cost update), so it can be lower than the sum in the Equipment Maintenance list.

## Release notes
Maintenance records now have a status. Choose Post (F9) when a record is final: it is locked and copied to a read-only maintenance history that cannot be changed or deleted. The history is shown on the Equipment Card and in a new Maintenance History list, with date, type, vendor, cost and description. The Equipment Maintenance list has a Status column and views for open and posted records.
