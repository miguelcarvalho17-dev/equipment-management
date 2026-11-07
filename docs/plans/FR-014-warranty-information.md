# FR-014 Warranty Information

> Status: Approved (user approved with all defaults for Q1-Q9). Open questions Q1-Q9 (see "Risks and open questions") each have a
> proposed default, and the plan is written with these defaults. **Q1 (Warranty Provider as free text or as a vendor
> link) and Q2 (what happens when only one date is filled in) change the design if they are answered differently.**
> Source: GitHub issue #33. Branch: `feature/FR-014-warranty-information` (cut from `main` at 03cdfa5, after the FR-013
> merge and the README update).
> No events report. FR-014 only adds fields to this app's own table 50100 "EQM Equipment" and shows them on this app's
> own pages. It subscribes to no standard events and changes no standard behavior, so al-event-finder is not needed.
> Scope: main app only. **No new objects.** Four new **stored** fields on table 50100, one new business rule with one
> new integration event, and changes to two of the app's own pages. **No permission set change. No version bump**
> (app.json stays 29.0.0.0). **No upgrade logic.** Tests are deferred (Q8 default): test codeunit 50168 is reserved,
> and the tester step is skipped.
> Workflow for FR-014: planner -> (human approves plan) -> developer -> reviewer -> build -> **tester step SKIPPED
> (Q8)** -> documenter -> appsource-validator.

## Goal
Users can record the warranty of each piece of equipment: when it starts, when it ends, who provides it and its
reference number. The data is kept on the equipment record and shown in a Warranty section on the Equipment Card, so
users can check whether a repair is still covered before they register maintenance. Warranty information is optional,
and when both dates are filled in the end date must be later than the start date.

### Requirement restated
- W-R1 Maintain warranty information per equipment: Warranty Start Date, Warranty End Date, Warranty Provider, Warranty
  Reference Number.
- W-R2 Warranty End Date must be greater than (strictly later than) Warranty Start Date.
- W-R3 Equipment may exist without warranty information: all four fields are optional, and existing equipment stays
  valid with blank values.

### Interpretation (defaults, see Q1-Q9)
- **Warranty Provider (Q1):** free text, Text[100], like the existing Manufacturer field. A warranty is often given by
  the manufacturer or a service company that is not a vendor in Business Central.
- **Only one date filled in (Q2):** allowed. The rule W-R2 is checked only when both dates are filled in. A blank date
  means "not known" or "no warranty". Clearing a date is always allowed.
- **Equal dates (Q3):** not allowed. "Greater than" in the issue is read literally; a warranty that starts and ends on
  the same day is rejected. Partners can relax this through the new IsHandled event (Q7).
- **No other date rules:** dates may be in the past or in the future, and they are not compared with the Purchase
  Date (Q5).
- **Final statuses (Q9):** warranty fields can still be changed on Lost and Disposed equipment (no new status rule).
- **Display (Q4):** a new Warranty section on the Equipment Card, and four hidden columns on the Equipment List (users
  can show them through personalization and filter on them, for example on Warranty End Date). No FactBox change, no
  calculated warranty status, no view, no notification.

### What already exists and is reused
| Already present | Use in FR-014 |
|---|---|
| Table 50100 "EQM Equipment" (public, `DataClassification = CustomerContent` at table level), fields 1-16; procedure `CheckEquipmentConsistency(IsNewRecord)` called from `OnInsert` and `OnModify`; pattern "local check procedure with an `OnBefore...` IsHandled event" (`CheckSerialNoIsUnique` with `OnBeforeCheckSerialNoIsUnique`). | Four new fields 17-20. The new date check follows the same pattern and is called from field validation and from `CheckEquipmentConsistency`. |
| Page 50101 "EQM Equipment Card", group `Purchase` (Purchase Date, Purchase Cost). | New group `Warranty` placed directly after `Purchase`. |
| Page 50100 "EQM Equipment List", hidden columns `"Purchase Date"` and `"Purchase Cost"`. | Four hidden warranty columns placed directly after `"Purchase Cost"`. |
| Permission sets 50100 "EQM - Reader" (R on table 50100), 50101 "EQM - Manager" (RIM on table 50100), 50102 "EQM - Administrator". | Already cover the new fields; nothing to add. |

