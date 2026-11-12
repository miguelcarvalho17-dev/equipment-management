# FR-024 Document Attachments

## Purpose
Equipment records can hold any number of files (purchase invoices, maintenance reports, warranty certificates, user manuals, delivery notes) through the standard Document Attachment framework (GitHub issue #62). Files are listed in an **Attachments** FactBox on the Equipment Card and managed from an **Attachments** action. Each file can be classified with an EQM category, shown only for equipment attachments.

Status: implemented on branch `feature/FR-024-document-attachments`, not committed at the time of writing. **Build: the app and the tests are reported as compiled; the documenter did not re-run the build (only comments were considered for AL changes, none were needed).** **Tests: 12 tests in codeunit 50179 are compiled but NOT run (no BC sandbox).** Plan verifications V1-V4 and the sandbox checks (plan scenario 10) are unverified. App version stays 29.0.0.0. No upgrade codeunit, no event published.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Enum | 50108 | EQM Attachment Category | New, `Extensible = true`: Other (0), Purchase Invoice (1), Maintenance Report (2), Warranty Certificate (3), User Manual (4), Delivery Note (5) |
| TableExtension | 50100 | EQM Document Attachment | Extends "Document Attachment" (1173): field 50100 "EQM Attachment Category" |
| PageExtension | 50101 | EQM Doc. Attachment Details | Extends "Document Attachment Details" (1173): category column after Name, visible for equipment only |
| Codeunit | 50118 | EQM Doc. Attachment Subscr. | New, `Access = Internal`: 2 subscribers, 1 internal helper |
| Table | 50100 | EQM Equipment | `OnDelete` deletes the attachments; new `OnRename` moves them |
| Page | 50101 | EQM Equipment Card | FactBox part `AttachedDocuments`, action `Attachments`, AboutText sentence |
| PermissionSet | 50100 / 50101 | EQM - Reader / Manager | Document Attachment R / RIMD; execute on codeunit 50118 |
| Codeunit (test app) | 50179 | EQM Doc. Attachment Tests | 12 tests, compiled, not run |

## Field
| Field | Meaning |
|---|---|
| 50100 "EQM Attachment Category" (caption Category) on table 1173 | Kind of document. Default is Other (ordinal 0), also for existing attachments of all other tables. Shown only when page 1173 is filtered on equipment. Data classification CustomerContent. |

The base enum "Attachment Document Type" is not extended (it is part of the primary key of table 1173).

## Behavior
- **Registration with the framework:** attachment rows use Table ID 50100 and "No." = equipment No. Two subscribers on codeunit 1173 "Document Attachment Mgmt" make this work (see Events).
- **FactBox:** part `AttachedDocuments` (page "Doc. Attachment List Factbox"), caption Attachments, placed after the Picture FactBox, linked on Table ID = 50100 and "No.".
- **Action Attachments** (navigation group, promoted, Image Attach): enabled only when the equipment is saved (`IsSaved`). Opens "Document Attachment Details" modally via `OpenForRecRef`, then refreshes the card with `CurrPage.Update(false)`.
- **Category column:** the page extension sets `EQMIsEquipmentView` in `OnOpenPage` through `IsEquipmentAttachmentView`, which checks whether the "Table ID" filter equals 50100 in filter groups 0, 2 and 4 and restores the original filter group. Customer, vendor and other record types do not show the column.
- **Delete equipment:** after the three existing checks (assigned, assignment history, maintenance records), `OnDelete` calls `DeleteAttachedDocuments`. If a check raises an error the delete is rolled back with the attachments.
- **Rename equipment:** `OnRename` renames the Document Attachment rows of the equipment directly (the number is part of their primary key) so attachments follow the new "No.". The standard `MoveAttachmentsWithinSameRecordType` was tried first and did not move them (test 6b failed).
- **Status:** attachments are allowed in any status, including Lost and Disposed.

## Setup
No setup. TODO(verify): that the FactBox and the Attachments action appear by default in the web client.

## Extending (events)
Published: none. Subscribed (codeunit 1173 "Document Attachment Mgmt", signatures taken from symbols, see `docs/plans/FR-024-document-attachments-events.md`; raising context not verified because base source is not available):

| Event | What the subscriber does |
|---|---|
| `OnAfterTableHasNumberFieldPrimaryKey(TableNo; var Result; var FieldNo)` | For TableNo = 50100 sets Result = true and FieldNo to the field number of "No.". Exits for other tables. |
| `OnAfterGetRefTable(var RecRef; DocumentAttachment)` | When "Table ID" = 50100 and RecRef is not open, opens RecRef on table 50100 and positions it on the equipment with that "No." (stays unpositioned, no error, if the equipment does not exist). |

Codeunit 50118 is internal; partners cannot call it. Enum 50108 is extensible, so partners can add categories.

## Permissions
| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See attachments, open files | yes (Document Attachment R, execute on codeunit 50118) | yes | yes |
| Add, change category, delete attachments; delete or rename equipment with attachments | no | yes (Document Attachment RIMD) | yes (inherited) |

TODO(verify) V4: whether upload and download also need `tabledata "Tenant Media"`; not granted (consistent with FR-023). Fallback: Reader r, Manager rimd.

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit by hand. TODO(verify): the new captions, tooltips and AboutText are in the file.

## Upgrade and compatibility
New field on an unreleased app: no upgrade code. At first release, field 50100 on base table 1173 and enum 50108 with its values become contract (never remove or renumber). The tableextension adds a column to table 1173 for every table type: AppSource review risk, accepted by user decision. Uninstalling leaves attachment rows with Table ID 50100 (standard behavior).

## Known limitations
- Card only: no Attachments FactBox on the Equipment List.
- The category is chosen on page "Document Attachment Details"; it is not shown in the narrow FactBox.
- No size or file type limit is set by this app.

## Test status
- 12 tests in codeunit 50179 (`test/src/EQMDocAttachmentTests.Codeunit.al`, `TestPermissions = Disabled`) are **compiled but NOT run**: there is no BC sandbox, and they were not run in CI. No pass result exists. They cover: save links attachment to equipment with category Other; attachments separated per equipment; category change read back; delete removes attachments; delete of assigned equipment rejected and attachments kept; rename moves attachments; rename keeps category; Customer attachment not affected; category column visible from the card and hidden for Customer; Table ID filter detection by the helper; Attachments action disabled on a new card and FactBox present on a saved card.
- Not covered by tests: Reader behavior (Permissions Mock did not lower rights in FR-023 CI), upload and download, FactBox count, drill-down.
- Open verifications (all unverified):
  - V1: the two hooks suffice for filter, count and drill-down. Fallback: `OnAfterSetDocumentAttachmentFiltersForRecRef`, page 1178 `OnAfterGetRecRefFail`.
  - V2: resolved by the fallback: `MoveAttachmentsWithinSameRecordType` did not move the rows for our table, so `OnRename` renames the 1173 rows directly. The direct rename is compiled but not yet re-run in tests.
  - V3: filter group used by `OpenForRecRef`; behavior of sales/purchase FlowFields and the default Document Type on page 1173 for this table.
  - V4: Tenant Media rights (see Permissions).
  - Plan scenario 10, sandbox: upload via FactBox and details, drill-down opens the file, FactBox count, Reader can see but not upload or delete.

## Open items from earlier (pre-existing, not part of FR-024)
AppSource `app.json` / AppSourceCop items AS0051, AS0052, AS0054 and AS0084 remain open.

## Discrepancies plan vs code
- Plan lists 9 numbered scenarios plus a sandbox one; the test codeunit has 12 tests (scenario 8 split into two, and two extra: category kept on rename, helper filter detection). No behavior difference found.
- Otherwise the code matches the plan. TODO(verify): the plan was DRAFT when read; approval is not recorded in the file.
