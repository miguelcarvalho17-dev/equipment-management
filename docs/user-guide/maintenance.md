# Maintenance

This article explains how to register and post maintenance, how maintenance changes the status of equipment, how to plan recurring maintenance and how to read the maintenance log. It is for Equipment Operators, Managers and Administrators. Equipment Readers can view maintenance.

**In this article**
- [Register a maintenance record](#register-a-maintenance-record)
- [Correct a record](#correct-a-record)
- [Post a record](#post-a-record)
- [Effect on the equipment status](#effect-on-the-equipment-status)
- [View maintenance and history](#view-maintenance-and-history)
- [Plan recurring maintenance](#plan-recurring-maintenance)
- [Overdue maintenance](#overdue-maintenance)
- [Maintenance costs](#maintenance-costs)
- [The maintenance log](#the-maintenance-log)

## Register a maintenance record

An administrator must first set **Maintenance Nos.** on **Equipment Setup**. New companies get it automatically.

1. Open the equipment card and choose **Register Maintenance**. Or choose the search icon, enter **Equipment Maintenance**, and choose **New**.
2. Fill in the fields of the **Maintenance Record** card.
3. Close the card. The record is saved with the status Open.

### General

| Field | Description |
|---|---|
| **No.** | The number of the maintenance record. |
| **Equipment No.** | The equipment the maintenance is performed on. The equipment must exist and cannot be lost or disposed of. Registering the record sets the equipment status to In Maintenance. You cannot change the equipment after the record is created. |
| **Equipment Description** | The description of the equipment. |
| **Maintenance Date** | The date the maintenance was performed. The date cannot be later than today. If you leave it blank, the work date is used. |
| **Maintenance Type** | The type of maintenance: Preventive, Corrective, Inspection or Upgrade. New records start as Preventive. |
| **Description** | A description of the maintenance work. |
| **Status** | Whether the maintenance record is open or posted. While a record is open, the equipment is In Maintenance and cannot be assigned. Posting copies the record to the maintenance history, and after that it cannot be changed. When the last open record of the equipment is posted, the equipment becomes Available. |

### Vendor and Cost

| Field | Description |
|---|---|
| **Vendor No.** | The vendor that performed the maintenance. Leave it blank when the maintenance was done internally. |
| **Vendor Name** | The name of the vendor that performed the maintenance. |
| **Performed By** | The name of the person or team that performed the maintenance. |
| **Cost** | The cost of the maintenance in local currency. The cost must be zero or greater. |

If the equipment is assigned, you are asked to confirm. If you choose **Yes**, the equipment is returned from the employee, the assignment is closed and the equipment becomes In Maintenance. If you choose **No**, no maintenance is registered.

## Correct a record

You can change the date, type, vendor, cost and descriptions of a record while its status is Open. You cannot change the equipment or the number, and you cannot delete the record. Equipment that has maintenance records cannot be deleted either.

## Post a record

Post a record when it is final. Posting locks the record and adds it to the maintenance history.

1. Open the record from **Equipment Maintenance**.
2. Check the details.
3. Choose **Post**, or press F9, and confirm. On the card, your changes are saved first.

After posting:

- The status is Posted, and the record can no longer be changed or deleted.
- A history entry is created with the date, type, vendor, cost, description, who did the work, who posted it and when.
- The vendor number and name are saved as they were when you posted.
- For a Preventive record, the last maintenance date of the equipment moves forward to the maintenance date of the record, if it is later than the current one.

There is no way to undo posting. If a posted record is wrong, register a new record that describes the correction. If you registered a record by mistake, post it with a cost of 0 and a description that says it was cancelled. The equipment becomes Available.

If posting fails, nothing is posted and the record stays Open. On the list, **Post** works on the selected row only.

## Effect on the equipment status

1. When you register maintenance, the equipment status changes to **In Maintenance**. This also happens for work in the past.
2. While at least one record is Open, the equipment cannot be assigned.
3. When you post the last open record, the equipment becomes **Available**.

If several records are open, the equipment stays In Maintenance until the last one is posted. Posting does not change the status of Lost or Disposed equipment. While a record is open, you cannot set the equipment to Available by hand, but you can still set it to Lost or Disposed.

## View maintenance and history

| Where | What you see |
|---|---|
| **Equipment Maintenance** list | All records, newest number first. Views: Preventive, Corrective, Inspection, Upgrade, Open and Posted. |
| **Maintenance History** list | Every posted maintenance. Views by type. |
| Equipment card, **Maintenance History** section | The posted maintenance of that equipment, newest date first. Open records are not shown. |
| Equipment card, **Maintenance** action | The records of that equipment. |
| **Maintenance** FactBox | The number of records, the number of open records, the latest record and the next maintenance date. |

On a posted row of the Equipment Maintenance list, choose **History Entry** to see its history entry. Choose **Equipment** or **Vendor** to open those cards.

## Plan recurring maintenance

Planned maintenance needs the Maintenance Planning feature. See [Setup and configuration](setup-and-configuration.md).

1. Open the equipment card. The **Planned Maintenance** FastTab is after the Warranty FastTab.
2. In **Maintenance Frequency (Months)**, enter how many months pass between maintenance, from 0 to 120. For example, enter 6 for every six months.
3. In **Last Maintenance Date**, enter the date the equipment was last maintained. It cannot be later than today.

**Next Maintenance Date** is calculated: the last maintenance date plus the frequency. For example, a last maintenance on 1 January 2026 with a frequency of 6 months gives 1 July 2026. It is blank when either field is blank. If the last date is at the end of a longer month, the next date is expected to be the last day of the shorter month. TODO(verify): not checked in a sandbox.

Posting a Preventive record moves the last maintenance date forward, but never backwards. Corrective, Inspection and Upgrade records do not change the plan. A daily job at 05:00 corrects dates that are out of date. See [Notifications and monitoring](notifications-and-monitoring.md).

To find equipment that is due, filter **Next Maintenance Date** on the equipment list with a date range. A filter with only an upper limit can also list equipment without a plan. TODO(verify): not checked in a sandbox.

## Overdue maintenance

Equipment is overdue when its next maintenance date is before today.

- The next maintenance date is shown in red on the equipment list, the equipment card and the Maintenance FactBox.
- The **Overdue Maintenance Equipment** tile on the dashboard counts the overdue equipment. Choose it to open the list.
- Due today is not overdue. Today means the real calendar date, not your work date.
- Lost and disposed equipment, and equipment without a next maintenance date, are never overdue.

Being overdue does not block anything. To clear it, post a Preventive record with a later date, or change the last maintenance date or the frequency. Disposing or losing the equipment also removes the highlight. The app sends no notification for overdue planned maintenance. It does notify you about a maintenance record that has been open for more than 14 days. See [Notifications and monitoring](notifications-and-monitoring.md).

## Maintenance costs

Only posted maintenance counts in the cost figures, in local currency.

- The equipment list shows **Total Maintenance Cost** per equipment. Choose the amount to open its history. Optional columns are **No. of Posted Maintenances**, **Average Maintenance Cost** and **Maintenance Cost %**.
- **Maintenance Cost %** is the total cost as a percentage of the purchase cost. At 100 or more it is shown in red. It is blank when the equipment has no purchase cost or no posted maintenance.
- To see the cost of one period, choose **Filter totals by**, and set **Date Filter**.
- The dashboard shows cost tiles and two charts. See [Dashboards and role center](dashboards-and-role-center.md).
- Maintenance posted with a cost of 0 counts in the number of maintenances and lowers the average.
- The cost chart uses the current category of the equipment. If you move equipment to another category, its past cost moves with it.

## The maintenance log

Every maintenance record has a permanent log of who registered, changed and posted it. See [Audit and change tracking](audit-and-change-tracking.md).

To read the log in your regional format, set your **Region** in **My Settings**. The **Maintenance Date** is shown as a date in your regional format, **Cost** with the separators of your region, and **Maintenance Type** by its name. The stored values do not change. To show the XML values, use personalization and add **Old Value (XML Format)** or **New Value (XML Format)**. See [Personalize your workspace](https://learn.microsoft.com/dynamics365/business-central/ui-personalization-user).

## What to know

- You cannot register maintenance for equipment that is Lost or Disposed.
- Maintenance records cannot be deleted.
- Registering maintenance for assigned equipment also returns the equipment.
- If two users register or post maintenance for the same equipment while the confirmation question is open, one of them may have to wait.
- Equipment that already had open records before the status rule existed cannot be assigned until those records are posted.
- The date of a record cannot be later than today. If you leave it blank, the work date is used.

## Related

- [Equipment register](equipment-register.md)
- [Warranty](warranty.md)
- [Audit and change tracking](audit-and-change-tracking.md)
- Feature article: [Equipment maintenance](../help/FR-010-maintenance-registration.md)
- Feature article: [Maintenance history](../help/FR-011-maintenance-history.md)
- Feature article: [Maintenance and equipment status](../help/FR-012-equipment-maintenance-status.md)
- Feature article: [Maintenance costs](../help/FR-013-maintenance-cost-tracking.md)
- Feature article: [Planned maintenance](../help/FR-019-planned-maintenance.md)
- Feature article: [Overdue maintenance monitoring](../help/FR-020-overdue-maintenance-monitoring.md)
- Feature article: [Maintenance log](../help/NFR-005-auditability.md)
- Feature article: [Regional format of the maintenance log](../help/FR-056-regional-settings.md)

---
Previous: [Equipment requests](equipment-requests.md) | Next: [Warranty](warranty.md)
