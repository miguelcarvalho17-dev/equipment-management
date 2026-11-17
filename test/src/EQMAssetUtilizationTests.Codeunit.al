namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 50196 "EQM Asset Utilization Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
        Counter: Integer;
        EquipmentNoTok: Label 'UTEQ%1X', Locked = true;
        CategoryCodeTok: Label 'UTCAT%1', Locked = true;
        CategoryDescriptionTok: Label 'Utilization category %1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        UtilizationColumnTok: Label 'UtilizationPct', Locked = true;
        TotalColumnTok: Label 'TotalEquipment', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CountsPerStatusWithinFilter()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        AvailableQty: Integer;
        AssignedQty: Integer;
        MaintenanceQty: Integer;
        Total: Integer;
        Assigned: Integer;
        Available: Integer;
        InMaintenance: Integer;
    begin
        // [SCENARIO 1] Counts per status within the filter
        // [GIVEN] In C1: A Available, S Assigned and M In Maintenance equipment
        AvailableQty := Random(5);
        AssignedQty := Random(5);
        MaintenanceQty := Random(5);
        CategoryCode := CreateCategory();
        CreateEquipmentCount(CategoryCode, Equipment.Status::Available, AvailableQty);
        CreateEquipmentCount(CategoryCode, Equipment.Status::Assigned, AssignedQty);
        CreateEquipmentCount(CategoryCode, Equipment.Status::"In Maintenance", MaintenanceQty);

        // [WHEN] CalcAssetUtilization runs on a record filtered on Category Code = C1
        Equipment.SetRange("Category Code", CategoryCode);
        DashboardMgt.CalcAssetUtilization(Equipment, Total, Assigned, Available, InMaintenance);

        // [THEN] Total = A+S+M, Assigned = S, Available = A, In Maintenance = M
        Assert.AreEqual(AvailableQty + AssignedQty + MaintenanceQty, Total, 'Total');
        Assert.AreEqual(AssignedQty, Assigned, 'Assigned');
        Assert.AreEqual(AvailableQty, Available, 'Available');
        Assert.AreEqual(MaintenanceQty, InMaintenance, 'In Maintenance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LostAndDisposedAreNotCounted()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        Total: Integer;
        Assigned: Integer;
        Available: Integer;
        InMaintenance: Integer;
    begin
        // [SCENARIO 2] (negative) Lost and Disposed are not counted
        // [GIVEN] In C1: 1 Available, 1 Assigned, L Lost and D Disposed
        CategoryCode := CreateCategory();
        CreateEquipmentCount(CategoryCode, Equipment.Status::Available, 1);
        CreateEquipmentCount(CategoryCode, Equipment.Status::Assigned, 1);
        CreateEquipmentCount(CategoryCode, Equipment.Status::Lost, Random(5));
        CreateEquipmentCount(CategoryCode, Equipment.Status::Disposed, Random(5));

        // [WHEN] CalcAssetUtilization runs on a record filtered on Category Code = C1
        Equipment.SetRange("Category Code", CategoryCode);
        DashboardMgt.CalcAssetUtilization(Equipment, Total, Assigned, Available, InMaintenance);

        // [THEN] Total = 2, Assigned = 1, Available = 1, In Maintenance = 0
        Assert.AreEqual(2, Total, 'Total');
        Assert.AreEqual(1, Assigned, 'Assigned');
        Assert.AreEqual(1, Available, 'Available');
        Assert.AreEqual(0, InMaintenance, 'In Maintenance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentOutsideFilterIsNotCounted()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode1: Code[20];
        CategoryCode2: Code[20];
        Total: Integer;
        Assigned: Integer;
        Available: Integer;
        InMaintenance: Integer;
    begin
        // [SCENARIO 3] (negative) Equipment outside the filter is not counted
        // [GIVEN] 1 Assigned in C1, S Assigned in C2
        CategoryCode1 := CreateCategory();
        CategoryCode2 := CreateCategory();
        CreateEquipmentCount(CategoryCode1, Equipment.Status::Assigned, 1);
        CreateEquipmentCount(CategoryCode2, Equipment.Status::Assigned, Random(5));

        // [WHEN] CalcAssetUtilization runs with a filter on C1
        Equipment.SetRange("Category Code", CategoryCode1);
        DashboardMgt.CalcAssetUtilization(Equipment, Total, Assigned, Available, InMaintenance);

        // [THEN] Total = 1 and Assigned = 1
        Assert.AreEqual(1, Total, 'Total');
        Assert.AreEqual(1, Assigned, 'Assigned');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserStatusFilterCombinesWithRule()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        AssignedQty: Integer;
        Total: Integer;
        Assigned: Integer;
        Available: Integer;
        InMaintenance: Integer;
    begin
        // [SCENARIO 4] A user Status filter combines with the rule
        // [GIVEN] In C1: A Available and S Assigned
        AssignedQty := Random(5);
        CategoryCode := CreateCategory();
        CreateEquipmentCount(CategoryCode, Equipment.Status::Available, Random(5));
        CreateEquipmentCount(CategoryCode, Equipment.Status::Assigned, AssignedQty);

        // [WHEN] CalcAssetUtilization runs with filter C1 and Status = Assigned
        Equipment.SetRange("Category Code", CategoryCode);
        Equipment.SetRange(Status, Equipment.Status::Assigned);
        DashboardMgt.CalcAssetUtilization(Equipment, Total, Assigned, Available, InMaintenance);

        // [THEN] Total = S, Assigned = S, Available = 0, and CalcUtilizationPct gives 100
        Assert.AreEqual(AssignedQty, Total, 'Total');
        Assert.AreEqual(AssignedQty, Assigned, 'Assigned');
        Assert.AreEqual(0, Available, 'Available');
        Assert.AreEqual(100, DashboardMgt.CalcUtilizationPct(Assigned, Total), 'Utilization');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserFilterOnFinalStatusCountsNothing()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        Total: Integer;
        Assigned: Integer;
        Available: Integer;
        InMaintenance: Integer;
    begin
        // [SCENARIO 5] (negative) A user filter on a final status still counts nothing
        // [GIVEN] In C1: D Disposed
        CategoryCode := CreateCategory();
        CreateEquipmentCount(CategoryCode, Equipment.Status::Disposed, Random(5));

        // [WHEN] CalcAssetUtilization runs with filter C1 and Status = Disposed
        Equipment.SetRange("Category Code", CategoryCode);
        Equipment.SetRange(Status, Equipment.Status::Disposed);
        DashboardMgt.CalcAssetUtilization(Equipment, Total, Assigned, Available, InMaintenance);

        // [THEN] Total = 0 and Assigned = 0
        Assert.AreEqual(0, Total, 'Total');
        Assert.AreEqual(0, Assigned, 'Assigned');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CallerFiltersAreKept()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        FiltersBefore: Text;
        Total: Integer;
        Assigned: Integer;
        Available: Integer;
        InMaintenance: Integer;
    begin
        // [SCENARIO 6] The caller's filters are kept
        // [GIVEN] A record filtered on C1; store GetFilters()
        CategoryCode := CreateCategory();
        CreateEquipmentCount(CategoryCode, Equipment.Status::Available, Random(5));
        Equipment.SetRange("Category Code", CategoryCode);
        FiltersBefore := Equipment.GetFilters();

        // [WHEN] CalcAssetUtilization runs
        DashboardMgt.CalcAssetUtilization(Equipment, Total, Assigned, Available, InMaintenance);

        // [THEN] GetFilters() is unchanged, and FilterGroup() on the caller's record is still 0
        Assert.AreEqual(FiltersBefore, Equipment.GetFilters(), 'Filters should be unchanged');
        Assert.AreEqual(0, Equipment.FilterGroup(), 'Filter group should still be 0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UtilizationIsAssignedOverTotalRounded()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        AvailableQty: Integer;
        AssignedQty: Integer;
        Total: Integer;
        Assigned: Integer;
        Available: Integer;
        InMaintenance: Integer;
    begin
        // [SCENARIO 7] Utilization = Assigned / Total * 100, rounded to 0.01
        // [GIVEN] In C1: A Available and S Assigned
        AvailableQty := Random(9);
        AssignedQty := Random(9);
        CategoryCode := CreateCategory();
        CreateEquipmentCount(CategoryCode, Equipment.Status::Available, AvailableQty);
        CreateEquipmentCount(CategoryCode, Equipment.Status::Assigned, AssignedQty);

        // [WHEN] Calc runs on C1, then CalcUtilizationPct
        Equipment.SetRange("Category Code", CategoryCode);
        DashboardMgt.CalcAssetUtilization(Equipment, Total, Assigned, Available, InMaintenance);

        // [THEN] Result = Round(S * 100 / (A + S), 0.01)
        Assert.AreEqual(Round(AssignedQty * 100 / (AvailableQty + AssignedQty), 0.01), DashboardMgt.CalcUtilizationPct(Assigned, Total), 'Utilization');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoEquipmentGivesZeroPercent()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        Total: Integer;
        Assigned: Integer;
        Available: Integer;
        InMaintenance: Integer;
    begin
        // [SCENARIO 8] (failure path) No equipment gives 0 % without a division-by-zero error
        // [GIVEN] Empty category C1
        CategoryCode := CreateCategory();

        // [WHEN] Calc runs on C1, then CalcUtilizationPct
        Equipment.SetRange("Category Code", CategoryCode);
        DashboardMgt.CalcAssetUtilization(Equipment, Total, Assigned, Available, InMaintenance);

        // [THEN] Total = 0 and the percentage = 0
        Assert.AreEqual(0, Total, 'Total');
        Assert.AreEqual(0, DashboardMgt.CalcUtilizationPct(Assigned, Total), 'Utilization');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportEmitsSummaryColumns()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        Output: Text;
    begin
        // [SCENARIO 9] The report runs and emits the summary columns
        // [GIVEN] In C1: 1 Assigned and 1 Available
        CategoryCode := CreateCategory();
        CreateEquipmentCount(CategoryCode, Equipment.Status::Assigned, 1);
        CreateEquipmentCount(CategoryCode, Equipment.Status::Available, 1);

        // [WHEN] Report.SaveAs XML with filter C1
        Equipment.SetRange("Category Code", CategoryCode);
        Output := RunReport(Equipment);

        // [THEN] The output is not empty and contains the utilization and total columns
        Assert.AreNotEqual('', Output, 'The report output should not be empty');
        Assert.IsTrue(Output.Contains(UtilizationColumnTok), 'The utilization column should be in the output');
        Assert.IsTrue(Output.Contains(TotalColumnTok), 'The total column should be in the output');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportRunsWhenNoEquipmentMatches()
    var
        Equipment: Record "EQM Equipment";
        CategoryCode: Code[20];
        Output: Text;
    begin
        // [SCENARIO 10] (failure path) The report runs when no equipment matches
        // [GIVEN] Empty category C1
        CategoryCode := CreateCategory();

        // [WHEN] Report.SaveAs XML with filter C1
        Equipment.SetRange("Category Code", CategoryCode);
        Output := RunReport(Equipment);

        // [THEN] No error, and the output contains the total column
        Assert.IsTrue(Output.Contains(TotalColumnTok), 'The total column should be in the output');
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateCategory(): Code[20]
    var
        EquipmentCategory: Record "EQM Equipment Category";
        Id: Text;
    begin
        Id := NextId();
        EquipmentCategory.Init();
        EquipmentCategory.Code := CopyStr(StrSubstNo(CategoryCodeTok, Id), 1, MaxStrLen(EquipmentCategory.Code));
        EquipmentCategory.Description := CopyStr(StrSubstNo(CategoryDescriptionTok, EquipmentCategory.Code), 1, MaxStrLen(EquipmentCategory.Description));
        EquipmentCategory.Active := true;
        EquipmentCategory.Insert(false);
        exit(EquipmentCategory.Code);
    end;

    local procedure CreateEquipment(CategoryCode: Code[20]; NewStatus: Enum "EQM Equipment Status")
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := 'Utilization test equipment';
        Equipment."Category Code" := CategoryCode;
        Equipment.Insert(true);
        if NewStatus <> Equipment.Status::Available then begin
            // Set directly, without validation, to avoid dependency on the assignment flow
            Equipment.Get(Equipment."No.");
            Equipment.Status := NewStatus;
            Equipment.Modify(false);
        end;
    end;

    local procedure CreateEquipmentCount(CategoryCode: Code[20]; NewStatus: Enum "EQM Equipment Status"; Quantity: Integer)
    var
        i: Integer;
    begin
        for i := 1 to Quantity do
            CreateEquipment(CategoryCode, NewStatus);
    end;

    local procedure RunReport(var Equipment: Record "EQM Equipment"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: TextBuilder;
    begin
        RecRef.GetTable(Equipment);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        Report.SaveAs(Report::"EQM Asset Utilization", '', ReportFormat::Xml, OutStr, RecRef);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result.AppendLine(Line);
        end;
        exit(Result.ToText());
    end;
}
