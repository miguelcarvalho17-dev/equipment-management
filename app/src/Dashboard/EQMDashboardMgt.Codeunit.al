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
    /// active from the reference date on, expiring within 90 days and within the expiring period from the reference
    /// date, expired before the reference date. Expiring this month: from the reference date up to and including the
    /// last day of the reference date's month, so warranties that ended earlier in the month count as expired, not as
    /// expiring. 0D means today. The 90 days come from the 90 Days warranty alert
    /// interval, so the tile and the alert window stay consistent.
    /// </summary>
    /// <param name="EquipmentCue">The cue record to set the filters on.</param>
    /// <param name="ReferenceDate">The date the tiles are calculated on.</param>
    internal procedure SetWarrantyCueFilters(var EquipmentCue: Record "EQM Equipment Cue"; ReferenceDate: Date)
    var
        Equipment: Record "EQM Equipment";
        WarrantyAlertMgt: Codeunit "EQM Warranty Alert Mgt.";
        ExpiringSoonDays: Integer;
        ExpiringWithin90Days: Integer;
    begin
        if ReferenceDate = 0D then
            ReferenceDate := Today();
        ExpiringSoonDays := Equipment.GetWarrantyExpiringSoonDays();
        ExpiringWithin90Days := WarrantyAlertMgt.GetIntervalDays(Enum::"EQM Warranty Alert Interval"::"90 Days");
        EquipmentCue.SetRange("Warranty Expiring Filter", ReferenceDate, ReferenceDate + ExpiringSoonDays);
        EquipmentCue.SetFilter("Warranty Expired Filter", '<>%1&<%2', 0D, ReferenceDate);
        EquipmentCue.SetFilter("Active Warranty Filter", '>=%1', ReferenceDate);
        EquipmentCue.SetRange("Warranty 90 Days Filter", ReferenceDate, ReferenceDate + ExpiringWithin90Days);
        EquipmentCue.SetRange("Warranty Month Filter", ReferenceDate, CalcDate(EndOfMonthFormulaTok, ReferenceDate));
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

    /// <summary>
    /// Counts the equipment for the asset utilization within the filters of the given record. Lost and disposed
    /// equipment is never counted. Total counts every other status, including statuses added by extensions.
    /// The filters on the given record are not changed.
    /// </summary>
    /// <param name="Equipment">The equipment record carrying the filters to apply.</param>
    /// <param name="TotalEquipment">Returns the equipment that is not lost or disposed.</param>
    /// <param name="AssignedEquipment">Returns the equipment with status Assigned.</param>
    /// <param name="AvailableEquipment">Returns the equipment with status Available.</param>
    /// <param name="InMaintenanceEquipment">Returns the equipment with status In Maintenance.</param>
    internal procedure CalcAssetUtilization(var Equipment: Record "EQM Equipment"; var TotalEquipment: Integer; var AssignedEquipment: Integer; var AvailableEquipment: Integer; var InMaintenanceEquipment: Integer)
    var
        FilteredEquipment: Record "EQM Equipment";
    begin
        FilteredEquipment.CopyFilters(Equipment);
        // Filter group 10 is outside the groups the platform uses (0-7), so a user filter on Status in group 0 still applies
        FilteredEquipment.FilterGroup(10);
        FilteredEquipment.SetFilter(Status, '<>%1&<>%2', FilteredEquipment.Status::Lost, FilteredEquipment.Status::Disposed);
        TotalEquipment := FilteredEquipment.Count();
        FilteredEquipment.SetRange(Status, FilteredEquipment.Status::Assigned);
        AssignedEquipment := FilteredEquipment.Count();
        FilteredEquipment.SetRange(Status, FilteredEquipment.Status::Available);
        AvailableEquipment := FilteredEquipment.Count();
        FilteredEquipment.SetRange(Status, FilteredEquipment.Status::"In Maintenance");
        InMaintenanceEquipment := FilteredEquipment.Count();
    end;

    /// <summary>
    /// Returns the utilization percentage: assigned equipment divided by total equipment, times 100, rounded to two decimals.
    /// Zero when there is no equipment.
    /// </summary>
    /// <param name="AssignedEquipment">The number of assigned equipment.</param>
    /// <param name="TotalEquipment">The total number of equipment.</param>
    /// <returns>The utilization percentage.</returns>
    internal procedure CalcUtilizationPct(AssignedEquipment: Integer; TotalEquipment: Integer): Decimal
    begin
        if TotalEquipment <= 0 then
            exit(0);
        exit(Round(AssignedEquipment * 100 / TotalEquipment, 0.01));
    end;

    /// <summary>
    /// Fills the maintenance cost buffer with the posted maintenance cost per category, equipment, year and month.
    /// Only maintenance history entries (posted maintenance) are included. Equipment is taken within the filters of the
    /// given equipment record, and entries within the filters of the given history entry record. The filters of both
    /// records are not changed. The current category of the equipment is used. The buffer is emptied first.
    /// </summary>
    /// <param name="Equipment">The equipment record carrying the filters to apply.</param>
    /// <param name="MaintenanceHistoryEntry">The history entry record carrying the filters to apply.</param>
    /// <param name="TempMaintCostBuffer">Returns the cost per category, equipment, year and month.</param>
    internal procedure BuildMaintenanceCostBuffer(var Equipment: Record "EQM Equipment"; var MaintenanceHistoryEntry: Record "EQM Maintenance History Entry"; var TempMaintCostBuffer: Record "EQM Maint. Cost Buffer" temporary)
    var
        FilteredEquipment: Record "EQM Equipment";
        FilteredHistoryEntry: Record "EQM Maintenance History Entry";
        EquipmentCategories: Dictionary of [Code[20], Code[20]];
        EquipmentDescriptions: Dictionary of [Code[20], Text];
        CategoryDescriptions: Dictionary of [Code[20], Text];
        CategoryCode: Code[20];
    begin
        TempMaintCostBuffer.Reset();
        TempMaintCostBuffer.DeleteAll();

        FilteredEquipment.CopyFilters(Equipment);
        FilteredEquipment.SetLoadFields("No.", Description, "Category Code");
        if not FilteredEquipment.FindSet() then
            exit;
        repeat
            EquipmentCategories.Add(FilteredEquipment."No.", FilteredEquipment."Category Code");
            EquipmentDescriptions.Add(FilteredEquipment."No.", FilteredEquipment.Description);
        until FilteredEquipment.Next() = 0;

        FilteredHistoryEntry.CopyFilters(MaintenanceHistoryEntry);
        FilteredHistoryEntry.SetLoadFields("Equipment No.", "Maintenance Date", Cost);
        if not FilteredHistoryEntry.FindSet() then
            exit;
        repeat
            // Entries of equipment outside the equipment filters are skipped
            if EquipmentCategories.Get(FilteredHistoryEntry."Equipment No.", CategoryCode) then
                AddToMaintCostBuffer(TempMaintCostBuffer, CategoryCode, FilteredHistoryEntry."Equipment No.", FilteredHistoryEntry."Maintenance Date", FilteredHistoryEntry.Cost, EquipmentDescriptions.Get(FilteredHistoryEntry."Equipment No."), CategoryDescriptions);
        until FilteredHistoryEntry.Next() = 0;
    end;

    local procedure AddToMaintCostBuffer(var TempMaintCostBuffer: Record "EQM Maint. Cost Buffer" temporary; CategoryCode: Code[20]; EquipmentNo: Code[20]; MaintenanceDate: Date; Cost: Decimal; EquipmentDescription: Text; var CategoryDescriptions: Dictionary of [Code[20], Text])
    var
        CostYear: Integer;
        CostMonth: Integer;
    begin
        // Posting always sets a maintenance date; a blank date is grouped under year 0, month 0 instead of raising an error
        if MaintenanceDate <> 0D then begin
            CostYear := Date2DMY(MaintenanceDate, 3);
            CostMonth := Date2DMY(MaintenanceDate, 2);
        end;

        if TempMaintCostBuffer.Get(CategoryCode, EquipmentNo, CostYear, CostMonth) then begin
            TempMaintCostBuffer."Total Cost" += Cost;
            TempMaintCostBuffer."No. of Maintenances" += 1;
            TempMaintCostBuffer.Modify();
            exit;
        end;

        TempMaintCostBuffer.Init();
        TempMaintCostBuffer."Category Code" := CategoryCode;
        TempMaintCostBuffer."Equipment No." := EquipmentNo;
        TempMaintCostBuffer."Cost Year" := CostYear;
        TempMaintCostBuffer."Cost Month" := CostMonth;
        if CostYear <> 0 then
            TempMaintCostBuffer."Period Start Date" := DMY2Date(1, CostMonth, CostYear);
        TempMaintCostBuffer."Category Description" := CopyStr(GetCategoryDescription(CategoryCode, CategoryDescriptions), 1, MaxStrLen(TempMaintCostBuffer."Category Description"));
        TempMaintCostBuffer."Equipment Description" := CopyStr(EquipmentDescription, 1, MaxStrLen(TempMaintCostBuffer."Equipment Description"));
        TempMaintCostBuffer."Total Cost" := Cost;
        TempMaintCostBuffer."No. of Maintenances" := 1;
        TempMaintCostBuffer.Insert();
    end;

    local procedure GetCategoryDescription(CategoryCode: Code[20]; var CategoryDescriptions: Dictionary of [Code[20], Text]): Text
    var
        EquipmentCategory: Record "EQM Equipment Category";
        CategoryDescription: Text;
    begin
        if CategoryCode = '' then
            exit('');
        if CategoryDescriptions.Get(CategoryCode, CategoryDescription) then
            exit(CategoryDescription);
        EquipmentCategory.SetLoadFields(Description);
        if EquipmentCategory.Get(CategoryCode) then
            CategoryDescription := EquipmentCategory.Description;
        CategoryDescriptions.Add(CategoryCode, CategoryDescription);
        exit(CategoryDescription);
    end;
}
