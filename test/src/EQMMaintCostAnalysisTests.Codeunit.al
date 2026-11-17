namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 50197 "EQM Maint. Cost Analysis Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        DashboardMgt: Codeunit "EQM Dashboard Mgt.";
        Counter: Integer;
        EquipmentNoTok: Label 'MCEQ%1X', Locked = true;
        CategoryCodeTok: Label 'MCCAT%1', Locked = true;
        CategoryDescriptionTok: Label 'Maintenance cost category %1', Locked = true;
        EquipmentDescriptionTok: Label 'Maintenance cost test equipment', Locked = true;
        MaintenanceNoTok: Label 'MCMNT%1', Locked = true;
        MaintenanceRecordNoTok: Label 'MCMR%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        TotalCostColumnTok: Label 'TotalCost', Locked = true;
        CostMonthColumnTok: Label 'CostMonth', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SumsSameMonthAndSplitsOtherMonth()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        TempBuffer: Record "EQM Maint. Cost Buffer" temporary;
        C1: Code[20];
        E1: Code[20];
        Y: Integer;
        M: Integer;
        Day: Integer;
        X1: Decimal;
        X2: Decimal;
        X3: Decimal;
    begin
        // [SCENARIO 1] Entries of the same equipment and month are summed; another month gets its own row
        // [GIVEN] E1 in C1 with entries X1 and X2 in (Y, M), and X3 in (Y, M+6)
        Y := PastYear();
        M := Random(6);
        Day := Random(28);
        X1 := RandomCost();
        X2 := RandomCost();
        X3 := RandomCost();
        C1 := CreateCategory();
        E1 := CreateEquipment(C1);
        InsertHistoryEntry(E1, DMY2Date(Day, M, Y), X1, HistoryEntry."Maintenance Type"::Preventive);
        InsertHistoryEntry(E1, DMY2Date(Day, M, Y), X2, HistoryEntry."Maintenance Type"::Preventive);
        InsertHistoryEntry(E1, DMY2Date(Day, M + 6, Y), X3, HistoryEntry."Maintenance Type"::Preventive);

        // [WHEN] Build runs with Equipment filtered on C1 and HistoryEntry unfiltered
        Equipment.SetRange("Category Code", C1);
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);

        // [THEN] Buffer Count = 2
        Assert.AreEqual(2, TempBuffer.Count(), 'Rows');

        // [THEN] The (Y, M) row sums both entries and carries the descriptions and period start
        TempBuffer.Get(C1, E1, Y, M);
        Assert.AreEqual(X1 + X2, TempBuffer."Total Cost", 'Total (Y, M)');
        Assert.AreEqual(2, TempBuffer."No. of Maintenances", 'Count (Y, M)');
        Assert.AreEqual(DMY2Date(1, M, Y), TempBuffer."Period Start Date", 'Period start');
        Assert.AreEqual(StrSubstNo(CategoryDescriptionTok, C1), TempBuffer."Category Description", 'Category description');
        Assert.AreEqual(EquipmentDescriptionTok, TempBuffer."Equipment Description", 'Equipment description');

        // [THEN] The (Y, M+6) row has X3 and count 1
        TempBuffer.Get(C1, E1, Y, M + 6);
        Assert.AreEqual(X3, TempBuffer."Total Cost", 'Total (Y, M+6)');
        Assert.AreEqual(1, TempBuffer."No. of Maintenances", 'Count (Y, M+6)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SameMonthInTwoYearsGivesTwoRows()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        TempBuffer: Record "EQM Maint. Cost Buffer" temporary;
        C1: Code[20];
        E1: Code[20];
        Y: Integer;
        M: Integer;
        Day: Integer;
        X1: Decimal;
        X2: Decimal;
    begin
        // [SCENARIO 2] Year breakdown: the same month in two years gives two rows
        // [GIVEN] E1 in C1 with X1 in (Y-1, M) and X2 in (Y, M)
        Y := PastYear();
        M := Random(6);
        Day := Random(28);
        X1 := RandomCost();
        X2 := RandomCost();
        C1 := CreateCategory();
        E1 := CreateEquipment(C1);
        InsertHistoryEntry(E1, DMY2Date(Day, M, Y - 1), X1, HistoryEntry."Maintenance Type"::Preventive);
        InsertHistoryEntry(E1, DMY2Date(Day, M, Y), X2, HistoryEntry."Maintenance Type"::Preventive);

        // [WHEN] Build on C1
        Equipment.SetRange("Category Code", C1);
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);

        // [THEN] Two rows, one per year
        Assert.AreEqual(2, TempBuffer.Count(), 'Rows');
        TempBuffer.Get(C1, E1, Y - 1, M);
        Assert.AreEqual(X1, TempBuffer."Total Cost", 'Total previous year');
        TempBuffer.Get(C1, E1, Y, M);
        Assert.AreEqual(X2, TempBuffer."Total Cost", 'Total year');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CostIsSplitPerCategory()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        TempBuffer: Record "EQM Maint. Cost Buffer" temporary;
        C1: Code[20];
        C2: Code[20];
        E1: Code[20];
        E2: Code[20];
        Y: Integer;
        M: Integer;
        Day: Integer;
        X1: Decimal;
        X2: Decimal;
    begin
        // [SCENARIO 3] Category breakdown
        // [GIVEN] E1 in C1 with X1, and E2 in C2 with X2, same (Y, M)
        Y := PastYear();
        M := Random(12);
        Day := Random(28);
        X1 := RandomCost();
        X2 := RandomCost();
        C1 := CreateCategory();
        C2 := CreateCategory();
        E1 := CreateEquipment(C1);
        E2 := CreateEquipment(C2);
        InsertHistoryEntry(E1, DMY2Date(Day, M, Y), X1, HistoryEntry."Maintenance Type"::Preventive);
        InsertHistoryEntry(E2, DMY2Date(Day, M, Y), X2, HistoryEntry."Maintenance Type"::Preventive);

        // [WHEN] Build with Category Code filter C1|C2
        Equipment.SetFilter("Category Code", '%1|%2', C1, C2);
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);

        // [THEN] The cost per category is X1 and X2
        TempBuffer.SetRange("Category Code", C1);
        TempBuffer.CalcSums("Total Cost");
        Assert.AreEqual(X1, TempBuffer."Total Cost", 'Total C1');
        TempBuffer.SetRange("Category Code", C2);
        TempBuffer.CalcSums("Total Cost");
        Assert.AreEqual(X2, TempBuffer."Total Cost", 'Total C2');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentOutsideFilterIsNotIncluded()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        TempBuffer: Record "EQM Maint. Cost Buffer" temporary;
        C1: Code[20];
        C2: Code[20];
        E1: Code[20];
        E2: Code[20];
        Day: Integer;
    begin
        // [SCENARIO 4] (negative) Equipment outside the equipment filter is not included
        // [GIVEN] E1 in C1 with X1, and E2 in C2 with X2
        Day := Random(28);
        C1 := CreateCategory();
        C2 := CreateCategory();
        E1 := CreateEquipment(C1);
        E2 := CreateEquipment(C2);
        InsertHistoryEntry(E1, DMY2Date(Day, 1, PastYear()), RandomCost(), HistoryEntry."Maintenance Type"::Preventive);
        InsertHistoryEntry(E2, DMY2Date(Day, 1, PastYear()), RandomCost(), HistoryEntry."Maintenance Type"::Preventive);

        // [WHEN] Build with filter C1
        Equipment.SetRange("Category Code", C1);
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);

        // [THEN] E2 is not in the buffer, and only one row exists
        TempBuffer.SetRange("Equipment No.", E2);
        Assert.IsTrue(TempBuffer.IsEmpty(), 'Equipment outside the filter should not be included');
        TempBuffer.Reset();
        Assert.AreEqual(1, TempBuffer.Count(), 'Rows');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenanceDateFilterExcludesOtherEntries()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        TempBuffer: Record "EQM Maint. Cost Buffer" temporary;
        C1: Code[20];
        E1: Code[20];
        Y: Integer;
        M: Integer;
        Day: Integer;
        X1: Decimal;
        X2: Decimal;
    begin
        // [SCENARIO 5] (negative) Maintenance Date filter excludes entries outside the range
        // [GIVEN] E1 in C1 with X1 in (Y, M) and X2 in (Y, M+6)
        Y := PastYear();
        M := Random(6);
        Day := Random(28);
        X1 := RandomCost();
        X2 := RandomCost();
        C1 := CreateCategory();
        E1 := CreateEquipment(C1);
        InsertHistoryEntry(E1, DMY2Date(Day, M, Y), X1, HistoryEntry."Maintenance Type"::Preventive);
        InsertHistoryEntry(E1, DMY2Date(Day, M + 6, Y), X2, HistoryEntry."Maintenance Type"::Preventive);

        // [WHEN] Build with a Maintenance Date filter on month M
        Equipment.SetRange("Category Code", C1);
        HistoryEntry.SetRange("Maintenance Date", DMY2Date(1, M, Y), CalcDate('<CM>', DMY2Date(1, M, Y)));
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);

        // [THEN] Only the (Y, M) row exists
        Assert.AreEqual(1, TempBuffer.Count(), 'Rows');
        TempBuffer.Get(C1, E1, Y, M);
        Assert.AreEqual(X1, TempBuffer."Total Cost", 'Total');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenanceTypeFilterExcludesOtherTypes()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        TempBuffer: Record "EQM Maint. Cost Buffer" temporary;
        C1: Code[20];
        E1: Code[20];
        Y: Integer;
        M: Integer;
        Day: Integer;
        X2: Decimal;
    begin
        // [SCENARIO 6] (negative) Maintenance Type filter
        // [GIVEN] E1 in C1 with a Preventive X1 and a Corrective X2 in (Y, M)
        Y := PastYear();
        M := Random(12);
        Day := Random(28);
        X2 := RandomCost();
        C1 := CreateCategory();
        E1 := CreateEquipment(C1);
        InsertHistoryEntry(E1, DMY2Date(Day, M, Y), RandomCost(), HistoryEntry."Maintenance Type"::Preventive);
        InsertHistoryEntry(E1, DMY2Date(Day, M, Y), X2, HistoryEntry."Maintenance Type"::Corrective);

        // [WHEN] Build with HistoryEntry filtered on Corrective
        Equipment.SetRange("Category Code", C1);
        HistoryEntry.SetRange("Maintenance Type", HistoryEntry."Maintenance Type"::Corrective);
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);

        // [THEN] Total = X2, count 1
        TempBuffer.Get(C1, E1, Y, M);
        Assert.AreEqual(X2, TempBuffer."Total Cost", 'Total');
        Assert.AreEqual(1, TempBuffer."No. of Maintenances", 'Count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenMaintenanceRecordsAreNotIncluded()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        TempBuffer: Record "EQM Maint. Cost Buffer" temporary;
        C1: Code[20];
        E1: Code[20];
    begin
        // [SCENARIO 7] (negative) Open maintenance records are not included
        // [GIVEN] E1 in C1 with only an open maintenance record
        C1 := CreateCategory();
        E1 := CreateEquipment(C1);
        InsertOpenMaintenanceRecord(E1, DMY2Date(Random(28), 1, PastYear()), RandomCost());

        // [WHEN] Build on C1
        Equipment.SetRange("Category Code", C1);
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);

        // [THEN] The buffer is empty
        Assert.IsTrue(TempBuffer.IsEmpty(), 'Open maintenance should not be included');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoPostedMaintenanceGivesEmptyBuffer()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        TempBuffer: Record "EQM Maint. Cost Buffer" temporary;
        C1: Code[20];
        C2: Code[20];
    begin
        // [SCENARIO 8] (failure path) No posted maintenance gives an empty buffer and no error
        // [GIVEN] E1 in C1 with no entries, and an empty category C2
        C1 := CreateCategory();
        C2 := CreateCategory();
        CreateEquipment(C1);

        // [WHEN] Build on C1, then on C2
        Equipment.SetRange("Category Code", C1);
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);

        // [THEN] The buffer is empty
        Assert.IsTrue(TempBuffer.IsEmpty(), 'Buffer should be empty for equipment without entries');
        Equipment.SetRange("Category Code", C2);
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);
        Assert.IsTrue(TempBuffer.IsEmpty(), 'Buffer should be empty for a category without equipment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ZeroCostEntriesAreCounted()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        TempBuffer: Record "EQM Maint. Cost Buffer" temporary;
        C1: Code[20];
        E1: Code[20];
        Y: Integer;
        M: Integer;
        Day: Integer;
        X1: Decimal;
    begin
        // [SCENARIO 9] Zero-cost entries are counted
        // [GIVEN] E1 in C1 with one entry of cost 0 and one of X1 in (Y, M)
        Y := PastYear();
        M := Random(12);
        Day := Random(28);
        X1 := RandomCost();
        C1 := CreateCategory();
        E1 := CreateEquipment(C1);
        InsertHistoryEntry(E1, DMY2Date(Day, M, Y), 0, HistoryEntry."Maintenance Type"::Preventive);
        InsertHistoryEntry(E1, DMY2Date(Day, M, Y), X1, HistoryEntry."Maintenance Type"::Preventive);

        // [WHEN] Build on C1
        Equipment.SetRange("Category Code", C1);
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);

        // [THEN] Total = X1, count = 2
        TempBuffer.Get(C1, E1, Y, M);
        Assert.AreEqual(X1, TempBuffer."Total Cost", 'Total');
        Assert.AreEqual(2, TempBuffer."No. of Maintenances", 'Count');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CallerFiltersAreKeptAndRebuildDoesNotDuplicate()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        TempBuffer: Record "EQM Maint. Cost Buffer" temporary;
        C1: Code[20];
        E1: Code[20];
        Y: Integer;
        M: Integer;
        X1: Decimal;
        EquipmentFilters: Text;
        HistoryFilters: Text;
    begin
        // [SCENARIO 10] Caller filters are kept and a rebuild does not duplicate
        // [GIVEN] E1 in C1 with X1. Equipment is filtered on C1 and HistoryEntry on Maintenance Type
        Y := PastYear();
        M := Random(12);
        X1 := RandomCost();
        C1 := CreateCategory();
        E1 := CreateEquipment(C1);
        InsertHistoryEntry(E1, DMY2Date(Random(28), M, Y), X1, HistoryEntry."Maintenance Type"::Preventive);
        Equipment.SetRange("Category Code", C1);
        HistoryEntry.SetRange("Maintenance Type", HistoryEntry."Maintenance Type"::Preventive);
        EquipmentFilters := Equipment.GetFilters();
        HistoryFilters := HistoryEntry.GetFilters();

        // [WHEN] Build runs twice on the same buffer
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);
        DashboardMgt.BuildMaintenanceCostBuffer(Equipment, HistoryEntry, TempBuffer);

        // [THEN] Count = 1 and Total = X1
        Assert.AreEqual(1, TempBuffer.Count(), 'Rows');
        TempBuffer.Get(C1, E1, Y, M);
        Assert.AreEqual(X1, TempBuffer."Total Cost", 'Total');

        // [THEN] Both filters are unchanged, and the filter group is 0
        Assert.AreEqual(EquipmentFilters, Equipment.GetFilters(), 'Equipment filters');
        Assert.AreEqual(HistoryFilters, HistoryEntry.GetFilters(), 'History entry filters');
        Assert.AreEqual(0, Equipment.FilterGroup(), 'Equipment filter group');
        Assert.AreEqual(0, HistoryEntry.FilterGroup(), 'History entry filter group');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportEmitsBreakdownColumns()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        C1: Code[20];
        E1: Code[20];
        Output: Text;
    begin
        // [SCENARIO 11] The report emits the breakdown columns for matching equipment
        // [GIVEN] E1 in C1 with X1
        C1 := CreateCategory();
        E1 := CreateEquipment(C1);
        InsertHistoryEntry(E1, DMY2Date(Random(28), Random(12), PastYear()), RandomCost(), HistoryEntry."Maintenance Type"::Preventive);

        // [WHEN] The report is saved as XML with Equipment filtered on C1
        Equipment.SetRange("Category Code", C1);
        Output := RunReport(Equipment);

        // [THEN] The output is not empty and contains the cost columns and E1
        Assert.AreNotEqual('', Output, 'The report output should not be empty');
        Assert.IsTrue(Output.Contains(TotalCostColumnTok), 'The total cost column should be in the output');
        Assert.IsTrue(Output.Contains(CostMonthColumnTok), 'The cost month column should be in the output');
        Assert.IsTrue(Output.Contains(E1), 'The equipment should be in the output');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportLeavesOutOtherCategories()
    var
        Equipment: Record "EQM Equipment";
        HistoryEntry: Record "EQM Maintenance History Entry";
        C1: Code[20];
        C2: Code[20];
        E1: Code[20];
        E2: Code[20];
        Output: Text;
    begin
        // [SCENARIO 12] (negative) The report leaves out equipment of other categories
        // [GIVEN] E1 in C1 with X1, and E2 in C2 with X2
        C1 := CreateCategory();
        C2 := CreateCategory();
        E1 := CreateEquipment(C1);
        E2 := CreateEquipment(C2);
        InsertHistoryEntry(E1, DMY2Date(Random(28), Random(12), PastYear()), RandomCost(), HistoryEntry."Maintenance Type"::Preventive);
        InsertHistoryEntry(E2, DMY2Date(Random(28), Random(12), PastYear()), RandomCost(), HistoryEntry."Maintenance Type"::Preventive);

        // [WHEN] The report is saved as XML with the filter C1
        Equipment.SetRange("Category Code", C1);
        Output := RunReport(Equipment);

        // [THEN] The output contains E1 and does not contain E2
        Assert.IsTrue(Output.Contains(E1), 'The equipment in the filter should be in the output');
        Assert.IsFalse(Output.Contains(E2), 'Equipment of another category should not be in the output');
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure CreateCategory(): Code[20]
    var
        EquipmentCategory: Record "EQM Equipment Category";
    begin
        EquipmentCategory.Init();
        EquipmentCategory.Code := CopyStr(StrSubstNo(CategoryCodeTok, NextId()), 1, MaxStrLen(EquipmentCategory.Code));
        EquipmentCategory.Description := CopyStr(StrSubstNo(CategoryDescriptionTok, EquipmentCategory.Code), 1, MaxStrLen(EquipmentCategory.Description));
        EquipmentCategory.Active := true;
        EquipmentCategory.Insert(false);
        exit(EquipmentCategory.Code);
    end;

    local procedure CreateEquipment(CategoryCode: Code[20]): Code[20]
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := EquipmentDescriptionTok;
        Equipment."Category Code" := CategoryCode;
        Equipment.Insert(true);
        exit(Equipment."No.");
    end;

    local procedure InsertHistoryEntry(EquipmentNo: Code[20]; MaintenanceDate: Date; Cost: Decimal; MaintenanceType: Enum "EQM Maintenance Type")
    var
        HistoryEntry: Record "EQM Maintenance History Entry";
    begin
        // Inserted directly, without triggers, to avoid dependency on the posting flow
        HistoryEntry.Init();
        HistoryEntry."Maintenance No." := CopyStr(StrSubstNo(MaintenanceNoTok, NextId()), 1, MaxStrLen(HistoryEntry."Maintenance No."));
        HistoryEntry."Equipment No." := EquipmentNo;
        HistoryEntry."Maintenance Date" := MaintenanceDate;
        HistoryEntry."Maintenance Type" := MaintenanceType;
        HistoryEntry.Cost := Cost;
        HistoryEntry.Insert(false);
    end;

    local procedure InsertOpenMaintenanceRecord(EquipmentNo: Code[20]; MaintenanceDate: Date; Cost: Decimal)
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        MaintenanceRecord.Init();
        MaintenanceRecord."No." := CopyStr(StrSubstNo(MaintenanceRecordNoTok, NextId()), 1, MaxStrLen(MaintenanceRecord."No."));
        MaintenanceRecord."Equipment No." := EquipmentNo;
        MaintenanceRecord."Maintenance Date" := MaintenanceDate;
        MaintenanceRecord.Cost := Cost;
        MaintenanceRecord.Status := MaintenanceRecord.Status::Open;
        MaintenanceRecord.Insert(false);
    end;

    local procedure RandomCost(): Decimal
    begin
        exit(Random(100000) / 100);
    end;

    local procedure PastYear(): Integer
    begin
        exit(Date2DMY(WorkDate(), 3) - 1);
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
        Report.SaveAs(Report::"EQM Maint. Cost Analysis", '', ReportFormat::Xml, OutStr, RecRef);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result.AppendLine(Line);
        end;
        exit(Result.ToText());
    end;
}
