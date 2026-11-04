# FR-006 Assignment History Tracking

> Status: REVISION 2, **APPROVED** by the user (decisions D1-D5 under "Risks and open questions" are final).
> Source: GitHub issue #12. Branch: `feature/FR-006-assignment-history-tracking`.
> No events report: FR-006 changes only this app's own objects (tables 50100 and 50103, codeunit 50106, permission set
> 50101) and subscribes to no standard events. al-event-finder is not needed.
> Scope: main app only. **No new objects, no schema change, no version bump** (app.json stays 29.0.0.0, as in FR-004 D9
> and FR-005). **No upgrade logic, no backfill.** **No automated tests** (D4; scenarios are a reference only).
> Workflow for FR-006: planner -> (human approves plan) -> developer -> reviewer -> **tester step SKIPPED** ->
> documenter -> appsource-validator.

## Goal
Every change of an equipment assignment is kept as a history entry with equipment, employee, start date, end date and
the user who assigned it. The history can never be lost: a closed entry cannot be changed or renamed, and equipment that
has any assignment history can no longer be deleted (it is set to Disposed instead). FR-004 and FR-005 already record and
close the entries; FR-006 adds these two hard rules.

### Requirement restated
- H-R1 Track all assignment changes: assigning, returning, and any other way equipment leaves Assigned (In Maintenance,
  Lost, Disposed). Reassignment is return + assign (FR-004 D1), so it produces two entries.
- H-R2 Each history record holds Equipment No., Employee No., Start Date, End Date, Assigned By.
- H-R3 A closed history entry cannot be modified.
- H-R4 History stays available after the equipment is reassigned, and (D2) is never deleted with its equipment.

### What FR-004 / FR-005 already deliver (reused, not duplicated)
| Requirement | Already covered by | Gap closed by FR-006 |
|---|---|---|
| H-R1 | Codeunit 50106 `UpdateAssignmentOnSave`, called from table 50100 OnModify: creates an Active entry on Available -> Assigned, closes it on Assigned -> anything else (Return, In Maintenance, Lost, Disposed). One-step reassignment is refused (FR-004 D1, `AlreadyAssignedErr`). | None. |
| H-R2 | Table 50103 "EQM Equipment Assignment": 2 "Equipment No.", 3 "Employee No.", 4 "Assignment Date" (= Start Date, WorkDate), 7 "Closing Date" (= End Date, WorkDate), 5 "Assigned By" (UserId); also 8 "Closed By", 6 Status. | None. Names stay; the mapping is documented (D1). |
| H-R3 | Indirect-only rights on table 50103 (EQM - Edit `Rimd`, Admin inherits); page 50104 read-only. Codeunit 50106 only modifies Active entries. | **Table-level rule:** Closed entries cannot be modified or renamed by anyone with triggers (new OnModify/OnRename in table 50103). |
| H-R4 | Returns close entries, never delete them (FR-005 D5). New assignments create new entries. History opens from equipment card/list and Employee Card. | **Equipment delete no longer deletes history:** equipment with any entry cannot be deleted (D2). Supersedes FR-004 D6 and FR-005 D7. |

## Approach and rejected alternatives
- Chosen:
  - **Immutability in table 50103 triggers** (OnModify and OnRename). Each reads the **stored** entry (separate record
    variable, `SetLoadFields`) and raises an error when its Status is Closed. Hard rule, no event, no IsHandled (D5).
    Covers every with-trigger write path (Modify(true), ModifyAll(..., true), Rename) from any app.
  - **Equipment delete refused when history exists (D2):** table 50100 OnDelete keeps its Assigned check first, then
    asks codeunit 50106 (new `HasAssignmentHistory`) whether any entry exists for the equipment and raises
    `DeleteHistoryExistsErr` telling the user to set the status to Disposed instead. Codeunit 50106 no longer deletes
    entries: `DeleteAssignments` and its label are removed, and the `d` right is removed from the codeunit's
    `Permissions` and from EQM - Edit (least privilege: nothing in the app deletes entries any more).
  - Field names and captions unchanged (D1); renames of equipment/employees cascade into history (D3).
