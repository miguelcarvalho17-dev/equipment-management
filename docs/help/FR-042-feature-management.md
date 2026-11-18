# Equipment Features (AppSource end-user help)

The Equipment Features page lets an administrator turn five optional parts of Equipment Management on or off for the current company. When a feature is off, its pages, fields, actions and tiles are hidden, and pages that belong only to that feature show an error when they are opened. Nothing is deleted. Turn the feature on again to see everything as before.

TODO(verify): this feature has not been tested in a sandbox. The wording of the error message, the empty list and the API error may differ slightly from the description below.

## The five features
| Feature | What it covers |
|---|---|
| **Equipment Images** | The picture panel on the Equipment Card and the Equipment List. |
| **Warranty Alerts** | The warranty alerts page, its action, its tile and the warranty notifications. |
| **Approval Workflows** | The equipment request process: the request pages, the approval actions and the Requests Pending Approval tile. |
| **API Integration** | The equipment API pages and the integration event settings and entries. |
| **Maintenance Planning** | The planned maintenance fields (last maintenance date, maintenance frequency and next maintenance date) and the planned maintenance tiles. |

## Before you start: permissions
- **Equipment Administrator** can turn features on and off.
- **Equipment Manager** and **Equipment Reader** can open the page and see the settings. They cannot change them.
- All five features are on until an administrator turns one off. The page lists them the first time an administrator opens it. Until then, a user who cannot change the settings sees an empty list. The features still work as usual.

## How to open the page
Use one of these:
- **Tell Me**: search for "Equipment Features".
- **Equipment Setup**: choose **Equipment Features** in the Navigation area.
- **Equipment Manager Role Center**: choose **Equipment Features** in the Setup section.

## Turn a feature on or off
1. Open **Equipment Features**.
2. In the **Enabled** column, select the check box to turn the feature on, or clear it to turn the feature off.
3. Close the page.

Each feature switches on its own. Turning one feature off does not change the others. The setting applies to the current company only. Another company keeps its own settings.

Users see the change the next time they open a page. A page that is already open keeps its state until it is opened again.

## What happens when a feature is off
- **Equipment Images:** the picture panel is hidden on the Equipment Card and the Equipment List. Pictures that are already stored are kept.
- **Warranty Alerts:** the **Warranty Alerts** action on the Equipment Card and the **Open Warranty Alerts** tile are hidden. The **Warranty Alert Job** field on Equipment Setup is hidden. The Warranty Alerts page shows an error when it is opened. No warranty notifications are sent, and the daily job creates no new warranty alerts. Warranty end dates and the warranty status stay visible.
- **Approval Workflows:** the **Equipment Requests** action on the Employee Card and the **Requests Pending Approval** tile are hidden. The Equipment Requests and Equipment Request Card pages show an error when they are opened. Requests cannot be sent for approval, approved, rejected or assigned while the feature is off. Existing requests are kept. Requests are never completed without approval.
- **API Integration:** the **Integration** group and the **Integration Events Enabled** field on Equipment Setup are hidden. The **Integration Event Entries** action is hidden, and its page shows an error when it is opened. The equipment API pages return an error. No integration event entries are written while the feature is off.
- **Maintenance Planning:** the **Planned Maintenance** group on the Equipment Card is hidden, with its three fields. The **Next Maintenance Date** column on the Equipment List is hidden, and so is the field on the Maintenance FactBox. The two **Planned Maintenance** tiles on the dashboard and the Role Center are hidden. The next maintenance date is still calculated.

## The error for a page that is off
When a page belongs to a feature that is off, opening it shows this message:

"The <feature> feature is turned off in this company. To use it, ask an administrator to turn it on in the Equipment Features page."

Choose **Open Equipment Features** to go to the page. An administrator can turn the feature on there.

## Good to know
- No data is deleted when a feature is turned off. Pictures, warranty alerts, equipment requests and integration event entries are kept. They appear again when the feature is turned on.
- Turning a feature off does not change equipment, assignments or maintenance records.
- The features are not a security setting. Permissions still decide who can see and change data.

## Known limitations
- **Tell Me still lists the pages of a feature that is off**, for example Warranty Alerts and Equipment Requests. Opening one shows the error above.
- **The Role Center actions Equipment Requests and Warranty Alerts stay visible** when their feature is off. Opening one shows the error above. The tiles of a feature that is off are hidden.
- **Pages that are already open** keep their state until they are opened again.
- **Users who cannot change the settings** see an empty list until an administrator has opened Equipment Features once.
- **If two administrators open Equipment Features for the first time at the same moment**, the page may close with an error. Open it again.

## Release notes
Equipment Management now lets an administrator turn five optional features on or off for each company: Equipment Images, Warranty Alerts, Approval Workflows, API Integration and Maintenance Planning. Open Equipment Features from Tell Me, Equipment Setup or the Equipment Manager Role Center. Nothing changes until you turn a feature off.
