# Create and delete demo data (Equipment Management)

Demo data gives a new company sample employees, equipment, assignments and maintenance records. Use it to try out Equipment Management before you enter your own data. You can delete it again when you are done.

## Who can use it
You need two kinds of permission:
- The **EQM - Administrator** permission set for Equipment Management.
- Permission to **edit employees** in Business Central. Without it, the actions show an error and nothing is changed. Ask your administrator to give you a permission set that lets you insert and delete employees.

Users with only the **EQM - Manager** permission set see the actions, but they cannot run them.

## Create demo data
1. Open **Equipment Setup**.
2. In the **Processing** area, choose **Create Demo Data**.
3. Read the question. It names the company where the demo data is created. The default answer is **No**. Choose **Yes** to continue.
4. A notification shows how many employees, equipment, assignments and maintenance records were created.

The demo data includes:
- 8 employees. Their names start with `EQMDEMO-E`, and their last name is "Demo".
- 15 equipment records across the seven default categories. Their numbers start with `EQMDEMO-`.
- Current and past assignments of the equipment to the employees.
- 12 maintenance records. Some are completed and some are open. Two open records are overdue.
- Warranties that are expired, expiring soon, active or blank.

Dates are relative to today, so the demo always shows warranties and overdue maintenance.

### Running Create again
If you run **Create Demo Data** again, it adds only what is missing. It does not change records that already exist. If the demo data is already there, nothing is created.

The demo skips an item when:
- its number is already used by a record that you created,
- its category is missing or not active, or
- for equipment, its serial number is already used. The equipment is then created without a serial number.

The notification shows how many items were skipped.

## Delete demo data
1. Open **Equipment Setup**.
2. In the **Processing** area, choose **Delete Demo Data**.
3. Read the question. The default answer is **No**. Choose **Yes** to continue.
4. A notification shows how many equipment records and employees were deleted, and how many were kept.

If there is no demo data in the company, the action shows a message and asks nothing.

### What is deleted
The action deletes only the records that **Create Demo Data** added. It deletes them with their history:
- the assignments, maintenance records, maintenance history, maintenance log, audit entries and warranty alerts of the demo equipment,
- the demo equipment, and then the demo employees.

Records that you created are not deleted. Demo records that you renamed or edited are still deleted.

### What is kept, and why
The action keeps demo data that you changed in a way that matters to you. A kept record is still counted in the notification.

**Equipment is kept when you added any of these to it:**
- a picture,
- a note,
- an attachment,
- an equipment request,
- a maintenance record that you created, or
- an assignment to an employee that you created.

**An employee is kept when any of these still refers to it:**
- equipment that is assigned to the employee,
- any assignment entry for the employee,
- an equipment request for the employee, or
- an attachment on the employee.

Keeping these records protects your work. You can delete the kept records yourself, and then run **Delete Demo Data** again.

## Side effects that cannot be undone
Demo data uses the same logic as your own work. Some effects happen outside the demo and are not reversed by **Delete Demo Data**:
- **Power Automate flows:** the "Equipment Assigned" events run for each active assignment that the demo creates. Flows that listen to these events run.
- **Warranty alerts:** the daily job can create warranty alerts for the demo equipment after you create it. Deleting the equipment removes them.
- **Change Log:** if the Change Log is set up, the changes are logged.
- **Telemetry:** if telemetry is on, the usage signals for the demo actions are sent, as for your own work. See the help on application telemetry.

If you want the demo data to stay out of your reports or integrations, delete it before you connect those tools, or ask your administrator to review the flows.

## Tips
- Run **Delete Demo Data** before you start to use the company for real work.
- If you add your own data to demo records, **Delete Demo Data** keeps those records. Delete your own data first if you want the demo removed.
- Demo names and numbers are fixed. The maintenance descriptions and the "Performed By" text follow your language.
