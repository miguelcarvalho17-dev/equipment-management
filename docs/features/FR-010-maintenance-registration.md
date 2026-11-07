# FR-010 Maintenance Registration

## Purpose
FR-011 update: records now have a Status (Open or Posted). Corrections are possible only while Open; posting freezes the record and writes it to the maintenance history. See docs/features/FR-011-maintenance-history.md.

Users register each maintenance activity done on a piece of equipment (preventive, corrective, inspection, upgrade) with date, vendor, cost and who did the work. Records form the maintenance history of the equipment, are shown on the Equipment List and Card, and cannot be deleted.

Status: describes the code as implemented. **Build is clean under CodeCop and UICop. No automated tests (deferred, plan decision Q10; test codeunit ID 50164 is reserved and unused). Sandbox checks MT-SB0 to MT-SB11 are NOT yet run.** App version stays 29.0.0.0. Namespace `MiguelCarvalho.EquipmentManagement`. New stored table and one new field on "EQM Equipment Setup"; no upgrade codeunit.

## Objects
| Type | ID | Name | Change |
|---|---|---|---|
| Table | 50105 | EQM Maintenance Record | New, `Access = Public`, CustomerContent. Fields: 1 "No." (Code[20]), 2 "Equipment No." (relation to equipment, not blank), 3 "Maintenance Date", 4 "Maintenance Type" (InitValue Preventive), 5 "Vendor No." (relation to Vendor), 6 Cost (Decimal, MinValue 0), 7 Description, 8 "Performed By", 9 "No. Series" (not editable), 10 "Equipment Description" (FlowField lookup, not editable). Keys: PK ("No.", clustered); EquipmentDate ("Equipment No.", "Maintenance Date", SumIndexFields Cost). |
| Enum | 50102 | EQM Maintenance Type | New, extensible: 0 Preventive, 1 Corrective, 2 Inspection, 3 Upgrade. |
| Codeunit | 50108 | EQM Maintenance Mgt. | New, `Access = Internal`. Read helpers (see below). |
| Page | 50113 | EQM Maintenance Records | New list 'Equipment Maintenance', `UsageCategory = Lists`, read-only, no delete, sorted by "No." descending, card 50114. Views Preventive, Corrective, Inspection, Upgrade. Equipment FactBox, Notes, Links (hidden). Actions Equipment, Vendor. |
| Page | 50114 | EQM Maintenance Record Card | New card 'Maintenance Record', `UsageCategory = None`, `DelayedInsert`, delete not allowed. Equipment No. editable only on a new record. Vendor Name shown (display only). FactBoxes: Equipment (50111) and Maintenance (50115). Actions Equipment, Vendor. |
| Page | 50115 | EQM Maintenance FactBox | New CardPart 'Maintenance': No. of Maintenance Records (drill-down), Last Maintenance Date, Last Maintenance Type, Total Maintenance Cost (since FR-013: posted maintenance only, FlowField on table 50100). |
| Table | 50102 | EQM Equipment Setup | New field 3 "Maintenance Nos." (relation to No. Series). Page 50103 shows it; search terms extended. |
| Table | 50100 | EQM Equipment | `OnDelete` also blocks deletion when maintenance records exist (error `DeleteMaintenanceExistsErr`). |
| Page | 50101 | EQM Equipment Card | Maintenance FactBox. Action Register Maintenance (Process; enabled when saved and not Lost/Disposed; opens a new maintenance card with Equipment No. filled). Action Maintenance (Equipment group, enabled when saved). |
| Page | 50100 | EQM Equipment List | Maintenance FactBox. Action Maintenance (promoted under Navigate). |
| Page | 50110 | EQM Equipment Manager RC | Embedding action Maintenance; Creation action Maintenance Record (new card). |
| Codeunit | 50105 | EQM Default Data | Also creates number series EQMAINT (starting MNT00001; Default Nos. and Manual Nos. on) and sets "Maintenance Nos." when blank. `EnsureEquipmentNoSeries` replaced by local `EnsureNoSeries`. |
| PermissionSet | 50100 / 50101 | EQM - Reader / EQM - Manager | See Permissions. |

## Behavior
- **Numbering:** on insert with a blank "No.", the next number is taken from "Maintenance Nos."; if it is empty, `TestField` raises an error. A manually typed number requires the series to allow manual numbers (`TestManual`). AssistEdit on "No." lets the user pick a related series.
- **Maintenance Date:** blank on insert becomes the work date. A date later than today is rejected (`FutureDateErr`), on validate and on save.
- **Equipment checks on insert:** equipment must exist; Lost or Disposed equipment is rejected (`EquipmentFinalStatusErr`). The status is not checked again when an existing record is modified, so old Open records of equipment that was later disposed can still be corrected. Since FR-011 only Open records can be corrected; a Posted record is frozen (`PostedRecordCannotBeChangedErr`).
- **Equipment cannot change** on a saved record (`EquipmentCannotChangeErr`), and the number cannot be renamed (`RenameNotAllowedErr`).
- **Cost** must be zero or greater (MinValue and a check on save).
- **No delete:** `OnDelete` on the table always raises `MaintenanceCannotBeDeletedErr`, for every user including Administrator. Pages also have delete disabled. Equipment with maintenance records cannot be deleted either.
- **Registering maintenance sets the equipment status to In Maintenance** (changed by FR-012; the earlier statement that registering does not change the status no longer holds). See docs/features/FR-012-equipment-maintenance-status.md.
- **Rename of equipment:** TODO(verify) (MT-SB9) that records follow a renamed equipment number.
- **Vendor Name** is shown only when the user can read vendors; otherwise blank.
- **FactBox:** counts and sums are live; Last Maintenance is the latest date (highest "No." on equal dates, by `FindLast` on the key).

