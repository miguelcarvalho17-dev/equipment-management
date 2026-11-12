# Event search report: FR-024 Document Attachments

**Feature:** Equipment (table 50100 "EQM Equipment") supports multiple document attachments through the standard Document Attachment framework (table 1173, page 1173 "Document Attachment Details", factbox page 1178 "Doc. Attachment List Factbox", codeunit 1173 "Document Attachment Mgmt").
**Target:** BC 29 (Base Application 29.0.54011.57272; symbols in `app/.alpackages`, repo-root `.alpackages` does not exist)  |  Base app source available: no (BASEAPP_SOURCE_PATH not set). Signatures below come from symbols (script output and SymbolReference.json). Symbols do not show where or in what state an event is raised, so runtime behavior is marked "not verified".
Search terms: document attachment, attachment details, doc. attachment list factbox, GetRefTable, table has number field primary key, copy attachments, delete attached documents, attachment document type, rename/move attachments.

## Corrections to the brief
- The factbox is **page 1178 "Doc. Attachment List Factbox"** (PageType ListPart, SourceTable 1173, InsertAllowed = false, DeleteAllowed = true). There is no page 1174 factbox; 1174 is the enum "Document Attachment File Type". Use the name, not the number: `part(DocAttachment; "Doc. Attachment List Factbox")`.
- Page 1173 has no `OnBeforeDrillDown`-type event. The page's only events are `OnAfterOpenForRecRef` and `OnBeforeImportWithFilter`. The factbox has `OnAfterGetRecRefFail` and `OnBeforeDocumentAttachmentDetailsRunModal`.
- Procedure name in symbols is spelled `TableHasNumberFieldPrimayKey` (typo in the base app). The event is spelled correctly: `OnAfterTableHasNumberFieldPrimaryKey`.

## Recommendation
**Subscribe to** `OnAfterTableHasNumberFieldPrimaryKey` and `OnAfterGetRefTable` on codeunit 1173 (two small subscribers in one internal codeunit, `Access = Internal`), plus call the public API directly from our own objects. No other event is required.
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasNumberFieldPrimaryKey', '', false, false)]
local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)

[EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterGetRefTable', '', false, false)]
local procedure OnAfterGetRefTable(var RecRef: RecordRef; DocumentAttachment: Record "Document Attachment")
```
- What each does (planner to implement; bodies are a plan matter):
  1. `OnAfterTableHasNumberFieldPrimaryKey`: if `TableNo = Database::"EQM Equipment"` set `Result := true` and `FieldNo := 1` ("No." is field 1 of table 50100; confirm in the table file). This tells the framework which field of our primary key goes into Document Attachment."No.". Without it the framework does not know our key, so attachments would not be stored/filtered by equipment number.
  2. `OnAfterGetRefTable`: if `DocumentAttachment."Table ID" = Database::"EQM Equipment"` and `RecRef` is not yet open, `RecRef.Open(Database::"EQM Equipment")`, `RecRef.Get(DocumentAttachment."No.")`. Used when the framework resolves the attached-to record from an attachment row (factbox/details drill-down, "go to document" style flows). Check `RecRef.Number` first so other tables are untouched.
- Moment: both are raised after the framework's own table-ID case logic (standard names `OnAfter...`), so they are extension hooks for tables the base app does not know.
- Data: TableNo / Table ID are enough for an early exit.
- Frequency: low (once per factbox refresh/page open). Exit immediately when the table is not ours.
- Override: `var` parameters (Result, FieldNo, RecRef). No IsHandled, not needed.
- Stability: both are the intended extension points for custom tables; widely used by partner apps. Good for AppSource.
- **Confidence: medium.** Signatures verified from symbols. That `OnAfterTableHasNumberFieldPrimaryKey` is the hook that makes a custom table with a "No." key work is from knowledge of the framework, not verified (no source). Verified in sandbox by: add attachment on an equipment record, then check Document Attachment rows have Table ID 50100 and "No." = equipment number, and the factbox count/list filters correctly.
- Not an event but required (part of the standard pattern, no event involved):
  - Equipment Card (and optionally List) factbox: `part(DocAttachment; "Doc. Attachment List Factbox") { SubPageLink = "Table ID" = const(Database::"EQM Equipment"), "No." = field("No."); }`. Standard pattern as on Customer/Item cards; the SubPageLink shape is from knowledge, not verified from symbols.
  - Action "Attachments" on the card opening page 1173 via `DocumentAttachmentDetails.OpenForRecRef(RecRef)` (public procedure `OpenForRecRef(RecRef)` is in symbols) then `RunModal()`.

## Alternatives and other candidates
| Candidate | Verdict |
|---|---|
| Codeunit 1173 `OnAfterSetDocumentAttachmentFiltersForRecRef(var DocumentAttachment, RecRef)` | Backup. Use only if the standard filter on Table ID + "No." is wrong for our table (it should not be). Ranked lower: only needed when the number-key hook alone does not filter correctly. Not verified. |
| Page 1173 `OnAfterOpenForRecRef(var DocumentAttachment, var RecRef, var FlowFieldsEditable, var PurchaseDocumentFlow)` | Alternative place to set `FlowFieldsEditable := false` and `PurchaseDocumentFlow := false` for equipment. Optional; flow fields (Sales/Purchase/Service/Production) are only relevant for document tables. Ranked lower: only cosmetic, and codeunit 1173 `OnAfterIsFlowFieldsEditable(TableNo, var Editable)` is a cleaner place. Behavior for custom tables without it: not verified; check in sandbox that Document Flow fields are hidden or harmless. |
| Page 1178 `OnAfterGetRecRefFail(var DocumentAttachment, var RecRef)` | Fallback. Raised when the factbox cannot open the RecRef from the row (our table not recognized). If `OnAfterGetRefTable` (above) is enough, not needed. Not verified when raised. |
| Page 1178 `OnBeforeDocumentAttachmentDetailsRunModal(var DocumentAttachment, var RecRef, var DocumentAttachmentDetails)` | Not needed. Only to alter the Details page before it opens. |
| Codeunit 1173 `OnBeforeDeleteAttachedDocumentsWithConfirm(RecRef, var IsHandled)` | Not needed. Would only change the confirmation dialog. |
| Table 1173 `OnBeforeInsertAttachment`, `OnBeforeSaveAttachment`, `OnAfterInitFieldsFromRecRef`, `OnBeforeSaveAttachmentFromStream` | Possible only if we want to set an extra field (e.g. attachment category, see below) at upload time. `OnAfterInitFieldsFromRecRef(var DocumentAttachment, var RecRef)` is the best fit because it runs while the row is initialized from the record. Not needed for the base requirement. |
| `OnAfterTableHasDocTypePrimaryKey`, `OnAfterTableHasLineNumberPrimaryKey`, `OnAfterTableIsDocument`, `OnAfterTableIsDocumentHeader`, `OnAfterTableIsDocumentLine`, `OnAfterTableIsEntity` | Do not subscribe. Our table has no document type or line number in its key and is not a document; leaving them untouched keeps Document Type and Line No. at defaults (not verified). `OnAfterTableIsEntity` is unclear in purpose; not verified, do not use without a reason. |
| Codeunit 1173 `OnBeforeCopyAttachments`, `OnCopyAttachmentsOn...` events | No copy flow exists for equipment (no "copy equipment" feature in the repo). Not needed. |

## Delete, rename and lifecycle behavior
- **Delete equipment: no event needed.** Table 50100 is our own: in its `OnDelete` trigger (existing checks at the end of the trigger: Assigned, assignment history, maintenance records), after the checks pass call the public `Document Attachment Mgmt` procedure `DeleteAttachedDocuments(RecRef)` (symbols: `DeleteAttachedDocuments(RecRef: RecordRef)`; an overload `DeleteAttachedDocuments(ForVariantRec: Variant; WithConfirm: Boolean)` also exists). Standard tables call it from their own `OnDelete`. Whether it deletes rows by Table ID + "No." only is not verified (no source). Place it after the existing Error checks so a blocked delete does not lose attachments. Subscribing to `OnAfterDeleteEvent` of our own table is rejected: it is our own table, a direct call is simpler and testable.
- **Equipment with history can never be deleted** (existing OnDelete checks; equipment goes to status Disposed instead). So attachments of used equipment stay for the whole lifecycle, which matches the requirement "available throughout the lifecycle". No code needed.
- **Rename:** symbols show `MoveAttachmentsWithinSameRecordType(MoveFromRecRef, MoveToRecRef)` (public) and an event `OnMoveAttachmentsWithinSameRecordTypeOnBeforeInsert(var DocumentAttachmentToCreate, MoveToRecRef, MoveToRecNo)`. Only needed if the "No." of equipment can be renamed. Planner to check the table (field 1 and any rename path); if renaming is allowed, call `MoveAttachmentsWithinSameRecordType` from `OnRename`. Confidence low (not verified how the procedure treats custom tables).
- **Copy:** no copy feature; none needed.
- **Permissions:** users who attach need rights on table 1173 "Document Attachment" (and Tenant Media for the Document Reference ID media field). Standard permission sets (D365 BASIC etc.) usually include this; our permission sets 50100-50102 should add `tabledata "Document Attachment" = RIMD` for Manager/Administrator and `= R` for Reader. Verify against the plan and the permission-set symbols; not checked here.

## Document type classification (purchase invoice, maintenance report, warranty certificate, user manual, delivery note)
- **No suitable published event.** Table 1173 has no free-text type/category field. "Document Type" (field 13) is of enum "Attachment Document Type" (extensible; values in symbols: Quote, Order, Invoice, Credit Memo, Blanket Order, Return Order, VAT Return Submission, VAT Return Response, Service Contract Quote, Service Contract). It is part of the primary key (Table ID, No., Document Type, Line No., ID) and it models sales/purchase document types, not attachment categories. Do not extend it with "Warranty Certificate" etc.: it would be misleading and `OnAfterTransformAttachmentDocumentTypeValue(TableNo, var AttachmentDocumentType)` shows the framework rewrites the value per table.
- Options for the planner, ranked:
  1. **Own category field via a table extension on 1173 plus a page extension on 1173 and 1178** (new enum "EQM Attachment Category" for the five categories plus Other; filled with `OnAfterInitFieldsFromRecRef` or by the user in the list). Pros: real classification, filterable. Cons: touches a core table for all companies, new field shows in every attachment list (hide it by default or show only when Table ID = 50100 by `Visible`), higher AppSource review risk and upgrade surface. Confidence: medium (design pattern is standard; behavior of Details page with a tableextension field not verified).
  2. **File-name convention / no classification in V1.** Simplest, zero risk; users name files "Invoice-...pdf". Meets "multiple attachments" but not "classified". Requires a decision from the requirement owner whether classification is mandatory.
  3. Request a standard category field from Microsoft (public BC repositories). Not realistic in the feature's time frame.
- **Confidence on classification: low.** Question for the user: is classification required, or is a file name enough? The five types are examples in the requirement.

## Published events found (from symbols, relevant ones)
| Object | Event | Signature | Relevant? |
|---|---|---|---|
| Codeunit 1173 "Document Attachment Mgmt" | OnAfterTableHasNumberFieldPrimaryKey | TableNo: Integer, var Result: Boolean, var FieldNo: Integer | **Yes (recommended)** |
| Codeunit 1173 | OnAfterGetRefTable | var RecRef: RecordRef, DocumentAttachment: Record "Document Attachment" | **Yes (recommended)** |
| Codeunit 1173 | OnAfterSetDocumentAttachmentFiltersForRecRef | var DocumentAttachment, RecRef | Backup |
| Codeunit 1173 | OnAfterSetDocumentAttachmentFiltersForRecRefInternal | var DocumentAttachment, RecordRef, GetRelatedAttachments: Boolean | No |
| Codeunit 1173 | OnAfterIsFlowFieldsEditable | TableNo: Integer, var Editable: Boolean | Optional |
| Codeunit 1173 | OnBeforeDeleteAttachedDocumentsWithConfirm | RecRef, var IsHandled | No |
| Codeunit 1173 | OnAfterTableHasDocTypePrimaryKey / HasLineNumberPrimaryKey / TableIsDocument / TableIsDocumentHeader / TableIsDocumentLine / TableIsEntity | TableNo plus var result | No (leave defaults) |
| Codeunit 1173 | OnMoveAttachmentsWithinSameRecordTypeOnBeforeInsert | var DocumentAttachmentToCreate, MoveToRecRef, MoveToRecNo | Only if rename is possible |
| Page 1173 "Document Attachment Details" | OnAfterOpenForRecRef | var DocumentAttachment, var RecRef, var FlowFieldsEditable, var PurchaseDocumentFlow | Optional |
| Page 1173 | OnBeforeImportWithFilter | var TempBlob, var FileName, var IsHandled, RecRef | No |
| Page 1178 "Doc. Attachment List Factbox" | OnAfterGetRecRefFail | var DocumentAttachment, var RecRef | Fallback |
| Page 1178 | OnBeforeDocumentAttachmentDetailsRunModal | var DocumentAttachment, var RecRef, var DocumentAttachmentDetails | No |
| Table 1173 "Document Attachment" | OnAfterInitFieldsFromRecRef | var DocumentAttachment, var RecRef | Only for option 1 of classification |
Full output of 30 events for codeunit 1173, 2 each for pages 1173 and 1178 and about 21 on table 1173 was read; the rest (copy, posted-document, content, OneDrive, export/import-stream events) are irrelevant to our scope.

## Existing patterns in the repo
- FR-023 plan (`docs/plans/FR-023-equipment-images.md`) is the structural model: a FactBox part is added first in the `FactBoxes` area of Equipment Card (page 50101, part "Picture") and List (page 50100), an AboutText sentence is added to the card, permission set 50100 is updated, and logic sits in an `Access = Internal` codeunit; the plan lists "Events: Subscribed: none". FR-024 differs: it subscribes to 2 base events, so it needs this report and an "Events" section naming them.
- Card currently has parts AssignmentHistory, MaintenanceHistory and FactBoxes Picture, EquipmentFactBox, MaintenanceFactBox, Links, Notes (`app/src/Equipment/EQMEquipmentCard.Page.al`). Next free IDs per FR-023: codeunit 50118, page 50123, enum 50108, table 50109. Planner to re-verify against `app/src`.
- Table 50100 `OnDelete` currently contains three Error checks (Assigned, assignment history, maintenance records) and no attachment handling.
- Equipment "No." is field 1 (Code[20]) per FR-023 notes; planner to verify the primary key is only "No.".

## Gaps and risks
- No base app source: where `OnAfterTableHasNumberFieldPrimaryKey` and `OnAfterGetRefTable` are raised and what state they run in is **not verified**. Event Recorder run (or sandbox test described above) recommended; this raises confidence to high.
- Whether the Details page 1173 and factbox work for a table that is not in the base app's own list using only these two hooks is unverified. If something is missing (e.g. count in the factbox, wrong filter), fall back to `OnAfterSetDocumentAttachmentFiltersForRecRef` and `OnAfterGetRecRefFail`.
- Possible Document Type quirk: since our key has no document type, Document Attachment rows get the default Document Type (first enum value, "Quote"). Not verified; harmless unless a filter on Document Type is applied. Check in the sandbox.
- Classification: no event; needs a user decision (see section above). Low confidence.
- Rename handling depends on whether equipment "No." can be renamed. Low confidence until checked.
- Test app: events and tables of the base app are accessible, so the two subscribers can be tested by calling the framework API (insert an attachment for a RecRef of equipment, then count). The UI parts (upload dialog) are sandbox checks, same as FR-023.