- Rejected: a new history table or log next to table 50103. Duplicates FR-004 data; two sources of truth would drift.
- Rejected: BC Change Log. Per-company admin setting, logs field changes, not assignment periods.
- Rejected: enforcing H-R3 only through permissions (status quo). Does not stop SUPER or code with direct rights.
- Rejected: an `OnBeforeModifyEvent` subscriber on table 50103. It is our own table; the trigger is simpler.
- Rejected: checking `xRec` in OnModify. `xRec` is only reliable when the modify comes from a page; table 50100 already
  uses the stored-record pattern for the same reason.
- Rejected: locking Active entries. Not asked for; codeunit 50106 must still close them.
- Rejected: an OnDelete guard on table 50103. With D2 nothing in the app deletes entries and no permission set grants
  delete (direct or indirect), so a trigger would only add a check that trigger-less `DeleteAll(false)` skips anyway.
- Rejected: keeping two delete errors (leftover Active entry vs. Closed history). With D2 both cases end in "cannot
  delete"; one error with one instruction is clearer. `ActiveAssignmentExistsErr` is removed.
- Rejected: putting the history check inside codeunit 50106 as an error-raising procedure. The user asked for the rule
  on the Equipment table's OnDelete; the codeunit only answers the data question (it holds the table 50103 access), and
  the error and its label live with the other equipment delete error (`DeleteAssignedErr`).
- Rejected: renaming fields 4/7 to "Start Date"/"End Date" or changing captions (D1).
- Rejected: blocking renames of equipment/employees with history (D3).

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50103, pages 50100-50104, codeunits 50103-50106,
enums 50100-50101, page extension 50100, permission sets 50100-50102, permission set extension 50103. Test app: no
objects (test codeunits 50150-50155 reserved by FR-001, 50156-50157 by FR-004, all unbuilt).

**No new objects.**

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50103 | EQM Equipment Assignment | Modify (own) | OnModify/OnRename refuse changes to Closed entries; local procedure; one label; summary and Status tooltip text |
| Table | 50100 | EQM Equipment | Modify (own) | OnDelete refuses equipment with assignment history; new label `DeleteHistoryExistsErr` |
| Codeunit | 50106 | EQM Assignment Mgt. | Modify (own) | New `HasAssignmentHistory`; remove `DeleteAssignments` and `ActiveAssignmentExistsErr`; `Permissions` drops `d` |
| PermissionSet | 50101 | EQM - Edit | Modify | `tabledata "EQM Equipment Assignment" = Rimd` becomes `Rim` |

Not changed: tables 50101/50102, pages 50100-50104, codeunits 50103-50105, enums 50100/50101, page extension 50100,
permission sets 50100/50102, permission set extension 50103, `app/app.json`, `test/`.
Next free IDs (unchanged by FR-006): tables 50104, pages 50105, codeunits 50107, enums 50102, page extensions 50101,
permission sets 50104. Test app: next free test codeunit 50158, **reserved for FR-006 "EQM Assignment History Tests",
not built now (D4).**

### Table 50103 "EQM Equipment Assignment" (changes)

**Table `/// <summary>`** becomes:
"One entry per assignment of equipment to an employee: the assignment history. Entries are created and closed by the
app when equipment is assigned and returned or leaves the Assigned status; users cannot edit them. A closed entry can
never be modified or renamed. Entries are never deleted: equipment that has entries cannot be deleted."

**New label** (table `var` section):
- `ClosedEntryCannotBeChangedErr`: 'You cannot change assignment entry %1 for equipment %2 because the assignment is closed. Closed assignments are kept as history and cannot be changed.' Comment: '%1 = entry number, %2 = equipment number'.

**New local procedure `CheckEntryIsNotClosed(EntryNo: Integer)`**
1. Local variable `StoredAssignment: Record "EQM Equipment Assignment"`.
2. `StoredAssignment.SetLoadFields(Status, "Equipment No.")`.
3. If `StoredAssignment.Get(EntryNo)` and (`StoredAssignment.Status = StoredAssignment.Status::Closed`):
   `Error(ClosedEntryCannotBeChangedErr, EntryNo, StoredAssignment."Equipment No.")`.
4. Not found: do nothing.
- Doc comment: "Raises an error when the stored assignment entry is closed. Closed entries are history and cannot be
  changed." Param EntryNo: "The entry number of the stored entry to check."
