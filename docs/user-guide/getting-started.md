# Get started with Equipment Management

This article explains how to install Equipment Management, what the installation creates and how to prepare your users. It is for administrators.

**In this article**
- [Prerequisites](#prerequisites)
- [Install the app](#install-the-app)
- [What the installation creates](#what-the-installation-creates)
- [Assign permission sets](#assign-permission-sets)
- [Choose the Equipment Manager role](#choose-the-equipment-manager-role)
- [Set up the app](#set-up-the-app)
- [Try the app with demo data](#try-the-app-with-demo-data)
- [Change your language](#change-your-language)
- [Next steps](#next-steps)

## Prerequisites

- Business Central online, version 29.0 or later.
- To install the app, you need the **D365 Extension Mgt.** user group or the **EXTEND. MGT. - ADMIN** permission set. See [Install and uninstall extensions](https://learn.microsoft.com/dynamics365/business-central/ui-extensions-install-uninstall).
- Every user of the app needs the standard **D365 BASIC** permission set, because the app reads employees, locations and number series.

## Install the app

The app is not listed on Microsoft Marketplace yet. TODO(verify): the installation steps are not checked in a sandbox.

1. Choose the search icon, enter **Extension Management**, and choose the related link.
2. Choose **Manage**, and then **Upload Extension**.
3. Select the app file, and choose **Deploy**.
4. Wait until the deployment status is **Success**.

When the app is listed on Marketplace, you can install it from the **Extension Marketplace** page instead.

## What the installation creates

The installation prepares each company so that you can start at once:

- The equipment setup, with number series for equipment (**EQUIP**), maintenance records and equipment requests.
- Starter categories: Laptop, Monitor, Mobile Phone, Tablet, Printer, Vehicle and Tool.
- Daily job queue entries that check warranties and maintenance. If the status of a job on **Equipment Setup** shows **Not scheduled**, choose **Schedule Monitoring Jobs**. See [Notifications and monitoring](notifications-and-monitoring.md).
- Change log rules for the equipment fields. The rules do nothing until an administrator turns on the change log. See [Audit and change tracking](audit-and-change-tracking.md).

A company that you create after the installation has no setup yet. An administrator creates it by opening **Equipment Setup**. See [Advanced scenarios](advanced-scenarios.md).

## Assign permission sets

Give each user one permission set that fits the job, and **D365 BASIC**.

| Permission set | For |
|---|---|
| Equipment Reader | People who only look things up. |
| Equipment Operator | People who do the daily equipment work. |
| Equipment Manager | People who run the register. |
| Equipment Administrator | The person responsible for the app. |
| Equipment API Consumer | An external system, not a person. |

See [Security and permissions](security-and-permissions.md) for what each set allows, and [Assign permissions to users and groups](https://learn.microsoft.com/dynamics365/business-central/ui-define-granular-permissions) for the steps.

## Choose the Equipment Manager role

The **Equipment Manager** role is a home page with tiles and charts. It does not give any permissions.

1. Choose the **Settings** icon, and then choose **My Settings**.
2. In the **Role** field, choose **Equipment Manager**.
3. Choose **OK**.

An administrator can also assign the role in **Profiles (Roles)**.

## Set up the app

The app has no assisted setup guide. You configure it on the **Equipment Setup** page.

1. Choose the search icon, enter **Equipment Setup**, and choose the related link.
2. Check the number series and the defaults.
3. Open **Equipment Features** and turn off the features that you do not need.

See [Setup and configuration](setup-and-configuration.md).

## Try the app with demo data

To try the app before you enter your own data, choose **Create Demo Data** on **Equipment Setup**. You can delete the demo data again with **Delete Demo Data**. See [Setup and configuration](setup-and-configuration.md#demo-data).

## Change your language

The app is available in English, Portuguese (Portugal) and Spanish (Spain). The language follows your Business Central language.

1. Choose the **Settings** icon, and then choose **My Settings**.
2. In the **Language** field, choose the language.
3. Choose **OK**, and then sign out and sign in again.

## Next steps

- [Setup and configuration](setup-and-configuration.md)
- [Equipment register](equipment-register.md)
- [Security and permissions](security-and-permissions.md)

## What to know

- A user without a permission set gets a permission error when opening an equipment page.
- The app is not released yet, and the steps are not verified in a sandbox.

## Related

- [Overview](README.md)
- [Security and permissions](security-and-permissions.md)
- Feature article: [Register and assign equipment](../help/FR-001-equipment-registration.md)
- Feature article: [Choosing a Permission Set for Equipment Management](../help/FR-036-permission-sets.md)
- Feature article: [Equipment Operator: the permission set for day-to-day equipment work](../help/FR-057-permission-review.md)
- Feature article: [Application Setup](../help/FR-043-application-setup.md)
- Feature article: [Change the language of Equipment Management](../help/FR-055-multi-language-support.md)
- Feature article: [Create and delete demo data (Equipment Management)](../help/FR-066-demo-data.md)
- Feature article: [Roles and permissions for equipment](../help/NFR-002-role-based-access.md)
- Learn: [Install and uninstall extensions](https://learn.microsoft.com/dynamics365/business-central/ui-extensions-install-uninstall)

---
Previous: [Overview](README.md) | Next: [Setup and configuration](setup-and-configuration.md)
