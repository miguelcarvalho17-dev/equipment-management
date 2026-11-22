# Audit and change tracking

This article explains the three ways to see what happened to equipment and maintenance: the equipment audit trail, the standard Business Central change log and the maintenance log. It is for managers, auditors and administrators.

**In this article**
- [Equipment audit trail](#equipment-audit-trail)
- [Change log](#change-log)
- [Maintenance log entries](#maintenance-log-entries)
- [Which record to use](#which-record-to-use)

## Equipment audit trail

The equipment audit trail is a read-only timeline for each piece of equipment. It shows when the equipment was created, changed, assigned, returned, sent to maintenance or disposed, who did it, and the status afterwards. It is always on and needs no setup. TODO(verify): the audit trail is not checked in a sandbox.

### Open the audit trail

1. Open the equipment card and choose **Audit Trail**. The action is available once the equipment is saved. The list shows only this equipment.
2. To see all equipment, choose the search icon, enter **Equipment Audit Trail**, and choose the related link.

The newest entry is at the top.

| Event Type | When |
|---|---|
| Created | New equipment is created. |
| Updated | Equipment details are saved with a change. |
| Assigned | Equipment is assigned to an employee. |
| Returned | Equipment is returned from an employee. |
| Sent to Maintenance | The status changes to In Maintenance, for example when you register maintenance. |
| Disposed | The status changes to Disposed. |

The columns are **Logged At**, **User ID**, **Event Type**, **Status After**, **Employee No.**, **Assignment Entry No.** and **Maintenance No.** The maintenance number is blank when someone changed the status by hand.

When assigned equipment is sent to maintenance or disposed, it is returned first, so a Returned entry appears before the Sent to Maintenance or Disposed entry.

An Updated entry says that details were saved with a change. It does not show which field or the values. The equipment card saves each field that you edit separately, so editing five fields gives five Updated entries. Changing the status to Lost, or from In Maintenance back to Available, also gives an Updated entry.

Entries cannot be changed or deleted. They contain user IDs. Deleting equipment does not delete its audit entries. Equipment created before the audit trail existed has no Created entry.

## Change log

The standard Business Central change log records who changed what, when, and the old and new value. The app registers the rules for equipment fields. The rules do nothing until an administrator turns on the change log. See [Audit changes](https://learn.microsoft.com/dynamics365/business-central/across-log-changes).

### Fields that are tracked

On an equipment record, changes to these fields are recorded: **Category Code**, **Status**, **Assigned Employee No.** and the four warranty fields **Warranty Start Date**, **Warranty End Date**, **Warranty Provider** and **Warranty Reference No.** Only changes are recorded, not the creation or deletion of equipment. Changes to other fields, such as **Description** or **Location Code**, are not recorded. Categories and the assignment history are not tracked.

### Turn on the change log

1. Choose the search icon, enter **Change Log Setup**, and choose the related link.
2. Turn on **Change Log Activated**.
3. Ask users to sign in again.

### See the recorded changes

1. Choose the search icon, enter **Change Log Entries**, and choose the related link.
2. Filter on the table of the equipment, or on the equipment number in **Primary Key**.

Each entry shows the date and time, the user, the field, the old value and the new value. How long entries are kept follows your change log retention policy. A company created after the app was installed may not have the rules. In that case, add the equipment table and its fields on **Change Log Setup**. TODO(verify): the entries per field and the behavior after you turn the change log on are not checked in a sandbox.

## Maintenance log entries

Every maintenance record has a permanent log of what happened to it. The maintenance log is always on and needs no setup.

### What is logged

- **Registered:** a maintenance record was created.
- **Changed:** a field of an open record was corrected. There is one entry for each field. The logged fields are Maintenance Date, Maintenance Type, Vendor No., Cost, Description and Performed By.
- **Posted:** the record was posted and locked.

### Open the log

1. Open **Equipment Maintenance** and select a record, or open the **Maintenance Record** card.
2. Choose **Log Entries**. The list shows only the entries of that record, newest first.
3. To see all entries, choose the search icon, enter **Maintenance Log Entries**, and choose the related link.

The columns include **Logged At**, **User ID**, **Action**, **Field Caption**, **Old Value** and **New Value**. The old and new values are shown in your regional format. See [Maintenance](maintenance.md#the-maintenance-log).

Everyone with the Equipment Reader permission set or higher can read the log. No role can edit it. Maintenance records created before the log existed have no Registered entry. Changes to the planned maintenance dates and the frequency on the equipment card are not part of this log. TODO(verify): the field name column and the Maintenance Type values are not checked in a sandbox.

## Which record to use

| You want to know | Use |
|---|---|
| When equipment was created, assigned, returned, sent to maintenance or disposed, and by whom. | Equipment audit trail |
| The old and new value of a changed equipment field. | Change log |
| Who registered, changed and posted a maintenance record. | Maintenance log entries |
| Who had the equipment, and from when to when. | Assignment history. See [Assignments](assignments.md). |

## What to know

- The audit trail and the maintenance log contain user IDs. See [Security and permissions](security-and-permissions.md).
- The equipment error log is not an audit trail. See [Notifications and monitoring](notifications-and-monitoring.md).
- Telemetry is not an audit trail either. See [Advanced scenarios](advanced-scenarios.md).

## Related

- [Maintenance](maintenance.md)
- [Assignments](assignments.md)
- Feature article: [Tracking Equipment Changes with the Change Log](../help/FR-034-change-log-support.md)
- Feature article: [Following the Life of Equipment with the Audit Trail](../help/FR-035-equipment-audit-trail.md)
- Feature article: [Maintenance log](../help/NFR-005-auditability.md)
- Learn: [Audit changes](https://learn.microsoft.com/dynamics365/business-central/across-log-changes)

---
Previous: [Notifications and monitoring](notifications-and-monitoring.md) | Next: [Integration with other apps](integration.md)
