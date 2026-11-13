# FR-025 Equipment Notes

> Status: **APPROVED** (user approved with the recommended answers to Q1 to Q4). Deviation: the card action is named `ShowEquipmentNotes` (the part keeps `EquipmentNotes`), because both names on one page fail with AL0155. Source: GitHub issue #63. Branch `feature/FR-025-equipment-notes`. No events report: only own objects change, and no standard behavior is hooked. No version bump (29.0.0.0, unreleased). No upgrade code.

## Goal
Users can record short operational notes on a piece of equipment (for example "28/06/2026 - Replacement charger issued."). Each note stores when it was written, who wrote it and the comment. Notes are listed newest first on the Equipment Card and can never be changed or deleted afterwards. This makes equipment traceable.

## Approach and rejected alternatives
- Chosen (Q1): new append-only table "EQM Equipment Note". The system sets Created At and User ID in `OnInsert`. `OnModify`, `OnDelete` and `OnRename` raise errors, as on tables 50106 and 50108. Users add notes in an insert-only ListPart on the card. A read-only list page is used for lookup, drill-down and the card action. No codeunit and no events.
- Rejected: the standard **Notes** FactBox (Record Link), which the card and list already show. Its note is a BLOB, it cannot be filtered or reported per field, any user with record-link rights can edit or delete it, and EQM roles cannot control it. It stays unchanged as the users' free notepad.
- Rejected: platform fields SystemCreatedAt/SystemCreatedBy instead of own fields. SystemCreatedBy is a GUID, which would need User read access to show a name. Explicit fields match tables 50103 and 50108.
- Rejected: an "Add Note" StandardDialog page plus a codeunit. It costs two extra objects, and the BC comment-sheet pattern (type on a new line) is enough.
- Rejected: an API entity in this phase. It is not requested, and it can be added later (FR-026 C10 spare pages 50126-50129).

## Objects
IDs in use (checked `app/src`, `test/src`): tables 50100-50108, pages 50100-50123, codeunits 50103-50118, enums 50100-50108, pageext 50100-50101, tableext 50100, permsets 50100-50102, permsetext 50103; test 50178-50180. Reserved: pages 50124-50129 and codeunits 50123-50129 (FR-026 C10), and test codeunits 50150-50177 and 50181-50182.
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Table | 50109 | EQM Equipment Note | New | Append-only notes, `app/src/Notes/EQMEquipmentNote.Table.al` |
| Page | 50131 | EQM Equipment Notes | New | Read-only List, Lookup/DrillDown page, `app/src/Notes/EQMEquipmentNotes.Page.al` |
| Page | 50130 | EQM Equipment Notes Part | New | ListPart on the card, insert-only, `app/src/Notes/EQMEquipmentNotesPart.Page.al` |
| Table | 50100 | EQM Equipment | Modify (own, Public) | `OnDelete` guard (Q3). **Behavior change on a public table** |
| Page | 50101 | EQM Equipment Card | Modify (own) | Part, navigation action, AboutText |
| PermissionSet | 50100 / 50101 | EQM - Reader / Manager | Modify (own) | See Permissions |
| Codeunit (test) | 50183 | EQM Equipment Note Tests | New | `test/src/EQMEquipmentNoteTests.Codeunit.al` |

## Data model and upgrade impact
- Table 50109: Caption 'Equipment Note', `DataClassification = CustomerContent` at table level, `Access = Public` (as 50106/50108), LookupPageId/DrillDownPageId = page 50131, DataCaptionFields "Equipment No.". Every field has a Caption and a ToolTip. Fields: 1 "Entry No." Integer AutoIncrement, PK clustered, Editable false. 2 "Equipment No." Code[20], TableRelation "EQM Equipment"."No.", NotBlank. 3 "Created At" DateTime, Editable false. 4 "User ID" Code[50], Editable false, field-level `DataClassification = EndUserIdentifiableInformation`. 5 Comment Text[250]. Secondary key EquipmentNo ("Equipment No.", "Entry No."). Fieldgroups: DropDown (Entry No., Equipment No., Created At, Comment) and Brick (Created At, User ID, Comment).
- `OnInsert`: TestField "Equipment No."; raise EquipmentNotFoundErr if the equipment does not exist (SetLoadFields "No."). Raise CommentRequiredErr if `DelChr(Comment, '<>', ' ')` is empty. Always overwrite: "Created At" := CurrentDateTime(), "User ID" := CopyStr(UserId(), 1, 50). `OnModify`, `OnDelete` and `OnRename` raise one label each (wording as table 50108, with "equipment note %1"). The labels carry Comments for their placeholders.
- No upgrade codeunit, because the table is new and the app is unreleased.

