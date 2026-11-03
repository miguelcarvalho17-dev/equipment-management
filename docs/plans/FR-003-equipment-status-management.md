# FR-003 Equipment Status Management

> Status: REVISION 2, **APPROVED** by the user (decisions D1-D9 and answers Q1-Q5 below are final).
> Source: GitHub issue #7. Branch: `feature/FR-003-equipment-status-management`.
> No events report: FR-003 changes only this app's own objects. It does not touch standard BC behavior and subscribes
> to no standard events, so al-event-finder is not needed.
> Scope of this iteration: main app only. **No automated tests** (D7: the user writes them later; the scenario list
> below is a reference only). **No version bump** (D8: app.json stays 29.0.0.0). **No upgrade logic** (D1).
> Workflow for FR-003: planner -> developer -> reviewer -> **tester step SKIPPED** -> documenter -> appsource-validator.

## Goal
Every equipment record has exactly one current lifecycle status: Available, Assigned, In Maintenance, Lost or Disposed.
Lost and Disposed are final statuses: they can never be assigned, never be left again, and new equipment cannot start
in them. Available equipment never carries an employee. The rules are enforced in table 50100 (on validate and on
insert/modify), so they hold for pages, code and APIs alike. List and card show the status with a color, and the list
offers optional per-status views.

### Requirement restated, with final decisions
- Supported statuses (issue): Available, Assigned, In Maintenance, Lost, Disposed.
- FR-001 already has enum 50100 with Available (0), Assigned (1), Under Maintenance (2), Retired (3), `Extensible = true`,
  and the field Status (field 9) on table 50100 with `InitValue = Available`.
- Final statuses: **Lost and Disposed** (D3, D4). In this plan "final status" always means Lost or Disposed.
- Business rules and where each one is enforced:

| # | Rule | Interpretation | Enforced in (table 50100) | Overridable by partners? |
|---|---|---|---|---|
| BR1 | Only one active status per equipment at any time (issue) | Status is a single enum field, so a record always has exactly one value. No status history (D6). | Structural (one field) | n/a |
| BR2 | Disposed equipment cannot be assigned (issue) | A record whose current status is Disposed can never get Status = Assigned. | Status OnValidate, `CheckEquipmentConsistency` on modify, `AssignEmployee` guard | No (hard rule) |
| BR3 | Lost equipment cannot be assigned (issue) | Same as BR2 for Lost. | Same as BR2 | No (hard rule) |
| BR4 | Available equipment must not have an assigned employee (issue) | Generalized (D5): "Assigned Employee No." may only be filled when Status = Assigned, for every status. | `CheckAssignedEmployeeAllowed` (field validate and insert/modify) | No (hard rule, made hard in FR-003) |
| BR5 | Lost and Disposed are final (D3, D4) | Once saved as Lost or Disposed, the status cannot change to any other value. Other fields can still be edited. | Status OnValidate, `CheckEquipmentConsistency` on modify | Yes, only through the new event `OnBeforeCheckStatusTransitionAllowed` |
| BR6 | New equipment cannot be created as Lost or Disposed (Q3) | A record that is not yet in the database cannot have a final status. | Status OnValidate (new record), `CheckEquipmentConsistency` on insert; card hides the values on a new record | No (hard rule) |
| BR7 | Setting a final status asks for confirmation (D9) | One question when the status changes to Lost or Disposed; it also says the employee is removed when one is set. Without UI it defaults to Yes. | Status OnValidate | n/a |

- Existing FR-001 rules stay: an employee is required when Assigned; leaving Assigned with an employee for a non-final
  status (Available, In Maintenance) asks to confirm and clears the employee. Moving to Lost/Disposed clears the employee too (Q1).
- In Maintenance equipment can be assigned directly (Q5). All transitions between Available, Assigned and In Maintenance stay allowed.
- No undo for Lost/Disposed in the standard app (Q4): the confirmation and the partner event cover it.

