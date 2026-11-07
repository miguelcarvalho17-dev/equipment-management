# FR-011 Equipment Maintenance History

## Purpose
Maintenance records (FR-010) get an Open/Posted status. Posting freezes the record and writes one read-only copy to a new table, "EQM Maintenance History Entry". The posted history is shown on the Equipment Card and in its own list. History entries can never be changed, renamed or deleted.

Status: describes the code as implemented. **Build is clean under CodeCop and UICop (0 errors, 0 warnings). No automated tests (deferred, plan decision Q8; test codeunit ID 50165 is reserved and unused). Sandbox checks HS-SB1 to HS-SB12 are NOT yet run, including equipment rename (R2, HS-SB9).** App version stays 29.0.0.0. Namespace `MiguelCarvalho.EquipmentManagement`. No upgrade codeunit.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Enum | 50103 | EQM Maintenance Status | New, `Extensible = false`: 0 Open, 1 Posted. |
| Table | 50106 | EQM Maintenance History Entry | New, `Access = Public`, CustomerContent. Fields: 1 "Entry No." (AutoIncrement), 2 "Maintenance No." (relation to 50105, not validated), 3 "Equipment No." (relation to equipment, not validated), 4 "Maintenance Date", 5 "Maintenance Type", 6 "Vendor No." (no relation, snapshot), 7 "Vendor Name" (snapshot), 8 Cost, 9 Description, 10 "Performed By", 11 "Posted By" (Code[50], EndUserIdentifiableInformation), 12 "Posted At", 13 "Equipment Description" (FlowField). All fields not editable. Keys: PK ("Entry No."); EquipmentDate ("Equipment No.", "Maintenance Date", SumIndexFields Cost); MaintenanceNo ("Maintenance No.", Unique). |
| Codeunit | 50109 | EQM Maintenance-Post | New, `Access = Public`, `TableNo` 50105, `Permissions = tabledata "EQM Maintenance History Entry" = ri`. Posts one record. |
| Page | 50116 | EQM Maintenance History Part | New ListPart on the Equipment Card, read-only, newest date first. Action Show Maintenance Record. |
| Page | 50117 | EQM Maintenance History | New list 'Maintenance History', `UsageCategory = History`, read-only, newest entry first. Views Preventive, Corrective, Inspection, Upgrade. Equipment FactBox, Notes, Links (hidden). Actions Equipment, Maintenance Record. |
| Table | 50105 | EQM Maintenance Record | New field 11 Status (not editable). Insert refused unless Status is Open. Modify refused when the stored record is Posted. New `internal GetStatusStyle()`. |
| Codeunit | 50108 | EQM Maintenance Mgt. | New `internal PostWithConfirmation`. |
| Page | 50113 | EQM Maintenance Records | Status column, Post action (F9), History Entry action, views Open and Posted. |
| Page | 50114 | EQM Maintenance Record Card | Status field, General and Vendor/Cost groups read-only when Posted, Post action (F9, saves first), History Entry action. |
| Page | 50101 | EQM Equipment Card | Part `MaintenanceHistory` after Assignment History; action `ShowMaintenanceHistory` (Equipment group, promoted under Navigate, enabled when saved). |
| PermissionSet | 50100 / 50101 | EQM - Reader / EQM - Manager | See Permissions. |

## Behavior
- **Status:** new records are Open. A record cannot be inserted as Posted (`InsertPostedErr`).
- **Posting** (codeunit 50109 `OnRun`), in one transaction with no `Commit`:
  1. Reads the stored record with `UpdLock`. Not found: `RecordNotSavedErr`. Already Posted: `AlreadyPostedErr`.
  2. When a history entry already exists for the "Maintenance No.": `AlreadyPostedErr`.
  3. Raises `OnBeforePostMaintenanceRecord`.
  4. Sets Status to Posted and calls `Modify(true)`. This reruns the FR-010 checks (equipment exists and is unchanged, date not in the future, cost >= 0). The equipment status is not checked, so Lost or Disposed equipment can still have maintenance posted (its status stays).
  5. Writes the history entry: copies Equipment No., Maintenance Date, Maintenance Type, Vendor No., Cost, Description and Performed By by assignment. Vendor Name comes from `GetVendorName` (blank when the user cannot read vendors). Posted By is `UserId()`, Posted At is `CurrentDateTime()`. Raises `OnBeforeInsertMaintenanceHistoryEntry`, then inserts.
  6. Since FR-012: calls `Equipment.CompleteMaintenance` (equipment read with `UpdLock`), which sets the equipment from In Maintenance to Available when no other record is open. Other statuses are not touched.
  7. Raises `OnAfterPostMaintenanceRecord`.
  An error at any step rolls back both the status change and the entry. The codeunit shows no dialog.
- **Confirmation:** `PostWithConfirmation` asks "Do you want to post maintenance record %1?" and runs the codeunit on Yes. The card saves the record before posting. The list posts the current row only.
- **No reversal:** a posted record never returns to Open. `OnModify` of table 50105 checks the stored record (`CheckNotPosted`) and raises `PostedRecordCannotBeChangedErr` for every role. Delete and rename of 50105 stay refused (FR-010).
- **The source record is kept**, frozen as Posted. The history entry is the audit copy and points back through "Maintenance No.".
- **History table lock:** `OnInsert` of 50106 raises `InsertNotAllowedErr` unless `AllowInsertFromPosting` was called on the same record variable just before. The flag is reset after one insert. `OnModify`, `OnDelete` and `OnRename` always raise an error. There is no IsHandled.
- **Vendor snapshot:** "Vendor No." and "Vendor Name" have no table relation, so a later vendor rename or name change does not alter the history. This is unverified in a sandbox (HS-SB10).
- **Equipment Card part:** shows posted entries of the equipment only, sorted by Maintenance Date descending (key EquipmentDate). Open records are not shown there. They stay visible in the maintenance list, the Maintenance action and the Maintenance FactBox. The FactBox counts Open and Posted records. **Changed by FR-013:** its "Total Maintenance Cost" now sums posted maintenance only (from table 50106); the record counts still include open records.
- **Equipment delete:** unchanged. Equipment with maintenance records cannot be deleted, and every history entry has a kept source record.
- **Rename of equipment:** the TableRelation on "Equipment No." (50106) is expected to cascade a rename into the history. TODO(verify) (HS-SB9, risk R2): whether the platform needs direct Modify on 50106 for the renaming user. If it does, rename fails for Manager and Administrator.