## Events
- Subscribed: none. Published: none. There is no partner need, and an IsHandled event would let a subscriber bypass immutability. Events can be added later without breaking anything.

## Permissions
- EQM - Reader: `tabledata "EQM Equipment Note" = R`; X on table 50109 and pages 50130 and 50131 (Q4: a Reader cannot add notes).
- EQM - Manager: `tabledata "EQM Equipment Note" = RI`. Administrator inherits it. No set gets M or D (notes are immutable for everyone, as in NFR-002 Q2). V1 may require an indirect `m`.

## Compatibility
- Additive except the new delete guard on table 50100 (Public). Deleting equipment that has notes now fails. This is acceptable because the app is unreleased, so no Obsolete handling is needed. **At first AppSource release, table 50109 (field IDs, names, types) becomes a contract.** Card and permission changes are additions only.

## Implementation steps
1. Create table 50109 (see Data model) and list page 50131 together, because they reference each other. Page 50131: List, `Editable/InsertAllowed/ModifyAllowed/DeleteAllowed = false`, `UsageCategory = History`, `SourceTableView = sorting("Entry No.") order(descending)`, columns Entry No. (hidden), Equipment No., Created At, User ID, Comment. AboutTitle/AboutText. AdditionalSearchTerms 'equipment notes, equipment comments, operational notes'. Compile.
2. Create page 50130: ListPart, Caption 'Equipment Notes', same SourceTableView, `DelayedInsert = true`, `InsertAllowed = true`, `DeleteAllowed = false`. Columns: Created At, User ID and Comment. Comment is `Editable = IsNewLine` (set `IsNewLine := Rec."Entry No." = 0` in OnNewRecord and OnAfterGetCurrRecord). Compile.
3. Table 50100 `OnDelete`: after the maintenance check, raise new label DeleteNotesExistErr 'You cannot delete equipment %1 because it has notes. To stop using the equipment, set its status to %2 instead.' with "No." and Format(Status::Disposed). Run it before `DeleteAttachedDocuments`. Check with a filtered `IsEmpty` on 50109. Compile.
4. Page 50101: add `part(EquipmentNotes; "EQM Equipment Notes Part")`, Caption 'Equipment Notes', SubPageLink "Equipment No." = field("No."), `UpdatePropagation = Both` is not needed. Place it after MaintenanceHistory, before group Audit. Add Navigation action `ShowEquipmentNotes` in EquipmentGroup (Caption 'Equipment Notes', ToolTip 'View all notes recorded for the equipment.', Image ViewComments, Enabled IsSaved, RunObject page 50131, RunPageLink "Equipment No." = field("No.")) and an actionref in Category_Category4. Append to AboutText: "**Equipment Notes** lists dated notes about the equipment; type a new line to add one. Notes cannot be changed or deleted." Compile.
5. Update permission sets 50100 and 50101 (see Permissions), in object order. Build, then commit the regenerated `Translations/Equipment Management.g.xlf` (no other translation files exist).
6. Create test codeunit 50183 (Subtype Test, TestPermissions Disabled, AutoRollback, helpers as in 50179). Copy the app labels the tests compare against as Locked test labels.
7. Documenter tasks: feature doc, help (add a note, immutability, the difference from the standard Notes FactBox), CHANGELOG, and a TODO section "FR-025 sandbox checks" (V1-V3, scenario 12).

