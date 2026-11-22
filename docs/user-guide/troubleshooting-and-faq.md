# Troubleshooting and FAQ

This article lists common issues with their causes and solutions, and answers frequent questions. It is for all users and administrators.

**In this article**
- [Common issues](#common-issues)
- [FAQ](#faq)

## Common issues

### The equipment setup is missing in a company

**Symptom:** A message says that the equipment setup has not been created in this company yet.

**Possible causes:** The company was created after the app was installed, and nobody with the Equipment Administrator permission set has opened **Equipment Setup** there.

**Solution:** Ask a user with the Equipment Administrator permission set to open **Equipment Setup**. The app then creates the setup, the number series, the starter categories and the daily jobs.

### Equipment Nos. is blank

**Symptom:** You cannot create equipment with an automatic number.

**Possible causes:** No number series is set in **Equipment Nos.** on **Equipment Setup**.

**Solution:** Ask an administrator to choose a number series. The same applies to **Maintenance Nos.** and **Request Nos.**

### Equipment cannot be deleted

**Symptom:** The app refuses to delete equipment.

**Possible causes:** The equipment is assigned, has assignment history, has maintenance records or has notes.

**Solution:** Set the status to **Disposed** instead. Equipment that is assigned must be returned first, but it still cannot be deleted afterwards if it has history.

### Equipment cannot be assigned

**Symptom:** **Assign to Employee** is not available, or the app shows an error.

**Possible causes:** The status is not Available (for example In Maintenance, Lost or Disposed). The equipment has an open maintenance record. The equipment is already assigned. The employee is not active, or is blocked for privacy reasons.

**Solution:** Post the open maintenance records. If the equipment is assigned, return it first. Choose an active employee who is not blocked for privacy reasons.

### A category cannot be deleted

**Symptom:** The app says that you cannot delete the category because equipment uses it.

**Possible causes:** One or more pieces of equipment use the category.

**Solution:** Clear **Active** on **Equipment Categories** instead.

### Duplicate serial number

**Symptom:** The app says that the serial number is already used by another piece of equipment.

**Possible causes:** A serial number can be used by one equipment record only.

**Solution:** Check the serial number, or find the other equipment with a filter on **Serial No.**

### The warranty end date is not accepted

**Symptom:** The app says that the end date must be later than the start date.

**Possible causes:** Both dates are filled in, and the end date is the same as or earlier than the start date.

**Solution:** Change one of the dates, or clear the date that is not known. To move a warranty later, change the end date first.

### A page shows that a feature is turned off

**Symptom:** The page shows that the feature is turned off in this company.

**Possible causes:** An administrator turned the feature off on **Equipment Features**.

**Solution:** Ask an administrator to turn the feature on. See [Setup and configuration](setup-and-configuration.md).

### You cannot approve your own request

**Symptom:** The app says that you cannot approve the request because you sent it for approval.

**Possible causes:** The user who sends a request for approval cannot approve it.

**Solution:** Ask another manager to approve it. You can reject your own request.

### Employee names are blank

**Symptom:** The name columns of employees are blank, although the employee number is shown.

**Possible causes:** The user has no permission to read employees. The **D365 BASIC** permission set is missing.

**Solution:** Give the user the **D365 BASIC** permission set. See [Security and permissions](security-and-permissions.md).

### The daily jobs do not run or show Error

**Symptom:** No warranty alerts are created, or a job on **Equipment Setup** shows Error or **Not scheduled**.

**Possible causes:** The job was never created. The user who owns the job was disabled or lost permissions. The job failed.

**Solution:** Choose **Schedule Monitoring Jobs** for missing jobs. For a job in Error, open **Equipment Error Log** to read the error, fix the cause, and restart the job from **Monitoring Job Queue Entries**. See [Notifications and monitoring](notifications-and-monitoring.md).

### No notifications appear

**Symptom:** You see no warranty or maintenance notification.

**Possible causes:** An administrator turned off **Enable Notifications**. You switched the kind off in **My Notifications**. No open warranty alert exists yet. The record is new and not saved.

**Solution:** Check **Enable Notifications** on **Equipment Setup** and **My Notifications**. Choose **Generate Alerts** on **Warranty Alerts** if the daily job has not run.

### An API call is denied

**Symptom:** The API returns an error or a permission error.

**Possible causes:** The API Integration feature is off. The user or application has no suitable permission set. The Microsoft Entra application is not enabled in Business Central.

**Solution:** Turn on the feature, assign Equipment API Consumer and D365 BASIC to the application, and check that the application card is enabled. See [Using the API](using-the-api.md).

## FAQ

**Q:** Can equipment have several pictures?
**A:** No. Each piece of equipment has one picture. A new picture replaces the old one after you confirm.

**Q:** Can equipment be assigned to resources?
**A:** No. Equipment can be assigned to employees only.

**Q:** Does the app do depreciation or fixed asset accounting?
**A:** No. This is out of scope. **Total Assets Value** is the purchase cost, without depreciation.

**Q:** Is location tracking available?
**A:** Not yet. It is on the roadmap. Equipment has a **Location Code** field only.

**Q:** Which languages are available?
**A:** English, Portuguese (Portugal) and Spanish (Spain). See [Advanced scenarios](advanced-scenarios.md).

**Q:** Does Delete Demo Data remove my own records?
**A:** No. It deletes only the records that Create Demo Data added. It keeps demo equipment and employees to which you added your own data. See [Setup and configuration](setup-and-configuration.md#demo-data).

**Q:** What happens to data when the app is uninstalled?
**A:** See [Install and uninstall extensions](https://learn.microsoft.com/dynamics365/business-central/ui-extensions-install-uninstall). The job queue entries of the app are not deleted by removing it. Delete them on the **Job Queue Entries** page.

## What to know

- Error messages in the app name the record and say what to do. Read them before you contact support.
- Give an administrator the **Error Code** and the call stack from the **Equipment Error Log** when you report a job failure.

## Related

- [Setup and configuration](setup-and-configuration.md)
- [Security and permissions](security-and-permissions.md)
- Feature article: [Manage equipment status](../help/FR-003-equipment-status-management.md)
- Feature article: [Assignment history](../help/FR-006-assignment-history-tracking.md)
- Feature article: [Approving Equipment Requests](../help/FR-033-approval-workflow.md)
- Feature article: [Equipment Features](../help/FR-042-feature-management.md)
- Feature article: [Equipment error log](../help/FR-051-error-logging.md)
- Feature article: [Equipment notifications](../help/FR-017-equipment-notifications.md)

---
Previous: [Advanced scenarios](advanced-scenarios.md) | Next: [Security and permissions](security-and-permissions.md)
