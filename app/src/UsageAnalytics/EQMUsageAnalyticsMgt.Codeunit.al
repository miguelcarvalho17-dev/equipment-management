namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Calculates the usage analytics metrics (most assigned categories, maintenance trends, equipment growth, active users) for the usage analytics report.
/// Reads data only: it never writes to the database, takes no locks and does not commit.
/// </summary>
codeunit 50144 "EQM Usage Analytics Mgt."
{
    Access = Internal;

    var
        StartOfMonthFormulaTok: Label '<-CM>', Locked = true;
        EndOfMonthFormulaTok: Label '<CM>', Locked = true;
        DefaultStartFormulaTok: Label '<-CM-11M>', Locked = true;
        UserMonthKeyTok: Label '%1|%2', Locked = true;
        PeriodMissingErr: Label 'Enter both a starting date and an ending date for the usage analytics.';
        PeriodReversedErr: Label 'The starting date %1 is after the ending date %2. Enter a starting date that is on or before the ending date.', Comment = '%1 = starting date, %2 = ending date';
        PeriodTooLongErr: Label 'The period from %1 to %2 covers %3 months. Choose a period of at most %4 months.', Comment = '%1 = starting date, %2 = ending date, %3 = number of months in the period, %4 = the longest allowed period in months';
        WithoutCategoryLbl: Label 'Without category';

    /// <summary>
    /// Returns the longest period, in calendar months, that the usage analytics accept.
    /// </summary>
    /// <returns>The maximum number of calendar months.</returns>
    internal procedure GetMaxPeriodMonths(): Integer
    begin
        exit(120);
    end;

    /// <summary>
    /// Returns the default period: the 12 calendar months up to and including the reference date.
    /// </summary>
    /// <param name="ReferenceDate">The last day of the period. Today's work date is used when blank.</param>
    /// <param name="StartingDate">Returns the first day of the month 11 months before the reference date.</param>
    /// <param name="EndingDate">Returns the reference date.</param>
    internal procedure GetDefaultPeriod(ReferenceDate: Date; var StartingDate: Date; var EndingDate: Date)
    begin
        if ReferenceDate = 0D then
            ReferenceDate := WorkDate();
        EndingDate := ReferenceDate;
        StartingDate := CalcDate(DefaultStartFormulaTok, ReferenceDate);
    end;

    /// <summary>
    /// Stops with an error when the period is blank, reversed or longer than the allowed number of months.
    /// </summary>
    /// <param name="StartingDate">The first day of the period.</param>
    /// <param name="EndingDate">The last day of the period.</param>
    internal procedure CheckPeriod(StartingDate: Date; EndingDate: Date)
    var
        PeriodError: ErrorInfo;
        Months: Integer;
    begin
        if (StartingDate = 0D) or (EndingDate = 0D) then begin
            PeriodError.Message(PeriodMissingErr);
            Error(PeriodError);
        end;
        if StartingDate > EndingDate then begin
            PeriodError.Message(StrSubstNo(PeriodReversedErr, StartingDate, EndingDate));
            Error(PeriodError);
        end;
        Months := CountMonths(StartingDate, EndingDate);
        if Months > GetMaxPeriodMonths() then begin
            PeriodError.Message(StrSubstNo(PeriodTooLongErr, StartingDate, EndingDate, Months, GetMaxPeriodMonths()));
            Error(PeriodError);
        end;
    end;

    /// <summary>
    /// Fills the buffer with one row per category that has assignments in the period, ranked by number of assignments.
    /// </summary>
    /// <param name="TempBuffer">The temporary buffer to fill. It is cleared first.</param>
    /// <param name="StartingDate">The first day of the period.</param>
    /// <param name="EndingDate">The last day of the period.</param>
    internal procedure BuildMostAssignedCategories(var TempBuffer: Record "EQM Usage Analytics Buffer" temporary; StartingDate: Date; EndingDate: Date)
    var
        AssignmentsByCategory: Query "EQM Assignments by Category";
        CategoryCodes: List of [Code[20]];
        CategoryCounts: List of [Integer];
        WithoutCategoryCount: Integer;
        TotalCount: Integer;
        WithoutCategoryPlaced: Boolean;
        Index: Integer;
    begin
        CheckPeriod(StartingDate, EndingDate);
        TempBuffer.Reset();
        TempBuffer.DeleteAll();

        AssignmentsByCategory.SetRange(AssignmentDateFilter, StartingDate, EndingDate);
        AssignmentsByCategory.Open();
        while AssignmentsByCategory.Read() do begin
            TotalCount += AssignmentsByCategory.NoOfAssignments;
            if AssignmentsByCategory.CategoryCode = '' then
                WithoutCategoryCount += AssignmentsByCategory.NoOfAssignments
            else begin
                CategoryCodes.Add(AssignmentsByCategory.CategoryCode);
                CategoryCounts.Add(AssignmentsByCategory.NoOfAssignments);
            end;
        end;
        AssignmentsByCategory.Close();

        for Index := 1 to CategoryCodes.Count() do begin
            if (not WithoutCategoryPlaced) and (WithoutCategoryCount > 0) and (WithoutCategoryCount >= CategoryCounts.Get(Index)) then begin
                AddCategoryRow(TempBuffer, '', WithoutCategoryCount, TotalCount);
                WithoutCategoryPlaced := true;
            end;
            AddCategoryRow(TempBuffer, CategoryCodes.Get(Index), CategoryCounts.Get(Index), TotalCount);
        end;
        if (not WithoutCategoryPlaced) and (WithoutCategoryCount > 0) then
            AddCategoryRow(TempBuffer, '', WithoutCategoryCount, TotalCount);
    end;

    /// <summary>
    /// Fills the buffer with one row per calendar month of the period: posted maintenance count and cost.
    /// </summary>
    /// <param name="TempBuffer">The temporary buffer to fill. It is cleared first.</param>
    /// <param name="StartingDate">The first day of the period.</param>
    /// <param name="EndingDate">The last day of the period.</param>
    internal procedure BuildMaintenanceTrends(var TempBuffer: Record "EQM Usage Analytics Buffer" temporary; StartingDate: Date; EndingDate: Date)
    var
        HistoryEntry: Record "EQM Maintenance History Entry";
    begin
        CheckPeriod(StartingDate, EndingDate);
        InitMonthRows(TempBuffer, StartingDate, EndingDate);

        HistoryEntry.SetLoadFields("Maintenance Date", Cost);
        if TempBuffer.FindSet(true) then
            repeat
                HistoryEntry.SetRange("Maintenance Date", TempBuffer."Period Start Date", TempBuffer."Period End Date");
                TempBuffer."No. of Maintenances" := HistoryEntry.Count();
                HistoryEntry.CalcSums(Cost);
                TempBuffer."Maintenance Cost" := HistoryEntry.Cost;
                TempBuffer.Modify();
            until TempBuffer.Next() = 0;
    end;

    /// <summary>
    /// Fills the buffer with one row per calendar month of the period: equipment created in the month and total equipment at the end of the month.
    /// </summary>
    /// <param name="TempBuffer">The temporary buffer to fill. It is cleared first.</param>
    /// <param name="StartingDate">The first day of the period.</param>
    /// <param name="EndingDate">The last day of the period.</param>
    internal procedure BuildEquipmentGrowth(var TempBuffer: Record "EQM Usage Analytics Buffer" temporary; StartingDate: Date; EndingDate: Date)
    var
        Equipment: Record "EQM Equipment";
    begin
        CheckPeriod(StartingDate, EndingDate);
        InitMonthRows(TempBuffer, StartingDate, EndingDate);

        Equipment.SetLoadFields("No.");
        if TempBuffer.FindSet(true) then
            repeat
                Equipment.SetRange(SystemCreatedAt, CreateDateTime(TempBuffer."Period Start Date", 000000T), CreateDateTime(TempBuffer."Period End Date", 235959.999T));
                TempBuffer."New Equipment" := Equipment.Count();
                Equipment.SetRange(SystemCreatedAt, 0DT, CreateDateTime(TempBuffer."Period End Date", 235959.999T));
                TempBuffer."Total Equipment" := Equipment.Count();
                TempBuffer.Modify();
            until TempBuffer.Next() = 0;
    end;

    /// <summary>
    /// Fills the buffer with one row per calendar month of the period: the number of distinct users with an audit entry or a posted maintenance.
    /// Only counts are stored, never the user IDs.
    /// </summary>
    /// <param name="TempBuffer">The temporary buffer to fill. It is cleared first.</param>
    /// <param name="StartingDate">The first day of the period.</param>
    /// <param name="EndingDate">The last day of the period.</param>
    internal procedure BuildActiveUsers(var TempBuffer: Record "EQM Usage Analytics Buffer" temporary; StartingDate: Date; EndingDate: Date)
    var
        AuditEntry: Record "EQM Equipment Audit Entry";
        HistoryEntry: Record "EQM Maintenance History Entry";
        SeenUsers: Dictionary of [Text, Boolean];
        UserCounts: Dictionary of [Integer, Integer];
        FromDateTime: DateTime;
        ToDateTime: DateTime;
    begin
        CheckPeriod(StartingDate, EndingDate);
        InitMonthRows(TempBuffer, StartingDate, EndingDate);

        FromDateTime := CreateDateTime(StartingDate, 000000T);
        ToDateTime := CreateDateTime(EndingDate, 235959.999T);

        AuditEntry.SetLoadFields("User ID", "Logged At");
        AuditEntry.SetRange("Logged At", FromDateTime, ToDateTime);
        AuditEntry.SetFilter("User ID", '<>%1', '');
        if AuditEntry.FindSet() then
            repeat
                AddActiveUser(SeenUsers, UserCounts, StartingDate, DT2Date(AuditEntry."Logged At"), AuditEntry."User ID");
            until AuditEntry.Next() = 0;

        HistoryEntry.SetLoadFields("Posted By", "Posted At");
        HistoryEntry.SetRange("Posted At", FromDateTime, ToDateTime);
        HistoryEntry.SetFilter("Posted By", '<>%1', '');
        if HistoryEntry.FindSet() then
            repeat
                AddActiveUser(SeenUsers, UserCounts, StartingDate, DT2Date(HistoryEntry."Posted At"), HistoryEntry."Posted By");
            until HistoryEntry.Next() = 0;

        if TempBuffer.FindSet(true) then
            repeat
                if UserCounts.ContainsKey(TempBuffer."Line No.") then begin
                    TempBuffer."Active Users" := UserCounts.Get(TempBuffer."Line No.");
                    TempBuffer.Modify();
                end;
            until TempBuffer.Next() = 0;
    end;

    local procedure AddCategoryRow(var TempBuffer: Record "EQM Usage Analytics Buffer" temporary; CategoryCode: Code[20]; AssignmentCount: Integer; TotalCount: Integer)
    begin
        TempBuffer.Init();
        TempBuffer."Line No." := TempBuffer.Count() + 1;
        TempBuffer.Rank := TempBuffer."Line No.";
        TempBuffer."Category Code" := CategoryCode;
        TempBuffer."Category Description" := CopyStr(GetCategoryDescription(CategoryCode), 1, MaxStrLen(TempBuffer."Category Description"));
        TempBuffer."No. of Assignments" := AssignmentCount;
        TempBuffer."Assignment Share %" := Round(AssignmentCount * 100 / TotalCount, 0.01);
        TempBuffer.Insert();
    end;

    local procedure GetCategoryDescription(CategoryCode: Code[20]): Text
    var
        Category: Record "EQM Equipment Category";
    begin
        if CategoryCode = '' then
            exit(WithoutCategoryLbl);
        Category.SetLoadFields(Description);
        if Category.Get(CategoryCode) then
            exit(Category.Description);
        exit('');
    end;

    local procedure InitMonthRows(var TempBuffer: Record "EQM Usage Analytics Buffer" temporary; StartingDate: Date; EndingDate: Date)
    var
        MonthStart: Date;
        MonthEnd: Date;
        LineNo: Integer;
    begin
        TempBuffer.Reset();
        TempBuffer.DeleteAll();

        MonthStart := CalcDate(StartOfMonthFormulaTok, StartingDate);
        repeat
            MonthEnd := CalcDate(EndOfMonthFormulaTok, MonthStart);
            LineNo += 1;
            TempBuffer.Init();
            TempBuffer."Line No." := LineNo;
            TempBuffer."Period Start Date" := MonthStart;
            if MonthStart < StartingDate then
                TempBuffer."Period Start Date" := StartingDate;
            TempBuffer."Period End Date" := MonthEnd;
            if MonthEnd > EndingDate then
                TempBuffer."Period End Date" := EndingDate;
            TempBuffer.Insert();
            // The last month ends the loop before MonthEnd + 1, so the date range limit (year 9999) is never crossed
            if MonthEnd < EndingDate then
                MonthStart := MonthEnd + 1;
        until MonthEnd >= EndingDate;
    end;

    local procedure AddActiveUser(var SeenUsers: Dictionary of [Text, Boolean]; var UserCounts: Dictionary of [Integer, Integer]; StartingDate: Date; ActivityDate: Date; UserId: Code[50])
    var
        MonthIndex: Integer;
        MonthKey: Text;
    begin
        MonthIndex := CountMonths(StartingDate, ActivityDate);
        MonthKey := StrSubstNo(UserMonthKeyTok, MonthIndex, UserId);
        if SeenUsers.ContainsKey(MonthKey) then
            exit;
        SeenUsers.Add(MonthKey, true);
        if UserCounts.ContainsKey(MonthIndex) then
            UserCounts.Set(MonthIndex, UserCounts.Get(MonthIndex) + 1)
        else
            UserCounts.Add(MonthIndex, 1);
    end;

    local procedure CountMonths(StartingDate: Date; EndingDate: Date): Integer
    begin
        exit((Date2DMY(EndingDate, 3) - Date2DMY(StartingDate, 3)) * 12 + Date2DMY(EndingDate, 2) - Date2DMY(StartingDate, 2) + 1);
    end;
}