- Hard rule: no event, no IsHandled (D5).

**New trigger OnModify**: `CheckEntryIsNotClosed(Rec."Entry No.")`.
- Active -> Closed (codeunit 50106 `CloseActiveAssignments`) passes, because the stored entry is still Active. Any later
  with-trigger modify of a Closed entry fails, including Closed -> Active and fields added by table extensions.

**New trigger OnRename**: `CheckEntryIsNotClosed(xRec."Entry No.")` (`xRec` holds the old, stored primary key).
- Active entries can still be renamed (no rule asked for; the app never renames entries).

**Field 6 Status: ToolTip** becomes:
'Specifies whether the assignment is active or closed. Equipment has at most one active assignment. The assignment is closed when the equipment is returned or its status changes from Assigned to another status. Closed assignments are kept as history and cannot be changed.'

**Unchanged:** fields 4 "Assignment Date" and 7 "Closing Date" (names, captions, tooltips; D1), keys, field groups. No
OnInsert / OnDelete trigger. Order in the object: `fields`, `keys`, `fieldgroups`, `var`, triggers (OnModify, OnRename),
procedure.

### Table 50100 "EQM Equipment" (changes)

**Trigger OnDelete** becomes (in this order):
1. Unchanged: if Status = Status::Assigned: `Error(DeleteAssignedErr, "No.", "Assigned Employee No.")`. Stays first: it
   is the more specific message for assigned equipment (which always has history too).
2. **New:** if `AssignmentMgt.HasAssignmentHistory("No.")`: `Error(DeleteHistoryExistsErr, "No.", Format(Status::Disposed))`.
   Hard rule (D2, D5), no event.
3. The call `AssignmentMgt.DeleteAssignments("No.")` is **removed** (the procedure no longer exists).
- Local variable `AssignmentMgt: Codeunit "EQM Assignment Mgt."` stays.
- Effect: only equipment that was never assigned can be deleted. Lost, Disposed and returned equipment with history
  stays in the database. Applies to Delete(true) from every source (card, list, API, code). Delete(false) bypasses it (R1).

**New label** (table `var` section, next to `DeleteAssignedErr`):
- `DeleteHistoryExistsErr`: 'You cannot delete equipment %1 because it has assignment history. To stop using the equipment, set its status to %2 instead.' Comment: '%1 = equipment number, %2 = Disposed status caption'.

**`DeleteAssignedErr`**: unchanged ('... Return the equipment first.'). After a return the user then gets
`DeleteHistoryExistsErr`; acceptable, each message is correct for its step. The documenter explains it in help.

Nothing else changes in table 50100 (no change to Rename: D3).

### Codeunit 50106 "EQM Assignment Mgt." (changes)
- **`Permissions`** becomes `tabledata "EQM Equipment Assignment" = rim, tabledata "EQM Equipment" = r` (`d` removed;
  nothing deletes entries).
- **Remove** `internal procedure DeleteAssignments(EquipmentNo: Code[20])` and its doc comment.
- **Remove** label `ActiveAssignmentExistsErr` (and the then-empty `var` section if nothing else is in it). Unused labels
  are analyzer warnings.
- **New `internal procedure HasAssignmentHistory(EquipmentNo: Code[20]): Boolean`**
  1. Local `EquipmentAssignment: Record "EQM Equipment Assignment"`.
  2. `SetCurrentKey("Equipment No.", Status)` (existing key `EquipmentStatus`); `SetRange("Equipment No.", EquipmentNo)`.
     No Status filter: Active and Closed entries both count (a leftover Active entry after trigger-less writes also blocks).
  3. `exit(not EquipmentAssignment.IsEmpty())`.
  - Doc comment: "Returns whether the equipment has any assignment entry, active or closed. Equipment with assignment
    history cannot be deleted." Param EquipmentNo: "The equipment number." Returns: "True when at least one entry exists."
- `UpdateAssignmentOnSave`, `CreateAssignment`, `CloseActiveAssignments`, both events: unchanged.
  `CloseActiveAssignments` modifies entries that are still Active in the database, so it passes the new table 50103 trigger.

### Permission set 50101 "EQM - Edit" (change)
- `tabledata "EQM Equipment Assignment" = Rimd` becomes `= Rim`. Everything else unchanged.