### Codeunit 50109 "EQM Maintenance-Post" (public)
`OnRun` on the record passed through `TableNo`. Run it with `Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord)`. The caller sees Status = Posted afterwards.

### Internal procedures
- Table 50105 `GetStatusStyle(): Text`: Ambiguous for Open, Favorable for Posted.
- Table 50106 `AllowInsertFromPosting()`: enables the next insert. Only the posting codeunit uses it.
- Codeunit 50108 `PostWithConfirmation(var MaintenanceRecord): Boolean`: false when the user cancels.

## Setup
No new setup. FR-010 Maintenance Nos. is still needed to register records. Existing maintenance records show as Open after publishing and can be posted (TODO(verify), HS-SB8). Give users **Equipment Manager** to post and **Equipment Reader** to read the history.

## Extending (events)
All three are in codeunit 50109, `[IntegrationEvent(false, false)]`, `local`, no `IsHandled`. They can be subscribed to only from inside this app. TODO(verify) whether public publishers are wanted for partners (same open point as FR-010).

| Event | Raised | Parameters and what a subscriber may do |
|---|---|---|
| `OnBeforePostMaintenanceRecord(var MaintenanceRecord)` | After the checks that the record is saved, Open and not yet in the history; before the status changes. | `MaintenanceRecord`: record being posted. Raise an error to stop posting. Fields added by an extension may be filled. Do not change standard fields. |
| `OnBeforeInsertMaintenanceHistoryEntry(var MaintenanceHistoryEntry; MaintenanceRecord)` | After all standard entry fields are filled; just before the insert. | `MaintenanceHistoryEntry`: fill fields added by an extension. Do not change standard fields. `MaintenanceRecord`: by value. |
| `OnAfterPostMaintenanceRecord(MaintenanceRecord; MaintenanceHistoryEntry)` | After the status change and the insert. | Both by value. Use for follow-up work. Subscribers must not commit. |

The existing `OnAfterCheckMaintenanceConsistency` (table 50105) is also raised during posting, with Status = Posted.

## Permissions
- **EQM - Reader:** `tabledata "EQM Maintenance History Entry" = R`; `X` on table 50106, pages 50116 and 50117, codeunit 50109. A Reader cannot post: posting needs Modify on 50105, which Readers do not have.
- **EQM - Manager:** `tabledata "EQM Maintenance History Entry" = i` (indirect insert, effective inside codeunit 50109, which declares `ri`). No direct insert, modify or delete on 50106.
- **EQM - Administrator** inherits Manager and has no extra rights on 50106.

| Function | Reader | Manager | Administrator |
|---|---|---|---|
| See the history (card part, list) | yes | yes | yes |
| Register and correct an Open record | no | yes | yes |
| Post a record | no | yes | yes |
| Change a posted record | no | no | no |
| Insert, change, rename or delete a history entry | no | no | no |

Known limitation (R1): code that runs with direct rights (SUPER or another app's elevated permissions) and writes without triggers (`Insert(false)`, `Modify(false)`, `ModifyAll`, `DeleteAll`) can bypass the table locks. These matrix results are from code reading, not from a sandbox run (HS-SB5, HS-SB6).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand.

## Upgrade and compatibility
Additive: new enum, table, codeunit and two pages, one new field. No upgrade codeunit and no Obsolete handling (nothing released). Behavior change to FR-010: a maintenance record can be corrected only while Open. The enum is not extensible. Public surface that becomes a contract at release: table 50106, enum 50103, field 11 on 50105, codeunit 50109 and its events, pages 50116 and 50117.

## Test status
No test objects; ID 50165 reserved (plan decision Q8). Sandbox checks HS-SB1 to HS-SB12 in docs/plans/FR-011-maintenance-history.md are all open: build and translations, Equipment Card part, posting from card and list, non-SUPER Manager and Reader, read-only pages, Tell Me, existing records, equipment rename (R2), vendor rename, no Vendor read, rollback on error. A later test H8 needs `internalsVisibleTo` for the test app in app.json, which is not set.

## Discrepancies plan vs code
- The Equipment Card action is `ShowMaintenanceHistory` (promoted as `ShowMaintenanceHistory_Promoted`), not `MaintenanceHistory`, because the part already uses that control name. Caption unchanged.
- Codeunit 50108 `ShowHistoryEntries` was not built (nothing calls it).
- Codeunit 50109 `Permissions` is `ri` (plan section "Codeunit 50109" said `i`); read is needed for the duplicate check.
- The insert lock on table 50106 is one-shot (the plan did not state the reset).
- Not done here: the plan also lists updates to the FR-010 and FR-008 feature and help docs, the NFR-002 matrices and docs/TODO.md. Those files are unchanged, so FR-010 text that says records can be corrected at any time is now outdated.
