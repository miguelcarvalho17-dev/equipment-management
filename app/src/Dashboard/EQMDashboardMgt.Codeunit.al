namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Data and drill-down helpers for the equipment dashboard tiles and charts.
/// </summary>
codeunit 50107 "EQM Dashboard Mgt."
{
    Access = Internal;

    var
        FavorableStyleTok: Label 'Favorable', Locked = true;
        UnfavorableStyleTok: Label 'Unfavorable', Locked = true;
        StartOfMonthFormulaTok: Label '<-CM>', Locked = true;
        EndOfMonthFormulaTok: Label '<CM>', Locked = true;
        StartOfYearFormulaTok: Label '<-CY>', Locked = true;

    /// <summary>
    /// Counts the equipment per category, for every category that has at least one equipment record.
    /// </summary>
    /// <param name="CategoryCodes">Returns the category codes in ascending order.</param>
    /// <param name="EquipmentCounts">Returns the number of equipment records for each category code, in the same order.</param>
    internal procedure GetEquipmentCountByCategory(var CategoryCodes: List of [Code[20]]; var EquipmentCounts: List of [Integer])
    var
        EquipmentByCategory: Query "EQM Equipment by Category";
    begin
        Clear(CategoryCodes);
        Clear(EquipmentCounts);

        EquipmentByCategory.Open();
        while EquipmentByCategory.Read() do begin
            CategoryCodes.Add(EquipmentByCategory.CategoryCode);
            EquipmentCounts.Add(EquipmentByCategory.NoOfEquipment);
        end;
        EquipmentByCategory.Close();
    end;

    /// <summary>
    /// Counts the equipment per status, for every value of the equipment status enum, zero counts included.
    /// </summary>
    /// <param name="StatusOrdinals">Returns the ordinal of every status value, in enum order.</param>
    /// <param name="EquipmentCounts">Returns the number of equipment records for each status ordinal, in the same order.</param>
    internal procedure GetEquipmentCountByStatus(var StatusOrdinals: List of [Integer]; var EquipmentCounts: List of [Integer])
    var
        EquipmentByStatus: Query "EQM Equipment by Status";
        CountByStatus: Dictionary of [Integer, Integer];
        StatusOrdinal: Integer;
    begin
        Clear(StatusOrdinals);
        Clear(EquipmentCounts);

        EquipmentByStatus.Open();
        while EquipmentByStatus.Read() do
            CountByStatus.Set(EquipmentByStatus.Status.AsInteger(), EquipmentByStatus.NoOfEquipment);
        EquipmentByStatus.Close();

        foreach StatusOrdinal in Enum::"EQM Equipment Status".Ordinals() do begin
            StatusOrdinals.Add(StatusOrdinal);
            if CountByStatus.ContainsKey(StatusOrdinal) then
                EquipmentCounts.Add(CountByStatus.Get(StatusOrdinal))
            else
                EquipmentCounts.Add(0);
        end;
    end;

    /// <summary>
    /// Returns the caption of an equipment status.
    /// </summary>
    /// <param name="StatusOrdinal">The ordinal of the equipment status.</param>
    /// <returns>The caption of the status.</returns>
    internal procedure GetStatusCaption(StatusOrdinal: Integer): Text
    begin
        exit(Format(Enum::"EQM Equipment Status".FromInteger(StatusOrdinal)));
    end;

    /// <summary>
    /// Opens the equipment list filtered to one category.
    /// </summary>
    /// <param name="CategoryCode">The category code to filter on.</param>
    internal procedure ShowEquipmentByCategory(CategoryCode: Code[20])
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.SetRange("Category Code", CategoryCode);
        Page.Run(Page::"EQM Equipment List", Equipment);
    end;

    /// <summary>
    /// Opens the equipment list filtered to one status.
    /// </summary>
    /// <param name="StatusOrdinal">The ordinal of the equipment status to filter on.</param>
    internal procedure ShowEquipmentByStatus(StatusOrdinal: Integer)
    var
        Equipment: Record "EQM Equipment";
    begin
        Equipment.SetRange(Status, Enum::"EQM Equipment Status".FromInteger(StatusOrdinal));
        Page.Run(Page::"EQM Equipment List", Equipment);
    end;

    /// <summary>
    /// Sets the date filters of the warranty tiles so that they count the same equipment as the warranty status:
    /// expiring soon from the reference date to the end of the expiring period, expired before the reference date.
    /// 0D means today.
    /// </summary>
    /// <param name="EquipmentCue">The cue record to set the filters on.</param>
    /// <param name="ReferenceDate">The date the tiles are calculated on.</param>
    internal procedure SetWarrantyCueFilters(var EquipmentCue: Record "EQM Equipment Cue"; ReferenceDate: Date)
    var
        Equipment: Record "EQM Equipment";
        ExpiringSoonDays: Integer;
    begin
        if ReferenceDate = 0D then
            ReferenceDate := Today();
        ExpiringSoonDays := Equipment.GetWarrantyExpiringSoonDays();
        EquipmentCue.SetRange("Warranty Expiring Filter", ReferenceDate, ReferenceDate + ExpiringSoonDays);
        EquipmentCue.SetFilter("Warranty Expired Filter", '<>%1&<%2', 0D, ReferenceDate);
    end;

    /// <summary>
    /// Sets the date filters of the planned maintenance tiles from a reference date. Overdue: a next maintenance date
    /// that is filled in and before the reference date, the same rule as IsPlannedMaintenanceOverdue on the equipment.
    /// Planned this month: a next maintenance date from the first to the last day of the reference date's month.
    /// 0D means today.
    /// </summary>
    /// <param name="EquipmentCue">The cue record to set the filters on.</param>
    /// <param name="ReferenceDate">The date the tiles are calculated on.</param>
    internal procedure SetPlannedMaintenanceCueFilters(var EquipmentCue: Record "EQM Equipment Cue"; ReferenceDate: Date)
    begin
        if ReferenceDate = 0D then
            ReferenceDate := Today();
        EquipmentCue.SetFilter("Overdue Maintenance Filter", '<>%1&<%2', 0D, ReferenceDate);
        EquipmentCue.SetRange("Planned Maint. Month Filter", CalcDate(StartOfMonthFormulaTok, ReferenceDate), CalcDate(EndOfMonthFormulaTok, ReferenceDate));
    end;

    /// <summary>
    /// Sets the date filter of the year-to-date maintenance cost tile: maintenance dates from 1 January of the
    /// reference date's year up to and including the reference date. 0D means today.
    /// </summary>
    /// <param name="EquipmentCue">The cue record to set the filter on.</param>
    /// <param name="ReferenceDate">The date the tile is calculated on.</param>
    internal procedure SetMaintenanceCostCueFilters(var EquipmentCue: Record "EQM Equipment Cue"; ReferenceDate: Date)
    begin
        if ReferenceDate = 0D then
            ReferenceDate := Today();
        EquipmentCue.SetRange("Maint. Cost YTD Filter", CalcDate(StartOfYearFormulaTok, ReferenceDate), ReferenceDate);
    end;

    /// <summary>
    /// Returns the style of the overdue maintenance tile: Unfavorable when at least one equipment is overdue,
    /// Favorable when none is.
    /// </summary>
    /// <param name="OverdueCount">The value of the tile.</param>
    /// <returns>The style name.</returns>
    internal procedure GetOverdueMaintenanceCueStyle(OverdueCount: Integer): Text
    begin
        if OverdueCount > 0 then
            exit(UnfavorableStyleTok);
        exit(FavorableStyleTok);
    end;

    /// <summary>
    /// Returns the posted maintenance cost per equipment category, highest cost first. Categories without posted
    /// maintenance cost are not returned. The current category of each equipment is used.
    /// </summary>
    /// <param name="CategoryCodes">Returns the category codes, highest cost first. A blank code means equipment without a category.</param>
    /// <param name="MaintenanceCosts">Returns the maintenance cost for each category code, in the same order.</param>
    internal procedure GetMaintenanceCostByCategory(var CategoryCodes: List of [Code[20]]; var MaintenanceCosts: List of [Decimal])
    var
        MaintCostByCategory: Query "EQM Maint. Cost by Category";
    begin
        Clear(CategoryCodes);
        Clear(MaintenanceCosts);

        MaintCostByCategory.Open();
        while MaintCostByCategory.Read() do begin
            CategoryCodes.Add(MaintCostByCategory.CategoryCode);
            MaintenanceCosts.Add(MaintCostByCategory.TotalCost);
        end;
        MaintCostByCategory.Close();
    end;

    /// <summary>
    /// Returns the equipment with the highest posted maintenance cost, highest first, at most NumberOfEquipment
    /// entries. Equipment without posted maintenance cost is not returned.
    /// </summary>
    /// <param name="NumberOfEquipment">The maximum number of equipment records to return. Zero or less returns nothing.</param>
    /// <param name="EquipmentNos">Returns the equipment numbers, highest cost first.</param>
    /// <param name="MaintenanceCosts">Returns the maintenance cost for each equipment number, in the same order.</param>
    internal procedure GetTopMaintenanceCostByEquipment(NumberOfEquipment: Integer; var EquipmentNos: List of [Code[20]]; var MaintenanceCosts: List of [Decimal])
    var
        MaintCostByEquipment: Query "EQM Maint. Cost by Equipment";
    begin
        Clear(EquipmentNos);
        Clear(MaintenanceCosts);
        if NumberOfEquipment <= 0 then
            exit;

        MaintCostByEquipment.TopNumberOfRows(NumberOfEquipment);
        MaintCostByEquipment.Open();
        while MaintCostByEquipment.Read() do begin
            EquipmentNos.Add(MaintCostByEquipment.EquipmentNo);
            MaintenanceCosts.Add(MaintCostByEquipment.TotalCost);
        end;
        MaintCostByEquipment.Close();
    end;

    /// <summary>
    /// Returns how many equipment records the maintenance cost chart shows.
    /// </summary>
    /// <returns>The number of equipment records in the chart.</returns>
    internal procedure GetTopEquipmentLimit(): Integer
    begin
        exit(10);
    end;

    /// <summary>
    /// Opens the posted maintenance history filtered to one piece of equipment.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number to filter on.</param>
    internal procedure ShowMaintenanceHistory(EquipmentNo: Code[20])
    var
        MaintenanceHistoryEntry: Record "EQM Maintenance History Entry";
    begin
        MaintenanceHistoryEntry.SetRange("Equipment No.", EquipmentNo);
        Page.Run(Page::"EQM Maintenance History", MaintenanceHistoryEntry);
    end;
}
