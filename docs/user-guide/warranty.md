# Warranty

This article explains how to record warranty information, how the warranty status is calculated and how to work with warranty alerts. It is for Managers, Operators and Administrators. Equipment Readers can see the status and the alerts.

**In this article**
- [Enter the warranty](#enter-the-warranty)
- [Warranty status](#warranty-status)
- [Warranty monitoring on the dashboard](#warranty-monitoring-on-the-dashboard)
- [Warranty alerts](#warranty-alerts)
- [Acknowledge alerts](#acknowledge-alerts)
- [Create alerts now](#create-alerts-now)
- [Alert days from the setup](#alert-days-from-the-setup)

## Enter the warranty

Warranty information is optional. It is changed by users with the Equipment Manager or Equipment Administrator permission set.

1. Open the equipment on the equipment card.
2. In the **Warranty** FastTab, fill in the fields that you know. The fields are described in [Equipment register](equipment-register.md#warranty).

Rules:

- All fields are optional. You can fill in just one date.
- When you fill in both dates, the end date must be later than the start date. The same day is not accepted. You get an error and the date is not accepted. To move a warranty to a later period, change the end date first, and then the start date.
- Dates can be in the past or in the future. You can change warranty fields on lost and disposed equipment.

When the FastTab is collapsed, it shows **Warranty End Date** and **Warranty Provider**. On the equipment list, the four warranty fields are hidden by default. Show them through personalization. To find equipment whose warranty ends soon, filter **Warranty End Date** on a period.

## Warranty status

You do not enter the status. It is calculated from the **Warranty End Date** and today's real date, not the work date.

| Warranty Status | When |
|---|---|
| Active | The warranty ends more than 30 days from today. |
| Expiring Soon | The warranty ends today or within the next 30 days. |
| Expired | The warranty end date is before today. |
| Blank | No warranty end date is filled in. The equipment is not monitored. |

The last day of the warranty is the end date. A warranty that ends today is still Expiring Soon, and is Expired from tomorrow. The start date does not change the status.

The status is shown on the equipment card, after **Warranty End Date**, in green, yellow or red. It is also a column in the equipment list. You cannot filter or sort on the status. The card and list show the status for lost and disposed equipment too.

## Warranty monitoring on the dashboard

The **Warranty** group on the dashboard and on the role center counts equipment by warranty end date. Lost and disposed equipment and equipment without an end date are not counted. See [Dashboards and role center](dashboards-and-role-center.md).

## Warranty alerts

An alert is created when the warranty has 90, 60 and 30 days left. Warranty alerts need the Warranty Alerts feature.

| Days left | Alert created |
|---|---|
| 61 to 90 | 90 Days |
| 31 to 60 | 60 Days |
| 0 to 30 | 30 Days |

- Each alert is created once for an equipment and warranty end date.
- If the warranty already has fewer days left when it is first checked, only the alert for the current interval is created. A warranty with 45 days left gets the 60 Days alert.
- A warranty that has ended gets no new alert. Open alerts of a warranty that has ended stay open until you acknowledge them.
- If you change the **Warranty End Date**, the open alerts for the old date are cancelled, and new alerts are created for the new date. Alerts that you acknowledged for a date are not created again for that date.
- Open alerts are also cancelled when the equipment is lost, disposed of or deleted. Lost and disposed equipment get no alerts.
- Alerts are created when the daily job runs, or when a manager chooses **Generate Alerts**. A changed end date shows only after the next run.

To see the alerts:

1. Choose the search icon, enter **Warranty Alerts**, and choose the related link. You can also choose **Warranty Alerts** in the Equipment Manager role center.
2. Use the views **Open**, **Acknowledged** and **Cancelled** to filter.

On an equipment card, choose **Related**, then **Equipment**, then **Warranty Alerts**, to see the alerts of that equipment.

The list shows the equipment, the alert interval, the warranty end date, **Days Remaining**, the warranty provider, the status and who acknowledged the alert. **Days Remaining** is negative after the end date. Choose **Equipment** to open the equipment card.

The **Open Warranty Alerts** tile shows how many alerts are open. Choose it to open the open alerts. Alerts cannot be deleted. Closed alerts can be removed with a retention policy. See [Notifications and monitoring](notifications-and-monitoring.md).

## Acknowledge alerts

1. Select one or more alerts.
2. Choose **Acknowledge**.

Open alerts become Acknowledged, and record your user and the time. Alerts that are already acknowledged or cancelled are skipped. If you select only such alerts, a message tells you so. Acknowledging an alert needs the Equipment Operator, Manager or Administrator permission set.

## Create alerts now

1. On **Warranty Alerts**, choose **Generate Alerts**.
2. A message shows the number of alerts that were created and cancelled.

The action creates the alerts that are due today without waiting for the daily job. Alerts that already exist are not created again.

## Alert days from the setup

**Default Warranty Alert Days** on **Equipment Setup** sets how many days before the end date alerts start, from 1 to 90. With 30, only the 30-day alert is created. If the field is blank, 90 days is used. Open alerts stay open when you lower the number. See [Setup and configuration](setup-and-configuration.md).

## What to know

- Notifications for a warranty that is about to end appear only while an open alert exists. See [Notifications and monitoring](notifications-and-monitoring.md).
- Alerts exist only after the daily job has run, or a manager has chosen **Generate Alerts**.
- The daily job runs as the user who created it. If that user is disabled or loses permissions, the job fails.
- If the Warranty Alerts feature is off, the page shows an error when you open it. The alert actions are hidden.
- TODO(verify): the warranty process is not checked in a sandbox.

## Related

- [Equipment register](equipment-register.md)
- [Dashboards and role center](dashboards-and-role-center.md)
- [Notifications and monitoring](notifications-and-monitoring.md)
- Feature article: [Warranty information](../help/FR-014-warranty-information.md)
- Feature article: [Warranty monitoring](../help/FR-015-warranty-monitoring.md)
- Feature article: [Warranty alerts](../help/FR-016-warranty-alerts.md)
- Feature article: [Application Setup](../help/FR-043-application-setup.md)

---
Previous: [Maintenance](maintenance.md) | Next: [Dashboards and role center](dashboards-and-role-center.md)
