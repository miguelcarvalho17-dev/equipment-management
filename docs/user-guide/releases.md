# Releases

This article lists what is in Equipment Management 29.0.0.0. The version is not released yet, and nothing is verified in a Business Central sandbox. The entries summarize the release notes of the change history.

**In this article**
- [29.0.0.0 (not released yet)](#29000-not-released-yet)

## 29.0.0.0 (not released yet)

### Equipment register and assignments

- Register equipment with categories and statuses. Assign equipment to employees and return it. Every assignment is kept with its start date, end date and user. Closed assignments cannot be changed, and equipment that was ever assigned cannot be deleted. Set it to Disposed instead.
- The equipment list explains how to search and filter, shows the name of the assigned employee, and can be opened from a category and from an employee. The equipment card shows who has the equipment and since when, the full assignment history, and who created and last changed the record.
- Equipment actions are grouped like other Business Central pages. FactBoxes show the assignment details, and the equipment assigned to an employee on the employee card. The equipment card has Equipment Summary, Equipment Statistics and Attachment Summary FactBoxes.

### Maintenance

- Register maintenance with date, type, vendor, cost and who did the work. Registering sets the equipment to In Maintenance, and equipment with open maintenance cannot be assigned. Post a record to lock it and copy it to a read-only maintenance history. Posting the last open record sets the equipment back to Available.
- Track costs: total, average and percentage of the purchase cost on the equipment list, and cost tiles and charts on the dashboard. The total counts posted maintenance only.
- Plan maintenance with a frequency in months and a last maintenance date. The next maintenance date is calculated, and posting a Preventive record moves the last date forward. Overdue equipment is highlighted in red and counted on a tile. A daily job at 05:00 recalculates the dates.

### Warranty

- Record the warranty start date, end date, provider and reference. The warranty status is Active, Expiring Soon or Expired, calculated from the end date.
- A warranty alert is created 90, 60 and 30 days before a warranty ends. Acknowledge alerts, or generate them on demand. Four warranty tiles show Active Warranties, Warranties Expiring in 90 Days, Warranties Expiring in 30 Days and Expired Warranties.

### Notifications and monitoring

- Notifications appear when a warranty is about to end, when a maintenance record has been open for more than 14 days, and when posting makes equipment available again. Switch each kind off with Don't show again or in My Notifications.
- The app creates daily job queue entries for the warranty alerts and the overdue maintenance check. Equipment Setup shows their status, and Schedule Monitoring Jobs creates missing entries.
- Administrators see failures in the new Equipment Error Log. Standard retention policies can delete old error log entries, closed warranty alerts and processed integration event entries. Nothing is deleted until a policy is turned on.

### Documents, notes and pictures

- Each piece of equipment can have one picture. Attach files such as invoices, maintenance reports, warranty certificates, user manuals and delivery notes, and set a category for each.
- Record dated notes on equipment. Notes cannot be changed or deleted, and equipment that has notes can no longer be deleted.

### Integration and API

- Other systems can read and maintain equipment, read categories and assignment history, and assign or return equipment through Business Central APIs (version 1.0).
- Turn on Integration Events Enabled on Equipment Setup to record an entry for each business event. External systems read the entries through the API and mark them as processed.
- Two Power Automate events, Equipment assigned and Warranty expiring, start flows under the category Equipment Management.

### Requests and approvals

- Employees can be given equipment through requests. A manager sends an open request for approval, another manager approves or rejects it with a reason, and an approved request is completed with Assign Equipment. Rejected and completed requests cannot be changed.

### Audit

- Every piece of equipment has a read-only audit trail of created, updated, assigned, returned, sent to maintenance and disposed events.
- The standard Change Log can track the category, status, assigned employee and warranty fields. An administrator turns it on.
- Every maintenance record has a permanent log of who registered, changed and posted it, with the old and new value of each corrected field.

### Dashboards and reports

- The Equipment Dashboard and the Equipment Manager role center show tiles and charts for equipment, operational indicators, warranty, planned maintenance and maintenance costs.
- Four Excel reports: Equipment Register, Asset Utilization, Maintenance Cost Analysis and Usage Analytics.

### Configuration

- Equipment Setup holds number series, the default warranty alert days, the default maintenance frequency and three switches for notifications, requests and the APIs.
- Equipment Features turns the optional features on or off for each company: Equipment Images, Warranty Alerts, Approval Workflows, API Integration, Maintenance Planning and Notifications.
- Administrators can create sample data in a new company with Create Demo Data, and remove it with Delete Demo Data.
- On upgrade, a blank Default Warranty Alert Days is set to 90.

### Localization

- The app is available in Portuguese (Portugal) and Spanish (Spain), in addition to English. The maintenance log shows dates, costs and maintenance types in your regional format.

### Security and compliance

- Five permission sets: Equipment Reader, Equipment Operator, Equipment Manager, Equipment Administrator and Equipment API Consumer. All users also need D365 BASIC.
- The data classification of the fields is documented. An administrator can mark employee numbers as personal data.
- Administrators can turn on telemetry for the environment. The signals contain no customer data.
- Large registers respond faster. The list and dashboard target is less than 3 seconds for up to 10,000 records, which is not yet measured.

### Documentation

- This user guide (FR-059) consolidates the per-feature help articles into one guide, in the order of an app documentation site. It has no screenshots and is not translated.

## What to know

- Contributor-only changes, such as tests, the build pipeline and code quality checks, do not change the app for users and are not listed.
- The version stays 29.0.0.0 for all changes until the first release.

## Related

- [Overview](README.md)

---
Previous: [Security and permissions](security-and-permissions.md)
