# FR-066 Demo Data — Plan

> Request (verbatim): The user wants demo data for the Equipment Management app so that, when it is launched in a BC29 environment, there are sample employees, equipment, assignments and maintenance records to look at.
>
> Status: **approved**

User decisions already made: FR-066; user-triggered actions on the Equipment Setup page (not on install/upgrade).

Tooling notes: the worktree had no `.alpackages`, so the AL MCP had no project loaded. IDs come from a source scan (high free end). Standard symbols (Employee fields, Confirm Management, Document Attachment fields) are confirmed only by compiled use elsewhere in this repo; the developer verifies with `al_symbolsearch` once symbols are available.

## Request
Add two user-triggered actions on the Equipment Setup page, **Create Demo Data** and **Delete Demo Data**. Create fills the current company with about 8 clearly marked demo employees, 15 equipment records across the 7 seeded categories, current and historical assignments, and maintenance records (open, posted, overdue). It goes through the app's own business logic. Delete removes only the records the demo created, and never touches data that a user created.
Target: AppSource

## Definition of done
- [ ] Page 50103 "EQM Equipment Setup" has actions **Create Demo Data** and **Delete Demo Data** in the Processing area. Both have Caption, ToolTip, Image, and `Enabled = CanManage`.
- [ ] Create asks for confirmation (default No) and names the company. Answering No changes nothing.
- [ ] On an empty company with the 7 default categories, Create makes:
  - 8 employees `EQMDEMO-E01`..`E08`.
  - 15 equipment `EQMDEMO-001`..`015`, final statuses Assigned 7, Available 3, In Maintenance 3, Lost 1, Disposed 1.
  - 13 assignment entries: 7 active and 6 closed.
  - 12 maintenance records `EQMDEMO-M01`..`M12`: 9 posted (9 history entries) and 3 open, of which 2 are overdue (more than 14 days open).
  - Warranties that are expired, expiring soon, inside the 90-day alert window, active, and blank.
  - 1 equipment whose planned maintenance is overdue.
- [ ] Every created employee, equipment and maintenance record has a row in the new table "EQM Demo Data Entry", holding its SystemId.
- [ ] A second Create creates nothing and changes nothing (row counts in all EQM tables and Employee unchanged).
- [ ] Create never modifies or deletes a record it did not create. It skips a catalog item when its number is already used by an untracked record, its category is missing or inactive, or (serial only) the serial number is already used (equipment is then created with a blank serial).
- [ ] The result is shown as a notification with the counts.
- [ ] Delete with nothing tracked shows "There is no demo data to delete…" without a confirm. Otherwise it asks for confirmation (default No).
- [ ] Delete removes each tracked demo equipment with its assignment entries, maintenance records, history entries, maintenance log entries, audit entries, warranty alerts and integration event entries. Then each tracked demo employee, then the tracking rows.
- [ ] Delete keeps a demo equipment (and its tracking row) when users added data to it: a note, a document attachment, a picture, an equipment request pointing to it, a non-demo maintenance record, or an assignment to a non-demo employee.
- [ ] Delete keeps a demo employee when anything left references it: equipment assigned to it, any assignment entry, any equipment request, or any document attachment on the employee.
- [ ] Delete still removes demo records that users only edited or renamed (found by SystemId).
- [ ] Without write permission on the equipment setup, or on Employee, both procedures raise an actionable error and nothing is written.
- [ ] Permission sets: Reader has X on table 50149 and codeunit 50149. Administrator has indirect `rimd` on 50149 and indirect `d` on the six dependent tables. Manager gets nothing new.
- [ ] pt-PT and es-ES XLIFF complete; `xlf_sync.py check` reports 0 errors (repo check 7).
- [ ] app/ and test/ compile with CodeCop, UICop and AppSourceCop, no new warnings.
- [ ] Test codeunit 50176 and new tests in 50162 compile. CI result reported as pending until push.
- [ ] `docs/features/FR-066-demo-data.md`, `docs/help/FR-066-demo-data.md` and a CHANGELOG `## FR-066` section exist.

## Out of scope
- No change to "EQM Install", "EQM Upgrade" or "EQM Upgrade Mgt.": no demo data on install or upgrade (user decision).
- No changes to app.json or test/app.json, no new permission set, no direct rights on standard Employee.
- No equipment requests, notes, attachments, pictures, warranty alerts or job queue entries in the demo set (alerts come from the existing daily job).
- No suppression of business events, telemetry, Power Automate events or Change Log for demo actions (would change existing subscribers).
- No locations, vendors or dimensions on demo records.
- Phase 2: optional demo requests, notes, pictures. Phase 3: "demo company only" guard. Phase 4: configurable size (large dataset) reusing FR-053.