## Approach and rejected alternatives
- Chosen:
  - **Enum (D1):** rename the two existing values in place and add one value. Ordinals stay the same:
    2 "Under Maintenance" becomes "In Maintenance", 3 Retired becomes Disposed, new 4 Lost. Stored data keeps its
    ordinal, so no data upgrade is needed. No obsoleting. Allowed because nothing is released (development phase).
  - **One local transition check** `CheckStatusTransitionAllowed(FromStatus, ToStatus)` in table 50100, called from the
    Status OnValidate (from = xRec.Status) and from `CheckEquipmentConsistency` on modify (from = the stored status).
    The stored status is authoritative, so direct field assignment without Validate cannot bypass the rules.
  - Hard rule "final status cannot become Assigned" (BR2, BR3) runs before the new IsHandled event; "final status
    cannot be left" (BR5) runs after it, so a partner can relax BR5 (for example an admin undo flow) but can never
    assign lost or disposed equipment.
  - **BR4 (D5):** the check "employee only when Assigned" in `CheckAssignedEmployeeAllowed` moves before the event, so
    it is always enforced. The existing event `OnBeforeCheckAssignedEmployeeAllowed` is **narrowed and renamed** to
    `OnBeforeCheckEmployeeIsEligible`: it now only lets partners skip the "employee is Active and not privacy blocked"
    checks. That still has a real use (for example assigning equipment to employees that are not Active, such as
    contractors on leave), so the event is kept rather than removed. The rename makes the narrowed meaning visible;
    allowed because nothing is released.
  - One internal helper `IsFinalStatus(Status)` (true for Lost and Disposed), shared by the table rules and the card.
  - **BR6 on the card (Q3):** two page controls bound to Status. On a new (unsaved) record a control with
    `ValuesAllowed = Available, Assigned, "In Maintenance"` is visible; on a saved record the normal Status control is
    visible. The table rejects final statuses on new records anyway.
  - UI: status color (StyleExpr) on list and card from one internal table procedure; five optional per-status views on
    the list, with no default filter (Q2); "Assign to Employee" disabled for Lost and Disposed.
- Rejected: obsoleting the old enum values with an upgrade codeunit (D1). Nothing is released, so it adds code and
  dropdown clutter for no benefit.
- Rejected: caption-only rename (keep names Under Maintenance/Retired). Names and captions would differ permanently.
- Rejected: removing `OnBeforeCheckAssignedEmployeeAllowed` entirely (D5). The eligibility checks (Active, privacy
  blocked) are still a reasonable partner override; only the BR4 part had to become hard.
- Rejected: an extra non-overridable "Available must not have an employee" check in `CheckEquipmentConsistency` (the
  revision 1 approach). Moving the existing check before the event enforces it for all statuses with no duplicated logic.
- Rejected: a status history table (D6). The issue asks for the current status only.
- Rejected: separate actions "Mark as Lost", "Dispose", "Send to Maintenance". The Status field already does this.
- Rejected: making the Status control non-editable on Lost/Disposed records. It would block partners that relax BR5
  through the event. The table error is enough.
- Rejected: Status non-editable on new cards (stay Available until saved). It would stop users from creating equipment
  directly as In Maintenance or Assigned, which is allowed.
- Rejected: an "after status changed" event. `OnAfterCheckEquipmentConsistency` and the platform field events cover it.
- Rejected: an interface on the status enum. Over-engineered for two final values.

## Objects
IDs in use (checked in `app/src`): tables 50100-50102, pages 50100-50103, codeunits 50103-50105, enum 50100,
permission sets 50100-50102, permission set extension 50103. FR-003 creates **no new objects**. Files stay where they are
(`app/src/Equipment/`). No `/test` changes, no `app.json` changes.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50100 | EQM Equipment Status | Modify (own) | Rename 2 and 3, add 4 Lost |
| Table | 50100 | EQM Equipment | Modify (own) | Transition rules, final statuses, new-record rule, confirm, event changes, helpers |
| Page | 50100 | EQM Equipment List | Modify (own) | Status style, five optional status views |
| Page | 50101 | EQM Equipment Card | Modify (own) | Status style, new-record Status control, Assign action disabled for final statuses |

Not changed: tables 50101/50102, pages 50102/50103, codeunits 50103/50104/50105, permission sets, permission set
extension, `app/app.json` (stays 29.0.0.0), `test/`.
Next free IDs after FR-003 (unchanged): app tables 50103, pages 50104, codeunits 50106, enums 50101, permission sets 50104.
Test range: FR-003 uses none (FR-001 reserved 50150-50155, not built).

### Enum 50100 "EQM Equipment Status" (changes)
Keep `Caption = 'Equipment Status'` and `Extensible = true`.

