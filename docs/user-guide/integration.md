# Integration with other apps

This article explains how other systems can follow what happens to your equipment: integration event entries and Power Automate flows. It is for administrators and for people who build flows. For the APIs themselves, see [Using the API](using-the-api.md).

**In this article**
- [Integration event entries](#integration-event-entries)
- [Power Automate](#power-automate)
- [Developers](#developers)

## Integration event entries

When you turn the feature on, the app writes one entry for each business event: equipment created, equipment assigned, equipment returned, maintenance created and warranty expired. The other system reads the pending entries through the API, and marks each one as processed. TODO(verify): the feature is not checked in a sandbox.

### Turn it on

1. Choose the search icon, enter **Equipment Setup**, and choose the related link.
2. In the **Integration** FastTab, turn on **Integration Events Enabled**.

The switch is off by default. While it is off, no entries are written. Events that happened before you turned it on are not recorded. The FastTab is shown only when the API Integration feature is on.

### View the entries

On **Equipment Setup**, choose **Integration Event Entries**. The list shows the newest entry first.

| Column | What it shows |
|---|---|
| **Entry No.** | The running number of the entry. |
| **Event Type** | Equipment Created, Equipment Assigned, Equipment Returned, Maintenance Created or Warranty Expired. |
| **Equipment No.** | The equipment the event is about. |
| **Equipment Status** | The equipment status when the event happened. |
| **Assignment Entry No.** | The assignment entry, for assigned and returned events. 0 for other events. |
| **Maintenance No.** | The maintenance record, for Maintenance Created. Blank otherwise. |
| **Created At** | When the entry was written. |
| **Processed** and **Processed At** | Whether and when the other system handled the entry. |

Entries cannot be created or changed by hand. Registering maintenance on assigned equipment writes two entries: Equipment Returned, then Maintenance Created. The daily warranty job writes the Warranty Expired entries.

### Delete processed entries

Entries are not removed automatically. An Equipment Administrator can delete entries that are marked Processed. Entries that are not processed cannot be deleted. You can also set up a retention policy. See [Notifications and monitoring](notifications-and-monitoring.md).

## Power Automate

The app publishes two events that start a Power Automate flow. Both appear under the category **Equipment Management**.

| Event | Starts when | Data |
|---|---|---|
| **Equipment assigned** | Equipment is assigned to an employee. | Equipment id, equipment number, description, employee number, assignment id, assignment date. |
| **Warranty expiring** | A warranty alert is created, 90, 60 or 30 days before the warranty end date. | Equipment id, equipment number, description, warranty provider, warranty end date, days remaining, alert interval. |

The employee name is not sent, only the employee number. Nothing is sent until you build a flow that subscribes. An event is sent only after the operation is saved. If the operation fails, nothing is sent.

TODO(verify): the events are not tested in Power Automate or in a sandbox. The screen names in Power Automate may differ from the steps below. The permission that a flow builder needs to subscribe to external business events is not confirmed.

### Example: Teams message when equipment is assigned

1. In Power Automate, choose **Create**, and then **Automated cloud flow**.
2. Search for the trigger **When a business event occurs** of the Business Central connector.
3. Select your **Environment** and **Company**. For **Category**, choose **Equipment Management**. For **Business event**, choose **Equipment assigned**.
4. Choose **New step**, search **Microsoft Teams**, and select **Post message in a chat or channel**.
5. Choose where to post, and then the team and channel.
6. In **Message**, write the text and insert the dynamic content from the trigger, for example the equipment number, the employee number and the assignment date.
7. Save the flow.

### Example: email when a warranty is expiring

1. Create an **Automated cloud flow** with the trigger **When a business event occurs**.
2. Select **Environment** and **Company**. For **Category**, choose **Equipment Management**. For **Business event**, choose **Warranty expiring**.
3. Choose **New step**, search **Office 365 Outlook**, and select **Send an email (V2)**.
4. In **To**, enter the recipient. Write the subject and the body with the dynamic content, for example the equipment description, the warranty provider and the end date.
5. Save the flow.

The email is sent when the warranty alert job creates an alert. It is also sent when you run **Generate Alerts** manually, once for each alert.

### React to records instead

To react to a record being created or changed, use the Business Central trigger **When a record is created** on the assignment API instead. It reacts to records, not to business moments. There is no equivalent for warranty alerts.

## Developers

Developers can subscribe to the business events of the app in their own extensions. This is described in the developer documentation (FR-060), which is not written yet.

## What to know

- Returning equipment does not start the Equipment assigned flow.
- Each warranty alert starts the flow once. The next alert, at 60 and then 30 days, starts it again.
- If nobody marks entries as processed, the list keeps growing.
- An entry exists only when the operation that caused it was saved. If writing an entry fails, the operation fails too.
- Both events and the entries are version 1.0. Names and data will not change after the first release.

## Related

- [Using the API](using-the-api.md)
- [Setup and configuration](setup-and-configuration.md)
- Feature article: [Integration Events](../help/FR-030-event-subscribers.md)
- Feature article: [Power Automate Support](../help/FR-031-power-automate-support.md)
- Learn: [Use Power Automate flows in Business Central](https://learn.microsoft.com/dynamics365/business-central/across-how-use-financials-data-source-flow)

---
Previous: [Audit and change tracking](audit-and-change-tracking.md) | Next: [Using the API](using-the-api.md)
