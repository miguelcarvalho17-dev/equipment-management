# FR-012 Equipment Maintenance Status

> Status: REVISION 1, waiting for human approval. Open questions Q1-Q9 (see "Risks and open questions") have a
> proposed default. The plan is written with these defaults. Q2 (assigned equipment), Q3 (automatic return) and Q4
> (cancel) change the design if they are answered differently.
> Source: GitHub issue #31. Branch: `feature/FR-012-equipment-maintenance-status` (cut from `main` after the FR-011
> merge, commit cb7c348).
> No events report. FR-012 changes only this app's own objects (tables 50100 and 50105, codeunits 50108 and 50109,
> pages 50101, 50113, 50114 and 50115). It subscribes to no standard events, so al-event-finder is not needed.
> Scope: main app only. **No new objects.** One new key on table 50105 and changes to eight of the app's own objects.
> **No permission set changes. No version bump** (app.json stays 29.0.0.0). **No upgrade logic.** Tests are deferred
> (Q9 default): test codeunit 50166 is reserved, and the tester step is skipped.
> Workflow for FR-012: planner -> (human approves plan) -> developer -> reviewer -> build -> **tester step SKIPPED
> (Q9)** -> documenter -> appsource-validator.

## Goal
Equipment that is being maintained is marked **In Maintenance** automatically, and nobody can assign it to an employee
while its maintenance is still open. When the last open maintenance of the equipment is completed (posted), the
equipment becomes **Available** again by itself. This links the maintenance records (FR-010, FR-011) to the equipment
lifecycle status (FR-003) and the assignment rules (FR-004, FR-005).

### Requirement restated
- S-R1 Equipment can be marked as under maintenance.
- BR-S1 The equipment status changes to In Maintenance automatically when a maintenance activity is opened.
- BR-S2 Equipment in maintenance cannot be assigned to employees.
- BR-S3 Equipment can be returned to Available after the maintenance is completed.
- BR-S4 Assignment attempts are blocked while maintenance is active.

### Interpretation (defaults, see Q1-Q8)
- **"Maintenance activity opened"** = a maintenance record (table 50105) is registered. Every new record has
  Status = Open (FR-011). (Q1)
- **"Maintenance completed"** = the record is posted (Status Open -> Posted, codeunit 50109). FR-012 adds no new
  maintenance status. (Q1)
- **"Maintenance active"** = the equipment has at least one maintenance record with Status = Open. This definition
  is used for the assignment block (BR-S2, BR-S4). It does not depend on the equipment status, so the block also holds
  when the status was changed by code or by an extension.
- **Assigned equipment** (Q2): registering maintenance asks the user to confirm. On Yes, the equipment is returned
  from the employee (the active assignment is closed as history, the same as an FR-003 status change away from
  Assigned) and its status becomes In Maintenance. On No, nothing is registered.
- **Return to Available** (Q3): automatic. When a record is posted and the equipment has no other open maintenance
  record and its status is In Maintenance, the status changes to Available. While open records exist, the user cannot
  change the status from In Maintenance to Available (or to any other non-final status) by hand.
- **Cancel** (Q4): there is no cancel. A record opened by mistake is completed by posting it (for example with cost 0
  and a description that says it was cancelled). Records still can never be deleted (FR-010 BR-M2), so "status on
  delete" does not apply.
- **Status that was already In Maintenance** (Q5): registering does not change it. Posting the last open record
  returns it to Available, even when the status was set by hand before the record was registered.
- **Lost or Disposed while maintenance is open** (Q6): allowed (final statuses always win; equipment can be found
  broken beyond repair during maintenance). The open record stays open and can still be posted (FR-011 Q4). Posting
  does not change a Lost or Disposed status.
- **Historical registration** (Q7): FR-010 Q4 ("registering does not change the status") is **reversed** by this
  issue. Registering past work now also sets In Maintenance until the record is posted. The user posts it right away
  to return the equipment to Available.
- **Manual In Maintenance** (Q8): setting In Maintenance by hand (FR-003, also on new equipment) stays allowed. An
  equipment with a manual In Maintenance status and no open record can be set back to Available by hand.

### What already exists and is reused
| Already present | Use in FR-012 |
|---|---|
| Enum 50100 "EQM Equipment Status" value 2 "In Maintenance" (FR-003). | The status set and cleared automatically. No enum change. |
| Table 50100 `CheckStatusTransitionAllowed` (FR-003/FR-004): hard check "final status cannot be assigned" **before** the IsHandled event `OnBeforeCheckStatusTransitionAllowed`; only Available can become Assigned. Called from Status `OnValidate` and from `CheckEquipmentConsistency` on modify. | Two new hard checks are added in the same place, before the IsHandled event, so no extension can bypass the maintenance block. |
| Table 50100 `AssignEmployee` / `UnassignEmployee` (FR-004/FR-005): internal procedures that change status and call `Modify(true)`. | Same pattern for two new internal procedures `StartMaintenance` and `CompleteMaintenance`. |
| Table 50100 `OnModify` -> `AssignmentMgt.UpdateAssignmentOnSave` (FR-006): closes the active assignment when the status leaves Assigned. | Closes the assignment when assigned equipment goes into maintenance. No change to codeunit 50106. |
| `ConfirmManagement.GetResponseOrDefault(..., true)` (FR-003, FR-005). | Used for the confirm on assigned equipment (Yes without UI). |
| Table 50105 `OnInsert` (FR-010/FR-011): number series, default date, Open-only check, `CheckMaintenanceConsistency(true)` (Lost/Disposed refused, BR-M5). | `StartMaintenance` is called at the end of `OnInsert`. |
| Codeunit 50109 "EQM Maintenance-Post" (FR-011): Open -> Posted, history entry, three events, no commit. | `CompleteMaintenance` is called after the history entry insert, before `OnAfterPostMaintenanceRecord`. |
| Codeunit 50108 "EQM Maintenance Mgt." (internal read helpers, already called from table 50100 `OnDelete`). | New helpers `HasOpenMaintenance`, `CountOpenMaintenanceRecords`, `ShowOpenMaintenanceRecords`. |
| Page 50115 "EQM Maintenance FactBox" on equipment card and list. | New line "Open Maintenance Records", so users see why Assign is disabled. |
| Equipment Card `CanAssign` (Status = Available). | Also false while maintenance is open. |

