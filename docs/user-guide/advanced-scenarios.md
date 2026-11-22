# Advanced scenarios

This article covers situations beyond the daily work: several companies, large registers, languages and regional formats, upgrades, telemetry and the limits of feature switches. It is for administrators.

**In this article**
- [Several companies and new companies](#several-companies-and-new-companies)
- [Large registers](#large-registers)
- [Languages and regional formats](#languages-and-regional-formats)
- [Upgrade the app](#upgrade-the-app)
- [Telemetry](#telemetry)
- [Feature switches and their limits](#feature-switches-and-their-limits)

## Several companies and new companies

The setup, the features and the data of the app belong to one company. Another company keeps its own settings.

The installation creates the setup, the number series, the starter categories and the daily jobs in each company that exists at that time. A company that you create later has no setup yet.

1. Sign in to the new company as a user with the Equipment Administrator permission set.
2. Choose the search icon, enter **Equipment Setup**, and choose the related link.

The app creates the setup, the number series, the starter categories and the daily jobs when the administrator opens the page. Until then, new equipment cannot be created, and a user without the Equipment Administrator permission set sees a message that asks them to contact an administrator. The Equipment Administrator can create the setup. A Reader or Manager who opens the page first gets the message.

The change log rules for the equipment fields may also be missing in a company that was created later. See [Audit and change tracking](audit-and-change-tracking.md). The retention policy tables may need the next upgrade before they are offered. See [Notifications and monitoring](notifications-and-monitoring.md).

## Large registers

The app is built for large registers: about 10,000 equipment records for the list and the dashboard, and 100,000 equipment records with 1,000,000 assignment records for the filters and jobs. The target of a list that opens in less than 3 seconds for up to 10,000 records is not yet measured.

- Narrow lists with filters instead of the search box. Filter on **Status**, **Category Code**, **Assigned Employee No.** or **Serial No.** Status and Category Code filters use indexes. Serial No. has no new index.
- The **Employee Name** column is looked up once for each employee while the list is open. If an employee is renamed while the list is open, close the list and open it again.
- Integrations can read only the records changed since their last read. Use a filter on `lastModifiedDateTime` in the equipment API and the assignment API.
- An administrator can turn on **Calculate only visible FlowFields** in **Feature Management**. See [Enabling upcoming features ahead of time](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/feature-management).
- A report on a long period can take a while. Use a shorter period or a **Maintenance Date** filter.

## Languages and regional formats

The app shows captions, ToolTips, messages and error messages in English, Portuguese (Portugal) or Spanish (Spain). The language follows the **Language** setting in Business Central. A user changes it in **My Settings** and signs in again.

If the language is not in the list, an administrator allows it on the **Allowed Languages** page. See [Specify the languages that are available in your Business Central environment](https://learn.microsoft.com/dynamics365/business-central/admin-allowed-languages).

What changes and what does not:

- The page and field names, ToolTips, actions and messages change.
- The data that you enter does not change, such as descriptions, notes and category descriptions. The starter categories and the number series keep the language they were created in.
- The date and number format follow your **Region** setting in **My Settings**. The maintenance log follows it too. See [Maintenance](maintenance.md#the-maintenance-log).
- For any other language, the app shows English.
- The column headings in the Excel reports are English.

## Upgrade the app

When you upgrade the app, it checks the data of each company once and fills in one value that earlier versions left blank. TODO(verify): the behavior after an upgrade is not checked in a sandbox.

- **Default Warranty Alert Days** on **Equipment Setup** shows 90 when it was blank. If you had set a value, the value stays.
- The upgrade does not change equipment, assignments, maintenance records, warranty alerts or number series.
- You do not need to run anything. The upgrade runs when the new version is installed.

To check, open **Equipment Setup**, and read **Default Warranty Alert Days** under **Defaults**.

## Telemetry

The app sends usage signals when equipment is created, assigned or returned, when maintenance is registered and when a warranty expires. It also sends signals for the warranty alert job, the overdue maintenance check and the scheduling of the monitoring jobs. The signals contain no customer data: no equipment, employee, maintenance or user numbers.

Telemetry is sent only when the environment is set up to send it. There is no switch in the app. To turn telemetry on or off, an administrator changes the environment settings in the Business Central admin center. See [Turn environment telemetry on or off](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/administration/telemetry-enable-application-insights).

Counts can be a little high, because a signal is sent when the action runs, before the save is complete. Telemetry is not an audit trail. Use the equipment audit trail for changes. TODO(verify): the signals are not checked in a sandbox.

## Feature switches and their limits

See [Setup and configuration](setup-and-configuration.md) for the switches. The limits:

- Pages of a feature that is off still appear in Tell Me. Opening one shows an error.
- The Equipment Requests and Warranty Alerts shortcuts on the role center stay visible when their feature is off.
- A page that is already open keeps its state until it is opened again.
- Users who cannot change the settings see an empty feature list until an administrator has opened **Equipment Features** once.
- If two administrators open **Equipment Features** for the first time at the same moment, the page may close with an error. Open it again.
- The features are not a security setting.

## What to know

- Business events for developers are described in the [developer documentation](../api/events.md) (FR-060).
- Daily jobs run in each company that has them. Check each company on **Equipment Setup**.

## Related

- [Setup and configuration](setup-and-configuration.md)
- [Notifications and monitoring](notifications-and-monitoring.md)
- Feature article: [Large registers: speed and filters](../help/FR-053-large-dataset-support.md)
- Feature article: [Equipment list and dashboard speed](../help/NFR-001-performance.md)
- Feature article: [Change the language of Equipment Management](../help/FR-055-multi-language-support.md)
- Feature article: [Regional format of the maintenance log](../help/FR-056-regional-settings.md)
- Feature article: [Data Upgrade Support](../help/FR-044-data-upgrade-support.md)
- Feature article: [Application telemetry](../help/FR-050-application-telemetry.md)
- Feature article: [Equipment Features](../help/FR-042-feature-management.md)

---
Previous: [Pages and UI reference](pages-and-ui-reference.md) | Next: [Troubleshooting and FAQ](troubleshooting-and-faq.md)
