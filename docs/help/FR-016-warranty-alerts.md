# Warranty alerts (AppSource end-user help)

Get an alert when a warranty is about to end, so you can renew it, plan a replacement or raise a claim in time. An alert is created when the warranty has 90, 60 and 30 days left.

## Before you start: permissions
- **Equipment Reader**, **Equipment Manager** and **Administrator** can see the alerts, the dashboard tile and the alerts of an equipment card.
- **Acknowledge** and **Generate Alerts** need **Equipment Manager** or **Administrator**. For a Reader they are disabled.
- Alerts cannot be deleted.

## When an alert is created
Alerts are based on the **Warranty End Date** of the equipment, counted from today's real date (not the work date). Lost and disposed equipment get no alerts.

| Days left | Alert created |
|---|---|
| 61 to 90 | 90 Days |
| 31 to 60 | 60 Days |
| 0 to 30 | 30 Days |

- Each alert is created once for an equipment and warranty end date.
- If the warranty already has fewer days left when it is first checked, only the alert for the current interval is created. A warranty with 45 days left gets the 60 Days alert, not a 90 Days alert.
- A warranty that has ended gets no new alert.
- If you change the **Warranty End Date**, the open alerts for the old date are cancelled and new alerts are created for the new date. Alerts you already acknowledged for a date are not created again for that date.
- Open alerts are also cancelled when the equipment is lost, disposed of or deleted. Open alerts of a warranty that has simply ended stay open until you acknowledge them.
- Alerts appear when the daily job runs or when a manager chooses **Generate Alerts**. A changed end date is only reflected after the next run.

## See the alerts
- Search for **Warranty Alerts**, or choose **Warranty Alerts** in the Equipment Manager Role Center.
- On the **Equipment Card**, choose **Related** > **Equipment** > **Warranty Alerts** to see the alerts of that equipment. The action is available once the card is saved.
- The **Open Warranty Alerts** tile in the Warranty group of the dashboard shows how many alerts are open. Choose it to open the open alerts.

The list shows the equipment, the alert interval, the warranty end date, **Days Remaining** (negative after the end date), the warranty provider (the company to contact for a renewal or claim), the status and who acknowledged the alert. Use the views **Open**, **Acknowledged** and **Cancelled** to filter by status. Choose **Equipment** to open the equipment card.

## Acknowledge alerts
1. Select one or more alerts.
2. Choose **Acknowledge**.

Open alerts become Acknowledged and record your user and the time. Alerts that are already acknowledged or cancelled are skipped. If you select only such alerts, you get the message that they are already acknowledged or cancelled.

## Create alerts now
Choose **Generate Alerts** to create the alerts that are due today without waiting for the daily job. You get a message with the number of created and cancelled alerts. Alerts that already exist are not created again.

## Set up the daily job (administrator)
Alerts are created every day by a job queue entry. It is not created automatically.
1. Open **Job Queue Entries** and choose **New**.
2. Set **Object Type to Run** to Codeunit and **Object ID to Run** to 50111 (EQM Warranty Alert Job).
3. Make the entry recurring on all days and enter a starting time, for example 06:00.
4. Set the status to **Ready**.

The entry runs as the user who sets it to Ready. That user needs **Equipment Manager** or **Administrator**. Without the entry, alerts are only created when a manager chooses **Generate Alerts**.

## Release notes
Warranty Alerts: the app now creates an alert 90, 60 and 30 days before a warranty ends, so you can renew it, plan a replacement or raise a claim in time. Open the new Warranty Alerts list from the Equipment Manager Role Center or from the Equipment Card, see the number of open alerts in the new Open Warranty Alerts tile on the dashboard, and acknowledge alerts when you have acted on them. Alerts are created every day by a job queue entry (set up by an administrator) or when a manager chooses Generate Alerts. If the warranty end date changes, the open alerts are cancelled and new ones are created for the new date.
