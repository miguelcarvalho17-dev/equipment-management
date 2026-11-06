# Maintenance and equipment status (AppSource end-user help)

When you register maintenance, the equipment is marked **In Maintenance** and cannot be assigned. When the last open maintenance record is posted, the equipment becomes **Available** again.

## Before you start: permissions
- **Equipment Manager** (and Administrator) can register and post maintenance, which changes the status.
- **Equipment Reader** can see the status and the **Open Maintenance Records** count, but cannot register or post.

## What happens
1. **Register maintenance** (Equipment Card > **Register Maintenance**, or the **Equipment Maintenance** list). The equipment **Status** changes to **In Maintenance**. This also happens for work in the past.
2. While at least one maintenance record is **Open**, the equipment cannot be assigned. **Assign to Employee** is unavailable on the card.
3. **Post** the record when the work is done. When no other open record exists, the status changes to **Available**.

## Assigned equipment
If the equipment is assigned to an employee, you are asked to confirm. Choose **Yes** to return the equipment from the employee, close the assignment in the assignment history and set **In Maintenance**. Choose **No** to cancel: no maintenance is registered. After posting, the equipment is Available, not assigned; assign it again if needed.

While the question is open, other users who register, save or post maintenance for the same equipment or number series may have to wait.

## Good to know
- **Several open records:** the equipment stays In Maintenance until the last one is posted.
- **Changing the status by hand:** while a record is open, you cannot set **In Maintenance** equipment to **Available**; post the records instead. You can still set it to **Lost** or **Disposed**. Posting such a record afterwards does not change the status.
- **In Maintenance set by hand, without records:** allowed, and you can set it back to Available by hand.
- **Registered by mistake?** Records cannot be deleted or cancelled. Post the record, for example with cost 0 and a description saying it was cancelled. The equipment becomes Available.
- **Open Maintenance Records:** the **Maintenance** FactBox shows how many records of the equipment are open. Choose the number to see them.
- Pages do not refresh by themselves; refresh the Equipment Card to see the new status.
- If posting or registering fails, nothing changes: the record and the equipment stay as they were.
- Equipment that already had open records before this change cannot be assigned until those records are posted.

## Release notes
Registering maintenance now sets the equipment to In Maintenance, and equipment with open maintenance cannot be assigned. Posting the last open maintenance record sets the equipment back to Available. For assigned equipment you confirm first; the equipment is then returned from the employee. The Maintenance FactBox shows the number of open records.
