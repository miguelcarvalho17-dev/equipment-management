# Maintenance log (AppSource end-user help)

Equipment Management keeps a permanent log of what happens to every maintenance record: who registered it, who changed it, who posted it, and when. For each changed field it shows the old and the new value. Nobody can change or delete log entries, and maintenance records themselves can never be deleted.

## What is logged
- **Registered:** a maintenance record was created.
- **Changed:** a field of an open record was corrected. One entry per field. Logged fields are Maintenance Date, Maintenance Type, Vendor No., Cost, Description and Performed By.
- **Posted:** the record was posted and locked.

Nothing is logged for a change that leaves these fields as they were.

## Open the log
1. Open **Equipment Maintenance** and select a record, or open the **Maintenance Record** card.
2. Choose **Log Entries** (also under Navigate). The list shows only the entries of that record, newest first.
3. To see all entries, search for **Maintenance Log Entries**.

## Read the list
- **Logged At** and **User ID**: when and by whom.
- **Action**: Registered, Changed or Posted.
- **Field Caption**, **Old Value**, **New Value**: for Changed entries, what was changed. Values are shown in a fixed technical format (for example dates as year-month-day), not in your regional format.

## Good to know
- Everyone with the EQM - Reader permission set or higher can read the log. It cannot be edited by any role.
- You cannot switch the log off, and you do not need to set anything up.
- Maintenance records created before this version have no Registered entry.
- Changes to the planned-maintenance dates and frequency on the equipment card are not part of this log.
- If you opened a record by mistake, you still cannot delete it: post it with cost 0 and a describing text. The log shows both.
- Business Central's own Change Log is separate. You can still turn it on for additional tracking.
- TODO(verify): the field name column and the Maintenance Type values were not checked in a sandbox.

## Release notes
Maintenance log: every maintenance record now has a permanent, read-only log of who registered, changed and posted it, and when, with the old and new value of each corrected field. Choose Log Entries on Equipment Maintenance or on the Maintenance Record card. Log entries cannot be changed or deleted.
