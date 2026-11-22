# Setup and configuration

This article explains how to configure Equipment Management for a company: numbering, defaults, features, categories and demo data. It is for administrators.

**In this article**
- [Open Equipment Setup](#open-equipment-setup)
- [Numbering](#numbering)
- [Defaults](#defaults)
- [Features](#features)
- [Integration](#integration)
- [Background monitoring](#background-monitoring)
- [Actions on Equipment Setup](#actions-on-equipment-setup)
- [Equipment categories](#equipment-categories)
- [Equipment features](#equipment-features)
- [Demo data](#demo-data)
- [Requirements](#requirements)

## Open Equipment Setup

1. Choose the search icon, enter **Equipment Setup**, and choose the related link.
2. Change the settings. The setup applies to the current company only.

The first time an administrator opens the page in a company that has no setup, the app creates the setup, the number series and the starter categories. A user who cannot change the setup sees a message that asks them to contact an administrator.

Users who cannot change the setup can open the page, but it is read-only.

## Numbering

The **Numbering** FastTab holds the number series that the app uses for new records.

| Field | Description |
|---|---|
| **Equipment Nos.** | The number series used to assign numbers to new equipment. |
| **Maintenance Nos.** | The number series used to assign numbers to new maintenance records. |
| **Request Nos.** | The number series used to assign numbers to new equipment requests. |

## Defaults

The **Defaults** FastTab holds the values that new records start with. Each field is shown only when its feature is on: Default Warranty Alert Days needs Warranty Alerts, and Default Maintenance Frequency needs Maintenance Planning.

| Field | Description |
|---|---|
| **Default Warranty Alert Days** | How many days before the warranty end date warranty alerts start to be created, from 1 to 90. Alerts are created 90, 60 and 30 days before the end date, as far as these fall within this number of days; for example, with 30 only the 30-day alert is created. When the field is blank, 90 days is used. Alerts that are already open are kept when you lower the number. |
| **Default Maintenance Frequency (Months)** | The maintenance frequency, in months, that new equipment gets when you create it on the equipment card, from 0 to 120. You can change the frequency on each piece of equipment. Leave the field blank when new equipment has no planned maintenance by default. Existing equipment, and equipment created through the API or by import, is not changed. |

## Features

The **Features** FastTab has three switches. Each switch is the same setting as a feature on **Equipment Features**.

| Field | Description |
|---|---|
| **Enable Notifications** | Whether users in this company see equipment notifications about expiring warranties, overdue maintenance and equipment that is back from maintenance. When it is off, no equipment notification is shown; when it is on, each user can still turn single notifications off in My Notifications. This is the Notifications feature on the Equipment Features page. |
| **Enable Equipment Requests** | Whether employees can request equipment and approvers can approve or reject the requests. When it is off, the Equipment Requests pages, actions and tile are hidden and existing requests are kept. This is the Approval Workflows feature on the Equipment Features page. Users see the change the next time they open a page. |
| **Enable APIs** | Whether external systems can use the equipment APIs. When it is off, the APIs return an error, the integration settings are hidden and no integration event entries are written. This is the API Integration feature on the Equipment Features page. Users see the change the next time they open a page. |

Changes apply the next time a user opens a page. A page that is already open keeps its state.

## Integration

The **Integration** FastTab is shown only when the API Integration feature is on.

| Field | Description |
|---|---|
| **Integration Events Enabled** | That an integration event entry is written for each business event (equipment created, assigned or returned, maintenance created, warranty expired), so that external systems can read them through the API. Entries are written only when this is on. |

## Background monitoring

The **Background Monitoring** FastTab shows the status of the daily jobs. See [Notifications and monitoring](notifications-and-monitoring.md).

| Field | Description |
|---|---|
| **Warranty Alert Job** | The status of the job queue entry that creates warranty alerts every day. Not scheduled means that no entry exists; choose Schedule Monitoring Jobs to create it. |
| **Overdue Maintenance Job** | The status of the job queue entry that checks overdue maintenance every day. Not scheduled means that no entry exists; choose Schedule Monitoring Jobs to create it. |
| **Maintenance Calculation Job** | The status of the job queue entry that recalculates the next maintenance date of the equipment every day. Not scheduled means that no entry exists; choose Schedule Monitoring Jobs to create it. |

## Actions on Equipment Setup

| Action | Description |
|---|---|
| **Schedule Monitoring Jobs** | Create the job queue entries that run the equipment monitoring every day, if they do not exist. Existing entries are not changed. |
| **Create Demo Data** | Create sample employees, equipment, assignments and maintenance records in this company so that you can try out the app. Existing records are not changed, and running it again only adds what is missing. |
| **Delete Demo Data** | Delete the demo data that Create Demo Data added to this company. Records that users created, and demo records that users added data to, are kept. |
| **Monitoring Job Queue Entries** | View the job queue entries that run the equipment monitoring, to see when they ran, change the time or restart them. |
| **Error Log** | View the errors that stopped the daily monitoring jobs or the scheduling of these jobs. |
| **Integration Event Entries** | View the integration event entries that external systems read through the API. |
| **Equipment Features** | Turn the optional equipment features on or off for this company: images, warranty alerts, approval workflows, API integration, maintenance planning and notifications. |

The **Error Log** action is shown only to users who can read the log. The **Integration Event Entries** action is shown only when the API Integration feature is on. The three actions that create jobs and demo data need the permission to change the setup.

## Equipment categories

Categories group your equipment. Maintaining them needs the Equipment Administrator permission set.

### Add a category

1. Choose the search icon, enter **Equipment Categories**, and choose the related link.
2. On a new line, enter a **Code** and a **Description**. **Active** is selected for you.

Codes must be unique, and they are not case sensitive.

### Deactivate a category

1. On **Equipment Categories**, clear **Active** for the category.

Equipment that already uses the category keeps it. Nobody can newly choose the category. To bring it back, select **Active** again.

### Delete or rename a category

- A category that equipment uses cannot be deleted. Clear **Active** instead.
- A deactivated category that equipment uses cannot be renamed. Select **Active**, rename the category, and then clear **Active** again.

## Equipment features

**Equipment Features** lets an administrator turn optional parts of the app on or off for the current company. Nothing is deleted when you turn a feature off.

1. Choose the search icon, enter **Equipment Features**, and choose the related link. You can also choose **Equipment Features** on **Equipment Setup** or in the Setup section of the Equipment Manager role center.
2. In the **Enabled** column, select the check box to turn a feature on, or clear it to turn it off.
3. Close the page.

| Feature | What it hides when it is off |
|---|---|
| **Equipment Images** | The picture FactBox on the equipment card and the equipment list. Stored pictures are kept. |
| **Warranty Alerts** | The Warranty Alerts action and the Open Warranty Alerts tile, the Warranty Alert Job field on setup and the warranty notifications. The daily job creates no new alerts. The Warranty Alerts page shows an error when you open it. |
| **Approval Workflows** | The Equipment Requests action on the employee card and the Requests Pending Approval tile. The request pages show an error. Existing requests are kept. |
| **API Integration** | The Integration FastTab and the Integration Event Entries action on setup. The equipment APIs return an error and no integration event entries are written. |
| **Maintenance Planning** | The Planned Maintenance FastTab on the equipment card, the Next Maintenance Date column in the list and on the Maintenance FactBox, and the two Planned Maintenance tiles. The next maintenance date is still calculated. |
| **Notifications** | All equipment notifications for every user in the company. |

TODO(verify): the wording of the error and of the empty list are not checked in a sandbox.

Users who cannot change the settings see an empty list until an administrator has opened the page once. The features still work in the meantime.

## Demo data

Demo data gives a company sample employees, equipment, assignments and maintenance records, so that you can try the app.

### Create demo data

1. Open **Equipment Setup**.
2. Choose **Create Demo Data**.
3. Read the question, which names the company. The default answer is **No**. Choose **Yes** to continue.
4. A notification shows how many records were created and how many were skipped.

The demo data has 8 employees with the last name Demo, 15 equipment records across the seven starter categories, current and past assignments, and 12 maintenance records. Some of the maintenance records are open, and two open records are overdue. Warranties are expired, expiring soon, active or blank. Dates are relative to today.

Running the action again adds only what is missing. It does not change existing records.

### Delete demo data

1. Open **Equipment Setup**.
2. Choose **Delete Demo Data**.
3. Read the question. The default answer is **No**. Choose **Yes** to continue.

The action deletes only the records that **Create Demo Data** added, with their history. It keeps equipment to which you added a picture, a note, an attachment, a request, your own maintenance record or your own assignment. It keeps an employee that is still used by equipment, an assignment, a request or an attachment. Records that you created yourself are never deleted.

Some effects cannot be undone by deleting the demo data. Power Automate flows that listen to the Equipment assigned event run for each active demo assignment. If the change log is on, the changes are logged. If telemetry is on, the usage signals are sent. Delete the demo data before you connect flows or other tools.

## Requirements

- To change the setup, the categories and the features, a user needs the Equipment Administrator permission set.
- To create or delete demo data, a user also needs the permission to insert and delete employees in Business Central.
- Equipment Manager and Equipment Reader users can open the pages and read the settings.

## What to know

- Settings apply to the current company only. Another company keeps its own settings.
- Turning a setting off does not change equipment, assignments, maintenance records or alerts that already exist.
- Turning off Notifications does not change business events, integration events, job queue entries or telemetry.
- The features are not a security setting. Permissions still decide who can see and change data.
- A setup that was created before the default for the warranty alert days existed can show the field blank. The app then uses 90 days.
- The default maintenance frequency applies only when you create equipment on the equipment card. It does not apply to equipment that exists, or to equipment created through the API or by import.

## Related

- [Getting started](getting-started.md)
- [Notifications and monitoring](notifications-and-monitoring.md)
- [Security and permissions](security-and-permissions.md)
- Feature article: [Manage equipment categories](../help/FR-002-equipment-categories.md)
- Feature article: [Equipment Features](../help/FR-042-feature-management.md)
- Feature article: [Application Setup](../help/FR-043-application-setup.md)
- Feature article: [Create and delete demo data (Equipment Management)](../help/FR-066-demo-data.md)
- Feature article: [Automatic daily monitoring](../help/FR-018-automated-background-processing.md)
- Feature article: [Automatic monitoring](../help/NFR-004-automation.md)
- Feature article: [Integration Events](../help/FR-030-event-subscribers.md)

---
Previous: [Getting started](getting-started.md) | Next: [Equipment register](equipment-register.md)
