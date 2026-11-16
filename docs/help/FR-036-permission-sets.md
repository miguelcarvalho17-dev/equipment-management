# Choosing a Permission Set for Equipment Management (AppSource end-user help)

Equipment Management comes with four permission sets. Assign the one that fits the job. TODO(verify): this feature has not been tested in a sandbox; names and screens may differ slightly from the steps below.

## Which role for whom
| Permission set | Give it to | What it allows |
|---|---|---|
| Equipment Reader | People who only need to look things up | View equipment, categories, assignments, maintenance, warranty alerts, notes, requests, audit trail and setup. Change nothing |
| Equipment Manager | People who run the equipment day to day | Everything a Reader can, plus create and change equipment, assign and return it, register maintenance, handle warranty alerts, add notes, work with requests and attachments. Cannot delete equipment and cannot change categories or setup |
| Equipment Administrator | The person responsible for the app | Everything a Manager can, plus delete equipment, manage categories and setup, and clean up integration events |
| Equipment API Consumer | An external system (not a person) | Access through the Equipment API only: no pages open in Business Central. See below |

Managers and Administrators already include the Reader permissions, so assign only one of the three.

All roles also need the Business Central permission set **D365 BASIC** (it gives read access to employees, locations and number series that the app uses).

## Assign a role to a user
1. Open **Users** and select the user.
2. In **User Permission Sets**, add the Equipment permission set and **D365 BASIC**.

## Let an external system use the API
Use this for a sync tool, a CMDB or a mobile app that calls the Equipment API without a signed-in person.
1. Register the application in Microsoft Entra and note its application (client) ID.
2. In Business Central, search for **Microsoft Entra Applications** and create a card for that ID. Enable it.
3. In the card's permission sets, add **EQM - API Consumer** and **D365 BASIC**.

What the integration can do: read equipment, categories, assignments and integration events; create and change equipment; assign and return equipment; mark integration events as processed. It cannot delete equipment, change categories or setup, or open any page. Deleting equipment needs a user with Equipment Administrator.

Related Microsoft Learn pages: see the Business Central documentation on Microsoft Entra applications and on assigning permission sets.
TODO(verify): the exact names of the Entra application pages and the steps above were not checked in a sandbox.

## Good to know
- Users without a role get a permission error when they open Equipment pages.
- A user with only API Consumer and D365 BASIC is not meant to open Equipment List or Equipment Card; TODO(verify) that this is refused.
- The Role IDs (EQM - Reader, EQM - Manager, EQM - Administrator, EQM - API Consumer) are stable. Partners can extend them with their own permission set extension.

## Release notes
Permission sets: a new **Equipment API Consumer** permission set lets an external system use the Equipment API through a Microsoft Entra application without opening any page and without the right to delete equipment. Equipment Reader, Manager and Administrator are unchanged. Assign D365 BASIC together with any of them.
