namespace MiguelCarvalho.EquipmentManagement;

using Microsoft.Purchases.Vendor;

/// <summary>
/// Read helpers for maintenance records shown on equipment pages, and the confirmation before posting.
/// </summary>
codeunit 50108 "EQM Maintenance Mgt."
{
    Access = Internal;

    var
        PostQst: Label 'Do you want to post maintenance record %1? It is copied to the maintenance history, and after that you cannot change it. If no other maintenance is open for the equipment, its status changes from In Maintenance to Available.', Comment = '%1 = maintenance record number';
        OverdueCheckedTelemetryTok: Label 'EQM0002', Locked = true;
        OverdueCheckedTelemetryMsg: Label 'Overdue maintenance checked.', Locked = true;
        ScheduledTok: Label 'JobQueue', Locked = true;
        ManualTok: Label 'Manual', Locked = true;
        OverdueCountDimTok: Label 'OverdueCount', Locked = true;
        OverdueDaysDimTok: Label 'OverdueDays', Locked = true;
        ReferenceDateDimTok: Label 'ReferenceDate', Locked = true;
        TriggerDimTok: Label 'Trigger', Locked = true;

    /// <summary>
    /// Returns whether the equipment has any maintenance record. Equipment with maintenance records cannot be deleted.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <returns>True when at least one record exists.</returns>
    internal procedure HasMaintenanceRecords(EquipmentNo: Code[20]): Boolean
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        MaintenanceRecord.SetCurrentKey("Equipment No.", "Maintenance Date");
        MaintenanceRecord.SetRange("Equipment No.", EquipmentNo);
        exit(not MaintenanceRecord.IsEmpty());
    end;

    /// <summary>
    /// Returns the number of maintenance records of the equipment.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <returns>The number of records.</returns>
    internal procedure CountMaintenanceRecords(EquipmentNo: Code[20]): Integer
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        MaintenanceRecord.SetCurrentKey("Equipment No.", "Maintenance Date");
        MaintenanceRecord.SetRange("Equipment No.", EquipmentNo);
        exit(MaintenanceRecord.Count());
    end;

    /// <summary>
    /// Finds the most recent maintenance record of the equipment (latest date; on equal dates the highest number).
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <param name="MaintenanceRecord">Returns the record; empty when none is found.</param>
    /// <returns>True when a record exists.</returns>
    internal procedure GetLastMaintenanceRecord(EquipmentNo: Code[20]; var MaintenanceRecord: Record "EQM Maintenance Record"): Boolean
    begin
        MaintenanceRecord.Reset();
        MaintenanceRecord.SetCurrentKey("Equipment No.", "Maintenance Date");
        MaintenanceRecord.SetRange("Equipment No.", EquipmentNo);
        exit(MaintenanceRecord.FindLast());
    end;

    /// <summary>
    /// Opens the maintenance records filtered to one piece of equipment.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number to filter on.</param>
    internal procedure ShowMaintenanceRecords(EquipmentNo: Code[20])
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        MaintenanceRecord.SetRange("Equipment No.", EquipmentNo);
        Page.Run(Page::"EQM Maintenance Records", MaintenanceRecord);
    end;

    /// <summary>
    /// Returns whether the equipment has at least one open maintenance record. Equipment with open
    /// maintenance cannot be assigned.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <returns>True when at least one open record exists.</returns>
    internal procedure HasOpenMaintenance(EquipmentNo: Code[20]): Boolean
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        MaintenanceRecord.SetCurrentKey("Equipment No.", Status);
        MaintenanceRecord.SetRange("Equipment No.", EquipmentNo);
        MaintenanceRecord.SetRange(Status, MaintenanceRecord.Status::Open);
        exit(not MaintenanceRecord.IsEmpty());
    end;

    /// <summary>
    /// Returns the number of open maintenance records of the equipment.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <returns>The number of open records.</returns>
    internal procedure CountOpenMaintenanceRecords(EquipmentNo: Code[20]): Integer
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        MaintenanceRecord.SetCurrentKey("Equipment No.", Status);
        MaintenanceRecord.SetRange("Equipment No.", EquipmentNo);
        MaintenanceRecord.SetRange(Status, MaintenanceRecord.Status::Open);
        exit(MaintenanceRecord.Count());
    end;

    /// <summary>
    /// Opens the open maintenance records filtered to one piece of equipment.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number to filter on.</param>
    internal procedure ShowOpenMaintenanceRecords(EquipmentNo: Code[20])
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        MaintenanceRecord.SetCurrentKey("Equipment No.", Status);
        MaintenanceRecord.SetRange("Equipment No.", EquipmentNo);
        MaintenanceRecord.SetRange(Status, MaintenanceRecord.Status::Open);
        Page.Run(Page::"EQM Maintenance Records", MaintenanceRecord);
    end;

    /// <summary>
    /// Returns after how many days an open maintenance record is overdue.
    /// </summary>
    /// <returns>The number of days.</returns>
    internal procedure GetMaintenanceOverdueDays(): Integer
    begin
        exit(14);
    end;

    /// <summary>
    /// Returns the number of days an open maintenance record has been open, counted from its maintenance date.
    /// </summary>
    /// <param name="MaintenanceRecord">The maintenance record.</param>
    /// <param name="ReferenceDate">The date to count to. 0D means today.</param>
    /// <returns>The number of days; 0 when the maintenance date is blank.</returns>
    internal procedure CalcDaysOpen(MaintenanceRecord: Record "EQM Maintenance Record"; ReferenceDate: Date): Integer
    begin
        if ReferenceDate = 0D then
            ReferenceDate := Today();
        if MaintenanceRecord."Maintenance Date" = 0D then
            exit(0);
        exit(ReferenceDate - MaintenanceRecord."Maintenance Date");
    end;

    /// <summary>
    /// Returns whether the maintenance record is open and has been open longer than the overdue limit.
    /// </summary>
    /// <param name="MaintenanceRecord">The maintenance record.</param>
    /// <param name="ReferenceDate">The date to count to. 0D means today.</param>
    /// <returns>True when the record is overdue.</returns>
    internal procedure IsMaintenanceOverdue(MaintenanceRecord: Record "EQM Maintenance Record"; ReferenceDate: Date): Boolean
    begin
        if MaintenanceRecord.Status <> MaintenanceRecord.Status::Open then
            exit(false);
        if MaintenanceRecord."Maintenance Date" = 0D then
            exit(false);
        exit(CalcDaysOpen(MaintenanceRecord, ReferenceDate) > GetMaintenanceOverdueDays());
    end;

    /// <summary>
    /// Sets the filters that select the overdue maintenance records.
    /// </summary>
    /// <param name="MaintenanceRecord">The record to filter.</param>
    /// <param name="ReferenceDate">The date to count to. 0D means today.</param>
    internal procedure SetOverdueMaintenanceFilter(var MaintenanceRecord: Record "EQM Maintenance Record"; ReferenceDate: Date)
    begin
        if ReferenceDate = 0D then
            ReferenceDate := Today();
        MaintenanceRecord.SetCurrentKey(Status, "Maintenance Date");
        MaintenanceRecord.SetRange(Status, MaintenanceRecord.Status::Open);
        MaintenanceRecord.SetFilter("Maintenance Date", '<>%1&..%2', 0D, ReferenceDate - GetMaintenanceOverdueDays() - 1);
    end;

    /// <summary>
    /// Returns the number of overdue maintenance records.
    /// </summary>
    /// <param name="ReferenceDate">The date to count to. 0D means today.</param>
    /// <returns>The number of overdue records.</returns>
    internal procedure CountOverdueMaintenance(ReferenceDate: Date): Integer
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        SetOverdueMaintenanceFilter(MaintenanceRecord, ReferenceDate);
        exit(MaintenanceRecord.Count());
    end;

    /// <summary>
    /// Finds the oldest overdue open maintenance record of the equipment.
    /// </summary>
    /// <param name="EquipmentNo">The equipment number.</param>
    /// <param name="ReferenceDate">The date to count to. 0D means today.</param>
    /// <param name="MaintenanceRecord">Returns the record; empty when none is found.</param>
    /// <returns>True when an overdue record exists.</returns>
    internal procedure FindOldestOverdueMaintenance(EquipmentNo: Code[20]; ReferenceDate: Date; var MaintenanceRecord: Record "EQM Maintenance Record"): Boolean
    begin
        if ReferenceDate = 0D then
            ReferenceDate := Today();
        MaintenanceRecord.Reset();
        MaintenanceRecord.SetCurrentKey("Equipment No.", "Maintenance Date");
        MaintenanceRecord.SetRange("Equipment No.", EquipmentNo);
        MaintenanceRecord.SetRange(Status, MaintenanceRecord.Status::Open);
        MaintenanceRecord.SetFilter("Maintenance Date", '<>%1&..%2', 0D, ReferenceDate - GetMaintenanceOverdueDays() - 1);
        MaintenanceRecord.SetLoadFields("No.", "Maintenance Date");
        exit(MaintenanceRecord.FindFirst());
    end;

    /// <summary>
    /// Opens the overdue maintenance records.
    /// </summary>
    /// <param name="ReferenceDate">The date to count to. 0D means today.</param>
    internal procedure ShowOverdueMaintenanceRecords(ReferenceDate: Date)
    var
        MaintenanceRecord: Record "EQM Maintenance Record";
    begin
        SetOverdueMaintenanceFilter(MaintenanceRecord, ReferenceDate);
        Page.Run(Page::"EQM Maintenance Records", MaintenanceRecord);
    end;

    /// <summary>
    /// Checks how many maintenance records are overdue on the reference date and logs the result to telemetry.
    /// Changes no data. 0D means today.
    /// </summary>
    /// <param name="ReferenceDate">The date to check on. 0D means today.</param>
    /// <param name="IsScheduled">True when a job queue entry runs the check; false when a user does.</param>
    /// <returns>The number of overdue records.</returns>
    internal procedure CheckOverdueMaintenance(ReferenceDate: Date; IsScheduled: Boolean): Integer
    var
        OverdueCount: Integer;
    begin
        if ReferenceDate = 0D then
            ReferenceDate := Today();
        OverdueCount := CountOverdueMaintenance(ReferenceDate);
        LogOverdueCheckTelemetry(ReferenceDate, IsScheduled, OverdueCount);
        exit(OverdueCount);
    end;

    local procedure LogOverdueCheckTelemetry(ReferenceDate: Date; IsScheduled: Boolean; OverdueCount: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add(OverdueCountDimTok, Format(OverdueCount, 0, 9));
        Dimensions.Add(OverdueDaysDimTok, Format(GetMaintenanceOverdueDays(), 0, 9));
        Dimensions.Add(ReferenceDateDimTok, Format(ReferenceDate, 0, 9));
        if IsScheduled then
            Dimensions.Add(TriggerDimTok, ScheduledTok)
        else
            Dimensions.Add(TriggerDimTok, ManualTok);
        Session.LogMessage(OverdueCheckedTelemetryTok, OverdueCheckedTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    /// <summary>
    /// Asks the user to confirm, then posts the maintenance record and shows a notification when the equipment is
    /// back from maintenance. Returns false when the user cancels.
    /// </summary>
    /// <param name="MaintenanceRecord">The record to post. It shows Status = Posted afterwards.</param>
    /// <returns>True when the record was posted; false when the user cancelled.</returns>
    internal procedure PostWithConfirmation(var MaintenanceRecord: Record "EQM Maintenance Record"): Boolean
    var
        Equipment: Record "EQM Equipment";
        NotificationMgt: Codeunit "EQM Notification Mgt.";
        StatusBeforePosting: Enum "EQM Equipment Status";
    begin
        if not Confirm(PostQst, true, MaintenanceRecord."No.") then
            exit(false);

        Equipment.SetLoadFields(Status);
        if Equipment.Get(MaintenanceRecord."Equipment No.") then
            StatusBeforePosting := Equipment.Status;

        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);
        NotificationMgt.SendReturnedFromMaintenanceNotification(MaintenanceRecord."Equipment No.", StatusBeforePosting);
        exit(true);
    end;

    /// <summary>
    /// Returns the name of a vendor. Returns blank when the user has no read permission on vendors.
    /// </summary>
    /// <param name="VendorNo">The vendor number.</param>
    /// <returns>The vendor name, or blank when the number is blank, the vendor does not exist or cannot be read.</returns>
    internal procedure GetVendorName(VendorNo: Code[20]): Text[100]
    var
        Vendor: Record Vendor;
    begin
        if VendorNo = '' then
            exit('');
        if not Vendor.ReadPermission() then
            exit('');

        Vendor.SetLoadFields(Name);
        if Vendor.Get(VendorNo) then
            exit(Vendor.Name);
        exit('');
    end;
}
