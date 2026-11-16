# Tracking Equipment Changes with the Change Log (AppSource end-user help)

Equipment Management prepares the standard Business Central Change Log to record changes to your equipment: who changed what, when, and the old and new value. TODO(verify): this feature has not been tested in a sandbox; screen layout may differ slightly from the steps below.

## What is tracked
Changes to these fields on an equipment record are recorded:
- **Category Code**
- **Status**
- **Assigned Employee No.** (assigning and returning equipment)
- **Warranty Start Date**, **Warranty End Date**, **Warranty Provider** and **Warranty Reference No.**

Only changes are recorded, not the creation or deletion of equipment. Changes to other fields (for example Description or Location Code) are not recorded. The warranty status (Active, Expiring Soon, Expired) is calculated from the end date and today, so it is not recorded; a change to the end date is.

Equipment categories and the assignment history are not tracked. Every assignment entry already shows who and when, and the assignment itself is recorded through the equipment's Assigned Employee No.

## Turn the Change Log on
The tracking rules are added when the app is installed, but they do nothing until the Change Log is on. This is a company-wide setting for all tables, so it is left to an administrator.
1. Search for **Change Log Setup** and open it.
2. Turn on **Change Log Activated**.
3. Users must sign in again for the change to take effect.

To check or adjust which fields are tracked, open **Change Log Setup** and look at the tables list (table **EQM Equipment**) and its fields. Your own settings are never overwritten by the app. If you delete the rules on purpose, the app does not add them back.

## See the recorded changes
1. Search for **Change Log Entries** and open it.
2. Filter on **Table No.** = the equipment table, or on the equipment number in **Primary Key**.
3. Each entry shows date and time, user, field, old value and new value.

## Good to know
- Companies created after the app was installed may not have the tracking rules. Add table **EQM Equipment** and its fields on the **Change Log Setup** page.
- Entries contain user IDs and values. How long they are kept is governed by your Change Log retention policy.
- The Maintenance Log (see the help for maintenance logging) is separate and always on.
- TODO(verify): the entries per field and the first-use behavior after turning the Change Log on were not checked in a sandbox.

## Release notes
Change Log support: the app now registers equipment category, status, assigned employee and warranty fields (start date, end date, provider, reference number) in the standard Business Central Change Log. An administrator turns on Change Log Activated in Change Log Setup; the app never switches it on. Only changes are recorded.