## Approach and rejected alternatives
- Chosen:
  - **Status logic on table 50100**, as two internal procedures next to `AssignEmployee` / `UnassignEmployee`:
    `StartMaintenance(MaintenanceRecord)` and `CompleteMaintenance(MaintenanceRecord)`. Each changes the status and
    saves with `Modify(true)`, so all FR-003 to FR-006 checks run and the assignment history is kept in sync.
  - **Callers:** table 50105 `OnInsert` (start) and codeunit 50109 `OnRun` (complete). Both lock the equipment row
    with `UpdLock` first, so two users who register and post maintenance for the same equipment at the same time are
    serialized and the "last open record" decision is correct.
  - **Assignment block (BR-S2, BR-S4)** as a hard check in `CheckStatusTransitionAllowed`, before the IsHandled event:
    a change **to** Assigned is refused while the equipment has an open maintenance record. This covers the Assign to
    Employee action, Status validation, and `Modify(true)` from code.
  - **Manual early return blocked:** in the same place, a change **from** In Maintenance to a non-final status is
    refused while an open record exists (BR-S3: back to Available only after completion). Lost and Disposed stay
    allowed (Q6).
  - **Two partner events** on table 50100: `OnBeforeStartMaintenance` (no IsHandled) and `OnBeforeCompleteMaintenance`
    (with IsHandled, so a partner can keep the equipment In Maintenance, for example until an inspection; this is
    stricter, never looser, than the issue).
  - **UI:** Equipment Card Assign disabled while maintenance is open; Maintenance FactBox shows the number of open
    records; ToolTips, AboutTexts and the post confirmation explain the status change.
  - New key `EquipmentStatus` ("Equipment No.", Status) on table 50105 for the open-record checks.
- Rejected: a new codeunit "EQM Maintenance Status Mgt." for the status logic. Table 50100 already owns the status
  procedures (`AssignEmployee`, `UnassignEmployee`) and is public, so its events are subscribable; a new object adds
  nothing.
- Rejected: blocking assignment only through the equipment status (In Maintenance is already not Available). The
  status can be changed by code, by trigger-less writes and by partners through `OnBeforeCheckStatusTransitionAllowed`
  IsHandled; the issue asks to block while maintenance is **active**, which is the open-record state.
- Rejected: subscribing to the implicit `OnAfterInsertEvent` of table 50105 instead of calling from `OnInsert`. The
  table is our own; a direct call is explicit and runs in a defined order (after the consistency check).
- Rejected: refusing maintenance for Assigned equipment ("return first", Q2 option A). It contradicts "status changes
  automatically" and forces two extra steps. Kept as the alternative in Q2.
- Rejected: keeping the employee on assigned equipment that goes into maintenance (Q2 option C). An employee is only
  allowed while the status is Assigned (FR-001/FR-003 rule), so this would need a status rule change.
- Rejected: a manual "Complete Maintenance" action instead of automatic return (Q3 alternative). Posting already marks
  completion; a second step can be forgotten and leaves equipment blocked.
- Rejected: a Cancelled maintenance status in this feature (Q4). It changes enum 50103, posting, the history and the
  pages; proposed as a follow-up feature if wanted.
- Rejected: calling `Validate(Status, "In Maintenance")` in `StartMaintenance`. For Assigned equipment the Status
  `OnValidate` asks its own generic question ("Changing the status removes the assigned employee..."); FR-012 asks one
  question that names maintenance. `Modify(true)` still runs every status check through `CheckEquipmentConsistency`.
- Rejected: an IsHandled on `OnBeforeStartMaintenance` or on the new hard checks. BR-S1, BR-S2 and BR-S4 are issue
  rules and must not be bypassed by extensions.

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50106, pages 50100-50117, codeunits 50103-50109,
queries 50100-50101, enums 50100-50103, page extension 50100, permission sets 50100-50102, permission set extension
50103, profile "EQM EQUIPMENT MANAGER". Test app: no objects; test codeunits 50150-50165 are reserved by FR-001 to
FR-011, none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50100 | EQM Equipment | Modify (own) | `StartMaintenance`, `CompleteMaintenance`, two hard transition checks, two events, labels, Status ToolTip |
| Table | 50105 | EQM Maintenance Record | Modify (own) | Key `EquipmentStatus`; `OnInsert` calls `StartMaintenance`; ToolTips of "Equipment No." and Status |
| Codeunit | 50108 | EQM Maintenance Mgt. | Modify (own) | `HasOpenMaintenance`, `CountOpenMaintenanceRecords`, `ShowOpenMaintenanceRecords`; `PostQst` text |
| Codeunit | 50109 | EQM Maintenance-Post | Modify (own) | Calls `CompleteMaintenance` after the history entry; summary text |
| Page | 50101 | EQM Equipment Card | Modify (own) | `CanAssign` false while maintenance is open; ToolTips of Assign to Employee and Register Maintenance |
| Page | 50113 | EQM Maintenance Records | Modify (own) | AboutText, Post ToolTip |
| Page | 50114 | EQM Maintenance Record Card | Modify (own) | AboutText, Post ToolTip |
| Page | 50115 | EQM Maintenance FactBox | Modify (own) | New field "Open Maintenance Records" with drill-down |

