namespace MiguelCarvalho.EquipmentManagement.Tests;

using MiguelCarvalho.EquipmentManagement;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 50169 "EQM Usage Analytics Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        UsageAnalyticsMgt: Codeunit "EQM Usage Analytics Mgt.";
        Counter: Integer;
        EquipmentNoTok: Label 'UAEQ%1X', Locked = true;
        CategoryCodeTok: Label 'UACAT%1', Locked = true;
        CategoryDescriptionTok: Label 'Usage analytics category %1', Locked = true;
        EquipmentDescriptionTok: Label 'Usage analytics test equipment', Locked = true;
        MaintenanceNoTok: Label 'UAMNT%1', Locked = true;
        MaintenanceRecordNoTok: Label 'UAMR%1', Locked = true;
        UserIdTok: Label 'UAUSER%1', Locked = true;
        CounterFormatTok: Label '<Integer,4><Filler Character,0>', Locked = true;
        StartOfMonthFormulaTok: Label '<-CM>', Locked = true;
        EndOfMonthFormulaTok: Label '<CM>', Locked = true;
        DefaultStartFormulaTok: Label '<-CM-11M>', Locked = true;
        PreviousMonthEndFormulaTok: Label '<-CM-1D>', Locked = true;
        TwoMonthsBackFormulaTok: Label '<-CM-2M>', Locked = true;
        ReversedFragmentTok: Label 'is after the ending date', Locked = true;
        MissingFragmentTok: Label 'Enter both a starting date and an ending date', Locked = true;
        TooLongFragmentTok: Label 'covers %1 months', Locked = true;
        WithoutCategoryTxt: Label 'Without category';
        ActiveUsersColumnTok: Label 'ActiveUsersCount', Locked = true;
        CategoryRankColumnTok: Label 'CategoryRank', Locked = true;
        TrendStartColumnTok: Label 'TrendPeriodStart', Locked = true;
        GrowthStartColumnTok: Label 'GrowthPeriodStart', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DefaultPeriodIsTwelveMonthsUpToReferenceDate()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        ReferenceDate: Date;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 1] The default period is the 12 calendar months up to the reference date
        // [GIVEN] A reference date R
        ReferenceDate := DMY2Date(Random(28), Random(12), 2000 + Random(20));

        // [WHEN] The default period is requested and trends are built for it
        UsageAnalyticsMgt.GetDefaultPeriod(ReferenceDate, StartingDate, EndingDate);
        UsageAnalyticsMgt.BuildMaintenanceTrends(TempBuffer, StartingDate, EndingDate);

        // [THEN] The end is R, the start is the first day of the month 11 months before R, and there are 12 rows
        Assert.AreEqual(ReferenceDate, EndingDate, 'Ending date');
        Assert.AreEqual(CalcDate(DefaultStartFormulaTok, ReferenceDate), StartingDate, 'Starting date');
        Assert.AreEqual(12, TempBuffer.Count(), 'Number of month rows');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StartingDateAfterEndingDateIsRejected()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        StartingDate: Date;
    begin
        // [SCENARIO 2] (negative) A starting date after the ending date is rejected
        // [GIVEN] A starting date that is one day after the ending date
        StartingDate := DMY2Date(Random(28), Random(12), 2000 + Random(20));

        // [WHEN] Trends are built
        asserterror UsageAnalyticsMgt.BuildMaintenanceTrends(TempBuffer, StartingDate + 1, StartingDate);

        // [THEN] The reversed period error is raised
        Assert.ExpectedError(ReversedFragmentTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankDateIsRejected()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
    begin
        // [SCENARIO 3] (negative) A blank date is rejected
        // [GIVEN] A blank starting date
        // [WHEN] Categories are built
        asserterror UsageAnalyticsMgt.BuildMostAssignedCategories(TempBuffer, 0D, Today());

        // [THEN] The error asks for both dates
        Assert.ExpectedError(MissingFragmentTok);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PeriodOfMoreThan120MonthsIsRejected()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 4] (negative, boundary) A period of 121 calendar months is rejected
        // [GIVEN] A period of 121 months
        StartingDate := DMY2Date(1, 1, 1990 + Random(10));
        EndingDate := CalcDate('<CM+120M>', StartingDate);

        // [WHEN] Active users are built
        asserterror UsageAnalyticsMgt.BuildActiveUsers(TempBuffer, StartingDate, EndingDate);

        // [THEN] The period length error names 121 months and the limit
        Assert.ExpectedError(StrSubstNo(TooLongFragmentTok, UsageAnalyticsMgt.GetMaxPeriodMonths() + 1));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PeriodOf120MonthsIsAccepted()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [SCENARIO 5] (boundary) A period of exactly 120 calendar months is accepted
        // [GIVEN] A period from S to E that covers 120 months
        StartingDate := DMY2Date(Random(28), Random(12), 1990 + Random(10));
        EndingDate := CalcDate('<CM+119M>', StartingDate);

        // [WHEN] Equipment growth is built
        UsageAnalyticsMgt.BuildEquipmentGrowth(TempBuffer, StartingDate, EndingDate);

        // [THEN] There are 120 rows, the first starts on S and the last ends on E
        Assert.AreEqual(UsageAnalyticsMgt.GetMaxPeriodMonths(), TempBuffer.Count(), 'Number of month rows');
        TempBuffer.FindFirst();
        Assert.AreEqual(StartingDate, TempBuffer."Period Start Date", 'First row start');
        TempBuffer.FindLast();
        Assert.AreEqual(EndingDate, TempBuffer."Period End Date", 'Last row end');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CategoriesAreRankedByAssignmentsInPeriod()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        C1: Code[20];
        C2: Code[20];
        E1: Code[20];
        E2: Code[20];
        Year: Integer;
        Total: Integer;
        FirstRank: Integer;
        SecondRank: Integer;
    begin
        // [SCENARIO 6] Categories are ranked by number of assignments, with share and description
        // [GIVEN] C1 with 3 assignments and C2 with 1 assignment in the period
        Year := PastYear();
        C1 := CreateCategory();
        C2 := CreateCategory();
        E1 := CreateEquipment(C1);
        E2 := CreateEquipment(C2);
        InsertAssignment(E1, DMY2Date(Random(28), 2, Year));
        InsertAssignment(E1, DMY2Date(Random(28), 5, Year));
        InsertAssignment(E1, DMY2Date(Random(28), 8, Year));
        InsertAssignment(E2, DMY2Date(Random(28), 9, Year));

        // [WHEN] The categories are built for the year
        UsageAnalyticsMgt.BuildMostAssignedCategories(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));

        // [THEN] C1 has 3 and C2 has 1, C1 ranks before C2, and the share and description are filled
        TempBuffer.FindSet();
        repeat
            Total += TempBuffer."No. of Assignments";
        until TempBuffer.Next() = 0;

        TempBuffer.SetRange("Category Code", C1);
        TempBuffer.FindFirst();
        FirstRank := TempBuffer.Rank;
        Assert.AreEqual(3, TempBuffer."No. of Assignments", 'C1 assignments');
        Assert.AreEqual(Round(3 * 100 / Total, 0.01), TempBuffer."Assignment Share %", 'C1 share');
        Assert.AreEqual(StrSubstNo(CategoryDescriptionTok, C1), TempBuffer."Category Description", 'C1 description');

        TempBuffer.SetRange("Category Code", C2);
        TempBuffer.FindFirst();
        SecondRank := TempBuffer.Rank;
        Assert.AreEqual(1, TempBuffer."No. of Assignments", 'C2 assignments');
        Assert.IsTrue(FirstRank < SecondRank, 'C1 should rank before C2');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignmentsOutsidePeriodAreNotCounted()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        C1: Code[20];
        E1: Code[20];
        Year: Integer;
    begin
        // [SCENARIO 7] (negative) Assignments the day before and the day after the period are not counted
        // [GIVEN] C1 with an assignment on 31 December of the year before and one on 1 January of the year after
        Year := PastYear();
        C1 := CreateCategory();
        E1 := CreateEquipment(C1);
        InsertAssignment(E1, DMY2Date(31, 12, Year - 1));
        InsertAssignment(E1, DMY2Date(1, 1, Year + 1));

        // [WHEN] The categories are built for the year
        UsageAnalyticsMgt.BuildMostAssignedCategories(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));

        // [THEN] C1 has no row
        TempBuffer.SetRange("Category Code", C1);
        Assert.IsTrue(TempBuffer.IsEmpty(), 'Assignments outside the period should not be counted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AssignmentOfUnknownEquipmentCountsWithoutCategory()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        C1: Code[20];
        E0: Code[20];
        Year: Integer;
        Before: Integer;
        BlankRank: Integer;
        C1Rank: Integer;
    begin
        // [SCENARIO 8] Assignments of unknown equipment and of equipment without category are merged into one row without category, ranked by count
        // [GIVEN] The count of the row without category before, equipment E0 without category with an assignment, C1 with one assignment
        Year := PastYear();
        UsageAnalyticsMgt.BuildMostAssignedCategories(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));
        TempBuffer.SetRange("Category Code", '');
        if TempBuffer.FindFirst() then
            Before := TempBuffer."No. of Assignments";
        E0 := CreateEquipmentWithoutCategory();
        InsertAssignment(E0, DMY2Date(Random(28), 4, Year));
        C1 := CreateCategory();
        InsertAssignment(CreateEquipment(C1), DMY2Date(Random(28), 5, Year));

        // [WHEN] An assignment of unknown equipment is added and the categories are rebuilt
        InsertAssignment(CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, 20), DMY2Date(Random(28), 3, Year));
        UsageAnalyticsMgt.BuildMostAssignedCategories(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));

        // [THEN] One row without category has two more assignments and the description "Without category", and it ranks before C1 (2 before 1)
        TempBuffer.SetRange("Category Code", '');
        TempBuffer.FindFirst();
        BlankRank := TempBuffer.Rank;
        Assert.AreEqual(Before + 2, TempBuffer."No. of Assignments", 'Assignments without category');
        Assert.AreEqual(WithoutCategoryTxt, TempBuffer."Category Description", 'Description');
        Assert.AreEqual(1, TempBuffer.Count(), 'There is only one row without category');
        TempBuffer.SetRange("Category Code", C1);
        TempBuffer.FindFirst();
        C1Rank := TempBuffer.Rank;
        Assert.IsTrue(BlankRank < C1Rank, 'Without category (2) ranks before C1 (1)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MonthlyCountAndCostOfPostedMaintenance()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        E1: Code[20];
        Year: Integer;
        Month: Integer;
        CountBefore: Integer;
        CostBefore: Decimal;
        OtherMonthCountBefore: Integer;
        X1: Decimal;
        X2: Decimal;
        X3: Decimal;
    begin
        // [SCENARIO 9] Posted maintenance is counted and summed per month
        // [GIVEN] Entries X1 and X2 in month M and X3 in month M+1, and the figures before them
        Year := PastYear();
        Month := Random(10);
        X1 := RandomCost();
        X2 := RandomCost();
        X3 := RandomCost();
        E1 := CreateEquipment(CreateCategory());
        UsageAnalyticsMgt.BuildMaintenanceTrends(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));
        TempBuffer.Get(Month);
        CountBefore := TempBuffer."No. of Maintenances";
        CostBefore := TempBuffer."Maintenance Cost";
        TempBuffer.Get(Month + 1);
        OtherMonthCountBefore := TempBuffer."No. of Maintenances";
        InsertHistoryEntry(E1, DMY2Date(Random(28), Month, Year), X1);
        InsertHistoryEntry(E1, DMY2Date(Random(28), Month, Year), X2);
        InsertHistoryEntry(E1, DMY2Date(Random(28), Month + 1, Year), X3);

        // [WHEN] The trends are built for the year
        UsageAnalyticsMgt.BuildMaintenanceTrends(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));

        // [THEN] Month M has two more entries and X1 + X2 more cost, month M+1 has one more entry
        Assert.AreEqual(12, TempBuffer.Count(), 'Number of month rows');
        TempBuffer.Get(Month);
        Assert.AreEqual(CountBefore + 2, TempBuffer."No. of Maintenances", 'Count in month M');
        Assert.AreEqual(CostBefore + X1 + X2, TempBuffer."Maintenance Cost", 'Cost in month M');
        TempBuffer.Get(Month + 1);
        Assert.AreEqual(OtherMonthCountBefore + 1, TempBuffer."No. of Maintenances", 'Count in month M+1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OpenMaintenanceAndEntriesOutsidePeriodAreNotCounted()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        TotalBefore: Integer;
        TotalAfter: Integer;
        E1: Code[20];
        Year: Integer;
    begin
        // [SCENARIO 10] (negative) Open maintenance records and entries outside the period are not counted
        // [GIVEN] An open record in the period, and posted entries the day before and the day after the period
        Year := PastYear();
        E1 := CreateEquipment(CreateCategory());
        TotalBefore := CountMaintenances(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));
        InsertOpenMaintenanceRecord(E1, DMY2Date(Random(28), 6, Year), RandomCost());
        InsertHistoryEntry(E1, DMY2Date(31, 12, Year - 1), RandomCost());
        InsertHistoryEntry(E1, DMY2Date(1, 1, Year + 1), RandomCost());

        // [WHEN] The trends are built for the year
        TotalAfter := CountMaintenances(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));

        // [THEN] The total did not change
        Assert.AreEqual(TotalBefore, TotalAfter, 'Total number of maintenances');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FirstAndLastMonthAreCutToPeriod()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        StartingDate: Date;
        EndingDate: Date;
        Year: Integer;
    begin
        // [SCENARIO 11] (boundary) The first and last month are cut to the period
        // [GIVEN] A period from 15 January to 10 March
        Year := PastYear();
        StartingDate := DMY2Date(15, 1, Year);
        EndingDate := DMY2Date(10, 3, Year);

        // [WHEN] The trends are built
        UsageAnalyticsMgt.BuildMaintenanceTrends(TempBuffer, StartingDate, EndingDate);

        // [THEN] There are three rows: 15 January to 31 January, the whole of February, and 1 March to 10 March
        Assert.AreEqual(3, TempBuffer.Count(), 'Number of month rows');
        TempBuffer.Get(1);
        Assert.AreEqual(StartingDate, TempBuffer."Period Start Date", 'First start');
        Assert.AreEqual(DMY2Date(31, 1, Year), TempBuffer."Period End Date", 'First end');
        TempBuffer.Get(2);
        Assert.AreEqual(DMY2Date(1, 2, Year), TempBuffer."Period Start Date", 'Second start');
        Assert.AreEqual(CalcDate(EndOfMonthFormulaTok, DMY2Date(1, 2, Year)), TempBuffer."Period End Date", 'Second end');
        TempBuffer.Get(3);
        Assert.AreEqual(DMY2Date(1, 3, Year), TempBuffer."Period Start Date", 'Last start');
        Assert.AreEqual(EndingDate, TempBuffer."Period End Date", 'Last end');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NewEquipmentCountsInCreationMonthAndInTotal()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        NewBefore: Integer;
        TotalBefore: Integer;
    begin
        // [SCENARIO 12] New equipment counts in the month it is created and in the total
        // [GIVEN] The figures of the current month before the equipment is created
        UsageAnalyticsMgt.BuildEquipmentGrowth(TempBuffer, CalcDate(StartOfMonthFormulaTok, Today()), Today());
        TempBuffer.FindLast();
        NewBefore := TempBuffer."New Equipment";
        TotalBefore := TempBuffer."Total Equipment";

        // [WHEN] One equipment is created and the growth is rebuilt
        CreateEquipment(CreateCategory());
        UsageAnalyticsMgt.BuildEquipmentGrowth(TempBuffer, CalcDate(StartOfMonthFormulaTok, Today()), Today());

        // [THEN] New equipment and total are both one higher
        TempBuffer.FindLast();
        Assert.AreEqual(NewBefore + 1, TempBuffer."New Equipment", 'New equipment');
        Assert.AreEqual(TotalBefore + 1, TempBuffer."Total Equipment", 'Total equipment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EquipmentCreatedAfterPeriodIsNotCounted()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        StartingDate: Date;
        EndingDate: Date;
        NewBefore: Integer;
        TotalBefore: Integer;
    begin
        // [SCENARIO 13] (negative) Equipment created after the period is not counted
        // [GIVEN] A period of two months that ended before the current month, and its figures
        StartingDate := CalcDate(TwoMonthsBackFormulaTok, Today());
        EndingDate := CalcDate(PreviousMonthEndFormulaTok, Today());
        UsageAnalyticsMgt.BuildEquipmentGrowth(TempBuffer, StartingDate, EndingDate);
        TempBuffer.FindLast();
        NewBefore := TempBuffer."New Equipment";
        TotalBefore := TempBuffer."Total Equipment";

        // [WHEN] One equipment is created now and the growth is rebuilt
        CreateEquipment(CreateCategory());
        UsageAnalyticsMgt.BuildEquipmentGrowth(TempBuffer, StartingDate, EndingDate);

        // [THEN] The last month of the period shows the same figures
        TempBuffer.FindLast();
        Assert.AreEqual(NewBefore, TempBuffer."New Equipment", 'New equipment');
        Assert.AreEqual(TotalBefore, TempBuffer."Total Equipment", 'Total equipment');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DistinctUsersArePerMonth()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        E1: Code[20];
        U1: Code[50];
        U2: Code[50];
        Year: Integer;
        Month: Integer;
        MonthBefore: Integer;
        NextMonthBefore: Integer;
    begin
        // [SCENARIO 14] A user counts once per month, whether found in the audit trail, in posted maintenance or both
        // [GIVEN] U1 with two audit entries and one posted maintenance in month M, U2 with one audit entry in month M, and U1 in month M+1
        Year := PastYear();
        Month := Random(10);
        U1 := CopyStr(StrSubstNo(UserIdTok, NextId()), 1, MaxStrLen(U1));
        U2 := CopyStr(StrSubstNo(UserIdTok, NextId()), 1, MaxStrLen(U2));
        E1 := CreateEquipment(CreateCategory());
        UsageAnalyticsMgt.BuildActiveUsers(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));
        TempBuffer.Get(Month);
        MonthBefore := TempBuffer."Active Users";
        TempBuffer.Get(Month + 1);
        NextMonthBefore := TempBuffer."Active Users";
        InsertAuditEntry(E1, U1, CreateDateTime(DMY2Date(Random(28), Month, Year), 090000T));
        InsertAuditEntry(E1, U1, CreateDateTime(DMY2Date(Random(28), Month, Year), 150000T));
        InsertAuditEntry(E1, U2, CreateDateTime(DMY2Date(Random(28), Month, Year), 100000T));
        InsertHistoryEntryPostedBy(E1, U1, CreateDateTime(DMY2Date(Random(28), Month, Year), 110000T));
        InsertAuditEntry(E1, U1, CreateDateTime(DMY2Date(Random(28), Month + 1, Year), 090000T));

        // [WHEN] The active users are built for the year
        UsageAnalyticsMgt.BuildActiveUsers(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));

        // [THEN] Month M has two more users and month M+1 has one more
        TempBuffer.Get(Month);
        Assert.AreEqual(MonthBefore + 2, TempBuffer."Active Users", 'Active users in month M');
        TempBuffer.Get(Month + 1);
        Assert.AreEqual(NextMonthBefore + 1, TempBuffer."Active Users", 'Active users in month M+1');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BlankUserAndActivityOutsidePeriodAreNotCounted()
    var
        TempBuffer: Record "EQM Usage Analytics Buffer" temporary;
        E1: Code[20];
        U1: Code[50];
        Year: Integer;
        TotalBefore: Integer;
        TotalAfter: Integer;
    begin
        // [SCENARIO 15] (negative) Entries without a user and activity outside the period are not counted
        // [GIVEN] An audit entry without a user in the period, and entries of U1 the day before and the day after the period
        Year := PastYear();
        U1 := CopyStr(StrSubstNo(UserIdTok, NextId()), 1, MaxStrLen(U1));
        E1 := CreateEquipment(CreateCategory());
        TotalBefore := CountActiveUsers(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));
        InsertAuditEntry(E1, '', CreateDateTime(DMY2Date(Random(28), 6, Year), 100000T));
        InsertAuditEntry(E1, U1, CreateDateTime(DMY2Date(31, 12, Year - 1), 120000T));
        InsertHistoryEntryPostedBy(E1, U1, CreateDateTime(DMY2Date(1, 1, Year + 1), 120000T));

        // [WHEN] The active users are built for the year
        TotalAfter := CountActiveUsers(TempBuffer, DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));

        // [THEN] The total did not change
        Assert.AreEqual(TotalBefore, TotalAfter, 'Total of active users');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportContainsAllFourMetrics()
    var
        UsageAnalytics: Report "EQM Usage Analytics";
        C1: Code[20];
        E1: Code[20];
        Year: Integer;
        Output: Text;
    begin
        // [SCENARIO 16] The report output contains the columns of all four metrics and the category with assignments
        // [GIVEN] C1 with an assignment in the period
        Year := PastYear();
        C1 := CreateCategory();
        E1 := CreateEquipment(C1);
        InsertAssignment(E1, DMY2Date(Random(28), Random(12), Year));

        // [WHEN] The report is saved as XML for the year
        UsageAnalytics.SetPeriod(DMY2Date(1, 1, Year), DMY2Date(31, 12, Year));
        Output := RunReport(UsageAnalytics);

        // [THEN] The output contains the column of each metric and C1
        Assert.IsTrue(Output.Contains(CategoryRankColumnTok), 'Most assigned categories column');
        Assert.IsTrue(Output.Contains(TrendStartColumnTok), 'Maintenance trends column');
        Assert.IsTrue(Output.Contains(GrowthStartColumnTok), 'Equipment growth column');
        Assert.IsTrue(Output.Contains(ActiveUsersColumnTok), 'Active users column');
        Assert.IsTrue(Output.Contains(C1), 'The category should be in the output');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportWithReversedPeriodFails()
    var
        UsageAnalytics: Report "EQM Usage Analytics";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Year: Integer;
    begin
        // [SCENARIO 17] (negative) The report fails when the starting date is after the ending date
        // [GIVEN] A period whose starting date is after its ending date
        Year := PastYear();
        UsageAnalytics.SetPeriod(DMY2Date(31, 12, Year), DMY2Date(1, 1, Year));
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);

        // [WHEN] The report is saved as XML
        asserterror UsageAnalytics.SaveAs('', ReportFormat::Xml, OutStr);

        // [THEN] The reversed period error is raised
        Assert.ExpectedError(ReversedFragmentTok);
    end;

    local procedure NextId(): Text
    begin
        Counter += 1;
        exit(Format(Counter, 0, CounterFormatTok));
    end;

    local procedure PastYear(): Integer
    begin
        // A year far in the past, so that other data does not mix with the test data
        exit(1990 + Random(10));
    end;

    local procedure RandomCost(): Decimal
    begin
        exit(Random(100000) / 100);
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

    local procedure CreateEquipmentWithoutCategory(): Code[20]
    var
        Equipment: Record "EQM Equipment";
    begin
        // Inserted directly, without triggers: the equipment table requires a category, but equipment saved before that rule (or imported) can have none
        Equipment.Init();
        Equipment."No." := CopyStr(StrSubstNo(EquipmentNoTok, NextId()), 1, MaxStrLen(Equipment."No."));
        Equipment.Description := EquipmentDescriptionTok;
        Equipment.Insert(false);
        exit(Equipment."No.");
    end;

    local procedure InsertAssignment(EquipmentNo: Code[20]; AssignmentDate: Date)
    var
        Assignment: Record "EQM Equipment Assignment";
    begin
        // Inserted directly, without triggers, to avoid dependency on the assignment flow
        Assignment.Init();
        Assignment."Equipment No." := EquipmentNo;
        Assignment."Assignment Date" := AssignmentDate;
        Assignment.Insert(false);
    end;

    local procedure InsertHistoryEntry(EquipmentNo: Code[20]; MaintenanceDate: Date; Cost: Decimal)
    var
        HistoryEntry: Record "EQM Maintenance History Entry";
    begin
        // Inserted directly, without triggers, to avoid dependency on the posting flow
        HistoryEntry.Init();
        HistoryEntry."Maintenance No." := CopyStr(StrSubstNo(MaintenanceNoTok, NextId()), 1, MaxStrLen(HistoryEntry."Maintenance No."));
        HistoryEntry."Equipment No." := EquipmentNo;
        HistoryEntry."Maintenance Date" := MaintenanceDate;
        HistoryEntry.Cost := Cost;
        HistoryEntry.Insert(false);
    end;

    local procedure InsertHistoryEntryPostedBy(EquipmentNo: Code[20]; PostedBy: Code[50]; PostedAt: DateTime)
    var
        HistoryEntry: Record "EQM Maintenance History Entry";
    begin
        HistoryEntry.Init();
        HistoryEntry."Maintenance No." := CopyStr(StrSubstNo(MaintenanceNoTok, NextId()), 1, MaxStrLen(HistoryEntry."Maintenance No."));
        HistoryEntry."Equipment No." := EquipmentNo;
        HistoryEntry."Maintenance Date" := DT2Date(PostedAt);
        HistoryEntry."Posted By" := PostedBy;
        HistoryEntry."Posted At" := PostedAt;
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

    local procedure InsertAuditEntry(EquipmentNo: Code[20]; UserId: Code[50]; LoggedAt: DateTime)
    var
        AuditEntry: Record "EQM Equipment Audit Entry";
    begin
        // Inserted without triggers: the audit trail only accepts entries from its own codeunit
        AuditEntry.Init();
        AuditEntry."Equipment No." := EquipmentNo;
        AuditEntry."User ID" := UserId;
        AuditEntry."Logged At" := LoggedAt;
        AuditEntry.Insert(false);
    end;

    local procedure CountMaintenances(var TempBuffer: Record "EQM Usage Analytics Buffer" temporary; StartingDate: Date; EndingDate: Date): Integer
    begin
        UsageAnalyticsMgt.BuildMaintenanceTrends(TempBuffer, StartingDate, EndingDate);
        TempBuffer.CalcSums("No. of Maintenances");
        exit(TempBuffer."No. of Maintenances");
    end;

    local procedure CountActiveUsers(var TempBuffer: Record "EQM Usage Analytics Buffer" temporary; StartingDate: Date; EndingDate: Date): Integer
    begin
        UsageAnalyticsMgt.BuildActiveUsers(TempBuffer, StartingDate, EndingDate);
        TempBuffer.CalcSums("Active Users");
        exit(TempBuffer."Active Users");
    end;

    local procedure RunReport(var UsageAnalytics: Report "EQM Usage Analytics"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: TextBuilder;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        UsageAnalytics.SaveAs('', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result.AppendLine(Line);
        end;
        exit(Result.ToText());
    end;
}
