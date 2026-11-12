# FR-024 Document Attachments

> Status: **APPROVED** (user approved the plan; category field via tableextension chosen by the user). Implemented, reviewed and documented; the 12 tests are compiled but not run. Source: GitHub issue #62. Branch `feature/FR-024-document-attachments`. Events: `docs/plans/FR-024-document-attachments-events.md` (factbox is page 1178; symbols in `app/.alpackages`).
> User decision: classification through an EQM field on Document Attachment (1173) via tableextension, own enum (5 kinds + Other). Base enum "Attachment Document Type" (part of PK) is NOT extended. No version bump (29.0.0.0, unreleased). No upgrade code.

## Goal
Equipment records hold any number of files (purchase invoices, maintenance reports, warranty certificates, user manuals, delivery notes) through the standard Document Attachment framework, in any status. Users see them in an Attachments FactBox on the Equipment Card, add/manage them from an Attachments action, and classify each file with an EQM category shown only on equipment attachments.

## Approach and rejected alternatives
- Chosen: register table 50100 with the framework via 2 subscribers on codeunit 1173 (internal codeunit); FactBox page 1178 + action opening page 1173 via `OpenForRecRef`; tableextension on 1173 with enum field; pageextension on 1173 showing it only for equipment; `DeleteAttachedDocuments` in OnDelete, `MoveAttachmentsWithinSameRecordType` in a new OnRename.
- Rejected: own attachment table/pages: duplicates the standard framework the issue requires.
- Rejected: extending enum "Attachment Document Type": part of the PK, rewritten per table by the framework (user decision).
- Rejected: pageextension on factbox 1178: narrow FactBox, and SubPageLink filter timing for a `Visible` condition is unverified; category is shown in page 1173.
- Rejected: subscriber on `OnAfterInitFieldsFromRecRef` to preset category: nothing to infer it from; enum default Other suffices.
- Rejected: blocking rename of equipment: changes released-in-repo behavior; moving attachments keeps it working.

## Objects
IDs in use (checked `app/src`, `test/src`): tables 50100-50108, pages 50100-50122, codeunits 50103-50117, enums 50100-50107, pageext 50100, permsets 50100-50102, permsetext 50103, no tableext; test codeunit 50178.
| Type | ID | Name | New/Extend | Purpose |
|---|---|---|---|---|
| Enum | 50108 | EQM Attachment Category | New | `Extensible = true`; values (ordinal, name, caption): 0 Other 'Other', 1 "Purchase Invoice", 2 "Maintenance Report", 3 "Warranty Certificate", 4 "User Manual", 5 "Delivery Note"; declared in ordinal order. File `app/src/Attachments/EQMAttachmentCategory.Enum.al` |
| TableExtension | 50100 | EQM Document Attachment | Extend "Document Attachment" (1173) | Field 50100 "EQM Attachment Category". File `app/src/Attachments/EQMDocumentAttachment.TableExt.al` |
| PageExtension | 50101 | EQM Doc. Attachment Details | Extend "Document Attachment Details" (1173) | Shows the category column for equipment only. File `.../EQMDocAttachmentDetails.PageExt.al` |
| Codeunit | 50118 | EQM Doc. Attachment Subscr. | New | `Access = Internal`; 2 subscribers + helper `IsEquipmentAttachmentView`. File `.../EQMDocAttachmentSubscr.Codeunit.al` |
| Table / Page | 50100 / 50101 | EQM Equipment / Card | Modify (own) | OnDelete + new OnRename; FactBox, action, AboutText |
| PermissionSet | 50100 / 50101 | EQM - Reader / Manager | Modify (own) | 1173 R / RIMD; X on codeunit 50118 |
| Codeunit (test) | 50179 | EQM Doc. Attachment Tests | New | Test app, scenarios below |

## Data model and upgrade impact
- Field 50100 "EQM Attachment Category": Enum 50108, Caption 'Category', ToolTip 'Specifies the kind of document, such as a purchase invoice, maintenance report, warranty certificate, user manual or delivery note.', DataClassification CustomerContent (on the field; tableextension has no table-level property). No InitValue: default ordinal 0 = Other, so existing attachment rows of all tables read Other (hidden outside equipment).
- Attachment rows: Table ID 50100, "No." = equipment No., Document Type/Line No. at framework defaults. No upgrade codeunit (new field, unreleased app).

## Events
- Subscribed (codeunit 1173 "Document Attachment Mgmt", from events report, confidence medium): `OnAfterTableHasNumberFieldPrimaryKey(TableNo; var Result; var FieldNo)`: exit unless TableNo = Database::"EQM Equipment"; set Result true, FieldNo = field "No." (1). `OnAfterGetRefTable(var RecRef; DocumentAttachment)`: exit unless "Table ID" = 50100 and `RecRef.Number = 0`; open RecRef on 50100 and position it on the equipment with "No." (Get; leave unpositioned if not found, no error).
- Published: none (no partner need; additive later).

## Permissions
- EQM - Reader: `tabledata "Document Attachment" = R`, `codeunit "EQM Doc. Attachment Subscr." = X`. EQM - Manager: `tabledata "Document Attachment" = RIMD` (Administrator inherits; needed for delete/rename of equipment).

