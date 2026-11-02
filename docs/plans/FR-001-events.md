# Event search report: FR-001 Equipment Registration (Employee delete guard, inactive employee check)

**Feature:** (1) block deleting a standard Employee while an EQM Equipment record references it with Status = Assigned; (2) reject assigning equipment to an inactive employee.
**Target:** BC 29 (application 29.0.0.0), runtime 18.0, AppSource mode  |  Symbols from .alpackages checked: **NO, the folder `app/.alpackages` is empty** (no Base Application or System Application .app files anywhere on this machine)  |  Base app source available: no (`BASEAPP_SOURCE_PATH` is a placeholder)

**Important:** `list_events.py` could not be run, so nothing below is verified against BC 29 symbols. Per the skill rules, every name is marked "implicit (not verified in symbols)" or "from memory, verify". Download symbols in VS Code (AL: Download Symbols) and re-run before development; see "Verification steps".

## Search terms used (planned, could not be executed)
Objects: Employee, "Employee Absence", "Employee Ledger Entry". Keywords: delete, remove, terminate, inactive, status, blocked, privacy. Synonyms: dismiss, deactivate.

## Requirement 1: block deleting an Employee while equipment is assigned

### Recommendation
**Subscribe to** `OnBeforeDeleteEvent` on table Employee (implicit table trigger event, not verified in symbols).
```al
[EventSubscriber(ObjectType::Table, Database::Employee, 'OnBeforeDeleteEvent', '', false, false)]
local procedure EmployeeOnBeforeDelete(var Rec: Record Employee; RunTrigger: Boolean)
```
- Moment: fires before the Employee OnDelete trigger body runs, so our error stops the delete before base cleanup. The error also rolls back the transaction either way.
- Data: Rec."No." is all that is needed. Check with `SetLoadFields`, key "Assigned Employee No.", filter "Assigned Employee No." = Rec."No." and Status = Assigned, then `IsEmpty`. The plan already defines a non-unique key on "Assigned Employee No.", so the lookup is cheap.
- Frequency: once per Employee delete (rare). Early exits: `if not RunTrigger then exit;` and `if Rec.IsTemporary() then exit;` (the event fires for temporary records too; the skill notes this).
- Override: none needed (we raise an error). Do not use the event to change Rec.
- Confidence: **medium**. Implicit events on a table trigger are a documented platform mechanism and the standard approach, and Employee is a regular table that is deletable with triggers. Not seen in symbols or source here.
- Caveat: the implicit event only fires when the delete runs with triggers (`Delete(true)`, UI delete). Deletes with `RunTrigger = false` bypass it (same limit as any trigger-based rule). If the record is deleted with `Delete(false)`, we cannot block it.
- Design note: the plan says "Assigned Employee No." has `TableRelation = Employee."No."`. A table relation without `ValidateTableRelation = false` does not by itself block deleting the target on the Employee side, so the subscriber is needed. Consider also whether the check should ignore Status (a non-Assigned item cannot hold an employee by the plan's rule, so filtering on Status is redundant but harmless; matching on employee alone is more robust to bypassed validation).
- Error text: own label with Comment in the new subscriber codeunit; one full sentence, `%1 = employee no.`.
- Public API note (AppSource): subscribe from an `internal`/non-public codeunit, e.g. "EQM Employee Subscribers"; no public surface added.

### Alternatives considered
| Candidate | Why ranked lower |
|---|---|
| `OnAfterDeleteEvent` on Employee (implicit, not verified) | Fires after the delete has run; error still rolls back, but base cleanup (related records) has already executed, wasted work and hides intent. Rank 2 only if OnBeforeDelete proves problematic. |
| Published event on Employee delete or in an Employee-related codeunit (e.g. an `OnBeforeDelete...` integration event) | None known; **could not search symbols**. Re-run `list_events.py --object Employee --keyword delete` before accepting that none exists. A published event would rank first if found (stability). |
| `OnBeforeRenameEvent` / `OnAfterRenameEvent` on Employee (implicit) | Not requested. Note: renaming an Employee cascades through the TableRelation automatically; no code needed. |
| TableExtension on Employee with an `OnDelete` trigger | Not possible in AL: table extensions cannot add or change table triggers. |
| FlowField "Assigned Equipment" on an Employee tableextension plus TestField in OnDelete | Same limitation (no trigger in tableextension); still needs the event. |
| Foreign-key style integrity via TableRelation only | Does not block parent deletes in BC. |

## Requirement 2: reject assigning equipment to an inactive employee

### Recommendation
**No event is needed.** Implement it inside "EQM Equipment" `CheckAssignedEmployeeAllowed` (internal; already called from "Assigned Employee No." OnValidate and from `CheckEquipmentConsistency`). Read the Employee record (`Employee.Get`, `SetLoadFields(Status, "Privacy Blocked")` or the fields confirmed below) and raise an own error.
- Confidence: **high** that no event is required (we own both the table and the validation trigger). **Low-to-medium** on the exact Employee field names until symbols are checked.
- The plan's published `OnBeforeCheckAssignedEmployeeAllowed(IsHandled)` already lets partners relax the rule, which covers the "inactive employees allowed" scenario. If the user decides inactive employees must be rejected (open question 9, assumption 9 currently says allowed), place the Employee check after the IsHandled exit.

### Which Employee fields define "inactive" (from memory of the BC Employee table 5200; NOT verified for BC 29)
| Field | Type | Meaning | Use in check |
|---|---|---|---|
| Status | Enum "Employee Status": Active (0), Inactive (1), Terminated (2) | Primary state | Reject when Status <> Active (Inactive and Terminated both rejected) |
| "Termination Date" | Date | Set when terminated; Status = Terminated is normally set alongside it | Informational only; do not use alone |
| "Inactive Date" | Date | Set when Inactive | Informational only |
| "Privacy Blocked" | Boolean | Privacy/GDPR block; base code refuses to use a privacy-blocked employee on documents | Reject when true (also blocks reading personal data in some flows) |
| "Blocked" | not known to exist on Employee | Customer/Vendor/Item have it; I do **not** believe Employee has one | Do not use unless symbols show it |

Notes:
- Status is an enum; compare with the enum value, never an integer. Whether the enum is extensible and its exact name ("Employee Status") must be confirmed in symbols.
- Base Employee table has a `CheckBlockedEmployee`-style procedure? Unknown, **not verified**; do not call anything unless symbols show it as public. Prefer reading fields directly.
- Reading "Privacy Blocked" for an Employee that does not exist: `Get` fails first; the TableRelation already raises the "not found" error, so only run the check when the Employee exists (TableRelation validation runs before OnValidate body, in the standard order, but guard with `if Employee.Get(...)`).
- Test impact: tests 20 and 21 use an existing employee created by the library; if the library creates employees Active (expected for `Library - Human Resource` CreateEmployee, verify), no test change; add tests for Inactive, Terminated, Privacy Blocked if the rule is adopted.

## Published events found (from symbols)
None: symbols were not available, the script was not run. Do not read this as "no published events exist".

## Gaps and risks
- **Symbols missing**: `app/.alpackages` is empty. The coordinator must download symbols for BC 29 (Base Application + System Application) and re-run, at minimum:
  `python3 .claude/skills/al-event-search/scripts/list_events.py app/.alpackages --object Employee`
  `python3 .claude/skills/al-event-search/scripts/list_events.py app/.alpackages --keyword delete --type table`
  to confirm (a) Employee field names/types for Status and Privacy Blocked, (b) absence or presence of a published Employee delete event.
- Where the base Employee OnDelete raises and which records it removes before/after was **not verified** (no source). Confirm in the debugger or Event Recorder that our error fires with the expected message when deleting an Employee from the Employee Card with one Assigned equipment.
- Employee delete in some flows (e.g. configuration packages, data migration) runs with `RunTrigger = false`; the guard does not apply there. Accepted limitation, document in the help article.
- The scenario changes standard behavior (a delete that was previously allowed is now refused). In AppSource mode this is an accepted pattern (error from subscriber), but it needs a clear message and a test using `Delete(true)` on an Employee with a manually bound subscriber or the real subscriber (test scenarios to add by the planner).
- Planned scope change: FR-001 plan says "Subscribed: none" and treats dangling references as out of scope; adding this subscriber changes that section, the object list (one new internal codeunit, next free ID 50103) and the test list. The planner must update the plan.
- Permissions: the subscriber reads tabledata "EQM Equipment" when a user deletes an Employee. A user who can delete employees but has no EQM permission would get a permission error instead of our check. Mitigation: set the subscriber codeunit `Permissions = tabledata "EQM Equipment" = r;` (indirect permission) in the codeunit, and include it in the AppSource permission review. Also, "Employee" read permission is provided by the base set.

## Verification steps (ordered)
1. Download BC 29 symbols; run the two script queries above.
2. Confirm Employee `Status` enum name and values, `Privacy Blocked`, `Termination Date`, `Inactive Date`, and absence of a `Blocked` field.
3. Event Recorder or debugger: delete an Employee from the UI and confirm the OnBeforeDelete subscriber fires once, with `RunTrigger = true`.
4. Add tests: delete blocked while assigned; allowed after unassign; allowed when equipment is Available.
