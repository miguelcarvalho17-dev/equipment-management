# Equipment Requests (AppSource end-user help)

Use equipment requests to record that an employee needs equipment: which type, why, and when it was asked for. Each request gets a number. In this version a request is only recorded: its status is always **Open**, and there is no approval step yet. TODO(verify): this feature has not been tested in a sandbox; screen layout may differ slightly from the steps below.

## Before you start
- **Equipment Manager** and **Equipment Administrator** can create, change and delete requests.
- **Equipment Reader** can only view requests.
- The number series for requests is set in **Equipment Setup** (**Request Nos.**). New installations fill it automatically. If you get an error about **Request Nos.** when you create a request, ask an administrator to choose a number series there.

## Open the list
Search for **Equipment Requests**, or choose **Equipment Requests** in the Equipment Manager Role Center. The list shows the newest request first. Use the views at the top (**Open**, **Pending Approval**, **Approved**, **Rejected**, **Completed**) to see requests with one status. At present all requests are Open.

To see the requests of one employee, open the **Employee Card** and choose **Equipment Requests** in the equipment group.

## Raise a request
1. On the **Equipment Requests** page, choose **New**.
2. In **Employee No.**, choose the employee who needs the equipment. The employee must be active and not blocked for privacy reasons.
3. In **Requested Equipment Type**, choose an equipment category (for example Laptop). Only active categories can be chosen.
4. In **Justification**, enter why the equipment is needed. This is required.
5. Leave **Request Date** as it is (today's work date) or enter an earlier date. A date in the future is not accepted.
6. Leave **No.** blank to get the next number automatically, then close the card.

## Change or delete a request
Open the request and change the fields, or delete it from the list. This works only while the status is **Open**. A request with any other status is locked and shows an error if you try to change or delete it. The request number cannot be changed.

## Statuses
| Status | Meaning |
|---|---|
| Open | The request was raised. It can be changed or deleted. All requests are Open in this version. |
| Pending Approval, Approved, Rejected, Completed | Reserved for the approval process, which is planned for a later version. Requests with these statuses are locked. |

## Common messages
- "You cannot raise an equipment request for employee X because the employee status is ...": the employee is not active.
- "You cannot request equipment type X because the category is not active.": choose another category or ask an administrator to activate it on **Equipment Categories**.
- "You must enter a justification for the equipment request.": fill in **Justification**.
- "The request date ... is in the future.": enter today's date or earlier.