## Compatibility
- Unreleased: no Obsolete handling. At first AppSource release field 50100 on base table 1173, enum 50108 and its values become contract (never remove/renumber). Tableextension on a base table adds a companion column for every company/table: AppSource review risk, accepted by user decision; affix on field name satisfies AppSourceCop. Card/table: additions only, no breaking change. Uninstall leaves attachment rows with Table ID 50100 (standard behavior).

## Implementation steps
1. Enum 50108 (captions as above). Compile.
2. Tableextension 50100 with the field (see Data model). Compile.
3. Codeunit 50118: the 2 subscribers (see Events) plus internal `IsEquipmentAttachmentView(var DocumentAttachment): Boolean` = true when the "Table ID" filter equals `Format(Database::"EQM Equipment")` in filter group 0, 2 or 4 (restore the original filter group). `/// <summary>` on each. Compile.
4. Pageextension 50101: add field "EQM Attachment Category" after the file name column in the repeater, `Visible = IsEquipmentView`; set `IsEquipmentView` in `OnOpenPage` via step 3 helper. `ApplicationArea = All` on the control (pageextension has no page-level property). Compile.
5. Table 50100 OnDelete: after the 3 existing Error checks, get a RecordRef of Rec and call `Document Attachment Mgmt`.`DeleteAttachedDocuments(RecRef)`. New `OnRename`: RecordRefs of xRec and Rec, call `MoveAttachmentsWithinSameRecordType(FromRecRef, ToRecRef)`. Compile.
6. Page 50101: FactBox `part(AttachedDocuments; "Doc. Attachment List Factbox")`, Caption 'Attachments', placed right after Picture, SubPageLink "Table ID" = const(Database::"EQM Equipment"), "No." = field("No."). Navigation group EquipmentGroup: action `Attachments` (Caption 'Attachments', ToolTip 'Add a file, such as an invoice, manual or warranty certificate, to the equipment, or view and categorize the attached files.', Image Attach, Enabled = IsSaved): RecordRef of Rec, `Document Attachment Details`.`OpenForRecRef(RecRef)`, `RunModal()`, then `CurrPage.Update(false)`. actionref in Category_Category4. Append to AboutText: "The **Attachments** FactBox lists the files attached to the equipment; use **Attachments** to add files and set their category."
7. Permission sets 50100/50101 (see Permissions). Build; commit regenerated `.g.xlf`.
8. Test codeunit 50179 (TestPermissions Disabled, AutoRollback, pattern of 50178). Attachments created with table 1173 `SaveAttachmentFromStream(InStream, RecRef, FileName)` from a small text stream.

## Test scenarios
Setup: category LAPTOP, saved equipment E (LT001) without history.
1. Given E, when a file is saved as attachment for E's RecRef, then one 1173 row exists with Table ID 50100, "No." LT001, category Other.
2. Given E, when 3 files are attached, then 3 rows for E; another equipment E2 has 0 (filter by No.).
3. Given an attachment of E, when its category is set to Warranty Certificate and modified, then it reads back Warranty Certificate.
4. Given E with 2 attachments, when E is deleted, then 0 rows remain for Table ID 50100/LT001.
5. (negative) Given assigned E with attachments, when delete is attempted, then DeleteAssignedErr and attachments are unchanged (rolled back).
6. Given E with 2 attachments, when E is renamed to LT009, then 2 rows have "No." LT009 and 0 have LT001.
7. Given a Customer attachment, when subscribers run (attach to a Customer RecRef), then its "No." is the customer No. (subscribers do not interfere).
8. Given the card of E (TestPage, trap page 1173), when Attachments is invoked, then page 1173 opens filtered on E and the Category column is visible; given page 1173 opened for a Customer RecRef, then it is not visible.
9. Given a new unsaved card, then action Attachments is disabled; given E, then the FactBox part exists.
10. Sandbox: upload via FactBox/details, drill-down from FactBox opens file, FactBox count; Reader sees but cannot upload/delete.

## Risks and open questions
- V1 Unverified (no base source/sandbox): the 2 hooks suffice for filter/count/drill-down. Fallback per events report: `OnAfterSetDocumentAttachmentFiltersForRecRef`, page 1178 `OnAfterGetRecRefFail`.
- V2 (RESOLVED: scenario 6b failed in a test run, fallback applied) `MoveAttachmentsWithinSameRecordType` behavior for custom tables (low). If scenario 6 fails: in OnRename, rename each 1173 row of Table ID 50100 / xRec."No." to the new No. directly.
- V3 Filter group used by `OpenForRecRef` unknown; helper checks 0/2/4. Sales/Purchase "flow" fields on page 1173 for our table, and Document Type default (Quote), unverified/assumed harmless.
- V4 Tenant Media rights for upload/download not granted (consistent with FR-023); if sandbox shows a permission error, add `tabledata "Tenant Media"` (Reader r, Manager rimd).
- Assumed card only (no List FactBox) because the brief names the card. Assumed Other = ordinal 0 default because existing and newly uploaded rows need a neutral value. Assumed enum Extensible because AppSource partners may add kinds. Assumed attachments allowed on Lost/Disposed equipment because the requirement covers the whole lifecycle.
- Docs (documenter): feature doc, help (FactBox, action, categories), CHANGELOG, TODO "FR-024 sandbox checks" (V1-V4, scenario 10).