## Approach and rejected alternatives
- Chosen: four new stored fields on our own table 50100, field-level `OnValidate` checks for immediate feedback, the
  same check in `CheckEquipmentConsistency` so that code that assigns the fields without `Validate` is also caught on
  `Insert(true)` / `Modify(true)`, and a Warranty group on the card. No new objects.
- Rejected: a separate table "EQM Equipment Warranty" (one or many warranties per equipment) with its own page. The
  issue asks for one set of warranty fields per equipment; a new table, page, permissions and delete handling add cost
  without a requirement. It stays possible later if multiple warranties are needed (Q4).
- Rejected: a table extension. Table 50100 is our own table; extending it from the same app is not possible and not
  needed.
- Rejected: a Vendor link for Warranty Provider (`Code[20]` with `TableRelation = Vendor`). Warranty providers are often
  not vendors, and the link would need a name lookup with a Vendor read guard (as in FR-010/FR-011). Kept as the
  alternative in Q1.
- Rejected: checking the dates only on save (in `CheckEquipmentConsistency`). On the card a saved record is modified as
  soon as the user leaves the field, so the user would get the same error at almost the same moment but with a less
  precise context. Checking in both places gives feedback on the field and protects code paths.
- Rejected: requiring both dates as soon as one is filled in (or requiring dates when a provider is filled in). Not
  asked by the issue and it would block partial data that users do have, such as only an end date. Kept as the
  alternative in Q2.
- Rejected: a calculated warranty status (Active / Expired / Not Started) with styles, an "Under Warranty" view, or an
  expiring-warranties tile. Not requested; listed as follow-ups in Q4.

## Objects
IDs in use (checked in `app/src` on this branch): tables 50100-50106, pages 50100-50119, codeunits 50103-50109,
queries 50100-50103, enums 50100-50103, page extension 50100, permission sets 50100-50102, permission set extension
50103, profile "EQM EQUIPMENT MANAGER". Fields in use on table 50100: 1-16. Test app: no objects; test codeunits
50150-50167 are reserved by FR-001 to FR-013, none is built.

| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50100 | EQM Equipment | Modify (own) | Fields 17 "Warranty Start Date", 18 "Warranty End Date", 19 "Warranty Provider", 20 "Warranty Reference No."; new label `WarrantyEndDateErr`; local procedure `CheckWarrantyDates`; new integration event `OnBeforeCheckWarrantyDates`; call added in `CheckEquipmentConsistency` |
| Page | 50101 | EQM Equipment Card | Modify (own) | New group `Warranty` after group `Purchase`; AboutText updated |
| Page | 50100 | EQM Equipment List | Modify (own) | Four hidden warranty columns after `"Purchase Cost"` |

Not changed: tables 50101-50106; pages 50102-50119 (including the Equipment FactBox 50111 and the Maintenance FactBox
50115); all codeunits, queries and enums; page extension 50100; permission sets 50100-50102; permission set extension
50103; the profile; `app/app.json`; `test/`.
No new files.

Next free IDs after FR-014 (unchanged by this feature): tables 50107, pages 50120, codeunits 50110, queries 50104,
enums 50104, page extensions 50101, permission sets 50104; next free field on table 50100: 21. Test app: test codeunit
**50168 reserved for FR-014 "EQM Warranty Tests"**, not built now (Q8).

### Platform names and behaviors to verify before coding (not design choices)
If any of these fails, stop and report.
- Field names are at most 30 characters: "Warranty Start Date" (19), "Warranty End Date" (17), "Warranty Provider" (17),
  "Warranty Reference No." (22).
- Adding stored fields to a table that already has data in the development sandbox syncs without a destructive change
  (new nullable columns get the default blank value). Record the publish result in WS-SB2.
- A `Date` passed to `Error` with a `%1` placeholder is formatted in the user's regional date format.

### Table 50100 "EQM Equipment" (change)
New fields, after field 16 "Average Maintenance Cost". All are normal stored fields and inherit
`DataClassification = CustomerContent` from the table; do not set it on the fields. No `InitValue`, no `NotBlank`,
no `TableRelation`.

