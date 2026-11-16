# Following the Life of Equipment with the Audit Trail (AppSource end-user help)

The Equipment Audit Trail is a read-only timeline for each piece of equipment: when it was created, changed, assigned, returned, sent to maintenance or disposed, who did it, and the status afterwards. It is always on and needs no setup. TODO(verify): this feature has not been tested in a sandbox; screen layout may differ slightly from the steps below.

## What is recorded
| Event Type | When |
|---|---|
| Created | New equipment is created |
| Updated | Equipment details are saved with a change (see below) |
| Assigned | Equipment is assigned to an employee |
| Returned | Equipment is returned from an employee |
| Sent to Maintenance | The status changes to In Maintenance, for example when you register maintenance |
| Disposed | The status changes to Disposed |

When assigned equipment is sent to maintenance or disposed, it is returned first, so **Returned** appears before **Sent to Maintenance** or **Disposed**.

## Open the audit trail
1. Open the equipment card and choose **Audit Trail** (available once the equipment is saved). The list shows only this equipment.
2. To see all equipment, search for **Equipment Audit Trail**.

The newest entry is at the top. Columns:
- **Logged At** and **User ID**: when the event happened and who caused it.
- **Event Type** and **Status After**: what happened and the equipment status after it.
- **Employee No.**: the employee, for Assigned and Returned.
- **Assignment Entry No.**: the matching line on Equipment Assignments, for Assigned and Returned.
- **Maintenance No.**: the maintenance record that sent the equipment to maintenance. It is blank when someone changed the status by hand.

Entries cannot be changed or deleted.

## About Updated entries
- An **Updated** entry says that equipment details were saved with a change. It does not show which field or the values. These details count: description, category, serial number, manufacturer, model, purchase date and cost, location, the warranty fields, last maintenance date and maintenance frequency.
- Changing the status to **Lost**, or from **In Maintenance** back to **Available**, also gives an Updated entry, with the new status in **Status After**.
- The equipment card saves each field you edit separately, so editing five fields gives five Updated entries.
- To see old and new values, use the standard Business Central **Change Log**. An administrator must switch it on; see the help for Change Log support.

## Good to know
- Equipment created before this feature was installed has no **Created** entry.
- Deleting equipment does not delete its audit entries; they stay in the list.
- Entries contain user IDs.
- Related history: **Equipment Assignments** (every assignment) and **Maintenance Log** (every maintenance operation).
- Permissions: users with the Equipment Reader, Manager or Administrator permission set can view the audit trail; nobody can edit it.
- TODO(verify): the points above were not checked in a sandbox.

## Release notes
Equipment Audit Trail: every piece of equipment now has a read-only timeline of its life (created, updated, assigned, returned, sent to maintenance, disposed) with the user, the time and the status afterwards. Open it with Audit Trail on the Equipment Card. Updated entries do not show values; use the Change Log for those.
