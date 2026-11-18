# Application Setup (AppSource end-user help)

The Equipment Setup page is where an administrator configures Equipment Management for the current company. It has two groups of settings: Defaults, for the warranty alert window and the maintenance frequency of new equipment, and Features, for three switches: Enable Notifications, Enable Equipment Requests and Enable APIs. Nothing is deleted when a setting is changed.

TODO(verify): this feature has not been tested in a sandbox. The wording of the messages and the behaviour of blank fields may differ slightly from the description below.

## Before you start: permissions
- **Equipment Administrator** can change the settings.
- **Equipment Manager** and **Equipment Reader** can open the page and see the settings. They cannot change them.

## How to open the page
Use **Tell Me**: search for "Equipment Setup".

## Defaults

### Default Warranty Alert Days
This field sets how many days before the warranty end date the warranty alerts start. It is visible only when the Warranty Alerts feature is on.
- Allowed values: **1 to 90**. The default is **90**.
- Alerts are created 90, 60 and 30 days before the end date, as far as these fall within the number of days. For example, with 30 only the 30-day alert is created.
- A setup created before this change can show the field blank. The app then uses 90 days, as before. You cannot enter 0 to blank the field; the app shows an error.
- If you lower the number, open alerts stay open, even when they are outside the new window.

### Default Maintenance Frequency (Months)
This field sets the maintenance frequency that new equipment gets when you create it on the Equipment Card. It is visible only when the Maintenance Planning feature is on.
- Allowed values: **0 to 120 months**. The default is **0**, which means no default.
- The default is applied when you start a new equipment record on the card. You can change or clear it before you save.
- The default is applied even when the Maintenance Planning feature is off. The field is then hidden on the card, so the frequency is set without being visible.
- The default is not applied to equipment that already exists. It is also not applied to equipment created through the API, by code or by a configuration package.

## Features

Three switches turn optional features on or off for the current company. Each switch is the same setting as a feature on the Equipment Features page.

| Switch | Same setting as | What it does when it is off |
|---|---|---|
| **Enable Notifications** | Notifications | No equipment notification is shown to any user in the company: on the Equipment Card, the Maintenance Record Card, the Role Center, or when equipment comes back from maintenance. Each user can still turn single notifications off in My Notifications. |
| **Enable Equipment Requests** | Approval Workflows | The Equipment Requests pages, actions and tile are hidden. Existing requests are kept. |
| **Enable APIs** | API Integration | The equipment APIs return an error. The integration settings are hidden. No integration event entries are written. |

- Only the Equipment Administrator can change the switches.
- Changes apply the next time a page is opened. A page that is already open keeps its state until it is opened again.
- The settings apply to the current company only. Another company keeps its own settings.
- Turning Enable Notifications off does not change business events, integration events, job queue jobs or telemetry.

## Good to know
- Turning a setting off does not change equipment, assignments, maintenance records or warranty alerts that already exist.
- The Equipment Features page lists six features. Enable Notifications is the new one.
- The setup page and the Equipment Features page show the same settings. A change on one page appears on the other when it is opened again.

## Known limitations
- **A blank Default Warranty Alert Days** can exist only in setups created before this change. It behaves as 90 days.
- **The maintenance default is not applied** to equipment created through the API, by code or by a configuration package.
- **Pages that are already open** keep their state until they are opened again.

## Release notes
Equipment Setup now has a Defaults group and a Features group. Set the Default Warranty Alert Days (1 to 90, 90 by default) to choose how early warranty alerts start. Set the Default Maintenance Frequency (in months) to have new equipment start with that frequency on the Equipment Card. Use the three switches to turn notifications, equipment requests and the APIs on or off for the company.