Not changed: tables 50101-50104, 50106; pages 50100, 50102-50112, 50116, 50117; codeunits 50103-50107; queries;
enums 50100-50103; page extension 50100; permission sets 50100-50102; permission set extension 50103; the profile;
`app/app.json`; `test/`.
No new files. Namespace `MiguelCarvalho.EquipmentManagement`, like all existing files.
Next free IDs after FR-012 (unchanged): tables 50107, pages 50118, codeunits 50110, queries 50102, enums 50104, page
extensions 50101, permission sets 50104. Test app: test codeunit **50166 reserved for FR-012 "EQM Maintenance Status
Tests"**, not built now (Q9).

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report. Do not pick a workaround on your own.
- `ReadIsolation := IsolationLevel::UpdLock` on a record variable before `Get`, then calling a table procedure on that
  variable that does `Modify(true)`, works without error (same use as in codeunit 50109).
- A `Confirm` (through `ConfirmManagement.GetResponseOrDefault`) raised inside table 50105 `OnInsert`, while the card
  inserts the record (`DelayedInsert`), is shown to the user and `Error('')` on No rolls back the insert with no
  message. Check in the sandbox (MS-SB3). The number from the series may be lost (gap); that is accepted.
- `xRec` of a record variable read with `Get` equals the read values when a table procedure on it calls `Validate`
  (used by `CompleteMaintenance`; `UnassignEmployee` relies on the same behavior today).

### Table 50100 "EQM Equipment" (change)
**Status field ToolTip** (field 9) becomes:
'Specifies the lifecycle status of the equipment: Available, Assigned, In Maintenance, Lost or Disposed. Only saved, available equipment without open maintenance can be assigned; use the Assign to Employee action. Assigned equipment becomes available only through the Return action. Registering maintenance sets the status to In Maintenance, and posting the last open maintenance record sets it back to Available. Lost and Disposed are final statuses: the equipment cannot be assigned or change status again. New equipment cannot start as Assigned, Lost or Disposed.'

**`CheckStatusTransitionAllowed(FromStatus, ToStatus)`** - add two checks directly **after** the existing
"to Assigned from a final status" check and **before** `OnBeforeCheckStatusTransitionAllowed` is raised. Use a local
`MaintenanceMgt: Codeunit "EQM Maintenance Mgt."`. Call `HasOpenMaintenance` only when one of the conditions on the
statuses is true (avoid a read on every status change):
1. When ToStatus = Assigned and `MaintenanceMgt.HasOpenMaintenance("No.")`: Error(MaintenanceOpenAssignErr, "No.").
2. When FromStatus = "In Maintenance" and ToStatus is not final (`not IsFinalStatus(ToStatus)`) and
   `MaintenanceMgt.HasOpenMaintenance("No.")`: Error(MaintenanceOpenStatusErr, "No.", Format(ToStatus),
   Format(Status::Available)).
The first line of the procedure (`FromStatus = ToStatus` -> exit) stays first. Nothing else in the procedure changes.

**Update the doc comment of `OnBeforeCheckStatusTransitionAllowed`**, parameter IsHandled: append "Equipment with open
maintenance still cannot be assigned, and its status cannot leave In Maintenance except to Lost or Disposed."

**Update the `/// <summary>` of `AssignEmployee`**: add "Raises an error when the equipment has open maintenance."

**New procedure `internal procedure StartMaintenance(MaintenanceRecord: Record "EQM Maintenance Record")`**, in this
order (Rec is the equipment; the caller has read it with `UpdLock`):
1. When Status = "In Maintenance": exit (several open records, or status set by hand; Q5).
2. When `IsFinalStatus(Status)`: exit (defensive; BR-M5 already refuses new records for Lost and Disposed).
3. When Status = Assigned:
   - when not `ConfirmManagement.GetResponseOrDefault(StrSubstNo(StartMaintenanceAssignedQst, "No.",
     "Assigned Employee No.", Format(Status::"In Maintenance")), true)`: `Error('')`;
   - "Assigned Employee No." := ''.
4. Status := Status::"In Maintenance" (direct assignment, see Approach).
5. `OnBeforeStartMaintenance(Rec, MaintenanceRecord)`.
6. `Modify(true)`. This runs `CheckEquipmentConsistency(false)` (transition check from the stored status, employee
   rules) and `UpdateAssignmentOnSave`, which closes the active assignment when the stored status was Assigned.
Doc comment: "Sets the status to In Maintenance and saves the record with triggers. Called when a maintenance record is
registered. Does nothing when the status is already In Maintenance, Lost or Disposed. For assigned equipment the user
is asked to confirm (Yes without a UI session); the equipment is then returned from the employee and the assignment
is closed. Raises an empty error when the user answers No."
Parameter: "The maintenance record being registered (passed by value). Used for the event."

**New procedure `internal procedure CompleteMaintenance(MaintenanceRecord: Record "EQM Maintenance Record")`**, in
this order:
1. When Status <> "In Maintenance": exit (Lost, Disposed, Available, or an extension status are not touched).
2. When `MaintenanceMgt.HasOpenMaintenance("No.")`: exit (other maintenance is still open).
3. `OnBeforeCompleteMaintenance(Rec, MaintenanceRecord, IsHandled)`; when IsHandled: exit.
4. `Validate(Status, Status::Available)`; `Modify(true)`.
Doc comment: "Sets the status from In Maintenance back to Available and saves the record with triggers, when the
equipment has no open maintenance record left. Called after a maintenance record is posted. Does nothing when the
status is not In Maintenance or when other maintenance is still open."

