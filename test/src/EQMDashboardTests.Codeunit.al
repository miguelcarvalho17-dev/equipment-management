namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;

codeunit 50161 "EQM Dashboard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        CategoryCodeTok: Label 'DBCAT', Locked = true;
        EquipmentNoTok: Label 'DBEQ%1', Locked = true;
        RequestNoTok: Label 'DBREQ%1', Locked = true;
        MaintenanceNoTok: Label 'DBMNT%1', Locked = true;
        EndOfMonthFormulaTok: Label '<CM>', Locked = true;
        Counter: Integer;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PendingRequestsAreCounted()
    var
        Request: Record "EQM Equipment Request";
        Baseline: Integer;
        NoOfRequests: Integer;
        Index: Integer;
    begin
        // [SCENARIO 1] Requests pending approval are counted
        // [GIVEN] The current value B of the tile and N requests with status Pending Approval
        Baseline := GetPendingApprovals(Today());
        NoOfRequests := Random(3);
        for Index := 1 to NoOfRequests do
            InsertRequest(Request.Status::"Pending Approval");

        // [WHEN] The tile is calculated
        // [THEN] The value is B + N
        Assert.AreEqual(Baseline + NoOfRequests, GetPendingApprovals(Today()), 'Pending requests should be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OtherRequestStatusesAreNotCounted()
    var
        Request: Record "EQM Equipment Request";
        Baseline: Integer;
    begin
        // [SCENARIO 2] (negative) Requests that are not pending approval are not counted
        // [GIVEN] The current value B and one request each with status Open, Approved, Rejected and Completed
        Baseline := GetPendingApprovals(Today());
        InsertRequest(Request.Status::Open);
        InsertRequest(Request.Status::Approved);
        InsertRequest(Request.Status::Rejected);
        InsertRequest(Request.Status::Completed);

        // [WHEN] The tile is calculated
        // [THEN] The value is B
        Assert.AreEqual(Baseline, GetPendingApprovals(Today()), 'Requests with other statuses should not be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantiesFromTodayToEndOfMonthAreCounted()
    var
        Equipment: Record "EQM Equipment";
        ReferenceDate: Date;
        Baseline: Integer;
    begin
        // [SCENARIO 3] Warranties ending from the reference date to the end of the month are counted, both boundaries included
        // [GIVEN] The current value B and available equipment with end dates R, R + a few days and the last day of the month
        ReferenceDate := MidMonthDate();
        Baseline := GetWarrantiesThisMonth(ReferenceDate);
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Available, 0, ReferenceDate);
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Available, 0, ReferenceDate + Random(5));
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Available, 0, CalcDate(EndOfMonthFormulaTok, ReferenceDate));

        // [WHEN] The tile is calculated for R
        // [THEN] The value is B + 3
        Assert.AreEqual(Baseline + 3, GetWarrantiesThisMonth(ReferenceDate), 'Warranties inside the window should be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WarrantiesOutsideTheWindowAreNotCounted()
    var
        Equipment: Record "EQM Equipment";
        ReferenceDate: Date;
        Baseline: Integer;
    begin
        // [SCENARIO 4] (negative) Warranties before R, after the end of the month or without an end date are not counted
        // [GIVEN] The current value B and equipment with end dates R - 1, the day after the end of the month and blank
        ReferenceDate := MidMonthDate();
        Baseline := GetWarrantiesThisMonth(ReferenceDate);
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Available, 0, ReferenceDate - 1);
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Available, 0, CalcDate(EndOfMonthFormulaTok, ReferenceDate) + 1);
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Available, 0, 0D);

        // [WHEN] The tile is calculated for R
        // [THEN] The value is B
        Assert.AreEqual(Baseline, GetWarrantiesThisMonth(ReferenceDate), 'Warranties outside the window should not be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LostAndDisposedWarrantiesAreNotCounted()
    var
        Equipment: Record "EQM Equipment";
        ReferenceDate: Date;
        Baseline: Integer;
    begin
        // [SCENARIO 5] (negative) Lost and disposed equipment is not counted
        // [GIVEN] The current value B, one Lost and one Disposed equipment with an end date inside the window
        ReferenceDate := MidMonthDate();
        Baseline := GetWarrantiesThisMonth(ReferenceDate);
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Lost, 0, ReferenceDate + 1);
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Disposed, 0, ReferenceDate + 1);

        // [WHEN] The tile is calculated for R
        // [THEN] The value is B
        Assert.AreEqual(Baseline, GetWarrantiesThisMonth(ReferenceDate), 'Lost and disposed equipment should not be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OnLastDayOfMonthOnlyThatDayCounts()
    var
        Equipment: Record "EQM Equipment";
        ReferenceDate: Date;
        Baseline: Integer;
    begin
        // [SCENARIO 6] (boundary) On the last day of the month only warranties ending that day are counted
        // [GIVEN] R2 is the last day of the month, the current value B for R2, and equipment ending on R2 and on R2 + 1
        ReferenceDate := CalcDate(EndOfMonthFormulaTok, MidMonthDate());
        Baseline := GetWarrantiesThisMonth(ReferenceDate);
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Available, 0, ReferenceDate);
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Available, 0, ReferenceDate + 1);

        // [WHEN] The tile is calculated for R2
        // [THEN] The value is B + 1
        Assert.AreEqual(Baseline + 1, GetWarrantiesThisMonth(ReferenceDate), 'Only the warranty ending on the last day should be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankReferenceDateMeansToday()
    var
        EquipmentCue: Record "EQM Equipment Cue";
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
    begin
        // [SCENARIO 7] A blank reference date means today
        // [GIVEN] A cue record
        EquipmentCue.Init();
        EquipmentCue.Insert();

        // [WHEN] The warranty filters are set with a blank reference date
        DashboardMgt.SetWarrantyCueFilters(EquipmentCue, 0D);

        // [THEN] The month filter runs from today to the end of the current month
        Assert.AreEqual(Today(), EquipmentCue.GetRangeMin("Warranty Month Filter"), 'The filter should start today');
        Assert.AreEqual(CalcDate(EndOfMonthFormulaTok, Today()), EquipmentCue.GetRangeMax("Warranty Month Filter"), 'The filter should end on the last day of the month');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenMaintenanceRecordsAreCounted()
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
        Equipment: Record "EQM Equipment";
        Baseline: Integer;
        NoOfRecords: Integer;
        Index: Integer;
    begin
        // [SCENARIO 8] Open maintenance records are counted
        // [GIVEN] The current value B and equipment E with N open maintenance records
        Baseline := GetOpenMaintenance();
        CreateEquipment(Equipment);
        NoOfRecords := Random(3);
        for Index := 1 to NoOfRecords do
            InsertMaintenanceRecord(Equipment."No.", MaintenanceRecord.Status::Open);

        // [WHEN] The tile is calculated
        // [THEN] The value is B + N
        Assert.AreEqual(Baseline + NoOfRecords, GetOpenMaintenance(), 'Open maintenance records should be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PostedMaintenanceRecordsAreNotCounted()
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
        Equipment: Record "EQM Equipment";
        Baseline: Integer;
        Index: Integer;
    begin
        // [SCENARIO 9] (negative) Posted maintenance records are not counted
        // [GIVEN] The current value B and equipment E with posted maintenance records
        Baseline := GetOpenMaintenance();
        CreateEquipment(Equipment);
        for Index := 1 to Random(3) do
            InsertMaintenanceRecord(Equipment."No.", MaintenanceRecord.Status::Posted);

        // [WHEN] The tile is calculated
        // [THEN] The value is B
        Assert.AreEqual(Baseline, GetOpenMaintenance(), 'Posted maintenance records should not be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CostOfEquipmentInUseIsSummed()
    var
        Equipment: Record "EQM Equipment";
        Baseline: Decimal;
        Expected: Decimal;
        Cost: Decimal;
    begin
        // [SCENARIO 10] The purchase cost of equipment that is available, assigned or in maintenance is summed
        // [GIVEN] The current value V and three equipment records with those statuses, each with a purchase cost
        Baseline := GetTotalAssetsValue();
        Cost := Random(100000) / 100;
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Available, Cost, 0D);
        Expected += Cost;
        Cost := Random(100000) / 100;
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Assigned, Cost, 0D);
        Expected += Cost;
        Cost := Random(100000) / 100;
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::"In Maintenance", Cost, 0D);
        Expected += Cost;

        // [WHEN] The tile is calculated
        // [THEN] The value is V + the sum S of the three costs
        Assert.AreEqual(Baseline + Expected, GetTotalAssetsValue(), 'The cost of equipment in use should be summed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LostAndDisposedCostIsExcluded()
    var
        Equipment: Record "EQM Equipment";
        Baseline: Decimal;
    begin
        // [SCENARIO 11] (negative) The purchase cost of lost and disposed equipment is not summed
        // [GIVEN] The current value V and one Lost and one Disposed equipment with a purchase cost
        Baseline := GetTotalAssetsValue();
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Lost, Random(100000) / 100 + 1, 0D);
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Disposed, Random(100000) / 100 + 1, 0D);

        // [WHEN] The tile is calculated
        // [THEN] The value is V
        Assert.AreEqual(Baseline, GetTotalAssetsValue(), 'The cost of lost and disposed equipment should be excluded');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CuePageShowsTheCalculatedValues()
    var
        Request: Record "EQM Equipment Request";
        MaintenanceRecord: Record "EQM Maintenance Record";
        Equipment: Record "EQM Equipment";
        CuesPage: TestPage "EQM Equipment Cues";
    begin
        // [SCENARIO 12] The cue page shows the four tiles with the calculated values
        // [GIVEN] The Role Center notifications are switched off, one pending request, one open maintenance record
        // and one available equipment with a purchase cost and a warranty ending today
        DisableRoleCenterNotifications();
        InsertRequest(Request.Status::"Pending Approval");
        CreateEquipment(Equipment);
        SetEquipmentFields(Equipment, Equipment.Status::Available, Random(100000) / 100 + 1, Today());
        InsertMaintenanceRecord(Equipment."No.", MaintenanceRecord.Status::Open);

        // [WHEN] The cue page is opened
        CuesPage.OpenView();

        // [THEN] The four tiles show the values calculated on a cue record
        Assert.AreEqual(GetPendingApprovals(Today()), CuesPage."Requests Pending Approval".AsInteger(), 'The pending approvals tile should show the calculated value');
        Assert.AreEqual(GetWarrantiesThisMonth(Today()), CuesPage."Warranties Expiring This Month".AsInteger(), 'The warranties tile should show the calculated value');
        Assert.AreEqual(GetOpenMaintenance(), CuesPage."Open Maintenance Activities".AsInteger(), 'The open maintenance tile should show the calculated value');
        Assert.AreEqual(GetTotalAssetsValue(), CuesPage."Total Assets Value".AsDecimal(), 'The total assets value tile should show the calculated value');
    end;

    local procedure InitCue(var EquipmentCue: Record "EQM Equipment Cue"; ReferenceDate: Date)
    var
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
    begin
        EquipmentCue.Init();
        EquipmentCue.Insert();
        DashboardMgt.SetWarrantyCueFilters(EquipmentCue, ReferenceDate);
    end;

    local procedure GetPendingApprovals(ReferenceDate: Date): Integer
    var
        EquipmentCue: Record "EQM Equipment Cue";
    begin
        InitCue(EquipmentCue, ReferenceDate);
        EquipmentCue.CalcFields("Requests Pending Approval");
        exit(EquipmentCue."Requests Pending Approval");
    end;

    local procedure GetWarrantiesThisMonth(ReferenceDate: Date): Integer
    var
        EquipmentCue: Record "EQM Equipment Cue";
    begin
        InitCue(EquipmentCue, ReferenceDate);
        EquipmentCue.CalcFields("Warranties Expiring This Month");
        exit(EquipmentCue."Warranties Expiring This Month");
    end;

    local procedure GetOpenMaintenance(): Integer
    var
        EquipmentCue: Record "EQM Equipment Cue";
    begin
        InitCue(EquipmentCue, Today());
        EquipmentCue.CalcFields("Open Maintenance Activities");
        exit(EquipmentCue."Open Maintenance Activities");
    end;

    local procedure GetTotalAssetsValue(): Decimal
    var
        EquipmentCue: Record "EQM Equipment Cue";
    begin
        InitCue(EquipmentCue, Today());
        EquipmentCue.CalcFields("Total Assets Value");
        exit(EquipmentCue."Total Assets Value");
    end;

    local procedure CreateEquipment(var Equipment: Record "EQM Equipment")
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CategoryCodeTok;
        Category.Active := true;
        if not Category.Insert() then
            Category.Modify();

        Counter += 1;
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, Counter), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := 'Test equipment';
        Equipment."Category Code" := CategoryCodeTok;
        Equipment.Insert(true);
    end;

    local procedure SetEquipmentFields(var Equipment: Record "EQM Equipment"; NewStatus: Enum "EQM Equipment Status"; PurchaseCost: Decimal; WarrantyEndDate: Date)
    begin
        // Set the fields directly, without validation, to avoid dependency on the assignment flow
        Equipment.Status := NewStatus;
        Equipment."Purchase Cost" := PurchaseCost;
        Equipment."Warranty End Date" := WarrantyEndDate;
        Equipment.Modify(false);
    end;

    local procedure InsertRequest(NewStatus: Enum "EQM Request Status")
    var
        Request: Record "EQM Equipment Request";
    begin
        Counter += 1;
        Request.Init();
        Request."No." := CopyStr(StrSubstNo(RequestNoTok, Counter), 1, MaxStrLen(Request."No."));
        Request."Request Date" := Today();
        Request.Status := NewStatus;
        Request.Insert(false);
    end;

    local procedure InsertMaintenanceRecord(EquipmentNo: Code[20]; NewStatus: Enum "EQM Maintenance Status")
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        Counter += 1;
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := CopyStr(StrSubstNo(MaintenanceNoTok, Counter), 1, MaxStrLen(MaintenanceRecord."No."));
        MaintenanceRecord."Equipment No." := EquipmentNo;
        MaintenanceRecord."Maintenance Date" := Today();
        MaintenanceRecord.Status := NewStatus;
        MaintenanceRecord.Insert(false);
    end;

    local procedure MidMonthDate(): Date
    begin
        exit(DMY2Date(15, Date2DMY(Today(), 2), Date2DMY(Today(), 3)));
    end;

    local procedure DisableRoleCenterNotifications()
    var
        NotificationMgt: Codeunit "EQM Notification Mgt.";
        WarrantyNotification: Notification;
        OverdueNotification: Notification;
    begin
        WarrantyNotification.Id := NotificationMgt.GetWarrantyNotificationId();
        NotificationMgt.DisableNotification(WarrantyNotification);
        OverdueNotification.Id := NotificationMgt.GetOverdueMaintenanceNotificationId();
        NotificationMgt.DisableNotification(OverdueNotification);
    end;
}
