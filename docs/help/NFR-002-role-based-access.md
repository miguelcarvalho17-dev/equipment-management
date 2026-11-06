# Roles and permissions for equipment (AppSource end-user help)

The app has three permission sets. Give each user the one that matches their work.

## Which role to give
| Permission set | Use it for | What the user can do |
|---|---|---|
| **Equipment Reader** | People who only look things up | Open the equipment list and card, assignment history, categories, setup and the dashboard. Cannot change anything. |
| **Equipment Manager** | People who run the equipment | Everything a Reader can, plus create and change equipment, change its status, assign it to an employee and return it. Cannot delete equipment. |
| **Equipment Administrator** | The person responsible for the app | Everything a Manager can, plus delete equipment, maintain categories and change the setup. |

Nobody can change or delete assignment history entries by hand, not even an administrator.

Maintenance: a Reader can see the maintenance history. Managers and Administrators can register maintenance, correct open records and post them. A posted record and the maintenance history cannot be changed or deleted by anyone, not even an administrator.

## Assign a permission set
1. Search for **Users** and open the user.
2. In **User Permission Sets**, add **Equipment Reader**, **Equipment Manager** or **Equipment Administrator**.
3. Also give the user the standard **D365 BASIC** set.

You can also add the set to a security group and put the users in that group.

## D365 BASIC is required
The Equipment sets do not give access to employees, locations or number series. Without D365 BASIC, a user still sees all equipment data, but the employee name columns are blank (the employee number is still shown), and assigning equipment does not work because the employee list is not available.

## What a Reader sees
- **Equipment Categories** and **Equipment Setup** open read-only.
- Actions such as **Assign to Employee** and **Return** are still shown. If a Reader uses them, a permission error appears when the change is saved, and nothing is changed.

## Equipment Setup in a new company
The first time **Equipment Setup** is opened in a company, an Equipment Administrator creates the default setup, number series and starter categories. If a Reader or Manager opens it first, a message asks them to contact a user with the Equipment Administrator permission set. Until the setup exists, new equipment cannot be created.

## Equipment Manager: role and permission set
The **Equipment Manager** role (the home page with the dashboard, chosen in **My Settings**) is not the same as the **Equipment Manager** permission set. Anyone can choose the role as their home page. What they can change depends on their permission set. For example, a Reader on that home page can open **New > Equipment**, but saving fails with a permission error.

## Related
- Register and assign equipment
- Equipment dashboard
