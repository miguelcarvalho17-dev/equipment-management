# FR-014 Warranty Information

## Purpose
Users record the warranty of each piece of equipment on the equipment record: when it starts, when it ends, who provides it and its reference number. The data is shown in a Warranty section on the Equipment Card, so users can check whether a repair is still covered before they register maintenance. All four fields are optional. When both dates are filled in, the end date must be later than the start date.

Status: describes the code as implemented (uncommitted changes on branch `feature/FR-014-warranty-information`). **No automated tests (deferred, plan decision Q8; test codeunit 50168 reserved, nothing written). Nothing was run in a sandbox; checks WS-SB1 to WS-SB8 are NOT verified. Build result and review verdict are not recorded here (not part of the documenter input); TODO(verify).** App version stays 29.0.0.0 (app.json unchanged). No new objects, no permission set change, no upgrade codeunit, no standard events subscribed, no events report.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50100 | EQM Equipment | New stored fields 17 "Warranty Start Date" (Date), 18 "Warranty End Date" (Date), 19 "Warranty Provider" (Text[100]), 20 "Warranty Reference No." (Text[50]); label `WarrantyEndDateErr`; local `CheckWarrantyDates`; local integration event `OnBeforeCheckWarrantyDates`; `CheckEquipmentConsistency` calls `CheckWarrantyDates` after `CheckSerialNoIsUnique`. |
| Page | 50101 | EQM Equipment Card | New group `Warranty` after group `Purchase`; AboutText mentions purchase and warranty information. |
| Page | 50100 | EQM Equipment List | Four warranty columns after Purchase Cost, `Visible = false`. |

## Behavior
- **Fields:** all four are optional and have no table relation. Existing equipment keeps blank values. Provider is free text (not a vendor link). Data classification is inherited from the table (`CustomerContent`).
- **Date rule:** `CheckWarrantyDates` raises `OnBeforeCheckWarrantyDates`; unless IsHandled, it exits when either date is blank, and raises `WarrantyEndDateErr` when "Warranty End Date" <= "Warranty Start Date". Equal dates are rejected. Only one date filled in is allowed. Clearing a date is always allowed.
- **Where it runs:** on `OnValidate` of fields 17 and 18, and in `CheckEquipmentConsistency` on `Insert(true)` / `Modify(true)`. `Modify(false)`, `Insert(false)` and direct assignment without a save bypass it (same limitation as the other consistency rules).
- **Error text:** 'The warranty end date %1 must be later than the warranty start date %2. Change one of the dates, or clear the date that is not known.' Dates are passed as `Date` values to `Error`; the regional format is TODO(verify) (WS-SB4).
- **Order of change:** because the check runs per field, moving a warranty to a later period by changing the start date first fails when the new start is after the old end date. Change the end date first, or clear it (plan risk R2; WS-SB5).
- **No other rules:** dates may be in the past or future, are not compared with Purchase Date, and stay editable on Lost and Disposed equipment. No calculated warranty status, FactBox field, view or notification.
- **Card:** group `Warranty` shows Warranty Start Date, Warranty End Date (Promoted), Warranty Provider (Promoted), Warranty Reference No. Controls inherit caption and ToolTip from the table.
- **List:** the four fields are hidden by default; show them with personalization and filter on them, for example on Warranty End Date. No key exists on these fields, so filtering scans the table.

## Setup
No setup. No new fields in Equipment Setup.

## Extending (events)
One published event, on table 50100 (local integration event, `IntegrationEvent(false, false)`):

| Event | Raised | Parameters | IsHandled |
|---|---|---|---|
| `OnBeforeCheckWarrantyDates(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)` | Before the end-after-start check, on every validation of fields 17 and 18 and on every `Insert(true)` / `Modify(true)`, also when the dates are blank (so a subscriber can enforce rules such as "both or neither"). | `Equipment`: the record being checked, passed by value (changes are not kept). `IsHandled`: set to true to skip the standard check. | Yes. Skips only the standard rule; raise an error in the subscriber to apply your own rule, or leave it silent to allow, for example, equal dates. |

Partners can also add rules with the existing `OnAfterCheckEquipmentConsistency`. No standard events are subscribed.

## Permissions
No change to permission sets. EQM - Reader has R on table 50100, EQM - Manager has RIM, EQM - Administrator inherits both.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See warranty fields on the card and the list | yes | yes | yes |
| Enter, change or clear warranty fields | no | yes | yes |
| Filter the Equipment list on warranty fields | yes | yes | yes |

From code reading, not a sandbox run (WS-SB7).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand.

## Upgrade and compatibility
Four new stored fields: schema sync adds nullable columns with blank values, which are valid. No upgrade codeunit, no key change; no destructive change expected, TODO(verify) in WS-SB2. Nothing is released, so no Obsolete handling. Public surface that becomes a contract at release: fields 17-20 on table 50100 and the event signature. Existing code paths (assign, return, status change, maintenance) cannot fail on the new rule, because existing equipment has blank dates.

## Test status
No test objects; test codeunit 50168 "EQM Warranty Tests" is reserved (plan Q8). Scenarios W1 to W26 in docs/plans/FR-014-warranty-information.md are a reference only. Sandbox checks WS-SB1 to WS-SB8 are listed in docs/TODO.md and are **not run**.

TODO(verify) in a sandbox:
- Publish over existing data without schema sync error.
- Error text and date format; the field-order behavior (R2).
- Collapsed Warranty group shows End Date and Provider; list columns can be shown and filtered.
- Reader/Manager permissions as non-SUPER users; new card teaching tip.

## Discrepancies plan vs code
- None found in the changed objects. Fields, captions, ToolTips, label, procedure, event, page controls and AboutText match the plan. The plan's doc updates to FR-007/FR-008 feature and help documents were not made in this step; TODO.