| Ordinal | Name | Caption | Change |
|---|---|---|---|
| 0 | Available | Available | none |
| 1 | Assigned | Assigned | none |
| 2 | "In Maintenance" | In Maintenance | renamed from "Under Maintenance" |
| 3 | Disposed | Disposed | renamed from Retired |
| 4 | Lost | Lost | new |

- Ordinals must not change. The dropdown follows ordinal order (Disposed before Lost); accepted, mention in help.
- Add a `/// <summary>` on the enum: "Lifecycle status of equipment. Lost and Disposed are final: they cannot be assigned,
  cannot be changed to another status, and cannot be used for new equipment."

### Table 50100 "EQM Equipment" (changes)

**Field 9 Status**
- ToolTip becomes: 'Specifies the lifecycle status of the equipment: Available, Assigned, In Maintenance, Lost or Disposed. To assign equipment to an employee, use the Assign to Employee action. Lost and Disposed are final statuses: the equipment cannot be assigned or change status again, and new equipment cannot start with them.'
- `InitValue = Available` unchanged.
- OnValidate is replaced by these steps, in this order:
  1. If `IsFinalStatus(Status)` and not `IsStoredRecord()`: Error(NewEquipmentFinalStatusErr, Format(Status)). (BR6)
  2. If Status <> xRec.Status: call `CheckStatusTransitionAllowed(xRec.Status, Status)`.
  3. If `IsFinalStatus(Status)` and Status <> xRec.Status (BR7):
     - If "Assigned Employee No." <> '': question = StrSubstNo(FinalStatusAssignedQst, "No.", "Assigned Employee No.", Format(Status));
       otherwise question = StrSubstNo(FinalStatusQst, "No.", Format(Status)).
     - If not `ConfirmManagement.GetResponseOrDefault(question, true)`: `Error('')`.
     - Set "Assigned Employee No." := '' (plain assignment).
     - Exit (skip step 4, so only one confirm is shown).
  4. Existing FR-001 logic unchanged: if Status <> Assigned and "Assigned Employee No." <> '', confirm
     StatusChangeRemovesEmployeeQst; No = `Error('')`; Yes = clear the employee.

**New local procedure `IsStoredRecord(): Boolean`**
- Returns false when "No." is blank. Otherwise reads a second EQM Equipment record with `SetLoadFields("No.")` and
  returns the result of `Get("No.")`.
- Doc comment: "True when this equipment already exists in the database (used to detect new records)."

**New local procedure `CheckStatusTransitionAllowed(FromStatus: Enum "EQM Equipment Status"; ToStatus: Enum "EQM Equipment Status")`**
1. Exit if FromStatus = ToStatus.
2. Hard rule (not skippable): if ToStatus = Assigned and `IsFinalStatus(FromStatus)`:
   Error(CannotAssignFinalStatusErr, "No.", Format(FromStatus)).
3. Raise `OnBeforeCheckStatusTransitionAllowed(Rec, FromStatus, ToStatus, IsHandled)`; exit if IsHandled.
4. If `IsFinalStatus(FromStatus)`: Error(StatusIsFinalErr, "No.", Format(FromStatus), Format(ToStatus)).
- All transitions among Available, Assigned and In Maintenance are allowed, and any of them may go to Lost or Disposed.
  Lost -> Disposed and Disposed -> Lost are blocked by step 4 like any other exit from a final status (D4).

**New internal procedure `IsFinalStatus(EquipmentStatus: Enum "EQM Equipment Status"): Boolean`**
- Returns true when EquipmentStatus is Lost or Disposed. `/// <summary>` doc comment.

**New internal procedure `GetStatusStyle(): Text`**
- Returns a page style name for Rec.Status: Available = 'Favorable', Assigned = 'Standard', In Maintenance = 'Ambiguous',
  Lost = 'Unfavorable', Disposed = 'Subordinate', any other value (partner extensions) = 'Standard'.
- `case` with an `else` branch. The style names are `Locked = true` labels with suffix `Tok` (e.g. `FavorableStyleTok`).

**Procedure `AssignEmployee(EmployeeNo)` (internal, changed)**
- New first step: if `IsFinalStatus(Status)`: Error(CannotAssignFinalStatusErr, "No.", Format(Status)).
  The guard does not depend on how xRec is set by the caller. Then the existing steps, unchanged.
