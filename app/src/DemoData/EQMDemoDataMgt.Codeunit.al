namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Foundation.Attachment;
using Microsoft.HumanResources.Employee;
using System.Utilities;

// Permission design: the demo data is created and deleted only in this codeunit. The Permissions property
// grants INDIRECT permissions only: it works only with matching rights in the user's permission sets. Only
// EQM - Administrator has them (indirect rimd on the tracking table and indirect delete on the audit, history,
// log, maintenance, assignment and warranty alert tables). Employee is not listed here, so the user's own
// rights on Employee are required: both procedures check that the user can write to the equipment setup and to
// Employee before they change anything.
// The setup page enables the actions only for users with write permission on the equipment setup.
// This behavior still needs a sandbox check.
codeunit 50149 "EQM Demo Data Mgt."
{
    Access = Internal;
    Permissions = tabledata "EQM Demo Data Entry" = rimd,
                  tabledata "EQM Equipment" = rimd,
                  tabledata "EQM Equipment Assignment" = rimd,
                  tabledata "EQM Equipment Audit Entry" = rd,
                  tabledata "EQM Maintenance Record" = rimd,
                  tabledata "EQM Maintenance History Entry" = rd,
                  tabledata "EQM Maintenance Log Entry" = rd,
                  tabledata "EQM Warranty Alert" = rd,
                  tabledata "EQM Integration Event Entry" = rd,
                  tabledata "EQM Equipment Note" = r,
                  tabledata "EQM Equipment Request" = r,
                  tabledata "Document Attachment" = r;

    var
        EmployeesCreatedCount: Integer;
        EquipmentCreatedCount: Integer;
        AssignmentsCreatedCount: Integer;
        MaintenanceCreatedCount: Integer;
        SkippedItemCount: Integer;
        EmployeeNoTok: Label 'EQMDEMO-E%1', Locked = true, Comment = '%1 = employee index with two digits';
        EquipmentNoTok: Label 'EQMDEMO-%1', Locked = true, Comment = '%1 = equipment index with three digits';
        MaintenanceNoTok: Label 'EQMDEMO-M%1', Locked = true, Comment = '%1 = maintenance index with two digits';
        SerialNoTok: Label 'EQMDEMO-SN-%1', Locked = true, Comment = '%1 = equipment index with three digits';
        EmployeeFirstNamesTok: Label 'Ana,Bruno,Carla,David,Elena,Filipe,Grace,Hugo', Locked = true;
        EmployeeLastNameTok: Label 'Demo', Locked = true;
        LaptopCodeTok: Label 'LAPTOP', Locked = true;
        MonitorCodeTok: Label 'MONITOR', Locked = true;
        PhoneCodeTok: Label 'PHONE', Locked = true;
        TabletCodeTok: Label 'TABLET', Locked = true;
        PrinterCodeTok: Label 'PRINTER', Locked = true;
        VehicleCodeTok: Label 'VEHICLE', Locked = true;
        ToolCodeTok: Label 'TOOL', Locked = true;
        Item001Tok: Label 'ThinkPad T14 Gen 5,Lenovo,T14 Gen 5,Lenovo Premier Support', Locked = true;
        Item002Tok: Label 'Latitude 7450,Dell,7450,Dell ProSupport', Locked = true;
        Item003Tok: Label 'MacBook Air 13,Apple,MacBook Air 13,AppleCare', Locked = true;
        Item004Tok: Label 'EliteBook 840 G11,HP,840 G11,HP Care Pack', Locked = true;
        Item005Tok: Label 'UltraSharp U2724D,Dell,U2724D,Dell', Locked = true;
        Item006Tok: Label 'Odyssey G5 27,Samsung,G5 27,Samsung', Locked = true;
        Item007Tok: Label 'iPhone 15,Apple,iPhone 15,AppleCare', Locked = true;
        Item008Tok: Label 'Galaxy S24,Samsung,S24,Samsung Care+', Locked = true;
        Item009Tok: Label 'Pixel 8,Google,Pixel 8,Google', Locked = true;
        Item010Tok: Label 'iPad Air 11,Apple,iPad Air 11,AppleCare', Locked = true;
        Item011Tok: Label 'Galaxy Tab S9,Samsung,Tab S9,Samsung', Locked = true;
        Item012Tok: Label 'LaserJet Pro 4002dn,HP,4002dn,HP', Locked = true;
        Item013Tok: Label 'Corolla Touring Sports,Toyota,Corolla TS,Toyota', Locked = true;
        Item014Tok: Label 'GSB 18V-55 cordless drill,Bosch,GSB 18V-55,Bosch', Locked = true;
        Item015Tok: Label 'Fluke 117 multimeter,Fluke,117,Fluke', Locked = true;
        PerformedByTxt: Label 'IT service desk', MaxLength = 100;
        M01Txt: Label 'Annual inspection and cleaning', MaxLength = 100;
        M02Txt: Label 'Battery replacement', MaxLength = 100;
        M03Txt: Label 'Keyboard repair', MaxLength = 100;
        M04Txt: Label 'Safety inspection', MaxLength = 100;
        M05Txt: Label 'Storage upgrade', MaxLength = 100;
        M06Txt: Label 'Toner and roller replacement', MaxLength = 100;
        M08Txt: Label 'Scheduled service', MaxLength = 100;
        M09Txt: Label 'Brake pad replacement', MaxLength = 100;
        M10Txt: Label 'Calibration check', MaxLength = 100;
        M11Txt: Label 'Screen replacement', MaxLength = 100;
        M12Txt: Label 'Firmware update', MaxLength = 100;
        CreateNoPermissionErr: Label 'You cannot create demo data because you do not have permission to change the equipment setup and to create and delete employees. Ask an administrator to assign you the Equipment Administrator permission set and a permission set that lets you edit employees.';
        DeleteNoPermissionErr: Label 'You cannot delete demo data because you do not have permission to change the equipment setup and to create and delete employees. Ask an administrator to assign you the Equipment Administrator permission set and a permission set that lets you edit employees.';
        CreateDemoDataQst: Label 'This creates sample employees, equipment, assignments and maintenance records in company %1 so that you can try out the app. Existing records are not changed. Do you want to continue?', Comment = '%1 = company name';
        DeleteDemoDataQst: Label 'This deletes the demo data that Create Demo Data added to company %1, including its assignment history, maintenance history, maintenance log, audit trail and warranty alerts. Records that users created are not deleted, and demo records that users added notes, attachments, pictures, requests or other data to are kept. Do you want to continue?', Comment = '%1 = company name';
        DemoDataCreatedMsg: Label 'Demo data was created: %1 employees, %2 equipment, %3 assignments and %4 maintenance records. %5 items were skipped because their number was already used or their category is missing or inactive.', Comment = '%1 = number of employees, %2 = number of equipment, %3 = number of assignments, %4 = number of maintenance records, %5 = number of skipped items';
        NothingCreatedMsg: Label 'No demo data was created. The demo records already exist, or their numbers or categories are not available.';
        DemoDataDeletedMsg: Label 'Demo data was deleted: %1 equipment and %2 employees. %3 equipment and %4 employees were kept because users added data to them.', Comment = '%1 = number of equipment deleted, %2 = number of employees deleted, %3 = number of equipment kept, %4 = number of employees kept';
        NoDemoDataMsg: Label 'There is no demo data to delete in this company.';

    /// <summary>
    /// Asks the user to confirm (default No), creates the demo data and shows the result as a notification.
    /// </summary>
    internal procedure CreateDemoDataWithConfirmation()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        EmployeesCreated: Integer;
        EquipmentCreated: Integer;
        AssignmentsCreated: Integer;
        MaintenanceCreated: Integer;
        SkippedCount: Integer;
    begin
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(CreateDemoDataQst, CompanyName()), false) then
            exit;

        CreateDemoData(EmployeesCreated, EquipmentCreated, AssignmentsCreated, MaintenanceCreated, SkippedCount);

        if (EmployeesCreated = 0) and (EquipmentCreated = 0) and (AssignmentsCreated = 0) and (MaintenanceCreated = 0) then
            SendResultNotification(NothingCreatedMsg)
        else
            SendResultNotification(StrSubstNo(DemoDataCreatedMsg, EmployeesCreated, EquipmentCreated, AssignmentsCreated, MaintenanceCreated, SkippedCount));
    end;

    /// <summary>
    /// Shows a notification when there is nothing to delete. Otherwise asks the user to confirm (default No),
    /// deletes the demo data and shows the result as a notification.
    /// </summary>
    internal procedure DeleteDemoDataWithConfirmation()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        EquipmentDeleted: Integer;
        EmployeesDeleted: Integer;
        EquipmentKept: Integer;
        EmployeesKept: Integer;
    begin
        if not HasDemoData() then begin
            SendResultNotification(NoDemoDataMsg);
            exit;
        end;

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(DeleteDemoDataQst, CompanyName()), false) then
            exit;

        DeleteDemoData(EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept);
        SendResultNotification(StrSubstNo(DemoDataDeletedMsg, EquipmentDeleted, EmployeesDeleted, EquipmentKept, EmployeesKept));
    end;

    /// <summary>
    /// Returns whether the demo data created any record that is still tracked.
    /// </summary>
    /// <returns>True when at least one tracking row exists.</returns>
    internal procedure HasDemoData(): Boolean
    var
        DemoDataEntry: Record "EQM Demo Data Entry";
    begin
        exit(not DemoDataEntry.IsEmpty());
    end;

    /// <summary>
    /// Creates the demo employees, equipment, assignments and maintenance records through the app's own business logic.
    /// Records that already exist are never changed. An item is skipped when its number is already used, or its category
    /// is missing or inactive. Shows no dialog and does not commit.
    /// </summary>
    /// <param name="EmployeesCreated">Returns the number of employees created.</param>
    /// <param name="EquipmentCreated">Returns the number of equipment records created.</param>
    /// <param name="AssignmentsCreated">Returns the number of assignment entries created, active and closed.</param>
    /// <param name="MaintenanceCreated">Returns the number of maintenance records created, open and posted.</param>
    /// <param name="SkippedCount">Returns the number of items that were skipped.</param>
    internal procedure CreateDemoData(var EmployeesCreated: Integer; var EquipmentCreated: Integer; var AssignmentsCreated: Integer; var MaintenanceCreated: Integer; var SkippedCount: Integer)
    var
        EmployeeIndex: Integer;
    begin
        CheckCanManageDemoData(false);

        EmployeesCreatedCount := 0;
        EquipmentCreatedCount := 0;
        AssignmentsCreatedCount := 0;
        MaintenanceCreatedCount := 0;
        SkippedItemCount := 0;

        for EmployeeIndex := 1 to 8 do
            CreateDemoEmployee(EmployeeIndex);

        CreateLaptopScenarios();
        CreateMonitorAndPhoneScenarios();
        CreateTabletPrinterVehicleAndToolScenarios();

        EmployeesCreated := EmployeesCreatedCount;
        EquipmentCreated := EquipmentCreatedCount;
        AssignmentsCreated := AssignmentsCreatedCount;
        MaintenanceCreated := MaintenanceCreatedCount;
        SkippedCount := SkippedItemCount;
    end;

    /// <summary>
    /// Deletes the demo equipment and employees that Create Demo Data tracked, with the records that exist only because
    /// of them. Equipment that users added data to, and employees that anything still refers to, are kept. Shows no
    /// dialog and does not commit.
    /// </summary>
    /// <param name="EquipmentDeleted">Returns the number of equipment records deleted.</param>
    /// <param name="EmployeesDeleted">Returns the number of employees deleted.</param>
    /// <param name="EquipmentKept">Returns the number of demo equipment records that were kept.</param>
    /// <param name="EmployeesKept">Returns the number of demo employees that were kept.</param>
    internal procedure DeleteDemoData(var EquipmentDeleted: Integer; var EmployeesDeleted: Integer; var EquipmentKept: Integer; var EmployeesKept: Integer)
    var
        DemoDataEntry: Record "EQM Demo Data Entry";
        Equipment: Record "EQM Equipment";
        Employee: Record Employee;
        MaintenanceRecord: Record "EQM Maintenance Record";
        RecordNos: List of [Code[20]];
        RecordNo: Code[20];
    begin
        CheckCanManageDemoData(true);

        EquipmentDeleted := 0;
        EmployeesDeleted := 0;
        EquipmentKept := 0;
        EmployeesKept := 0;

        CollectTrackedNumbers(Database::"EQM Equipment", RecordNos);
        foreach RecordNo in RecordNos do begin
            DemoDataEntry.Get(Database::"EQM Equipment", RecordNo);
            if not Equipment.GetBySystemId(DemoDataEntry."Record System Id") then
                DemoDataEntry.Delete()
            else
                if CanDeleteDemoEquipment(Equipment) then begin
                    DeleteDemoEquipment(Equipment);
                    EquipmentDeleted += 1;
                end else
                    EquipmentKept += 1;
        end;

        Clear(RecordNos);
        CollectTrackedNumbers(Database::Employee, RecordNos);
        foreach RecordNo in RecordNos do begin
            DemoDataEntry.Get(Database::Employee, RecordNo);
            if not Employee.GetBySystemId(DemoDataEntry."Record System Id") then
                DemoDataEntry.Delete()
            else
                if IsEmployeeReferenced(Employee."No.") then
                    EmployeesKept += 1
                else begin
                    Employee.Delete(true);
                    DemoDataEntry.Delete();
                    EmployeesDeleted += 1;
                end;
        end;

        Clear(RecordNos);
        CollectTrackedNumbers(Database::"EQM Maintenance Record", RecordNos);
        foreach RecordNo in RecordNos do begin
            DemoDataEntry.Get(Database::"EQM Maintenance Record", RecordNo);
            if not MaintenanceRecord.GetBySystemId(DemoDataEntry."Record System Id") then
                DemoDataEntry.Delete();
        end;
    end;

    local procedure CheckCanManageDemoData(ForDelete: Boolean)
    var
        EquipmentSetup: Record "EQM Equipment Setup";
        Employee: Record Employee;
        NoPermissionError: ErrorInfo;
    begin
        if EquipmentSetup.WritePermission() and Employee.WritePermission() then
            exit;

        if ForDelete then
            NoPermissionError.Message(DeleteNoPermissionErr)
        else
            NoPermissionError.Message(CreateNoPermissionErr);
        Error(NoPermissionError);
    end;

    local procedure SendResultNotification(MessageText: Text)
    var
        ResultNotification: Notification;
    begin
        if not GuiAllowed() then
            exit;

        ResultNotification.Message(MessageText);
        ResultNotification.Scope := NotificationScope::LocalScope;
        ResultNotification.Send();
    end;

    // Tracking

    local procedure IsOwnDemoRecord(TableId: Integer; RecordNo: Code[20]; var SystemId: Guid): Boolean
    var
        DemoDataEntry: Record "EQM Demo Data Entry";
    begin
        if not DemoDataEntry.Get(TableId, RecordNo) then
            exit(false);
        SystemId := DemoDataEntry."Record System Id";
        exit(true);
    end;

    local procedure IsTrackedRecord(TableId: Integer; SystemId: Guid): Boolean
    var
        DemoDataEntry: Record "EQM Demo Data Entry";
    begin
        DemoDataEntry.SetCurrentKey("Record System Id");
        DemoDataEntry.SetRange("Record System Id", SystemId);
        DemoDataEntry.SetRange("Table ID", TableId);
        exit(not DemoDataEntry.IsEmpty());
    end;

    local procedure TrackRecord(TableId: Integer; RecordNo: Code[20]; SystemId: Guid)
    var
        DemoDataEntry: Record "EQM Demo Data Entry";
        IsNewEntry: Boolean;
    begin
        IsNewEntry := not DemoDataEntry.Get(TableId, RecordNo);
        if IsNewEntry then begin
            DemoDataEntry.Init();
            DemoDataEntry."Table ID" := TableId;
            DemoDataEntry."Record No." := RecordNo;
        end;
        DemoDataEntry."Record System Id" := SystemId;
        DemoDataEntry."Created At" := CurrentDateTime();
        DemoDataEntry."Created By" := CopyStr(UserId(), 1, MaxStrLen(DemoDataEntry."Created By"));
        if IsNewEntry then
            DemoDataEntry.Insert()
        else
            DemoDataEntry.Modify();
    end;

    local procedure DeleteTrackingRow(TableId: Integer; SystemId: Guid)
    var
        DemoDataEntry: Record "EQM Demo Data Entry";
    begin
        DemoDataEntry.SetCurrentKey("Record System Id");
        DemoDataEntry.SetRange("Record System Id", SystemId);
        DemoDataEntry.SetRange("Table ID", TableId);
        DemoDataEntry.DeleteAll();
    end;

    local procedure CollectTrackedNumbers(TableId: Integer; var RecordNos: List of [Code[20]])
    var
        DemoDataEntry: Record "EQM Demo Data Entry";
    begin
        DemoDataEntry.SetRange("Table ID", TableId);
        if DemoDataEntry.FindSet() then
            repeat
                RecordNos.Add(DemoDataEntry."Record No.");
            until DemoDataEntry.Next() = 0;
    end;

    local procedure DemoEmployeeNo(Index: Integer): Code[20]
    begin
        exit(CopyStr(StrSubstNo(EmployeeNoTok, Format(Index, 0, '<Integer,2><Filler Character,0>')), 1, 20));
    end;

    local procedure DemoEquipmentNo(Index: Integer): Code[20]
    begin
        exit(CopyStr(StrSubstNo(EquipmentNoTok, Format(Index, 0, '<Integer,3><Filler Character,0>')), 1, 20));
    end;

    local procedure DemoMaintenanceNo(Index: Integer): Code[20]
    begin
        exit(CopyStr(StrSubstNo(MaintenanceNoTok, Format(Index, 0, '<Integer,2><Filler Character,0>')), 1, 20));
    end;

    // Create

    local procedure CreateDemoEmployee(Index: Integer)
    var
        Employee: Record Employee;
        EmployeeNo: Code[20];
        SystemId: Guid;
    begin
        EmployeeNo := DemoEmployeeNo(Index);
        if Employee.Get(EmployeeNo) then begin
            SkippedItemCount += 1;
            exit;
        end;
        if IsOwnDemoRecord(Database::Employee, EmployeeNo, SystemId) then
            if Employee.GetBySystemId(SystemId) then begin
                SkippedItemCount += 1;
                exit;
            end;

        Employee.Init();
        Employee."No." := EmployeeNo;
        Employee."First Name" := CopyStr(SelectStr(Index, EmployeeFirstNamesTok), 1, MaxStrLen(Employee."First Name"));
        Employee."Last Name" := CopyStr(EmployeeLastNameTok, 1, MaxStrLen(Employee."Last Name"));
        Employee.Status := Employee.Status::Active;
        Employee."Privacy Blocked" := false;
        Employee.Insert(true);
        TrackRecord(Database::Employee, Employee."No.", Employee.SystemId);
        EmployeesCreatedCount += 1;
    end;

    local procedure CreateLaptopScenarios()
    begin
        if InsertDemoEquipment(1, LaptopCodeTok, Item001Tok, 420, 1450, true, -420, 310, 12) then begin
            PostDemoMaintenance(1, 1, "EQM Maintenance Type"::Preventive, 60, 85, M01Txt);
            InsertClosedDemoAssignment(1, 5, 400, 210);
            AssignDemoEmployee(1, 1);
        end;
        if InsertDemoEquipment(2, LaptopCodeTok, Item002Tok, 700, 1320, true, -700, 25, 12) then begin
            PostDemoMaintenance(2, 2, "EQM Maintenance Type"::Corrective, 150, 240, M02Txt);
            AssignDemoEmployee(2, 2);
        end;
        if InsertDemoEquipment(3, LaptopCodeTok, Item003Tok, 900, 1199, true, -900, -170, 0) then begin
            PostDemoMaintenance(3, 11, "EQM Maintenance Type"::Corrective, 400, 180, M11Txt);
            InsertClosedDemoAssignment(3, 3, 880, 300);
            InsertClosedDemoAssignment(3, 6, 290, 30);
        end;
        if InsertDemoEquipment(4, LaptopCodeTok, Item004Tok, 120, 1380, true, -120, 975, 12) then
            RegisterOpenDemoMaintenance(4, 3, "EQM Maintenance Type"::Corrective, 20, 0, M03Txt);
    end;

    local procedure CreateMonitorAndPhoneScenarios()
    begin
        if InsertDemoEquipment(5, MonitorCodeTok, Item005Tok, 500, 420, true, -500, 595, 0) then
            AssignDemoEmployee(5, 1);
        if InsertDemoEquipment(6, MonitorCodeTok, Item006Tok, 1100, 310, true, -1100, -370, 0) then begin
            PostDemoMaintenance(6, 12, "EQM Maintenance Type"::Upgrade, 500, 0, M12Txt);
            InsertClosedDemoAssignment(6, 4, 1090, 400);
            SetDemoFinalStatus(6, "EQM Equipment Status"::Disposed);
        end;
        if InsertDemoEquipment(7, PhoneCodeTok, Item007Tok, 300, 899, true, -300, 65, 0) then
            AssignDemoEmployee(7, 3);
        if InsertDemoEquipment(8, PhoneCodeTok, Item008Tok, 250, 799, true, -250, 115, 0) then
            AssignDemoEmployee(8, 4);
        if InsertDemoEquipment(9, PhoneCodeTok, Item009Tok, 600, 699, true, -600, 12, 0) then begin
            InsertClosedDemoAssignment(9, 7, 590, 90);
            SetDemoFinalStatus(9, "EQM Equipment Status"::Lost);
        end;
    end;

    local procedure CreateTabletPrinterVehicleAndToolScenarios()
    begin
        if InsertDemoEquipment(10, TabletCodeTok, Item010Tok, 200, 749, true, -200, 165, 0) then
            InsertClosedDemoAssignment(10, 8, 180, 60);
        if InsertDemoEquipment(11, TabletCodeTok, Item011Tok, 380, 869, true, -380, 350, 12) then begin
            PostDemoMaintenance(11, 4, "EQM Maintenance Type"::Inspection, 90, 0, M04Txt);
            RegisterOpenDemoMaintenance(11, 5, "EQM Maintenance Type"::Upgrade, 3, 120, M05Txt);
        end;
        if InsertDemoEquipment(12, PrinterCodeTok, Item012Tok, 800, 389, true, -800, -70, 6) then begin
            PostDemoMaintenance(12, 6, "EQM Maintenance Type"::Preventive, 400, 75, M06Txt);
            PostDemoMaintenance(12, 7, "EQM Maintenance Type"::Preventive, 220, 75, M06Txt);
        end;
        if InsertDemoEquipment(13, VehicleCodeTok, Item013Tok, 1000, 28500, true, -1000, 95, 6) then begin
            PostDemoMaintenance(13, 8, "EQM Maintenance Type"::Preventive, 160, 320, M08Txt);
            PostDemoMaintenance(13, 9, "EQM Maintenance Type"::Corrective, 75, 1150, M09Txt);
            AssignDemoEmployee(13, 6);
        end;
        if InsertDemoEquipment(14, ToolCodeTok, Item014Tok, 150, 189, true, -150, 580, 0) then
            AssignDemoEmployee(14, 7);
        if InsertDemoEquipment(15, ToolCodeTok, Item015Tok, 90, 265, false, 0, 0, 12) then
            RegisterOpenDemoMaintenance(15, 10, "EQM Maintenance Type"::Inspection, 30, 45, M10Txt);
    end;

    local procedure InsertDemoEquipment(Index: Integer; CategoryCode: Text; ItemData: Text; PurchaseDaysAgo: Integer; PurchaseCost: Decimal; HasWarranty: Boolean; WarrantyStartDays: Integer; WarrantyEndDays: Integer; MaintenanceFrequency: Integer): Boolean
    var
        Equipment: Record "EQM Equipment";
        OtherEquipment: Record "EQM Equipment";
        Category: Record "EQM Equipment Category";
        EquipmentNo: Code[20];
        SerialNo: Code[50];
        SystemId: Guid;
    begin
        EquipmentNo := DemoEquipmentNo(Index);
        if Equipment.Get(EquipmentNo) then begin
            SkippedItemCount += 1;
            exit(false);
        end;
        if IsOwnDemoRecord(Database::"EQM Equipment", EquipmentNo, SystemId) then
            if Equipment.GetBySystemId(SystemId) then begin
                SkippedItemCount += 1;
                exit(false);
            end;
        Category.SetLoadFields(Active);
        if not Category.Get(CopyStr(CategoryCode, 1, MaxStrLen(Category.Code))) or not Category.Active then begin
            SkippedItemCount += 1;
            exit(false);
        end;

        SerialNo := CopyStr(StrSubstNo(SerialNoTok, Format(Index, 0, '<Integer,3><Filler Character,0>')), 1, MaxStrLen(SerialNo));
        OtherEquipment.SetCurrentKey("Serial No.");
        OtherEquipment.SetRange("Serial No.", SerialNo);
        if not OtherEquipment.IsEmpty() then
            SerialNo := '';

        Equipment.Init();
        Equipment."No." := EquipmentNo;
        Equipment.Description := CopyStr(SelectStr(1, ItemData), 1, MaxStrLen(Equipment.Description));
        Equipment."Category Code" := Category.Code;
        Equipment."Serial No." := SerialNo;
        Equipment.Manufacturer := CopyStr(SelectStr(2, ItemData), 1, MaxStrLen(Equipment.Manufacturer));
        Equipment.Model := CopyStr(SelectStr(3, ItemData), 1, MaxStrLen(Equipment.Model));
        Equipment."Purchase Date" := Today() - PurchaseDaysAgo;
        Equipment."Purchase Cost" := PurchaseCost;
        if HasWarranty then begin
            Equipment."Warranty Start Date" := Today() + WarrantyStartDays;
            Equipment."Warranty End Date" := Today() + WarrantyEndDays;
            Equipment."Warranty Provider" := CopyStr(SelectStr(4, ItemData), 1, MaxStrLen(Equipment."Warranty Provider"));
        end;
        Equipment."Maintenance Frequency (Months)" := MaintenanceFrequency;
        Equipment.Insert(true);
        TrackRecord(Database::"EQM Equipment", Equipment."No.", Equipment.SystemId);
        EquipmentCreatedCount += 1;
        exit(true);
    end;

    local procedure PostDemoMaintenance(EquipmentIndex: Integer; MaintenanceIndex: Integer; MaintenanceType: Enum "EQM Maintenance Type"; DaysAgo: Integer; Cost: Decimal; DescriptionText: Text)
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
        MaintenancePost: Codeunit "EQM Maintenance-Post";
    begin
        if not InsertDemoMaintenance(MaintenanceRecord, EquipmentIndex, MaintenanceIndex, MaintenanceType, DaysAgo, Cost, DescriptionText) then
            exit;
        MaintenancePost.Run(MaintenanceRecord);
    end;

    local procedure RegisterOpenDemoMaintenance(EquipmentIndex: Integer; MaintenanceIndex: Integer; MaintenanceType: Enum "EQM Maintenance Type"; DaysAgo: Integer; Cost: Decimal; DescriptionText: Text)
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        InsertDemoMaintenance(MaintenanceRecord, EquipmentIndex, MaintenanceIndex, MaintenanceType, DaysAgo, Cost, DescriptionText);
    end;

    local procedure InsertDemoMaintenance(var MaintenanceRecord: Record "EQM Maintenance Record"; EquipmentIndex: Integer; MaintenanceIndex: Integer; MaintenanceType: Enum "EQM Maintenance Type"; DaysAgo: Integer; Cost: Decimal; DescriptionText: Text): Boolean
    var
        MaintenanceNo: Code[20];
    begin
        MaintenanceNo := DemoMaintenanceNo(MaintenanceIndex);
        if MaintenanceRecord.Get(MaintenanceNo) then begin
            SkippedItemCount += 1;
            exit(false);
        end;

        MaintenanceRecord.Init();
        MaintenanceRecord."No." := MaintenanceNo;
        MaintenanceRecord."Equipment No." := DemoEquipmentNo(EquipmentIndex);
        MaintenanceRecord."Maintenance Date" := Today() - DaysAgo;
        MaintenanceRecord."Maintenance Type" := MaintenanceType;
        MaintenanceRecord.Cost := Cost;
        MaintenanceRecord.Description := CopyStr(DescriptionText, 1, MaxStrLen(MaintenanceRecord.Description));
        MaintenanceRecord."Performed By" := CopyStr(PerformedByTxt, 1, MaxStrLen(MaintenanceRecord."Performed By"));
        MaintenanceRecord.Insert(true);
        TrackRecord(Database::"EQM Maintenance Record", MaintenanceRecord."No.", MaintenanceRecord.SystemId);
        MaintenanceCreatedCount += 1;
        exit(true);
    end;

    local procedure GetOwnDemoEmployee(EmployeeIndex: Integer; var Employee: Record Employee): Boolean
    var
        EmployeeNo: Code[20];
        SystemId: Guid;
    begin
        EmployeeNo := DemoEmployeeNo(EmployeeIndex);
        if not IsOwnDemoRecord(Database::Employee, EmployeeNo, SystemId) then
            exit(false);
        if not Employee.GetBySystemId(SystemId) then
            exit(false);
        exit(Employee."No." = EmployeeNo);
    end;

    local procedure InsertClosedDemoAssignment(EquipmentIndex: Integer; EmployeeIndex: Integer; FromDaysAgo: Integer; ToDaysAgo: Integer)
    var
        Employee: Record Employee;
        EquipmentAssignment: Record "EQM Equipment Assignment";
        UserName: Code[50];
    begin
        if not GetOwnDemoEmployee(EmployeeIndex, Employee) then begin
            SkippedItemCount += 1;
            exit;
        end;

        UserName := CopyStr(UserId(), 1, MaxStrLen(UserName));
        EquipmentAssignment.Init();
        EquipmentAssignment."Equipment No." := DemoEquipmentNo(EquipmentIndex);
        EquipmentAssignment."Employee No." := Employee."No.";
        EquipmentAssignment."Assignment Date" := Today() - FromDaysAgo;
        EquipmentAssignment."Assigned By" := UserName;
        EquipmentAssignment.Status := EquipmentAssignment.Status::Closed;
        EquipmentAssignment."Closing Date" := Today() - ToDaysAgo;
        EquipmentAssignment."Closed By" := UserName;
        EquipmentAssignment.Insert(true);
        AssignmentsCreatedCount += 1;
    end;

    local procedure AssignDemoEmployee(EquipmentIndex: Integer; EmployeeIndex: Integer)
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
    begin
        if not GetOwnDemoEmployee(EmployeeIndex, Employee) then begin
            SkippedItemCount += 1;
            exit;
        end;
        if (Employee.Status <> Employee.Status::Active) or Employee."Privacy Blocked" then begin
            SkippedItemCount += 1;
            exit;
        end;

        Equipment.Get(DemoEquipmentNo(EquipmentIndex));
        Equipment.AssignEmployee(Employee."No.");
        AssignmentsCreatedCount += 1;
    end;

    local procedure SetDemoFinalStatus(EquipmentIndex: Integer; EquipmentStatus: Enum "EQM Equipment Status")
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.Get(DemoEquipmentNo(EquipmentIndex));
        Equipment.Status := EquipmentStatus;
        Equipment.Modify(true);
    end;

    // Delete

    local procedure CanDeleteDemoEquipment(Equipment: Record "EQM Equipment"): Boolean
    var
        EquipmentNote: Record "EQM Equipment Note";
        EquipmentRequest: Record "EQM Equipment Request";
        DocumentAttachment: Record "Document Attachment";
        MaintenanceRecord: Record "EQM Maintenance Record";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        Employee: Record Employee;
    begin
        if Equipment.Picture.Count() > 0 then
            exit(false);

        EquipmentNote.SetCurrentKey("Equipment No.", "Entry No.");
        EquipmentNote.SetRange("Equipment No.", Equipment."No.");
        if not EquipmentNote.IsEmpty() then
            exit(false);

        DocumentAttachment.SetRange("Table ID", Database::"EQM Equipment");
        DocumentAttachment.SetRange("No.", Equipment."No.");
        if not DocumentAttachment.IsEmpty() then
            exit(false);

        EquipmentRequest.SetRange("Assigned Equipment No.", Equipment."No.");
        if not EquipmentRequest.IsEmpty() then
            exit(false);

        MaintenanceRecord.SetCurrentKey("Equipment No.", "Maintenance Date");
        MaintenanceRecord.SetRange("Equipment No.", Equipment."No.");
        if MaintenanceRecord.FindSet() then
            repeat
                if not IsTrackedRecord(Database::"EQM Maintenance Record", MaintenanceRecord.SystemId) then
                    exit(false);
            until MaintenanceRecord.Next() = 0;

        EquipmentAssignment.SetCurrentKey("Equipment No.", Status);
        EquipmentAssignment.SetRange("Equipment No.", Equipment."No.");
        if EquipmentAssignment.FindSet() then
            repeat
                if not Employee.Get(EquipmentAssignment."Employee No.") then
                    exit(false);
                if not IsTrackedRecord(Database::Employee, Employee.SystemId) then
                    exit(false);
            until EquipmentAssignment.Next() = 0;

        exit(true);
    end;

    // The OnDelete triggers of these tables forbid deleting them by design. Delete(false) and DeleteAll(false)
    // skip them on purpose: this runs only after CanDeleteDemoEquipment confirmed that every one of these rows
    // exists because the demo created the equipment.
    local procedure DeleteDemoEquipment(Equipment: Record "EQM Equipment")
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
        MaintenanceLogEntry: Record "EQM Maintenance Log Entry";
        MaintenanceHistoryEntry: Record "EQM Maintenance History Entry";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        AuditEntry: Record "EQM Equipment Audit Entry";
        WarrantyAlert: Record "EQM Warranty Alert";
        IntegrationEventEntry: Record "EQM Integration Event Entry";
    begin
        MaintenanceRecord.SetCurrentKey("Equipment No.", "Maintenance Date");
        MaintenanceRecord.SetRange("Equipment No.", Equipment."No.");
        if MaintenanceRecord.FindSet() then
            repeat
                MaintenanceLogEntry.SetCurrentKey("Maintenance No.");
                MaintenanceLogEntry.SetRange("Maintenance No.", MaintenanceRecord."No.");
                MaintenanceLogEntry.DeleteAll(false);
                DeleteTrackingRow(Database::"EQM Maintenance Record", MaintenanceRecord.SystemId);
            until MaintenanceRecord.Next() = 0;

        MaintenanceHistoryEntry.SetCurrentKey("Equipment No.", "Maintenance Date");
        MaintenanceHistoryEntry.SetRange("Equipment No.", Equipment."No.");
        MaintenanceHistoryEntry.DeleteAll(false);

        MaintenanceRecord.DeleteAll(false);

        EquipmentAssignment.SetCurrentKey("Equipment No.", Status);
        EquipmentAssignment.SetRange("Equipment No.", Equipment."No.");
        EquipmentAssignment.DeleteAll(false);

        AuditEntry.SetCurrentKey("Equipment No.", "Entry No.");
        AuditEntry.SetRange("Equipment No.", Equipment."No.");
        AuditEntry.DeleteAll(false);

        WarrantyAlert.SetCurrentKey("Equipment No.", "Warranty End Date", "Alert Interval");
        WarrantyAlert.SetRange("Equipment No.", Equipment."No.");
        WarrantyAlert.DeleteAll(false);

        IntegrationEventEntry.SetRange("Equipment No.", Equipment."No.");
        IntegrationEventEntry.DeleteAll(false);

        DeleteTrackingRow(Database::"EQM Equipment", Equipment.SystemId);
        Equipment.Delete(false);
    end;

    local procedure IsEmployeeReferenced(EmployeeNo: Code[20]): Boolean
    var
        Equipment: Record "EQM Equipment";
        EquipmentAssignment: Record "EQM Equipment Assignment";
        EquipmentRequest: Record "EQM Equipment Request";
        DocumentAttachment: Record "Document Attachment";
    begin
        Equipment.SetCurrentKey("Assigned Employee No.", Status);
        Equipment.SetRange("Assigned Employee No.", EmployeeNo);
        if not Equipment.IsEmpty() then
            exit(true);

        EquipmentAssignment.SetCurrentKey("Employee No.", Status);
        EquipmentAssignment.SetRange("Employee No.", EmployeeNo);
        if not EquipmentAssignment.IsEmpty() then
            exit(true);

        EquipmentRequest.SetCurrentKey("Employee No.", Status);
        EquipmentRequest.SetRange("Employee No.", EmployeeNo);
        if not EquipmentRequest.IsEmpty() then
            exit(true);

        DocumentAttachment.SetRange("Table ID", Database::Employee);
        DocumentAttachment.SetRange("No.", EmployeeNo);
        exit(not DocumentAttachment.IsEmpty());
    end;
}