## Test scenarios
Setup: active category LAPTOP, saved equipment E (LT001) and E2 (LT002), Available.
1. Given E, when a note with comment 'Charger issued' is inserted with Insert(true), then exactly one note exists for LT001, User ID = UserId(), and Created At is between the times taken before and after the insert.
2. Given a note with preset User ID 'X' and Created At 01-01-2020, when it is inserted, then both values are overwritten by the system.
3. (neg) A blank comment, or a comment of spaces only, gives CommentRequiredErr and no row is created.
4. (neg) A blank Equipment No. gives a TestField error. Equipment No. LT999 (not existing) gives EquipmentNotFoundErr. In both cases no row is created.
5. (neg) Given a note, Modify(true) with a changed comment raises ModifyNotAllowedErr and the comment is unchanged.
6. (neg) Given a note, Delete(true) raises DeleteNotAllowedErr and Rename raises RenameNotAllowedErr. The note still exists.
7. Given 2 notes on E and 1 on E2, filtering by Equipment No. returns 2 and 1.
8. (neg) Given E with a note, deleting E raises DeleteNotesExistErr, and E and its note still exist. Given E2 without notes, deleting it succeeds (regression).
9. Given E with 2 notes, renaming E to LT009 makes both notes carry LT009, and none carry LT001 (V1).
10. Given E with status Lost, adding a note succeeds.
11. TestPage card of E (2 notes): part EquipmentNotes shows the newest note first. Comment is not editable on an existing row and is editable on a new row. Action ShowEquipmentNotes opens page 50131 filtered on LT001. On a new, unsaved card the action is disabled.
12. Sandbox (manual): a Reader sees notes, and inserting gives a permission error. A Manager adds a note. No role (Administrator included) can edit or delete a note. Renaming E with notes as a non-SUPER Manager and as an Administrator works (V1). Tell Me finds "Equipment Notes".

## Risks and open questions
- **Q1 (design, default: own table).** Option A: own append-only table (this plan). Option B: rely only on the standard Notes FactBox that already exists, with docs only and no code. B cannot guarantee immutability or structured fields.
- **Q2 (rule, default: immutable).** Option A: nobody can edit or delete a note, and a correction is a new note. Option B: the author can edit or delete their own note (needs M/D and an author check).
- **Q3 (rule, default: block).** Option A: equipment with notes cannot be deleted (same as history and maintenance). Option B: deleting equipment also deletes its notes (needs an internal delete path around the OnDelete error).
- **Q4 (rule, default: Manager and up).** Option A: Manager and Administrator add notes, and a Reader only reads (NFR-002: a Reader changes nothing). Option B: a Reader may also add notes (`RI` in Reader).
- V1 Resolved (CI, commit dc2149d: test RenamingEquipmentMovesItsNotes passes, rename cascades, no fallback needed; was: unverified, same as HS-SB9): the platform's rename cascade on "Equipment No." might fire OnModify or need M permission. If scenario 9 or 12 fails, there are two fallbacks, both needing approval: block rename when notes exist, or grant an indirect `m` to the Manager.
- V2 Partly verified (the new-line test passes in CI; real web client typing not checked in a sandbox): `Editable = IsNewLine` on a repeater field with DelayedInsert lets you type on the new line and locks the line after the insert. OnModify stays the hard guard either way.
- V3 Comment may contain personal data (names). It is classified CustomerContent, consistent with the other free-text fields (TODO personal-data item).
- Assumed Created At is system-set and not user-entered, because back-dating would weaken traceability. The event date can be written in the comment, as in the issue example.
- Assumed Comment is Text[250] because notes are short, single-line operational remarks. Assumed notes are allowed in every status, because traceability covers the whole lifecycle.
- Assumed card only, with no notes FactBox on the list, because the list already has 5 FactBoxes and the requirement does not ask for one. Assumed the standard Notes systempart stays unchanged (least invasive).
- Assumed pages 50130/50131 and test codeunit 50183, because 50124-50129 and 50181-50182 are reserved (FR-026 C10).
- The issue text was not read directly, because the planner has no shell access. The coordinator should confirm that the acceptance criteria of #63 match the requirement above.