- Doc comment: add "Raises an error when the status is Lost or Disposed."

**Procedure `CheckEquipmentConsistency(IsNewRecord)` (changed)**
- The stored-record read becomes `StoredEquipment.SetLoadFields("Assigned Employee No.", "Category Code", Status)`.
  New local variables `StatusChanged: Boolean` (false by default) and `StoredStatus: Enum "EQM Equipment Status"`.
  When not IsNewRecord and the stored record is found: `StatusChanged := StoredEquipment.Status <> Status` and
  `StoredStatus := StoredEquipment.Status`.
- New steps right after `CheckCategoryAllowed(CategoryChanged)`:
  - If IsNewRecord and `IsFinalStatus(Status)`: Error(NewEquipmentFinalStatusErr, Format(Status)). (BR6)
  - If StatusChanged: `CheckStatusTransitionAllowed(StoredStatus, Status)`.
- The remaining steps stay in the same order: serial no., `CheckAssignedEmployeeAllowed(EmployeeChanged)`, Assigned
  requires an employee, `OnAfterCheckEquipmentConsistency(Rec)` last. No separate BR4 step (BR4 is inside `CheckAssignedEmployeeAllowed`).
- Update the `/// <summary>`: mention the final-status rule for new records, the status transition check on modify,
  and that an employee is allowed only when Status = Assigned.

**Procedure `CheckAssignedEmployeeAllowed(CheckEmployeeIsActive)` (local, changed for D5)**
New order:
1. Exit if "Assigned Employee No." = ''.
2. Hard: if Status <> Status::Assigned: Error(EmployeeOnlyWhenAssignedErr, FieldCaption("Assigned Employee No."), Format(Status::Assigned)). (BR4, all statuses)
3. Hard: `Employee.SetLoadFields(Status, "Privacy Blocked")`; if not `Employee.Get("Assigned Employee No.")`:
   Error(EmployeeNotFoundErr, "Assigned Employee No.", "No."). (unchanged rule, now not skippable)
4. Exit if not CheckEmployeeIsActive.
5. Raise `OnBeforeCheckEmployeeIsEligible(Rec, IsHandled)`; exit if IsHandled.
6. Existing checks unchanged: privacy blocked -> EmployeePrivacyBlockedErr; Status <> Active -> EmployeeNotActiveErr.
- The old event call `OnBeforeCheckAssignedEmployeeAllowed` at the top of the procedure is removed, and its publisher
  declaration is replaced by `OnBeforeCheckEmployeeIsEligible` (see Events).

**New labels** (table 50100; full sentences with Comment):
- `CannotAssignFinalStatusErr`: 'You cannot assign equipment %1 because its status is %2.' Comment: '%1 = equipment number, %2 = status caption'.
- `StatusIsFinalErr`: 'You cannot change the status of equipment %1 to %3 because %2 is a final status.' Comment: '%1 = equipment number, %2 = current status caption, %3 = new status caption'.
- `NewEquipmentFinalStatusErr`: 'You cannot create equipment with the status %1. Create the equipment first, and then change its status.' Comment: '%1 = status caption'.
- `FinalStatusQst`: 'The status %2 is final. After you change equipment %1 to %2, you cannot change its status again. Do you want to continue?' Comment: '%1 = equipment number, %2 = status caption'.
- `FinalStatusAssignedQst`: 'Equipment %1 is assigned to employee %2. Changing the status to %3 removes the employee, and you cannot change the status again. Do you want to continue?' Comment: '%1 = equipment number, %2 = employee number, %3 = status caption'.
Existing labels are unchanged; `StatusChangeRemovesEmployeeQst` is still used for Assigned -> Available / In Maintenance.

**Events in the table**: see Events. Doc comments in the FR-001 style.

### Page 50100 "EQM Equipment List" (changes)
- Status column: `StyleExpr = StatusStyle`. New page variable `StatusStyle: Text`, set in a new `OnAfterGetRecord`
  trigger: `StatusStyle := Rec.GetStatusStyle()`.
- New `views` section with five optional views, each `Filters = where(Status = const(<value>))`, in this order:
  `Available` Caption 'Available'; `Assigned` Caption 'Assigned'; `InMaintenance` Caption 'In Maintenance';
  `Lost` Caption 'Lost'; `Disposed` Caption 'Disposed'.
