# Equipment notes (AppSource end-user help)

You can record short notes on a piece of equipment, for example "28/06/2026 - Replacement charger issued." Each note shows when it was written, who wrote it and the text. Notes are listed newest first in **Equipment Notes** on the **Equipment Card**.

## Before you start: permissions
- **Equipment Reader**: can see notes. Cannot add notes.
- **Equipment Manager** and **Administrator**: can also add notes.
- Nobody can change or delete a note.

TODO(verify): permissions were not checked in a sandbox.

## What you can do
| Where | What it does |
|---|---|
| **Equipment Notes** section on the card | Lists the notes of the equipment, newest first. Type on the new line to add a note. |
| **Equipment Notes** action on the card | Opens the list of all notes of the equipment. Available once the equipment is saved. |

## Add a note
1. Open the equipment and save it first. On a new, unsaved equipment you cannot add notes and the action is disabled.
2. In **Equipment Notes**, go to the empty line at the end of the list and type the text in **Comment**. Maximum 250 characters.
3. Move to another line or field to save the note. **Created At** and **User ID** are filled in automatically.

TODO(verify): exactly where the empty line appears and when the note is saved were not checked in a sandbox.

If you leave the comment empty you get an error and no note is created. You cannot choose the date or the user. If the event happened on another day, write the date in the comment.

## Good to know
- Notes cannot be changed or deleted after they are saved. To correct a note, add a new one.
- You can add notes to equipment with any status, including Lost and Disposed.
- Equipment that has notes cannot be deleted. Set its status to Disposed instead.
- Renaming the equipment number: TODO(verify) that the notes follow the equipment; this is not confirmed yet.
- The standard **Notes** FactBox is separate. It is a free notepad that can be edited and deleted, and it is not controlled by the equipment roles. Use **Equipment Notes** when the record must be kept.
- Equipment Notes is on the Equipment Card only, not on the Equipment List.

## Release notes
Equipment notes: you can now record dated notes on a piece of equipment. Each note shows when it was written and by whom. Notes appear newest first in Equipment Notes on the Equipment Card and cannot be changed or deleted afterwards. Equipment that has notes can no longer be deleted; set its status to Disposed instead. Equipment Reader can see notes; Equipment Manager can also add them.
