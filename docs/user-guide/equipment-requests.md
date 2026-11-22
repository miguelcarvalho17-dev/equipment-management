# Equipment requests

This article explains how to request equipment for an employee, and how managers approve, reject and complete a request. It is for managers and administrators.

**In this article**
- [Open the requests](#open-the-requests)
- [Create a request](#create-a-request)
- [Request statuses](#request-statuses)
- [Send a request for approval](#send-a-request-for-approval)
- [Approve or reject a request](#approve-or-reject-a-request)
- [Assign equipment](#assign-equipment)
- [When Approval Workflows is off](#when-approval-workflows-is-off)

## Open the requests

1. Choose the search icon, enter **Equipment Requests**, and choose the related link. You can also choose **Equipment Requests** in the Equipment Manager role center.
2. Use the views at the top to see one status: Open, Pending Approval, Approved, Rejected or Completed.

To see the requests of one employee, open the employee card and choose **Equipment Requests** in the equipment group.

## Create a request

Creating, changing and deleting requests needs the Equipment Manager or Equipment Administrator permission set.

1. On **Equipment Requests**, choose **New**.
2. Fill in the fields of the **Equipment Request** card.
3. Leave **No.** blank to get the next number from the series, and close the card.

### General

| Field | Description |
|---|---|
| **No.** | The number of the equipment request. If you leave it blank, the next number from the Request Nos. series is used. |
| **Employee No.** | The employee the equipment is requested for. The employee must exist, be active and not be blocked for privacy reasons. |
| **Employee Name** | The name of the employee. |
| **Requested Equipment Type** | The type of equipment that is requested. Choose an active equipment category, for example Laptop or Monitor. |
| **Equipment Type Description** | The description of the requested equipment type. |
| **Justification** | Why the equipment is needed. A justification is required. |
| **Request Date** | The date the equipment was requested. The date cannot be later than today. If you leave it blank, the work date is used. |
| **Status** | The status of the request: Open, Pending Approval, Approved, Rejected or Completed. New requests are Open. Send an open request for approval; another manager approves or rejects it. Approved requests are completed by assigning equipment. Rejected and completed requests are final. Only open requests can be changed or deleted. |

### Approval

| Field | Description |
|---|---|
| **Sent for Approval By** | The user who sent the request for approval. This user cannot approve the request. |
| **Decided By** | The user who approved or rejected the request. |
| **Decision Date** | The date the request was approved or rejected. |
| **Decision Comment** | The comment entered when the request was approved or rejected. A rejection requires a comment. |
| **Assigned Equipment No.** | The equipment that was assigned to complete the request. |

New requests are Open. You can change or delete a request only while it is Open. The request number cannot be changed.

## Request statuses

| Status | Meaning | Next step |
|---|---|---|
| Open | The request was raised and can still be changed. | Send for Approval |
| Pending Approval | The request waits for a decision. | Approve or Reject |
| Approved | The request is approved. No equipment is assigned yet. | Assign Equipment |
| Rejected | The request is rejected. This status is final. | Raise a new request if needed. |
| Completed | Equipment was assigned. This status is final. | None |

## Send a request for approval

1. Open the request and choose **Send for Approval**.
2. The status changes to **Pending Approval**. Your user name is shown in **Sent for Approval By**.

The employee and the equipment type must still be active. If not, you get an error and the request stays Open.

## Approve or reject a request

You cannot approve a request that you sent for approval. Another manager must approve it, so you need at least two users with a manager role. You can reject your own request.

1. A different manager opens the request and chooses **Approve** or **Reject**.
2. Enter a comment, and choose **OK**. For **Approve**, the comment is optional. For **Reject**, you must enter the reason.
3. The status changes to **Approved** or **Rejected**. **Decided By**, **Decision Date** and **Decision Comment** are filled in.

If you choose **Cancel** in the comment window, nothing changes. A rejected request cannot be reopened.

## Assign equipment

1. Open the approved request and choose **Assign Equipment**.
2. Choose one of the available equipment items of the requested type, and choose **OK**.
3. The equipment is assigned to the employee, and the request becomes **Completed**. **Assigned Equipment No.** shows the equipment.

If no equipment of the requested type is available, a message tells you so, and the request stays Approved. The normal assignment rules apply: the equipment must be available and not in maintenance, and the employee must be active. You can still assign equipment from the equipment card without a request.

## When Approval Workflows is off

When an administrator turns off the Approval Workflows feature, the request pages, the actions and the **Requests Pending Approval** tile are hidden. The **Equipment Requests** action on the role center stays visible, and opening it shows an error. Requests cannot be sent, approved, rejected or assigned. Existing requests are kept, and they appear again when the feature is turned on. See [Setup and configuration](setup-and-configuration.md).

## What to know

- Equipment Readers can only view requests. The actions fail with a permission error for them.
- Equipment Operators cannot create, send, approve or reject requests.
- Only Open requests can be changed or deleted.
- The number series for requests is **Request Nos.** on **Equipment Setup**. If you get an error about it when you create a request, ask an administrator to choose a series.
- TODO(verify): the approval process is not checked in a sandbox, and the screen layout may differ.

## Related

- [Assignments](assignments.md)
- [Troubleshooting and FAQ](troubleshooting-and-faq.md)
- Feature article: [Equipment Requests](../help/FR-032-equipment-request-process.md)
- Feature article: [Approving Equipment Requests](../help/FR-033-approval-workflow.md)
- Feature article: [Equipment Features](../help/FR-042-feature-management.md)

---
Previous: [Assignments](assignments.md) | Next: [Maintenance](maintenance.md)