- No default filter and no `SourceTableView`: the default view ("All") shows all equipment with all statuses (Q2).
- Actions unchanged.

### Page 50101 "EQM Equipment Card" (changes)
- Group Assignment, Status:
  - Existing control `Status`: add `StyleExpr = StatusStyle` and `Visible = IsSaved`. Keep its OnValidate (`UpdateControls()`).
  - New control `StatusNew` bound to `Rec.Status`, placed directly before `Status`: `ValuesAllowed = Available, Assigned, "In Maintenance"`,
    `Visible = IsNewRecord`, `StyleExpr = StatusStyle`, same OnValidate (`UpdateControls()`). No Caption/ToolTip on the control
    (inherited from the table field). Both controls are never visible at the same time.
  - New page variable `IsNewRecord: Boolean`, set in `UpdateControls()` as `IsNewRecord := not IsSaved` (use a separate
    variable rather than an expression in the property). `IsSaved` already exists (SystemCreatedAt <> 0DT).
    `UpdateControls()` already runs in OnNewRecord and OnAfterGetRecord, so no extra trigger code is needed.
- Action AssignToEmployee: `Enabled = CanAssign` instead of `IsSaved`.
  ToolTip becomes: 'Assigns the equipment to an active employee that you select. Not available for lost or disposed equipment.'
- New page variables `StatusStyle: Text` and `CanAssign: Boolean`. `UpdateControls()` adds, after the existing lines:
  `StatusStyle := Rec.GetStatusStyle()` and `CanAssign := IsSaved and not Rec.IsFinalStatus(Rec.Status)`.
- Unassign, the employee field editability and the employee lookup are unchanged.

