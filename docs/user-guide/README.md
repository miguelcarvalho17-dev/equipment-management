# Equipment Management user guide

Applies to Equipment Management 29.0.0.0, which is not released yet. The steps are not verified in a Business Central sandbox.

This guide explains how to use Equipment Management in Business Central. It is for the people who use the app every day, for managers, for administrators and for integrators.

**In this article**
- [What the app does](#what-the-app-does)
- [Who this guide is for](#who-this-guide-is-for)
- [Key concepts](#key-concepts)
- [Contents](#contents)

## What the app does

Companies hand out equipment to employees every day: laptops, phones, tablets, monitors, tools and vehicles. When this information lives in separate spreadsheets, nobody knows for sure who has an item. Maintenance is done late and warranties expire unnoticed.

Equipment Management keeps this information in Business Central, where your employees, permissions and reports already are. With the app you can:

- Register equipment and group it by category.
- Assign equipment to employees and return it, and keep a history of every assignment.
- Register and post maintenance, plan recurring maintenance and see what is overdue.
- Record warranties and get an alert before a warranty ends.
- Let employees request equipment, and let managers approve or reject the requests.
- Follow the key figures on a role center and in reports.
- Connect other systems through APIs, integration event entries and Power Automate.

## Who this guide is for

- **End users** who register, assign and maintain equipment.
- **Managers** who follow the figures, approve requests and run reports.
- **Administrators** who install the app, set it up, give permissions and watch the daily jobs.
- **Integrators** who connect other systems to the app.

Developers who want to extend the app should use the [developer documentation](../README.md) (FR-060).

## Key concepts

- **Equipment** is one item that you track, such as a laptop. Each item has a number, a description and a category.
- **Category** groups equipment, for example Laptop or Printer. Only active categories can be chosen for new equipment.
- **Status** shows where the equipment stands: Available, Assigned, In Maintenance, Disposed or Lost. Disposed and Lost are final.
- **Assignment** records that an employee has an item. When the item is returned, the assignment is closed and stays in the history.
- **Maintenance record** is the work done on an item. It is open until you post it. Posting locks the record and adds it to the **maintenance history**, which nobody can change.
- **Warranty alert** is a reminder that the warranty of an item ends in 90, 60 or 30 days.
- **Equipment request** asks for an item for an employee. It goes through an approval process before equipment is assigned.

## Contents

1. [Overview](README.md): this page.
2. [Getting started](getting-started.md): install the app and prepare users.
3. [Setup and configuration](setup-and-configuration.md): numbering, defaults, categories, features and demo data.
4. [Equipment register](equipment-register.md): create equipment and use the equipment card.
5. [Assignments](assignments.md): assign, return and review the history.
6. [Equipment requests](equipment-requests.md): request, approve and complete.
7. [Maintenance](maintenance.md): register, post and plan maintenance.
8. [Warranty](warranty.md): warranty data, status and alerts.
9. [Dashboards and role center](dashboards-and-role-center.md): tiles and charts.
10. [Reports](reports.md): the four Excel reports.
11. [Notifications and monitoring](notifications-and-monitoring.md): notifications, daily jobs and the error log.
12. [Audit and change tracking](audit-and-change-tracking.md): the audit trail, the change log and the maintenance log.
13. [Integration with other apps](integration.md): integration event entries and Power Automate.
14. [Using the API](using-the-api.md): the equipment APIs for integrators.
15. [Pages and UI reference](pages-and-ui-reference.md): every page, report and part.
16. [Advanced scenarios](advanced-scenarios.md): companies, large registers, languages, upgrades and telemetry.
17. [Troubleshooting and FAQ](troubleshooting-and-faq.md): common issues and answers.
18. [Security and permissions](security-and-permissions.md): permission sets and data protection.
19. [Releases](releases.md): what is in version 29.0.0.0.

---
Next: [Getting started](getting-started.md)