### app.json, translations
- No app.json change. The build regenerates `app/Translations/Equipment Management.g.xlf` (two new labels, one removed
  label, changed tooltip); commit it, never edit by hand.

## Data model and upgrade impact
- No schema change: no new tables, fields, enums or keys. Triggers, procedures, labels and one permission change only.
- DataClassification: nothing new.
- Upgrade codeunit: not needed (nothing released; no data transformation).
- Existing data: unaffected. Existing Closed entries become immutable and equipment that already has entries becomes
  undeletable from the first publish. Pre-FR-004 Assigned equipment without entries (FR-004 D10) can still be deleted
  once it is no longer Assigned, because it has no history.
- Volume: entries and equipment with history are kept forever (R4).

## Events
**Standard BC events: none.** No events report required.

Subscribed: none.

Published: **no new events, no signature changes.**
- Neither new rule has an IsHandled (D5): both are business rules from the issue/user, and in AppSource mode an
  IsHandled can be added later without a breaking change, while removing one is breaking.
- Existing `OnBeforeInsertAssignment` and `OnBeforeCloseAssignment` (codeunit 50106) remain the only points where partners
  fill their own fields; both run while the entry is not yet Closed in the database.

## Permissions
- **EQM - Edit (50101):** `tabledata "EQM Equipment Assignment"` from `Rimd` to `Rim` (no delete right any more, direct
  or indirect). EQM - Admin inherits it; no EQM set can delete entries.