**New events** (`[IntegrationEvent(false, false)]`, `local`, XML doc comments, placed after the existing events):
- `OnBeforeStartMaintenance(var Equipment: Record "EQM Equipment"; MaintenanceRecord: Record "EQM Maintenance Record")`.
  Summary: "Raised when registering maintenance changes the equipment status to In Maintenance, after the status and
  the employee are set and before the record is saved." Parameters: Equipment "The equipment, with Status = In
  Maintenance and the employee removed. You can set fields that your extension added; do not change the standard
  fields. Raise an error to stop the registration."; MaintenanceRecord "The maintenance record being registered
  (passed by value)."
- `OnBeforeCompleteMaintenance(var Equipment: Record "EQM Equipment"; MaintenanceRecord: Record "EQM Maintenance Record"; var IsHandled: Boolean)`.
  Summary: "Raised when the last open maintenance record of equipment in maintenance is posted, before the status
  changes to Available." Parameters: Equipment "The equipment, still In Maintenance."; MaintenanceRecord "The posted
  maintenance record (passed by value)."; IsHandled "Set to true to keep the equipment In Maintenance. The user can set
  it to Available later."

**New labels** (table 50100 `var` section, next to the other errors):
- `MaintenanceOpenAssignErr`: 'You cannot assign equipment %1 because it has open maintenance. Post the open maintenance records of the equipment first.' Comment: '%1 = equipment number'.
- `MaintenanceOpenStatusErr`: 'You cannot change the status of equipment %1 to %2 because it has open maintenance. The status changes to %3 automatically when the last open maintenance record is posted.' Comment: '%1 = equipment number, %2 = new status caption, %3 = Available status caption'.
- `StartMaintenanceAssignedQst`: 'Equipment %1 is assigned to employee %2. Registering maintenance returns the equipment from the employee and changes its status to %3. Do you want to continue?' Comment: '%1 = equipment number, %2 = employee number, %3 = In Maintenance status caption'.

`StartMaintenance` needs a local `ConfirmManagement: Codeunit "Confirm Management"` (already used in the table,
`using System.Utilities;` is present). `CompleteMaintenance` needs a local `MaintenanceMgt` and `IsHandled: Boolean`.

### Table 50105 "EQM Maintenance Record" (change)
- New key after `EquipmentDate`: `key(EquipmentStatus; "Equipment No.", Status)` (no SumIndexFields).
- `OnInsert`: after `CheckMaintenanceConsistency(true)` (last line today), add: local `Equipment: Record "EQM
  Equipment"`; `Equipment.ReadIsolation := IsolationLevel::UpdLock`; when `Equipment.Get("Equipment No.")`:
  `Equipment.StartMaintenance(Rec)`. (The consistency check has already proved that the equipment exists; the `if`
  only avoids a second error path.)
- ToolTip of field 2 "Equipment No." becomes: 'Specifies the equipment the maintenance is performed on. The equipment must exist and cannot be lost or disposed of. Registering the record sets the equipment status to In Maintenance. You cannot change the equipment after the record is created.'
- ToolTip of field 11 Status becomes: 'Specifies whether the maintenance record is open or posted. While a record is open, the equipment is In Maintenance and cannot be assigned. Posting copies the record to the maintenance history, and after that it cannot be changed. When the last open record of the equipment is posted, the equipment becomes Available.'
- Table `/// <summary>` becomes: "One record per maintenance activity performed on equipment. Maintenance cannot be
  registered for Lost or Disposed equipment. Registering a record sets the equipment status to In Maintenance; while
  the equipment has open records it cannot be assigned. Open records can be corrected. Posting freezes the record,
  writes a maintenance history entry and, when no other record is open, sets the equipment back to Available. Records
  are never deleted, so equipment that has maintenance records cannot be deleted either."
- `OnModify`, `OnDelete`, `OnRename`, `CheckMaintenanceConsistency` and its event: unchanged.

### Codeunit 50108 "EQM Maintenance Mgt." (change)
New internal procedures, each with an XML doc comment, using `SetCurrentKey("Equipment No.", Status)`:
1. `HasOpenMaintenance(EquipmentNo: Code[20]): Boolean` - filter "Equipment No." and Status = Open; return
   `not IsEmpty()`. Doc: "Returns whether the equipment has at least one open maintenance record. Equipment with open
   maintenance cannot be assigned."
2. `CountOpenMaintenanceRecords(EquipmentNo: Code[20]): Integer` - same filters; return `Count()`.
3. `ShowOpenMaintenanceRecords(EquipmentNo: Code[20])` - same filters; `Page.Run(Page::"EQM Maintenance Records",
   MaintenanceRecord)` (shape of `ShowMaintenanceRecords`).
- `PostQst` text becomes: 'Do you want to post maintenance record %1? It is copied to the maintenance history, and after that you cannot change it. If no other maintenance is open for the equipment, its status changes from In Maintenance to Available.' Comment unchanged.
- The codeunit has no `Permissions` property and needs none (all roles have R on table 50105).

### Codeunit 50109 "EQM Maintenance-Post" (change)
- `OnRun`: between `InsertHistoryEntry(Rec, MaintenanceHistoryEntry)` and `OnAfterPostMaintenanceRecord(...)`, add a
  call to a new local procedure `CompleteEquipmentMaintenance(Rec)`: local `Equipment: Record "EQM Equipment"`;
  `Equipment.ReadIsolation := IsolationLevel::UpdLock`; when `Equipment.Get(MaintenanceRecord."Equipment No.")`:
  `Equipment.CompleteMaintenance(MaintenanceRecord)`. When the equipment is not found, do nothing.
- Still no `Commit`. An error in `CompleteMaintenance` rolls back the status change of the record and the history
  entry.