### Codeunit 50108 "EQM Maintenance Mgt." (internal; `///` comments present)
- `HasMaintenanceRecords(EquipmentNo): Boolean`
- `CountMaintenanceRecords(EquipmentNo): Integer`
- `GetLastMaintenanceRecord(EquipmentNo; var MaintenanceRecord): Boolean`
- ~~`GetTotalMaintenanceCost(EquipmentNo): Decimal`~~ **Removed by FR-013.** The FactBox total is now the FlowField "Total Maintenance Cost" on table 50100 (posted maintenance only).
- `ShowMaintenanceRecords(EquipmentNo)`: runs page 50113 filtered to the equipment.
- `GetVendorName(VendorNo): Text[100]`

## Setup
1. **New installs:** the default data creates series EQMAINT and fills Maintenance Nos. in Equipment Setup. TODO(verify) in a sandbox that this runs on install as it does for Equipment Nos.
2. **Existing companies must set Maintenance Nos. by hand:** open **Equipment Setup** as Administrator and choose a number series in **Maintenance Nos.** (or run the default data again if that is available to you). Without it, registering maintenance fails with a missing-value error on Maintenance Nos.
3. Give users **Equipment Manager** to register and correct maintenance, **Equipment Reader** to read.

## Extending (events)
| Event | Raised | Parameters |
|---|---|---|
| `OnAfterCheckMaintenanceConsistency(MaintenanceRecord)` on table 50105 | `[IntegrationEvent(false, false)]`, `local`, at the end of `CheckMaintenanceConsistency`, on insert and modify, after all standard checks passed. | `MaintenanceRecord`: record being saved, by value, so changes are not kept. A subscriber can only reject the save by raising an error. No `IsHandled`. |

The publisher is `local`, so it can be subscribed to only from inside this app. TODO(verify) whether a public publisher is wanted for partners. `CheckMaintenanceConsistency` and `AssistEdit` on the table are `internal`. The enum is extensible.

## Permissions
- **EQM - Reader:** `tabledata "EQM Maintenance Record" = R`; `X` on table 50105, pages 50113, 50114, 50115 and codeunit 50108.
- **EQM - Manager:** `tabledata "EQM Maintenance Record" = RIM` (no delete).
- **EQM - Administrator** inherits Manager; no delete on maintenance records (the table blocks it anyway). Administrator can edit the new Maintenance Nos. field through its existing setup permission.
- Number series consumption by a non-SUPER Manager (indirect No. Series access) is unverified (MT-SB5).

**Known limitations:**
- Maintenance cannot be removed once saved. A wrong Open record can be corrected; a Posted record (FR-011) cannot, and a new record must describe the correction.
- Cost is in local currency only; no currency, no scheduling or reminders.
- The Register Maintenance action uses the image `ServiceLedger`, not the planned `Maintenance` (compiler error AL0482 for that name).

## Translations
`app/Translations/Equipment Management.g.xlf` is regenerated by the build and shows as modified. Never edit it by hand.

## Upgrade and compatibility
Additive: new table, enum, codeunit, pages, one new setup field, extra checks on equipment delete. No upgrade codeunit and no Obsolete handling. Existing companies need Maintenance Nos. set (see Setup). Depends on the Vendor table (`Microsoft.Purchases.Vendor`) and No. Series (`Microsoft.Foundation.NoSeries`).

## Test status
No test objects; test ID 50164 reserved. Sandbox checks MT-SB0 to MT-SB11 in docs/plans/FR-010-maintenance-registration.md are all open: setup in existing company (SB0), build/translations (SB1), Tell Me and teaching tips (SB2), Register Maintenance from card (SB3), delete blocked (SB4), non-SUPER Manager numbering (SB5), Reader read-only (SB6), future date and negative cost (SB7), Role Center (SB8), equipment rename (SB9), vendor name and action (SB10), Lost/Disposed behavior (SB11).

## Discrepancies plan vs code
- Register Maintenance uses image `ServiceLedger` instead of `Maintenance` (AL0482).
- The `.g.xlf` is regenerated by the build; not edited.
- TODO(verify): the plan was not re-compared line by line beyond the points above.