| ID | Name | Type | Caption | ToolTip | Trigger |
|---|---|---|---|---|---|
| 17 | "Warranty Start Date" | Date | Warranty Start Date | 'Specifies the date the warranty of the equipment starts. Leave it blank when the equipment has no warranty or the start date is not known.' | `OnValidate`: call `CheckWarrantyDates()` |
| 18 | "Warranty End Date" | Date | Warranty End Date | 'Specifies the date the warranty of the equipment ends. When both warranty dates are filled in, the end date must be later than the start date. Leave it blank when the equipment has no warranty or the end date is not known.' | `OnValidate`: call `CheckWarrantyDates()` |
| 19 | "Warranty Provider" | Text[100] | Warranty Provider | 'Specifies the company that provides the warranty, for example the manufacturer, the vendor or a service company.' | none |
| 20 | "Warranty Reference No." | Text[50] | Warranty Reference No. | 'Specifies the reference of the warranty, such as the contract, certificate or registration number from the warranty provider.' | none |

- No change to keys or field groups (DropDown and Brick stay as they are). No change to `OnInsert`, `OnModify`,
  `OnDelete` or to existing events.
- New label in the `var` section, after `StartMaintenanceAssignedQst`:
  `WarrantyEndDateErr: Label 'The warranty end date %1 must be later than the warranty start date %2. Change one of the dates, or clear the date that is not known.', Comment = '%1 = warranty end date, %2 = warranty start date';`
- New local procedure `CheckWarrantyDates()`, placed after `CheckStatusTransitionAllowed` and before `IsStoredRecord`,
  with a `/// <summary>`: "Checks that the warranty end date is later than the warranty start date. The check runs only
  when both dates are filled in." Steps, in this order (same order as `CheckSerialNoIsUnique`):
  1. Local `IsHandled: Boolean`. Raise `OnBeforeCheckWarrantyDates(Rec, IsHandled)`; when IsHandled: exit.
  2. When "Warranty Start Date" = 0D or "Warranty End Date" = 0D: exit.
  3. When "Warranty End Date" <= "Warranty Start Date": `Error(WarrantyEndDateErr, "Warranty End Date", "Warranty Start Date")`.
- `CheckEquipmentConsistency`: add the call `CheckWarrantyDates();` directly after the existing line
  `CheckSerialNoIsUnique();`. Update its `/// <summary>` text: after "serial number unique," insert "warranty end date
  later than the warranty start date when both are filled in,". Nothing else in the procedure changes.
- New integration event, placed after `OnBeforeCheckStatusTransitionAllowed` and before
  `OnAfterCheckEquipmentConsistency`, see Events.

### Page 50101 "EQM Equipment Card" (change)
- `area(Content)`: directly after `group(Purchase)` (before `part(AssignmentHistory ...)`), add `group(Warranty)` with
  `Caption = 'Warranty'` and these controls, in this order (control name = field name, no ToolTip, Caption or
  ApplicationArea on the controls; all inherited):
  - `"Warranty Start Date"`
  - `"Warranty End Date"` with `Importance = Promoted`
  - `"Warranty Provider"` with `Importance = Promoted`
  - `"Warranty Reference No."`
- No triggers on the new controls (the table validates).
- `AboutText` becomes: 'Here you manage one piece of equipment. The first sections show its details, its current status and who it is assigned to, and its purchase and warranty information. Use **Assign to Employee** and **Return** to change the assignment, and **Register Maintenance** to record maintenance work. Further down, **Assignment History** lists every assignment, **Maintenance History** lists every posted maintenance, and **Audit** shows who created the record and who changed it last.'
- Nothing else changes.

### Page 50100 "EQM Equipment List" (change)
- Repeater, directly after `field("Purchase Cost"; ...)` and before `field("Total Maintenance Cost"; ...)`, add in this
  order, each with `Visible = false` and nothing else: `"Warranty Start Date"`, `"Warranty End Date"`,
  `"Warranty Provider"`, `"Warranty Reference No."`.
- AboutText, views, actions and triggers do not change.

### Permission sets
No change. "EQM - Reader" already has R on tabledata "EQM Equipment" (users see the fields, cannot change them);
"EQM - Manager" has RIM (users can maintain the fields); "EQM - Administrator" inherits both.

### app.json, translations
- **app.json: no change.** Version stays 29.0.0.0.
- The build regenerates `app/Translations/Equipment Management.g.xlf` (four field captions and ToolTips, the label
  `WarrantyEndDateErr` with its comment, the group caption 'Warranty' and the changed card AboutText). Commit it; never
  edit it by hand. No inline `CaptionML`.