- `Permissions` unchanged: the equipment modify uses the user's own M on table 50100 (Manager has RIM).
- `/// <summary>` becomes: "Posts a maintenance record: freezes it, writes a read-only maintenance history entry and,
  when no other maintenance is open, sets the equipment from In Maintenance back to Available. Run it with
  Codeunit.Run on the record. It shows no dialogs."
- Doc comment of `OnAfterPostMaintenanceRecord`: append "The equipment status has already been updated."

### Page 50101 "EQM Equipment Card" (change)
- `UpdateControls`: `CanAssign := IsSaved and (Rec.Status = Rec.Status::Available) and not
  MaintenanceMgt.HasOpenMaintenance(Rec."No.")` (local `MaintenanceMgt: Codeunit "EQM Maintenance Mgt."`; evaluate
  `HasOpenMaintenance` only when the first two conditions are true).
- Action `AssignToEmployee` ToolTip: 'Assign available equipment to an active employee that you select. The assignment is recorded with the work date and your user name. Not available while the equipment has open maintenance.'
- Action `RegisterMaintenance` ToolTip: 'Register maintenance for the equipment. The equipment status changes to In Maintenance, and the equipment cannot be assigned until the maintenance record is posted. Not available for lost or disposed equipment.'
- Nothing else changes (`CanRegisterMaintenance` stays: In Maintenance equipment can get more records).

### Page 50115 "EQM Maintenance FactBox" (change)
- New field directly after `NoOfMaintenanceRecords`: `NoOfOpenMaintenanceRecords` (Integer),
  `Caption = 'Open Maintenance Records'`,
  `ToolTip = 'Specifies how many maintenance records of the equipment are open. While a record is open, the equipment cannot be assigned. Choose the number to see them.'`;
  `OnDrillDown`: `MaintenanceMgt.ShowOpenMaintenanceRecords(Rec."No.")`.
- `ClearFactBox`: set it to 0. `UpdateFactBox`: after the count of all records (and only when that count > 0), set it
  with `CountOpenMaintenanceRecords`.

### Page 50113 "EQM Maintenance Records" (change)
- `AboutText` becomes: 'This list shows the maintenance work on your equipment: when, what type, by whom and at what cost. Choose **New** to register maintenance. While a record is open, its equipment is In Maintenance and cannot be assigned. Choose **Post** when the work is done: the record is copied to the maintenance history and locked, and the equipment becomes Available when no other maintenance is open. No record can be deleted. Choose a view at the top to see one maintenance type, or only open or posted records.'
- Action `Post` ToolTip: 'Post the maintenance record. It is copied to the maintenance history, and after that it cannot be changed or deleted. If no other maintenance is open for the equipment, the equipment becomes Available.'

### Page 50114 "EQM Maintenance Record Card" (change)
- `AboutText` becomes: 'Register maintenance on equipment. Choose the equipment, the date and the type of maintenance, and add the vendor, the cost and who did the work. When you register the record, the equipment status changes to In Maintenance and the equipment cannot be assigned. You cannot register maintenance for lost or disposed equipment. You can correct the record until you choose **Post**. Posting copies it to the maintenance history, locks it and, when no other maintenance is open, makes the equipment Available again. Maintenance records can never be deleted.'
- Action `Post` ToolTip: same text as on page 50113.

