# FR-025 Equipment Notes

## Purpose
Users record short operational notes on a piece of equipment (GitHub issue #63). Each note stores when it was written, who wrote it and the comment. Notes are listed newest first on the Equipment Card and can never be changed or deleted, so the history of the equipment stays traceable. The standard Notes FactBox (record links) is unchanged and remains a free notepad; it is not immutable and not controlled by EQM roles.

Status: implemented, not committed at the time of writing. **Build: reported as compiled by earlier steps; the documenter changed no AL code and did not re-run the build.** **Tests: CI on PR 113 ran codeunit 50183: 17 of 18 passed; the failing one (note typed on a new card part line) exposed a blank "Equipment No." on the new line, fixed by an OnNewRecord trigger in the part; not re-run yet.** Plan verification V1 is confirmed (RenamingEquipmentMovesItsNotes passes); V2 is partly verified; manual scenario 12 is unverified. App version stays 29.0.0.0. No upgrade codeunit, no event published or subscribed.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50109 | EQM Equipment Note | New, `Access = Public`, append-only |
| Page | 50131 | EQM Equipment Notes | New, read-only list, newest first, `UsageCategory = History` |
| Page | 50130 | EQM Equipment Notes Part | New, ListPart on the card, insert-only |
| Table | 50100 | EQM Equipment | `OnDelete` blocks delete when notes exist |
| Page | 50101 | EQM Equipment Card | Part `EquipmentNotes`, action `ShowEquipmentNotes`, AboutText sentence |
| PermissionSet | 50100 / 50101 | EQM - Reader / Manager | See Permissions |
| Codeunit (test app) | 50183 | EQM Equipment Note Tests | 18 tests; 17 passed in CI, 1 fixed and not re-run |

## Fields (table 50109)
| Field | Meaning |
|---|---|
| 1 "Entry No." | Integer, auto-increment, primary key. Not editable. |
| 2 "Equipment No." | Equipment the note belongs to. Relation to "EQM Equipment"."No.", must not be blank. |
| 3 "Created At" | Date and time of the insert. Set by the system, not editable. |
| 4 "User ID" | User who inserted the note (`UserId()`, cut to 50 characters). Set by the system, not editable. Classified EndUserIdentifiableInformation. |
| 5 Comment | The note text, Text[250]. Required. |

Table classification is CustomerContent. Secondary key `EquipmentNo` ("Equipment No.", "Entry No."). Field groups DropDown and Brick are defined. Lookup and drill-down open page 50131.

## Behavior
- **Insert (`OnInsert`):** raises an error if "Equipment No." is blank (TestField), if the equipment does not exist, or if Comment is empty or only spaces. Then it always overwrites "Created At" with `CurrentDateTime()` and "User ID" with the current user, so values supplied by the caller are ignored.
- **Immutable:** `OnModify`, `OnDelete` and `OnRename` each raise an error. Correction is done by adding a new note.
- **Delete equipment:** after the checks for assignment, assignment history and maintenance records, `OnDelete` of table 50100 raises an error if any note exists for the equipment (message points to status Disposed). The check runs before the attachments are deleted.
- **Status:** notes can be added in any status, including Lost and Disposed.
- **Card part `EquipmentNotes`:** ListPart sorted by "Entry No." descending, linked on "Equipment No." = "No.". Insert allowed with `DelayedInsert`, delete not allowed. Comment is editable only on a new line (`IsNewLine`, set in `OnNewRecord` and `OnAfterGetCurrRecord`). The part is `Editable = IsSaved`, so notes cannot be added on a new, unsaved card.
- **Action `ShowEquipmentNotes`** (navigation group, promoted, Image ViewComments): enabled only when `IsSaved`. Opens page 50131 filtered on the equipment. Named `ShowEquipmentNotes` because the part is called `EquipmentNotes` and both names cannot exist on one page (AL0155).
- **Page 50131:** list is read-only (no insert, modify, delete). Columns: Equipment No., Created At, User ID, Comment; Entry No. is hidden. Search terms: equipment notes, equipment comments, operational notes.

## Setup
No setup. Assign the permission sets (see below). TODO(verify): that the part and the action appear by default in the web client.

## Extending (events)
Published: none. Subscribed: none. No `IsHandled` event is offered on purpose: a subscriber could bypass immutability. Table 50109 is `Access = Public`, so partners can read it and insert through the table trigger.

## Permissions
| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See notes (card part, list, lookup) | yes (`tabledata` R, X on table 50109 and pages 50130, 50131) | yes | yes |
| Add a note | no | yes (`tabledata` RI) | yes (inherited) |
| Change or delete a note | no | no | no (no set grants M or D, and the table triggers block it anyway) |

Pages 50130 and 50131 are executable for the Reader set. The Manager set inherits them, TODO(verify) in a sandbox.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit by hand. It contains entries for the new objects.

## Upgrade and compatibility
New table on an unreleased app: no upgrade code. The new delete guard on public table 50100 is a behavior change: equipment with notes can no longer be deleted. At first AppSource release, table 50109 (field IDs, names, types) becomes a contract; never remove or renumber. Card and permission changes are additions only.

## Known limitations
- Card only: no notes FactBox on the Equipment List.
- No API entity for notes in this phase (FR-026 covers equipment only).
- Comment is a single line of up to 250 characters. It may contain personal data; classified CustomerContent like other free-text fields.
- A note cannot be corrected or removed; add a new note.

## Test status
- 18 test procedures in codeunit 50183 (`test/src/EQMEquipmentNoteTests.Codeunit.al`, `TestPermissions = Disabled`, AutoRollback) ran in CI on PR 113: **17 of 18 passed**. The failing test (note typed on a new part line) raised "Equipment No. must have a value" from the table TestField; the part now fills "Equipment No." in OnNewRecord from its single-value filter, and the fixed test has not been re-run. They cover: user and time set on insert; preset values overwritten; blank and spaces-only comment rejected; blank and unknown equipment rejected; modify, delete and rename of a note rejected; notes separated per equipment; delete of equipment with notes rejected and without notes succeeds; rename of equipment moves its notes; note on Lost equipment; card part newest first with existing lines locked; note typed on a new part line is saved; action opens the list filtered on the equipment; action disabled on a new card.
- Not covered by tests: Reader and Manager rights.
- Unverified:
  - **V1:** whether renaming equipment cascades "Equipment No." into the notes despite the `OnModify` error, and whether it needs an indirect `m` right for the Manager. **Confirmed by CI:** test `RenamingEquipmentMovesItsNotes` passes, so the rename cascades; no fallback needed. (Old text: plan fallbacks (need approval): block rename when notes exist, or grant indirect `m` to Manager.)
  - **V2:** whether `Editable = IsNewLine` with `DelayedInsert` lets the user type on the new line and locks it after the insert. `OnModify` is the hard guard either way. Partly verified: the CI failure showed the new line did not carry "Equipment No." from the SubPageLink in the test page; the part now sets it in OnNewRecord. Typing on the real client is still to be checked in a sandbox.
  - **Manual scenario 12 (sandbox):** Reader sees notes and cannot insert; Manager adds a note; nobody can edit or delete; rename with notes as non-SUPER Manager and as Administrator; Tell Me finds "Equipment Notes".

## Discrepancies plan vs code
- The card part has `Editable = IsSaved`; the plan does not mention it.
- The plan and the task description speak of 19 tests; the codeunit contains 18 test procedures (plus helpers and one page handler).
- Otherwise the code matches the plan (plan status APPROVED).
