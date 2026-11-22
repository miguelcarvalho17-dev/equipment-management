# Security and permissions

This article explains the five permission sets of Equipment Management, what each one allows, and how the app handles personal data. It is for administrators. TODO(verify): the roles are not checked in a sandbox, and the limits come from the permission design.

**In this article**
- [Permission sets](#permission-sets)
- [Who can do what](#who-can-do-what)
- [D365 BASIC](#d365-basic)
- [Assign a permission set](#assign-a-permission-set)
- [Data classification and personal data](#data-classification-and-personal-data)
- [Who can see the error log](#who-can-see-the-error-log)

## Permission sets

| Permission set | Give it to | What it allows |
|---|---|---|
| **Equipment Reader** | People who only look things up. | View equipment, categories, assignments, maintenance, warranty alerts, notes, requests, the audit trail and the setup. Change nothing. |
| **Equipment Operator** | People who do the daily equipment work. | Everything a Reader can, plus assign and return equipment, register and post maintenance, add notes, acknowledge and generate warranty alerts, and change existing equipment. |
| **Equipment Manager** | People who run the register. | Everything an Operator can, plus create equipment, work with requests and manage attachments. Cannot delete equipment, and cannot change categories or setup. |
| **Equipment Administrator** | The person responsible for the app. | Everything a Manager can, plus delete equipment, manage categories, setup and features, read the error log, use demo data, and delete processed integration entries. |
| **Equipment API Consumer** | An external system, not a person. | Access through the equipment APIs only. No page opens. |

Operator, Manager and Administrator include the Reader permissions, so assign only one of the sets. Assign Operator only to people who should not have Manager rights.

## Who can do what

| Task | Reader | Operator | Manager | Administrator |
|---|---|---|---|---|
| View equipment, history, alerts and reports | Yes | Yes | Yes | Yes |
| Assign and return equipment | No | Yes | Yes | Yes |
| Register and post maintenance | No | Yes | Yes | Yes |
| Acknowledge and generate warranty alerts | No | Yes | Yes | Yes |
| Add notes | No | Yes | Yes | Yes |
| Create equipment | No | No | Yes | Yes |
| Create, send, approve and reject requests | No | No | Yes | Yes |
| Add and change attachments | No | No | Yes | Yes |
| Delete equipment | No | No | No | Yes |
| Change categories, setup and features | No | No | No | Yes |
| Read and delete the error log | No | No | No | Yes |
| Create and delete demo data | No | No | No | Yes |

An Operator can change the fields of existing equipment, including the status and the description. Renaming equipment that has attachments fails with a permission error for an Operator. An Operator may not be able to change the equipment picture. TODO(verify): both limits are not checked in a sandbox.

Nobody can change or delete closed assignments, posted maintenance, maintenance history, log entries or notes, not even an administrator.

Equipment Readers see the actions **Assign to Employee** and **Return**, and a permission error appears when they use them. **Equipment Categories** and **Equipment Setup** open read-only for users who cannot change them.

## D365 BASIC

Every user of the app also needs the standard **D365 BASIC** permission set. It gives read access to employees, locations and number series. Without it, employee names are blank, and assigning equipment does not work because the employee list is not available.

The **Equipment Manager** role is the home page. It is not the same as the Equipment Manager permission set. Anyone can choose the role. What a user can change depends on the permission set.

## Assign a permission set

1. Choose the search icon, enter **Users**, and open the user.
2. On the **User Permission Sets** FastTab, add the Equipment permission set and **D365 BASIC**.

You can also add the set to a security group. See [Assign permissions to users and groups](https://learn.microsoft.com/dynamics365/business-central/ui-define-granular-permissions). For an external system, see [Using the API](using-the-api.md#get-access).

## Data classification and personal data

Every field of the app has a data classification. The user names of the people who act in the app, such as who assigned, posted or decided, are classified as end user identifiable information. Employee numbers are customer content. Free text, such as notes, comments and justifications, is customer content.

An administrator can mark the employee number fields as personal data in your environment:

1. Choose the search icon, enter **Data Classification Worksheet**, and choose the related link.
2. Choose **Find New Fields** to load the fields of the app.
3. Find the field, for example **Assigned Employee No.** on the equipment table.
4. Set **Data Sensitivity** to **Personal**, and apply the change.

Your choice applies to your environment only. Personal data that users type into free text is not found by the classification. Review it under your own privacy process. TODO(verify): the worksheet steps are not checked in a sandbox. See [Classify data sensitivity](https://learn.microsoft.com/dynamics365/business-central/admin-classifying-data-sensitivity).

The assignment history, the audit trail and the logs keep user IDs and employee numbers, and the app cannot remove them. The APIs do not return user names.

## Who can see the error log

Only users with the Equipment Administrator permission set can read and delete the entries of the equipment error log. The **Error Log** action on **Equipment Setup** is shown only to them. See [Notifications and monitoring](notifications-and-monitoring.md).

## What to know

- A user without a permission set gets a permission error when opening an equipment page.
- Partners can extend the permission sets with their own permission set extension.
- Retention policies need the SUPER or the Retention Policy Setup permission set. The app does not give it to any role.

## Related

- [Getting started](getting-started.md)
- [Using the API](using-the-api.md)
- Feature article: [Choosing a Permission Set for Equipment Management](../help/FR-036-permission-sets.md)
- Feature article: [Roles and permissions for equipment](../help/NFR-002-role-based-access.md)
- Feature article: [Equipment Operator: the permission set for day-to-day equipment work](../help/FR-057-permission-review.md)
- Feature article: [Data classification of the app](../help/FR-058-data-classification.md)
- Feature article: [Equipment error log](../help/FR-051-error-logging.md)

---
Previous: [Troubleshooting and FAQ](troubleshooting-and-faq.md) | Next: [Releases](releases.md)
