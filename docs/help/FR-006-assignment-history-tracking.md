# Assignment history (AppSource end-user help)

The app keeps a history of every assignment of equipment to an employee. History cannot be lost: closed assignments
cannot be changed, and equipment that has been assigned cannot be deleted.

## Before you start: permissions
Everyone with **Equipment Reader** can see the assignment history. Nobody can change a closed assignment, and equipment with assignment history cannot be deleted.

## View the history
- Equipment card or list: choose **Assignments**.
- Employee card: choose **Navigate > Equipment Assignments**.
- Or search for **Equipment Assignments**.
- Use the views **Active** and **Closed** to filter.

## What each assignment shows
| Field | Meaning |
|---|---|
| Equipment No. / Employee No. | The equipment and the employee. |
| Assignment Date | The **start date**: your work date when the equipment was assigned. |
| Closing Date | The **end date**: your work date when the equipment was returned or left the Assigned status. Blank while active. |
| Assigned By | The user who assigned the equipment. |
| Status | Active while assigned, Closed afterwards. |

Reassigning equipment means returning it and assigning it again, so you get two entries: the old one (Closed) and a new one (Active).

## Closed assignments cannot be changed
Once an assignment is closed it is kept as it is. The page is read-only, and a change from any other source is refused with a message.

## Deleting equipment
- Equipment that is **Assigned** cannot be deleted. Return it first.
- After the return, the equipment has assignment history and still cannot be deleted. You get the message that it has assignment history.
- Set the status to **Disposed** instead. The equipment and its history stay in the system.
- Equipment that was never assigned can be deleted.
- If the equipment is already **Disposed** or **Lost**, there is nothing more to do when the delete is refused; the equipment stays as it is.
- If you get the history message for equipment that is not assigned and has no entries in the Closed view, assign it to an employee and return it, then set it to Disposed.

## Renaming
If you change the number of equipment or of an employee, the history entries show the new number.

## Privacy
The history keeps employee numbers and user names and cannot be removed from within the app.

## Release notes
Assignment history is now protected. Every assignment is kept with its start date (Assignment Date), end date (Closing Date) and the user who assigned it. Closed assignments cannot be changed, and equipment that has ever been assigned cannot be deleted; set it to Disposed instead.