## Objects
| Type | ID | Name | New/Changed | File |
|---|---|---|---|---|
| Table | 50149 | EQM Demo Data Entry | New | app/src/DemoData/EQMDemoDataEntry.Table.al |
| Codeunit | 50149 | EQM Demo Data Mgt. | New | app/src/DemoData/EQMDemoDataMgt.Codeunit.al |
| Page | 50103 | EQM Equipment Setup | Changed (2 actions) | app/src/Setup/EQMEquipmentSetup.Page.al |
| PermissionSet | 50100 | EQM - Reader | Changed (2 X entries) | app/src/Permissions/EQMReader.PermissionSet.al |
| PermissionSet | 50102 | EQM - Administrator | Changed (indirect entries) | app/src/Permissions/EQMAdministrator.PermissionSet.al |
| XLIFF | – | g.xlf, pt-PT, es-ES | Changed | app/Translations/*.xlf |
| JSON | – | coverage register | Changed (add codeunit 50149) | .github/coverage/coverage-register.json |
| Codeunit (test) | 50176 | EQM Demo Data Tests | New (reuses unbuilt FR-022 reservation) | test/src/EQMDemoDataTests.Codeunit.al |
| Codeunit (test) | 50162 | EQM Role Permission Tests | Changed (2 tests) | test/src/EQMRolePermissionTests.Codeunit.al |
| Docs | – | feature, help, changelog | New/Changed | docs/features/FR-066-demo-data.md, docs/help/FR-066-demo-data.md, CHANGELOG.md |

ID scan: app tables in use 50100-50114; codeunits 50103-50122 and 50130-50141; pages 50100-50126 and 50130-50140. No document references 50149. The FR-053 branch (not readable from this worktree) adds a query file, so table/codeunit 50149 should not clash. Test IDs 50150-50176 are all reserved by earlier plans; 50176 (FR-022, never built) is reused per DECISIONS precedent.

## Events and standard symbols
| Symbol | Signature | Verified with al_symbolsearch |
|---|---|---|
| Table Employee (`Microsoft.HumanResources.Employee`): "No." Code[20], "First Name", "Last Name", Status (Active), "Privacy Blocked" | as used in EQMEquipment.Table.al and tests | No (MCP unavailable); confirmed by compiled use |
| Employee.Insert(true) / Delete(true) | Record methods | No; standard trigger content not verifiable (Risks) |
| Codeunit "Confirm Management" (`System.Utilities`) | `GetResponseOrDefault(Question: Text; DefaultButton: Boolean): Boolean` | No; confirmed by use in EQMEquipment.Table.al |
| Table "Document Attachment" ("Table ID", "No.") | – | No; confirmed by use in EQMEquipment.Table.al OnRename |
| Platform: WritePermission, GetBySystemId, DeleteAll(Boolean), MediaSet.Count, Notification, GuiAllowed, CompanyName, Today, UserId, CurrentDateTime | | Platform; WritePermission, DeleteAll confirmed on Learn |
| App: `"EQM Equipment".AssignEmployee(EmployeeNo)` (internal); `Codeunit "EQM Maintenance-Post"` (50109, TableNo "EQM Maintenance Record"); `IsFinalStatus`, `GetWarrantyStatus()`, `IsPlannedMaintenanceOverdue(Date)`; `"EQM Maintenance Mgt".CountOverdueMaintenance(Date)`; `"EQM Default Data".CreateDefaultData()` | | Read in source |

No event is subscribed or published by this feature.

## Steps
1. **app/src/DemoData/EQMDemoDataEntry.Table.al.** Table 50149 "EQM Demo Data Entry". `namespace MiguelCarvalho.EquipmentManagement;`, Caption 'Equipment Demo Data Entry', `DataClassification = CustomerContent`, `Access = Internal`. No page.
   - field(1) "Table ID": Integer, SystemMetadata, Caption 'Table ID', ToolTip 'Specifies the table of the record that the demo data created.'
   - field(2) "Record No.": Code[20], CustomerContent, Caption 'Record No.', ToolTip 'Specifies the number of the record when the demo data created it.'
   - field(3) "Record System Id": Guid, SystemMetadata, Caption 'Record System ID', ToolTip 'Specifies the system ID of the record that the demo data created. It identifies the record even after it is renamed.'
   - field(4) "Created At": DateTime, SystemMetadata, Caption 'Created At', ToolTip 'Specifies when the demo record was created.'
   - field(5) "Created By": Code[50], EndUserIdentifiableInformation, Caption 'Created By', ToolTip 'Specifies the user who created the demo data.'
   - Keys: `key(PK; "Table ID", "Record No.") { Clustered = true; }` and `key(SystemId; "Record System Id") { }`.
   - Tracks which rows the demo owns, so Delete never touches user data and survives a rename.

2. **app/src/DemoData/EQMDemoDataMgt.Codeunit.al.** Codeunit 50149 "EQM Demo Data Mgt." (skeleton, guards, tracking helpers). `Access = Internal`. Usings: `Microsoft.HumanResources.Employee`, `Microsoft.Foundation.Attachment`, `System.Utilities`.
   - Header comment explains permission design (same style as codeunit 50105): indirect rights only, granted by EQM - Administrator. Employee is not listed, so the user's own Employee rights are required.
   - `Permissions =` tabledata "EQM Demo Data Entry" = rimd; "EQM Equipment" = rimd; "EQM Equipment Assignment" = rimd; "EQM Equipment Audit Entry" = rd; "EQM Maintenance Record" = rimd; "EQM Maintenance History Entry" = rd; "EQM Maintenance Log Entry" = rd; "EQM Warranty Alert" = rd; "EQM Integration Event Entry" = rd; "EQM Equipment Note" = r; "EQM Equipment Request" = r; "Document Attachment" = r.
   - Local procedures: `CheckCanManageDemoData(ForDelete: Boolean)` (fresh EquipmentSetup and Employee variables; if `not EquipmentSetup.WritePermission() or not Employee.WritePermission()` raise `Error(ErrorInfo)` with CreateNoPermissionErr / DeleteNoPermissionErr); `IsOwnDemoRecord(TableId; RecordNo; var SystemId): Boolean`; `TrackRecord(TableId; RecordNo; SystemId)` (Insert, or Modify existing row; Created At = CurrentDateTime(), Created By = CopyStr(UserId(), …)); `DemoEmployeeNo(Index)`, `DemoEquipmentNo(Index)`, `DemoMaintenanceNo(Index)` using Locked labels 'EQMDEMO-E%1', 'EQMDEMO-%1', 'EQMDEMO-M%1' (with Comment) and `Format(Index, 0, '<Integer,2><Filler Character,0>')` (3 digits for equipment).
   - Labels: CreateNoPermissionErr: 'You cannot create demo data because you do not have permission to change the equipment setup and to create and delete employees. Ask an administrator to assign you the Equipment Administrator permission set and a permission set that lets you edit employees.' DeleteNoPermissionErr: same text with "delete demo data".

3. **Same file: create logic.** `internal procedure CreateDemoData(var EmployeesCreated; var EquipmentCreated; var AssignmentsCreated; var MaintenanceCreated; var SkippedCount: Integer)`, no UI. Starts with `CheckCanManageDemoData(false)`. T := Today() for every date. Fresh local record variables only. No Commit.
   - **Employees (1..8):** skip (SkippedCount += 1) if `Employee.Get(No)` succeeds or a tracked row's SystemId resolves with `GetBySystemId`. Otherwise Init; "No."; "First Name" from Locked labels Ana, Bruno, Carla, David, Elena, Filipe, Grace, Hugo; "Last Name" = Locked 'Demo'; Status = Active; "Privacy Blocked" = false; `Insert(true)`; TrackRecord; count.
   - **Equipment (1..15)** per the table below. Skip the item and all dependents if the number exists, a tracked SystemId resolves (renamed demo record), or the category is missing or `Active = false`. Otherwise set by direct assignment: "No.", Description, "Category Code", "Serial No." = 'EQMDEMO-SN-%1' (3 digits), Manufacturer, Model, "Purchase Date", "Purchase Cost", "Warranty Start Date", "Warranty End Date", "Warranty Provider", "Maintenance Frequency (Months)". If the serial is already used by other equipment (SetCurrentKey("Serial No.") + IsEmpty), leave it blank. `Insert(true)` (consistency checks, audit Created, business event), then TrackRecord. Run scenario steps in the listed order: posted maintenance, closed history, open maintenance, current assignment or final status.
   - **Helpers:**
     - `PostDemoMaintenance(EquipmentNo, MaintIndex, Type, DaysAgo, Cost, DescriptionTxt)`: skip if maintenance number exists (SkippedCount += 1); else set "No.", "Equipment No.", "Maintenance Date" = T - DaysAgo, "Maintenance Type", Cost, Description, "Performed By" = PerformedByTxt; `Insert(true)`; TrackRecord; `MaintenancePost.Run(MaintenanceRecord)`.
     - `RegisterOpenDemoMaintenance(…)`: same without posting.
     - `InsertClosedDemoAssignment(EquipmentNo, EmpIndex, FromDaysAgo, ToDaysAgo)`: only if `IsOwnDemoRecord(Employee)` and it resolves, else SkippedCount += 1. Direct Init, Status = Closed, "Assignment Date", "Closing Date", "Assigned By" and "Closed By" = UserId; `Insert(true)` (table has no OnInsert).
     - `AssignDemoEmployee(EquipmentNo, EmpIndex)`: same employee check; re-Get the equipment (posting modified it) and `Equipment.AssignEmployee(EmployeeNo)`.
     - `SetDemoFinalStatus(EquipmentNo, Status)`: Get again; `Status := Lost or Disposed`; `Modify(true)`. Do not Validate (raises final-status confirm).
   - Never call `UnassignEmployee`, `Validate(Status)` or `PostWithConfirmation` (dialogs/notifications). Always re-Get equipment before a modify.
   - **Dataset** (days before T; maintenance types P Preventive, C Corrective, I Inspection, U Upgrade; purchase = days before T):

| # | Cat | Description / Manufacturer / Model (Locked) | Purchase | Cost | Warranty start→end (days rel. T) | Provider (Locked) | Freq | Scenario in order |
|---|---|---|---|---|---|---|---|---|
| 001 | LAPTOP | ThinkPad T14 Gen 5 / Lenovo / T14 Gen 5 | 420 | 1450 | -420 → +310 | Lenovo Premier Support | 12 | M01 P 60d 85 posted; closed E05 400→210; assign E01 |
| 002 | LAPTOP | Latitude 7450 / Dell / 7450 | 700 | 1320 | -700 → +25 | Dell ProSupport | 12 | M02 C 150d 240 posted; assign E02 |
| 003 | LAPTOP | MacBook Air 13 / Apple / MacBook Air 13 | 900 | 1199 | -900 → -170 | AppleCare | 0 | M11 C 400d 180 posted; closed E03 880→300; closed E06 290→30 (Available) |
| 004 | LAPTOP | EliteBook 840 G11 / HP / 840 G11 | 120 | 1380 | -120 → +975 | HP Care Pack | 12 | M03 C 20d 0 open (overdue) |
| 005 | MONITOR | UltraSharp U2724D / Dell / U2724D | 500 | 420 | -500 → +595 | Dell | 0 | assign E01 |
| 006 | MONITOR | Odyssey G5 27 / Samsung / G5 27 | 1100 | 310 | -1100 → -370 | Samsung | 0 | M12 U 500d 0 posted; closed E04 1090→400; Disposed |
| 007 | PHONE | iPhone 15 / Apple / iPhone 15 | 300 | 899 | -300 → +65 | AppleCare | 0 | assign E03 |
| 008 | PHONE | Galaxy S24 / Samsung / S24 | 250 | 799 | -250 → +115 | Samsung Care+ | 0 | assign E04 |
| 009 | PHONE | Pixel 8 / Google / Pixel 8 | 600 | 699 | -600 → +12 | Google | 0 | closed E07 590→90; Lost |
| 010 | TABLET | iPad Air 11 / Apple / iPad Air 11 | 200 | 749 | -200 → +165 | AppleCare | 0 | closed E08 180→60 (Available) |
| 011 | TABLET | Galaxy Tab S9 / Samsung / Tab S9 | 380 | 869 | -380 → +350 | Samsung | 12 | M04 I 90d 0 posted; M05 U 3d 120 open (not overdue) |
| 012 | PRINTER | LaserJet Pro 4002dn / HP / 4002dn | 800 | 389 | -800 → -70 | HP | 6 | M06 P 400d 75 posted; M07 P 220d 75 posted (planned maintenance overdue) |
| 013 | VEHICLE | Corolla Touring Sports / Toyota / Corolla TS | 1000 | 28500 | -1000 → +95 | Toyota | 6 | M08 P 160d 320 posted; M09 C 75d 1150 posted; assign E06 |
| 014 | TOOL | GSB 18V-55 cordless drill / Bosch / GSB 18V-55 | 150 | 189 | -150 → +580 | Bosch | 0 | assign E07 |
| 015 | TOOL | Fluke 117 multimeter / Fluke / 117 | 90 | 265 | blank | – | 12 | M10 I 30d 45 open (overdue) |

   - Maintenance descriptions are translatable `Txt` labels, MaxLength = 100: M01 'Annual inspection and cleaning'; M02 'Battery replacement'; M03 'Keyboard repair'; M04 'Safety inspection'; M05 'Storage upgrade'; M06 and M07 'Toner and roller replacement'; M08 'Scheduled service'; M09 'Brake pad replacement'; M10 'Calibration check'; M11 'Screen replacement'; M12 'Firmware update'. PerformedByTxt 'IT service desk'. All names, products, providers and number patterns are `Locked = true` Tok labels.

4. **Same file: delete logic.** `internal procedure DeleteDemoData(var EquipmentDeleted; var EmployeesDeleted; var EquipmentKept; var EmployeesKept: Integer)`. Starts with `CheckCanManageDemoData(true)`.
   - **Equipment pass.** Loop tracking rows with "Table ID" = Database::"EQM Equipment" (collect keys into a List first, then process). If `GetBySystemId` fails, delete the stale tracking row. Else if `not CanDeleteDemoEquipment`, EquipmentKept += 1. Else `DeleteDemoEquipment`, EquipmentDeleted += 1.
   - **CanDeleteDemoEquipment** returns false when: `Equipment.Picture.Count() > 0`; an "EQM Equipment Note" exists for it; a "Document Attachment" exists with "Table ID" = Database::"EQM Equipment" and "No." = equipment; an "EQM Equipment Request" exists with "Assigned Equipment No." = equipment; any maintenance record of the equipment fails `IsOwnDemoRecord` (tracked and SystemId matches); any assignment entry of the equipment has an employee that is not an own demo employee.
   - **DeleteDemoEquipment** uses `DeleteAll(false)` / `Delete(false)` on purpose (OnDelete triggers forbid deletion by design). Order: (a) for each maintenance record, its "EQM Maintenance Log Entry" rows filtered on "Maintenance No."; (b) "EQM Maintenance History Entry" on "Equipment No." (key EquipmentDate); (c) "EQM Maintenance Record" on "Equipment No."; (d) "EQM Equipment Assignment" on "Equipment No."; (e) "EQM Equipment Audit Entry" (key EquipmentNo); (f) "EQM Warranty Alert" (key Equipment); (g) "EQM Integration Event Entry" on "Equipment No."; (h) `Equipment.Delete(false)`; (i) delete the tracking rows of the equipment and its maintenance records.
   - **Employee pass** after the equipment pass. Loop tracking rows with Database::Employee. Stale row: delete it. Keep (EmployeesKept += 1) if any exists: EQM Equipment with "Assigned Employee No." (key AssignedEmployee); an "EQM Equipment Assignment" with "Employee No." (key EmployeeStatus); an "EQM Equipment Request" with "Employee No."; a "Document Attachment" with "Table ID" = Database::Employee. Else `Employee.Delete(true)` (standard OnDelete and the EQM guard), delete the tracking row, EmployeesDeleted += 1.
   - `internal procedure HasDemoData(): Boolean` returns `not DemoDataEntry.IsEmpty()`.

5. **Same file: UI wrappers.**
   - `CreateDemoDataWithConfirmation()`: `ConfirmManagement.GetResponseOrDefault(StrSubstNo(CreateDemoDataQst, CompanyName()), false)`; exit on No; call CreateDemoData; send DemoDataCreatedMsg, or NothingCreatedMsg when all counts are 0.
   - `DeleteDemoDataWithConfirmation()`: if `not HasDemoData()` send NoDemoDataMsg and exit; confirm DeleteDemoDataQst (default false), call DeleteDemoData, send DemoDataDeletedMsg.
   - `local procedure SendResultNotification(MessageText: Text)`: `if not GuiAllowed() then exit;` Notification.Message, Scope LocalScope, Send.
   - Labels: CreateDemoDataQst: 'This creates sample employees, equipment, assignments and maintenance records in company %1 so that you can try out the app. Existing records are not changed. Do you want to continue?' DeleteDemoDataQst: 'This deletes the demo data that Create Demo Data added to company %1, including its assignment history, maintenance history, maintenance log, audit trail and warranty alerts. Records that users created are not deleted, and demo records that users added notes, attachments, pictures, requests or other data to are kept. Do you want to continue?' DemoDataCreatedMsg: 'Demo data was created: %1 employees, %2 equipment, %3 assignments and %4 maintenance records. %5 items were skipped because their number was already used or their category is missing or inactive.' NothingCreatedMsg: 'No demo data was created. The demo records already exist, or their numbers or categories are not available.' DemoDataDeletedMsg: 'Demo data was deleted: %1 equipment and %2 employees. %3 equipment and %4 employees were kept because users added data to them.' NoDemoDataMsg: 'There is no demo data to delete in this company.'

6. **app/src/Setup/EQMEquipmentSetup.Page.al.** In `area(Processing)`, after ScheduleMonitoringJobs:
   - `action(CreateDemoData)`: Caption 'Create Demo Data'; ToolTip 'Create sample employees, equipment, assignments and maintenance records in this company so that you can try out the app. Existing records are not changed, and running it again only adds what is missing.'; `Image = Import`; `Enabled = CanManage`; OnAction `DemoDataMgt.CreateDemoDataWithConfirmation(); CurrPage.Update(false);`.
   - `action(DeleteDemoData)`: Caption 'Delete Demo Data'; ToolTip 'Delete the demo data that Create Demo Data added to this company. Records that users created, and demo records that users added data to, are kept.'; `Image = Delete`; `Enabled = CanManage`.
   - Page variable `DemoDataMgt: Codeunit "EQM Demo Data Mgt.";`. Do not promote either action.

7. **EQMReader.PermissionSet.al.** Add `table "EQM Demo Data Entry" = X` and `codeunit "EQM Demo Data Mgt." = X` (required by test 50162 `ReaderHasExecuteOnEveryObjectOfTheApp`). No tabledata.

8. **EQMAdministrator.PermissionSet.al.** Add: `tabledata "EQM Demo Data Entry" = rimd`; `tabledata "EQM Equipment Assignment" = Rimd`; `tabledata "EQM Equipment Audit Entry" = id`; `tabledata "EQM Maintenance History Entry" = id`; `tabledata "EQM Maintenance Log Entry" = id`; `tabledata "EQM Maintenance Record" = RIMd`; `tabledata "EQM Warranty Alert" = RIMd`. (Repeat Manager's rights and add indirect `d`; Integration Event Entry already has mD.) Nothing in Manager or API Consumer.

9. **app/Translations/*.xlf.** Run `al_build` on app/ (regenerates `Equipment Management.g.xlf`; `al_compile` does not). Then `python3 .github/scripts/xlf_sync.py sync`, `export`, translate every new unit following the FR-055 glossary, `import`, `check` (0 errors). New units: table caption, 5 field captions, 5 field ToolTips, 2 action captions, 2 action ToolTips, 2 errors, 2 confirms, 4 messages, 11 maintenance descriptions, 1 Performed By text. Locked labels produce no units.

10. **.github/coverage/coverage-register.json.** Add `50149` to `scope.businessLogic.codeunits`.

11. **test/src/EQMDemoDataTests.Codeunit.al.** Test codeunit 50176 "EQM Demo Data Tests", `Subtype = Test`, `[TransactionModel(TransactionModel::AutoRollback)]` on each test. `Initialize()` calls `DefaultData.CreateDefaultData()`. Helpers insert user records with `Insert(false)` using counter-based Locked labels as in FR-038/FR-045. Assertions filter on `'EQMDEMO-*'` or compare deltas, never absolute counts.

12. **test/src/EQMRolePermissionTests.Codeunit.al.** Add two tests reusing `RightsOf` / `AssertNoDelete`: `AdministratorCanDeleteDemoDependentsIndirectly` (Delete indirect on 50103, 50105, 50106, 50107, 50108, 50112 and on table 50149); `ManagerCannotDeleteDemoDependents` (negative).

13. **Docs:** `docs/features/FR-066-demo-data.md` (objects, permission design, side effects, not verified); `docs/help/FR-066-demo-data.md` (create/delete, what is kept and why, side effects: Power Automate flows, integration entries, Change Log, telemetry); `CHANGELOG.md` `## FR-066` section.

## Tests
Test codeunit 50176; every test begins with `Initialize()`.
- D1 Create on a fresh company: counts 8/15/13/12/0; statuses Assigned 7, Available 3, In Maintenance 3, Lost 1, Disposed 1; 35 tracking rows.
- D2 (neg) Second run: all created counts 0, every table count unchanged.
- D3 (neg) Employee 'EQMDEMO-E01' inserted by user: its First Name unchanged, no tracking row, EQMDEMO-001 and -005 Available, no assignment to EQMDEMO-E01, SkippedCount ≥ 3.
- D4 (neg) User equipment untouched (Status, Description, no assignments/maintenance).
- D5 Variety: CountOverdueMaintenance(Today) +2; EQMDEMO-002 Expiring Soon; -003 Expired; -012 IsPlannedMaintenanceOverdue; -015 blank warranty status.
- D6 History and log: 9 history entries; each EQMDEMO maintenance record has ≥1 log entry; EQMDEMO-003 has 2 closed assignment entries with the planned dates.
- D7 Delete removes everything (no EQMDEMO equipment, employees, maintenance, history, log, audit, assignment, warranty alert, integration rows; tracking empty; counts 15/8/0/0).
- D8 (neg) Delete keeps user data (user employee and equipment assigned to each other; both and the entry remain).
- D9 (neg) A note keeps equipment: EQMDEMO-003, its history and tracking row remain; E03 and E06 remain; EquipmentKept 1, EmployeesKept 2.
- D10 (neg) User maintenance on EQMDEMO-010 keeps it; EquipmentKept 1.
- D11 (neg) User equipment assigned to EQMDEMO-E05 keeps E05 (EmployeesKept 1).
- D12 Stale tracking (E08's history entry and employee deleted with Delete(false)): no error, tracking empty.
- D13 An edited demo record (Description changed) is still deleted.
- D14 Renamed demo record: Create again makes no new EQMDEMO-010; Delete removes the renamed one.
- D15 Re-create after delete: counts 8/15/13/12.
- D16 (neg) Inactive LAPTOP category: no EQMDEMO equipment in LAPTOP, SkippedCount ≥ 4, no error.
- D17 (neg) Serial collision with user equipment: EQMDEMO-001 exists with blank serial, user equipment unchanged.
- D18 (neg) Confirm No on create: no EQMDEMO equipment, no notification.
- D19 Confirm Yes on create: notification text equals StrSubstNo of the created message with 8, 15, 13, 12, 0.
- D20 (neg) Delete with nothing: "no demo data" notification, no confirm.
- D21 (neg) Confirm No on delete: all 15 remain.
- D22 Page action: TestPage "EQM Equipment Setup" OpenEdit, CreateDemoData.Invoke(); EQMDEMO-001 exists.

Test codeunit 50162: P1 Administrator indirect Delete on 50103, 50105, 50106, 50107, 50108, 50112 and indirect RIMD on 50149. P2 (neg) Manager has no Delete on 50103, 50105, 50106, 50108, 50112.

Not testable in CI: the permission-denied path of CheckCanManageDemoData (no "Library - Lower Permissions"; adding it changes test/app.json, stop list). Sandbox check: setup page as a user with EQM - Manager only (actions disabled), and as EQM - Administrator without Employee write rights (actionable error).

Existing tests likely affected: 50162 `ReaderHasExecuteOnEveryObjectOfTheApp` and `ReaderIsReadOnlyOnAllEquipmentTables` (pass only if step 7 adds X and no tabledata); repo checks 5 (coverage) and 7 (translations).

## Assumptions
- Dates relative to Today(), not WorkDate(), because warranty status, overdue and maintenance checks use Today(). Active assignments get WorkDate() from "EQM Assignment Mgt.".
- Demo marking: number prefix `EQMDEMO-`, Last Name 'Demo', and the tracking table. No unverified Employee field (e.g. Job Title).
- Equipment, employee and product texts are Locked; maintenance descriptions and Performed By are translated, written in the session language (as FR-055 default data).
- Missing or inactive category → item skipped; categories are not re-created.
- Confirm defaults to No. Results shown as a notification, not a Message.
- No vendor, location or dimension set.

## DECISIONS
- FR-066 Demo Data | Chose a tracking table (table ID + number + SystemId) with deterministic `EQMDEMO-` numbers over the prefix alone, so Delete only removes rows the demo inserted and finds renamed records | Reversible: no
- FR-066 Demo Data | Chose to create through the app logic (Equipment Insert(true), Maintenance Insert(true) + "EQM Maintenance-Post", Equipment.AssignEmployee, Status + Modify(true) for Lost/Disposed) over direct inserts, so rules, audit, log and history are real | Reversible: yes
- FR-066 Demo Data | Chose direct Insert of closed assignment entries for history over switching WorkDate around AssignEmployee/UnassignEmployee (no backdating, WorkDate is session state, UnassignEmployee shows a confirm); these rows have no Assigned/Returned audit entries | Reversible: yes
- FR-066 Demo Data | Chose that Delete removes the demo equipment's maintenance records, history, log, audit, assignment, warranty alert and integration event entries with Delete(false)/DeleteAll(false), bypassing "kept permanently" OnDelete guards, over keeping orphans, because those rows exist only because the demo created them | Reversible: yes
- FR-066 Demo Data | Chose to delete integration event entries of demo equipment whether processed or not | Reversible: yes
- FR-066 Demo Data | Chose "edited demo records are still demo; demo records with user-added dependent data are kept" over "any change keeps the record" | Reversible: yes
- FR-066 Demo Data | Chose that a second Create only adds missing master records (each with its full scenario) and never adds to existing ones, over a strict no-op | Reversible: yes
- FR-066 Demo Data | Chose the user's own Employee write permission (WritePermission) over indirect Employee rights in EQM - Administrator, so no permission on a standard table changes | Reversible: yes
- FR-066 Demo Data | Chose indirect `d` on tables 50103, 50105, 50106, 50107, 50108, 50112 (and indirect rimd on 50149) in EQM - Administrator, used only via codeunit 50149's Permissions property, over requiring SUPER | Reversible: yes
- FR-066 Demo Data | Chose not to suppress business events, Power Automate events, integration entries, telemetry or Change Log during demo creation (smallest change); documented in help | Reversible: yes
- FR-066 Demo Data | Chose a single transaction, no Commit, no Codeunit.Run wrapper: failure rolls back everything | Reversible: yes
- FR-066 Demo Data | Chose table 50149, codeunit 50149 and test codeunit 50176 (FR-022 reservation, never built) from a source scan, because the AL MCP had no project loaded | Reversible: yes
- FR-066 Demo Data | Chose to add the permission tests to existing 50162 to reuse its Expanded Permission helpers | Reversible: yes

## Risks
- **Permission widening:** EQM - Administrator gains indirect delete on audit, history, log, maintenance, assignment and warranty tables, usable only inside codeunit 50149. CLAUDE.md lists only objects created by this change as planned; needs the user's eye. Reviewer: confirm no other object's Permissions property lists `d` on these tables.
- **Standard Employee triggers unverified** (no symbols): Employee.Insert(true) with explicit No. expected not to need HR Setup; Employee.Delete(true) expected to delete related HR rows (user needs rights, hence the WritePermission check). Standard subscribers (e.g. Dataverse coupling) unknown. Sandbox check as non-SUPER EQM Administrator with HR edit rights.
- **Employee field names** confirmed only by compiled use; developer runs `al_symbolsearch` when symbols are downloaded.
- **Irreversible side effects:** Power Automate "Equipment Assigned" external events (7), warranty alerts raised later by the job, Change Log entries (if set up, FR-034), telemetry EQM0005-EQM0009. Documented in help.
- **Concurrency:** two simultaneous Create runs → second gets duplicate-key error and rolls back. Acceptable.
- **Bypassing OnDelete guards:** every Delete(false) must be reached only after CanDeleteDemoEquipment returned true for a tracked SystemId (reviewer check).
- **Integration Event Entry has no key on "Equipment No.":** up to 15 filtered scans; note for FR-053 follow-up.
- **D14 rename test** relies on the platform cascading "Equipment No." to closed assignment entries without their OnModify/OnRename. If CI errors, use equipment without history rather than changing app code.
- **Test ID 50176** is FR-022's reservation; FR-053 branch may also use a reserved test ID. Check both branches before merging.
- No AppSourceCop baseline comparison and no separate AppSource validation. New objects, additive actions and permissions only.

## References
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/properties/devenv-permissions-property
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-permissionset-composing
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-writepermission-method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-deleteall-method
- https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission
- https://learn.microsoft.com/dynamics365/business-central/contoso-coffee/contoso-coffee-intro