## Data model and upgrade impact
- Table 50100: four new **stored** fields (17 Date, 18 Date, 19 Text[100], 20 Text[50]). Schema sync adds four columns;
  existing rows get blank values, which are valid (W-R3).
- No new key. Filtering on Warranty End Date on the list reads without an index; acceptable for equipment volumes
  (follow-up only if users report slow filters).
- DataClassification: inherited `CustomerContent` from the table; nothing set on the new fields. Provider and
  reference are business data, not personal data.
- Upgrade codeunit: **not needed.** Nothing is released, the version stays 29.0.0.0, and blank is the correct value for
  existing equipment (no backfill, for example not from Purchase Date, Q5).
- Rename of equipment: the new fields are on the equipment record itself, so they move with it.

## Events
**Standard BC events: none.** No events report is required. Subscribed: none.

Published: **one new integration event** on table 50100, consistent with the existing IsHandled events on every other
equipment business rule (category active, serial number unique, employee eligible, status transition):
- `[IntegrationEvent(false, false)] local procedure OnBeforeCheckWarrantyDates(Equipment: Record "EQM Equipment"; var IsHandled: Boolean)`
- IsHandled: **yes.** Setting it to true skips the standard rule (end date later than start date), for example to allow
  a warranty that starts and ends on the same day or to apply a different rule. The record is passed by value (same as
  `OnBeforeCheckSerialNoIsUnique`); subscribers can read the dates and raise their own error.
- Doc comment: `/// <summary>` "Raised before the check that the warranty end date is later than the warranty start
  date, when either warranty date is validated and on insert and modify." `/// <param name="Equipment">` "The record
  being checked (passed by value; changes are not kept)." `/// <param name="IsHandled">` "Set to true to skip the
  standard check. Raise an error in the subscriber to apply your own rule."
