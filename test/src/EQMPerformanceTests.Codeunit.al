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
        CategoryTwoCodeTok: Label 'PERFCAT2', Locked = true;
        AssignmentsTooSlowMsg: Label 'The assignment list took %1 ms; the budget is %2 ms.', Comment = '%1 = elapsed ms, %2 = budget ms';
        UtilizationTooSlowMsg: Label 'The asset utilization calculation took %1 ms; the budget is %2 ms.', Comment = '%1 = elapsed ms, %2 = budget ms';
        AlertJobTooSlowMsg: Label 'The warranty alert job took %1 ms; the budget is %2 ms.', Comment = '%1 = elapsed ms, %2 = budget ms';
        KeyMissingMsg: Label 'The key on table %1 with first field %2 is missing or not active.', Comment = '%1 = table number, %2 = first field number';
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

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignmentListOpensWithinBudgetOnLargeHistory()
    var
        Employee: Record Employee;
        AssignmentList: TestPage "EQM Equipment Assignments";
        StartTime: DateTime;
        Elapsed: Integer;
        Index: Integer;
        EmployeeNames: List of [Text];
        EmployeeName: Text;
    begin
        // [SCENARIO L1] The assignment list opens within budget on a large history and shows the employee name on every row
        // [GIVEN] An employee and a large number of closed assignment entries
        CreateEmployee(Employee);
        InsertAssignments(GetAssignmentDatasetSize(), Employee."No.");

        // [WHEN] The list is opened and the first rows are read
        StartTime := CurrentDateTime();
        AssignmentList.OpenView();
        AssignmentList.First();
        for Index := 1 to 50 do begin
            EmployeeNames.Add(Format(AssignmentList."Employee Name".Value()));
            if not AssignmentList.Next() then
                break;
        end;
        Elapsed := ElapsedMs(StartTime);
        AssignmentList.Close();

        // [THEN] The elapsed time is within the budget and every row shows the employee name
        Assert.IsTrue(Elapsed < GetResponseBudgetMs(), StrSubstNo(AssignmentsTooSlowMsg, Elapsed, GetResponseBudgetMs()));
        foreach EmployeeName in EmployeeNames do
            Assert.AreEqual(Employee.FullName(), EmployeeName, 'Every row should show the employee name');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignmentListShowsBlankNameForMissingEmployee()
    var
        Employee: Record Employee;
        MissingEmployeeAssignment: Record "EQM Equipment Assignment";
        EmployeeAssignment: Record "EQM Equipment Assignment";
        AssignmentList: TestPage "EQM Equipment Assignments";
        MissingEmployeeNo: Code[20];
    begin
        // [SCENARIO L2] The assignment list shows a blank name for a missing employee and still shows the real name after it
        // [GIVEN] An entry for an employee number that has no employee and an entry for an existing employee
        CreateEmployee(Employee);
        Counter += 1;
        MissingEmployeeNo := CopyStr(StrSubstNo(EmployeeNoTok, Counter), 1, MaxStrLen(MissingEmployeeNo));
        MissingEmployeeAssignment := InsertAssignment(MissingEmployeeNo);
        EmployeeAssignment := InsertAssignment(Employee."No.");

        // [WHEN] The list is opened on each entry
        AssignmentList.OpenView();
        AssignmentList.GoToRecord(MissingEmployeeAssignment);
        // [THEN] The missing employee has a blank name and the existing employee has the full name
        Assert.AreEqual('', Format(AssignmentList."Employee Name".Value()), 'The name should be blank when the employee does not exist');
        AssignmentList.GoToRecord(EmployeeAssignment);
        Assert.AreEqual(Employee.FullName(), Format(AssignmentList."Employee Name".Value()), 'The employee name should still be shown');
        AssignmentList.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeltaFilterOnSystemModifiedAtReturnsOnlyNewerEntries()
    var
        Employee: Record Employee;
        Assignment: Record "EQM Equipment Assignment";
        FirstEntryNo: Integer;
        LastBatchAEntryNo: Integer;
        LastEntryNo: Integer;
        BatchASize: Integer;
        BatchBSize: Integer;
        Boundary: DateTime;
        Index: Integer;
    begin
        // [SCENARIO D1] A delta filter on SystemModifiedAt returns only the entries changed after the boundary
        // [GIVEN] A first batch of entries, a boundary after the last of them, and a second batch
        CreateEmployee(Employee);
        BatchASize := Random(20) + 5;
        BatchBSize := Random(20) + 5;
        Assignment := InsertAssignment(Employee."No.");
        FirstEntryNo := Assignment."Entry No.";
        for Index := 2 to BatchASize do
            Assignment := InsertAssignment(Employee."No.");
        LastBatchAEntryNo := Assignment."Entry No.";
        Assignment.SetRange("Entry No.", FirstEntryNo, LastBatchAEntryNo);
        Boundary := 0DT;
        Assignment.FindSet();
        repeat
            if Assignment.SystemModifiedAt > Boundary then
                Boundary := Assignment.SystemModifiedAt;
        until Assignment.Next() = 0;
        Sleep(100);
        for Index := 1 to BatchBSize do
            Assignment := InsertAssignment(Employee."No.");
        LastEntryNo := Assignment."Entry No.";

        // [WHEN] The entries are filtered on SystemModifiedAt
        Assignment.Reset();
        Assignment.SetRange("Entry No.", FirstEntryNo, LastEntryNo);
        Assignment.SetFilter(SystemModifiedAt, '>%1', Boundary);

        // [THEN] Only the second batch is returned, and the first batch is returned by the opposite filter
        Assert.AreEqual(BatchBSize, Assignment.Count(), 'Only the entries after the boundary should be returned');
        Assignment.SetFilter(SystemModifiedAt, '<=%1', Boundary);
        Assert.AreEqual(BatchASize, Assignment.Count(), 'Only the entries up to the boundary should be returned');
    end;

    [Test]
    procedure Fr053KeysExistAndAreActive()
    var
        Equipment: Record "EQM Equipment";
        Assignment: Record "EQM Equipment Assignment";
        CategoryStatusFields: List of [Integer];
        EquipmentModifiedFields: List of [Integer];
        AssignmentModifiedFields: List of [Integer];
    begin
        // [SCENARIO K1] The FR-053 keys exist and are active
        // [GIVEN] The field numbers of each key
        CategoryStatusFields.Add(Equipment.FieldNo("Category Code"));
        CategoryStatusFields.Add(Equipment.FieldNo(Status));
        EquipmentModifiedFields.Add(Equipment.FieldNo(SystemModifiedAt));
        AssignmentModifiedFields.Add(Assignment.FieldNo(SystemModifiedAt));

        // [WHEN] [THEN] Each key is found among the active keys of its table
        Assert.IsTrue(HasActiveKey(Database::"EQM Equipment", CategoryStatusFields), StrSubstNo(KeyMissingMsg, Database::"EQM Equipment", CategoryStatusFields.Get(1)));
        Assert.IsTrue(HasActiveKey(Database::"EQM Equipment", EquipmentModifiedFields), StrSubstNo(KeyMissingMsg, Database::"EQM Equipment", EquipmentModifiedFields.Get(1)));
        Assert.IsTrue(HasActiveKey(Database::"EQM Equipment Assignment", AssignmentModifiedFields), StrSubstNo(KeyMissingMsg, Database::"EQM Equipment Assignment", AssignmentModifiedFields.Get(1)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssetUtilizationForOneCategoryIsCorrectAndWithinBudget()
    var
        Equipment: Record "EQM Equipment";
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
        ExpectedByStatus: Dictionary of [Integer, Integer];
        NewStatus: Enum "EQM Equipment Status";
        StartTime: DateTime;
        Elapsed: Integer;
        Index: Integer;
        StatusOrdinal: Integer;
        ExpectedTotal: Integer;
        TotalEquipment: Integer;
        AssignedEquipment: Integer;
        AvailableEquipment: Integer;
        InMaintenanceEquipment: Integer;
    begin
        // [SCENARIO C1] Asset utilization counts for one category are correct and within budget
        // [GIVEN] A large dataset of equipment in the second category with the status cycling by the index
        for Index := 1 to GetDatasetSize() do begin
            StatusOrdinal := Index mod 5;
            NewStatus := Enum::"EQM Equipment Status".FromInteger(StatusOrdinal);
            InsertEquipmentInCategory(CategoryTwoCodeTok, NewStatus);
            if ExpectedByStatus.ContainsKey(StatusOrdinal) then
                ExpectedByStatus.Set(StatusOrdinal, ExpectedByStatus.Get(StatusOrdinal) + 1)
            else
                ExpectedByStatus.Add(StatusOrdinal, 1);
            if not Equipment.IsFinalStatus(NewStatus) then
                ExpectedTotal += 1;
        end;

        // [WHEN] The utilization is calculated for the category
        Equipment.SetRange("Category Code", CategoryTwoCodeTok);
        StartTime := CurrentDateTime();
        DashboardMgt.CalcAssetUtilization(Equipment, TotalEquipment, AssignedEquipment, AvailableEquipment, InMaintenanceEquipment);
        Elapsed := ElapsedMs(StartTime);

        // [THEN] The counts match the dataset and the elapsed time is within the budget
        Assert.IsTrue(Elapsed < GetResponseBudgetMs(), StrSubstNo(UtilizationTooSlowMsg, Elapsed, GetResponseBudgetMs()));
        Assert.AreEqual(ExpectedTotal, TotalEquipment, 'Total should count the equipment that is not lost or disposed');
        Assert.AreEqual(ExpectedByStatus.Get(Equipment.Status::Assigned.AsInteger()), AssignedEquipment, 'Assigned count should match');
        Assert.AreEqual(ExpectedByStatus.Get(Equipment.Status::Available.AsInteger()), AvailableEquipment, 'Available count should match');
        Assert.AreEqual(ExpectedByStatus.Get(Equipment.Status::"In Maintenance".AsInteger()), InMaintenanceEquipment, 'In maintenance count should match');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssetUtilizationDoesNotCountOtherCategory()
    var
        Equipment: Record "EQM Equipment";
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
        AvailableInCategoryTwo: Integer;
        AssignedInOtherCategory: Integer;
        Index: Integer;
        TotalEquipment: Integer;
        AssignedEquipment: Integer;
        AvailableEquipment: Integer;
        InMaintenanceEquipment: Integer;
    begin
        // [SCENARIO C2] Equipment of another category is not counted
        // [GIVEN] Available equipment in the second category and assigned equipment in the first category
        AvailableInCategoryTwo := Random(10) + 5;
        AssignedInOtherCategory := Random(10) + 5;
        for Index := 1 to AvailableInCategoryTwo do
            InsertEquipmentInCategory(CategoryTwoCodeTok, Equipment.Status::Available);
        for Index := 1 to AssignedInOtherCategory do
            InsertEquipmentInCategory(CategoryCodeTok, Equipment.Status::Assigned);

        // [WHEN] The utilization is calculated for the second category
        Equipment.SetRange("Category Code", CategoryTwoCodeTok);
        DashboardMgt.CalcAssetUtilization(Equipment, TotalEquipment, AssignedEquipment, AvailableEquipment, InMaintenanceEquipment);

        // [THEN] Only the equipment of the second category is counted
        Assert.AreEqual(0, AssignedEquipment, 'Assigned equipment of another category should not be counted');
        Assert.AreEqual(AvailableInCategoryTwo, TotalEquipment, 'Total should be the equipment of the category');
        Assert.AreEqual(AvailableInCategoryTwo, AvailableEquipment, 'Available should be the equipment of the category');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaleAlertOfDeletedEquipmentIsCancelled()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        WarrantyEndDate: Date;
    begin
        // [SCENARIO S1] An open alert of deleted equipment is cancelled
        // [GIVEN] An open alert whose equipment was deleted
        WarrantyEndDate := GetFarWarrantyEndDate();
        Equipment := InsertEquipment(Equipment.Status::Available, '', 0, WarrantyEndDate, 0D);
        WarrantyAlert := InsertAlert(Equipment."No.", WarrantyEndDate, WarrantyAlert.Status::Open);
        Equipment.Delete(false);

        // [WHEN] The alerts are generated
        RunAlertJob();

        // [THEN] The alert is cancelled with a cancellation time
        WarrantyAlert.Get(WarrantyAlert."Entry No.");
        Assert.AreEqual(WarrantyAlert.Status::Cancelled, WarrantyAlert.Status, 'The alert should be cancelled');
        Assert.AreNotEqual(0DT, WarrantyAlert."Cancelled At", 'The cancellation time should be set');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaleAlertOfLostEquipmentIsCancelled()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        WarrantyEndDate: Date;
    begin
        // [SCENARIO S2] An open alert of lost equipment is cancelled
        // [GIVEN] An open alert whose equipment is lost
        WarrantyEndDate := GetFarWarrantyEndDate();
        Equipment := InsertEquipment(Equipment.Status::Lost, '', 0, WarrantyEndDate, 0D);
        WarrantyAlert := InsertAlert(Equipment."No.", WarrantyEndDate, WarrantyAlert.Status::Open);

        // [WHEN] The alerts are generated
        RunAlertJob();

        // [THEN] The alert is cancelled
        WarrantyAlert.Get(WarrantyAlert."Entry No.");
        Assert.AreEqual(WarrantyAlert.Status::Cancelled, WarrantyAlert.Status, 'The alert of lost equipment should be cancelled');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MatchingAlertStaysOpen()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        WarrantyEndDate: Date;
    begin
        // [SCENARIO S3] An open alert that matches its equipment stays open
        // [GIVEN] An open alert with the same warranty end date as its available equipment
        WarrantyEndDate := GetFarWarrantyEndDate();
        Equipment := InsertEquipment(Equipment.Status::Available, '', 0, WarrantyEndDate, 0D);
        WarrantyAlert := InsertAlert(Equipment."No.", WarrantyEndDate, WarrantyAlert.Status::Open);

        // [WHEN] The alerts are generated
        RunAlertJob();

        // [THEN] The alert is still open
        WarrantyAlert.Get(WarrantyAlert."Entry No.");
        Assert.AreEqual(WarrantyAlert.Status::Open, WarrantyAlert.Status, 'The matching alert should stay open');
        Assert.IsTrue(WarrantyAlertMgt.HasOpenAlert(Equipment."No.", WarrantyEndDate), 'The equipment should still have an open alert');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AcknowledgedAlertOfDeletedEquipmentIsUntouched()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        WarrantyEndDate: Date;
    begin
        // [SCENARIO S4] An acknowledged alert of deleted equipment is not changed
        // [GIVEN] An acknowledged alert whose equipment was deleted
        WarrantyEndDate := GetFarWarrantyEndDate();
        Equipment := InsertEquipment(Equipment.Status::Available, '', 0, WarrantyEndDate, 0D);
        WarrantyAlert := InsertAlert(Equipment."No.", WarrantyEndDate, WarrantyAlert.Status::Acknowledged);
        Equipment.Delete(false);

        // [WHEN] The alerts are generated
        RunAlertJob();

        // [THEN] The alert is still acknowledged and was not cancelled
        WarrantyAlert.Get(WarrantyAlert."Entry No.");
        Assert.AreEqual(WarrantyAlert.Status::Acknowledged, WarrantyAlert.Status, 'The acknowledged alert should not change');
        Assert.AreEqual(0DT, WarrantyAlert."Cancelled At", 'The acknowledged alert should not get a cancellation time');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StaleAlertCancellationIsCorrectAndWithinBudget()
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlert: Record "EQM Warranty Alert";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        StaleEntryNos: List of [Integer];
        ValidEntryNos: List of [Integer];
        EntryNo: Integer;
        Index: Integer;
        CreatedCount: Integer;
        CancelledCount: Integer;
        WarrantyEndDate: Date;
        StartTime: DateTime;
        Elapsed: Integer;
    begin
        // [SCENARIO S5] Stale alert cancellation is correct and within budget on a large number of alerts
        // [GIVEN] Open alerts where every even one is stale (alert date differs from the equipment) and every odd one is valid
        for Index := 1 to GetAlertDatasetSize() do begin
            WarrantyEndDate := GetFarWarrantyEndDate();
            Equipment := InsertEquipment(Equipment.Status::Available, '', 0, WarrantyEndDate, 0D);
            if Index mod 2 = 0 then begin
                WarrantyAlert := InsertAlert(Equipment."No.", WarrantyEndDate + 1, WarrantyAlert.Status::Open);
                StaleEntryNos.Add(WarrantyAlert."Entry No.");
            end else begin
                WarrantyAlert := InsertAlert(Equipment."No.", WarrantyEndDate, WarrantyAlert.Status::Open);
                ValidEntryNos.Add(WarrantyAlert."Entry No.");
            end;
        end;

        // [WHEN] The alerts are generated
        StartTime := CurrentDateTime();
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);
        Elapsed := ElapsedMs(StartTime);

        // [THEN] The stale alerts are cancelled, the valid ones stay open, and the elapsed time is within the budget
        Assert.IsTrue(Elapsed < GetResponseBudgetMs(), StrSubstNo(AlertJobTooSlowMsg, Elapsed, GetResponseBudgetMs()));
        Assert.IsTrue(CancelledCount >= StaleEntryNos.Count(), 'At least the stale alerts should be cancelled');
        foreach EntryNo in StaleEntryNos do begin
            WarrantyAlert.Get(EntryNo);
            Assert.AreEqual(WarrantyAlert.Status::Cancelled, WarrantyAlert.Status, 'A stale alert should be cancelled');
        end;
        foreach EntryNo in ValidEntryNos do begin
            WarrantyAlert.Get(EntryNo);
            Assert.AreEqual(WarrantyAlert.Status::Open, WarrantyAlert.Status, 'A valid alert should stay open');
        end;
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

    local procedure GetAssignmentDatasetSize(): Integer
    begin
        // FR-053: CI-sized sample of the 1,000,000 assignment records the app is built for
        exit(20000);
    end;

    local procedure GetAlertDatasetSize(): Integer
    begin
        // FR-053: even, so that half of the alerts are stale
        exit(1000);
    end;

    local procedure GetFarWarrantyEndDate(): Date
    begin
        // Beyond the 90-day alert window, so the alert job creates no alert for it
        exit(Today() + 200 + Random(100));
    end;

    local procedure EnsureCategoryCode(CategoryCode: Code[20])
    var
        Category: Record "EQM Equipment Category";
    begin
        Category.Init();
        Category.Code := CategoryCode;
        Category.Active := true;
        if not Category.Insert() then
            Category.Modify();
    end;

    local procedure InsertEquipmentInCategory(CategoryCode: Code[20]; NewStatus: Enum "EQM Equipment Status") Equipment: Record "EQM Equipment"
    begin
        // Insert without triggers on purpose: it builds the volume fast
        EnsureCategoryCode(CategoryCode);
        Counter += 1;
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, Counter), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := 'Test equipment';
        Equipment."Category Code" := CategoryCode;
        Equipment.Status := NewStatus;
        Equipment.Insert(false);
    end;

    local procedure InsertAssignment(EmployeeNo: Code[20]) Assignment: Record "EQM Equipment Assignment"
    begin
        // Insert without triggers on purpose: the table has no insert trigger and this builds the volume fast
        Assignment.Init();
        Assignment."Equipment No." := CopyStr(StrSubstNo(EquipmentNoTok, 0), 1, MaxStrLen(Assignment."Equipment No."));
        Assignment."Employee No." := EmployeeNo;
        Assignment."Assignment Date" := Today() - 1;
        Assignment.Status := Assignment.Status::Closed;
        Assignment."Closing Date" := Today();
        Assignment.Insert(false);
    end;

    local procedure InsertAssignments(NoOfRecords: Integer; EmployeeNo: Code[20])
    var
        Index: Integer;
    begin
        for Index := 1 to NoOfRecords do
            InsertAssignment(EmployeeNo);
    end;

    local procedure InsertAlert(EquipmentNo: Code[20]; WarrantyEndDate: Date; AlertStatus: Enum "EQM Warranty Alert Status") WarrantyAlert: Record "EQM Warranty Alert"
    begin
        WarrantyAlert.Init();
        WarrantyAlert."Equipment No." := EquipmentNo;
        WarrantyAlert."Warranty End Date" := WarrantyEndDate;
        WarrantyAlert."Alert Date" := Today();
        WarrantyAlert.Status := AlertStatus;
        WarrantyAlert.Insert(false);
    end;

    local procedure RunAlertJob()
    var
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        CreatedCount: Integer;
        CancelledCount: Integer;
    begin
        WarrantyAlertMgt.GenerateAlerts(Today(), false, CreatedCount, CancelledCount);
    end;

    local procedure HasActiveKey(TableNo: Integer; FieldNos: List of [Integer]): Boolean
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
        KeyIndex: Integer;
        FieldIndex: Integer;
        Matches: Boolean;
    begin
        RecRef.Open(TableNo);
        for KeyIndex := 1 to RecRef.KeyCount() do begin
            KeyRef := RecRef.KeyIndex(KeyIndex);
            if KeyRef.Active() and (KeyRef.FieldCount() = FieldNos.Count()) then begin
                Matches := true;
                for FieldIndex := 1 to KeyRef.FieldCount() do
                    if KeyRef.FieldIndex(FieldIndex).Number() <> FieldNos.Get(FieldIndex) then
                        Matches := false;
                if Matches then
                    exit(true);
            end;
        end;
        exit(false);
    end;

    local procedure ElapsedMs(StartTime: DateTime): Integer
    var
        Elapsed: Duration;
    begin
        Elapsed := CurrentDateTime() - StartTime;
        exit(Elapsed);
    end;
}