### app/app.json
- **No change** (D8). Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf` (renamed captions, new value, labels, tooltips,
  views). Commit it; never edit it by hand.

## Data model and upgrade impact
- No new tables or fields. Field 9 keeps its ID, name and type. Enum ordinals 0-3 are unchanged; ordinal 4 is new.
- **Upgrade codeunit needed: no** (D1). Stored values are ordinals:
  - records with 2 (Under Maintenance) read as In Maintenance;
  - records with 3 (Retired) read as Disposed and from now on are final (D2 confirmed). Development sandboxes only.
- Existing records that already break BR4 (an employee on a non-Assigned status) can exist only after trigger-less
  writes. No data fix: the next Modify(true) raises EmployeeOnlyWhenAssignedErr; the user clears the employee.
- DataClassification unchanged (CustomerContent at table level).

## Events
Subscribed:
- None. FR-003 does not touch standard behavior.

Published (table 50100, Public; `[IntegrationEvent(false, false)]`, `local`, record passed by value):
- **New** `OnBeforeCheckStatusTransitionAllowed(Equipment: Record "EQM Equipment"; FromStatus: Enum "EQM Equipment Status"; ToStatus: Enum "EQM Equipment Status"; var IsHandled: Boolean)`, **with IsHandled**.
  - Raised only when the status really changes (FromStatus <> ToStatus), after the hard rule "final status cannot become Assigned" passed.
  - Raised on Status validate (FromStatus = previous value) and again on modify when the stored status differs
    (FromStatus = stored status). Subscribers must tolerate two calls for one change.
  - Not raised on insert (new records have no transition; BR6 is checked separately and is not skippable).
  - IsHandled = true skips the rule "Lost and Disposed are final". It is the only way to leave a final status (D3, D4, Q4).
    It cannot allow a Lost or Disposed record to become Assigned.
  - Subscribers that leave IsHandled false can raise their own error to block a transition (for example rules for a
    partner enum value).
  - Doc comment: "Raised before the standard status transition rules run, when the status changes."
    FromStatus: "The current status (the previous value on validate, the stored value on modify)." ToStatus: "The new status."
    IsHandled: "Set to true to skip the standard transition rules, such as Lost and Disposed being final. Lost and disposed equipment still cannot be assigned."
- **Replaced (D5)** `OnBeforeCheckAssignedEmployeeAllowed(Equipment; var IsHandled)` is **removed** and replaced by
  `OnBeforeCheckEmployeeIsEligible(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)`, with IsHandled.
  - Raised only when an employee is filled in, the status is Assigned, the employee exists, and the employee is new or
    changed (validate, insert, or a different employee on modify).
  - IsHandled = true skips only the "employee is Active" and "employee is not privacy blocked" checks.
  - Not skippable any more: employee only when Assigned (BR4), employee must exist, Assigned requires an employee.
  - Doc comment: "Raised before the checks that the assigned employee is Active and not blocked for privacy reasons."
    IsHandled: "Set to true to allow an employee that is not Active or is privacy blocked. The employee must still exist, and an employee is only allowed when the status is Assigned."
- Unchanged: `OnBeforeCheckSerialNoIsUnique`, `OnBeforeCheckCategoryIsActive`, `OnAfterCheckEquipmentConsistency`.

## Permissions
- No new objects, so no permission set changes. Changing status uses the existing `tabledata "EQM Equipment" = M` in
  EQM - Edit (and Admin by inclusion). EQM - Read users see the views and colors but cannot change status.
- Help text (documenter): "Changing the status needs the Equipment - Edit permission set."

## Compatibility
- AppSource mode, development phase: nothing is released, no baseline, no dependent apps. The user decided (D1, D5)
  that no Obsolete handling is needed in this phase.
- Changes that would be **breaking after a release** (allowed now only because nothing is released):
  - enum value renames "Under Maintenance" -> "In Maintenance" and Retired -> Disposed;
  - removal of event `OnBeforeCheckAssignedEmployeeAllowed` (replaced by `OnBeforeCheckEmployeeIsEligible` with a narrower meaning).
- Additive: enum value 4 Lost, event `OnBeforeCheckStatusTransitionAllowed`, internal procedures.
- Behavior changes (for the changelog):
  - Status captions: Under Maintenance -> In Maintenance, Retired -> Disposed; new status Lost.
  - Lost and Disposed are final: they cannot be assigned, cannot be changed, and need confirmation when set.
  - New equipment cannot be created as Lost or Disposed; the card offers only Available, Assigned and In Maintenance on a new record.
  - An employee is allowed only when the status is Assigned, with no partner override; a missing employee record can no longer be skipped by a partner either.
- Doc references to update (documenter, not developer):
  - `docs/features/FR-001-equipment-registration.md`: enum row (line with "Available, Assigned, Under Maintenance, Retired"),
    the Behavior section for Status, and the "Extending (events)" table (replace `OnBeforeCheckAssignedEmployeeAllowed`
    with `OnBeforeCheckEmployeeIsEligible`, add `OnBeforeCheckStatusTransitionAllowed`).
  - `docs/help/FR-001-equipment-registration.md` lines 34-35 (status change question now differs for Lost/Disposed).
  - `CHANGELOG.md`: the 29.0.0.0 entry is history and stays; record the FR-003 changes (including the event replacement) in a new section (see open item O1).
  - Historical plans (`docs/plans/FR-001-*.md`, `docs/plans/FR-002-*.md`) are not edited; R7 covers their test specs.
- Internal, not API: `CheckStatusTransitionAllowed`, `IsStoredRecord` (local), `IsFinalStatus`, `GetStatusStyle` (internal). No `internalsVisibleTo`.

## Test scenarios
**No automated tests in this iteration (D7). No test codeunits, no `test/app.json` change, no test-app IDs. The tester
step is skipped.** The list below is a reference for the user, who writes the tests later. The developer and reviewer use
it to check behavior by reading the code.

Conventions for whoever implements them later: confirms answered by a `[ConfirmHandler]` that also records the question;
a test that expects no confirm has no handler; after an expected error, re-read the record and assert it is unchanged.
"Saved as X" means the status was validated to X (with Yes to the confirm for Lost/Disposed) and Modify(true) was called.

Enum
- S1 Given enum "EQM Equipment Status", when its ordinals and names are read, then they are 0 Available, 1 Assigned, 2 In Maintenance, 3 Disposed, 4 Lost, and the captions match.

Final statuses cannot be assigned (BR2, BR3; one test per status)
- S2 Given equipment saved as Lost (and, separately, Disposed), when Status is validated to Assigned, then CannotAssignFinalStatusErr (equipment no., status) is raised and the stored status is unchanged.
- S3 Given equipment saved as Lost (Disposed), when Status := Assigned and an active employee are set by direct assignment and Modify(true) is called, then CannotAssignFinalStatusErr is raised.
- S4 Given equipment saved as Lost (Disposed), when the card is opened, then the action Assign to Employee is disabled; when `AssignEmployee` is called from code, then CannotAssignFinalStatusErr is raised.

Final statuses cannot be left (BR5; D4)
- S5 Given equipment saved as Lost, when Status is validated to Available, In Maintenance or Disposed (one test each), then StatusIsFinalErr (equipment no., Lost, new status) is raised.
- S6 Given equipment saved as Disposed, when Status is validated to Available, In Maintenance or Lost (one test each), then StatusIsFinalErr is raised.
- S7 Given equipment saved as Lost (Disposed), when Status := Available by direct assignment and Modify(true) is called, then StatusIsFinalErr is raised and the stored status is unchanged.
- S8 Given equipment saved as Lost (Disposed), when Description is changed and Modify(true) is called, then the record is saved and the status is unchanged.
- S9 Given equipment saved as Lost (Disposed), when Status is validated to the same value again, then no error and no confirm.
- S10 Given equipment saved as Lost (Disposed), when Delete(true) is called, then the record is deleted with no confirm.

Final-status confirmation (BR7)
- S11 Given saved Available equipment, when Status is validated to Lost (Disposed) and the confirm is answered Yes, then the status is set; exactly one confirm was shown and it equals FinalStatusQst (equipment no., status).
- S12 Same as S11, answered No: an error is raised and the stored status is still Available.
- S13 Given equipment assigned to employee E, when Status is validated to Lost (Disposed) and answered Yes, then the status is set and the employee is blank; exactly one confirm, equal to FinalStatusAssignedQst (equipment no., E, status).
- S14 Same as S13, answered No: the stored record is still Assigned to E.
- S15 Given saved In Maintenance equipment, when Status is validated to Lost and answered Yes and Modify(true) is called, then it is saved as Lost.
- S16 Given equipment assigned to E, when Status := Lost by direct assignment (employee kept) and Modify(true) is called, then EmployeeOnlyWhenAssignedErr is raised.
- S17 Given a session without UI (default answer Yes), when Status is validated to Disposed, then no dialog appears and the status is Disposed.

New equipment (BR6, Q3)
- S18 Given a new, not inserted equipment record, when Status is validated to Lost (Disposed), then NewEquipmentFinalStatusErr (status) is raised.
- S19 Given a new record with Status := Lost (Disposed) by direct assignment, when Insert(true) is called, then NewEquipmentFinalStatusErr is raised and no record exists.
- S20 Given a new record, when Status is validated to In Maintenance and Insert(true) is called, then it is saved as In Maintenance.
- S21 Given a new record with Status Assigned and an active employee (both validated), when Insert(true) is called, then it is saved (FR-001 behavior unchanged).

Employee rules (BR4, D5)
- S22 Given Available (In Maintenance, Lost, Disposed) equipment, when an active employee is validated into "Assigned Employee No.", then EmployeeOnlyWhenAssignedErr is raised.
- S23 Given saved Available equipment, when an employee is set by direct assignment and Modify(true) is called, then EmployeeOnlyWhenAssignedErr is raised.
- S24 Given a subscriber to `OnBeforeCheckEmployeeIsEligible` that sets IsHandled, when an employee is set on Available (In Maintenance) equipment by direct assignment and Modify(true) is called, then EmployeeOnlyWhenAssignedErr is still raised.
- S25 Given the same subscriber and Assigned equipment, when an Inactive (privacy blocked) employee is validated, then no error is raised.
- S26 Given the same subscriber and Assigned equipment, when a non-existing employee no. is set by direct assignment and Modify(true) is called, then EmployeeNotFoundErr is raised.

Non-final transitions and regression
- S27 Given saved In Maintenance equipment and an active employee, when it is assigned (Assign to Employee or validate Assigned + employee + Modify(true)), then it is saved as Assigned (Q5).
- S28 Given equipment assigned to E, when Status is validated to In Maintenance (Available) and answered Yes, then the employee is blank; the question equals StatusChangeRemovesEmployeeQst.
- S29 Given Available equipment, when Status is validated to In Maintenance, then no confirm is shown.

Transition event
- S30 Given a subscriber to `OnBeforeCheckStatusTransitionAllowed` that sets IsHandled, and equipment saved as Lost (Disposed), when Status is validated to Available and Modify(true) is called, then it is saved as Available.
- S31 Given the same subscriber and equipment saved as Lost (Disposed), when Status is validated to Assigned, then CannotAssignFinalStatusErr is still raised.
- S32 Given a subscriber that records FromStatus/ToStatus, and saved Assigned equipment, when Status is validated to In Maintenance (answered Yes) and Modify(true) is called, then the event was raised with Assigned -> In Maintenance (twice: validate and modify).
- S33 Given a subscriber that raises its own error when ToStatus = In Maintenance, when Status is validated to In Maintenance on Available equipment, then that error is raised and the stored status is unchanged.
- S34 Given a subscriber that records calls, when new equipment is inserted, then the event is not raised.

Card and list (UI)
- U1 Given a new card (OpenNew), then the Status control offers only Available, Assigned and In Maintenance (setting Lost via the visible control fails), and the full Status control is not visible.
- U2 Given equipment saved as Lost (Disposed), when the card is opened, then Assign to Employee is disabled and the full Status control is visible.
- U3 Given saved Available equipment, when the card is opened, then Assign to Employee is enabled and assigning an active employee works.
- U4 Given equipment assigned to E, when Status is set to Lost on the card and the confirm is answered Yes, then the record is Lost with a blank employee and Assign to Employee is disabled.
- U5 Given equipment saved as Disposed, when Status is set to Available on the card, then StatusIsFinalErr is raised.
- Manual: status colors on list and card; the five list views exist and the default view shows all statuses; the
  Status dropdown shows In Maintenance and Disposed (no old names) and Lost; the generated `.g.xlf` has no orphan
  entries for Under Maintenance/Retired.

## Risks and open questions
Final decisions (approved by the user):
- D1 Rename in place keeping ordinals (2 In Maintenance, 3 Disposed), add 4 Lost. No obsoleting, no upgrade codeunit.
- D2 Retired -> Disposed confirmed.
- D3 Disposed is final; partners may relax it only through `OnBeforeCheckStatusTransitionAllowed`.
- D4 Lost is final with the same treatment as Disposed (no transition out, including Lost -> Disposed; the event is the only way to relax).
- D5 BR4 is a hard rule for all statuses; `OnBeforeCheckAssignedEmployeeAllowed` is replaced by the narrower `OnBeforeCheckEmployeeIsEligible`.
- D6 No status history.
- D7 No tests in this iteration; scenarios kept as a reference list. Tester step skipped.
- D8 No version bump; app.json stays 29.0.0.0.
- D9 Confirmation when setting Disposed, and also Lost (both final), default Yes without UI.
- Q1 Employee is cleared when the status becomes Lost or Disposed.
- Q2 The list shows all equipment by default; per-status views are optional.
- Q3 New equipment cannot be Lost or Disposed (table rule; the card does not offer them on a new record).
- Q4 No undo in the standard app.
- Q5 In Maintenance equipment can be assigned directly.

Still open (not blocking development):
- O1 CHANGELOG placement: the version stays 29.0.0.0, but CHANGELOG.md is organized per version. Planner recommendation
  for the documenter: add a section `## Unreleased (FR-003)` at the top instead of editing the 29.0.0.0 entry. Confirm or change.

Risks:
- R1 The enum renames and the event replacement are breaking in AppSource terms; safe only while nothing is released.
- R2 Enum ordinal order puts Disposed before Lost in the dropdown; reordering needs a data upgrade.
- R3 Trigger-less writes (`Modify(false)`, `Insert(false)`, `ModifyAll`, RapidStart without validation) bypass all status
  rules, like every FR-001/FR-002 check. Document in help.
- R4 Non-UI sessions answer the final-status confirm with Yes, so Lost/Disposed is set without a question. Intended.
- R5 Card twin Status controls: with personalization a user could make the hidden control visible; the table rule (BR6)
  still rejects final statuses on new records, and `ValuesAllowed` hides partner enum values on new records only.
  If the twin-control approach gives analyzer or UX problems, the developer stops and reports instead of improvising.
- R6 `IsStoredRecord` adds one primary-key read per Status validation. Negligible.
- R7 FR-001 test specs (scenarios 19, 32, 56) and FR-002 E12 use Retired/Under Maintenance and the removed event; the
  user must update them when writing tests.
- R8 Partner enum values are not final and get the 'Standard' style; partners add their own rules through the transition event.
- R9 No automated tests: regressions in FR-001/FR-002 behavior are caught only by review and manual checks until tests are written.