- Raised on every validation of fields 17 and 18 and on every `Insert(true)` / `Modify(true)` of equipment, also when
  the dates are blank (the event comes before the blank check, so a subscriber can enforce rules such as "both or
  neither").
- Partners can also add rules through the existing `OnAfterCheckEquipmentConsistency`. Existing events are unchanged.

## Permissions
No permission set changes (see Objects).

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See warranty fields on the card and the list | yes | yes | yes |
| Enter, change or clear warranty fields | no (no M on table 50100) | yes | yes |
| Filter the Equipment list on warranty fields | yes | yes | yes |

## Compatibility
- AppSource mode, development phase: nothing is released, there is no baseline, and no Obsolete handling is needed.
- New public surface that becomes a contract after the first release: fields 17-20 on public table 50100 (names,
  types and lengths cannot change later without obsoletion) and the event `OnBeforeCheckWarrantyDates` (signature
  cannot change). If Q1 is later changed to a Vendor link after release, a new field is added and field 19 is obsoleted;
  deciding Q1 now avoids that.
- New behavior: `CheckEquipmentConsistency` (internal) now also raises the warranty error. Existing equipment has blank
  warranty dates, so no existing record or existing code path (assign, return, status change, maintenance start and
  completion) can fail on the new rule.
- No control, action or group is renamed or removed. The new card group is added between existing ones; existing
  personalizations still apply.
- Doc updates (documenter). Historical plans in `docs/plans/` are not edited.
  - New `docs/features/FR-014-warranty-information.md` and `docs/help/FR-014-warranty-information.md`: the four fields,
    the date rule (only when both dates are filled in, equal dates rejected), optional warranty, where the fields
    appear, how to show the list columns and filter on Warranty End Date, roles, the new event for partners.
  - `docs/help/FR-008-equipment-card.md` and `docs/features/FR-008-equipment-card.md`: new Warranty section.
  - `docs/help/FR-007-equipment-list-management.md`: new optional warranty columns.
  - `CHANGELOG.md`: new top section `## FR-014 Warranty Information (version stays 29.0.0.0, no bump)`.
  - `docs/TODO.md`: section "FR-014 sandbox checks" with WS-SB1 to WS-SB8.

## Test scenarios
**No automated tests in this iteration** (Q8 default, as in FR-003 to FR-013). Test codeunit 50168 "EQM Warranty
Tests" is reserved, and the tester step is skipped. The list is the reference for the developer and reviewer and for
the tests the user writes later (needs the test-app fix in `docs/TODO.md` first).

Test data, unless stated: active category LAPTOP; equipment E1 (LAPTOP, Available, saved with `Insert(true)`, all
warranty fields blank). Dates: `D1` = 1 January 2026, `D2` = 31 December 2027, `D0` = 31 December 2025.

Optional warranty (W-R3)
- W1 Given a new equipment record with all warranty fields blank, when it is inserted with `Insert(true)`, then no
  error is raised and all four fields are blank after `Get`.
- W2 Given E1 with blank warranty fields, when its Description is changed and `Modify(true)` runs, then no error is
  raised (the new rule does not affect equipment without warranty).
- W3 Given E1, when "Warranty Provider" = 'Contoso Service' and "Warranty Reference No." = 'WR-0001' are set without any
  dates and `Modify(true)` runs, then no error is raised and both values are stored.

Valid warranty (W-R1, W-R2)
- W4 Given E1, when "Warranty Start Date" is validated with D1, "Warranty End Date" with D2, the provider and the
  reference are set and `Modify(true)` runs, then all four values are stored unchanged.
- W5 Given E1, when only "Warranty Start Date" = D1 is validated and saved, then no error is raised (Q2).
- W6 Given E1, when only "Warranty End Date" = D2 is validated and saved, then no error is raised (Q2).
- W7 Given E1 with Start D1 and End D2, when "Warranty End Date" is validated with D1 + 1 day, then no error is raised
  (the smallest valid period).
- W8 Given E1 with Start and End in the future (Today + 10 and Today + 400), then no error is raised (no future-date
  rule).
- W9 Given E1 with Start D1 and End D2, when "Warranty Start Date" is validated with 0D, then no error is raised and
  the record can be saved; the same when End is cleared.

Invalid warranty (W-R2, negative)
- W10 Given E1 with Start D1, when "Warranty End Date" is validated with D0 (earlier), then the error
  `WarrantyEndDateErr` is raised with D0 and D1 in the text, and the stored record is unchanged.
- W11 Given E1 with Start D1, when "Warranty End Date" is validated with D1 (equal), then the same error is raised
  (Q3).
- W12 Given E1 with End D1, when "Warranty Start Date" is validated with D2 (later than the end), then the same error
  is raised with D1 and D2 in the text.
- W13 Given a new record where the fields are assigned directly (no `Validate`) with Start D2 and End D1, when
  `Insert(true)` runs, then the error is raised and no record is inserted.
- W14 Given E1 where the fields are assigned directly with Start D2 and End D1, when `Modify(true)` runs, then the
  error is raised and the stored record keeps its previous values.
- W15 Given E1 with an invalid pair assigned directly, when `Modify(false)` runs, then no error is raised (documented
  limitation R1, same as the other consistency rules).

Interaction with existing rules (regression)
- W16 Given E1 with Start D1 and End D2, when it is assigned to an active employee (`AssignEmployee`) and returned
  (`UnassignEmployee`), then both succeed and the warranty values are unchanged.
- W17 Given E1 with Start D1 and End D2, when maintenance is registered and posted, then the status changes to In
  Maintenance and back to Available with no error, and the warranty values are unchanged.
- W18 Given E1 with a valid warranty and status Disposed, when "Warranty Reference No." is changed and saved, then no
  error is raised (Q9).
- W19 Given E1 with a valid warranty, when it is renamed to E1-NEW, then the record E1-NEW has the same warranty
  values.

Event
- W20 Given a manual-binding test subscriber to `OnBeforeCheckWarrantyDates` that sets IsHandled = true, when End is
  validated equal to Start (D1/D1) and saved, then no error is raised; after the subscriber is unbound, the same input
  raises the error.
- W21 Given a test subscriber that counts calls, when "Warranty Start Date" is validated once and `Modify(true)` runs
  once, then the event is raised twice.

Pages (TestPage)
- W22 Given the Equipment Card on E1 (Manager permissions), then the Warranty group shows the four fields in the order
  Start, End, Provider, Reference, and all four are editable.
- W23 Given the Equipment Card on E1 with Start D1, when End is set to D0 on the page, then the error
  `WarrantyEndDateErr` is shown and the stored record is unchanged.
- W24 Given the Equipment List, then the four warranty fields exist on the page (hidden by default); with a filter on
  "Warranty End Date" (`..D2`), only equipment with an end date on or before D2 is shown.

Permissions (`TestPermissions = Restrictive`, with D365 BASIC)
- W25 Reader: the card shows the warranty values; changing a warranty field and saving raises a permission error.
- W26 Manager: entering, changing and clearing the warranty fields on the card works without a permission error.

### Manual sandbox checks (for the user)
- WS-SB1 Build with CodeCop, UICop and AppSourceCop: no errors or warnings; `.g.xlf` contains the new captions,
  ToolTips, the error label with its comment, the group caption and the new card AboutText.
- WS-SB2 Publish over the existing development data: no schema sync error; existing equipment opens with blank warranty
  fields.
- WS-SB3 Equipment Card: the Warranty section appears after Purchase; when collapsed it shows Warranty End Date and
  Warranty Provider.
- WS-SB4 Enter an end date earlier than or equal to the start date: the error appears on the field, the text is
  readable and the dates are in the regional format.
- WS-SB5 Change both dates of an existing warranty to a later period by changing the end date first, then the start
  date: no error. Changing the start date first to a date after the old end date gives the error (R2); record whether
  the message is clear enough.
- WS-SB6 Equipment List: the four columns can be shown through personalization; filtering on Warranty End Date works.
- WS-SB7 Non-SUPER Reader sees the warranty fields and cannot change them; non-SUPER Manager can.
- WS-SB8 Teaching tip of the Equipment Card shows the new text.

## Risks and open questions
Open questions (each has the default used in this plan; answer to change it):
- **Q1 Warranty Provider: free text or Vendor link.** Default: free text Text[100] "Warranty Provider". Alternative:
  "Warranty Vendor No." Code[20] with `TableRelation = Vendor`, a guarded vendor name on the card (reuse codeunit 50108
  `GetVendorName`) and a Vendor action; or both (vendor link plus free text). **Changes the design if answered
  differently** (field type, name, page controls, Vendor read guard).
- **Q2 Only one date filled in.** Default: allowed; the rule runs only when both dates are filled in. Alternatives:
  require Start whenever End is filled in; or require both or neither. Either adds one label and one check in
  `CheckWarrantyDates` and changes W5/W6/W9. **Changes the design if answered differently.**
- **Q3 Equal dates.** Default: rejected (strictly later, as the issue says). Alternative: allow End = Start (change
  `<=` to `<`).
- **Q4 Display and follow-ups.** Default: card group plus hidden list columns only. Not built: FactBox fields, a
  calculated warranty status (for example Active / Expired / Not Started) with a style, an "Under Warranty" or
  "Warranty Expired" view, an "expiring warranties" tile on the dashboard, a warning when maintenance is registered for
  equipment under warranty, or several warranties per equipment (separate table).
- **Q5 Default start date.** Default: no default. Alternative: fill Warranty Start Date from Purchase Date when it is
  blank and the Purchase Date is validated.
- **Q6 Reference type and length.** Default: Text[50] (keeps the case and spaces of the provider's reference).
  Alternative: Code[50] like "Serial No." (upper case, better for search and uniqueness).
- **Q7 New IsHandled event.** Default: publish `OnBeforeCheckWarrantyDates`, consistent with the other equipment
  rules. Alternative: no event (partners use `OnAfterCheckEquipmentConsistency` to add rules, but cannot relax this
  one). After release the signature is permanent.
- **Q8 Automated tests.** Default: deferred, as in FR-003 to FR-013; test codeunit 50168 reserved, tester step
  skipped, WS-SB1 to WS-SB8 are the verification.
- **Q9 Lost and Disposed equipment.** Default: warranty fields stay editable. Alternative: block changes in final
  statuses (adds a rule and a label).

Risks:
- R1 `Modify(false)`, `Insert(false)` or direct assignment without save bypass the rule (W15), as for every other
  consistency rule of table 50100. Accepted.
- R2 Because the check runs on field validation, moving a warranty to a later period by changing the start date first
  fails when the new start is after the old end. The message tells the user to change the other date or clear it.
  Accepted (same behavior as standard BC starting/ending date pairs); checked in WS-SB5.
- R3 Fields 17-20 and the event become permanent API at the first release (Q1, Q6, Q7 should be settled now).
- R4 No index on Warranty End Date; filtering on it scans table 50100. Acceptable for equipment volumes.
- R5 No automated tests (Q8): regressions are caught only by review and the sandbox checks.
