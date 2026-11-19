namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using Microsoft.HumanResources.Employee;
using System.TestLibraries.Utilities;

codeunit 50159 "EQM Performance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        CategoryCodeTok: Label 'PERFCAT', Locked = true;
        EquipmentNoTok: Label 'PERF%1', Locked = true;
        EmployeeNoTok: Label 'PERFEMP%1', Locked = true;
        FirstNameTok: Label 'Perf', Locked = true;
        LastNameTok: Label 'Tester%1', Locked = true;
        ListTooSlowMsg: Label 'The equipment list took %1 ms; the budget is %2 ms.', Comment = '%1 = elapsed ms, %2 = budget ms';
        StatusViewTooSlowMsg: Label 'The status view took %1 ms; the budget is %2 ms.', Comment = '%1 = elapsed ms, %2 = budget ms';
        CuesTooSlowMsg: Label 'The dashboard cues took %1 ms; the budget is %2 ms.', Comment = '%1 = elapsed ms, %2 = budget ms';
        Counter: Integer;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentListOpensWithinBudget()
    var
        Employee: Record Employee;
        EquipmentList: TestPage "EQM Equipment List";
        CountByStatus: Dictionary of [Integer, Integer];
        NonFinalPurchaseCost: Decimal;
        StartTime: DateTime;
        Elapsed: Integer;
        Index: Integer;
        EmployeeName: Text;
        StatusText: Text;
    begin
        // [SCENARIO 1] The Equipment list opens within the 3-second budget with 10,000 records
        // [GIVEN] An employee and the dataset of equipment
        CreateEmployee(Employee);
        CreateDataset(GetDatasetSize(), Employee."No.", CountByStatus, NonFinalPurchaseCost);

        // [WHEN] The list is opened and the first rows are read
        StartTime := CurrentDateTime();
        EquipmentList.OpenView();
        EquipmentList.First();
        for Index := 1 to 50 do begin
            EmployeeName := EquipmentList."Assigned Employee Name".Value();
            StatusText := EquipmentList.Status.Value();
            if not EquipmentList.Next() then
                break;
        end;
        Elapsed := ElapsedMs(StartTime);
        EquipmentList.Close();

        // [THEN] The elapsed time is within the budget
        Assert.IsTrue(Elapsed < GetResponseBudgetMs(), StrSubstNo(ListTooSlowMsg, Elapsed, GetResponseBudgetMs()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusViewOpensWithinBudget()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        EquipmentList: TestPage "EQM Equipment List";
        CountByStatus: Dictionary of [Integer, Integer];
        NonFinalPurchaseCost: Decimal;
        StartTime: DateTime;
        Elapsed: Integer;
    begin
        // [SCENARIO 2] A status view on 10,000 records opens within budget and shows only that status
        // [GIVEN] The dataset of equipment
        CreateEmployee(Employee);
        CreateDataset(GetDatasetSize(), Employee."No.", CountByStatus, NonFinalPurchaseCost);

        // [WHEN] The list is opened with a filter on the status In Maintenance
        StartTime := CurrentDateTime();
        EquipmentList.OpenView();
        EquipmentList.Filter.SetFilter(Status, Format(Equipment.Status::"In Maintenance"));
        EquipmentList.First();
        Elapsed := ElapsedMs(StartTime);

        // [THEN] The elapsed time is within the budget and the first row has that status
        Assert.IsTrue(Elapsed < GetResponseBudgetMs(), StrSubstNo(StatusViewTooSlowMsg, Elapsed, GetResponseBudgetMs()));
        Assert.AreEqual(Format(Equipment.Status::"In Maintenance"), EquipmentList.Status.Value(), 'The first row should have the filtered status');
        EquipmentList.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DashboardTilesAreCorrectOnLargeDataset()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        EquipmentCue: Record "EQM Equipment Cue";
        ResultCue: Record "EQM Equipment Cue";
        CountByStatus: Dictionary of [Integer, Integer];
        NonFinalPurchaseCost: Decimal;
        BaselineTotal: Integer;
        BaselineAvailable: Integer;
        BaselineAssigned: Integer;
        BaselineInMaintenance: Integer;
        BaselineLost: Integer;
        BaselineDisposed: Integer;
        BaselineValue: Decimal;
    begin
        // [SCENARIO 3] Dashboard tiles are correct on 10,000 records
        // [GIVEN] The current values of the tiles and then the dataset
        GetCue(EquipmentCue);
        EquipmentCue.CalcFields("Total Equipment", "Available Equipment", "Assigned Equipment", "Equipment in Maintenance", "Lost Equipment", "Disposed Equipment", "Total Assets Value");
        BaselineTotal := EquipmentCue."Total Equipment";
        BaselineAvailable := EquipmentCue."Available Equipment";
        BaselineAssigned := EquipmentCue."Assigned Equipment";
        BaselineInMaintenance := EquipmentCue."Equipment in Maintenance";
        BaselineLost := EquipmentCue."Lost Equipment";
        BaselineDisposed := EquipmentCue."Disposed Equipment";
        BaselineValue := EquipmentCue."Total Assets Value";
        CreateEmployee(Employee);
        CreateDataset(GetDatasetSize(), Employee."No.", CountByStatus, NonFinalPurchaseCost);

        // [WHEN] The tiles are calculated on a fresh cue
        GetCue(ResultCue);
        ResultCue.CalcFields("Total Equipment", "Available Equipment", "Assigned Equipment", "Equipment in Maintenance", "Lost Equipment", "Disposed Equipment", "Total Assets Value");

        // [THEN] Each tile is the baseline plus the records created for it
        Assert.AreEqual(BaselineTotal + GetDatasetSize(), ResultCue."Total Equipment", 'Total equipment should include the dataset');
        Assert.AreEqual(BaselineAvailable + CountByStatus.Get(Equipment.Status::Available.AsInteger()), ResultCue."Available Equipment", 'Available equipment should include the dataset');
        Assert.AreEqual(BaselineAssigned + CountByStatus.Get(Equipment.Status::Assigned.AsInteger()), ResultCue."Assigned Equipment", 'Assigned equipment should include the dataset');
        Assert.AreEqual(BaselineInMaintenance + CountByStatus.Get(Equipment.Status::"In Maintenance".AsInteger()), ResultCue."Equipment in Maintenance", 'Equipment in maintenance should include the dataset');
        Assert.AreEqual(BaselineLost + CountByStatus.Get(Equipment.Status::Lost.AsInteger()), ResultCue."Lost Equipment", 'Lost equipment should include the dataset');
        Assert.AreEqual(BaselineDisposed + CountByStatus.Get(Equipment.Status::Disposed.AsInteger()), ResultCue."Disposed Equipment", 'Disposed equipment should include the dataset');
        Assert.AreEqual(BaselineValue + NonFinalPurchaseCost, ResultCue."Total Assets Value", 'Total assets value should include the purchase cost of the dataset');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DashboardCuePageOpensWithinBudget()
    var
        Employee: Record Employee;
        EquipmentCue: Record "EQM Equipment Cue";
        CuesPage: TestPage "EQM Equipment Cues";
        CountByStatus: Dictionary of [Integer, Integer];
        NonFinalPurchaseCost: Decimal;
        BaselineTotal: Integer;
        StartTime: DateTime;
        Elapsed: Integer;
        TotalEquipment: Integer;
        AssetsValue: Decimal;
        WarrantyExpiring: Integer;
        OverdueMaintenance: Integer;
    begin
        // [SCENARIO 4] The dashboard cue page opens within budget on 10,000 records
        // [GIVEN] The Role Center notifications are switched off, the current total and the dataset
        DisableRoleCenterNotifications();
        GetCue(EquipmentCue);
        EquipmentCue.CalcFields("Total Equipment");
        BaselineTotal := EquipmentCue."Total Equipment";
        CreateEmployee(Employee);
        CreateDataset(GetDatasetSize(), Employee."No.", CountByStatus, NonFinalPurchaseCost);

        // [WHEN] The cue page is opened and the tiles are read
        StartTime := CurrentDateTime();
        CuesPage.OpenView();
        TotalEquipment := CuesPage."Total Equipment".AsInteger();
        AssetsValue := CuesPage."Total Assets Value".AsDecimal();
        WarrantyExpiring := CuesPage."Warranty Expiring Soon".AsInteger();
        OverdueMaintenance := CuesPage."Overdue Maintenance Equipment".AsInteger();
        Elapsed := ElapsedMs(StartTime);
        CuesPage.Close();

        // [THEN] The elapsed time is within the budget and the total is correct
        Assert.IsTrue(Elapsed < GetResponseBudgetMs(), StrSubstNo(CuesTooSlowMsg, Elapsed, GetResponseBudgetMs()));
        Assert.AreEqual(BaselineTotal + GetDatasetSize(), TotalEquipment, 'The total equipment tile should include the dataset');
        Assert.IsTrue(AssetsValue >= NonFinalPurchaseCost, 'The total assets value tile should include the dataset');
        Assert.IsTrue(WarrantyExpiring >= 0, 'The warranty tile should be calculated');
        Assert.IsTrue(OverdueMaintenance >= 0, 'The overdue maintenance tile should be calculated');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StatusChartQueryReturnsCorrectCounts()
    var
        Employee: Record Employee;
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
        CountByStatus: Dictionary of [Integer, Integer];
        NonFinalPurchaseCost: Decimal;
        BaselineOrdinals: List of [Integer];
        BaselineCounts: List of [Integer];
        StatusOrdinals: List of [Integer];
        EquipmentCounts: List of [Integer];
        Index: Integer;
        Added: Integer;
    begin
        // [SCENARIO 5] The status chart query returns the right counts on 10,000 records
        // [GIVEN] The current counts per status and then the dataset
        DashboardMgt.GetEquipmentCountByStatus(BaselineOrdinals, BaselineCounts);
        CreateEmployee(Employee);
        CreateDataset(GetDatasetSize(), Employee."No.", CountByStatus, NonFinalPurchaseCost);

        // [WHEN] The counts are read again
        DashboardMgt.GetEquipmentCountByStatus(StatusOrdinals, EquipmentCounts);

        // [THEN] Each status count is the baseline plus the records created for it
        Assert.AreEqual(BaselineOrdinals.Count(), StatusOrdinals.Count(), 'The statuses should not change');
        for Index := 1 to StatusOrdinals.Count() do begin
            Added := 0;
            if CountByStatus.ContainsKey(StatusOrdinals.Get(Index)) then
                Added := CountByStatus.Get(StatusOrdinals.Get(Index));
            Assert.AreEqual(BaselineCounts.Get(Index) + Added, EquipmentCounts.Get(Index), 'The chart count should include the dataset');
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LostAndDisposedAreNotCountedInValueOrDateTiles()
    var
        Equipment: Record "EQM Equipment";
        EquipmentCue: Record "EQM Equipment Cue";
        ResultCue: Record "EQM Equipment Cue";
        BaselineValue: Decimal;
        BaselineExpiring: Integer;
        BaselineActive: Integer;
        BaselineOverdue: Integer;
        BaselineLost: Integer;
        BaselineDisposed: Integer;
        NoOfRecords: Integer;
        Index: Integer;
    begin
        // [SCENARIO 6] Lost and disposed equipment is not counted in the value, warranty or overdue tiles
        // [GIVEN] The current values of the tiles
        GetCue(EquipmentCue);
        EquipmentCue.CalcFields("Total Assets Value", "Warranty Expiring Soon", "Active Warranties", "Overdue Maintenance Equipment", "Lost Equipment", "Disposed Equipment");
        BaselineValue := EquipmentCue."Total Assets Value";
        BaselineExpiring := EquipmentCue."Warranty Expiring Soon";
        BaselineActive := EquipmentCue."Active Warranties";
        BaselineOverdue := EquipmentCue."Overdue Maintenance Equipment";
        BaselineLost := EquipmentCue."Lost Equipment";
        BaselineDisposed := EquipmentCue."Disposed Equipment";

        // [GIVEN] N lost and N disposed equipment with a purchase cost, a warranty ending tomorrow and overdue maintenance
        NoOfRecords := Random(5);
        for Index := 1 to NoOfRecords do begin
            InsertEquipment(Equipment.Status::Lost, '', Random(100000) / 100 + 1, Today() + 1, Today() - 1);
            InsertEquipment(Equipment.Status::Disposed, '', Random(100000) / 100 + 1, Today() + 1, Today() - 1);
        end;

        // [WHEN] The tiles are calculated
        GetCue(ResultCue);
        ResultCue.CalcFields("Total Assets Value", "Warranty Expiring Soon", "Active Warranties", "Overdue Maintenance Equipment", "Lost Equipment", "Disposed Equipment");

        // [THEN] The value, warranty and overdue tiles are unchanged and the lost and disposed tiles grow
        Assert.AreEqual(BaselineValue, ResultCue."Total Assets Value", 'Total assets value should not count lost or disposed equipment');
        Assert.AreEqual(BaselineExpiring, ResultCue."Warranty Expiring Soon", 'The expiring warranty tile should not count lost or disposed equipment');
        Assert.AreEqual(BaselineActive, ResultCue."Active Warranties", 'The active warranty tile should not count lost or disposed equipment');
        Assert.AreEqual(BaselineOverdue, ResultCue."Overdue Maintenance Equipment", 'The overdue tile should not count lost or disposed equipment');
        Assert.AreEqual(BaselineLost + NoOfRecords, ResultCue."Lost Equipment", 'The lost equipment tile should count the new records');
        Assert.AreEqual(BaselineDisposed + NoOfRecords, ResultCue."Disposed Equipment", 'The disposed equipment tile should count the new records');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListShowsEmployeeNameOnEveryRowOfSameEmployee()
    var
        Employee: Record Employee;
        Equipment: Record "EQM Equipment";
        FirstEquipment: Record "EQM Equipment";
        SecondEquipment: Record "EQM Equipment";
        EquipmentList: TestPage "EQM Equipment List";
    begin
        // [SCENARIO 7] The list shows the employee's full name on every row of the same employee
        // [GIVEN] An employee and two equipment records assigned to the employee
        CreateEmployee(Employee);
        FirstEquipment := InsertEquipment(Equipment.Status::Assigned, Employee."No.", Random(100000) / 100, 0D, 0D);
        SecondEquipment := InsertEquipment(Equipment.Status::Assigned, Employee."No.", Random(100000) / 100, 0D, 0D);

        // [WHEN] The list is opened and both rows are shown
        EquipmentList.OpenView();
        EquipmentList.GoToRecord(FirstEquipment);
        // [THEN] Both rows show the full name of the employee
        Assert.AreEqual(Employee.FullName(), EquipmentList."Assigned Employee Name".Value(), 'The first row should show the employee name');
        EquipmentList.GoToRecord(SecondEquipment);
        Assert.AreEqual(Employee.FullName(), EquipmentList."Assigned Employee Name".Value(), 'The second row should show the employee name');
        EquipmentList.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ListShowsBlankNameWithoutEmployee()
    var
        Equipment: Record "EQM Equipment";
        AvailableEquipment: Record "EQM Equipment";
        OrphanEquipment: Record "EQM Equipment";
        EquipmentList: TestPage "EQM Equipment List";
        MissingEmployeeNo: Code[20];
    begin
        // [SCENARIO 8] The list shows a blank name when there is no employee or the employee does not exist
        // [GIVEN] An available equipment without employee and an assigned equipment with an employee number that has no employee
        Counter += 1;
        MissingEmployeeNo := CopyStr(StrSubstNo(EmployeeNoTok, Counter), 1, MaxStrLen(MissingEmployeeNo));
        AvailableEquipment := InsertEquipment(Equipment.Status::Available, '', Random(100000) / 100, 0D, 0D);
        OrphanEquipment := InsertEquipment(Equipment.Status::Assigned, MissingEmployeeNo, Random(100000) / 100, 0D, 0D);

        // [WHEN] The list is opened on each record
        EquipmentList.OpenView();
        EquipmentList.GoToRecord(AvailableEquipment);
        // [THEN] The assigned employee name is blank on both
        Assert.AreEqual('', EquipmentList."Assigned Employee Name".Value(), 'The name should be blank without an employee');
        EquipmentList.GoToRecord(OrphanEquipment);
        Assert.AreEqual('', EquipmentList."Assigned Employee Name".Value(), 'The name should be blank when the employee does not exist');
        EquipmentList.Close();
    end;

    local procedure GetDatasetSize(): Integer
    begin
        // NFR-001 dataset size
        exit(10000);
    end;

    local procedure GetResponseBudgetMs(): Integer
    begin
        // NFR-001: the list must open in less than 3 seconds
        exit(3000);
    end;

    local procedure EnsureCategory()
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CategoryCodeTok;
        Category.Active := true;
        if not Category.Insert() then
            Category.Modify();
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    begin
        Counter += 1;
        Employee.Init();
        Employee."No." := CopyStr(StrSubstNo(EmployeeNoTok, Counter), 1, MaxStrLen(Employee."No."));
        Employee."First Name" := FirstNameTok;
        Employee."Last Name" := CopyStr(StrSubstNo(LastNameTok, Counter), 1, MaxStrLen(Employee."Last Name"));
        Employee.Insert(false);
    end;

    local procedure InsertEquipment(NewStatus: Enum "EQM Equipment Status"; EmployeeNo: Code[20]; PurchaseCost: Decimal; WarrantyEndDate: Date; NextMaintenanceDate: Date) Equipment: Record "EQM Equipment"
    begin
        // Insert without triggers on purpose: it builds the volume fast, as other tests set fields with Modify(false)
        EnsureCategory();
        Counter += 1;
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, Counter), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := 'Test equipment';
        Equipment."Category Code" := CategoryCodeTok;
        Equipment.Status := NewStatus;
        if NewStatus = NewStatus::Assigned then
            Equipment."Assigned Employee No." := EmployeeNo;
        Equipment."Purchase Cost" := PurchaseCost;
        Equipment."Warranty End Date" := WarrantyEndDate;
        Equipment."Next Maintenance Date" := NextMaintenanceDate;
        Equipment.Insert(false);
    end;

    local procedure CreateDataset(NoOfRecords: Integer; EmployeeNo: Code[20]; var CountByStatus: Dictionary of [Integer, Integer]; var NonFinalPurchaseCost: Decimal)
    var
        Equipment: Record "EQM Equipment";
        NewStatus: Enum "EQM Equipment Status";
        PurchaseCost: Decimal;
        Index: Integer;
        StatusOrdinal: Integer;
    begin
        // The status cycles through the five values by the index
        Clear(CountByStatus);
        NonFinalPurchaseCost := 0;
        for Index := 1 to NoOfRecords do begin
            StatusOrdinal := Index mod 5;
            NewStatus := Enum::"EQM Equipment Status".FromInteger(StatusOrdinal);
            PurchaseCost := Random(100000) / 100;
            Equipment := InsertEquipment(NewStatus, EmployeeNo, PurchaseCost, Today() - 200 + Random(400), Today() - 100 + Random(200));
            if CountByStatus.ContainsKey(StatusOrdinal) then
                CountByStatus.Set(StatusOrdinal, CountByStatus.Get(StatusOrdinal) + 1)
            else
                CountByStatus.Add(StatusOrdinal, 1);
            if not (NewStatus in [Equipment.Status::Lost, Equipment.Status::Disposed]) then
                NonFinalPurchaseCost += PurchaseCost;
        end;
    end;

    local procedure GetCue(var EquipmentCue: Record "EQM Equipment Cue")
    var
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
    begin
        EquipmentCue.Init();
        EquipmentCue.Insert();
        DashboardMgt.SetWarrantyCueFilters(EquipmentCue, Today());
        DashboardMgt.SetPlannedMaintenanceCueFilters(EquipmentCue, Today());
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

    local procedure ElapsedMs(StartTime: DateTime): Integer
    var
        Elapsed: Duration;
    begin
        Elapsed := CurrentDateTime() - StartTime;
        exit(Elapsed);
    end;
}
