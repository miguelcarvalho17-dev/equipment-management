# Approving Equipment Requests (AppSource end-user help)

An equipment request now goes through an approval process. A manager sends an open request for approval, another manager approves or rejects it, and an approved request is completed by assigning equipment to the employee. TODO(verify): this feature has not been tested in a sandbox; screen layout may differ slightly from the steps below.

## Before you start
- **Equipment Manager** and **Equipment Administrator** can send, approve, reject and assign.
- **Equipment Reader** can only view requests. The actions fail with a permission error for a Reader.
- You cannot approve a request that you sent for approval. Another manager must approve it, so you need at least two users with a manager role. You can still reject your own request.

## The process
| Status | Meaning | Next step |
|---|---|---|
| Open | The request was raised and can still be changed. | **Send for Approval** |
| Pending Approval | Waiting for a decision. | **Approve** or **Reject** (by another manager for Approve) |
| Approved | Approved. No equipment is assigned yet. | **Assign Equipment** |
| Rejected | Rejected. Final. | Raise a new request if needed. |
| Completed | Equipment was assigned. Final. | None |

Only Open requests can be changed or deleted.

## Send a request for approval
1. Open the request (card or list) and choose **Send for Approval**.
2. The status changes to **Pending Approval**. Your user name is shown in **Sent for Approval By**.

The employee and the equipment type must still be active. If not, you get an error and the request stays Open.

## Approve or reject
1. A different manager opens the request and chooses **Approve** or **Reject**.
2. Enter a comment and choose **OK**. For **Approve** the comment is optional. For **Reject** you must enter the reason.
3. The status changes to **Approved** or **Rejected**. **Decided By**, **Decision Date** and **Decision Comment** are filled in.

Choosing **Cancel** in the comment window changes nothing. A rejected request cannot be reopened.

## Assign equipment from an approved request
1. Open the Approved request and choose **Assign Equipment**.
2. Choose one of the available equipment items of the requested type and choose **OK**.
3. The equipment is assigned to the employee and the request becomes **Completed**. **Assigned Equipment No.** shows the equipment.

If no equipment of the requested type is available, a message tells you so and the request stays Approved. Assigning follows the normal assignment rules: the equipment must be available and not under maintenance, and the employee must be active. If a rule fails, you get an error and the request stays Approved. See the help for equipment assignment for details.

Equipment can still be assigned directly from the Equipment Card without a request.

## Find requests
On **Equipment Requests**, use the views at the top (**Open**, **Pending Approval**, **Approved**, **Rejected**, **Completed**). Add the **Decided By** and **Decision Date** columns through personalization if you need them.

## Common messages
- "You cannot approve equipment request X because you sent it for approval. Another manager must approve it.": ask another manager.
- "You must enter a comment to reject equipment request X.": enter the reason.
- "Equipment request X was rejected. A rejected request cannot be reopened; raise a new request instead."
- "You can only send equipment request X for approval when its status is Open." / "...approve or reject... Pending Approval.": the request has another status.
- "You cannot assign equipment for request X because its status is ... The request must be approved first."
- "You cannot assign equipment ... because its category ... is not the requested equipment type ...": choose equipment of the requested type.
- "There is no available equipment of type X.": none is free; try again later.
