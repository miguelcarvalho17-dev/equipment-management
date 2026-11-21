# Equipment Operator: the permission set for day-to-day equipment work (AppSource end-user help)

Equipment Management has an **Equipment Operator** permission set. Use it for people who assign equipment, register and post maintenance and follow up warranty alerts, but who do not create equipment, manage the register or handle requests. TODO(verify): this role has not been tested in a sandbox; the limits below are from the permission design and may differ in practice.

## Which role for whom
| Permission set | Give it to | What it allows |
|---|---|---|
| Equipment Reader | People who only need to look things up | View equipment, categories, assignments, maintenance, warranty alerts, notes, requests, audit trail and setup. Change nothing |
| Equipment Operator | People who do the daily equipment work | Everything a Reader can, plus assign and return equipment, register and post maintenance, add notes, acknowledge and generate warranty alerts, and change existing equipment (see the limits below) |
| Equipment Manager | People who manage the register | Everything an Operator can, plus create equipment, work with requests and attachments. Cannot delete equipment and cannot change categories or setup |
| Equipment Administrator | The person responsible for the app | Everything a Manager can, plus delete equipment, manage categories and setup, the error log and demo data |

Assign the set that fits the job. Operator, Manager and Administrator each include the Reader permissions, so a person does not need Reader as well. Manager does not include Operator: a Manager can do everything an Operator can, so assign Operator only to people who should not have Manager rights.

All roles also need the Business Central permission set **D365 BASIC**. It gives read access to employees, locations and number series that the app uses. Without it, employee names are blank and maintenance numbers may not be assigned (TODO(verify)).

For how to assign a set to a user, see `docs/help/FR-036-permission-sets.md`.

## What an Equipment Operator cannot do
- Create new equipment.
- Delete equipment or any other record of the app.
- Change categories or the equipment setup.
- Create, send, approve or reject equipment requests.
- Upload, change or delete attachments on equipment.
- Open the Equipment Error Log, or read entries in it.

## Known limits
- **Changing existing equipment.** An Operator can change the fields on the equipment card and in the list. This includes the status (for example Lost or Disposed) and the equipment name.
- **Renaming equipment with attachments.** Renaming equipment that has attachments fails with a permission error, and nothing changes. TODO(verify).
- **Pictures.** An Operator may not be able to change the equipment picture. TODO(verify).
- **Reading.** An Operator can read the audit trail and integration event entries, which show user IDs, as a Reader can. Attachments can be opened, but not changed.

## Good to know
- A user without a role gets a permission error when they open Equipment pages.
- Manager covers everything an Operator can do, so give Manager to people who need to create equipment.

## Release notes
Equipment Management has a new **Equipment Operator** permission set. It is for people who assign equipment, register and post maintenance and follow up warranty alerts without creating equipment or managing the register. Existing permission sets (Reader, Manager, Administrator and API Consumer) are unchanged. Assign D365 BASIC together with the set.
