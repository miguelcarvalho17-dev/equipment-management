# Power Automate Support (AppSource end-user help)

Equipment Management publishes two events that start a Power Automate flow: **Equipment assigned** and **Warranty expiring**. Use them to post a Teams message when equipment is handed out, or to email the responsible person before a warranty ends. Nothing is sent until you build a flow that subscribes, and an event is sent only after the operation has been saved. If the operation fails, nothing is sent.

TODO(verify): this feature has not been tested in Power Automate or in a sandbox. Automated tests only check that assigning equipment and creating a warranty alert run without an error; the events themselves are not tested automatically. Screen names in Power Automate may differ from the steps below.

## Before you start: permissions
- The person who builds the flow needs a Business Central user with permission to subscribe to external business events (a Business Central permission, not part of the Equipment permission sets). TODO(verify): which permission set.
- **Equipment Reader, Manager and Administrator** include the permission to raise the events.
- Assigning equipment needs Manager or Administrator; the warranty alerts are created by the daily warranty job or the Generate Alerts action.

## The events
Both appear in Power Automate under the category **Equipment Management**.

| Event | Starts when | Data |
|---|---|---|
| Equipment assigned | Equipment is assigned to an employee. | Equipment id, equipment number, description, employee number, assignment id, assignment date. |
| Warranty expiring | A warranty alert is created, 90, 60 or 30 days before the warranty end date. | Equipment id, equipment number, description, warranty provider, warranty end date, days remaining, alert interval (90, 60 or 30). |

The employee name is not sent, only the employee number.

## Example 1: Teams message when equipment is assigned
1. In Power Automate, choose **Create** > **Automated cloud flow**, skip the name suggestion and search the trigger **When a business event occurs** (Business Central).
2. Select your **Environment** and **Company**. For **Category**, choose **Equipment Management**; for **Business event**, choose **Equipment assigned**.
3. Choose **New step**, search **Microsoft Teams** and select **Post message in a chat or channel**.
4. Choose where to post (for example **Channel**), then the team and channel.
5. In **Message**, write the text and insert the dynamic content from the trigger, for example: "Equipment [Equipment No.] ([Equipment Description]) was assigned to employee [Employee No.] on [Assignment Date]."
6. Save the flow. Assign equipment in Business Central; the message is posted after the assignment is saved (it can take a moment).

Optional: to show the employee name, add a **Business Central** action **Get record** (or a **List records** on the standard employees API) filtered on the employee number.

## Example 2: Email when a warranty is expiring
1. Create an **Automated cloud flow** with the trigger **When a business event occurs**.
2. Select **Environment** and **Company**, **Category** **Equipment Management**, **Business event** **Warranty expiring**.
3. Choose **New step**, search **Office 365 Outlook** and select **Send an email (V2)**.
4. In **To**, enter the recipient. In **Subject**, for example: "Warranty expiring: [Equipment No.]".
5. In **Body**, use the dynamic content: "[Equipment Description] has a warranty with [Warranty Provider] that ends on [Warranty End Date], in [Days Remaining] days (alert [Alert Interval Days] days before the end)."
6. Save the flow. The email is sent when the warranty alert job creates an alert (also when you run Generate Alerts manually), once per alert.

## No-code alternative: record changes
If you only need to react to a record being created or changed, use the Business Central trigger **When a record is created** (or changed) on the Assignment API (entity `assignments`) instead. It reacts to records, not to business moments, and there is no equivalent for warranty alerts.

## Good to know
- Events are sent only to flows that subscribe, and only after the operation is saved.
- Unassigning equipment does not start the Equipment assigned flow.
- Each warranty alert starts the flow once; the next alert (60, then 30 days) starts it again.
- The events are version 1.0 and a frozen contract once released: names and data will not change. Changes will come as a new version.

For general use of the trigger, see the Microsoft Learn documentation for the Business Central connector in Power Automate.

## Release notes
Power Automate: Equipment Management now offers two triggers for the "When a business event occurs" trigger of the Business Central connector, under the category Equipment Management. Equipment assigned starts a flow when equipment is assigned to an employee; Warranty expiring starts a flow when a 90, 60 or 30 day warranty alert is created. Build flows such as a Teams message or an email without code. Events are sent only to flows that subscribe, and only after the operation is saved.