### app.json, translations
- **app.json: no change.** Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf` (new and changed labels, ToolTips, AboutTexts,
  one caption). Commit it; never edit it by hand.

## Data model and upgrade impact
- No new tables or fields. One new secondary key on table 50105: `EquipmentStatus` ("Equipment No.", Status).
- DataClassification: unchanged (no new fields).
- Upgrade codeunit: **not needed.** Nothing is released, and the version stays 29.0.0.0.
- **Existing development data:** open maintenance records registered before FR-012 did not change the equipment
  status. After publishing, such equipment cannot be assigned (open record), even if its status is Available. Posting
  those records clears the block (status stays Available because it is not In Maintenance). Sandbox step MS-SB0.
  No data fix is planned (not released; Q9 of FR-010 pattern).
- Volume: the open-record check is one `IsEmpty` on the new key per status change to Assigned or away from
  In Maintenance, per post and per equipment card refresh of an Available record.

## Events
**Standard BC events: none.** No events report is required. Subscribed: none.

Published (table 50100, `[IntegrationEvent(false, false)]`, `local`, with XML doc comments; see table 50100 section):
- `OnBeforeStartMaintenance(var Equipment: Record "EQM Equipment"; MaintenanceRecord: Record "EQM Maintenance Record")`
  - **No IsHandled** (BR-S1 is an issue rule). Raised only when the status really changes (not when already In
    Maintenance). Partners fill their own fields or raise an error to stop the registration.
- `OnBeforeCompleteMaintenance(var Equipment: Record "EQM Equipment"; MaintenanceRecord: Record "EQM Maintenance Record"; var IsHandled: Boolean)`
  - **IsHandled: yes.** Lets a partner keep the equipment In Maintenance after posting (stricter than the issue; the
    user can still set Available by hand, because no record is open). It cannot make equipment assignable while
    maintenance is open.
- Unchanged and still raised in the new flows: `OnAfterCheckEquipmentConsistency` (on every equipment `Modify(true)`
  above), `OnBeforeCheckStatusTransitionAllowed` (after the new hard checks), `OnBeforeCloseAssignment` (codeunit
  50106, when assigned equipment goes into maintenance), `OnAfterCheckMaintenanceConsistency`, and the three posting
  events of codeunit 50109.
- The new hard checks in `CheckStatusTransitionAllowed` run **before** `OnBeforeCheckStatusTransitionAllowed`, so its
  IsHandled cannot bypass them (same as the existing final-status assign check).

## Permissions
- **No permission set changes.** No new objects.
- **EQM - Reader:** cannot register or post (no I/M on table 50105), so no status change can start from a Reader.
- **EQM - Manager:** registering and posting now also modify table 50100 (direct RIM, present) and, for assigned
  equipment, close the assignment through codeunit 50106 (indirect `m` on table 50103 + codeunit `Permissions` rim,
  present since FR-004/FR-005).
- **EQM - Administrator:** inherits Manager; nothing to add.
- A user with custom permissions that allow inserting maintenance records but not modifying equipment gets a
  permission error at registration. Accepted; the EQM sets are the documented roles (NFR-002).

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| Register maintenance (sets In Maintenance) | no | yes | yes |
| Post maintenance (may set Available) | no | yes | yes |
| Assign equipment with open maintenance | no | no (business error) | no (business error) |
| Set In Maintenance -> Available by hand while maintenance is open | no | no (business error) | no (business error) |
| Set In Maintenance -> Lost / Disposed while maintenance is open | no | yes | yes |

## Compatibility
- AppSource mode, development phase: nothing is released, there is no baseline, no Obsolete handling is needed.
- New public surface after the first release: the two events on table 50100 and key `EquipmentStatus` on table 50105.
  `StartMaintenance`, `CompleteMaintenance` and the three new helpers in codeunit 50108 are `internal`.
- **Behavior changes (intentional, from issue #31):**
  - FR-010 Q4 / interpretation "registering does not change the equipment status" is reversed. FR-010 scenario M12f
    ("status before = status after") no longer holds; registering for Available or Assigned equipment sets
    In Maintenance.
  - FR-011 scenario H13 ("posting did not change the equipment status") no longer holds when the equipment is
    In Maintenance and no other record is open.
  - FR-003: the status can no longer leave In Maintenance for Available (or another non-final status) while an open
    maintenance record exists.
  - FR-004: Assign to Employee is refused for any equipment with an open maintenance record, also when an extension
    allows the transition through `OnBeforeCheckStatusTransitionAllowed`.
  - Registering maintenance for assigned equipment returns it from the employee (with confirmation) and closes the
    assignment entry.
- No control, action or group is renamed or removed. Only ToolTips, AboutTexts, one confirm text and one FactBox field
  change or are added.
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-012-equipment-maintenance-status.md` and `docs/help/FR-012-equipment-maintenance-status.md`:
    automatic In Maintenance, the confirm for assigned equipment, the assignment block, automatic return to Available on
    posting the last open record, several open records, Lost/Disposed during maintenance, no cancel (post instead),
    the FactBox line, roles.
  - `docs/help/FR-003-equipment-status-management.md`: line 13 says In Maintenance equipment "can be assigned directly";
    this is already wrong since FR-004 (only Available can be assigned) and must be corrected; add the FR-012 rules.
  - `docs/help/FR-010-maintenance-registration.md` line 18 ("Registering maintenance does not change the equipment
    Status") and `docs/features/FR-010-maintenance-registration.md` line 34: replace with the FR-012 behavior.
  - `docs/features|help/FR-011-maintenance-history.md`: posting may set the equipment to Available.
  - `docs/help/FR-004-equipment-assignment.md`, `docs/help/FR-005-equipment-unassignment.md`: open maintenance blocks
    assignment; registering maintenance returns assigned equipment.
  - `docs/features|help/NFR-002-role-based-access.md`: matrix rows above.
  - `CHANGELOG.md`: new top section `## FR-012 Equipment Maintenance Status (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-012 sandbox checks" with MS-SB0 to MS-SB10.

## Test scenarios
**No automated tests in this iteration** (Q9 default, as in FR-003 to FR-011). Test codeunit 50166 "EQM Maintenance
Status Tests" is reserved, and the tester step is skipped. The list is the reference for the developer and reviewer
and for the tests the user writes later (needs the test-app fix in `docs/TODO.md` first).

Test data, unless stated:
- setup with "Maintenance Nos." = a fresh series; category C1; active employee P1;
- equipment E1 (Available), E2 (Assigned to P1 through `AssignEmployee`, so one active assignment entry), E3
  (In Maintenance set by hand, no records), E4 (Available, used for two records), E5 (Available, later Disposed);
- "Register" = Init, Validate "Equipment No." and the other fields, `Insert(true)`. "Post" =
  `Codeunit.Run(Codeunit::"EQM Maintenance-Post", Record)`. Confirms are answered by a ConfirmHandler where a UI is
  involved; without a handler `GetResponseOrDefault` answers Yes.
- After an expected error, assert that the equipment status, its employee, its assignment entries and the maintenance
  records are unchanged.

Start of maintenance (BR-S1)
- S1 Given E1 (Available), when a record is registered, then E1.Status = In Maintenance and the record is Open.
- S2 Given E2 (Assigned to P1) and the confirm answered Yes, when a record is registered, then E2.Status =
  In Maintenance, "Assigned Employee No." is blank, the assignment entry of P1 is Closed with Closing Date = WorkDate
  and Closed By = UserId, and the record exists.
- S3 (negative) Given E2 (Assigned) and the confirm answered No, when a record is registered, then no record exists,
  E2 is still Assigned to P1 and the assignment entry is still Active.
- S4 Given E3 (In Maintenance by hand), when a record is registered, then no confirm is shown, E3 stays In Maintenance
  and `OnBeforeStartMaintenance` is not raised.
- S5 Given E4 with one open record (In Maintenance), when a second record is registered, then E4 stays In Maintenance
  and both records are Open.
- S6 (negative) Given E5 Disposed, when a record is registered, then `EquipmentFinalStatusErr` is raised (FR-010
  regression) and the status is unchanged.
- S7 Given a record whose date is 30 days ago (historical work), when it is registered, then the equipment is
  In Maintenance (Q7).
- S8 (negative) Given a subscriber to `OnAfterCheckMaintenanceConsistency` that raises an error, when a record is
  registered for E1, then E1 stays Available (the status change runs after the check and is rolled back).

Assignment block (BR-S2, BR-S4)
- S9 (negative) Given E4 In Maintenance with an open record, when `AssignEmployee(P1)` is called, then
  `MaintenanceOpenAssignErr` (E4) is raised.
- S10 (negative) Given E1 Available with an open record (record inserted with `Insert(false)`, so the status did not
  change; simulates pre-FR-012 data), when `AssignEmployee(P1)` is called, then `MaintenanceOpenAssignErr` is raised.
- S11 (negative) Given a manual subscriber to `OnBeforeCheckStatusTransitionAllowed` that sets IsHandled = true, and E4
  with an open record, when `AssignEmployee(P1)` is called, then `MaintenanceOpenAssignErr` is still raised.
- S12 (negative) Given E4 with an open record, when Status := Assigned and "Assigned Employee No." := P1 are set by
  direct assignment and `Modify(true)` is called, then `MaintenanceOpenAssignErr` is raised (consistency check path).
- S13 Given the Equipment Card (TestPage) on E4 with an open record, then Assign to Employee is disabled; on E1 without
  records it is enabled; after the last record of E4 is posted and E4 is Available, it is enabled.
- S14 Given E3 (In Maintenance by hand, no records), when the status is set to Available by hand and then
  `AssignEmployee(P1)` is called, then both succeed (manual In Maintenance without records is not blocked; Q8).

Manual status changes while maintenance is open (BR-S3, Q6)
- S15 (negative) Given E4 In Maintenance with an open record, when Status is validated to Available, then
  `MaintenanceOpenStatusErr` (E4, Available, Available) is raised and the status stays In Maintenance.
- S16 (negative) Same with direct assignment of Available and `Modify(true)`: `MaintenanceOpenStatusErr`.
- S17 Given E4 with an open record, when Status is validated to Disposed (confirm Yes) and saved, then E4 is Disposed
  and the record is still Open. When that record is then posted, then it is posted, the history entry exists and E4
  stays Disposed. Same for Lost.
- S18 Given E4 with an open record, when Description or Location Code of E4 is changed and saved, then it is saved (the
  new checks run only on status changes).

Completion (BR-S3, Q3, Q5)
- S19 Given E1 In Maintenance with one open record, when the record is posted, then E1.Status = Available, the record
  is Posted and one history entry exists.
- S20 Given E4 with two open records R1 and R2, when R1 is posted, then E4 stays In Maintenance; when R2 is posted,
  then E4 is Available.
- S21 Given E3 (In Maintenance by hand) with one record registered after that, when the record is posted, then E3 is
  Available (Q5).
- S22 Given E2 that was Assigned before maintenance (S2), when its record is posted, then E2 is Available, has no
  employee, and no new assignment entry was created.
- S23 Given E1 Available with an open record (inserted with `Insert(false)`), when it is posted, then E1 stays
  Available and no status-change event is raised.
- S24 Given a subscriber to `OnBeforeCompleteMaintenance` that sets IsHandled, when the last open record of E1 is
  posted, then E1 stays In Maintenance; then setting Available by hand succeeds (no open record).
- S25 (negative) Given a subscriber to `OnAfterCheckEquipmentConsistency` that raises an error when Status = Available,
  when the last open record of E1 is posted, then the error is raised, the record stays Open, no history entry exists
  and E1 stays In Maintenance (rollback of the whole posting).
- S26 Given a subscriber to `OnAfterPostMaintenanceRecord` that reads the equipment, then it sees Status = Available
  for the last open record (status updated before the event).

Cancel and delete (Q4)
- S27 (negative) Given an open record, when `Delete(true)` is called, then `MaintenanceCannotBeDeletedErr` is raised and
  the equipment stays In Maintenance (FR-010 regression).
- S28 Given an open record registered by mistake, when it is posted with cost 0, then the equipment returns to
  Available (the documented way to end maintenance without work).

Events
- S29 Given a subscriber to `OnBeforeStartMaintenance` that counts calls and checks values, when a record is registered
  for E1 and for E2, then it runs once per registration, with Equipment.Status = In Maintenance and a blank employee;
  for E3 and for a second record on E4 it does not run.
- S30 Given a subscriber to `OnBeforeStartMaintenance` that raises an error, when a record is registered for E1, then no
  record exists and E1 stays Available.
- S31 Given a subscriber to `OnBeforeCompleteMaintenance` that counts calls, then it runs only when the last open
  record of equipment that is In Maintenance is posted (S19, R2 of S20), not for R1 of S20, S17 or S23.

UI
- S32 Given E4 with two records, one open and one posted, then the Maintenance FactBox shows No. of Maintenance Records
  2 and Open Maintenance Records 1; the drill-down on Open Maintenance Records opens page 50113 filtered on E4 and
  Status Open. Given E1 without records, it shows 0 and 0.
- S33 Given the maintenance card opened from Equipment Card > Register Maintenance on E2 (Assigned), when the record is
  saved, then the confirm text names E2, P1 and In Maintenance; after Yes and returning to the equipment card, the
  status is In Maintenance (after refresh, R4).
- S34 Given the equipment card of E4 In Maintenance with an open record, when the user selects Available in Status,
  then `MaintenanceOpenStatusErr` is shown at once.

Permissions (`TestPermissions = Restrictive`, with D365 BASIC)
- S35 Manager: registering for E1 and E2 and posting the last record work with no permission error; the assignment
  entry of E2 is closed.
- S36 Reader: registering raises a permission error on table 50105; the equipment status is unchanged.

### Manual sandbox checks (for the user)
- MS-SB0 After publishing, list equipment that has open maintenance records from FR-010/FR-011 testing; post them (or
  accept that they cannot be assigned until posted).
- MS-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` contains the new and changed texts.
- MS-SB2 Register maintenance for Available equipment from the Equipment Card: status becomes In Maintenance; Assign to
  Employee is disabled; the FactBox shows 1 open record.
- MS-SB3 Register maintenance for assigned equipment: one confirm appears (not two). No cancels without any message and
  no record is created; Yes returns the equipment and closes the assignment (Assignment History shows the closed
  entry). Note whether a number from the series was skipped after No.
  While the confirm is open, check from a second session that registering on the same series or posting for the same
  equipment waits (accepted behavior, option B, see R2).
- MS-SB4 Two open records: post one (still In Maintenance), post the other (Available). Check the post confirm text.
- MS-SB5 Try Status = Available by hand while a record is open: error. Set Disposed while open: allowed; then post the
  record: status stays Disposed.
- MS-SB6 Non-SUPER Manager does all of the above without permission errors (equipment modify, assignment close).
- MS-SB7 Reader: Register fails with a permission error; nothing changes.
- MS-SB8 Equipment List view In Maintenance and the dashboard In Maintenance tile include the equipment while
  maintenance is open.
- MS-SB9 Two sessions: register a record for E in session A without leaving the card insert finished, and post the last
  other open record of E in session B; record whether B waits and the final status is In Maintenance (R3). Also record how long B waits while A's confirm
  dialog for assigned equipment is open (accepted behavior, option B, see R2).
- MS-SB10 Teaching tips of pages 50113 and 50114 show the new texts.

## Risks and open questions
Open questions (each has the default used in this plan; answer to change it):
- **Q1 What "opened" and "completed" mean.** Default: opened = maintenance record registered (Status Open);
  completed = record posted. No new maintenance status.
- **Q2 Equipment that is Assigned when maintenance is registered.** Default (B): confirm, then return the equipment
  from the employee (assignment closed as history) and set In Maintenance; No cancels the registration.
  Alternatives: (A) refuse registration with "return the equipment first"; (C) keep it assigned and do not change the
  status (would break BR-S1 for assigned equipment). **Changes the design if not B.**
- **Q3 Return to Available.** Default: automatic when the last open record is posted; manual return blocked while a
  record is open. Alternative: a manual "Complete Maintenance" action on the equipment card that is enabled only when
  no record is open. **Changes the design if manual.**
- **Q4 Cancel.** Default: no cancel in FR-012; to end maintenance that was opened by mistake, post the record (cost 0,
  description "cancelled"). Records cannot be deleted (FR-010). Alternative: a follow-up feature adds a Cancelled
  status to enum 50103 with a Cancel action that writes no history entry and completes the maintenance. **Changes the
  design if wanted now.**
- **Q5 Status set to In Maintenance by hand before registering.** Default: posting the last open record still sets it
  to Available.
- **Q6 Lost or Disposed while maintenance is open.** Default: allowed; the open record can still be posted; status is
  not changed by posting.
- **Q7 Historical maintenance (work already done).** Default: accepted that registering it sets In Maintenance until
  posted; the user posts right away. No "Register and Post" (FR-011 Q7 stays).
- **Q8 Manual In Maintenance without a record.** Default: still allowed (FR-003), also on new equipment; it can be set
  back to Available by hand because no record is open.
- **Q9 Automated tests.** Default: deferred, as in FR-003 to FR-011; test codeunit 50166 reserved, tester step
  skipped, MS-SB0 to MS-SB10 are the verification.

Risks:
- R1 Trigger-less writes (`Insert(false)` on table 50105, `Modify(false)` on table 50100, RapidStart) skip the status
  change and the checks, as for every rule in the app. The assignment block still holds because it reads open records,
  not the status (S10).
- R2 The confirm for assigned equipment appears at insert time of the maintenance card (`DelayedInsert`), not when the
  equipment is chosen. On No the number from the series may be skipped. Accepted; checked in MS-SB3.
  **User decision (accepted, option B):** the confirmation for assigned equipment is asked inside `OnInsert` of table
  50105, while the No. Series line and the `UpdLock` on the equipment row are held. Other users who register, save or
  post on that number series or on that equipment wait while the dialog is open. Accepted as is; not redesigned.
- R3 Concurrency: both callers lock the equipment row (`UpdLock`) before deciding, so a parallel register and post on the
  same equipment are serialized. Unverified in the sandbox (MS-SB9).
  **User decision (accepted, option B):** the confirm dialog (R2) is shown while the No. Series line and the equipment
  row lock are held, so other users registering, saving or posting on that series or equipment wait until the dialog
  is answered. Accepted.
- R4 The Equipment Card and its FactBoxes do not refresh after registering or posting from another page; a refresh
  shows the new status (same as FR-011 R6).
- R5 A partner rule in `OnAfterCheckEquipmentConsistency` or `OnBeforeStartMaintenance` that raises an error now also
  blocks registering or posting maintenance (S8, S25, S30). Intended (one transaction), document in the help.
- R6 Development data from FR-010/FR-011 with open records and Available equipment blocks assignment until posted
  (MS-SB0). Not a release issue.
- R7 Registering historical maintenance for assigned equipment (Q7 + Q2) returns the equipment from the employee. Users
  who only want to record past work on equipment still in use will have to reassign it after posting. Depends on the
  answers to Q2 and Q7.
- R8 No automated tests (Q9): regressions are caught only by review and the sandbox checks.
