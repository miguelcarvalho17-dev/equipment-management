namespace MiguelCarvalho.EquipmentManagement;

/// <summary>
/// Data and drill-down helpers for the equipment dashboard tiles and charts.
/// </summary>
codeunit 50107 "EQM Dashboard Mgt."
{
    Access = Internal;

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