- EQM - Read (50100), EQM - Admin (50102), extension 50103: unchanged.
- The table 50103 trigger reads table 50103 (every caller already has R or the codeunit's `r`). `HasAssignmentHistory`
  runs inside codeunit 50106 (`Permissions` includes read); users deleting equipment have EQM - Edit anyway.
- Help text (documenter): "Everyone with Equipment - Read can see the assignment history. Nobody can change a closed
  assignment, and equipment with assignment history cannot be deleted."

## Compatibility
- AppSource mode, development phase: nothing released, no baseline, no Obsolete handling needed.
- No new public surface. Removed `DeleteAssignments` is `internal` (no `internalsVisibleTo`), so no external caller.
- Behavior changes (would be breaking after a release, allowed now):
  - Modify(true) / ModifyAll(..., true) / Rename on a Closed entry raises `ClosedEntryCannotBeChangedErr`.
  - Deleting equipment with any assignment entry raises `DeleteHistoryExistsErr`; Closed entries are no longer deleted
    with their equipment. **Supersedes FR-004 D6 and FR-005 D7**, and FR-004 scenarios A22, A23b (and the
    `ActiveAssignmentExistsErr` path).
  - EQM - Edit loses the indirect delete right on table 50103.
- Trigger-less writes (Modify(false), Delete(false), ModifyAll/DeleteAll(false)) still bypass both rules (R1).
- Doc references to update (documenter, not developer):
  - New `docs/features/FR-006-assignment-history-tracking.md` and `docs/help/FR-006-assignment-history-tracking.md`:
    history content with the mapping **Start Date = Assignment Date, End Date = Closing Date** (D1); where to open it
    (equipment card/list "Assignments", Employee Card "Equipment Assignments", search "Equipment Assignments"); views
    Active/Closed; closed entries cannot be changed; reassignment = return + assign = two entries; equipment with
    history cannot be deleted, set it to Disposed; renaming equipment/employees updates the history (D3).
  - `docs/features/FR-004-equipment-assignment.md` and `docs/help/FR-004-equipment-assignment.md`: delete behavior (D6
    superseded), EQM - Edit rights now `Rim`, closed entries immutable.
  - `docs/features/FR-005-equipment-unassignment.md` and `docs/help/FR-005-equipment-unassignment.md`: D7 superseded.
  - `docs/help/FR-001-equipment-registration.md` and FR-001 feature doc: deleting equipment is refused when it has
    assignment history.
  - CHANGELOG: section `## FR-006 Assignment History Tracking (version stays 29.0.0.0, no bump)` at the top, plus a
    release-notes paragraph.
  - `docs/TODO.md`: sandbox checks for H12 (equipment rename with closed history) and for deleting equipment with
    history from the list and card.
  - Historical plans are not edited.

## Test scenarios
**No automated tests in this iteration (D4). No test codeunits, no `test/app.json` change; ID 50158 stays reserved and
unused. The tester step is skipped.** The list below is a reference for the user, who writes the tests later. The
developer and reviewer use it to check behavior by reading the code.

Conventions: "assign" = `AssignEmployee` on saved Available equipment with an Active, not privacy-blocked employee;
"return" = `UnassignEmployee` with a `[ConfirmHandler]` answering Yes. Assert dates against `WorkDate()` and users
against `UserId()`. After an expected error, re-read equipment and entries and assert they are unchanged. Tests that
write directly to table 50103 run with the test runner's default (SUPER) permissions unless stated.

History content (H-R1, H-R2) - regression of FR-004/FR-005
- H1 Given saved Available equipment E and employee P, when E is assigned to P, then exactly one entry exists for E with Equipment No. = E, Employee No. = P, Assignment Date (start) = WorkDate, Assigned By = current user, Status Active, Closing Date (end) blank, Closed By blank.
- H2 Given E assigned to P, when WorkDate is set to D2 and E is returned, then the entry has Status Closed, Closing Date = D2, Closed By = current user, and Assignment Date, Employee No., Assigned By unchanged.
- H3 Given E assigned to P, when Status is validated to In Maintenance (confirm Yes) and Modify(true) is called, then the entry is Closed with end date WorkDate. Repeat for Lost and Disposed (separately).

History after reassignment (H-R4)
- H4 Given E assigned to P1 and returned, when E is assigned to P2, then E has two entries: P1 Closed (start date, end date and users unchanged) and P2 Active; the P2 entry has the higher Entry No.
- H5 Given H4 and then E returned and assigned to P1 again, then E has three entries (P1 Closed, P2 Closed, P1 Active) and filtering on Employee No. = P1 returns two entries.
- H6 Given E assigned to P1, when `AssignEmployee(P2)` is called, then AlreadyAssignedErr is raised and the history still has exactly one entry (P1 Active).

Closed entries cannot be modified (H-R3) - new
- H7 Given a Closed entry X, when Employee No. (separately: Assignment Date, Closing Date, Assigned By, Closed By) is changed and Modify(true) is called, then ClosedEntryCannotBeChangedErr (entry no. of X, equipment no.) is raised and X is unchanged.
- H8 Given a Closed entry X, when Status := Active and Modify(true) is called, then ClosedEntryCannotBeChangedErr is raised and X stays Closed.
- H9 Given two Closed entries for E, when `ModifyAll("Closed By", 'OTHER', true)` is called on a filter for E, then ClosedEntryCannotBeChangedErr is raised and both entries are unchanged.
- H10 Given a Closed entry X, when X is renamed to an unused Entry No., then ClosedEntryCannotBeChangedErr is raised and X still exists under its old number.
- H11 Given an Active entry A (created by assigning), when E is returned, then A becomes Closed without error. Given an Active entry inserted directly by the test, when a field is changed and Modify(true) is called, then no error is raised (rule applies to Closed only).
- H12 Given equipment E (not Assigned) with one Closed entry, when E is renamed to E2 with Rename, then no error is raised and the entry's Equipment No. = E2 (D3). Same for renaming the employee: the entry's Employee No. follows.
- H13 (documents R1) Given a Closed entry X, when a field is changed and Modify(false) is called, then no error is raised. Known gap, pinned so a change is noticed.

Equipment delete with history (D2) - new
- H14 Given Available equipment E with two Closed entries, when E.Delete(true) is called, then DeleteHistoryExistsErr (E, Disposed caption) is raised, and E and both entries still exist.
- H15 Given Disposed (separately: Lost, In Maintenance) equipment E with Closed entries, when E.Delete(true) is called, then DeleteHistoryExistsErr is raised and nothing is deleted.
- H16 Given Assigned equipment E (one Active entry), when E.Delete(true) is called, then DeleteAssignedErr (E, employee) is raised, not DeleteHistoryExistsErr, and nothing is deleted.
- H17 Given Available equipment E with a leftover Active entry (inserted directly by the test) and no Closed entry, when E.Delete(true) is called, then DeleteHistoryExistsErr is raised and nothing is deleted.
- H18 Given Available equipment E that was never assigned (no entries), when E.Delete(true) is called, then E is deleted.
- H19 Given pre-FR-004-style equipment (Assigned without entry, created with trigger-less writes) that is returned, when Delete(true) is called, then it is deleted (no history exists).
- H20 Given E with Closed entries, when E is set to Disposed (confirm Yes) and saved, then E and all entries still exist and the entries are unchanged.
- H21 (documents R1) Given E with Closed entries, when E.Delete(false) is called, then E is deleted and its entries remain (orphan entries; known gap).
- H22 Given the equipment list page (TestPage) on equipment with history, when Delete is invoked (confirm Yes on the platform delete question), then DeleteHistoryExistsErr is shown and the record remains.

Availability and permissions
- H23 Given employee P with one Closed and one Active entry on different equipment, when page EQM Equipment Assignments is opened from the Employee Card action, then both entries are shown; view Closed shows only the closed one.
- H24 (`TestPermissions = Restrictive`) Given a user with EQM - Edit and D365 BASIC, when the user assigns and returns equipment, then entries are created and closed; when the same user calls Modify(true) or Delete(true) on an entry directly, then a permission error is raised.
- H25 (`TestPermissions = Restrictive`) Given a user with EQM - Read only, when page EQM Equipment Assignments is opened, then entries are visible and the page allows no insert, modify or delete.

Manual sandbox checks (for the user): open a closed entry on page 50104 (no field editable); rename equipment with
history (H12); delete equipment with history from the card and the list (error, nothing deleted); delete never-assigned
equipment (works); `.g.xlf` regenerated with the new labels, the new tooltip, and without `ActiveAssignmentExistsErr`.

## Risks and open questions
Decisions (approved by the user):
- **D1 (Q1):** keep field names and captions ("Assignment Date", "Closing Date"); document Start Date = Assignment Date,
  End Date = Closing Date.
- **D2 (Q2):** equipment that has any assignment entry (Active or Closed) cannot be deleted; the error tells the user to
  set the status to Disposed instead. Table 50100 OnDelete holds the rule; codeunit 50106 `HasAssignmentHistory`
  answers the data question. Entries are never deleted. Supersedes FR-004 D6 and FR-005 D7.
- **D3 (Q3):** renaming equipment or an employee updates the numbers in history entries through the TableRelation
  cascade; the history follows the record and stays linkable. No rename block.
- **D4 (Q4):** no automated tests now (as FR-004 D8 and FR-005); scenarios H1-H25 kept as reference; test codeunit 50158
  reserved, not built; tester step skipped.
- **D5 (Q5):** both new rules are hard: no event, no IsHandled.

Still open: none.

Risks:
- R1 Trigger-less writes (Modify(false), Delete(false), ModifyAll/DeleteAll(false), RapidStart without validation)
  bypass both rules, as all FR-001..FR-005 rules. Delete(false) on equipment leaves orphan entries (H21). Mitigated by
  permissions: no EQM set grants modify or delete on entries.
- R2 Active entries are not locked at table level; code with direct rights could change the employee of an Active
  entry and break the FR-004 invariant. Out of scope.
- R3 If the platform rename cascade (H12) ever ran OnModify on table 50103, renaming equipment or an employee with
  closed history would fail. Expected not to; verify in the sandbox.
- R4 Data grows without limit: equipment with history and its entries are kept forever; there is no archive or
  retention policy. Acceptable for equipment volumes; revisit if needed.
- R5 Privacy: entries keep employee numbers after the employee is deleted and store user names
  (EndUserIdentifiableInformation). Because entries are immutable and equipment with history cannot be deleted, there is
  no in-app way to remove or anonymise them. Mention in help/privacy notes; ties to the open TODO on personal-data
  classification. A future retention/anonymisation feature would need an explicit, permission-guarded path.
- R6 A leftover Active entry on non-Assigned equipment (only after trigger-less writes) now blocks deletion permanently;
  setting the equipment to Disposed does not close it (equipment was not Assigned). Repair = assign and return, then
  Disposed. Document in help.
- R7 Users deleting returned equipment first see nothing about history until they try; the two-step messages
  (`DeleteAssignedErr`, then `DeleteHistoryExistsErr`) are explained in help.
- R8 No automated tests (D4): regressions caught only by review and manual sandbox checks.
