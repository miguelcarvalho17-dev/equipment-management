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
    /// Asks the user to confirm, then posts the maintenance record. Returns false when the user cancels.
    /// </summary>
    /// <param name="MaintenanceRecord">The record to post. It shows Status = Posted afterwards.</param>
    /// <returns>True when the record was posted; false when the user cancelled.</returns>
    internal procedure PostWithConfirmation(var MaintenanceRecord: Record "EQM Maintenance Record"): Boolean
    begin
        if not Confirm(PostQst, true, MaintenanceRecord."No.") then
            exit(false);

        Codeunit.Run(Codeunit::"EQM Maintenance-Post", MaintenanceRecord);
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
